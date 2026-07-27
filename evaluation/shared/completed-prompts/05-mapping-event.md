# Completed Prompt - Template 5: mapping-event

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
Act as a .NET mapping specialist. Implement manual mappings between:

Sources: EventCreateRequest, EventUpdateRequest, Event
Destinations: Event, EventResponse, EventListItemResponse
Protected destination members: Id and all server-controlled persistence/navigation members
Computed/renamed fields: Event.DurationMinutes = (EndUtc - StartUtc).TotalMinutes in response mapping; CategoryName from Category.Name for list projection

Requirements:
- Follow the mapping approach already used by the repository.
- Never map protected members from client-controlled request DTOs.
- Make reverse mapping explicit; do not use ReverseMap when directions have
  different security rules.
- Handle nested objects and null values without producing reference cycles.
- For EF Core list queries, prefer a server-side projection that selects only
  required response fields.
- Do not silently ignore a destination member without documenting why.

Output:
1. Mapping table: source field -> destination field -> transformation.
2. Complete profile/helper code with target path.
3. Query projection example.
4. Configuration validation test plus tests for protected and computed fields.
5. Commands to run the tests.

Acceptance criteria: configuration validation passes; protected fields cannot
be overwritten; list mapping can be translated by EF Core when required.
```
