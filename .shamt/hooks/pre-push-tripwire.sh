#!/usr/bin/env bash
# PreToolUse (Bash matching git push) — Final guard before changes leave the worktree.
# Verifies three conditions before allowing a push:
#   (a) .shamt/audit/last_run.json is fresh (≤SHAMT_AUDIT_MAX_AGE_DAYS) and clean
#   (b) Active epic's validation log shows consecutive_clean ≥ 1
#   (c) Builder handoff log (if S6 just completed) shows no unresolved errors
# Emergency bypass: set SHAMT_BYPASS_TRIPWIRE=1 (a confirmation prompt is shown).
# Configurable: SHAMT_AUDIT_MAX_AGE_DAYS (default 7).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MAX_AGE_DAYS="${SHAMT_AUDIT_MAX_AGE_DAYS:-7}"

input="$(cat)"

# Only intercept git push invocations
if ! echo "$input" | grep -qE '"git push|git push '; then
    # Also check command field in JSON
    command_val="$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('tool_input', {}).get('command', d.get('command', '')))
except Exception:
    pass
" 2>/dev/null || true)"
    if ! echo "$command_val" | grep -qE '^git push'; then
        exit 0
    fi
fi

# --- Emergency bypass ---
if [ "${SHAMT_BYPASS_TRIPWIRE:-0}" = "1" ]; then
    echo "SHAMT PRE-PUSH TRIPWIRE: Bypass active (SHAMT_BYPASS_TRIPWIRE=1). Proceeding without checks." >&2
    exit 0
fi

FAILED=0

# --- Check (a): Audit freshness and cleanliness ---
LAST_RUN="$PROJECT_ROOT/.shamt/audit/last_run.json"
if [ ! -f "$LAST_RUN" ]; then
    echo "SHAMT PRE-PUSH TRIPWIRE [BLOCKED]: No audit record found at .shamt/audit/last_run.json" >&2
    echo "  → Run a full guide audit (3 consecutive clean rounds) before pushing." >&2
    FAILED=1
else
    exit_met="$(python3 -c "
import json
d = json.load(open('$LAST_RUN'))
print(str(d.get('exit_criterion_met', False)).lower())
" 2>/dev/null || echo "false")"
    if [ "$exit_met" != "true" ]; then
        echo "SHAMT PRE-PUSH TRIPWIRE [BLOCKED]: Last audit did not meet exit criteria." >&2
        echo "  → Run a full guide audit before pushing." >&2
        FAILED=1
    fi

    timestamp="$(python3 -c "
import json
d = json.load(open('$LAST_RUN'))
print(d.get('timestamp', ''))
" 2>/dev/null || echo "")"
    if [ -n "$timestamp" ]; then
        age_days="$(python3 -c "
from datetime import datetime, timezone
ts = '$timestamp'
try:
    t = datetime.fromisoformat(ts.replace('Z', '+00:00'))
    print((datetime.now(timezone.utc) - t).days)
except Exception:
    print(9999)
" 2>/dev/null || echo "9999")"
        if [ "$age_days" -gt "$MAX_AGE_DAYS" ]; then
            echo "SHAMT PRE-PUSH TRIPWIRE [BLOCKED]: Audit is ${age_days} days old (max ${MAX_AGE_DAYS})." >&2
            echo "  → Run a fresh guide audit before pushing." >&2
            FAILED=1
        fi
    fi
fi

# --- Check (b): Active epic validation log shows consecutive_clean ≥ 1 ---
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

if [ -n "$active_epic" ]; then
    epic_dir="$PROJECT_ROOT/.shamt/epics/$active_epic"
    # Find the most recent validation log
    val_log="$(find "$epic_dir" -name "*VALIDATION_LOG.md" 2>/dev/null | sort | tail -1 || true)"
    if [ -n "$val_log" ] && [ -f "$val_log" ]; then
        last_clean="$(python3 -c "
import re
text = open('$val_log').read()
vals = re.findall(r'\*{0,2}consecutive_clean\*{0,2}:\*{0,2}\s*(\d+)', text)
if vals:
    print(int(vals[-1]))
else:
    print(-1)
" 2>/dev/null || echo "-1")"
        if [ "$last_clean" = "0" ]; then
            echo "SHAMT PRE-PUSH TRIPWIRE [BLOCKED]: Validation log for $active_epic shows consecutive_clean=0." >&2
            echo "  → Complete the validation loop (reach consecutive_clean ≥ 1) before pushing." >&2
            FAILED=1
        fi
        # last_clean=-1 means no consecutive_clean field (old format) — pass through
    fi
fi

# --- Check (c): Builder handoff log shows no unresolved errors ---
if [ -n "$active_epic" ]; then
    epic_dir="$PROJECT_ROOT/.shamt/epics/$active_epic"
    handoff_log="$(find "$epic_dir" -name "BUILDER_HANDOFF*.md" -o -name "S6_HANDOFF*.md" 2>/dev/null | sort | tail -1 || true)"
    if [ -n "$handoff_log" ] && [ -f "$handoff_log" ]; then
        if grep -qiE 'UNRESOLVED ERROR|status:\s*error|status:\s*failed' "$handoff_log" 2>/dev/null; then
            echo "SHAMT PRE-PUSH TRIPWIRE [BLOCKED]: Builder handoff log has unresolved errors." >&2
            echo "  → Resolve all builder errors before pushing ($handoff_log)." >&2
            FAILED=1
        fi
    fi
fi

if [ "$FAILED" = "1" ]; then
    echo "" >&2
    echo "To bypass in an emergency: SHAMT_BYPASS_TRIPWIRE=1 git push ..." >&2
    exit 2
fi

exit 0
