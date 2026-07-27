# Unedited first response - 10 integration tests (Category)

The shared `ApiFactory` uses the real HTTP pipeline, SQLite in-memory, and a
test-assembly-only authentication handler.

Scenarios supplied:

- anonymous GET -> 200;
- anonymous POST -> 401;
- authenticated non-Admin POST -> 403;
- Admin valid POST -> 201 with response contract and Location header.

```powershell
dotnet test evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release --filter "FullyQualifiedName~IntegrationTests"
```

Missing from this first response: duplicate-name 409, referenced-delete 409,
not-found 404, update/delete persistence, invalid length 400, and robust
database isolation for parallel test execution.

