# SHAMT-35: Split S10 into S10 (Final Changes & Merge) and S11 (Shamt Finalization)

**Status:** Validated
**Created:** 2026-04-09
**Branch:** `feat/SHAMT-35`
**Validation Log:** [SHAMT35_VALIDATION_LOG.md](./SHAMT35_VALIDATION_LOG.md)

---

## Problem Statement

S10 currently conflates two distinct concerns: (1) finalizing the epic's code and getting it merged, and (2) performing Shamt-specific housekeeping after the merge. The current step ordering reflects this confusion — guide update proposals (S10.P1) run after the PR is created but before it is merged, which means the lessons-learned analysis happens mid-air rather than at a true endpoint.

Additionally, Steps 1, 2, and 2b (pre-cleanup verification and test re-runs) duplicate work already required by S9, adding overhead without value. S9's exit criteria already guarantee the epic is complete and tests pass before S10 starts.

The result is a 10-step stage that is too long, partially misordered, and mixes concerns that belong in different mental models: "we're wrapping up the feature work" vs. "we're tidying the Shamt system."

**Impact of not solving this:** Agents enter S10 confused about which steps apply now vs. after merge. The guide is hard to navigate. Lessons-learned analysis is disconnected from the full picture (PR comments may not exist yet). The stage is perceived as bloated, reducing compliance.

---

## Goals

1. Remove redundant pre-cleanup verification steps (Steps 1, 2, 2b) that duplicate S9 exit criteria
2. Split the remaining work into two stages with clear, non-overlapping concerns
3. **S10 — Final Changes & Merge:** Everything needed to finalize the feature branch and get it into main (docs verification, final commit, overview doc, PR creation, PR comment resolution)
4. **S11 — Shamt Finalization:** Everything Shamt-specific that happens after merge (guide update proposals, epic archival, tracker update, final verification)
5. Ensure S10.P1 (guide updates) runs in S11, where it can incorporate PR review comments from a completed PR — not an open one

---

## Detailed Design

### Proposal 1: Two-Stage Split with Redundant Steps Removed

**S10 — Final Changes & Merge** contains all steps that touch the feature branch and result in a merged PR:

| New Step | Former Step | What it does |
|----------|-------------|--------------|
| Step 1 | Former Step 3 | Documentation verification (EPIC_README, lessons learned, smoke test plan, feature READMEs) |
| Step 2 | Former Step 4 | Final commit (epic implementation changes) |
| Step 3 | Former Step 7 (S10.P2) | Optional epic overview document (`SHAMT-{N}-OVERVIEW.md`) |
| Step 4 | Former Step 8 | Push branch and create PR; wait for user to signal merge; on user signal: check out main/master, verify the feature branch appears in git log, then hand off to S11 |
| Step 5 | Former Step 8.5 | PR comment resolution (user-triggered; runs before merge if reviewer feedback arrives) |

**S11 — Shamt Finalization** contains all steps that happen after the merge and operate on the Shamt system itself. S11 begins when the user signals that the PR has been merged. The agent checks out main/master and verifies the merge (feature branch commits appear in `git log`) before proceeding. If verification fails, the agent halts and reports to the user rather than continuing.

| New Step | Former Step | What it does |
|----------|-------------|--------------|
| Step 1 | Former Step 9 (S10.P1) | Guide update from lessons learned + PR comment analysis; create proposal doc |
| Step 2 | Former Step 5 | Move entire epic folder to `.shamt/epics/done/` (max 10 rule) and commit |
| Step 3 | Former Step 6 | Update EPIC_TRACKER.md (move to Completed, add detail section, increment next number); update PROCESS_METRICS.md |
| Step 4 | Former Step 10 | Final verification and completion announcement |

**Steps removed entirely:**
- Former Step 1 (Pre-Cleanup Verification) — duplicates S9 exit criteria (S9 already verifies all features complete, tests pass, no pending work)
- Former Step 2 (Run Tests Per Testing Approach) — duplicates S9 mandatory test gate; running tests again in S10 adds no value since no new code is written between S9 and S10
- Former Step 2b (Investigate User-Reported Anomalies) — this belongs in S9's user testing loop (S9 Step 6), not S10 cleanup

**Rationale:** The split follows a natural seam: S10 ends when `main` is updated. S11 begins from a clean `main`. This ordering makes S10.P1 (guide updates) more valuable — it runs after the PR is fully reviewed and merged, so `pr_comment_resolution.md` is complete before the lessons-learned analysis begins.

