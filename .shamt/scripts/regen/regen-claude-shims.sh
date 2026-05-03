#!/usr/bin/env bash
# =============================================================================
# regen-claude-shims.sh — Shamt Claude Code shim generator
# =============================================================================
# Transforms canonical Shamt content in .shamt/{skills,agents,commands}/ into
# Claude Code-shaped equivalents under .claude/{skills,agents,commands}/.
#
# Usage:
#   bash .shamt/scripts/regen/regen-claude-shims.sh
#
# Run from any directory — the script self-locates relative to its own path.
# Idempotent: safe to run multiple times; user-authored files (no managed
# header) are preserved.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SHAMT_DIR="$PROJECT_ROOT/.shamt"
CLAUDE_DIR="$PROJECT_ROOT/.claude"

MANAGED_HEADER="<!-- Managed by Shamt — do not edit. Run regen-claude-shims.sh to regenerate. -->"

# --- Determine repo type (master vs. child) -----------------------------------

REPO_TYPE_CONF="$SHAMT_DIR/config/repo_type.conf"
REPO_TYPE="child"
if [ -f "$REPO_TYPE_CONF" ]; then
    REPO_TYPE="$(tr -d '[:space:]' < "$REPO_TYPE_CONF")"
fi

# --- Determine PR provider ----------------------------------------------------

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
echo "  Shamt Regen — Claude Code Shims"
echo "============================================================"
echo "  Project: $PROJECT_ROOT"
echo "  Repo type: $REPO_TYPE"
echo "============================================================"
echo ""

# --- Helpers ------------------------------------------------------------------

is_shamt_managed() {
    local file="$1"
    [ -f "$file" ] && head -1 "$file" | grep -q "Managed by Shamt"
}

is_master_only() {
    local skill_file="$1"
    # Extract YAML frontmatter (between first and second ---) and check for master-only: true
    awk 'BEGIN{f=0} /^---$/{f++; next} f==1{print} f>=2{exit}' "$skill_file" \
        | grep -q "^master-only: true"
}

# --- Phase 1: Skills ----------------------------------------------------------

SKILLS_SRC="$SHAMT_DIR/skills"
SKILLS_DST="$CLAUDE_DIR/skills"
SKILLS_WRITTEN=0
SKILLS_SKIPPED=0
SKILLS_PRESERVED=0

if [ -d "$SKILLS_SRC" ]; then
    mkdir -p "$SKILLS_DST"
    while IFS= read -r -d '' skill_dir; do
        skill_name="$(basename "$skill_dir")"
        skill_src="$skill_dir/SKILL.md"
        skill_dst="$SKILLS_DST/$skill_name/SKILL.md"

        [ -f "$skill_src" ] || continue

        # Apply master-only filter on child projects
        if [ "$REPO_TYPE" = "child" ] && is_master_only "$skill_src"; then
            SKILLS_SKIPPED=$((SKILLS_SKIPPED + 1))
            continue
        fi

        # Preserve user-authored files (no managed header)
        if [ -f "$skill_dst" ] && ! is_shamt_managed "$skill_dst"; then
            SKILLS_PRESERVED=$((SKILLS_PRESERVED + 1))
            continue
        fi

        mkdir -p "$(dirname "$skill_dst")"
        {
            printf '%s\n' "$MANAGED_HEADER"
            cat "$skill_src"
        } > "$skill_dst"
        SKILLS_WRITTEN=$((SKILLS_WRITTEN + 1))
    done < <(find "$SKILLS_SRC" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)
    echo "  Skills: $SKILLS_WRITTEN written, $SKILLS_SKIPPED skipped (master-only on child), $SKILLS_PRESERVED preserved (user-authored)"
else
    echo "  Skills: .shamt/skills/ not found — skipping"
fi

# --- Phase 2: Agents ----------------------------------------------------------

AGENTS_SRC="$SHAMT_DIR/agents"
AGENTS_DST="$CLAUDE_DIR/agents"
AGENTS_WRITTEN=0
AGENTS_PRESERVED=0

