# Completed Prompt - Template 10: integration-tests-event

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
Act as an ASP.NET Core integration-test specialist. Add xUnit integration tests
using WebApplicationFactory for:

Endpoints: GET/POST/PUT/DELETE /api/events
Authorization cases: anonymous GET succeeds; anonymous write is 401; authenticated non-Admin write is 403; Admin write reaches validation/business logic
Relational test provider: SQLite in-memory
Seed data: one Category, one Organizer, one existing Event, plus deterministic duplicate and not-found identifiers
External services to replace: authentication handler and system clock; no external network calls

Requirements:
- Reuse the existing test factory if present.
- Isolate database state per test or test class and make seeds deterministic.
- Prefer a relational provider when query translation, indexes, constraints, or
  transactions matter; explain any EF InMemory use.
- Replace external HTTP, email, file, and time dependencies with controlled
  test doubles through DI.
- Send real HTTP requests through HttpClient and deserialize responses.
- Test status, body contract, persistence effect, authorization, validation,
  duplicate/conflict behavior, and not found.
- Do not bypass middleware unless the test explicitly targets a lower layer.

Output:
1. Scenario matrix.
2. Factory/fixture changes.
3. Complete tests.
4. Required package changes with justification.
5. Exact dotnet test command and cleanup notes.

Acceptance criteria: tests pass repeatedly and in any order; 401, 403, 400, 404,
409, and success paths are covered where applicable.
```
