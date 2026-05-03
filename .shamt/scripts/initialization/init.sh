#!/usr/bin/env bash
# =============================================================================
# Shamt Initialization Script (Bash — Linux / Mac)
# =============================================================================
# Run this script from the root of the project you want to initialize Shamt in.
# Usage: bash /path/to/shamt-ai-dev/.shamt/scripts/initialization/init.sh
# =============================================================================

set -e

SHAMT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TARGET_DIR="$(pwd)"
SHAMT_DIR="$TARGET_DIR/.shamt"

# Parse --host, --with-cloud, and --pr-provider flags
HOST_FLAG=""
WITH_CLOUD=0
PR_PROVIDER_FLAG=""
for _arg in "$@"; do
    case "$_arg" in
        --host=*)           HOST_FLAG="${_arg#--host=}" ;;
        --with-cloud)       WITH_CLOUD=1 ;;
        --pr-provider=*)    PR_PROVIDER_FLAG="${_arg#--pr-provider=}" ;;
    esac
done

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

_do_setup_mcp() {
    if [ ! -d "$TARGET_DIR/.shamt/mcp" ]; then
        cp -r "$SHAMT_SOURCE_DIR/.shamt/mcp" "$TARGET_DIR/.shamt/mcp"
        echo "  ✓ MCP dir copied"
    fi
    if command -v python3 >/dev/null 2>&1; then
        echo "  Setting up MCP venv (this may take a moment)..."
        if python3 -m venv "$TARGET_DIR/.shamt/mcp/.venv" \
           && "$TARGET_DIR/.shamt/mcp/.venv/bin/pip" install -e "$TARGET_DIR/.shamt/mcp" -q; then
            echo "  ✓ MCP venv created and shamt-mcp installed"
        else
            echo "  ⚠  MCP setup failed — MCP will not be registered. Re-run after fixing the issue."
        fi
    else
        echo "  ⚠  python3 not found — MCP setup skipped."
    fi
}

# --- AI Service Selection ----------------------------------------------------

separator "AI Service"

# --host flag short-circuits the menu for known hosts
CODEX_FRONTIER_MODEL=""
CODEX_DEFAULT_MODEL=""

if [ -n "$HOST_FLAG" ] && [[ "$HOST_FLAG" =~ codex ]]; then
    # Codex (or dual-host) selected via flag
    if [[ "$HOST_FLAG" =~ claude ]]; then
        AI_SERVICE="claude_codex"
        RULES_FILE_NAME="AGENTS.md"   # canonical; CLAUDE.md symlinked to it
    else
        AI_SERVICE="codex"
        RULES_FILE_NAME="AGENTS.md"
    fi
    RULES_FILE_DIR="$TARGET_DIR"
    echo "  → Host flag: $HOST_FLAG — AI service set to $AI_SERVICE"
elif [ -n "$HOST_FLAG" ] && [[ "$HOST_FLAG" =~ claude ]]; then
    AI_SERVICE="claude_code"
    RULES_FILE_NAME="CLAUDE.md"
    RULES_FILE_DIR="$TARGET_DIR"
    echo "  → Host flag: $HOST_FLAG — AI service set to claude_code"
else
    echo "Which AI coding assistant will you use with this project?"
    echo ""
    echo "  1) Claude Code (Anthropic)       → CLAUDE.md at project root"
    echo "  2) Codex (OpenAI)                → AGENTS.md at project root"
    echo "  3) GitHub Copilot                → .github/copilot-instructions.md"
    echo "  4) Cursor                        → .cursorrules (legacy) or .cursor/index.mdc (new)"
    echo "  5) Windsurf (Codeium)            → .windsurfrules at project root"
    echo "  6) Amazon Q Developer            → (setup TBD)"
    echo "  7) Other                         → you will specify"
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
            AI_SERVICE="codex"
            RULES_FILE_NAME="AGENTS.md"
            RULES_FILE_DIR="$TARGET_DIR"
            ;;
        3)
            AI_SERVICE="github_copilot"
            RULES_FILE_NAME="copilot-instructions.md"
            RULES_FILE_DIR="$TARGET_DIR/.github"
            ;;
        4)
            AI_SERVICE="cursor"
            echo ""
            echo "  Cursor supports two rules file formats:"
            echo "    1) Legacy .cursorrules (project root) — still widely used"
            echo "    2) New .cursor/index.mdc — recommended as of 2026"
            echo ""
            read -rp "  Which format? [2]: " cursor_format
            cursor_format="${cursor_format:-2}"
            if [ "$cursor_format" = "1" ]; then
                RULES_FILE_NAME=".cursorrules"
                RULES_FILE_DIR="$TARGET_DIR"
            else
                RULES_FILE_NAME="index.mdc"
                RULES_FILE_DIR="$TARGET_DIR/.cursor"
            fi
            ;;
        5)
            AI_SERVICE="windsurf"
            RULES_FILE_NAME=".windsurfrules"
            RULES_FILE_DIR="$TARGET_DIR"
            ;;
        6)
            AI_SERVICE="amazon_q"
            RULES_FILE_NAME="TBD"
            RULES_FILE_DIR="$TARGET_DIR"
            echo ""
            echo "  ⚠  Amazon Q rules file convention is not yet confirmed."
            echo "  The agent will help you determine the correct setup."
            ;;
        7)
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
fi

