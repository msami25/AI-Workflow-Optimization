<#
.SYNOPSIS
Runs isolated integration checks for Invoke-EfDatabaseMigration.ps1.

.DESCRIPTION
Uses disposable SQLite database files under artifacts/EfMigrationTests. No
external or production database is contacted. The fixture's --seed entry point
replaces the single fixture row, making reseeding repeatable.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $repositoryRoot "scripts/Invoke-EfDatabaseMigration.ps1"
$projectPath = Join-Path $PSScriptRoot "fixtures/EfMigrationFixture/EfMigrationFixture.csproj"
$artifactDirectory = Join-Path $repositoryRoot "artifacts/EfMigrationTests"
$shell = if (Get-Command "pwsh" -ErrorAction SilentlyContinue) {
    (Get-Command "pwsh").Source
}
else {
    (Get-Command "powershell").Source
}

function Invoke-MigrationScript {
    param(
        [Parameter(Mandatory)][string]$DatabasePath,
        [string[]]$AdditionalArguments = @(),
        [hashtable]$EnvironmentVariables = @{},
        [string]$Context = "FixtureDbContext",
        [string]$ScriptEnvironment = "Testing"
    )

    $oldDatabase = $env:EF_MIGRATION_FIXTURE_DB
    $oldModelChange = $env:EF_MIGRATION_FIXTURE_MODEL_CHANGE
    $oldSeedFailure = $env:EF_MIGRATION_FIXTURE_SEED_FAIL
    try {
        $env:EF_MIGRATION_FIXTURE_DB = $DatabasePath
        $env:EF_MIGRATION_FIXTURE_MODEL_CHANGE = $null
        $env:EF_MIGRATION_FIXTURE_SEED_FAIL = $null
        foreach ($entry in $EnvironmentVariables.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable(
                [string]$entry.Key,
                [string]$entry.Value,
                [EnvironmentVariableTarget]::Process
            )
        }

        $arguments = @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", $scriptPath,
            "-MigrationProject", $projectPath,
            "-StartupProject", $projectPath,
            "-DbContext", $Context,
            "-Configuration", "Release",
            "-Environment", $ScriptEnvironment
        ) + $AdditionalArguments

        $oldErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $output = @(& $shell @arguments 2>&1 | ForEach-Object { $_.ToString() })
            $processExitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $oldErrorActionPreference
        }

        return [PSCustomObject]@{
            ExitCode = $processExitCode
            Output = ($output -join [Environment]::NewLine)
        }
    }
    finally {
        $env:EF_MIGRATION_FIXTURE_DB = $oldDatabase
        $env:EF_MIGRATION_FIXTURE_MODEL_CHANGE = $oldModelChange
        $env:EF_MIGRATION_FIXTURE_SEED_FAIL = $oldSeedFailure
    }
}

function Assert-ExitCode {
    param(
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)][int]$Expected,
        [Parameter(Mandatory)][string]$Scenario
    )

    if ($Result.ExitCode -ne $Expected) {
        throw (
            "$Scenario expected exit code $Expected but received " +
            "$($Result.ExitCode).`n$($Result.Output)"
        )
    }

    Write-Host "[PASS] $Scenario (exit $Expected)" -ForegroundColor Green
}

if (Test-Path -LiteralPath $artifactDirectory) {
    Remove-Item -LiteralPath $artifactDirectory -Recurse -Force
}
New-Item -ItemType Directory -Path $artifactDirectory | Out-Null

Write-Host "Building isolated EF migration fixture (restore must be run first)..."
& dotnet build $projectPath --configuration Release --no-restore
if ($LASTEXITCODE -ne 0) {
    throw "Fixture build failed with exit code $LASTEXITCODE."
}

$pendingDatabase = Join-Path $artifactDirectory "pending.db"
New-Item -ItemType File -Path $pendingDatabase | Out-Null

$noMigrations = Invoke-MigrationScript `
    -DatabasePath $pendingDatabase `
    -Context "NoMigrationsDbContext"
Assert-ExitCode -Result $noMigrations -Expected 0 -Scenario "no migrations"

$pending = Invoke-MigrationScript -DatabasePath $pendingDatabase
Assert-ExitCode -Result $pending -Expected 2 -Scenario "pending/check-only"

$apply = Invoke-MigrationScript `
    -DatabasePath $pendingDatabase `
    -AdditionalArguments @("-Apply")
