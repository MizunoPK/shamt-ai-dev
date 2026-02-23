# Round 13 SR13.4 Discovery Report

## Dimensions Covered: D7, D15, D16, D17

**Date:** 2026-02-22
**Sub-Round:** 13.4
**Auditor:** Agent (Claude Sonnet 4.6)

---

## Audit Scope

All guide files in `/home/kai/code/shamt-ai-dev/.shamt/guides/` covering:
- `stages/` (S1-S10 workflow guides)
- `reference/` (reference cards, glossary, mandatory_gates, etc.)
- `templates/`, `prompts/`, `debugging/`, `parallel_work/`, `missed_requirement/`, `changelog_application/`, `master_dev_workflow/`
- Root-level guides (README.md, EPIC_WORKFLOW_USAGE.md, prompts_reference_v2.md)

Audit output files in `audit/outputs/` were excluded (they document past errors, not violations).

---

## Findings: 3 genuine findings

---

### Finding 1: stage_5_reference_card.md — D7 (Integration & Compatibility) missing Gate 7a embed annotation

- **File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/stage_5/stage_5_reference_card.md`
- **Line:** 33
- **Dimension:** D7 (Context-Sensitive Validation) / D17 (Stage Flow Consistency)
- **Issue:** The workflow diagram lists D4, D10, and D11 with their embedded gate annotations (`← EMBEDS Gate 4a`, `← EMBEDS Gate 24`, `← EMBEDS Gates 23a, 25`) but D7 was missing `← EMBEDS Gate 7a`. This is inconsistent because Gate 7a is definitively embedded in D7 per `reference/mandatory_gates.md` line 269 ("Gate 7a → Embedded in Dimension 7: Integration & Compatibility") and `reference/mandatory_gates.md` line 679. The omission creates a misleading impression that only 4 of the 5 iteration gates have dimension mappings. The stage_5_reference_card.md at line 206 correctly lists all 5 gates (4a, 7a, 23a, 24, 25), but the diagram was incomplete.
- **Fix Applied:** Added `← EMBEDS Gate 7a` annotation to the D7 line in the workflow diagram.

**Before:**
```text
        │   ├─ D7: Integration & Compatibility
```
**After:**
```text
        │   ├─ D7: Integration & Compatibility ← EMBEDS Gate 7a
```

---

### Finding 2: mandatory_gates.md — Count heading says "3" but 4 items listed under "Formal Gates Requiring User Input"

- **File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/mandatory_gates.md`
- **Line:** 717
- **Dimension:** D15 (Duplication Detection — contradictory content, Type 8) / D17 (Stage Flow Consistency)
- **Issue:** The heading at line 717 states "Formal Gates Requiring User Input: 3" (consistent with canonical fact: 3 total formal user-approval gates are Gate 3, Gate 4.5, Gate 5). However, the bullet list beneath it contains 4 items: Gate 3, Gate 4.5, Gate 5, and Gate 25. Gate 25 is an iteration-level embedded gate that only requires user input conditionally (only when discrepancies are found between spec.md and validated documents). Including it in the list without clarification creates a count mismatch: header says 3, list has 4. This contradicts the canonical fact of "Total formal user-approval gates: 3."
- **Fix Applied:** Updated the heading to clarify "3 (always required) + 1 conditional" and added "(conditional)" notation to Gate 25 in the list.

**Before:**
```markdown
**Formal Gates Requiring User Input:** 3
- Gate 3: User Checklist Approval (S2.P1.I3)
- Gate 4.5: Epic Plan Approval (S3.P3) - includes test plan approval
- Gate 5: Implementation Plan Approval (S5 v2 — after Validation Loop, before S6)
- Gate 25 (Dimension 11 validation): User decision if discrepancies found
```
**After:**
```markdown
**Formal Gates Requiring User Input:** 3 (always required) + 1 conditional
- Gate 3: User Checklist Approval (S2.P1.I3)
- Gate 4.5: Epic Plan Approval (S3.P3) - includes test plan approval
- Gate 5: Implementation Plan Approval (S5 v2 — after Validation Loop, before S6)
- Gate 25 (Dimension 11 validation): User decision **only if discrepancies found** (conditional)
```

---

### Finding 3: glossary.md — "Cross-Feature Sanity Check" incorrectly attributed pairwise comparison to S3

