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
- Skip Step 6 (Epic Final Review) or any of its 5 categories because "S9.P2 already covered them" — all 5 categories are MANDATORY; S9.P2 results provide supplementary context only, not a replacement for the epic-scope review
- Fix issues found in Step 6 inline instead of creating bug fix folders — ALL high/medium priority issues require a bug fix folder and the full S2→S5→S6→S7 workflow
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
   - 5 categories reviewed at epic level (cross-feature and epic-scope concerns only)
   - All categories must pass (no failures)

2. **Bug Fixes (if issues found)**
   - Bug fix folders created for any issues
   - S9 RESTARTED after bug fixes

3. **Final Verification**
   - All S9 steps confirmed complete
   - epic_lessons_learned.md updated
   - EPIC_README.md marked complete

4. **S9 Completion**
   - Ready to proceed to S10 (Epic Cleanup)

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
│ (5 Categories - Epic Scope)         │
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

2. ⚠️ ALL 5 categories are MANDATORY
   - Cannot skip categories
   - All categories must PASS (no exceptions)
   - If ANY category fails → create bug fix

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
- **Review ALL 5 categories** (no skipping)
- **For high-overlap categories:** Quick verification against S9.P2 findings, confirm still holds
- **For lower-overlap categories:** Thorough fresh review

**Note:** This guidance applies ONLY when S9.P2 achieved primary clean round + sub-agent confirmation. If S9.P2 had issues or was shortened, review all 5 categories thoroughly without relying on S9.P2 results.

---

## STEP 6: Epic Final Review (5 Categories)

**Purpose:** Systematic review of 5 epic-level categories using the standard primary-agent + sub-agent confirmation protocol. S7.P3 already validated per-feature code quality; this step covers only cross-feature and epic-scope concerns.

**Note:** Per-feature code quality was confirmed in S7.P3. Categories here cover only cross-feature and epic-scope concerns that are invisible until all features are complete together.

---

### Overview

**Objective:** Review 5 epic-level categories. Each category focuses on concerns that are only meaningful at epic scope — not individual feature behavior.

**This is NOT feature-level review:**
- S7.P3 (Final Review) already reviewed each feature's correctness, code quality, documentation, security, performance, and test coverage
- S9.P4 reviews EPIC-SCOPE concerns only:
  - Cross-feature integration correctness
  - Architectural coherence across features
  - Epic requirements coverage against original request
  - Emergent patterns only visible at full-epic scale
  - Epic documentation completeness

**5 Review Categories:**

1. **Cross-Feature Integration** — Do all features work together correctly? Are integration points verified? Does data flow correctly between features? Are there interface mismatches?

2. **Architecture Coherence** — Does the overall implementation match the intended architecture? Is there unplanned coupling between features? Has the design drifted from the epic's intended structure?

3. **Epic Requirements Coverage** — Are ALL original epic requirements satisfied? Verify against the epic request file (`.shamt/epics/requests/{epic_name}.txt`) line-by-line. Are any user-stated goals unaddressed?

4. **Emergent Quality Patterns** — Cross-feature inconsistencies only visible at epic scope: inconsistent error handling styles across features, naming inconsistencies between features (same concept named differently), logic duplicated across features that should be shared.

5. **Epic Documentation Completeness** — Does `EPIC_README.md` accurately reflect the actual implementation? Does `epic_lessons_learned.md` cover all stages? Does `epic_smoke_test_plan.md` reflect the actual implementation? Are feature summaries accurate?

**Exit Criteria:** Primary clean round + sub-agent confirmation (standard master protocol)

---

### Step-by-Step Workflow

**Step 6.1: Create pr_review_issues.md**

```text
Location: SHAMT-{N}-{epic_name}/pr_review_issues.md
Purpose: Track issues discovered during epic review
```

**Step 6.2: Primary Agent Review (5 Categories)**

