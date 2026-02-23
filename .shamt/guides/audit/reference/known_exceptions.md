# Known Exceptions - Prerequisites/Exit Criteria

**Purpose:** Documents files that intentionally lack formal "## Prerequisites" or "## Exit Criteria" sections

**Last Updated:** 2026-02-22

**Why This Document Exists:**
Audit Dimension D13 (Documentation Quality) checks for "## Prerequisites" and "## Exit Criteria" sections in workflow guides. However, certain file types intentionally use alternative patterns. This document prevents these files from being flagged as violations in future audits.

---

## Exception Categories

### Category A: S5 Iteration Files (14 files)

**Pattern:** Lightweight iteration guides with inline prerequisites, exit criteria inherited from parent round

**⚠️ NOTE: All 14 files in this category have been DELETED from the filesystem** as part of the S5 v1 → S5 v2 migration. S5 v2 consolidates all iteration content into a single `s5_v2_validation_loop.md` file using an 11-dimension Validation Loop approach. These entries are retained for historical reference only — they cannot produce D13 false positives since the files no longer exist.

**Design Rationale (historical):**
- Iteration files were sequential steps within S5 v1 rounds (Round 1, Round 2, Round 3)
- Prerequisites were simple: "Previous iteration complete" (stated inline)
- Exit criteria defined at round level (s5_v2_validation_loop.md consolidates all rounds)
- Formal sections would have been redundant
- Files followed "router + detailed iteration" pattern for focused reference

**Missing Sections:** Prerequisites (inline instead), Exit Criteria (inherited from parent)

**Files (DELETED — S5 v1 only, no longer in filesystem):**

#### S5.P1 (Round 1) Iteration Files (7 files)

1. **stages/s5/s5_p1_i3_integration.md**
   - Type: Router for Iterations 5-7
   - Prerequisites: Line 8 - "**Prerequisites:** Iterations 1-4 + Gate 4a complete"
   - Exit Criteria: Inherited from s5_v2_validation_loop.md
   - Design: Navigation hub to 6 sub-iteration files

2. **stages/s5/s5_p1_i3_iter5_dataflow.md**
   - Type: Iteration 5 - End-to-End Data Flow
   - Prerequisites: Line 6 - "**Prerequisites:** Previous iterations complete"
   - Exit Criteria: Inherited from s5_v2_validation_loop.md
   - Design: Focused single-iteration guide (109 lines)

3. **stages/s5/s5_p1_i3_iter5a_downstream.md**
   - Type: Iteration 5a - Downstream Data Consumption Tracing
   - Prerequisites: Line 6 - "**Prerequisites:** Previous iterations complete"
   - Exit Criteria: Inherited from s5_v2_validation_loop.md
   - Design: Focused single-iteration guide (352 lines)

4. **stages/s5/s5_p1_i3_iter6_errorhandling.md**
   - Type: Iteration 6 - Error Handling Scenarios
   - Prerequisites: Line 6 - "**Prerequisites:** Previous iterations complete"
   - Exit Criteria: Inherited from s5_v2_validation_loop.md
   - Design: Focused single-iteration guide (132 lines)

5. **stages/s5/s5_p1_i3_iter6a_dependencies.md**
   - Type: Iteration 6a - External Dependency Final Verification
   - Prerequisites: Line 6 - "**Prerequisites:** Previous iterations complete"
   - Exit Criteria: Inherited from s5_v2_validation_loop.md
   - Design: Focused single-iteration guide (157 lines)

6. **stages/s5/s5_p1_i3_iter7_integration.md**
   - Type: Iteration 7 - Integration Gap Check
   - Prerequisites: Inline statement
   - Exit Criteria: Inherited from s5_v2_validation_loop.md
   - Design: Focused single-iteration guide

7. **stages/s5/s5_p1_i3_iter7a_compatibility.md**
   - Type: Iteration 7a - Backward Compatibility Check
   - Prerequisites: Inline statement
   - Exit Criteria: Inherited from s5_v2_validation_loop.md
   - Design: Focused single-iteration guide

