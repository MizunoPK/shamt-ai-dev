# =============================================================================
# Shamt Lite Initialization Script (PowerShell — Windows)
# =============================================================================
# Run this script from the root of the project you want to initialize Shamt Lite in.
# Usage:
#   & "C:\path\to\shamt-ai-dev\.shamt\scripts\initialization\init_lite.ps1" [project-name] [-Host claude|codex|claude,codex] [-WithMcp]
#
# Default (no host): writes shamt-lite/ files only — Tier 0 standalone behavior.
# -Host claude:    additionally writes <TARGET>\CLAUDE.md + .claude\{skills,commands,agents}\
# -Host codex:     additionally writes <TARGET>\AGENTS.md + .codex\{agents,config.toml} + .agents\skills\
# -Host claude,codex: both; AGENTS.md is canonical, CLAUDE.md duplicates it
# -WithMcp:        reserved (Tier 3, deferred — currently a no-op)
# =============================================================================

param(
    [string]$ProjectName,
    [string]$HostFlag = "",
    [switch]$WithMcp
)

$ErrorActionPreference = "Stop"

$ShamtSourceDir = $PSScriptRoot
$ShamtRoot = (Get-Item "$ShamtSourceDir\..\..\..").FullName
$TargetDir = (Get-Location).Path
$LiteDir = Join-Path $TargetDir "shamt-lite"

# --- Parse host flag ---------------------------------------------------------

$WantClaude = $false
$WantCodex  = $false
if (-not [string]::IsNullOrWhiteSpace($HostFlag)) {
    $hosts = $HostFlag.Split(',') | ForEach-Object { $_.Trim().ToLower() }
    if ($hosts -contains "claude") { $WantClaude = $true }
    if ($hosts -contains "codex")  { $WantCodex  = $true }
    if (-not $WantClaude -and -not $WantCodex) {
        Write-Host "ERROR: -Host '$HostFlag' is not recognized. Supported: claude, codex, 'claude,codex'" -ForegroundColor Red
        exit 1
    }
}

