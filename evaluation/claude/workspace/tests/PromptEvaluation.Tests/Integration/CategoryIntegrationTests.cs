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
        var inDb = _context.Categories.Find(created!.Id);
        Assert.NotNull(inDb);
    }

    [Fact]
    public async Task Delete_Admin_ReferencedCategory_Returns409()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "AdminToken");
        var response = await _client.DeleteAsync("/api/categories/1");
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }
}