#### S5.P3 (Round 3) Iteration Files (7 files)

8. **stages/s5/s5_p3_i1_preparation.md**
   - Type: Round 3 Part 1 - Preparation
   - Prerequisites: Inline statement
   - Exit Criteria: Inherited from s5_v2_validation_loop.md (Round 3 section)
   - Design: Preparation phase guide for Round 3

9. **stages/s5/s5_p3_i1_iter17_phasing.md**
   - Type: Iteration 17 - Phasing
   - Prerequisites: Inline statement
   - Exit Criteria: Inherited from s5_v2_validation_loop.md (Round 3 section)
   - Design: Focused single-iteration guide

10. **stages/s5/s5_p3_i1_iter18_rollback.md**
    - Type: Iteration 18 - Rollback
    - Prerequisites: Inline statement
    - Exit Criteria: Inherited from s5_v2_validation_loop.md (Round 3 section)
    - Design: Focused single-iteration guide

11. **stages/s5/s5_p3_i1_iter19_traceability.md**
    - Type: Iteration 19 - Traceability
    - Prerequisites: Inline statement
    - Exit Criteria: Inherited from s5_v2_validation_loop.md (Round 3 section)
    - Design: Focused single-iteration guide

12. **stages/s5/s5_p3_i1_iter20_performance.md** (DEPRECATED - S5 v1)
    - Type: S5 v1 Iteration 20 - Performance (now Dimension 9)
    - Prerequisites: Inline statement
    - Exit Criteria: Inherited from s5_v2_validation_loop.md
    - Design: Focused single-iteration guide (S5 v1 only)

13. **stages/s5/s5_p3_i1_iter21_mockaudit.md** (DEPRECATED - S5 v1)
    - Type: S5 v1 Iteration 21 - Mock Audit (now part of Dimension 11)
    - Prerequisites: Inline statement
    - Exit Criteria: Inherited from s5_v2_validation_loop.md
    - Design: Focused single-iteration guide (S5 v1 only)

14. **stages/s5/s5_p3_i1_iter22_consumers.md** (DEPRECATED - S5 v1)
    - Type: S5 v1 Iteration 22 - Consumers (now Dimension 10)
    - Prerequisites: Inline statement
    - Exit Criteria: Inherited from s5_v2_validation_loop.md
    - Design: Focused single-iteration guide (S5 v1 only)

**Audit Action:** SKIP these files when checking D13 (Documentation Quality) - Prerequisites/Exit Criteria

---

### Category B: S5 Design and Migration Documents (2 files)

**Pattern:** Design plans and migration guides (not workflow execution guides)

**Design Rationale:**
- These are reference documents for understanding S5 v1→v2 transition
- Not part of active workflow execution path
- Provide historical context and design decisions
- Prerequisites/Exit Criteria not applicable to reference documentation

**Missing Sections:** Prerequisites, Exit Criteria

**Files:**

   - Type: Migration guide
   - Purpose: Help agents understand transition from S5 v1 (22 iterations) to S5 v2 (Validation Loop)
   - Design: Comparison tables, side-by-side workflows, FAQ format

   - Type: Design plan document
   - Purpose: Document architectural decisions for S5 v2 design
   - Design: Architecture, dimension definitions, validation loop design

**Audit Action:** SKIP these files when checking D13 (Documentation Quality) - Prerequisites/Exit Criteria

---

### Category C: Optional/Auxiliary Files (3 files)

**Pattern:** Support guides used conditionally or as reference material, not standard sequential workflows

**Design Rationale:**
- Files serve specific auxiliary purposes
- Prerequisites/exit criteria handled inline or not applicable
- Not part of standard epic workflow sequence

**Files:**

