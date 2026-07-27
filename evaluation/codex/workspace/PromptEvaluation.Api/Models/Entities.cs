namespace PromptEvaluation.Api.Models;

public sealed class Event
{
    public int Id { get; set; }
    public required string Title { get; set; }
    public string? Description { get; set; }
    public required string Location { get; set; }
    public DateTime StartUtc { get; set; }
    public DateTime EndUtc { get; set; }
    public int Capacity { get; set; }
    public int CategoryId { get; set; }
    public int OrganizerId { get; set; }
    public Category? Category { get; set; }
}

public sealed class Category
{
    public int Id { get; set; }
    public required string Name { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; }
    public ICollection<Event> Events { get; } = new List<Event>();
}
