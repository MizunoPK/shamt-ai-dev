#!/usr/bin/env bash
# =============================================================================
# regen-lite-cursor.sh — Shamt Lite Cursor shim generator
# =============================================================================
# Deploys Shamt Lite canonical content into a child project's .cursor/ tree:
#   Skills   → <TARGET>/.cursor/skills/<name>/SKILL.md   (filter: shamt-lite-*)
#   Commands → <TARGET>/.cursor/commands/<name>.md
#   Rules    → <TARGET>/.cursor/rules/lite-*.mdc
#   Agents   → <TARGET>/.cursor/agents/<name>.md         (YAML → Cursor md)
#
# Source content lives in this master shamt-ai-dev repo:
#   Skills   .shamt/skills/shamt-lite-*/SKILL.md
#   Commands .shamt/scripts/initialization/lite/commands/*.md
#   Rules    .shamt/scripts/initialization/lite/rules-cursor/*.mdc
#   Agents   .shamt/scripts/initialization/lite/agents/*.yaml
#
# Usage (from the child project root):
#   bash /path/to/shamt-ai-dev/.shamt/scripts/regen/regen-lite-cursor.sh
#
# Idempotent: files with no Shamt-managed header are preserved.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHAMT_SOURCE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"   # master shamt-ai-dev root
SHAMT_DIR="$SHAMT_SOURCE_DIR/.shamt"
TARGET_DIR="$(pwd)"
CURSOR_DIR="$TARGET_DIR/.cursor"

LITE_CMDS_SRC="$SHAMT_DIR/scripts/initialization/lite/commands"
LITE_AGENTS_SRC="$SHAMT_DIR/scripts/initialization/lite/agents"
LITE_RULES_SRC="$SHAMT_DIR/scripts/initialization/lite/rules-cursor"
SKILLS_SRC="$SHAMT_DIR/skills"

MANAGED_HEADER="<!-- Managed by Shamt — do not edit. Run regen-lite-cursor.sh to regenerate. -->"

# --- Read model resolution ---------------------------------------------------
# Primary: .shamt/host/cursor/ (full-Shamt projects or explicit placement)
# Fallback: shamt-lite/host/cursor/ (Lite-only projects)

CHEAP_MODEL="inherit"
for _mrf in \
    "$TARGET_DIR/.shamt/host/cursor/.model_resolution.local.toml" \
    "$TARGET_DIR/shamt-lite/host/cursor/.model_resolution.local.toml"; do
    if [ -f "$_mrf" ]; then
        _val=$(grep '^CHEAP_MODEL' "$_mrf" 2>/dev/null | cut -d'"' -f2)
        if [ -n "$_val" ]; then
            CHEAP_MODEL="$_val"
        fi
        break
    fi
done

echo ""
echo "============================================================"
echo "  Shamt Lite Regen — Cursor Shims"
echo "============================================================"
echo "  Source: $SHAMT_SOURCE_DIR"
echo "  Target: $TARGET_DIR"
echo "  Cursor cheap-tier model: $CHEAP_MODEL"
echo "============================================================"
echo ""

is_shamt_managed() {
    local file="$1"
    [ -f "$file" ] && grep -q "Managed by Shamt" "$file"
}

# Return the paths: value to inject into a skill's frontmatter, or empty string.
get_cursor_paths() {
    case "$1" in
        shamt-lite-spec)    echo "stories/**/spec.md, **/ticket*.md" ;;
        shamt-lite-plan)    echo "stories/**/implementation_plan.md" ;;
        shamt-lite-review)  echo "stories/**/code_review/**" ;;
        *)                  echo "" ;;
    esac
}

# --- Phase 1: Skills (filter shamt-lite-*) -----------------------------------

