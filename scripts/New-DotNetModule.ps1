<#
.SYNOPSIS
Creates a reusable .NET module skeleton and adds it to a solution.

.DESCRIPTION
Creates an application class library and an xUnit test project, adds both to an
existing .sln or .slnx solution, adds the project reference, restores packages,
and reports elapsed time. If no solution exists, use -CreateSolution.

.EXAMPLE
.\scripts\New-DotNetModule.ps1 -ModuleName Notifications

.EXAMPLE
.\scripts\New-DotNetModule.ps1 -ModuleName Reporting `
  -SolutionPath .\backend\EventBoard.Api.slnx -Framework net8.0

.EXAMPLE
.\scripts\New-DotNetModule.ps1 -ModuleName Demo -WhatIf
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
param(
    [Parameter(Mandatory)]
    [ValidatePattern("^[A-Za-z][A-Za-z0-9]*$")]
    [string]$ModuleName,

    [string]$SolutionPath,

    [ValidatePattern("^net[0-9]+\.[0-9]+$")]
    [string]$Framework = "net8.0",

    [ValidateNotNullOrEmpty()]
    [string]$SourceDirectory = "src",

    [ValidateNotNullOrEmpty()]
    [string]$TestDirectory = "tests",

    [switch]$CreateSolution
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Assert-Command {
    param([Parameter(Mandatory)][string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found. Install the .NET SDK and reopen PowerShell."
    }
}

function Invoke-DotNet {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$Description
    )

    Write-Host "[$Description]" -ForegroundColor Cyan
    & dotnet @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet command failed ($LASTEXITCODE): dotnet $($Arguments -join ' ')"
    }
}

function Resolve-Solution {
    param(
        [string]$RequestedPath,
        [bool]$MayCreate
    )

    if ($RequestedPath) {
        $candidate = if ([System.IO.Path]::IsPathRooted($RequestedPath)) {
            [System.IO.Path]::GetFullPath($RequestedPath)
        }
        else {
            [System.IO.Path]::GetFullPath(
                (Join-Path (Get-Location) $RequestedPath)
            )
        }

        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }

        if (-not $MayCreate) {
            throw "Solution not found: $candidate. Pass -CreateSolution to create it."
        }

        $extension = [System.IO.Path]::GetExtension($candidate)
        if ($extension -and $extension -notin @(".sln", ".slnx")) {
            throw "SolutionPath must end in .sln or .slnx."
        }

        $solutionDirectory = Split-Path -Parent $candidate
        $solutionName = [System.IO.Path]::GetFileNameWithoutExtension($candidate)
        if (-not (Test-Path -LiteralPath $solutionDirectory)) {
            New-Item -ItemType Directory -Path $solutionDirectory | Out-Null
        }

        Invoke-DotNet `
            -Arguments @("new", "sln", "-n", $solutionName, "-o", $solutionDirectory) `
            -Description "Creating solution $solutionName"

        $created = Get-ChildItem -LiteralPath $solutionDirectory -File |
            Where-Object { $_.BaseName -eq $solutionName -and $_.Extension -in @(".sln", ".slnx") } |
            Select-Object -First 1

        if (-not $created) {
            throw "The .NET SDK did not create the expected solution."
        }

        return $created.FullName
    }

    $solutions = @(
        Get-ChildItem -LiteralPath (Get-Location) -File |
            Where-Object { $_.Extension -in @(".sln", ".slnx") }
    )

    if ($solutions.Count -eq 1) {
        return $solutions[0].FullName
    }

    if ($solutions.Count -gt 1) {
        $names = $solutions.Name -join ", "
        throw "Multiple solutions found ($names). Pass -SolutionPath explicitly."
    }

    if (-not $MayCreate) {
        throw "No .sln or .slnx found in the current directory. Pass -SolutionPath or -CreateSolution."
    }

    $currentDirectory = (Get-Location).Path
    $defaultName = Split-Path -Leaf $currentDirectory
    Invoke-DotNet `
        -Arguments @("new", "sln", "-n", $defaultName) `
        -Description "Creating solution $defaultName"

    $createdSolution = Get-ChildItem -LiteralPath (Get-Location) -File |
        Where-Object { $_.BaseName -eq $defaultName -and $_.Extension -in @(".sln", ".slnx") } |
        Select-Object -First 1

    if (-not $createdSolution) {
        throw "The .NET SDK did not create the expected solution."
    }

    return $createdSolution.FullName
}

Assert-Command -Name "dotnet"

$timer = [System.Diagnostics.Stopwatch]::StartNew()
$repositoryRoot = (Get-Location).Path
$applicationName = "$ModuleName.Application"
$testProjectName = "$ModuleName.Tests"
$applicationPath = Join-Path $repositoryRoot "$SourceDirectory/$applicationName"
$testProjectPath = Join-Path $repositoryRoot "$TestDirectory/$testProjectName"
$applicationProject = Join-Path $applicationPath "$applicationName.csproj"
$testProject = Join-Path $testProjectPath "$testProjectName.csproj"

if ((Test-Path -LiteralPath $applicationPath) -or (Test-Path -LiteralPath $testProjectPath)) {
    throw "A target directory already exists. Choose another ModuleName or move the existing module."
}

if (-not $PSCmdlet.ShouldProcess(
    $repositoryRoot,
    "Create module '$ModuleName', add projects to the solution, and restore dependencies"
)) {
    Write-Host "Preview complete; no files were changed." -ForegroundColor Yellow
    return
}

$resolvedSolution = Resolve-Solution `
    -RequestedPath $SolutionPath `
    -MayCreate $CreateSolution.IsPresent

try {
    Invoke-DotNet `
        -Arguments @(
            "new", "classlib",
            "-n", $applicationName,
            "-o", $applicationPath,
            "--framework", $Framework
        ) `
        -Description "Creating $applicationName"

    Invoke-DotNet `
        -Arguments @(
            "new", "xunit",
            "-n", $testProjectName,
            "-o", $testProjectPath,
            "--framework", $Framework
        ) `
        -Description "Creating $testProjectName"

    foreach ($folder in @("DTOs", "Interfaces", "Services")) {
        New-Item -ItemType Directory -Path (Join-Path $applicationPath $folder) | Out-Null
    }

    Invoke-DotNet `
        -Arguments @("sln", $resolvedSolution, "add", $applicationProject, $testProject) `
        -Description "Adding projects to $(Split-Path -Leaf $resolvedSolution)"

    Invoke-DotNet `
        -Arguments @("add", $testProject, "reference", $applicationProject) `
        -Description "Adding application reference to tests"

    Invoke-DotNet `
        -Arguments @("restore", $resolvedSolution) `
        -Description "Restoring dependencies"
}
catch {
    Write-Host "Module creation stopped: $($_.Exception.Message)" -ForegroundColor Red
    Write-Warning "Partially created files were preserved for inspection; remove them manually if unwanted."
    exit 1
}
finally {
    $timer.Stop()
}

Write-Host ""
Write-Host "Module created successfully in $([math]::Round($timer.Elapsed.TotalSeconds, 2)) seconds." -ForegroundColor Green
Write-Host "Application: $applicationProject"
Write-Host "Tests:       $testProject"
Write-Host "Solution:    $resolvedSolution"
Write-Host ""
Write-Host "Next: use Templates 1, 2, 4, 5, and 9 from PROMPT_LIBRARY.md." -ForegroundColor Cyan

