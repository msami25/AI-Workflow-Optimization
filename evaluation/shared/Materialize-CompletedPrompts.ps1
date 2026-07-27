[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repositoryRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot "../..")
)
$libraryPath = Join-Path $repositoryRoot "PROMPT_LIBRARY.md"
$outputDirectory = Join-Path $PSScriptRoot "completed-prompts"
$manifestPath = Join-Path $PSScriptRoot "PROMPT_MANIFEST.sha256"

if (-not (Test-Path -LiteralPath $libraryPath -PathType Leaf)) {
    throw "Prompt library not found: $libraryPath"
}

if ((Test-Path -LiteralPath $manifestPath -PathType Leaf) -and -not $Force) {
    throw "Completed prompts are frozen. Use -Force only when intentionally creating a documented refined packet."
}

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$library = Get-Content -LiteralPath $libraryPath -Raw

function Get-FencedText {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$HeadingPattern
    )

    $heading = [regex]::Match(
        $Text,
        $HeadingPattern,
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )
    if (-not $heading.Success) {
        throw "Heading not found: $HeadingPattern"
    }

    $fenceStart = $Text.IndexOf('```text', $heading.Index)
    if ($fenceStart -lt 0) {
        throw "Opening text fence not found after: $HeadingPattern"
    }

    $contentStart = $fenceStart + '```text'.Length
    while ($contentStart -lt $Text.Length -and
        ($Text[$contentStart] -eq "`r" -or $Text[$contentStart] -eq "`n")) {
        $contentStart++
    }

    $fenceEnd = $Text.IndexOf('```', $contentStart)
    if ($fenceEnd -lt 0) {
        throw "Closing fence not found after: $HeadingPattern"
    }

    return $Text.Substring($contentStart, $fenceEnd - $contentStart).Trim()
}

function Complete-Text {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][hashtable]$Values
    )

    $completed = $Text
    foreach ($key in ($Values.Keys | Sort-Object Length -Descending)) {
        $completed = $completed.Replace("{$key}", [string]$Values[$key])
    }

    $remaining = [regex]::Matches($completed, "\{[^`r`n{}]+\}") |
        ForEach-Object Value |
        Where-Object { $_ -ne "{id}" } |
        Sort-Object -Unique
    if ($remaining) {
        throw "Unresolved placeholders: $($remaining -join ', ')"
    }

    return $completed
}

$shared = Get-FencedText -Text $library -HeadingPattern "^## Shared project context$"
$baseValues = @{
    "ProjectName" = "PromptEvaluation"
    "TargetFramework, e.g., .NET 8" = ".NET 8"
    "Application type: {ASP.NET Core Web API / Worker / MVC}" = ""
    "ASP.NET Core Web API / Worker / MVC" = "ASP.NET Core Web API"
    "CurrentArchitecture" = "Layered API: controllers, services, EF Core DbContext, DTOs, centralized exception handling"
    "SQL Server / PostgreSQL / SQLite" = "SQLite"
    "EF Core version" = "EF Core 8"
    "xUnit, Moq, WebApplicationFactory" = "xUnit, Moq, WebApplicationFactory, SQLite in-memory"
    "Nullable enabled, file-scoped namespaces, naming rules" = "Nullable enabled, file-scoped namespaces, PascalCase public members, async methods suffixed Async"
    "TargetFramework" = ".NET 8"
}

