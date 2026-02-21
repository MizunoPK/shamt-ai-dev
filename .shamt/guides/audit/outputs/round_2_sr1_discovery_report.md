# Discovery Report — Round 2, Sub-Round 2.1 (Core Quality)

**Date:** 2026-02-20
**Sub-Round:** 2.1 (D1, D2, D3, D8)
**Duration:** ~30 minutes
**Total Genuine Issues Found:** 1 (fixed)

---

## Summary by Dimension

| Dimension | Issues Found | Fixed | Notes |
|-----------|--------------|-------|-------|
| D1: Cross-Reference Accuracy | 1 | ✅ | Broken link in s9_p2_epic_qc_rounds.md — introduced by SR1.4 D16.2 fix |
| D2: Stage Ordering Compliance | 0 | — | All stage references use correct order |
| D3: Gate Numbering Consistency | 0 | — | All gate numbers accurate and consistent |
| D8: Section Header Hierarchy | 0 | — | All h2→h3→h4 progressions valid |
| **TOTAL** | **1** | **1** | |

---

## Investigation Notes

### D1 Analysis

**D1-1 (FIXED): Broken link in s9_p2_epic_qc_rounds.md**

The `## Next Phase` section added in SR1.4 (D16.2 fix) contained a link to `s9_p1_epic_smoke_test.md`. The correct filename is `s9_p1_epic_smoke_testing.md` (with "ing"). This was a typo introduced during the SR1.4 fix.

**Fix applied:** Changed `s9_p1_epic_smoke_test.md` → `s9_p1_epic_smoke_testing.md` in the `## Next Phase` See also line.

**All other D1 checks:** Scanned all inter-guide links in stages/, reference/, templates/, debugging/, missed_requirement/. Zero additional broken links found. All referenced files exist on disk.

### D2 Analysis

**Stage ordering references — CLEAN:** Zero instances of guides referencing stages out of sequence (e.g., S6 → S4, S10 → S8). All stage transitions follow S1 → S2 → ... → S10 order.

### D3 Analysis

**Gate numbering — CLEAN:** All gate numbers match the authoritative list in `reference/mandatory_gates.md`. No duplicate gate numbers, no gaps, no out-of-sequence references. Gate 4.5 notation consistent throughout (decimal format correct).

### D8 Analysis

**Section header hierarchy — CLEAN:** No h2→h4 skips found (all `##` → `####` transitions have intervening `###`). The false positive pattern from Round 1 (duplicate headers inside code blocks) was already known and confirmed again here. Zero genuine violations.

---

## False Positive Summary

| Finding | Reason Dismissed |
|---------|-----------------|
| D8: Header hierarchy gaps | All instances inside fenced code blocks (D9.2 pattern) |
| D1: Several "missing" links | Correct filenames verified against actual filesystem |

---

## Sub-Round 2.1 Loop Decision

**Result:** 1 genuine issue found and fixed (D1 broken link)

**Root cause of D1 issue:** The SR1.4 fix introduced a filename typo — `s9_p1_epic_smoke_testing.md` was written as `s9_p1_epic_smoke_test.md`. Caught on first re-read in SR2.1.

**Proceed to:** Sub-Round 2.2 (Content Quality: D4, D5, D6, D13, D14)
