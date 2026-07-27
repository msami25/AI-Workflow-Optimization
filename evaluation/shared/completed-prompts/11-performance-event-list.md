# Completed Prompt - Template 11: performance-event-list

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
Act as a senior .NET performance engineer. Diagnose and optimize GET /api/events.

Evidence:
Baseline to be measured with 50,000 seeded events; capture median/p95 latency and SQL command count before changing code

Expected data volume:
50,000 events, 500 categories, and 2,000 organizers

Fields actually required by the client:
Id, Title, Location, StartUtc, EndUtc, CategoryName, and remaining capacity

Paging requirement:
required pageNumber >= 1 and pageSize 1-100, default 50, ordered by StartUtc then Id

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
