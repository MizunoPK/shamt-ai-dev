#!/usr/bin/env bash
# UserPromptSubmit / PreToolUse (export script) — Block export if last audit
# is stale (>7 days) or if exit_criterion_met is false.
# Stale threshold configurable via SHAMT_AUDIT_MAX_AGE_DAYS env var.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LAST_RUN="$PROJECT_ROOT/.shamt/audit/last_run.json"
MAX_AGE_DAYS="${SHAMT_AUDIT_MAX_AGE_DAYS:-7}"

input="$(cat)"

# Only intercept if this is an export invocation
if ! echo "$input" | grep -qiE 'export\.sh|run export|export to master'; then
    exit 0
fi

if [ ! -f "$LAST_RUN" ]; then
    echo "SHAMT HOOK BLOCKED: No audit record found at .shamt/audit/last_run.json" >&2
    echo "Run a full guide audit (3 consecutive clean rounds) before exporting." >&2
    exit 2
fi

# Check exit_criterion_met
exit_met="$(python3 -c "import json; d=json.load(open('$LAST_RUN')); print(d.get('exit_criterion_met', False))" 2>/dev/null || echo "false")"
if [ "$exit_met" != "True" ] && [ "$exit_met" != "true" ]; then
    echo "SHAMT HOOK BLOCKED: Last audit did not meet exit criteria." >&2
    echo "Run a full guide audit (3 consecutive clean rounds) before exporting." >&2
    exit 2
fi

# Check staleness
timestamp="$(python3 -c "import json; d=json.load(open('$LAST_RUN')); print(d.get('timestamp',''))" 2>/dev/null || echo "")"
if [ -n "$timestamp" ]; then
    age_days="$(python3 -c "
from datetime import datetime, timezone
import sys
ts = '$timestamp'
try:
    audit_time = datetime.fromisoformat(ts.replace('Z','+00:00'))
    now = datetime.now(timezone.utc)
    print((now - audit_time).days)
except Exception:
    print(9999)
" 2>/dev/null || echo "9999")"
    if [ "$age_days" -gt "$MAX_AGE_DAYS" ]; then
        echo "SHAMT HOOK BLOCKED: Last audit is ${age_days} days old (max ${MAX_AGE_DAYS})." >&2
        echo "Run a fresh guide audit before exporting." >&2
        exit 2
    fi
fi

exit 0
