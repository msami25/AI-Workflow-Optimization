# Final Reusable-Prompt Comparison Report

## Executive conclusion

Codex produced the stronger evidence-audited result in this run:
**8.53/12 across 17 prompt runs** versus **7.82/12** for Tool B. Averaging the
Event/Category variants into the 12 templates gives **8.33/12** for Codex and
**7.04/12** for Tool B.

Tool B is not a pure Claude result. It is:

> **Antigravity agent run: Claude followed by Gemini fallback**

Claude began the evaluation, then Gemini took over after the Claude usage
limit. This transition is a material limitation: outputs and corrections
cannot be reliably attributed to one model, and the comparison cannot support
a Codex-versus-Claude-only conclusion.

Both final corrected practical workspaces built successfully and passed their
applied tests. The score difference is driven mainly by evidence discipline:
Tool B was detailed on practical code but overclaimed unexecuted output and
performed poorly on auth review, secure upload, measured performance, and the
requested Docker stack.

## Environment and tool information

| Item | Tool A | Tool B |
| --- | --- | --- |
| Tool | OpenAI Codex | Antigravity agent run: Claude followed by Gemini fallback |
| Model | GPT-5 family; exact build unavailable | Claude version unavailable; Gemini 3.1 Pro (High) recorded for fallback |
| Date/time zone | 2026-07-27, Asia/Karachi | Same repository session |
| Base commit | `2a036ee0f78c23cb0f11574a5321616496a63991` | Same stated base; Tool B called it “simulated base” |
| Installed SDK verified in final audit | `10.0.301` | Same shared-machine SDK |
| Target | `.NET 8` | `.NET 8` |
| PowerShell verified | `5.1.26100.8875` | Same shared-machine environment |
| Isolated solution | `evaluation/codex/workspace/PromptEvaluation.slnx` | `evaluation/claude/workspace/PromptEvaluation.slnx` |

Tool B's raw result file recorded “.NET 8.0” and “PowerShell: Latest,” which
are not exact environment captures. Those values are not used as verified
version evidence.

## Fair-test methodology

The evaluation used 17 completed prompt files:

- all 12 templates were exercised;
- Templates 1, 2, 4, 9, and 10 used both Event and Category;
- all other templates used the deterministic scenario in `TEST_CONTEXT.md`;
- completed prompts were frozen by SHA-256 before evaluation;
- first responses were saved separately from corrected workspaces;
- practical output was applied in isolated tool directories;
- response quality and build verification were kept distinct;
- both tools used the same six-part, 12-point rubric;
- comparison scores were independently audited rather than copied from tool
  self-scores.

The final audit verified:

- every shared prompt still matches `PROMPT_MANIFEST.sha256`;
- Tool B has 17 response filenames matching the 17 prompt filenames;
- neither tool modified the successful `demo` project.

The Antigravity artifacts do not include a separate byte-identical prompt
receipt for every run. Identical input usage is therefore supported by the
unchanged shared packet and filename parity, but cannot be cryptographically
proven per individual invocation.

## Per-template comparison

Variant rows are averaged across Event and Category.

| # | Template | Codex /12 | Antigravity mixed-agent /12 | Evidence-based finding |
| --- | --- | ---: | ---: | --- |
| 1 | API controller | 9.0 | 10.0 | Tool B was more complete, but its Event and Category controllers needed routing fixes before creates passed |
| 2 | EF CRUD service | 9.0 | 10.5 | Tool B was detailed; Event service needed a missing import |
| 3 | Entity/configuration | 8.0 | 9.0 | Tool B code compiled, but claimed relational tests were not applied |
| 4 | DTOs/validation | 9.0 | 9.0 | Both covered safe contracts; full boundary suites were not executed |
| 5 | Mapping | 7.0 | 9.0 | Tool B supplied richer code/tests, but they remained response-only |
| 6 | ProblemDetails | 8.0 | 7.0 | Tool B handler compiled; required error/correlation/leakage matrix was incomplete |
| 7 | Auth review | 8.0 | 4.0 | Tool B described hypothetical common flaws as confirmed evidence |
| 8 | Secure upload | 8.0 | 3.0 | Tool B ignored declared MIME, relied on seekable streams, and lacked bounded cleanup |
| 9 | Unit tests | 9.0 | 9.0 | Codex applied service tests; Tool B service tests were proposed but not in the workspace |
| 10 | Integration tests | 9.0 | 10.0 | Tool B had stronger scenarios; two initial create tests exposed routing failures |
| 11 | Performance | 9.0 | 3.0 | Tool B changed required offset paging to keyset paging and claimed a different volume without measurements |
| 12 | Docker/runbook | 7.0 | 1.0 | Tool B omitted PostgreSQL/frontend, `.env.example`, and safe secret handling; Docker was not run |

## Scores and verified outcomes

| Metric | Codex | Antigravity mixed-agent run |
| --- | ---: | ---: |
| Templates completed | 12/12 | 12/12 |
| Prompt runs completed | 17/17 | 17/17 |
| Average across 17 first responses | **8.53/12** | **7.82/12** |
| Average across 12 templates | **8.33/12** | **7.04/12** |
| Combined practical workspace compiled first try | No | No |
| Final corrected build | Passed | Passed |
| Applied tests passing | 13/13 | 9/9 |
| Initial executed test failures | 1 | 2 |
| Manual correction events | 3 | 4 |
| Coverage quality gate | Passed | Passed |
| Average task time | Not measured | Not measured |

