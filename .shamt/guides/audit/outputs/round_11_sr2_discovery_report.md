# Round 11 SR11.2 Discovery Report
## Dimensions Covered: D4, D5, D6, D13, D14
## Findings: 3 genuine findings

**Date:** 2026-02-22
**Sub-Round:** 11.2
**Auditor:** Claude Sonnet 4.6

---

### Finding 1 (D14): d3_workflow_integration.md — S5 phase count example incorrect (Type 4)

- **File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/audit/dimensions/d3_workflow_integration.md`
- **Lines:** 350–357
- **Issue:** Type 4 (Phase and Iteration Dependencies) section showed `**Example: S5 (Implementation Planning) has 3 phases:**` with S5.P1 Round 1 (I1-I7), S5.P2 Round 2 (I8-I13), S5.P3 Round 3 (I14-I22). This describes S5 v1 structure. S5 v2 has only 2 phases: Phase 1 (Draft Creation) and Phase 2 (Validation Loop). An auditing agent reading this would expect to find 3 phases in S5 and mistakenly accept S5.P3 references as valid.
- **Fix Applied:** Changed example to:
  - Header: `**Example: S5 (Implementation Planning) has 2 phases (S5 v2):**`
  - Content: `S5 Phase 1: Draft Creation → S5 Phase 2: Validation Loop (3 consecutive clean rounds across 11 dimensions)`
  - Added v2 note clarifying that S5 v1 used 3 phases (S5.P1/P2/P3) and S5 v2 uses 2 phases only.

---

### Finding 2 (D14): d3_workflow_integration.md — Root Cause 4 scenario describes S5 with 3 phases (Type 4)

- **File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/audit/dimensions/d3_workflow_integration.md`
- **Lines:** 600–612 (Root Cause 4)
- **Issue:** Root Cause 4 scenario started with "S5 splits into 3 phases (S5.P1, S5.P2, S5.P3)" as a concrete scenario. While this was describing a historical pattern (S5 v1), it was not labeled as historical and could be read as a current scenario — reinforcing the incorrect 3-phase model for S5.
- **Fix Applied:** Changed the scenario to be generic (describing any stage gaining phases) and added a Historical S5 Example note clarifying the specific S5 v1 → v2 history.

---

### Finding 3 (D14): d3_workflow_integration.md — Rule 3 example uses S5 v1 (S5.P1/P2/P3) as valid simplified router notation

