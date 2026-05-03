# /shamt-validate

**Purpose:** Run a Shamt validation loop on any artifact — spec, implementation plan, design doc, or code review file.

**Invokes:** `shamt-validation-loop` skill

---

## Usage

```
/shamt-validate {artifact}
```

## Arguments

- `{artifact}` (required) — relative or absolute path to the artifact to validate. Examples:
  - `.shamt/epics/EPIC-001/features/auth/spec.md`
  - `design_docs/active/SHAMT39_DESIGN.md`
  - `.shamt/epics/EPIC-001/features/auth/implementation_plan.md`

## What Happens

1. The agent loads the `shamt-validation-loop` skill
2. Creates a `VALIDATION_LOG.md` in the same directory as the artifact (if one does not already exist)
3. Reads the artifact in full
4. Runs all applicable validation dimensions (7 master + scenario-specific)
5. Fixes any issues found immediately, then re-reads with fresh eyes
6. Continues until a primary clean round is achieved (consecutive_clean = 1)
7. Spawns 2 independent Haiku sub-agents in parallel for confirmation
8. If both confirm zero issues: declares validation complete
9. If either finds an issue: fixes and continues

## Expected Output

- `VALIDATION_LOG.md` next to the artifact, documenting all rounds
- Artifact is updated with any fixes made during validation
- Final status: VALIDATED with exit criterion met

## Notes

- Scenario-specific dimensions are auto-detected from the artifact type (spec → D8-D10; implementation plan → D8-D12; design doc → 7 dimensions)
- To validate a design doc, prefer `/shamt-validate` over running the design doc validation workflow manually — the skill handles dimension selection
- For guide audits (25 dimensions: 23 core + D-DRIFT/D-COVERAGE, 3 consecutive clean rounds), use `/shamt-audit` instead
- For very large artifacts or sessions likely to span many rounds, prefix with `/loop` to enable context-checkpoint recovery between rounds. Not required for typical use.

<!-- Managed by Shamt — do not edit. Run regen-claude-shims.sh to regenerate. -->
