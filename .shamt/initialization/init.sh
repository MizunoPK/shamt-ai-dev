#!/usr/bin/env bash
# =============================================================================
# Shamt Initialization Script (Bash — Linux / Mac)
# =============================================================================
# Run this script from the root of the project you want to initialize Shamt in.
# Usage: bash /path/to/shamt-ai-dev/.shamt/initialization/init.sh
# =============================================================================

set -e

SHAMT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_DIR="$(pwd)"
SHAMT_DIR="$TARGET_DIR/.shamt"

echo ""
echo "============================================================"
echo "  Shamt Initialization"
echo "============================================================"
echo "  Source: $SHAMT_SOURCE_DIR"
echo "  Target: $TARGET_DIR"
echo "============================================================"
echo ""

# --- Helpers -----------------------------------------------------------------

prompt() {
    local question="$1"
    local default="$2"
    local answer
    if [ -n "$default" ]; then
        read -rp "$question [$default]: " answer
        echo "${answer:-$default}"
    else
        read -rp "$question: " answer
        echo "$answer"
    fi
}

prompt_required() {
    local question="$1"
    local answer=""
    while [ -z "$answer" ]; do
        read -rp "$question: " answer
        if [ -z "$answer" ]; then
            echo "  (This field is required)" >&2
        fi
    done
    echo "$answer"
}

separator() {
    echo ""
    echo "------------------------------------------------------------"
    echo "  $1"
    echo "------------------------------------------------------------"
}

# --- AI Service Selection ----------------------------------------------------

separator "AI Service"
echo "Which AI coding assistant will you use with this project?"
echo ""
echo "  1) Claude Code (Anthropic)       → CLAUDE.md at project root"
echo "  2) GitHub Copilot                → .github/copilot-instructions.md"
echo "  3) Cursor                        → .cursorrules at project root"
echo "  4) Windsurf (Codeium)            → .windsurfrules at project root"
echo "  5) Amazon Q Developer            → (setup TBD)"
echo "  6) Other                         → you will specify"
echo ""
read -rp "Enter choice [1]: " ai_choice
ai_choice="${ai_choice:-1}"

case "$ai_choice" in
    1)
        AI_SERVICE="claude_code"
        RULES_FILE_NAME="CLAUDE.md"
        RULES_FILE_DIR="$TARGET_DIR"
        ;;
    2)
        AI_SERVICE="github_copilot"
        RULES_FILE_NAME="copilot-instructions.md"
        RULES_FILE_DIR="$TARGET_DIR/.github"
        ;;
    3)
        AI_SERVICE="cursor"
        RULES_FILE_NAME=".cursorrules"
        RULES_FILE_DIR="$TARGET_DIR"
        ;;
    4)
        AI_SERVICE="windsurf"
        RULES_FILE_NAME=".windsurfrules"
        RULES_FILE_DIR="$TARGET_DIR"
        ;;
    5)
        AI_SERVICE="amazon_q"
        RULES_FILE_NAME="TBD"
        RULES_FILE_DIR="$TARGET_DIR"
        echo ""
        echo "  ⚠  Amazon Q rules file convention is not yet confirmed."
        echo "  The agent will help you determine the correct setup."
        ;;
    6)
        AI_SERVICE="other"
        echo ""
        RULES_FILE_NAME=$(prompt_required "  Rules file name (e.g. .myrules)")
        RULES_FILE_LOCATION=$(prompt "  Rules file location relative to project root" ".")
        if [ "$RULES_FILE_LOCATION" = "." ]; then
            RULES_FILE_DIR="$TARGET_DIR"
        else
            RULES_FILE_DIR="$TARGET_DIR/$RULES_FILE_LOCATION"
        fi
        ;;
    *)
        echo "Invalid choice. Defaulting to Claude Code."
        AI_SERVICE="claude_code"
        RULES_FILE_NAME="CLAUDE.md"
        RULES_FILE_DIR="$TARGET_DIR"
        ;;
esac

echo "  ✓ AI service: $AI_SERVICE"

# --- Project Details ---------------------------------------------------------

separator "Project Details"

PROJECT_NAME=$(prompt_required "  Project name")
EPIC_TAG=$(prompt "  Epic tag (identifier for epics, e.g. SHAMT, MYPROJ)" "SHAMT")
EPIC_TAG=$(echo "$EPIC_TAG" | tr '[:lower:]' '[:upper:]')
SHAMT_NAME=$(prompt "  Agent name (your version of Shamt)" "Shamt")
STARTING_EPIC=$(prompt "  Starting epic number" "1")

