namespace PromptEvaluation.Api.Exceptions;

public class EntityNotFoundException : Exception
{
    public string EntityName { get; }
    public object EntityId { get; }

    public EntityNotFoundException(string entityName, object entityId)
        : base($"{entityName} with identifier '{entityId}' was not found.")
    {
        EntityName = entityName;
        EntityId = entityId;
    }
}
