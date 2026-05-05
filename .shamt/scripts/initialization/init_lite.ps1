# =============================================================================
# Shamt Lite Initialization Script (PowerShell — Windows)
# =============================================================================
# Run this script from the root of the project you want to initialize Shamt Lite in.
# Usage:
#   & "C:\path\to\shamt-ai-dev\.shamt\scripts\initialization\init_lite.ps1" [project-name] [-Host claude|codex|cursor|...] [-WithMcp]
#
# Default (no host): writes shamt-lite/ files only — Tier 0 standalone behavior.
# -Host claude:         additionally writes <TARGET>\CLAUDE.md + .claude\{skills,commands,agents}\
# -Host codex:          additionally writes <TARGET>\AGENTS.md + .codex\{agents,config.toml} + .agents\skills\
# -Host cursor:         additionally writes .cursor\{skills,commands,rules,agents}\; prompts for cheap-tier model
# -Host claude,codex:   both Claude + Codex; AGENTS.md is canonical, CLAUDE.md is a duplicate
# -Host cursor,codex:   both Cursor + Codex; independent deployments
# (any comma-separated combination of claude, codex, cursor is accepted)
# -WithMcp:             reserved (Tier 3, deferred — currently a no-op)
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
$WantCursor = $false
if (-not [string]::IsNullOrWhiteSpace($HostFlag)) {
    $hosts = $HostFlag.Split(',') | ForEach-Object { $_.Trim().ToLower() }
    if ($hosts -contains "claude") { $WantClaude = $true }
    if ($hosts -contains "codex")  { $WantCodex  = $true }
    if ($hosts -contains "cursor") { $WantCursor = $true }
    if (-not $WantClaude -and -not $WantCodex -and -not $WantCursor) {
        Write-Host "ERROR: -Host '$HostFlag' is not recognized. Supported: claude, codex, cursor (comma-separated combinations OK)" -ForegroundColor Red
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

if ($WantClaude -or $WantCodex -or $WantCursor) {
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
        if ($existing -notmatch 'host/codex/\.model_resolution\.local\.toml') {
            Add-Content $gitignore -Value "`nhost/codex/.model_resolution.local.toml" -Encoding UTF8
        }
    }

    Copy-Item -Path (Join-Path $LiteDir "SHAMT_LITE.md") -Destination $CodexRules
    Write-Host "  ✓ AGENTS.md written ($fm / $dm)"
}

# --- Write ai_service.conf + update gitignore --------------------------------

$svcParts = @()
if ($WantClaude) { $svcParts += 'claude' }
if ($WantCodex)  { $svcParts += 'codex' }
if ($WantCursor) { $svcParts += 'cursor' }
$AiServiceConf = if ($svcParts.Count -eq 0) { 'none' } else { $svcParts -join '_' }

$ConfigDir = Join-Path $LiteDir "config"
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
[System.IO.File]::WriteAllText((Join-Path $ConfigDir "ai_service.conf"), "$AiServiceConf`n", [System.Text.Encoding]::UTF8)

$gitignore = Join-Path $LiteDir ".gitignore"
if (-not (Test-Path $gitignore)) {
    [System.IO.File]::WriteAllText($gitignore, "config/`nCHEATSHEET.md`n", [System.Text.Encoding]::UTF8)
} else {
    $existing = Get-Content $gitignore -Raw
    if ($existing -notmatch '(?m)^config/$') {
        Add-Content $gitignore -Value "`nconfig/" -Encoding UTF8
    }
    if ($existing -notmatch '(?m)^CHEATSHEET\.md$') {
        Add-Content $gitignore -Value "CHEATSHEET.md" -Encoding UTF8
    }
}

# Cursor: prompt for cheap-tier model, write resolution file, run regen
if ($WantCursor) {
    Write-Host ""
    Write-Host "Cursor needs a cheap-tier model identifier for sub-agent personas."
    Write-Host "  'inherit' (default): Cursor uses whatever model is currently active."
    Write-Host "  Specific id (e.g. claude-haiku-4-5): pin to a fast cheap model."
    $cm = Read-Host "Cursor cheap-tier model id [inherit]"
    if ([string]::IsNullOrWhiteSpace($cm)) { $cm = "inherit" }

    $hostCursorDir = Join-Path $LiteDir "host\cursor"
    New-Item -ItemType Directory -Force -Path $hostCursorDir | Out-Null
    $cursorResolutionFile = Join-Path $hostCursorDir ".model_resolution.local.toml"
    Set-Content $cursorResolutionFile -Value "CHEAP_MODEL = `"$cm`"" -NoNewline -Encoding UTF8

    # gitignore inside shamt-lite/
    $gitignore = Join-Path $LiteDir ".gitignore"
    if (-not (Test-Path $gitignore)) {
        Set-Content $gitignore -Value "host/cursor/.model_resolution.local.toml" -NoNewline -Encoding UTF8
    } else {
        $existing = Get-Content $gitignore -Raw
        if ($existing -notmatch 'host/cursor/\.model_resolution\.local\.toml') {
            Add-Content $gitignore -Value "`nhost/cursor/.model_resolution.local.toml" -Encoding UTF8
        }
    }

    $regenCursor = Join-Path $ShamtRoot ".shamt\scripts\regen\regen-lite-cursor.ps1"
    if (Test-Path $regenCursor) {
        & $regenCursor
    } else {
        Write-Host "  ⚠  regen-lite-cursor.ps1 not found at $regenCursor — skipping" -ForegroundColor Yellow
    }

    Write-Host "  ✓ Cursor wiring deployed (cheap-tier model: $cm)"
    Write-Host "    To change later: edit .cursor\agents\shamt-lite-*.md or re-run init_lite.ps1 -Host cursor"
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

