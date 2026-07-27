# Unedited first response - 04 DTOs/validation (Event)

Assumptions: create and update currently replace all mutable fields; nullable
Description may be cleared with `null`. This is PUT semantics, not PATCH.

Supplied contracts:

- `EventCreateRequest` and `EventUpdateRequest` inherit a write contract with
  DataAnnotations and `IValidatableObject`;
- `EventResponse` contains the public identifier and fields;
- requests contain no Id or server-controlled members;
- manual service mapping allowlists every mutable property.

Validation covers required/max-length Title and Location, Description maximum,
Capacity 1-10,000, positive CategoryId/OrganizerId, UTC timestamps, and
`EndUtc > StartUtc`. `[ApiController]` produces validation ProblemDetails.

Target paths:

- `PromptEvaluation.Api/Contracts/EventContracts.cs`
- `PromptEvaluation.Api/Services/EventService.cs`
- `PromptEvaluation.Tests/IntegrationTests.cs`

The first response did not create a distinct list-item contract or the full
boundary test matrix.

```powershell
dotnet test evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release
```