if ($WithMcp.IsPresent) {
    Write-Host "  ⚠  -WithMcp is reserved for a future Tier 3 release; ignoring." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  Shamt Lite Initialization"
Write-Host "============================================================"
Write-Host "  Source: $ShamtSourceDir"
Write-Host "  Target: $TargetDir"
if (-not [string]::IsNullOrWhiteSpace($HostFlag)) {
    Write-Host "  Host wiring: $HostFlag"
}
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

# --- Host wiring (Tier 1+2) --------------------------------------------------

if ($WantClaude -or $WantCodex) {
    Write-Host ""
    Write-Host "------------------------------------------------------------"
    Write-Host "  Host wiring"
    Write-Host "------------------------------------------------------------"
}

$ClaudeRules = Join-Path $TargetDir "CLAUDE.md"
$CodexRules  = Join-Path $TargetDir "AGENTS.md"

# Codex: prompt for model resolution, write file, deploy AGENTS.md, run regen
if ($WantCodex) {
    Write-Host ""
    Write-Host "Codex needs two model identifiers — these are stored locally and gitignored."
    Write-Host "  FRONTIER_MODEL: deeper-reasoning model (used for design + validation)."
    Write-Host "  DEFAULT_MODEL : cheap-tier model (used for execution + sub-agents)."
    $fm = Read-Host "FRONTIER_MODEL [o3]"
    $dm = Read-Host "DEFAULT_MODEL  [o4-mini]"
    if ([string]::IsNullOrWhiteSpace($fm)) { $fm = "o3" }
    if ([string]::IsNullOrWhiteSpace($dm)) { $dm = "o4-mini" }

    $hostCodexDir = Join-Path $LiteDir "host\codex"
    New-Item -ItemType Directory -Force -Path $hostCodexDir | Out-Null
    $resolutionFile = Join-Path $hostCodexDir ".model_resolution.local.toml"
    Set-Content $resolutionFile -Value "FRONTIER_MODEL = `"$fm`"`nDEFAULT_MODEL = `"$dm`"" -NoNewline -Encoding UTF8

    # gitignore inside shamt-lite/
    $gitignore = Join-Path $LiteDir ".gitignore"
    if (-not (Test-Path $gitignore)) {
        Set-Content $gitignore -Value "host/codex/.model_resolution.local.toml" -NoNewline -Encoding UTF8
    } else {
        $existing = Get-Content $gitignore -Raw
        if ($existing -notmatch '\.model_resolution\.local\.toml') {
            Add-Content $gitignore -Value "`nhost/codex/.model_resolution.local.toml" -Encoding UTF8
        }
    }

    Copy-Item -Path (Join-Path $LiteDir "SHAMT_LITE.md") -Destination $CodexRules
    Write-Host "  ✓ AGENTS.md written ($fm / $dm)"
}

if ($WantClaude) {
    if ($WantCodex) {
        # Dual-host: AGENTS.md is canonical; CLAUDE.md is a duplicate on Windows
        Copy-Item -Path $CodexRules -Destination $ClaudeRules -Force
        Write-Host "  ✓ CLAUDE.md duplicated from AGENTS.md (dual-host)"
    } else {
        Copy-Item -Path (Join-Path $LiteDir "SHAMT_LITE.md") -Destination $ClaudeRules
        Write-Host "  ✓ CLAUDE.md written"
    }
}

# Run regen scripts
if ($WantClaude) {
    $regenClaude = Join-Path $ShamtRoot ".shamt\scripts\regen\regen-lite-claude.ps1"
    if (Test-Path $regenClaude) {
        & $regenClaude
    } else {
        Write-Host "  ⚠  regen-lite-claude.ps1 not found at $regenClaude — skipping" -ForegroundColor Yellow
    }
}

if ($WantCodex) {
    $regenCodex = Join-Path $ShamtRoot ".shamt\scripts\regen\regen-lite-codex.ps1"
    if (Test-Path $regenCodex) {
        & $regenCodex
    } else {
        Write-Host "  ⚠  regen-lite-codex.ps1 not found at $regenCodex — skipping" -ForegroundColor Yellow
    }
}

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
if ($WantClaude) {
    Write-Host ""
    Write-Host "  CLAUDE.md                                  (Claude Code rules file)"
    Write-Host "  .claude\skills\shamt-lite-*\SKILL.md       (5 Lite skills)"
    Write-Host "  .claude\commands\lite-*.md                 (5 Lite slash commands)"
    Write-Host "  .claude\agents\shamt-lite-*.md             (validator + builder personas)"
}
if ($WantCodex) {
    Write-Host ""
    Write-Host "  AGENTS.md                                  (Codex rules file)"
    Write-Host "  .agents\skills\shamt-lite-*\SKILL.md       (5 Lite skills)"
    Write-Host "  .codex\agents\shamt-lite-*.toml            (validator + builder personas)"
    Write-Host "  .codex\config.toml                         (8 SHAMT-LITE-PROFILES)"
    Write-Host "  shamt-lite\host\codex\.model_resolution.local.toml (gitignored)"
}

Write-Host ""
Write-Host "Next steps:"
if ([string]::IsNullOrWhiteSpace($HostFlag)) {
    Write-Host "  1. Copy shamt-lite\SHAMT_LITE.md to your AI service's rules file"
    Write-Host "     (e.g., CLAUDE.md, .cursorrules, copilot-instructions.md)"
    Write-Host ""
    Write-Host "  2. Start a story: create stories\{slug}\ticket.md and follow"
    Write-Host "     story_workflow_lite.md for the six-phase workflow"
} else {
    Write-Host "  1. Start a story: create shamt-lite\stories\{slug}\ticket.md and"
    Write-Host "     invoke /lite-story {slug} (or any of /lite-spec, /lite-plan,"
    Write-Host "     /lite-review, /lite-validate)"
    if ($WantCodex) {
        Write-Host ""
        Write-Host "  2. Codex profile usage: launch a session with the per-phase profile,"
        Write-Host "     e.g.  codex --profile shamt-lite-spec-validate"
    }
}

Write-Host ""
Write-Host "  3. (Optional) Fill out architecture and coding standards templates:"
Write-Host "     • shamt-lite\templates\architecture.template.md → ARCHITECTURE.md"
Write-Host "     • shamt-lite\templates\coding_standards.template.md → CODING_STANDARDS.md"
Write-Host ""
Write-Host "============================================================"
Write-Host ""
