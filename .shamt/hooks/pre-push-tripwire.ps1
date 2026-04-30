# pre-push-tripwire.ps1
# PreToolUse (Bash matching git push) — Final guard before changes leave the worktree.
# Verifies three conditions before allowing a push:
#   (a) .shamt/audit/last_run.json is fresh (<=SHAMT_AUDIT_MAX_AGE_DAYS) and clean
#   (b) Active epic's validation log shows consecutive_clean >= 1
#   (c) Builder handoff log (if S6 just completed) shows no unresolved errors
# Emergency bypass: set SHAMT_BYPASS_TRIPWIRE=1.
# Configurable: $env:SHAMT_AUDIT_MAX_AGE_DAYS (default 7).

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
$maxAgeDays = if ($env:SHAMT_AUDIT_MAX_AGE_DAYS) { [int]$env:SHAMT_AUDIT_MAX_AGE_DAYS } else { 7 }

$inputText = $input | Out-String

# Only intercept git push
$isPush = $false
if ($inputText -match '"git push|git push ') { $isPush = $true }
if (-not $isPush) {
    try {
        $data = $inputText | ConvertFrom-Json
        $cmd = if ($data.tool_input.command) { $data.tool_input.command }
               elseif ($data.command) { $data.command }
               else { "" }
        if ($cmd -match '^git push') { $isPush = $true }
    } catch { }
}
if (-not $isPush) { exit 0 }

# Emergency bypass
if ($env:SHAMT_BYPASS_TRIPWIRE -eq "1") {
    Write-Error "SHAMT PRE-PUSH TRIPWIRE: Bypass active (SHAMT_BYPASS_TRIPWIRE=1). Proceeding without checks."
    exit 0
}

$failed = $false

# --- Check (a): Audit freshness and cleanliness ---
$lastRunPath = Join-Path $projectRoot ".shamt\audit\last_run.json"
if (-not (Test-Path $lastRunPath)) {
    Write-Error "SHAMT PRE-PUSH TRIPWIRE [BLOCKED]: No audit record found at .shamt\audit\last_run.json`n  → Run a full guide audit (3 consecutive clean rounds) before pushing."
    $failed = $true
} else {
    try {
        $audit = Get-Content $lastRunPath -Raw | ConvertFrom-Json
        if (-not $audit.exit_criterion_met) {
            Write-Error "SHAMT PRE-PUSH TRIPWIRE [BLOCKED]: Last audit did not meet exit criteria.`n  → Run a full guide audit before pushing."
            $failed = $true
        }
        if ($audit.timestamp) {
            $auditTime = [datetime]::Parse($audit.timestamp).ToUniversalTime()
            $ageDays = ([datetime]::UtcNow - $auditTime).Days
            if ($ageDays -gt $maxAgeDays) {
                Write-Error "SHAMT PRE-PUSH TRIPWIRE [BLOCKED]: Audit is $ageDays days old (max $maxAgeDays).`n  → Run a fresh guide audit before pushing."
                $failed = $true
            }
        }
    } catch {
        Write-Error "SHAMT PRE-PUSH TRIPWIRE [BLOCKED]: Could not parse audit record: $_"
        $failed = $true
    }
}

# --- Check (b): Active epic validation log shows consecutive_clean >= 1 ---
$activeEpic = ""
try {
    $tracker = Join-Path $projectRoot ".shamt\epics\EPIC_TRACKER.md"
    if (Test-Path $tracker) {
        $line = Select-String -Path $tracker -Pattern '\|\s*([A-Z]+-\d+)\s*\|[^|]+\|[^|]+\|\s*[Ii]n [Pp]rogress' |
                Select-Object -First 1
        if ($line) { $activeEpic = ($line.Line -split '\|')[1].Trim() }
    }
} catch { }

if (-not [string]::IsNullOrEmpty($activeEpic)) {
    $epicDir = Join-Path $projectRoot ".shamt\epics\$activeEpic"
    $valLog = Get-ChildItem -Path $epicDir -Filter "*VALIDATION_LOG.md" -ErrorAction SilentlyContinue |
              Sort-Object Name | Select-Object -Last 1
    if ($valLog) {
        try {
            $text = Get-Content $valLog.FullName -Raw
            $matches_ = [regex]::Matches($text, '\*{0,2}consecutive_clean\*{0,2}:\*{0,2}\s*(\d+)')
            if ($matches_.Count -gt 0) {
                $lastClean = [int]$matches_[$matches_.Count - 1].Groups[1].Value
                if ($lastClean -eq 0) {
                    Write-Error "SHAMT PRE-PUSH TRIPWIRE [BLOCKED]: Validation log for $activeEpic shows consecutive_clean=0.`n  → Complete the validation loop before pushing."
                    $failed = $true
                }
            }
        } catch { }
    }

    # --- Check (c): Builder handoff log has no unresolved errors ---
    $handoffLog = Get-ChildItem -Path $epicDir -Filter "BUILDER_HANDOFF*.md","S6_HANDOFF*.md" -ErrorAction SilentlyContinue |
                  Sort-Object Name | Select-Object -Last 1
    if ($handoffLog) {
        $handoffText = Get-Content $handoffLog.FullName -Raw -ErrorAction SilentlyContinue
        if ($handoffText -match '(?i)UNRESOLVED ERROR|status:\s*error|status:\s*failed') {
            Write-Error "SHAMT PRE-PUSH TRIPWIRE [BLOCKED]: Builder handoff log has unresolved errors.`n  → Resolve all builder errors before pushing ($($handoffLog.FullName))."
            $failed = $true
        }
    }
}

if ($failed) {
    Write-Error "`nTo bypass in an emergency: `$env:SHAMT_BYPASS_TRIPWIRE=1; git push ..."
    exit 2
}

exit 0
