# =============================================================================
# shamt-add-host.ps1 — Add a host to an existing Shamt project (Windows)
# =============================================================================
# Mirror of shamt-add-host.sh for Windows/PowerShell.
#
# Usage:
#   & "C:\path\to\shamt-ai-dev\.shamt\scripts\initialization\shamt-add-host.ps1" <host>
#
# Arguments:
#   host — "claude" or "codex" (required)
#
# Run from the project root.
# =============================================================================

$ErrorActionPreference = "Stop"

$ShamtSourceDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$TargetDir = Get-Location
$ShamtDir = Join-Path $TargetDir ".shamt"
$Host = if ($args.Count -gt 0) { $args[0] } else { "" }

Write-Host ""
Write-Host "============================================================"
Write-Host "  Shamt — Add Host"
Write-Host "============================================================"
Write-Host "  Project: $TargetDir"
Write-Host "  Host:    $Host"
Write-Host "============================================================"
Write-Host ""

# --- Validate -----------------------------------------------------------------

if (-not (Test-Path $ShamtDir)) {
    Write-Host "  Error: .shamt\ not found. Run init.ps1 first." -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($Host)) {
    Write-Host "  Usage: & shamt-add-host.ps1 <host>" -ForegroundColor Yellow
    Write-Host "  Hosts:  claude  |  codex" -ForegroundColor Yellow
    exit 1
}

if ($Host -notin @("claude", "codex")) {
    Write-Host "  Error: unknown host '$Host'. Valid values: claude, codex" -ForegroundColor Red
    exit 1
}

# --- Claude Code host wiring --------------------------------------------------

if ($Host -eq "claude") {
    Write-Host "  Adding Claude Code host wiring..."
    Write-Host ""

    foreach ($d in @("skills", "agents", "commands")) {
        New-Item -ItemType Directory -Force -Path (Join-Path $TargetDir ".claude\$d") | Out-Null
    }
    Write-Host "  OK .claude\ directory structure created"

    $RegenScript = Join-Path $ShamtSourceDir ".shamt\scripts\regen\regen-claude-shims.ps1"
    if (Test-Path $RegenScript) {
        & powershell -ExecutionPolicy Bypass -File $RegenScript
        Write-Host "  OK Claude Code shims generated"
    } else {
        Write-Host "  WARNING: regen-claude-shims.ps1 not found — run it manually" -ForegroundColor Yellow
    }

    $StarterSettings = Join-Path $ShamtSourceDir ".shamt\host\claude\settings.starter.json"
    $TargetSettings  = Join-Path $TargetDir ".claude\settings.json"
    if (Test-Path $TargetSettings) {
        Write-Host "  OK .claude\settings.json already exists — skipping"
    } elseif (Test-Path $StarterSettings) {
        $content = (Get-Content $StarterSettings -Raw) -replace [regex]::Escape('${PROJECT}'), $TargetDir
        [System.IO.File]::WriteAllText($TargetSettings, $content, [System.Text.Encoding]::UTF8)
        Write-Host "  OK .claude\settings.json written"
    } else {
        Write-Host "  WARNING: settings.starter.json not found — skipping" -ForegroundColor Yellow
    }

    $AiServiceConf = Join-Path $ShamtDir "config\ai_service.conf"
    New-Item -ItemType Directory -Force -Path (Split-Path $AiServiceConf) | Out-Null
    Set-Content $AiServiceConf "claude_code" -NoNewline
    Write-Host "  OK ai_service.conf updated to claude_code"

    Write-Host ""
    Write-Host "  NOTE: Ensure this project is trusted in Claude Code." -ForegroundColor Cyan
}

# --- Codex host wiring --------------------------------------------------------

if ($Host -eq "codex") {
    Write-Host "  Adding Codex host wiring..."
    Write-Host ""

    New-Item -ItemType Directory -Force -Path (Join-Path $TargetDir ".codex\agents") | Out-Null
    Write-Host "  OK .codex\ directory structure created"

    # Model resolution: prompt if missing
    $ModelResolution = Join-Path $ShamtDir "host\codex\.model_resolution.local.toml"
    New-Item -ItemType Directory -Force -Path (Split-Path $ModelResolution) | Out-Null
    if (-not (Test-Path $ModelResolution)) {
        Write-Host "  Codex model names (from Codex changelog — press Enter to accept defaults):"
        $frontier = Read-Host "    Frontier model [o3]"
        if ([string]::IsNullOrWhiteSpace($frontier)) { $frontier = "o3" }
        $default  = Read-Host "    Default model  [o4-mini]"
        if ([string]::IsNullOrWhiteSpace($default))  { $default  = "o4-mini" }
        Set-Content $ModelResolution "FRONTIER_MODEL = `"$frontier`"`nDEFAULT_MODEL = `"$default`"" -NoNewline
        Write-Host "  OK .model_resolution.local.toml written"
    } else {
        Write-Host "  OK .model_resolution.local.toml already exists"
    }

    # Write starter config.toml
    $StarterConfig  = Join-Path $ShamtSourceDir ".shamt\host\codex\config.starter.toml"
    $TargetConfig   = Join-Path $TargetDir ".codex\config.toml"
    if (Test-Path $TargetConfig) {
        Write-Host "  OK .codex\config.toml already exists — skipping initial write"
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

    # Run regen
    $RegenScript = Join-Path $ShamtSourceDir ".shamt\scripts\regen\regen-codex-shims.ps1"
    if (Test-Path $RegenScript) {
        & powershell -ExecutionPolicy Bypass -File $RegenScript
        Write-Host "  OK Codex shims generated"
    } else {
        Write-Host "  WARNING: regen-codex-shims.ps1 not found — run it manually" -ForegroundColor Yellow
    }

    $AiServiceConf = Join-Path $ShamtDir "config\ai_service.conf"
    New-Item -ItemType Directory -Force -Path (Split-Path $AiServiceConf) | Out-Null
    Set-Content $AiServiceConf "codex" -NoNewline
    Write-Host "  OK ai_service.conf updated to codex"
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  Host '$Host' wiring complete."
Write-Host "============================================================"
Write-Host ""
