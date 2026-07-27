# Unedited first response - 01 API controller (Category)

Assumptions: `ICategoryService` owns uniqueness and referenced-delete rules.
Reads are anonymous; create, update, and delete require the `Admin` role.
Centralized middleware maps a known business conflict to 409.

Target files supplied:

- `PromptEvaluation.Api/Controllers/CategoriesController.cs`
- `PromptEvaluation.Api/Services/ServiceContracts.cs`
- `PromptEvaluation.Api/Contracts/CategoryContracts.cs`
- `PromptEvaluation.Tests/IntegrationTests.cs`

The thin controller uses `[ApiController]`, attribute routing,
`CancellationToken`, `ActionResult`, logging, `CreatedAtAction`, 404 for a
missing item, and 204 for successful update/delete. No persistence entity is
bound and no EF query occurs in the controller.

The shared HTTP tests cover anonymous reads, 401, 403, validation reaching the
Admin endpoint, and a 201 Category create.

```powershell
dotnet build evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release
dotnet test evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release
```

Known dependency: the Template 6 handler is required for an HTTP 409 response.

