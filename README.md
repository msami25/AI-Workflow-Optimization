# Reusable .NET Prompt & Automation Toolkit

A practical toolkit for producing consistent .NET 8 code with AI and automating
repetitive development work.

## Submission contents

| File | Purpose |
| --- | --- |
| `PROMPT_LIBRARY.md` | 12 refined, reusable prompt templates |
| `scripts/New-DotNetModule.ps1` | Creates a class library, xUnit project, solution entries, and project reference |
| `scripts/Invoke-DotNetQualityGate.ps1` | Restores, builds, tests, and optionally collects coverage |
| `AI_TOOL_TEST_RESULTS.md` | Repeatable comparison matrix for two AI tools |
| `LOOM_SCRIPTS.md` | Technical and non-technical recording scripts |
| `CHANGELOG.md` | Version history and refinements |

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- .NET 8 SDK or newer
- A `.sln` or `.slnx` solution for existing-project use
- Optional: ReportGenerator for an HTML coverage report

Check the environment:

```powershell
dotnet --version
$PSVersionTable.PSVersion
```

If Windows blocks local scripts for the current terminal:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

This changes the policy only for the open PowerShell process.

## Script 1: create a module

From the root of a .NET repository:

```powershell
.\scripts\New-DotNetModule.ps1 -ModuleName Notifications
```

The script finds the repository's `.sln` or `.slnx`, then creates:

```text
src/Notifications.Application/
tests/Notifications.Tests/
```

It adds both projects to the solution, references the application project from
the test project, restores dependencies, and prints the elapsed time.

Useful options:

```powershell
.\scripts\New-DotNetModule.ps1 `
  -ModuleName Reporting `
  -SolutionPath .\backend\EventBoard.Api.slnx `
  -Framework net8.0
```

Preview the actions without changing files:

```powershell
.\scripts\New-DotNetModule.ps1 -ModuleName Demo -WhatIf
```

## Script 2: run the quality gate

Restore, compile, and test:

```powershell
.\scripts\Invoke-DotNetQualityGate.ps1
```

Run a Release build and collect XPlat coverage:

```powershell
.\scripts\Invoke-DotNetQualityGate.ps1 `
  -SolutionPath .\backend\EventBoard.Api.slnx `
  -Configuration Release `
  -CollectCoverage
```

Also request an HTML report:

```powershell
.\scripts\Invoke-DotNetQualityGate.ps1 -CollectCoverage -GenerateHtmlReport
```

Install ReportGenerator if the last option reports that it is unavailable:

```powershell
dotnet tool install --global dotnet-reportgenerator-globaltool
```

Test and coverage artifacts are written beneath `artifacts/TestResults`.

## Using the prompt library

1. Select the template matching the task.
2. Replace every `{Placeholder}`.
3. Paste the completed prompt into the AI tool.
4. Review the proposed file list before accepting code.
5. Run the generated tests and the quality-gate script.
6. Record the result in `AI_TOOL_TEST_RESULTS.md`.

Never paste production secrets, access tokens, private connection strings, or
customer data into an AI prompt.

## Two-tool evaluation

Use the same completed prompt and project context in both tools. The suggested
pair is:

- Tool A: OpenAI Codex
- Tool B: Claude Code, GitHub Copilot, or Gemini CLI

Score both outputs using the rubric in `AI_TOOL_TEST_RESULTS.md`. Record actual
commands, tool/model versions, pass/fail results, manual corrections, and time
saved. Do not claim a test passed unless its generated code compiled and its
tests ran successfully.

## Suggested Git workflow

```powershell
git init
git add README.md PROMPT_LIBRARY.md
git commit -m "docs: add reusable dotnet prompt library"

git add scripts
git commit -m "feat: add module and quality gate automation"

git add AI_TOOL_TEST_RESULTS.md LOOM_SCRIPTS.md CHANGELOG.md
git commit -m "docs: add evaluation evidence and loom scripts"
```
