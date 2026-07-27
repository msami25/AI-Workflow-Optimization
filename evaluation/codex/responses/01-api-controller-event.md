# Unedited first response - 01 API controller (Event)

Assumptions: `IEventService` owns business rules and exposes asynchronous CRUD
methods using the supplied Event DTOs. A centralized handler maps
`BusinessConflictException` to 409. Reads are anonymous and every write
requires the `Admin` role.

Target files supplied:

- `PromptEvaluation.Api/Controllers/EventsController.cs`
- `PromptEvaluation.Api/Services/ServiceContracts.cs`
- `PromptEvaluation.Api/Contracts/EventContracts.cs`
- `PromptEvaluation.Tests/IntegrationTests.cs`

The controller uses `[ApiController]`, `[Route("api/events")]`, constructor
injection, `ILogger<EventsController>`, `CancellationToken`, constrained
`{id:int}` routes, `[AllowAnonymous]` reads, and
`[Authorize(Roles = "Admin")]` writes. It returns `Ok`, `NotFound`,
`CreatedAtAction`, and `NoContent` as appropriate. It contains no EF query and
no catch block.

Tests supplied cover anonymous GET, anonymous POST (401), non-Admin POST (403),
Admin validation (400), and successful create behavior through the shared
integration harness.

Verification:

```powershell
dotnet build evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release
dotnet test evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release
```

Known dependency: conflict-to-409 behavior requires the centralized exception
handler requested separately by Template 6.

