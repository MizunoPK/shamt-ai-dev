# Round 9 SR4 Discovery Report — D7, D15, D16, D17

**Date:** 2026-02-22
**Sub-Round:** SR9.4
**Dimensions:** D7 (Context-Sensitive Validation), D15 (Duplication Detection), D16 (Accessibility & Usability), D17 (Stage Flow Consistency)
**Status:** COMPLETE
**Genuine Findings:** 19
**Fixed:** 19
**Pending User Decision:** 0

---

## Summary

| Dimension | Findings | Fixed | Pending |
|-----------|----------|-------|---------|
| D16 | 0 | 0 | 0 |
| D15 | 0 | 0 | 0 |
| D17 | 14 | 14 | 0 |
| D7 | 5 | 5 | 0 |
| **Total** | **19** | **19** | **0** |

Note: Most D17 findings are stale old-notation labels ("5a/5b/5c/5d/5e") that conflict with current stage notation. D7 findings are invalid gate names and a misplaced gate reference. All were fixed immediately.

---

## Findings / Zero-Finding Confirmations

---

### D16: Accessibility & Usability

**Files Searched:** All guides in stages/, reference/, audit/dimensions/, parallel_work/, debugging/, prompts/, templates/
**Checks Performed:**
1. Files >500 lines without TOC
2. Code blocks without language specifiers
3. Navigation links at stage boundaries

---

#### D16 Zero-Finding Confirmations

