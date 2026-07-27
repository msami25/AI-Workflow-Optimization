using System.Net;
using System.Net.Http.Json;
using PromptEvaluation.Api.Contracts;

namespace PromptEvaluation.Tests;

public sealed class IntegrationTests
{
    [Theory]
    [InlineData("/api/events")]
    [InlineData("/api/categories")]
    public async Task Get_Anonymous_ReturnsOk(string path)
    {
        using var factory = new ApiFactory();
        using var client = factory.CreateClient();

        var response = await client.GetAsync(path);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Theory]
    [InlineData("/api/events")]
    [InlineData("/api/categories")]
    public async Task Post_Anonymous_ReturnsUnauthorized(string path)
    {
        using var factory = new ApiFactory();
        using var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync(path, new { });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Theory]
    [InlineData("/api/events")]
    [InlineData("/api/categories")]
    public async Task Post_NonAdmin_ReturnsForbidden(string path)
    {
        using var factory = new ApiFactory();
        using var client = factory.CreateClient();
        client.AuthenticateAs("User");

        var response = await client.PostAsJsonAsync(path, new { });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task PostCategory_AdminValidRequest_ReturnsCreated()
    {
        using var factory = new ApiFactory();
        using var client = factory.CreateClient();
        client.AuthenticateAs("Admin");

        var response = await client.PostAsJsonAsync(
            "/api/categories",
            new CategoryCreateRequest { Name = "Music", IsActive = true });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<CategoryResponse>();
        Assert.Equal("Music", body?.Name);
        Assert.NotNull(response.Headers.Location);
    }

    [Fact]
    public async Task PostEvent_AdminInvalidRequest_ReturnsValidationProblem()
    {
        using var factory = new ApiFactory();
        using var client = factory.CreateClient();
        client.AuthenticateAs("Admin");
        var start = new DateTime(2026, 8, 1, 10, 0, 0, DateTimeKind.Utc);

        var response = await client.PostAsJsonAsync(
            "/api/events",
            new EventCreateRequest
            {
                Title = "Launch",
                Location = "Hall",
                StartUtc = start,
                EndUtc = start,
                Capacity = 100,
                CategoryId = 1,
                OrganizerId = 7
            });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);
    }
}
