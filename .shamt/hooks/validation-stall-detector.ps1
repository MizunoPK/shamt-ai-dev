# validation-stall-detector.ps1
# PostToolUse (Edit matching *VALIDATION_LOG.md) — Detect validation loop stalls.
# Fires when consecutive_clean has been 0 for SHAMT_STALL_THRESHOLD or more
# consecutive rounds. Writes STALL_ALERT.md to the active epic folder.
# Configurable: $env:SHAMT_STALL_THRESHOLD (default 3). Informational — always exits 0.

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
$threshold = if ($env:SHAMT_STALL_THRESHOLD) { [int]$env:SHAMT_STALL_THRESHOLD } else { 3 }

$inputText = $input | Out-String

# Only act on validation log edits
if ($inputText -notmatch "VALIDATION_LOG") { exit 0 }

# Extract file path from PostToolUse JSON
$logPath = ""
try {
    $data = $inputText | ConvertFrom-Json
    $logPath = if ($data.tool_input.file_path) { $data.tool_input.file_path }
               elseif ($data.file_path) { $data.file_path }
               else { "" }
} catch { }

if ([string]::IsNullOrEmpty($logPath) -or -not (Test-Path $logPath)) { exit 0 }

# Count trailing zero consecutive_clean rounds
$stallCount = 0
try {
    $text = Get-Content $logPath -Raw
    $vals = [regex]::Matches($text, '\*{0,2}consecutive_clean\*{0,2}:\*{0,2}\s*(\d+)') |
            ForEach-Object { [int]$_.Groups[1].Value }
    if ($vals.Count -eq 0) { exit 0 }  # old log format — skip gracefully
    for ($i = $vals.Count - 1; $i -ge 0; $i--) {
        if ($vals[$i] -eq 0) { $stallCount++ } else { break }
    }
} catch { exit 0 }

if ($stallCount -lt $threshold) { exit 0 }

# Stall detected — find active epic
$activeEpic = ""
try {
    $tracker = Join-Path $projectRoot ".shamt\epics\EPIC_TRACKER.md"
    if (Test-Path $tracker) {
        $line = Select-String -Path $tracker -Pattern '\|\s*([A-Z]+-\d+)\s*\|[^|]+\|[^|]+\|\s*[Ii]n [Pp]rogress' |
                Select-Object -First 1
        if ($line) {
            $activeEpic = ($line.Line -split '\|')[1].Trim()
        }
    }
} catch { }

$alertMsg = "SHAMT validation loop stalled — consecutive_clean=0 for $stallCount rounds. Likely needs human judgment or model escalation."

if (-not [string]::IsNullOrEmpty($activeEpic)) {
    $alertDir = Join-Path $projectRoot ".shamt\epics\$activeEpic"
    if (-not (Test-Path $alertDir)) { New-Item -ItemType Directory -Path $alertDir | Out-Null }
    $alertContent = @"
# Validation Loop Stall Alert

**consecutive_clean = 0 for $stallCount consecutive rounds** (threshold: $threshold)

**Log:** $logPath

## Recommended Actions

1. **Review the last round's findings** — are the issues genuinely hard, or is the validator being too strict?
2. **Escalate reasoning effort** — if using Haiku/Sonnet, switch to Opus for the next round.
3. **Decompose the artifact** — validate sections independently if the artifact is large.
4. **Human judgment** — if the loop has been stuck for many rounds, bring in a human reviewer.

Stall threshold is configurable via `SHAMT_STALL_THRESHOLD` env var (current: $threshold).
"@
    Set-Content -Path (Join-Path $alertDir "STALL_ALERT.md") -Value $alertContent
}

Write-Error $alertMsg
exit 0
