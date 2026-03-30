#!/usr/bin/env bash
# =============================================================================
# Shamt Storage Get Script (Bash — Linux / Mac)
# =============================================================================
# Run this script from the root of your child project.
# Usage: bash .shamt/scripts/storage/get.sh [--dry-run] [--force]
#
# Pulls stored .shamt/ and AI rules files from a dedicated Storage repo
# back into this machine. Overwrites local .shamt/ with the stored version
# (preserving machine-local conf files).
# =============================================================================

set -e

# --- Parse arguments ---------------------------------------------------------

DRY_RUN=false
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --force)   FORCE=true ;;
        *) echo "Unknown argument: $arg"; echo "Usage: get.sh [--dry-run] [--force]"; exit 1 ;;
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
echo "  Shamt Storage Get"
echo "============================================================"
echo "  Project: $PROJECT_NAME"
echo "  From:    $STORAGE_DIR/$PROJECT_NAME"
echo "  To:      $CHILD_ROOT"
echo "============================================================"
echo ""

# --- Pre-pull dirty-tree check -----------------------------------------------

if ! git -C "$STORAGE_DIR" diff --quiet 2>/dev/null || ! git -C "$STORAGE_DIR" diff --cached --quiet 2>/dev/null; then
    echo "  Error: Storage repo has uncommitted changes."
    echo "  Commit or stash changes in: $STORAGE_DIR"
    echo "  Then re-run this script."
    echo ""
    exit 1
fi

# --- Pull latest from storage remote -----------------------------------------

if ! git -C "$STORAGE_DIR" pull 2>/dev/null; then
    echo "  Warning: git pull failed in storage repo — continuing with local state."
    echo "  (This is non-fatal: you may be offline or have no remote configured.)"
    echo ""
fi

# --- Validate project exists in storage --------------------------------------

SOURCE_DIR="$STORAGE_DIR/$PROJECT_NAME"
if [ ! -d "$SOURCE_DIR" ]; then
    echo "  Error: No storage found for project: $PROJECT_NAME"
    echo "  Run store.sh first to save this project's state."
    echo ""
    exit 1
fi

# --- Print what will be overwritten ------------------------------------------

echo "  The following will be overwritten with the stored version:"
echo ""
echo "    .shamt/  (preserving machine-local conf files)"

RULES_FILES=(
    "CLAUDE.md"
    ".github/copilot-instructions.md"
    ".cursorrules"
    ".windsurfrules"
    "GEMINI.md"
)

PRESENT_RULES=()
for rules_file in "${RULES_FILES[@]}"; do
    if [ -f "$CHILD_ROOT/$rules_file" ] && [ -f "$SOURCE_DIR/$rules_file" ]; then
        PRESENT_RULES+=("$rules_file")
    fi
done

if [ ${#PRESENT_RULES[@]} -gt 0 ]; then
    for f in "${PRESENT_RULES[@]}"; do
        echo "    $f"
    done
fi

echo ""

if [ "$DRY_RUN" = "true" ]; then
    echo "------------------------------------------------------------"
    echo "  DRY RUN — no changes were made."
    echo "  Re-run without --dry-run to apply."
    echo ""
    echo "============================================================"
    echo ""
    exit 0
fi

# --- Interactive confirmation (unless --force) --------------------------------

if [ "$FORCE" = "false" ]; then
    read -rp "  Proceed? [y/N]: " _confirm
    _confirm="${_confirm:-N}"
    if [[ ! "$_confirm" =~ ^[Yy]$ ]]; then
        echo "  Get cancelled."
        echo ""
        echo "============================================================"
        echo ""
        exit 0
    fi
    echo ""
fi

# --- Sync storage .shamt/ -> local .shamt/ -----------------------------------

EXCLUDE_ARGS=(
    --exclude="storage_path.conf"
    --exclude="shamt_master_path.conf"
    --exclude="rules_file_path.conf"
    --exclude="import_diff*.md"
)

if command -v rsync &>/dev/null; then
    rsync -a --delete \
        "${EXCLUDE_ARGS[@]}" \
        "$SOURCE_DIR/.shamt/" "$CHILD_SHAMT_DIR/"
else
    # cp fallback — no --delete so local-only files are preserved
    # Conf files are not in source (excluded by store.sh) so they won't be overwritten
    cp -r "$SOURCE_DIR/.shamt/." "$CHILD_SHAMT_DIR/"
    echo "  Note: rsync not available — used cp fallback."
    echo "  Local-only files in .shamt/ were not removed."
    echo ""
fi

echo "  Restored .shamt/ from storage."

# --- Restore AI rules files --------------------------------------------------

RESTORED_RULES=()
for rules_file in "${RULES_FILES[@]}"; do
    src="$SOURCE_DIR/$rules_file"
    if [ -f "$src" ]; then
        dst="$CHILD_ROOT/$rules_file"
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        RESTORED_RULES+=("$rules_file")
    fi
done

if [ ${#RESTORED_RULES[@]} -gt 0 ]; then
    echo ""
    echo "  Restored AI rules files:"
    for f in "${RESTORED_RULES[@]}"; do
        echo "    + $f"
    done
fi

echo ""
echo "============================================================"
echo ""
