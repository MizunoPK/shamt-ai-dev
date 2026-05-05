# Regen Scripts

This directory contains the shim generator scripts that transform canonical Shamt content
into host-specific files for Claude Code, Codex, and Cursor (full-Shamt and Shamt Lite).

## Overview

After `init.sh`, `init_lite.sh`, or `import.sh` runs, the canonical Shamt content lives in:
- `.shamt/skills/` — skill bodies (SKILL.md files)
- `.shamt/agents/` — agent persona definitions (YAML files)
- `.shamt/commands/` — slash command bodies (markdown files)
- `.shamt/scripts/initialization/lite/` — Shamt Lite commands, agents, profiles, and rules

Each regen script reads from canonical source directories and writes host-specific equivalents.

## Scripts

| Script | Platform | Host | Description |
|--------|----------|------|-------------|
| `regen-claude-shims.sh` | Linux / Mac | Claude Code | Full-Shamt skills, agents, commands → `.claude/` |
| `regen-claude-shims.ps1` | Windows | Claude Code | PowerShell port of the above |
| `regen-codex-shims.sh` | Linux / Mac | Codex | Full-Shamt skills → `.agents/skills/`, agents/profiles/hooks → `.codex/` |
| `regen-codex-shims.ps1` | Windows | Codex | PowerShell port of the above |
| `cleanup-codex-prompts-interim.sh` | Linux / Mac | Codex | One-time removal of stale `~/.codex/prompts/shamt-*.md` after SHAMT-53 migration |
| `cleanup-codex-prompts-interim.ps1` | Windows | Codex | PowerShell port of the above |
| `regen-lite-claude.sh` | Linux / Mac | Claude Code (Lite) | Shamt Lite skills, commands, agents → `.claude/` |
| `regen-lite-claude.ps1` | Windows | Claude Code (Lite) | PowerShell port of the above |
| `regen-lite-codex.sh` | Linux / Mac | Codex (Lite) | Shamt Lite skills → `.agents/skills/`, agents + profiles → `.codex/` |
| `regen-lite-codex.ps1` | Windows | Codex (Lite) | PowerShell port of the above |
| `regen-lite-cursor.sh` | Linux / Mac | Cursor (Lite) | Shamt Lite skills, commands, rules (`.mdc`), agents → `.cursor/` |
| `regen-lite-cursor.ps1` | Windows | Cursor (Lite) | PowerShell port of the above |

## When to Run

| Script | Run automatically by | Also run manually when |
|--------|---------------------|----------------------|
| `regen-claude-shims.sh/.ps1` | `import.sh` (when `ai_service.conf = claude_code`) | After editing canonical skills/agents/commands |
| `regen-codex-shims.sh/.ps1` | `import.sh` (when `ai_service.conf = codex` or `claude_codex`) | After editing canonical skills/agents/commands |
| `regen-lite-claude.sh/.ps1` | `init_lite.sh --host=claude` | After updating Lite canonical content in master |
| `regen-lite-codex.sh/.ps1` | `init_lite.sh --host=codex` | After updating Lite canonical content in master |
| `regen-lite-cursor.sh/.ps1` | `init_lite.sh --host=cursor` | After updating Lite canonical content in master |

## Usage

Run full-Shamt scripts from any directory — they self-locate relative to their own path:

```bash
bash .shamt/scripts/regen/regen-claude-shims.sh
bash .shamt/scripts/regen/regen-codex-shims.sh
```

Run Lite scripts from the child project root:

```bash
bash /path/to/shamt-ai-dev/.shamt/scripts/regen/regen-lite-claude.sh
bash /path/to/shamt-ai-dev/.shamt/scripts/regen/regen-lite-cursor.sh
```

## Full-Shamt: Claude Code Transform Conventions

### Skills

Each `.shamt/skills/<name>/SKILL.md` → `.claude/skills/<name>/SKILL.md`.

- Managed header prepended as first line.
- SKILL.md content (frontmatter + body) copied verbatim.
- The neutral `triggers:` frontmatter is preserved — Claude Code reads it to auto-trigger the skill.
- Skills with `master-only: true` frontmatter are **skipped on child projects**.

### Agents

Each `.shamt/agents/<name>.yaml` → `.claude/agents/<name>.md`.

YAML transform:
- `model_tier:` mapped to Claude model ID: `cheap` → `claude-haiku-4-5-20251001`, `balanced` → `claude-sonnet-4-6`, `reasoning` → `claude-opus-4-7`
- `tools_allowed:` → `tools:` list
- `prompt_template:` literal block → agent body after frontmatter `---`

### Commands

Each `.shamt/commands/<name>.md` → `.claude/commands/<name>.md`. Managed header prepended.
`{placeholder}` notation is documentation-style; Claude reads arguments from invocation context.

### Cheat Sheet

`regen-claude-shims.sh` generates `.shamt/CHEATSHEET.md` filtered by `ai_service.conf`,
`pr_provider.conf`, `repo_type.conf`, and `features.shamt_hooks` (SHAMT-49).

## Full-Shamt: Codex Transform Conventions

### Skills (Phase 1)