$runs = @(
    @{
        Number = 1; Slug = "api-controller-event"; Values = @{
            Entity = "Event"; IdType = "int"; Route = "events"
            "ReadRole or Anonymous" = "Anonymous"; WriteRole = "Admin"
            ProjectNamespace = "PromptEvaluation.Api.Controllers"
        }
    },
    @{
        Number = 1; Slug = "api-controller-category"; Values = @{
            Entity = "Category"; IdType = "int"; Route = "categories"
            "ReadRole or Anonymous" = "Anonymous"; WriteRole = "Admin"
            ProjectNamespace = "PromptEvaluation.Api.Controllers"
        }
    },
    @{
        Number = 2; Slug = "crud-service-event"; Values = @{
            Entity = "Event"; IdType = "int"; DbContext = "EvaluationDbContext"
            MutableProperties = "Title, Description, Location, StartUtc, EndUtc, Capacity, CategoryId, OrganizerId"
            "UniqueRule or None" = "Title, StartUtc, and Location must be unique; EndUtc must be later than StartUtc"
        }
    },
    @{
        Number = 2; Slug = "crud-service-category"; Values = @{
            Entity = "Category"; IdType = "int"; DbContext = "EvaluationDbContext"
            MutableProperties = "Name, Description, IsActive"
            "UniqueRule or None" = "Name must be case-insensitively unique; a referenced category cannot be deleted"
        }
    },
    @{
        Number = 3; Slug = "entity-configuration-event"; Values = @{
            Entity = "Event"
            Properties = "Id (int); Title (required, max 150); Description (optional, max 2000); Location (required, max 200); StartUtc and EndUtc (UTC); Capacity (1-10,000); CategoryId (int); OrganizerId (int)"
            Relationships = "Event has one Category and one Organizer; Category and Organizer each have many Events"
            DeleteBehavior = "Restrict deletion of referenced Category and Organizer records"
            DbContext = "EvaluationDbContext"; MigrationName = "AddEvent"
            DataProject = "evaluation/codex/workspace/PromptEvaluation.Api/PromptEvaluation.Api.csproj"
        }
    },
    @{
        Number = 4; Slug = "dtos-validation-event"; Values = @{
            Entity = "Event"
            Fields = "Title, Description, Location, StartUtc, EndUtc, Capacity, CategoryId, OrganizerId; responses also contain Id"
            ValidationRules = "Title required/max 150; Description max 2000; Location required/max 200; Capacity 1-10,000; EndUtc later than StartUtc; positive CategoryId and OrganizerId; clients cannot assign Id"
            "ValidationLibrary, e.g., DataAnnotations or FluentValidation" = "DataAnnotations with IValidatableObject for cross-field validation"
            "MappingApproach, e.g., manual mapping or AutoMapper" = "manual mapping"
        }
    },
    @{
        Number = 4; Slug = "dtos-validation-category"; Values = @{
            Entity = "Category"
            Fields = "Name, Description, IsActive; responses also contain Id"
            ValidationRules = "Name required/max 80; Description max 500; clients cannot assign Id; case-insensitive uniqueness is enforced by the service/database"
            "ValidationLibrary, e.g., DataAnnotations or FluentValidation" = "DataAnnotations"
            "MappingApproach, e.g., manual mapping or AutoMapper" = "manual mapping"
        }
    },
    @{
        Number = 5; Slug = "mapping-event"; Values = @{
            SourceTypes = "EventCreateRequest, EventUpdateRequest, Event"
            DestinationTypes = "Event, EventResponse, EventListItemResponse"
            ProtectedMembers = "Id and all server-controlled persistence/navigation members"
            ComputedFields = "Event.DurationMinutes = (EndUtc - StartUtc).TotalMinutes in response mapping; CategoryName from Category.Name for list projection"
            MappingApproach = "manual"
        }
    },
    @{
        Number = 6; Slug = "problem-details-event"; Values = @{
            ExceptionTypes = "ValidationException, EntityNotFoundException, BusinessConflictException, and unexpected Exception"
            StatusMappings = "ValidationException -> 400; EntityNotFoundException -> 404; BusinessConflictException -> 409; unexpected Exception -> 500"
            "CorrelationHeader, e.g., X-Correlation-ID" = "X-Correlation-ID"
            EnvironmentRules = "Production returns generic safe detail and never stack traces/internal messages; Development may include a safe diagnostic error code but no secrets"
        }
    },
    @{
        Number = 7; Slug = "auth-review-event"; Values = @{
            AuthFlow = "JWT bearer access tokens with rotating refresh tokens in Secure, HttpOnly cookies"
            Roles = "Admin and User; Event create/update/delete require Admin"
            ProtectedEndpoints = "POST, PUT, and DELETE /api/events require Admin; GET endpoints are anonymous"
            TokenLocation = "Bearer access token in Authorization header; refresh token in Secure, HttpOnly cookie"
            FrontendOrigin = "https://localhost:5173"
        }
    },
    @{
        Number = 8; Slug = "secure-upload-event"; Values = @{
            AllowedTypes = "JPEG and PNG event images"
            MaxBytes = "5,242,880 bytes (5 MiB)"
            "StorageType, e.g., isolated local volume or object storage" = "isolated local volume outside the executable and content root"
            "VirusScanner or Not available" = "Not available"
            AuthorizationRule = "Only Admin may upload or replace an event image"
        }
    },
    @{
        Number = 9; Slug = "unit-tests-event"; Values = @{
            ClassUnderTest = "EventService"
            BehaviorList = "empty/found/not-found reads; valid create; invalid time range; uniqueness conflict; safe update; delete; cancellation"
            Dependencies = "EvaluationDbContext and ILogger<EventService>; use a relational SQLite in-memory database for EF behavior and a no-op logger"
            TestData = "Title lengths 1 and 150; Description 2000; Location 200; Capacity 1 and 10,000; EndUtc before/equal/after StartUtc; duplicate Title+StartUtc+Location"
            "MockingLibrary, e.g., Moq or NSubstitute" = "Moq"
        }
    },
    @{
        Number = 9; Slug = "unit-tests-category"; Values = @{
            ClassUnderTest = "CategoryService"
            BehaviorList = "empty/found/not-found reads; valid create; case-insensitive name conflict; safe update; referenced delete rejection; successful delete; cancellation"
            Dependencies = "EvaluationDbContext and ILogger<CategoryService>; use a relational SQLite in-memory database for EF behavior and a no-op logger"
            TestData = "Name lengths 1 and 80; Description 500; names Music/music/MUSIC; referenced and unreferenced categories"
            "MockingLibrary, e.g., Moq or NSubstitute" = "Moq"
        }
    },
    @{
        Number = 10; Slug = "integration-tests-event"; Values = @{
            Endpoints = "GET/POST/PUT/DELETE /api/events"
            AuthCases = "anonymous GET succeeds; anonymous write is 401; authenticated non-Admin write is 403; Admin write reaches validation/business logic"
            "DatabaseProvider, e.g., SQLite in-memory/Testcontainer" = "SQLite in-memory"
            SeedData = "one Category, one Organizer, one existing Event, plus deterministic duplicate and not-found identifiers"
            ExternalServices = "authentication handler and system clock; no external network calls"
        }
    },
    @{
        Number = 10; Slug = "integration-tests-category"; Values = @{
            Endpoints = "GET/POST/PUT/DELETE /api/categories"
            AuthCases = "anonymous GET succeeds; anonymous write is 401; authenticated non-Admin write is 403; Admin write reaches validation/business logic"
            "DatabaseProvider, e.g., SQLite in-memory/Testcontainer" = "SQLite in-memory"
            SeedData = "one referenced Category, one unreferenced Category, one Event, and deterministic duplicate/not-found identifiers"
            ExternalServices = "authentication handler; no external network calls"
        }
    },
    @{
        Number = 11; Slug = "performance-event-list"; Values = @{
            Endpoint = "GET /api/events"
            LatencyEvidence = "Baseline to be measured with 50,000 seeded events; capture median/p95 latency and SQL command count before changing code"
            ExpectedVolume = "50,000 events, 500 categories, and 2,000 organizers"
            RequiredFields = "Id, Title, Location, StartUtc, EndUtc, CategoryName, and remaining capacity"
            PagingRule = "required pageNumber >= 1 and pageSize 1-100, default 50, ordered by StartUtc then Id"
        }
    },
    @{
        Number = 12; Slug = "docker-runbook-stack"; Values = @{
            Services = "ASP.NET Core API, PostgreSQL database, and frontend"
            ApiPort = "http://localhost:8080"
            HealthPath = "/health"
            EnvironmentVariables = "ASPNETCORE_ENVIRONMENT, ConnectionStrings__DefaultConnection, Jwt__Issuer, Jwt__Audience, Jwt__SigningKey, Frontend__Origin"
            PersistentData = "named PostgreSQL data volume and named event-upload volume"
            FrontendBuild = "Node multi-stage build producing static assets served by nginx as a non-root user"
        }
    }
)

