#!/usr/bin/env bash
# =============================================================================
# regen-codex-shims.sh — Shamt Codex shim generator
# =============================================================================
# Transforms canonical Shamt content in .shamt/{skills,agents,commands}/ into
# Codex-shaped equivalents:
#   Skills   → ~/.codex/prompts/shamt-<name>.md       (interim; see README)
#   Agents   → .codex/agents/<name>.toml              (project-local)
#   Commands → ~/.codex/prompts/<name>.md             (interim)
#   Profiles → .codex/config.toml SHAMT-PROFILES block
#   Hooks    → .codex/config.toml SHAMT-HOOKS block
#   MCP      → .codex/config.toml SHAMT-MCP block (when venv present)
#
# Usage:
#   bash .shamt/scripts/regen/regen-codex-shims.sh
#
# Run from any directory — the script self-locates relative to its own path.
# Idempotent: safe to run multiple times.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SHAMT_DIR="$PROJECT_ROOT/.shamt"
CODEX_DIR="$PROJECT_ROOT/.codex"
CODEX_PROMPTS_DIR="$HOME/.codex/prompts"

MANAGED_HEADER="# Managed by Shamt — do not edit. Run regen-codex-shims.sh to regenerate."

# --- Determine repo type -------------------------------------------------------

REPO_TYPE_CONF="$SHAMT_DIR/config/repo_type.conf"
REPO_TYPE="child"
if [ -f "$REPO_TYPE_CONF" ]; then
    REPO_TYPE="$(tr -d '[:space:]' < "$REPO_TYPE_CONF")"
fi

PR_PROVIDER_CONF="$SHAMT_DIR/config/pr_provider.conf"
PR_PROVIDER="github"
if [ -f "$PR_PROVIDER_CONF" ]; then
    PR_PROVIDER="$(tr -d '[:space:]' < "$PR_PROVIDER_CONF")"
fi

ADO_ORG_CONF="$SHAMT_DIR/config/ado_org.txt"
ADO_ORG=""
if [ -f "$ADO_ORG_CONF" ]; then
    ADO_ORG="$(tr -d '[:space:]' < "$ADO_ORG_CONF")"
fi

echo ""
echo "============================================================"
echo "  Shamt Regen — Codex Shims"
echo "============================================================"
echo "  Project: $PROJECT_ROOT"
echo "  Repo type: $REPO_TYPE"
echo "============================================================"
echo ""

# --- Read model resolution ----------------------------------------------------

MODEL_RESOLUTION="$SHAMT_DIR/host/codex/.model_resolution.local.toml"
FRONTIER_MODEL="o3"
DEFAULT_MODEL="o4-mini"
if [ -f "$MODEL_RESOLUTION" ]; then
    _fm="$(grep '^FRONTIER_MODEL' "$MODEL_RESOLUTION" 2>/dev/null | cut -d'"' -f2 || echo "")"
    _dm="$(grep '^DEFAULT_MODEL' "$MODEL_RESOLUTION" 2>/dev/null | cut -d'"' -f2 || echo "")"
    [ -n "$_fm" ] && FRONTIER_MODEL="$_fm"
    [ -n "$_dm" ] && DEFAULT_MODEL="$_dm"
fi

echo "  Models: FRONTIER=$FRONTIER_MODEL  DEFAULT=$DEFAULT_MODEL"
echo ""

# --- Helpers ------------------------------------------------------------------

is_shamt_managed() {
    local file="$1"
    [ -f "$file" ] && head -1 "$file" | grep -q "Managed by Shamt"
}

is_master_only() {
    local skill_file="$1"
    awk 'BEGIN{f=0} /^---$/{f++; next} f==1{print} f>=2{exit}' "$skill_file" \
        | grep -q "^master-only: true"
}

substitute_models() {
    sed -e "s|\${FRONTIER_MODEL}|$FRONTIER_MODEL|g" \
        -e "s|\${DEFAULT_MODEL}|$DEFAULT_MODEL|g"
}

# --- Phase 1: Skills → ~/.codex/prompts/shamt-<name>.md ----------------------
# Interim location: ~/.codex/prompts/ (custom-prompts directory).
# Invoked as /prompts:shamt-<name> in a Codex session.
# Migration: update this phase when Codex's skills surface stabilizes.

