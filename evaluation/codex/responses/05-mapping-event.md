# Unedited first response - 05 mapping (Event)

Assumption: the repository uses manual mapping, so no AutoMapper package or
profile should be introduced.

| Source | Destination | Transformation |
| --- | --- | --- |
| create/update Title | Event.Title | trim; never maps Id |
| create/update fields | Event mutable fields | explicit allowlist |
| Event fields | EventResponse | direct scalar projection |
| EndUtc, StartUtc | DurationMinutes | `EF.Functions.DateDiffMinute` only on providers that translate it; otherwise omit from SQL projection |
| Category.Name | CategoryName | projected join/navigation scalar |

The implemented service uses an expression-compatible scalar projection for
the existing response. For a richer list contract, use an expression:

```csharp
query.Select(e => new EventListItemResponse(
    e.Id, e.Title, e.Location, e.StartUtc, e.EndUtc,
    e.Category!.Name, e.Capacity));
```

Protected members (`Id`, navigations, and server state) are never assigned from
requests. Reverse mapping is not provided. Configuration validation is not
applicable to manual mapping; tests should instead prove protected fields
remain unchanged and execute the projection against SQLite. Those dedicated
tests were not supplied in this first response.

