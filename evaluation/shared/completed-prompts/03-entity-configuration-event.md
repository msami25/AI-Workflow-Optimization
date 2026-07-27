# Completed Prompt - Template 3: entity-configuration-event

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
Act as an EF Core database designer. Design the Event model for an existing
.NET 8 application using EvaluationDbContext.

Required properties:
Id (int); Title (required, max 150); Description (optional, max 2000); Location (required, max 200); StartUtc and EndUtc (UTC); Capacity (1-10,000); CategoryId (int); OrganizerId (int)

Relationships and cardinality:
Event has one Category and one Organizer; Category and Organizer each have many Events

Required delete behavior:
Restrict deletion of referenced Category and Organizer records

Produce:
1. The entity class with nullable reference types handled correctly.
2. IEntityTypeConfiguration<Event> using Fluent API for table name, key,
   lengths, required fields, indexes, unique constraints, precision, foreign
   keys, and explicit delete behavior.
3. The minimal DbContext registration change.
4. A migration impact plan; do not hand-edit generated migration code.
5. Exact commands:
   dotnet ef migrations add AddEvent --project evaluation/codex/workspace/PromptEvaluation.Api/PromptEvaluation.Api.csproj
   dotnet ef database update --project evaluation/codex/workspace/PromptEvaluation.Api/PromptEvaluation.Api.csproj
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