SKILLS_SRC="$SHAMT_DIR/skills"
SKILLS_WRITTEN=0
SKILLS_SKIPPED=0

if [ -d "$SKILLS_SRC" ]; then
    mkdir -p "$CODEX_PROMPTS_DIR"
    while IFS= read -r -d '' skill_dir; do
        skill_name="$(basename "$skill_dir")"
        skill_src="$skill_dir/SKILL.md"
        skill_dst="$CODEX_PROMPTS_DIR/shamt-${skill_name}.md"

        [ -f "$skill_src" ] || continue

        if [ "$REPO_TYPE" = "child" ] && is_master_only "$skill_src"; then
            SKILLS_SKIPPED=$((SKILLS_SKIPPED + 1))
            continue
        fi

        {
            printf '%s\n' "$MANAGED_HEADER"
            cat "$skill_src"
        } > "$skill_dst"
        SKILLS_WRITTEN=$((SKILLS_WRITTEN + 1))
    done < <(find "$SKILLS_SRC" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)
    echo "  Skills: $SKILLS_WRITTEN written to ~/.codex/prompts/, $SKILLS_SKIPPED skipped (master-only on child)"
else
    echo "  Skills: .shamt/skills/ not found — skipping"
fi

# --- Phase 2: Agents → .codex/agents/<name>.toml ------------------------------
# YAML → TOML transform: model_tier mapped to Codex model name.

AGENTS_SRC="$SHAMT_DIR/agents"
AGENTS_WRITTEN=0

# Model tier → Codex model name mapping
tier_to_model() {
    case "$1" in
        cheap)     echo "$DEFAULT_MODEL" ;;
        balanced)  echo "$FRONTIER_MODEL" ;;
        reasoning) echo "$FRONTIER_MODEL" ;;
        *)         echo "$1" ;;
    esac
}

if [ -d "$AGENTS_SRC" ]; then
    mkdir -p "$CODEX_DIR/agents"
    while IFS= read -r -d '' yaml_file; do
        agent_name="$(basename "$yaml_file" .yaml)"
        agent_dst="$CODEX_DIR/agents/${agent_name}.toml"

        python3 - "$yaml_file" "$agent_dst" "$FRONTIER_MODEL" "$DEFAULT_MODEL" <<'PYEOF'
import sys, re

yaml_file, out_file, frontier_model, default_model = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
managed_header = "# Managed by Shamt — do not edit. Run regen-codex-shims.sh to regenerate."

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

# Extract tools_allowed list
tools = []
tools_m = re.search(r'^tools_allowed:(.*?)(?=^\S|\Z)', content, re.M | re.DOTALL)
if tools_m:
    tools = re.findall(r'^  - (\S+)$', tools_m.group(1), re.M)

# Extract prompt_template literal block
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
    done < <(find "$AGENTS_SRC" -maxdepth 1 -name "*.yaml" -print0 | sort -z)
    echo "  Agents: $AGENTS_WRITTEN written to .codex/agents/"
else
    echo "  Agents: .shamt/agents/ not found — skipping"
fi

# --- Phase 3: Commands → ~/.codex/prompts/ ------------------------------------
# Canonical {name} argument substitution translated to $NAME (Codex prompt syntax).

CMDS_SRC="$SHAMT_DIR/commands"
CMDS_WRITTEN=0

if [ -d "$CMDS_SRC" ]; then
    mkdir -p "$CODEX_PROMPTS_DIR"
    while IFS= read -r -d '' cmd_file; do
        cmd_name="$(basename "$cmd_file")"
        [ "$cmd_name" = "README.md" ] && continue
        [ "$cmd_name" = "CHEATSHEET.md" ] && continue
        cmd_dst="$CODEX_PROMPTS_DIR/$cmd_name"

        {
            printf '%s\n\n' "$MANAGED_HEADER"
            # Translate {placeholder} → $PLACEHOLDER
            sed 's/{\([a-zA-Z_][a-zA-Z0-9_]*\)}/$\U\1/g' "$cmd_file"
        } > "$cmd_dst"
        CMDS_WRITTEN=$((CMDS_WRITTEN + 1))
    done < <(find "$CMDS_SRC" -maxdepth 1 -name "*.md" -print0 | sort -z)

    # CHEATSHEET.md: deploy as-is (no argument substitution needed)
    if [ -f "$CMDS_SRC/CHEATSHEET.md" ]; then
        {
            printf '%s\n\n' "$MANAGED_HEADER"
            cat "$CMDS_SRC/CHEATSHEET.md"
        } > "$CODEX_PROMPTS_DIR/CHEATSHEET.md"
        CMDS_WRITTEN=$((CMDS_WRITTEN + 1))
    fi

    echo "  Commands: $CMDS_WRITTEN written to ~/.codex/prompts/"
