#!/usr/bin/env bash
# PostToolUse (Edit matching *VALIDATION_LOG.md) — Detect validation loop stalls.
# Fires when consecutive_clean has been 0 for SHAMT_STALL_THRESHOLD or more
# consecutive rounds. Emits a PushNotification and writes STALL_ALERT.md.
# Configurable: SHAMT_STALL_THRESHOLD (default 3).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
THRESHOLD="${SHAMT_STALL_THRESHOLD:-3}"

input="$(cat)"

# Only act on validation log edits
if ! echo "$input" | grep -q "VALIDATION_LOG"; then
    exit 0
fi

# Extract file path from PostToolUse JSON (best-effort)
log_path="$(echo "$input" | python3 -c "
import sys, json, re
data = sys.stdin.read()
try:
    obj = json.loads(data)
    path = obj.get('tool_input', {}).get('file_path', '')
    if not path:
        path = obj.get('file_path', '')
    print(path)
except Exception:
    pass
" 2>/dev/null || true)"

if [ -z "$log_path" ] || [ ! -f "$log_path" ]; then
    exit 0
fi

# Count zero-consecutive_clean rounds from the log
# Backward-compat: if no consecutive_clean field found, skip gracefully
stall_count="$(python3 -c "
import re, sys

text = open('$log_path').read()

# Find all consecutive_clean values in order
vals = re.findall(r'\*{0,2}consecutive_clean\*{0,2}:\*{0,2}\s*(\d+)', text)
if not vals:
    # No consecutive_clean fields — old log format; skip gracefully
    print(0)
    sys.exit(0)

# Count trailing zeros
count = 0
for v in reversed(vals):
    if int(v) == 0:
        count += 1
    else:
        break
print(count)
" 2>/dev/null || echo 0)"

if [ "$stall_count" -lt "$THRESHOLD" ]; then
    exit 0
fi

# Stall detected — find active epic
active_epic="$(python3 -c "
import re
tracker = '$PROJECT_ROOT/.shamt/epics/EPIC_TRACKER.md'
try:
    for line in open(tracker):
        m = re.search(r'\|\s*([A-Z]+-\d+)\s*\|[^|]+\|[^|]+\|\s*[Ii]n [Pp]rogress', line)
        if m:
            print(m.group(1).strip())
            break
except Exception:
    pass
" 2>/dev/null || true)"

alert_msg="SHAMT validation loop stalled — consecutive_clean=0 for ${stall_count} rounds. Likely needs human judgment or model escalation."

# Write STALL_ALERT.md if epic found
if [ -n "$active_epic" ]; then
    alert_dir="$PROJECT_ROOT/.shamt/epics/$active_epic"
    status_file="$alert_dir/AGENT_STATUS.md"
    mkdir -p "$alert_dir"

    # Read current model and reasoning effort from AGENT_STATUS.md (best-effort)
    current_model="see AGENT_STATUS.md"
    current_effort="see AGENT_STATUS.md"
    if [ -f "$status_file" ]; then
        parsed_model="$(grep -oP '(?i)model:\s*\*{0,2}\s*\K\S+' "$status_file" 2>/dev/null | head -1 || true)"
        parsed_effort="$(grep -oP '(?i)(?:reasoning|effort):\s*\*{0,2}\s*\K\S+' "$status_file" 2>/dev/null | head -1 || true)"
        [ -n "$parsed_model" ] && current_model="$parsed_model"
        [ -n "$parsed_effort" ] && current_effort="$parsed_effort"
    fi

    # Determine escalation recommendation based on current effort
    case "$current_effort" in
        minimal|low)       next_step="Bump reasoning effort to **medium** (switch to validate-careful profile)." ;;
        medium)            next_step="Bump reasoning effort to **high** (switch to validate-careful profile with higher effort)." ;;
        high)              next_step="Escalate to **diagnose** profile: Opus with xhigh reasoning effort, fresh (cold) context." ;;
        xhigh|"see AGENT_STATUS.md") next_step="Maximum effort already set (or unknown). Consider decomposing the artifact or escalating to human judgment." ;;
        *)                 next_step="Escalate reasoning effort one level, or switch to **diagnose** profile (Opus, xhigh, cold cache)." ;;
    esac

    cat > "$alert_dir/STALL_ALERT.md" <<ALERT
# Validation Loop Stall Alert

**consecutive_clean = 0 for ${stall_count} consecutive rounds** (threshold: ${THRESHOLD})

**Log:** $log_path
**Current model:** $current_model
**Current reasoning effort:** $current_effort

## Recommended Next Step

$next_step

## Escalation Path

| Step | Action | Profile |
|------|--------|---------|
| 1 | Review last round's findings — is the validator being too strict? | (no model change) |
| 2 | Bump reasoning effort one level | validate-careful |
| 3 | Switch to cold-cache root-cause analysis | diagnose |
| 4 | Decompose artifact — validate sub-sections independently | any |
| 5 | Escalate to human judgment | — |

The validation loop skill will read this file on the next round entry and propose escalation via AskUserQuestion (Claude Code) or PR comment template (Codex headless).

Stall threshold is configurable via \`SHAMT_STALL_THRESHOLD\` env var (current: ${THRESHOLD}).
ALERT
fi

# Emit push notification (informational, not blocking)
echo "$alert_msg" >&2

exit 0
