# Shared Evaluation Context

## Frozen baseline

- Repository commit: `2a036ee0f78c23cb0f11574a5321616496a63991`
- Evaluation date: `2026-07-27`
- Target framework: `.NET 8`
- Installed SDK used for verification: `10.0.301`
- PowerShell: `5.1.26100.8875`
- Application type: ASP.NET Core Web API
- Architecture: layered API with controllers, services, EF Core `DbContext`,
  DTOs, and centralized exception handling
- Database: SQLite
- ORM: EF Core 8
- Tests: xUnit, Moq, `WebApplicationFactory`, SQLite in-memory
- Conventions: nullable reference types, file-scoped namespaces, async APIs
  with `CancellationToken`, UTC timestamps, and explicit DTO mapping

## Event

- `Id`: `int`
- `Title`: required, maximum 150 characters
- `Description`: optional, maximum 2000 characters
- `Location`: required, maximum 200 characters
- `StartUtc` and `EndUtc`: UTC timestamps
- `Capacity`: 1 through 10,000
- `CategoryId`: `int`
- `OrganizerId`: `int`
- `EndUtc` must be later than `StartUtc`
- `(Title, StartUtc, Location)` is unique
- Only `Admin` can create, update, or delete

## Category

- `Id`: `int`
- `Name`: required, maximum 80 characters
- `Description`: optional, maximum 500 characters
- `IsActive`: `bool`
- `Name` is unique using case-insensitive comparison
- A category referenced by an event cannot be deleted
- Reads are anonymous; writes require `Admin`

## Fixed scenario choices

- Event uploads are JPEG or PNG, at most 5 MiB, stored in an isolated local
  volume outside the content root. No malware scanner is available.
- Authentication is JWT bearer with short-lived access tokens and rotating
  refresh tokens in Secure, HttpOnly cookies. The frontend origin is
  `https://localhost:5173`.
- Correlation uses `X-Correlation-ID`; production errors contain safe generic
  detail while development may include a safe diagnostic code, never secrets
  or stack traces.
- Performance evaluation targets `GET /api/events` with 50,000 events and a
  page size of 50.
- Deployment uses API, PostgreSQL, and frontend services. The API is published
  at `http://localhost:8080` and exposes `/health`.

## Fairness and evidence rules

1. Each tool receives the byte-identical completed prompt file.
2. Each saved response is the unedited first answer for that prompt.
3. No tool may inspect the other tool's answers or scores before finishing its
   own first responses.
4. A response is scored from 0 to 2 for completeness, correctness,
   architecture, security, tests, and verification (maximum 12).
5. Compilation or passing tests may be claimed only when the recorded command
   actually succeeded.
6. Response review and build verification are reported separately.
7. Shared prompts are immutable after the SHA-256 manifest is recorded.