# --- Generate CHEATSHEET.md --------------------------------------------------

$csPath     = Join-Path $LiteDir "CHEATSHEET.md"
$configPath = Join-Path $LiteDir "config\ai_service.conf"

$aiSvc  = (Get-Content $configPath -Raw).Trim()
$parts  = $aiSvc -split '_'
$hasClaude = $parts -contains 'claude'
$hasCodex  = $parts -contains 'codex'
$hasCursor = $parts -contains 'cursor'

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('# Shamt Lite — Cheat Sheet')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('> Generated by Shamt. Re-run init_lite or a regen-lite script to refresh.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Six-Phase Story Workflow')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Phase | Artifact | Gate |')
[void]$sb.AppendLine('|-------|----------|------|')
[void]$sb.AppendLine('| 1. Intake | `stories/{slug}/ticket.md` | User confirms slug + content |')
[void]$sb.AppendLine('| 2. Spec   | `stories/{slug}/spec.md` | (2a) User picks design, (2b) User approves validated spec |')
[void]$sb.AppendLine('| 3. Plan   | `stories/{slug}/implementation_plan.md` | User approves validated plan |')
[void]$sb.AppendLine('| 4. Build  | code changes | Verification checklist in plan |')
[void]$sb.AppendLine('| 5. Review | `stories/{slug}/code_review/review_v1.md` | Review is the artifact |')
[void]$sb.AppendLine('| 6. Polish | commit messages + CHANGES.md entries | User signals "polishing complete" |')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Core Patterns')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Pattern | When to use |')
[void]$sb.AppendLine('|---------|-------------|')
[void]$sb.AppendLine('| P1: Validation Loop | Verifying any artifact (spec, plan, review) |')
[void]$sb.AppendLine('| P2: Ask-First | Before large artifacts — surface assumptions first |')
[void]$sb.AppendLine('| P3: Spec Protocol | Spec phase — 7 structured steps to validated spec |')
[void]$sb.AppendLine('| P4: Code Review | Review phase — ELI5 + dimensions + PR comment blocks |')
[void]$sb.AppendLine('| P5: Implementation Planning | Plan phase — mechanical step-by-step plan |')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Validation Rules')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('- **Clean round:** 0 issues OR exactly 1 LOW (fixed)')
[void]$sb.AppendLine('- **Reset:** any MEDIUM/HIGH/CRITICAL or multiple LOWs -> `consecutive_clean = 0`')
[void]$sb.AppendLine('- **Exit:** `consecutive_clean = 1` + 1 Haiku sub-agent confirms zero issues')
[void]$sb.AppendLine('- Severity: CRITICAL > HIGH > MEDIUM > LOW')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Context-Clear Breakpoints')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Suggest `/clear` after Gate 2b (spec approved) and after Gate 3 (plan approved).')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Builder Handoff')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('If plan has **>10 mechanical steps**: spawn Haiku builder (see Pattern 5 in SHAMT_LITE.md).')
[void]$sb.AppendLine('')

