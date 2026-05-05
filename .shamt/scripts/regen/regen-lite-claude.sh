#!/usr/bin/env bash
# =============================================================================
# regen-lite-claude.sh — Shamt Lite Claude Code shim generator
# =============================================================================
# Deploys Shamt Lite canonical content into a child project's .claude/ tree:
#   Skills   → <TARGET>/.claude/skills/<name>/SKILL.md   (filter: shamt-lite-*)
#   Commands → <TARGET>/.claude/commands/<name>.md
#   Agents   → <TARGET>/.claude/agents/<name>.md         (YAML → Claude md)
#
# Source content lives in this master shamt-ai-dev repo:
#   Skills   .shamt/skills/shamt-lite-*/SKILL.md
#   Commands .shamt/scripts/initialization/lite/commands/*.md
#   Agents   .shamt/scripts/initialization/lite/agents/*.yaml
#
# Usage (from the child project root):
#   bash /path/to/shamt-ai-dev/.shamt/scripts/regen/regen-lite-claude.sh
#
# Idempotent: safe to run multiple times. Files with no Shamt-managed header
# are preserved.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHAMT_SOURCE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"   # master shamt-ai-dev root
SHAMT_DIR="$SHAMT_SOURCE_DIR/.shamt"
TARGET_DIR="$(pwd)"
CLAUDE_DIR="$TARGET_DIR/.claude"

LITE_CMDS_SRC="$SHAMT_DIR/scripts/initialization/lite/commands"
LITE_AGENTS_SRC="$SHAMT_DIR/scripts/initialization/lite/agents"
SKILLS_SRC="$SHAMT_DIR/skills"

MANAGED_HEADER="<!-- Managed by Shamt — do not edit. Run regen-lite-claude.sh to regenerate. -->"

echo ""
echo "============================================================"
echo "  Shamt Lite Regen — Claude Code Shims"
echo "============================================================"
echo "  Source: $SHAMT_SOURCE_DIR"
echo "  Target: $TARGET_DIR"
echo "============================================================"
echo ""

is_shamt_managed() {
    local file="$1"
    [ -f "$file" ] && grep -q "Managed by Shamt" "$file"
}

# --- Phase 1: Skills (filter shamt-lite-*) -----------------------------------

SKILLS_DST="$CLAUDE_DIR/skills"
SKILLS_WRITTEN=0
SKILLS_PRESERVED=0

if [ -d "$SKILLS_SRC" ]; then
    mkdir -p "$SKILLS_DST"
    while IFS= read -r -d '' skill_dir; do
        skill_name="$(basename "$skill_dir")"
        case "$skill_name" in
            shamt-lite-*) ;;
            *) continue ;;
        esac

        skill_src="$skill_dir/SKILL.md"
        skill_dst="$SKILLS_DST/$skill_name/SKILL.md"

        [ -f "$skill_src" ] || continue

        if [ -f "$skill_dst" ] && ! is_shamt_managed "$skill_dst"; then
            SKILLS_PRESERVED=$((SKILLS_PRESERVED + 1))
            continue
        fi

        mkdir -p "$(dirname "$skill_dst")"
        # Substitute {cheap-tier} ONLY inside <parameter name="model">...</parameter> XML
        # tags so deployed XML examples are concrete on Claude Code. The explanatory
        # footnote (which references `{cheap-tier}` as inline code) is preserved.
        {
            sed 's|<parameter name="model">{cheap-tier}</parameter>|<parameter name="model">haiku</parameter>|g' "$skill_src"
            printf '\n%s\n' "$MANAGED_HEADER"
        } > "$skill_dst"
        SKILLS_WRITTEN=$((SKILLS_WRITTEN + 1))
    done < <(find "$SKILLS_SRC" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)
    echo "  Skills: $SKILLS_WRITTEN written, $SKILLS_PRESERVED preserved (user-authored)"
else
    echo "  Skills: $SKILLS_SRC not found — skipping"
fi

# --- Phase 2: Commands -------------------------------------------------------

CMDS_DST="$CLAUDE_DIR/commands"
CMDS_WRITTEN=0
CMDS_PRESERVED=0

