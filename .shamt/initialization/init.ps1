# =============================================================================
# Shamt Initialization Script (PowerShell — Windows)
# =============================================================================
# Run this script from the root of the project you want to initialize Shamt in.
# Usage: & "C:\path\to\shamt-ai-dev\.shamt\initialization\init.ps1"
# =============================================================================

$ErrorActionPreference = "Stop"

$ShamtSourceDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TargetDir = Get-Location
$ShamtDir = Join-Path $TargetDir ".shamt"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Shamt Initialization"
Write-Host "============================================================"
Write-Host "  Source: $ShamtSourceDir"
Write-Host "  Target: $TargetDir"
Write-Host "============================================================"
Write-Host ""

# --- Helpers -----------------------------------------------------------------

function Prompt-Input {
    param([string]$Question, [string]$Default = "")
    if ($Default) {
        $answer = Read-Host "$Question [$Default]"
        if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
        return $answer
    } else {
        return Read-Host $Question
    }
}

function Prompt-Required {
    param([string]$Question)
    $answer = ""
    while ([string]::IsNullOrWhiteSpace($answer)) {
        $answer = Read-Host $Question
        if ([string]::IsNullOrWhiteSpace($answer)) {
            Write-Host "  (This field is required)" -ForegroundColor Yellow
        }
    }
    return $answer
}

function Write-Separator {
    param([string]$Title)
    Write-Host ""
    Write-Host "------------------------------------------------------------"
    Write-Host "  $Title"
    Write-Host "------------------------------------------------------------"
}

function Apply-Substitutions {
    param([string]$FilePath, [hashtable]$Replacements)
    $content = Get-Content $FilePath -Raw
    foreach ($key in $Replacements.Keys) {
        $content = $content -replace [regex]::Escape($key), $Replacements[$key]
    }
    Set-Content $FilePath $content -NoNewline
}

# --- AI Service Selection ----------------------------------------------------

Write-Separator "AI Service"
Write-Host "Which AI coding assistant will you use with this project?"
Write-Host ""
Write-Host "  1) Claude Code (Anthropic)       -> CLAUDE.md at project root"
Write-Host "  2) GitHub Copilot                -> .github/copilot-instructions.md"
Write-Host "  3) Cursor                        -> .cursorrules at project root"
Write-Host "  4) Windsurf (Codeium)            -> .windsurfrules at project root"
Write-Host "  5) Amazon Q Developer            -> (setup TBD)"
Write-Host "  6) Other                         -> you will specify"
Write-Host ""
$aiChoice = Prompt-Input "Enter choice" "1"

switch ($aiChoice) {
    "2" { $AiService = "github_copilot"; $RulesFileName = "copilot-instructions.md"; $RulesFileSubdir = ".github" }
    "3" { $AiService = "cursor"; $RulesFileName = ".cursorrules"; $RulesFileSubdir = "" }
    "4" { $AiService = "windsurf"; $RulesFileName = ".windsurfrules"; $RulesFileSubdir = "" }
    "5" {
        $AiService = "amazon_q"; $RulesFileName = "TBD"; $RulesFileSubdir = ""
        Write-Host "  WARNING: Amazon Q rules file convention is not yet confirmed." -ForegroundColor Yellow
        Write-Host "  The agent will help you determine the correct setup." -ForegroundColor Yellow
    }
    "6" {
        $AiService = "other"
        $RulesFileName = Prompt-Required "  Rules file name (e.g. .myrules)"
        $subdir = Prompt-Input "  Rules file subdirectory relative to project root (leave blank for root)" ""
        $RulesFileSubdir = $subdir
    }
    default { $AiService = "claude_code"; $RulesFileName = "CLAUDE.md"; $RulesFileSubdir = "" }
}

if ($RulesFileSubdir) {
    $RulesFileDir = Join-Path $TargetDir $RulesFileSubdir
} else {
    $RulesFileDir = $TargetDir
}

Write-Host "  OK AI service: $AiService"

# --- Project Details ---------------------------------------------------------

Write-Separator "Project Details"

$ProjectName = Prompt-Required "  Project name"
$EpicTag = (Prompt-Input "  Epic tag (e.g. SHAMT, MYPROJ)" "SHAMT").ToUpper()
$ShamtName = Prompt-Input "  Agent name (your version of Shamt)" "Shamt"
$StartingEpic = Prompt-Input "  Starting epic number" "1"