else
    echo "  Commands: .shamt/commands/ not found — skipping"
fi

# --- Phase 4: Profiles + Hooks + MCP → .codex/config.toml -------------------
# Updates the three managed blocks in config.toml idempotently.

CONFIG_TOML="$CODEX_DIR/config.toml"
PROFILES_SRC="$SHAMT_DIR/host/codex/profiles"

if [ -f "$CONFIG_TOML" ] && [ -d "$PROFILES_SRC" ]; then
    python3 - "$CONFIG_TOML" "$PROFILES_SRC" "$PROJECT_ROOT" "$REPO_TYPE" \
              "$FRONTIER_MODEL" "$DEFAULT_MODEL" <<'PYEOF'
import sys, os, re
from pathlib import Path

config_path, profiles_src, project_root, repo_type, frontier_model, default_model = \
    sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]

with open(config_path) as f:
    config = f.read()

# --- Helper: replace between markers -----------------------------------------

def replace_block(text, start_marker, end_marker, new_content):
    pattern = re.compile(
        r'(# ={13,}\n# ' + re.escape(start_marker) + r'.*?\n# ={13,}\n)'
        r'.*?'
        r'(# ={13,}\n# ' + re.escape(end_marker) + r'\n# ={13,})',
        re.DOTALL
    )
    replacement = r'\g<1>\n' + new_content + '\n' + r'\g<2>'
    result, count = pattern.subn(replacement, text)
    if count == 0:
        # Fallback: simple comment marker
        pattern2 = re.compile(
            r'# ' + re.escape(start_marker) + r'.*?'
            r'# ' + re.escape(end_marker),
            re.DOTALL
        )
        replacement2 = '# ' + start_marker + '\n\n' + new_content + '\n\n# ' + end_marker
        result, count2 = pattern2.subn(replacement2, text)
        if count2 == 0:
            return text  # markers not found; leave unchanged
    return result

# --- Build profiles block -----------------------------------------------------

profiles_lines = []
fragment_files = sorted(Path(profiles_src).glob('*.fragment.toml'))
for fpath in fragment_files:
    frag = fpath.read_text()
    frag = frag.replace('${FRONTIER_MODEL}', frontier_model)
    frag = frag.replace('${DEFAULT_MODEL}', default_model)
    profiles_lines.append(frag.rstrip())
    profiles_lines.append('')  # blank line between fragments

# Append S5 MCP server if venv present
venv_python = Path(project_root) / '.shamt' / 'mcp' / '.venv' / 'bin' / 'python'
if venv_python.exists():
    profiles_lines.append(f'[profiles.shamt-s5.mcp_servers.shamt]')
    profiles_lines.append(f'command = "{venv_python}"')
    profiles_lines.append(f'args = ["-m", "shamt_mcp"]')
    profiles_lines.append('')

profiles_content = '\n'.join(profiles_lines)

# --- Build MCP block ----------------------------------------------------------

mcp_lines = []
if venv_python.exists():
    mcp_lines += [
        '[mcp_servers.shamt]',
        f'command = "{venv_python}"',
        'args = ["-m", "shamt_mcp"]',
        '',
    ]
    mcp_status = f"registered ({venv_python})"
else:
    mcp_status = "skipped (venv not found — see .shamt/mcp/README.md)"

pr_provider = "$PR_PROVIDER"
ado_org = "$ADO_ORG"
if "ado" in pr_provider and ado_org:
    mcp_lines += [
        '[mcp_servers.ado]',
        'command = "npx"',
        f'args = ["-y", "@azure-devops/mcp", "{ado_org}", "-d", "core", "repositories"]',
        'type = "stdio"',
        '',
    ]
    print(f"  MCP ADO: registered (org={ado_org})")
