# =============================================================================
# regen-lite-claude.ps1 — Shamt Lite Claude Code shim generator (Windows)
# =============================================================================
# Deploys Shamt Lite canonical content into a child project's .claude/ tree.
#
# Source content lives in this master shamt-ai-dev repo:
#   Skills   .shamt\skills\shamt-lite-*\SKILL.md
#   Commands .shamt\scripts\initialization\lite\commands\*.md
#   Agents   .shamt\scripts\initialization\lite\agents\*.yaml
#
# Usage (from the child project root):
#   powershell -ExecutionPolicy Bypass -File C:\path\to\shamt-ai-dev\.shamt\scripts\regen\regen-lite-claude.ps1
#
# Idempotent: files with no Shamt-managed header are preserved.
# =============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ShamtSourceDir = (Get-Item "$ScriptDir\..\..\..").FullName
$ShamtDir = Join-Path $ShamtSourceDir ".shamt"
$TargetDir = (Get-Location).Path
$ClaudeDir = Join-Path $TargetDir ".claude"

$LiteCmdsSrc   = Join-Path $ShamtDir "scripts\initialization\lite\commands"
$LiteAgentsSrc = Join-Path $ShamtDir "scripts\initialization\lite\agents"
$SkillsSrc     = Join-Path $ShamtDir "skills"

$ManagedHeader = "<!-- Managed by Shamt — do not edit. Run regen-lite-claude.ps1 to regenerate. -->"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Shamt Lite Regen — Claude Code Shims"
Write-Host "============================================================"
Write-Host "  Source: $ShamtSourceDir"
Write-Host "  Target: $TargetDir"
Write-Host "============================================================"
Write-Host ""

function Is-ShamtManaged {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $false }
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    return ($content -match "Managed by Shamt")
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

# --- Phase 1: Skills (filter shamt-lite-*) -----------------------------------

$SkillsDst = Join-Path $ClaudeDir "skills"
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
        # tags so deployed XML examples are concrete on Claude Code. The explanatory
        # footnote (which references `{cheap-tier}` as inline code) is preserved.
        $content = (Get-Content $skillSrc -Raw) -replace '<parameter name="model">\{cheap-tier\}</parameter>', '<parameter name="model">haiku</parameter>'
        $content = $content + "`n" + $ManagedHeader + "`n"
        $content = $content -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($skillDst, $content, [System.Text.Encoding]::UTF8)
        $SkillsWritten++
    }
    Write-Host "  Skills: $SkillsWritten written, $SkillsPreserved preserved (user-authored)"
} else {
    Write-Host "  Skills: $SkillsSrc not found — skipping"
}

# --- Phase 2: Commands -------------------------------------------------------

$CmdsDst = Join-Path $ClaudeDir "commands"
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

# --- Phase 3: Agents (YAML → Claude Code agent md) --------------------------

$AgentsDst = Join-Path $ClaudeDir "agents"
$AgentsWritten = 0; $AgentsPreserved = 0

if (Test-Path $LiteAgentsSrc) {
    New-Item -ItemType Directory -Force -Path $AgentsDst | Out-Null
    Get-ChildItem -Path $LiteAgentsSrc -Filter "*.yaml" | Sort-Object Name | ForEach-Object {
        $agentName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $agentDst  = Join-Path $AgentsDst "$agentName.md"

        if ((Test-Path $agentDst) -and -not (Is-ShamtManaged $agentDst)) {
            $AgentsPreserved++; return
        }

        $lines = Get-Content $_.FullName
        $name = ""; $description = ""; $modelTier = ""; $tools = @(); $templateLines = @()
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
        # Flush description block if file ends inside it
        if ($inDescBlock -and $descLines.Count -gt 0 -and $description -eq "") {
            $description = ($descLines -join " ").Trim()
        }

        $modelId = Get-ModelId $modelTier
        $template = ($templateLines -join "`n").TrimEnd()

        $sb = [System.Text.StringBuilder]::new()
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
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine($ManagedHeader)

        $content = $sb.ToString() -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($agentDst, $content, [System.Text.Encoding]::UTF8)
        $AgentsWritten++
    }
    Write-Host "  Agents: $AgentsWritten written, $AgentsPreserved preserved (user-authored)"
} else {
    Write-Host "  Agents: $LiteAgentsSrc not found — skipping"
}

Write-Host ""
Write-Host "  ✓ Lite regen complete"
Write-Host ""
