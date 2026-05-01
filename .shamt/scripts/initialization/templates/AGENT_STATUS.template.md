# Agent Status — {EPIC_ID}

> This file tracks the active agent's current position in the workflow.
> Keep it updated after every significant action. Do NOT store user preferences
> or project facts here — those belong in harness memory (see `memory_tiers.md`).

---

**Epic:** {EPIC_ID} — {EPIC_NAME}
**Stage:** {STAGE}
**Phase:** {PHASE}
**Step:** {STEP}

**Model:** {MODEL}
**Reasoning:** {EFFORT}

**Last Action:** {LAST_ACTION}
**Blocker:** {BLOCKER_OR_NONE}

---

## Active Work

{DESCRIPTION_OF_CURRENT_WORK}

---

## Resumption Context

If resuming after compaction or a new session:

1. Read `RESUME_SNAPSHOT.md` (written by `precompact-snapshot.sh` / `session-start-resume.sh`)
2. Verify the current stage guide is loaded
3. Continue from the step listed above

---

## Notes

{ANY_NOTES_RELEVANT_TO_RESUMPTION — delete this section if empty}
