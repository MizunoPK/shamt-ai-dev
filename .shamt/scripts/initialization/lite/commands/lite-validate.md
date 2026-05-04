# /lite-validate

**Purpose:** Run a Shamt Lite validation loop on any artifact — spec, implementation plan, code review, or general document.

**Invokes:** `shamt-lite-validate` skill

---

## Usage

```
/lite-validate {artifact}
```

## Arguments

- `{artifact}` (required) — relative or absolute path to the artifact to validate. Examples:
  - `stories/add-export/spec.md`
  - `stories/add-export/implementation_plan.md`
  - `stories/add-export/code_review/review_v1.md`
  - any standalone document (uses 4 general dimensions)

## What Happens

1. The agent loads the `shamt-lite-validate` skill
2. Detects artifact type from path/content (spec / plan / code review / general)
3. Reads the artifact in full
4. Runs the appropriate dimension set (7 for spec, 7 for plan, 5 for review, 4 for general)
5. Fixes any issues immediately, then re-reads with fresh eyes
6. Continues until a primary clean round is achieved (`consecutive_clean = 1`)
7. Spawns 1 Haiku sub-agent for independent confirmation
8. If sub-agent confirms zero issues: appends validation footer and finishes
9. If sub-agent finds an issue: fixes, resets to 0, returns to Step 1

## Expected Output

- Artifact has the validation footer appended: `✅ Validated {date} — N rounds, 1 sub-agent confirmed`
- Any issues found during validation have been fixed in the artifact

## Notes

- **Lite vs. full Shamt:** Lite uses 1 sub-agent confirmation; full Shamt uses 2.
- Sub-agents do NOT get the 1-LOW allowance — any issue resets `consecutive_clean = 0`.
- For very large artifacts or sessions likely to span many rounds, prefix with `/loop` to enable context-checkpoint recovery between rounds. Not required for typical use.
