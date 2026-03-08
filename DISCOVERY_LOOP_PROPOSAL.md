# Proposal: Deepen Discovery Validation Loop (TODO Item 3)

**Date:** 2026-03-07
**Status:** DRAFT — awaiting approval before implementation
**Revision:** 2 — adversarial self-review applied

---

## Problem

The Discovery validation loop is entirely backward-looking. It checks whether what is already in DISCOVERY.md is internally complete and consistent, but it never forces the agent to ask: *"What angles haven't I considered yet?"*

Observed failure modes:
- Discovery produces zero questions for the user — the agent reads the request, makes assumptions, and proceeds
- Requirements that were never surfaced during Discovery emerge mid-implementation as missed features
- Implementation decisions (API design, error handling, data structure) get made silently during S5-S6 rather than flagged as open questions during S1
- "Out of scope" items are decided unilaterally rather than confirmed with the user
- Non-functional requirements (performance, security, compatibility) are never raised
- Success criteria are never established — the agent finishes the work but the user never confirmed what "done" looks like or how to verify it

The current issue categories, per-round checklists, and exit criteria all assume the agent already found everything worth finding. There is no adversarial pressure to surface unknowns.

---

## Proposed Changes

### File 1: `guides/reference/validation_loop_discovery.md`

#### 1a. Expand "What Counts as Issue" — add 6 new categories

Current categories cover things already documented but incomplete. New categories cover things the agent hasn't thought to document at all:

- **Zero questions asked of user** — if no questions have been posed during Discovery, treat this as a signal of under-questioning. Justify absence of questions explicitly, or treat it as an open issue.
- **Alternative interpretations not considered** — if the request has only been read one way, without documenting other plausible interpretations and why they were ruled out.
- **Adjacent systems or workflows not assessed** — any system, file, workflow, or user role that could be affected but hasn't been examined or explicitly ruled out.
- **Implementation decisions not surfaced** — high-level choices that will need to be made during implementation (approach, API contracts, schema design, error handling strategy) that haven't been flagged as open questions or resolved. Note: this covers high-level architectural choices, not low-level implementation details (those belong in feature specs).
- **Non-functional requirements absent** — no consideration of performance, security, backward compatibility, or other constraints any production implementation should address.
- **Success criteria not defined** — no concrete description of what "done" looks like from the user's perspective. How will the user verify the epic was implemented correctly? What is the ideal end state in concrete terms?

#### 1b. Add "Adversarial Challenge" block to each round's checklist

These are questions the agent must ask itself each round. A "No" answer is an issue.

> **When an adversarial challenge item returns "No":** Document what is missing as an issue, add any unasked questions to the Pending Questions table, and treat this round as NOT clean (clean counter resets to 0).

**Round 1 Adversarial Challenge:**
1. Did I work through all 6 question brainstorm categories in DISCOVERY.md, and either list questions or write a one-line justification for each category?
2. Have I asked the user at least one clarifying question? If not, what am I assuming that should be verified instead?
3. Have I identified any adjacent systems or affected workflows not mentioned in the request?
4. Have I surfaced implementation decisions that will require choices — as open questions or confirmed decisions?
5. Have I considered non-functional constraints (performance, security, compatibility)?
6. Have I documented what success looks like — how the user will concretely verify the epic is done?

**Round 2 Adversarial Challenge:**
- What could go wrong with the current approach? Are the main risks documented?
- Are there user-facing edge cases or workflow variations not yet covered?
- Have I assumed any user preference that should be verified rather than decided unilaterally? (If yes, add a question to Pending Questions and present it to the user immediately.)

**Round 3 Adversarial Challenge:**
- Would a skeptical reviewer find any obvious missing angle in this document?
- Is every "out of scope" item either (a) explicitly stated in the epic request, or (b) confirmed by the user in a Resolved Question? (If not, present to user for confirmation before this round can be clean.)
- Has the user confirmed what success looks like — do they agree on how to verify the epic is done correctly?

#### 1c. Add to exit criteria

