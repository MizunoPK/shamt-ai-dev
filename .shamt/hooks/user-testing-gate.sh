#!/usr/bin/env bash
# PreToolUse (Bash matching git push) — S9 only.
# Blocks git push unless a user-testing artifact exists confirming "ZERO bugs found".

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EPIC_TRACKER="$PROJECT_ROOT/.shamt/epics/EPIC_TRACKER.md"

input="$(cat)"

# Only intercept git push
if ! echo "$input" | grep -qE '"git push|'"'"'git push'; then
    exit 0
fi

# Find active epic
active_epic="$(grep -i "In Progress" "$EPIC_TRACKER" 2>/dev/null \
    | grep -oP '(?<=\| )[A-Z]+-[0-9]+(?= \|)' | head -1 || true)"

if [ -z "$active_epic" ]; then
    exit 0
fi

# Only active in S9
status_file="$PROJECT_ROOT/.shamt/epics/$active_epic/AGENT_STATUS.md"
if [ ! -f "$status_file" ]; then
    exit 0
fi

current_stage="$(grep -oP '(?i)(?:stage:\s*\*{0,2}\s*)S\d+\.P\d+' "$status_file" 2>/dev/null \
    | tail -1 | grep -oP 'S\d+' || true)"

if [ "$current_stage" != "S9" ]; then
    exit 0
fi

# Check for user-testing artifact with "ZERO bugs found"
epic_dir="$PROJECT_ROOT/.shamt/epics/$active_epic"
if ! grep -rqi "ZERO bugs found" "$epic_dir" 2>/dev/null; then
    echo "SHAMT HOOK BLOCKED: git push in S9 requires user-testing confirmation." >&2
    echo "Create a user-testing artifact in $epic_dir containing 'ZERO bugs found'." >&2
    echo "See S9 guide for user-testing artifact format." >&2
    exit 2
fi

exit 0
