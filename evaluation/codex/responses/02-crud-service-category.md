# Unedited first response - 02 CRUD service (Category)

Assumptions: SQLite `NOCASE` collation plus a unique index backs the
case-insensitive rule. `EvaluationDbContext` is the unit of work.

The supplied `CategoryService` projects untracked reads, uses `FindAsync` for
tracked writes, trims names, allowlists mutable fields, checks uniqueness, and
rejects deletion when `Events.AnyAsync` finds a reference. Missing
update/delete returns `false`; conflicts use `BusinessConflictException`.

Target paths:

- `PromptEvaluation.Api/Services/CategoryService.cs`
- `PromptEvaluation.Api/Services/ServiceContracts.cs`
- `PromptEvaluation.Tests/ServiceTests.cs`

Tests supplied exercise case-insensitive duplicate creation and referenced
deletion. The full empty-list, update, successful-delete, dependency-failure,
and cancellation matrix was not completed in the first response.

```powershell
dotnet test evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release --filter "FullyQualifiedName~ServiceTests"
```

The query is untracked and projected. A production list endpoint should add
bounded paging.