if [ -d "$AGENTS_SRC" ]; then
    mkdir -p "$AGENTS_DST"
    while IFS= read -r -d '' yaml_file; do
        agent_name="$(basename "$yaml_file" .yaml)"
        agent_dst="$AGENTS_DST/$agent_name.md"

        # Preserve user-authored files (no managed header)
        if [ -f "$agent_dst" ] && ! is_shamt_managed "$agent_dst"; then
            AGENTS_PRESERVED=$((AGENTS_PRESERVED + 1))
            continue
        fi

        # Transform YAML to Claude Code agent markdown via inline Python3
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
description = extract_scalar('description', content)
model_tier = extract_scalar('model_tier', content)

# Extract tools_allowed list
tools = []
tools_m = re.search(r'^tools_allowed:(.*?)(?=^\S|\Z)', content, re.M | re.DOTALL)
if tools_m:
    tools = re.findall(r'^  - (\S+)\$', tools_m.group(1), re.M)

# Extract prompt_template literal block (style: |)
template = ''
pt_m = re.search(r'^prompt_template:\s*\|(.*)$', content, re.M | re.DOTALL)
if pt_m:
    lines = pt_m.group(1).split('\n')[1:]  # skip first (empty) line after |
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
    f.write(managed_header + '\n')
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
PYEOF
        AGENTS_WRITTEN=$((AGENTS_WRITTEN + 1))
    done < <(find "$AGENTS_SRC" -maxdepth 1 -name "*.yaml" -print0 | sort -z)
    echo "  Agents: $AGENTS_WRITTEN written, $AGENTS_PRESERVED preserved (user-authored)"
else
    echo "  Agents: .shamt/agents/ not found — skipping"
fi

# --- Phase 3: Commands --------------------------------------------------------

CMDS_SRC="$SHAMT_DIR/commands"
CMDS_DST="$CLAUDE_DIR/commands"
CMDS_WRITTEN=0
CMDS_PRESERVED=0

if [ -d "$CMDS_SRC" ]; then
    mkdir -p "$CMDS_DST"
    while IFS= read -r -d '' cmd_file; do
        cmd_name="$(basename "$cmd_file")"
        # Skip README.md — it's documentation, not a slash command
        [ "$cmd_name" = "README.md" ] && continue
        cmd_dst="$CMDS_DST/$cmd_name"

        # Preserve user-authored files (no managed header)
        if [ -f "$cmd_dst" ] && ! is_shamt_managed "$cmd_dst"; then
            CMDS_PRESERVED=$((CMDS_PRESERVED + 1))
            continue
        fi

        {
            printf '%s\n\n' "$MANAGED_HEADER"
            cat "$cmd_file"
        } > "$cmd_dst"
        CMDS_WRITTEN=$((CMDS_WRITTEN + 1))
    done < <(find "$CMDS_SRC" -maxdepth 1 -name "*.md" -print0 | sort -z)
    echo "  Commands: $CMDS_WRITTEN written, $CMDS_PRESERVED preserved (user-authored)"
else
    echo "  Commands: .shamt/commands/ not found — skipping"
fi

# --- Phase 4: Hooks + MCP registration ----------------------------------------
# Installs hook registrations and mcpServers.shamt into .claude/settings.json
# when features.shamt_hooks=true is set in settings.json.

SETTINGS_JSON="$CLAUDE_DIR/settings.json"
HOOKS_SRC="$SHAMT_DIR/hooks"

if [ -d "$HOOKS_SRC" ] && [ -f "$SETTINGS_JSON" ]; then
    python3 - "$SETTINGS_JSON" "$PROJECT_ROOT" "$HOOKS_SRC" "$REPO_TYPE" <<'PYEOF'
import sys, json
from pathlib import Path

settings_path, project_root, hooks_src, repo_type = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

with open(settings_path) as f:
    settings = json.load(f)

features = settings.get('features', {})
if not features.get('shamt_hooks', False):
    print("  Hooks: skipped (set features.shamt_hooks=true in .claude/settings.json to enable)")
    sys.exit(0)

root = Path(project_root)

def hook_cmd(name):
    return str(root / '.shamt' / 'hooks' / name)

