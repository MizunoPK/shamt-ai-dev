#!/usr/bin/env bash
# =============================================================================
# Shamt Lite Initialization Script (Bash — Linux / Mac)
# =============================================================================
# Run this script from the root of the project you want to initialize Shamt Lite in.
# Usage:
#   bash /path/to/shamt-ai-dev/.shamt/scripts/initialization/init_lite.sh [project-name] [--host=claude|codex|claude,codex] [--with-mcp]
#
# Default (no flag): writes shamt-lite/ files only — Tier 0 standalone behavior.
# --host=claude:    additionally writes <TARGET>/CLAUDE.md + .claude/{skills,commands,agents}/
# --host=codex:     additionally writes <TARGET>/AGENTS.md + .codex/{agents,config.toml} + .agents/skills/
# --host=claude,codex (or codex,claude): both; AGENTS.md is canonical, CLAUDE.md symlinked
# --with-mcp:       reserved (Tier 3, deferred — currently a no-op)
# =============================================================================

set -e

SHAMT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHAMT_ROOT="$(cd "$SHAMT_SOURCE_DIR/../../.." && pwd)"  # master shamt-ai-dev root
TARGET_DIR="$(pwd)"
LITE_DIR="$TARGET_DIR/shamt-lite"

# --- Parse flags -------------------------------------------------------------

HOST_FLAG=""
WITH_MCP=0
PROJECT_NAME=""
for _arg in "$@"; do
    case "$_arg" in
        --host=*)    HOST_FLAG="${_arg#--host=}" ;;
        --with-mcp)  WITH_MCP=1 ;;
        --*)         echo "Unknown flag: $_arg" >&2; exit 1 ;;
        *)           if [ -z "$PROJECT_NAME" ]; then PROJECT_NAME="$_arg"; fi ;;
    esac
done

WANT_CLAUDE=0
WANT_CODEX=0
if [ -n "$HOST_FLAG" ]; then
    case ",$HOST_FLAG," in
        *,claude,*) WANT_CLAUDE=1 ;;
    esac
    case ",$HOST_FLAG," in
        *,codex,*) WANT_CODEX=1 ;;
    esac
    if [ "$WANT_CLAUDE" -eq 0 ] && [ "$WANT_CODEX" -eq 0 ]; then
        echo "ERROR: --host=$HOST_FLAG is not recognized. Supported: claude, codex, claude,codex" >&2
        exit 1
    fi
fi

if [ "$WITH_MCP" -eq 1 ]; then
    echo "  ⚠  --with-mcp is reserved for a future Tier 3 release; ignoring."
fi

echo ""
echo "============================================================"
echo "  Shamt Lite Initialization"
echo "============================================================"
echo "  Source: $SHAMT_SOURCE_DIR"
echo "  Target: $TARGET_DIR"
if [ -n "$HOST_FLAG" ]; then
    echo "  Host wiring: $HOST_FLAG"
fi
echo "============================================================"
echo ""

# --- Get project name --------------------------------------------------------

if [ -z "$PROJECT_NAME" ]; then
    read -rp "Enter project name: " PROJECT_NAME
    while [ -z "$PROJECT_NAME" ]; do
        echo "  (Project name is required)" >&2
        read -rp "Enter project name: " PROJECT_NAME
    done
fi

CURRENT_DATE=$(date +%Y-%m-%d)

echo ""
echo "  Project Name: $PROJECT_NAME"
echo "  Date: $CURRENT_DATE"
echo ""

# --- Check if directory already exists ---------------------------------------

if [ -d "$LITE_DIR" ]; then
    echo "ERROR: $LITE_DIR already exists."
    echo "Remove it first or run this script from a different directory."
    exit 1
fi

# --- Create directory structure ----------------------------------------------

echo "Creating directory structure..."
mkdir -p "$LITE_DIR/reference"
mkdir -p "$LITE_DIR/templates"
mkdir -p "$LITE_DIR/stories"

# --- Copy and instantiate files ----------------------------------------------

echo "Copying files..."

# Main rules file
sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
    -e "s/{{DATE}}/$CURRENT_DATE/g" \
    "$SHAMT_SOURCE_DIR/SHAMT_LITE.template.md" \
    > "$LITE_DIR/SHAMT_LITE.md"

# Story workflow file (no template variables)
cp "$SHAMT_SOURCE_DIR/story_workflow_lite.template.md" \
   "$LITE_DIR/story_workflow_lite.md"

# CHANGES.md (no template variables)
cp "$SHAMT_SOURCE_DIR/CHANGES.template.md" \
   "$LITE_DIR/CHANGES.md"

