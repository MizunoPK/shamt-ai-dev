#!/usr/bin/env bash
# PreToolUse (Task) — During S6, reject spawned sub-agents that are not
# shamt-builder. S6 builder MUST use the shamt-builder persona.
#
# Only active when the active epic is in S6 (detected from AGENT_STATUS.md).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EPIC_TRACKER="$PROJECT_ROOT/.shamt/epics/EPIC_TRACKER.md"

input="$(cat)"

# Only intercept Task tool calls
if ! echo "$input" | grep -qi '"Task"'; then
    exit 0
fi

# Find active epic
active_epic="$(grep -i "In Progress" "$EPIC_TRACKER" 2>/dev/null \
    | grep -oP '(?<=\| )[A-Z]+-[0-9]+(?= \|)' | head -1 || true)"

if [ -z "$active_epic" ]; then
    exit 0
fi

# Check if active epic is in S6
status_file="$PROJECT_ROOT/.shamt/epics/$active_epic/AGENT_STATUS.md"
if [ ! -f "$status_file" ]; then
    exit 0
fi

current_stage="$(grep -oP '(?i)(?:stage:\s*\*{0,2}\s*)S\d+\.P\d+' "$status_file" 2>/dev/null \
    | tail -1 | grep -oP 'S\d+' || true)"

if [ "$current_stage" != "S6" ]; then
    exit 0
fi

# In S6: check that the Task call uses subagent_type=shamt-builder
if ! echo "$input" | grep -qi 'shamt-builder'; then
    echo "SHAMT HOOK BLOCKED: S6 Task spawn must use subagent_type=shamt-builder." >&2
    echo "The architect-builder pattern is mandatory in S6 (no exceptions)." >&2
    echo "Wrap implementation work in a shamt-builder sub-agent." >&2
    exit 2
fi

# Emit builder_runs_total metric for the allowed spawn (best-effort)
SHAMT_PY="$PROJECT_ROOT/.shamt/mcp/.venv/bin/python3"
[ -x "$SHAMT_PY" ] || SHAMT_PY="python3"
"$SHAMT_PY" -c "
import sys
sys.path.insert(0, '$PROJECT_ROOT/.shamt/mcp/src')
try:
    from shamt_mcp.metrics_append import metrics_append
    metrics_append('builder_runs_total', 1.0, {'shamt_variant': 'cli', 'status': 'spawned'}, epic_id='$active_epic')
except Exception:
    pass
" 2>/dev/null || true

exit 0
