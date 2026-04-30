# =============================================================================
# permission-router.ps1 — Codex PermissionRequest handler (Windows/PowerShell)
# =============================================================================
# Mirror of permission-router.sh for Windows.
# Reads a PermissionRequest JSON from stdin, outputs a decision JSON to stdout.
# =============================================================================

$ErrorActionPreference = "Stop"

$inputJson = $input | Out-String
if ([string]::IsNullOrWhiteSpace($inputJson)) { exit 1 }

try {
    $data = $inputJson | ConvertFrom-Json
} catch {
    exit 1
}

$toolName = if ($data.tool_name) { $data.tool_name } else { "" }
if ([string]::IsNullOrEmpty($toolName)) { exit 1 }

# --- Helper: find active epic path -------------------------------------------

function Get-ActiveEpicPath {
    $tracker = Join-Path (Get-Location) ".shamt\epics\EPIC_TRACKER.md"
    if (-not (Test-Path $tracker)) { return "" }
    $line = Select-String -Path $tracker -Pattern '^\| .* \| active \|' | Select-Object -First 1
    if (-not $line) { return "" }
    $parts = $line.Line -split '\|'
    if ($parts.Count -lt 2) { return "" }
    $tag = $parts[1].Trim()
    if ([string]::IsNullOrEmpty($tag)) { return "" }
    return Join-Path (Get-Location) ".shamt\epics\$tag"
}

# --- Decision logic -----------------------------------------------------------

switch ($toolName) {
    { $_ -in @("edit", "write") } {
        $target = if ($data.path) { $data.path } elseif ($data.file_path) { $data.file_path } else { "" }
        $epicPath = Get-ActiveEpicPath
        if ($epicPath -ne "" -and $target -ne "" -and $target.StartsWith($epicPath)) {
            Write-Output '{"decision":"approve","reason":"in-scope edit within active epic folder"}'
            exit 0
        }
        Write-Output '{"decision":"ask_user","reason":"edit outside active epic folder"}'
        exit 0
    }
    { $_ -in @("shell", "bash") } {
        $command = if ($data.command) { $data.command } else { "" }
        if ($command -match "git push") {
            Write-Output '{"decision":"ask_user","reason":"push requires human review"}'
            exit 0
        }
        if ($command -match "git commit") {
            Write-Output '{"decision":"ask_user","reason":"commit requires human review"}'
            exit 0
        }
        Write-Output '{"decision":"ask_user"}'
        exit 0
    }
    default {
        exit 1
    }
}
