# Unedited first response — 09 Unit Tests (Event)

## Assumptions
- `EventService` depends on `EvaluationDbContext` and `ILogger<EventService>`.
- `EventCreateRequest` and `EventUpdateRequest` DTOs exist.
- `BusinessConflictException` is thrown on uniqueness collisions (`Title` + `StartUtc` + `Location`).
- `ValidationException` is thrown if `EndUtc <= StartUtc`.
- `EntityNotFoundException` is thrown on updating/deleting non-existent events.

## Behavior-to-Test Matrix

| Method | Scenario | Expected Result |
|---|---|---|
| `GetAllAsync` | Empty database | Returns empty list |
| `GetByIdAsync` | Event exists | Returns event response |
| `GetByIdAsync` | Event does not exist | Returns null |
| `CreateAsync` | Valid request | Creates event, returns response |
| `CreateAsync` | Duplicate (Title+StartUtc+Location) | Throws `BusinessConflictException` |
| `CreateAsync` | `EndUtc` <= `StartUtc` | Throws `ValidationException` |
| `UpdateAsync` | Safe update (valid request) | Updates event properties |
| `UpdateAsync` | Id does not exist | Throws `EntityNotFoundException` |
| `DeleteAsync` | Existing event | Deletes event |
| `DeleteAsync` | Non-existent event | Throws `EntityNotFoundException` |
| `CreateAsync` | CancellationToken cancelled | Throws `OperationCanceledException` |

## Complete Test Class

**Target path**: `tests/PromptEvaluation.Tests/Services/EventServiceTests.cs`

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
using System.ComponentModel.DataAnnotations;

namespace PromptEvaluation.Tests.Services;

public class EventServiceTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly EvaluationDbContext _context;
    private readonly EventService _service;

    public EventServiceTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<EvaluationDbContext>()
            .UseSqlite(_connection)
            .Options;

        _context = new EvaluationDbContext(options);
        _context.Database.EnsureCreated();

        _service = new EventService(
            _context,
            Mock.Of<ILogger<EventService>>());
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
    public async Task GetByIdAsync_ExistingEvent_ReturnsEvent()
    {
        _context.Events.Add(new Event
        {
            Title = "Concert", Location = "Arena", StartUtc = DateTime.UtcNow, EndUtc = DateTime.UtcNow.AddHours(2), Capacity = 100
        });
        await _context.SaveChangesAsync();

        var result = await _service.GetByIdAsync(1);

        Assert.NotNull(result);
        Assert.Equal("Concert", result!.Title);
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
        var start = DateTime.UtcNow;
        var request = new EventCreateRequest
        {
            Title = new string('T', 150), Location = new string('L', 200), StartUtc = start, EndUtc = start.AddHours(2), Capacity = 10000, CategoryId = 1, OrganizerId = 1
        };

        var result = await _service.CreateAsync(request);

        Assert.True(result.Id > 0);
        Assert.Single(await _context.Events.ToListAsync());
    }

    [Fact]
    public async Task CreateAsync_DuplicateTitleStartLocation_ThrowsConflict()
    {
        var start = DateTime.UtcNow;
        _context.Events.Add(new Event
        {
            Title = "Concert", Location = "Arena", StartUtc = start, EndUtc = start.AddHours(2), Capacity = 100, CategoryId = 1, OrganizerId = 1
        });
        await _context.SaveChangesAsync();

        var request = new EventCreateRequest
        {
            Title = "Concert", Location = "Arena", StartUtc = start, EndUtc = start.AddHours(3), Capacity = 200, CategoryId = 2, OrganizerId = 2
        };

        await Assert.ThrowsAsync<BusinessConflictException>(
            () => _service.CreateAsync(request));
            
        // Verify no side effects (write did not occur after validation fail)
        Assert.Single(await _context.Events.ToListAsync());
    }

    [Fact]
    public async Task CreateAsync_InvalidTimeRange_ThrowsValidationException()
    {
        var start = DateTime.UtcNow;
        var request = new EventCreateRequest
        {
            Title = "Concert", Location = "Arena", StartUtc = start, EndUtc = start.AddHours(-1), Capacity = 100
        };

        await Assert.ThrowsAsync<ValidationException>(
            () => _service.CreateAsync(request));
            
        Assert.Empty(await _context.Events.ToListAsync());
    }

    [Fact]
    public async Task UpdateAsync_SafeUpdate_UpdatesProperties()
    {
        var start = DateTime.UtcNow;
        _context.Events.Add(new Event
        {
            Title = "Concert", Location = "Arena", StartUtc = start, EndUtc = start.AddHours(2), Capacity = 100, CategoryId = 1, OrganizerId = 1
        });
        await _context.SaveChangesAsync();

        await _service.UpdateAsync(1, new EventUpdateRequest
        {
            Title = "Updated Concert", Location = "New Arena", StartUtc = start, EndUtc = start.AddHours(3), Capacity = 200, CategoryId = 2, OrganizerId = 2
        });

        var updated = await _context.Events.FindAsync(1);
        Assert.Equal("Updated Concert", updated!.Title);
        Assert.Equal("New Arena", updated.Location);
    }

    [Fact]
    public async Task UpdateAsync_NonExistentId_ThrowsNotFound()
    {
        var start = DateTime.UtcNow;
        await Assert.ThrowsAsync<EntityNotFoundException>(
            () => _service.UpdateAsync(999, new EventUpdateRequest
            {
                Title = "X", Location = "Y", StartUtc = start, EndUtc = start.AddHours(1)
            }));
    }

    [Fact]
    public async Task DeleteAsync_ExistingEvent_Deletes()
    {
        _context.Events.Add(new Event
        {
            Title = "Concert", Location = "Arena", StartUtc = DateTime.UtcNow, EndUtc = DateTime.UtcNow.AddHours(2), Capacity = 100
        });
        await _context.SaveChangesAsync();

        await _service.DeleteAsync(1);

        Assert.Empty(await _context.Events.ToListAsync());
    }

    [Fact]
    public async Task DeleteAsync_NonExistentId_ThrowsNotFound()
    {
        await Assert.ThrowsAsync<EntityNotFoundException>(
            () => _service.DeleteAsync(999));
    }

    [Fact]
    public async Task CreateAsync_Cancellation_ThrowsOperationCanceled()
    {
        var cts = new CancellationTokenSource();
        cts.Cancel();

        await Assert.ThrowsAnyAsync<OperationCanceledException>(
            () => _service.CreateAsync(
                new EventCreateRequest { Title = "X", Location = "Y", StartUtc = DateTime.UtcNow, EndUtc = DateTime.UtcNow.AddHours(1) }, cts.Token));
    }
}
```

## Mocking Explanation
- The database uses an actual SQLite in-memory connection rather than mocked `DbSet`s to test EF Core behavior natively.
- `ILogger` is mocked since we do not assert on logs.

## Test Command
```powershell
dotnet test evaluation/claude/workspace/PromptEvaluation.slnx --filter "FullyQualifiedName~EventServiceTests"
```

## Gaps Requiring Integration Tests
These tests do not cover:
1. Controller-level validation (e.g., `DataAnnotations` returning 400 Bad Request).
2. Global exception handler mapping domain exceptions to HTTP responses (404, 409).
3. JWT Authentication and `[Authorize(Roles="Admin")]` enforcement.
