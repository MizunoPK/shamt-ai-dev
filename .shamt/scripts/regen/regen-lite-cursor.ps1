# =============================================================================
# regen-lite-cursor.ps1 — Shamt Lite Cursor shim generator (Windows)
# =============================================================================
# Deploys Shamt Lite canonical content into a child project's .cursor/ tree:
#   Skills   → <TARGET>\.cursor\skills\<name>\SKILL.md   (filter: shamt-lite-*)
#   Commands → <TARGET>\.cursor\commands\<name>.md
#   Rules    → <TARGET>\.cursor\rules\lite-*.mdc
#   Agents   → <TARGET>\.cursor\agents\<name>.md         (YAML → Cursor md)
#
# Usage (from the child project root):
#   powershell -ExecutionPolicy Bypass -File C:\path\to\shamt-ai-dev\.shamt\scripts\regen\regen-lite-cursor.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ShamtSourceDir = (Get-Item "$ScriptDir\..\..\..").FullName
$ShamtDir = Join-Path $ShamtSourceDir ".shamt"
$TargetDir = (Get-Location).Path
$CursorDir = Join-Path $TargetDir ".cursor"

$LiteCmdsSrc   = Join-Path $ShamtDir "scripts\initialization\lite\commands"
$LiteAgentsSrc = Join-Path $ShamtDir "scripts\initialization\lite\agents"
$LiteRulesSrc  = Join-Path $ShamtDir "scripts\initialization\lite\rules-cursor"
$SkillsSrc     = Join-Path $ShamtDir "skills"

$ManagedHeader   = "<!-- Managed by Shamt — do not edit. Run regen-lite-cursor.ps1 to regenerate. -->"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Shamt Lite Regen — Cursor Shims"
Write-Host "============================================================"
Write-Host "  Source: $ShamtSourceDir"
Write-Host "  Target: $TargetDir"
Write-Host "============================================================"
Write-Host ""

# --- Read model resolution ---------------------------------------------------
# Primary: .shamt\host\cursor\ (full-Shamt projects or explicit placement)
# Fallback: shamt-lite\host\cursor\ (Lite-only projects)

$CheapModel = "inherit"
$ModelResolutionPrimary = Join-Path $TargetDir ".shamt\host\cursor\.model_resolution.local.toml"
$ModelResolutionFallback = Join-Path $TargetDir "shamt-lite\host\cursor\.model_resolution.local.toml"

foreach ($mrf in @($ModelResolutionPrimary, $ModelResolutionFallback)) {
    if (Test-Path $mrf) {
        foreach ($line in Get-Content $mrf) {
            if ($line -match '^CHEAP_MODEL\s*=\s*"([^"]+)"') { $CheapModel = $matches[1] }
        }
        break
    }
}

Write-Host "  Cursor cheap-tier model: $CheapModel"
Write-Host ""

function Is-ShamtManagedTop {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $false }
    $first = Get-Content $FilePath -TotalCount 3 -ErrorAction SilentlyContinue
    return ($first -match "Managed by Shamt").Count -gt 0
}

function Is-ShamtManaged {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $false }
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    return ($content -match "Managed by Shamt")
}

function Get-CursorPaths {
    param([string]$SkillName)
    switch ($SkillName) {
        "shamt-lite-spec"   { return "stories/**/spec.md, **/ticket*.md" }
        "shamt-lite-plan"   { return "stories/**/implementation_plan.md" }
        "shamt-lite-review" { return "stories/**/code_review/**" }
        default             { return "" }
    }
}

# --- Phase 1: Skills (filter shamt-lite-*) → .cursor/skills/ ----------------

$SkillsDst = Join-Path $CursorDir "skills"
$SkillsWritten = 0; $SkillsPreserved = 0

