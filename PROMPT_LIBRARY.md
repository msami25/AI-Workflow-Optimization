---
title: Reusable .NET Prompt Library
version: 1.0.0
last_tested: 2026-07-27
target_framework: .NET 8
maintainer: Muhammad Samiullah
---

# Reusable .NET Prompt Library

These templates are designed for real ASP.NET Core projects. Replace every
value in `{braces}` before use. Give the AI only the relevant project files and
never include secrets or production data.

## Shared project context

Paste this block before a template when starting a new AI session:

```text
Project: {ProjectName}
Framework: {TargetFramework, e.g., .NET 8}
Application type: {ASP.NET Core Web API / Worker / MVC}
Architecture: {CurrentArchitecture}
Database: {SQL Server / PostgreSQL / SQLite}
ORM: {EF Core version}
Test stack: {xUnit, Moq, WebApplicationFactory}
Existing conventions: {Nullable enabled, file-scoped namespaces, naming rules}

Work only within the requested scope. Preserve existing behavior unless a
change is explicitly requested. Do not invent files, methods, packages, or
requirements. Do not expose secrets. First state assumptions and the files you
need to inspect. After implementation, list changed files, verification
commands, risks, and any remaining work.
```

## Template 1 — ASP.NET Core API controller

**Use for:** a thin REST controller backed by an existing service.

**Placeholders:** `{Entity}`, `{IdType}`, `{Route}`, `{ReadRole}`,
`{WriteRole}`, `{ProjectNamespace}`.

```text
Act as a senior ASP.NET Core developer. Create a production-ready
{Entity}Controller in {ProjectNamespace} for route "api/{Route}".

Context:
- Entity identifier type: {IdType}
- Read authorization: {ReadRole or Anonymous}
- Create/update/delete authorization: {WriteRole}
- Business logic belongs in I{Entity}Service, not the controller.
- Use request/response DTOs; never bind the EF entity directly.

Required endpoints:
- GET /api/{Route}
- GET /api/{Route}/{id}
- POST /api/{Route}
- PUT /api/{Route}/{id}
- DELETE /api/{Route}/{id}

Requirements:
- Use [ApiController], attribute routing, constructor injection, async/await,
  CancellationToken, ActionResult, and ILogger<{Entity}Controller>.
- Return 200 for successful reads, 201 with CreatedAtAction for create, 204 for
  update/delete, 400 for invalid input, 404 when absent, and 409 for a known
  business conflict.
- Apply explicit [Authorize] policies/roles to write operations. Do not weaken
  any existing authorization.
- Rely on centralized exception handling; do not add broad catch blocks.
- Keep methods thin and avoid returning stack traces or internal exception
  messages.

Output in this order:
1. Assumptions and required existing interfaces/DTOs.
2. Complete controller code.
3. Any minimal supporting contracts that are missing, each in a separate code
   block with its target path.
4. Unit/integration test cases covering status codes and authorization.
5. dotnet build and dotnet test commands.

Acceptance criteria: code compiles on {TargetFramework}; routes are unambiguous;
write endpoints reject unauthenticated and unauthorized users; no EF Core
queries occur inside the controller.
```

**Example values:** `Entity=Event`, `IdType=int`, `Route=events`,
`WriteRole=Admin`.

## Template 2 — EF Core CRUD service

**Use for:** an application service containing CRUD business logic.

**Placeholders:** `{Entity}`, `{IdType}`, `{DbContext}`,
`{MutableProperties}`, `{UniqueRule}`.