# Prompt for Codex model names when Codex is selected
if [[ "$AI_SERVICE" =~ codex ]]; then
    echo ""
    echo "  Codex model names (from Codex changelog — press Enter to accept defaults):"
    read -rp "    Frontier model [o3]: " CODEX_FRONTIER_MODEL
    CODEX_FRONTIER_MODEL="${CODEX_FRONTIER_MODEL:-o3}"
    read -rp "    Default model  [o4-mini]: " CODEX_DEFAULT_MODEL
    CODEX_DEFAULT_MODEL="${CODEX_DEFAULT_MODEL:-o4-mini}"
fi

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

# --- Repository Configuration ------------------------------------------------

separator "Repository Configuration"

echo "  Should .shamt/ and the rules file be excluded from git in this project?"
echo "  This uses .git/info/exclude — local only, never committed or visible to other users."
echo "  Default: YES (recommended for solo/multi-agent work — keeps epic state files out of git)."
echo "  Choose 'no' only if you need to share .shamt/ with other developers via git."
echo ""
read -rp "  Locally exclude .shamt/ and rules file from git? [Y/n]: " exclude_choice
exclude_choice="${exclude_choice:-Y}"
if [[ "$exclude_choice" =~ ^[Yy]$ ]]; then
    EXCLUDE_SHAMT="true"
else
    EXCLUDE_SHAMT="false"
fi

echo "  ✓ Locally exclude .shamt/ and rules file (default: yes): $EXCLUDE_SHAMT"

# --- Confirmation ------------------------------------------------------------

separator "Review"
echo "  Project name:          $PROJECT_NAME"
echo "  Epic tag:              $EPIC_TAG"
echo "  Agent name:            $SHAMT_NAME"
echo "  Starting epic #:       $STARTING_EPIC"
echo "  AI service:            $AI_SERVICE"
echo "  Rules file:            $RULES_FILE_NAME"
echo "  Rules file path:       $RULES_FILE_DIR/"
if [ -n "$CODEX_FRONTIER_MODEL" ]; then
echo "  Codex frontier model:  $CODEX_FRONTIER_MODEL"
echo "  Codex default model:   $CODEX_DEFAULT_MODEL"
fi
echo "  Git platform:          $GIT_PLATFORM"
echo "  Default branch:        $DEFAULT_BRANCH"
echo "  Exclude .shamt/ (local): $EXCLUDE_SHAMT"
echo "  Epic directory:        .shamt/epics/"
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
mkdir -p "$SHAMT_DIR/scripts"
mkdir -p "$SHAMT_DIR/project-specific-configs"
mkdir -p "$SHAMT_DIR/epics/requests"
mkdir -p "$SHAMT_DIR/epics/done"
mkdir -p "$SHAMT_DIR/unimplemented_design_proposals"
mkdir -p "$RULES_FILE_DIR"

echo "  ✓ .shamt/ structure created"

# --- Write Config Files ------------------------------------------------------

separator "Writing config files"

echo "$SHAMT_SOURCE_DIR" > "$SHAMT_DIR/shamt_master_path.conf"
echo "  ✓ Master path written to .shamt/shamt_master_path.conf"

echo "$RULES_FILE_DIR/$RULES_FILE_NAME" > "$SHAMT_DIR/rules_file_path.conf"
echo "  ✓ Rules file path written to .shamt/rules_file_path.conf"

