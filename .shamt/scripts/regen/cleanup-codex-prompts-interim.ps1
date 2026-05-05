# =============================================================================
# cleanup-codex-prompts-interim.ps1 — Remove stale Shamt skill prompts from
# %USERPROFILE%\.codex\prompts\ after migrating to .agents\skills\<name>\SKILL.md
# =============================================================================
# Run this once after upgrading to SHAMT-53 (Codex Skills GA migration).
# For each shamt-*.md in %USERPROFILE%\.codex\prompts\, checks whether the
# corresponding .agents\skills\ entry exists and removes it if so. Warns for
# any that cannot be matched.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .shamt\scripts\regen\cleanup-codex-prompts-interim.ps1
#
# Safe to re-run: already-removed files are silently ignored.
# =============================================================================

$ErrorActionPreference = "Stop"

$ScriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot     = (Get-Item "$ScriptDir\..\..\..").FullName
$CodexPromptsDir = Join-Path $env:USERPROFILE ".codex\prompts"
$AgentsSkillsDir = Join-Path $ProjectRoot ".agents\skills"

$Removed = 0
$Warned  = 0

Write-Host ""
Write-Host "============================================================"
Write-Host "  Shamt: Cleanup interim Codex skill prompts"
Write-Host "============================================================"
Write-Host "  Scanning: $CodexPromptsDir\shamt-*.md"
Write-Host "  Checking against: $AgentsSkillsDir\"
Write-Host "============================================================"
Write-Host ""

if (-not (Test-Path $CodexPromptsDir)) {
    Write-Host "  %USERPROFILE%\.codex\prompts\ not found — nothing to clean up."
    Write-Host ""
    exit 0
}

$promptFiles = Get-ChildItem -Path $CodexPromptsDir -Filter "shamt-*.md" -ErrorAction SilentlyContinue | Sort-Object Name

foreach ($file in $promptFiles) {
    $filename  = $file.Name
    # Strip leading "shamt-" and trailing ".md" → skill directory name
    $skillName = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    if ($skillName.StartsWith("shamt-")) {
        $skillName = $skillName.Substring(6)  # strip "shamt-"
    }

    $agentsSkill = Join-Path $AgentsSkillsDir "$skillName\SKILL.md"

    if (Test-Path $agentsSkill) {
        Remove-Item $file.FullName -Force
        Write-Host "  Removed: $($file.FullName)"
        $Removed++
    } else {
        Write-Host "  WARN: $($file.FullName) — no matching .agents\skills\$skillName\SKILL.md found; left in place"
        $Warned++
    }
}

Write-Host ""
Write-Host "  Removed: $Removed  |  Warnings: $Warned"
Write-Host ""

if ($Warned -gt 0) {
    Write-Host "  Check warnings above. Run regen-codex-shims.ps1 first to populate"
    Write-Host "  .agents\skills\, then re-run this script."
    Write-Host ""
}