$completedShared = Complete-Text -Text $shared -Values $baseValues

foreach ($run in $runs) {
    $template = Get-FencedText `
        -Text $library `
        -HeadingPattern "^## Template $($run.Number) "
    $values = @{}
    foreach ($entry in $baseValues.GetEnumerator()) {
        $values[$entry.Key] = $entry.Value
    }
    foreach ($entry in $run.Values.GetEnumerator()) {
        $values[$entry.Key] = $entry.Value
    }

    $completedTemplate = Complete-Text -Text $template -Values $values
    $fileName = "{0:D2}-{1}.md" -f $run.Number, $run.Slug
    $path = Join-Path $outputDirectory $fileName
    $contentLines = @(
        "# Completed Prompt - Template $($run.Number): $($run.Slug)"
        ""
        "## Shared project context"
        ""
        '```text'
        $completedShared
        '```'
        ""
        "## Task"
        ""
        '```text'
        $completedTemplate
        '```'
    )
    $content = $contentLines -join [Environment]::NewLine
    [System.IO.File]::WriteAllText(
        $path,
        $content + [Environment]::NewLine,
        [System.Text.UTF8Encoding]::new($false)
    )
}

$promptFiles = Get-ChildItem -LiteralPath $outputDirectory -Filter "*.md" -File |
    Sort-Object Name
$manifest = foreach ($file in $promptFiles) {
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  completed-prompts/$($file.Name)"
}
[System.IO.File]::WriteAllLines(
    $manifestPath,
    $manifest,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Materialized $($promptFiles.Count) completed prompts."
Write-Host "Manifest: $manifestPath"
