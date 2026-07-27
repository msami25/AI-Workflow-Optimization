# AI Tool Test Results

## Important evidence rule

Record only runs that were actually performed. A generated answer is not a
passing result until the relevant code compiles and its tests pass. Replace all
`PENDING` cells before final submission and attach screenshots or terminal
clips in the technical Loom video.

## Test environment

| Item | Tool A | Tool B |
| --- | --- | --- |
| AI tool | OpenAI Codex | `{Claude Code / GitHub Copilot / Gemini CLI}` |
| Model/version | `{record exact value}` | `{record exact value}` |
| Date | `{YYYY-MM-DD}` | `{YYYY-MM-DD}` |
| Repository/commit | `{repository and hash}` | `{same repository and hash}` |
| .NET SDK | `{dotnet --version}` | `{same SDK}` |
| Prompt context | Same files and placeholder values | Same files and placeholder values |

## Fair-test method

1. Start both tools from the same clean Git commit.
2. Give each tool the same relevant files and completed prompt.
3. Do not give one tool corrections that the other tool did not receive.
4. Save the first response before refinement.
5. Apply the output in separate Git branches or worktrees.
6. Run the same build and test commands.
7. Record compile status, tests, warnings, manual fixes, and elapsed time.
8. If a prompt fails, refine the template once and rerun both tools.

Suggested branches:

```powershell
git switch -c test-prompts-codex
git switch -c test-prompts-second-tool
```

## Scoring rubric

Score each criterion from 0 to 2.

| Criterion | 0 | 1 | 2 |
| --- | --- | --- | --- |
| Completeness | Major sections missing | Minor omissions | Meets output contract |
| Correctness | Does not compile/unsafe | Compiles after fixes | Compiles without fixes |
| Architecture | Breaks project patterns | Mixed consistency | Matches existing patterns |
| Security | Introduces serious risk | Needs hardening | Respects stated boundaries |
| Tests | Missing/irrelevant | Partial useful tests | Required cases pass |
| Verification | No usable commands | Incomplete commands | Exact commands work |

Maximum score per run: **12**.

## Entity test data

Use both inputs to check whether prompts are truly generic.

### Entity A — Event

```text
Entity: Event
IdType: int
Properties: Title (required, max 150), Description (max 2000),
Location (required, max 200), StartUtc, EndUtc, Capacity (1-10000),
CategoryId, OrganizerId
Business rules: EndUtc must be later than StartUtc; Title + StartUtc +
Location must be unique; only Admin can delete
```

### Entity B — Category

```text
Entity: Category
IdType: int
Properties: Name (required, max 80), Description (max 500), IsActive
Business rules: Name is case-insensitively unique; a category referenced by an
event cannot be deleted; Admin writes and anonymous reads
```

## Template coverage matrix

Run each template at least once. Use Event for templates involving richer
behavior and Category to expose assumptions about simpler entities. For a
stronger submission, run Templates 1, 2, 4, 9, and 10 with both entities.

| # | Template | Entity/scenario | Tool A | Tool B | Evidence |
| --- | --- | --- | --- | --- | --- |
| 1 | API controller | Event and Category | PENDING | PENDING | Build + route/auth tests |
| 2 | EF Core CRUD service | Event and Category | PENDING | PENDING | Unit tests + query review |
| 3 | Entity/configuration | Event | PENDING | PENDING | Migration generated + tests |
| 4 | DTOs/validation | Event and Category | PENDING | PENDING | Boundary validation tests |
| 5 | Mapping | Event | PENDING | PENDING | Mapping configuration test |
| 6 | Exception handling | Event not found/conflict | PENDING | PENDING | ProblemDetails integration tests |
| 7 | Auth review | Admin event writes | PENDING | PENDING | 401/403 tests |
| 8 | File upload | Event image | PENDING | PENDING | Valid/spoofed/oversize tests |
| 9 | xUnit unit tests | Event and Category services | PENDING | PENDING | Filtered dotnet test |
| 10 | Integration tests | Event and Category endpoints | PENDING | PENDING | WebApplicationFactory tests |
| 11 | Performance | Event listing | PENDING | PENDING | Query count + latency |
| 12 | Docker/runbook | API + DB + frontend | PENDING | PENDING | Compose health + HTTP response |

## Detailed run record

Copy this section for each tool/template run.

### Run `{ID}` — Template `{number/name}`

| Field | Result |
| --- | --- |
| Tool/model | `{value}` |
| Git commit before run | `{hash}` |
| Entity/scenario | `{Event / Category / other}` |
| Start/end time | `{timestamps}` |
| First-response score | `{0-12}` |
| Files generated/changed | `{paths}` |
| Build command/result | `{command and pass/fail}` |
| Test command/result | `{command, passed, failed}` |
| New warnings | `{count/details}` |
| Manual corrections | `{none or exact edits}` |
| Prompt failure found | `{specific issue}` |
| Refinement applied | `{exact template wording change}` |
| Rerun result | `{score/build/tests}` |
| Evidence | `{Loom timestamp/screenshot/commit}` |

## Comparison summary

Complete after running both tools:

| Metric | Tool A | Tool B |
| --- | ---: | ---: |
| Average first-response score / 12 | PENDING | PENDING |
| Templates compiling without correction | PENDING | PENDING |
| Total tests generated and passing | PENDING | PENDING |
| Total manual corrections | PENDING | PENDING |
| Average time per task | PENDING | PENDING |

### Findings

```text
Tool A was strongest at: PENDING
Tool B was strongest at: PENDING
The most common first-run failure was: PENDING
The highest-value prompt refinement was: PENDING
Measured time saved compared with the previous manual workflow: PENDING
```

## Refinements already built into version 1.0

These changes came from reviewing common weaknesses in entity-specific prompts:

| Weak initial behavior | Refinement in this library |
| --- | --- |
| AI invented project structure | Requires inspection, assumptions, and target paths |
| Controllers contained EF/business logic | Requires thin controllers and service injection |
| Entities were bound directly to requests | Requires separate DTOs and over-posting tests |
| Async code omitted cancellation | Requires CancellationToken throughout |
| Broad catch blocks hid failures | Assigns error handling to centralized middleware |
| Security claims lacked proof | Requires 401/403 and token-behavior tests |
| File uploads trusted MIME/extension | Requires size, signature, random name, and traversal controls |
| Performance fixes were unmeasured | Requires baseline and before/after query/latency evidence |
| Outputs lacked verification | Every template requires exact build/test commands |
| Tool comparisons were subjective | Adds a repeatable 12-point rubric and identical inputs |
