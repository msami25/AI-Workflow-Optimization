# Changelog

All notable changes to this toolkit are documented here.

## 1.2.0 - 2026-07-28

### Added

- A reusable EF Core migration automation script with preview-by-default
  behavior, `ShouldProcess`-guarded updates, context/environment selection, and
  stable exit codes.
- Explicit classification for no migrations, pending model changes, pending
  database migrations, unavailable databases, migration conflicts, and seed
  failures.
- Optional non-Production reseeding through a documented startup-project
  `--seed` entry point.
- An isolated EF Core SQLite fixture and repeatable PowerShell integration suite
  covering safe preview, apply/idempotency, failure recovery, and reseeding.

### Security

- Raw EF diagnostics are captured only for classification and never printed, so
  connection strings and provider credentials are not exposed by the script.
- Automatic Production reseeding is prohibited.

### Documented

- Migration usage, exit codes, seed contract, recovery examples, and actual
  verification commands/results.

## 1.1.0 - 2026-07-27

### Added

- A hash-frozen 17-prompt evaluation packet covering all 12 templates, with
  Event and Category variants for Templates 1, 2, 4, 9, and 10.
- Separate Codex and Antigravity response, workspace, scoring, and build/test
  evidence directories.
- A final evidence-audited comparison report and independent per-template
  rubric scores.
- Isolated `.NET 8` comparison workspaces so the successful `demo` project
  remained unchanged.

### Verified

- Codex corrected workspace: Release build passed with 0 warnings/errors and
  13/13 tests passed.
- Antigravity corrected workspace: Release build passed with 0 warnings/errors
  and 9/9 tests passed.
- Both quality gates generated XPlat coverage successfully.
- All shared prompt hashes still match their frozen manifest.

### Documented

- Tool B accurately as “Antigravity agent run: Claude followed by Gemini
  fallback”; Gemini took over after the Claude usage limit.
- The model transition as a comparison limitation rather than presenting Tool
  B as a pure Claude run.
- Unsupported Tool B self-score, environment, test-file, and
  compile-without-correction claims without deleting the raw artifact.
- Missing timing/manual-baseline evidence, so development-time improvement
  remains unmeasured.

## 1.0.0 - 2026-07-27

### Added

- Twelve reusable prompt templates covering .NET architecture, CRUD, security,
  testing, performance, observability, and deployment.
- A PowerShell module scaffolder with input validation, solution discovery,
  `-WhatIf` support, and elapsed-time reporting.
- A PowerShell quality gate for restore, Release/Debug builds, xUnit execution,
  TRX output, XPlat coverage, and optional HTML reports.
- A two-tool test protocol with an evidence-focused scoring rubric.
- Technical and non-technical Loom recording scripts.

### Refined

- Added explicit output contracts to reduce incomplete AI responses.
- Added verification commands and acceptance criteria to every template.
- Added security boundaries that prohibit secrets and unsafe destructive steps.
- Replaced entity-specific wording with reusable placeholders.
- Added `.slnx` support for modern .NET solutions.
