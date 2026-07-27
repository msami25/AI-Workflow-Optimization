# Completed Prompt - Template 6: problem-details-event

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
Act as an ASP.NET Core reliability engineer. Add centralized exception handling
using IExceptionHandler and ProblemDetails for .NET 8.

Map these exception types:
ValidationException, EntityNotFoundException, BusinessConflictException, and unexpected Exception

Required HTTP mappings:
ValidationException -> 400; EntityNotFoundException -> 404; BusinessConflictException -> 409; unexpected Exception -> 500

Correlation header: X-Correlation-ID
Environment behavior: Production returns generic safe detail and never stack traces/internal messages; Development may include a safe diagnostic error code but no secrets

Requirements:
- Register the handler and ProblemDetails in Program.cs in the correct order.
- Return RFC-style ProblemDetails with status, title, safe detail, instance,
  error code, and correlation/trace identifier.
- Never expose a stack trace, SQL text, connection string, token, or internal
  exception message in production.
- Log an expected 4xx domain error below Error level and unexpected 5xx errors
  at Error with the exception object.
- Preserve cancellation behavior; do not convert client cancellation into 500.
- Avoid duplicate logging in controllers/services and the handler.

Output:
1. Exception-to-status mapping table.
2. Complete handler code.
3. Program.cs changes with placement instructions.
4. Integration tests for known 400/404/409 errors, unexpected 500, production
   data leakage, and correlation IDs.
5. Verification commands and sample safe JSON response.

Acceptance criteria: every tested error uses one consistent shape, production
responses contain no sensitive details, and logs retain diagnostic context.
```
