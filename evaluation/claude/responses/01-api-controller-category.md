# Unedited first response — 01 API Controller (Category)

## Assumptions and Required Existing Interfaces/DTOs

1. **ICategoryService** exists at `PromptEvaluation.Api.Services.ICategoryService` with methods:
   - `GetAllAsync(CancellationToken)` → `IEnumerable<CategoryListItemResponse>`
   - `GetByIdAsync(int, CancellationToken)` → `CategoryResponse?`
   - `CreateAsync(CategoryCreateRequest, CancellationToken)` → `CategoryResponse`
   - `UpdateAsync(int, CategoryUpdateRequest, CancellationToken)` → `void`
   - `DeleteAsync(int, CancellationToken)` → `void`

2. **DTOs** exist under `PromptEvaluation.Api.DTOs`:
   - `CategoryCreateRequest`, `CategoryUpdateRequest`, `CategoryResponse`, `CategoryListItemResponse`

3. **Centralized exception handling** maps `EntityNotFoundException` → 404 and `BusinessConflictException` → 409 via `IExceptionHandler`.

4. **Files to inspect**: `ICategoryService.cs`, Category DTOs, `Program.cs` (for service registration and auth configuration).

---

## Complete Controller Code

**Target path**: `src/PromptEvaluation.Api/Controllers/CategoryController.cs`

```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Services;

namespace PromptEvaluation.Api.Controllers;

[ApiController]
[Route("api/categories")]
public class CategoryController : ControllerBase
{
    private readonly ICategoryService _categoryService;
    private readonly ILogger<CategoryController> _logger;

    public CategoryController(ICategoryService categoryService, ILogger<CategoryController> logger)
    {
        _categoryService = categoryService;
        _logger = logger;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<CategoryListItemResponse>>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        var categories = await _categoryService.GetAllAsync(cancellationToken);
        return Ok(categories);
    }

    [HttpGet("{id:int}")]
    [AllowAnonymous]
    public async Task<ActionResult<CategoryResponse>> GetByIdAsync(
        int id, CancellationToken cancellationToken)
    {
        var category = await _categoryService.GetByIdAsync(id, cancellationToken);
        if (category is null)
        {
            return NotFound();
        }

        return Ok(category);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<CategoryResponse>> CreateAsync(
        [FromBody] CategoryCreateRequest request, CancellationToken cancellationToken)
    {
        var created = await _categoryService.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetByIdAsync), new { id = created.Id }, created);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateAsync(
        int id, [FromBody] CategoryUpdateRequest request, CancellationToken cancellationToken)
    {
        await _categoryService.UpdateAsync(id, request, cancellationToken);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteAsync(
        int id, CancellationToken cancellationToken)
    {
        await _categoryService.DeleteAsync(id, cancellationToken);
        return NoContent();
    }
}
```

---

## Supporting Contracts

No additional contracts are missing. The controller depends on `ICategoryService` and Category DTOs, which are assumed to exist.

---

## Unit/Integration Test Cases

**Target path**: `tests/PromptEvaluation.Tests/Controllers/CategoryControllerTests.cs`

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using PromptEvaluation.Api.Controllers;
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Services;

namespace PromptEvaluation.Tests.Controllers;

public class CategoryControllerTests
{
    private readonly Mock<ICategoryService> _serviceMock = new();
    private readonly Mock<ILogger<CategoryController>> _loggerMock = new();
    private readonly CategoryController _controller;

    public CategoryControllerTests()
    {
        _controller = new CategoryController(_serviceMock.Object, _loggerMock.Object);
    }

    [Fact]
    public async Task GetAllAsync_ReturnsOk_WithCategories()
    {
        var items = new[] { new CategoryListItemResponse { Id = 1, Name = "Music", IsActive = true } };
        _serviceMock.Setup(s => s.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(items);

        var result = await _controller.GetAllAsync(CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(200, okResult.StatusCode);
    }

    [Fact]
    public async Task GetByIdAsync_CategoryExists_ReturnsOk()
    {
        _serviceMock.Setup(s => s.GetByIdAsync(1, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new CategoryResponse { Id = 1, Name = "Music" });

        var result = await _controller.GetByIdAsync(1, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        Assert.Equal(200, okResult.StatusCode);
    }

    [Fact]
    public async Task GetByIdAsync_CategoryNotFound_Returns404()
    {
        _serviceMock.Setup(s => s.GetByIdAsync(999, It.IsAny<CancellationToken>()))
            .ReturnsAsync((CategoryResponse?)null);

        var result = await _controller.GetByIdAsync(999, CancellationToken.None);

        Assert.IsType<NotFoundResult>(result.Result);
    }

    [Fact]
    public async Task CreateAsync_ValidRequest_Returns201()
    {
        var request = new CategoryCreateRequest { Name = "Music" };
        _serviceMock.Setup(s => s.CreateAsync(request, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new CategoryResponse { Id = 1, Name = "Music" });

        var result = await _controller.CreateAsync(request, CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        Assert.Equal(201, created.StatusCode);
        Assert.Equal(nameof(CategoryController.GetByIdAsync), created.ActionName);
    }

    [Fact]
    public async Task UpdateAsync_ValidRequest_Returns204()
    {
        _serviceMock.Setup(s => s.UpdateAsync(1, It.IsAny<CategoryUpdateRequest>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var result = await _controller.UpdateAsync(1,
            new CategoryUpdateRequest { Name = "Updated" }, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task DeleteAsync_ValidId_Returns204()
    {
        _serviceMock.Setup(s => s.DeleteAsync(1, It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var result = await _controller.DeleteAsync(1, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }
}
```

Authorization enforcement (401/403) requires integration tests through `WebApplicationFactory` with a test authentication handler — unit tests of the controller class alone do not exercise the ASP.NET Core pipeline's `[Authorize]` attributes.

---

## Verification Commands

```powershell
dotnet build evaluation/claude/workspace/PromptEvaluation.slnx --configuration Release
dotnet test evaluation/claude/workspace/PromptEvaluation.slnx --configuration Release --filter "FullyQualifiedName~CategoryControllerTests"
```

---

## Changed Files

| File | Action |
|------|--------|
| `src/PromptEvaluation.Api/Controllers/CategoryController.cs` | Created |
| `tests/PromptEvaluation.Tests/Controllers/CategoryControllerTests.cs` | Created |

## Risks

- Authorization tests at the unit level verify only return types, not middleware enforcement. Integration tests with `WebApplicationFactory` are needed to prove 401/403 behavior.
- If `ICategoryService` throws an unhandled exception type not mapped in the exception handler, it would result in a generic 500.

## Remaining Work

- Integration tests for authorization enforcement (401/403 paths).
- OpenAPI/Swagger annotations if API documentation is required.
