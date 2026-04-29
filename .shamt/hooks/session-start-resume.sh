#!/usr/bin/env bash
# SessionStart — Read RESUME_SNAPSHOT.md for the active epic (if present) and
# inject its content as agent context via stdout.
#
# Claude Code SessionStart hooks can emit text to stdout; the runtime injects
# this as a system message at session start.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SHAMT_DIR="$PROJECT_ROOT/.shamt"
EPIC_TRACKER="$SHAMT_DIR/epics/EPIC_TRACKER.md"

# --- Find active epic ---------------------------------------------------------

active_epic=""
if [ -f "$EPIC_TRACKER" ]; then
    active_epic="$(grep -i "In Progress" "$EPIC_TRACKER" 2>/dev/null \
        | grep -oP '(?<=\| )[A-Z]+-[0-9]+(?= \|)' | head -1 || true)"
fi

if [ -z "$active_epic" ]; then
    exit 0  # No active epic — nothing to inject
fi

SNAPSHOT_FILE="$SHAMT_DIR/epics/$active_epic/RESUME_SNAPSHOT.md"

if [ ! -f "$SNAPSHOT_FILE" ]; then
    exit 0  # No snapshot — hooks not yet written for this epic or clean start
fi

# --- Emit snapshot as agent context ------------------------------------------

echo "=== SHAMT RESUME CONTEXT ==="
echo ""
echo "A prior session was compacted. The following snapshot was captured before compaction:"
echo ""
cat "$SNAPSHOT_FILE"
echo ""
echo "=== END RESUME CONTEXT ==="
echo ""
echo "Resume the active work above from the recorded stage/phase/step."
echo "If AGENT_STATUS.md contains more current information, prefer it over this snapshot."

exit 0
