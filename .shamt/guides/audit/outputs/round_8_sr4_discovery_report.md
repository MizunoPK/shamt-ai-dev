# Round 8 SR4 Discovery Report — D7, D15, D16, D17

**Date:** 2026-02-21
**Sub-Round:** SR8.4
**Dimensions:** D7, D15, D16, D17
**Status:** COMPLETE
**Genuine Findings:** 1
**Fixed:** 1
**Pending User Decision:** 0

---

## Summary

| Dimension | Findings | Fixed | Pending |
|-----------|----------|-------|---------|
| D7  | 0 | 0 | 0 |
| D15 | 1 | 1 | 0 |
| D16 | 0 | 0 | 0 |
| D17 | 0 | 0 | 0 |
| **Total** | **1** | **1** | **0** |

---

## Findings / Zero-Finding Confirmations

---

### D7: Context-Sensitive Validation — ZERO GENUINE FINDINGS

#### D7.1: S1-Gate-A/B/C Disambiguation — CONFIRMED CLEAN

`reference/stage_1/stage_1_reference_card.md` (line 81) contains the disambiguation note:

> "These are S1-local gates (labeled S1-Gate-A, S1-Gate-B, S1-Gate-C to avoid conflict with global Gate 1/2/3 defined in reference/mandatory_gates.md)."

Headings use `### S1-Gate-A:`, `### S1-Gate-B:`, `### S1-Gate-C:` — note text and heading labels match exactly. This was corrected in Round 7 SR4. No regression.

`reference/stage_10/stage_10_reference_card.md` (line 96) uses `### S10-Gate-A:` with matching disambiguation note. Internally consistent.

#### D7.2: Gate 25 Formal Gate Count — CONFIRMED CLEAN

`reference/mandatory_gates.md` Summary Statistics section (line 693) states:

- S2: 3 formal gates per feature (Gates 1, 2, 3)
- S3: 1 formal gate (Gate 4.5)

