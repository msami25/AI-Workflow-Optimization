# Unedited first response — 02 CRUD Service (Event)

## Assumptions

1. **EvaluationDbContext** exists with `DbSet<Event> Events`, `DbSet<Category> Categories`, `DbSet<Organizer> Organizers`.
2. **Event** entity has `Id`, `Title`, `Description`, `Location`, `StartUtc`, `EndUtc`, `Capacity`, `CategoryId`, `OrganizerId`, and navigation `Category`.
3. **DTOs**: `EventCreateRequest`, `EventUpdateRequest`, `EventResponse`, `EventListItemResponse` exist.
4. **Exception types**: `ValidationException` (for time range), `EntityNotFoundException`, and `BusinessConflictException` (for uniqueness).
5. The project treats `DbContext` as the unit of work; no separate repository abstraction.
6. **Files to inspect**: `EvaluationDbContext.cs`, `Event.cs`, Event DTOs, `Program.cs`.

---

## Interface Signatures

**Target path**: `src/PromptEvaluation.Api/Services/IEventService.cs`

```csharp
using PromptEvaluation.Api.DTOs;

namespace PromptEvaluation.Api.Services;

public interface IEventService
{
    Task<IEnumerable<EventListItemResponse>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<EventResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<EventResponse> CreateAsync(EventCreateRequest request, CancellationToken cancellationToken = default);
    Task UpdateAsync(int id, EventUpdateRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(int id, CancellationToken cancellationToken = default);
}
```

---

## Complete Service Code

**Target path**: `src/PromptEvaluation.Api/Services/EventService.cs`

**Choice: `SingleOrDefaultAsync` vs `FindAsync`**
- `FindAsync` is used for update/delete because it leverages the identity map (the entity will be tracked for `SaveChangesAsync`).
- `SingleOrDefaultAsync` with `AsNoTracking` is used for reads to avoid polluting the change tracker.

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using PromptEvaluation.Api.Data;
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Exceptions;
using PromptEvaluation.Api.Models;
using System.ComponentModel.DataAnnotations;

namespace PromptEvaluation.Api.Services;

public class EventService : IEventService
{
    private readonly EvaluationDbContext _context;
    private readonly ILogger<EventService> _logger;