15. **stages/s3/s3_parallel_work_sync.md**
    - **Type:** Optional synchronization checklist
    - **When Used:** Only when S2 executed in parallel mode (Primary + Secondary agents)
    - **Skipped:** When S2 done sequentially (single agent)
    - **Prerequisites:** None (conditional usage based on S2 execution mode)
    - **Exit Criteria:** Inline completion verification in Step 0.2 - STATUS file checks
    - **Missing Sections:** Prerequisites (not applicable), Exit Criteria (inline instead)
    - **Design Rationale:** Conditional auxiliary workflow, not standard stage progression
    - **Audit Action:** SKIP - not a standard workflow guide

16. **stages/s4/s4_feature_testing_card.md**
    - **Type:** Quick reference card / cheat sheet
    - **Purpose:** At-a-glance iteration checklist for S4
    - **Full Guides:** References s4_feature_testing_strategy.md, s4_test_strategy_development.md
    - **Prerequisites:** Line 13 inline - "**Prerequisites:** S3 complete (Gate 4.5 passed), spec.md finalized (Gate 3 passed)"
    - **Exit Criteria:** Not applicable (reference card, not workflow)
    - **Missing Sections:** Prerequisites (inline instead), Exit Criteria (not applicable)
    - **Design Rationale:** Reference material for quick lookup, not step-by-step workflow execution
    - **Audit Action:** SKIP - reference card, not workflow guide

17. **stages/s4/s4_test_strategy_development.md**
    - **Type:** Detailed iteration guide (Iterations 1-3)
    - **Purpose:** Deep-dive instructions for S4 Iterations 1-3
    - **Prerequisites:** Handled in MANDATORY READING PROTOCOL (line 8) - "Verify S4 router guide already read, Verify prerequisites complete (S3 done, Gate 4.5 passed)"
    - **Exit Criteria:** HAS formal "## Exit Criteria" section at line 768
    - **Missing Sections:** Prerequisites (handled in MANDATORY READING PROTOCOL instead of separate h2 section)
    - **Design Rationale:** Prerequisites verification integrated into reading protocol for consistency
    - **Audit Action:** SKIP for Prerequisites check (has Exit Criteria, Prerequisites in protocol)
    - **Note:** This is an audit FALSE POSITIVE - file has Exit Criteria but was flagged by Round 2 audit

---

### Category D: Emoji Heading Anchor Patterns

**Purpose:** Documents the correct GFM anchor format for headings that start with emoji.

**Why anchors look "wrong" but are correct:**
GFM (GitHub Flavored Markdown) strips emoji characters during anchor generation. A heading like
`## 🔢 Understanding Gate Numbering` produces anchor `#-understanding-gate-numbering`, NOT
`#🔢-understanding-gate-numbering`. The leading hyphen comes from the space character that
follows the emoji (space → hyphen after stripping the emoji).

**Pattern:** `#-kebab-case-title` is correct for all emoji-prefixed headings.

**🚨 Do NOT "fix" these anchors** — they are already correct. Changing them from `#-name` to
`#emoji-name` is a regression (introduced in Round 12 SR12.3 and reverted in Round 13).

**Verified correct anchors:**

| File | Heading | Correct Anchor | Wrong Form (do not use) |
|------|---------|----------------|------------------------|
| `reference/mandatory_gates.md` | `## 🔢 Understanding Gate Numbering` | `#-understanding-gate-numbering` | `#🔢-understanding-gate-numbering` |
| `stages/s2/s2_feature_deep_dive.md` | `## 🔀 Parallel Work Check (FIRST PRIORITY)` | `#-parallel-work-check-first-priority` | `#🔀-parallel-work-check-first-priority` |
| `stages/s2/s2_feature_deep_dive.md` | `## 📖 Terminology Note` | `#-terminology-note` | `#📖-terminology-note` |
| `stages/s10/s10_epic_cleanup.md` | `## 🚨 MANDATORY READING PROTOCOL` | `#-mandatory-reading-protocol` | `#🚨-mandatory-reading-protocol` |
| `stages/s10/s10_epic_cleanup.md` | `## 🛑 Critical Rules` | `#-critical-rules` | `#🛑-critical-rules` |

