# Discovery Report — Round 3, Sub-Round 3.1 (Core Quality)

**Date:** 2026-02-20
**Sub-Round:** 3.1 (D1, D2, D3, D8)
**Duration:** ~45 minutes
**Total Genuine Issues Found:** 1 (fixed)

---

## Summary by Dimension

| Dimension | Issues Found | Fixed | Notes |
|-----------|--------------|-------|-------|
| D1: Cross-Reference Accuracy | 0 | — | All inter-guide links valid |
| D2: Stage Ordering Compliance | 0 | — | All stage transitions correct |
| D3: Gate Numbering Consistency | 0 | — | Gate 7.2 IS formally defined (mandatory_gates.md line 692) |
| D8: Section Header Hierarchy | 1 | ✅ | s8_p2_testing_examples.md: h1 → h3 skip; 3 false positives |
| **TOTAL** | **1** | **1** | |

---

## Investigation Notes

### D1 Analysis

**Cross-reference accuracy — CLEAN:** All inter-guide links in stages/, reference/, templates/, debugging/, audit/, missed_requirement/, and parallel_work/ verified. All referenced files exist on disk. No broken links found.

### D2 Analysis

**Stage ordering — CLEAN:** No instances of guides referencing stages out of sequence. All stage transitions follow S1 → S2 → ... → S10 order.

### D3 Analysis

**Gate numbering — CLEAN:** Initial investigation flagged "Gate 7.2" in `stages/s10/s10_p1_guide_update_workflow.md` line 45 as potentially non-standard. Cross-referenced against `reference/mandatory_gates.md`:

- **mandatory_gates.md line 692:** `### Gate 7.2: User Testing (ZERO Bugs)` — formally defined
- **mandatory_gates.md line 735:** `S10: User Testing Zero Bugs (referenced as "Gate 7.2" in this file)` — explicitly noted

Gate 7.2 is legitimately defined. The prior session's false alarm arose from reading only the gates summary list (lines 1-25 of mandatory_gates.md) rather than the full file. All gate references verified consistent.

**See also:** Gate 7.2 also correctly referenced in `prompts/guide_update_prompts.md` lines 10 and 53.

### D8 Analysis — Header Hierarchy (1 FIXED, 3 FALSE POSITIVES)

**D8-1 (FIXED): `reference/s8_p2_testing_examples.md` line 12**

File structure before fix:
- Line 1: `# S8.P2: Epic Testing Update - Real-World Examples` (h1)
- Line 12: `### Example 1: Adding Integration Point Test` (h3) ← **skip!**

**Root cause:** The file had only h1 and h3 levels — no h2 "chapter" separator between the metadata block and the first example.

**Fix:** Added `## Examples` h2 header before line 12 (now line 11).

**File structure after fix:**
- Line 1: `# S8.P2: ...` (h1)
- Line 11: `## Examples` (h2) ← added
- Line 13: `### Example 1: ...` (h3)
- Lines 38, 54, 79: `### Scenario N: ...` (h3) — correctly under `## Examples`
- Lines 132, 160, 200: `### Example 2 / Scenario N: ...` (h3) — correctly under `## Examples`
- Line 236: `### Example 3: ...` (h3) — correctly under `## Examples`

Note: "## File: ..." lines at 19 and 138, and "## Epic Success Criteria" at 244 are all inside code blocks — false positives from grep.

---

**D8-FP-1: `debugging/investigation.md` line 432 — FALSE POSITIVE**

The D8 checker flagged h2 → h4 skip. Investigation revealed the `## ` at line 411 is INSIDE a fenced code block (` ```markdown ` opened at line 410). The state-tracker was seeing it as a non-code-block header, making the real h4 at line 432 appear to skip a level. Actual hierarchy is correct.

**D8-FP-2: `audit/reference/user_challenge_protocol.md` line 159 — FALSE POSITIVE**

The D8 checker flagged h1 → h3 skip. Actual file structure is:
- h1 (line 1) → h2 `## Core Principle` (line 20) → h3 subsections
- h2 `## Common Challenge Types` (line 58) → h3 Challenge Types 1, 2, 3 (lines 60, 100, 159)

**Root cause of false flag:** Nested fence parity inversion. Inside `## Challenge Type 2`'s `Appropriate Response` block:
- Line 121: ` ```markdown ` opens outer block (in_block = True)
- Line 137: ` ```bash ` — literal content inside outer block, but naive tracker toggles in_block = False (PARITY INVERTED)
- Line 140: ` ``` ` — tracker now sees as OPENING fence → in_block = True (inverted)
- Line 143: ` ```bash ` — tracker sees as closing → in_block = False (inverted)
- Lines 144-146: bash comments `# Re-run discovery pattern`, `# Output: ...` — tracker thinks NOT in block → D8 checker records these as h1 headers! (last_level = 1)
- Line 147: ` ```text ` — tracker sees as opening → in_block = True
- Line 150: ` ``` ` — tracker sees as closing → in_block = False
- Line 159: `### Challenge Type 3` — NOT in block; last recorded level was 1 (bash comment) → reports h1 → h3 skip

**Note for SR3.4:** This file has the same nested fence pattern as D16.1 violations fixed in SR2.4. The bare ` ``` ` at line 140 (post-inversion) would be flagged by the D16.1 script as a bare opening fence. Flagged for D16.1 check in SR3.4.

**D8-FP-3: `audit/stages/stage_3_apply_fixes.md` line 269 — FALSE POSITIVE**

The D8 checker flagged h1 → h4 skip. The `# ` at line 262 (which the checker treated as h1) is inside a code block (bounded by ` ``` ` at lines 260-263). The actual h4 at line 269 (`#### STEP 6: Decision Point`) is properly nested under a real h2 → h3 progression elsewhere in the file.

---

## False Positive Summary

| Finding | Reason Dismissed |
|---------|-----------------|
| D3: Gate 7.2 | Formally defined in mandatory_gates.md line 692 |
| D8: debugging/investigation.md line 432 | h2 inside fenced code block (D9.2 pattern) |
| D8: user_challenge_protocol.md line 159 | Parity inversion from nested ` ```bash ` inside ` ```markdown ` block; bash comments mistaken for h1 |
| D8: stage_3_apply_fixes.md line 269 | h1 inside fenced code block (D9.2 pattern) |

---

## Files Modified in SR3.1

| File | Change |
|------|--------|
| `reference/s8_p2_testing_examples.md` | D8: Added `## Examples` h2 before first `### Example` section |

---

## Open Items for SR3.4

- **user_challenge_protocol.md D16.1:** Nested fence parity inversion at lines 121-150 (` ```markdown ` containing ` ```bash ` as literal content) causes D16.1 false positive at bare ` ``` ` line 140. Evaluate and fix in SR3.4 D16.1 check.

---

## Sub-Round 3.1 Loop Decision

**Result:** 1 genuine issue found and fixed (D8 h1→h3 skip in s8_p2_testing_examples.md)

**Proceed to:** Sub-Round 3.2 (Content Quality: D4, D5, D6, D13, D14)

**Open items from prior rounds still valid:**
- D13-3: Hardcoded 2025 dates in 3 example blocks (deferred from SR2.2) — evaluate in SR3.2
- D16.3: ~67 remaining files without TOCs (150-400 line range) — evaluate priority in SR3.4
- D10: Monitor `validation_loop_master_protocol.md` (1249 lines) and `s2_parallel_protocol.md` (1245 lines) — evaluate in SR3.3
- D9.2: Duplicate header false positives (duplicate header detector ignores code block context) — confirmed still false positives
