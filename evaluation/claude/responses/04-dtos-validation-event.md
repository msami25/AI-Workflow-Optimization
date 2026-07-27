# Unedited first response — 04 DTOs and Validation (Event)

## Assumptions

1. **Event** fields are `Title`, `Description`, `Location`, `StartUtc`, `EndUtc`, `Capacity`, `CategoryId`, `OrganizerId`. Responses also contain `Id`.
2. Update semantics: Full replacement (PUT), so `EventUpdateRequest` requires all fields. Omitted optional values are cleared.
3. Validation failures return an RFC-compliant `ProblemDetails` via a global exception handler or `[ApiController]` default model state behavior.
4. Cross-field validation (`EndUtc` > `StartUtc`) must be handled by `IValidatableObject`.
5. **Files to inspect**: `Program.cs` (for validation error setup), Models.

---

## DTO and Validator Code

**Target path**: `src/PromptEvaluation.Api/DTOs/EventDtos.cs`

```csharp
using System.ComponentModel.DataAnnotations;

namespace PromptEvaluation.Api.DTOs;

public class EventCreateRequest : IValidatableObject
{
    [Required(ErrorMessage = "Title is required.")]
    [StringLength(150, ErrorMessage = "Title cannot exceed 150 characters.")]
    public string Title { get; set; } = string.Empty;

    [StringLength(2000, ErrorMessage = "Description cannot exceed 2000 characters.")]
    public string? Description { get; set; }

    [Required(ErrorMessage = "Location is required.")]
    [StringLength(200, ErrorMessage = "Location cannot exceed 200 characters.")]
    public string Location { get; set; } = string.Empty;

    public DateTime StartUtc { get; set; }

    public DateTime EndUtc { get; set; }

    [Range(1, 10000, ErrorMessage = "Capacity must be between 1 and 10,000.")]
    public int Capacity { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "CategoryId must be a positive integer.")]
    public int CategoryId { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "OrganizerId must be a positive integer.")]
    public int OrganizerId { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (EndUtc <= StartUtc)
        {
            yield return new ValidationResult(
                "EndUtc must be later than StartUtc.",
                new[] { nameof(EndUtc), nameof(StartUtc) });
        }
    }
}

public class EventUpdateRequest : IValidatableObject
{
    [Required(ErrorMessage = "Title is required.")]
    [StringLength(150, ErrorMessage = "Title cannot exceed 150 characters.")]
    public string Title { get; set; } = string.Empty;

    [StringLength(2000, ErrorMessage = "Description cannot exceed 2000 characters.")]
    public string? Description { get; set; }

    [Required(ErrorMessage = "Location is required.")]
    [StringLength(200, ErrorMessage = "Location cannot exceed 200 characters.")]
    public string Location { get; set; } = string.Empty;

    public DateTime StartUtc { get; set; }

    public DateTime EndUtc { get; set; }

    [Range(1, 10000, ErrorMessage = "Capacity must be between 1 and 10,000.")]
    public int Capacity { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "CategoryId must be a positive integer.")]
    public int CategoryId { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "OrganizerId must be a positive integer.")]
    public int OrganizerId { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (EndUtc <= StartUtc)
        {
            yield return new ValidationResult(
                "EndUtc must be later than StartUtc.",
                new[] { nameof(EndUtc), nameof(StartUtc) });
        }
    }
}

public class EventResponse
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Location { get; set; } = string.Empty;
    public DateTime StartUtc { get; set; }
    public DateTime EndUtc { get; set; }
    public int Capacity { get; set; }
    public int CategoryId { get; set; }
    public int OrganizerId { get; set; }
}

public class EventListItemResponse
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public DateTime StartUtc { get; set; }
    public DateTime EndUtc { get; set; }
}
```

---

## Mapping Code

**Target path**: `src/PromptEvaluation.Api/Mapping/EventMapper.cs`