```text
Act as a senior .NET backend developer. Implement {Entity}Service for
I{Entity}Service using {DbContext} and EF Core.

Inputs:
- Identifier: {IdType}
- Mutable properties: {MutableProperties}
- Uniqueness/business rule: {UniqueRule or None}

Implement GetAllAsync, GetByIdAsync, CreateAsync, UpdateAsync, and DeleteAsync.
Use CancellationToken on every async method.

Constraints:
- Use AsNoTracking for read-only queries.
- Project to response DTOs rather than returning tracked entities.
- Use FindAsync or SingleOrDefaultAsync appropriately; explain the choice.
- Never call Update with an untrusted detached request object.
- Load the existing record, map only allowed properties, and save once.
- Treat a missing record and a uniqueness conflict as typed/domain results or
  documented exceptions that middleware can map to 404/409.
- Log useful identifiers but no secrets or personal data.
- Do not add try/catch merely to log and rethrow.
- Avoid repository abstractions if the project already treats DbContext as the
  unit of work.

Output:
1. Assumptions.
2. Interface signatures if changes are required.
3. Complete service code and target path.
4. DTO/mapping code only if missing.
5. Tests for empty list, found/not found, valid create, conflict, partial
   update protection, delete, and cancellation.
6. Build/test commands and a short performance note.

Acceptance criteria: async database calls are used; reads do not track; over-
posting is prevented; SaveChangesAsync is called only for successful writes.
```

## Template 3 — Entity, configuration, and migration plan

**Use for:** safely adding an EF Core entity and database relationship.

**Placeholders:** `{Entity}`, `{Properties}`, `{Relationships}`,
`{DeleteBehavior}`, `{DbContext}`, `{MigrationName}`.

```text
Act as an EF Core database designer. Design the {Entity} model for an existing
{TargetFramework} application using {DbContext}.

Required properties:
{Properties}

Relationships and cardinality:
{Relationships}

Required delete behavior:
{DeleteBehavior}

Produce:
1. The entity class with nullable reference types handled correctly.
2. IEntityTypeConfiguration<{Entity}> using Fluent API for table name, key,
   lengths, required fields, indexes, unique constraints, precision, foreign
   keys, and explicit delete behavior.
3. The minimal DbContext registration change.
4. A migration impact plan; do not hand-edit generated migration code.
5. Exact commands:
   dotnet ef migrations add {MigrationName} --project {DataProject}
   dotnet ef database update --project {DataProject}
6. Tests for constraints and relationships using the project's relational test
   provider. Do not use EF InMemory to prove relational constraints.

Safety constraints:
- Do not drop or rename existing production columns without a staged migration
  and rollback/data-migration plan.
- Avoid cascade paths that can delete unrelated data.
- Store UTC timestamps using the project's established convention.
- Do not put connection strings or credentials in source code.

Acceptance criteria: the model reflects the stated cardinality, migrations are
repeatable, indexes support expected lookups, and rollback risk is documented.
```

## Template 4 — Request/response DTOs and validation

**Use for:** safe API contracts and server-side validation.

**Placeholders:** `{Entity}`, `{Fields}`, `{ValidationRules}`,
`{ValidationLibrary}`, `{MappingApproach}`.

```text
Act as an API contract designer. Create DTOs and validation for {Entity}.

Fields:
{Fields}

Rules:
{ValidationRules}

Use {ValidationLibrary, e.g., DataAnnotations or FluentValidation} and
{MappingApproach, e.g., manual mapping or AutoMapper}.

Create separate contracts when their responsibilities differ:
- {Entity}CreateRequest
- {Entity}UpdateRequest
- {Entity}Response
- {Entity}ListItemResponse

Requirements:
- Do not expose internal fields, password hashes, refresh tokens, row-version
  internals, or navigation cycles.
- Distinguish omitted optional values from values that should be cleared.
- Enforce length/range/format rules server-side.
- Use a consistent validation error response compatible with ProblemDetails.
- Prevent clients from assigning protected fields such as Id, OwnerId, Role,
  CreatedAt, or IsApproved.
- Ensure mapping is explicit and testable.

Output:
1. Assumptions about nullability and update semantics.
2. DTO and validator code with target paths.
3. Mapping code.
4. Controller/service integration snippet.
5. Tests for valid boundaries, invalid boundaries, null/empty values, and
   protected-field over-posting.

Acceptance criteria: invalid input produces 400 with useful field errors and no
domain or persistence entity is used as an API request body.
```

