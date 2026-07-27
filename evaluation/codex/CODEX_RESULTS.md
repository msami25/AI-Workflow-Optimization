# Codex Evaluation Results

## Scope and methodology

- Baseline commit:
  `2a036ee0f78c23cb0f11574a5321616496a63991`
- Tool: OpenAI Codex, GPT-5 family (exact runtime build/model identifier was
  not exposed)
- Prompt inputs: 17 hash-frozen files in
  `evaluation/shared/completed-prompts/`
- Templates 1, 2, 4, 9, and 10 were run for both Event and Category.
- All other templates were run once with the scenario fixed in
  `TEST_CONTEXT.md`.
- Scores apply to the unedited first response, not the corrected workspace.
- Practical code was applied only in
  `evaluation/codex/workspace/PromptEvaluation.slnx`.
- No trustworthy per-prompt generation timer was available. Timing is
  therefore reported as not measured rather than inferred.

## Rubric results

Each criterion is 0-2: completeness (C), correctness (K), architecture (A),
security (S), tests (T), and verification (V).

| Prompt | C | K | A | S | T | V | Total | Highest verified state |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 01 Event controller | 1 | 1 | 2 | 2 | 1 | 2 | 9 | test-verified after corrections |
| 01 Category controller | 1 | 1 | 2 | 2 | 1 | 2 | 9 | test-verified after corrections |
| 02 Event service | 1 | 1 | 2 | 2 | 1 | 2 | 9 | test-verified after corrections |
| 02 Category service | 1 | 1 | 2 | 2 | 1 | 2 | 9 | test-verified after corrections |
| 03 Event model/configuration | 1 | 1 | 2 | 2 | 1 | 1 | 8 | response-reviewed only |
| 04 Event DTOs/validation | 1 | 1 | 2 | 2 | 1 | 2 | 9 | test-verified after corrections |
| 04 Category DTOs/validation | 1 | 1 | 2 | 2 | 1 | 2 | 9 | test-verified after corrections |
| 05 Event mapping | 1 | 1 | 2 | 2 | 0 | 1 | 7 | response-reviewed only |
| 06 ProblemDetails | 1 | 1 | 2 | 2 | 1 | 1 | 8 | response-reviewed only |
| 07 Auth review | 1 | 2 | 1 | 2 | 1 | 1 | 8 | response-reviewed only |
| 08 Secure upload | 1 | 1 | 2 | 2 | 1 | 1 | 8 | response-reviewed only |
| 09 Event unit tests | 1 | 1 | 2 | 2 | 1 | 2 | 9 | test-verified after corrections |
| 09 Category unit tests | 1 | 1 | 2 | 2 | 1 | 2 | 9 | test-verified after corrections |
| 10 Event integration tests | 1 | 1 | 2 | 2 | 1 | 2 | 9 | test-verified after corrections |
| 10 Category integration tests | 1 | 1 | 2 | 2 | 1 | 2 | 9 | test-verified after corrections |
| 11 Event list performance | 1 | 2 | 2 | 2 | 1 | 1 | 9 | response-reviewed only |
| 12 Docker/runbook | 1 | 1 | 2 | 2 | 0 | 1 | 7 | response-reviewed only |

- Average across 17 prompt runs: **8.53 / 12**
- Average after averaging variants within each of 12 templates:
  **8.33 / 12**
- Templates attempted: **12 / 12**
- Prompt runs completed: **17 / 17**
- First responses compiling without correction: **0 practical combined
  workspace runs**. The combined generated workspace initially failed to
  compile.
- Corrected practical workspace: **compiled, 0 warnings, 13/13 tests passed**
- Average completion time: **not measured**
- Measured development-time improvement: **not measured**

The “0 compiling without correction” metric is intentionally conservative.
Several template outputs shared one generated workspace and test factory, and
the first combined build failed; individual compile attribution would be
speculative.

## Per-template review notes