# Reference files (no template variables)
cp "$SHAMT_SOURCE_DIR/reference/severity_classification_lite.md" \
   "$LITE_DIR/reference/"

cp "$SHAMT_SOURCE_DIR/reference/validation_exit_criteria_lite.md" \
   "$LITE_DIR/reference/"

cp "$SHAMT_SOURCE_DIR/reference/question_brainstorm_categories_lite.md" \
   "$LITE_DIR/reference/"

# Ticket template (no template variables)
cp "$SHAMT_SOURCE_DIR/templates/ticket.template.md" \
   "$LITE_DIR/templates/ticket.template.md"

# Spec template (no template variables)
cp "$SHAMT_SOURCE_DIR/templates/spec.template.md" \
   "$LITE_DIR/templates/spec.template.md"

sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
    -e "s/{{DATE}}/$CURRENT_DATE/g" \
    "$SHAMT_SOURCE_DIR/templates/architecture_lite.template.md" \
    > "$LITE_DIR/templates/architecture.template.md"

sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
    -e "s/{{DATE}}/$CURRENT_DATE/g" \
    "$SHAMT_SOURCE_DIR/templates/coding_standards_lite.template.md" \
    > "$LITE_DIR/templates/coding_standards.template.md"

# Code review template (no template variables)
cp "$SHAMT_SOURCE_DIR/templates/code_review_lite.template.md" \
   "$LITE_DIR/templates/code_review.template.md"

# Implementation plan template (no template variables)
cp "$SHAMT_SOURCE_DIR/templates/implementation_plan_lite.template.md" \
   "$LITE_DIR/templates/implementation_plan.template.md"

# --- Host wiring (Tier 1+2) --------------------------------------------------

if [ "$WANT_CLAUDE" -eq 1 ] || [ "$WANT_CODEX" -eq 1 ]; then
    echo ""
    echo "------------------------------------------------------------"
    echo "  Host wiring"
    echo "------------------------------------------------------------"
fi

# Determine which rules file is canonical:
# - claude only: CLAUDE.md is canonical
# - codex only: AGENTS.md is canonical
# - both: AGENTS.md is canonical, CLAUDE.md symlinks to it (Unix) or duplicates (no symlink fallback handled below)

CLAUDE_RULES="$TARGET_DIR/CLAUDE.md"
CODEX_RULES="$TARGET_DIR/AGENTS.md"

# Codex: prompt for model resolution, write file, deploy AGENTS.md, run regen
if [ "$WANT_CODEX" -eq 1 ]; then
    echo ""
    echo "Codex needs two model identifiers — these are stored locally and gitignored."
    echo "  FRONTIER_MODEL: deeper-reasoning model (used for design + validation)."
    echo "  DEFAULT_MODEL : cheap-tier model (used for execution + sub-agents)."
    read -rp "FRONTIER_MODEL [o3]: " _fm
    read -rp "DEFAULT_MODEL  [o4-mini]: " _dm
    CODEX_FRONTIER_MODEL="${_fm:-o3}"
    CODEX_DEFAULT_MODEL="${_dm:-o4-mini}"

    mkdir -p "$LITE_DIR/host/codex"
    printf 'FRONTIER_MODEL = "%s"\nDEFAULT_MODEL = "%s"\n' \
        "$CODEX_FRONTIER_MODEL" "$CODEX_DEFAULT_MODEL" \
        > "$LITE_DIR/host/codex/.model_resolution.local.toml"

    # Write a .gitignore entry inside shamt-lite/ to keep the resolution file out of git
    if [ ! -f "$LITE_DIR/.gitignore" ]; then
        printf 'host/codex/.model_resolution.local.toml\n' > "$LITE_DIR/.gitignore"
    elif ! grep -q '.model_resolution.local.toml' "$LITE_DIR/.gitignore"; then
        printf 'host/codex/.model_resolution.local.toml\n' >> "$LITE_DIR/.gitignore"
    fi

    # AGENTS.md = copy of SHAMT_LITE.md (Codex reads it from project root automatically)
    cp "$LITE_DIR/SHAMT_LITE.md" "$CODEX_RULES"
    echo "  ✓ AGENTS.md written ($CODEX_FRONTIER_MODEL / $CODEX_DEFAULT_MODEL)"
fi

