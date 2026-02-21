# Round 5 SR5.4 Discovery Report
## Dimensions: D7, D15, D16, D17

**Date:** 2026-02-21
**Sub-Round:** SR5.4
**Status:** COMPLETE — 4 genuine findings; 2 fixed, 2 flagged for user decision

---

## Dimension Results

### D7 — Terminology (Stage/Phase/Step labels)

**No new findings** under pure D7 scope. (Related issues captured under D17.)

---

### D15 — Content Duplication

**No new findings.** (Round 4 D15 fix in `s9_p4_epic_final_review.md` addressed this dimension's main target.)

---

### D16 — Navigation Completeness

**No new findings.** All stage guides reviewed have `## Next Phase` or `## Next Stage` sections. (D3-2 fix in SR5.1 addressed the only missing navigation in scope.)

---

### D17 — Stage Flow / Next Phase Accuracy

**Finding D17.1 (GENUINE — FIXED):**
- **File:** `stages/s9/s9_p2_epic_qc_rounds.md`, line 808
- **Issue:** `## Next Phase` section referenced the router guide instead of the direct guide:
  - Was: `"Guide: stages/s9/s9_epic_final_qc.md (S9.P3 section)"`
  - Should reference the actual S9.P3 file directly.
- **Fix Applied:** Changed to `"Guide: stages/s9/s9_p3_user_testing.md"`
- **Status:** ✅ FIXED

**Finding D17.2 (GENUINE — FIXED):**
- **File:** `stages/s2/s2_p2_specification.md`, lines 661 and 673–699
- **Issue:** Both the post-Gate-2 decision block and the `## Next Stage` section said "Proceed directly to S5" without any context disclaimer. This is incorrect for first-time S2 use (S3 and S4 are mandatory between S2 and S5). The direct path to S5 is only valid for rework mid-epic (returning from S5–S8 loop, where S3/S4 already completed).
- **Fix Applied:**
  - Decision block (line 661): Added parenthetical `"(first-time: S3 → S4 → S5; rework mid-epic: see Next Stage)"`
  - Next Stage section: Added context callout block distinguishing first-time vs. rework path, and updated Option A to list both paths explicitly.
- **Status:** ✅ FIXED

**Finding D17.3 (GENUINE — FLAGGED FOR USER DECISION):**
- **File:** `stages/s2/s2_feature_deep_dive.md`
- **Issue:** The guide simultaneously contains:
  - New 2-phase model (Quick Navigation table): S2.P1 = Spec Creation & Refinement, S2.P2 = Cross-Feature Alignment
  - Old 3-phase model (Sub-Stage Breakdown): S2.P1 = Research, S2.P2 = Specification, S2.P3 = Refinement
  - Both actively reference real files. This is a partial refactor artifact.
- **Note:** SR5.1 (D1-4) added a clarification note to the Sub-Stage Breakdown section, which reduces immediate confusion. However, the structural conflict requires a user decision on which phase model is authoritative before a complete fix can be applied.
- **User Decision Required:**
  - Option A: Keep new 2-phase model as authoritative → remove/archive old phase descriptions from Sub-Stage Breakdown, update all references
  - Option B: Revert to old 3-phase model → remove new phase labels from Quick Navigation table
  - Option C: Maintain current hybrid with clarification note (SR5.1 fix) pending future cleanup
- **Status:** ⚠️ FLAGGED — awaiting user decision

**Finding D17.4 (GENUINE — FLAGGED FOR USER DECISION):**
- **File:** `reference/stage_2/stage_2_reference_card.md`, lines 5 and 17–21
- **Issue:** Same partial-refactor conflict as D17.3, in the reference card:
  - Line 5 (header): `"## Stage 2: Feature Deep Dives — 2 Phases"`
  - Lines 17–21 (content): Lists 3 phases (Research, Specification, Refinement)
  - The header says 2 phases, the content describes 3.
- **Note:** This is the same S2 partial refactor — the reference card's header was updated to reflect the new 2-phase model but its content was not updated.
- **User Decision Required:** Same as D17.3 — which S2 phase model is authoritative?
- **Status:** ⚠️ FLAGGED — awaiting user decision (same decision as D17.3 resolves this)

---

## Summary

| Dimension | Findings | Genuine | Fixed | Flagged |
|-----------|----------|---------|-------|---------|
| D7 | 0 | 0 | — | — |
| D15 | 0 | 0 | — | — |
| D16 | 0 | 0 | — | — |
| D17 | 4 | 4 | 2 | 2 |
| **Total** | **4** | **4** | **2** | **2** |

---

## User Decision Required: S2 Phase Model

**Context:** S2 was partially refactored from 3 phases to 2 phases. The sub-guides (`s2_p2_specification.md`, `s2_p3_refinement.md`) still exist and are still actively linked. Two files still contain the old 3-phase descriptions alongside new 2-phase descriptions.

**Files affected by D17.3/D17.4 decision:**
- `stages/s2/s2_feature_deep_dive.md` (router guide)
- `reference/stage_2/stage_2_reference_card.md`

**Options:**
1. **Keep new 2-phase model** — Remove old phase descriptions, archive/redirect sub-guides
2. **Revert to 3-phase model** — Remove new phase labels from Quick Navigation table
3. **Keep current hybrid with clarification note** — Defer full cleanup to later

**Round 5 SR5.4 result:** NOT clean (4 genuine findings: 2 fixed, 2 pending user decision)
