#!/usr/bin/env bash
# =============================================================================
# regen-lite-codex.sh — Shamt Lite Codex shim generator
# =============================================================================
# Deploys Shamt Lite canonical content into a child project's Codex tree:
#   Skills   → <TARGET>/.agents/skills/<name>/SKILL.md   (filter: shamt-lite-*)
#   Agents   → <TARGET>/.codex/agents/<name>.toml        (YAML → TOML)
#   Profiles → <TARGET>/.codex/config.toml SHAMT-LITE-PROFILES block
#
# Source content lives in this master shamt-ai-dev repo:
#   Skills   .shamt/skills/shamt-lite-*/SKILL.md
#   Agents   .shamt/scripts/initialization/lite/agents/*.yaml
#   Profiles .shamt/scripts/initialization/lite/profiles-codex/*.fragment.toml
#
# Model resolution (substituted into profile fragments):
#   .shamt/host/codex/.model_resolution.local.toml (per-project, gitignored)
#
# Usage (from the child project root):
#   bash /path/to/shamt-ai-dev/.shamt/scripts/regen/regen-lite-codex.sh
#
# Idempotent.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHAMT_SOURCE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"   # master shamt-ai-dev root
SHAMT_DIR="$SHAMT_SOURCE_DIR/.shamt"
TARGET_DIR="$(pwd)"
CODEX_DIR="$TARGET_DIR/.codex"
AGENTS_SKILLS_DIR="$TARGET_DIR/.agents/skills"

LITE_AGENTS_SRC="$SHAMT_DIR/scripts/initialization/lite/agents"
LITE_PROFILES_SRC="$SHAMT_DIR/scripts/initialization/lite/profiles-codex"
SKILLS_SRC="$SHAMT_DIR/skills"

MANAGED_HEADER="# Managed by Shamt — do not edit. Run regen-lite-codex.sh to regenerate."
MANAGED_HEADER_MD="<!-- Managed by Shamt — do not edit. Run regen-lite-codex.sh to regenerate. -->"

echo ""
echo "============================================================"
echo "  Shamt Lite Regen — Codex Shims"
echo "============================================================"
echo "  Source: $SHAMT_SOURCE_DIR"
echo "  Target: $TARGET_DIR"
echo "============================================================"
echo ""

# --- Read model resolution ---------------------------------------------------
# The model resolution file lives in the TARGET project's .shamt/host/codex/
# (written by init_lite.sh --host=codex). For Lite-only projects without the
# master .shamt/, fall back to TARGET-side equivalents.

MODEL_RESOLUTION="$TARGET_DIR/.shamt/host/codex/.model_resolution.local.toml"
if [ ! -f "$MODEL_RESOLUTION" ]; then
    # Lite-only projects keep the resolution file under shamt-lite/host/codex/
    MODEL_RESOLUTION="$TARGET_DIR/shamt-lite/host/codex/.model_resolution.local.toml"
fi

FRONTIER_MODEL="o3"
DEFAULT_MODEL="o4-mini"
if [ -f "$MODEL_RESOLUTION" ]; then
    _fm="$(grep '^FRONTIER_MODEL' "$MODEL_RESOLUTION" 2>/dev/null | cut -d'"' -f2 || true)"
    _dm="$(grep '^DEFAULT_MODEL' "$MODEL_RESOLUTION" 2>/dev/null | cut -d'"' -f2 || true)"
    [ -n "$_fm" ] && FRONTIER_MODEL="$_fm"
    [ -n "$_dm" ] && DEFAULT_MODEL="$_dm"
fi

echo "  Models: FRONTIER=$FRONTIER_MODEL  DEFAULT=$DEFAULT_MODEL"
echo ""

is_shamt_managed() {
    local file="$1"
    [ -f "$file" ] && head -1 "$file" | grep -q "Managed by Shamt"
}

# --- Phase 1: Skills (filter shamt-lite-*) → .agents/skills/ ----------------

SKILLS_WRITTEN=0
SKILLS_PRESERVED=0

