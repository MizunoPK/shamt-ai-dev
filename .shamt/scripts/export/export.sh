#!/usr/bin/env bash
# =============================================================================
# Shamt Export Script (Bash — Linux / Mac)
# =============================================================================
# Run this script from the root of your child project.
# Usage: bash .shamt/scripts/export/export.sh
#
# Copies all modified shared files (guides/ and scripts/) from this project
# to the local shamt-ai-dev master repo. Open a PR after running.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHILD_SHAMT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHILD_ROOT="$(cd "$CHILD_SHAMT_DIR/.." && pwd)"

# --- Read master path --------------------------------------------------------

MASTER_PATH_CONF="$CHILD_SHAMT_DIR/shamt_master_path.conf"
if [ ! -f "$MASTER_PATH_CONF" ]; then
    echo ""
    echo "  Error: .shamt/shamt_master_path.conf not found."
    echo "  Run the init script to set up the master path."
    echo ""
    exit 1
fi

MASTER_DIR="$(tr -d '[:space:]' < "$MASTER_PATH_CONF")"
if [ ! -d "$MASTER_DIR" ]; then
    echo ""
    echo "  Error: Master directory not found: $MASTER_DIR"
    echo "  Update .shamt/shamt_master_path.conf with the correct path."
    echo ""
    exit 1
fi

MASTER_SHAMT_DIR="$MASTER_DIR/.shamt"

echo ""
echo "============================================================"
echo "  Shamt Export"
echo "============================================================"
echo "  From: $CHILD_ROOT"
echo "  To:   $MASTER_DIR"
echo "============================================================"
echo ""

# --- Compare and copy changed files ------------------------------------------

EXPORTED=()

export_dir() {
    local source_dir="$1"  # child's guides/ or scripts/
    local master_dir="$2"  # master's guides/ or scripts/
    local rel_prefix="$3"  # e.g. "guides" or "scripts"

    [ -d "$source_dir" ] || return 0

    while IFS= read -r -d '' src_file; do
        local rel_path="${src_file#"$CHILD_SHAMT_DIR/"}"

        # Never export audit outputs — child-specific, not relevant to master
        if [[ "$rel_path" == "guides/audit/outputs/"* ]]; then
            continue
        fi

        local dst_file="$MASTER_SHAMT_DIR/$rel_path"

        if [ ! -f "$dst_file" ]; then
            # New file in child — copy to master
            mkdir -p "$(dirname "$dst_file")"
            cp "$src_file" "$dst_file"
            EXPORTED+=("$rel_path (new)")
        elif ! diff -q "$src_file" "$dst_file" > /dev/null 2>&1; then
            # Files differ — copy to master
            cp "$src_file" "$dst_file"
            EXPORTED+=("$rel_path")
        fi
    done < <(find "$source_dir" -type f -print0 | sort -z)
}

export_dir "$CHILD_SHAMT_DIR/guides" "$MASTER_SHAMT_DIR/guides" "guides"
export_dir "$CHILD_SHAMT_DIR/scripts" "$MASTER_SHAMT_DIR/scripts" "scripts"

# --- Summary -----------------------------------------------------------------

if [ ${#EXPORTED[@]} -eq 0 ]; then
    echo "  No differences found. Child is in sync with master."
    echo ""
    echo "============================================================"
    echo ""
    exit 0
fi

echo "  Exported ${#EXPORTED[@]} file(s) to master:"
echo ""
for f in "${EXPORTED[@]}"; do
    echo "    + $f"
done
echo ""

# --- Next steps --------------------------------------------------------------

echo "------------------------------------------------------------"
echo "  Next steps"
echo "------------------------------------------------------------"
echo ""
echo "  1. Go to the shamt-ai-dev directory:"
echo "       cd $MASTER_DIR"
echo ""
echo "  2. Create a new branch and commit:"
echo "       git checkout -b feat/child-sync-$(date +%Y%m%d)"
echo "       git add .shamt/guides/ .shamt/scripts/"
echo "       git commit -m \"sync: guide/script improvements from child project\""
echo ""
echo "  3. Open a PR against main."
echo ""
echo "  Tip: Include content from .shamt/CHANGES.md in the PR description"
echo "  to give reviewers context on what changed and why."
echo ""
echo "============================================================"
echo ""
