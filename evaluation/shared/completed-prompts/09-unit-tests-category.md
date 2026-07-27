# Completed Prompt - Template 9: unit-tests-category

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
Act as a .NET test engineer. Write maintainable xUnit tests for
CategoryService.

Public behaviors to test:
empty/found/not-found reads; valid create; case-insensitive name conflict; safe update; referenced delete rejection; successful delete; cancellation

Dependencies:
EvaluationDbContext and ILogger<CategoryService>; use a relational SQLite in-memory database for EF behavior and a no-op logger

Representative data and boundaries:
Name lengths 1 and 80; Description 500; names Music/music/MUSIC; referenced and unreferenced categories

Use Moq only for true external
collaborators.

Requirements:
- Test observable behavior, not private implementation.
- Follow Arrange-Act-Assert and use names in
  Method_Scenario_ExpectedResult form.
- Cover success, boundary, not-found, invalid input, dependency failure, and
  cancellation when applicable.
- Verify important side effects exactly, including that writes do not occur
  after validation fails.
- Avoid DateTime.Now, random values, network calls, shared mutable fixtures,
  Thread.Sleep, and order-dependent tests.
- Reuse the project's fixture/builders before creating new helpers.

Output:
1. Behavior-to-test matrix.
2. Complete test class and only necessary fixture changes.
3. Explanation of anything intentionally not mocked.
4. Exact filtered test command.
5. Gaps that need integration rather than unit tests.

Acceptance criteria: tests are deterministic, compile, can run independently,
and fail for the intended behavior regression rather than implementation churn.
```