    public EventService(EvaluationDbContext context, ILogger<EventService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<IEnumerable<EventListItemResponse>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        return await _context.Events
            .AsNoTracking()
            .Include(e => e.Category)
            .OrderBy(e => e.StartUtc)
            .ThenBy(e => e.Id)
            .Select(e => new EventListItemResponse
            {
                Id = e.Id,
                Title = e.Title,
                Location = e.Location,
                StartUtc = e.StartUtc,
                EndUtc = e.EndUtc,
                CategoryName = e.Category != null ? e.Category.Name : string.Empty,
                RemainingCapacity = e.Capacity
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<EventResponse?> GetByIdAsync(
        int id, CancellationToken cancellationToken = default)
    {
        return await _context.Events
            .AsNoTracking()
            .Where(e => e.Id == id)
            .Select(e => new EventResponse
            {
                Id = e.Id,
                Title = e.Title,
                Description = e.Description,
                Location = e.Location,
                StartUtc = e.StartUtc,
                EndUtc = e.EndUtc,
                Capacity = e.Capacity,
                CategoryId = e.CategoryId,
                OrganizerId = e.OrganizerId,
                DurationMinutes = (e.EndUtc - e.StartUtc).TotalMinutes
            })
            .SingleOrDefaultAsync(cancellationToken);
    }

    public async Task<EventResponse> CreateAsync(
        EventCreateRequest request, CancellationToken cancellationToken = default)
    {
        if (request.EndUtc <= request.StartUtc)
        {
            throw new ValidationException("EndUtc must be later than StartUtc.");
        }

        var duplicate = await _context.Events
            .AsNoTracking()
            .AnyAsync(e =>
                e.Title == request.Title &&
                e.StartUtc == request.StartUtc &&
                e.Location == request.Location,
                cancellationToken);

        if (duplicate)
        {
            _logger.LogWarning("Event uniqueness conflict: Title={Title}, StartUtc={StartUtc}, Location={Location}",
                request.Title, request.StartUtc, request.Location);
            throw new BusinessConflictException(
                "An event with the same Title, StartUtc, and Location already exists.",
                "DUPLICATE_EVENT");
        }

        var entity = new Event
        {
            Title = request.Title,
            Description = request.Description,
            Location = request.Location,
            StartUtc = request.StartUtc,
            EndUtc = request.EndUtc,
            Capacity = request.Capacity,
            CategoryId = request.CategoryId,
            OrganizerId = request.OrganizerId
        };

        _context.Events.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Created event {EventId}", entity.Id);

        return new EventResponse
        {
            Id = entity.Id,
            Title = entity.Title,
            Description = entity.Description,
            Location = entity.Location,
            StartUtc = entity.StartUtc,
            EndUtc = entity.EndUtc,
            Capacity = entity.Capacity,
            CategoryId = entity.CategoryId,
            OrganizerId = entity.OrganizerId,
            DurationMinutes = (entity.EndUtc - entity.StartUtc).TotalMinutes
        };
    }

    public async Task UpdateAsync(
        int id, EventUpdateRequest request, CancellationToken cancellationToken = default)
    {
        if (request.EndUtc <= request.StartUtc)
        {
            throw new ValidationException("EndUtc must be later than StartUtc.");
        }

        var entity = await _context.Events.FindAsync(new object[] { id }, cancellationToken);
        if (entity is null)
        {
            throw new EntityNotFoundException(nameof(Event), id);
        }

        var duplicate = await _context.Events
            .AsNoTracking()
            .AnyAsync(e =>
                e.Id != id &&
                e.Title == request.Title &&
                e.StartUtc == request.StartUtc &&
                e.Location == request.Location,
                cancellationToken);

        if (duplicate)
        {
            throw new BusinessConflictException(
                "An event with the same Title, StartUtc, and Location already exists.",
                "DUPLICATE_EVENT");
        }

        // Map only allowed properties — prevents over-posting
        entity.Title = request.Title;
        entity.Description = request.Description;
        entity.Location = request.Location;
        entity.StartUtc = request.StartUtc;
        entity.EndUtc = request.EndUtc;
        entity.Capacity = request.Capacity;
        entity.CategoryId = request.CategoryId;
        entity.OrganizerId = request.OrganizerId;

        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Updated event {EventId}", id);
    }

    public async Task DeleteAsync(
        int id, CancellationToken cancellationToken = default)
    {
        var entity = await _context.Events.FindAsync(new object[] { id }, cancellationToken);
        if (entity is null)
        {
            throw new EntityNotFoundException(nameof(Event), id);
        }

        _context.Events.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Deleted event {EventId}", id);
    }
}
```

---

## DTO/Mapping Code

DTOs use explicit manual mapping within the service methods (no AutoMapper). This is visible in the `Select` projections for reads and explicit property assignment for writes. No additional mapping code is needed.

---

## Tests

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
            Title = "Concert", Location = "Arena", StartUtc = start, EndUtc = start.AddHours(2), Capacity = 100, CategoryId = 1, OrganizerId = 1
        };

        var result = await _service.CreateAsync(request);

        Assert.Equal("Concert", result.Title);
        Assert.True(result.Id > 0);
        Assert.Equal(120, result.DurationMinutes);
        Assert.Single(await _context.Events.ToListAsync());
    }

    [Fact]
    public async Task CreateAsync_Duplicate_ThrowsConflict()
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
    }

    [Fact]
    public async Task UpdateAsync_ExistingEvent_UpdatesProperties()
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
        Assert.Equal(200, updated.Capacity);
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

---

## Build/Test Commands

```powershell
dotnet build evaluation/claude/workspace/PromptEvaluation.slnx --configuration Release
dotnet test evaluation/claude/workspace/PromptEvaluation.slnx --configuration Release --filter "FullyQualifiedName~EventServiceTests"
```

## Performance Note

- `AsNoTracking` on read queries avoids identity-map overhead.
- The `GetAllAsync` list mapping projects only needed fields using `Select`, allowing EF Core to fetch only those columns instead of complete records, mitigating over-fetching.

---

## Changed Files

| File | Action |
|------|--------|
| `src/PromptEvaluation.Api/Services/IEventService.cs` | Created |
| `src/PromptEvaluation.Api/Services/EventService.cs` | Created |
| `tests/PromptEvaluation.Tests/Services/EventServiceTests.cs` | Created |

## Risks

- The `GetAllAsync` method currently returns all events unconditionally; it needs pagination as the dataset grows.
- Hardcoded string error codes should be extracted to constants.

## Remaining Work

- Pagination on `GetAllAsync`.
