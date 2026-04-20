# SHAMT-37: Enforce Sub-Agent Spawn Discipline in S9.P4

**Status:** Implemented
**Created:** 2026-04-20
**Branch:** `feat/SHAMT-37`
**Validation Log:** [SHAMT37_VALIDATION_LOG.md](./SHAMT37_VALIDATION_LOG.md)

---

## Problem Statement

During KAI-16 (remove_code_comments), the S9.P4 epic final review sub-agent was spawned without completing the mandatory reading protocol. The agent read enough of the guide to understand the general structure, then acted on that mental model — pattern-matching the guide's shape — without following the mandatory sub-guide reads that provide the actual prompt template.

The root cause has two parts:

1. **Preamble reads are easy to skip.** The mandatory reading steps ("Read `code_review/s7_s9_code_review_variant.md`") appear in the STEP 6 header, several screenfuls before the action step (Step 6a: Spawn Fresh Sub-Agent). By the time the agent reaches the action, the preamble is mentally de-prioritized.

2. **Template source is never audited.** Even if the agent reads the sub-guide, the guide does not require the agent to declare which template it used. An agent can write a custom prompt "inspired by" the template without the violation being detectable.

The impact of NOT solving this: the spawned sub-agent runs a degraded review using an improvised prompt instead of the validated template, producing an unreliable review that may miss entire categories or dimensions.

---

## Goals

1. Require the agent to output a pre-action checklist confirming all mandatory reads before spawning any sub-agent in Step 6a.
2. Co-locate a hard gate at the Step 6a action step so the enforcement is visible at the point of action, not only in the preamble.
3. Require the agent to declare the template source in its output, making compliance auditable without post-hoc investigation.

---

## Detailed Design

### Proposal 1 (P1-1): Pre-Action Checklist Before Sub-Agent Spawn

**Description:** Before writing any prompt or spawning any sub-agent in Step 6a, the agent must output a pre-action checklist with all boxes checked:

```
Pre-action checklist (output before spawning sub-agent):
- [x] Read `code_review/s7_s9_code_review_variant.md` — confirmed
- [x] Read `code_review/code_review_workflow.md` — confirmed
```

The checklist forces an explicit declaration that reading happened. An agent that pattern-matched the guide shape rather than following the protocol cannot truthfully check the boxes — forcing it to either comply or visibly fail.

**Rationale:** Mandatory reading steps in preambles are cognitively distant from action steps. Moving the enforcement to the action step as a required output (not just a reminder) interrupts the action until compliance is confirmed.

**Alternatives considered:** Adding a reminder note at Step 6a (insufficient — no output required, agent can skip). Restructuring the guide to place mandatory reads immediately before Step 6a (reduces skipping risk but doesn't enforce completion).

---

### Proposal 2 (P1-2): Hard Gate Warning at Step 6a

**Description:** At Step 6a ("Spawn Fresh Sub-Agent"), add a hard gate immediately before the action:

> ⚠️ **MANDATORY GATE:** If you have not read `code_review/s7_s9_code_review_variant.md` in this session, STOP and read it now before writing any prompt. "I understand the shape" is not the same as "I have followed the mandatory reading protocol."

**Rationale:** The preamble says "read these guides" but the action step is several steps later. The gate is co-located with the action — the agent cannot encounter the spawn instruction without first seeing the stop condition. The explicit call-out of "I understand the shape" directly names the failure pattern observed in KAI-16.

**Alternatives considered:** None — this is a minimal, targeted fix at the point of failure.

---

### Proposal 3 (P2-1): Require Agent to State Template Source

**Description:** When spawning the sub-agent for Step 6 review, the agent must include a statement in its output:

> "Using template from `code_review/s7_s9_code_review_variant.md` Step [N]"

**Rationale:** Even if an agent reads the sub-guide, it may write a custom prompt "inspired by" the template rather than using it directly. Requiring the agent to name the specific step forces it to locate and cite the actual template — if it cannot state the source, it has not used the template. This makes compliance auditable.

**Alternatives considered:** Requiring the agent to paste the template verbatim (too prescriptive, breaks if template updates). Audit after the fact by comparing prompts (too late — the review has already run on a degraded prompt).

---

**Recommended approach:** Implement all three proposals together. P1-1 and P1-2 address the same root cause from complementary angles (output-based and warning-based enforcement). P2-1 closes a second gap (template drift). Together they form a defense-in-depth pattern: (1) stop before acting, (2) confirm reads explicitly, (3) declare what you used.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/guides/stages/s9/s9_p4_epic_final_review.md` | MODIFY | Add pre-action checklist, hard gate, and template source requirement to Step 6a |

---

## Implementation Plan

### Phase 1: Modify s9_p4_epic_final_review.md

Add three changes to the Step 6a section:

- [ ] **P1-2 (Hard Gate):** Immediately before the "Primary agent action" line in Step 6a, insert the `⚠️ MANDATORY GATE` block.
- [ ] **P1-1 (Pre-Action Checklist):** After the hard gate, insert the pre-action checklist block with instructions to output it before spawning.
- [ ] **P2-1 (Template Source Statement):** After the checklist block, add a line requiring the agent to include a "Using template from..." statement in its output.

Exact insertion point: Step 6a, between the step header (`### Step 6a: Spawn Fresh Sub-Agent (Epic-Scope Review)`) and the "Primary agent action" line.

- [ ] Verify the inserted text is correctly formatted (markdown blockquote for gate, code block for checklist).
- [ ] Re-read the modified section to confirm it reads coherently and does not conflict with adjacent text.

---

## Validation Strategy

- **Primary validation:** Design doc validation loop (7 dimensions) — run until primary clean round + 2 parallel Haiku sub-agent confirmations.
- **Implementation validation:** After Phase 1 complete, run implementation validation (5 dimensions) — verify all 3 proposals are present and correctly placed.
- **Manual check:** Read the full Step 6a section after edits to confirm it reads coherently and the gate/checklist appear at the correct position relative to the action.
- **Success criteria:** All three proposals present in `s9_p4_epic_final_review.md`, correctly placed before the spawn action, coherent with surrounding text.

---

## Open Questions

None — all three proposals were pre-approved by user on 2026-04-09.

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Inserted text breaks guide readability (too much friction) | Gate + checklist are short (<5 lines total); scope is narrow (one step only) |
| Template source step number changes when sub-guide is updated | Wording says "Step [N]" — agent fills in the current step; not hardcoded |
| Audit finds similar pattern in other guides (scope creep) | Proposal doc's scope note acknowledged this; defer to separate SHAMT if needed |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-20 | Initial draft created from KAI-16-guide-update-proposals.md (all 3 proposals pre-approved 2026-04-09); incoming proposal archived to design_docs/archive/ during design doc creation |
