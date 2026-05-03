# =============================================================================
# Shamt Initialization Script (PowerShell — Windows)
# =============================================================================
# Run this script from the root of the project you want to initialize Shamt in.
# Usage: & "C:\path\to\shamt-ai-dev\.shamt\scripts\initialization\init.ps1"
# =============================================================================

$ErrorActionPreference = "Stop"

$ShamtSourceDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$TargetDir = Get-Location
$ShamtDir = Join-Path $TargetDir ".shamt"

# Parse --host, --with-cloud, and --pr-provider flags
$HostFlag = ""
$WithCloud = $false
$PrProviderFlag = ""
foreach ($arg in $args) {
    if ($arg -match '^--host=(.+)$')        { $HostFlag = $matches[1] }
    if ($arg -eq '--with-cloud')            { $WithCloud = $true }
    if ($arg -match '^--pr-provider=(.+)$') { $PrProviderFlag = $matches[1] }
}

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

function Add-ExcludeEntry {
    param([string]$ExcludeFile, [string]$Entry)
    if (Test-Path $ExcludeFile) {
        $existing = Get-Content $ExcludeFile -Raw
        if ($existing -notlike "*$Entry*") {
            Add-Content $ExcludeFile "`n$Entry"
        }
    } else {
        Set-Content $ExcludeFile $Entry
    }
}

