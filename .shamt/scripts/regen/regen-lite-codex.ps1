# =============================================================================
# regen-lite-codex.ps1 — Shamt Lite Codex shim generator (Windows)
# =============================================================================
# Deploys Shamt Lite canonical content into a child project's Codex tree:
#   Skills   → <TARGET>\.agents\skills\<name>\SKILL.md   (filter: shamt-lite-*)
#   Agents   → <TARGET>\.codex\agents\<name>.toml        (YAML → TOML)
#   Profiles → <TARGET>\.codex\config.toml SHAMT-LITE-PROFILES block
#
# Usage (from the child project root):
#   powershell -ExecutionPolicy Bypass -File C:\path\to\shamt-ai-dev\.shamt\scripts\regen\regen-lite-codex.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ShamtSourceDir = (Get-Item "$ScriptDir\..\..\..").FullName
$ShamtDir = Join-Path $ShamtSourceDir ".shamt"
$TargetDir = (Get-Location).Path
$CodexDir = Join-Path $TargetDir ".codex"
$AgentsSkillsDir = Join-Path $TargetDir ".agents\skills"

$LiteAgentsSrc   = Join-Path $ShamtDir "scripts\initialization\lite\agents"
$LiteProfilesSrc = Join-Path $ShamtDir "scripts\initialization\lite\profiles-codex"
$SkillsSrc       = Join-Path $ShamtDir "skills"

$ManagedHeader   = "# Managed by Shamt — do not edit. Run regen-lite-codex.ps1 to regenerate."
$ManagedHeaderMd = "<!-- Managed by Shamt — do not edit. Run regen-lite-codex.ps1 to regenerate. -->"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Shamt Lite Regen — Codex Shims"
Write-Host "============================================================"
Write-Host "  Source: $ShamtSourceDir"
Write-Host "  Target: $TargetDir"
Write-Host "============================================================"
Write-Host ""

# --- Read model resolution ---------------------------------------------------

$ModelResolution = Join-Path $TargetDir ".shamt\host\codex\.model_resolution.local.toml"
if (-not (Test-Path $ModelResolution)) {
    $ModelResolution = Join-Path $TargetDir "shamt-lite\host\codex\.model_resolution.local.toml"
}

$FrontierModel = "o3"
$DefaultModel  = "o4-mini"
if (Test-Path $ModelResolution) {
    foreach ($line in Get-Content $ModelResolution) {
        if ($line -match '^FRONTIER_MODEL\s*=\s*"([^"]+)"') { $FrontierModel = $matches[1] }
        if ($line -match '^DEFAULT_MODEL\s*=\s*"([^"]+)"')  { $DefaultModel  = $matches[1] }
    }
}

Write-Host "  Models: FRONTIER=$FrontierModel  DEFAULT=$DefaultModel"
Write-Host ""

function Is-ShamtManagedTop {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $false }
    $first = Get-Content $FilePath -TotalCount 3 -ErrorAction SilentlyContinue
    return ($first -match "Managed by Shamt").Count -gt 0
}

# --- Phase 1: Skills (filter shamt-lite-*) → .agents/skills/ ----------------

$SkillsWritten = 0; $SkillsPreserved = 0

if (Test-Path $SkillsSrc) {
    New-Item -ItemType Directory -Force -Path $AgentsSkillsDir | Out-Null
    Get-ChildItem -Path $SkillsSrc -Directory | Where-Object { $_.Name -like "shamt-lite-*" } | Sort-Object Name | ForEach-Object {
        $skillName = $_.Name
        $skillSrc  = Join-Path $_.FullName "SKILL.md"
        $skillDst  = Join-Path $AgentsSkillsDir "$skillName\SKILL.md"

        if (-not (Test-Path $skillSrc)) { return }

        if ((Test-Path $skillDst) -and -not (Is-ShamtManagedTop $skillDst)) {
            $SkillsPreserved++; return
        }

        New-Item -ItemType Directory -Force -Path (Split-Path $skillDst) | Out-Null
        # Substitute {cheap-tier} ONLY inside <parameter name="model">...</parameter> XML
        # tags so deployed XML examples carry the project's DEFAULT_MODEL. The
        # explanatory footnote (which references `{cheap-tier}` as inline code) is
        # preserved.
        $xmlPattern = '<parameter name="model">\{cheap-tier\}</parameter>'
        $xmlReplacement = "<parameter name=`"model`">$DefaultModel</parameter>"
        $skillBody = (Get-Content $skillSrc -Raw) -replace $xmlPattern, $xmlReplacement
        $content = $ManagedHeaderMd + "`n" + $skillBody
        $content = $content -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($skillDst, $content, [System.Text.Encoding]::UTF8)
        $SkillsWritten++
    }
    Write-Host "  Skills: $SkillsWritten written to .agents\skills\, $SkillsPreserved preserved (user-authored)"
} else {
    Write-Host "  Skills: $SkillsSrc not found — skipping"
}