if (Test-Path $SkillsSrc) {
    New-Item -ItemType Directory -Force -Path $SkillsDst | Out-Null
    Get-ChildItem -Path $SkillsSrc -Directory | Where-Object { $_.Name -like "shamt-lite-*" } | Sort-Object Name | ForEach-Object {
        $skillName = $_.Name
        $skillSrc  = Join-Path $_.FullName "SKILL.md"
        $skillDst  = Join-Path $SkillsDst "$skillName\SKILL.md"

        if (-not (Test-Path $skillSrc)) { return }

        if ((Test-Path $skillDst) -and -not (Is-ShamtManaged $skillDst)) {
            $SkillsPreserved++; return
        }

        New-Item -ItemType Directory -Force -Path (Split-Path $skillDst) | Out-Null

        # Substitute {cheap-tier} ONLY inside <parameter name="model">...</parameter> XML
        # tags so deployed XML examples carry the project's CHEAP_MODEL.
        $xmlPattern = '<parameter name="model">\{cheap-tier\}</parameter>'
        $xmlReplacement = "<parameter name=`"model`">$CheapModel</parameter>"
        $skillBody = (Get-Content $skillSrc -Raw) -replace $xmlPattern, $xmlReplacement

        # Inject paths: into YAML frontmatter (after the first --- line) if needed
        $cursorPaths = Get-CursorPaths $skillName
        if ($cursorPaths -ne "") {
            $lines = $skillBody -split "`n"
            $injected = $false
            $newLines = [System.Collections.Generic.List[string]]::new()
            foreach ($line in $lines) {
                $newLines.Add($line)
                if (-not $injected -and $line.Trim() -eq "---") {
                    $newLines.Add("paths: $cursorPaths")
                    $injected = $true
                }
            }
            $skillBody = $newLines -join "`n"
        }

        $content = $skillBody + "`n" + $ManagedHeader + "`n"
        $content = $content -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($skillDst, $content, [System.Text.Encoding]::UTF8)
        $SkillsWritten++
    }
    Write-Host "  Skills: $SkillsWritten written to .cursor\skills\, $SkillsPreserved preserved (user-authored)"
} else {
    Write-Host "  Skills: $SkillsSrc not found — skipping"
}

# --- Phase 2: Commands → .cursor/commands/ -----------------------------------

$CmdsDst = Join-Path $CursorDir "commands"
$CmdsWritten = 0; $CmdsPreserved = 0

if (Test-Path $LiteCmdsSrc) {
    New-Item -ItemType Directory -Force -Path $CmdsDst | Out-Null
    Get-ChildItem -Path $LiteCmdsSrc -Filter "*.md" | Sort-Object Name | ForEach-Object {
        $cmdName = $_.Name
        $cmdDst  = Join-Path $CmdsDst $cmdName

        if ((Test-Path $cmdDst) -and -not (Is-ShamtManaged $cmdDst)) {
            $CmdsPreserved++; return
        }

        $content = (Get-Content $_.FullName -Raw) + "`n" + $ManagedHeader + "`n"
        $content = $content -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($cmdDst, $content, [System.Text.Encoding]::UTF8)
        $CmdsWritten++
    }
    Write-Host "  Commands: $CmdsWritten written, $CmdsPreserved preserved (user-authored)"
} else {
    Write-Host "  Commands: $LiteCmdsSrc not found — skipping"
}

# --- Phase 3: Rules (.mdc files) → .cursor/rules/ ---------------------------

$RulesDst = Join-Path $CursorDir "rules"
$RulesWritten = 0; $RulesPreserved = 0

if (Test-Path $LiteRulesSrc) {
    New-Item -ItemType Directory -Force -Path $RulesDst | Out-Null
    Get-ChildItem -Path $LiteRulesSrc -Filter "*.mdc" | Sort-Object Name | ForEach-Object {
        $mdcName = $_.Name
        $mdcDst  = Join-Path $RulesDst $mdcName

        if ((Test-Path $mdcDst) -and -not (Is-ShamtManaged $mdcDst)) {
            $RulesPreserved++; return
        }

        $content = (Get-Content $_.FullName -Raw) + "`n" + $ManagedHeader + "`n"
        $content = $content -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($mdcDst, $content, [System.Text.Encoding]::UTF8)
        $RulesWritten++
    }
    Write-Host "  Rules: $RulesWritten written, $RulesPreserved preserved (user-authored)"
} else {
    Write-Host "  Rules: $LiteRulesSrc not found — skipping"
}

