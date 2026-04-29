<!-- Managed by Shamt — do not edit. Run regen-claude-shims.sh to regenerate. -->

# /shamt-status

**Purpose:** Print the current project state — active epic, current stage, last completed action, and any blockers.

**Invokes:** Direct file reads (no dedicated skill)

---

## Usage

```
/shamt-status
```

## Arguments

None.

## What Happens

1. Reads `EPIC_TRACKER.md` to identify the active epic(s) and their current stages
2. Reads `.shamt/epics/{active-epic}/AGENT_STATUS.md` for the most recent progress entry
3. Checks for any blocker indicators (open checklist items marked as blocked, stale STALL_ALERT.md files)
4. Reads `.shamt/epics/{active-epic}/EPIC_README.md` for the epic goal
5. Reports a concise status summary

## Expected Output

```
Active Epic: EPIC-007 — "Add OAuth2 login with Google and GitHub"
Current Stage: S2.P1 (Spec Writing — Iteration 3)
Last Action: Added requirement R-14 (OAuth state parameter for CSRF protection)
Open Questions: 2 in checklist.md (questions 8 and 11)
Blockers: None
```

## Notes

- If multiple epics are in progress (parallel work), all active epics are listed
- If no epic is active, reports "No active epic — use `/shamt-start-epic` to begin one"
- This command reads files but makes no changes to any epic state
