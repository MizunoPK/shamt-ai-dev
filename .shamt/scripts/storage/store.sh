#!/usr/bin/env bash
# =============================================================================
# Shamt Storage Store Script (Bash — Linux / Mac)
# =============================================================================
# Run this script from the root of your child project.
# Usage: bash .shamt/scripts/storage/store.sh [--dry-run]
#
# Copies your .shamt/ directory and AI rules files to a dedicated Storage
# repo, then commits and pushes. This makes your Shamt state portable across
# machines.
# =============================================================================

set -e

# --- Parse arguments ---------------------------------------------------------

DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        *) echo "Unknown argument: $arg"; echo "Usage: store.sh [--dry-run]"; exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHILD_SHAMT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHILD_ROOT="$(cd "$CHILD_SHAMT_DIR/.." && pwd)"

# --- Read storage path -------------------------------------------------------

STORAGE_PATH_CONF="$CHILD_SHAMT_DIR/storage_path.conf"
if [ ! -f "$STORAGE_PATH_CONF" ]; then
    echo ""
    echo "  Error: .shamt/storage_path.conf not found."
    echo "  Ask your agent: \"What is the path to my Storage repo?\""
    echo "  The agent will ask you for the path and save it to .shamt/storage_path.conf."
    echo ""
    exit 1
fi

STORAGE_DIR="$(tr -d '[:space:]' < "$STORAGE_PATH_CONF")"
if [ ! -d "$STORAGE_DIR" ]; then
    echo ""
    echo "  Error: Storage directory not found: $STORAGE_DIR"
    echo "  Update .shamt/storage_path.conf with the correct path."
    echo ""
    exit 1
fi

# --- Derive project name -----------------------------------------------------

PROJECT_NAME="$(basename "$CHILD_ROOT" | tr ' ' '_')"

echo ""
echo "============================================================"
echo "  Shamt Storage Store"
echo "============================================================"
echo "  Project: $PROJECT_NAME"
echo "  From:    $CHILD_ROOT"
echo "  To:      $STORAGE_DIR/$PROJECT_NAME"
echo "============================================================"
echo ""

# --- Create project dir in storage if needed ---------------------------------

DEST_DIR="$STORAGE_DIR/$PROJECT_NAME"
if [ "$DRY_RUN" = "false" ]; then
    mkdir -p "$DEST_DIR"
fi

# --- Sync .shamt/ to storage -------------------------------------------------

EXCLUDE_ARGS=(
    --exclude="storage_path.conf"
    --exclude="shamt_master_path.conf"
    --exclude="rules_file_path.conf"
    --exclude="import_diff*.md"
)

if [ "$DRY_RUN" = "true" ]; then
    echo "  Would sync .shamt/ to storage:"
    echo "    $CHILD_SHAMT_DIR/ -> $DEST_DIR/.shamt/"
    echo ""
    echo "  Excluded (machine-local conf files):"
    echo "    storage_path.conf, shamt_master_path.conf, rules_file_path.conf, import_diff*.md"
    echo ""
else
    if command -v rsync &>/dev/null; then
        rsync -a --delete \
            "${EXCLUDE_ARGS[@]}" \
            "$CHILD_SHAMT_DIR/" "$DEST_DIR/.shamt/"
    else
        # cp fallback — no --delete; conf files excluded by not copying them explicitly
        mkdir -p "$DEST_DIR/.shamt"
        cp -r "$CHILD_SHAMT_DIR/." "$DEST_DIR/.shamt/"
        # Remove excluded files if they were copied
        rm -f "$DEST_DIR/.shamt/storage_path.conf"
        rm -f "$DEST_DIR/.shamt/shamt_master_path.conf"
        rm -f "$DEST_DIR/.shamt/rules_file_path.conf"
        rm -f "$DEST_DIR/.shamt/import_diff"*.md 2>/dev/null || true
        echo "  Note: rsync not available — used cp fallback."
        echo "  Deleted files in storage will not be removed until rsync is available."
        echo ""
    fi
    echo "  Synced .shamt/ to storage."
fi

# --- Copy AI rules files -----------------------------------------------------

RULES_FILES=(
    "CLAUDE.md"
    ".github/copilot-instructions.md"
    ".cursorrules"
    ".windsurfrules"
    "GEMINI.md"
)

COPIED_RULES=()

for rules_file in "${RULES_FILES[@]}"; do
    src="$CHILD_ROOT/$rules_file"
    if [ -f "$src" ]; then
        if [ "$DRY_RUN" = "true" ]; then
            COPIED_RULES+=("$rules_file")
        else
            dst="$DEST_DIR/$rules_file"
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
            COPIED_RULES+=("$rules_file")
        fi
    fi
done

if [ ${#COPIED_RULES[@]} -gt 0 ]; then
    if [ "$DRY_RUN" = "true" ]; then
        echo "  Would copy AI rules files:"
    else
        echo "  Copied AI rules files:"
    fi
    for f in "${COPIED_RULES[@]}"; do
        echo "    + $f"
    done
    echo ""
fi

if [ "$DRY_RUN" = "true" ]; then
    echo "------------------------------------------------------------"
    echo "  DRY RUN — no changes were made to storage."
    echo "  Re-run without --dry-run to apply."
    echo ""
    echo "============================================================"
    echo ""
    exit 0
fi

# --- Stage changes -----------------------------------------------------------

git -C "$STORAGE_DIR" add "$PROJECT_NAME"

# --- Check if anything was staged --------------------------------------------

if git -C "$STORAGE_DIR" diff --cached --quiet; then
    echo "  Already up to date — nothing to commit."
    echo ""
    echo "============================================================"
    echo ""
    exit 0
fi

# --- Commit ------------------------------------------------------------------

COMMIT_DATE="$(date +%Y-%m-%d)"
git -C "$STORAGE_DIR" commit -m "sync: $PROJECT_NAME — $COMMIT_DATE"
echo "  Committed to storage repo."
echo ""

# --- Push --------------------------------------------------------------------

if ! git -C "$STORAGE_DIR" push; then
    echo ""
    echo "  Warning: push failed. Your changes are committed locally in the storage repo"
    echo "  but were not pushed to the remote. Run 'git push' in: $STORAGE_DIR"
    echo ""
    exit 1
fi

echo "  Pushed to remote."
echo ""
echo "============================================================"
echo ""