Review each category sequentially. For each category:
- Read relevant code/docs directly (do not rely on memory of earlier stages)
- Check the S9.P2 validation log for prior findings relevant to this category (trust but verify the most critical claims)
- Document any issues found in `pr_review_issues.md`

**Focus by category:**

**Category 1 — Cross-Feature Integration:**
- Read each feature's actual integration points (not just specs)
- Verify data handoffs between features work correctly
- Check that error propagation across feature boundaries is handled

**Category 2 — Architecture Coherence:**
- Compare actual code structure to intended architecture (from DISCOVERY.md and epic ticket)
- Identify any features that coupled to others in unplanned ways
- Check for consistent design patterns across features

**Category 3 — Epic Requirements Coverage:**
- Read `.shamt/epics/requests/{epic_name}.txt` (original request)
- Compare each stated requirement against the actual implementation
- Flag any goal that appears unaddressed or only partially addressed

**Category 4 — Emergent Quality Patterns:**
- Scan all features for inconsistent error handling styles
- Check that the same concept isn't named differently across features
- Identify logic that is duplicated across features and should be shared (not just noted in one feature)

**Category 5 — Epic Documentation Completeness:**
- Read `EPIC_README.md` and verify it accurately describes the implementation
- Verify `epic_smoke_test_plan.md` reflects actual test scenarios (not assumptions from S1/S3)
- Check that `epic_lessons_learned.md` covers insights from all stages

**Step 6.3: Assess Primary Round Results**

**If primary review found ZERO issues across all 5 categories:**
- Mark primary round as clean
- Proceed to Step 6.4 (sub-agent confirmation)

**If primary review found issues:**
- Fix all issues found
- Re-run the primary review (Step 6.2) from the beginning
- Repeat until a primary round finds zero issues

**Step 6.4: Sub-Agent Confirmation**

After the first clean primary round, spawn 2 independent sub-agents to confirm. Each sub-agent:
- Reviews all 5 categories independently
- Has access to the same code and documentation
- Reports zero issues OR identifies any remaining concerns

**Pass criteria:** Both sub-agents report zero issues → S9.P4 Step 6 PASSED.

If either sub-agent finds issues: fix them, re-run primary review, then spawn 2 new sub-agents.

**Step 6.5: Document Results**

**Update epic_lessons_learned.md with results:**

**See:** `reference/stage_9/epic_final_review_templates.md` Template 1 for review results template

**Include:**
- Date, epic name, total rounds (primary + sub-agent confirmation)
- Final status (PASSED)
- Summary of what was found in each category
- Total issues found and fixed
- Epic-level concerns addressed

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
4. Re-run S9.P4 (Epic Final Review - all 11 categories)
5. Document restart in epic_lessons_learned.md

---

## STEP 8: Final Verification & README Update

**When to use:** Step 6 passed (all 11 categories) AND Step 7 complete OR skipped (no issues)

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
- [ ] Epic final review passed (all 5 categories, primary clean round + sub-agent confirmation)
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
- ✅ Epic PR review passed (all 11 categories)
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
- [ ] All 5 categories reviewed: ✅ PASSED
  - [ ] 1. Cross-Feature Integration: ✅ PASS
  - [ ] 2. Architecture Coherence: ✅ PASS
  - [ ] 3. Epic Requirements Coverage: ✅ PASS
  - [ ] 4. Emergent Quality Patterns: ✅ PASS
  - [ ] 5. Epic Documentation Completeness: ✅ PASS
- [ ] Primary clean round achieved (zero issues across all 5 categories)
- [ ] Sub-agent confirmation: both sub-agents reported zero issues ✅
- [ ] Review results documented in epic_lessons_learned.md

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

**Before proceeding to S10 (Epic Cleanup), verify:**

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
- Epic PR review passed (all 11 categories)
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

**📖 READ NEXT:** `stages/s10/s10_epic_cleanup.md` - Guide updates, PR creation, archival

---

*End of s9_p4_epic_final_review.md*