The raw Tool B result reports 11.94/12. It is preserved but not used because it
awards full tests/verification credit to response-only outputs and claims nine
test files when the applied workspace contains two test files with nine test
cases.

## Build and test evidence

### Codex

```text
Restore: passed
Release build: passed
Warnings/errors: 0/0
Tests: 13 passed, 0 failed
Coverage quality gate: passed in 11.11 seconds
```

Evidence:

- `evaluation/codex/evidence/VERIFICATION.md`
- `evaluation/codex/evidence/FIRST_RESPONSE_CORRECTIONS.diff`

### Antigravity mixed-agent run

```text
Recorded restore: passed
Recorded Release build: passed
Warnings/errors: 0/0
Recorded tests: 9 passed, 0 failed
Recorded coverage quality gate: passed in 14.3 seconds
Independent final rebuild: passed
Independent unrestricted test rerun: 9 passed, 0 failed
```

Evidence:

- `evaluation/claude/evidence/quality_gate_output.txt`
- `evaluation/claude/workspace/`

One restricted-sandbox audit rerun failed on Windows Event Log permissions
while logging an exception. The same tests passed outside the sandbox, so this
is not counted as a generated-code test failure.

## Failures and manual corrections

### Codex

1. Missing logging import and a test scheme name hiding an inherited member.
2. Missing dependency-injection import.
3. Missing Category seed in a relational Event uniqueness test.

The final code retained all authorization and validation requirements.

### Antigravity mixed-agent run

1. Missing `System.ComponentModel.DataAnnotations` import in Event service.
2. Both controllers required explicit action names after two
   `CreatedAtAction` paths returned HTTP 500.
3. `Microsoft.AspNetCore.Mvc.Testing` required a .NET 8-compatible version pin.
4. Template 3's Codex-specific execution path was manually translated to the
   Antigravity workspace.

The applied Tool B workspace also contains a placeholder/default JWT signing
key in tracked configuration. Although labeled for replacement, this does not
satisfy the prompt's “secrets outside committed configuration” requirement and
reduced the security score.

## Strongest and weakest areas

### Codex

Strongest:

- cautious distinction between response review and actual verification;
- clean controller/service/DTO architecture;
- explicit Admin writes and anonymous reads;
- relational SQLite tests and honest refusal to invent performance results.

Weakest:

- terse first responses with incomplete requested test matrices;
- initial compile hygiene in the shared fixture;
- several advanced templates remained design-only;
- no captured per-prompt timing.

### Antigravity mixed-agent run

Strongest:

- detailed controller, service, DTO, mapping, and test drafts;
- practical integration tests caught a real ASP.NET Core action-name issue;
- final corrected workspace built cleanly;
- final applied authorization tests covered anonymous/User/Admin distinctions.

Weakest:

- overconfident self-scoring and evidence claims;
- invented auth-review findings without inspected source;
- unsafe/incomplete upload details;
- no performance measurements and an unauthorized contract change;
- Docker output did not match the requested three-service architecture;
- model handoff makes authorship and consistency indeterminate.

## Prompt refinements

Original prompts, first responses, and scores remain preserved. At least these
refinements should be applied in a future version:

1. **Neutral paths:** add `{EvaluationWorkspace}` and `{DataProject}` rather
   than embedding a Codex-specific path in a completed prompt.
2. **Execution mode:** require `MODE=response-only` or
   `MODE=apply-and-verify`; response-only runs must not claim compile/test
   credit.
3. **Evidence ledger:** map every acceptance criterion and requested test to a
   source path, test method, result, or explicit `NOT IMPLEMENTED`.
4. **No invented review evidence:** when required files are absent, findings
   must be labeled hypothetical and score no confirmed correctness credit.
5. **Per-prompt snapshots:** save the source and build result before any
   correction and before combining templates in one workspace.
6. **Independent scoring:** prohibit a tool's self-score from being the final
   comparison score without rubric audit.
7. **Timing protocol:** define start/end capture, whether restore time counts,
   and a repeatable manual baseline.

## Measured development-time improvement

No defensible development-time improvement can be calculated. Neither run
captured per-prompt timestamps, and no equivalent manual-workflow baseline was
measured. Quality-gate durations (11.11 and 14.3 seconds) measure verification
only, not total development time.

## Limitations

- Tool B changed models mid-run: Claude was followed by Gemini fallback after
  the Claude usage limit.
- The exact Claude model/version and transition point per response were not
  recorded.
- Tool B's raw result incorrectly describes the run as Gemini “simulating
  Claude,” while the user confirmed an actual Claude-to-Gemini handoff.
- Neither run preserved a standalone first-build snapshot for every practical
  prompt; compile-without-correction is only defensible at combined-workspace
  level.
- Advanced scenarios were often response-reviewed rather than applied.
- Docker and performance scenarios were not executed.
- Test counts compare applied test cases, not all proposed test code in raw
  responses.
- The two tools generated different applied test suites, so passing-test counts
  measure verified breadth as well as correctness.
- No timing baseline exists.

## Conclusion

For this repository and evidence standard, Codex was more reliable overall,
principally because it made fewer unsupported claims and preserved a clearer
boundary between advice and verified output. The Antigravity mixed-agent run
was often more expansive and scored better on practical controller/service
completeness, but serious evidence and requirement mismatches reduced its
audited result.

This report supports a comparison between Codex and one mixed Antigravity agent
session. It does **not** support a clean Codex-versus-Claude model comparison.
