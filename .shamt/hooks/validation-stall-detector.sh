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
    mkdir -p "$alert_dir"
    cat > "$alert_dir/STALL_ALERT.md" <<ALERT
# Validation Loop Stall Alert

**consecutive_clean = 0 for ${stall_count} consecutive rounds** (threshold: ${THRESHOLD})

**Log:** $log_path

## Recommended Actions

1. **Review the last round's findings** — are the issues genuinely hard, or is the validator being too strict?
2. **Escalate reasoning effort** — if using Haiku/Sonnet, switch to Opus for the next round.
3. **Decompose the artifact** — validate sections independently if the artifact is large.
4. **Human judgment** — if the loop has been stuck for many rounds, bring in a human reviewer.

Stall threshold is configurable via \`SHAMT_STALL_THRESHOLD\` env var (current: ${THRESHOLD}).
ALERT
fi

# Emit push notification (informational, not blocking)
echo "$alert_msg" >&2

exit 0