- All files over 500 lines in stages/, reference/, prompts/ have TOC sections — CORRECT
- Zero untagged code blocks (` ``` ` without a language specifier) found in stages/, templates/, prompts/, reference/, debugging/, missed_requirement/, parallel_work/ — CORRECT
- 26 untagged code blocks found in `audit/outputs/` — these are working output documents, not auditable guides; exempt per D16 scope
- Stage boundary navigation links are present in all primary stage guides (handoff statements referencing next guide)

---

### D15: Duplication Detection

**Files Searched:** All guides, with focus on gate definitions, stage flow claims, dimension counts
**Checks Performed:**
1. Contradictory gate placement claims (same gate, different stage)
2. Inconsistent dimension counts (same context, different numbers)
3. Contradictory scope claims for stages

---

#### D15 Zero-Finding Confirmations

- Gate 4.5 (Epic Plan Approval): Consistently placed in S3.P3 across all guides that reference it — CORRECT
- "12 dimensions" (S7/S9 QC rounds — 7 master + 5 stage-specific) vs "11 dimensions" (S5 Validation Loop — 7 master + 11 S5-specific): Both are correct in their respective contexts, different dimensional sets for different stages — NOT a contradiction
- S4 described as having "0 formal gates" across all guides that mention it — CORRECT; no contradiction
- Gate 5 placement: Consistently described as occurring after S5 v2 Validation Loop completes, before S6 — CORRECT; the mandatory_gates.md summary note "S5.P3" (fixed separately under D7) was the only stale reference

---

### D17: Stage Flow Consistency

**Files Searched:** All stage guides, all reference files
**Checks Performed:** Adjacent stage handoffs, old "5a/5b/5c/5d/5e" notation vs current S-notation, conditional logic coverage, scope alignment

---

#### Finding D17-1: `reference/stage_5/stage_5_reference_card.md` — old notation in workflow diagram code block

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/stage_5/stage_5_reference_card.md`
**Lines:** 43, 51, 68, 72, 76 (before fix)
**Issue:** Workflow diagram code block used old sub-stage labels:
- "STAGE 5b:" → should be "S6:"
- "STAGE 5c:" → should be "S7:"
- "STAGE 5d:" → should be "S8.P1:"
- "STAGE 5e:" → should be "S8.P2:"
- "STAGE 6 (if all features done)" → should be "S9 (if all features done)"
These conflicted with the correct S-notation used throughout the same file.
**Fix Applied:** Updated all five labels to current notation.

---

#### Finding D17-2: `reference/stage_5/stage_5_reference_card.md` — old notation in Time Estimates section

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/stage_5/stage_5_reference_card.md`
**Lines:** 172–189 (before fix)
**Issue:** Time Estimates section used "5a:", "5b:", "5c:", "5d+5e:" as section labels instead of current stage names.
**Fix Applied:**
- "5a:" → "S5 (Planning):"
- "5b:" → "S6 (Execution):"
- "5c:" → "S7 (Post-Impl):"
- "5d+5e:" → "S8.P1+S8.P2:"

---

#### Finding D17-3: `reference/stage_5/stage_5_reference_card.md` — old notation in Critical Rules heading

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/stage_5/stage_5_reference_card.md`
**Line:** 217 (before fix)
**Issue:** Section heading read "S8.P1 & 5e" — mixed notation (one correct, one old).
**Fix Applied:** → "S8.P1 & S8.P2"

---

#### Finding D17-4: `reference/stage_5/stage_5_reference_card.md` — S7/S8 exit conditions mixed into S5 Exit Conditions block

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/stage_5/stage_5_reference_card.md`
**Lines:** 281–285 (before fix)
**Issue:** The "S5 is complete for a feature when" checklist contained 5 items that belong to S7 and S8, not S5:
- "Validation Loop passed (3 consecutive clean rounds)" — duplicate of an earlier S5 item
- "PR review passed (all 11 categories)" — S7.P3 scope
- "Lessons learned documented" — S7.P3 scope
- "Remaining feature specs updated (S8.P1)" — S8.P1 scope
- "Epic test plan updated (S8.P2)" — S8.P2 scope
These items caused the S5 Exit Conditions to falsely include work that happens in later stages, creating a stage scope conflict (D17 pattern: scope alignment).
**Fix Applied:** Removed the 5 out-of-scope items; S5 Exit Conditions now correctly contain only S5-scoped items (draft creation, Validation Loop, embedded gates, Gate 5 approval, readiness for S6).

---

#### Finding D17-5: `stages/s8/s8_p1_cross_feature_alignment.md` — old notation in prose

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s8/s8_p1_cross_feature_alignment.md`
**Line:** 455 (before fix)
**Issue:** "Use clear rework criteria (S1, 2, or 5a)" — mixed missing "S" prefix on "2" and old "5a" label.
**Fix Applied:** → "Use clear rework criteria (S1, S2, or S5)"

---

#### Finding D17-6: `stages/s8/s8_p2_epic_testing_update.md` — old notation in Evolution Documentation

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s8/s8_p2_epic_testing_update.md`
**Line:** 991 (before fix)
**Issue:** "Track how plan matured from S1 → 4 → 5e" — missing "S" prefix on "4" and old "5e" label.
**Fix Applied:** → "Track how plan matured from S1 → S4 → S8.P2"

---

#### Finding D17-7: `stages/s9/s9_p1_epic_smoke_testing.md` — old notation in context paragraph

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s9/s9_p1_epic_smoke_testing.md`
**Line:** 76 (before fix)
**Issue:** "evolved through Stages 1, 4, and 5e" — missing "S" prefixes and old "5e" label.
**Fix Applied:** → "evolved through Stages S1, S4, and S8.P2"

---

#### Finding D17-8: `stages/s9/s9_p1_epic_smoke_testing.md` — old notation in testing scope comparison

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s9/s9_p1_epic_smoke_testing.md`
**Lines:** 115–116 (before fix)
**Issue:** "Feature testing (5c): Tests feature in isolation" and "Epic testing (6a): Tests entire epic" used old sub-stage labels.
**Fix Applied:**
- "Feature testing (5c):" → "Feature testing (S7):"
- "Epic testing (6a):" → "Epic testing (S9):"

---

#### Finding D17-9: `stages/s9/s9_p1_epic_smoke_testing.md` — old notation in pre-condition

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s9/s9_p1_epic_smoke_testing.md`
**Line:** 163 (before fix)
**Issue:** "Epic Progress Tracker shows all features at 5e" — old "5e" label.
**Fix Applied:** → "Epic Progress Tracker shows all features at S8.P2"

---

#### Finding D17-10: `reference/faq_troubleshooting.md` — four old notation instances

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/faq_troubleshooting.md`
**Lines:** 311, 316, 321–322, 388 (before fix)
**Issues:**
- Line 311: "LAST checkpoint before S8.P1/5e" — old "5e" label
- Line 316: Section header "S8.P1/5e: Post-Feature Alignment" — old "5e" in header
- Lines 321–322: "(5d)" and "(5e)" in parenthetical clarifications
- Line 388: "S6/5c/6 but fail in S10" — mixed old and new notation
**Fix Applied:**
- Line 311: → "S8.P1/S8.P2"
- Line 316: → "S8.P1/S8.P2: Post-Feature Alignment"
- Lines 321–322: "(5d)" → "(S8.P1)" and "(5e)" → "(S8.P2)"
- Line 388: → "S6/S7 but fail in S10"

---

#### Finding D17-11: `reference/implementation_orchestration.md` — four old notation instances

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/implementation_orchestration.md`
**Lines:** 5, 56, 360, 363, 428–429 (before fix)
**Issues:**
- Line 5 (description): "Stages 5b, 5c, 5d, 5e" in the document description
- Line 56 (workflow diagram): "YES → Stages 5d + 5e"
- Lines 360/363 (Decision section): "Go to 5d" and "updating specs (5d) or test plan (5e)"
- Lines 428–429 (Summary): "After 5c: Skip S8 if last feature" and "After 5e: Next feature's 5a"
**Fix Applied:**
- Line 5: → "Stages S6, S7, S8.P1, S8.P2"
- Line 56: → "YES → Stages S8.P1 + S8.P2"
- Lines 360/363: → "Go to S8.P1" and "updating specs (S8.P1) or test plan (S8.P2)"
- Lines 428–429: → "After S7: Skip S8 if last feature" and "After S8.P2: Next feature's S5"

---

#### Finding D17-12: `reference/GIT_WORKFLOW.md` — old notation in Best Practices (Commit Frequency)

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/GIT_WORKFLOW.md`
**Lines:** 351–353 (before fix)
**Issue:** Three old-notation labels in the "DON'T" list for commit timing:
- "Commit during planning stages (1-4)" — missing "S" prefixes
- "Commit mid-implementation (5a-5b)" — old sub-stage labels
- "Commit before testing passes (5c smoke testing/QC)" — old sub-stage label
**Fix Applied:**
- → "Commit during planning stages (S1-S4)"
- → "Commit mid-implementation (S5-S6)"
- → "Commit before testing passes (S7 smoke testing/QC)"

---

#### D17 Zero-Finding Confirmations

- S1→S2 handoff: s1 directs to s2_feature_deep_dive.md; s2 confirms prerequisite of S1 completion — CONSISTENT
- S2→S3 handoff: s2 directs to s3_epic_planning_approval.md after all features complete S2; s3 confirms prerequisite — CONSISTENT
- S3→S4 handoff: s3 directs to s4 after Gate 4.5 approval; s4 confirms prerequisite — CONSISTENT
- S4→S5 handoff: s4 directs to s5_v2_validation_loop.md; s5 confirms S4 completion as prerequisite — CONSISTENT
- S7→S8/S9 conditional: s7 correctly branches to S8 (if features remain) or S9 (if last feature); s8 confirms S7 prerequisite; s9 confirms S8 completion prerequisite — CONSISTENT
- S9→S10 handoff: s9 directs to s10_epic_cleanup.md after user testing passes; s10 confirms user testing as prerequisite — CONSISTENT
- `stages/s5/s5_update_notes.md` old notation: explicitly labeled "historical reference document" — D7 context exception applied, not fixed

---

### D7: Context-Sensitive Validation

**Files Searched:** All guides that were touched during D17 pass, plus explicitly labeled historical/migration documents
**Checks Performed:** Verifying that all fixes were genuine errors (not intentional historical/contextual uses), and checking for remaining false-positive candidates

---

#### Finding D7-1: `reference/mandatory_gates.md` — stale "S5.P3" reference in summary section

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/mandatory_gates.md`
**Line:** 720 (before fix)
**Issue:** Summary section stated "Gate 5: Implementation Plan Approval (S5.P3)". S5 v2 does not have a Phase 3 (P3) — it has Phase 1 (Draft Creation) and Phase 2 (Validation Loop). Gate 5 occurs after the Validation Loop completes, before S6 begins. The "S5.P3" label referred to the old S5 v1 structure and was stale.
**D7 Analysis:** Not a historical reference or anti-pattern example — it appeared in a current-state reference table describing where Gate 5 occurs. This is an active inaccuracy, not an intentional exception.
**Fix Applied:** → "Gate 5: Implementation Plan Approval (S5 v2 — after Validation Loop, before S6)"

---

#### Finding D7-2: `reference/stage_9/epic_final_review_templates.md` — stale "S5.P3 guide" reference in improvement note

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/stage_9/epic_final_review_templates.md`
**Line:** 617 (before fix)
**Issue:** An improvement suggestion read "S5.P3 guide: Add performance baseline comparison to smoke testing". S5 has no P3 in v2; smoke testing is in S7.P1.
**D7 Analysis:** Not a historical reference document or anti-pattern example — it was a current improvement suggestion pointing to the wrong guide.
**Fix Applied:** → "S7.P1 guide: Add performance baseline comparison to smoke testing"

---

#### Finding D7-3: `reference/stage_5/stage_5_reference_card.md` — nonexistent "Gate 3a" in Sub-Stage Summary Table

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/stage_5/stage_5_reference_card.md`
**Line:** 86 (before fix)
**Issue:** The Mandatory Gates column for S5.P2 listed "Gates 3a/23a/24/25". The valid iteration-level gates in S5 v2 are: 4a, 7a, 23a, 24, 25 (per mandatory_gates.md). "Gate 3a" does not exist; it is not listed anywhere in mandatory_gates.md or the S5 guide. Gates 4a and 7a were both omitted.
**D7 Analysis:** No contextual reason for "3a" to be valid — mandatory_gates.md is the authoritative gate list and does not define a Gate 3a. This was a genuine error in the gate list.
**Fix Applied:** → "Gates 4a/7a/23a/24/25 embedded"

---

#### Finding D7-4: `reference/stage_5/stage_5_reference_card.md` — nonexistent "Gate 3a" in Exit Conditions checklist

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/stage_5/stage_5_reference_card.md`
**Line:** 278 (before fix)
**Issue:** Exit Conditions checklist read "All embedded gates passed (Gates 3a, 23a, 24, 25)" — same nonexistent Gate 3a problem as D7-3, missing Gates 4a and 7a.
**D7 Analysis:** Same as D7-3 — no valid contextual reason for "Gate 3a".
**Fix Applied:** → "All embedded gates passed (Gates 4a, 7a, 23a, 24, 25)"

---

#### D7 False Positives Dismissed

**`stages/s5/s5_update_notes.md` — old "5a/5b/5c/5d/5e" notation throughout:**
File opens with "This file is a historical reference document tracking changes made to Stage 5." Old notation throughout is intentional — it documents what the old notation was before migration. Not a D17 or D7 violation. No fix needed.

**`reference/stage_5/s5_v2_quick_reference.md` — "I5a", "I6a", "I7a" iteration labels in v1→v2 mapping table:**
These appear in an explicit S5 v1 → v2 migration mapping table. The "I5a" labels are iteration labels within the v1 iteration numbering scheme (not stage labels). The table is contextualized as showing how v1 structure mapped to v2. Not a violation. No fix needed.

**`stages/s10/s10_epic_cleanup.md` — "5a.", "5b." as step numbering:**
These are sub-step labels for "Step 5" (as in "step 5a" and "step 5b" within a numbered list), not stage notation. The surrounding text makes clear these are implementation sub-steps, not stage references. Not a violation. No fix needed.

**`audit/outputs/` — 26 untagged code blocks:**
These are working output documents (past audit reports), not auditable guides. D16 scope covers guides only. Not violations.

---

## Files Modified This Sub-Round

| File | Dimension | Changes Made |
|------|-----------|--------------|
| `reference/stage_5/stage_5_reference_card.md` | D17, D7 | Fixed old "STAGE 5b/5c/5d/5e" labels in workflow diagram; fixed old "5a/5b/5c/5d+5e" in Time Estimates; fixed "S8.P1 & 5e" heading; removed 5 S7/S8-scoped items from S5 Exit Conditions; fixed nonexistent "Gate 3a" in table and checklist → correct "Gates 4a/7a/23a/24/25" |
| `stages/s8/s8_p1_cross_feature_alignment.md` | D17 | Fixed "S1, 2, or 5a" → "S1, S2, or S5" |
| `stages/s8/s8_p2_epic_testing_update.md` | D17 | Fixed "S1 → 4 → 5e" → "S1 → S4 → S8.P2" |
| `stages/s9/s9_p1_epic_smoke_testing.md` | D17 | Fixed three old notation instances: "Stages 1, 4, and 5e"; "Feature testing (5c)"/"Epic testing (6a)"; "all features at 5e" |
| `reference/faq_troubleshooting.md` | D17 | Fixed four old notation instances: "S8.P1/5e", section header "S8.P1/5e:", "(5d)"/"(5e)" parentheticals, "S6/5c/6" |
| `reference/implementation_orchestration.md` | D17 | Fixed four old notation clusters: description "5b/5c/5d/5e"; diagram "5d + 5e"; Decision section "5d"/"5e"; Summary section "5c"/"5e"/"5a" |
| `reference/GIT_WORKFLOW.md` | D17 | Fixed three old notation instances in Commit Frequency DON'T list: "stages (1-4)", "(5a-5b)", "(5c smoke testing/QC)" |
| `reference/mandatory_gates.md` | D7 | Fixed stale "S5.P3" reference in gate summary → "S5 v2 — after Validation Loop, before S6" |
| `reference/stage_9/epic_final_review_templates.md` | D7 | Fixed stale "S5.P3 guide" reference → "S7.P1 guide" |

---

## False Positives Investigated and Dismissed

| Candidate | Dimension | Why Dismissed |
|-----------|-----------|---------------|
| `stages/s5/s5_update_notes.md` old "5a/5b" notation | D17 | Explicitly labeled "historical reference document" — old notation is intentional and correct in this context |
| `reference/stage_5/s5_v2_quick_reference.md` "I5a/I6a/I7a" labels | D7 | These are iteration labels within a v1→v2 migration mapping table, not stage references — valid historical context |
| `stages/s10/s10_epic_cleanup.md` "5a./5b." sub-step labels | D7 | These are numbered sub-steps of Step 5 (step 5a, step 5b), not stage notation — context makes clear it's step numbering |
| `audit/outputs/` 26 untagged code blocks | D16 | Working output documents, not auditable guides — out of D16 scope |
| "12 dimensions" vs "11 dimensions" across guides | D15 | Different contexts: S7/S9 uses 12 dimensions (7 master + 5 stage-specific); S5 uses 11 S5-specific dimensions. Both are correct in context — not a contradiction |

---

## Not Investigated (Out of Scope for SR9.4)

- D1, D2, D3, D8 → Covered by SR9.1
- D4, D5, D6, D13, D14 → Covered by SR9.2
- D9, D10, D11, D12, D18 → Covered by SR9.3

---

## Context: Round 8 vs Round 9

Round 8 SR8.4 found 0 D17 findings (clean). Round 9 SR9.4 found 14 D17 findings — all instances of the old "5a/5b/5c/5d/5e" sub-stage notation that survived previous audit rounds. These were concentrated in reference files (stage_5_reference_card, faq_troubleshooting, implementation_orchestration, GIT_WORKFLOW) and S8/S9 stage guides. The "Gate 3a" errors in stage_5_reference_card.md (D7 findings) appear to be a typo where "4a" was mistyped as "3a" and Gate 7a was omitted, possibly from when the gate list was first written.

---

**Report Generated:** 2026-02-22
