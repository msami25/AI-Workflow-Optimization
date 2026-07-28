# Automation Script Test Results

## Environment

- Date: 2026-07-27
- Operating system: Windows
- PowerShell: 5.1.26100.8875
- .NET SDK: 10.0.301
- Generated project target: .NET 8

## New-DotNetModule.ps1

### First run

- Result: Failed after creating the solution, class library, and xUnit project.
- Error: `Cannot bind argument to parameter 'Path' because it is an empty string.`
- Root cause: Console output from `dotnet new sln` was captured together with the solution path.
- Additional issue: The Unicode arrow was displayed incorrectly in Windows PowerShell.

### Refinement

- Piped `dotnet` console output through `Out-Host`.
- Replaced the Unicode arrow with ASCII brackets.
- Preserved the failed run temporarily for investigation.

### Second run

- Result: Passed.
- Module: `Notifications`
- Solution created: `demo/ToolkitDemo.slnx`
- Application and xUnit projects created and referenced successfully.
- Dependencies restored successfully.
- Execution time: 8.55 seconds.

## Invoke-DotNetQualityGate.ps1

- Restore: Passed in 1.33 seconds.
- Release build: Passed in 4.69 seconds.
- Tests: 1 passed, 0 failed, 0 skipped.
- XPlat coverage file: Generated successfully.
- Total quality-gate time: 9.89 seconds.
- Final result: `QUALITY GATE PASSED`.

## Conclusion

Testing exposed a real path-resolution bug that was corrected and verified.
The scripts now create a reusable module and validate it in under 20 seconds.

## Invoke-EfDatabaseMigration.ps1

### Environment

- Date: 2026-07-28
- Operating system: Windows 10.0.26200
- PowerShell: 5.1
- .NET SDK: 10.0.301
- `dotnet-ef`: 10.0.9
- Fixture target/runtime packages: .NET 8 / EF Core 8.0.28 / SQLite
- Database scope: disposable files under `artifacts/EfMigrationTests`; no
  external or Production database was used

### Commands

```powershell
$files = @(
  'scripts/Invoke-EfDatabaseMigration.ps1',
  'tests/Invoke-EfDatabaseMigration.Tests.ps1'
)
foreach ($file in $files) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path $file),
    [ref]$tokens,
    [ref]$errors
  ) | Out-Null
  if ($errors.Count -gt 0) { throw "$file failed syntax validation." }
}

dotnet restore .\tests\fixtures\EfMigrationFixture\EfMigrationFixture.csproj
dotnet build .\tests\fixtures\EfMigrationFixture\EfMigrationFixture.csproj `
  --configuration Release `
  --no-restore
.\tests\Invoke-EfDatabaseMigration.Tests.ps1
dotnet restore .\demo\ToolkitDemo.slnx
dotnet build .\demo\ToolkitDemo.slnx --configuration Release --no-restore
dotnet test .\demo\ToolkitDemo.slnx --configuration Release --no-build
git diff --check
```

### Isolated scenario results

- No migrations: exit `0`.
- Pending/check-only: exit `2`; no migration applied.
- Pending/apply: exit `0`.
- Second no-pending check: exit `0`, confirming idempotency.
- Pending model changes: exit `3`.
- Missing/unreachable database: exit `5`.
- Invalid project: exit `4`.
- Invalid context: exit `4`.
- Conflicting pre-existing schema with `-Reseed`: exit `6`; reseed was not
  attempted.
- Requested seed-entry-point failure after a successful apply: exit `7`.
- Apply and reseed: exit `0`.
- Reseed data verification: exactly one row.
- Production reseed prohibition: exit `4`.

### Final verification result

- PowerShell syntax: passed for the migration script and integration harness.
- Restore: passed.
- Release build: passed with 0 warnings and 0 errors.
- Isolated migration suite: all scenarios passed.
- Existing demo Release build: passed with 0 warnings and 0 errors.
- Existing demo tests: 1 passed, 0 failed, 0 skipped.
- `git diff --check`: passed.

### Limitations

- The fixture verifies SQLite behavior. Provider-specific authentication,
  transient networking, locks, and transactional DDL behavior require the
  target application's non-Production integration environment.
- EF Core providers can represent a missing but automatically creatable
  database differently. This script treats an EF-reported connection-open
  failure as unavailable and an accessible empty database as pending.
- The script does not create migrations or repair conflicts automatically;
  both require human review.
