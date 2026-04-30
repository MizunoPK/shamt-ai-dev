# =============================================================================
# regen-codex-shims.ps1 — Shamt Codex shim generator (Windows/PowerShell)
# =============================================================================
# Mirror of regen-codex-shims.sh for Windows.
# Transforms canonical Shamt content into Codex-shaped equivalents.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .shamt\scripts\regen\regen-codex-shims.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Get-Item "$ScriptDir\..\..\..").FullName
$ShamtDir    = Join-Path $ProjectRoot ".shamt"
$CodexDir    = Join-Path $ProjectRoot ".codex"
$CodexPromptsDir = Join-Path $env:USERPROFILE ".codex\prompts"

$ManagedHeader = "# Managed by Shamt — do not edit. Run regen-codex-shims.ps1 to regenerate."

# --- Determine repo type ------------------------------------------------------

$RepoTypeConf = Join-Path $ShamtDir "config\repo_type.conf"
$RepoType = "child"
if (Test-Path $RepoTypeConf) {
    $RepoType = (Get-Content $RepoTypeConf -Raw).Trim()
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  Shamt Regen — Codex Shims"
Write-Host "============================================================"
Write-Host "  Project: $ProjectRoot"
Write-Host "  Repo type: $RepoType"
Write-Host "============================================================"
Write-Host ""

# --- Read model resolution ----------------------------------------------------

$ModelResolution = Join-Path $ShamtDir "host\codex\.model_resolution.local.toml"
$FrontierModel = "o3"
$DefaultModel  = "o4-mini"
if (Test-Path $ModelResolution) {
    foreach ($line in Get-Content $ModelResolution) {
        if ($line -match '^FRONTIER_MODEL\s*=\s*"(.+)"') { $FrontierModel = $matches[1] }
        if ($line -match '^DEFAULT_MODEL\s*=\s*"(.+)"')  { $DefaultModel  = $matches[1] }
    }
}

Write-Host "  Models: FRONTIER=$FrontierModel  DEFAULT=$DefaultModel"
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
    $lines = Get-Content $SkillFile
    $dashCount = 0; $inFrontmatter = $false
    foreach ($line in $lines) {
        if ($line -eq "---") {
            $dashCount++
            if ($dashCount -eq 1) { $inFrontmatter = $true; continue }
            if ($dashCount -eq 2) { break }
        }
        if ($inFrontmatter -and $line -match "^master-only:\s*true") { return $true }
    }
    return $false
}

function Tier-To-Model {
    param([string]$Tier)
    switch ($Tier) {
        "cheap"     { return $script:DefaultModel }
        "balanced"  { return $script:FrontierModel }
        "reasoning" { return $script:FrontierModel }
        default     { return $Tier }
    }
}

# --- Phase 1: Skills → %USERPROFILE%\.codex\prompts\shamt-<name>.md ----------

$SkillsSrc = Join-Path $ShamtDir "skills"
$SkillsWritten = 0; $SkillsSkipped = 0

if (Test-Path $SkillsSrc) {
    New-Item -ItemType Directory -Force -Path $CodexPromptsDir | Out-Null
    Get-ChildItem -Path $SkillsSrc -Directory | Sort-Object Name | ForEach-Object {
        $skillName = $_.Name
        $skillSrc  = Join-Path $_.FullName "SKILL.md"
        if (-not (Test-Path $skillSrc)) { return }

        if ($RepoType -eq "child" -and (Is-MasterOnly $skillSrc)) {
            $script:SkillsSkipped++; return
        }

        $skillDst = Join-Path $CodexPromptsDir "shamt-$skillName.md"
        $content = $ManagedHeader + "`n" + (Get-Content $skillSrc -Raw)
        $content = $content -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($skillDst, $content, [System.Text.Encoding]::UTF8)
        $script:SkillsWritten++
    }
    Write-Host "  Skills: $SkillsWritten written to %USERPROFILE%\.codex\prompts\, $SkillsSkipped skipped (master-only on child)"
} else {
    Write-Host "  Skills: .shamt\skills\ not found — skipping"
}

# --- Phase 2: Agents → .codex\agents\<name>.toml -----------------------------

$AgentsSrc = Join-Path $ShamtDir "agents"
$AgentsWritten = 0