Assert-ExitCode -Result $apply -Expected 0 -Scenario "pending/apply"

$noPending = Invoke-MigrationScript -DatabasePath $pendingDatabase
Assert-ExitCode -Result $noPending -Expected 0 -Scenario "no-pending"

$modelChangeDatabase = Join-Path $artifactDirectory "model-change.db"
$modelChanges = Invoke-MigrationScript `
    -DatabasePath $modelChangeDatabase `
    -EnvironmentVariables @{ EF_MIGRATION_FIXTURE_MODEL_CHANGE = "1" }
Assert-ExitCode -Result $modelChanges -Expected 3 -Scenario "pending model changes"

$missingParent = Join-Path $artifactDirectory "missing/fixture.db"
$missingDatabase = Invoke-MigrationScript -DatabasePath $missingParent
Assert-ExitCode -Result $missingDatabase -Expected 5 -Scenario "missing/unreachable database"

$invalidProjectArguments = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $scriptPath,
    "-MigrationProject", (Join-Path $artifactDirectory "missing.csproj"),
    "-StartupProject", $projectPath
)
& $shell @invalidProjectArguments *> $null
if ($LASTEXITCODE -ne 4) {
    throw "invalid project expected exit code 4 but received $LASTEXITCODE."
}
Write-Host "[PASS] invalid project (exit 4)" -ForegroundColor Green

$invalidContext = Invoke-MigrationScript `
    -DatabasePath (Join-Path $artifactDirectory "invalid-context.db") `
    -Context "MissingDbContext"
Assert-ExitCode -Result $invalidContext -Expected 4 -Scenario "invalid context"

$conflictDatabase = Join-Path $artifactDirectory "conflict.db"
$oldFixtureDatabase = $env:EF_MIGRATION_FIXTURE_DB
try {
    $env:EF_MIGRATION_FIXTURE_DB = $conflictDatabase
    & dotnet run `
        --project $projectPath `
        --configuration Release `
        --no-build `
        -- `
        --create-conflict
    if ($LASTEXITCODE -ne 0) {
        throw "Conflict setup failed with exit code $LASTEXITCODE."
    }
}
finally {
    $env:EF_MIGRATION_FIXTURE_DB = $oldFixtureDatabase
}

$conflict = Invoke-MigrationScript `
    -DatabasePath $conflictDatabase `
    -AdditionalArguments @("-Apply", "-Reseed")
Assert-ExitCode -Result $conflict -Expected 6 -Scenario "migration conflict"

$seedDatabase = Join-Path $artifactDirectory "seed.db"
New-Item -ItemType File -Path $seedDatabase | Out-Null

$seedFailure = Invoke-MigrationScript `
    -DatabasePath $seedDatabase `
    -AdditionalArguments @("-Apply", "-Reseed") `
    -EnvironmentVariables @{ EF_MIGRATION_FIXTURE_SEED_FAIL = "1" }
Assert-ExitCode -Result $seedFailure -Expected 7 -Scenario "reseed failure"

$reseed = Invoke-MigrationScript `
    -DatabasePath $seedDatabase `
    -AdditionalArguments @("-Apply", "-Reseed")
Assert-ExitCode -Result $reseed -Expected 0 -Scenario "apply and reseed"

try {
    $env:EF_MIGRATION_FIXTURE_DB = $seedDatabase
    $seedCount = & dotnet run `
        --project $projectPath `
        --configuration Release `
        --no-build `
        -- `
        --seed-count
    $seedCountExitCode = $LASTEXITCODE
}
finally {
    $env:EF_MIGRATION_FIXTURE_DB = $oldFixtureDatabase
}
if ($seedCountExitCode -ne 0 -or ($seedCount | Select-Object -Last 1) -ne "1") {
    throw "Reseed verification expected exactly one row."
}
Write-Host "[PASS] reseed data verification (1 row)" -ForegroundColor Green

$productionReseed = Invoke-MigrationScript `
    -DatabasePath $seedDatabase `
    -AdditionalArguments @("-Apply", "-Reseed") `
    -ScriptEnvironment "Production"
Assert-ExitCode -Result $productionReseed -Expected 4 -Scenario "Production reseed prohibition"

Write-Host "All isolated EF migration script checks passed." -ForegroundColor Green
