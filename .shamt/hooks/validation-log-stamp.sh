#!/usr/bin/env bash
# PostToolUse (Edit matching *VALIDATION_LOG.md) — Append timestamp and model
# used to the validation log after each edit.
# Claude Code passes the tool result JSON on stdin.

set -euo pipefail

input="$(cat)"

# Extract the file path from the tool result (best-effort JSON parse)
log_path="$(echo "$input" | python3 -c "
import sys, json, re
data = sys.stdin.read()
try:
    obj = json.loads(data)
    # PostToolUse result contains the file_path in the tool_input
    path = obj.get('tool_input', {}).get('file_path', '')
    if not path:
        path = obj.get('file_path', '')
    print(path)
except Exception:
    m = re.search(r'VALIDATION_LOG\.md', data)
    if m:
        print('(unknown)')
" 2>/dev/null || true)"

if [ -z "$log_path" ] || [[ "$log_path" != *"VALIDATION_LOG"* ]]; then
    exit 0
fi

# Resolve absolute path
if [[ "$log_path" != /* ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    log_path="$PROJECT_ROOT/$log_path"
fi

if [ ! -f "$log_path" ]; then
    exit 0
fi

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
printf '\n<!-- stamp: %s -->\n' "$timestamp" >> "$log_path"

# Emit validation_round metric (best-effort — never blocks the hook)
SCRIPT_DIR2="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT2="$(cd "$SCRIPT_DIR2/../.." && pwd)"
SHAMT_PY="$PROJECT_ROOT2/.shamt/mcp/.venv/bin/python3"
[ -x "$SHAMT_PY" ] || SHAMT_PY="python3"
"$SHAMT_PY" -c "
import sys
sys.path.insert(0, '$PROJECT_ROOT2/.shamt/mcp/src')
try:
    from shamt_mcp.metrics_append import metrics_append
    metrics_append('validation_round', 1.0, {})
except Exception:
    pass
" 2>/dev/null || true

exit 0
