# S9.P4: Epic Final Review

**Part of:** Epic-Driven Development Workflow v2
**Prerequisites:** S9.P3 complete (User Testing passed with ZERO bugs)
**Next Stage:** `stages/s10/s10_epic_cleanup.md`
**File:** `s9_p4_epic_final_review.md`

---


## Table of Contents

1. [S9.P4: Epic Final Review](#s9p4-epic-final-review)
2. [🚨 MANDATORY READING PROTOCOL](#-mandatory-reading-protocol)
3. [🚫 FORBIDDEN SHORTCUTS](#-forbidden-shortcuts)
4. [Overview](#overview)
5. [Critical Rules for S9.P4](#critical-rules-for-s9p4)
6. [Prerequisites](#prerequisites)
7. [STEP 6: Epic PR Review (Multi-Round with Fresh Eyes)](#step-6-epic-pr-review-multi-round-with-fresh-eyes)
8. [STEP 7: Handle Issues (If Any Discovered)](#step-7-handle-issues-if-any-discovered)
9. [STEP 8: Final Verification & README Update](#step-8-final-verification--readme-update)
10. [Re-Reading Checkpoints](#re-reading-checkpoints)
11. [Exit Criteria](#exit-criteria)
12. [Reference Files](#reference-files)
13. [Prerequisites for Next Stage](#prerequisites-for-next-stage)
14. [Summary](#summary)

---
## 🚨 MANDATORY READING PROTOCOL

**CRITICAL:** You MUST read this ENTIRE guide before starting S9.P4 work.

**Why this matters:**
- S9.P4 is the FINAL VALIDATION before epic completion
- Missing steps here means shipping incomplete or incorrect epic
- Thoroughness prevents post-completion issues

**Reading Checkpoint:**
Before proceeding, you must have:
- [ ] Read this ENTIRE guide (use Read tool, not memory)
- [ ] Verified S9.P3 complete (User Testing passed with ZERO bugs)
- [ ] Verified no pending issues or bug fixes
- [ ] Located epic_lessons_learned.md file

**If resuming after session compaction:**
1. Check EPIC_README.md "Agent Status" section for current step
2. Re-read this guide from the beginning
3. Continue from documented checkpoint

---

## 🚫 FORBIDDEN SHORTCUTS

You CANNOT:
- Skip Step 6 (Epic Final Review) or any of its 5 categories because "S9.P2 already covered them" — fresh sub-agent epic code review (12 categories + 13 dimensions, epic-scope) are MANDATORY; S9.P2 results provide supplementary context only, not a replacement for the epic-scope review
- Fix issues found in Step 6 inline instead of creating bug fix folders — ALL high/medium priority issues require a bug fix folder and the **S5→S6→S7 workflow** (implementation + testing; do NOT repeat S2 spec work unless bug reveals a spec issue)
- Proceed to Step 8 (Final Verification) after creating bug fixes without restarting S9 from S9.P1 — the S9 restart is MANDATORY after any bug fixes created in Step 7
- Mark S9.P4 complete without updating both EPIC_README.md Epic Progress Tracker and epic_lessons_learned.md with S9.P4 results and insights

If you are about to do any of the above: STOP and re-read the relevant section.

---

## Overview

### What is this sub-stage?

**S9.P4 - Epic Final Review** is the final validation phase of S9, where you apply an epic-level PR review checklist, handle any discovered issues through bug fixes, and perform final verification before declaring the epic complete.

**This is NOT feature-level review** - S7 (Testing & Review) already reviewed individual features. This focuses on:
- Epic-wide architectural consistency
- Cross-feature code quality
- Epic scope and completeness
- Final validation against original request

### When do you use this guide?

**Use this guide when:**
- S9.P2 complete (validation loop achieved primary clean round + sub-agent confirmation)
- S9.P1 epic smoke testing passed (all 4 parts)
- S9.P3 user testing passed (user reports "No bugs found")
- Ready for final epic-level PR review and validation

**Do NOT use this guide if:**
- S9.P1 smoke testing not complete
- S9.P2 validation loop not complete (primary clean round + sub-agent confirmation required)
- S9.P3 user testing not complete
- Pending bug fixes not yet completed

### What are the key outputs?

1. **Epic Final Review Results** (documented in epic_lessons_learned.md)
   - Epic code review complete at epic level (cross-feature and epic-scope concerns only)
   - All categories must pass (no failures)

2. **Bug Fixes (if issues found)**
   - Bug fix folders created for any issues
   - S9 RESTARTED after bug fixes

3. **Final Verification**
   - All S9 steps confirmed complete
   - epic_lessons_learned.md updated
   - EPIC_README.md marked complete

4. **S9 Completion**
   - Ready to proceed to S10 (Final Changes & Merge)

### Time estimate

**60-90 minutes for SMALL/MEDIUM epics** (if no issues found)
- Epic PR Review: 30-45 minutes (scales with epic size; see note below)
- Final Verification: 15-30 minutes
- Documentation updates: 15 minutes

**+30-60 minutes for LARGE epics** (5+ features, 500+ files changed)
- Epic PR Review may take 60-90 minutes instead of 30-45
- Review complexity grows with feature count and file changes

**+2-4 hours per bug fix** (if issues found, includes S9 restart)

**Note:** Epic PR Review time scales with epic scope. The 30-45 minute estimate assumes 2-3 features or <300 files changed. For larger epics, allocate 60-90 minutes.

### Workflow overview

```bash
S9.P4 Workflow (Epic Final Review)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Prerequisites Met?
  ├─ S9.P2 complete (primary clean round + sub-agent confirmation)
  ├─ S9.P3 complete (user testing passed)
  └─ All tests passing (100%)
         │
         ▼
┌─────────────────────────────────────┐
│ STEP 6: Epic Final Review           │
│ (Fresh Sub-Agent - Epic Scope)       │
└─────────────────────────────────────┘
         │
         ├─ 1. Cross-Feature Integration
         ├─ 2. Architecture Coherence
         ├─ 3. Epic Requirements Coverage
         ├─ 4. Emergent Quality Patterns
         └─ 5. Epic Documentation Completeness
         │
         ▼
    Any Issues Found?
    ├─ YES → STEP 7 (Handle Issues)
    │         │
    │         ├─ Document all issues
    │         ├─ Create bug fixes
    │         └─ RESTART S9
    │
    └─ NO → STEP 8 (Final Verification)
              │
              ├─ Verify all issues resolved
              ├─ Update EPIC_README.md
              ├─ Update epic_lessons_learned.md
              └─ Mark S9 complete
              │
              ▼
        S9 COMPLETE
              │
              ▼
        Ready for S10
```

---

## Critical Rules for S9.P4

```text
┌─────────────────────────────────────────────────────────────┐
│ CRITICAL RULES - S9.P4 (Epic Final Review)               │
└─────────────────────────────────────────────────────────────┘

1. ⚠️ Epic-level PR review focuses on CROSS-FEATURE concerns
   - Feature-level review already done in S7 (Testing & Review)
   - Focus: Architectural consistency, cross-feature impacts
   - Don't repeat feature-level checks

2. ⚠️ FRESH SUB-AGENT CODE REVIEW REQUIRED (Epic-Scope)
   - Fresh Opus sub-agent performs epic-scoped code review (ZERO implementation bias)
   - Sub-agent checks ALL 12 review categories + 13 validation dimensions (interpreted at epic scope)
   - Dimension 13 (Implementation Fidelity) validates epic requirements coverage
   - See `code_review/s7_s9_code_review_variant.md` for complete workflow

3. If issues found, you MUST RESTART S9
   - After bug fixes complete
   - RESTART from S9.P1 (smoke testing)
   - Cannot partially continue S9

4. ⚠️ Validate against ORIGINAL epic request
   - Not against evolved specs
   - Re-read `.shamt/epics/requests/{epic_name}.txt` file
   - Verify user's stated goals achieved

5. ⚠️ Zero tolerance for architectural inconsistencies
   - Design patterns must be consistent across features
   - Code style must be uniform
   - Error handling must be consistent

6. ⚠️ Test pass rate required (conditional on Testing Approach)
   - Options C/D: All unit tests must pass (100%), no "expected failures"
   - Options B/D: All integration scripts must exit 0
   - Option A: No automated tests — smoke testing only
   - Fix ALL test failures before marking complete

7. ⚠️ Document EVERYTHING in epic_lessons_learned.md
   - PR review results
   - Issues found (if any)
   - S9 insights
   - Improvements for future epics

8. ⚠️ Cannot proceed to S10 without completion
   - All 8 steps of S9 must be complete
   - No pending issues or bug fixes
   - EPIC_README.md must show S9 complete
```

---

## Prerequisites

**Before starting S9.P4, verify ALL of these are true:**

### From S5 (Implementation Planning - All Features)
- [ ] All feature implementation plans exist and are accessible
- [ ] Implementation plan locations documented (needed for Dimension 13 - Implementation Fidelity check at epic scope)

### From S2 (Specification - All Features)
- [ ] All feature spec files exist and are accessible
- [ ] Spec file locations documented (needed for Dimension 13 - Implementation Fidelity check at epic scope)

### From Epic Request
- [ ] Original epic request file exists at `.shamt/epics/requests/{epic_name}.txt`
- [ ] Epic request accessible (needed for epic requirements coverage validation)

### From S9.P2 (Epic QC Validation Loop)
- [ ] primary clean round + sub-agent confirmation achieved
- [ ] All 13 dimensions checked every round (7 master + 6 epic)
- [ ] VALIDATION_LOOP_LOG.md complete
- [ ] S9.P2 completion documented in EPIC_README.md

### From S9.P1 (Epic Smoke Testing)
- [ ] Epic smoke testing Part 1 (Import Tests): PASSED
- [ ] Epic smoke testing Part 2 (Entry Point Tests): PASSED
- [ ] Epic smoke testing Part 3 (E2E Execution Tests): PASSED
- [ ] Epic smoke testing Part 4 (Cross-Feature Integration Tests): PASSED

### From S9.P3 (User Testing)
- [ ] User testing completed
- [ ] User reports "No bugs found"
- [ ] No pending bug fixes

### Feature Completion
- [ ] All features completed S8.P2 (Epic Testing Update) (Post-Feature Testing Update)
- [ ] S7.P3 (Final Review) completed and passed for ALL features
- [ ] No features currently in S6 (Implementation)
- [ ] No pending feature work

### Quality Gates
- [ ] All unit tests passing (100% pass rate)
- [ ] No known bugs or issues
- [ ] All previous bug fixes (if any) completed S7 (Testing & Review)

### Documentation
- [ ] epic_lessons_learned.md exists and accessible
- [ ] EPIC_README.md shows S9.P1, S9.P2, S9.P3 complete
- [ ] Original `.shamt/epics/requests/{epic_name}.txt` file located

**If ANY prerequisite not met:**
- STOP - Do not proceed with S9.P4
- Complete missing prerequisites first
- Return to appropriate phase (S9.P1, S9.P2, or S9.P3)

---

## S9.P2 Validation Overlap Awareness

**If S9.P2 achieved primary clean round + sub-agent confirmation:**

S9.P2's 12-dimension validation provides strong coverage that overlaps with several S9.P4 categories. Use S9.P2 findings as context, but still verify each category independently:

**Categories with High S9.P2 Coverage (trust but verify):**
- **Category 1 (Cross-Feature Integration):** S9.P2 Dimension 1 (Empirical Verification) validated integrations; S9.P2 Dimension 8 (Integration Points) validated data flows
- **Category 2 (Architecture Coherence):** S9.P2 Dimensions 8 & 11 (Integration, Alignment) validated design coherence

**Categories with Lower S9.P2 Coverage (more thorough review needed):**
- **Category 3 (Epic Requirements Coverage):** Requires re-reading the original request file line-by-line — not fully covered in S9.P2
- **Category 4 (Emergent Quality Patterns):** Cross-feature inconsistencies may have been partially flagged in S9.P2 Dimension 10 (Error Handling), but naming and logic duplication require explicit review
- **Category 5 (Epic Documentation Completeness):** Not fully covered in S9.P2

**Approach:**
- **Review fresh sub-agent epic code review** (no skipping)
- **For high-overlap categories:** Quick verification against S9.P2 findings, confirm still holds
- **For lower-overlap categories:** Thorough fresh review

**Note:** This guidance applies ONLY when S9.P2 achieved primary clean round + sub-agent confirmation. If S9.P2 had issues or was shortened, review fresh sub-agent epic code review (12 categories + 13 dimensions, epic-scope) thoroughly without relying on S9.P2 results.

---

## STEP 6: Epic Final Review (Fresh Sub-Agent Code Review)

**🚨 MANDATORY: READ CODE REVIEW VARIANT GUIDE**

**Before proceeding, you MUST:**
1. **READ:** `code_review/s7_s9_code_review_variant.md` (S7/S9 Code Review Variant)
2. **READ:** `code_review/code_review_workflow.md` (Full code review workflow)
3. **Understand the fresh sub-agent pattern for epic scope:**
   - Fresh Opus sub-agent reviews code with ZERO implementation bias
   - Skip overview.md creation (saves ~20-30% tokens)
   - Check 13 dimensions (7 master + 6 code-review-specific including Implementation Fidelity)
   - **Epic-scope focus:** Cross-feature integration, architectural coherence, NOT per-feature code quality

**Purpose:** Unbiased epic-level PR review using proven code review framework (12 review categories + 13 validation dimensions) with epic-scope interpretation.

**Why Fresh Sub-Agent?**
- **Zero implementation bias:** Sub-agent has no memory of design decisions, shortcuts, or assumptions made during epic implementation
- **True code review perspective:** Reviews code as written, not as intended
- **Catches epic-level drift:** Validates actual implementation matches validated plans at epic scope (Dimension 13: Implementation Fidelity)

**Key Distinction - Epic Scope:**
- **S7.P3 already validated per-feature code quality** (correctness, testing, security, performance at feature level)
- **S9.P4 focuses on epic-scope concerns only:**
  - Cross-feature integration correctness
  - Architectural coherence across features
  - Epic requirements coverage against original request
  - Emergent patterns only visible at full-epic scale
  - Epic documentation completeness
  - NOT individual feature code quality (already done)

---

### Step 6a: Spawn Fresh Sub-Agent (Epic-Scope Review)

**Primary agent action:** Spawn fresh Opus sub-agent to run epic-scoped code review.

Use Task tool with the prompt template from `code_review/s7_s9_code_review_variant.md` (Step 1: S9.P4 Epic Review example).

**Key parameters for sub-agent:**
- **Branch:** Epic branch name (e.g., `feat/EPIC-123`)
- **Review Type:** S9.P4 Epic PR Review
- **Scope:** **EPIC-LEVEL concerns only** (cross-feature integration, architectural coherence, NOT per-feature quality)
- **Epic Implementation Plans:** Path to all feature implementation plans in epic folder
- **Epic Spec Files:** Path to all feature specs in epic folder
- **Epic Request File:** Path to `.shamt/epics/requests/{epic_name}.txt` (original user request)
- **Model:** `opus` (for deep reasoning and thorough epic-level review)

**Sub-agent will:**
1. Access epic branch (read-only git commands)
2. Skip overview.md creation (Steps 3-4)
3. Write `review_v1.md` with severity-tagged epic-scope comments
4. Run validation loop (13 dimensions) until primary clean round + sub-agent confirmation
5. **Focus on epic-scope concerns** (not per-feature code quality)

**Epic-Scope Interpretation of 12 Review Categories:**

The sub-agent checks all 12 review categories but **interprets them at epic scope**:
1. **Correctness** — Cross-feature integration correctness (not per-feature correctness)
2. **Code Quality** — Architectural coherence across features (not per-feature code style)
3. **Comments & Documentation** — Epic documentation (EPIC_README.md, epic_lessons_learned.md)
4. **Code Organization** — Cross-feature structure consistency (not per-feature organization)
5. **Testing** — Epic smoke test coverage (not per-feature unit tests)
6. **Security** — Cross-feature security patterns (not per-feature validation)
7. **Performance** — Epic-level performance concerns (cross-feature bottlenecks)
8. **Error Handling** — Cross-feature error propagation (not per-feature error handling)
9. **Architecture & Design** — Overall epic architecture coherence (not per-feature design)
10. **Backwards Compatibility** — Cross-feature API consistency (not per-feature compatibility)
11. **Scope & Changes** — Epic requirements coverage against original request
12. **Context & Intent** — Epic-level intent (not per-feature context)

**Dimension 13 (Implementation Fidelity) at Epic Scope:**
- Verify all feature implementation plans collectively satisfy epic goals
- Verify no epic-level requirements missed
- Verify no scope creep at epic level
- Check against `.shamt/epics/requests/{epic_name}.txt` line-by-line

---

### Step 6b: Wait for Sub-Agent Review Completion

**Sub-agent output location:**
```text
.shamt/code_reviews/{sanitized_epic_branch}/review_v1.md
```

**Wait for sub-agent to complete:**
- Sub-agent runs full code review workflow with epic-scope focus
- Validation loop with 13 dimensions
- Exit criteria: Primary clean round + 2 Haiku sub-agent confirmations

**Time estimate:** 45-90 minutes depending on epic size and feature count

---

### Step 6c: Read Review Results

**Primary agent action:** Read the completed review file.

```bash
Read .shamt/code_reviews/{sanitized_epic_branch}/review_v1.md
```

**Review structure:**
- **Header:** Branch, date, file count, commit range
- **Comments by Category:** 12 review categories (epic-scope interpretation)
- **Comments by Severity:** BLOCKING → CONCERN → SUGGESTION → NITPICK
- **Format:** Each comment has file path, line number, issue description, suggested fix

**Focus:** Comments should be epic-scope concerns (cross-feature integration, architectural coherence), NOT per-feature code quality.

---

### Step 6d: Address All Comments

**Comment Addressing Protocol (per Design Decision 3):**

**BLOCKING comments (Must Fix Immediately):**
- **What:** Cross-feature integration bugs, epic requirements gaps, architectural showstoppers
- **Action:** Fix all BLOCKING comments before proceeding
- **Cannot continue until:** All BLOCKING resolved

**CONCERN comments (Must Fix Immediately):**
- **What:** Real cross-feature quality, architectural inconsistency, or epic documentation problems
- **Action:** Fix all CONCERN comments before proceeding
- **Cannot continue until:** All CONCERN resolved

**SUGGESTION comments (User Review):**
- **What:** Optional epic-level improvements
- **Action:** Walk through with user one-by-one
- **For each SUGGESTION:**
  1. Present to user with context + comment + suggested fix
  2. User decides: Fix now / Document as "acknowledged, won't fix" / Escalate
  3. Record decision in comment response log

**NITPICK comments (User Review):**
- **What:** Minor epic-level style or preference issues
- **Action:** Walk through with user one-by-one
- **For each NITPICK:**
  1. Present to user with context + comment + suggested fix
  2. User decides: Fix now / Document as "acknowledged, won't fix" / Escalate
  3. Record decision in comment response log

**Create Epic Comment Response Log:**

```markdown
## S9.P4 Epic Comment Response Log

**Epic:** {epic_name}
**Review File:** .shamt/code_reviews/{sanitized_branch}/review_v1.md
**Date:** {date}

### BLOCKING Comments (0 found)
{If none found, state: "No BLOCKING comments found ✅"}

### CONCERN Comments (0 found)
{If none found, state: "No CONCERN comments found ✅"}

### SUGGESTION Comments ({count} found)
1. **[File:Line]** {Issue description}
   - **User Decision:** {Fix / Document / Escalate}
   - **Action Taken:** {What was done}
   - **Status:** ✅ Addressed

### NITPICK Comments ({count} found)
1. **[File:Line]** {Issue description}
   - **User Decision:** {Fix / Document / Escalate}
   - **Action Taken:** {What was done}
   - **Status:** ✅ Addressed
```

**Checkpoint Before Continuing:**
- [ ] All BLOCKING comments resolved (code fixed)
- [ ] All CONCERN comments resolved (code fixed)
- [ ] All SUGGESTION comments addressed (fixed OR documented with user approval)
- [ ] All NITPICK comments addressed (fixed OR documented with user approval)
- [ ] Epic Comment Response Log complete
- [ ] All code changes committed

**If ANY checkbox unchecked:** Return to comment addressing and complete.

---

### Step 6 Completion

**S9.P4 Step 6 (Epic Final Review) is complete when:**
- ✅ Fresh sub-agent code review complete (review_v1.md validated with epic-scope focus)
- ✅ All BLOCKING/CONCERN comments fixed
- ✅ All SUGGESTION/NITPICK comments addressed (with user approval)
- ✅ Epic Comment Response Log complete
- ✅ All changes committed
- ✅ Epic is production-ready from cross-feature and architectural perspective

**Output artifacts:**
- `.shamt/code_reviews/{sanitized_epic_branch}/review_v1.md` (validated epic review)
- `.shamt/code_reviews/{sanitized_epic_branch}/review_validation_log.md` (validation history)
- Epic Comment Response Log (in EPIC_README.md or separate file)

**Proceed to STEP 7 (Handle Issues) if ANY issues were found that require bug fixes**
**OR proceed to STEP 8 (Final Verification) if review was clean**

---

## STEP 7: Handle Issues (If Any Discovered)

**When to use:** ANY category failed in Step 6 PR review

**When to SKIP:** All 11 categories passed, no issues discovered

---

### Overview

**Objective:** Create bug fixes for any epic-level integration issues discovered during Step 6.

**Critical Rule:** After bug fixes, you MUST COMPLETELY RESTART S9 from S9.P1.

**Why RESTART?** Bug fixes may have affected areas already checked. Cannot assume previous QC results still valid.

---

### Step-by-Step Workflow

**See:** `reference/stage_9/epic_final_review_templates.md` Templates 2-6 for issue handling templates

**Step 7.1: Document ALL Issues**

**See:** Template 2 (Issues Found Documentation)

Document in epic_lessons_learned.md:
- Issue description
- Discovered in (which category)
- Impact (HIGH/MEDIUM/LOW)
- Root cause
- Fix required
- Priority (high/medium/low)

**Step 7.2: Determine Bug Fix Priorities**

**See:** Template 3 (Issue Prioritization)

**Priority Levels:**
- **high:** Breaks functionality, security, architecture, performance >100% regression
- **medium:** Affects quality (consistency, error messages, minor performance)
- **low:** Cosmetic only (comments, variable names) - document only, no bug fix

**Step 7.3: Present Issues to User**

**See:** Template 4 (User Presentation)

Present ALL high/medium priority issues to user for approval before creating bug fixes.

**Step 7.4: Create Bug Fixes Using Bug Fix Workflow**

**See:** Template 5 (Bug Fix Folder Structure)

For EACH issue:
1. Create bug fix folder (bugfix_{priority}_{name}/)
2. Create notes.txt with issue description
3. Run through bug fix workflow: S2 → S5 → S6 → S7
4. Bug fix stays in epic folder (doesn't move to done/)

**Step 7.5: RESTART S9 After Bug Fixes**

**See:** Template 6 (S9 Restart Documentation)

**CRITICAL:** You MUST COMPLETELY RESTART S9 after ALL bug fixes complete.

**Restart Protocol:**
1. Mark all S9 steps as "incomplete" in EPIC_README.md
2. Re-run S9.P1 (Epic Smoke Testing - all 4 parts)
3. Re-run S9.P2 (Epic QC Validation Loop - until primary clean round + sub-agent confirmation)
4. Re-run S9.P4 (Epic Final Review - fresh sub-agent epic code review)
5. Document restart in epic_lessons_learned.md

---

## STEP 8: Final Verification & README Update

**When to use:** Step 6 passed (fresh sub-agent epic code review) AND Step 7 complete OR skipped (no issues)

---

### Overview

**Objective:** Verify S9.P3 complete, all issues resolved, update epic documentation.

---

### Step-by-Step Workflow

**See:** `reference/stage_9/epic_final_review_templates.md` Templates 7-10 for verification templates

**Step 8.1: Verify All Issues Resolved**

**See:** Template 7 (Final Verification Checklist)

**Verification Checklist:**
- [ ] S9.P1 Epic smoke testing passed (all 4 parts)
- [ ] S9.P2 Epic QC Validation Loop passed (primary clean round + sub-agent confirmation)
- [ ] All 13 dimensions validated (7 master + 6 epic)
- [ ] S9.P3 User testing passed (no bugs found)
- [ ] Epic final review passed (fresh sub-agent epic code review (12 categories + 13 dimensions, epic-scope), primary clean round + sub-agent confirmation)
- [ ] NO pending issues or bug fixes
- [ ] ALL tests passing (100% pass rate)

**Run all tests to confirm:**
```bash
{TEST_COMMAND}
## Expected: 100% pass rate, exit code 0
```

**If ANY item unchecked:** STOP - Address remaining issues, re-run affected steps

**Step 8.2: Update EPIC_README.md Epic Progress Tracker**

**See:** Template 8 (Epic Progress Tracker Update)

Mark S9 complete, including:
- S9.P1, P2, P3, P4 completion status
- Issues found and resolved
- Bug fixes completed
- S9 restarts (if any)
- Date completed

**Step 8.3: Update epic_lessons_learned.md**

**See:** Template 9 (S9.P4 Lessons Learned)

Add S9.P4 insights:
- What went well
- What could be improved
- Issues found & resolved
- Insights for future epics
- Guide improvements needed
- Statistics (time, issues, bug fixes)
- Key takeaway

**Step 8.4: Update EPIC_README.md Agent Status**

**See:** Template 10 (Agent Status Update)

Mark S9.P4 complete and prepare for S10:
- Current stage: S9.P4
- Status: COMPLETE
- S9 summary (all parts, results)
- Next stage: stages/s10/s10_epic_cleanup.md
- Next action: Read epic cleanup guide

**Step 8.5: Completion Indicator**

**S9.P4 is COMPLETE when ALL of these are true:**
- ✅ All 3 steps finished (6, 7, 8)
- ✅ Epic PR review passed (fresh sub-agent epic code review)
- ✅ All issues resolved (bug fixes complete OR no issues found)
- ✅ No pending issues or bug fixes
- ✅ EPIC_README.md Epic Progress Tracker updated
- ✅ epic_lessons_learned.md updated with S9.P4 insights
- ✅ EPIC_README.md Agent Status shows S9.P4 complete
- ✅ All tests passing (100% pass rate)
- ✅ Ready to proceed to S10

**If ANY item not complete:** STOP - Complete missing items, re-verify

---

## Re-Reading Checkpoints

**You MUST re-read this guide when:**

### 1. After Session Compaction
- Conversation compacted while in S9.P4
- Re-read to restore context
- Check EPIC_README.md Agent Status to see which step you're on
- Continue from documented checkpoint

### 2. After Creating Bug Fixes
- Bug fixes created during Step 7
- Re-read "STEP 7: Handle Issues" section
- Remember: MUST RESTART S9 after bug fixes (from S9.P1)
- Re-read S9.P1 and S9.P2 guides for restart

### 3. After Extended Break (>24 hours)
- Returning to epic after break
- Re-read guide to refresh requirements
- Verify prerequisites still met (tests passing, no new issues)

### 4. When Encountering Confusion
- Unsure about next step
- Re-read workflow overview and current step
- Check EPIC_README.md for current status

### 5. Before Starting Epic PR Review (Step 6)
- Re-read all 11 category descriptions
- Refresh focus areas for each category
- Ensure thorough coverage (don't rush)

**Re-Reading Protocol:**
1. Use Read tool to load ENTIRE guide
2. Find current step in EPIC_README.md Agent Status
3. Read "Workflow Overview" section
4. Read current step's detailed workflow
5. Proceed with renewed understanding

---

## Exit Criteria

**S9.P4 is COMPLETE when ALL of the following are true:**

### Epic Final Review (Step 6)
- [ ] All Epic code review complete: ✅ PASSED
  - [ ] 1. Cross-Feature Integration: ✅ PASS
  - [ ] 2. Architecture Coherence: ✅ PASS
  - [ ] 3. Epic Requirements Coverage: ✅ PASS
  - [ ] 4. Emergent Quality Patterns: ✅ PASS
  - [ ] 5. Epic Documentation Completeness: ✅ PASS
- [ ] Primary clean round achieved (zero issues across fresh sub-agent epic code review (12 categories + 13 dimensions, epic-scope))
- [ ] Sub-agent confirmation: both sub-agents reported zero issues ✅ (see protocol below)
- [ ] Review results documented in epic_lessons_learned.md

**Sub-Agent Confirmation Protocol (when consecutive_clean = 1):**

EXECUTE THE FOLLOWING TASK TOOL CALLS IN A SINGLE MESSAGE:

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues in epic final review (sub-agent A)</parameter>
  <parameter name="prompt">You are sub-agent A confirming zero issues in S9.P4 epic final review.

**Artifact to validate:** Epic {epic_name} pr_review_issues.md and epic implementation
**Validation categories:** All 5 epic final review categories
**Your task:** Review the epic and verify fresh sub-agent epic code review have zero issues.

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found".

Check: Cross-feature integration, architecture coherence, epic requirements coverage against original request, emergent quality patterns, epic documentation completeness.
</parameter>
</invoke>

<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues in epic final review (sub-agent B)</parameter>
  <parameter name="prompt">You are sub-agent B confirming zero issues in S9.P4 epic final review.

**Artifact to validate:** Epic {epic_name} pr_review_issues.md and epic implementation
**Validation categories:** All 5 epic final review categories
**Your task:** Review the epic in reverse order and verify fresh sub-agent epic code review have zero issues.

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found".

Check: Cross-feature integration, architecture coherence, epic requirements coverage against original request, emergent quality patterns, epic documentation completeness.
</parameter>
</invoke>
```

**Why Haiku?** Sub-agent confirmations are focused verification (70-80% token savings per SHAMT-27). See `reference/model_selection.md`.

**What happens next:**
- Both confirm zero issues → S9.P4 complete, proceed to Step 7 or Step 8 ✅
- Either finds issues → Reset consecutive_clean = 0, fix issues, continue validation

### Handle Issues (Step 7 - if applicable)
- [ ] All issues documented (if any found)
- [ ] Bug fixes created for all high/medium priority issues (if any)
- [ ] Bug fixes completed S7 (Testing & Review) (if any created)
- [ ] S9 RESTARTED after bug fixes (if any created)
- [ ] All steps re-run and passed after restart

### Final Verification (Step 8)
- [ ] All issues resolved (no pending issues or bug fixes)
- [ ] All unit tests passing (100% pass rate)
- [ ] EPIC_README.md Epic Progress Tracker updated (S9 marked complete)
- [ ] epic_lessons_learned.md updated with S9.P4 insights
- [ ] EPIC_README.md Agent Status shows S9.P4 complete

### Overall S9 Completion
- [ ] S9.P1 complete (Epic Smoke Testing passed)
- [ ] S9.P2 complete (Epic QC Validation Loop - primary clean round + sub-agent confirmation)
- [ ] S9.P3 complete (User Testing passed - no bugs found)
- [ ] S9.P4 complete (Epic Final Review passed, issues resolved)
- [ ] Original epic goals validated and achieved (from S9.P2 dimension 12)
- [ ] Ready to proceed to S10

**DO NOT proceed to S10 until ALL completion criteria are met.**

---

## Reference Files

**For detailed information, see these reference files:**

**Epic PR Review Checklist:**
- `reference/stage_9/epic_pr_review_checklist.md`
- Complete 11-category checklist with validation steps
- Use during Step 6 (Epic PR Review)

**Templates:**
- `reference/stage_9/epic_final_review_templates.md`
- Templates for documenting results (Steps 6-8)
- Issue documentation, bug fix structure, verification checklists

**Examples & Best Practices:**
- `reference/stage_9/epic_final_review_examples.md`
- Common mistakes to avoid (7 anti-patterns)
- Real-world example walkthrough
- Best practices summary

---

## Prerequisites for Next Stage

**Before proceeding to S10 (Final Changes & Merge), verify:**

### S9.P4 Completion
- [ ] STEP 6 (Epic PR Review) complete: All 11 categories PASSED
- [ ] STEP 7 (Handle Issues) complete OR skipped (no issues)
- [ ] STEP 8 (Final Verification) complete: All verification items checked

### Overall S9 Completion
- [ ] S9.P1 complete (Epic Smoke Testing passed)
- [ ] S9.P2 complete (Epic QC Validation Loop - primary clean round + sub-agent confirmation)
- [ ] S9.P3 complete (User Testing passed - no bugs found)
- [ ] S9.P4 complete (Epic Final Review passed, issues resolved)
- [ ] No pending issues or bug fixes
- [ ] All bug fix folders (if any) show S7 (Testing & Review) complete

### Documentation Complete
- [ ] epic_lessons_learned.md updated with S9.P4 insights
- [ ] EPIC_README.md Epic Progress Tracker shows S9 complete
- [ ] EPIC_README.md Agent Status shows S9.P4 complete
- [ ] PR review results documented

### Quality Gates Passed
- [ ] All unit tests passing (100% pass rate)
- [ ] Original epic goals validated (from S9.P2 dimension 12)
- [ ] Epic success criteria met
- [ ] End-to-end workflows validated

**Only proceed to S10 when ALL items are checked.**

**Next stage:** stages/s10/s10_epic_cleanup.md
**Next action:** Read stages/s10/s10_epic_cleanup.md to begin epic cleanup

---

## Summary

**S9.P4 - Epic Final Review is the final validation before epic completion:**

**Key Activities:**
1. **Epic Final Review (Step 6):** Review 5 epic-level categories using primary-agent + sub-agent confirmation protocol
   - Focus: Cross-feature integration, architecture coherence, original requirements coverage, emergent patterns, documentation completeness
   - Per-feature code quality already confirmed in S7.P3; these 5 categories are purely epic-scope
   - Document results in epic_lessons_learned.md

2. **Handle Issues (Step 7):** Create bug fixes for any discovered issues
   - Document all issues comprehensively
   - Create bug fixes using bug fix workflow
   - RESTART S9 from S9.P1 after fixes

3. **Final Verification (Step 8):** Confirm S9 complete
   - Verify all issues resolved
   - Update EPIC_README.md (Epic Progress Tracker, Agent Status)
   - Update epic_lessons_learned.md with insights

**Critical Distinctions:**
- **Feature-level PR review (S7 (Testing & Review)):** Reviews individual features in isolation
- **Epic-level PR review (S9.P4):** Reviews cross-feature consistency, architectural cohesion, epic scope

**Success Criteria:**
- Epic PR review passed (fresh sub-agent epic code review)
- All issues resolved (bug fixes complete OR no issues)
- No pending issues or bug fixes
- All tests passing (100%)
- Original epic goals achieved
- Ready to proceed to S10

**Common Pitfalls:**
- Repeating feature-level review instead of restricting to epic-scope categories
- Fixing issues inline instead of using bug fix workflow
- Skipping Category 3 (Epic Requirements Coverage) line-by-line verification against original request
- Comparing to specs instead of original epic request (`.shamt/epics/requests/`)
- Accepting issues instead of creating bug fixes
- Not documenting review results
- Proceeding to S10 with pending issues

**See:** `reference/stage_9/epic_final_review_examples.md` for detailed examples of each mistake and best practices

**Remember:** S9.P4 is the LAST CHANCE to catch epic-level issues before shipping. Thoroughness here prevents post-completion rework and ensures epic delivers on user's vision.


## Next Stage

**After S9.P4 complete:** Proceed to `stages/s10/s10_epic_cleanup.md`

**S9 Complete Checklist Before S10:**
- [ ] All 4 phases of S9 complete (Smoke Test, QC Rounds, User Testing, Final Review)
- [ ] ZERO bugs remaining (100% test pass, user approved)
- [ ] Epic documentation verified and complete

**📖 READ NEXT:** `stages/s10/s10_epic_cleanup.md` - Final docs, commit, PR creation, merge verification

---

*End of s9_p4_epic_final_review.md*
