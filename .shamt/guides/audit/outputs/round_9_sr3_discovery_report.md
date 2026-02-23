# Round 9 SR3 Discovery Report — D9, D10, D11, D12, D18

**Date:** 2026-02-21
**Sub-Round:** SR9.3
**Dimensions:** D9, D10, D11, D12, D18
**Status:** COMPLETE
**Genuine Findings:** 9
**Fixed:** 9
**Pending User Decision:** 0

---

## Summary

| Dimension | Findings | Fixed | Pending |
|-----------|----------|-------|---------|
| D9 | 7 | 7 | 0 |
| D10 | 0 | 0 | 0 |
| D11 | 0 | 0 | 0 |
| D12 | 1 | 1 | 0 |
| D18 | 1 | 1 | 0 |
| **Total** | **9** | **9** | **0** |

---

## Findings / Zero-Finding Confirmations

---

### D18: Character and Format Compliance

**Files Searched:** All guides in stages/, reference/, audit/dimensions/, parallel_work/, debugging/, prompts/, templates/
**Search Pattern:** Unicode checkboxes (□ ☐ ☑ ☒), smart quotes (" " ' '), smart apostrophes — em-dashes (—) are allowed in prose

---

#### Finding D18-1: `audit/README.md` — malformed closing fence using language tag ` ```diff`

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/audit/README.md`
**Line:** 42 (before fix)
**Issue:** A bash code block (opened with ` ```bash`) was "closed" with ` ```diff` instead of plain ` ``` `. In standard markdown a fence with a language tag opens a new block — so ` ```diff` at a closing position is malformed.
**Fix Applied:** Changed ` ```diff` → ` ``` ` (plain closing fence)

---

#### D18 Zero-Finding Confirmations

- All 269 em-dash (—) occurrences found in a corpus scan are in prose context — allowed per D18
- The `audit/dimensions/d18_character_format_compliance.md` file itself contains Unicode checkbox characters (□ ☐ ☑ ☒) and em-dashes as intentional examples in tables and code blocks — NOT violations
- Zero Unicode checkbox characters (□ ☐ ☑ ☒) found in published guides (stages/, reference/, prompts/)
- Zero smart quote/apostrophe characters found in published guides
- Zero other banned Unicode characters (e.g., zero-width spaces) found

---

### D12: Cross-File Dependencies

**Files Searched:** audit/dimensions/d12_cross_file_dependencies.md, stage handoff chains, template references
**Checks Performed:** Stale planning notes, stage handoff file existence, template reference validity

---

#### Finding D12-1: `audit/dimensions/d12_cross_file_dependencies.md` — stale "Next Phase" planning note

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/audit/dimensions/d12_cross_file_dependencies.md`
**Line:** 1205 (before fix)
**Issue:** The file ended with a leftover planning artifact:
```
**Next Phase:** Phase 3 - Medium-priority dimensions (D4, D7, D9, D15)
```
This note was from the original drafting/development phase and no longer reflects any current state. It appeared after the horizontal rule that should logically end the document.
**Fix Applied:** Removed the stale "Next Phase" line — the document now ends cleanly at the preceding horizontal rule.

---

#### D12 Zero-Finding Confirmations

- All stage handoff chains verified: S1 → S2 → S3 → S4 → S5 → S6 → S7 → S8 → S9 → S10 guide paths exist as actual files
- Template references in stage guides point to files that exist in `templates/`
- No circular dependency patterns found in guide cross-references
- Dimension file cross-references in d12_cross_file_dependencies.md itself are accurate (all referenced dimension files exist)

---

### D9: Intra-File Consistency

**Files Searched:** All guides in stages/, reference/, parallel_work/
**Checks Performed:** ToC entries vs actual headings (anchor accuracy, ghost entries, missing entries), code fence pairing (malformed opening/closing fences)

---

