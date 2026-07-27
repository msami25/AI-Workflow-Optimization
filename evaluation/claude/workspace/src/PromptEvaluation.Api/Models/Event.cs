namespace PromptEvaluation.Api.Models;

public class Event
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

    public Category? Category { get; set; }
    public Organizer? Organizer { get; set; }
}
