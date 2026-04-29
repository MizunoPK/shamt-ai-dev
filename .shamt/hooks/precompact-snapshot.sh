#!/usr/bin/env bash
# PreCompact — Dump epic / stage / phase / step / blockers / open validation
# counters to .shamt/epics/<active>/RESUME_SNAPSHOT.md before context compaction.

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
    exit 0  # No active epic — nothing to snapshot
fi

# --- Read AGENT_STATUS.md -----------------------------------------------------

STATUS_FILE="$SHAMT_DIR/epics/$active_epic/AGENT_STATUS.md"
SNAPSHOT_FILE="$SHAMT_DIR/epics/$active_epic/RESUME_SNAPSHOT.md"

stage=""
phase=""
step=""
blocker=""
consecutive_clean=""

if [ -f "$STATUS_FILE" ]; then
    stage="$(grep -oP '(?i)(?:stage:\s*\*{0,2}\s*)S\d+\.P\d+' "$STATUS_FILE" 2>/dev/null \
        | tail -1 | grep -oP 'S\d+' || true)"
    phase="$(grep -oP '(?i)(?:stage:\s*\*{0,2}\s*)S\d+\.\KP\d+' "$STATUS_FILE" 2>/dev/null \
        | tail -1 || true)"
    blocker="$(grep -oP '(?i)(?:blocked?|blocker):\s*\*{0,2}\s*\K.+' "$STATUS_FILE" 2>/dev/null \
        | head -1 | sed 's/\*//g; s/^ *//; s/ *$//' || true)"
    consecutive_clean="$(grep -oP '(?i)consecutive_clean:\s*\K[0-9]+' "$STATUS_FILE" 2>/dev/null \
        | tail -1 || true)"
    step="$(grep -oP '(?i)step:\s*\K.+' "$STATUS_FILE" 2>/dev/null \
        | head -1 | sed 's/^ *//; s/ *$//' || true)"
fi

# --- Capture recent file edits (last 3) from git log --------------------------

recent_edits="$(git -C "$PROJECT_ROOT" log --oneline --diff-filter=M --name-only -5 --pretty=format: 2>/dev/null \
    | grep -v '^$' | head -3 | tr '\n' ' ' || echo "(unavailable)")"

# --- Write RESUME_SNAPSHOT.md -------------------------------------------------

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$SNAPSHOT_FILE" <<EOF
# RESUME_SNAPSHOT

**Written by:** precompact-snapshot.sh hook
**Timestamp:** $timestamp
**Trigger:** PreCompact (auto-compaction)

---

## Active Work

| Field | Value |
|---|---|
| Epic | $active_epic |
| Stage | ${stage:-unknown} |
| Phase | ${phase:-unknown} |
| Step | ${step:-unknown} |
| Blocker | ${blocker:-none} |

## Validation Loop State

| Field | Value |
|---|---|
| consecutive_clean | ${consecutive_clean:-unknown} |

## Recent File Edits

${recent_edits}

---

*This snapshot was written automatically before context compaction. The SessionStart hook reads it to restore context.*
EOF

exit 0