# --- Git Configuration -------------------------------------------------------

separator "Git Configuration"

echo "Which git platform will you use?"
echo "  1) GitHub"
echo "  2) GitLab"
echo "  3) Other / none"
read -rp "Enter choice [1]: " git_choice
git_choice="${git_choice:-1}"

case "$git_choice" in
    2)  GIT_PLATFORM="gitlab" ;;
    3)  GIT_PLATFORM="other" ;;
    *)  GIT_PLATFORM="github" ;;
esac

DEFAULT_BRANCH=$(prompt "  Default/main branch name" "main")

echo "  ✓ Git platform: $GIT_PLATFORM"
echo "  ✓ Default branch: $DEFAULT_BRANCH"

# --- Confirmation ------------------------------------------------------------

separator "Review"
echo "  Project name:      $PROJECT_NAME"
echo "  Epic tag:          $EPIC_TAG"
echo "  Agent name:        $SHAMT_NAME"
echo "  Starting epic #:   $STARTING_EPIC"
echo "  AI service:        $AI_SERVICE"
echo "  Rules file:        $RULES_FILE_NAME"
echo "  Rules file path:   $RULES_FILE_DIR/"
echo "  Git platform:      $GIT_PLATFORM"
echo "  Default branch:    $DEFAULT_BRANCH"
echo "  Epic directory:    .shamt/epics/"
echo ""
read -rp "Proceed with initialization? [Y/n]: " confirm
confirm="${confirm:-Y}"
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Initialization cancelled."
    exit 0
fi

# --- Create Folder Structure -------------------------------------------------

separator "Creating folder structure"

mkdir -p "$SHAMT_DIR/guides"
mkdir -p "$SHAMT_DIR/initialization"
mkdir -p "$SHAMT_DIR/epics/requests"
mkdir -p "$SHAMT_DIR/epics/done"
mkdir -p "$SHAMT_DIR/changelogs/outbound"
mkdir -p "$SHAMT_DIR/changelogs/unapplied_external_changes"
mkdir -p "$SHAMT_DIR/changelogs/applied_external_changes"
mkdir -p "$RULES_FILE_DIR"

echo "  ✓ .shamt/ structure created"

# --- Copy Guides -------------------------------------------------------------

separator "Copying guides"

cp -r "$SHAMT_SOURCE_DIR/.shamt/guides/"* "$SHAMT_DIR/guides/"
cp -r "$SHAMT_SOURCE_DIR/.shamt/initialization/"* "$SHAMT_DIR/initialization/"
echo "  ✓ Guides and initialization files copied"

# --- Copy and Configure Rules File -------------------------------------------

separator "Configuring rules file"

RULES_TEMPLATE="$SHAMT_DIR/initialization/RULES_FILE.template.md"
RULES_DEST="$RULES_FILE_DIR/$RULES_FILE_NAME"

if [ -f "$RULES_DEST" ]; then
    echo "  ⚠  $RULES_FILE_NAME already exists at $RULES_FILE_DIR/"
    read -rp "  Overwrite? [y/N]: " overwrite
    overwrite="${overwrite:-N}"
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "  Skipping rules file — agent will incorporate existing file."
        RULES_FILE_EXISTS="true"
    else
        RULES_FILE_EXISTS="false"
    fi
else
    RULES_FILE_EXISTS="false"
fi

if [ "$RULES_FILE_EXISTS" = "false" ]; then
    cp "$RULES_TEMPLATE" "$RULES_DEST"
    echo "  ✓ Rules file written to $RULES_DEST"
fi

# --- Apply Substitutions to Templates ----------------------------------------

separator "Applying configuration"

do_substitutions() {
    local file="$1"
    sed -i \
        -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
        -e "s/{{EPIC_TAG}}/$EPIC_TAG/g" \
        -e "s/{{SHAMT_NAME}}/$SHAMT_NAME/g" \
        -e "s/{{GIT_PLATFORM}}/$GIT_PLATFORM/g" \
        -e "s/{{DEFAULT_BRANCH}}/$DEFAULT_BRANCH/g" \
        "$file"
}

# Apply substitutions to guides
find "$SHAMT_DIR/guides" -name "*.md" -exec sed -i \
    -e "s/{{EPIC_TAG}}/$EPIC_TAG/g" \
    -e "s/SHAMT-{N}/$EPIC_TAG-{N}/g" \
    -e "s/{{DEFAULT_BRANCH}}/$DEFAULT_BRANCH/g" \
    -e "s/{{GIT_PLATFORM}}/$GIT_PLATFORM/g" \
    {} +

