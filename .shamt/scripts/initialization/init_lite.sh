#!/usr/bin/env bash
# =============================================================================
# Shamt Lite Initialization Script (Bash — Linux / Mac)
# =============================================================================
# Run this script from the root of the project you want to initialize Shamt Lite in.
# Usage:
#   bash /path/to/shamt-ai-dev/.shamt/scripts/initialization/init_lite.sh [project-name] [--host=claude|codex|cursor|...] [--with-mcp]
#
# Default (no flag): writes shamt-lite/ files only — Tier 0 standalone behavior.
# --host=claude:         additionally writes <TARGET>/CLAUDE.md + .claude/{skills,commands,agents}/
# --host=codex:          additionally writes <TARGET>/AGENTS.md + .codex/{agents,config.toml} + .agents/skills/
# --host=cursor:         additionally writes .cursor/{skills,commands,rules,agents}/; prompts for cheap-tier model
# --host=claude,codex:   both Claude + Codex; AGENTS.md is canonical, CLAUDE.md symlinked (Unix) or duplicated
# --host=cursor,codex:   both Cursor + Codex; independent deployments, no symlinking
# (any comma-separated combination of claude, codex, cursor is accepted)
# --with-mcp:            reserved (Tier 3, deferred — currently a no-op)
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
WANT_CURSOR=0
if [ -n "$HOST_FLAG" ]; then
    case ",$HOST_FLAG," in
        *,claude,*) WANT_CLAUDE=1 ;;
    esac
    case ",$HOST_FLAG," in
        *,codex,*) WANT_CODEX=1 ;;
    esac
    case ",$HOST_FLAG," in
        *,cursor,*) WANT_CURSOR=1 ;;
    esac
    if [ "$WANT_CLAUDE" -eq 0 ] && [ "$WANT_CODEX" -eq 0 ] && [ "$WANT_CURSOR" -eq 0 ]; then
        echo "ERROR: --host=$HOST_FLAG is not recognized. Supported: claude, codex, cursor (comma-separated combinations OK)" >&2
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

if [ "$WANT_CLAUDE" -eq 1 ] || [ "$WANT_CODEX" -eq 1 ] || [ "$WANT_CURSOR" -eq 1 ]; then
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
    elif ! grep -q 'host/codex/.model_resolution.local.toml' "$LITE_DIR/.gitignore"; then
        printf 'host/codex/.model_resolution.local.toml\n' >> "$LITE_DIR/.gitignore"
    fi

    # AGENTS.md = copy of SHAMT_LITE.md (Codex reads it from project root automatically)
    cp "$LITE_DIR/SHAMT_LITE.md" "$CODEX_RULES"
    echo "  ✓ AGENTS.md written ($CODEX_FRONTIER_MODEL / $CODEX_DEFAULT_MODEL)"
fi

# --- Write ai_service.conf + update gitignore --------------------------------

_PARTS=()
[ "$WANT_CLAUDE" -eq 1 ] && _PARTS+=("claude")
[ "$WANT_CODEX"  -eq 1 ] && _PARTS+=("codex")
[ "$WANT_CURSOR" -eq 1 ] && _PARTS+=("cursor")
if [ "${#_PARTS[@]}" -eq 0 ]; then
    _AI_SERVICE_CONF="none"
else
    _AI_SERVICE_CONF=$(IFS='_'; echo "${_PARTS[*]}")
fi

mkdir -p "$LITE_DIR/config"
printf '%s\n' "$_AI_SERVICE_CONF" > "$LITE_DIR/config/ai_service.conf"

if [ ! -f "$LITE_DIR/.gitignore" ]; then
    printf 'config/\nCHEATSHEET.md\n' > "$LITE_DIR/.gitignore"
else
    grep -q '^config/$' "$LITE_DIR/.gitignore" || printf '\nconfig/\n' >> "$LITE_DIR/.gitignore"
    grep -q '^CHEATSHEET\.md$' "$LITE_DIR/.gitignore" || printf 'CHEATSHEET.md\n' >> "$LITE_DIR/.gitignore"
fi