_sync_date="$(date +%Y-%m-%d)"
_master_hash="$(git -C "$SHAMT_SOURCE_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
printf '%s | %s\n' "$_sync_date" "$_master_hash" > "$SHAMT_DIR/last_sync.conf"
echo "  ✓ Sync state written to .shamt/last_sync.conf"

mkdir -p "$SHAMT_DIR/config"
echo "$AI_SERVICE" > "$SHAMT_DIR/config/ai_service.conf"
if [ "$TARGET_DIR" = "$SHAMT_SOURCE_DIR" ]; then
    echo "master" > "$SHAMT_DIR/config/repo_type.conf"
else
    echo "child" > "$SHAMT_DIR/config/repo_type.conf"
fi
echo "$EPIC_TAG" > "$SHAMT_DIR/config/epic_tag.conf"

# --- PR provider config -------------------------------------------------------
_pr_provider="${PR_PROVIDER_FLAG:-github}"
if [ -z "$PR_PROVIDER_FLAG" ] && [ -f "$SHAMT_DIR/config/pr_provider.conf" ]; then
    # Re-init: preserve existing choice unless flag overrides
    _pr_provider="$(tr -d '[:space:]' < "$SHAMT_DIR/config/pr_provider.conf")"
fi
if [ -z "$PR_PROVIDER_FLAG" ] && [ ! -f "$SHAMT_DIR/config/pr_provider.conf" ]; then
    echo ""
    echo "  PR provider (default: github):"
    echo "    1) github  — GitHub Actions CI + GitHub PR comments"
    echo "    2) ado     — Azure Pipelines CI + ADO PR comment threads"
    echo "    3) both    — configure both"
    read -rp "  Enter choice [1/2/3] (press Enter for github): " _pr_choice
    case "$_pr_choice" in
        2) _pr_provider="ado" ;;
        3) _pr_provider="both" ;;
        *) _pr_provider="github" ;;
    esac
fi
echo "$_pr_provider" > "$SHAMT_DIR/config/pr_provider.conf"

if [[ "$_pr_provider" == *ado* ]]; then
    if ! command -v npx >/dev/null 2>&1; then
        echo ""
        echo "  ⚠  WARNING: 'npx' not found. Node.js 20+ is required for the ADO MCP Server."
        echo "     Install Node.js from https://nodejs.org and re-run init, or run regen-claude-shims.sh after installing."
    fi
    if [ -z "$(cat "$SHAMT_DIR/config/ado_org.txt" 2>/dev/null)" ]; then
        read -rp "  Enter your ADO organization name (e.g. 'myorg' from dev.azure.com/myorg): " _ado_org
        echo "$_ado_org" > "$SHAMT_DIR/config/ado_org.txt"
        echo "  ✓ ADO org stored in .shamt/config/ado_org.txt"
    fi
    echo ""
    echo "  ℹ  ADO MCP Server: on first use, your browser will open for Microsoft Entra authentication."
fi

echo "  ✓ Host config written to .shamt/config/"

# --- Configure local git excludes --------------------------------------------

separator "Configuring local git excludes"

GIT_EXCLUDE_FILE="$TARGET_DIR/.git/info/exclude"

if [ ! -d "$TARGET_DIR/.git/info" ]; then
    echo "  ⚠  .git/info/ not found — is this a git repository?"
    echo "  Run 'git init' first, then re-run init to apply local excludes."
    echo "  Skipping local excludes configuration."