| Template | Assumptions/omissions/manual correction |
| --- | --- |
| 1 | Assumed service contracts and central conflict handler. Thin/authenticated controllers compiled after shared test-harness imports were fixed. 409 was not integration-tested. |
| 2 | Assumed DTO validation precedes service calls. Test matrices were partial; list paging is absent. Category/Event behavior passed after fixture correction. |
| 3 | Assumed an existing Organizer type that the isolated project did not contain. No migration was generated or rolled back. The completed prompt embeds a Codex workspace path, an input-neutrality defect documented below. |
| 4 | PUT replacement semantics assumed. Distinct list-item contracts and full boundary suites were omitted. |
| 5 | Manual mapping matched the repository choice, but computed fields and dedicated projection/protected-member tests were omitted. |
| 6 | Supplied a mapping/design but did not implement the typed `IExceptionHandler`; the workspace only used framework ProblemDetails. |
| 7 | Correctly refused confirmed findings without the requested auth/token/frontend files. No code patch was invented. |
| 8 | Covered major threats but did not supply or compile full storage code; malware scanning remained explicitly unavailable. |
| 9 | Tests were deterministic and relational but incomplete. The Event duplicate fixture initially omitted Category seed, causing the only executed test failure. |
| 10 | Real HTTP/auth/database paths were exercised. Missing 404/409/update/delete cases and parallel-safe database reset. |
| 11 | Correctly declined to claim improvement without baseline measurements. Proposed index remained conditional. |
| 12 | Safe runbook commands were given, but no Docker artifacts were produced or executed because source paths/health implementation were absent. |

## Unsafe suggestions, invented files, and corrections

- No credential, token, personal data, `--privileged`, Docker socket mount, or
  destructive volume command was introduced.
- No authorization or validation rule was weakened to obtain a green build.
- The isolated workspace files were intentionally created for evaluation; they
  were not represented as pre-existing production files.
- Template 3 assumed an Organizer model based on the prompt but did not invent
  it in compiled code.
- Manual corrections:
  1. add `Microsoft.Extensions.Logging` and rename the test scheme constant;
  2. add `Microsoft.Extensions.DependencyInjection`;
  3. seed the required Category in one Event service test.

## Verification evidence

Final commands and outputs are in `evidence/VERIFICATION.md`.

- Actual solution:
  `evaluation/codex/workspace/PromptEvaluation.slnx`
- Restore: passed
- Release build: passed, 0 warnings, 0 errors
- Tests: passed 13, failed 0, skipped 0
- Quality gate with XPlat coverage: passed
- Coverage/TRX build artifacts remain under ignored `artifacts/`

## Strongest and weakest areas

Strongest:

- architecture boundaries (thin controllers, DTOs, services, untracked
  projections);
- explicit write authorization;
- honesty when evidence or inspected files were unavailable;
- relational SQLite verification instead of EF InMemory.

Weakest:

- completeness of required test matrices and output sections;
- first-pass compile hygiene in the shared test fixture;
- unimplemented ProblemDetails, upload, migration, performance, and Docker
  scenarios;
- no per-prompt timing instrumentation.

## Evidence-based prompt refinements (not applied)

The original completed prompts remain unchanged.

1. **Neutral workspace placeholder:** Template 3's completed prompt resolved
   `DataProject` to a Codex-specific path. Add an explicit
   `{EvaluationWorkspace}` placeholder and require each tool to resolve it to
   its own isolated directory. This prevents cross-tool artifact access.
2. **Response versus implementation mode:** require the runner to declare
   `MODE=response-only|apply-and-verify` before answering. Several prompts
   demand complete code even when required repository files are not supplied,
   which encourages invented structure.
3. **Test coverage ledger:** require a checklist mapping every requested test
   case to a test method or an explicit `NOT IMPLEMENTED` entry. The practical
   first responses repeatedly omitted boundary and 404/409 cases while still
   sounding complete.
4. **First-build attribution:** for multi-template workspaces, require one
   commit-free snapshot/build per prompt before combining outputs. A shared
   harness made it impossible to attribute compile-without-correction fairly
   to an individual practical prompt.
5. **Timing protocol:** provide a start/end capture command and define whether
   package restore time is included. No defensible average time or development
   improvement can be calculated from this run.

These are recommendations only. No original prompt, response, score, or shared
manifest was changed.