# --- Git Configuration -------------------------------------------------------

Write-Separator "Git Configuration"

Write-Host "Which git platform will you use?"
Write-Host "  1) GitHub"
Write-Host "  2) GitLab"
Write-Host "  3) Other / none"
$gitChoice = Prompt-Input "Enter choice" "1"

switch ($gitChoice) {
    "2" { $GitPlatform = "gitlab" }
    "3" { $GitPlatform = "other" }
    default { $GitPlatform = "github" }
}

$DefaultBranch = Prompt-Input "  Default/main branch name" "main"

Write-Host "  OK Git platform: $GitPlatform"
Write-Host "  OK Default branch: $DefaultBranch"

# --- Confirmation ------------------------------------------------------------

Write-Separator "Review"
Write-Host "  Project name:      $ProjectName"
Write-Host "  Epic tag:          $EpicTag"
Write-Host "  Agent name:        $ShamtName"
Write-Host "  Starting epic #:   $StartingEpic"
Write-Host "  AI service:        $AiService"
Write-Host "  Rules file:        $RulesFileName"
Write-Host "  Rules file path:   $RulesFileDir\"
Write-Host "  Git platform:      $GitPlatform"
Write-Host "  Default branch:    $DefaultBranch"
Write-Host "  Epic directory:    .shamt\epics\"
Write-Host ""

$confirm = Prompt-Input "Proceed with initialization? [Y/n]" "Y"
if ($confirm -notmatch '^[Yy]$') {
    Write-Host "Initialization cancelled."
    exit 0
}

# --- Create Folder Structure -------------------------------------------------

Write-Separator "Creating folder structure"

$dirs = @(
    "$ShamtDir\guides",
    "$ShamtDir\initialization",
    "$ShamtDir\epics\requests",
    "$ShamtDir\epics\done",
    "$ShamtDir\changelogs\outbound",
    "$ShamtDir\changelogs\unapplied_external_changes",
    "$ShamtDir\changelogs\applied_external_changes",
    $RulesFileDir
)
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

Write-Host "  OK .shamt\ structure created"

# --- Copy Guides -------------------------------------------------------------

Write-Separator "Copying guides"

Copy-Item -Path "$ShamtSourceDir\.shamt\guides\*" -Destination "$ShamtDir\guides\" -Recurse -Force
Copy-Item -Path "$ShamtSourceDir\.shamt\initialization\*" -Destination "$ShamtDir\initialization\" -Recurse -Force
Write-Host "  OK Guides and initialization files copied"

# --- Configure Rules File ----------------------------------------------------

Write-Separator "Configuring rules file"

$RulesDest = Join-Path $RulesFileDir $RulesFileName
$RulesTemplate = Join-Path $ShamtDir "initialization\RULES_FILE.template.md"
$RulesFileExisted = $false

if (Test-Path $RulesDest) {
    Write-Host "  WARNING: $RulesFileName already exists at $RulesFileDir\" -ForegroundColor Yellow
    $overwrite = Prompt-Input "  Overwrite? [y/N]" "N"
    if ($overwrite -notmatch '^[Yy]$') {
        Write-Host "  Skipping rules file - agent will incorporate existing file."
        $RulesFileExisted = $true
    }
}

if (-not $RulesFileExisted) {
    Copy-Item $RulesTemplate $RulesDest -Force
    Write-Host "  OK Rules file written to $RulesDest"
}

# --- Apply Substitutions -----------------------------------------------------

Write-Separator "Applying configuration"

$replacements = @{
    "{{PROJECT_NAME}}"  = $ProjectName
    "{{EPIC_TAG}}"      = $EpicTag
    "{{SHAMT_NAME}}"    = $ShamtName
    "{{GIT_PLATFORM}}"  = $GitPlatform
    "{{DEFAULT_BRANCH}}"= $DefaultBranch
    "SHAMT-{N}"         = "$EpicTag-{N}"
}

# Apply to rules file
if (-not $RulesFileExisted) {
    Apply-Substitutions -FilePath $RulesDest -Replacements $replacements
}

# Apply to guides (epic tag and branch name only)
Get-ChildItem -Path "$ShamtDir\guides" -Filter "*.md" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $content = $content -replace [regex]::Escape("{{EPIC_TAG}}"), $EpicTag
    $content = $content -replace [regex]::Escape("SHAMT-{N}"), "$EpicTag-{N}"
    $content = $content -replace [regex]::Escape("{{DEFAULT_BRANCH}}"), $DefaultBranch
    $content = $content -replace [regex]::Escape("{{GIT_PLATFORM}}"), $GitPlatform
    Set-Content $_.FullName $content -NoNewline
}

