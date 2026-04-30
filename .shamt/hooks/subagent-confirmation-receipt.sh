#!/usr/bin/env bash
# SubagentStop — When a confirming sub-agent reports issues, write a veto flag
# that validation_round() MCP tool will detect and consume.
#
# The primary agent's call to shamt.validation_round() checks for this flag
# before incrementing consecutive_clean. If the flag is present, the counter
# is not incremented and the flag is deleted.
#
# The hook receives the sub-agent's output. It writes a veto if it detects
# the sub-agent found one or more issues (i.e., output does NOT contain
# a clean-confirmation phrase).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EPIC_TRACKER="$PROJECT_ROOT/.shamt/epics/EPIC_TRACKER.md"

input="$(cat)"

# Extract sub-agent output text (best-effort)
output_text="$(echo "$input" | python3 -c "
import sys, json
data = sys.stdin.read()
try:
    obj = json.loads(data)
    # SubagentStop passes the agent result
    out = obj.get('output', obj.get('result', data))
    if isinstance(out, dict):
        out = out.get('output', str(out))
    print(str(out)[:2000])
except Exception:
    print(data[:2000])
" 2>/dev/null || echo "$input")"

# Clean-confirmation phrases — if any match, no veto
if echo "$output_text" | grep -qiE 'zero issues|0 issues|confirmed.*clean|CLEAN CONFIRMATION|no issues found'; then
    exit 0
fi

# Issue-report phrases — if any match, write veto
confirmer_status="clean"
if echo "$output_text" | grep -qiE 'issue.*found|finding|CRITICAL|HIGH|MEDIUM|LOW:|severity'; then
    confirmer_status="issues_found"
    active_epic="$(grep -i "In Progress" "$EPIC_TRACKER" 2>/dev/null \
        | grep -oP '(?<=\| )[A-Z]+-[0-9]+(?= \|)' | head -1 || true)"
    if [ -n "$active_epic" ]; then
        veto_file="$PROJECT_ROOT/.shamt/epics/$active_epic/.subagent_confirmation_veto"
        touch "$veto_file"
        echo "SHAMT: Sub-agent confirmation veto written — issues detected in sub-agent output." >&2
    fi
fi

# Emit confirmer_run metric (best-effort — never blocks the hook)
SHAMT_PY="$PROJECT_ROOT/.shamt/mcp/.venv/bin/python3"
[ -x "$SHAMT_PY" ] || SHAMT_PY="python3"
"$SHAMT_PY" -c "
import sys
sys.path.insert(0, '$PROJECT_ROOT/.shamt/mcp/src')
try:
    from shamt_mcp.metrics_append import metrics_append
    epic_id = '$active_epic' if '$active_epic' else None
    metrics_append('confirmer_run', 1.0, {'shamt_persona': 'shamt-validator', 'model': 'haiku'}, epic_id=epic_id)
except Exception:
    pass
" 2>/dev/null || true

exit 0