#### Finding D9-1: `stages/s1/s1_epic_planning.md` — ghost ToC entry "Guide Comprehension Verification"

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s1/s1_epic_planning.md`
**Line:** 36 (before fix)
**Issue:** ToC item 16 read `[Guide Comprehension Verification](#guide-comprehension-verification)` but no heading with that text exists anywhere in the file. This was a ghost entry pointing to a non-existent anchor.
**Fix Applied:** Removed the ghost ToC entry. Subsequent entries renumbered: 17→16, 18→17.

---

#### Finding D9-2: `stages/s2/s2_feature_deep_dive.md` — wrong ToC anchor for "Next Stage"

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s2/s2_feature_deep_dive.md`
**Line:** 27 (before fix)
**Issue:** ToC item 12 read `[Next Stage After S2](#next-stage-after-s2)`. The actual heading in the file is `## Next Stage` (not "Next Stage After S2"), which generates anchor `#next-stage`. The ToC label and anchor were both wrong.
**Fix Applied:** Changed to `[Next Stage](#next-stage)` to match the actual heading.

---

#### Finding D9-3: `stages/s2/s2_feature_deep_dive.md` — ghost ToC entry "Original Guide Location"

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s2/s2_feature_deep_dive.md`
**Line:** 30 (before fix)
**Issue:** ToC item 15 read `[Original Guide Location](#original-guide-location)` but no heading with that text exists in the file. Ghost entry.
**Fix Applied:** Removed the ghost ToC entry. Subsequent entry (Summary) renumbered 16→15.

---

#### Finding D9-4: `stages/s5/s5_v2_validation_loop.md` — emoji ToC entry with wrong anchor for "Overview"

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s5/s5_v2_validation_loop.md`
**Line:** 16 (before fix)
**Issue:** ToC item 1 read `[🎯 OVERVIEW](#-overview)`. The actual heading is `## Overview` (no emoji), which generates anchor `#overview`. The emoji-prefixed label and the resultant `#-overview` anchor were both wrong.
**Fix Applied:** Changed to `[Overview](#overview)` to match the actual heading.

---

#### Finding D9-5: `stages/s5/s5_v2_validation_loop.md` — emoji ToC entry with wrong anchor for "Exit Criteria"

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s5/s5_v2_validation_loop.md`
**Line:** 55 (before fix)
**Issue:** ToC item read `[✅ EXIT CRITERIA & QUALITY METRICS](#-exit-criteria-quality-metrics)`. The actual heading is `## Exit Criteria` (no emoji, shorter text), which generates anchor `#exit-criteria`. Both the label and anchor were wrong.
**Fix Applied:** Changed to `[Exit Criteria & Quality Metrics](#exit-criteria)` — descriptive label preserved, anchor corrected to match the actual heading.

---

#### Finding D9-6: `stages/s5/s5_v2_validation_loop.md` — malformed closing fence at line 363 (` ```text` instead of ` ``` `)

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s5/s5_v2_validation_loop.md`
**Line:** 363 (before fix)
**Issue:** A `markdown` code block (opened at line 351 with ` ```markdown`) was "closed" with ` ```text` — a fence with a language tag opens a new block, not closes the current one. This was a malformed closing fence that would cause parser confusion.
**Fix Applied:** Changed ` ```text` → ` ``` ` (plain closing fence).

---

#### Finding D9-7: `stages/s5/s5_v2_validation_loop.md` — malformed closing fence at line 455 (` ```text` instead of ` ``` `)

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/stages/s5/s5_v2_validation_loop.md`
**Line:** 455 (before fix)
**Issue:** A `text` code block (opened at line 432 with ` ```text`) was also "closed" with ` ```text` — same malformed closing fence pattern as D9-6. In standard markdown, any closing fence must be a plain ` ``` ` without a language tag.
**Fix Applied:** Changed ` ```text` → ` ``` ` (plain closing fence).

---

#### Finding D9-8: `parallel_work/s2_primary_agent_group_wave_guide.md` — spurious ` ```text` fence wrapping prose content

**File:** `/home/kai/code/shamt-ai-dev/.shamt/guides/parallel_work/s2_primary_agent_group_wave_guide.md`
**Line:** 895 (before fix)
**Issue:** A lone ` ```text` fence appeared after the prose line "**Proceeding to S3 now...**" (line 894) and before a **Then:** bullet list (lines 896-901). The fence was not closed, and it was wrapping prose + bullet content inside a code block, which would render the prose as preformatted text. No corresponding closing fence preceded the next ` ```text` block at line 910. The spurious fence served no purpose; the prose and bullets should render as normal markdown.
**Fix Applied:** Removed the lone ` ```text` line entirely (line 895), restoring the prose and bullet list to normal markdown rendering.

---

#### D9 Zero-Finding Confirmations

- `reference/qc_rounds_pattern.md` ToC anchors for Round 1/2/3 contain triple dashes (e.g., `#round-1-scope-specific---see-implementation-guides`) — these are CORRECT. The ` - ` (space-dash-space) in the heading text generates three hyphens in the GitHub anchor (space→hyphen, literal dash, space→hyphen). Verified with Python GitHub anchor simulation.
- `reference/mandatory_gates.md` ToC anchor for S2 contains triple dashes (`#s2-feature-deep-dive-3-formal-gates-per-feature---new-checklist-approval-added`) — CORRECT for the same reason (the heading text contains ` - NEW:` which produces `---new`). Verified.
- All other ToC entries checked in stages/s3, stages/s4, stages/s6, stages/s7, stages/s8, stages/s9, stages/s10 guides match their actual headings.
- All code fence pairs in stages/s3 through stages/s10 guides are properly matched (no unclosed or malformed fences beyond the s5 and parallel_work findings above).
- 4-backtick outer fences (used to wrap 3-backtick content) are intentional and correct — not a D9 violation.

---

### D10: File Size Assessment

**Files Searched:** All guides in stages/, reference/, audit/dimensions/, parallel_work/, debugging/, prompts/, templates/
**Hard Limit:** 1250 lines for workflow guides; >1350 must reduce; reference files may qualify for exception

---

#### D10 Zero-Finding Confirmations

- Files over 1250 lines found: `audit/dimensions/d15_duplication_detection.md` (1363 lines) and `audit/dimensions/d9_intra_file_consistency.md` (1340 lines)
  - `d15_duplication_detection.md` at 1363 lines exceeds the 1350 "must reduce" threshold. However, this is a reference file (non-sequential reading, single focused purpose, no duplication of content). The D10 reference-file exception applies. No action required.
  - `d9_intra_file_consistency.md` at 1340 lines is between 1250 and 1350 (review zone). Same reference-file exception applies. No action required.
- All stage guides (s1 through s10 primary guides) are under 1250 lines: s1=1237, s5=1247, others well under.
- CLAUDE.md character count not checked here (D10 exemption applies to this file as a project-level config, not a workflow guide).

---

### D11: Structural Patterns

**Files Searched:** All stage guides in stages/, all reference guides in reference/
**Checks Performed:** Required sections (Prerequisites, Overview, Exit Criteria or equivalent), header hierarchy, section ordering consistency

---

#### D11 Zero-Finding Confirmations

- All S1-S10 primary stage guides have a Prerequisites section (or equivalent — e.g., "Prerequisites for S2" in s1) — CORRECT
- All S1-S10 primary stage guides have an Overview section (or equivalent introductory section) — CORRECT
- All S1-S10 primary stage guides have an Exit Criteria / Next Stage / Completion Criteria section — CORRECT
  - `stages/s9/s9_p4_epic_final_review.md` uses "Completion Criteria" instead of "Exit Criteria" — acceptable equivalent, not a violation
- No heading hierarchy violations found (H2 headings not nested inside H3, etc.) in primary stage guides
- Reference files in `reference/` do not require the same structural pattern as stage guides — correctly exempt from stage-pattern checks

---

## Files Modified This Sub-Round

| File | Dimension | Changes Made |
|------|-----------|--------------|
| `audit/README.md` | D18 | Changed ` ```diff` closing fence → ` ``` ` (plain closing fence) |
| `audit/dimensions/d12_cross_file_dependencies.md` | D12 | Removed stale "Next Phase: Phase 3..." planning artifact at end of file |
| `stages/s1/s1_epic_planning.md` | D9 | Removed ghost ToC entry "Guide Comprehension Verification" (no matching heading); renumbered subsequent entries |
| `stages/s2/s2_feature_deep_dive.md` | D9 | Fixed ToC item 12: "Next Stage After S2" → "Next Stage" with correct anchor; removed ghost entry "Original Guide Location" |
| `stages/s5/s5_v2_validation_loop.md` | D9 | Fixed 2 emoji ToC entries with wrong anchors; fixed 2 malformed ` ```text` closing fences → ` ``` ` |
| `parallel_work/s2_primary_agent_group_wave_guide.md` | D9 | Removed spurious ` ```text` fence that was wrapping prose + bullet list content |

---

## False Positives Investigated and Dismissed

| Candidate | Dimension | Why Dismissed |
|-----------|-----------|---------------|
| `reference/qc_rounds_pattern.md` ToC anchors with triple dashes | D9 | Triple dashes are correct — heading text contains ` - ` (space-dash-space) which GitHub converts to three hyphens. Python simulation confirmed. |
| `reference/mandatory_gates.md` S2 ToC anchor with triple dashes | D9 | Same reason — ` - NEW:` in heading text correctly generates `---new` in anchor. Verified. |
| 269 em-dash characters across guides | D18 | Em-dashes are allowed in prose per D18. All occurrences are in prose/explanatory context, not as structural markers. |
| Unicode characters in `d18_character_format_compliance.md` | D18 | Intentional examples in that dimension's own table/code blocks. Not violations. |
| `stages/s9/s9_p4_epic_final_review.md` missing "Exit Criteria" | D11 | File uses "Completion Criteria" — accepted equivalent per D11 definition. Not a violation. |
| d15 at 1363 lines and d9 at 1340 lines | D10 | Both qualify for reference-file exception (non-sequential reading, single purpose, no content duplication). |

---

## Not Investigated (Out of Scope for SR9.3)

- D1, D2, D3, D8 → Covered by SR9.1
- D4, D5, D6, D13, D14 → Covered by SR9.2
- D7, D15, D16, D17 → Covered by SR9.4

---

## Context: Round 8 vs Round 9

Round 8 SR8.3 found 0 D9 findings (clean). Round 9 SR9.3 found 7 D9 issues — most in ToC entries. The ghost entries in s1 and s2 are likely pre-existing artifacts from when guide sections were renamed or removed without updating the ToC. The malformed fences in s5_v2_validation_loop.md and the spurious fence in s2_primary_agent_group_wave_guide.md are editing artifacts from content updates. Round 8 may have introduced or missed these during its changes.

---

**Report Generated:** 2026-02-21