## Template 5 — Mapping profile and mapping tests

**Use for:** repeatable AutoMapper or manual mappings.

**Placeholders:** `{SourceTypes}`, `{DestinationTypes}`,
`{ProtectedMembers}`, `{ComputedFields}`, `{MappingApproach}`.

```text
Act as a .NET mapping specialist. Implement {MappingApproach} mappings between:

Sources: {SourceTypes}
Destinations: {DestinationTypes}
Protected destination members: {ProtectedMembers}
Computed/renamed fields: {ComputedFields}

Requirements:
- Follow the mapping approach already used by the repository.
- Never map protected members from client-controlled request DTOs.
- Make reverse mapping explicit; do not use ReverseMap when directions have
  different security rules.
- Handle nested objects and null values without producing reference cycles.
- For EF Core list queries, prefer a server-side projection that selects only
  required response fields.
- Do not silently ignore a destination member without documenting why.

Output:
1. Mapping table: source field -> destination field -> transformation.
2. Complete profile/helper code with target path.
3. Query projection example.
4. Configuration validation test plus tests for protected and computed fields.
5. Commands to run the tests.

Acceptance criteria: configuration validation passes; protected fields cannot
be overwritten; list mapping can be translated by EF Core when required.
```

## Template 6 — Centralized exception handling and ProblemDetails

**Use for:** consistent, secure API errors and logs.

**Placeholders:** `{ExceptionTypes}`, `{StatusMappings}`,
`{CorrelationHeader}`, `{EnvironmentRules}`.

```text
Act as an ASP.NET Core reliability engineer. Add centralized exception handling
using IExceptionHandler and ProblemDetails for {TargetFramework}.

Map these exception types:
{ExceptionTypes}

Required HTTP mappings:
{StatusMappings}

Correlation header: {CorrelationHeader, e.g., X-Correlation-ID}
Environment behavior: {EnvironmentRules}

Requirements:
- Register the handler and ProblemDetails in Program.cs in the correct order.
- Return RFC-style ProblemDetails with status, title, safe detail, instance,
  error code, and correlation/trace identifier.
- Never expose a stack trace, SQL text, connection string, token, or internal
  exception message in production.
- Log an expected 4xx domain error below Error level and unexpected 5xx errors
  at Error with the exception object.
- Preserve cancellation behavior; do not convert client cancellation into 500.
- Avoid duplicate logging in controllers/services and the handler.

Output:
1. Exception-to-status mapping table.
2. Complete handler code.
3. Program.cs changes with placement instructions.
4. Integration tests for known 400/404/409 errors, unexpected 500, production
   data leakage, and correlation IDs.
5. Verification commands and sample safe JSON response.

Acceptance criteria: every tested error uses one consistent shape, production
responses contain no sensitive details, and logs retain diagnostic context.
```

## Template 7 — Authentication and authorization review

**Use for:** auditing JWT and role/policy protection.

**Placeholders:** `{AuthFlow}`, `{Roles}`, `{ProtectedEndpoints}`,
`{TokenLocation}`, `{FrontendOrigin}`.

