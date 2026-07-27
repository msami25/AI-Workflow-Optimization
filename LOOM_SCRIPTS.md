# Loom Video Scripts

## Before recording

- Close notifications and hide secrets, tokens, connection strings, and
  personal browser tabs.
- Increase terminal and editor font size.
- Open `PROMPT_LIBRARY.md`, both scripts, and `AI_TOOL_TEST_RESULTS.md`.
- Use a clean demo directory so the module script does not alter production
  code.
- Keep the technical video around 4–5 minutes and the non-technical video
  around 2–3 minutes.

## Video 1 — Technical walkthrough

### 0:00–0:30 — Purpose and structure

Say:

> This is my reusable .NET prompt and automation toolkit. It contains twelve
> practical prompt templates, two PowerShell scripts, a repeatable two-AI-tool
> evaluation, usage instructions, and a changelog. The goal is to make AI
> output consistent, secure, and verifiable instead of rewriting instructions
> for every feature.

Show the repository files in the editor.

### 0:30–1:35 — Prompt template design

Open `PROMPT_LIBRARY.md`.

Say:

> Every template has a defined use case, reusable placeholders, technical
> constraints, an output contract, and acceptance criteria. For example, the
> controller template requires thin controllers, DTOs, authorization,
> cancellation tokens, correct status codes, and tests. I can replace Entity
> with Event or Category without rewriting the whole prompt.

Briefly show Templates 1, 7, 8, 9, and 11.

Say:

> The collection covers controller and service scaffolding, EF Core models,
> validation and mapping, exception handling, authentication, secure uploads,
> unit and integration tests, performance diagnosis, and Docker deployment.
> The security templates explicitly prohibit secrets and require evidence such
> as 401/403 tests, while the performance template requires measured results.

### 1:35–2:30 — Module automation

Open `scripts/New-DotNetModule.ps1`.

Say:

> The first PowerShell script validates its inputs, finds a modern .sln or
> .slnx solution, creates an application library and xUnit test project, adds
> both to the solution, creates standard folders, adds the project reference,
> restores packages, and reports elapsed time. It also supports WhatIf so I can
> preview the operation safely.

Show:

```powershell
.\scripts\New-DotNetModule.ps1 -ModuleName Notifications -WhatIf
```

Then show a real demo command or its successful result:

```powershell
.\scripts\New-DotNetModule.ps1 `
  -ModuleName Notifications `
  -SolutionPath .\demo\ToolkitDemo.sln `
  -SourceDirectory demo\src `
  -TestDirectory demo\tests `
  -CreateSolution
```

### 2:30–3:15 — Quality gate automation

Open `scripts/Invoke-DotNetQualityGate.ps1`.

Say:

> The second script combines restore, build, and test into one quality gate. It
> stops on the first failure, produces TRX test evidence, optionally collects
> XPlat coverage, and can generate an HTML report. This prevents generated code
> from being accepted only because it looks correct.

Run:

```powershell
.\scripts\Invoke-DotNetQualityGate.ps1 `
  -SolutionPath .\demo\ToolkitDemo.sln `
  -CollectCoverage
```

Show `QUALITY GATE PASSED` and the results directory.

### 3:15–4:15 — Two-tool testing and refinements

Open `AI_TOOL_TEST_RESULTS.md`.

Say:

> I tested with the same repository commit, context, and placeholder values in
> two AI tools. I used Event and Category to expose hardcoded assumptions. Each
> result was scored for completeness, correctness, architecture, security,
> tests, and verification. A result counted as passing only after build and
> tests succeeded.

Show your completed comparison table and terminal evidence. Mention one real
difference between the tools and one prompt refinement made after a failure.

### 4:15–4:35 — Close

Say:

> The final toolkit is reusable, versioned, and evidence-driven. Prompts improve
> consistency, the module script removes repetitive setup, and the quality gate
> verifies that AI-generated changes actually work.

## Video 2 — Non-technical time-saving demo

### 0:00–0:25 — Problem

Say:

> Normally, starting a .NET feature requires creating projects and folders,
> adding them to the solution, connecting the test project, and restoring
> dependencies. Repeating these steps manually takes time and can introduce
> mistakes.

Show an empty `demo` folder.

### 0:25–1:15 — One-command module creation

Say:

> I created one reusable command that asks only for the module name. I will
> create a Notifications module now.

Run:

```powershell
.\scripts\New-DotNetModule.ps1 `
  -ModuleName Notifications `
  -SolutionPath .\demo\ToolkitDemo.sln `
  -SourceDirectory demo\src `
  -TestDirectory demo\tests `
  -CreateSolution
```

Show the successful elapsed time and expand the generated application and test
projects in the editor.

Say:

> In seconds, the toolkit created the working structure, connected the projects,
> and restored the dependencies. The same command works for Reporting,
> Payments, Bookings, or another module simply by changing one word.

### 1:15–1:55 — Reusing a prompt

Open Template 1 and point at `{Entity}`.

Say:

> I also no longer rewrite long AI instructions. I choose a tested template,
> replace a few placeholders such as Event or Category, and receive output in
> the same project style with validation, security, and tests already requested.
> This reduces both typing time and review mistakes.

### 1:55–2:30 — Automatic confidence check

Run:

```powershell
.\scripts\Invoke-DotNetQualityGate.ps1 `
  -SolutionPath .\demo\ToolkitDemo.sln
```

Say:

> Finally, one command builds and tests everything. Instead of checking several
> commands manually, I receive one clear pass or fail result. This toolkit lets
> me spend more time on business requirements and less time on repetitive
> setup.

Show `QUALITY GATE PASSED`, then end the recording.
