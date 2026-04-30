#!/usr/bin/env bash
# =============================================================================
# permission-router.sh — Codex PermissionRequest handler
# =============================================================================
# Reads a PermissionRequest JSON from stdin. Auto-approves in-scope edits;
# escalates commits, pushes, and out-of-scope operations to the user.
#
# Codex fires this hook before any tool use that requires permission.
# Exit 0 with JSON on stdout to respond; exit 1 to pass through to Codex default.
# =============================================================================

set -e

INPUT="$(cat)"

tool_name="$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || echo "")"

if [ -z "$tool_name" ]; then
    exit 1
fi

# --- Helpers -------------------------------------------------------------------

active_epic_path() {
    # Find the active epic directory from EPIC_TRACKER.md
    local tracker
    tracker="$(pwd)/.shamt/epics/EPIC_TRACKER.md"
    if [ ! -f "$tracker" ]; then return; fi
    local tag
    tag="$(grep -m1 '^| .* | active |' "$tracker" 2>/dev/null | awk -F'|' '{print $2}' | tr -d ' ' || echo "")"
    if [ -n "$tag" ]; then
        echo "$(pwd)/.shamt/epics/$tag"
    fi
}

# --- Decision logic ------------------------------------------------------------

case "$tool_name" in
    edit|write)
        target="$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('path',d.get('file_path','')))" 2>/dev/null || echo "")"
        epic_path="$(active_epic_path)"
        if [ -n "$epic_path" ] && [ -n "$target" ] && [[ "$target" == "$epic_path"* ]]; then
            printf '{"decision":"approve","reason":"in-scope edit within active epic folder"}\n'
            exit 0
        fi
        # Out-of-scope edit: escalate
        printf '{"decision":"ask_user","reason":"edit outside active epic folder"}\n'
        exit 0
        ;;
    shell|bash)
        command="$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null || echo "")"
        if [[ "$command" == *"git push"* ]]; then
            printf '{"decision":"ask_user","reason":"push requires human review"}\n'
            exit 0
        fi
        if [[ "$command" == *"git commit"* ]]; then
            printf '{"decision":"ask_user","reason":"commit requires human review"}\n'
            exit 0
        fi
        # All other shell commands: default escalate
        printf '{"decision":"ask_user"}\n'
        exit 0
        ;;
    *)
        # Unknown tool: pass through to Codex default
        exit 1
        ;;
esac
