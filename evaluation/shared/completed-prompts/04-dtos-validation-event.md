# Completed Prompt - Template 4: dtos-validation-event

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
Act as an API contract designer. Create DTOs and validation for Event.

Fields:
Title, Description, Location, StartUtc, EndUtc, Capacity, CategoryId, OrganizerId; responses also contain Id

Rules:
Title required/max 150; Description max 2000; Location required/max 200; Capacity 1-10,000; EndUtc later than StartUtc; positive CategoryId and OrganizerId; clients cannot assign Id

Use DataAnnotations with IValidatableObject for cross-field validation and
manual mapping.

Create separate contracts when their responsibilities differ:
- EventCreateRequest
- EventUpdateRequest
- EventResponse
- EventListItemResponse

Requirements:
- Do not expose internal fields, password hashes, refresh tokens, row-version
  internals, or navigation cycles.
- Distinguish omitted optional values from values that should be cleared.
- Enforce length/range/format rules server-side.
- Use a consistent validation error response compatible with ProblemDetails.
- Prevent clients from assigning protected fields such as Id, OwnerId, Role,
  CreatedAt, or IsApproved.
- Ensure mapping is explicit and testable.

Output:
1. Assumptions about nullability and update semantics.
2. DTO and validator code with target paths.
3. Mapping code.
4. Controller/service integration snippet.
5. Tests for valid boundaries, invalid boundaries, null/empty values, and
   protected-field over-posting.

Acceptance criteria: invalid input produces 400 with useful field errors and no
domain or persistence entity is used as an API request body.
```
