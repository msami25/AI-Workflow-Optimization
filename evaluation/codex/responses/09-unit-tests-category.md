# Unedited first response - 09 xUnit tests (CategoryService)

| Behavior | Test |
| --- | --- |
| case-insensitive duplicate | `Music` then `music` throws conflict |
| referenced deletion | throws conflict and preserves Category |
| relational behavior | SQLite in-memory with `NOCASE` collation |

The supplied tests use a database per test and a no-op logger. EF Core is not
mocked because collation, foreign keys, and query translation are the behavior
under test.

```powershell
dotnet test evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release --filter "FullyQualifiedName~ServiceTests"
```

Gaps: empty/found/not-found reads, 1/80/81 character boundaries, safe update,
successful delete, cancellation, and dependency failure were not all covered
in this first response.

