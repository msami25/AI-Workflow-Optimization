using System.ComponentModel.DataAnnotations;

namespace PromptEvaluation.Api.Contracts;

public abstract class EventWriteRequest : IValidatableObject
{
    [Required, StringLength(150)]
    public string Title { get; init; } = "";

    [StringLength(2000)]
    public string? Description { get; init; }

    [Required, StringLength(200)]
    public string Location { get; init; } = "";

    public DateTime StartUtc { get; init; }
    public DateTime EndUtc { get; init; }

    [Range(1, 10_000)]
    public int Capacity { get; init; }

    [Range(1, int.MaxValue)]
    public int CategoryId { get; init; }

    [Range(1, int.MaxValue)]
    public int OrganizerId { get; init; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (StartUtc.Kind != DateTimeKind.Utc || EndUtc.Kind != DateTimeKind.Utc)
        {
            yield return new ValidationResult(
                "StartUtc and EndUtc must be UTC.",
                [nameof(StartUtc), nameof(EndUtc)]);
        }

        if (EndUtc <= StartUtc)
        {
            yield return new ValidationResult(
                "EndUtc must be later than StartUtc.",
                [nameof(EndUtc)]);
        }
    }
}

public sealed class EventCreateRequest : EventWriteRequest;
public sealed class EventUpdateRequest : EventWriteRequest;

public sealed record EventResponse(
    int Id,
    string Title,
    string? Description,
    string Location,
    DateTime StartUtc,
    DateTime EndUtc,
    int Capacity,
    int CategoryId,
    int OrganizerId);
