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
if echo "$output_text" | grep -qiE 'issue.*found|finding|CRITICAL|HIGH|MEDIUM|LOW:|severity'; then
    active_epic="$(grep -i "In Progress" "$EPIC_TRACKER" 2>/dev/null \
        | grep -oP '(?<=\| )[A-Z]+-[0-9]+(?= \|)' | head -1 || true)"
    if [ -n "$active_epic" ]; then
        veto_file="$PROJECT_ROOT/.shamt/epics/$active_epic/.subagent_confirmation_veto"
        touch "$veto_file"
        echo "SHAMT: Sub-agent confirmation veto written — issues detected in sub-agent output." >&2
    fi
fi

exit 0