# Claude: write CLAUDE.md (or symlink to AGENTS.md if dual-host)
if [ "$WANT_CLAUDE" -eq 1 ]; then
    if [ "$WANT_CODEX" -eq 1 ]; then
        # Dual-host: AGENTS.md is canonical, CLAUDE.md symlinks to it (Unix)
        if [ -f "$CLAUDE_RULES" ]; then
            rm "$CLAUDE_RULES"
        fi
        ln -s "AGENTS.md" "$CLAUDE_RULES"
        echo "  ✓ CLAUDE.md → AGENTS.md symlink created (dual-host)"
    else
        cp "$LITE_DIR/SHAMT_LITE.md" "$CLAUDE_RULES"
        echo "  ✓ CLAUDE.md written"
    fi
fi

# Run regen scripts
if [ "$WANT_CLAUDE" -eq 1 ]; then
    REGEN_CLAUDE="$SHAMT_ROOT/.shamt/scripts/regen/regen-lite-claude.sh"
    if [ -f "$REGEN_CLAUDE" ]; then
        bash "$REGEN_CLAUDE"
    else
        echo "  ⚠  regen-lite-claude.sh not found at $REGEN_CLAUDE — skipping" >&2
    fi
fi

if [ "$WANT_CODEX" -eq 1 ]; then
    REGEN_CODEX="$SHAMT_ROOT/.shamt/scripts/regen/regen-lite-codex.sh"
    if [ -f "$REGEN_CODEX" ]; then
        bash "$REGEN_CODEX"
    else
        echo "  ⚠  regen-lite-codex.sh not found at $REGEN_CODEX — skipping" >&2
    fi
fi

# --- Success message ---------------------------------------------------------

echo ""
echo "============================================================"
echo "  ✓ Shamt Lite initialized successfully!"
echo "============================================================"
echo ""
echo "Files created:"
echo "  shamt-lite/"
echo "  ├── SHAMT_LITE.md                        (5 patterns + token discipline)"
echo "  ├── story_workflow_lite.md               (six-phase story workflow)"
echo "  ├── CHANGES.md                           (Polish-phase upstream candidates)"
echo "  ├── stories/                             (per-story work folders)"
echo "  ├── reference/"
echo "  │   ├── severity_classification_lite.md"
echo "  │   ├── validation_exit_criteria_lite.md"
echo "  │   └── question_brainstorm_categories_lite.md"
echo "  └── templates/"
echo "      ├── ticket.template.md"
echo "      ├── spec.template.md"
echo "      ├── code_review.template.md"
echo "      ├── implementation_plan.template.md"
echo "      ├── architecture.template.md"
echo "      └── coding_standards.template.md"
if [ "$WANT_CLAUDE" -eq 1 ]; then
    echo ""
    echo "  CLAUDE.md                                  (Claude Code rules file)"
    echo "  .claude/skills/shamt-lite-*/SKILL.md       (5 Lite skills)"
    echo "  .claude/commands/lite-*.md                 (5 Lite slash commands)"
    echo "  .claude/agents/shamt-lite-*.md             (validator + builder personas)"
fi
if [ "$WANT_CODEX" -eq 1 ]; then
    echo ""
    echo "  AGENTS.md                                  (Codex rules file)"
    echo "  .agents/skills/shamt-lite-*/SKILL.md       (5 Lite skills)"
    echo "  .codex/agents/shamt-lite-*.toml            (validator + builder personas)"
    echo "  .codex/config.toml                         (8 SHAMT-LITE-PROFILES)"
    echo "  shamt-lite/host/codex/.model_resolution.local.toml (gitignored)"
fi

echo ""
echo "Next steps:"
if [ -z "$HOST_FLAG" ]; then
    echo "  1. Copy shamt-lite/SHAMT_LITE.md to your AI service's rules file"
    echo "     (e.g., CLAUDE.md, .cursorrules, copilot-instructions.md)"
    echo ""
    echo "  2. Start a story: create stories/{slug}/ticket.md and follow"
    echo "     story_workflow_lite.md for the six-phase workflow"
else
    echo "  1. Start a story: create shamt-lite/stories/{slug}/ticket.md and"
    echo "     invoke /lite-story {slug} (or any of /lite-spec, /lite-plan,"
    echo "     /lite-review, /lite-validate)"
    if [ "$WANT_CODEX" -eq 1 ]; then
        echo ""
        echo "  2. Codex profile usage: launch a session with the per-phase profile,"
        echo "     e.g.  codex --profile shamt-lite-spec-validate"
    fi
fi

echo ""
echo "  3. (Optional) Fill out architecture and coding standards templates:"
echo "     • shamt-lite/templates/architecture.template.md → ARCHITECTURE.md"
echo "     • shamt-lite/templates/coding_standards.template.md → CODING_STANDARDS.md"
echo ""
echo "============================================================"
echo ""
