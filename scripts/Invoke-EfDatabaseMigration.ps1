<#
.SYNOPSIS
Checks and optionally applies Entity Framework Core migrations.

.DESCRIPTION
Runs EF Core migration checks without changing the database by default. The
script distinguishes an empty migration set, pending model changes, pending
database migrations, database connectivity failures, and migration failures.

When -Reseed is supplied, the startup project is run with the documented seed
entry point:

    dotnet run --project <StartupProject> --configuration <Configuration> `
      --no-build -- --seed

The startup project must implement the --seed argument as an idempotent seed
operation. Reseeding is blocked when -Environment is Production.

.EXAMPLE
.\scripts\Invoke-EfDatabaseMigration.ps1 `
  -MigrationProject .\src\App.Data\App.Data.csproj `
  -StartupProject .\src\App.Api\App.Api.csproj

.EXAMPLE
.\scripts\Invoke-EfDatabaseMigration.ps1 `
  -MigrationProject .\src\App.Data\App.Data.csproj `
  -StartupProject .\src\App.Api\App.Api.csproj `
  -DbContext AppDbContext -Apply

.EXAMPLE
.\scripts\Invoke-EfDatabaseMigration.ps1 `
  -MigrationProject .\src\App.Data\App.Data.csproj `
  -StartupProject .\src\App.Api\App.Api.csproj `
  -Environment Development -Apply -Reseed
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$MigrationProject,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$StartupProject,

    [ValidateNotNullOrEmpty()]
    [string]$DbContext,

    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [ValidateNotNullOrEmpty()]
    [string]$Environment = "Development",

    [switch]$Apply,

    [switch]$Reseed
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Exit codes are intentionally stable for use in CI and deployment automation.
$exitSuccess = 0
$exitPendingMigrations = 2
$exitPendingModelChanges = 3
$exitValidation = 4
$exitDatabaseUnavailable = 5
$exitMigrationFailure = 6
$exitReseedFailure = 7

function Resolve-ProjectFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ParameterName
    )

    $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Path))
    }

    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "$ParameterName was not found."
    }

    if ([System.IO.Path]::GetExtension($candidate) -ne ".csproj") {
        throw "$ParameterName must point to a .csproj file."
    }

    return $candidate
}

function Invoke-DotNetCapture {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $lines = @(
            & dotnet @Arguments 2>&1 |
                ForEach-Object { $_.ToString() }
        )
        $commandExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return [PSCustomObject]@{
        ExitCode = $commandExitCode
        Output = $lines
        Text = ($lines -join [Environment]::NewLine)
    }
}

function Get-MigrationRecords {
    param([Parameter(Mandatory)][string]$Text)

    $arrayStart = $Text.LastIndexOf([Environment]::NewLine + "[")
    if ($arrayStart -ge 0) {
        $arrayStart += [Environment]::NewLine.Length
    }
    elseif ($Text.TrimStart().StartsWith("[")) {
        $arrayStart = $Text.IndexOf("[")
    }
    $arrayEnd = $Text.LastIndexOf("]")
    if ($arrayStart -lt 0 -or $arrayEnd -lt $arrayStart) {
        throw "EF Core returned an unexpected migration-list response."
    }

    $json = $Text.Substring($arrayStart, $arrayEnd - $arrayStart + 1)
    $records = ConvertFrom-Json -InputObject $json
    if ($null -eq $records) {
        return
    }

    return @($records)
}

function Test-DatabaseUnavailableMessage {
    param([Parameter(Mandatory)][string]$Text)

    return $Text -match (
        "unable to (connect|open)|cannot open database|could not open a connection|" +
        "connection (refused|timed out)|login failed|network-related|" +
        "server was not found|no such host|host is unknown|database .* does not exist|" +
        "unable to open database file|failed to connect|" +
        "an error occurred using the connection"
    )
}

function New-EfArguments {
    param([Parameter(Mandatory)][string[]]$Command)

    $arguments = @("ef") + $Command + @(
        "--project", $script:resolvedMigrationProject,
        "--startup-project", $script:resolvedStartupProject,
        "--configuration", $Configuration,
        "--no-color"
    )

    if ($DbContext) {
        $arguments += @("--context", $DbContext)
    }

    return $arguments
}

function Write-Status {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )

    Write-Host $Message -ForegroundColor $Color
}

if (-not (Get-Command "dotnet" -ErrorAction SilentlyContinue)) {
    Write-Status "VALIDATION ERROR: dotnet was not found." Red
    exit $exitValidation
}

$efVersion = Invoke-DotNetCapture -Arguments @("ef", "--version")
if ($efVersion.ExitCode -ne 0) {
    Write-Status "VALIDATION ERROR: dotnet-ef was not found or could not run." Red
    Write-Host "Install a compatible tool with: dotnet tool install --global dotnet-ef"
    exit $exitValidation
}

try {
    $script:resolvedMigrationProject = Resolve-ProjectFile `
        -Path $MigrationProject `
        -ParameterName "MigrationProject"
    $script:resolvedStartupProject = Resolve-ProjectFile `
        -Path $StartupProject `
        -ParameterName "StartupProject"

    if ($Reseed -and -not $Apply) {
        throw "-Reseed requires -Apply."
    }

    if ($Reseed -and $Environment -ieq "Production") {
        throw "Automatic reseeding is prohibited in Production."
    }
}
catch {
    Write-Status "VALIDATION ERROR: $($_.Exception.Message)" Red
    exit $exitValidation
}

$oldAspNetCoreEnvironment = [Environment]::GetEnvironmentVariable(
    "ASPNETCORE_ENVIRONMENT",
    [EnvironmentVariableTarget]::Process
)
$oldDotNetEnvironment = [Environment]::GetEnvironmentVariable(
    "DOTNET_ENVIRONMENT",
    [EnvironmentVariableTarget]::Process
)

try {
    [Environment]::SetEnvironmentVariable(
        "ASPNETCORE_ENVIRONMENT",
        $Environment,
        [EnvironmentVariableTarget]::Process
    )
    [Environment]::SetEnvironmentVariable(
        "DOTNET_ENVIRONMENT",
        $Environment,
        [EnvironmentVariableTarget]::Process
    )

    Write-Status "EF Core migration check" Cyan
    Write-Host "Configuration: $Configuration"
    Write-Host "Environment:   $Environment"
    Write-Host "Mode:          $(if ($Apply) { 'apply' } else { 'preview' })"

    $offlineList = Invoke-DotNetCapture -Arguments (
        New-EfArguments -Command @("migrations", "list", "--json", "--no-connect")
    )
    if ($offlineList.ExitCode -ne 0) {
        Write-Status "VALIDATION ERROR: EF Core could not load the projects or DbContext." Red
        Write-Host "Check project compatibility, design-time services, and -DbContext."
        exit $exitValidation
    }

    try {
        $availableMigrations = @(Get-MigrationRecords -Text $offlineList.Text)
    }
    catch {
        Write-Status "VALIDATION ERROR: EF Core migration output could not be interpreted." Red
        exit $exitValidation
    }

    if ($availableMigrations.Count -eq 0) {
        Write-Status "NO MIGRATIONS: the selected context has no migrations." Yellow
        exit $exitSuccess
    }

    $modelCheck = Invoke-DotNetCapture -Arguments (
        New-EfArguments -Command @("migrations", "has-pending-model-changes")
    )
    $hasPendingModelChanges = $modelCheck.Text -match (
        "(?im)^\s*(Changes have been made to the model|" +
        "Model changes were found|The model has pending model changes)"
    )

    if ($modelCheck.ExitCode -ne 0 -and -not $hasPendingModelChanges) {
        Write-Status "VALIDATION ERROR: EF Core could not compare the model to its snapshot." Red
        Write-Host "Check the selected context and use EF Core 8 or newer."
        exit $exitValidation
    }

    if ($hasPendingModelChanges) {
        Write-Status "MODEL CHANGES DETECTED: create and review a new migration before updating the database." Yellow
        exit $exitPendingModelChanges
    }

    $connectedList = Invoke-DotNetCapture -Arguments (
        # EF can return an all-pending list when opening the database failed.
        # Verbose diagnostics are captured only for classification and are
        # never written, preventing connection details from reaching output.
        New-EfArguments -Command @("migrations", "list", "--json", "--verbose")
    )
    if (Test-DatabaseUnavailableMessage -Text $connectedList.Text) {
        Write-Status "DATABASE UNAVAILABLE: the database is missing or unreachable." Red
        Write-Host "Verify the environment's database configuration and network access."
        exit $exitDatabaseUnavailable
    }

    if ($connectedList.ExitCode -ne 0) {
        Write-Status "DATABASE CHECK FAILED: EF Core could not read migration history." Red
        Write-Host "Review the database and migration history for a conflict."
        exit $exitMigrationFailure
    }

    try {
        $databaseMigrations = @(Get-MigrationRecords -Text $connectedList.Text)
    }
    catch {
        Write-Status "DATABASE CHECK FAILED: EF Core returned an unexpected migration history response." Red
        exit $exitMigrationFailure
    }

    $pendingMigrations = @(
        $databaseMigrations |
            Where-Object {
                $_.applied -ne $true
            }
    )

    if ($pendingMigrations.Count -gt 0) {
        Write-Status "PENDING MIGRATIONS: $($pendingMigrations.Count) migration(s) require application." Yellow

        if (-not $Apply) {
            Write-Host "Preview only; rerun with -Apply after reviewing the migrations."
            exit $exitPendingMigrations
        }

        if (-not $PSCmdlet.ShouldProcess(
            "the database selected by the startup project and environment",
            "Apply $($pendingMigrations.Count) EF Core migration(s)"
        )) {
            Write-Host "Migration application was not approved; the database remains pending."
            exit $exitPendingMigrations
        }

        $update = Invoke-DotNetCapture -Arguments (
            New-EfArguments -Command @("database", "update")
        )
        if ($update.ExitCode -ne 0) {
            if (Test-DatabaseUnavailableMessage -Text $update.Text) {
                Write-Status "DATABASE UNAVAILABLE: migration could not connect to the database." Red
                exit $exitDatabaseUnavailable
            }

            Write-Status "MIGRATION FAILED: EF Core could not apply the pending migrations." Red
            Write-Host "No reseed was attempted. Resolve the schema/history conflict and retry."
            exit $exitMigrationFailure
        }

        $verification = Invoke-DotNetCapture -Arguments (
            New-EfArguments -Command @("migrations", "list", "--json")
        )
        if ($verification.ExitCode -ne 0) {
            Write-Status "MIGRATION FAILED: post-update verification could not read migration history." Red
            exit $exitMigrationFailure
        }

        try {
            $verifiedMigrations = @(Get-MigrationRecords -Text $verification.Text)
            $stillPending = @(
                $verifiedMigrations |
                    Where-Object {
                        $_.applied -ne $true
                    }
            )
        }
        catch {
            Write-Status "MIGRATION FAILED: post-update verification returned an unexpected response." Red
            exit $exitMigrationFailure
        }

        if ($stillPending.Count -gt 0) {
            Write-Status "MIGRATION FAILED: migrations remain pending after database update." Red
            exit $exitMigrationFailure
        }

        Write-Status "MIGRATIONS APPLIED: database migration history is current." Green
    }
    else {
        Write-Status "NO PENDING MIGRATIONS: database migration history is current." Green
    }

    if ($Reseed) {
        if (-not $PSCmdlet.ShouldProcess(
            "the non-Production database selected by the startup project",
            "Run the startup project's --seed entry point"
        )) {
            Write-Host "Reseed was not approved; migration verification succeeded without reseeding."
            exit $exitSuccess
        }

        $seed = Invoke-DotNetCapture -Arguments @(
            "run",
            "--project", $script:resolvedStartupProject,
            "--configuration", $Configuration,
            "--no-build",
            "--",
            "--seed"
        )
        if ($seed.ExitCode -ne 0) {
            Write-Status "RESEED FAILED: migrations succeeded, but the --seed entry point failed." Red
            exit $exitReseedFailure
        }

        Write-Status "RESEED COMPLETE: the startup project's --seed entry point succeeded." Green
    }

    exit $exitSuccess
}
finally {
    [Environment]::SetEnvironmentVariable(
        "ASPNETCORE_ENVIRONMENT",
        $oldAspNetCoreEnvironment,
        [EnvironmentVariableTarget]::Process
    )
    [Environment]::SetEnvironmentVariable(
        "DOTNET_ENVIRONMENT",
        $oldDotNetEnvironment,
        [EnvironmentVariableTarget]::Process
    )
}
