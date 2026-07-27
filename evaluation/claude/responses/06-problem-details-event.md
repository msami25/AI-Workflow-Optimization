# Unedited first response — 06 Problem Details (Event)

## Assumptions

1. The project uses the built-in ASP.NET Core `IExceptionHandler` middleware introduced in .NET 8.
2. `IHostEnvironment.IsDevelopment()` is used to determine safe detail exposure.
3. We are mapping exceptions defined in the domain: `ValidationException`, `EntityNotFoundException`, `BusinessConflictException`.

---

## Exception Mapping Table

| Exception Type | HTTP Status | Title | Detail (Prod) | Detail (Dev) | Code |
|---|---|---|---|---|---|
| `ValidationException` | 400 Bad Request | Validation Error | Exception message | Exception message | `VALIDATION_ERROR` |
| `EntityNotFoundException` | 404 Not Found | Not Found | Exception message | Exception message | `ENTITY_NOT_FOUND` |
| `BusinessConflictException` | 409 Conflict | Conflict | Exception message | Exception message | Exception's `ConflictCode` |
| `Exception` (fallback) | 500 Internal Server Error | Internal Server Error | "An unexpected error occurred." | "An unexpected error occurred. Check server logs." | `INTERNAL_ERROR` |

---

## Complete Handler Code

**Target path**: `src/PromptEvaluation.Api/Middleware/GlobalExceptionHandler.cs`

```csharp
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
        // Preserve cancellation behavior - do not convert to 500
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
                    : "An unexpected error occurred.", // Safe generic detail for production
                "INTERNAL_ERROR")
        };

        if (statusCode >= 500)
        {
            _logger.LogError(exception, "Unhandled exception. CorrelationId={CorrelationId}", correlationId);
        }
        else
        {
            _logger.LogWarning("Expected domain error {ErrorCode}: {Message}. CorrelationId={CorrelationId}",
                errorCode, exception.Message, correlationId);
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
```

---

## Program.cs Changes

**Target path**: `src/PromptEvaluation.Api/Program.cs`

```csharp
// 1. Add these lines BEFORE builder.Build();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

var app = builder.Build();

// 2. Add this line at the start of the middleware pipeline
app.UseExceptionHandler();
```

---

## Integration Tests

**Target path**: `tests/PromptEvaluation.Tests/Middleware/GlobalExceptionHandlerTests.cs`

```csharp
using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc;
using PromptEvaluation.Api.Exceptions;
using PromptEvaluation.Tests.Fixtures;

namespace PromptEvaluation.Tests.Middleware;

// Uses WebApplicationFactory (setup in fixture)
public class GlobalExceptionHandlerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;

    public GlobalExceptionHandlerTests(CustomWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task ExceptionHandler_Returns404_ForEntityNotFound()
    {
        // Assuming GET /api/events/99999 throws EntityNotFoundException internally
        var response = await _client.GetAsync("/api/events/99999");
        
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        
        var problem = await response.Content.ReadFromJsonAsync<ProblemDetails>();
        Assert.NotNull(problem);
        Assert.Equal("Not Found", problem!.Title);
        Assert.Equal(404, problem.Status);
        Assert.True(problem.Extensions.ContainsKey("errorCode"));
        Assert.Equal("ENTITY_NOT_FOUND", problem.Extensions["errorCode"]?.ToString());
    }

    [Fact]
    public async Task ExceptionHandler_Returns500_AndNoSensitiveDetail_ForUnexpectedException()
    {
        // Add a test endpoint or force a failure that throws an unexpected Exception
        // For testing, we assume the environment is "Production" via the factory
        _client.DefaultRequestHeaders.Add("X-Correlation-ID", "test-corr-123");
        var response = await _client.GetAsync("/api/force-500-error");
        
        Assert.Equal(HttpStatusCode.InternalServerError, response.StatusCode);
        
        var problem = await response.Content.ReadFromJsonAsync<ProblemDetails>();
        Assert.Equal(500, problem!.Status);
        Assert.Equal("An unexpected error occurred.", problem.Detail); // No stack trace
        Assert.Equal("test-corr-123", problem.Extensions["correlationId"]?.ToString());
    }
}
```

---

## Commands and Sample JSON

```powershell
dotnet build
dotnet test --filter "FullyQualifiedName~GlobalExceptionHandlerTests"
```

**Sample Safe JSON Response (500 Error in Production)**:

```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.6.1",
  "title": "Internal Server Error",
  "status": 500,
  "detail": "An unexpected error occurred.",
  "instance": "/api/events",
  "correlationId": "5de6e9f1-4c12-4a0b-85d8-c84d720c2d3a",
  "errorCode": "INTERNAL_ERROR",
  "traceId": "00-4b1..."
}
```