Each `.shamt/skills/<name>/SKILL.md` → `.agents/skills/<name>/SKILL.md` (project-local,
Codex Skills GA since December 2025). The skill directory name is the full canonical name
(e.g., `shamt-validator`), so the deployed path is `.agents/skills/shamt-validator/SKILL.md`.

- Managed header prepended as first line.
- Skills with `master-only: true` frontmatter are **skipped on child projects**.

### Agents (Phase 2)

Each `.shamt/agents/<name>.yaml` → `.codex/agents/<name>.toml`.

YAML → TOML transform:
- `model_tier:` → `model:` mapped to `FRONTIER_MODEL` (reasoning/balanced) or `DEFAULT_MODEL` (cheap)
- `reasoning_effort:` → `model_reasoning_effort:`
- `sandbox:` → `sandbox_mode:`
- `tools_allowed:` list → `tools_allowed = [...]`
- `prompt_template:` literal block → `prompt = """..."""`

Model names resolved from `.shamt/host/codex/.model_resolution.local.toml` (gitignored).

### Commands (Phase 3)

Each `.shamt/commands/<name>.md` → `~/.codex/prompts/<name>.md` (per-user).

- `{placeholder}` → `$PLACEHOLDER` (Codex prompt syntax).
- Commands deploy to `~/.codex/prompts/` — **NOT** to `.agents/skills/`.

### Profiles, Hooks, MCP (Phase 4)

Profile fragments from `.shamt/host/codex/profiles/*.fragment.toml` concatenated into the
`SHAMT-PROFILES` block in `.codex/config.toml`. Hooks → `SHAMT-HOOKS`. MCP → `SHAMT-MCP`.

## SHAMT-53 Cleanup Script

After upgrading to SHAMT-53, run once to remove stale skill files from the old per-user
`~/.codex/prompts/shamt-*.md` location:

```bash
bash .shamt/scripts/regen/cleanup-codex-prompts-interim.sh
```

The script checks each `~/.codex/prompts/shamt-*.md` against `.agents/skills/`. Removes if
a matching SKILL.md exists; warns and leaves in place if not (run regen first in that case).

## Shamt Lite: Claude Code (`regen-lite-claude.sh/.ps1`)

Deploys to `.claude/{skills,commands,agents}/`:
- Skills: Lite skills (filter `shamt-lite-*`) with managed header
- Commands: from `lite/commands/*.md`
- Agents: from `lite/agents/*.yaml` (YAML → Claude Code agent md)
- Cheat sheet: reads `shamt-lite/config/ai_service.conf`; generates `shamt-lite/CHEATSHEET.md` with service-specific slash commands and quick reference

## Shamt Lite: Codex (`regen-lite-codex.sh/.ps1`)

Deploys to `.agents/skills/`, `.codex/agents/`, and `.codex/config.toml`:
- Skills: Lite skills (filter `shamt-lite-*`) → `.agents/skills/<name>/SKILL.md`
- Agents: from `lite/agents/*.yaml` (YAML → TOML) → `.codex/agents/<name>.toml`
- Profiles: from `lite/profiles-codex/*.fragment.toml` → SHAMT-LITE-PROFILES block
- Cheat sheet: reads `shamt-lite/config/ai_service.conf`; generates `shamt-lite/CHEATSHEET.md` with service-specific quick reference

## Shamt Lite: Cursor (`regen-lite-cursor.sh/.ps1`)

Deploys to `.cursor/{skills,commands,rules,agents}/`:
- Skills: Lite skills with `paths:` frontmatter injected; `{cheap-tier}` substituted in
  `<parameter name="model">` XML tags using model from the project's `.model_resolution.local.toml`
- Commands: from `lite/commands/*.md`
- Rules: from `lite/rules-cursor/*.mdc` — 5 attachment-aware `.mdc` files
- Agents: from `lite/agents/*.yaml` (YAML → Cursor agent md)
- Cheat sheet: reads `shamt-lite/config/ai_service.conf`; generates `shamt-lite/CHEATSHEET.md` with service-specific quick reference

## Managed Header

Every Shamt-generated file begins with a managed header line:
```
<!-- Managed by Shamt — do not edit. Run regen-<host>-shims.sh to regenerate. -->
```
(Codex TOML files use `#` comment syntax instead.)

The regen script reads the first line of any existing file before overwriting. If the first
line does NOT contain "Managed by Shamt", the file is **user-authored** and is **preserved**.

## Version Control

Generated shim files in `.claude/skills/`, `.claude/agents/`, `.claude/commands/`,
`.agents/skills/`, and `.cursor/` are **committed to version control** — they behave like
lock files, not build artifacts.

Full-Shamt regen runs automatically on `import.sh`; Lite regen scripts run at `init_lite.sh`
time and must be re-run manually after updates to Lite canonical content in master.

`.gitignore` excludes only machine-specific files (`.claude/settings.json`,
`.shamt/host/codex/.model_resolution.local.toml`) — not the generated shim directories.

## Idempotence

Running any regen script multiple times produces identical output. Safe to re-run after any
update to canonical content.

## Stale Shim Files

If a skill or command is removed from `.shamt/`, its previously-generated shim file persists
until manually removed. Stale shims are identifiable by the managed header — any Shamt-managed
file whose source no longer exists is stale.
