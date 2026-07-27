# Completed Prompt - Template 12: docker-runbook-stack

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
Act as a DevOps engineer for a .NET 8 application. Create or review a
local Docker Compose setup.

Services: ASP.NET Core API, PostgreSQL database, and frontend
Published API URL/port: http://localhost:8080
Health endpoint: /health
Required environment variables (names only): ASPNETCORE_ENVIRONMENT, ConnectionStrings__DefaultConnection, Jwt__Issuer, Jwt__Audience, Jwt__SigningKey, Frontend__Origin
Persistent data: named PostgreSQL data volume and named event-upload volume
Frontend build/runtime: Node multi-stage build producing static assets served by nginx as a non-root user

Requirements:
- Use multi-stage builds, a non-root runtime user where supported, a small
  runtime image, .dockerignore, and deterministic restore layers.
- Add health checks and dependency health conditions without treating startup
  order as application readiness.
- Keep secrets out of Dockerfiles, Compose files, images, and Git; provide
  `.env.example` with placeholders only.
- Persist database/upload data in named volumes.
- Set production-safe environment defaults, restart behavior, and structured
  logs.
- Include commands to build, start, inspect health/logs, verify the endpoint,
  stop, and remove containers without deleting volumes by default.
- Do not add `--privileged`, mount the Docker socket, or expose the database
  publicly unless explicitly justified.

Output:
1. Assumptions and architecture summary.
2. Dockerfile(s), compose.yaml, .dockerignore, and .env.example with target
   paths.
3. Health endpoint implementation only if missing.
4. Verification script/commands.
5. Troubleshooting runbook for failed health, database connection, migration,
   CORS, and missing environment variables.

Acceptance criteria: images build from a clean checkout; services become
healthy; the API responds at the documented URL; no real secret is committed.
```
