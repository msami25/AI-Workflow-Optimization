namespace PromptEvaluation.Api.Exceptions;

public class BusinessConflictException : Exception
{
    public string ConflictCode { get; }

    public BusinessConflictException(string message, string conflictCode = "CONFLICT")
        : base(message)
    {
        ConflictCode = conflictCode;
    }
}
