#!/usr/bin/env bash
# =============================================================================
# shamt-statusline.sh — Shamt Claude Code status line renderer
# =============================================================================
# Reads .shamt/epics/EPIC_TRACKER.md to find the active epic, then reads that
# epic's AGENT_STATUS.md and emits a compact status string for the Claude Code
# statusLine feature.
#
# Output format (active epic):
#   {EPIC-TAG} | S{N}.P{N} | round {N} | blocker: {text or "none"}
#
# Output format (no active epic):
#   Shamt | no active epic
#
# Usage: set as the statusLine command in .claude/settings.json
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SHAMT_DIR="$PROJECT_ROOT/.shamt"
EPIC_TRACKER="$SHAMT_DIR/epics/EPIC_TRACKER.md"

# --- Find active epic ---------------------------------------------------------

ACTIVE_EPIC=""
if [ -f "$EPIC_TRACKER" ]; then
    # Look for a line like: | EPIC-007 | ... | In Progress | ...
    ACTIVE_EPIC="$(grep -i "In Progress" "$EPIC_TRACKER" 2>/dev/null \
        | grep -oP '(?<=\| )[A-Z]+-[0-9]+(?= \|)' \
        | head -1 || true)"
fi

if [ -z "$ACTIVE_EPIC" ]; then
    printf 'Shamt | no active epic'
    exit 0
fi

# --- Read AGENT_STATUS.md for that epic ---------------------------------------

STATUS_FILE="$SHAMT_DIR/epics/$ACTIVE_EPIC/AGENT_STATUS.md"

if [ ! -f "$STATUS_FILE" ]; then
    printf '%s | status unknown' "$ACTIVE_EPIC"
    exit 0
fi

# Extract stage (look for lines like "Stage: S2.P1" or "**Stage:** S2.P1")
STAGE="$(grep -oP '(?i)(?:stage:\s*\*{0,2}\s*)S\d+\.P\d+' "$STATUS_FILE" 2>/dev/null \
    | tail -1 | grep -oP 'S\d+\.P\d+' || true)"

# Extract round (look for "round N" or "consecutive_clean: N" or "Round N")
ROUND="$(grep -oP '(?i)(?:round|consecutive_clean):\s*\*{0,2}\s*\K[0-9]+' "$STATUS_FILE" 2>/dev/null \
    | tail -1 || true)"

# Extract blocker (look for "Blocker: ..." or "Blocked: ...")
BLOCKER="$(grep -oP '(?i)(?:blocked?|blocker):\s*\*{0,2}\s*\K.+' "$STATUS_FILE" 2>/dev/null \
    | head -1 | sed 's/\*//g; s/^ *//; s/ *$//' || true)"

# Build output
STAGE="${STAGE:-?}"
ROUND="${ROUND:-?}"
BLOCKER="${BLOCKER:-none}"
# Trim blocker if too long
if [ "${#BLOCKER}" -gt 40 ]; then
    BLOCKER="${BLOCKER:0:37}..."
fi

printf '%s | %s | round %s | blocker: %s' "$ACTIVE_EPIC" "$STAGE" "$ROUND" "$BLOCKER"
