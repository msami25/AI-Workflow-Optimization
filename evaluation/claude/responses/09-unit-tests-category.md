# Unedited first response — 09 Unit Tests (Category)

## Assumptions
- `CategoryService` depends on `EvaluationDbContext` and `ILogger<CategoryService>`.
- `CategoryCreateRequest` and `CategoryUpdateRequest` DTOs exist.
- `BusinessConflictException` is thrown on name collisions or deleting referenced categories.
- `EntityNotFoundException` is thrown on updating/deleting non-existent categories.

## Behavior-to-Test Matrix

| Method | Scenario | Expected Result |
|---|---|---|
| `GetAllAsync` | Empty database | Returns empty list |
| `GetByIdAsync` | Category exists | Returns category response |
| `GetByIdAsync` | Category does not exist | Returns null |
| `CreateAsync` | Valid request | Creates category, returns response |
| `CreateAsync` | Name already exists (case-insensitive) | Throws `BusinessConflictException` |
| `UpdateAsync` | Valid request | Updates category properties |
| `UpdateAsync` | Name exists on another category | Throws `BusinessConflictException` |
| `UpdateAsync` | Id does not exist | Throws `EntityNotFoundException` |
| `DeleteAsync` | Unreferenced category | Deletes category |
| `DeleteAsync` | Category has referenced events | Throws `BusinessConflictException` |
| `CreateAsync` | CancellationToken cancelled | Throws `OperationCanceledException` |

## Complete Test Class

**Target path**: `tests/PromptEvaluation.Tests/Services/CategoryServiceTests.cs`

```csharp
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using PromptEvaluation.Api.Data;
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Exceptions;
using PromptEvaluation.Api.Models;
using PromptEvaluation.Api.Services;

namespace PromptEvaluation.Tests.Services;

public class CategoryServiceTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly EvaluationDbContext _context;
    private readonly CategoryService _service;

    public CategoryServiceTests()
    {
        // Use a relational SQLite in-memory database to properly test EF Core behavior
        // (like case-insensitive queries, constraints) instead of the EF InMemory provider
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<EvaluationDbContext>()
            .UseSqlite(_connection)
            .Options;

        _context = new EvaluationDbContext(options);
        _context.Database.EnsureCreated();

        // No-op logger
        _service = new CategoryService(
            _context,
            Mock.Of<ILogger<CategoryService>>());
    }

    public void Dispose()
    {
        _context.Dispose();
        _connection.Dispose();
    }

    [Fact]
    public async Task GetAllAsync_EmptyDatabase_ReturnsEmptyList()
    {
        var result = await _service.GetAllAsync();
        Assert.Empty(result);
    }

    [Fact]
    public async Task GetByIdAsync_ExistingCategory_ReturnsCategory()
    {
        _context.Categories.Add(new Category { Name = "Music", IsActive = true });
        await _context.SaveChangesAsync();

        var result = await _service.GetByIdAsync(1);

        Assert.NotNull(result);
        Assert.Equal("Music", result!.Name);
    }

    [Fact]
    public async Task GetByIdAsync_NonExistentId_ReturnsNull()
    {
        var result = await _service.GetByIdAsync(999);
        Assert.Null(result);
    }

    [Fact]
    public async Task CreateAsync_ValidRequest_CreatesAndReturns()
    {
        var request = new CategoryCreateRequest { Name = "Music", Description = new string('A', 500), IsActive = true };

        var result = await _service.CreateAsync(request);

        Assert.Equal("Music", result.Name);
        Assert.True(result.Id > 0);
        
        var inDb = await _context.Categories.SingleAsync();
        Assert.Equal("Music", inDb.Name);
    }

    [Fact]
    public async Task CreateAsync_DuplicateNameCaseInsensitive_ThrowsConflict()
    {
        _context.Categories.Add(new Category { Name = "MUSIC", IsActive = true });
        await _context.SaveChangesAsync();

        var request = new CategoryCreateRequest { Name = "music" };

        await Assert.ThrowsAsync<BusinessConflictException>(
            () => _service.CreateAsync(request));
            
        // Verify no side effect occurred
        Assert.Single(await _context.Categories.ToListAsync());
    }

    [Fact]
    public async Task UpdateAsync_ExistingCategory_UpdatesProperties()
    {
        _context.Categories.Add(new Category { Name = "Music", IsActive = true });
        await _context.SaveChangesAsync();

        await _service.UpdateAsync(1, new CategoryUpdateRequest
        {
            Name = "Live Music",
            IsActive = false
        });

        var updated = await _context.Categories.FindAsync(1);
        Assert.Equal("Live Music", updated!.Name);
        Assert.False(updated.IsActive);
    }

    [Fact]
    public async Task UpdateAsync_NonExistentId_ThrowsNotFound()
    {
        await Assert.ThrowsAsync<EntityNotFoundException>(
            () => _service.UpdateAsync(999, new CategoryUpdateRequest { Name = "X" }));
    }

    [Fact]
    public async Task DeleteAsync_UnreferencedCategory_Deletes()
    {
        _context.Categories.Add(new Category { Name = "Music", IsActive = true });
        await _context.SaveChangesAsync();

        await _service.DeleteAsync(1);

        Assert.Empty(await _context.Categories.ToListAsync());
    }

    [Fact]
    public async Task DeleteAsync_ReferencedCategory_ThrowsConflict()
    {
        var category = new Category { Name = "Music", IsActive = true };
        _context.Categories.Add(category);
        _context.Organizers.Add(new Organizer { Name = "Org1" });
        await _context.SaveChangesAsync();

        _context.Events.Add(new Event
        {
            Title = "Concert",
            Location = "Arena",
            StartUtc = DateTime.UtcNow,
            EndUtc = DateTime.UtcNow.AddHours(2),
            Capacity = 100,
            CategoryId = 1,
            OrganizerId = 1
        });
        await _context.SaveChangesAsync();

        await Assert.ThrowsAsync<BusinessConflictException>(
            () => _service.DeleteAsync(1));
    }

    [Fact]
    public async Task CreateAsync_Cancellation_ThrowsOperationCanceled()
    {
        var cts = new CancellationTokenSource();
        cts.Cancel();

        await Assert.ThrowsAnyAsync<OperationCanceledException>(
            () => _service.CreateAsync(
                new CategoryCreateRequest { Name = "Music" }, cts.Token));
    }
}
```

## Mocking Explanation
- The database uses an actual SQLite in-memory connection rather than mocked `DbSet`s. Mocking EF Core sets is an anti-pattern as it does not test LINQ translation, referential constraints, or uniqueness.
- `ILogger` is mocked using `Mock.Of<ILogger<CategoryService>>()` since we do not assert on logs in these tests; it merely fulfills the dependency.

## Test Command
```powershell
dotnet test evaluation/claude/workspace/PromptEvaluation.slnx --filter "FullyQualifiedName~CategoryServiceTests"
```

## Gaps Requiring Integration Tests
These tests do not cover:
1. Controller routing and HTTP status code mappings.
2. Authorization attribute enforcement.
3. Cross-request concurrency (which requires full HTTP pipeline and shared database state).