else
    add_exclude() {
        local entry="$1"
        if ! grep -qF "$entry" "$GIT_EXCLUDE_FILE"; then
            echo "$entry" >> "$GIT_EXCLUDE_FILE"
        fi
    }

    # Always exclude *.conf files (covers shamt_master_path.conf, last_sync.conf, rules_file_path.conf, etc.)
    add_exclude ".shamt/*.conf"
    echo "  ✓ .shamt/*.conf added to .git/info/exclude (always)"

    # Always exclude import_diff*.md (transient diff files — never commit)
    add_exclude ".shamt/import_diff*.md"
    echo "  ✓ .shamt/import_diff*.md added to .git/info/exclude (always)"

    # Always exclude VALIDATION_LOG* (transient validation logs — never commit)
    add_exclude "*VALIDATION_LOG*"
    echo "  ✓ *VALIDATION_LOG* added to .git/info/exclude (always)"

    # Optionally exclude .shamt/ and rules file
    if [ "$EXCLUDE_SHAMT" = "true" ]; then
        # Warn if .shamt/ is already tracked by git (migration required)
        if [ -n "$(git -C "$TARGET_DIR" ls-files .shamt/ 2>/dev/null | head -1)" ]; then
            echo ""
            echo "  ⚠  Warning: .shamt/ is currently tracked by git. To migrate:"
            echo "       git rm -r --cached .shamt/"
            echo "       git commit -m \"stop tracking .shamt/ framework directory\""
            echo "  (Continuing — adding .shamt/ to .git/info/exclude now; run the commands above when ready)"
        fi
        add_exclude ".shamt/"
        if [ "$RULES_FILE_DIR" = "$TARGET_DIR" ]; then
            RULES_EXCLUDE_PATH="$RULES_FILE_NAME"
        else
            RULES_EXCLUDE_PATH="${RULES_FILE_DIR#"$TARGET_DIR"/}/$RULES_FILE_NAME"
        fi
        add_exclude "$RULES_EXCLUDE_PATH"
        echo "  ✓ .shamt/ and $RULES_EXCLUDE_PATH added to .git/info/exclude"
    fi
fi

# --- Copy Guides -------------------------------------------------------------

separator "Copying guides"

cp -r "$SHAMT_SOURCE_DIR/.shamt/guides/"* "$SHAMT_DIR/guides/"
# Exclude master's audit output history — child projects start fresh
rm -rf "$SHAMT_DIR/guides/audit/outputs"
mkdir -p "$SHAMT_DIR/guides/audit/outputs"
echo "  ✓ Guides copied (audit/outputs/ cleared for fresh start)"

# --- Copy Scripts ------------------------------------------------------------

separator "Copying scripts"

cp -r "$SHAMT_SOURCE_DIR/.shamt/scripts/"* "$SHAMT_DIR/scripts/"
echo "  ✓ Scripts copied"

# --- Copy Canonical Content --------------------------------------------------

separator "Copying canonical content"

for _dir in skills agents commands; do
    if [ -d "$SHAMT_SOURCE_DIR/.shamt/$_dir" ]; then
        mkdir -p "$SHAMT_DIR/$_dir"
        cp -r "$SHAMT_SOURCE_DIR/.shamt/$_dir/"* "$SHAMT_DIR/$_dir/" 2>/dev/null || true
    fi
done
echo "  ✓ Canonical content copied (skills/, agents/, commands/)"

# --- Configure Rules File ----------------------------------------------------

separator "Configuring rules file"

RULES_TEMPLATE="$SHAMT_DIR/scripts/initialization/RULES_FILE.template.md"
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
EPIC_TRACKER_TEMPLATE="$SHAMT_DIR/scripts/initialization/EPIC_TRACKER.template.md"
EPIC_TRACKER_DEST="$SHAMT_DIR/epics/EPIC_TRACKER.md"
cp "$EPIC_TRACKER_TEMPLATE" "$EPIC_TRACKER_DEST"
do_substitutions "$EPIC_TRACKER_DEST"
# Set starting epic number
sed -i "s/$EPIC_TAG-1/$EPIC_TAG-$STARTING_EPIC/g" "$EPIC_TRACKER_DEST"

echo "  ✓ Configuration applied"

# --- Write init_config.md Handoff File ---------------------------------------

separator "Writing handoff file for agent"

NEEDS_AI_DISCOVERY="false"
if [ "$AI_SERVICE" = "other" ] || [ "$AI_SERVICE" = "amazon_q" ]; then
    NEEDS_AI_DISCOVERY="true"
fi

cat > "$SHAMT_DIR/project-specific-configs/init_config.md" << EOF
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
- **Rules File Template:** .shamt/scripts/initialization/RULES_FILE.template.md
- **Needs AI Discovery:** $NEEDS_AI_DISCOVERY

## Git Configuration
- **Platform:** $GIT_PLATFORM
- **Default Branch:** $DEFAULT_BRANCH

## Script Actions Completed
- [x] Created .shamt/ folder structure (including project-specific-configs/ and unimplemented_design_proposals/)
- [x] Copied guides from master Shamt (audit/outputs/ cleared for fresh start)
- [x] Copied scripts from master Shamt
- [x] Placed rules file at $RULES_FILE_DIR/$RULES_FILE_NAME
- [x] Created EPIC_TRACKER.md at .shamt/epics/EPIC_TRACKER.md
- [x] Written .shamt/shamt_master_path.conf
- [x] Written .shamt/rules_file_path.conf
- [x] Written .shamt/last_sync.conf (initialized from master HEAD)
- [x] Applied configuration substitutions to guides and rules file

