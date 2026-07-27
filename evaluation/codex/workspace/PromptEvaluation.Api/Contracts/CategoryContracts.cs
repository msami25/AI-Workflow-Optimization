using System.ComponentModel.DataAnnotations;

namespace PromptEvaluation.Api.Contracts;

public abstract class CategoryWriteRequest
{
    [Required, StringLength(80)]
    public string Name { get; init; } = "";

    [StringLength(500)]
    public string? Description { get; init; }

    public bool IsActive { get; init; }
}

public sealed class CategoryCreateRequest : CategoryWriteRequest;
public sealed class CategoryUpdateRequest : CategoryWriteRequest;
public sealed record CategoryResponse(int Id, string Name, string? Description, bool IsActive);