```text
Act as a .NET application security reviewer. Review and harden this
authentication/authorization flow:

Auth flow: {AuthFlow}
Roles/policies: {Roles}
Protected endpoints: {ProtectedEndpoints}
Access/refresh token location: {TokenLocation}
Allowed frontend origin: {FrontendOrigin}

Inspect the supplied Program.cs, auth service, token service, controllers,
configuration, and frontend HTTP client before proposing changes.

Check:
- JWT issuer, audience, signature, lifetime, clock skew, and key length.
- Access-token expiry and refresh-token rotation/revocation/reuse detection.
- Whether role claims use the same claim type expected by authorization.
- Explicit authorization on every state-changing/admin endpoint.
- Secure, HttpOnly, SameSite, and HTTPS cookie settings where cookies are used.
- Exact CORS origins; never combine wildcard origins with credentials.
- Rate limiting and generic login errors to reduce brute force/user discovery.
- Secret storage outside committed configuration.
- Logout/session invalidation and audit logging without token leakage.

Output:
1. Findings table: severity, evidence, risk, recommended fix.
2. Minimal patch plan ordered by risk.
3. Code changes only for confirmed issues.
4. Unit/integration tests proving 401 vs 403, role enforcement, expired token,
   invalid signature, refresh rotation, and revoked token behavior.
5. Commands and manual verification steps.

Do not claim compliance or security perfection. State what was not inspected.
Acceptance criteria: anonymous, authenticated, and authorized cases are tested;
no secret/token value appears in source, response bodies, or logs.
```

## Template 8 — Secure file upload

**Use for:** adding or auditing image/document uploads.

**Placeholders:** `{AllowedTypes}`, `{MaxBytes}`, `{StorageType}`,
`{VirusScanner}`, `{AuthorizationRule}`.

```text
Act as an ASP.NET Core file-upload security engineer. Implement or review file
upload with these rules:

Allowed business file types: {AllowedTypes}
Maximum size: {MaxBytes}
Storage: {StorageType, e.g., isolated local volume or object storage}
Malware scanning: {VirusScanner or Not available}
Authorization: {AuthorizationRule}

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

## Template 9 — xUnit unit tests

**Use for:** focused tests of an existing class.

**Placeholders:** `{ClassUnderTest}`, `{BehaviorList}`, `{Dependencies}`,
`{TestData}`, `{MockingLibrary}`.

```text
Act as a .NET test engineer. Write maintainable xUnit tests for
{ClassUnderTest}.

Public behaviors to test:
{BehaviorList}

Dependencies:
{Dependencies}

Representative data and boundaries:
{TestData}

Use {MockingLibrary, e.g., Moq or NSubstitute} only for true external
collaborators.

Requirements:
- Test observable behavior, not private implementation.
- Follow Arrange-Act-Assert and use names in
  Method_Scenario_ExpectedResult form.
- Cover success, boundary, not-found, invalid input, dependency failure, and
  cancellation when applicable.
- Verify important side effects exactly, including that writes do not occur
  after validation fails.
- Avoid DateTime.Now, random values, network calls, shared mutable fixtures,
  Thread.Sleep, and order-dependent tests.
- Reuse the project's fixture/builders before creating new helpers.

Output:
1. Behavior-to-test matrix.
2. Complete test class and only necessary fixture changes.
3. Explanation of anything intentionally not mocked.
4. Exact filtered test command.
5. Gaps that need integration rather than unit tests.

Acceptance criteria: tests are deterministic, compile, can run independently,
and fail for the intended behavior regression rather than implementation churn.
```

## Template 10 — Web API integration tests

**Use for:** end-to-end HTTP behavior inside a test host.

**Placeholders:** `{Endpoints}`, `{AuthCases}`, `{DatabaseProvider}`,
`{SeedData}`, `{ExternalServices}`.

```text
Act as an ASP.NET Core integration-test specialist. Add xUnit integration tests
using WebApplicationFactory for:

Endpoints: {Endpoints}
Authorization cases: {AuthCases}
Relational test provider: {DatabaseProvider, e.g., SQLite in-memory/Testcontainer}
Seed data: {SeedData}
External services to replace: {ExternalServices}

Requirements:
- Reuse the existing test factory if present.
- Isolate database state per test or test class and make seeds deterministic.
- Prefer a relational provider when query translation, indexes, constraints, or
  transactions matter; explain any EF InMemory use.
- Replace external HTTP, email, file, and time dependencies with controlled
  test doubles through DI.