if [ -d "$SKILLS_SRC" ]; then
    mkdir -p "$AGENTS_SKILLS_DIR"
    while IFS= read -r -d '' skill_dir; do
        skill_name="$(basename "$skill_dir")"
        case "$skill_name" in
            shamt-lite-*) ;;
            *) continue ;;
        esac

        skill_src="$skill_dir/SKILL.md"
        skill_dst="$AGENTS_SKILLS_DIR/$skill_name/SKILL.md"

        [ -f "$skill_src" ] || continue

        if [ -f "$skill_dst" ] && ! head -3 "$skill_dst" | grep -q "Managed by Shamt"; then
            SKILLS_PRESERVED=$((SKILLS_PRESERVED + 1))
            continue
        fi

        mkdir -p "$(dirname "$skill_dst")"
        # Substitute {cheap-tier} ONLY inside <parameter name="model">...</parameter> XML
        # tags so deployed XML examples carry the project's DEFAULT_MODEL. The
        # explanatory footnote (which references `{cheap-tier}` as inline code) is
        # preserved.
        {
            printf '%s\n' "$MANAGED_HEADER_MD"
            sed "s|<parameter name=\"model\">{cheap-tier}</parameter>|<parameter name=\"model\">$DEFAULT_MODEL</parameter>|g" "$skill_src"
        } > "$skill_dst"
        SKILLS_WRITTEN=$((SKILLS_WRITTEN + 1))
    done < <(find "$SKILLS_SRC" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)
    echo "  Skills: $SKILLS_WRITTEN written to .agents/skills/, $SKILLS_PRESERVED preserved (user-authored)"
else
    echo "  Skills: $SKILLS_SRC not found — skipping"
fi

# --- Phase 2: Agents (YAML → TOML) → .codex/agents/ -------------------------

AGENTS_WRITTEN=0

if [ -d "$LITE_AGENTS_SRC" ]; then
    mkdir -p "$CODEX_DIR/agents"
    while IFS= read -r -d '' yaml_file; do
        agent_name="$(basename "$yaml_file" .yaml)"
        agent_dst="$CODEX_DIR/agents/${agent_name}.toml"

        python3 - "$yaml_file" "$agent_dst" "$FRONTIER_MODEL" "$DEFAULT_MODEL" <<'PYEOF'
import sys, re

yaml_file, out_file, frontier_model, default_model = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
managed_header = "# Managed by Shamt — do not edit. Run regen-lite-codex.sh to regenerate."

with open(yaml_file, 'r') as f:
    content = f.read()

def extract_scalar(field, text):
    m = re.search(r'^' + re.escape(field) + r':\s*(.+)$', text, re.M)
    return m.group(1).strip() if m else ''

name = extract_scalar('name', content)
model_tier = extract_scalar('model_tier', content)
reasoning_effort = extract_scalar('reasoning_effort', content)
sandbox = extract_scalar('sandbox', content)

tier_map = {'cheap': default_model, 'balanced': frontier_model, 'reasoning': frontier_model}
model = tier_map.get(model_tier, model_tier)

tools = []
tools_m = re.search(r'^tools_allowed:(.*?)(?=^\S|\Z)', content, re.M | re.DOTALL)
if tools_m:
    tools = re.findall(r'^  - (\S+)$', tools_m.group(1), re.M)

template = ''
pt_m = re.search(r'^prompt_template:\s*\|(.*)$', content, re.M | re.DOTALL)
if pt_m:
    lines = pt_m.group(1).split('\n')[1:]
    dedented = []
    for l in lines:
        if l.startswith('  '):
            dedented.append(l[2:])
        elif l.strip() == '':
            dedented.append('')
        else:
            dedented.append(l)
    template = '\n'.join(dedented).rstrip('\n')

with open(out_file, 'w') as f:
    f.write(managed_header + '\n\n')
    f.write(f'[{name}]\n')
    f.write(f'model = "{model}"\n')
    if reasoning_effort:
        f.write(f'model_reasoning_effort = "{reasoning_effort}"\n')
    if sandbox:
        f.write(f'sandbox_mode = "{sandbox}"\n')
    if tools:
        f.write('tools_allowed = [' + ', '.join(f'"{t}"' for t in tools) + ']\n')
    if template:
        f.write(f'\nprompt = """\n{template}\n"""\n')
