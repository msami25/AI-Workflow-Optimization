# Completed Prompt - Template 8: secure-upload-event

## Shared project context

```text
Project: PromptEvaluation
Framework: .NET 8
Application type: ASP.NET Core Web API
Architecture: Layered API: controllers, services, EF Core DbContext, DTOs, centralized exception handling
Database: SQLite
ORM: EF Core 8
Test stack: xUnit, Moq, WebApplicationFactory, SQLite in-memory
Existing conventions: Nullable enabled, file-scoped namespaces, PascalCase public members, async methods suffixed Async

Work only within the requested scope. Preserve existing behavior unless a
change is explicitly requested. Do not invent files, methods, packages, or
requirements. Do not expose secrets. First state assumptions and the files you
need to inspect. After implementation, list changed files, verification
commands, risks, and any remaining work.
```

## Task

```text
Act as an ASP.NET Core file-upload security engineer. Implement or review file
upload with these rules:

Allowed business file types: JPEG and PNG event images
Maximum size: 5,242,880 bytes (5 MiB)
Storage: isolated local volume outside the executable and content root
Malware scanning: Not available
Authorization: Only Admin may upload or replace an event image

Requirements:
- Enforce request-size and per-file limits before copying the full stream.
- Treat extension and Content-Type as untrusted; validate an allowlist plus
  file signatures/magic bytes.
- Generate a server-side random filename and never use a client path.
- Store outside the executable/content root unless public serving is a stated
  requirement; if public, serve only from an isolated upload directory.
- Reject double extensions, path traversal, empty files, and mismatched
  signatures. Prevent overwrite.
- Use async bounded streaming with CancellationToken.
- Return safe errors and log metadata without file contents or personal data.
- Document malware-scanning limitations and defense in depth.

Output:
1. Threat table.
2. Service/interface and options code.
3. DI/configuration and controller integration.
4. Tests for allowed file, oversize, spoofed MIME, invalid signature, traversal
   filename, duplicate name, empty file, unauthorized user, and cancellation.
5. Manual curl/Swagger verification checklist.

Acceptance criteria: no client-controlled path is used; spoofed files and
oversized uploads fail; stored filenames are non-predictable.
```
