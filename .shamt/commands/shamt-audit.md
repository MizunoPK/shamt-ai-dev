# /shamt-audit

**Purpose:** Run the Shamt guide audit on the entire `.shamt/guides/` tree (or a scoped subdirectory), checking all 23 dimensions plus D-DRIFT and D-COVERAGE for skill bodies.

**Invokes:** `shamt-guide-audit` skill

---

## Usage

```
/shamt-audit
/shamt-audit {scope}
```

## Arguments

- `{scope}` (optional) — subdirectory path to scope the audit to. Default: all of `.shamt/guides/` including all subdirectories. Examples:
  - `.shamt/guides/reference/` — audit only reference guides
  - `.shamt/guides/code_review/` — audit only code review guides

## What Happens

1. The agent loads the `shamt-guide-audit` skill
2. Walks the scoped directory tree (default: all of `.shamt/guides/`)
3. Runs audit rounds using the 23-dimension sub-round structure:
   - Sub-round N.1: Core dimensions D1-D4 (cross-references, terminology, workflow integration, CLAUDE.md sync)
   - Sub-round N.2: Content dimensions D5-D9 + D23 (counts, completeness, templates, quality, accuracy, architecture currency)
   - Sub-round N.3: Structural dimensions D10-D14 (intra-file, file size, patterns, dependencies, format)
   - Sub-round N.4: Advanced dimensions D15-D22 (context-sensitivity, duplication, accessibility, flow, rules alignment, scripts, comprehension risk, bypass risk)
   - D-DRIFT: reads each SKILL.md's `source_guides:` and compares key steps against source guide files
   - D-COVERAGE: walks `.shamt/guides/` and flags uncovered guides as LOW candidates
4. Fixes all issues found immediately
5. Continues until **3 consecutive clean rounds** (guide audits use the higher bar — not 1+sub-agents)

## Expected Output

- Issues fixed inline across all affected guide files
- Audit summary documenting all rounds and `consecutive_clean` counter
- Final status: AUDIT COMPLETE with 3 consecutive clean rounds

## Notes

- Guide audits require **3 consecutive clean rounds** — not the 1+2-sub-agents pattern used by workflow validation loops. Do not exit early.
- Uses model delegation: Haiku for mechanical checks, Sonnet for structural analysis, Opus for content and advanced dimensions
- MANDATORY after any changes to `.shamt/guides/` files (e.g., after a master import, after implementing a design doc)
- For very large guide trees or sessions likely to span many rounds, prefix with `/loop` to enable context-checkpoint recovery between rounds. Not required for typical use.