# Cursor: prompt for cheap-tier model, write resolution file, run regen
if [ "$WANT_CURSOR" -eq 1 ]; then
    echo ""
    echo "Cursor needs a cheap-tier model identifier for sub-agent personas."
    echo "  'inherit' (default): Cursor uses whatever model is currently active."
    echo "  Specific id (e.g. claude-haiku-4-5): pin to a fast cheap model."
    read -rp "Cursor cheap-tier model id [inherit]: " _cm
    CURSOR_CHEAP_MODEL="${_cm:-inherit}"

    mkdir -p "$LITE_DIR/host/cursor"
    printf 'CHEAP_MODEL = "%s"\n' "$CURSOR_CHEAP_MODEL" \
        > "$LITE_DIR/host/cursor/.model_resolution.local.toml"

    # Add gitignore entry inside shamt-lite/ to keep the resolution file out of git
    if [ ! -f "$LITE_DIR/.gitignore" ]; then
        printf 'host/cursor/.model_resolution.local.toml\n' > "$LITE_DIR/.gitignore"
    elif ! grep -q 'host/cursor/.model_resolution.local.toml' "$LITE_DIR/.gitignore"; then
        printf 'host/cursor/.model_resolution.local.toml\n' >> "$LITE_DIR/.gitignore"
    fi

    REGEN_CURSOR="$SHAMT_ROOT/.shamt/scripts/regen/regen-lite-cursor.sh"
    if [ -f "$REGEN_CURSOR" ]; then
        bash "$REGEN_CURSOR"
    else
        echo "  ⚠  regen-lite-cursor.sh not found at $REGEN_CURSOR — skipping" >&2
    fi

    echo "  ✓ Cursor wiring deployed (cheap-tier model: $CURSOR_CHEAP_MODEL)"
    echo "    To change later: edit .cursor/agents/shamt-lite-*.md or re-run init_lite.sh --host=cursor"
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

# --- Generate CHEATSHEET.md --------------------------------------------------

python3 - "$TARGET_DIR" <<'PYEOF'
import sys, os

target_dir  = sys.argv[1]
lite_dir    = os.path.join(target_dir, 'shamt-lite')
config_path = os.path.join(lite_dir, 'config', 'ai_service.conf')
out_path    = os.path.join(lite_dir, 'CHEATSHEET.md')

with open(config_path) as f:
    svc = f.read().strip()
parts      = svc.split('_')
has_claude = 'claude' in parts
has_codex  = 'codex'  in parts
has_cursor = 'cursor' in parts

L = [
    '# Shamt Lite — Cheat Sheet',
    '',
    '> Generated by Shamt. Re-run init_lite or a regen-lite script to refresh.',
    '',
    '## Six-Phase Story Workflow',
    '',
    '| Phase | Artifact | Gate |',
    '|-------|----------|------|',
    '| 1. Intake | `stories/{slug}/ticket.md` | User confirms slug + content |',
    '| 2. Spec   | `stories/{slug}/spec.md` | (2a) User picks design, (2b) User approves validated spec |',
    '| 3. Plan   | `stories/{slug}/implementation_plan.md` | User approves validated plan |',
    '| 4. Build  | code changes | Verification checklist in plan |',
    '| 5. Review | `stories/{slug}/code_review/review_v1.md` | Review is the artifact |',
    '| 6. Polish | commit messages + CHANGES.md entries | User signals "polishing complete" |',
    '',
    '## Core Patterns',
    '',
    '| Pattern | When to use |',
    '|---------|-------------|',
    '| P1: Validation Loop | Verifying any artifact (spec, plan, review) |',
    '| P2: Ask-First | Before large artifacts — surface assumptions first |',
    '| P3: Spec Protocol | Spec phase — 7 structured steps to validated spec |',
    '| P4: Code Review | Review phase — ELI5 + dimensions + PR comment blocks |',
    '| P5: Implementation Planning | Plan phase — mechanical step-by-step plan |',
    '',
    '## Validation Rules',
    '',
    '- **Clean round:** 0 issues OR exactly 1 LOW (fixed)',
    '- **Reset:** any MEDIUM/HIGH/CRITICAL or multiple LOWs → `consecutive_clean = 0`',
    '- **Exit:** `consecutive_clean = 1` + 1 Haiku sub-agent confirms zero issues',
    '- Severity: CRITICAL > HIGH > MEDIUM > LOW',
    '',
    '## Context-Clear Breakpoints',
    '',
    'Suggest `/clear` after Gate 2b (spec approved) and after Gate 3 (plan approved).',
    '',
    '## Builder Handoff',
    '',
    'If plan has **>10 mechanical steps**: spawn Haiku builder (see Pattern 5 in SHAMT_LITE.md).',
    '',
]
if has_claude:
    L += [
        '---', '',
        '## Slash Commands (Claude Code)', '',
        '| Command | Phase |',
        '|---------|-------|',
        '| `/lite-story {slug}` | Intake — start a new story |',
        '| `/lite-spec {slug}` | Spec — run spec protocol |',
        '| `/lite-plan {slug}` | Plan — write implementation plan |',
        '| `/lite-review` | Review — code review of current changes |',
        '| `/lite-validate` | Any — run a validation loop |',
        '',
        '## Skills (auto-triggered)', '',
        '| Skill | Trigger phrases |',
        '|-------|----------------|',
        '| `shamt-lite-story` | "start a story", "run lite story workflow" |',
        '| `shamt-lite-spec` | "spec this ticket", "run the spec protocol" |',
        '| `shamt-lite-plan` | "plan this", "create an implementation plan" |',
        '| `shamt-lite-review` | "review this branch", "review the changes" |',
        '| `shamt-lite-validate` | "validate this", "run a validation loop" |',
        '',
        '## Personas', '',
        '| Persona | Use |',
        '|---------|-----|',
        '| `shamt-lite-builder` | Haiku — executes mechanical implementation plans |',
        '| `shamt-lite-validator` | Haiku — sub-agent confirmation |',
        '',
    ]
