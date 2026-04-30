# Host Directory — Claude Code

This directory contains Claude Code-specific host wiring artifacts authored by Shamt.

## Contents

| File | Purpose |
|------|---------|
| `settings.starter.json` | Starter `.claude/settings.json` written by `init.sh` on first init |
| `README.md` | This file |

## settings.starter.json

Written to `.claude/settings.json` by `init.sh` when Claude Code is the selected AI service. Contains:

- **statusLine** — Wires `shamt-statusline.sh` as the Claude Code status bar renderer. Displays active epic, stage, round, and blocker in real time.
- **hooks** — Empty placeholder block. SHAMT-41 fills this in with the pre-tool-call validation hook and post-tool-call logging hook.
- **mcpServers** — Empty placeholder block. SHAMT-43 fills this in with MCP server registrations.
- **_shamt_managed_blocks** — Array of top-level keys that Shamt is allowed to update on subsequent operations. Starts with `["statusLine"]`; SHAMT-41 adds `"hooks"` and `"mcpServers"` when it installs those blocks.

## Init behavior

At init time, `init.sh` copies `settings.starter.json` to `.claude/settings.json` with `${PROJECT}` resolved to the absolute project root path.

If `.claude/settings.json` already exists:
- If `_shamt_managed_blocks` is present → Shamt blocks already merged; skip overwrite.
- If `_shamt_managed_blocks` is absent → Shamt blocks not merged; init prints a manual merge instruction.

## User ownership

After init, `.claude/settings.json` is **user-owned**. Shamt only updates the keys listed in `_shamt_managed_blocks`. All other keys are untouched by Shamt operations (init, import, regen).

## Regen does not touch settings.json

`regen-claude-shims.sh` regenerates `.claude/skills/`, `.claude/agents/`, and `.claude/commands/` but never modifies `.claude/settings.json`. The settings file is written once at init and updated only by explicit SHAMT-N design doc implementations (SHAMT-41 for hooks, SHAMT-43 for MCP).