hooks_block = {
    "PreToolUse": [
        {
            "matcher": "Bash",
            "hooks": [
                {"type": "command", "command": hook_cmd("no-verify-blocker.sh")},
                {"type": "command", "command": hook_cmd("commit-format.sh")},
                {"type": "command", "command": hook_cmd("pre-push-tripwire.sh")},
            ]
        },
        {
            "matcher": "Task",
            "hooks": [
                {"type": "command", "command": hook_cmd("architect-builder-enforcer.sh")},
            ]
        }
    ],
    "PostToolUse": [
        {
            "matcher": "Edit",
            "hooks": [
                {"type": "command", "command": hook_cmd("validation-log-stamp.sh")},
                {"type": "command", "command": hook_cmd("validation-stall-detector.sh")},
            ]
        }
    ],
    "UserPromptSubmit": [
        {
            "hooks": [
                {"type": "command", "command": hook_cmd("stage-transition-snapshot.sh")},
            ]
        }
    ],
    "PreCompact": [
        {
            "hooks": [
                {"type": "command", "command": hook_cmd("precompact-snapshot.sh")},
            ]
        }
    ],
    "SessionStart": [
        {
            "hooks": [
                {"type": "command", "command": hook_cmd("session-start-resume.sh")},
            ]
        }
    ],
    "SubagentStop": [
        {
            "hooks": [
                {"type": "command", "command": hook_cmd("subagent-confirmation-receipt.sh")},
            ]
        }
    ]
}

# Child projects only: add pre-export-audit-gate to UserPromptSubmit
if repo_type != 'master':
    hooks_block["UserPromptSubmit"][0]["hooks"].insert(0, {
        "type": "command", "command": hook_cmd("pre-export-audit-gate.sh")
    })
    # user-testing-gate in S9 push path (child-only, add to PreToolUse Bash)
    hooks_block["PreToolUse"][0]["hooks"].append({
        "type": "command", "command": hook_cmd("user-testing-gate.sh")
    })

settings["hooks"] = hooks_block

managed = settings.get("_shamt_managed_blocks", [])
if "hooks" not in managed:
    managed.append("hooks")
settings["_shamt_managed_blocks"] = managed

# Register MCP server if venv exists
venv_python = root / '.shamt' / 'mcp' / '.venv' / 'bin' / 'python'
if venv_python.exists():
    settings.setdefault("mcpServers", {})["shamt"] = {
        "command": str(venv_python),
        "args": ["-m", "shamt_mcp"],
        "env": {}
    }
    mcp_status = f"registered ({venv_python})"
else:
    mcp_status = "skipped (venv not found — see .shamt/mcp/README.md)"

# Register ADO MCP server if pr_provider.conf contains "ado"
pr_provider = "$PR_PROVIDER"
ado_org = "$ADO_ORG"
if "ado" in pr_provider and ado_org:
    settings.setdefault("mcpServers", {})["ado"] = {
        "command": "npx",
        "args": ["-y", "@azure-devops/mcp", ado_org, "-d", "core", "repositories"],
        "type": "stdio"
    }
    print(f"  MCP ADO: registered (org={ado_org}, domains=core,repositories)")
elif "ado" in pr_provider and not ado_org:
    print(f"  MCP ADO: skipped (ado_org.txt not found — run init.sh --pr-provider=ado to set org name)")

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

print(f"  Hooks: installed")
print(f"  MCP: {mcp_status}")
PYEOF
    # Ensure hook scripts are executable
    find "$HOOKS_SRC" -name "*.sh" -exec chmod +x {} \;
else
    echo "  Hooks + MCP: skipped (.shamt/hooks/ or .claude/settings.json not found)"
fi

# --- Phase 5: Tailored cheat sheet -------------------------------------------
# Generates .shamt/CHEATSHEET.md filtered to this project's config.

EPIC_TAG_CONF="$SHAMT_DIR/config/epic_tag.conf"
AI_SERVICE_CONF="$SHAMT_DIR/config/ai_service.conf"