**Algorithm (for deriving anchors for new emoji headings):**
1. Take heading text, lowercase it
2. Strip all non-alphanumeric, non-space, non-hyphen characters (including the emoji)
3. Replace spaces with hyphens — the space after the stripped emoji becomes a leading `-`
4. Do not trim leading hyphens — `#-name` is valid

**Related:** See D9 Context-Sensitive Rule 5 for full specification.

---

## How to Use This Document

### For Future Audits

**When running D13 (Documentation Quality) Prerequisites/Exit Criteria checks:**

1. **Generate violation list** using automated pattern search
2. **Cross-reference with this document** before flagging as issues
3. **Filter out known exceptions** (19 files total)
4. **Investigate remaining violations** as potential real issues

**Example Audit Workflow:**
```bash
# Step 1: Find files missing Prerequisites
for file in stages/*/*.md; do
  grep -q "^## Prerequisites" "$file" || echo "$file"
done > missing_prereqs.txt

# Step 2: Filter out known exceptions
# Remove lines matching: s5/s5_p1_i3_*, s5/s5_p3_i1_*, s3/s3_parallel_work_sync.md, s4/s4_feature_testing_card.md, s4/s4_test_strategy_development.md
grep -v -E "(s5_p1_i3_|s5_p3_i1_|s3_parallel_work_sync|s4_feature_testing_card|s4_test_strategy_development)" missing_prereqs.txt > real_violations.txt

# Step 3: Investigate remaining files
wc -l real_violations.txt  # Should be low count
```

### For Guide Authors

**When creating new iteration guides in S5:**
- Use inline prerequisites: "**Prerequisites:** Previous iterations complete"
- Rely on parent round guide for exit criteria
- Follow established pattern (see Category A files above)
- File size: Keep focused and lightweight (100-400 lines)

**When creating auxiliary/optional guides:**
- Consider if Prerequisites/Exit Criteria apply
- If guide is conditional or reference material, inline may be appropriate
- Add entry to this document if creating new exception pattern

**When creating standard workflow guides:**
- **DO include formal "## Prerequisites" section** (h2 level)
- **DO include formal "## Exit Criteria" section** (h2 level)
- Exceptions are rare - default to formal sections

---

## Audit History

**Round 2 (2026-02-05):** Identified 34 files missing Prerequisites/Exit Criteria
**Round 3 (2026-02-05):** Investigated all 34 files, categorized as:
- 4 real issues (fixed)
- 30 intentional exceptions (documented here)

**Known Audit Tools:**
- D13 dimension automated checks
- audit/scripts/pre_audit_checks.sh

**Future Updates:**
- Add new exceptions as patterns emerge
- Update category descriptions if design patterns change
- Maintain audit tool compatibility

---

## Summary Statistics

**Total Known Exceptions:** 19 files

**By Category:**
- Category A (S5 Iteration Files): 14 files
- Category B (S5 Design/Migration Documents): 2 files
- Category C (Optional/Auxiliary): 3 files

**Missing Sections:**
- Missing Prerequisites only: 5 files (s5 iterations 5, 5a, 6, 6a, 7 with inline statements)
- Missing Exit Criteria only: 3 files (s3_parallel_work_sync, s4_feature_testing_card, s4_test_strategy_development)
- Missing BOTH: 11 files (remaining s5 iteration files + 2 design docs)

**Design Patterns:**
- Router + Iteration: 14 files (S5 structure)
- Design/Migration Reference: 2 files (S5 v1→v2 documentation)
- Optional/Conditional: 1 file (s3_parallel_work_sync)
- Reference Material: 2 files (s4_feature_testing_card, s4_test_strategy_development)

---

**Last Verified:** 2026-02-22 (Round 11 audit — confirmed Category A files are all DELETED from filesystem as part of S5 v1 → v2 migration)
**Next Review:** When new stage/iteration guides added, or if D13 check patterns change

