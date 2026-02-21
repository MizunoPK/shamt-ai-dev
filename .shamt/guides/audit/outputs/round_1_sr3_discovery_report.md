# Discovery Report — Round 1, Sub-Round 1.3 (Structural Dimensions)

**Date:** 2026-02-20
**Sub-Round:** 1.3 (D9, D10, D11, D12, D18)
**Duration:** ~90 minutes
**Total Genuine Issues Found:** 4 (all fixed)

---

## Summary by Dimension

| Dimension | Issues Found | Fixed | Notes |
|-----------|--------------|-------|-------|
| D9: Intra-File Consistency | 0 | — | All "duplicate header" findings were false positives (code block context) |
| D10: File Size Assessment | 4 | ✅ | 4 files exceeded 1250-line threshold; all reduced |
| D11: Structural Patterns | 0 | — | Naming conventions clean; required sections present; "skipped headers" were false positives |
| D12: Cross-File Dependencies | 0 | — | Missing debugging files are runtime outputs; stale s5 refs are in teaching code blocks |
| D18: Character and Format Compliance | 0 | — | No Unicode checkboxes, curly quotes, or dash list markers found |
| **TOTAL** | **4** | **4** | |

---

## Investigation Notes

### D18 Analysis

Clean pass. Python-based character scan of all .md files (excluding audit/) found:
- Zero Unicode checkboxes (U+25A1, U+2610, U+2611, U+2612)
- Zero Unicode curly quotes (U+201C, U+201D, U+2018, U+2019)
- Zero Unicode dash list markers (en-dash or em-dash at line start)

### D11 Analysis

**D11.1 File naming conventions:** Clean. All stages/, reference/, templates/, parallel_work/ files use underscores, not hyphens in filenames.

**D11.2 Required sections:** Clean. All stage guides have both `## Prerequisites` and `## Exit Criteria` sections.

**D11.3 Skipped header levels:** 10 findings across 3 files — all false positives.

- `s5_v2_validation_loop.md` (5 findings): `#### Step 3–7:` headers flagged as h2→h4. Investigation shows they are correctly nested under `### Step-by-Step Process` (h3). The checker was confused by `## Task 1:` and `## Task 6:` headers INSIDE markdown code blocks between the h3 and h4.
- `s6_execution.md` (3 findings): `#### 3.3–3.5:` headers flagged. They are correctly nested under `### General Process (Repeat for EACH phase):` (h3). The `## [module]/util/RecordManager.py` on line 487 is inside a code block.
- `s8_p2_epic_testing_update.md` (2 findings): `#### 3b:` and `#### 3g:` headers flagged. Correctly nested under `### STEP 3: Update Test Plan` (h3). Checker confused by `## Epic Smoke Test Plan:` header inside code blocks.

**Root cause:** The automated header hierarchy checker doesn't detect markdown code block context. `##`-level headers inside code blocks reset `prev_level` to 2, causing false h2→h4 skip reports.

### D10: Issues Found and Fixed (4 files)

All 4 files exceeded the 1250-line CRITICAL threshold:

| File | Before | After | Lines Removed | Strategy |
|------|--------|-------|---------------|----------|
| `stages/s1/s1_epic_planning.md` | 1294 | 1238 | 56 | Removed "Why this checkpoint exists" blocks from 5 checkpoints; removed "Guide Comprehension Verification" section |
| `stages/s5/s5_v2_validation_loop.md` | 1321 | 1238 | 83 | Removed "Lessons Learned & Best Practices" section (duplicated Anti-Patterns); condensed Validation Loop Log sub-section; removed Summary section |
| `parallel_work/s2_parallel_protocol.md` | 1345 | 1245 | 100 | Removed "Integration Guide" section (guide-authoring meta-docs, not agent workflow); removed "Next Steps" aspirational content from Summary |
| `reference/validation_loop_master_protocol.md` | 1344 | 1249 | 95 | Replaced S5 Extension example with 5-line pointer (full detail in s5_v2_validation_loop.md); removed Scenario-Specific Dimension Examples section; removed Summary section |

