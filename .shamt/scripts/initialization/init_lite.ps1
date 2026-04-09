# =============================================================================
# Shamt Lite Initialization Script (PowerShell — Windows)
# =============================================================================
# Run this script from the root of the project you want to initialize Shamt Lite in.
# Usage: & "C:\path\to\shamt-ai-dev\.shamt\scripts\initialization\init_lite.ps1" [project-name]
# =============================================================================

param([string]$ProjectName)

$ErrorActionPreference = "Stop"

$ShamtSourceDir = $PSScriptRoot
$TargetDir = Get-Location
$LiteDir = Join-Path $TargetDir "shamt-lite"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Shamt Lite Initialization"
Write-Host "============================================================"
Write-Host "  Source: $ShamtSourceDir"
Write-Host "  Target: $TargetDir"
Write-Host "============================================================"
Write-Host ""

# --- Get project name --------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = Read-Host "Enter project name"
    while ([string]::IsNullOrWhiteSpace($ProjectName)) {
        Write-Host "  (Project name is required)" -ForegroundColor Yellow
        $ProjectName = Read-Host "Enter project name"
    }
}

$CurrentDate = Get-Date -Format "yyyy-MM-dd"

Write-Host ""
Write-Host "  Project Name: $ProjectName"
Write-Host "  Date: $CurrentDate"
Write-Host ""

# --- Check if directory already exists ---------------------------------------

if (Test-Path $LiteDir) {
    Write-Host "ERROR: $LiteDir already exists." -ForegroundColor Red
    Write-Host "Remove it first or run this script from a different directory."
    exit 1
}

# --- Create directory structure ----------------------------------------------

Write-Host "Creating directory structure..."
New-Item -ItemType Directory -Path (Join-Path $LiteDir "reference") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $LiteDir "templates") -Force | Out-Null

# --- Helper function for template substitution -------------------------------

function Copy-WithSubstitutions {
    param([string]$SourcePath, [string]$DestPath, [hashtable]$Replacements)

    $content = Get-Content $SourcePath -Raw -Encoding UTF8
    foreach ($key in $Replacements.Keys) {
        $content = $content -replace [regex]::Escape($key), $Replacements[$key]
    }
    Set-Content $DestPath $content -NoNewline -Encoding UTF8
}

$Substitutions = @{
    "{{PROJECT_NAME}}" = $ProjectName
    "{{DATE}}" = $CurrentDate
}

# --- Copy and instantiate files ----------------------------------------------

Write-Host "Copying files..."

# Main rules file
Copy-WithSubstitutions `
    -SourcePath (Join-Path $ShamtSourceDir "SHAMT_LITE.template.md") `
    -DestPath (Join-Path $LiteDir "SHAMT_LITE.md") `
    -Replacements $Substitutions

# Reference files (no template variables)
Copy-Item `
    -Path (Join-Path $ShamtSourceDir "reference\severity_classification_lite.md") `
    -Destination (Join-Path $LiteDir "reference\")

Copy-Item `
    -Path (Join-Path $ShamtSourceDir "reference\validation_exit_criteria_lite.md") `
    -Destination (Join-Path $LiteDir "reference\")

Copy-Item `
    -Path (Join-Path $ShamtSourceDir "reference\question_brainstorm_categories_lite.md") `
    -Destination (Join-Path $LiteDir "reference\")

# Template files (with template variables)
Copy-WithSubstitutions `
    -SourcePath (Join-Path $ShamtSourceDir "templates\discovery_lite.template.md") `
    -DestPath (Join-Path $LiteDir "templates\discovery.template.md") `
    -Replacements $Substitutions

Copy-WithSubstitutions `
    -SourcePath (Join-Path $ShamtSourceDir "templates\architecture_lite.template.md") `
    -DestPath (Join-Path $LiteDir "templates\architecture.template.md") `
    -Replacements $Substitutions

Copy-WithSubstitutions `
    -SourcePath (Join-Path $ShamtSourceDir "templates\coding_standards_lite.template.md") `
    -DestPath (Join-Path $LiteDir "templates\coding_standards.template.md") `
    -Replacements $Substitutions

# Code review template (no template variables)
Copy-Item `
    -Path (Join-Path $ShamtSourceDir "templates\code_review_lite.template.md") `
    -Destination (Join-Path $LiteDir "templates\code_review.template.md")

# Implementation plan template (DATE variable only, no PROJECT_NAME)
Copy-WithSubstitutions `
    -SourcePath (Join-Path $ShamtSourceDir "templates\implementation_plan_lite.template.md") `
    -DestPath (Join-Path $LiteDir "templates\implementation_plan.template.md") `
    -Replacements @{ "{{DATE}}" = $CurrentDate }

# --- Success message ---------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ✓ Shamt Lite initialized successfully!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:"
Write-Host "  shamt-lite\"
Write-Host "  ├── SHAMT_LITE.md                        (main rules file)"
Write-Host "  ├── reference\"
Write-Host "  │   ├── severity_classification_lite.md"
Write-Host "  │   ├── validation_exit_criteria_lite.md"
Write-Host "  │   └── question_brainstorm_categories_lite.md"
Write-Host "  └── templates\"
Write-Host "      ├── discovery.template.md"
Write-Host "      ├── code_review.template.md"
Write-Host "      ├── implementation_plan.template.md"
Write-Host "      ├── architecture.template.md"
Write-Host "      └── coding_standards.template.md"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Copy shamt-lite\SHAMT_LITE.md to your AI service's rules file"
Write-Host "     (e.g., CLAUDE.md, .cursorrules, copilot-instructions.md)"
Write-Host ""
Write-Host "  2. (Optional) Fill out architecture and coding standards templates:"
Write-Host "     • shamt-lite\templates\architecture.template.md → ARCHITECTURE.md"
Write-Host "     • shamt-lite\templates\coding_standards.template.md → CODING_STANDARDS.md"
Write-Host ""
Write-Host "  3. Start using validation loops, discovery, and code review!"
Write-Host ""
Write-Host "============================================================"
Write-Host ""