# Create EPIC_TRACKER.md
$epicTrackerDest = Join-Path $ShamtDir "epics\EPIC_TRACKER.md"
Copy-Item (Join-Path $ShamtDir "initialization\EPIC_TRACKER.template.md") $epicTrackerDest -Force
Apply-Substitutions -FilePath $epicTrackerDest -Replacements $replacements
# Set starting number
(Get-Content $epicTrackerDest -Raw) -replace "$EpicTag-1", "$EpicTag-$StartingEpic" | Set-Content $epicTrackerDest -NoNewline

# Create CHANGELOG_INDEX files
@"
# Applied External Changes Index

**Current Version:** v0000 (no changelogs applied yet)

| Version | Date Applied | Summary |
|---------|-------------|---------|
| — | — | No changelogs applied yet |
"@ | Set-Content "$ShamtDir\changelogs\applied_external_changes\CHANGELOG_INDEX.md"

@"
# Outbound Changelog Index

| Entry ID | Date | Summary | Submitted to Master |
|----------|------|---------|---------------------|
| — | — | No changelog entries yet | — |
"@ | Set-Content "$ShamtDir\changelogs\outbound\CHANGELOG_INDEX.md"

Write-Host "  OK Configuration applied"

# --- Write init_config.md ----------------------------------------------------

Write-Separator "Writing handoff file for agent"

$needsAiDiscovery = ($AiService -eq "other" -or $AiService -eq "amazon_q").ToString().ToLower()
$today = Get-Date -Format "yyyy-MM-dd"
$rulesNote = if ($RulesFileExisted) { "- Existing rules file was preserved — agent should incorporate it into new RULES_FILE content." } else { "- Rules file written fresh from template." }
$aiNote = if ($needsAiDiscovery -eq "true") { "- AI service '$AiService' needs rules file convention confirmed. Agent should research and update ai_services.md." } else { "" }

@"
# Shamt Initialization Config

**Generated:** $today
**Status:** PENDING_AGENT_COMPLETION

## Project Configuration
- **Project Name:** $ProjectName
- **Epic Tag:** $EpicTag
- **Shamt Agent Name:** $ShamtName
- **Starting Epic Number:** $StartingEpic
- **Epic Working Directory:** .shamt/epics/

## AI Service
- **Service:** $AiService
- **Rules File Name:** $RulesFileName
- **Rules File Path:** $RulesFileDir\
- **Needs AI Discovery:** $needsAiDiscovery

## Git Configuration
- **Platform:** $GitPlatform
- **Default Branch:** $DefaultBranch

## Script Actions Completed
- [x] Created .shamt\ folder structure
- [x] Copied guides from master Shamt
- [x] Copied initialization files
- [x] Placed rules file at $RulesFileDir\$RulesFileName
- [x] Created EPIC_TRACKER.md at .shamt\epics\EPIC_TRACKER.md
- [x] Created CHANGELOG_INDEX.md files
- [x] Applied configuration substitutions

## Agent Remaining Tasks
- [ ] Handle AI service discovery (if Needs AI Discovery = true)
- [ ] Analyze codebase structure, languages, frameworks
- [ ] Write ARCHITECTURE.md (incorporate existing content if present)
- [ ] Write CODING_STANDARDS.md (incorporate existing content if present)
- [ ] Customize guides for this project (test commands, project-specific notes)
- [ ] Add 3-5 key coding rules to rules file summary section
- [ ] Mark this file complete: change Status to COMPLETE

## Notes
$rulesNote
$aiNote
"@ | Set-Content "$ShamtDir\init_config.md"

Write-Host "  OK Handoff file written to .shamt\init_config.md"

# --- Done --------------------------------------------------------------------

Write-Separator "Done!"
Write-Host ""
Write-Host "  Shamt has been initialized in: $TargetDir"
Write-Host ""
Write-Host "  Next step: open your project in $ShamtName (your AI assistant) and say:"
Write-Host ""
Write-Host "    `"Read .shamt/init_config.md and complete the Shamt initialization.`""
Write-Host ""
Write-Host "  The agent will analyze your codebase and finish setup."
Write-Host ""
Write-Host "============================================================"
Write-Host ""