PYEOF
        AGENTS_WRITTEN=$((AGENTS_WRITTEN + 1))
    done < <(find "$LITE_AGENTS_SRC" -maxdepth 1 -name "*.yaml" -print0 | sort -z)
    echo "  Agents: $AGENTS_WRITTEN written to .codex/agents/"
else
    echo "  Agents: $LITE_AGENTS_SRC not found — skipping"
fi

# --- Phase 3: Profiles → .codex/config.toml SHAMT-LITE-PROFILES block --------

CONFIG_TOML="$CODEX_DIR/config.toml"

if [ -d "$LITE_PROFILES_SRC" ]; then
    mkdir -p "$CODEX_DIR"

    # Build the profiles content
    PROFILES_CONTENT=""
    while IFS= read -r -d '' frag; do
        # Substitute model variables in each fragment
        frag_content="$(sed -e "s|\${FRONTIER_MODEL}|$FRONTIER_MODEL|g" \
                            -e "s|\${DEFAULT_MODEL}|$DEFAULT_MODEL|g" "$frag")"
        if [ -n "$PROFILES_CONTENT" ]; then
            PROFILES_CONTENT="${PROFILES_CONTENT}"$'\n\n'"${frag_content}"
        else
            PROFILES_CONTENT="${frag_content}"
        fi
    done < <(find "$LITE_PROFILES_SRC" -maxdepth 1 -name "*.fragment.toml" -print0 | sort -z)

    START_MARKER="# ============================================================
# SHAMT-LITE-PROFILES-START — managed by regen-lite-codex.sh; do not edit manually
# ============================================================"
    END_MARKER="# ============================================================
# SHAMT-LITE-PROFILES-END
# ============================================================"

    if [ ! -f "$CONFIG_TOML" ]; then
        # Create a fresh Lite-only config.toml
        {
            echo "$MANAGED_HEADER"
            echo "# Codex configuration for Shamt Lite"
            echo ""
            echo "$START_MARKER"
            echo ""
            echo "$PROFILES_CONTENT"
            echo ""
            echo "$END_MARKER"
        } > "$CONFIG_TOML"
        echo "  Profiles: created $CONFIG_TOML with SHAMT-LITE-PROFILES block"
    else
        # Update existing config.toml (insert or replace SHAMT-LITE-PROFILES block)
        python3 - "$CONFIG_TOML" "$PROFILES_CONTENT" <<'PYEOF'
import sys, re

config_path, profiles_content = sys.argv[1], sys.argv[2]

with open(config_path) as f:
    config = f.read()

start_re = r'# ={13,}\n# SHAMT-LITE-PROFILES-START.*?\n# ={13,}'
end_re   = r'# ={13,}\n# SHAMT-LITE-PROFILES-END\n# ={13,}'

block_pattern = re.compile(start_re + r'.*?' + end_re, re.DOTALL)

start_marker = "# ============================================================\n# SHAMT-LITE-PROFILES-START — managed by regen-lite-codex.sh; do not edit manually\n# ============================================================"
end_marker = "# ============================================================\n# SHAMT-LITE-PROFILES-END\n# ============================================================"

new_block = start_marker + "\n\n" + profiles_content + "\n\n" + end_marker

result, count = block_pattern.subn(new_block, config)
if count == 0:
    # No existing block — append it
    if not result.endswith('\n'):
        result += '\n'
    result += '\n' + new_block + '\n'

with open(config_path, 'w') as f:
    f.write(result)
PYEOF
        echo "  Profiles: SHAMT-LITE-PROFILES block updated in $CONFIG_TOML"
    fi
else
    echo "  Profiles: $LITE_PROFILES_SRC not found — skipping"
fi

# --- Phase 4: Generate CHEATSHEET.md -----------------------------------------

_CONF="$TARGET_DIR/shamt-lite/config/ai_service.conf"
if [ ! -f "$_CONF" ]; then
    echo "  Cheat sheet: skipped (shamt-lite/config/ai_service.conf not found — run init_lite.sh first)"
else
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
fi

echo ""
echo "  ✓ Lite regen complete"
echo ""
