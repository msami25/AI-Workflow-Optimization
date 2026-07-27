using System.ComponentModel.DataAnnotations;

namespace PromptEvaluation.Api.DTOs;

public class EventCreateRequest : IValidatableObject
{
    [Required]
    [StringLength(150)]
    public string Title { get; set; } = string.Empty;

    [StringLength(2000)]
    public string? Description { get; set; }

    [Required]
    [StringLength(200)]
    public string Location { get; set; } = string.Empty;

    public DateTime StartUtc { get; set; }

    public DateTime EndUtc { get; set; }

    [Range(1, 10000)]
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
                new[] { nameof(EndUtc) });
        }
    }
}

public class EventUpdateRequest : IValidatableObject
{
    [Required]
    [StringLength(150)]
    public string Title { get; set; } = string.Empty;

    [StringLength(2000)]
    public string? Description { get; set; }

    [Required]
    [StringLength(200)]
    public string Location { get; set; } = string.Empty;

    public DateTime StartUtc { get; set; }

    public DateTime EndUtc { get; set; }

    [Range(1, 10000)]
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
                new[] { nameof(EndUtc) });
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
    public double DurationMinutes { get; set; }
}

public class EventListItemResponse
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public DateTime StartUtc { get; set; }
    public DateTime EndUtc { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public int RemainingCapacity { get; set; }
}
