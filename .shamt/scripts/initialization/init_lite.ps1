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
New-Item -ItemType Directory -Path (Join-Path $LiteDir "stories") -Force | Out-Null

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

# Story workflow file (no template variables)
Copy-Item `
    -Path (Join-Path $ShamtSourceDir "story_workflow_lite.template.md") `
    -Destination (Join-Path $LiteDir "story_workflow_lite.md")

# CHANGES.md (no template variables)
Copy-Item `
    -Path (Join-Path $ShamtSourceDir "CHANGES.template.md") `
    -Destination (Join-Path $LiteDir "CHANGES.md")

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

# Ticket template (no template variables)
Copy-Item `
    -Path (Join-Path $ShamtSourceDir "templates\ticket.template.md") `
    -Destination (Join-Path $LiteDir "templates\ticket.template.md")

# Spec template (no template variables)
Copy-Item `
    -Path (Join-Path $ShamtSourceDir "templates\spec.template.md") `
    -Destination (Join-Path $LiteDir "templates\spec.template.md")

# Architecture template
Copy-WithSubstitutions `
    -SourcePath (Join-Path $ShamtSourceDir "templates\architecture_lite.template.md") `
    -DestPath (Join-Path $LiteDir "templates\architecture.template.md") `
    -Replacements $Substitutions

# Coding standards template
Copy-WithSubstitutions `
    -SourcePath (Join-Path $ShamtSourceDir "templates\coding_standards_lite.template.md") `
    -DestPath (Join-Path $LiteDir "templates\coding_standards.template.md") `
    -Replacements $Substitutions

# Code review template (no template variables)
Copy-Item `
    -Path (Join-Path $ShamtSourceDir "templates\code_review_lite.template.md") `
    -Destination (Join-Path $LiteDir "templates\code_review.template.md")

# Implementation plan template (no template variables)
Copy-Item `
    -Path (Join-Path $ShamtSourceDir "templates\implementation_plan_lite.template.md") `
    -Destination (Join-Path $LiteDir "templates\implementation_plan.template.md")

# --- Success message ---------------------------------------------------------

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ✓ Shamt Lite initialized successfully!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:"
Write-Host "  shamt-lite\"
Write-Host "  ├── SHAMT_LITE.md                        (5 patterns + token discipline)"
Write-Host "  ├── story_workflow_lite.md               (six-phase story workflow)"
Write-Host "  ├── CHANGES.md                           (Polish-phase upstream candidates)"
Write-Host "  ├── stories\                             (per-story work folders)"
Write-Host "  ├── reference\"
Write-Host "  │   ├── severity_classification_lite.md"
Write-Host "  │   ├── validation_exit_criteria_lite.md"
Write-Host "  │   └── question_brainstorm_categories_lite.md"
Write-Host "  └── templates\"
Write-Host "      ├── ticket.template.md"
Write-Host "      ├── spec.template.md"
Write-Host "      ├── code_review.template.md"
Write-Host "      ├── implementation_plan.template.md"
Write-Host "      ├── architecture.template.md"
Write-Host "      └── coding_standards.template.md"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Copy shamt-lite\SHAMT_LITE.md to your AI service's rules file"
Write-Host "     (e.g., CLAUDE.md, .cursorrules, copilot-instructions.md)"
Write-Host ""
Write-Host "  2. Start a story: create stories\{slug}\ticket.md and follow"
Write-Host "     story_workflow_lite.md for the six-phase workflow"
Write-Host ""
Write-Host "  3. (Optional) Fill out architecture and coding standards templates:"
Write-Host "     • shamt-lite\templates\architecture.template.md → ARCHITECTURE.md"
Write-Host "     • shamt-lite\templates\coding_standards.template.md → CODING_STANDARDS.md"
Write-Host ""
Write-Host "============================================================"
Write-Host ""