```csharp
using PromptEvaluation.Api.DTOs;
using PromptEvaluation.Api.Models;

namespace PromptEvaluation.Api.Mapping;

public static class EventMapper
{
    public static Event ToEntity(this EventCreateRequest request)
    {
        return new Event
        {
            Title = request.Title,
            Description = request.Description,
            Location = request.Location,
            StartUtc = request.StartUtc,
            EndUtc = request.EndUtc,
            Capacity = request.Capacity,
            CategoryId = request.CategoryId,
            OrganizerId = request.OrganizerId
        };
    }

    public static void UpdateEntity(this EventUpdateRequest request, Event entity)
    {
        entity.Title = request.Title;
        entity.Description = request.Description;
        entity.Location = request.Location;
        entity.StartUtc = request.StartUtc;
        entity.EndUtc = request.EndUtc;
        entity.Capacity = request.Capacity;
        entity.CategoryId = request.CategoryId;
        entity.OrganizerId = request.OrganizerId;
    }

    public static EventResponse ToResponse(this Event entity)
    {
        return new EventResponse
        {
            Id = entity.Id,
            Title = entity.Title,
            Description = entity.Description,
            Location = entity.Location,
            StartUtc = entity.StartUtc,
            EndUtc = entity.EndUtc,
            Capacity = entity.Capacity,
            CategoryId = entity.CategoryId,
            OrganizerId = entity.OrganizerId
        };
    }
}
```

---

## Controller/Service Integration Snippet

```csharp
[HttpPost]
public async Task<ActionResult<EventResponse>> CreateAsync(EventCreateRequest request)
{
    // [ApiController] applies DataAnnotations & IValidatableObject implicitly
    var entity = request.ToEntity();
    
    _context.Events.Add(entity);
    await _context.SaveChangesAsync();
    
    return CreatedAtAction(nameof(GetByIdAsync), new { id = entity.Id }, entity.ToResponse());
}
```

---

## Tests

**Target path**: `tests/PromptEvaluation.Tests/DTOs/EventValidationTests.cs`

```csharp
using System.ComponentModel.DataAnnotations;
using PromptEvaluation.Api.DTOs;

namespace PromptEvaluation.Tests.DTOs;

public class EventValidationTests
{
    private IList<ValidationResult> ValidateModel(object model)
    {
        var validationResults = new List<ValidationResult>();
        var ctx = new ValidationContext(model, null, null);
        Validator.TryValidateObject(model, ctx, validationResults, true);
        return validationResults;
    }

    [Fact]
    public void EventCreateRequest_ValidInput_HasNoErrors()
    {
        var request = new EventCreateRequest 
        { 
            Title = "Concert", Location = "Arena", StartUtc = DateTime.UtcNow, EndUtc = DateTime.UtcNow.AddHours(2), Capacity = 100, CategoryId = 1, OrganizerId = 1 
        };
        var errors = ValidateModel(request);
        Assert.Empty(errors);
    }

    [Fact]
    public void EventCreateRequest_MissingTitle_ReturnsError()
    {
        var request = new EventCreateRequest { Title = "", Location = "Arena", Capacity = 100, CategoryId = 1, OrganizerId = 1 };
        var errors = ValidateModel(request);
        Assert.Contains(errors, e => e.MemberNames.Contains(nameof(EventCreateRequest.Title)));
    }

    [Fact]
    public void EventCreateRequest_EndUtcBeforeStartUtc_ReturnsError()
    {
        var start = DateTime.UtcNow;
        var request = new EventCreateRequest 
        { 
            Title = "Concert", Location = "Arena", StartUtc = start, EndUtc = start.AddHours(-1), Capacity = 100, CategoryId = 1, OrganizerId = 1 
        };
        var errors = ValidateModel(request);
        Assert.Contains(errors, e => e.MemberNames.Contains(nameof(EventCreateRequest.EndUtc)));
    }

    [Fact]
    public void EventCreateRequest_CapacityOutOfBounds_ReturnsError()
    {
        var request = new EventCreateRequest 
        { 
            Title = "Concert", Location = "Arena", StartUtc = DateTime.UtcNow, EndUtc = DateTime.UtcNow.AddHours(2), Capacity = 0, CategoryId = 1, OrganizerId = 1 
        };
        var errors = ValidateModel(request);
        Assert.Contains(errors, e => e.MemberNames.Contains(nameof(EventCreateRequest.Capacity)));
    }

    [Fact]
    public void EventCreateRequest_ProtectedFields_CannotBeSet()
    {
        // Assert: The class does not even have an Id property
        var type = typeof(EventCreateRequest);
        var idProp = type.GetProperty("Id");
        Assert.Null(idProp);
    }
}
```

---

## Changed Files

| File | Action |
|------|--------|
| `src/PromptEvaluation.Api/DTOs/EventDtos.cs` | Created/Updated |
| `src/PromptEvaluation.Api/Mapping/EventMapper.cs` | Created |
| `tests/PromptEvaluation.Tests/DTOs/EventValidationTests.cs` | Created |