elif "ado" in pr_provider:
    print(f"  MCP ADO: skipped (ado_org.txt not found)")

mcp_content = '\n'.join(mcp_lines)

# --- Build hooks block --------------------------------------------------------

hooks_src = Path(project_root) / '.shamt' / 'hooks'
hooks_content = ''

if not hooks_src.exists():
    print("  Hooks: skipped (.shamt/hooks/ not found)")
else:
    def hook_cmd(name):
        return str(hooks_src / name)

    hooks_lines = []

    # pre_tool_use: shell (Bash-equivalent)
    pre_shell = [hook_cmd('no-verify-blocker.sh'), hook_cmd('commit-format.sh'), hook_cmd('pre-push-tripwire.sh')]
    if repo_type != 'master':
        pre_shell += [hook_cmd('user-testing-gate.sh'), hook_cmd('pre-export-audit-gate.sh')]
    hooks_lines += ['[hooks.pre_tool_use.shell]']
    hooks_lines += ['commands = [']
    for h in pre_shell:
        hooks_lines += [f'  "{h}",']
    hooks_lines += [']', '']

    # pre_tool_use: agent_spawn (Task-equivalent)
    hooks_lines += [
        '[hooks.pre_tool_use.agent_spawn]',
        f'commands = ["{hook_cmd("architect-builder-enforcer.sh")}"]',
        '',
    ]

    # post_tool_use: edit
    hooks_lines += [
        '[hooks.post_tool_use.edit]',
        'commands = [',
        f'  "{hook_cmd("validation-log-stamp.sh")}",',
        f'  "{hook_cmd("validation-stall-detector.sh")}",',
        ']',
        '',
    ]

    # user_prompt_submit
    upm_hooks = []
    if repo_type != 'master':
        upm_hooks.append(hook_cmd('pre-export-audit-gate.sh'))
    upm_hooks.append(hook_cmd('stage-transition-snapshot.sh'))
    hooks_lines += ['[hooks.user_prompt_submit]', 'commands = [']
    for h in upm_hooks:
        hooks_lines += [f'  "{h}",']
    hooks_lines += [']', '']

    # session_start
    hooks_lines += [
        '[hooks.session_start]',
        f'commands = ["{hook_cmd("session-start-resume.sh")}"]',
        '',
    ]

    # stop (SubagentStop equivalent via Stop hook with stdin-parsing)
    hooks_lines += [
        '[hooks.stop]',
        f'commands = ["{hook_cmd("subagent-confirmation-receipt.sh")}"]',
        '',
    ]

    # permission_request (Codex-only)
    hooks_lines += [
        '[hooks.permission_request]',
        f'commands = ["{hook_cmd("permission-router.sh")}"]',
        '',
    ]

    hooks_content = '\n'.join(hooks_lines)

# --- Apply blocks to config ---------------------------------------------------

config = replace_block(config, 'SHAMT-PROFILES-START — managed by regen-codex-shims.sh; do not edit manually',
                                'SHAMT-PROFILES-END', profiles_content)
config = replace_block(config, 'SHAMT-MCP-START — managed by regen-codex-shims.sh; do not edit manually',
                                'SHAMT-MCP-END', mcp_content)
config = replace_block(config, 'SHAMT-HOOKS-START — managed by regen-codex-shims.sh; do not edit manually',
                                'SHAMT-HOOKS-END', hooks_content)

with open(config_path, 'w') as f:
    f.write(config)

print(f"  Profiles: {len(fragment_files)} fragments written")
print(f"  MCP: {mcp_status}")
if hooks_content:
    print(f"  Hooks: installed")
PYEOF
    # Ensure hook scripts are executable (only if hooks dir was copied)
    if [ -d "$SHAMT_DIR/hooks" ]; then
        find "$SHAMT_DIR/hooks" -name "*.sh" -exec chmod +x {} \;
    fi
else
    echo "  Profiles + Hooks + MCP: skipped (.codex/config.toml or .shamt/host/codex/profiles/ not found)"
fi

echo ""
echo "  ✓ Regen complete"
echo ""
