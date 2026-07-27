# Unedited first response - 10 integration tests (Event)

The supplied `ApiFactory` uses `WebApplicationFactory<Program>`, sets the host
to Testing, replaces the database with one open SQLite in-memory connection,
and replaces authentication with a deterministic header-based handler that
exists only in the test assembly.

Scenarios supplied:

- anonymous `GET /api/events` -> 200;
- anonymous `POST /api/events` -> 401;
- authenticated User POST -> 403;
- Admin invalid time range -> 400 ProblemDetails.

No middleware is bypassed; requests use real `HttpClient`. The test
authentication scheme does not ship in the API project.

```powershell
dotnet test evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release --filter "FullyQualifiedName~IntegrationTests"
```

Missing from this first response: seeded success, persistence assertion,
duplicate 409, 404, update/delete, and stronger per-test database reset.

