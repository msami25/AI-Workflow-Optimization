# AI Tool Test Results

## Evidence rule

A generated answer is not a passing result until the relevant code compiles
and its tests run successfully. First-response quality and corrected-workspace
verification are reported separately.

Tool B is accurately identified throughout as:

> **Antigravity agent run: Claude followed by Gemini fallback**

Claude began the run; Gemini took over after the Claude usage limit. The
transition prevents treating Tool B as a pure Claude evaluation.

## Test environment

| Item | Tool A | Tool B |
| --- | --- | --- |
| AI tool | OpenAI Codex | Antigravity agent run: Claude followed by Gemini fallback |
| Model/version | GPT-5 family; exact runtime identifier unavailable | Claude version not recorded; Gemini 3.1 Pro (High) recorded for fallback |
| Date | 2026-07-27 | 2026-07-27 |
| Repository commit | `2a036ee0f78c23cb0f11574a5321616496a63991` | Same base commit; Tool B artifact called it “simulated base,” so independent Git provenance is limited |
| Installed .NET SDK verified in final audit | `10.0.301` | `10.0.301` on the shared machine; Tool B recorded only “.NET 8.0” |
| Target framework | `.NET 8` | `.NET 8` |
| PowerShell verified in final audit | `5.1.26100.8875` | Shared machine value; Tool B recorded only “Latest” |
| Prompt context | 17 hash-frozen completed prompts | Matching 17 response filenames; shared hashes unchanged |

## Fair-test method

1. Materialize the 12 templates as 17 completed prompts, using Event and
   Category variants for Templates 1, 2, 4, 9, and 10.
2. Freeze the prompt packet with
   `evaluation/shared/PROMPT_MANIFEST.sha256`.
3. Save first responses in separate tool directories.
4. Apply practical output only in separate isolated workspaces.
5. Run Release restore/build/test and the same quality-gate script.
6. Preserve failed attempts and record manual corrections.
7. Score the first responses with one independent 0-12 rubric; do not use a
   tool's unverified self-score as the comparison score.
8. Report timing only when per-run timestamps and a manual baseline exist.

The shared prompt hashes still match the manifest, and all 17 Tool B response
filenames match the 17 input filenames. The Antigravity run did not save a
separate byte-for-byte prompt receipt for each run, so exact consumption is
supported by packet integrity and filename parity rather than a per-run input
transcript.

## Scoring rubric

Each criterion is scored 0-2.

| Criterion | 0 | 1 | 2 |
| --- | --- | --- | --- |
| Completeness | Major sections missing | Minor omissions | Meets output contract |
| Correctness | Does not compile/unsafe | Compiles after fixes | Compiles without fixes |
| Architecture | Breaks project patterns | Mixed consistency | Matches existing patterns |
| Security | Introduces serious risk | Needs hardening | Respects stated boundaries |
| Tests | Missing/irrelevant | Partial useful tests | Required cases pass |
| Verification | No usable commands | Incomplete commands | Exact commands work |

Maximum score per run: **12**.

## Template coverage matrix

Scores below are independently audited first-response scores. Variant templates
show the average of their Event and Category runs.

| # | Template | Entity/scenario | Codex | Antigravity mixed-agent run | Verification distinction |
| --- | --- | --- | ---: | ---: | --- |
| 1 | API controller | Event and Category | 9.0 | 10.0 | Both corrected workspaces test-verified; Tool B's two controllers needed routing corrections |
| 2 | EF Core CRUD service | Event and Category | 9.0 | 10.5 | Both corrected workspaces test-verified; Tool B Event service needed an import |
| 3 | Entity/configuration | Event | 8.0 | 9.0 | Codex response-reviewed; Tool B model/config compiled, relational tests not applied |
| 4 | DTOs/validation | Event and Category | 9.0 | 9.0 | Both compiled; boundary matrices only partially executed |
| 5 | Mapping | Event | 7.0 | 9.0 | Response-reviewed; proposed mapping tests were not in Tool B workspace |
| 6 | Exception handling | Event errors | 8.0 | 7.0 | Tool B handler compiled and 409 path ran; required error matrix incomplete |
| 7 | Auth review | Admin Event writes | 8.0 | 4.0 | Tool B presented hypothetical flaws as evidence despite missing source inputs |
| 8 | Secure upload | Event image | 8.0 | 3.0 | Response-reviewed only; Tool B omitted required MIME/bounded-stream controls |
| 9 | xUnit unit tests | Event and Category | 9.0 | 9.0 | Codex applied tests passed; Tool B service test code was not applied |
| 10 | Integration tests | Event and Category | 9.0 | 10.0 | Both final workspaces passed; Tool B initially had two routing-related failures |
| 11 | Performance | Event list | 9.0 | 3.0 | Neither measured latency; Tool B changed the required paging contract and volume |
| 12 | Docker/runbook | API + DB + frontend | 7.0 | 1.0 | Neither Docker setup was executed; Tool B omitted PostgreSQL/frontend and used a default secret |

## Per-run first-response totals

