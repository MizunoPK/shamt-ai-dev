# Regen Scripts

This directory contains the shim generator scripts that transform canonical Shamt content
into host-specific files for Claude Code, Codex, and Cursor.

## Overview

After `init.sh` or `import.sh` runs, the canonical Shamt content lives in:
- `.shamt/skills/` — skill bodies (SKILL.md files)
- `.shamt/agents/` — agent persona definitions (YAML files)
- `.shamt/commands/` — slash command bodies (markdown files)

Each host-specific regen script reads from those directories and writes host-shaped equivalents.

## Scripts

| Script | Platform | Host | Description |
|--------|----------|------|-------------|
| `regen-claude-shims.sh` | Linux / Mac | Claude Code | Full-Shamt skills, agents, commands → `.claude/` |
| `regen-claude-shims.ps1` | Windows | Claude Code | PowerShell port of the above |
| `regen-codex-shims.sh` | Linux / Mac | Codex | Full-Shamt skills, agents, commands, profiles, hooks → `.agents/skills/`, `.codex/` |
| `regen-codex-shims.ps1` | Windows | Codex | PowerShell port of the above |
| `cleanup-codex-prompts-interim.sh` | Linux / Mac | Codex | One-time cleanup of stale `~/.codex/prompts/shamt-*.md` files after SHAMT-53 migration |
| `cleanup-codex-prompts-interim.ps1` | Windows | Codex | PowerShell port of the above |

## Usage

Run from any directory — scripts self-locate relative to their own path:

```bash
bash .shamt/scripts/regen/regen-claude-shims.sh
bash .shamt/scripts/regen/regen-codex-shims.sh
```

Run automatically by `import.sh` based on `ai_service.conf`:
- `claude_code` → runs `regen-claude-shims.sh`
- `codex` or `claude_codex` → runs `regen-codex-shims.sh`

## Claude Code: Transform Conventions

### Skills

Each `.shamt/skills/<name>/SKILL.md` becomes `.claude/skills/<name>/SKILL.md`.

- The managed header is prepended as the first line.
- The SKILL.md content (frontmatter + body) is copied verbatim.
- The neutral `triggers:` frontmatter is preserved — Claude Code reads it directly to auto-trigger the skill.
- Skills with `master-only: true` frontmatter are **skipped on child projects** (not written to `.claude/skills/`). On the master repo, they are written normally.

### Agents

Each `.shamt/agents/<name>.yaml` becomes `.claude/agents/<name>.md`.

The YAML is transformed:
- `name:` → `name:` in Claude Code agent frontmatter
- `description:` → `description:`
- `model_tier:` → `model:` with the tier mapped to a model ID:
  - `cheap` → `claude-haiku-4-5-20251001`
  - `balanced` → `claude-sonnet-4-6`
  - `reasoning` → `claude-opus-4-7`
- `tools_allowed:` list → `tools:` list in Claude Code format
- `prompt_template:` (literal block) → agent body (after the frontmatter `---`)

### Commands

Each `.shamt/commands/<name>.md` becomes `.claude/commands/<name>.md`.

- The managed header is prepended (with a blank line after it).
- The command body is copied verbatim.
- `{placeholder}` notation in command bodies is documentation-style; Claude reads the argument from the invocation context.

## Codex: Transform Conventions

### Skills (Phase 1)

Each `.shamt/skills/<name>/SKILL.md` becomes `.agents/skills/<name>/SKILL.md` (project-local,
Codex Skills GA since December 2025). The skill directory name is the full canonical name
(e.g., `shamt-validator`), so the deployed path is `.agents/skills/shamt-validator/SKILL.md`.

- The managed header is prepended as the first line.
- Skills with `master-only: true` frontmatter are **skipped on child projects**.

### Agents (Phase 2)

Each `.shamt/agents/<name>.yaml` becomes `.codex/agents/<name>.toml` (project-local).

The YAML is transformed to TOML:
- `model_tier:` → `model:` mapped to `FRONTIER_MODEL` (reasoning/balanced) or `DEFAULT_MODEL` (cheap)
- `reasoning_effort:` → `model_reasoning_effort:`
- `sandbox:` → `sandbox_mode:`
- `tools_allowed:` list → `tools_allowed = [...]`
- `prompt_template:` (literal block) → `prompt = """`...`"""`

Model names are resolved from `.shamt/host/codex/.model_resolution.local.toml` (gitignored).

### Commands (Phase 3)

Each `.shamt/commands/<name>.md` becomes `~/.codex/prompts/<name>.md` (per-user).

- `{placeholder}` notation is translated to `$PLACEHOLDER` (Codex prompt syntax).
- Commands remain in `~/.codex/prompts/` — they are NOT deployed to `.agents/skills/`.

### Profiles, Hooks, MCP (Phase 4)

Profile fragments from `.shamt/host/codex/profiles/*.fragment.toml` are concatenated into the
`SHAMT-PROFILES` block in `.codex/config.toml`. Hooks and MCP server registration are written
to `SHAMT-HOOKS` and `SHAMT-MCP` blocks respectively.

## Cleanup Script (SHAMT-53 migration)

After upgrading to SHAMT-53, run the cleanup script once to remove stale skill files from the
old per-user `~/.codex/prompts/` location:

```bash
bash .shamt/scripts/regen/cleanup-codex-prompts-interim.sh
```

The script checks each `~/.codex/prompts/shamt-*.md` against the project `.agents/skills/`
directory. Files with a matching `.agents/skills/<name>/SKILL.md` are removed. Files with no
match are warned and left in place (run regen first if this happens).

## Managed Header

Every Shamt-generated file begins with a managed header line. The regen script reads the first
line of any existing file before overwriting. If the first line does NOT contain "Managed by
Shamt", the file is **user-authored** and is **preserved** (not overwritten).

## Version Control

Generated shim files in `.claude/skills/`, `.claude/agents/`, `.claude/commands/` and
`.agents/skills/` are **committed to version control** — they behave like lock files, not build
artifacts. After each `shamt import` that changes canonical content, regen runs automatically
and the resulting changes should be staged and committed.

`.gitignore` excludes only machine-specific files (`.claude/settings.json`,
`.claude/settings.local.json`, `.shamt/host/codex/.model_resolution.local.toml`) — not the
generated shim directories.

## Idempotence

Running any regen script multiple times produces identical output. Diff between two consecutive
runs is always empty (assuming no changes to source content).

## Stale Shim Files

If a skill or command is removed from `.shamt/`, its previously-generated shim file persists
until manually removed. Stale shims are identifiable by the managed header — any Shamt-managed
file whose source no longer exists in `.shamt/` is stale.

## When to Run

- **After `shamt import`** — `import.sh` automatically runs the appropriate regen script.
- **After manually editing canonical content** — run regen to propagate changes to the host.
- **After adding a new skill or agent to master** — regen picks it up on the next run.
- **On the master repo after each SHAMT implementation** — any SHAMT that affects canonical content.
