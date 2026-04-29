# Regen Scripts

This directory contains the Claude Code shim generator scripts that transform canonical Shamt content into Claude Code-specific host files.

## Overview

After `init.sh` or `import.sh` runs, the canonical Shamt content lives in:
- `.shamt/skills/` — skill bodies (SKILL.md files)
- `.shamt/agents/` — agent persona definitions (YAML files)
- `.shamt/commands/` — slash command bodies (markdown files)

`regen-claude-shims.sh` reads from those directories and writes Claude Code-shaped equivalents under:
- `.claude/skills/` — skills with managed header prepended
- `.claude/agents/` — agents transformed from YAML to Claude Code agent markdown
- `.claude/commands/` — command bodies with managed header prepended

## Scripts

| Script | Platform | Description |
|--------|----------|-------------|
| `regen-claude-shims.sh` | Linux / Mac | Main regen script (bash) |
| `regen-claude-shims.ps1` | Windows | PowerShell port |

## Usage

Run from any directory — the script self-locates relative to its own path:

```bash
bash .shamt/scripts/regen/regen-claude-shims.sh
```

Or from the project root:
```bash
bash .shamt/scripts/regen/regen-claude-shims.sh
```

## Transform Conventions

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

## Managed Header

Every Shamt-generated file begins with:
```
<!-- Managed by Shamt — do not edit. Run regen-claude-shims.sh to regenerate. -->
```

The regen script reads the first line of any existing file in `.claude/skills/`, `.claude/agents/`, `.claude/commands/`. If the first line does NOT contain "Managed by Shamt", the file is **user-authored** and is **preserved** (not overwritten).

## Version Control

Generated shim files in `.claude/skills/`, `.claude/agents/`, `.claude/commands/` are **committed to version control** — they behave like lock files, not build artifacts. After each `shamt import` that changes canonical content, regen runs automatically and the resulting changes in `.claude/` should be staged and committed. This ensures the exact set of deployed shims is visible in git history and child project members all use the same shims without needing to run regen themselves.

`.gitignore` excludes only `.claude/settings.json` and `.claude/settings.local.json` (machine-specific) — not the generated shim directories.

## Idempotence

Running the regen script multiple times produces identical output. Diff between two consecutive runs is always empty (assuming no changes to source content).

## Stale Shim Files

If a skill or command is removed from `.shamt/`, its previously-generated shim file in `.claude/` persists until manually removed. Stale shims are identifiable by the managed header — any Shamt-managed file whose source no longer exists in `.shamt/` is stale.

## When to Run

- **After `shamt import`** — `import.sh` automatically runs regen when `ai_service.conf` records `claude_code`.
- **After manually editing canonical content** — run regen to propagate changes to `.claude/`.
- **After adding a new skill or agent to master** — regen picks it up on the next run.
- **On the master repo after each SHAMT implementation** — Phase 7.5 of each SHAMT design doc that affects canonical content.