## Agent Remaining Tasks

**Before beginning:** Re-read the validation loop protocol at:
\`.shamt/guides/reference/validation_loop_master_protocol.md\`

Then run a validation loop to complete initialization:

- [ ] Handle AI service discovery (if Needs AI Discovery = true)
- [ ] Analyze codebase structure, languages, frameworks
- [ ] Ask clarifying questions until codebase is fully understood
- [ ] Write ARCHITECTURE.md to \`.shamt/project-specific-configs/\`
- [ ] Write CODING_STANDARDS.md to \`.shamt/project-specific-configs/\`
- [ ] Add 3-5 key coding rules to rules file summary section
- [ ] Fill in Project Context section in rules file (tech stack, runtime, test runner, deployment target, critical gotchas)
- [ ] Validate all outputs meet quality bar (primary clean round + sub-agent confirmation)
- [ ] Mark this file complete: change Status to COMPLETE

## Notes
$( [ "$RULES_FILE_EXISTS" = "true" ] && echo "- Existing rules file was preserved — agent should incorporate it into the new rules file content." || echo "- Rules file written fresh from template." )
$( [ "$NEEDS_AI_DISCOVERY" = "true" ] && echo "- AI service '$AI_SERVICE' needs rules file convention confirmed. Agent should research and update ai_services.md." )
$( [ "$EXCLUDE_SHAMT" = "true" ] && echo "- .shamt/ and rules file are excluded via .git/info/exclude (local only — not committed or visible to other users)." || echo "- .shamt/ is not excluded from git — it will be tracked and visible to all repo users." )
- ARCHITECTURE.md and CODING_STANDARDS.md belong in \`.shamt/project-specific-configs/\`, not the project root.
- Shared guide files in \`.shamt/guides/\` must remain generic — never write project-specific content into them.
- The only exception: a pointer note in a shared guide directing the agent to check \`.shamt/project-specific-configs/\` for a supplement.
EOF

echo "  ✓ Handoff file written to .shamt/project-specific-configs/init_config.md"

# --- Optional Features -------------------------------------------------------

separator "Optional Features"

echo "  Active enforcement (hooks) — enforces commit format, blocks --no-verify,"
echo "  guards pushes, writes session snapshots."
read -rp "  Enable active enforcement (hooks)? [y/N]: " _hooks_choice
_hooks_choice="${_hooks_choice:-N}"
[[ "$_hooks_choice" =~ ^[Yy]$ ]] && ENABLE_HOOKS="y" || ENABLE_HOOKS="n"

echo ""
echo "  Shamt MCP server — provides shamt.validation_round(), shamt.audit_run(),"
echo "  and other workflow tools. Requires Python 3."
read -rp "  Enable Shamt MCP server? [y/N]: " _mcp_choice
_mcp_choice="${_mcp_choice:-N}"
[[ "$_mcp_choice" =~ ^[Yy]$ ]] && ENABLE_MCP="y" || ENABLE_MCP="n"

ENABLE_CI_GH_VALIDATE="n"
ENABLE_CI_GH_JANITOR="n"
ENABLE_CI_ADO_VALIDATE="n"
ENABLE_CI_ADO_JANITOR="n"

if [[ "$_pr_provider" == *github* ]]; then
    echo ""
    echo "  CI automation (GitHub Actions) — automated PR validation and stale-work janitor."
    echo "  Requires OPENAI_API_KEY secret in your repository."
    read -rp "  Enable automated PR validation (GitHub Actions)? [y/N]: " _ci_gh_val
    _ci_gh_val="${_ci_gh_val:-N}"
    [[ "$_ci_gh_val" =~ ^[Yy]$ ]] && ENABLE_CI_GH_VALIDATE="y"
    read -rp "  Enable weekly stale-work janitor (GitHub Actions)? [y/N]: " _ci_gh_jan
    _ci_gh_jan="${_ci_gh_jan:-N}"
    [[ "$_ci_gh_jan" =~ ^[Yy]$ ]] && ENABLE_CI_GH_JANITOR="y"
fi

if [[ "$_pr_provider" == *ado* ]]; then
    echo ""
    echo "  CI automation (Azure Pipelines) — automated PR validation and stale-work janitor."
    echo "  Requires OPENAI_API_KEY secret in your repository."
    read -rp "  Enable automated PR validation (Azure Pipelines)? [y/N]: " _ci_ado_val
    _ci_ado_val="${_ci_ado_val:-N}"
    [[ "$_ci_ado_val" =~ ^[Yy]$ ]] && ENABLE_CI_ADO_VALIDATE="y"
    read -rp "  Enable weekly stale-work janitor (Azure Pipelines)? [y/N]: " _ci_ado_jan
    _ci_ado_jan="${_ci_ado_jan:-N}"
    [[ "$_ci_ado_jan" =~ ^[Yy]$ ]] && ENABLE_CI_ADO_JANITOR="y"
fi

echo ""
echo "  ✓ Optional features: hooks=$ENABLE_HOOKS  mcp=$ENABLE_MCP"

# --- Claude Code Host Wiring -------------------------------------------------

if [[ "$AI_SERVICE" =~ claude ]]; then
    separator "Claude Code host wiring"

    # Create .claude/ directory structure
    mkdir -p "$TARGET_DIR/.claude/skills"
    mkdir -p "$TARGET_DIR/.claude/agents"
    mkdir -p "$TARGET_DIR/.claude/commands"
    echo "  ✓ .claude/ directory structure created"

    # Write starter settings.json BEFORE regen so the hooks flag is readable
    STARTER_SETTINGS="$SHAMT_SOURCE_DIR/.shamt/host/claude/settings.starter.json"
    TARGET_SETTINGS="$TARGET_DIR/.claude/settings.json"
    if [ -f "$TARGET_SETTINGS" ]; then
        if grep -q "_shamt_managed_blocks" "$TARGET_SETTINGS" 2>/dev/null; then
            echo "  ✓ .claude/settings.json already has Shamt-managed blocks — skipping"
        else
            echo "  ⚠  .claude/settings.json exists but lacks Shamt blocks."
            echo "     To merge manually, add the statusLine block from:"
            echo "     $STARTER_SETTINGS"
        fi
    elif [ -f "$STARTER_SETTINGS" ]; then
        sed "s|\${PROJECT}|$TARGET_DIR|g" "$STARTER_SETTINGS" > "$TARGET_SETTINGS"
        echo "  ✓ .claude/settings.json written"
    else
        echo "  ⚠  settings.starter.json not found — skipping settings.json creation"
    fi

    # Apply hooks if enabled
    if [ "$ENABLE_HOOKS" = "y" ]; then
        if [ ! -d "$TARGET_DIR/.shamt/hooks" ]; then
            cp -r "$SHAMT_SOURCE_DIR/.shamt/hooks" "$TARGET_DIR/.shamt/hooks"
            echo "  ✓ Hooks dir copied"
        fi
        if command -v python3 >/dev/null 2>&1 && [ -f "$TARGET_SETTINGS" ]; then
            if python3 - "$TARGET_SETTINGS" <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path) as f: s = json.load(f)
s.setdefault('features', {})['shamt_hooks'] = True
with open(path, 'w') as f: json.dump(s, f, indent=2)
PYEOF
            then
                echo "  ✓ features.shamt_hooks=true patched into settings.json"
            else
                echo "  ⚠  Failed to patch features.shamt_hooks — edit settings.json manually."
            fi
        else
            echo "  ⚠  python3 not found — features.shamt_hooks flag not set."
            echo "     Run regen-claude-shims.sh manually after installing Python 3 to complete hooks setup."
        fi
    fi

    # Apply MCP if enabled
    if [ "$ENABLE_MCP" = "y" ]; then
        _do_setup_mcp
    fi

    # Run regen LAST — reads settings.json with hooks flag already set
    REGEN_SCRIPT="$SHAMT_DIR/scripts/regen/regen-claude-shims.sh"
    if [ -f "$REGEN_SCRIPT" ]; then
        bash "$REGEN_SCRIPT"
        echo "  ✓ Claude Code shims generated"
    else
        echo "  ⚠  regen-claude-shims.sh not found — run it manually after init"
    fi

    echo ""
    echo "  ⚠  Trust reminder: ensure this project is trusted in Claude Code."
    echo "     Open Claude Code in $TARGET_DIR — it will prompt for trust on first open."
fi

# For dual-host (claude_codex): symlink CLAUDE.md → AGENTS.md so both names work
if [ "$AI_SERVICE" = "claude_codex" ]; then
    AGENTS_FILE="$TARGET_DIR/AGENTS.md"
    CLAUDE_FILE="$TARGET_DIR/CLAUDE.md"
    if [ -f "$AGENTS_FILE" ] && [ ! -e "$CLAUDE_FILE" ]; then
        ln -s AGENTS.md "$CLAUDE_FILE"
        echo "  ✓ CLAUDE.md → AGENTS.md symlink created (dual-host)"
    fi
fi

# --- Codex Host Wiring -------------------------------------------------------

if [[ "$AI_SERVICE" =~ codex ]]; then
    separator "Codex host wiring"

    # Create .codex/ directory structure
    mkdir -p "$TARGET_DIR/.codex/agents"
    echo "  ✓ .codex/ directory structure created"

    # Write model resolution file
    MODEL_RESOLUTION="$SHAMT_DIR/host/codex/.model_resolution.local.toml"
    mkdir -p "$SHAMT_DIR/host/codex"
    printf 'FRONTIER_MODEL = "%s"\nDEFAULT_MODEL = "%s"\n' \
        "$CODEX_FRONTIER_MODEL" "$CODEX_DEFAULT_MODEL" > "$MODEL_RESOLUTION"
    echo "  ✓ .model_resolution.local.toml written ($CODEX_FRONTIER_MODEL / $CODEX_DEFAULT_MODEL)"

    # Write starter config.toml
    STARTER_CONFIG="$SHAMT_SOURCE_DIR/.shamt/host/codex/config.starter.toml"
    TARGET_CONFIG="$TARGET_DIR/.codex/config.toml"
    if [ -f "$TARGET_CONFIG" ]; then
        echo "  ✓ .codex/config.toml already exists — skipping"
    elif [ -f "$STARTER_CONFIG" ]; then
        cp "$STARTER_CONFIG" "$TARGET_CONFIG"
        echo "  ✓ .codex/config.toml written from starter"
    else
        echo "  ⚠  config.starter.toml not found — skipping"
    fi

    # Copy requirements.toml.template to project root
    REQUIREMENTS_TPL="$SHAMT_SOURCE_DIR/.shamt/host/codex/requirements.toml.template"
    TARGET_REQUIREMENTS="$TARGET_DIR/requirements.toml"
    if [ -f "$TARGET_REQUIREMENTS" ]; then
        echo "  ✓ requirements.toml already exists — skipping"
    elif [ -f "$REQUIREMENTS_TPL" ]; then
        cp "$REQUIREMENTS_TPL" "$TARGET_REQUIREMENTS"
        echo "  ✓ requirements.toml written"
    else
        echo "  ⚠  requirements.toml.template not found — skipping"
    fi

    # Apply hooks if enabled (guard against double-copy in dual-host)
    if [ "$ENABLE_HOOKS" = "y" ] && [ ! -d "$TARGET_DIR/.shamt/hooks" ]; then
        cp -r "$SHAMT_SOURCE_DIR/.shamt/hooks" "$TARGET_DIR/.shamt/hooks"
        echo "  ✓ Hooks dir copied"
    fi

    # Apply MCP if enabled (guard against double-install in dual-host)
    if [ "$ENABLE_MCP" = "y" ] && [ ! -d "$TARGET_DIR/.shamt/mcp/.venv" ]; then
        _do_setup_mcp
    fi

    # Run regen script to populate .codex/ from canonical content
    REGEN_SCRIPT="$SHAMT_DIR/scripts/regen/regen-codex-shims.sh"
    if [ -f "$REGEN_SCRIPT" ]; then
        bash "$REGEN_SCRIPT"
        echo "  ✓ Codex shims generated"
    else
        echo "  ⚠  regen-codex-shims.sh not found — run it manually after init"
    fi
fi

# --- CI Automation -----------------------------------------------------------

if [ "$ENABLE_CI_GH_VALIDATE" = "y" ] || [ "$ENABLE_CI_GH_JANITOR" = "y" ] || \
   [ "$ENABLE_CI_ADO_VALIDATE" = "y" ] || [ "$ENABLE_CI_ADO_JANITOR" = "y" ]; then
    separator "CI Automation"

    _SDK_DIR="$SHAMT_SOURCE_DIR/.shamt/sdk"

    if [ "$ENABLE_CI_GH_VALIDATE" = "y" ]; then
        mkdir -p "$TARGET_DIR/.github/workflows"
        _src="$_SDK_DIR/.github/workflows/shamt-validate.yml.template"
        if [ -f "$_src" ]; then
            cp "$_src" "$TARGET_DIR/.github/workflows/shamt-validate.yml"
            echo "  ✓ .github/workflows/shamt-validate.yml written"
        else
            echo "  ⚠  $_src not found — skipping"
        fi
    fi

    if [ "$ENABLE_CI_GH_JANITOR" = "y" ]; then
        mkdir -p "$TARGET_DIR/.github/workflows"
        _src="$_SDK_DIR/.github/workflows/shamt-cron-janitor.yml.template"
        if [ -f "$_src" ]; then
            cp "$_src" "$TARGET_DIR/.github/workflows/shamt-cron-janitor.yml"
            echo "  ✓ .github/workflows/shamt-cron-janitor.yml written"
        else
            echo "  ⚠  $_src not found — skipping"
        fi
    fi

    if [ "$ENABLE_CI_ADO_VALIDATE" = "y" ]; then
        mkdir -p "$TARGET_DIR/azure-pipelines"
        _src="$_SDK_DIR/azure-pipelines/shamt-validate.yml.template"
        if [ -f "$_src" ]; then
            cp "$_src" "$TARGET_DIR/azure-pipelines/shamt-validate.yml"
            echo "  ✓ azure-pipelines/shamt-validate.yml written"
        else
            echo "  ⚠  $_src not found — skipping"
        fi
    fi

    if [ "$ENABLE_CI_ADO_JANITOR" = "y" ]; then
        mkdir -p "$TARGET_DIR/azure-pipelines"
        _src="$_SDK_DIR/azure-pipelines/shamt-cron-janitor.yml.template"
        if [ -f "$_src" ]; then
            cp "$_src" "$TARGET_DIR/azure-pipelines/shamt-cron-janitor.yml"
            echo "  ✓ azure-pipelines/shamt-cron-janitor.yml written"
        else
            echo "  ⚠  $_src not found — skipping"
        fi
    fi

    echo ""
    echo "  ⚠  CI automation: add OPENAI_API_KEY secret to your repository before workflows run."
fi

# --- Cloud environment setup (--with-cloud, Codex hosts only) -----------------

if [ "$WITH_CLOUD" -eq 1 ]; then
    case "$AI_SERVICE" in
        codex|claude_codex) ;;
        *)
            echo "  ⚠  --with-cloud is only applicable to Codex hosts (ai_service = codex or claude_codex). Skipping."
            WITH_CLOUD=0
            ;;
    esac
fi

if [ "$WITH_CLOUD" -eq 1 ]; then
    echo ""
    echo "  Setting up Codex Cloud environment..."
    echo ""

    CLOUD_TEMPLATE="$SHAMT_SOURCE_DIR/.shamt/host/codex/cloud-environment.template.json"
    TARGET_CLOUD="$TARGET_DIR/codex-environment.json"
    if [ -f "$TARGET_CLOUD" ]; then
        echo "  ✓ codex-environment.json already exists — skipping"
    elif [ -f "$CLOUD_TEMPLATE" ]; then
        cp "$CLOUD_TEMPLATE" "$TARGET_CLOUD"
        echo "  ✓ codex-environment.json written from template"
    else
        echo "  ⚠  cloud-environment.template.json not found — skipping"
    fi

    echo ""
    echo "  ⚠  Cloud setup notes:"
    echo "     1. Verify the manifest filename for your Codex Cloud version."
    echo "        See .shamt/host/codex/cloud-README.md for details."
    echo "     2. Set EPIC_BRANCH in the manifest before launching a cloud task."
    echo "     3. Register your project in Codex Cloud and link the manifest."
fi

# --- Done --------------------------------------------------------------------

separator "Done!"
echo ""
echo "  Shamt has been initialized in: $TARGET_DIR"
echo ""
echo "  Next step: open your project in $SHAMT_NAME (your AI assistant) and say:"
echo ""
echo "    \"Read .shamt/project-specific-configs/init_config.md and complete the Shamt initialization.\""
echo ""
echo "  The agent will analyze your codebase and finish setup."
echo ""
echo "  To sync with master later:"
echo "    Import updates from master: bash .shamt/scripts/import/import.sh"
echo "    Export changes to master:   bash .shamt/scripts/export/export.sh"
echo ""
echo "============================================================"
echo ""
