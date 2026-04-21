#!/usr/bin/env bash
# =============================================================================
# Shamt Lite Initialization Script (Bash — Linux / Mac)
# =============================================================================
# Run this script from the root of the project you want to initialize Shamt Lite in.
# Usage: bash /path/to/shamt-ai-dev/.shamt/scripts/initialization/init_lite.sh [project-name]
# =============================================================================

set -e

SHAMT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"
LITE_DIR="$TARGET_DIR/shamt-lite"

echo ""
echo "============================================================"
echo "  Shamt Lite Initialization"
echo "============================================================"
echo "  Source: $SHAMT_SOURCE_DIR"
echo "  Target: $TARGET_DIR"
echo "============================================================"
echo ""

# --- Get project name --------------------------------------------------------

if [ -n "$1" ]; then
    PROJECT_NAME="$1"
else
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
echo ""
echo "Next steps:"
echo "  1. Copy shamt-lite/SHAMT_LITE.md to your AI service's rules file"
echo "     (e.g., CLAUDE.md, .cursorrules, copilot-instructions.md)"
echo ""
echo "  2. Start a story: create stories/{slug}/ticket.md and follow"
echo "     story_workflow_lite.md for the six-phase workflow"
echo ""
echo "  3. (Optional) Fill out architecture and coding standards templates:"
echo "     • shamt-lite/templates/architecture.template.md → ARCHITECTURE.md"
echo "     • shamt-lite/templates/coding_standards.template.md → CODING_STANDARDS.md"
echo ""
echo "============================================================"
echo ""
