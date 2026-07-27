# Completed Prompt - Template 2: crud-service-event

## Shared project context

```text
Project: PromptEvaluation
Framework: .NET 8
Application type: ASP.NET Core Web API
Architecture: Layered API: controllers, services, EF Core DbContext, DTOs, centralized exception handling
Database: SQLite
ORM: EF Core 8
Test stack: xUnit, Moq, WebApplicationFactory, SQLite in-memory
Existing conventions: Nullable enabled, file-scoped namespaces, PascalCase public members, async methods suffixed Async

Work only within the requested scope. Preserve existing behavior unless a
change is explicitly requested. Do not invent files, methods, packages, or
requirements. Do not expose secrets. First state assumptions and the files you
need to inspect. After implementation, list changed files, verification
commands, risks, and any remaining work.
```

## Task

```text
Act as a senior .NET backend developer. Implement EventService for
IEventService using EvaluationDbContext and EF Core.

Inputs:
- Identifier: int
- Mutable properties: Title, Description, Location, StartUtc, EndUtc, Capacity, CategoryId, OrganizerId
- Uniqueness/business rule: Title, StartUtc, and Location must be unique; EndUtc must be later than StartUtc

Implement GetAllAsync, GetByIdAsync, CreateAsync, UpdateAsync, and DeleteAsync.
Use CancellationToken on every async method.

Constraints:
- Use AsNoTracking for read-only queries.
- Project to response DTOs rather than returning tracked entities.
- Use FindAsync or SingleOrDefaultAsync appropriately; explain the choice.
- Never call Update with an untrusted detached request object.
- Load the existing record, map only allowed properties, and save once.
- Treat a missing record and a uniqueness conflict as typed/domain results or
  documented exceptions that middleware can map to 404/409.
- Log useful identifiers but no secrets or personal data.
- Do not add try/catch merely to log and rethrow.
- Avoid repository abstractions if the project already treats DbContext as the
  unit of work.

Output:
1. Assumptions.
2. Interface signatures if changes are required.
3. Complete service code and target path.
4. DTO/mapping code only if missing.
5. Tests for empty list, found/not found, valid create, conflict, partial
   update protection, delete, and cancellation.
6. Build/test commands and a short performance note.

Acceptance criteria: async database calls are used; reads do not track; over-
posting is prevented; SaveChangesAsync is called only for successful writes.
```
