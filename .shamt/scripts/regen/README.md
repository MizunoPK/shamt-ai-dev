# Regen Scripts

This directory contains the shim generator scripts that transform canonical Shamt content into host-specific files for Claude Code, Codex, and Cursor (Lite).

## Overview

After `init.sh`, `init_lite.sh`, or `import.sh` runs, the canonical Shamt content lives in:
- `.shamt/skills/` — skill bodies (SKILL.md files)
- `.shamt/agents/` — agent persona definitions (YAML files)
- `.shamt/commands/` — slash command bodies (markdown files)
- `.shamt/scripts/initialization/lite/` — Shamt Lite commands, agents, and rules

Each regen script reads from canonical source directories and writes host-specific equivalents.

## Scripts

| Script | Platform | Description |
|--------|----------|-------------|
| `regen-claude-shims.sh` | Linux / Mac | Claude Code: deploys skills, agents, commands to `.claude/` |
| `regen-claude-shims.ps1` | Windows | PowerShell port of `regen-claude-shims.sh` |
| `regen-codex-shims.sh` | Linux / Mac | Codex: deploys skills to `~/.codex/prompts/`, agents to `.codex/agents/`, writes SHAMT-HOOKS/SHAMT-PROFILES blocks |
| `regen-codex-shims.ps1` | Windows | PowerShell port of `regen-codex-shims.sh` |
| `regen-lite-claude.sh` | Linux / Mac | Shamt Lite for Claude Code: deploys lite skills, commands, agents to `.claude/` |
| `regen-lite-claude.ps1` | Windows | PowerShell port of `regen-lite-claude.sh` |
| `regen-lite-codex.sh` | Linux / Mac | Shamt Lite for Codex: deploys lite skills, agents, and SHAMT-LITE-PROFILES block |
| `regen-lite-codex.ps1` | Windows | PowerShell port of `regen-lite-codex.sh` |
| `regen-lite-cursor.sh` | Linux / Mac | Shamt Lite for Cursor: deploys lite skills, commands, rules (`.mdc`), agents to `.cursor/` |
| `regen-lite-cursor.ps1` | Windows | PowerShell port of `regen-lite-cursor.sh` |

## When to Run Each Script

| Script | Run automatically by | Also run manually when |
|--------|---------------------|----------------------|
| `regen-claude-shims.sh/.ps1` | `import.sh` (when `ai_service.conf = claude_code`) | After manually editing canonical skills/agents/commands |
| `regen-codex-shims.sh/.ps1` | `import.sh` (when `ai_service.conf = codex` or `claude_codex`) | After manually editing canonical skills/agents/commands |
| `regen-lite-claude.sh/.ps1` | `init_lite.sh --host=claude` | After updating Lite canonical content in master |
| `regen-lite-codex.sh/.ps1` | `init_lite.sh --host=codex` | After updating Lite canonical content in master |
| `regen-lite-cursor.sh/.ps1` | `init_lite.sh --host=cursor` | After updating Lite canonical content in master |

## Usage

Run from the child project root (for full-Shamt scripts):

```bash
bash .shamt/scripts/regen/regen-claude-shims.sh
```

Run from the child project root (for Lite scripts):

```bash
bash /path/to/shamt-ai-dev/.shamt/scripts/regen/regen-lite-cursor.sh
```

All scripts are self-locating — they resolve paths relative to their own location, not the current working directory.

## Transform Conventions

### Full Shamt — Claude Code (`regen-claude-shims.sh/.ps1`)

Each `.shamt/skills/<name>/SKILL.md` → `.claude/skills/<name>/SKILL.md`.

- Managed header prepended as first line.
- SKILL.md content (frontmatter + body) copied verbatim.
- Skills with `master-only: true` skipped on child projects.

Each `.shamt/agents/<name>.yaml` → `.claude/agents/<name>.md`.

YAML transform:
- `model_tier:` mapped to Claude model ID: `cheap` → `claude-haiku-4-5-20251001`, `balanced` → `claude-sonnet-4-6`, `reasoning` → `claude-opus-4-7`
- `tools_allowed:` → `tools:` list

Each `.shamt/commands/<name>.md` → `.claude/commands/<name>.md`. Header prepended.

Cheat sheet (SHAMT-49): generates `.shamt/CHEATSHEET.md` filtered by ai_service, pr_provider, repo_type, and features.

### Full Shamt — Codex (`regen-codex-shims.sh/.ps1`)

- Skills → `~/.codex/prompts/shamt-<name>.md`
- Agents → `.codex/agents/<name>.toml` (YAML → TOML transform)
- Commands → `~/.codex/prompts/`; translates `{placeholder}` → `$PLACEHOLDER`
- Profiles: concatenates `.shamt/host/codex/profiles/*.fragment.toml` into `.codex/config.toml` SHAMT-PROFILES block
- Hooks: writes SHAMT-HOOKS block in `.codex/config.toml`

### Shamt Lite — Claude Code (`regen-lite-claude.sh/.ps1`)

Deploys to `.claude/{skills,commands,agents}/`:
- Skills: Lite skills (filter `shamt-lite-*`) with managed header
- Commands: from `lite/commands/*.md`
- Agents: from `lite/agents/*.yaml` (YAML → Claude Code agent md)

### Shamt Lite — Codex (`regen-lite-codex.sh/.ps1`)

Deploys to `.agents/skills/`, `.codex/agents/`, and `.codex/config.toml`:
- Skills: Lite skills (filter `shamt-lite-*`) with managed header → `.agents/skills/<name>/SKILL.md`
- Agents: from `lite/agents/*.yaml` (YAML → TOML) → `.codex/agents/<name>.toml`
- Profiles: from `lite/profiles-codex/*.fragment.toml` → SHAMT-LITE-PROFILES block in `.codex/config.toml`

### Shamt Lite — Cursor (`regen-lite-cursor.sh/.ps1`)

Deploys to `.cursor/{skills,commands,rules,agents}/`:
- Skills: Lite skills with `paths:` frontmatter injected for spec/plan/review; `{cheap-tier}` substituted in `<parameter name="model">` XML tags using model from `.shamt/host/cursor/.model_resolution.local.toml` (full-Shamt projects) or `shamt-lite/host/cursor/.model_resolution.local.toml` (Lite-only projects)
- Commands: from `lite/commands/*.md`
- Rules: from `lite/rules-cursor/*.mdc` — 5 attachment-aware `.mdc` files
- Agents: from `lite/agents/*.yaml` (YAML → Cursor agent md via embedded Python transform)

## Managed Header

Every Shamt-generated file ends with (or begins with, for Claude Code):
```
<!-- Managed by Shamt — do not edit. Run regen-<host>-shims.sh to regenerate. -->
```

Files without the managed header are user-authored and are preserved (not overwritten).

## Idempotence

All regen scripts are idempotent — running multiple times produces identical output. Safe to re-run after any update to canonical content.

## Stale Shim Files

If a skill or command is removed from `.shamt/`, its previously-generated shim file persists until manually removed. Stale shims are identifiable by the managed header — any Shamt-managed file whose source no longer exists is stale.

## Version Control

Generated shim files in `.claude/`, `.codex/`, and `.cursor/` are committed to version control — they behave like lock files. After each `shamt import` that changes canonical content, full-Shamt regen runs automatically (see When to Run table above); Lite regen scripts are not triggered by import and must be re-run manually or via `init_lite.sh`. Stage and commit the resulting shim changes.
