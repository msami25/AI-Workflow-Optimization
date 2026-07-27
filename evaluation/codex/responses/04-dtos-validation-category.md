# Unedited first response - 04 DTOs/validation (Category)

Assumptions: PUT replaces Name, Description, and IsActive; `null` clears
Description. Case-insensitive uniqueness belongs in service/database logic,
not DataAnnotations.

Supplied create/update contracts accept only Name, Description, and IsActive.
Name is required and limited to 80; Description is limited to 500. The response
adds Id. Manual mapping prevents Id over-posting, and `[ApiController]` returns
validation ProblemDetails.

Target paths:

- `PromptEvaluation.Api/Contracts/CategoryContracts.cs`
- `PromptEvaluation.Api/Services/CategoryService.cs`
- `PromptEvaluation.Tests/IntegrationTests.cs`

The first response omitted a distinct `CategoryListItemResponse` and a complete
length/null boundary suite.

```powershell
dotnet test evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release
```