if has_codex:
    L += [
        '---', '',
        '## Codex Profiles', '',
        'Switch profiles at phase boundaries (each transition = new session):',
        '',
        '| Phase | Profile flag |',
        '|-------|-------------|',
        '| Intake | `codex --profile shamt-lite-intake` |',
        '| Spec (research) | `codex --profile shamt-lite-spec-research` |',
        '| Spec (design) | `codex --profile shamt-lite-spec-design` |',
        '| Spec (validation) | `codex --profile shamt-lite-spec-validate` |',
        '| Plan | `codex --profile shamt-lite-plan` |',
        '| Build | `codex --profile shamt-lite-build` |',
        '| Review | `codex --profile shamt-lite-review` |',
        '| Validation sub-agent | `codex --profile shamt-lite-validator` |',
        '',
    ]
if has_cursor:
    L += [
        '---', '',
        '## Cursor Rules', '',
        'Shamt Lite `.mdc` rules are active in `.cursor/rules/`. They auto-attach',
        'based on file glob patterns — no manual activation needed.',
        '',
        'Explicitly invoke a pattern in your prompt:',
        '- "run the spec protocol for {slug}"',
        '- "write an implementation plan"',
        '- "validate this artifact"',
        '- "do a code review of this branch"',
        '',
    ]
if not has_claude and not has_codex and not has_cursor:
    L += [
        '---', '',
        '## Natural Language Triggers', '',
        'No host-specific commands configured. Reference patterns by name:',
        '- "run the spec protocol" → Pattern 3',
        '- "validate this" → Pattern 1',
        '- "write an implementation plan" → Pattern 5',
        '- "code review" → Pattern 4',
        '- "start a story" → story_workflow_lite.md',
        '',
    ]

with open(out_path, 'w') as f:
    f.write('\n'.join(L))

print('  Cheat sheet: written to shamt-lite/CHEATSHEET.md (service: ' + svc + ')')
PYEOF

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
echo "  ├── CHEATSHEET.md                           (service-specific quick reference, gitignored)"
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
if [ "$WANT_CURSOR" -eq 1 ]; then
    echo ""
    echo "  .cursor/skills/shamt-lite-*/SKILL.md       (5 Lite skills)"
    echo "  .cursor/commands/lite-*.md                 (5 Lite slash commands)"
    echo "  .cursor/rules/lite-*.mdc                   (5 attachment-aware rules)"
    echo "  .cursor/agents/shamt-lite-*.md             (validator + builder personas)"
    echo "  shamt-lite/host/cursor/.model_resolution.local.toml (gitignored)"
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
