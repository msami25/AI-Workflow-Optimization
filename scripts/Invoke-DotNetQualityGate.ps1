<#
.SYNOPSIS
Runs a repeatable restore, build, and test quality gate for a .NET solution.

.DESCRIPTION
Discovers or accepts a .sln/.slnx path, restores packages, builds the selected
configuration, runs tests with TRX output, and can collect XPlat coverage and
generate an HTML report.

.EXAMPLE
.\scripts\Invoke-DotNetQualityGate.ps1

.EXAMPLE
.\scripts\Invoke-DotNetQualityGate.ps1 `
  -SolutionPath .\backend\EventBoard.Api.slnx `
  -Configuration Release -CollectCoverage -GenerateHtmlReport
#>

[CmdletBinding()]
param(
    [string]$SolutionPath,

    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [string]$ResultsDirectory = "artifacts/TestResults",

    [switch]$SkipRestore,

    [switch]$CollectCoverage,

    [switch]$GenerateHtmlReport
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Assert-Command {
    param([Parameter(Mandatory)][string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found. Install the .NET SDK and reopen PowerShell."
    }
}

function Invoke-DotNetStep {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $stepTimer = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Host ""
    Write-Host "[$Name] dotnet $($Arguments -join ' ')" -ForegroundColor Cyan
    & dotnet @Arguments
    $exitCode = $LASTEXITCODE
    $stepTimer.Stop()

    if ($exitCode -ne 0) {
        throw "$Name failed with exit code $exitCode after $([math]::Round($stepTimer.Elapsed.TotalSeconds, 2)) seconds."
    }

    Write-Host "$Name passed in $([math]::Round($stepTimer.Elapsed.TotalSeconds, 2)) seconds." -ForegroundColor Green
}

function Resolve-SolutionFile {
    param([string]$RequestedPath)

    if ($RequestedPath) {
        $candidate = if ([System.IO.Path]::IsPathRooted($RequestedPath)) {
            [System.IO.Path]::GetFullPath($RequestedPath)
        }
        else {
            [System.IO.Path]::GetFullPath(
                (Join-Path (Get-Location) $RequestedPath)
            )
        }

        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "Solution not found: $candidate"
        }

        if ([System.IO.Path]::GetExtension($candidate) -notin @(".sln", ".slnx")) {
            throw "SolutionPath must point to a .sln or .slnx file."
        }

        return $candidate
    }

    $solutions = @(
        Get-ChildItem -LiteralPath (Get-Location) -File |
            Where-Object { $_.Extension -in @(".sln", ".slnx") }
    )

    if ($solutions.Count -eq 0) {
        throw "No .sln or .slnx found in the current directory. Pass -SolutionPath."
    }

    if ($solutions.Count -gt 1) {
        throw "Multiple solutions found. Pass -SolutionPath explicitly."
    }

    return $solutions[0].FullName
}

Assert-Command -Name "dotnet"

if ($GenerateHtmlReport -and -not $CollectCoverage) {
    throw "-GenerateHtmlReport requires -CollectCoverage."
}

$gateTimer = [System.Diagnostics.Stopwatch]::StartNew()
$resolvedSolution = Resolve-SolutionFile -RequestedPath $SolutionPath
$resolvedResultsDirectory = if ([System.IO.Path]::IsPathRooted($ResultsDirectory)) {
    [System.IO.Path]::GetFullPath($ResultsDirectory)
}
else {
    [System.IO.Path]::GetFullPath(
        (Join-Path (Get-Location) $ResultsDirectory)
    )
}

New-Item -ItemType Directory -Force -Path $resolvedResultsDirectory | Out-Null

Write-Host "Running .NET quality gate" -ForegroundColor White
Write-Host "Solution:      $resolvedSolution"
Write-Host "Configuration: $Configuration"
Write-Host "Results:       $resolvedResultsDirectory"

try {
    if (-not $SkipRestore) {
        Invoke-DotNetStep `
            -Name "Restore" `
            -Arguments @("restore", $resolvedSolution)
    }

    $buildArguments = @(
        "build", $resolvedSolution,
        "--configuration", $Configuration,
        "--no-restore"
    )

    Invoke-DotNetStep -Name "Build" -Arguments $buildArguments

    $testArguments = @(
        "test", $resolvedSolution,
        "--configuration", $Configuration,
        "--no-build",
        "--logger", "trx;LogFileName=tests.trx",
        "--results-directory", $resolvedResultsDirectory
    )

    if ($CollectCoverage) {
        $testArguments += '--collect:XPlat Code Coverage'
    }

    Invoke-DotNetStep -Name "Tests" -Arguments $testArguments

    if ($GenerateHtmlReport) {
        $coverageFiles = @(
            Get-ChildItem `
                -LiteralPath $resolvedResultsDirectory `
                -Filter "coverage.cobertura.xml" `
                -File `
                -Recurse
        )

        if ($coverageFiles.Count -eq 0) {
            throw "Coverage was requested, but no coverage.cobertura.xml file was found."
        }

        $reportGenerator = Get-Command "reportgenerator" -ErrorAction SilentlyContinue
        if (-not $reportGenerator) {
            throw "ReportGenerator is not installed. Run: dotnet tool install --global dotnet-reportgenerator-globaltool"
        }

        $coveragePattern = Join-Path $resolvedResultsDirectory "**/coverage.cobertura.xml"
        $reportDirectory = Join-Path $resolvedResultsDirectory "CoverageReport"
        Write-Host ""
        Write-Host "[Coverage report] reportgenerator" -ForegroundColor Cyan
        & reportgenerator `
            "-reports:$coveragePattern" `
            "-targetdir:$reportDirectory" `
            "-reporttypes:Html"

        if ($LASTEXITCODE -ne 0) {
            throw "ReportGenerator failed with exit code $LASTEXITCODE."
        }

        Write-Host "HTML report: $(Join-Path $reportDirectory 'index.html')" -ForegroundColor Green
    }
}
catch {
    $gateTimer.Stop()
    Write-Host ""
    Write-Host "QUALITY GATE FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

$gateTimer.Stop()
Write-Host ""
Write-Host "QUALITY GATE PASSED in $([math]::Round($gateTimer.Elapsed.TotalSeconds, 2)) seconds." -ForegroundColor Green
Write-Host "Test artifacts: $resolvedResultsDirectory"
exit 0
