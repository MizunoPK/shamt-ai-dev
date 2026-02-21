# Round 7 SR4 Discovery Report — D7, D15, D16, D17

**Date:** 2026-02-21
**Sub-Round:** SR7.4
**Dimensions:** D7, D15, D16, D17
**Status:** COMPLETE
**Genuine Findings:** 9
**Fixed:** 7
**Pending User Decision:** 2

---

## Summary

| Dimension | Findings | Fixed | Pending |
|-----------|----------|-------|---------|
| D7: Context-Sensitive | 3 | 1 | 2 |
| D15: Duplication | 4 | 4 | 0 |
| D16: Accessibility | 1 | 1 | 0 |
| D17: Stage Flow | 1 | 1 | 0 |
| **Total** | **9** | **7** | **2** |

---

## Findings

### Finding #1
**Dimension:** D15
**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s2/s2_p3_refinement.md`
**Line:** 864 (pre-fix)
**Issue:** Inline `**Next Stage:**` in the Exit Criteria section body immediately precedes the `## Next Stage` H2 section (3 lines below). The inline version is a single-sentence summary that duplicates the information provided by the canonical H2 section.

Old content at line 864:
```
**Next Stage:** Either next feature's Research Phase (stages/s2/s2_p1_spec_creation_refinement.md) OR Cross-Feature Sanity Check (stages/s3/s3_epic_planning_approval.md) if all features complete
```
Followed 3 lines later by `## Next Stage` with full content.

**Fixed To:** Removed the inline `**Next Stage:**` line (and its surrounding blank line) entirely. The `## Next Stage` H2 section provides complete information.
**Status:** FIXED

---

### Finding #2
**Dimension:** D15
**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s2/s2_p2_specification.md`
**Line:** 2 (pre-fix)
**Issue:** Lines 1–2 contained both an H1 and an H2 with identical text "S2.P2: Specification Phase":

```
# S2.P2: Specification Phase
## S2.P2: Specification Phase
```

This is an outright duplicate heading at the top of the file. The H2 is redundant and provides no additional navigation value.
**Fixed To:** Removed the duplicate `## S2.P2: Specification Phase` H2 on line 2.
**Status:** FIXED

---

### Finding #3
**Dimension:** D15
**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s10/s10_p1_guide_update_workflow.md`
**Line:** 677 (pre-fix)
**Issue:** The Exit Criteria section body ended with an inline `**Next Stage:** S10 Step 7 (Final Commit & Pull Request)` that duplicates navigation already provided by the `## Next Phase` H2 at line 793. The two lines diverge slightly in wording ("Step 7" vs "Return to s10_epic_cleanup.md") which could confuse an agent about the intended target. The canonical `## Next Phase` footer is authoritative.

**Fixed To:** Removed the inline `**Next Stage:**` line from the Exit Criteria body. The `## Next Phase` section at line 793 remains and provides complete navigation.
**Status:** FIXED

---

### Finding #4
**Dimension:** D15
**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/mandatory_gates.md`
**Line:** 763 (header of "Formal Gates Requiring User Input" subsection)
**Issue:** The header says "Formal Gates Requiring User Input: **3**" but the bulleted list below it contains **4** items:
- Gate 3: User Checklist Approval (S2.P1.I3)
- Gate 4.5: Epic Plan Approval (S3.P3) - includes test plan approval
- Gate 5: Implementation Plan Approval (S5.P3)
- Gate 25 (Dimension 11 validation): User decision if discrepancies found

**Fixed To:** Changed the count from `3` to `4`.
**Status:** FIXED

---

### Finding #5
**Dimension:** D16
**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/mandatory_gates.md`
**Line:** 21
**Issue:** The Table of Contents entry for S8 has a broken anchor:
```
10. [S8: Post-Feature Updates](#s8-post-.shamt/epics)
```
The anchor `#s8-post-.shamt/epics` does not correspond to any heading in the file. The actual H2 heading at line 648 is `## S8: Post-Feature Updates` which generates anchor `#s8-post-feature-updates`. The broken anchor was likely introduced when the heading was renamed and the TOC was not updated.

**Fixed To:**
```
10. [S8: Post-Feature Updates](#s8-post-feature-updates)
```
**Status:** FIXED

---

### Finding #6
**Dimension:** D7
**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/stage_1/stage_1_reference_card.md`
**Line:** 81
**Issue:** The disambiguation note added in Round 6 contains an internal inconsistency. The note says:

> "These are S1-local gates (labeled **S1-A, S1-B, S1-C** to avoid conflict...)"

But the actual headings immediately below use the longer form:
- `### S1-Gate-A: Discovery Phase Approval (Step 3)`
- `### S1-Gate-B: Feature Breakdown Approval (Step 4)`
- `### S1-Gate-C: Epic Ticket Validation (Step 4)`

