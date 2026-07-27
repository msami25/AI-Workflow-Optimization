# Unedited first response — 10 Integration Tests (Event)

## Scenario Matrix

| Endpoint | Auth Role | Input / State | Expected Result |
|---|---|---|---|
| `GET /api/events` | Anonymous | Seeded events | 200 OK, returns list |
| `POST /api/events` | Anonymous | Valid request | 401 Unauthorized |
| `POST /api/events` | Authenticated (User) | Valid request | 403 Forbidden |
| `POST /api/events` | Admin | Valid request | 201 Created, persists to DB |
| `POST /api/events` | Admin | Invalid Time (Validation) | 400 Bad Request, details returned |
| `POST /api/events` | Admin | Duplicate Event (Conflict) | 409 Conflict |
| `DELETE /api/events/{id}` | Admin | Non-existent Id | 404 Not Found |
| `PUT /api/events/{id}` | Admin | Valid request | 204 No Content |

---

## Factory / Fixture Changes

*Note: The `CustomWebApplicationFactory` and `TestAuthHandler` from the Category Integration Tests are reused here. They set up the SQLite in-memory database and mock JWT authentication.*

---

## Complete Tests

**Target path**: `tests/PromptEvaluation.Tests/Integration/EventIntegrationTests.cs`

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

public class EventIntegrationTests : IClassFixture<CustomWebApplicationFactory>, IDisposable
{
    private readonly CustomWebApplicationFactory _factory;
    private readonly HttpClient _client;
    private readonly IServiceScope _scope;
    private readonly EvaluationDbContext _context;

    public EventIntegrationTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = _factory.CreateClient();
        
        _scope = _factory.Services.CreateScope();
        _context = _scope.ServiceProvider.GetRequiredService<EvaluationDbContext>();
        _context.Database.EnsureCreated();

        SeedDatabase();
    }

    private void SeedDatabase()
    {
        _context.Categories.Add(new Category { Id = 1, Name = "Category 1", IsActive = true });
        _context.Organizers.Add(new Organizer { Id = 1, Name = "Organizer 1" });
        _context.SaveChanges();

        _context.Events.Add(new Event
        {
            Id = 1, Title = "Existing Event", Location = "Arena", Capacity = 100, StartUtc = DateTime.UtcNow, EndUtc = DateTime.UtcNow.AddHours(2),
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
        var response = await _client.GetAsync("/api/events");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadFromJsonAsync<List<EventListItemResponse>>();
        Assert.NotNull(content);
        Assert.Single(content!);
    }

    [Fact]
    public async Task Post_Anonymous_Returns401()
    {
        var response = await _client.PostAsJsonAsync("/api/events", new EventCreateRequest());
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Post_AuthenticatedUser_Returns403()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "UserToken");
        var response = await _client.PostAsJsonAsync("/api/events", new EventCreateRequest());
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Post_Admin_ValidRequest_Returns201AndPersists()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "AdminToken");
        
        var start = DateTime.UtcNow;
        var request = new EventCreateRequest 
        { 
            Title = "New Event", Location = "New Arena", Capacity = 100, 
            StartUtc = start, EndUtc = start.AddHours(2), CategoryId = 1, OrganizerId = 1 
        };
        
        var response = await _client.PostAsJsonAsync("/api/events", request);
        
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await response.Content.ReadFromJsonAsync<EventResponse>();
        Assert.NotNull(created);
        Assert.Equal("New Event", created!.Title);
        
        var inDb = _context.Events.Find(created.Id);
        Assert.NotNull(inDb);
    }

    [Fact]
    public async Task Post_Admin_InvalidTime_Returns400()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "AdminToken");
        
        var start = DateTime.UtcNow;
        var request = new EventCreateRequest 
        { 
            Title = "Bad Event", Location = "Arena", Capacity = 100, 
            StartUtc = start, EndUtc = start.AddHours(-1), // End before Start
            CategoryId = 1, OrganizerId = 1 
        };
        
        var response = await _client.PostAsJsonAsync("/api/events", request);
        
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<ProblemDetails>();
        Assert.Contains(problem!.Detail!, "EndUtc must be later than StartUtc");
    }

    [Fact]
    public async Task Post_Admin_DuplicateEvent_Returns409()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "AdminToken");
        
        var existing = _context.Events.First();
        var request = new EventCreateRequest 
        { 
            Title = existing.Title, Location = existing.Location, Capacity = 100, 
            StartUtc = existing.StartUtc, EndUtc = existing.StartUtc.AddHours(1), CategoryId = 1, OrganizerId = 1 
        };
        
        var response = await _client.PostAsJsonAsync("/api/events", request);
        
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<ProblemDetails>();
        Assert.Equal("DUPLICATE_EVENT", problem!.Extensions["errorCode"]?.ToString());
    }

    [Fact]
    public async Task Delete_Admin_NonExistent_Returns404()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "AdminToken");
        
        var response = await _client.DeleteAsync("/api/events/999");
        
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
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
dotnet test evaluation/claude/workspace/PromptEvaluation.slnx --filter "FullyQualifiedName~EventIntegrationTests"
```

**Cleanup Notes**: 
The SQLite in-memory database connection is closed when the factory is disposed, tearing down the database cleanly. The `IClassFixture` scopes the factory to the test class, but `EnsureCreated()` and `EnsureDeleted()` in the constructor/dispose pair ensure each test gets a clean schema and data within that shared connection.
