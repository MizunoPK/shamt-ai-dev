# =============================================================================
# regen-claude-shims.ps1 — Shamt Claude Code shim generator (Windows/PowerShell)
# =============================================================================
# Transforms canonical Shamt content in .shamt/{skills,agents,commands}/ into
# Claude Code-shaped equivalents under .claude/{skills,agents,commands}/.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .shamt\scripts\regen\regen-claude-shims.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Get-Item "$ScriptDir\..\..\..").FullName
$ShamtDir = Join-Path $ProjectRoot ".shamt"
$ClaudeDir = Join-Path $ProjectRoot ".claude"

$ManagedHeader = "<!-- Managed by Shamt — do not edit. Run regen-claude-shims.ps1 to regenerate. -->"

# --- Determine repo type ------------------------------------------------------

$RepoTypeConf = Join-Path $ShamtDir "config\repo_type.conf"
$RepoType = "child"
if (Test-Path $RepoTypeConf) {
    $RepoType = (Get-Content $RepoTypeConf -Raw).Trim()
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  Shamt Regen — Claude Code Shims"
Write-Host "============================================================"
Write-Host "  Project: $ProjectRoot"
Write-Host "  Repo type: $RepoType"
Write-Host "============================================================"
Write-Host ""

# --- Helpers ------------------------------------------------------------------

function Is-ShamtManaged {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $false }
    $firstLine = (Get-Content $FilePath -TotalCount 1 -ErrorAction SilentlyContinue)
    return $firstLine -match "Managed by Shamt"
}

function Is-MasterOnly {
    param([string]$SkillFile)
    # Read frontmatter (between first and second ---) and check for master-only: true
    $lines = Get-Content $SkillFile
    $inFrontmatter = $false
    $dashCount = 0
    foreach ($line in $lines) {
        if ($line -eq "---") {
            $dashCount++
            if ($dashCount -eq 1) { $inFrontmatter = $true; continue }
            if ($dashCount -eq 2) { break }
        }
        if ($inFrontmatter -and $line -match "^master-only:\s*true") {
            return $true
        }
    }
    return $false
}

function Get-ModelId {
    param([string]$Tier)
    $map = @{
        "cheap"     = "claude-haiku-4-5-20251001"
        "balanced"  = "claude-sonnet-4-6"
        "reasoning" = "claude-opus-4-7"
    }
    if ($map.ContainsKey($Tier)) { return $map[$Tier] }
    return $Tier
}

# --- Phase 1: Skills ----------------------------------------------------------

$SkillsSrc = Join-Path $ShamtDir "skills"
$SkillsDst = Join-Path $ClaudeDir "skills"
$SkillsWritten = 0; $SkillsSkipped = 0; $SkillsPreserved = 0

if (Test-Path $SkillsSrc) {
    New-Item -ItemType Directory -Force -Path $SkillsDst | Out-Null
    Get-ChildItem -Path $SkillsSrc -Directory | Sort-Object Name | ForEach-Object {
        $skillName = $_.Name
        $skillSrc  = Join-Path $_.FullName "SKILL.md"
        $skillDst  = Join-Path $SkillsDst "$skillName\SKILL.md"

        if (-not (Test-Path $skillSrc)) { return }

        if ($RepoType -eq "child" -and (Is-MasterOnly $skillSrc)) {
            $SkillsSkipped++; return
        }
        if ((Test-Path $skillDst) -and -not (Is-ShamtManaged $skillDst)) {
            $SkillsPreserved++; return
        }

        New-Item -ItemType Directory -Force -Path (Split-Path $skillDst) | Out-Null
        $content = $ManagedHeader + "`n" + (Get-Content $skillSrc -Raw)
        # Normalize to LF
        $content = $content -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($skillDst, $content, [System.Text.Encoding]::UTF8)
        $SkillsWritten++
    }
    Write-Host "  Skills: $SkillsWritten written, $SkillsSkipped skipped (master-only on child), $SkillsPreserved preserved (user-authored)"
} else {
    Write-Host "  Skills: .shamt\skills\ not found — skipping"
}

# --- Phase 2: Agents ----------------------------------------------------------

$AgentsSrc = Join-Path $ShamtDir "agents"
$AgentsDst = Join-Path $ClaudeDir "agents"
$AgentsWritten = 0; $AgentsPreserved = 0

