# Slash Commands — Format and Conventions

Slash commands are user-invocable Shamt operations. Each command body lives in `.shamt/commands/<name>.md`. Regen scripts copy command bodies to host-specific locations at deployment time.

## Directory Structure

```
.shamt/commands/
├── README.md                          (this file)
├── CHEATSHEET.md                      (user-facing quick reference — not a command)
├── shamt-start-epic.md
├── shamt-validate.md
├── shamt-audit.md
├── shamt-export.md
├── shamt-import.md
├── shamt-status.md
├── shamt-resume.md
└── shamt-promote.md                   (master-only)
```

## Host Deployment

Regen scripts copy command bodies verbatim (no substitution) to host-specific locations:

**Claude Code** → `.claude/commands/<name>.md`  
**Codex** → `~/.codex/prompts/<name>.md`

`CHEATSHEET.md` is copied verbatim to both locations. It is not a command — it is a user-facing reference card.

## Command Body Format

Each command body markdown file documents:
1. **Purpose** — one sentence on what the command does
2. **Invocation** — how the user calls it and what arguments it accepts
3. **What it invokes** — the skill name or script path being triggered
4. **Argument shape** — each argument described with type and whether required
5. **Expected output** — what the agent should produce after running the command
6. **Wrap relationship** — if the command is a thin wrapper over a skill, state this explicitly

### Argument Substitution Syntax

Use `{name}` curly-brace syntax for argument placeholders in command bodies. This is the canonical format — regen scripts translate to host-specific syntax if needed (e.g., `$ARGUMENTS` for Codex custom-prompts).

```markdown
## Arguments

- `{artifact}` (required) — relative or absolute path to the artifact to validate
- `{scope}` (optional) — guide subdirectory to scope the audit to (default: all of `.shamt/guides/`)
```

### Command Body Template

```markdown
# /shamt-{name}

**Purpose:** One sentence describing what this command does.

**Invokes:** `shamt-{skill}` skill (or `scripts/{path}.sh`)

---

## Usage

```
/shamt-{name} {argument}
```

## Arguments

- `{argument}` — description, required vs optional, expected format

## What Happens

Step-by-step description of what the agent does when this command is invoked:

1. [First action]
2. [Second action]
3. ...

## Expected Output

Description of what the agent produces — files created, text output, next steps.

## Notes

Any edge cases, restrictions, or related commands.
```

## Command Scope: Master-Only Commands

`shamt-promote` is master-only — it promotes incoming child proposals to design docs. The `.shamt/commands/` directory is NOT synced via `shamt import` / `shamt export` — those only sync `guides/` and `scripts/`. Command bodies reach child projects via `init.sh` (fresh init) or the regen scripts (SHAMT-40 / SHAMT-42). Child regen scripts skip wiring the `shamt-promote` command.

## CHEATSHEET.md

`CHEATSHEET.md` is the user-facing quick reference. It is NOT a command — it has no invocation syntax. It is deployed verbatim alongside command bodies. Content:

- **Command table**: all slash commands with one-line descriptions
- **S1–S11 stage flow**: key artifact per stage
- **Sub-agent persona quick reference**: name, tier, use case

CHEATSHEET.md grows with each SHAMT-N that adds user-visible operational patterns.

## Adding New Commands

1. Create `.shamt/commands/<name>.md` using the template above
2. Determine if master-only and note it in the command body
3. Update `CHEATSHEET.md` command table with the new command
4. Update this README's directory listing