**Alternatives considered:**
- *Reorder within a single S10:* Keeps the stage too long and doesn't resolve the conceptual mixing. Rejected.
- *Remove S10.P2 (overview doc):* The overview doc is genuinely useful for PR reviewers and should stay, but it belongs in S10 (pre-merge) since it's part of the PR diff.

**Recommended approach:** Proposal 1 — two-stage split with redundant steps removed.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/guides/stages/s10/s10_epic_cleanup.md` | MODIFY | Rewrite as S10 Final Changes & Merge (Steps 1–5 only) |
| `.shamt/guides/stages/s10/s10_p1_guide_update_workflow.md` | MOVE → s11 | Moves to new `stages/s11/` folder; update all internal references |
| `.shamt/guides/stages/s10/s10_p2_overview_workflow.md` | RENAME → `s10_p1_overview_workflow.md` | Renamed since P1 is gone; update step number references and internal header |
| `.shamt/guides/stages/s11/s11_shamt_finalization.md` | CREATE | New top-level S11 guide (archival, tracker, guide updates, final verification) |
| `.shamt/guides/reference/stage_10/stage_10_reference_card.md` | MODIFY | Update to reflect new S10 scope |
| `.shamt/guides/reference/` | CREATE folder | Create `stage_11/` reference folder |
| `.shamt/guides/reference/stage_11/stage_11_reference_card.md` | CREATE | Quick reference card for S11 |
| `.shamt/guides/prompts/s10_prompts.md` | MODIFY | Remove references to removed steps (1, 2, 2b); update S10 description and step numbers |
| `.shamt/guides/prompts/s11_prompts.md` | CREATE | New prompt file for starting S11 (Shamt Finalization) |
| `.shamt/guides/EPIC_WORKFLOW_USAGE.md` | MODIFY | Update workflow chain from "→ S10: Epic Cleanup" to "→ S10: Final Changes & Merge → S11: Shamt Finalization"; update S10 section description |
| `.shamt/guides/missed_requirement/s9_s10_special.md` | MODIFY | Update title/scope to note that missed requirements discovered in S11 should also restart from S9.P1 |
| `.shamt/guides/stages/s9/s9_epic_final_qc.md` | NO CHANGE | No update needed |
| `CLAUDE.md` | MODIFY | Update S10 description; add S11 to stage list |

---

## Implementation Plan

### Phase 1: Remove Redundant Steps and Rewrite S10

Rewrite `s10_epic_cleanup.md` to cover only the post-S9, pre-merge work (former Steps 3, 4, 7, 8, 8.5).
- [ ] Remove Steps 1, 2, 2b from `s10_epic_cleanup.md` entirely
- [ ] Renumber remaining steps as Steps 1–5 (doc verification → final commit → overview doc → push/PR → PR comment resolution)
- [ ] Update Workflow Overview diagram to reflect new step count
- [ ] Update Quick Navigation table
- [ ] Update all cross-references within the file (e.g., "return to Step 7" → "return to Step 3")
- [ ] Update time estimate (remove ~15 min for removed steps)
- [ ] Update Prerequisites Checklist: remove test-run and anomaly-investigation items; add note that S9 exit criteria cover these
- [ ] Update Critical Rules block: remove rules 1 (S9 verification) and 2 (run tests) since these are now S9 responsibilities; renumber remaining rules
- [ ] Verify exit criteria section reflects new step set

### Phase 2: Move S10.P1 to S11 and Create S11 Guide

Create the new S11 stage covering post-merge Shamt housekeeping.
- [ ] Create `stages/s11/` directory
- [ ] Create `stages/s11/s11_shamt_finalization.md` as the top-level S11 guide
  - Steps 1–4: guide update proposals → epic folder move → tracker update → final verification
  - Prerequisites: user has signaled merge; agent has checked out main/master and verified merge via `git log`
  - Model selection block (same delegation pattern as current S10)
  - Mandatory reading protocol, forbidden shortcuts, critical rules
- [ ] Move `s10_p1_guide_update_workflow.md` to `stages/s11/s11_p1_guide_update_workflow.md`
  - Update header (file name, breadcrumb)
  - Update "Return to" link at bottom: `stages/s10/s10_epic_cleanup.md` → `stages/s11/s11_shamt_finalization.md`
  - Update internal step number references to match new S11 step numbering
- [ ] Rename `s10_p2_overview_workflow.md` → `s10_p1_overview_workflow.md`; update file header and any internal self-references

### Phase 3: Update Reference Cards and CLAUDE.md

- [ ] Update `reference/stage_10/stage_10_reference_card.md` to reflect new S10 scope (5 steps, no archival)
- [ ] Create `reference/stage_11/` directory
- [ ] Create `reference/stage_11/stage_11_reference_card.md` (4 steps: guide updates, archive, tracker, final verification)
- [ ] Update `CLAUDE.md`:
  - Update S10 description to "Final Changes & Merge"
  - Add S11 entry: "Shamt Finalization" with brief description of its 4 steps

### Phase 4: Audit and Cross-Reference Cleanup

- [ ] Grep for all references to "s10_epic_cleanup" in `.shamt/guides/` — verify each one still makes sense or update to reference S11 where appropriate
- [ ] Grep for "Step 9" references within former S10 content (now moved to S11) — update step numbers
- [ ] Grep for "Step 8.5" references — update to new Step 5 (S10)
- [ ] Verify `sync/export_workflow.md` and `sync/import_workflow.md` don't reference S10 step numbers that changed
- [ ] Update `prompts/s10_prompts.md`: remove test-run instructions; update step numbers and S10 scope description
- [ ] Create `prompts/s11_prompts.md`: "Starting S11: Shamt Finalization" prompt covering the 4-step S11 flow
- [ ] Update `EPIC_WORKFLOW_USAGE.md`: update workflow chain line and S10 section to reflect new scope; add S11 section
- [ ] Update `missed_requirement/s9_s10_special.md`: note in title/scope that S11 discovery also restarts from S9.P1
- [ ] Run full guide audit (3 consecutive clean rounds)

---

## Validation Strategy

- **Primary validation:** Design doc validation loop (7 dimensions) until primary clean round + 2 independent sub-agent confirmations
- **Implementation validation:** After all phases complete, run implementation validation (5 dimensions)
- **Success criteria:**
  - S10 guide covers exactly the 5 steps defined (doc verification, final commit, overview doc, push/PR, PR comment resolution)
  - S11 guide covers exactly the 4 steps defined (guide updates, archive, tracker, final verification)
  - No dangling references to removed steps (1, 2, 2b) anywhere in `.shamt/guides/`
  - Full guide audit passes (3 consecutive clean rounds)

---

## Open Questions

~~1. With S10.P1 moved to S11, S10 now has only one sub-workflow (P2: Overview Doc). Should `s10_p2_overview_workflow.md` be renamed to `s10_p1_overview_workflow.md`?~~ **Resolved: Rename.**

~~2. Are there any child project guides that embed S10 step numbers directly?~~ **Resolved: Assume no — proceed without flagging.**

~~3. Should the S9 exit criteria be explicitly updated to mention "no test re-run needed in S10"?~~ **Resolved: No note needed.**

---

## Risks & Mitigation

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Child projects have cached versions of S10 that reference old step numbers | Medium | S10 changes are propagated via import; child projects re-import on next sync |
| S11 feels disconnected from S10 — agents don't know to run it | Low | S10 Step 4 explicitly instructs the agent to wait for a user merge signal, then check out main/master and verify before handing off to S11; S10 exit criteria also lists "Proceed to S11" |
| Former Step 8.5 (PR comment resolution) timing — it can happen mid-PR before merge | Low | Kept in S10 as Step 5 (user-triggered); S10 still owns all pre-merge activity |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-09 | Initial draft created |
| 2026-04-09 | Round 1 validation fixes: added missing files to Files Affected (s10_prompts, s11_prompts, EPIC_WORKFLOW_USAGE, s9_s10_special, s9_epic_final_qc conditional); corrected S11 step order in Validation Strategy and Phase 3; rewrote garbled Open Question 1; added Phase 4 implementation steps for new files |
| 2026-04-09 | Round 2 validation fix: corrected S11 step order in Goals #4 (was old order) |
| 2026-04-09 | Validated — primary clean round + 2 independent sub-agent confirmations |
| 2026-04-09 | Resolved open questions: rename s10_p2 → s10_p1; assume no child step number refs; no S9 note needed |
