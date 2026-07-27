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
    }
}
