# Unedited first response — 05 Mapping (Event)

## Assumptions

1. The project uses manual mapping via extension methods (e.g., `static class EventMapper`).
2. Protected members (`Id`, navigations, etc.) are omitted from requests and never mapped from requests to entities.
3. EF Core projection will use a `Select` expression for list views to avoid pulling full entities.

---

## Mapping Table

| Source | Destination | Transformation / Rule |
|---|---|---|
| `EventCreateRequest` | `Event` | Map Title, Description, Location, StartUtc, EndUtc, Capacity, CategoryId, OrganizerId. Ignore Id. |
| `EventUpdateRequest` | `Event` | Update Title, Description, Location, StartUtc, EndUtc, Capacity, CategoryId, OrganizerId. Ignore Id. |
| `Event` | `EventResponse` | Map all primitive fields directly. Compute `DurationMinutes = (EndUtc - StartUtc).TotalMinutes`. |
| `Event` | `EventListItemResponse` | Map Id, Title, Location, StartUtc, EndUtc. Compute `CategoryName = Category.Name`. Compute `RemainingCapacity = Capacity` (assuming no tickets sold logic yet). |

---

## Mapping Profile / Helper Code

**Target path**: `src/PromptEvaluation.Api/Mapping/EventMapper.cs`

```csharp
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Models;
using System.Linq.Expressions;

namespace PromptEvaluation.Api.Mapping;

public static class EventMapper
{
    // Direction: Request -> Entity (Create)
    public static Event ToEntity(this EventCreateRequest request)
    {
        return new Event
        {
            // Id and navigation properties are protected and not mapped
            Title = request.Title,
            Description = request.Description,
            Location = request.Location,
            StartUtc = request.StartUtc,
            EndUtc = request.EndUtc,
            Capacity = request.Capacity,
            CategoryId = request.CategoryId,
            OrganizerId = request.OrganizerId
        };
    }

    // Direction: Request -> Entity (Update)
    public static void UpdateEntity(this EventUpdateRequest request, Event entity)
    {
        // Update only allowed fields, avoiding over-posting of Id or navigation links
        entity.Title = request.Title;
        entity.Description = request.Description;
        entity.Location = request.Location;
        entity.StartUtc = request.StartUtc;
        entity.EndUtc = request.EndUtc;
        entity.Capacity = request.Capacity;
        entity.CategoryId = request.CategoryId;
        entity.OrganizerId = request.OrganizerId;
    }

    // Direction: Entity -> Response (Single detail)
    public static EventResponse ToResponse(this Event entity)
    {
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

    // Query Projection: Entity -> Response (List projection)
    // Exposes an Expression tree so EF Core can translate it to SQL
    public static Expression<Func<Event, EventListItemResponse>> ListProjection => 
        e => new EventListItemResponse
        {
            Id = e.Id,
            Title = e.Title,
            Location = e.Location,
            StartUtc = e.StartUtc,
            EndUtc = e.EndUtc,
            CategoryName = e.Category != null ? e.Category.Name : string.Empty,
            RemainingCapacity = e.Capacity
        };
}
```

---

## Query Projection Example

In the `IEventService.GetAllAsync` implementation:

```csharp
public async Task<IEnumerable<EventListItemResponse>> GetAllAsync(CancellationToken cancellationToken)
{
    return await _context.Events
        .AsNoTracking()
        // EF Core translates this directly to SQL, selecting only required columns
        .Select(EventMapper.ListProjection) 
        .ToListAsync(cancellationToken);
}
```

---

## Tests

**Target path**: `tests/PromptEvaluation.Tests/Mapping/EventMapperTests.cs`

```csharp
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Mapping;
using PromptEvaluation.Api.Models;

namespace PromptEvaluation.Tests.Mapping;

public class EventMapperTests
{
    [Fact]
    public void ToEntity_MapsAllowedFields_IgnoresProtectedFields()
    {
        var request = new EventCreateRequest
        {
            Title = "Test", Description = "Desc", Location = "Loc", 
            StartUtc = DateTime.UtcNow, EndUtc = DateTime.UtcNow.AddHours(2), 
            Capacity = 100, CategoryId = 1, OrganizerId = 1
        };

        var entity = request.ToEntity();

        Assert.Equal("Test", entity.Title);
        Assert.Equal(0, entity.Id); // Protected field not mapped
        Assert.Null(entity.Category); // Navigation property untouched
    }

    [Fact]
    public void ToResponse_CalculatesDurationMinutes()
    {
        var start = DateTime.UtcNow;
        var entity = new Event
        {
            Id = 1, Title = "Test", Location = "Loc", 
            StartUtc = start, EndUtc = start.AddHours(2.5), 
            Capacity = 100
        };

        var response = entity.ToResponse();

        Assert.Equal(150, response.DurationMinutes);
    }
    
    [Fact]
    public void ListProjection_MapsCategoryName_And_RemainingCapacity()
    {
        var entity = new Event
        {
            Id = 1, Title = "Test", Location = "Loc", Capacity = 100,
            Category = new Category { Name = "Music" }
        };

        var func = EventMapper.ListProjection.Compile();
        var response = func(entity);

        Assert.Equal("Music", response.CategoryName);
        Assert.Equal(100, response.RemainingCapacity);
    }
}
```

---

## Commands

```powershell
dotnet test evaluation/claude/workspace/PromptEvaluation.slnx --filter "FullyQualifiedName~EventMapperTests"
```