# --- Phase 4: Agents (YAML → Cursor agent md) --------------------------------

$AgentsDst = Join-Path $CursorDir "agents"
$AgentsWritten = 0; $AgentsPreserved = 0

function Convert-YamlAgentToCursorMd {
    param([string]$YamlPath, [string]$OutPath, [string]$Cheap)

    $lines = Get-Content $YamlPath
    $name = ""; $modelTier = ""; $tools = @(); $templateLines = @()
    $descLines = @()
    $inTools = $false; $inTemplate = $false; $inDescBlock = $false

    foreach ($line in $lines) {
        if ($line -match "^name:\s*(.+)$") {
            $name = $matches[1].Trim(); $inTools = $false; $inTemplate = $false; $inDescBlock = $false
        }
        elseif ($line -match "^description:\s*\|$") {
            $inDescBlock = $true; $inTools = $false; $inTemplate = $false
        }
        elseif ($line -match "^description:\s*(.+)$") {
            $description = $matches[1].Trim(); $inTools = $false; $inTemplate = $false; $inDescBlock = $false
        }
        elseif ($line -match "^model_tier:\s*(.+)$") {
            $modelTier = $matches[1].Trim(); $inTools = $false; $inTemplate = $false; $inDescBlock = $false
        }
        elseif ($line -match "^tools_allowed:$") {
            $inTools = $true; $inTemplate = $false; $inDescBlock = $false
        }
        elseif ($line -match "^prompt_template:\s*\|$") {
            $inTools = $false; $inTemplate = $true; $inDescBlock = $false
        }
        elseif ($inDescBlock -and $line -match "^  (.+)$") {
            $descLines += $matches[1]
        }
        elseif ($inDescBlock -and $line -notmatch "^\s") {
            $inDescBlock = $false
            $description = ($descLines -join " ").Trim()
        }
        elseif ($inTools -and $line -match "^  - (\S+)$") {
            $tools += $matches[1]
        }
        elseif ($inTools -and $line -notmatch "^  ") {
            $inTools = $false
        }
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
    if ($inDescBlock -and $descLines.Count -gt 0 -and $description -eq "") {
        $description = ($descLines -join " ").Trim()
    }

    # cheap → CHEAP_MODEL; balanced/reasoning → inherit
    $tierMap = @{ "cheap" = $Cheap; "balanced" = "inherit"; "reasoning" = "inherit" }
    $model = if ($tierMap.ContainsKey($modelTier)) { $tierMap[$modelTier] } else { "inherit" }
    $template = ($templateLines -join "`n").TrimEnd()

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("name: $name")
    [void]$sb.AppendLine("description: $description")
    [void]$sb.AppendLine("model: $model")
    if ($tools.Count -gt 0) {
        [void]$sb.AppendLine("tools:")
        foreach ($t in $tools) { [void]$sb.AppendLine("  - $t") }
    }
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine($template)
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine($ManagedHeader)

    $content = $sb.ToString() -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($OutPath, $content, [System.Text.Encoding]::UTF8)
}

if (Test-Path $LiteAgentsSrc) {
    New-Item -ItemType Directory -Force -Path $AgentsDst | Out-Null
    Get-ChildItem -Path $LiteAgentsSrc -Filter "*.yaml" | Sort-Object Name | ForEach-Object {
        $agentName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $agentDst  = Join-Path $AgentsDst "$agentName.md"

        if ((Test-Path $agentDst) -and -not (Is-ShamtManaged $agentDst)) {
            $AgentsPreserved++; return
        }

        Convert-YamlAgentToCursorMd -YamlPath $_.FullName -OutPath $agentDst -Cheap $CheapModel
        $AgentsWritten++
    }
    Write-Host "  Agents: $AgentsWritten written, $AgentsPreserved preserved (user-authored)"
} else {
    Write-Host "  Agents: $LiteAgentsSrc not found — skipping"
}

Write-Host ""
Write-Host "  ✓ Lite regen complete"
Write-Host ""
