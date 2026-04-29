# /shamt-resume

**Purpose:** Re-hydrate agent context after a compaction event, a new session, or a context loss — restore the full picture of where the epic is and what the next action is.

**Invokes:** Direct file reads following the GUIDE_ANCHOR pattern

---

## Usage

```
/shamt-resume
/shamt-resume {epic_tag}
```

## Arguments

- `{epic_tag}` (optional) — the epic to resume. If omitted, the agent identifies the active epic from `EPIC_TRACKER.md`. Examples: `EPIC-007`

## What Happens

1. Identifies the active epic (from `{epic_tag}` or `EPIC_TRACKER.md`)
2. Reads `AGENT_STATUS.md` for the most recent progress and current stage
3. Reads the current stage guide to re-load the step-by-step procedure
4. Reads the stage-specific artifact (e.g., `spec.md` for S2, `implementation_plan.md` for S5)
5. Reads `EPIC_README.md` for the epic goal and user requirements
6. Reports exactly where the agent left off and what the next concrete action is
7. Proceeds with the next action (does not ask the user what to do next unless blocked)

## Expected Output

```
Resuming EPIC-007 (OAuth2 Login)
Current Stage: S5.P2 — Implementation Plan Validation (Round 3)
Last Action: Fixed 2 MEDIUM issues in Round 2
consecutive_clean: 0 (Round 3 starts now)
Next Action: Re-read implementation_plan.md from top to bottom with fresh eyes
```

## Notes

- Always reads files fresh — never relies on in-context memory from before compaction
- If `AGENT_STATUS.md` shows "Blocked: awaiting user input on [X]", the resume command surfaces the open question immediately instead of proceeding
- For master dev work (no EPIC_TRACKER.md), reads the current design doc and validation log to determine resume point