- Send real HTTP requests through HttpClient and deserialize responses.
- Test status, body contract, persistence effect, authorization, validation,
  duplicate/conflict behavior, and not found.
- Do not bypass middleware unless the test explicitly targets a lower layer.

Output:
1. Scenario matrix.
2. Factory/fixture changes.
3. Complete tests.
4. Required package changes with justification.
5. Exact dotnet test command and cleanup notes.

Acceptance criteria: tests pass repeatedly and in any order; 401, 403, 400, 404,
409, and success paths are covered where applicable.
```

## Template 11 — EF Core performance and N+1 diagnosis

**Use for:** investigating a slow list/detail endpoint.

**Placeholders:** `{Endpoint}`, `{LatencyEvidence}`, `{ExpectedVolume}`,
`{RequiredFields}`, `{PagingRule}`.

```text
Act as a senior .NET performance engineer. Diagnose and optimize {Endpoint}.

Evidence:
{LatencyEvidence}

Expected data volume:
{ExpectedVolume}

Fields actually required by the client:
{RequiredFields}

Paging requirement:
{PagingRule}

First inspect the controller, service, EF Core query, DTO mapping, generated SQL
or query logs, and any per-item external calls. Identify evidence of N+1,
over-fetching, client-side evaluation, missing pagination, tracking overhead,
unbounded Include chains, repeated Count/Any queries, or sync-over-async.

Requirements:
- Establish a reproducible baseline: request, data volume, query count, and
  elapsed time.
- Prefer one server-translatable projection with AsNoTracking and deterministic
  ordering.
- Add bounded pagination and cancellation.
- Recommend an index only when the predicate/order supports it; include the
  migration and write-cost tradeoff.
- Do not cache user-specific/sensitive data without an invalidation and
  authorization analysis.
- Preserve response behavior or clearly document the contract change.

Output:
1. Root-cause evidence.
2. Before/after query shape and minimal code patch.
3. Tests preventing regression.
4. Measurement commands and comparison table.
5. Remaining risks.

Acceptance criteria: improvement is supported by measured query count/latency,
not merely claimed; tests confirm response correctness and page bounds.
```

## Template 12 — Docker deployment and operational runbook

**Use for:** containerizing and verifying a local .NET stack.

**Placeholders:** `{Services}`, `{ApiPort}`, `{HealthPath}`,
`{EnvironmentVariables}`, `{PersistentData}`, `{FrontendBuild}`.

```text
Act as a DevOps engineer for a {TargetFramework} application. Create or review a
local Docker Compose setup.

Services: {Services}
Published API URL/port: {ApiPort}
Health endpoint: {HealthPath}
Required environment variables (names only): {EnvironmentVariables}
Persistent data: {PersistentData}
Frontend build/runtime: {FrontendBuild}

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

## Refinement checklist

Before accepting AI-generated output, verify:

- [ ] Every placeholder was replaced.
- [ ] The AI inspected relevant existing files instead of inventing structure.
- [ ] Generated code targets the stated .NET version.
- [ ] DTOs protect server-controlled fields.
- [ ] Authentication and authorization were not weakened.
- [ ] Logs and errors reveal no secrets or internal stack traces.
- [ ] Async methods accept and pass CancellationToken.
- [ ] EF Core reads avoid tracking and N+1 where appropriate.
- [ ] Tests verify behavior, failure cases, and authorization.
- [ ] Package additions are necessary and compatible.
- [ ] `dotnet build` succeeds with no new warnings.
- [ ] `dotnet test` passes.
- [ ] Any migration, deployment, or deletion step has a rollback plan.

## Versioning convention

- **Patch**: wording or constraint refinement without changing expected output.
- **Minor**: new template or new required output section.
- **Major**: placeholder or output-contract changes that break existing usage.

When refining a template, record the failure, the prompt change, and the new
test result in `AI_TOOL_TEST_RESULTS.md`, then update `CHANGELOG.md`.
