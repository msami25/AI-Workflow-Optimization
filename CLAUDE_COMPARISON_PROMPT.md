# Claude inside Antigravity - comparison instructions

You are evaluating the reusable .NET prompt templates in this repository as
Tool B (Claude inside Antigravity). This is a controlled comparison against
Tool A. Follow these instructions exactly and do not commit or push.

## Integrity boundary

1. Work from repository commit
   `2a036ee0f78c23cb0f11574a5321616496a63991` and the current uncommitted
   evaluation packet. Do not checkout/reset/clean because the evaluation packet
   is intentionally uncommitted.
2. Read:
   - `evaluation/shared/TEST_CONTEXT.md`
   - `evaluation/shared/PROMPT_MANIFEST.sha256`
   - every file under `evaluation/shared/completed-prompts/`
   - `PROMPT_LIBRARY.md` only if needed to understand template numbering
   - the two scripts under `scripts/` only when running verification
3. Before answering, verify the SHA-256 hashes in
   `evaluation/shared/PROMPT_MANIFEST.sha256`. If any mismatch exists, stop and
   report it.
4. Do **not** open, search, summarize, or inspect:
   - `evaluation/codex/responses/`
   - `evaluation/codex/evidence/`
   - `evaluation/codex/CODEX_RESULTS.md`
   - `evaluation/codex/workspace/`
   - any Codex score or result quoted elsewhere
5. Do not modify anything under `evaluation/shared/` or `evaluation/codex/`.
6. Never simulate, predict, infer, or fabricate build results, test results,
   scores, timings, or Codex output.
7. The Template 3 completed prompt contains a Codex-specific `DataProject`
   path. Treat that string as part of the immutable input, but do not open or
   write that path. If applying Template 3, substitute only at execution time
   with the equivalent path under `evaluation/claude/workspace/` and record
   that as a manual execution correction; do not edit the completed prompt.

## Runs

There are 17 immutable prompt files covering all 12 templates. Run each one in
filename order. Templates 1, 2, 4, 9, and 10 have Event and Category variants.

For each prompt:

1. Use the completed prompt file byte-for-byte as the user/task input. Do not
   silently refine it.
2. Capture the unedited first response before making corrections.
3. Save that response under `evaluation/claude/responses/` using exactly the
   same filename as the input prompt.
4. Score the first response, not a revised answer.
5. Record assumptions, omissions, unsafe suggestions, invented files, and
   every manual correction.
6. Mark the highest honest state:
   - response-reviewed only
   - statically validated
   - compiled
   - test-verified
7. Do not claim compilation or passing tests unless the exact command was run
   successfully.

Use this 12-point rubric, scoring each criterion 0, 1, or 2:

| Criterion | 0 | 1 | 2 |
| --- | --- | --- | --- |
| Completeness | Major sections missing | Minor omissions | Meets output contract |
| Correctness | Does not compile/unsafe | Compiles after fixes | Compiles without fixes |
| Architecture | Breaks project patterns | Mixed consistency | Matches existing patterns |
| Security | Introduces serious risk | Needs hardening | Respects stated boundaries |
| Tests | Missing/irrelevant | Partial useful tests | Required cases pass |
| Verification | No usable commands | Incomplete commands | Exact commands work |

## Practical verification

Prioritize Templates 1, 2, 4, 9, and 10. Apply practical output only under:

```text
evaluation/claude/workspace/
```

Do not modify `demo` and do not use the Codex workspace. Use the actual `.sln`
or `.slnx` file created/reported by the installed SDK.

Run, where applicable:

```powershell
dotnet restore <actual-solution-path>
dotnet build <actual-solution-path> --configuration Release
dotnet test <actual-solution-path> --configuration Release
```

Also run, where coverage is applicable:

```powershell
.\scripts\Invoke-DotNetQualityGate.ps1 `
  -SolutionPath <actual-solution-path> `
  -Configuration Release `
  -CollectCoverage `
  -ResultsDirectory artifacts/EvaluationClaudeTestResults
```

Save concise, real command evidence under `evaluation/claude/evidence/`.
Generated `bin`, `obj`, coverage, TRX, and test-result directories must remain
ignored/untracked.

If a response fails to compile or a test fails:

1. preserve the first response;
2. record the exact failure;
3. make the minimum correction only inside the Claude workspace;
4. record the correction;
5. rerun and report both first and final results.

For response-only templates, do not create fake build evidence. State which
required files or measurements were unavailable.

## Required result file

Replace the placeholder content in
`evaluation/claude/CLAUDE_RESULTS.md` with:

- environment, exact Claude model/version if exposed, commit, SDK, and
  PowerShell version;
- a 17-row rubric table with all six component scores, total, and highest
  verified state;
- average across 17 prompt runs;
- average across 12 templates after averaging Event/Category variants;
- templates and prompt runs completed;
- outputs compiling without correction;
- corrected outputs compiling;
- tests generated/passing/failing;
- all manual corrections;
- average completion time only if timestamps were actually captured;
- strongest/weakest areas;
- assumptions, omissions, unsafe suggestions, and invented files;
- response-quality results separated from build-verified results;
- exact evidence paths.

Do not inspect or compare against Codex after finishing. Stop after completing
the Claude artifacts. Do not update `AI_TOOL_TEST_RESULTS.md`, `CHANGELOG.md`,
or create the final comparison report; the repository owner will do that only
after both independent result sets exist.

Finally run:

```powershell
git status --short
```

Confirm that only `evaluation/claude/` (plus ignored build artifacts) was
changed by Claude. Stop without committing or pushing.