if (Test-Path $AgentsSrc) {
    New-Item -ItemType Directory -Force -Path $AgentsDst | Out-Null
    Get-ChildItem -Path $AgentsSrc -Filter "*.yaml" | Sort-Object Name | ForEach-Object {
        $agentName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $agentDst  = Join-Path $AgentsDst "$agentName.md"

        if ((Test-Path $agentDst) -and -not (Is-ShamtManaged $agentDst)) {
            $AgentsPreserved++; return
        }

        $lines = Get-Content $_.FullName
        $name = ""; $description = ""; $modelTier = ""; $tools = @(); $templateLines = @()
        $inTools = $false; $inTemplate = $false; $templateIndent = 2

        foreach ($line in $lines) {
            if ($line -match "^name:\s*(.+)$")        { $name = $matches[1].Trim(); $inTools = $false; $inTemplate = $false }
            elseif ($line -match "^description:\s*(.+)$") { $description = $matches[1].Trim(); $inTools = $false; $inTemplate = $false }
            elseif ($line -match "^model_tier:\s*(.+)$")  { $modelTier = $matches[1].Trim(); $inTools = $false; $inTemplate = $false }
            elseif ($line -match "^tools_allowed:$")       { $inTools = $true; $inTemplate = $false }
            elseif ($line -match "^prompt_template:\s*\|$") { $inTools = $false; $inTemplate = $true }
            elseif ($inTools -and $line -match "^  - (\S+)$") { $tools += $matches[1] }
            elseif ($inTools -and $line -notmatch "^  ") { $inTools = $false }
            elseif ($inTemplate) {
                if ($line.Length -ge $templateIndent -and $line.Substring(0, $templateIndent) -eq "  ") {
                    $templateLines += $line.Substring($templateIndent)
                } elseif ($line -eq "") {
                    $templateLines += ""
                } elseif ($line -notmatch "^\s") {
                    $inTemplate = $false
                } else {
                    $templateLines += $line
                }
            }
        }

        $modelId = Get-ModelId $modelTier
        $template = ($templateLines -join "`n").TrimEnd()

        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.AppendLine($ManagedHeader)
        [void]$sb.AppendLine("---")
        [void]$sb.AppendLine("name: $name")
        [void]$sb.AppendLine("description: $description")
        [void]$sb.AppendLine("model: $modelId")
        if ($tools.Count -gt 0) {
            [void]$sb.AppendLine("tools:")
            foreach ($t in $tools) { [void]$sb.AppendLine("  - $t") }
        }
        [void]$sb.AppendLine("---")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine($template)

        $content = $sb.ToString() -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($agentDst, $content, [System.Text.Encoding]::UTF8)
        $AgentsWritten++
    }
    Write-Host "  Agents: $AgentsWritten written, $AgentsPreserved preserved (user-authored)"
} else {
    Write-Host "  Agents: .shamt\agents\ not found — skipping"
}

# --- Phase 3: Commands --------------------------------------------------------

$CmdsSrc = Join-Path $ShamtDir "commands"
$CmdsDst = Join-Path $ClaudeDir "commands"
$CmdsWritten = 0; $CmdsPreserved = 0

if (Test-Path $CmdsSrc) {
    New-Item -ItemType Directory -Force -Path $CmdsDst | Out-Null
    Get-ChildItem -Path $CmdsSrc -Filter "*.md" | Where-Object { $_.Name -ne "README.md" } | Sort-Object Name | ForEach-Object {
        $cmdName = $_.Name
        $cmdDst  = Join-Path $CmdsDst $cmdName

        if ((Test-Path $cmdDst) -and -not (Is-ShamtManaged $cmdDst)) {
            $CmdsPreserved++; return
        }

        $content = $ManagedHeader + "`n`n" + (Get-Content $_.FullName -Raw)
        $content = $content -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($cmdDst, $content, [System.Text.Encoding]::UTF8)
        $CmdsWritten++
    }
    Write-Host "  Commands: $CmdsWritten written, $CmdsPreserved preserved (user-authored)"
} else {
    Write-Host "  Commands: .shamt\commands\ not found — skipping"
}

Write-Host ""
Write-Host "  ✓ Regen complete"
Write-Host ""
