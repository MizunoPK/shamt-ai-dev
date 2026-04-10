# S7.P3: Final Review (PR Validation Loop)

**File:** `s7_p3_final_review.md`

**Purpose:** Production readiness validation through PR validation loop, lessons learned capture, and final verification.

**Version:** 2.0 (Updated to use standardized validation loop)
**Last Updated:** 2026-02-10

**Stage Flow Context:**
```text
S7.P1 (Smoke Testing) → S7.P2 (Validation Loop) →
→ [YOU ARE HERE: S7.P3 - Final Review] →
→ S8 (Post-Feature Alignment)
```

---

## Table of Contents

1. [🚨 MANDATORY READING PROTOCOL](#🚨-mandatory-reading-protocol)
2. [Overview](#overview)
3. [🛑 Critical Rules](#🛑-critical-rules)
4. [Prerequisites Checklist](#prerequisites-checklist)
5. [Workflow Overview](#workflow-overview)
6. [Step 1: PR Review (Validation Loop)](#step-1-pr-review-validation-loop)
7. [Step 2: Lessons Learned Capture](#step-2-lessons-learned-capture)
8. [Step 3: Final Verification](#step-3-final-verification)
9. [🛑 MANDATORY CHECKPOINT 1](#🛑-mandatory-checkpoint-1)
10. [Exit Criteria](#exit-criteria)
11. [Common Mistakes to Avoid](#common-mistakes-to-avoid)
12. [Real-World Examples](#real-world-examples)
13. [Prerequisites for Next Stage](#prerequisites-for-next-stage)
14. [Summary](#summary)

---

## 🚨 MANDATORY READING PROTOCOL

**BEFORE starting Final Review — including when resuming a prior session — you MUST:**

1. **Use the phase transition prompt** from `prompts_reference_v2.md`
   - Find "Starting S7.P3" prompt
   - Speak it out loud (acknowledge requirements)
   - List critical requirements from this guide

2. **Update README Agent Status** with:
   - Current Phase: S7.P3 (Final Review - PR Validation Loop)
   - Current Guide: reference/validation_loop_qc_pr.md
   - Guide Last Read: {YYYY-MM-DD HH:MM}
   - Critical Rules: "primary clean round + sub-agent confirmation required", "All 11 PR categories checked every round", "Update guides immediately", "100% completion required"
   - Next Action: Begin PR Validation Loop Round 1

3. **Verify all prerequisites** (see checklist below)

4. **THEN AND ONLY THEN** begin final review

**This is NOT optional.** Reading this guide ensures production-ready quality.

---

## 🚫 FORBIDDEN SHORTCUTS

You CANNOT:
- Skip Step 1 (PR Review Validation Loop) because "the code was already reviewed during S7.P2" — S7.P3 uses fresh-eyes PR review (reference/validation_loop_qc_pr.md), distinct from S7.P2's code quality validation loop; primary clean round + sub-agent confirmation is required
- Skip Step 2 (Lessons Learned Capture) to save time — lessons learned documentation is mandatory and feeds into S11.P1 guide improvement; it cannot be deferred

If you are about to do any of the above: STOP and re-read the relevant section.

---

## Overview

**What is this guide?**
Final Review validates production readiness through PR validation loop (7 master dimensions + QC/PR criteria), applies lessons learned to guides immediately, and verifies 100% completion.

**When do you use this guide?**
- S7.P2 complete (Feature QC validation loop passed)
- Ready for final production readiness validation
- Before cross-feature alignment

**Key Outputs:**
- ✅ PR validation loop complete (primary clean round + sub-agent confirmation)
- ✅ All 11 PR categories checked (code quality, testing, security, etc.)
- ✅ lessons_learned.md updated
- ✅ Workflow guides updated immediately (lessons applied, not just documented)
- ✅ Final verification passed (100% completion confirmed)
- ✅ Ready for S8.P1 (Cross-Feature Alignment)

**Time Estimate:**
2-3 hours (PR validation loop typically 4-6 rounds)

**Exit Condition:**
Final Review is complete when primary clean round + sub-agent confirmation achieved (zero issues across all categories), lessons learned are applied to guides (not just documented), 100% completion is verified, and feature is ready for commit

---

## 🛑 Critical Rules

🚨 **S7.P3 IS NOT A LIGHTER VERSION OF S7.P2** 🚨

Even if S7.P2 found and fixed many issues, S7.P3 requires FULL rigor:
- S7.P2 = **Developer testing** (functional correctness, bug hunting)
- S7.P3 = **PR reviewer** (code quality, maintainability, production readiness)
- Both require: empirical verification with `read_file` and `grep_search`, comprehensive checks, file:line citations
- "S7.P2 was thorough" does NOT justify summarizing S7.P3 categories

**Evidence requirements per PR category:**
- Each category must cite specific tool calls (grep_search results, read_file findings)
- "Refactoring looks good ✅" is NOT acceptable — must explain WHY (e.g., "grep_search found 7 field conditionals at lines 76-94, duplication acceptable because each has unique extraction logic")
- "Performance OK ✅" is NOT acceptable — must calculate impact (e.g., "5-10 briefs × 10ms render = negligible, no memoization needed")

**Historical context:** In a child project Feature 03, an agent summarized Categories 4-11 as "✅ PASS" without investigation after thorough S7.P2. User caught the shortcut, requiring full restart of S7.P3. The different lens (reviewer vs developer) catches different issues.

```text
┌─────────────────────────────────────────────────────────────┐
│ CRITICAL RULES - These MUST be copied to README Agent Status │
└─────────────────────────────────────────────────────────────┘

1. ⚠️ FRESH SUB-AGENT CODE REVIEW REQUIRED
   - Fresh Opus sub-agent performs code review (ZERO implementation bias)
   - Sub-agent checks ALL 12 review categories + 13 validation dimensions
   - 12 review categories: Correctness, Code Quality, Comments & Documentation, Code Organization, Testing, Security, Performance, Error Handling, Architecture & Design, Backwards Compatibility, Scope & Changes, Context & Intent
   - 13 dimensions: 7 master + 6 code-review-specific (including Implementation Fidelity)
   - See `code_review/s7_s9_code_review_variant.md` for complete workflow

2. ⚠️ PRIMARY CLEAN ROUND + SUB-AGENT CONFIRMATION REQUIRED
   - Code review sub-agent runs validation loop internally
   - Clean round = ZERO issues OR exactly 1 LOW-severity issue (fixed)
   - Counter resets if: 2+ LOW issues OR any MEDIUM/HIGH/CRITICAL issue
   - See `reference/severity_classification_universal.md` for severity definitions
   - After primary clean round (counter = 1): spawn 2 independent Haiku sub-agents in parallel; both must confirm zero issues to exit
   - Typical: 3-5 primary rounds total to achieve primary clean round

3. ⚠️ FIX ISSUES IMMEDIATELY (NO RESTART)
   - If issues found → Fix ALL immediately
   - Critical issues (correctness, security): Must fix before next round
   - Minor issues: Must fix before next round (no deferring)
   - Continue validation (no restart to S7.P2)

4. ⚠️ LESSONS LEARNED MUST UPDATE GUIDES
   - If you discover guide gaps → update guides IMMEDIATELY
   - Don't just document the lesson → apply it to guides
   - Update relevant guide files before completing S7.P3
   - This is NOT optional

5. ⚠️ 100% REQUIREMENT COMPLETION - ZERO TECH DEBT TOLERANCE
   - Feature is DONE or NOT DONE (no partial credit, no "90% done")
   - ALL spec requirements must be implemented 100%
   - ALL checklist items must be verified and resolved
   - NO "we'll add that later" items allowed
   - NO deferred features, shortcuts, or "temporary" solutions
   - NO tech debt - if it's in the spec, it's REQUIRED and must be fully implemented
   - If something cannot be implemented, get user approval to REMOVE from scope
   - Clean codebase with zero compromises - every requirement fully complete

6. ⚠️ FINAL VERIFICATION IS MANDATORY
   - Cannot skip final verification checklist
   - Must honestly answer: "Would I ship this to production?"
   - If any hesitation → investigate why

7. ⚠️ RE-READING CHECKPOINT
   - Before declaring complete → re-read Completion Criteria
   - Verify ALL criteria met (not just most)
   - Update README Agent Status one final time
```

---

## Prerequisites Checklist

**Verify these BEFORE starting Final Review:**

**From S7.P2:**
- [ ] Validation Loop: PASSED (primary clean round + sub-agent confirmation)
- [ ] All 17 dimensions checked every round (7 master + 10 S7 QC-specific)
- [ ] Zero issues deferred (fix-and-continue approach used)
- [ ] All re-reading checkpoints completed

**From S5 (Implementation Planning):**
- [ ] Validated implementation plan exists and is accessible
- [ ] Implementation plan location documented (needed for Dimension 13 - Implementation Fidelity check)

**From S2 (Specification):**
- [ ] Feature spec file exists and is accessible
- [ ] Spec file location documented (needed for Dimension 13 - Implementation Fidelity check)

**From S7.P1:**
- [ ] All 3 smoke test parts passed
- [ ] Part 3 verified OUTPUT DATA VALUES

**Unit Tests:**
- [ ] Run `{TEST_COMMAND}` → exit code 0
- [ ] All unit tests passing (100% pass rate)

**Documentation:**
- [ ] `implementation_checklist.md` all requirements verified
- [ ] QC round results documented

**If ANY prerequisite not met:** Return to previous stage and complete it first.

---

## Workflow Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                FINAL REVIEW WORKFLOW                        │
└─────────────────────────────────────────────────────────────┘

Fresh Sub-Agent Code Review (12 Categories + 13 Dimensions)
   ├─ Spawn fresh Opus sub-agent (zero implementation bias)
   ├─ Sub-agent checks 12 review categories:
   │  1. Correctness
   │  2. Code Quality
   │  3. Comments & Documentation
   │  4. Code Organization
   │  5. Testing
   │  6. Security
   │  7. Performance
   │  8. Error Handling
   │  9. Architecture & Design
   │  10. Backwards Compatibility
   │  11. Scope & Changes
   │  12. Context & Intent
   ├─ Sub-agent validates 13 dimensions (7 master + 6 code-review-specific)
   ├─ Dimension 13: Implementation Fidelity (validates plan adherence)
   ├─ Primary agent addresses ALL comments (BLOCKING/CONCERN must fix, SUGGESTION/NITPICK user review)
   ↓
   Output: review_v1.md with severity-tagged comments

Lessons Learned Capture
   ├─ Review what went well / what didn't
   ├─ Identify guide gaps
   ├─ UPDATE GUIDES IMMEDIATELY (don't just document)
   ├─ Update lessons_learned.md
   ↓

Final Verification
   ├─ All completion criteria met?
   ├─ Feature is ACTUALLY complete?
   ├─ Would ship to production?
   ↓
   If YES: Update README, proceed to S8.P1 (Cross-Feature Alignment)
   If NO: Investigate and resolve

Re-Reading Checkpoint
   ↓ Re-read Completion Criteria
   ↓ Update README Agent Status
   ↓ Ready for S8.P1 (Cross-Feature Alignment)
```

---

## Step 1: PR Review (Fresh Sub-Agent Code Review)

**🚨 MANDATORY: READ CODE REVIEW VARIANT GUIDE**

**Before proceeding, you MUST:**
1. **READ:** `code_review/s7_s9_code_review_variant.md` (S7/S9 Code Review Variant)
2. **READ:** `code_review/code_review_workflow.md` (Full code review workflow)
3. **Understand the fresh sub-agent pattern:**
   - Fresh Opus sub-agent reviews code with ZERO implementation bias
   - Skip overview.md creation (saves ~20-30% tokens)
   - Check 13 dimensions (7 master + 6 code-review-specific including Implementation Fidelity)
   - Primary agent addresses all comments systematically

**Purpose:** Unbiased PR-level review using proven code review framework (12 review categories + 13 validation dimensions).

**Why Fresh Sub-Agent?**
- **Zero implementation bias:** Sub-agent has no memory of design decisions, shortcuts, or assumptions made during implementation
- **True code review perspective:** Reviews code as written, not as intended
- **Catches implementation drift:** Validates actual implementation matches validated plans (Dimension 13: Implementation Fidelity)

---

### Step 1a: Spawn Fresh Sub-Agent

**Primary agent action:** Spawn fresh Opus sub-agent to run code review.

Use Task tool with the prompt template from `code_review/s7_s9_code_review_variant.md` (Step 1: S7.P3 Feature Review example).

**Key parameters for sub-agent:**
- **Branch:** Feature branch name (e.g., `feat/EPIC-123/feature-01`)
- **Review Type:** S7.P3 Feature PR Review
- **Scope:** Feature-level code quality (not epic-level concerns)
- **Implementation Plan:** Path to validated implementation plan
- **Spec File:** Path to feature spec file
- **Model:** `opus` (for deep reasoning and thorough review)

**Sub-agent will:**
1. Access branch (read-only git commands)
2. Skip overview.md creation (Steps 3-4)
3. Write `review_v1.md` with severity-tagged comments
4. Run validation loop (13 dimensions) until primary clean round + sub-agent confirmation

---

### Step 1b: Wait for Sub-Agent Review Completion

**Sub-agent output location:**
```text
.shamt/code_reviews/{sanitized_feature_branch}/review_v1.md
```

**Wait for sub-agent to complete:**
- Sub-agent runs full code review workflow
- Validation loop with 13 dimensions
- Exit criteria: Primary clean round + 2 Haiku sub-agent confirmations

**Time estimate:** 30-60 minutes depending on feature size

---

### Step 1c: Read Review Results

**Primary agent action:** Read the completed review file.

```bash
Read .shamt/code_reviews/{sanitized_feature_branch}/review_v1.md
```

**Review structure:**
- **Header:** Branch, date, file count, commit range
- **Comments by Category:** 12 review categories
  1. Correctness
  2. Code Quality
  3. Comments & Documentation
  4. Code Organization
  5. Testing
  6. Security
  7. Performance
  8. Error Handling
  9. Architecture & Design
  10. Backwards Compatibility
  11. Scope & Changes
  12. Context & Intent (if applicable)
- **Comments by Severity:** BLOCKING → CONCERN → SUGGESTION → NITPICK
- **Format:** Each comment has file path, line number, issue description, suggested fix

---

### Step 1d: Address All Comments

**Comment Addressing Protocol (per Design Decision 3):**

**BLOCKING comments (Must Fix Immediately):**
- **What:** Correctness bugs, security issues, data-loss risks
- **Action:** Fix all BLOCKING comments before proceeding
- **Cannot continue until:** All BLOCKING resolved

**CONCERN comments (Must Fix Immediately):**
- **What:** Real quality, performance, or maintainability problems
- **Action:** Fix all CONCERN comments before proceeding
- **Cannot continue until:** All CONCERN resolved

**SUGGESTION comments (User Review):**
- **What:** Optional improvements where code works but could be better
- **Action:** Walk through with user one-by-one
- **For each SUGGESTION:**
  1. Present to user with context + comment + suggested fix
  2. User decides: Fix now / Document as "acknowledged, won't fix" / Escalate
  3. Record decision in comment response log

**NITPICK comments (User Review):**
- **What:** Minor style or preference issues
- **Action:** Walk through with user one-by-one
- **For each NITPICK:**
  1. Present to user with context + comment + suggested fix
  2. User decides: Fix now / Document as "acknowledged, won't fix" / Escalate
  3. Record decision in comment response log

**Create Comment Response Log:**

```markdown
## S7.P3 Comment Response Log

**Feature:** {feature_name}
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
- [ ] Comment Response Log complete
- [ ] All code changes committed

**If ANY checkbox unchecked:** Return to comment addressing and complete.

---

### Step 1 Completion

**S7.P3 Step 1 (PR Review) is complete when:**
- ✅ Fresh sub-agent code review complete (review_v1.md validated)
- ✅ All BLOCKING/CONCERN comments fixed
- ✅ All SUGGESTION/NITPICK comments addressed (with user approval)
- ✅ Comment Response Log complete
- ✅ All changes committed

**Output artifacts:**
- `.shamt/code_reviews/{sanitized_branch}/review_v1.md` (validated review)
- `.shamt/code_reviews/{sanitized_branch}/review_validation_log.md` (validation history)
- Comment Response Log (in feature README or separate file)

**Proceed to Step 1b (Documentation Impact Assessment)**

---

## Step 1b: Documentation Impact Assessment

**Purpose:** Ensure architectural and convention decisions from this feature are captured in project documentation.

**Time:** 5-10 minutes

### Process

**1b-1. Review Feature Changes**

Consider what this feature introduced:
- New modules, classes, or services?
- New integration patterns or data flows?
- New coding patterns that should be followed?
- Decisions about how to handle specific scenarios?

**1b-2. Complete Assessment Checklist**

Document in the feature README.md:

```markdown
## Documentation Impact Assessment

**Date:** {YYYY-MM-DD}

### Architecture Impact
- [ ] This feature added new modules/services -> Update ARCHITECTURE.md
- [ ] This feature changed data flow or integration patterns -> Update ARCHITECTURE.md
- [ ] This feature added significant dependencies -> Update ARCHITECTURE.md
- [ ] No architecture changes

### Coding Standards Impact
- [ ] This feature established patterns others should follow -> Update CODING_STANDARDS.md
- [ ] This feature made convention decisions (naming, structure, etc.) -> Update CODING_STANDARDS.md
- [ ] This feature revealed existing conventions are problematic -> Update CODING_STANDARDS.md
- [ ] No coding standards changes

### Actions Taken
- [ ] Reviewed ARCHITECTURE.md - no updates needed
- [ ] Reviewed CODING_STANDARDS.md - no updates needed
- [ ] Updated ARCHITECTURE.md: {describe changes}
- [ ] Updated CODING_STANDARDS.md: {describe changes}
- [ ] Noted issues for S11 guide update process: {describe}
```

**1b-3. Make Updates (If Needed)**

If any checkbox indicates updates needed:
1. Open the relevant file
2. Add/modify the relevant section
3. Update the "Last Updated" date
4. Add entry to "Update History" table
5. Continue to Step 2 (Lessons Learned)

**Note:** This assessment is advisory, not blocking. Even if no updates are needed, the assessment must be completed and documented.

---

## Step 2: Lessons Learned Capture

**📖 See `reference/validation_loop_qc_pr.md` for fresh perspective review approach (optional).**

**Purpose:** Document what went well, what didn't, and UPDATE GUIDES IMMEDIATELY

**CRITICAL:** Don't just document lessons - APPLY them to guides before completing S7.P3

**Fresh Perspective Approach (Optional):**
- Re-read lessons with fresh eyes after initial drafting
- Check for patterns (similar issues across phases)
- Verify lessons are actionable (not just observations)
- Ensure guide updates are specific (not vague improvements)

---

### Lessons Learned Process

**1. Review what went well:**
- What aspects of implementation went smoothly?
- What parts of the guides were helpful?
- What practices prevented issues?

**2. Review what didn't go well:**
- What issues were discovered in QC/smoke testing?
- What was unclear in the guides?
- What steps were skipped/missed?
- What caused rework?

**3. Identify guide gaps:**
- Are there missing steps in guides that would have helped?
- Are there unclear instructions that caused confusion?
- Are there missing examples that would clarify?
- Are there missing anti-patterns to document?

**4. UPDATE GUIDES IMMEDIATELY:**

This is NOT optional. If you found guide gaps, fix them NOW.

**Example:**
```markdown
## Lesson Learned:

Issue: Validation Loop found all output data was zeros
Root cause: Smoke test Part 3 only checked "file exists", didn't verify data VALUES
Guide gap: stages/s7/s7_p1_smoke_testing.md didn't emphasize DATA VALUES enough

Action taken: Updated S7.P1 guide
- Added "CRITICAL - Verify OUTPUT DATA" to Part 3 heading
- Added real-world example of zero data issue
- Added explicit "Don't just check file exists" warning
- Added code example showing good vs bad Part 3 validation

Files updated:
- .shamt/guides/stages/s7/s7_p1_smoke_testing.md
```

**5. Update lessons_learned.md:**

```markdown
## Feature_XX Lessons Learned

### What Went Well
- Smoke testing caught integration bug that unit tests missed
- Validation Loop baseline comparison revealed pattern inconsistency
- PR Review Category 5 (Testing) identified missing edge case tests

### What Didn't Go Well
- Initial smoke test Part 3 only checked file existence (not data values)
- Required QC restart after Round 1 due to mock assumption failures
- 3 hours spent debugging issue that better interface verification would have caught

### Root Causes
- Guide didn't emphasize DATA VALUES enough in smoke testing
- Skipped Interface Verification Protocol in S6 (assumed interface)
- Excessive mocking in tests hid real integration issues

### Guide Updates Applied
1. Updated stages/s7/s7_p1_smoke_testing.md:
   - Enhanced smoke test Part 3 with DATA VALUES emphasis
   - Added real-world example of zero data issue

2. Updated stages/s6/s6_execution.md:
   - Made Interface Verification Protocol STEP 1 (not optional)
   - Added "NO coding from memory" critical rule

3. Updated stages/s5/s5_v2_validation_loop.md:
   - Enhanced Mock Audit (iteration 21) with "excessive mocking" anti-pattern

### Recommendations for Future Features
- ALWAYS verify data VALUES in smoke tests (not just structure)
- NEVER skip Interface Verification Protocol
- Use mocks only for I/O, not internal classes
- If in doubt about interface, READ THE SOURCE CODE

### Time Impact
- Guide gaps cost: ~3 hours debugging + 2 hours rework
- Following guides correctly would have saved: ~5 hours
- QC restart added: ~2 hours (but prevented larger issues later)
```

---

## Step 3: Final Verification

**Purpose:** Confirm all completion criteria met before transitioning to S8.P1 (Cross-Feature Alignment)

---

### Final Verification Checklist

**Smoke Testing:**
- [ ] Part 1 (Import Test): PASSED
- [ ] Part 2 (Entry Point Test): PASSED
- [ ] Part 3 (E2E Execution Test): PASSED with data VALUES verified

**Validation Loop:**
- [ ] Validation Loop: PASSED (primary clean round + sub-agent confirmation)
- [ ] All 17 dimensions checked every round (7 master + 10 S7 QC-specific)
- [ ] Zero issues deferred (fix-and-continue approach used)

**PR Review:**
- [ ] All 11 categories reviewed
- [ ] Zero critical issues
- [ ] Minor issues documented (if any)

**Artifacts Updated:**
- [ ] lessons_learned.md updated with this feature's lessons
- [ ] Guides updated if gaps found (applied immediately, not just documented)
- [ ] Epic Checklist updated: `- [x] Feature_XX QC complete`

**Zero Tech Debt Verification:**
- [ ] **ZERO tech debt**: No deferred issues of ANY size (critical, minor, cosmetic)
- [ ] **ZERO "later" items**: If you wrote it down to fix later, fix it NOW
- [ ] **Production ready**: Would you ship this to production RIGHT NOW with no changes? (Must answer YES)

**README Agent Status:**
- [ ] Updated with completion of S7.P3
- [ ] Next action set to "S8.P1 (Cross-Feature Alignment): Cross-Feature Alignment"

**Git:**
- [ ] All implementation changes committed
- [ ] Working directory clean (`git status`)
- [ ] Commit messages descriptive

**Final Question:**
- [ ] **"Is this feature ACTUALLY complete and ready for production?"**
  - Not "tests pass"
  - Not "code works"
  - But "feature is DONE and CORRECT"

**If ALL boxes checked:** Proceed to S8.P1 (Cross-Feature Alignment)
**If ANY box unchecked:** Do NOT proceed - complete the missing item first

---

## 🛑 MANDATORY CHECKPOINT 1

**You are about to declare S7.P3 complete**

⚠️ STOP - DO NOT PROCEED TO S8 YET

**REQUIRED ACTIONS:**
1. [ ] Use Read tool to re-read "Completion Criteria" section below
2. [ ] Verify ALL completion criteria met (not just most) - check every box
3. [ ] Use Read tool to re-read "Prerequisites for Next Stage" section
4. [ ] Update feature README Agent Status:
   - Current Guide: "stages/s8/s8_p1_cross_feature_alignment.md"
   - Current Step: "S7.P3 complete, ready to start S8.P1"
   - Last Updated: [timestamp]
5. [ ] Output acknowledgment: "✅ CHECKPOINT 1 COMPLETE: Re-read Completion Criteria and Prerequisites, verified ALL criteria met"

**Why this checkpoint exists:**
- S7.P3 has 15+ completion criteria across 3 subsections
- 95% of agents miss at least one criterion when not re-reading
- Incomplete S7 causes failed commits and rework

**ONLY after completing ALL 5 actions above, proceed to Next Steps section**

---

## Exit Criteria

**S7.P3 (and entire S7 (Testing & Review)) is complete when ALL of the following are true:**

### Smoke Testing (S7.P1)
- [x] All 3 smoke test parts passed
- [x] Part 3 verified OUTPUT DATA VALUES (not just "file exists")
- [x] Feature executes end-to-end without crashes
- [x] Output data is correct and reasonable

### Validation Loop (S7.P2)
- [x] Validation Loop passed (primary clean round + sub-agent confirmation)
- [x] All 17 dimensions checked every round (7 master + 10 S7 QC-specific)
- [x] Zero issues deferred (fix-and-continue approach used)

### PR Review (S7.P3)
- [x] All 11 categories reviewed
- [x] Zero critical issues found
- [x] Minor issues documented (if any exist)

### Documentation
- [x] lessons_learned.md updated with this feature's lessons
- [x] Guides updated if gaps were found (applied immediately)
- [x] implementation_checklist.md all requirements verified

### Unit Tests
- [x] Run `{TEST_COMMAND}` → exit code 0
- [x] 100% pass rate maintained

### Git
- [x] All implementation changes committed
- [x] Working directory clean (`git status`)
- [x] Commit messages descriptive

### README Agent Status
- [x] Updated to reflect S7.P3 completion
- [x] Next action set to "S8.P1 (Cross-Feature Alignment): Cross-Feature Alignment"
- [x] Guide Last Read timestamp current

### Final Verification
- [x] Feature is ACTUALLY complete (not just functional)
- [x] Would ship to production with confidence
- [x] Data values verified (not just structure)
- [x] All spec requirements met (100%, no partial work)

**If ALL criteria met:** Proceed to S8.P1

**If ANY criteria not met:** Do NOT proceed until all are met

---

## Common Mistakes to Avoid

### Anti-Pattern 1: Documenting Lessons But Not Applying Them

**❌ Mistake:**
```markdown
## Lessons Learned
- S7.P1 guide should emphasize data values more

{End of feature work - guide never updated}
```

**Why wrong:** Next feature will hit same issue because guide wasn't fixed

**✅ Correct:** UPDATE GUIDES IMMEDIATELY when gaps found (Step 2)

---

### Anti-Pattern 2: Ignoring Minor Issues

**❌ Mistake:**
"PR Review found missing docstrings, but that's minor, I'll skip documenting it"

**Why wrong:**
- Minor issues accumulate → technical debt
- Missing docstrings → harder maintenance
- Not documenting → issue gets forgotten

**✅ Correct:** Document ALL issues (critical AND minor), even if not blocking

---

### Anti-Pattern 3: "Good Enough" Mentality

**❌ Mistake:**
"Feature mostly works, 90% of data is correct, ship it"

**Why wrong:**
- 10% wrong data → untrustworthy results → users abandon feature
- "Good enough" compounds → technical debt
- Critical Rule: NO PARTIAL WORK

**✅ Correct:** 100% requirement completion, or feature is INCOMPLETE

---

### Anti-Pattern 4: Skipping Final Verification

**❌ Mistake:**
"I did PR review and lessons learned, that's enough"

**Why wrong:** Final Verification catches edge cases missed in earlier steps

**✅ Correct:** Actually work through Final Verification Checklist (all boxes)

---

## Real-World Examples

### Example 1: Lessons Learned Updates Prevent Future Issues

**Feature:** Schedule strength multiplier

**Issue found in Validation Loop:**
```text
Log quality check: 487 WARNING messages during normal execution
Investigation: Most are "Opponent data missing for week {week}, using default"

Root cause: Schedule data only loaded for weeks 1-17
Code tries to access week 18 (doesn't exist in regular season)
Should use INFO level, not WARNING (this is expected behavior)
```

**Developer's actions:**
1. Fixed log level (WARNING → INFO)
2. Added documentation about 17-week schedule
3. **Updated S7.P2 guide:**
   - Added "Log Quality Verification" example
   - Added "Expected vs Unexpected warnings" distinction
   - Added this real-world example to guide

**Result:** Next feature developer read updated guide, avoided same issue

**Lesson:** Updating guides immediately prevents future features from hitting same issues.

---

### Example 2: PR Review Catches Scope Creep

**Feature:** Add rank multiplier to scoring recommendations

**PR Review Category 11 (Scope):**
```markdown
Spec requirement: "Add rank multiplier to scoring recommendations"

Code review found:
✅ In scope:
- Calculate rank multiplier
- Apply to draft scores
- Display in recommendations

⚠️ Out of scope (not in spec):
- NEW: Caching layer for rank data (250 lines of code)
- NEW: Admin UI for configuring rank weights (180 lines of code)
- NEW: rank priority trend analysis over time (320 lines of code)

Total: 750 lines of unspecified code (30% of feature)

Issue: Scope creep - added features not in spec
Decision: Remove out-of-scope code or get user approval
```

**Resolution:**
- Asked user if these additions were wanted
- User said: "No, just the basic rank multiplier for now"
- Removed 750 lines of unspecified code
- Feature size reduced 30%
- Complexity reduced significantly

**Lesson:** PR Review Category 11 catches scope creep before it's shipped

---

## Prerequisites for Next Stage

**Before transitioning to S8.P1, verify:**

### Completion Verification
- [ ] All S7.P3 completion criteria met (see Completion Criteria section)
- [ ] All smoke tests passed (3 parts)
- [ ] All QC rounds passed (primary clean round + sub-agent confirmation)
- [ ] PR review complete (11 categories)
- [ ] Lessons learned captured AND guides updated

### Files Verified
- [ ] lessons_learned.md updated
- [ ] implementation_checklist.md all verified
- [ ] Guides updated if gaps found

### Git Status
- [ ] All changes committed
- [ ] Working directory clean
- [ ] Descriptive commit messages

### README Agent Status
- [ ] Updated to reflect S7.P3 completion
- [ ] Next action set to "Read stages/s8/s8_p1_cross_feature_alignment.md"

### Final Check
- [ ] Feature is COMPLETE (not just functional)
- [ ] Would ship to production with confidence
- [ ] 100% requirement completion (no partial work)

**If ALL verified:** Ready for S8.P1 (Cross-Feature Alignment)

**S8.P1 (Cross-Feature Alignment) Preview:**
- Review all REMAINING (not-yet-implemented) feature specs
- Compare to ACTUAL implementation (not plan) of just-completed feature
- Update specs if implementation revealed changes/insights
- Ensure remaining features align with reality

**Next step:** Read stages/s8/s8_p1_cross_feature_alignment.md and use phase transition prompt

---

## Summary

**S7.P3 validates production readiness through:**
1. **PR Review** - 11 categories ensure code quality, security, correctness
2. **Lessons Learned** - Capture insights and apply improvements to guides
3. **Final Verification** - Confirm 100% completion and readiness

**Critical protocols:**
- All 11 PR categories mandatory (each catches different issues)
- Update guides immediately when gaps found (don't just document)
- 100% completion required (no partial work)
- Final verification confirms "actually complete" not just "functional"

**Success criteria:**
- PR review complete (zero critical issues)
- Lessons learned captured and guides updated
- Final verification passed (all boxes checked)
- Feature is COMPLETE and production-ready

**After S7.P3:** Proceed to S8.P1 to ensure remaining feature specs align with actual implementation.

---

## Next Phase

**After completing S7.P3 (Final Review):**

- PR review complete (zero critical issues)
- Lessons learned captured and guides updated
- Feature is COMPLETE and production-ready
- Proceed to: `stages/s8/s8_p1_cross_feature_alignment.md` (Cross-Feature Alignment)

**See also:** `prompts_reference_v2.md` → "Starting S8" prompt

---

*End of stages/s7/s7_p3_final_review.md*
