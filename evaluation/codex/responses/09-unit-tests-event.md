# Unedited first response - 09 xUnit tests (EventService)

| Behavior | Test |
| --- | --- |
| missing read | returns null |
| duplicate composite key | throws typed conflict and leaves one row |
| cancelled list | throws cancellation |
| relational rules | SQLite in-memory enforces constraints |

The supplied `ServiceTests` use a fresh open SQLite in-memory connection per
test, deterministic UTC data, `NullLogger`, Arrange-Act-Assert, and no network,
sleep, random values, or shared state. EF Core is not mocked because query
translation, uniqueness, and foreign keys are observable relational behavior.

```powershell
dotnet test evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release --filter "FullyQualifiedName~ServiceTests"
```

Gaps needing more tests: every length/range boundary, valid update/delete,
missing update/delete, and database failure. Authentication and HTTP
ProblemDetails belong in integration tests.

The first fixture omitted the required Category seed for duplicate Event
creation; that omission was discovered only when the test was executed.

