# Unedited first response - 06 centralized ProblemDetails

| Exception | HTTP | Log level | Safe detail |
| --- | ---: | --- | --- |
| `ValidationException` | 400 | Information | validation failed |
| `EntityNotFoundException` | 404 | Information | resource not found |
| `BusinessConflictException` | 409 | Warning | request conflicts with state |
| unexpected `Exception` | 500 | Error | unexpected error |

Use one `IExceptionHandler` registered before `AddProblemDetails`, then
`app.UseExceptionHandler()` before endpoint mapping. The handler should attach
`status`, `title`, `instance`, a stable error code, and the accepted or
generated `X-Correlation-ID`. It must log the exception object only for the
unexpected 500 case and must return `false` for request-aborted cancellation.

Production responses must not include exception messages, SQL, stack traces,
tokens, or connection strings. Development may include a stable diagnostic
code but not sensitive details.

Required integration cases: 400, 404, 409, 500, correlation header
round-tripping, generated correlation identifiers, and assertions that
production JSON does not contain seeded secret-like markers.

```powershell
dotnet test evaluation/codex/workspace/PromptEvaluation.slnx --configuration Release --filter "FullyQualifiedName~ProblemDetails"
```

The isolated workspace only registered framework ProblemDetails and did not
implement this typed handler. This first response is response-reviewed only.

