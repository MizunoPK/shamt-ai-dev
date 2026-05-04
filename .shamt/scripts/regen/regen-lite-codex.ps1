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
        $content = $ManagedHeaderMd + "`n" + (Get-Content $skillSrc -Raw)
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

Write-Host ""
Write-Host "  ✓ Lite regen complete"
Write-Host ""