CHEATSHEET_EPIC_TAG="SHAMT-N"
if [ -f "$EPIC_TAG_CONF" ]; then
    CHEATSHEET_EPIC_TAG="$(tr -d '[:space:]' < "$EPIC_TAG_CONF")"
fi

CHEATSHEET_AI_SERVICE="claude_code"
if [ -f "$AI_SERVICE_CONF" ]; then
    CHEATSHEET_AI_SERVICE="$(tr -d '[:space:]' < "$AI_SERVICE_CONF")"
fi

CHEATSHEET_OUT="$SHAMT_DIR/CHEATSHEET.md"
CHEATSHEET_SETTINGS="$CLAUDE_DIR/settings.json"

python3 - "$CHEATSHEET_OUT" "$CHEATSHEET_EPIC_TAG" "$CHEATSHEET_AI_SERVICE" "$PR_PROVIDER" "$REPO_TYPE" "$CHEATSHEET_SETTINGS" <<'PYEOF'
import sys, json

out_path, epic_tag, ai_service, pr_provider, repo_type, settings_path = \
    sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]

hooks_enabled = False
mcp_enabled = False
try:
    with open(settings_path) as f:
        settings = json.load(f)
    hooks_enabled = settings.get('features', {}).get('shamt_hooks', False)
    mcp_enabled = 'shamt' in settings.get('mcpServers', {})
except (FileNotFoundError, json.JSONDecodeError):
    print("  ⚠  settings.json missing or malformed — optional features disabled in cheat sheet")

has_github = pr_provider in ('github', 'both') or not pr_provider
has_ado = pr_provider in ('ado', 'both')

lines = []
lines.append('<!-- Generated by Shamt regen — do not edit. Run regen-claude-shims.sh (or regen-codex-shims.sh) to update. -->')
lines.append('')
lines.append('# Cheat Sheet')
lines.append('')

lines.append('## Git Conventions')
lines.append('')
lines.append(f'- Branch: `feat/{epic_tag}-N` or `fix/{epic_tag}-N`')
lines.append(f'- Commit: `feat/{epic_tag}-N: message` or `fix/{epic_tag}-N: message`')
lines.append('- Default branch: `main`')
lines.append('')

lines.append('## Slash Commands')
lines.append('')
lines.append('- `/shamt-start-epic` — start a new epic')
lines.append('- `/shamt-validate` — run validation loop (use with `/loop`)')
lines.append('- `/shamt-audit` — run guide audit (use with `/loop`)')
lines.append('- `/shamt-status` — check current epic status')
lines.append('- `/shamt-resume` — resume from snapshot')
lines.append('- `/shamt-export` — export changes to master')
lines.append('- `/shamt-import` — sync updates from master')
if repo_type == 'master':
    lines.append('- `/shamt-promote` — promote child design doc to master')
lines.append('')

lines.append('## Validation Rules')
lines.append('')
lines.append('- Clean round: ZERO issues OR exactly ONE LOW fixed')
lines.append('- Multiple LOWs or any MEDIUM/HIGH/CRITICAL → `consecutive_clean` resets to 0')
lines.append('- Workflow validation exit: `consecutive_clean=1` + 2 Haiku sub-agent confirmations')
lines.append('- Guide audit exit: `consecutive_clean=3` (three consecutive clean rounds)')
lines.append('')

lines.append('## Stage Flow')
lines.append('')
stage_flow = 'S1 Discovery → S2 Deep Dive → S3 Alignment → S4 Contracts → S5 Plan → S6 Build → S7 QA → S8 Merge → S9 Epic Test → S10 Cleanup'
if repo_type != 'master':
    stage_flow += ' → S11 Export'
lines.append(stage_flow)
lines.append('')

lines.append('## Key Personas')
lines.append('')
lines.append('| Persona | Role | Model tier |')
lines.append('|---------|------|-----------|')
lines.append('| `shamt-validator` | Validation, QC rounds | Haiku |')
lines.append('| `shamt-builder` | S6 implementation execution | Haiku |')
lines.append('| `shamt-architect` | Planning, design decisions | Opus |')
lines.append('| `shamt-guide-auditor` | Guide audit dimensions | Sonnet/Opus |')
lines.append('| `shamt-code-reviewer` | Code review | Sonnet |')
if repo_type != 'master':
    lines.append('| `shamt-spec-aligner` | Spec alignment (child only) | Sonnet |')
    lines.append('| `shamt-discovery-researcher` | S1 discovery (child only) | Sonnet |')