if ($hasClaude) {
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Slash Commands (Claude Code)')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Command | Phase |')
    [void]$sb.AppendLine('|---------|-------|')
    [void]$sb.AppendLine('| `/lite-story {slug}` | Intake — start a new story |')
    [void]$sb.AppendLine('| `/lite-spec {slug}` | Spec — run spec protocol |')
    [void]$sb.AppendLine('| `/lite-plan {slug}` | Plan — write implementation plan |')
    [void]$sb.AppendLine('| `/lite-review` | Review — code review of current changes |')
    [void]$sb.AppendLine('| `/lite-validate` | Any — run a validation loop |')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Skills (auto-triggered)')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Skill | Trigger phrases |')
    [void]$sb.AppendLine('|-------|----------------|')
    [void]$sb.AppendLine('| `shamt-lite-story` | "start a story", "run lite story workflow" |')
    [void]$sb.AppendLine('| `shamt-lite-spec` | "spec this ticket", "run the spec protocol" |')
    [void]$sb.AppendLine('| `shamt-lite-plan` | "plan this", "create an implementation plan" |')
    [void]$sb.AppendLine('| `shamt-lite-review` | "review this branch", "review the changes" |')
    [void]$sb.AppendLine('| `shamt-lite-validate` | "validate this", "run a validation loop" |')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Personas')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Persona | Use |')
    [void]$sb.AppendLine('|---------|-----|')
    [void]$sb.AppendLine('| `shamt-lite-builder` | Haiku — executes mechanical implementation plans |')
    [void]$sb.AppendLine('| `shamt-lite-validator` | Haiku — sub-agent confirmation |')
    [void]$sb.AppendLine('')
}
if ($hasCodex) {
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Codex Profiles')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Switch profiles at phase boundaries (each transition = new session):')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Phase | Profile flag |')
    [void]$sb.AppendLine('|-------|-------------|')
    [void]$sb.AppendLine('| Intake | `codex --profile shamt-lite-intake` |')
    [void]$sb.AppendLine('| Spec (research) | `codex --profile shamt-lite-spec-research` |')
    [void]$sb.AppendLine('| Spec (design) | `codex --profile shamt-lite-spec-design` |')
    [void]$sb.AppendLine('| Spec (validation) | `codex --profile shamt-lite-spec-validate` |')
    [void]$sb.AppendLine('| Plan | `codex --profile shamt-lite-plan` |')
    [void]$sb.AppendLine('| Build | `codex --profile shamt-lite-build` |')
    [void]$sb.AppendLine('| Review | `codex --profile shamt-lite-review` |')
    [void]$sb.AppendLine('| Validation sub-agent | `codex --profile shamt-lite-validator` |')
    [void]$sb.AppendLine('')
}
if ($hasCursor) {
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Cursor Rules')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Shamt Lite `.mdc` rules are active in `.cursor/rules/`. They auto-attach')
    [void]$sb.AppendLine('based on file glob patterns — no manual activation needed.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Explicitly invoke a pattern in your prompt:')
    [void]$sb.AppendLine('- "run the spec protocol for {slug}"')
    [void]$sb.AppendLine('- "write an implementation plan"')
    [void]$sb.AppendLine('- "validate this artifact"')
    [void]$sb.AppendLine('- "do a code review of this branch"')
    [void]$sb.AppendLine('')
}
if (-not $hasClaude -and -not $hasCodex -and -not $hasCursor) {
    [void]$sb.AppendLine('---')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Natural Language Triggers')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('No host-specific commands configured. Reference patterns by name:')
    [void]$sb.AppendLine('- "run the spec protocol" -> Pattern 3')
    [void]$sb.AppendLine('- "validate this" -> Pattern 1')
    [void]$sb.AppendLine('- "write an implementation plan" -> Pattern 5')
    [void]$sb.AppendLine('- "code review" -> Pattern 4')
    [void]$sb.AppendLine('- "start a story" -> story_workflow_lite.md')
    [void]$sb.AppendLine('')
}

$csContent = $sb.ToString() -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($csPath, $csContent, [System.Text.Encoding]::UTF8)
Write-Host "  Cheat sheet: written to shamt-lite/CHEATSHEET.md (service: $aiSvc)"

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
Write-Host "  ├── CHEATSHEET.md                           (service-specific quick reference, gitignored)"
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
if ($WantCursor) {
    Write-Host ""
    Write-Host "  .cursor\skills\shamt-lite-*\SKILL.md       (5 Lite skills)"
    Write-Host "  .cursor\commands\lite-*.md                 (5 Lite slash commands)"
    Write-Host "  .cursor\rules\lite-*.mdc                   (5 attachment-aware rules)"
    Write-Host "  .cursor\agents\shamt-lite-*.md             (validator + builder personas)"
    Write-Host "  shamt-lite\host\cursor\.model_resolution.local.toml (gitignored)"
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