# --- Phase 2: Agents (YAML → TOML) → .codex/agents/ -------------------------

$AgentsWritten = 0

function Convert-YamlAgentToToml {
    param([string]$YamlPath, [string]$OutPath, [string]$Frontier, [string]$Default)

    $lines = Get-Content $YamlPath
    $name = ""; $modelTier = ""; $reasoningEffort = ""; $sandbox = ""
    $tools = @(); $templateLines = @()
    $inTools = $false; $inTemplate = $false

    foreach ($line in $lines) {
        if ($line -match "^name:\s*(.+)$")              { $name = $matches[1].Trim(); $inTools=$false; $inTemplate=$false }
        elseif ($line -match "^model_tier:\s*(.+)$")    { $modelTier = $matches[1].Trim(); $inTools=$false; $inTemplate=$false }
        elseif ($line -match "^reasoning_effort:\s*(.+)$") { $reasoningEffort = $matches[1].Trim(); $inTools=$false; $inTemplate=$false }
        elseif ($line -match "^sandbox:\s*(.+)$")       { $sandbox = $matches[1].Trim(); $inTools=$false; $inTemplate=$false }
        elseif ($line -match "^tools_allowed:$")        { $inTools = $true; $inTemplate = $false }
        elseif ($line -match "^prompt_template:\s*\|$") { $inTools = $false; $inTemplate = $true }
        elseif ($inTools -and $line -match "^  - (\S+)$") { $tools += $matches[1] }
        elseif ($inTools -and $line -notmatch "^  ")    { $inTools = $false }
        elseif ($inTemplate) {
            if ($line.Length -ge 2 -and $line.Substring(0, 2) -eq "  ") {
                $templateLines += $line.Substring(2)
            } elseif ($line -eq "") {
                $templateLines += ""
            } elseif ($line -notmatch "^\s") {
                $inTemplate = $false
            } else {
                $templateLines += $line
            }
        }
    }

    $tierMap = @{ "cheap" = $Default; "balanced" = $Frontier; "reasoning" = $Frontier }
    $model = if ($tierMap.ContainsKey($modelTier)) { $tierMap[$modelTier] } else { $modelTier }
    $template = ($templateLines -join "`n").TrimEnd()

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine($ManagedHeader)
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("[$name]")
    [void]$sb.AppendLine("model = `"$model`"")
    if ($reasoningEffort) { [void]$sb.AppendLine("model_reasoning_effort = `"$reasoningEffort`"") }
    if ($sandbox)         { [void]$sb.AppendLine("sandbox_mode = `"$sandbox`"") }
    if ($tools.Count -gt 0) {
        $toolList = ($tools | ForEach-Object { "`"$_`"" }) -join ", "
        [void]$sb.AppendLine("tools_allowed = [$toolList]")
    }
    if ($template) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("prompt = `"`"`"")
        [void]$sb.AppendLine($template)
        [void]$sb.AppendLine("`"`"`"")
    }

    $content = $sb.ToString() -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($OutPath, $content, [System.Text.Encoding]::UTF8)
}

if (Test-Path $LiteAgentsSrc) {
    New-Item -ItemType Directory -Force -Path (Join-Path $CodexDir "agents") | Out-Null
    Get-ChildItem -Path $LiteAgentsSrc -Filter "*.yaml" | Sort-Object Name | ForEach-Object {
        $agentName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $agentDst  = Join-Path (Join-Path $CodexDir "agents") "$agentName.toml"
        Convert-YamlAgentToToml -YamlPath $_.FullName -OutPath $agentDst -Frontier $FrontierModel -Default $DefaultModel
        $AgentsWritten++
    }
    Write-Host "  Agents: $AgentsWritten written to .codex\agents\"
} else {
    Write-Host "  Agents: $LiteAgentsSrc not found — skipping"
}

# --- Phase 3: Profiles → .codex/config.toml SHAMT-LITE-PROFILES block --------

$ConfigToml = Join-Path $CodexDir "config.toml"

if (Test-Path $LiteProfilesSrc) {
    New-Item -ItemType Directory -Force -Path $CodexDir | Out-Null

    $profilesContent = ""
    Get-ChildItem -Path $LiteProfilesSrc -Filter "*.fragment.toml" | Sort-Object Name | ForEach-Object {
        $frag = Get-Content $_.FullName -Raw
        $frag = $frag -replace '\$\{FRONTIER_MODEL\}', $FrontierModel
        $frag = $frag -replace '\$\{DEFAULT_MODEL\}', $DefaultModel
        if ($profilesContent -ne "") { $profilesContent += "`n`n" }
        $profilesContent += $frag.TrimEnd()
    }

    $startMarker = "# ============================================================`n# SHAMT-LITE-PROFILES-START — managed by regen-lite-codex.ps1; do not edit manually`n# ============================================================"
    $endMarker   = "# ============================================================`n# SHAMT-LITE-PROFILES-END`n# ============================================================"

    if (-not (Test-Path $ConfigToml)) {
        $newContent = "$ManagedHeader`n# Codex configuration for Shamt Lite`n`n$startMarker`n`n$profilesContent`n`n$endMarker`n"
        $newContent = $newContent -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($ConfigToml, $newContent, [System.Text.Encoding]::UTF8)
        Write-Host "  Profiles: created $ConfigToml with SHAMT-LITE-PROFILES block"
    } else {
        $config = Get-Content $ConfigToml -Raw
        $blockPattern = '(?s)# ={13,}\s*\n# SHAMT-LITE-PROFILES-START.*?\n# ={13,}.*?# ={13,}\s*\n# SHAMT-LITE-PROFILES-END\s*\n# ={13,}'
        $newBlock = "$startMarker`n`n$profilesContent`n`n$endMarker"

        if ($config -match $blockPattern) {
            $config = [regex]::Replace($config, $blockPattern, [System.Text.RegularExpressions.Regex]::Escape($newBlock).Replace('\','\\') -replace '\\\$','$$')
            # Simpler: just use a placeholder-free replacement
            $config = [regex]::Replace((Get-Content $ConfigToml -Raw), $blockPattern, { param($m) $newBlock })
        } else {
            if (-not $config.EndsWith("`n")) { $config += "`n" }
            $config += "`n$newBlock`n"
        }

        $config = $config -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($ConfigToml, $config, [System.Text.Encoding]::UTF8)
        Write-Host "  Profiles: SHAMT-LITE-PROFILES block updated in $ConfigToml"
    }
} else {
    Write-Host "  Profiles: $LiteProfilesSrc not found — skipping"
}

# --- Phase 4: Generate CHEATSHEET.md -----------------------------------------

$_confPath = Join-Path $TargetDir "shamt-lite\config\ai_service.conf"
if (-not (Test-Path $_confPath)) {
    Write-Host "  Cheat sheet: skipped (shamt-lite/config/ai_service.conf not found — run init_lite.ps1 first)"
} else {
    $aiSvc  = (Get-Content $_confPath -Raw).Trim()
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
    $csPath = Join-Path $TargetDir "shamt-lite\CHEATSHEET.md"
    [System.IO.File]::WriteAllText($csPath, $csContent, [System.Text.Encoding]::UTF8)
    Write-Host "  Cheat sheet: written to shamt-lite/CHEATSHEET.md (service: $aiSvc)"
}

Write-Host ""
Write-Host "  ✓ Lite regen complete"
Write-Host ""
