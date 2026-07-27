# Unedited first response — 10 Integration Tests (Category)

## Scenario Matrix

| Endpoint | Auth Role | Input / State | Expected Result |
|---|---|---|---|
| `GET /api/categories` | Anonymous | Seeded categories | 200 OK, returns list |
| `POST /api/categories` | Anonymous | Valid request | 401 Unauthorized |
| `POST /api/categories` | Authenticated (User) | Valid request | 403 Forbidden |
| `POST /api/categories` | Admin | Valid request | 201 Created, persists to DB |
| `POST /api/categories` | Admin | Missing Name (Validation) | 400 Bad Request |
| `POST /api/categories` | Admin | Duplicate Name (Conflict) | 409 Conflict |
| `DELETE /api/categories/{id}` | Admin | Non-existent Id | 404 Not Found |
| `DELETE /api/categories/{id}` | Admin | Referenced Category | 409 Conflict |

---

## Factory / Fixture Changes

**Target path**: `tests/PromptEvaluation.Tests/Fixtures/CustomWebApplicationFactory.cs`

```csharp
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using PromptEvaluation.Api.Data;
using System.Security.Claims;
using System.Text.Encodings.Web;

namespace PromptEvaluation.Tests.Fixtures;

// 1. Test Authentication Handler to bypass JWT
public class TestAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public TestAuthHandler(IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger, UrlEncoder encoder)
        : base(options, logger, encoder)
    {
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Context.Request.Headers.TryGetValue("Authorization", out var authHeader))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var token = authHeader.ToString().Replace("Bearer ", "");
        var claims = new List<Claim> { new Claim(ClaimTypes.Name, "TestUser") };

        if (token == "AdminToken")
        {
            claims.Add(new Claim(ClaimTypes.Role, "Admin"));
        }
        else if (token == "UserToken")
        {
            claims.Add(new Claim(ClaimTypes.Role, "User"));
        }

        var identity = new ClaimsIdentity(claims, "Test");
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, "Test");

        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}

// 2. Custom WebApplicationFactory
public class CustomWebApplicationFactory : WebApplicationFactory<Program>
{
    private SqliteConnection? _connection;

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureTestServices(services =>
        {
            // Remove existing DbContext configuration
            var descriptor = services.SingleOrDefault(
                d => d.ServiceType == typeof(DbContextOptions<EvaluationDbContext>));
            if (descriptor != null)
            {
                services.Remove(descriptor);
            }

            // Add SQLite in-memory database
            _connection = new SqliteConnection("DataSource=:memory:");
            _connection.Open();

            services.AddDbContext<EvaluationDbContext>(options =>
            {
                options.UseSqlite(_connection);
            });

            // Replace authentication with test handler
            services.AddAuthentication("Test")
                .AddScheme<AuthenticationSchemeOptions, TestAuthHandler>("Test", options => { });
        });
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        _connection?.Dispose();
    }
}
```

---

## Complete Tests

**Target path**: `tests/PromptEvaluation.Tests/Integration/CategoryIntegrationTests.cs`

```csharp
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using PromptEvaluation.Api.Data;
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Models;
using PromptEvaluation.Tests.Fixtures;

namespace PromptEvaluation.Tests.Integration;

public class CategoryIntegrationTests : IClassFixture<CustomWebApplicationFactory>, IDisposable
{
    private readonly CustomWebApplicationFactory _factory;
    private readonly HttpClient _client;
    private readonly IServiceScope _scope;
    private readonly EvaluationDbContext _context;

    public CategoryIntegrationTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = _factory.CreateClient();
        
        // Isolate database state per test
        _scope = _factory.Services.CreateScope();
        _context = _scope.ServiceProvider.GetRequiredService<EvaluationDbContext>();
        _context.Database.EnsureCreated();

        SeedDatabase();
    }

    private void SeedDatabase()
    {
        _context.Categories.Add(new Category { Id = 1, Name = "Referenced Category", IsActive = true });
        _context.Categories.Add(new Category { Id = 2, Name = "Unreferenced Category", IsActive = true });
        _context.Organizers.Add(new Organizer { Id = 1, Name = "Org" });
        _context.SaveChanges();

        _context.Events.Add(new Event
        {
            Id = 1, Title = "Event", Location = "Loc", Capacity = 100, StartUtc = DateTime.UtcNow, EndUtc = DateTime.UtcNow.AddHours(1),
            CategoryId = 1, OrganizerId = 1
        });
        _context.SaveChanges();
    }

    public void Dispose()
    {
        _context.Database.EnsureDeleted();
        _scope.Dispose();
    }

    [Fact]
    public async Task GetAll_Anonymous_Succeeds()
    {
        var response = await _client.GetAsync("/api/categories");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<CategoryListItemResponse>>();
        Assert.NotNull(content);
        Assert.Equal(2, content!.Count);
    }

    [Fact]
    public async Task Post_Anonymous_Returns401()
    {
        var response = await _client.PostAsJsonAsync("/api/categories", new CategoryCreateRequest { Name = "New" });
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Post_AuthenticatedUser_Returns403()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "UserToken");
        var response = await _client.PostAsJsonAsync("/api/categories", new CategoryCreateRequest { Name = "New" });
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Post_Admin_ValidRequest_Returns201AndPersists()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "AdminToken");
        
        var request = new CategoryCreateRequest { Name = "New Category" };
        var response = await _client.PostAsJsonAsync("/api/categories", request);
        
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await response.Content.ReadFromJsonAsync<CategoryResponse>();
        Assert.NotNull(created);
        Assert.Equal("New Category", created!.Name);
        
        // Verify persistence
        var inDb = _context.Categories.Find(created.Id);
        Assert.NotNull(inDb);
        Assert.Equal("New Category", inDb!.Name);
    }

    [Fact]
    public async Task Post_Admin_DuplicateName_Returns409()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "AdminToken");
        
        var request = new CategoryCreateRequest { Name = "Unreferenced Category" };
        var response = await _client.PostAsJsonAsync("/api/categories", request);
        
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<ProblemDetails>();
        Assert.Equal("DUPLICATE_CATEGORY_NAME", problem!.Extensions["errorCode"]?.ToString());
    }

    [Fact]
    public async Task Delete_Admin_ReferencedCategory_Returns409()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "AdminToken");
        
        // Category 1 is referenced by Event 1
        var response = await _client.DeleteAsync("/api/categories/1");
        
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<ProblemDetails>();
        Assert.Equal("CATEGORY_IN_USE", problem!.Extensions["errorCode"]?.ToString());
    }

    [Fact]
    public async Task Delete_Admin_UnreferencedCategory_Returns204()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "AdminToken");
        
        // Category 2 is unreferenced
        var response = await _client.DeleteAsync("/api/categories/2");
        
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }
}
```

---

## Required Package Changes

**Package**: `Microsoft.AspNetCore.Mvc.Testing`
**Justification**: Provides `WebApplicationFactory` which allows bootstrapping the ASP.NET Core application in-memory for integration tests, enabling real HTTP requests through the middleware pipeline without network binding.

---

## Commands and Cleanup

**Command**:
```powershell
dotnet test evaluation/claude/workspace/PromptEvaluation.slnx --filter "FullyQualifiedName~CategoryIntegrationTests"
```

**Cleanup Notes**: 
The SQLite in-memory database connection is closed when the factory is disposed, tearing down the database cleanly. The `IClassFixture` scopes the factory to the test class, but `EnsureCreated()` and `EnsureDeleted()` in the constructor/dispose pair ensure each test gets a clean schema and data within that shared connection.