# Apply to rules file
if [ "$RULES_FILE_EXISTS" = "false" ]; then
    do_substitutions "$RULES_DEST"
fi

# Copy and configure EPIC_TRACKER
EPIC_TRACKER_TEMPLATE="$SHAMT_DIR/initialization/EPIC_TRACKER.template.md"
EPIC_TRACKER_DEST="$SHAMT_DIR/epics/EPIC_TRACKER.md"
cp "$EPIC_TRACKER_TEMPLATE" "$EPIC_TRACKER_DEST"
do_substitutions "$EPIC_TRACKER_DEST"
# Set starting epic number
sed -i "s/$EPIC_TAG-1/$EPIC_TAG-$STARTING_EPIC/g" "$EPIC_TRACKER_DEST"

# Copy CHANGELOG_INDEX templates
cat > "$SHAMT_DIR/changelogs/applied_external_changes/CHANGELOG_INDEX.md" << EOF
# Applied External Changes Index

**Current Version:** v0000 (no changelogs applied yet)

| Version | Date Applied | Summary |
|---------|-------------|---------|
| — | — | No changelogs applied yet |
EOF

cat > "$SHAMT_DIR/changelogs/outbound/CHANGELOG_INDEX.md" << EOF
# Outbound Changelog Index

| Entry ID | Date | Summary | Submitted to Master |
|----------|------|---------|---------------------|
| — | — | No changelog entries yet | — |
EOF

echo "  ✓ Configuration applied"

# --- Write init_config.md Handoff File ---------------------------------------

separator "Writing handoff file for agent"

NEEDS_AI_DISCOVERY="false"
if [ "$AI_SERVICE" = "other" ] || [ "$AI_SERVICE" = "amazon_q" ]; then
    NEEDS_AI_DISCOVERY="true"
fi

cat > "$SHAMT_DIR/init_config.md" << EOF
# Shamt Initialization Config

**Generated:** $(date +%Y-%m-%d)
**Status:** PENDING_AGENT_COMPLETION

## Project Configuration
- **Project Name:** $PROJECT_NAME
- **Epic Tag:** $EPIC_TAG
- **Shamt Agent Name:** $SHAMT_NAME
- **Starting Epic Number:** $STARTING_EPIC
- **Epic Working Directory:** .shamt/epics/

## AI Service
- **Service:** $AI_SERVICE
- **Rules File Name:** $RULES_FILE_NAME
- **Rules File Path:** $RULES_FILE_DIR/
- **Needs AI Discovery:** $NEEDS_AI_DISCOVERY

## Git Configuration
- **Platform:** $GIT_PLATFORM
- **Default Branch:** $DEFAULT_BRANCH

## Script Actions Completed
- [x] Created .shamt/ folder structure
- [x] Copied guides from master Shamt
- [x] Copied initialization files
- [x] Placed rules file at $RULES_FILE_DIR/$RULES_FILE_NAME
- [x] Created EPIC_TRACKER.md at .shamt/epics/EPIC_TRACKER.md
- [x] Created CHANGELOG_INDEX.md files
- [x] Applied configuration substitutions

## Agent Remaining Tasks
- [ ] Handle AI service discovery (if Needs AI Discovery = true)
- [ ] Analyze codebase structure, languages, frameworks
- [ ] Write ARCHITECTURE.md (incorporate existing content if present)
- [ ] Write CODING_STANDARDS.md (incorporate existing content if present)
- [ ] Customize guides for this project (test commands, project-specific notes)
- [ ] Add 3-5 key coding rules to rules file summary section
- [ ] Mark this file complete: change Status to COMPLETE

## Notes
$( [ "$RULES_FILE_EXISTS" = "true" ] && echo "- Existing rules file was preserved — agent should incorporate it into the new RULES_FILE content." || echo "- Rules file written fresh from template." )
$( [ "$NEEDS_AI_DISCOVERY" = "true" ] && echo "- AI service '$AI_SERVICE' needs rules file convention confirmed. Agent should research and update ai_services.md." || echo "" )
EOF

echo "  ✓ Handoff file written to .shamt/init_config.md"

# --- Done --------------------------------------------------------------------

separator "Done!"
echo ""
echo "  Shamt has been initialized in: $TARGET_DIR"
echo ""
echo "  Next step: open your project in $SHAMT_NAME (your AI assistant) and say:"
echo ""
echo "    \"Read .shamt/init_config.md and complete the Shamt initialization.\""
echo ""
echo "  The agent will analyze your codebase and finish setup."
echo ""
echo "============================================================"
echo ""