if [ -d "$LITE_CMDS_SRC" ]; then
    mkdir -p "$CMDS_DST"
    while IFS= read -r -d '' cmd_file; do
        cmd_name="$(basename "$cmd_file")"
        cmd_dst="$CMDS_DST/$cmd_name"

        if [ -f "$cmd_dst" ] && ! is_shamt_managed "$cmd_dst"; then
            CMDS_PRESERVED=$((CMDS_PRESERVED + 1))
            continue
        fi

        {
            cat "$cmd_file"
            printf '\n%s\n' "$MANAGED_HEADER"
        } > "$cmd_dst"
        CMDS_WRITTEN=$((CMDS_WRITTEN + 1))
    done < <(find "$LITE_CMDS_SRC" -maxdepth 1 -name "*.md" -print0 | sort -z)
    echo "  Commands: $CMDS_WRITTEN written, $CMDS_PRESERVED preserved (user-authored)"
else
    echo "  Commands: $LITE_CMDS_SRC not found — skipping"
fi

# --- Phase 3: Agents (YAML → Claude Code agent md) --------------------------

AGENTS_DST="$CLAUDE_DIR/agents"
AGENTS_WRITTEN=0
AGENTS_PRESERVED=0

if [ -d "$LITE_AGENTS_SRC" ]; then
    mkdir -p "$AGENTS_DST"
    while IFS= read -r -d '' yaml_file; do
        agent_name="$(basename "$yaml_file" .yaml)"
        agent_dst="$AGENTS_DST/$agent_name.md"

        if [ -f "$agent_dst" ] && ! is_shamt_managed "$agent_dst"; then
            AGENTS_PRESERVED=$((AGENTS_PRESERVED + 1))
            continue
        fi

        python3 - "$yaml_file" "$agent_dst" <<PYEOF
import sys, re

yaml_file = sys.argv[1]
out_file = sys.argv[2]
managed_header = "$MANAGED_HEADER"

with open(yaml_file, 'r') as f:
    content = f.read()

def extract_scalar(field, text):
    m = re.search(r'^' + re.escape(field) + r':\s*(.+)\$', text, re.M)
    return m.group(1).strip() if m else ''

name = extract_scalar('name', content)

# Description may be a literal block (style: |) or scalar
description = ''
desc_block = re.search(r'^description:\s*\|(.*?)(?=^\S|\Z)', content, re.M | re.DOTALL)
if desc_block:
    lines = desc_block.group(1).split('\n')[1:]
    dedented = []
    for l in lines:
        if l.startswith('  '):
            dedented.append(l[2:])
        elif l.strip() == '':
            dedented.append('')
        else:
            dedented.append(l)
    description = ' '.join(line.strip() for line in dedented if line.strip())
else:
    description = extract_scalar('description', content)

model_tier = extract_scalar('model_tier', content)

tools = []
tools_m = re.search(r'^tools_allowed:(.*?)(?=^\S|\Z)', content, re.M | re.DOTALL)
if tools_m:
    tools = re.findall(r'^  - (\S+)\$', tools_m.group(1), re.M)

template = ''
pt_m = re.search(r'^prompt_template:\s*\|(.*)\$', content, re.M | re.DOTALL)
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

tier_map = {
    'cheap': 'claude-haiku-4-5-20251001',
    'balanced': 'claude-sonnet-4-6',
    'reasoning': 'claude-opus-4-7',
}
model = tier_map.get(model_tier, model_tier)

with open(out_file, 'w') as f:
    f.write('---\n')
    f.write('name: ' + name + '\n')
    f.write('description: ' + description + '\n')
    f.write('model: ' + model + '\n')
    if tools:
        f.write('tools:\n')
        for t in tools:
            f.write('  - ' + t + '\n')
    f.write('---\n\n')
    f.write(template + '\n')
    f.write('\n' + managed_header + '\n')
PYEOF
        AGENTS_WRITTEN=$((AGENTS_WRITTEN + 1))
    done < <(find "$LITE_AGENTS_SRC" -maxdepth 1 -name "*.yaml" -print0 | sort -z)
    echo "  Agents: $AGENTS_WRITTEN written, $AGENTS_PRESERVED preserved (user-authored)"
else
    echo "  Agents: $LITE_AGENTS_SRC not found — skipping"
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