lines.append('')

if hooks_enabled:
    lines.append('## Active Enforcement Hooks')
    lines.append('')
    lines.append('| Hook | Purpose |')
    lines.append('|------|---------|')
    lines.append(f'| `commit-format.sh` | Enforces `feat/{epic_tag}-N:` commit prefix |')
    lines.append('| `no-verify-blocker.sh` | Blocks `--no-verify` / `--no-gpg-sign` |')
    lines.append('| `pre-push-tripwire.sh` | Guards push: audit clean + validation non-zero |')
    lines.append('| `validation-log-stamp.sh` | Auto-stamps validation logs on edit |')
    lines.append('| `validation-stall-detector.sh` | Alerts when `consecutive_clean=0` stalls |')
    lines.append('| `architect-builder-enforcer.sh` | S6: rejects non-`shamt-builder` Task spawns |')
    lines.append('| `precompact-snapshot.sh` | Writes `RESUME_SNAPSHOT.md` before compaction |')
    lines.append('| `session-start-resume.sh` | Injects snapshot context on session start |')
    lines.append('')

if mcp_enabled:
    lines.append('## MCP Tools')
    lines.append('')
    lines.append('| Tool | Purpose |')
    lines.append('|------|---------|')
    lines.append('| `shamt.validation_round(...)` | Track `consecutive_clean` across rounds |')
    lines.append('| `shamt.audit_run()` | Record guide audit result for pre-push tripwire |')
    lines.append('| `shamt.next_number()` | Atomically reserve next SHAMT-N number |')
    lines.append('| `shamt.metrics_append()` | Emit metrics to sidecar.jsonl and OTel |')
    lines.append('| `shamt.epic_status()` | Query active epic state |')
    lines.append('')

if 'codex' in ai_service:
    lines.append('## Codex Tips')
    lines.append('')
    lines.append('- Switch profiles at stage transitions: `codex --profile shamt-sN`')
    lines.append('- Stage transitions are natural session boundaries on Codex')
    lines.append('- Cloud S6 builder: architect commits validated plan, launches Codex Cloud task')
    lines.append('')

if 'claude' in ai_service:
    lines.append('## Claude Code Tips')
    lines.append('')
    lines.append('- `/loop` with `/shamt-validate` self-paces validation rounds')
    lines.append('- Use `run_in_background=true` for builder sub-agents in S6')
    lines.append('- Status line: `EPIC-N | S{stage}.P{phase} | round {N} | blocker: {text}`')
    lines.append('')

if has_github:
    lines.append('## GitHub CI')
    lines.append('')
    lines.append('- `.github/workflows/shamt-validate.yml` — PR validation gate (requires `OPENAI_API_KEY` secret)')
    lines.append('- `.github/workflows/shamt-cron-janitor.yml` — weekly stale-work scanner')
    lines.append('')

if has_ado:
    lines.append('## ADO CI / PR Review')
    lines.append('')
    lines.append('- `azure-pipelines/shamt-validate.yml` — PR validation gate (requires `OPENAI_API_KEY` variable)')
    lines.append('- `azure-pipelines/shamt-cron-janitor.yml` — weekly stale-work scanner')
    lines.append('- ADO MCP: Azure DevOps MCP integration for interactive PR review (see canonical `/CHEATSHEET` for details)')
    lines.append('')

with open(out_path, 'w') as f:
    f.write('\n'.join(lines))
    f.write('\n')
PYEOF

# Write .shamt/.gitignore unconditionally — ensures CHEATSHEET.md stays untracked
# whether .shamt/ itself is tracked or excluded at the repo level
printf 'CHEATSHEET.md\n' > "$SHAMT_DIR/.gitignore"

echo "  Cheat sheet: generated (.shamt/CHEATSHEET.md)"

echo ""
echo "  ✓ Regen complete"
echo ""