The "Formal Gates Requiring User Input" count was corrected to **4** in Round 7 SR4 (Finding #4). Verified the count is now 4 in the file (line 763 area), listing Gates 3, 4.5, 5, and 25. Gate 25 is correctly included as it requires user decision when spec discrepancies are found. No issue.

#### D7.3: S2.P2 References in parallel_work — INTENTIONAL, NOT ERRORS

`parallel_work/s2_secondary_agent_guide.md` and `parallel_work/s2_parallel_protocol.md` contain `S2.P2` references in two distinct contexts:

1. **Status/checkpoint template strings** (e.g., `STAGE: S2.P2`, `Next: Continuing with S2.P2`) — These appear in communication message templates showing examples of how agents report their stage. The secondary agent would fill these in as they reach that stage.

2. **Primary agent S2.P2** — The Primary agent does run S2.P2 (Cross-Feature Alignment). Several references explicitly describe Primary running S2.P2 while secondaries wait.

`s2_secondary_agent_guide.md` line 409 contains an explicit clarifying note:
> "S2 for Secondary agents consists only of S2.P1 (`s2_p1_spec_creation_refinement.md`). The Cross-Feature Alignment phase (S2.P2) is run by the Primary agent after all secondaries complete S2.P1."

The references to `S2.P2` in the secondary guide appear in sample message templates showing what Primary would say back to Secondary, and in checkpoint status examples showing what stage the secondary *started from* before being interrupted. All are contextually appropriate. **No genuine errors.**

#### D7.4: Legacy S2 Sub-Guides Prerequisite Labels — INTENTIONAL

`stages/s2/s2_p2_5_spec_validation.md` (line 5) has `**Prerequisites:** S2.P2 complete (Specification Phase PASSED)`. This refers to `s2_p2_specification.md` in the **old 3-phase S2 workflow** (S2.P1 Research → S2.P2 Specification → S2.P2.5 Validation → S2.P3 Refinement).

The s2 router guide (`s2_feature_deep_dive.md`) confirms the old guides are legacy artifacts: "The original monolithic guide has been removed. Use `s2_p1_spec_creation_refinement.md` ... and `s2_p2_cross_feature_alignment.md`."

The three old sub-guides (`s2_p2_specification.md`, `s2_p2_5_spec_validation.md`, `s2_p3_refinement.md`) remain in the directory for historical reference and are still cited in `reference/guide_update_tracking.md` as sources of lessons learned. Their internal prerequisite labels are self-consistent within the old workflow. Flagging them as errors would be a false positive. **No genuine error.**

---

### D15: Duplication Detection — 1 FINDING (FIXED)

#### Finding #1 — FIXED

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s2/s2_p3_refinement.md`
**Lines:** 1–2 (pre-fix)
**Issue:** Duplicate H1 and H2 with identical title text "S2.P3: Refinement Phase":

```
# S2.P3: Refinement Phase
## S2.P3: Refinement Phase
```

This is the same pattern that Round 7 SR4 (Finding #2) fixed in `s2_p2_specification.md`. Round 5 changed the H1 from a stale title to "S2.P3: Refinement Phase" to match the H2, but the H2 was never removed at that time.

**Fixed To:**

```
# S2.P3: Refinement Phase

**File:** `s2_p3_refinement.md`
```

The redundant `## S2.P3: Refinement Phase` line was removed. The H1 provides the title; the H2 was unnecessary and duplicative.

**Status:** FIXED

---

#### D15 — Zero-Finding Confirmations

**Inline `**Next Phase/Stage:**` in metadata blocks (4 files):** Not a D15 violation.

Four guides use a file-header metadata block pattern (lines 1–8) that includes a `**Next Phase:**` or `**Next Stage:**` quick-reference field:
- `stages/s2/s2_p2_specification.md` (line 6)
- `stages/s2/s2_p2_5_spec_validation.md` (line 6)
- `stages/s9/s9_p4_epic_final_review.md` (line 5)
- `stages/s10/s10_epic_cleanup.md` (line 6)

This is a consistent design pattern used across 14+ guides (stages, debugging, missed_requirement) — the metadata block provides at-a-glance orientation when a file is first opened; the `## Next Phase/Stage` H2 footer provides the full actionable navigation section with checklists, context, and cross-references. The two serve distinct purposes (quick reference vs. complete navigation) and are D15 Rule 1 compliant (intentional, stable, serves a different function). Round 7 correctly targeted only the *body-level inline duplicates* (lines inside the Exit Criteria section body that immediately preceded the H2 footer), not the metadata-block pattern.

**Reference cards `**Next Stage:**` bold lines:** Not D15 duplicates. Reference cards (`reference/stage_*/stage_*_reference_card.md`) use bold `**Next Stage:**` lines as the terminal item in their completion checklist sections. None of these files have a corresponding `## Next Stage` H2 section — the bold line IS the navigation element, not a duplicate of one.

**Gate 4.5 across files:** Not a D15 issue. The same gate is referenced in many files because S3 defines it, S4 verifies its prerequisite, S5 lists it as a completed dependency, etc. Each reference is contextually appropriate and serves workflow continuity, not copy-paste duplication.

---

### D16: Accessibility — ZERO GENUINE FINDINGS

#### D16.1: Non-Standard Navigation Headings — CONFIRMED CLEAN

`grep -rn "^## Next:\|^## Return to\|^## Back to\|^## Go to\|^## Continue to"` returned zero results across all guides. All navigation headers use the standardized `## Next Stage` / `## Next Phase` format established in Round 6.

#### D16.2: Long Guides Without TOC — ACCEPTABLE BY FILE TYPE

The scan found 22 files over 200 lines without a TOC. These fall into two categories that are acceptable by design:

**Reference cards** (`reference/stage_*/stage_*_reference_card.md`): These files are intended as dense quick-reference tables and checklists. They are structured as a single logical scan — stage overview, step table, rules, checklist, next stage. TOCs would add overhead without navigation benefit in files that are read top-to-bottom as a whole.

**Supporting reference files** (`reference/PROTOCOL_DECISION_TREE.md`, `reference/s2_parallelization_decision_tree.md`, `reference/smoke_testing_pattern.md`, etc.): These are single-topic deep-dive files. They are typically read in full once, not navigated to specific sections repeatedly.

**`stages/s4/s4_validation_loop.md` (385 lines):** This is an S4-specific validation loop guide. It follows the same pattern as the S5 validation loop family, where individual sub-guides handle navigation rather than a master TOC.

**`stages/s5/s5_update_notes.md` (285 lines):** Update notes file — not a workflow guide, informational only.

No files were found where a missing TOC creates a genuine navigation barrier for agent users.

#### D16.3: TOC Anchors After Round 7 Fix — CONFIRMED CLEAN

`reference/mandatory_gates.md` TOC anchor `[S8: Post-Feature Updates](#s8-post-feature-updates)` (Round 7 SR4 Finding #5 fix) verified present and correct at line 21. The corresponding H2 heading `## S8: Post-Feature Updates` exists in the file.

Spot-checked TOC anchors in `stages/s5/s5_v2_validation_loop.md` and `stages/s2/s2_feature_deep_dive.md` — both present, no broken anchor patterns detected.

---

### D17: Stage Flow Consistency — ZERO GENUINE FINDINGS

Full S1→S10 chain verified:

| Transition | Guide | Target |
|---|---|---|
| S1 → S2 | `stages/s1/s1_epic_planning.md` `## Next Stage` | `stages/s2/s2_p1_spec_creation_refinement.md` ✅ |
| S2.P1 → S2.P2 | `stages/s2/s2_p1_spec_creation_refinement.md` `## Next Phase` | `stages/s2/s2_p2_cross_feature_alignment.md` ✅ |
| S2.P2 → S3 | `stages/s2/s2_p2_cross_feature_alignment.md` `## Next Stage` | `stages/s3/s3_epic_planning_approval.md` ✅ |
| S2 router → S3 | `stages/s2/s2_feature_deep_dive.md` `## Next Stage` | S3 (when all features complete) ✅ |
| S2.P2.5 → S2.P3 | `stages/s2/s2_p2_5_spec_validation.md` `## Next Phase` | `stages/s2/s2_p3_refinement.md` ✅ (Fixed R7) |
| S2.P3 → S3 | `stages/s2/s2_p3_refinement.md` `## Next Stage` | `stages/s3/s3_epic_planning_approval.md` ✅ |
| S3 → S4 | `stages/s3/s3_epic_planning_approval.md` `## Next Stage` | `stages/s4/s4_feature_testing_strategy.md` ✅ |
| S4 → S5 | `stages/s4/s4_feature_testing_strategy.md` `## Next Stage` | `stages/s5/s5_v2_validation_loop.md` ✅ |
| S5 → S6 | `stages/s5/s5_v2_validation_loop.md` `## Next Phase` | `stages/s6/s6_execution.md` ✅ |
| S6 → S7 | `stages/s6/s6_execution.md` `## Next Stage` | `stages/s7/s7_p1_smoke_testing.md` ✅ |
| S7.P1 → S7.P2 | `stages/s7/s7_p1_smoke_testing.md` `## Next Phase` | `stages/s7/s7_p2_qc_rounds.md` ✅ |
| S7.P2 → S7.P3 | `stages/s7/s7_p2_qc_rounds.md` `## Next Phase` | `stages/s7/s7_p3_final_review.md` ✅ |
| S7.P3 → S8 | `stages/s7/s7_p3_final_review.md` `## Next Phase` | `stages/s8/s8_p1_cross_feature_alignment.md` ✅ |
| S8.P1 → S8.P2 | `stages/s8/s8_p1_cross_feature_alignment.md` `## Next Phase` | `stages/s8/s8_p2_epic_testing_update.md` ✅ |
| S8.P2 → S5 or S9 | `stages/s8/s8_p2_epic_testing_update.md` `## Next Phase` | `stages/s5/s5_v2_validation_loop.md` OR `stages/s9/s9_epic_final_qc.md` ✅ |
| S9 router → S9.P1 | `stages/s9/s9_epic_final_qc.md` | `stages/s9/s9_p1_epic_smoke_testing.md` ✅ |
| S9.P1 → S9.P2 | `stages/s9/s9_p1_epic_smoke_testing.md` `## Next Phase` | `stages/s9/s9_p2_epic_qc_rounds.md` ✅ |
| S9.P2 → S9.P3 | `stages/s9/s9_p2_epic_qc_rounds.md` `## Next Phase` | `stages/s9/s9_p3_user_testing.md` ✅ |
| S9.P3 → S9.P4 | `stages/s9/s9_p3_user_testing.md` `## Next Phase` | `stages/s9/s9_p4_epic_final_review.md` ✅ |
| S9.P4 → S10 | `stages/s9/s9_p4_epic_final_review.md` `## Next Stage` | `stages/s10/s10_epic_cleanup.md` ✅ |
| S9 router → S10 | `stages/s9/s9_epic_final_qc.md` `## Next Stage` | `stages/s10/s10_epic_cleanup.md` ✅ |
| S10 → end | `stages/s10/s10_epic_cleanup.md` `## Next Stage` | "EPIC COMPLETE - No Next Stage" ✅ |

All 22 stage transitions verified clean. No broken or misdirected next-guide pointers found.

---

## Fix Applied

### Fix 1: `stages/s2/s2_p3_refinement.md` — Remove Duplicate H2 Title

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s2/s2_p3_refinement.md`
**Lines affected:** 2 (removed)
**Change:** Removed `## S2.P3: Refinement Phase` from line 2 (immediately following the H1 with identical text).

**Before:**
```
# S2.P3: Refinement Phase
## S2.P3: Refinement Phase

**File:** `s2_p3_refinement.md`
```

**After:**
```
# S2.P3: Refinement Phase

**File:** `s2_p3_refinement.md`
```

**Rationale:** The H1 provides the guide title. The H2 was redundant and created a confusing double-header. Same pattern as Round 7 SR4 Finding #2 fix applied to `s2_p2_specification.md`. The duplicate was introduced when Round 5 updated the H1 text to match the H2 but did not remove the H2.