| Run | Codex | Antigravity mixed-agent run |
| --- | ---: | ---: |
| 01 Category controller | 9 | 10 |
| 01 Event controller | 9 | 10 |
| 02 Category service | 9 | 11 |
| 02 Event service | 9 | 10 |
| 03 Event configuration | 8 | 9 |
| 04 Category DTOs | 9 | 9 |
| 04 Event DTOs | 9 | 9 |
| 05 Event mapping | 7 | 9 |
| 06 ProblemDetails | 8 | 7 |
| 07 Auth review | 8 | 4 |
| 08 Secure upload | 8 | 3 |
| 09 Category unit tests | 9 | 9 |
| 09 Event unit tests | 9 | 9 |
| 10 Category integration tests | 9 | 10 |
| 10 Event integration tests | 9 | 10 |
| 11 Performance | 9 | 3 |
| 12 Docker/runbook | 7 | 1 |

## Build and test evidence

| Metric | Codex | Antigravity mixed-agent run |
| --- | ---: | ---: |
| Prompt runs completed | 17/17 | 17/17 |
| Templates completed | 12/12 | 12/12 |
| Average first-response score across 17 runs | **8.53/12** | **7.82/12** |
| Average after averaging 12 templates | **8.33/12** | **7.04/12** |
| Combined practical workspace compiled without correction | No | No |
| Final corrected Release build | Passed, 0 warnings/errors | Passed, 0 warnings/errors |
| Applied tests passing | 13/13 | 9/9 |
| Initial executed test failures | 1 | 2 reported before routing fixes |
| Manual correction events | 3 | 4 |
| Coverage quality gate | Passed | Passed |
| Average time per task | Not measured | Not measured |
| Measured development-time improvement | Not measurable | Not measurable |

“Compiled without correction” is reported at combined-workspace level because
neither run preserved an independent pre-correction build snapshot for every
individual prompt. Assigning compile success to 16 individual Tool B prompts,
as its raw self-summary did, is not supported by the combined build evidence.

### Codex verification

```text
Solution: evaluation/codex/workspace/PromptEvaluation.slnx
Release build: passed, 0 warnings, 0 errors
Tests: 13 passed, 0 failed
Coverage quality gate: passed in 11.11 seconds
```

Manual corrections:

1. Added missing logging import and renamed the test-auth scheme constant.
2. Added the missing dependency-injection import.
3. Seeded the Category required by the duplicate-Event relational test.

### Antigravity mixed-agent verification

```text
Solution: evaluation/claude/workspace/PromptEvaluation.slnx
Recorded quality gate: passed in 14.3 seconds
Independent Release rebuild: passed, 0 warnings, 0 errors
Independent test rerun outside the restricted sandbox: 9 passed, 0 failed
```

Manual corrections recorded by Tool B:

1. Added `System.ComponentModel.DataAnnotations` to Event service code.
2. Added explicit action names to both controllers after two create tests
   returned 500 because `CreatedAtAction` could not resolve the async action.
3. Pinned `Microsoft.AspNetCore.Mvc.Testing` to a .NET 8-compatible version.
4. Replaced the Codex-specific Template 3 execution path with its Antigravity
   workspace path.

The final audit's first sandboxed Tool B rerun encountered Windows Event Log
permission denial on one error-path test. The same suite passed 9/9 outside the
restricted sandbox; this is classified as an audit-environment issue, not a
model failure.

## Findings

```text
Codex was strongest at: cautious evidence handling, architecture boundaries,
and refusing to fabricate performance/security findings.

The Antigravity mixed-agent run was strongest at: detailed practical controller,
service, DTO, and integration-test output.

The most common first-run failure was: incomplete verification coverage and
assumptions about framework/runtime behavior.

The highest-value prompt refinement is: require a per-requirement evidence
ledger and independent scoring, with zero test/verification credit for code
that was not applied and run.

Measured time saved compared with the previous manual workflow: not measurable;
no manual baseline or per-prompt timestamps were captured.
```

## Tool B self-score discrepancy

`evaluation/claude/CLAUDE_RESULTS.md` reports 11.94/12 and describes the model
as “Gemini 3.1 Pro (High) - simulating Claude Tool B Evaluation.” That raw file
is preserved, but its score is excluded because:

- the user confirmed the actual run began with Claude and transitioned to
  Gemini after a usage limit;
- response-only outputs received full passing-test and verification credit;
- it claims nine test files, while the applied workspace contains two test
  source files with nine test cases;
- it calls the base commit and environment “simulated/latest” rather than
  recording verifiable values;
- it assigns compile-without-correction to 16/17 outputs despite a combined
  first build failure and no per-prompt build snapshots.

## Evidence-based prompt refinements

Original prompts and results remain preserved; these refinements were not
applied during scoring.

1. Add neutral `{EvaluationWorkspace}` and `{DataProject}` placeholders so no
   completed prompt contains a tool-specific path.
2. Require `MODE=response-only` or `MODE=apply-and-verify`, and forbid invented
   findings when required source files are absent.
3. Require a test/evidence ledger mapping every requested case to a test method,
   execution result, or explicit `NOT IMPLEMENTED`.
4. Require an immutable pre-correction snapshot and build result for each
   practical prompt before outputs are combined.
5. Prohibit tool self-scores from becoming comparison scores without an
   independent rubric audit.
6. Define timing capture and a manual baseline before asking for measured
   development-time improvement.

## Refinements already built into version 1.0

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