An agent reading the note would see "S1-A" but encounter headings with "S1-Gate-A", making it unclear whether these are the same thing. The note should match the heading format exactly.

**Fixed To:** Updated note to use `S1-Gate-A, S1-Gate-B, S1-Gate-C` (matching the actual heading labels).
**Status:** FIXED

---

### Finding #7
**Dimension:** D15
**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/mandatory_gates.md`
**Lines:** 15 (TOC) and 110 (H2 section heading)
**Issue:** Both the TOC entry and the S2 section heading say "4 gates per feature":
- TOC line 15: `[S2: Feature Deep Dive (4 gates per feature - NEW...)]`
- H2 line 110: `## S2: Feature Deep Dive (4 gates per feature - NEW...)`

However, the Summary Statistics section at line 739 correctly states "S2: 3 formal gates per feature (Gates 1, 2, 3)". The S2 section does list a "Gate 4" but its own description says it is "embedded in Gate 3" and not a separate formal gate. The Quick Summary Table also lists only 3 S2 gates. The "4 gates" claim contradicts the file's own summary and creates confusion about how many formal gates S2 has.

**Fixed To:** Changed both the TOC entry and H2 heading from "4 gates per feature" to "3 formal gates per feature" to match the Summary Statistics and Quick Summary Table.
**Status:** FIXED

---

### Finding #8 (Pending User Decision)
**Dimension:** D7
**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/mandatory_gates.md`
**Lines:** 235 and 259
**Issue:** The file defines two distinct sections both labeled **Gate 4.5**:

1. **S3 section (line 235):** `### Gate 4.5: Epic Plan Approval` — S3.P3 user approval of complete epic plan (includes epic_smoke_test_plan.md presentation)
2. **S4 section (line 259):** `### Gate 4.5: Epic Test Plan Approval (NEW MANDATORY GATE)` — described as S4-level test plan approval before S5 begins

These two gates have the same number but represent two different approval events. An agent encountering "Gate 4.5 passed" in a prerequisite check cannot tell which of the two gates is meant. This also conflicts with the actual `stages/s4/s4_feature_testing_strategy.md` guide, which references Gate 4.5 only as the S3 prerequisite and does not define any S4-level gate of its own.

As a partial fix, the Summary Statistics line 741 has been updated from:
> "S4: 0 formal gates (test plan approval happens at Gate 4.5 in S3)"

to:
> "S4: 1 formal gate (Gate 4.5: Epic Test Plan Approval — note: shares label with S3's Gate 4.5; see S4 section for details)"

This makes the contradiction visible rather than hiding it. The underlying naming conflict (two gates labeled Gate 4.5) requires user decision:

**Option A:** Rename S4's gate to "Gate 4.6" or "Gate 4.5b" to distinguish it from S3's Gate 4.5. Update all references.
**Option B:** Consolidate the two Gate 4.5 definitions — since S3's Gate 4.5 already includes epic_smoke_test_plan.md presentation, the S4 section may be redundant. Remove the S4 Gate 4.5 section and update summary statistics.
**Option C:** Clarify that S3's Gate 4.5 is the ONLY Gate 4.5 and the S4 section is documentation of what that gate covers (not a separate gate). Reword the S4 section accordingly.

**Status:** PENDING USER DECISION

---

### Finding #9 (Pending User Decision)
**Dimension:** D17
**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s2/s2_p2_5_spec_validation.md`
**Lines:** 6 (header metadata) vs 547 (canonical nav footer)
**Issue:** The header metadata block says:
```
**Next Phase:** `stages/s2/s2_p3_refinement.md`
```

But the `## Next Phase` canonical navigation footer at the end of the file says:
```
**After completing S2.P2.5 for all features, proceed to:**
- Stage: S3 — Epic Planning Approval
- Guide: stages/s3/s3_epic_planning_approval.md
```

These point to different destinations: header says P3 Refinement, footer says S3 Approval. A reader seeing the header metadata first would have a different expectation than what the canonical navigation section says.

This inconsistency exists because `s2_p2_5_spec_validation.md` is a legacy phase file from the old 3-phase S2 model (P1 Research → P2 Specification → P2.5 Validation → P3 Refinement). The header metadata reflects the old model flow (next is P3). The footer was updated at some point to reflect the current model (P2.5 is optional/terminal before S3). The file is still referenced from `prompts/s2_p2.5_prompts.md`, so it cannot be treated as purely inert.

