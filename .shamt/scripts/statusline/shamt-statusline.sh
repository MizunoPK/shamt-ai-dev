#!/usr/bin/env bash
# Intentionally no set -e: status renderers must always exit 0 and produce output.
# Critical greps use || true for graceful degradation.
# =============================================================================
# shamt-statusline.sh — Shamt Claude Code status line renderer
# =============================================================================
# Reads .shamt/epics/EPIC_TRACKER.md to find the active epic, then reads that
# epic's AGENT_STATUS.md and emits a compact status string for the Claude Code
# statusLine feature.
#
# Output format (active epic, enhanced SHAMT-45):
#   {EPIC-TAG} | S{N}.P{N} | round {N} | effort: {effort} | stall: {warn|none} | profile: {name}
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
STALL_FILE="$SHAMT_DIR/epics/$ACTIVE_EPIC/STALL_ALERT.md"

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

# Extract reasoning effort (look for "Reasoning: high" or "Effort: high")
EFFORT="$(grep -oP '(?i)(?:reasoning|effort):\s*\*{0,2}\s*\K\S+' "$STATUS_FILE" 2>/dev/null \
    | head -1 || true)"

# Determine stall indicator from STALL_ALERT.md
STALL="none"
if [ -f "$STALL_FILE" ]; then
    STALL="warn"
fi

# Determine active profile:
#   1. Read SHAMT_ACTIVE_PROFILE env var
#   2. Derive from stage as shamt-s{N} if stage is known
PROFILE="${SHAMT_ACTIVE_PROFILE:-}"
if [ -z "$PROFILE" ] && [ -n "$STAGE" ]; then
    STAGE_NUM="$(echo "$STAGE" | grep -oP '(?<=S)\d+' | head -1 || true)"
    [ -n "$STAGE_NUM" ] && PROFILE="shamt-s${STAGE_NUM}"
fi

# Build output
STAGE="${STAGE:-?}"
ROUND="${ROUND:-?}"
EFFORT="${EFFORT:-?}"
PROFILE="${PROFILE:-?}"

OUTPUT="${ACTIVE_EPIC} | ${STAGE} | round ${ROUND}"
[ "$EFFORT" != "?" ] && OUTPUT="${OUTPUT} | effort: ${EFFORT}"
OUTPUT="${OUTPUT} | stall: ${STALL}"
[ "$PROFILE" != "?" ] && OUTPUT="${OUTPUT} | profile: ${PROFILE}"

printf '%s' "$OUTPUT"