- **File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/glossary.md`
- **Line:** 169
- **Dimension:** D15 (Duplication Detection — contradictory content, Type 8) / D17 (Stage Flow Consistency — S2->S3 scope alignment)
- **Issue:** The glossary defined "Cross-Feature Sanity Check" as "S3 process of systematic pairwise comparison of all feature specs." However, pairwise comparison was moved from old S3 to S2.P2. This is explicitly stated in:
  - `stages/s2/s2_feature_deep_dive.md` line 159: "S2.P2 is pairwise comparison (moved from old S3)"
  - `stages/s2/s2_feature_deep_dive.md` line 548: "S2.P1 (3 iterations) → S2.P2 (pairwise comparison) → S3"
  - `stages/s3/s3_epic_planning_approval.md` line 54: "Pairwise comparison removed (moved to S2.P2)"

  The glossary definition was never updated when pairwise comparison moved to S2.P2, causing a D17 scope alignment contradiction (S3 is described as doing pairwise comparison when it no longer does). S3's actual scope is epic-level testing strategy, documentation refinement, and user approval (Gate 4.5).
- **Fix Applied:** Updated the glossary definition to accurately describe S3's current scope and explicitly note that pairwise comparison is now in S2.P2.

**Before:**
```markdown
### Cross-Feature Sanity Check
S3 process of systematic pairwise comparison of all feature specs.
```
**After:**
```markdown
### Cross-Feature Sanity Check
S3 process of validating epic-level consistency across all feature specs. Note: Pairwise comparison of feature specs is performed in S2.P2 (moved from old S3). S3 focuses on epic-level testing strategy, documentation, and user approval (Gate 4.5).
```

---

## False Positives Identified and Dismissed

The following were investigated and determined NOT to be violations:

1. **s4_feature_testing_card.md missing "## Next Stage" / "## See Also"** — Has a "## Navigation" section on line 164 explicitly showing "Previous:" and "Next:" with guide links. Acceptable navigation pattern; file is only 191 lines so no TOC needed.

2. **s5_update_notes.md missing navigation** — Explicitly documented as "a historical reference document, not an active workflow guide" (line 15). No navigation section required.

3. **s5_update_notes.md and s5_v2_quick_reference.md with 22-iteration references** — s5_update_notes.md is a historical document; s5_v2_validation_loop.md mentions 22 iterations only in v1 vs v2 comparison table; s5_v2_quick_reference.md Migration Guide section is teaching content. All confirmed false positives per task brief.

4. **mandatory_gates.md "10 formal gates" claim** — Verified accurate: Gates 1, 2, 3, 4.5, 5, 4a, 7a, 23a, 24, 25 = exactly 10. Count is correct.

5. **naming_conventions.md "no longer used" references to iteration files** — Properly marked as deprecated with past tense ("Was correct:") and explicit deprecation notice. Valid historical reference with context.

6. **s3_epic_planning_approval.md "Moved from old S4" references** — Properly marked with "Moved from old S4" context. Valid historical reference.

7. **S7/S9 restart protocol references** — Checked; consistent throughout: S7.P2 and S9.P2 use fix-and-continue (not restart); S9.P3 user-reported bugs require restart from S9.P1. No contradictions found.

8. **Stage flow consistency checks (all 9 transitions)** — All S1→S2, S2→S3, S3→S4, S4→S5, S5→S6, S6→S7, S7→S8, S8→S5/S9, S9→S10 transitions were verified. Group workflow correctly says "groups only matter for S2, then epic-level S3." No remaining D17 contradictions found.

9. **D16 TOC check** — All files >500 lines have TOCs. Zero files missing TOC.

10. **D16 code block language tags** — All code blocks across all guide files have language tags. Zero untagged opening fences.

---

## Automated Checks Summary

| Check | Result |
|-------|--------|
| Files >500 lines missing TOC | 0 missing |
| Untagged opening code block fences | 0 untagged |
| Old S#a/b/c notation in current guides | None found |
| S1-S10 stage flow contradictions | 1 found (Finding 3) |
| Gate count contradictions | 1 found (Finding 2) |

---

## Summary

- **Genuine findings:** 3
- **Fixed:** 3
- **Pending:** 0

### Files Modified

1. `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/stage_5/stage_5_reference_card.md` — Added `← EMBEDS Gate 7a` to D7 in workflow diagram (line 33)
2. `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/mandatory_gates.md` — Clarified "Formal Gates Requiring User Input" count heading and marked Gate 25 as conditional (line 717)
3. `/home/kai/code/shamt-ai-dev/.shamt/guides/reference/glossary.md` — Updated "Cross-Feature Sanity Check" definition to accurately reflect S3's current scope and S2.P2's ownership of pairwise comparison (line 169)
