using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using PromptEvaluation.Api.Contracts;
using PromptEvaluation.Api.Data;
using PromptEvaluation.Api.Models;
using PromptEvaluation.Api.Services;

namespace PromptEvaluation.Tests;

public sealed class ServiceTests
{
    private static readonly DateTime Start = new(2026, 8, 1, 10, 0, 0, DateTimeKind.Utc);

    [Fact]
    public async Task EventCreate_DuplicateCompositeKey_ThrowsConflict()
    {
        await using var fixture = await DatabaseFixture.CreateAsync();
        var service = new EventService(fixture.Context, NullLogger<EventService>.Instance);
        fixture.Context.Categories.Add(new Category { Name = "General", IsActive = true });
        await fixture.Context.SaveChangesAsync();
        var request = EventRequest("Launch");

        await service.CreateAsync(request, CancellationToken.None);

        await Assert.ThrowsAsync<BusinessConflictException>(
            () => service.CreateAsync(request, CancellationToken.None));
        Assert.Single(await fixture.Context.Events.ToListAsync());
    }

    [Fact]
    public async Task EventRead_MissingId_ReturnsNull()
    {
        await using var fixture = await DatabaseFixture.CreateAsync();
        var service = new EventService(fixture.Context, NullLogger<EventService>.Instance);

        var result = await service.GetByIdAsync(404, CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task CategoryCreate_NameDiffersOnlyByCase_ThrowsConflict()
    {
        await using var fixture = await DatabaseFixture.CreateAsync();
        var service = new CategoryService(fixture.Context, NullLogger<CategoryService>.Instance);
        await service.CreateAsync(
            new CategoryCreateRequest { Name = "Music", IsActive = true },
            CancellationToken.None);

        await Assert.ThrowsAsync<BusinessConflictException>(
            () => service.CreateAsync(
                new CategoryCreateRequest { Name = "music", IsActive = true },
                CancellationToken.None));
    }

    [Fact]
    public async Task CategoryDelete_ReferencedCategory_ThrowsConflict()
    {
        await using var fixture = await DatabaseFixture.CreateAsync();
        var category = new Category { Name = "Music", IsActive = true };
        fixture.Context.Add(category);
        await fixture.Context.SaveChangesAsync();
        fixture.Context.Add(new Event
        {
            Title = "Launch",
            Location = "Hall",
            StartUtc = Start,
            EndUtc = Start.AddHours(1),
            Capacity = 100,
            CategoryId = category.Id,
            OrganizerId = 7
        });
        await fixture.Context.SaveChangesAsync();
        var service = new CategoryService(fixture.Context, NullLogger<CategoryService>.Instance);

        await Assert.ThrowsAsync<BusinessConflictException>(
            () => service.DeleteAsync(category.Id, CancellationToken.None));
    }

    [Fact]
    public async Task EventRead_CancelledToken_ThrowsCancellation()
    {
        await using var fixture = await DatabaseFixture.CreateAsync();
        var service = new EventService(fixture.Context, NullLogger<EventService>.Instance);
        using var source = new CancellationTokenSource();
        source.Cancel();

        await Assert.ThrowsAnyAsync<OperationCanceledException>(
            () => service.GetAllAsync(source.Token));
    }

    private static EventCreateRequest EventRequest(string title) => new()
    {
        Title = title,
        Location = "Hall",
        StartUtc = Start,
        EndUtc = Start.AddHours(1),
        Capacity = 100,
        CategoryId = 1,
        OrganizerId = 7
    };

    private sealed class DatabaseFixture : IAsyncDisposable
    {
        private readonly SqliteConnection connection;

        private DatabaseFixture(SqliteConnection connection, EvaluationDbContext context)
        {
            this.connection = connection;
            Context = context;
        }

        public EvaluationDbContext Context { get; }

        public static async Task<DatabaseFixture> CreateAsync()
        {
            var connection = new SqliteConnection("Data Source=:memory:");
            await connection.OpenAsync();
            var options = new DbContextOptionsBuilder<EvaluationDbContext>()
                .UseSqlite(connection)
                .Options;
            var context = new EvaluationDbContext(options);
            await context.Database.EnsureCreatedAsync();
            return new DatabaseFixture(connection, context);
        }

        public async ValueTask DisposeAsync()
        {
            await Context.DisposeAsync();
            await connection.DisposeAsync();
        }
    }
}