**User decision needed:** Which next destination is correct for S2.P2.5 in the current workflow? Whichever is correct, the header metadata and `## Next Phase` footer must be made consistent.

**Status:** PENDING USER DECISION

---

## Zero-Finding Confirmation

### D17: Stage Flow Consistency — All Main Stage Guides Clean

The primary stage flow chain was verified and is correct:

| Stage Guide | Next Stage Points To | Correct? |
|-------------|---------------------|---------|
| `stages/s1/s1_epic_planning.md` | `stages/s2/s2_p1_spec_creation_refinement.md` (S2.P1) | Yes |
| `stages/s2/s2_feature_deep_dive.md` | `stages/s3/s3_epic_planning_approval.md` | Yes |
| `stages/s3/s3_epic_planning_approval.md` | `stages/s4/s4_feature_testing_strategy.md` | Yes |
| `stages/s4/s4_feature_testing_strategy.md` | `stages/s5/s5_v2_validation_loop.md` | Yes |
| `stages/s5/s5_v2_validation_loop.md` | `stages/s6/s6_execution.md` | Yes |
| `stages/s6/s6_execution.md` | `stages/s7/s7_p1_smoke_testing.md` | Yes |
| `stages/s7/s7_p1_smoke_testing.md` | `stages/s7/s7_p2_qc_rounds.md` | Yes |
| `stages/s7/s7_p2_qc_rounds.md` | `stages/s7/s7_p3_final_review.md` | Yes |
| `stages/s7/s7_p3_final_review.md` | `stages/s8/s8_p1_cross_feature_alignment.md` | Yes |
| `stages/s8/s8_p1_cross_feature_alignment.md` | `stages/s8/s8_p2_epic_testing_update.md` | Yes |
| `stages/s8/s8_p2_epic_testing_update.md` | S5 (features remain) or S9 (all complete) | Yes |
| `stages/s9/s9_epic_final_qc.md` | `stages/s10/s10_epic_cleanup.md` | Yes |
| `stages/s9/s9_p1_epic_smoke_testing.md` | `stages/s9/s9_p2_epic_qc_rounds.md` | Yes |
| `stages/s9/s9_p2_epic_qc_rounds.md` | `stages/s9/s9_p3_user_testing.md` | Yes |
| `stages/s9/s9_p3_user_testing.md` | `stages/s9/s9_p4_epic_final_review.md` | Yes |
| `stages/s9/s9_p4_epic_final_review.md` | `stages/s10/s10_epic_cleanup.md` | Yes |
| `stages/s10/s10_epic_cleanup.md` | None (epic complete) | Yes |

### D16: Accessibility — Non-Standard Navigation Headings

Searched for `## Next:`, `## Return to`, `## Back to`, `## Go to` headings — zero found. All navigation headings use the standard `## Next Stage` or `## Next Phase` format.

Long guides (>200 lines) were checked for TOC presence:
- `stages/s4/s4_validation_loop.md` (385 lines): No TOC. However, examination shows that the majority of its apparent H2 headings are inside a fenced code block (template content for test_strategy.md). The actual guide navigation sections number ~13, which is manageable without a TOC. Not added.
- `stages/s2/s2_p2_cross_feature_alignment.md` (203 lines): Just over threshold with 10 navigational sections. Short enough that a TOC is not needed.
- `stages/s3/s3_parallel_work_sync.md` (266 lines): Specialized supplementary guide with 9 sections. Not added.
- `stages/s5/s5_update_notes.md` (285 lines): A proposal/change-tracking document, not an active stage guide. TOC not warranted.

### D7: Context-Sensitive Validation — Gate Disambiguation Notes

The S10-Gate-A disambiguation note was verified as internally consistent: the note text says "S10-local gate (labeled S10-Gate-A)" and the heading uses "S10-Gate-A". No inconsistency.

Discovery examples in `reference/stage_1/discovery_examples.md` were verified to correctly show the 3-consecutive-clean-rounds exit criterion (Finding #1 from SR6.2 was properly applied). Lines 191 and 334 both show correct criterion.

The S2 router guide (`s2_feature_deep_dive.md`) accurately describes the current 2-phase S2 model after Round 6's fixes. Gate 3 is described consistently as "User Approval" in the router and "User Checklist Approval" in mandatory_gates.md — these are compatible descriptions of the same gate.

Intentional uses of old S2 phase file names (`s2_p2_specification.md`, `s2_p3_refinement.md`) in `reference/naming_conventions.md` are correct — they appear as naming convention examples, not as active workflow references. These are legitimate uses.