**Content preservation:** All edits removed supplementary/redundant content. No workflow steps, checkpoints, exit criteria, prerequisites, or critical rules were removed. The S5 extension example in validation_loop_master_protocol.md was replaced with a pointer to the actual full guide. The "Lessons Learned" section in s5_v2 was entirely covered by the "Anti-Patterns to Avoid" section in the same file.

### D12 Analysis

**Apparent missing debugging files:** `investigation_rounds.md`, `guide_update_recommendations.md`, `process_failure_analysis.md` referenced in `debugging/investigation.md`, `debugging/loop_back.md`, `debugging/root_cause_analysis.md`. Investigation shows these are **runtime output files** created during debugging sessions in child project `debugging/` folders (e.g., `feature_XX/debugging/guide_update_recommendations.md`). They are not master guide files. FALSE POSITIVE.

**Apparent stale s5 file references in `naming_conventions.md`:**
- Lines 258, 420 (`s5_p1_i3_integration.md`): Inside markdown code blocks labeled "Historical S5 v1 Example" — intentional teaching content
- Line 434 (`phase_5.1_implementation_planning.md`): Inside a code block under "❌ Mistake 1: Using Old Notation" showing what wrong notation looks like
All are intentional pedagogical content. FALSE POSITIVE.

**D12 CLAUDE.md check:** shamt-ai-dev CLAUDE.md is a master-repo config file with no stage guide path references. N/A.

**D12 prompts_reference_v2.md check:** All 11 real prompt file references resolve. One placeholder `prompts/s{N}_prompts.md` is instructional text, not a real link. Clean.

**D12 Stage chain:** All 10 stage directories (s1–s10) exist with files. Clean.

### D9 Analysis

**D9.1 Mixed notation:** No files found using both old `S#a` notation and new `S#.P#` notation within the same file. Clean.

**D9.2 Duplicate headers:** 15 files flagged. Investigation of all cases:
- Most (13 files): Generic headers like "Purpose", "Steps", "Agent Status" appearing multiple times as sub-section headers within multi-part iteration guides. These are structural/expected, not content duplicates.
- `s10_p1_guide_update_workflow.md` (`Dimension 11: Spec Alignment & Cross-Validation (CRITICAL)` ×2): Both occurrences are inside markdown code blocks as part of a BEFORE/AFTER guide update example. FALSE POSITIVE.
- `s7_p3_final_review.md` (`Category 1: Correctness and Logic` ×2): First is an actual checklist section; second is inside a `Document findings:` code block showing how to record results. FALSE POSITIVE.

No D9.2 genuine issues found.

---

## False Positive Summary

| Finding | Reason Dismissed |
|---------|-----------------|
| D11.3: 10 skipped header levels in 3 files | Checker doesn't handle `##` headers inside code blocks; all h4s are properly under h3 parents |
| D12: 3 missing debugging files | Runtime output files created in child projects, not master guide files |
| D12: stale s5 refs in naming_conventions.md (×3) | Inside markdown code blocks as teaching examples (historical and "wrong way" examples) |
| D12: `prompts/s{N}_prompts.md` | Placeholder variable in instructional text, not a real file reference |
| D9.2: Duplicate headers in 13 files | Generic structural sub-section headers (Purpose, Steps, Agent Status) expected in multi-iteration guides |
| D9.2: `s10_p1` Dimension 11 header ×2 | Inside BEFORE/AFTER code block teaching example |
| D9.2: `s7_p3` Category 1 header ×2 | Second occurrence inside "Document findings:" code block template |

---

## Sub-Round 1.3 Loop Decision

**Result:** 4 genuine issues found and fixed (all D10 file size violations)

**Proceed to:** Sub-Round 1.4 (Advanced: D7, D15, D16, D17)

**Notable:** D18 was completely clean — no Unicode character violations. D9, D11, D12 were all clean after investigation.
