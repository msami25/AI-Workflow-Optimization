# Unedited first response — 04 DTOs and Validation (Category)

## Assumptions

1. **Category** fields are `Name`, `Description`, `IsActive`. `Id` is available in responses.
2. Uniqueness of `Name` is enforced by the database/service, so the DTO only enforces length/presence.
3. Update semantics: Full replacement (PUT), so `CategoryUpdateRequest` requires all fields, though some are optional. Omitted optional values are cleared.
4. Validation failures return an RFC-compliant `ProblemDetails` via a global exception handler or `[ApiController]` default model state behavior.
5. Nullable reference types are enabled (`string?` for optional, `string` for required).
6. **Files to inspect**: `Program.cs` (for validation error setup), Models.

---

## DTO and Validator Code

**Target path**: `src/PromptEvaluation.Api/DTOs/CategoryDtos.cs`

```csharp
using System.ComponentModel.DataAnnotations;

namespace PromptEvaluation.Api.DTOs;

public class CategoryCreateRequest
{
    [Required(ErrorMessage = "Name is required.")]
    [StringLength(80, ErrorMessage = "Name cannot exceed 80 characters.")]
    public string Name { get; set; } = string.Empty;

    [StringLength(500, ErrorMessage = "Description cannot exceed 500 characters.")]
    public string? Description { get; set; }

    public bool IsActive { get; set; } = true;
}

public class CategoryUpdateRequest
{
    [Required(ErrorMessage = "Name is required.")]
    [StringLength(80, ErrorMessage = "Name cannot exceed 80 characters.")]
    public string Name { get; set; } = string.Empty;

    [StringLength(500, ErrorMessage = "Description cannot exceed 500 characters.")]
    public string? Description { get; set; }

    public bool IsActive { get; set; }
}

public class CategoryResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; }
}

public class CategoryListItemResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}
```

---

## Mapping Code

Manual mapping is explicit and avoids exposing internal or protected fields like `CreatedAt` or row-version bytes (though none exist for Category yet). `Id` is explicitly omitted from requests.

**Target path**: `src/PromptEvaluation.Api/Mapping/CategoryMapper.cs`

```csharp
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Models;

namespace PromptEvaluation.Api.Mapping;

public static class CategoryMapper
{
    public static Category ToEntity(this CategoryCreateRequest request)
    {
        return new Category
        {
            Name = request.Name,
            Description = request.Description,
            IsActive = request.IsActive
        };
    }

    public static void UpdateEntity(this CategoryUpdateRequest request, Category entity)
    {
        entity.Name = request.Name;
        entity.Description = request.Description;
        entity.IsActive = request.IsActive;
    }

    public static CategoryResponse ToResponse(this Category entity)
    {
        return new CategoryResponse
        {
            Id = entity.Id,
            Name = entity.Name,
            Description = entity.Description,
            IsActive = entity.IsActive
        };
    }
}
```

---

## Controller/Service Integration Snippet

```csharp
[HttpPost]
public async Task<ActionResult<CategoryResponse>> CreateAsync(CategoryCreateRequest request)
{
    // [ApiController] automatically validates DataAnnotations and returns 400 ProblemDetails
    var entity = request.ToEntity();
    
    _context.Categories.Add(entity);
    await _context.SaveChangesAsync();
    
    return CreatedAtAction(nameof(GetByIdAsync), new { id = entity.Id }, entity.ToResponse());
}
```

---

## Tests

**Target path**: `tests/PromptEvaluation.Tests/DTOs/CategoryValidationTests.cs`

```csharp
using System.ComponentModel.DataAnnotations;
using PromptEvaluation.Api.DTOs;

namespace PromptEvaluation.Tests.DTOs;

public class CategoryValidationTests
{
    private IList<ValidationResult> ValidateModel(object model)
    {
        var validationResults = new List<ValidationResult>();
        var ctx = new ValidationContext(model, null, null);
        Validator.TryValidateObject(model, ctx, validationResults, true);
        return validationResults;
    }

    [Fact]
    public void CategoryCreateRequest_ValidInput_HasNoErrors()
    {
        var request = new CategoryCreateRequest { Name = "Music", Description = "Live music", IsActive = true };
        var errors = ValidateModel(request);
        Assert.Empty(errors);
    }

    [Fact]
    public void CategoryCreateRequest_MissingName_ReturnsError()
    {
        var request = new CategoryCreateRequest { Name = "" };
        var errors = ValidateModel(request);
        Assert.Contains(errors, e => e.MemberNames.Contains(nameof(CategoryCreateRequest.Name)));
    }

    [Fact]
    public void CategoryCreateRequest_NameTooLong_ReturnsError()
    {
        var request = new CategoryCreateRequest { Name = new string('x', 81) };
        var errors = ValidateModel(request);
        Assert.Contains(errors, e => e.MemberNames.Contains(nameof(CategoryCreateRequest.Name)));
    }

    [Fact]
    public void CategoryCreateRequest_DescriptionTooLong_ReturnsError()
    {
        var request = new CategoryCreateRequest { Name = "Music", Description = new string('x', 501) };
        var errors = ValidateModel(request);
        Assert.Contains(errors, e => e.MemberNames.Contains(nameof(CategoryCreateRequest.Description)));
    }

    [Fact]
    public void CategoryCreateRequest_ProtectedFields_CannotBeSet()
    {
        // Assert: The class does not even have an Id property, proving clients cannot over-post Id.
        var type = typeof(CategoryCreateRequest);
        var idProp = type.GetProperty("Id");
        Assert.Null(idProp);
    }
}
```

---

## Changed Files

| File | Action |
|------|--------|
| `src/PromptEvaluation.Api/DTOs/CategoryDtos.cs` | Created/Updated |
| `src/PromptEvaluation.Api/Mapping/CategoryMapper.cs` | Created |
| `tests/PromptEvaluation.Tests/DTOs/CategoryValidationTests.cs` | Created |