- **File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/audit/dimensions/d3_workflow_integration.md`
- **Lines:** 854–868 (Rule 3 — Context-Sensitive Rules)
- **Issue:** Rule 3 showed `S5.P1 → S5.P2 → S5.P3 → S6` as an example of a valid simplified router workflow. Since S5 v2 does not have P1/P2/P3 notation at all, showing this as a valid pattern would cause an auditor to incorrectly PASS a router that uses the abolished 3-phase S5 structure.
- **Fix Applied:**
  - Changed the example to use S7 (which does have 3 correct phases) as the pattern demonstration.
  - Added a S5 v2 warning note explicitly stating that `S5.P1 → S5.P2 → S5.P3` is S5 v1 notation and should be flagged as a violation.
  - Updated the Validation line to add "AND phase structure matches current workflow".

---

## False Positives Investigated

### D4 FP-1: "16 dimensions" in d4_count_accuracy.md (teaching examples)

**Files:** `audit/dimensions/d4_count_accuracy.md` (multiple lines)
**Ruling: NOT A VIOLATION**
**Reasoning:** Per Round 3 SR2 precedent and Round 10 SR2 confirmation, count claims in teaching examples within dimension guides are exempted. The actual dimension count is 18 (18 files in `audit/dimensions/`, confirmed by `audit/README.md` lines 100-133 which consistently say "18 dimensions").

### D4 FP-2: "19 templates" in d14_content_accuracy.md (teaching examples)

**File:** `audit/dimensions/d14_content_accuracy.md`
**Ruling: NOT A VIOLATION**
**Reasoning:** Per Round 3 SR2 and Round 10 SR2 precedent — these are teaching examples showing the type of count-accuracy issue to catch, not current factual claims. Actual template count is 23 (.md files) + 1 (.txt file) = 24 files total (including TEMPLATES_INDEX.md), or 22 actual templates excluding the index and .txt file.

### D4 FP-3: Phase count table in d4_count_accuracy.md shows S4 as "4 iterations (no phases)"

**File:** `audit/dimensions/d4_count_accuracy.md` line 239 (Phase Count by Stage table)
**Ruling: NOT A VIOLATION**
**Reasoning:** The table entry for S4 says "4 iterations (no phases)" which is correct — S4 uses I1-I4 notation (4 iterations) and has no phase structure. This is accurate per `reference/mandatory_gates.md` and `stages/s4/s4_feature_testing_strategy.md`.

### D5 FP-1: "TBD" markers in research_examples.md and specification_examples.md

**Files:** `reference/stage_2/research_examples.md`, `reference/stage_2/specification_examples.md`
**Ruling: NOT A VIOLATION**
**Reasoning:** These TBDs appear inside code blocks showing realistic research note examples. They represent pending research findings that an agent would fill in during actual research (e.g., "rank priority: Integer ranking 1-500 (TBD - ask user for range)"). They are example content showing how research notes look, not stub sections of the guide itself.

### D5 FP-2: "⏳ UNREAD" in s2_p1_spec_creation_refinement.md

**File:** `stages/s2/s2_p1_spec_creation_refinement.md` line 212
**Ruling: NOT A VIOLATION**
**Reasoning:** The ⏳ UNREAD marker appears inside a code block showing the template format for parallel-work agent communication messages. It is an example of what the message format looks like, not stub content in the guide itself.

### D6 FP-1: "Round N" in pr_review_issues_template.md and VALIDATION_LOOP_LOG_S5_template.md

**Files:** `templates/pr_review_issues_template.md`, `templates/VALIDATION_LOOP_LOG_S5_template.md`
**Ruling: NOT A VIOLATION**
**Reasoning:** "Round N" in pr_review_issues_template refers to PR review iteration rounds (Round 1a, 1b, 1c, 1d, Round 2, etc.). In VALIDATION_LOOP_LOG_S5_template, "Round 1", "Round 2", etc. refer to S5 Validation Loop rounds. These are not old stage notation (S5a, S5b) but valid round labels for the respective workflows.

### D6 FP-2: "S5 Round 2" in debugging_guide_update_recommendations_template.md

**File:** `templates/debugging_guide_update_recommendations_template.md` lines 84, 238, 274
**Ruling: NOT A VIOLATION**
**Reasoning:** "S5 Round 2" is used as an example context for when a debugging insight was discovered (e.g., "During S5 Round 2 when analyzing record data edge cases"). "S5 Round N" is accepted shorthand throughout the guides for S5's validation rounds (Phase 1, Phase 2, Phase 3 of the Validation Loop). This is not the old S5a/S5b/S5c notation.

### D13 FP-1: Missing "Critical Rules" sections in several stage guides

**Files:** Various s2, s3, s4, s5 guides
**Ruling: NOT A VIOLATION**
**Reasoning:** Many of these guides use "🛑 Critical Rules" (with emoji — grep missed these), or use equivalent functional sections (SPECIAL CASES, COMMON ISSUES, ANTI-PATTERNS in s5_v2_validation_loop.md). Stage iteration files (s5_p1_i3*, etc.) follow the known exceptions pattern documented in `audit/reference/known_exceptions.md`. The D13 known exceptions cover 17 files that intentionally lack formal section structures.

### D14 FP-1: "Last Updated" missing from README.md, EPIC_WORKFLOW_USAGE.md, prompts_reference_v2.md

**Files:** `.shamt/guides/README.md`, `EPIC_WORKFLOW_USAGE.md`, `prompts_reference_v2.md`
**Ruling: NOT A VIOLATION**
**Reasoning:** Per Round 3 SR2 ruling (reaffirmed in Round 10 SR2): "Last Updated missing from root-level files is not a D13/D14 requirement." These files intentionally omit Last Updated metadata.

### D14 FP-2: "S5 splits into 3 phases" at d3 line 603 — Is this separate from Finding 2?

**Ruling: SAME FINDING AS FINDING 2** (addressed together under Root Cause 4 fix)

### D14 FP-3: confidence_calibration.md "13-16 dimensions checked"

**File:** `audit/reference/confidence_calibration.md` line 83
**Ruling: NOT A VIOLATION**
**Reasoning:** "13-16 dimensions" is a RANGE describing partial coverage in a confidence scoring table (0.6 = "Partial" coverage). With 18 total dimensions, this range (72-89%) is a coverage band, not an incorrect count claim.

---

## Coverage Report

### Files Checked

**Dimension guides (audit/dimensions/):** All 18 dimension files verified for required sections (D13); d3 checked extensively for S5 phase claims (D14); d4, d5, d6, d13, d14 read in full.

**Stage guides (stages/):** S1-S10 key guides spot-checked for D4/D14 count claims; S5/S7 guides verified for correct dimension counts (11 vs 12); S7.P2 restart protocol verified; S10 guide structure verified.

**Reference guides (reference/):** mandatory_gates.md, faq_troubleshooting.md, glossary.md, naming_conventions.md, stage_5/s5_v2_quick_reference.md, stage_5/stage_5_reference_card.md, validation_loop_s7_feature_qc.md checked.

**Templates (templates/):** TEMPLATES_INDEX.md verified (23 templates listed, consistent structure); epic_readme_template.md, feature_readme_template.md, VALIDATION_LOOP_LOG_S5_template.md checked for D6 currency and D13 completeness.

**Root files:** EPIC_WORKFLOW_USAGE.md verified — all 10 stages present; prompts_reference_v2.md verified — all stage prompt files referenced.

**Audit reference files (audit/reference/):** issue_classification.md, confidence_calibration.md, known_exceptions.md reviewed for D14 accuracy.

### Known Exceptions Applied (Per Prior Rulings)

- 17 files intentionally lack Prerequisites/Exit Criteria sections (Round 3 D13 known exceptions)
- "Last Updated" missing from root-level files is not a D13/D14 requirement (Round 3 SR2)
- Teaching examples in dimension guides are not active count claims (Round 3 SR2)
- Reference card files intentionally omit TOC (Round 8 SR4 precedent)
- Audit output files not subject to D4/D5/D6 checks (scope exclusion)

---

## Summary
- Genuine findings: 3
- Fixed: 3
- Pending: 0

All 3 findings were in `audit/dimensions/d3_workflow_integration.md` — residual S5 v1 (3-phase) content that was not caught in prior rounds. The gate table in d3 was fixed in Round 10 SR4, but the phase-count teaching examples, Root Cause 4 scenario, and Rule 3 router example all still used S5 v1 structure. These are now corrected to reflect S5 v2 (2 phases: Draft Creation + Validation Loop).