function Invoke-SetupMcp {
    $mcpDst = Join-Path $ShamtDir "mcp"
    if (-not (Test-Path $mcpDst)) {
        Copy-Item -Path (Join-Path $ShamtSourceDir ".shamt\mcp") -Destination $mcpDst -Recurse -Force
        Write-Host "  OK MCP dir copied"
    }
    if (Get-Command python3 -ErrorAction SilentlyContinue) {
        Write-Host "  Setting up MCP venv (this may take a moment)..."
        try {
            python3 -m venv (Join-Path $mcpDst ".venv")
            & (Join-Path $mcpDst ".venv\Scripts\pip") install -e $mcpDst -q
            Write-Host "  OK MCP venv created and shamt-mcp installed"
        } catch {
            Write-Host "  WARNING: MCP setup failed — MCP will not be registered. Re-run after fixing the issue." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  WARNING: python3 not found — MCP setup skipped." -ForegroundColor Yellow
    }
}

# --- AI Service Selection ----------------------------------------------------

Write-Separator "AI Service"

$CodexFrontierModel = ""
$CodexDefaultModel  = ""

if ($HostFlag -ne "" -and $HostFlag -match "codex") {
    if ($HostFlag -match "claude") {
        $AiService = "claude_codex"; $RulesFileName = "AGENTS.md"; $RulesFileSubdir = ""
    } else {
        $AiService = "codex"; $RulesFileName = "AGENTS.md"; $RulesFileSubdir = ""
    }
    $RulesFileDir = $TargetDir
    Write-Host "  -> Host flag: $HostFlag — AI service set to $AiService"
} elseif ($HostFlag -ne "" -and $HostFlag -match "claude") {
    $AiService = "claude_code"; $RulesFileName = "CLAUDE.md"; $RulesFileSubdir = ""
    $RulesFileDir = $TargetDir
    Write-Host "  -> Host flag: $HostFlag — AI service set to claude_code"
} else {
    Write-Host "Which AI coding assistant will you use with this project?"
    Write-Host ""
    Write-Host "  1) Claude Code (Anthropic)       -> CLAUDE.md at project root"
    Write-Host "  2) Codex (OpenAI)                -> AGENTS.md at project root"
    Write-Host "  3) GitHub Copilot                -> .github/copilot-instructions.md"
    Write-Host "  4) Cursor                        -> .cursorrules (legacy) or .cursor\index.mdc (new)"
    Write-Host "  5) Windsurf (Codeium)            -> .windsurfrules at project root"
    Write-Host "  6) Amazon Q Developer            -> (setup TBD)"
    Write-Host "  7) Other                         -> you will specify"
    Write-Host ""
    $aiChoice = Prompt-Input "Enter choice" "1"

    switch ($aiChoice) {
        "2" { $AiService = "codex"; $RulesFileName = "AGENTS.md"; $RulesFileSubdir = "" }
        "3" { $AiService = "github_copilot"; $RulesFileName = "copilot-instructions.md"; $RulesFileSubdir = ".github" }
        "4" {
            $AiService = "cursor"
            Write-Host ""
            Write-Host "  Cursor supports two rules file formats:"
            Write-Host "    1) Legacy .cursorrules (project root) - still widely used"
            Write-Host "    2) New .cursor\index.mdc - recommended as of 2026"
            Write-Host ""
            $cursorFormat = Prompt-Input "  Which format?" "2"
            if ($cursorFormat -eq "1") {
                $RulesFileName = ".cursorrules"
                $RulesFileSubdir = ""
            } else {
                $RulesFileName = "index.mdc"
                $RulesFileSubdir = ".cursor"
            }
        }
        "5" { $AiService = "windsurf"; $RulesFileName = ".windsurfrules"; $RulesFileSubdir = "" }
        "6" {
            $AiService = "amazon_q"; $RulesFileName = "TBD"; $RulesFileSubdir = ""
            Write-Host "  WARNING: Amazon Q rules file convention is not yet confirmed." -ForegroundColor Yellow
            Write-Host "  The agent will help you determine the correct setup." -ForegroundColor Yellow
        }
        "7" {
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
}

# Prompt for Codex model names when Codex is selected
if ($AiService -match "codex") {
    Write-Host ""
    Write-Host "  Codex model names (from Codex changelog — press Enter to accept defaults):"
    $fm = Read-Host "    Frontier model [o3]"
    if ([string]::IsNullOrWhiteSpace($fm)) { $fm = "o3" }
    $dm = Read-Host "    Default model  [o4-mini]"
    if ([string]::IsNullOrWhiteSpace($dm)) { $dm = "o4-mini" }
    $CodexFrontierModel = $fm
    $CodexDefaultModel  = $dm
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

# --- Repository Configuration ------------------------------------------------

Write-Separator "Repository Configuration"

Write-Host "  Should .shamt/ and the rules file be excluded from git in this project?"
Write-Host "  This uses .git/info/exclude — local only, never committed or visible to other users."
Write-Host "  Default: YES (recommended for solo/multi-agent work — keeps epic state files out of git)."
Write-Host "  Choose 'no' only if you need to share .shamt/ with other developers via git."
Write-Host ""
$excludeChoice = Prompt-Input "  Locally exclude .shamt/ and rules file from git? [Y/n]" "Y"
if ($excludeChoice -match '^[Yy]$') {
    $ExcludeShamt = $true
} else {
    $ExcludeShamt = $false
}

Write-Host "  OK Locally exclude .shamt/ and rules file (default: yes): $ExcludeShamt"

# --- Confirmation ------------------------------------------------------------

Write-Separator "Review"
Write-Host "  Project name:          $ProjectName"
Write-Host "  Epic tag:              $EpicTag"
Write-Host "  Agent name:            $ShamtName"
Write-Host "  Starting epic #:       $StartingEpic"
Write-Host "  AI service:            $AiService"
Write-Host "  Rules file:            $RulesFileName"
Write-Host "  Rules file path:       $RulesFileDir\"
if ($CodexFrontierModel -ne "") {
    Write-Host "  Codex frontier model:  $CodexFrontierModel"
    Write-Host "  Codex default model:   $CodexDefaultModel"
}
Write-Host "  Git platform:          $GitPlatform"
Write-Host "  Default branch:        $DefaultBranch"
Write-Host "  Exclude .shamt/ (local): $ExcludeShamt"
Write-Host "  Epic directory:        .shamt\epics\"
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
    "$ShamtDir\scripts",
    "$ShamtDir\project-specific-configs",
    "$ShamtDir\epics\requests",
    "$ShamtDir\epics\done",
    "$ShamtDir\unimplemented_design_proposals",
    $RulesFileDir
)
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

Write-Host "  OK .shamt\ structure created"

# --- Write Config Files ------------------------------------------------------

Write-Separator "Writing config files"

Set-Content "$ShamtDir\shamt_master_path.conf" $ShamtSourceDir -NoNewline
Write-Host "  OK Master path written to .shamt\shamt_master_path.conf"

$rulesFilePath = Join-Path $RulesFileDir $RulesFileName
Set-Content "$ShamtDir\rules_file_path.conf" $rulesFilePath -NoNewline
Write-Host "  OK Rules file path written to .shamt\rules_file_path.conf"

$syncDate = Get-Date -Format "yyyy-MM-dd"
$masterHashResult = & git -C $ShamtSourceDir rev-parse --short HEAD 2>&1
$masterHash = if ($LASTEXITCODE -eq 0) { ($masterHashResult | Out-String).Trim() } else { "unknown" }
Set-Content (Join-Path $ShamtDir "last_sync.conf") "$syncDate | $masterHash" -NoNewline
Write-Host "  OK Sync state written to .shamt\last_sync.conf"

$ConfigDir = Join-Path $ShamtDir "config"
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
Set-Content (Join-Path $ConfigDir "ai_service.conf") $AiService -NoNewline
if ($TargetDir -eq $ShamtSourceDir) {
    Set-Content (Join-Path $ConfigDir "repo_type.conf") "master" -NoNewline
} else {
    Set-Content (Join-Path $ConfigDir "repo_type.conf") "child" -NoNewline
}
Set-Content (Join-Path $ConfigDir "epic_tag.conf") $EpicTag -NoNewline

# PR provider config
$PrProviderConfPath = Join-Path $ConfigDir "pr_provider.conf"
$AdoOrgPath = Join-Path $ConfigDir "ado_org.txt"
$PrProvider = if ($PrProviderFlag) { $PrProviderFlag }
              elseif (Test-Path $PrProviderConfPath) { (Get-Content $PrProviderConfPath -Raw).Trim() }
              else {
                  Write-Host ""
                  Write-Host "  PR provider (default: github):"
                  Write-Host "    1) github  - GitHub Actions CI + GitHub PR comments"
                  Write-Host "    2) ado     - Azure Pipelines CI + ADO PR comment threads"
                  Write-Host "    3) both    - configure both"
                  $choice = Read-Host "  Enter choice [1/2/3] (press Enter for github)"
                  switch ($choice) { "2" { "ado" } "3" { "both" } default { "github" } }
              }
Set-Content $PrProviderConfPath $PrProvider -NoNewline

if ($PrProvider -match "ado") {
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "  WARNING: 'npx' not found. Node.js 20+ is required for the ADO MCP Server." -ForegroundColor Yellow
        Write-Host "  Install Node.js from https://nodejs.org and re-run init, or run regen-claude-shims.ps1 after installing." -ForegroundColor Yellow
    }
    $existingOrg = if (Test-Path $AdoOrgPath) { (Get-Content $AdoOrgPath -Raw).Trim() } else { "" }
    if (-not $existingOrg) {
        $adoOrg = Read-Host "  Enter your ADO organization name (e.g. 'myorg' from dev.azure.com/myorg)"
        Set-Content $AdoOrgPath $adoOrg -NoNewline
        Write-Host "  OK ADO org stored in .shamt\config\ado_org.txt"
    }
    Write-Host ""
    Write-Host "  ℹ  ADO MCP Server: on first use, your browser will open for Microsoft Entra authentication."
}

Write-Host "  OK Host config written to .shamt\config\"

# --- Configure local git excludes --------------------------------------------

Write-Separator "Configuring local git excludes"

$GitExcludeDir = Join-Path $TargetDir ".git\info"
$GitExcludeFile = Join-Path $GitExcludeDir "exclude"

if (-not (Test-Path $GitExcludeDir)) {
    Write-Host "  WARNING: .git\info\ not found — is this a git repository?" -ForegroundColor Yellow
    Write-Host "  Run 'git init' first, then re-run init to apply local excludes." -ForegroundColor Yellow
    Write-Host "  Skipping local excludes configuration." -ForegroundColor Yellow
} else {
    # Always exclude *.conf files (covers shamt_master_path.conf, last_sync.conf, rules_file_path.conf, etc.)
    Add-ExcludeEntry -ExcludeFile $GitExcludeFile -Entry ".shamt/*.conf"
    Write-Host "  OK .shamt/*.conf added to .git/info/exclude (always)"

    # Always exclude import_diff*.md (transient diff files — never commit)
    Add-ExcludeEntry -ExcludeFile $GitExcludeFile -Entry ".shamt/import_diff*.md"
    Write-Host "  OK .shamt/import_diff*.md added to .git/info/exclude (always)"

    # Always exclude VALIDATION_LOG* (transient validation logs — never commit)
    Add-ExcludeEntry -ExcludeFile $GitExcludeFile -Entry "*VALIDATION_LOG*"
    Write-Host "  OK *VALIDATION_LOG* added to .git/info/exclude (always)"

    # Optionally exclude .shamt/ and rules file
    if ($ExcludeShamt) {
        # Warn if .shamt/ is already tracked by git (migration required)
        $trackedCheck = & git -C $TargetDir ls-files .shamt/ 2>&1 | Select-Object -First 1
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($trackedCheck)) {
            Write-Host ""
            Write-Host "  WARNING: .shamt/ is currently tracked by git. To migrate:" -ForegroundColor Yellow
            Write-Host "       git rm -r --cached .shamt/" -ForegroundColor Yellow
            Write-Host "       git commit -m ""stop tracking .shamt/ framework directory""" -ForegroundColor Yellow
            Write-Host "  (Continuing -- adding .shamt/ to .git/info/exclude now; run the commands above when ready)" -ForegroundColor Yellow
        }
        Add-ExcludeEntry -ExcludeFile $GitExcludeFile -Entry ".shamt/"
        if ($RulesFileDir -eq $TargetDir) {
            $RulesExcludePath = $RulesFileName
        } else {
            $RulesExcludePath = (Resolve-Path -Relative $rulesFilePath).TrimStart(".\").Replace("\", "/")
        }
        Add-ExcludeEntry -ExcludeFile $GitExcludeFile -Entry $RulesExcludePath
        Write-Host "  OK .shamt/ and $RulesExcludePath added to .git/info/exclude"
    }
}

# --- Copy Guides -------------------------------------------------------------

Write-Separator "Copying guides"

Copy-Item -Path "$ShamtSourceDir\.shamt\guides\*" -Destination "$ShamtDir\guides\" -Recurse -Force
# Exclude master's audit output history — child projects start fresh
$auditOutputs = Join-Path $ShamtDir "guides\audit\outputs"
if (Test-Path $auditOutputs) {
    Remove-Item $auditOutputs -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $auditOutputs | Out-Null
Write-Host "  OK Guides copied (audit/outputs/ cleared for fresh start)"

# --- Copy Scripts ------------------------------------------------------------

Write-Separator "Copying scripts"

Copy-Item -Path "$ShamtSourceDir\.shamt\scripts\*" -Destination "$ShamtDir\scripts\" -Recurse -Force
Write-Host "  OK Scripts copied"

# --- Copy Canonical Content --------------------------------------------------

Write-Separator "Copying canonical content"

foreach ($canonDir in @("skills", "agents", "commands")) {
    $srcPath = Join-Path $ShamtSourceDir ".shamt\$canonDir"
    $dstPath = Join-Path $ShamtDir $canonDir
    if (Test-Path $srcPath) {
        New-Item -ItemType Directory -Force -Path $dstPath | Out-Null
        Copy-Item -Path "$srcPath\*" -Destination $dstPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "  OK Canonical content copied (skills\, agents\, commands\)"

# --- Configure Rules File ----------------------------------------------------

Write-Separator "Configuring rules file"

$RulesDest = Join-Path $RulesFileDir $RulesFileName
$RulesTemplate = Join-Path $ShamtDir "scripts\initialization\RULES_FILE.template.md"
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
    "{{PROJECT_NAME}}"   = $ProjectName
    "{{EPIC_TAG}}"       = $EpicTag
    "{{SHAMT_NAME}}"     = $ShamtName
    "{{GIT_PLATFORM}}"   = $GitPlatform
    "{{DEFAULT_BRANCH}}" = $DefaultBranch
    "SHAMT-{N}"          = "$EpicTag-{N}"
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
Copy-Item (Join-Path $ShamtDir "scripts\initialization\EPIC_TRACKER.template.md") $epicTrackerDest -Force
Apply-Substitutions -FilePath $epicTrackerDest -Replacements $replacements
(Get-Content $epicTrackerDest -Raw) -replace "$EpicTag-1", "$EpicTag-$StartingEpic" | Set-Content $epicTrackerDest -NoNewline

Write-Host "  OK Configuration applied"

# --- Write init_config.md Handoff File ---------------------------------------

Write-Separator "Writing handoff file for agent"

$needsAiDiscovery = ($AiService -eq "other" -or $AiService -eq "amazon_q")
$today = Get-Date -Format "yyyy-MM-dd"
$rulesNote = if ($RulesFileExisted) {
    "- Existing rules file was preserved — agent should incorporate it into the new rules file content."
} else {
    "- Rules file written fresh from template."
}
$aiNote = if ($needsAiDiscovery) {
    "- AI service '$AiService' needs rules file convention confirmed. Agent should research and update ai_services.md."
} else { "" }
$excludeNote = if ($ExcludeShamt) {
    "- .shamt/ and rules file are excluded via .git/info/exclude (local only — not committed or visible to other users)."
} else {
    "- .shamt/ is not excluded from git — it will be tracked and visible to all repo users."
}

$initConfigContent = @"
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
- **Rules File Template:** .shamt\scripts\initialization\RULES_FILE.template.md
- **Needs AI Discovery:** $($needsAiDiscovery.ToString().ToLower())

## Git Configuration
- **Platform:** $GitPlatform
- **Default Branch:** $DefaultBranch

## Script Actions Completed
- [x] Created .shamt\ folder structure (including project-specific-configs\ and unimplemented_design_proposals\)
- [x] Copied guides from master Shamt (audit\outputs\ cleared for fresh start)
- [x] Copied scripts from master Shamt
- [x] Placed rules file at $RulesFileDir\$RulesFileName
- [x] Created EPIC_TRACKER.md at .shamt\epics\EPIC_TRACKER.md
- [x] Written .shamt\shamt_master_path.conf
- [x] Written .shamt\rules_file_path.conf
- [x] Written .shamt\last_sync.conf (initialized from master HEAD)
- [x] Applied configuration substitutions to guides and rules file

## Agent Remaining Tasks

**Before beginning:** Re-read the validation loop protocol at:
`.shamt/guides/reference/validation_loop_master_protocol.md`

Then run a validation loop to complete initialization:

- [ ] Handle AI service discovery (if Needs AI Discovery = true)
- [ ] Analyze codebase structure, languages, frameworks
- [ ] Ask clarifying questions until codebase is fully understood
- [ ] Write ARCHITECTURE.md to `.shamt/project-specific-configs/`
- [ ] Write CODING_STANDARDS.md to `.shamt/project-specific-configs/`
- [ ] Add 3-5 key coding rules to rules file summary section
- [ ] Fill in Project Context section in rules file (tech stack, runtime, test runner, deployment target, critical gotchas)
- [ ] Validate all outputs meet quality bar (primary clean round + sub-agent confirmation)
- [ ] Mark this file complete: change Status to COMPLETE

## Notes
$rulesNote
$aiNote
$excludeNote
- ARCHITECTURE.md and CODING_STANDARDS.md belong in `.shamt/project-specific-configs/`, not the project root.
- Shared guide files in `.shamt/guides/` must remain generic — never write project-specific content into them.
- The only exception: a pointer note in a shared guide directing the agent to check `.shamt/project-specific-configs/` for a supplement.
"@

Set-Content "$ShamtDir\project-specific-configs\init_config.md" $initConfigContent

Write-Host "  OK Handoff file written to .shamt\project-specific-configs\init_config.md"

# --- Optional Features -------------------------------------------------------

Write-Separator "Optional Features"

Write-Host "  Active enforcement (hooks) — enforces commit format, blocks --no-verify,"
Write-Host "  guards pushes, writes session snapshots."
$hooksChoice = Read-Host "  Enable active enforcement (hooks)? [y/N]"
$EnableHooks = ($hooksChoice -match '^[Yy]$')

Write-Host ""
Write-Host "  Shamt MCP server — provides shamt.validation_round(), shamt.audit_run(),"
Write-Host "  and other workflow tools. Requires Python 3."
$mcpChoice = Read-Host "  Enable Shamt MCP server? [y/N]"
$EnableMcp = ($mcpChoice -match '^[Yy]$')

$EnableCiGhValidate  = $false
$EnableCiGhJanitor   = $false
$EnableCiAdoValidate = $false
$EnableCiAdoJanitor  = $false

if ($PrProvider -match "github") {
    Write-Host ""
    Write-Host "  CI automation (GitHub Actions) — automated PR validation and stale-work janitor."
    Write-Host "  Requires OPENAI_API_KEY secret in your repository."
    $ciGhVal = Read-Host "  Enable automated PR validation (GitHub Actions)? [y/N]"
    $EnableCiGhValidate = ($ciGhVal -match '^[Yy]$')
    $ciGhJan = Read-Host "  Enable weekly stale-work janitor (GitHub Actions)? [y/N]"
    $EnableCiGhJanitor = ($ciGhJan -match '^[Yy]$')
}

if ($PrProvider -match "ado") {
    Write-Host ""
    Write-Host "  CI automation (Azure Pipelines) — automated PR validation and stale-work janitor."
    Write-Host "  Requires OPENAI_API_KEY secret in your repository."
    $ciAdoVal = Read-Host "  Enable automated PR validation (Azure Pipelines)? [y/N]"
    $EnableCiAdoValidate = ($ciAdoVal -match '^[Yy]$')
    $ciAdoJan = Read-Host "  Enable weekly stale-work janitor (Azure Pipelines)? [y/N]"
    $EnableCiAdoJanitor = ($ciAdoJan -match '^[Yy]$')
}

$hooksStr = if ($EnableHooks) { "y" } else { "n" }
$mcpStr   = if ($EnableMcp)   { "y" } else { "n" }
Write-Host ""
Write-Host "  OK Optional features: hooks=$hooksStr  mcp=$mcpStr"

# --- Claude Code Host Wiring -------------------------------------------------

if ($AiService -match "claude") {
    Write-Separator "Claude Code host wiring"

    foreach ($d in @("skills", "agents", "commands")) {
        New-Item -ItemType Directory -Force -Path (Join-Path $TargetDir ".claude\$d") | Out-Null
    }
    Write-Host "  OK .claude\ directory structure created"

    # Write starter settings.json BEFORE regen so the hooks flag is readable
    $StarterSettings = Join-Path $ShamtSourceDir ".shamt\host\claude\settings.starter.json"
    $TargetSettings  = Join-Path $TargetDir ".claude\settings.json"
    if (Test-Path $TargetSettings) {
        $existingContent = Get-Content $TargetSettings -Raw
        if ($existingContent -match "_shamt_managed_blocks") {
            Write-Host "  OK .claude\settings.json already has Shamt-managed blocks — skipping"
        } else {
            Write-Host "  WARNING: .claude\settings.json exists but lacks Shamt blocks." -ForegroundColor Yellow
            Write-Host "     Merge the statusLine block from: $StarterSettings" -ForegroundColor Yellow
        }
    } elseif (Test-Path $StarterSettings) {
        $settingsContent = (Get-Content $StarterSettings -Raw) -replace [regex]::Escape('${PROJECT}'), $TargetDir
        [System.IO.File]::WriteAllText($TargetSettings, $settingsContent, [System.Text.Encoding]::UTF8)
        Write-Host "  OK .claude\settings.json written"
    } else {
        Write-Host "  WARNING: settings.starter.json not found — skipping settings.json creation" -ForegroundColor Yellow
    }

    # Apply hooks if enabled
    if ($EnableHooks) {
        $hooksDst = Join-Path $ShamtDir "hooks"
        if (-not (Test-Path $hooksDst)) {
            Copy-Item -Path (Join-Path $ShamtSourceDir ".shamt\hooks") -Destination $hooksDst -Recurse -Force
            Write-Host "  OK Hooks dir copied"
        }
        if (Test-Path $TargetSettings) {
            try {
                $s = Get-Content $TargetSettings -Raw | ConvertFrom-Json
                if (-not ($s.PSObject.Properties.Name -contains 'features')) {
                    $s | Add-Member -MemberType NoteProperty -Name features -Value ([PSCustomObject]@{})
                }
                $s.features | Add-Member -MemberType NoteProperty -Name shamt_hooks -Value $true -Force
                $s | ConvertTo-Json -Depth 20 | Set-Content $TargetSettings -Encoding UTF8
                Write-Host "  OK features.shamt_hooks=true patched into settings.json"
            } catch {
                Write-Host "  WARNING: Failed to patch features.shamt_hooks — edit settings.json manually." -ForegroundColor Yellow
            }
        } else {
            Write-Host "  WARNING: settings.json not found — features.shamt_hooks flag not set." -ForegroundColor Yellow
            Write-Host "     Run regen-claude-shims.ps1 manually after creating settings.json." -ForegroundColor Yellow
        }
    }

    # Apply MCP if enabled
    if ($EnableMcp) {
        Invoke-SetupMcp
    }

    # Run regen LAST — reads settings.json with hooks flag already set
    $RegenScript = Join-Path $ShamtDir "scripts\regen\regen-claude-shims.ps1"
    if (Test-Path $RegenScript) {
        & powershell -ExecutionPolicy Bypass -File $RegenScript
        Write-Host "  OK Claude Code shims generated"
    } else {
        Write-Host "  WARNING: regen-claude-shims.ps1 not found — run it manually after init" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  NOTE: Ensure this project is trusted in Claude Code." -ForegroundColor Cyan
    Write-Host "     Open Claude Code in $TargetDir — it will prompt for trust on first open." -ForegroundColor Cyan
}

# For dual-host (claude_codex): duplicate AGENTS.md as CLAUDE.md (symlinks not reliable on Windows)
if ($AiService -eq "claude_codex") {
    $agentsFile = Join-Path $TargetDir "AGENTS.md"
    $claudeFile = Join-Path $TargetDir "CLAUDE.md"
    if ((Test-Path $agentsFile) -and -not (Test-Path $claudeFile)) {
        Copy-Item $agentsFile $claudeFile
        Write-Host "  OK CLAUDE.md written as duplicate of AGENTS.md (dual-host; keep in sync)"
    }
}

# --- Codex Host Wiring -------------------------------------------------------

if ($AiService -match "codex") {
    Write-Separator "Codex host wiring"

    New-Item -ItemType Directory -Force -Path (Join-Path $TargetDir ".codex\agents") | Out-Null
    Write-Host "  OK .codex\ directory structure created"

    # Write model resolution file
    $ModelResolution = Join-Path $ShamtDir "host\codex\.model_resolution.local.toml"
    New-Item -ItemType Directory -Force -Path (Split-Path $ModelResolution) | Out-Null
    $modelContent = "FRONTIER_MODEL = `"$CodexFrontierModel`"`nDEFAULT_MODEL = `"$CodexDefaultModel`""
    [System.IO.File]::WriteAllText($ModelResolution, $modelContent, [System.Text.Encoding]::UTF8)
    Write-Host "  OK .model_resolution.local.toml written ($CodexFrontierModel / $CodexDefaultModel)"

    # Write starter config.toml
    $StarterConfig = Join-Path $ShamtSourceDir ".shamt\host\codex\config.starter.toml"
    $TargetConfig  = Join-Path $TargetDir ".codex\config.toml"
    if (Test-Path $TargetConfig) {
        Write-Host "  OK .codex\config.toml already exists — skipping"
    } elseif (Test-Path $StarterConfig) {
        Copy-Item $StarterConfig $TargetConfig
        Write-Host "  OK .codex\config.toml written from starter"
    } else {
        Write-Host "  WARNING: config.starter.toml not found — skipping" -ForegroundColor Yellow
    }

    # Copy requirements.toml.template to project root
    $RequirementsTpl    = Join-Path $ShamtSourceDir ".shamt\host\codex\requirements.toml.template"
    $TargetRequirements = Join-Path $TargetDir "requirements.toml"
    if (Test-Path $TargetRequirements) {
        Write-Host "  OK requirements.toml already exists — skipping"
    } elseif (Test-Path $RequirementsTpl) {
        Copy-Item $RequirementsTpl $TargetRequirements
        Write-Host "  OK requirements.toml written"
    } else {
        Write-Host "  WARNING: requirements.toml.template not found — skipping" -ForegroundColor Yellow
    }

    # Apply hooks if enabled (guard against double-copy in dual-host)
    if ($EnableHooks -and -not (Test-Path (Join-Path $ShamtDir "hooks"))) {
        Copy-Item -Path (Join-Path $ShamtSourceDir ".shamt\hooks") -Destination (Join-Path $ShamtDir "hooks") -Recurse -Force
        Write-Host "  OK Hooks dir copied"
    }

    # Apply MCP if enabled (guard against double-install in dual-host)
    if ($EnableMcp -and -not (Test-Path (Join-Path $ShamtDir "mcp\.venv"))) {
        Invoke-SetupMcp
    }

    # Run regen script
    $RegenScript = Join-Path $ShamtDir "scripts\regen\regen-codex-shims.ps1"
    if (Test-Path $RegenScript) {
        & powershell -ExecutionPolicy Bypass -File $RegenScript
        Write-Host "  OK Codex shims generated"
    } else {
        Write-Host "  WARNING: regen-codex-shims.ps1 not found — run it manually after init" -ForegroundColor Yellow
    }
}

# --- CI Automation -----------------------------------------------------------

if ($EnableCiGhValidate -or $EnableCiGhJanitor -or $EnableCiAdoValidate -or $EnableCiAdoJanitor) {
    Write-Separator "CI Automation"

    $SdkDir = Join-Path $ShamtSourceDir ".shamt\sdk"

    if ($EnableCiGhValidate) {
        $wfDir = Join-Path $TargetDir ".github\workflows"
        New-Item -ItemType Directory -Force -Path $wfDir | Out-Null
        $src = Join-Path $SdkDir ".github\workflows\shamt-validate.yml.template"
        if (Test-Path $src) {
            Copy-Item $src (Join-Path $wfDir "shamt-validate.yml")
            Write-Host "  OK .github/workflows/shamt-validate.yml written"
        } else {
            Write-Host "  WARNING: $src not found — skipping" -ForegroundColor Yellow
        }
    }

    if ($EnableCiGhJanitor) {
        $wfDir = Join-Path $TargetDir ".github\workflows"
        New-Item -ItemType Directory -Force -Path $wfDir | Out-Null
        $src = Join-Path $SdkDir ".github\workflows\shamt-cron-janitor.yml.template"
        if (Test-Path $src) {
            Copy-Item $src (Join-Path $wfDir "shamt-cron-janitor.yml")
            Write-Host "  OK .github/workflows/shamt-cron-janitor.yml written"
        } else {
            Write-Host "  WARNING: $src not found — skipping" -ForegroundColor Yellow
        }
    }

    if ($EnableCiAdoValidate) {
        $apDir = Join-Path $TargetDir "azure-pipelines"
        New-Item -ItemType Directory -Force -Path $apDir | Out-Null
        $src = Join-Path $SdkDir "azure-pipelines\shamt-validate.yml.template"
        if (Test-Path $src) {
            Copy-Item $src (Join-Path $apDir "shamt-validate.yml")
            Write-Host "  OK azure-pipelines/shamt-validate.yml written"
        } else {
            Write-Host "  WARNING: $src not found — skipping" -ForegroundColor Yellow
        }
    }

    if ($EnableCiAdoJanitor) {
        $apDir = Join-Path $TargetDir "azure-pipelines"
        New-Item -ItemType Directory -Force -Path $apDir | Out-Null
        $src = Join-Path $SdkDir "azure-pipelines\shamt-cron-janitor.yml.template"
        if (Test-Path $src) {
            Copy-Item $src (Join-Path $apDir "shamt-cron-janitor.yml")
            Write-Host "  OK azure-pipelines/shamt-cron-janitor.yml written"
        } else {
            Write-Host "  WARNING: $src not found — skipping" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "  WARNING: CI automation: add OPENAI_API_KEY secret to your repository before workflows run." -ForegroundColor Yellow
}

# --- Cloud environment setup (--with-cloud, Codex hosts only) -----------------

if ($WithCloud) {
    if ($AiService -notmatch "codex") {
        Write-Host "  WARNING: --with-cloud is only applicable to Codex hosts. Skipping." -ForegroundColor Yellow
        $WithCloud = $false
    }
}

if ($WithCloud) {
    Write-Host ""
    Write-Host "  Setting up Codex Cloud environment..."
    Write-Host ""

    $CloudTemplate  = Join-Path $ShamtSourceDir ".shamt\host\codex\cloud-environment.template.json"
    $TargetCloud    = Join-Path $TargetDir "codex-environment.json"
    if (Test-Path $TargetCloud) {
        Write-Host "  OK codex-environment.json already exists — skipping"
    } elseif (Test-Path $CloudTemplate) {
        Copy-Item $CloudTemplate $TargetCloud
        Write-Host "  OK codex-environment.json written from template"
    } else {
        Write-Host "  WARNING: cloud-environment.template.json not found — skipping" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  NOTE: Cloud setup notes:" -ForegroundColor Cyan
    Write-Host "     1. Verify the manifest filename for your Codex Cloud version." -ForegroundColor Cyan
    Write-Host "        See .shamt\host\codex\cloud-README.md for details." -ForegroundColor Cyan
    Write-Host "     2. Set EPIC_BRANCH in the manifest before launching a cloud task." -ForegroundColor Cyan
    Write-Host "     3. Register your project in Codex Cloud and link the manifest." -ForegroundColor Cyan
}

# --- Done --------------------------------------------------------------------

Write-Separator "Done!"
Write-Host ""
Write-Host "  Shamt has been initialized in: $TargetDir"
Write-Host ""
Write-Host "  Next step: open your project in $ShamtName (your AI assistant) and say:"
Write-Host ""
Write-Host "    `"Read .shamt/project-specific-configs/init_config.md and complete the Shamt initialization.`""
Write-Host ""
Write-Host "  The agent will analyze your codebase and finish setup."
Write-Host ""
Write-Host "  To sync with master later:"
Write-Host "    Import updates from master: bash .shamt/scripts/import/import.sh (or import.ps1)"
Write-Host "    Export changes to master:   bash .shamt/scripts/export/export.sh (or export.ps1)"
Write-Host ""
Write-Host "============================================================"
Write-Host ""
