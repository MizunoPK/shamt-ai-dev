# Guide Update Proposals: KAI-16 — Remove Code Comments

**Created:** 2026-04-09
**Epic:** KAI-16 — remove_code_comments
**Source:** epic_lessons_learned.md → S9 lesson (agent pattern-matches guide shape)
**Status:** All 3 proposals APPROVED by user 2026-04-09
**Note:** This file is gitignored (lives in .shamt/) — local-only, not in commit history.

---

## Accepted Proposals

| ID | Priority | Target Guide | Summary | Status |
|----|----------|--------------|---------|--------|
| P1-1 | P1 | s9_p4_epic_final_review.md | Pre-action checklist output before sub-agent spawn | APPROVED |
| P1-2 | P1 | s9_p4_epic_final_review.md | Hard gate warning at "Spawn Sub-Agent" action step | APPROVED |
| P2-1 | P2 | s9_p4_epic_final_review.md | Require agent to state prompt template source | APPROVED |

---

## Rejected Proposals

None.

---

## Proposal Detail

### P1-1: Pre-Action Checklist Before Sub-Agent Spawn

**Priority:** P1 (High)
**Target:** `stages/s9/s9_p4_epic_final_review.md`
**Root Cause Addressed:** Agent read enough of S9.P4 to understand the general structure, then acted on that mental model without completing the mandatory sub-guide reads. The mandatory reading steps in the preamble are easy to skip once the agent has a "workable" mental model.

**Proposed Change:**

In any guide step that spawns a sub-agent or takes a major action after sub-guide reads, require the agent to output a pre-action checklist before proceeding:

```
Pre-action checklist (output before spawning sub-agent):
- [ ] Read `code_review/s7_s9_code_review_variant.md` — confirmed
- [ ] Read `code_review/code_review_workflow.md` — confirmed
```

The agent must output this checklist with all boxes checked before writing any prompt or spawning any sub-agent.

---

### P1-2: Hard Gate at Action Step

**Priority:** P1 (High)
**Target:** `stages/s9/s9_p4_epic_final_review.md` — specifically the "Spawn Fresh Sub-Agent" step

**Root Cause Addressed:** The preamble says "read these guides" but the action step (spawn sub-agent) is several steps later. By the time the agent reaches the action step, the preamble instructions are mentally de-prioritized. The gate needs to be co-located with the action.

**Proposed Change:**

At the "Spawn Fresh Sub-Agent" step, add a hard gate immediately before the action:

> ⚠️ **MANDATORY GATE:** If you have not read `code_review/s7_s9_code_review_variant.md` in this session, STOP and read it now before writing any prompt. "I understand the shape" is not the same as "I have followed the mandatory reading protocol."

---

### P2-1: Require Agent to State Template Source

**Priority:** P2 (Medium)
**Target:** `stages/s9/s9_p4_epic_final_review.md`

**Root Cause Addressed:** Even if an agent reads the sub-guide, it may write a custom prompt "inspired by" the template rather than using the template directly. Requiring the agent to state the source forces it to acknowledge which template it used.

**Proposed Change:**

When spawning a sub-agent for review, the agent must include a statement in its output:

> "Using template from `code_review/s7_s9_code_review_variant.md` Step [N]"

This makes compliance visible and auditable — if the agent cannot state the template source, it has not actually used the template.

---

## Scope Note

All three proposals target `stages/s9/s9_p4_epic_final_review.md`. The pattern (sub-guide dependency not enforced at the action step) may apply to other guides with similar structure. Consider auditing other guides that reference sub-guides for the same gap when implementing these proposals.