- Question brainstorm categories in DISCOVERY.md are complete — each has questions listed OR an explicit one-line justification for why none apply
- All questions asked during Discovery have been answered (Resolved Questions table not empty; Pending Questions table empty)
- All implementation decisions requiring user input have been resolved or explicitly deferred with user agreement
- Non-functional requirements considered and either addressed or explicitly ruled out with user agreement
- Success criteria confirmed with user
- Adversarial challenge checklist completed in the final round with no new issues found

---

### File 2: `guides/stages/s1/s1_p3_discovery_phase.md`

#### 2a. Expand Step 4 (Extract Initial Questions) with additional question categories

Current sources only cover ambiguous language and undefined terms. Add:

- **Implementation approach decisions** — what choices will need to be made during implementation? High-level API design, data structures, error handling strategy, naming conventions. Surface these as questions before assuming.
- **Non-functional requirements** — are there performance targets, security constraints, compatibility requirements, or scale expectations?
- **Adjacent systems and side effects** — what else in the codebase could be affected? Are there users or workflows not mentioned in the request that will be impacted?
- **Scope edge cases** — what happens at the boundary of scope? If the user said "add X", what about cases where X partially overlaps with existing Y?
- **Success criteria** — how will the user know this worked? What does the ideal end state look like in concrete terms?

Add a hard callout after the question sources list:

> 🚨 **If you have identified zero questions after reading the entire request:** You are almost certainly under-questioning. Re-read specifically looking for hidden assumptions — things you accepted as true that the user never explicitly stated.

#### 2b. Strengthen MANDATORY CHECKPOINT 1

The checkpoint currently says "verify initial questions asked and answered by user" but does not enforce that any were actually generated or that question brainstorm categories were worked through. Make two changes:

1. **Replace current item 4** ("Verify initial questions asked and answered by user") with:
   `[ ] Verify at least one clarifying question was asked of and answered by the user. If no questions were generated, STOP — re-read the request using the question brainstorm categories before proceeding.`

2. **Add new item after item 4:**
   `[ ] Verified that question brainstorm categories were worked through — all 6 categories in DISCOVERY.md have either questions listed or an explicit one-line justification for why none apply.`

#### 2c. Add to Common Mistakes anti-patterns

```
X "I read the entire epic request and have no questions for the user"
  --> STOP - Zero initial questions is a red flag.
  --> Re-read with the question brainstorm categories in mind (functional
      requirements, user workflow/edge cases, implementation approach,
      constraints, scope boundaries, success criteria).
```

---

### File 3: `guides/templates/discovery_template.md`

#### 3a. Add question brainstorm prompt to the Pending Questions section

Before the Pending Questions table, add a prompt the agent must work through. For each category, either list questions or write an explicit one-line justification for why none apply:

- **Functional requirements** — ambiguous terms, implicit expectations, undefined behavior?
- **User workflow / edge cases** — usage patterns beyond the happy path?
- **Implementation approach** — multiple valid ways to build this; does the user have preferences?
- **Constraints** — performance, security, compatibility, scale?
- **Scope boundaries** — what's at the edge — explicitly agreed or assumed?
- **Success criteria** — how does the user concretely verify this is done correctly?

*Silence is not acceptable for any category. If a category has no questions, a one-line justification is required.*

---

## What This Does NOT Change

- Overall S1.P3 structure (still a validation loop with 3 clean rounds)
- The 3-consecutive-clean-rounds exit mechanic (adversarial checks add to what constitutes a clean round, not to the counter mechanics)
- DISCOVERY.md section structure (same sections, better question-generation prompt within the Pending Questions section)
- Any other stage guides

## Out of Scope

Creating a formal `EPIC_REQUEST_TEMPLATE.md` is explicitly NOT part of this change. The focus is deepening the Discovery validation loop's proactive question-generation mechanism. An improved epic request template may be tracked as a separate follow-up item.

---

## Files to Edit (Implementation Order)

1. `guides/reference/validation_loop_discovery.md`
2. `guides/stages/s1/s1_p3_discovery_phase.md`
3. `guides/templates/discovery_template.md`