if (Test-Path $AgentsSrc) {
    New-Item -ItemType Directory -Force -Path (Join-Path $CodexDir "agents") | Out-Null
    Get-ChildItem -Path $AgentsSrc -Filter "*.yaml" | Sort-Object Name | ForEach-Object {
        $agentName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $agentDst  = Join-Path $CodexDir "agents\$agentName.toml"

        $lines = Get-Content $_.FullName
        $name = ""; $modelTier = ""; $reasoningEffort = ""; $sandbox = ""
        $tools = @(); $templateLines = @()
        $inTools = $false; $inTemplate = $false

        foreach ($line in $lines) {
            if ($line -match "^name:\s*(.+)$")              { $name = $matches[1].Trim(); $inTools = $false; $inTemplate = $false }
            elseif ($line -match "^model_tier:\s*(.+)$")    { $modelTier = $matches[1].Trim(); $inTools = $false; $inTemplate = $false }
            elseif ($line -match "^reasoning_effort:\s*(.+)$") { $reasoningEffort = $matches[1].Trim(); $inTools = $false; $inTemplate = $false }
            elseif ($line -match "^sandbox:\s*(.+)$")       { $sandbox = $matches[1].Trim(); $inTools = $false; $inTemplate = $false }
            elseif ($line -match "^tools_allowed:$")         { $inTools = $true; $inTemplate = $false }
            elseif ($line -match "^prompt_template:\s*\|$")  { $inTools = $false; $inTemplate = $true }
            elseif ($inTools -and $line -match "^  - (\S+)$") { $tools += $matches[1] }
            elseif ($inTools -and $line -notmatch "^  ") { $inTools = $false }
            elseif ($inTemplate) {
                if ($line.Length -ge 2 -and $line.Substring(0,2) -eq "  ") {
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

        $model = Tier-To-Model $modelTier
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
        [System.IO.File]::WriteAllText($agentDst, $content, [System.Text.Encoding]::UTF8)
        $script:AgentsWritten++
    }
    Write-Host "  Agents: $AgentsWritten written to .codex\agents\"
} else {
    Write-Host "  Agents: .shamt\agents\ not found — skipping"
}

# --- Phase 3: Commands → %USERPROFILE%\.codex\prompts\ -----------------------

$CmdsSrc = Join-Path $ShamtDir "commands"
$CmdsWritten = 0

if (Test-Path $CmdsSrc) {
    New-Item -ItemType Directory -Force -Path $CodexPromptsDir | Out-Null
    Get-ChildItem -Path $CmdsSrc -Filter "*.md" | Where-Object { $_.Name -ne "README.md" } | Sort-Object Name | ForEach-Object {
        $cmdName = $_.Name
        $cmdDst  = Join-Path $CodexPromptsDir $cmdName
        # Translate {placeholder} → $PLACEHOLDER
        $rawContent = Get-Content $_.FullName -Raw
        $translated = [regex]::Replace($rawContent, '\{([a-zA-Z_][a-zA-Z0-9_]*)\}', { param($m) '$' + $m.Groups[1].Value.ToUpper() })
        $content = $ManagedHeader + "`n`n" + $translated
        $content = $content -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($cmdDst, $content, [System.Text.Encoding]::UTF8)
        $script:CmdsWritten++
    }
    Write-Host "  Commands: $CmdsWritten written to %USERPROFILE%\.codex\prompts\"
} else {
    Write-Host "  Commands: .shamt\commands\ not found — skipping"
}

# --- Phase 4: Profiles + Hooks + MCP → .codex\config.toml -------------------

$ConfigToml = Join-Path $CodexDir "config.toml"
$ProfilesSrc = Join-Path $ShamtDir "host\codex\profiles"

if ((Test-Path $ConfigToml) -and (Test-Path $ProfilesSrc)) {
    # Delegate to Python for the block-replace logic (mirrors the .sh approach)
    $pyScript = @"
import sys, os, re
from pathlib import Path

config_path = r'$($ConfigToml -replace '\\', '\\')'
profiles_src = r'$($ProfilesSrc -replace '\\', '\\')'
project_root = r'$($ProjectRoot -replace '\\', '\\')'
repo_type = '$RepoType'
frontier_model = '$FrontierModel'
default_model = '$DefaultModel'

with open(config_path) as f:
    config = f.read()

def replace_block(text, start_marker, end_marker, new_content):
    pattern = re.compile(
        r'(# ={13,}\n# ' + re.escape(start_marker) + r'.*?\n# ={13,}\n)'
        r'.*?'
        r'(# ={13,}\n# ' + re.escape(end_marker) + r'\n# ={13,})',
        re.DOTALL
    )
    replacement = r'\g<1>\n' + new_content + '\n' + r'\g<2>'
    result, count = pattern.subn(replacement, text)
    if count == 0:
        pattern2 = re.compile(r'# ' + re.escape(start_marker) + r'.*?# ' + re.escape(end_marker), re.DOTALL)
        replacement2 = '# ' + start_marker + '\n\n' + new_content + '\n\n# ' + end_marker
        result, _ = pattern2.subn(replacement2, text)
        return result
    return result

fragment_files = sorted(Path(profiles_src).glob('*.fragment.toml'))
profiles_lines = []
_fm_ph = chr(36) + '{FRONTIER_MODEL}'
_dm_ph = chr(36) + '{DEFAULT_MODEL}'
for fpath in fragment_files:
    frag = fpath.read_text()
    frag = frag.replace(_fm_ph, frontier_model)
    frag = frag.replace(_dm_ph, default_model)
    profiles_lines.append(frag.rstrip())
    profiles_lines.append('')
venv_python = Path(project_root) / '.shamt' / 'mcp' / '.venv' / 'bin' / 'python'
if venv_python.exists():
    profiles_lines += [f'[profiles.shamt-s5.mcp_servers.shamt]', f'command = "{venv_python}"', 'args = ["-m", "shamt_mcp"]', '']
profiles_content = '\n'.join(profiles_lines)

mcp_lines = []
if venv_python.exists():
    mcp_lines += ['[mcp_servers.shamt]', f'command = "{venv_python}"', 'args = ["-m", "shamt_mcp"]', '']
mcp_content = '\n'.join(mcp_lines)

hooks_src = Path(project_root) / '.shamt' / 'hooks'
def hook_cmd(name):
    return str(hooks_src / name)
hooks_lines = []
pre_shell = [hook_cmd('no-verify-blocker.sh'), hook_cmd('commit-format.sh')]
if repo_type != 'master':
    pre_shell += [hook_cmd('user-testing-gate.sh'), hook_cmd('pre-export-audit-gate.sh')]
hooks_lines += ['[hooks.pre_tool_use.shell]', 'commands = ['] + [f'  "{h}",' for h in pre_shell] + [']', '']
hooks_lines += ['[hooks.pre_tool_use.agent_spawn]', f'commands = ["{hook_cmd("architect-builder-enforcer.sh")}"]', '']
hooks_lines += ['[hooks.post_tool_use.edit]', f'commands = ["{hook_cmd("validation-log-stamp.sh")}"]', '']
upm = []
if repo_type != 'master': upm.append(hook_cmd('pre-export-audit-gate.sh'))
upm.append(hook_cmd('stage-transition-snapshot.sh'))
hooks_lines += ['[hooks.user_prompt_submit]', 'commands = ['] + [f'  "{h}",' for h in upm] + [']', '']
hooks_lines += ['[hooks.session_start]', f'commands = ["{hook_cmd("session-start-resume.sh")}"]', '']
hooks_lines += ['[hooks.stop]', f'commands = ["{hook_cmd("subagent-confirmation-receipt.sh")}"]', '']
hooks_lines += ['[hooks.permission_request]', f'commands = ["{hook_cmd("permission-router.sh")}"]', '']
hooks_content = '\n'.join(hooks_lines)

config = replace_block(config, 'SHAMT-PROFILES-START — managed by regen-codex-shims.sh; do not edit manually', 'SHAMT-PROFILES-END', profiles_content)
config = replace_block(config, 'SHAMT-MCP-START — managed by regen-codex-shims.sh; do not edit manually', 'SHAMT-MCP-END', mcp_content)
config = replace_block(config, 'SHAMT-HOOKS-START — managed by regen-codex-shims.sh; do not edit manually', 'SHAMT-HOOKS-END', hooks_content)

with open(config_path, 'w') as f:
    f.write(config)
print(f'  Profiles: {len(fragment_files)} fragments written')
print(f'  Hooks: installed')
"@

    python3 -c $pyScript
} else {
    Write-Host "  Profiles + Hooks + MCP: skipped (.codex\config.toml or profiles\ not found)"
}

Write-Host ""
Write-Host "  OK Regen complete"
Write-Host ""
