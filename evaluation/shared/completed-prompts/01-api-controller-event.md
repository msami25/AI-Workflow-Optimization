# Completed Prompt - Template 1: api-controller-event

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
Act as a senior ASP.NET Core developer. Create a production-ready
EventController in PromptEvaluation.Api.Controllers for route "api/events".

Context:
- Entity identifier type: int
- Read authorization: Anonymous
- Create/update/delete authorization: Admin
- Business logic belongs in IEventService, not the controller.
- Use request/response DTOs; never bind the EF entity directly.

Required endpoints:
- GET /api/events
- GET /api/events/{id}
- POST /api/events
- PUT /api/events/{id}
- DELETE /api/events/{id}

Requirements:
- Use [ApiController], attribute routing, constructor injection, async/await,
  CancellationToken, ActionResult, and ILogger<EventController>.
- Return 200 for successful reads, 201 with CreatedAtAction for create, 204 for
  update/delete, 400 for invalid input, 404 when absent, and 409 for a known
  business conflict.
- Apply explicit [Authorize] policies/roles to write operations. Do not weaken
  any existing authorization.
- Rely on centralized exception handling; do not add broad catch blocks.
- Keep methods thin and avoid returning stack traces or internal exception
  messages.

Output in this order:
1. Assumptions and required existing interfaces/DTOs.
2. Complete controller code.
3. Any minimal supporting contracts that are missing, each in a separate code
   block with its target path.
4. Unit/integration test cases covering status codes and authorization.
5. dotnet build and dotnet test commands.

Acceptance criteria: code compiles on .NET 8; routes are unambiguous;
write endpoints reject unauthenticated and unauthorized users; no EF Core
queries occur inside the controller.
```
