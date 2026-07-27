# Unedited first response — 11 Performance (Event List)

## Identified Bottleneck

1. **Unbounded Result Set (`N+1` / Memory Exhaustion)**: `GetAllAsync` returns `await _context.Events.ToListAsync()`. If the table contains 500k rows, the application will attempt to load 500k entity objects into memory simultaneously. This leads to massive RAM usage (triggering Garbage Collection pauses or `OutOfMemoryException`), high CPU usage for EF Core materialization, and long database lock times or network transfer durations.

## Refactoring Recommendations

1. **Offset Pagination (Skip/Take)**: The simplest solution is to paginate the results. `Skip(page * size).Take(size)`. 
   - *Pros*: Easy to implement, supports jumping to a specific page.
   - *Cons*: Slower for deep pages (database still counts skipped rows).
2. **Keyset Pagination (Cursor-based)**: `Where(e => e.Id > lastId).Take(size)`. 
   - *Pros*: Extremely fast regardless of depth.
   - *Cons*: Cannot jump to specific pages, requires deterministic sorting (usually by Id or Date+Id).

## Code Implementation (Keyset Pagination)

We will use keyset pagination (cursor-based) for optimal performance over 500k rows.

**Request DTO**
```csharp
public class EventListQuery
{
    // The cursor - the ID of the last event seen. 0 for first page.
    public int LastSeenId { get; set; } = 0;
    
    // Page size
    public int Limit { get; set; } = 50;
}
```

**Service Modification**
```csharp
public async Task<IEnumerable<EventListItemResponse>> GetPaginatedAsync(
    EventListQuery query, CancellationToken cancellationToken = default)
{
    // Ensure limit is reasonable
    var limit = Math.Clamp(query.Limit, 1, 100);

    var dbQuery = _context.Events.AsNoTracking();

    if (query.LastSeenId > 0)
    {
        // Keyset pagination clause
        dbQuery = dbQuery.Where(e => e.Id > query.LastSeenId);
    }

    return await dbQuery
        .OrderBy(e => e.Id) // Deterministic sort matching the cursor
        .Take(limit)
        .Select(e => new EventListItemResponse
        {
            Id = e.Id,
            Title = e.Title,
            Location = e.Location,
            StartUtc = e.StartUtc,
            EndUtc = e.EndUtc
        })
        .ToListAsync(cancellationToken);
}
```

**Controller Modification**
```csharp
[HttpGet]
[AllowAnonymous]
public async Task<ActionResult<IEnumerable<EventListItemResponse>>> GetAllAsync(
    [FromQuery] EventListQuery query, CancellationToken cancellationToken)
{
    var events = await _eventService.GetPaginatedAsync(query, cancellationToken);
    return Ok(events);
}
```

## Additional Optimizations Applied

1. **`AsNoTracking()`**: Included in the code block above. When listing records, EF Core does not need to attach them to the Change Tracker.
2. **Projection (`Select`)**: Instead of fetching the entire `Event` (including descriptions which might be large strings), we project directly into `EventListItemResponse`. This narrows the SQL `SELECT` clause to only the requested columns, saving database memory, network bandwidth, and application memory.
