using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using PromptEvaluation.Api.Exceptions;

namespace PromptEvaluation.Api.Middleware;

public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;
    private readonly IHostEnvironment _environment;

    public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger, IHostEnvironment environment)
    {
        _logger = logger;
        _environment = environment;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        if (exception is OperationCanceledException)
        {
            return false;
        }

        var correlationId = httpContext.Request.Headers["X-Correlation-ID"].FirstOrDefault()
            ?? httpContext.TraceIdentifier;

        var (statusCode, title, detail, errorCode) = exception switch
        {
            ValidationException ve => (
                StatusCodes.Status400BadRequest,
                "Validation Error",
                ve.Message,
                "VALIDATION_ERROR"),
            EntityNotFoundException enf => (
                StatusCodes.Status404NotFound,
                "Not Found",
                enf.Message,
                "ENTITY_NOT_FOUND"),
            BusinessConflictException bce => (
                StatusCodes.Status409Conflict,
                "Conflict",
                bce.Message,
                bce.ConflictCode),
            _ => (
                StatusCodes.Status500InternalServerError,
                "Internal Server Error",
                _environment.IsDevelopment()
                    ? "An unexpected error occurred. Check server logs."
                    : "An unexpected error occurred.",
                "INTERNAL_ERROR")
        };

        if (statusCode >= 500)
        {
            _logger.LogError(exception, "Unhandled exception. CorrelationId={CorrelationId}", correlationId);
        }
        else
        {
            _logger.LogWarning("Expected domain error {ErrorCode}. CorrelationId={CorrelationId}",
                errorCode, correlationId);
        }

        var problemDetails = new ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Detail = detail,
            Instance = httpContext.Request.Path,
            Extensions =
            {
                ["correlationId"] = correlationId,
                ["errorCode"] = errorCode,
                ["traceId"] = httpContext.TraceIdentifier
            }
        };

        httpContext.Response.StatusCode = statusCode;
        await httpContext.Response.WriteAsJsonAsync(problemDetails, cancellationToken);

        return true;
    }
}
