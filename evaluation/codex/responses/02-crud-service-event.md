# Unedited first response - 02 CRUD service (Event)

Assumptions: `EvaluationDbContext` is the unit of work; DTO validation has
already rejected invalid time ranges and capacities. The service still checks
the composite uniqueness rule. Database constraints remain the final
concurrency-safe backstop.

The supplied `EventService`:

- uses `AsNoTracking` and DTO projection for both reads;
- uses `FindAsync([id], cancellationToken)` for tracked writes;
- checks `(Title, StartUtc, Location)` before create/update;
- loads the existing entity and maps only allowlisted fields;
- calls `SaveChangesAsync` once for each successful write;
- returns `false` for missing update/delete and throws a typed
  `BusinessConflictException` for duplicates;
- logs only the created Event identifier.

Target paths:

- `PromptEvaluation.Api/Services/EventService.cs`
- `PromptEvaluation.Api/Services/ServiceContracts.cs`
- `PromptEvaluation.Tests/ServiceTests.cs`

Tests supplied cover missing read, duplicate create, no second write after
conflict, and cancellation. Boundary and every update/delete case listed in the
prompt were not all implemented in this first response.

```powershell
dotnet test evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release --filter "FullyQualifiedName~ServiceTests"
```

Performance note: list reads are server-projected and untracked, but they need
bounded pagination before production-scale use.

