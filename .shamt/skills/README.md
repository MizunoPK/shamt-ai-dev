# Skills — Authoring Conventions

Skills are host-portable behavior packs encoding Shamt protocols. Each skill lives in its own subdirectory and distills one or more source guides into a self-contained, triggerable artifact.

## Directory Structure

```
.shamt/skills/
├── README.md                          (this file)
├── shamt-validation-loop/SKILL.md
├── shamt-architect-builder/SKILL.md
├── shamt-spec-protocol/SKILL.md
├── shamt-code-review/SKILL.md
├── shamt-guide-audit/SKILL.md
├── shamt-discovery/SKILL.md
├── shamt-import/SKILL.md
├── shamt-export/SKILL.md
├── shamt-master-reviewer/SKILL.md     (master-only)
└── shamt-lite-story/SKILL.md
```

## SKILL.md Format

Every SKILL.md must begin with a YAML frontmatter block:

```yaml
---
name: shamt-validation-loop
description: Run Shamt validation loops on any artifact — spec, plan, design doc, or code
triggers:
  - "run validation"
  - "validate this"
  - "start validation loop"
  - "validation loop"
source_guides:
  - guides/reference/validation_loop_master_protocol.md
  - guides/reference/severity_classification_universal.md
master-only: false
---
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Kebab-case skill identifier (matches directory name) |
| `description` | yes | One-sentence description of what this skill does |
| `triggers` | yes | Neutral trigger phrases; regen scripts translate to host format |
| `source_guides` | yes | Every guide file this skill body was distilled from (relative paths from `.shamt/`); this is the input to the D-DRIFT audit dimension |
| `master-only` | no | Set `true` for skills that must not be wired to child projects. Default `false`. |

### Trigger Format Note

Use neutral trigger phrases in the `triggers:` list — not Claude Code-specific syntax (no `!` prefix, no `$ARGUMENTS` syntax). Regen scripts in SHAMT-40 (Claude Code) and SHAMT-42 (Codex) translate these to host-specific trigger formats at deployment time.

## Self-Containment Requirement

**Each SKILL.md must be self-contained.** An agent reading only the SKILL.md should be able to execute the protocol without consulting the source guide. Skill bodies are distillations, not cross-references.

✅ Correct: SKILL.md contains the full protocol steps, exit criteria, and examples needed to run the skill.  
❌ Wrong: SKILL.md says "see validation_loop_master_protocol.md for the full protocol."

Skill bodies may include back-references to source guides for deeper context (e.g., "for complete dimension checklists, see `guides/reference/validation_loop_master_protocol.md`"), but must not depend on those references for executability.

## Bidirectional Coverage Expectation

Every skill must correspond to guide content that actually exists in `.shamt/guides/`. Major guide sections should have corresponding skills. Both directions are enforced by the guide audit:

- **D-DRIFT**: Reads each SKILL.md's `source_guides:` frontmatter and compares key protocol steps against the referenced guide files. Flags divergences (MEDIUM for prose drift; HIGH for missing or contradicted steps).
- **D-COVERAGE**: Walks `.shamt/guides/` and flags guide files with no corresponding skill as LOW-severity candidates. Also flags skills whose source guides don't cover the skill's stated protocol steps (reverse gap).

When updating a source guide, update the corresponding skill body in the same commit. When adding a new guide section that introduces a distinct protocol, consider whether a new skill is warranted.

## Skill Body Structure (Recommended)

```markdown
---
[frontmatter]
---

## Overview
[One paragraph: what this skill does, when to invoke it, what it produces]

## When This Skill Triggers
[Trigger semantics — what user or agent context causes this skill to be invoked]

## Protocol

### Step 1: [First step]
[Details]

### Step 2: [Second step]
[Details]

...

## Exit Criteria
[What "done" means — output format, validation standard, etc.]

## Quick Reference
[Optional: summary table, cheat-sheet format for key rules]
```

## Adding New Skills

1. Create `.shamt/skills/<name>/` directory
2. Author `SKILL.md` with complete frontmatter + self-contained protocol body
3. Add the `source_guides:` list naming every guide the skill draws from
4. Update this README's directory listing above
5. Run the guide audit D-COVERAGE check to confirm bidirectional coverage

## Master-Only Skills

Skills with `master-only: true` (currently `shamt-master-reviewer`) are synced to child projects via `shamt import` (children receive the latest content) but are not wired to `.claude/skills/` or Codex on child projects. The wiring skip is in the regen scripts (SHAMT-40 / SHAMT-42), not in the sync layer.
