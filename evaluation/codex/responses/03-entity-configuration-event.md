# Unedited first response - 03 entity/configuration (Event)

Assumptions: Category and Organizer already exist with integer keys; the
project uses SQLite for evaluation and UTC `DateTime` values. Organizer was not
materialized in the isolated harness, so its foreign key cannot honestly be
claimed as compiled.

Proposed model/configuration:

- required Title (150) and Location (200), optional Description (2000);
- Capacity check constraint from 1 through 10,000;
- time-range check constraint requiring `EndUtc > StartUtc`;
- unique index on `(Title, StartUtc, Location)`;
- required Category and Organizer relationships with `DeleteBehavior.Restrict`;
- no cascade deletion of events.

Minimal context change:

```csharp
public DbSet<Event> Events => Set<Event>();
modelBuilder.ApplyConfiguration(new EventConfiguration());
```

Migration plan:

1. Add nullable foreign-key columns first if existing rows require backfill.
2. Backfill and validate Category/Organizer references.
3. Add non-null constraints, checks, indexes, and foreign keys.
4. Review generated SQL and test rollback on a database copy.
5. Do not hand-edit the generated migration.

```powershell
dotnet ef migrations add AddEvent --project evaluation/codex/workspace/PromptEvaluation.Api/PromptEvaluation.Api.csproj
dotnet ef database update --project evaluation/codex/workspace/PromptEvaluation.Api/PromptEvaluation.Api.csproj
```

Relational tests should prove duplicate composite keys, capacity/time checks,
and restricted Category/Organizer deletion using SQLite or the production
provider. This response was design-reviewed only; no migration was generated.