SKILLS_DST="$CURSOR_DIR/skills"
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

        cursor_paths="$(get_cursor_paths "$skill_name")"

        # Substitute {cheap-tier} ONLY inside <parameter name="model">...</parameter> XML
        # tags so deployed XML examples carry the project's CHEAP_MODEL. The
        # explanatory footnote (which references `{cheap-tier}` as inline code) is preserved.
        if [ -n "$cursor_paths" ]; then
            # Inject paths: into YAML frontmatter (after the first ---) + {cheap-tier} substitution
            {
                awk -v paths="paths: $cursor_paths" \
                    'NR==1 { print; print paths; next } { print }' "$skill_src" \
                | sed "s|<parameter name=\"model\">{cheap-tier}</parameter>|<parameter name=\"model\">$CHEAP_MODEL</parameter>|g"
                printf '\n%s\n' "$MANAGED_HEADER"
            } > "$skill_dst"
        else
            {
                sed "s|<parameter name=\"model\">{cheap-tier}</parameter>|<parameter name=\"model\">$CHEAP_MODEL</parameter>|g" "$skill_src"
                printf '\n%s\n' "$MANAGED_HEADER"
            } > "$skill_dst"
        fi

        SKILLS_WRITTEN=$((SKILLS_WRITTEN + 1))
    done < <(find "$SKILLS_SRC" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)
    echo "  Skills: $SKILLS_WRITTEN written, $SKILLS_PRESERVED preserved (user-authored)"
else
    echo "  Skills: $SKILLS_SRC not found — skipping"
fi

# --- Phase 2: Commands -------------------------------------------------------

CMDS_DST="$CURSOR_DIR/commands"
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

# --- Phase 3: Rules (.mdc files) → .cursor/rules/ ---------------------------

RULES_DST="$CURSOR_DIR/rules"
RULES_WRITTEN=0
RULES_PRESERVED=0

if [ -d "$LITE_RULES_SRC" ]; then
    mkdir -p "$RULES_DST"
    while IFS= read -r -d '' mdc_file; do
        mdc_name="$(basename "$mdc_file")"
        mdc_dst="$RULES_DST/$mdc_name"

        if [ -f "$mdc_dst" ] && ! is_shamt_managed "$mdc_dst"; then
            RULES_PRESERVED=$((RULES_PRESERVED + 1))
            continue
        fi

        {
            cat "$mdc_file"
            printf '\n%s\n' "$MANAGED_HEADER"
        } > "$mdc_dst"
        RULES_WRITTEN=$((RULES_WRITTEN + 1))
    done < <(find "$LITE_RULES_SRC" -maxdepth 1 -name "*.mdc" -print0 | sort -z)
    echo "  Rules: $RULES_WRITTEN written, $RULES_PRESERVED preserved (user-authored)"
else
    echo "  Rules: $LITE_RULES_SRC not found — skipping"
fi

# --- Phase 4: Agents (YAML → Cursor agent md) --------------------------------

AGENTS_DST="$CURSOR_DIR/agents"
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

        python3 - "$yaml_file" "$agent_dst" "$CHEAP_MODEL" <<PYEOF
import sys, re

yaml_file = sys.argv[1]
out_file = sys.argv[2]
cheap_model = sys.argv[3]
managed_header = "$MANAGED_HEADER"

with open(yaml_file, 'r') as f:
    content = f.read()

def extract_scalar(field, text):
    m = re.search(r'^' + re.escape(field) + r':\s*(.+)$', text, re.M)
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
    tools = re.findall(r'^  - (\S+)$', tools_m.group(1), re.M)

template = ''
pt_m = re.search(r'^prompt_template:\s*\|(.*)', content, re.M | re.DOTALL)
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

# Map model tier to Cursor model id
# cheap → CHEAP_MODEL (inherit by default, or user-configured value)
# balanced/reasoning → inherit (Cursor picks based on context)
tier_map = {
    'cheap': cheap_model,
    'balanced': 'inherit',
    'reasoning': 'inherit',
}
model = tier_map.get(model_tier, 'inherit')

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

echo ""
echo "  ✓ Lite regen complete"
echo ""
