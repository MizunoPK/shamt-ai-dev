# S10: Epic Cleanup Guide

**Guide Version:** 2.1
**Last Updated:** 2026-01-02
**Prerequisites:** S9 complete (Epic Final QC passed)
**Next Stage:** None (Epic complete - moved to done/)

---

## Table of Contents

1. [MANDATORY READING PROTOCOL](#-mandatory-reading-protocol)
2. [Overview](#overview)
3. [Critical Rules](#-critical-rules)
4. [Prerequisites Checklist](#prerequisites-checklist)
5. [Workflow Overview](#workflow-overview)
6. [Quick Navigation](#quick-navigation)
7. [Detailed Workflow](#detailed-workflow)
8. [Re-Reading Checkpoints](#re-reading-checkpoints)
9. [Exit Criteria](#exit-criteria)
10. [Summary](#summary)

---

## 🚨 MANDATORY READING PROTOCOL

**BEFORE starting S10 — including when resuming a prior session — you MUST:**

1. **Quick entry point:** `reference/stage_10/stage_10_reference_card.md` — covers the full S10 workflow; use this for fast navigation
2. **Full guide (this file):** Read entirely for detailed step instructions or when encountering edge cases
3. **Use the phase transition prompt** from `prompts_reference_v2.md` ("Starting Epic Cleanup")
4. **Acknowledge critical requirements** by listing them explicitly
5. **Verify ALL prerequisites** using the checklist below
6. **Update EPIC_README.md Agent Status** to reflect S10 start
7. **THEN AND ONLY THEN** begin epic cleanup

**Rationale:** S10 is the FINAL stage before epic completion. This stage ensures:
- All work is committed to git
- Documentation is complete and accurate
- Epic folder is ready for archival
- Future agents can understand what was accomplished

Rushing this process results in incomplete documentation, missing commits, or disorganized done/ folder.

---

## 🚫 FORBIDDEN SHORTCUTS

You CANNOT:
- Skip commit verification because "all changes were committed during S5-S9" — use the Prerequisites Checklist to verify all changes are committed; missing commits are a common S10 failure
- Move the epic folder to done/ before completing ALL cleanup steps — moving to done/ is the FINAL step after all documentation, verification, and commit steps are complete

If you are about to do any of the above: STOP and re-read the relevant section.

---

## Overview

**What is S10?**
Epic Cleanup is the final stage where you commit all changes, verify documentation, and move the completed epic to the done/ folder for archival.

**When do you use this guide?**
- After S9 (Epic Final QC) is complete
- All features implemented and validated
- Epic ready for completion

**Key Outputs:**
- ✅ All changes committed to git with clear commit message
- ✅ Documentation verified complete (README, lessons learned, etc.)
- ✅ Epic folder moved to `.shamt/epics/done/{epic_name}/`
- ✅ CLAUDE.md updated if workflow changes made

**Phase Structure:**
- **S10.P1 (Guide Updates):** MANDATORY — every epic must review guide improvements (based on lessons learned)
- **S10.P2 (Epic Overview):** OPTIONAL — user decides whether to create narrative overview document
- **Phase Execution:** P1 and P2 are independent (P2 is not dependent on P1 output). P1 runs first, then S10 asks user about P2.

**Time Estimate:**
Epic cleanup typically takes 85-130 minutes (S10.P2 skipped) or 105-170 minutes (S10.P2 opted in), both including S10.P1 guide updates. Without guide updates, approximately 40-60 minutes.

**Model Selection for Token Optimization (SHAMT-27):**

S10 cleanup can save 20-30% tokens through delegation:

```
Primary Agent (Opus):
├─ Spawn Haiku → Run tests, verify file existence, count files
├─ Spawn Sonnet → Read documentation for completeness checks
├─ Primary handles → Commit message writing, CLAUDE.md updates, decision-making
└─ Primary executes → Git operations, file moves, final verification
```

**See:** `reference/model_selection.md` for Task tool examples.

**Critical Success Factors:**
1. Run tests per Testing Approach BEFORE committing (Options C/D: unit tests 100% pass; Options B/D: integration scripts all exit code 0)
2. Verify ALL documentation complete
3. Write clear commit message describing epic
4. Move ENTIRE epic folder to done/ (not piecemeal)
5. Update CLAUDE.md if guides were improved

---

## 🛑 Critical Rules

```text
┌─────────────────────────────────────────────────────────────────┐
│ CRITICAL RULES FOR STAGE 10                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ 1. ⚠️ STAGE 9 MUST BE COMPLETE                                  │
│    - Verify Epic Final QC passed                                │
│    - Verify no pending bug fixes or features                    │
│    - Verify EPIC_README.md shows S9 complete               │
│                                                                  │
│ 2. ⚠️ RUN TESTS PER TESTING APPROACH BEFORE COMMITTING           │
│    Check EPIC_README for Testing Approach (A/B/C/D):            │
│    - Option A: No automated test requirement — skip this gate   │
│    - Options C/D: Run unit tests; exit code MUST be 0 (100%)   │
│    - Options B/D: Run all integration scripts; all exit code 0 │
│    - If ANY test/script fails → Fix before committing           │
│                                                                  │
│ 3. ⚠️ VERIFY ALL DOCUMENTATION COMPLETE                         │
│    - EPIC_README.md complete and accurate                       │
│    - epic_lessons_learned.md contains insights                  │
│    - All feature README.md files complete                       │
│    - epic_smoke_test_plan.md reflects final implementation      │
│                                                                  │
│ 4. ⚠️ USER TESTING COMPLETED IN STAGE 9                         │
│    - S9 includes mandatory user testing (Step 6)           │
│    - User must report "No bugs found" before S10            │
│    - If bugs found in S9 → Bug fixes → Restart S9    │
│    - S10 only begins after user testing passed              │
│                                                                  │
│ 5. ⚠️ COMMIT MESSAGE MUST USE NEW FORMAT                        │
│    - Format: "{commit_type}/SHAMT-{number}: {message}"           │
│    - commit_type is "feat" or "fix"                             │
│    - Message: 100 chars or less                                 │
│    - Body: List major features and changes                      │
│                                                                  │
│ 6. ⚠️ CREATE PULL REQUEST FOR USER REVIEW                       │
│    - Push branch to remote: git push origin {work_type}/SHAMT-{N}│
│    - Create PR using gh CLI with epic summary                   │
│    - User reviews PR and merges when satisfied                  │
│                                                                  │
│ 7. ⚠️ UPDATE .shamt/epics/EPIC_TRACKER.md BEFORE CREATING PR                │
│    - Move epic from Active to Completed table                   │
│    - Add epic detail section with commits                       │
│    - Increment "Next Available Number"                          │
│    - Commit and push .shamt/epics/EPIC_TRACKER.md update as part of PR       │
│                                                                  │
│ 8. ⚠️ MOVE ENTIRE EPIC FOLDER (NOT INDIVIDUAL FEATURES)         │
│    - Move: .shamt/epics/{epic}/                              │
│    - To: .shamt/epics/done/{epic}/                           │
│    - Keep original epic request (.txt) in .shamt/epics/requests/  │
│                                                                  │
│ 9. ⚠️ MAINTAIN MAX 10 EPICS IN done/ FOLDER                     │
│    - Count epics in done/ before moving current epic            │
│    - If count >= 10: Delete oldest epic(s) to make room         │
│    - After move: done/ should have 10 or fewer epics            │
│    - Keeps repository size manageable                           │
│                                                                  │
│ 10. ⚠️ UPDATE CLAUDE.md IF GUIDES IMPROVED                       │
│    - Check epic_lessons_learned.md for guide improvements       │
│    - Update .shamt/guides/ files if needed                          │
│    - Update CLAUDE.md if workflow changed                       │
│                                                                  │
│ 11. ⚠️ VERIFY EPIC IS TRULY COMPLETE                            │
│     - All features implemented                                  │
│     - All tests passing                                         │
│     - All QC passed                                             │
│     - User testing passed (completed in S9 Step 6)         │
│     - No pending work                                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites Checklist

**Before starting S10, verify:**

### S9 Completion
- [ ] EPIC_README.md shows "S9 - Epic Final QC: ✅ COMPLETE"
- [ ] Epic smoke testing passed (S9.P1)
- [ ] Epic QC Validation Loop passed (primary clean round + sub-agent confirmation in S9.P2)
- [ ] User testing passed (Step 6 - ZERO bugs reported by user)
- [ ] Epic PR review passed (all 11 categories)
- [ ] No pending issues from S9

### Feature Completion Status
- [ ] ALL features show "S8.P2 (Epic Testing Update) complete" in EPIC_README.md
- [ ] No features in progress
- [ ] No pending bug fixes (or all bug fixes at S7 (Testing & Review))

### Test Status
- [ ] Testing Approach confirmed (check EPIC_README for A/B/C/D)
- [ ] **Option A:** No automated test requirement (skip this section)
- [ ] **Options C/D:** All unit tests passing (verified recently, no failures, no skips)
- [ ] **Options B/D:** All integration scripts passing (exit code 0, verified recently)

### Documentation Status
- [ ] EPIC_README.md exists and is complete
- [ ] epic_lessons_learned.md exists with insights from all stages
- [ ] epic_smoke_test_plan.md reflects final implementation
- [ ] All feature README.md files complete

**If ANY checklist item is unchecked, STOP. Do NOT proceed to S10 until all prerequisites are met.**

---

## Workflow Overview

```text
STAGE 10: Epic Cleanup
│
├─> STEP 1: Pre-Cleanup Verification (Verify epic truly complete)
│   ├─ Verify S9 complete
│   ├─ Verify all features complete
│   ├─ Verify no pending work
│   └─ Read epic_lessons_learned.md for guide improvements
│
├─> STEP 2: Run Tests Per Testing Approach (conditional)
│   ├─ Check EPIC_README for Testing Approach (A/B/C/D)
│   ├─ Option A: No automated test requirement → skip to STEP 3
│   ├─ Options C/D: Run unit tests; exit code 0 required
│   ├─ Options B/D: Run all integration scripts; all exit code 0 required
│   └─ If ANY test/script fails → Fix and re-run
│
├─> STEP 3: Documentation Verification
│   ├─ Verify EPIC_README.md complete
│   ├─ Verify epic_lessons_learned.md contains insights
│   ├─ Verify epic_smoke_test_plan.md accurate
│   ├─ Verify all feature README.md files complete
│   └─ Update any incomplete documentation
│
├─> STEP 4: Final Commit (Epic Implementation)
│   ├─ Review all changes with git status and git diff
│   ├─ Stage all epic-related changes
│   ├─ Create commit with clear message
│   └─ Verify commit successful
│
├─> STEP 5: Move Epic to done/ Folder
│   ├─ Create done/ folder if doesn't exist
│   ├─ Clean up done/ folder (max 10 epics, delete oldest if needed)
│   ├─ Move entire epic folder to done/
│   ├─ Verify move successful (folder structure intact)
│   ├─ Verify done/ has 10 or fewer epics
│   ├─ Leave original epic request (.txt) in .shamt/epics/requests/
│   └─ Commit the epic folder move
│
├─> STEP 6: Update .shamt/epics/EPIC_TRACKER.md
│   ├─ Move epic from Active to Completed table
│   ├─ Add epic detail section with full description
│   ├─ Increment "Next Available Number"
│   ├─ Commit the .shamt/epics/EPIC_TRACKER.md update
│   └─ Append summary row to .shamt/epics/PROCESS_METRICS.md and commit
│
├─> STEP 7: S10.P2 — Epic Overview Document (optional)
│   ├─ Ask user: create SHAMT-{N}-OVERVIEW.md? (yes / no)
│   ├─ If no: skip to STEP 8
│   ├─ Gather context (git log, git diff, EPIC_README, feature READMEs)
│   ├─ Plan narrative structure before writing
│   ├─ Create SHAMT-{N}-OVERVIEW.md at repository root
│   ├─ Run validation loop (2 consecutive clean rounds)
│   └─ Commit overview document
│
├─> STEP 8: Push Branch and Create Pull Request
│   ├─ Check gh CLI availability (gh auth status)
│   ├─ If gh available: agent creates PR directly
│   ├─ If gh not available: provide PR creation instructions to user
│   ├─ Recommend squash commit message to user
│   ├─ Wait for user to merge PR
│   └─ Sync local main (git reset --hard origin/main)
│
├─> STEP 8.5: PR Comment Resolution (User-Triggered)
│   ├─ User directs agent to process PR comments
│   ├─ Fetch all review comments via gh API
│   ├─ Create pr_comment_resolution.md in epic folder
│   ├─ Work through each comment (fix / discuss / won't fix)
│   └─ Push any new commits
│
├─> STEP 9: S10.P1 — Guide Update from Lessons Learned + PR Comment Analysis
│   ├─ Read ALL lessons_learned.md files (epic + features)
│   ├─ Read pr_comment_resolution.md if it exists
│   ├─ Identify guide gaps from lessons AND PR comment patterns
│   ├─ Create GUIDE_UPDATE_PROPOSAL.md (prioritized P0-P3)
│   ├─ Present each proposal to user (individual approval)
│   ├─ Create proposal doc in .shamt/unimplemented_design_proposals/
│   └─ Commit proposal doc (or note zero proposals if none accepted)
│
└─> STEP 10: Final Verification & Completion
    ├─ Verify epic in done/ folder
    ├─ Verify original request still in .shamt/epics/requests/
    ├─ Verify git shows clean state
    ├─ Update EPIC_README.md with completion summary
    └─ Celebrate epic completion! 🎉
```

**Critical Decision Points:**
- **After Step 2:** If tests fail → Fix issues, RESTART Step 2
- **After Step 3:** If documentation incomplete → Update docs, re-verify
- **After Step 4:** If commit fails → Fix issues, retry commit

---

## Quick Navigation

**S10 has 10 main steps. Jump to any step:**

| Step | Focus Area | Time | Mandatory Gate? | Go To |
|------|-----------|------|-----------------|-------|
| **Step 1** | Pre-Cleanup Verification | 5 min | No | [Jump](#step-1-pre-cleanup-verification) |
| **Step 2** | Run Tests Per Testing Approach | 5 min | ✅ YES (conditional per A/B/C/D) | [Jump](#step-2-run-tests-per-testing-approach) |
| **Step 2b** | Investigate Anomalies | 10-30 min | Optional | [Jump](#step-2b-investigate-user-reported-anomalies-if-applicable) |
| **Step 3** | Documentation Verification | 10 min | No | [Jump](#step-3-documentation-verification) |
| **Step 4** | Final Commit (Epic Work) | 10 min | No | [Jump](#step-4-final-commit-epic-implementation) |
| **Step 5** | Move Epic to done/ | 5 min | No | [Jump](#step-5-move-epic-to-done-folder) |
| **Step 6** | Update .shamt/epics/EPIC_TRACKER.md | 5 min | No | [Jump](#step-6-update-shamtepicsepic_trackermd) |
| **Step 7** | S10.P2 Epic Overview Document | 0 min (skipped) / 20-40 min (opted in) | No | [Jump](#step-7-s10p2--epic-overview-document-optional) |
| **Step 8** | Push and Create PR (with gh detection) | 5 min | No | [Jump](#step-8-push-branch-and-create-pull-request) |
| **Step 8.5** | PR Comment Resolution | 0 min (skipped) / 15-30 min (triggered) | Optional | [Jump](#step-85-pr-comment-resolution-user-triggered) |
| **Step 9** | S10.P1 Guide Update + PR Comment Analysis | 20-45 min | No | [Jump](#step-9-guide-update-from-lessons-learned-mandatory-s10p1) |
| **Step 10** | Final Verification | 5 min | No | [Jump](#step-10-final-verification--completion) |

**Total Time:** 85-130 minutes (S10.P2 skipped) or 105-170 minutes (S10.P2 opted in), both including S10.P1 guide updates

**Reference Files (Extracted for Quick Access):**

| Reference | Description | Location |
|-----------|-------------|----------|
| **Commit Message Examples** | Format, examples, anti-patterns | [reference/stage_10/commit_message_examples.md](../../reference/stage_10/commit_message_examples.md) |
| **Epic Completion Template** | EPIC_README completion format | [reference/stage_10/epic_completion_template.md](../../reference/stage_10/epic_completion_template.md) |
| **Lessons Learned Guide** | How to extract and apply lessons | [reference/stage_10/lessons_learned_examples.md](../../reference/stage_10/lessons_learned_examples.md) |

**Key Sections:**

| Section | Description | Go To |
|---------|-------------|-------|
| Critical Rules | Must-follow cleanup rules | [Critical Rules](#-critical-rules) |
| Prerequisites | What must be done first | [Prerequisites Checklist](#prerequisites-checklist) |
| Exit Criteria | All items that must be checked | [Exit Criteria](#exit-criteria) |

**Important:**
- Step 2: Test requirement is MANDATORY but conditional — check Testing Approach (A/B/C/D) in EPIC_README
- Step 9: Apply ALL lessons from ALL sources (epic + features + bugfixes + debugging + PR comments)
- User testing completed in S9 Step 6 (prerequisite for S10)

---

## Detailed Workflow

### STEP 1: Pre-Cleanup Verification

**Objective:** Verify epic is truly complete and ready for cleanup.

**Actions:**

**1a. Verify S9 Complete**

Read EPIC_README.md "Epic Progress Tracker" section and verify S9 shows ✅ COMPLETE with all sub-items checked.

**If S9 NOT complete:** STOP S10, return to S9, complete S9 fully.

**1b. Verify All Features Complete**

Check EPIC_README.md "Epic Progress Tracker" to verify ALL features show ✅ through S8.P2 (Epic Testing Update).

**1c. Verify No Pending Work**

Check epic folder for any incomplete work:
```bash
ls .shamt/epics/{epic_name}/
```

Look for:
- ❌ Any feature folders without "S8.P2 (Epic Testing Update) complete" in README.md
- ❌ Any bugfix folders without "S7 (Testing & Review) complete" in README.md
- ❌ Any folders with "IN PROGRESS" status
- ❌ Any temporary files (*.tmp, *.bak, etc.)

**If pending work found:** STOP S10, complete pending work, return when all work complete.

**1d. Read epic_lessons_learned.md**

Use Read tool to load epic_lessons_learned.md and look for "Guide Improvements Needed" sections. Document guide improvements noted for Step 9 (S10.P1).

---

### STEP 2: Run Tests Per Testing Approach

**Objective:** Verify all required tests pass before committing changes. Requirements depend on the epic's Testing Approach set at S1.

**Actions:**

**2a. Check Testing Approach**

Read EPIC_README.md and find the `Testing Approach:` field in the header.

- **Option A (smoke only):** No automated test requirement — skip to STEP 3.
- **Options C/D (unit tests):** Run unit tests per Step 2b.
- **Options B/D (integration scripts):** Run integration scripts per Step 2c.
- **Option D (both):** Run both Step 2b and Step 2c.

**2b. Run Unit Tests (Options C/D only)**

Run the complete unit test suite:
```bash
{TEST_COMMAND}
```

**Expected Output:**
```bash
Total: {N} tests
Passed: {N} ✅
Failed: 0
Skipped: 0

EXIT CODE: 0 ✅ (Safe to commit)
```

Check the exit code:
```bash
echo $?  # On Linux/Mac
echo %ERRORLEVEL%  # On Windows
```

**If exit code is NOT 0:**
- **STOP** - Do NOT commit
- Review test output for failures
- Fix failing tests (including pre-existing failures from other epics)
- Re-run: `{TEST_COMMAND}`
- Only proceed when exit code = 0

**Note:** It is ACCEPTABLE to fix pre-existing test failures during S10 to achieve 100% pass rate.

**2c. Run Integration Scripts (Options B/D only)**

Read the Integration Test Convention from EPIC_README.md and run all integration scripts for all features:

```bash
## Run each feature's integration script per the Integration Test Convention
{integration_script_run_command}
```

**Expected:** All scripts exit with code 0.

**If any script exits non-zero:**
- **STOP** - Do NOT commit
- Review script output for failures
- Fix failing assertions or implementation issues
- Rerun the script — if fix is a behavior change, notify user
- Only proceed when all scripts exit code 0

---

### STEP 2b: Investigate User-Reported Anomalies (If Applicable)

**Objective:** Verify root cause of unexpected behavior empirically.

**When to use:** User notices unexpected behavior during testing (e.g., "all items have same value")

**⚠️ CRITICAL RULE:** Do NOT assume existing code comments/warnings explain the behavior - verify empirically.

**Actions:**

1. **Create test script to verify behavior directly** against source of truth
2. **Compare expected vs actual behavior** (test current scenario vs control)
3. **Update documentation** if root cause differs from assumptions
4. **Document investigation** in epic_lessons_learned.md

Use your best judgment to investigate the root cause empirically before drawing conclusions.

---

### STEP 3: Documentation Verification

**Objective:** Verify all epic documentation is complete and accurate.

**Actions:**

**3a. Verify EPIC_README.md Complete**

Read EPIC_README.md and verify all sections present:
- 🎯 Quick Reference Card
- Agent Status
- Epic Overview
- Epic Progress Tracker
- Feature Summary
- Epic-Level Files
- Workflow Checklist

Verify:
- ✅ All sections present
- ✅ Information accurate and up-to-date
- ✅ No placeholder text (e.g., "TODO", "{fill in later}")
- ✅ Dates are correct
- ✅ Feature list matches actual features

**If incomplete:** Update missing sections, fix inaccurate information, remove placeholder text.

**3b. Verify epic_lessons_learned.md Contains Insights**

Read epic_lessons_learned.md and verify:
- ✅ Insights from ALL stages present (Stages 1-6)
- ✅ Lessons from ALL features documented
- ✅ "Guide Improvements Needed" sections present
- ✅ Cross-epic insights documented
- ✅ Recommendations actionable

**If incomplete:** Add missing stage insights, document lessons from all features, add cross-epic patterns.

**3c. Verify epic_smoke_test_plan.md Accurate**

Read epic_smoke_test_plan.md and verify:
- ✅ "Last Updated" shows recent S8.P2 (Epic Testing Update) update
- ✅ Update History table shows all features contributed
- ✅ Test scenarios reflect ACTUAL implementation
- ✅ Integration tests included (added during S8.P2 (Epic Testing Update))
- ✅ Epic success criteria still accurate

**If outdated:** Update test plan to reflect final implementation.

**3d. Verify All Feature README.md Files Complete**

For EACH feature folder, read README.md and verify:
- ✅ README.md exists
- ✅ All sections present
- ✅ Status shows "S8.P2 (Epic Testing Update) complete"
- ✅ No placeholders or TODOs
- ✅ Workflow checklist all checked

**If ANY feature README incomplete:** Update incomplete README files.

**3e. Review Architecture and Coding Standards Documents**

**Purpose:** Ensure epic-level changes are reflected in project documentation.

**Process:**

1. **Review ARCHITECTURE.md:**
   - Read the current document
   - Compare against changes made in this epic
   - Check: Are all new components/modules documented?
   - Check: Are data flows still accurate?
   - Check: Are integration patterns current?

2. **Review CODING_STANDARDS.md:**
   - Read the current document
   - Consider patterns established across all features
   - Check: Are new conventions documented?
   - Check: Do documented conventions match what we actually did?

3. **Cross-Feature Pattern Check:**
   - Did multiple features establish the same pattern? -> Document it
   - Did we make consistent decisions about similar problems? -> Document them
   - Did we deviate from documented conventions? -> Either fix code or update doc

4. **Document Review Results:**

```markdown
## Architecture/Standards Review (S10)

**Review Date:** {YYYY-MM-DD}

### ARCHITECTURE.md
- [ ] Reviewed and current - no updates needed
- [ ] Updated: {list changes made}
- [ ] Issues noted for future: {list}

### CODING_STANDARDS.md
- [ ] Reviewed and current - no updates needed
- [ ] Updated: {list changes made}
- [ ] Issues noted for future: {list}

### Cross-Feature Patterns Documented
- {Pattern 1}: Added to {file}
- {Pattern 2}: Added to {file}
- None identified
```

---

### STEP 4: Final Commit (Epic Implementation)

**Objective:** Commit all epic implementation work (code changes, tests, documentation) with clear, descriptive message. This is the main epic commit - epic folder move and .shamt/epics/EPIC_TRACKER.md update will be separate commits in Steps 6-7.

**Actions:**

**5a. Review All Changes**

Check git status and diff:
```bash
git status
git diff {modified_files}
```

Verify:
- ✅ All changes related to epic
- ✅ No unrelated changes included
- ✅ No debugging code left in (e.g., print statements)
- ✅ No commented-out code
- ✅ No sensitive data (API keys, passwords, etc.)
- ✅ EPIC_METRICS.md exists and is updated through S9 (Stage Timing table filled in, Validation Loop Summary reflects actual loop data)

**5b. Stage All Epic Changes**

Add all epic-related changes:
```bash
## Stage modified files
git add {file1} {file2} {file3}

## Stage epic folder (all files)
git add .shamt/epics/{epic_name}/
```

**5c. Create Commit with Clear Message**

**Commit Message Format:**
```text
{commit_type}/SHAMT-{number}: Complete {epic_name} epic

Major features:
- {Feature 1 brief description}
- {Feature 2 brief description}

Key changes:
- {File 1}: {What changed and why}
- {File 2}: {What changed and why}

Testing:
- All unit tests passing ({N}/{N})
- Epic smoke testing passed
- Epic QC Validation Loop passed (primary clean round + sub-agent confirmation)
```

**Where:**
- `{commit_type}` = `feat` (feature epic) or `fix` (bug fix epic)
- `{number}` = SHAMT number from .shamt/epics/EPIC_TRACKER.md and branch name
- Message limit: 100 chars or less for first line

**Detailed Examples:** See `reference/stage_10/commit_message_examples.md` for complete examples, anti-patterns, and variations.

**Create commit using HEREDOC** (ensures proper formatting):
```bash
git commit -m "$(cat <<'EOF'
feat/SHAMT-{N}: Complete {epic_name} epic

{content following format above}
EOF
)"
```

**5d. Verify Commit Successful**

Check git log:
```bash
git log -1 --stat
```

Verify commit message clear, all epic files included, file change counts reasonable.

**Note:** Do NOT push yet - Steps 6-7 will create additional commits (epic folder move, .shamt/epics/EPIC_TRACKER.md update) that should all be part of the same PR.

---

### STEP 5: Move Epic to done/ Folder

**Objective:** Move completed epic folder to done/ for archival.

**Actions:**

**6a. Create done/ Folder (If Doesn't Exist)**

Check if done/ folder exists:
```bash
ls .shamt/epics/
```

If done/ doesn't exist:
```bash
mkdir .shamt/epics/done
```

**6b. Clean Up done/ Folder (Max 10 Epics)**

**Purpose:** Maintain a maximum of 10 archived epics in done/ folder by deleting oldest epics when needed.

**Check current epic count:**
```bash
## Count epic directories in done/
ls -d .shamt/epics/done/*/ | wc -l
```

**If count is 10 or more:**

1. **List epics by date (oldest first):**
   ```bash
   # Windows (PowerShell)
   Get-ChildItem .shamt/epics\done -Directory | Sort-Object LastWriteTime | Select-Object Name, LastWriteTime

   # Linux/Mac
   ls -lt .shamt/epics/done/ | tail -n +2
   ```

2. **Calculate how many to delete:**
   - Current count: {N}
   - Will add: 1 (current epic)
   - Total: {N+1}
   - Need to delete: {N+1-10} oldest epics

3. **Delete oldest epic(s):**
   ```bash
   # Windows
   rmdir /s /q .shamt/epics\done\{oldest_epic_name}

   # Linux/Mac
   rm -rf .shamt/epics/done/{oldest_epic_name}
   ```

4. **Repeat for each epic that needs deletion**

5. **Verify count after deletion:**
   ```bash
   ls -d .shamt/epics/done/*/ | wc -l
   ```

   **Expected:** 9 or fewer (leaving room for current epic)

**If count is less than 10:**
- No deletion needed
- Proceed to next step

**⚠️ IMPORTANT:**
- Always keep the 10 MOST RECENT epics
- Delete the OLDEST epics first
- After deletion, done/ should have 9 or fewer epics (before adding current)
- This keeps the repository size manageable
- Older epics are preserved in git history if needed

**6c. Move Entire Epic Folder to done/**

Move the complete epic folder (with SHAMT number) using **`git mv`** (not shell `mv`):

```bash
git mv .shamt/epics/SHAMT-{N}-{epic_name} .shamt/epics/done/SHAMT-{N}-{epic_name}
```

**Example:** `git mv .shamt/epics/SHAMT-11-game_data_fetcher_cli .shamt/epics/done/SHAMT-11-game_data_fetcher_cli`

**⚠️ CRITICAL: Use `git mv`, NOT shell `mv`.**
Shell `mv` moves the files on disk but leaves the old paths as unstaged deletions in git. `git mv` stages both the deletion (old location) and the addition (new location) atomically, so the commit in Step 6g captures the complete move.

Using shell `mv` + `git add done/{epic}/` only stages the new files — the old files remain as uncommitted deletions, polluting `git status` and requiring a separate cleanup commit.

**6d. Verify Move Successful**

Check folder structure:
```bash
ls .shamt/epics/done/SHAMT-{N}-{epic_name}/
```

**Example:** `ls .shamt/epics/done/SHAMT-1-improve_recommendation_engine/`

**Expected:**
```text
EPIC_README.md
epic_smoke_test_plan.md
epic_lessons_learned.md
feature_01_{name}/
feature_02_{name}/
feature_03_{name}/
bugfix_{priority}_{name}/  (if bug fixes existed)
```

Verify:
- ✅ All features present
- ✅ All epic-level files present
- ✅ All bug fix folders present (if any)
- ✅ No files left behind in original location

**6e. Verify done/ Folder Count**

Check total epics in done/:
```bash
ls -d .shamt/epics/done/*/ | wc -l
```

**Expected:** 10 or fewer

**If count exceeds 10:**
- Review what was deleted in Step S9.P2
- Verify correct epics were removed
- Ensure only most recent 10 epics remain

**6f. Leave Original Epic Request in Requests Folder**

**IMPORTANT:** Do NOT move the request file from `.shamt/epics/requests/`.

**Why:** The request file lives in `.shamt/epics/requests/` (in its subfolder) and is not part of the epic folder. When the epic folder moves to `done/`, the request file stays in `.shamt/epics/requests/` permanently for reference.

**6g. Commit the Epic Folder Move**

Commit the folder move (`git mv` already staged everything in Step 6c):
```bash
git commit -m "chore/SHAMT-{N}: Move completed epic to done/ folder

Epic SHAMT-{N} ({epic_name}) is complete:
- All {N} features implemented and tested
- {X}/{X} tests passing
- Epic moved to done/ for clean PR state

No further changes needed after merge.

"
```

Verify commit successful:
```bash
git log -1 --oneline
```

---

### STEP 6: Update .shamt/epics/EPIC_TRACKER.md

**Objective:** Update .shamt/epics/EPIC_TRACKER.md to move epic from Active to Completed and add detailed epic information.

**Actions:**

**7a. Move Epic from Active to Completed Table**

Edit `.shamt/epics/EPIC_TRACKER.md`:

1. Remove the epic's row from the "Active Epics" table
2. Add the epic's row to the "Completed Epics" table with completion date and done/ location

**7b. Add Epic Detail Section**

Add a detailed section below "## Epic Details" with complete epic information (see Epic Detail Template in .shamt/epics/EPIC_TRACKER.md or SHAMT-6/SHAMT-8 examples for format):

Required information:
- Type, branch, dates, location
- Description (1-2 paragraphs)
- Features implemented (list)
- Key changes (bullet points)
- Commit history (hashes + messages)
- Testing results (test counts, smoke testing, QC rounds, user testing)
- Lessons learned (summary + link to epic_lessons_learned.md)
- Related documentation (links)

**7c. Increment Next Available Number**

Update "Next Available Number" field to SHAMT-{N+1}

**7d. Commit the .shamt/epics/EPIC_TRACKER.md Update**

Stage and commit:
```bash
git add .shamt/epics/EPIC_TRACKER.md
git commit -m "chore/SHAMT-{N}: Update EPIC_TRACKER with completed epic

Move SHAMT-{N} from Active to Completed:
- {brief epic summary}
- {key achievement}
- {key achievement}

Increment Next Available Number to SHAMT-{N+1}.

"
```

Verify commit successful:
```bash
git log -1 --oneline
```

**7e. Append to .shamt/epics/PROCESS_METRICS.md**

Read EPIC_METRICS.md from the archived epic folder to compute the summary row.

If PROCESS_METRICS.md does not yet exist, create it with this header:
```markdown
| Epic | Date | Features | Total Time | S5 Avg Rounds | S7 Avg Rounds | S9 Rounds | S9P3 Restarts | Top Reset Dim |
|------|------|:--------:|:----------:|:-------------:|:-------------:|:---------:|:-------------:|---------------|
```

Append one row for this epic (extract values from EPIC_METRICS.md):
```markdown
| SHAMT-{N} | {date} | {feature count} | {total time} | {S5.P2 avg rounds} | {S7.P2 avg rounds} | {S9.P2 rounds} | {S9.P3 restart count} | {most common reset dim} |
```

Commit the update:
```bash
git add .shamt/epics/PROCESS_METRICS.md
git commit -m "chore/SHAMT-{N}: append PROCESS_METRICS row"
```

---

### STEP 7: S10.P2 — Epic Overview Document (optional)

**Objective:** Optionally create a narrative overview document for PR reviewers and developers onboarding onto the work.

**READ THE FULL GUIDE:**
```text
stages/s10/s10_p2_overview_workflow.md
```

**Process Overview:**
1. Ask the user: "Would you like to create a `SHAMT-{N}-OVERVIEW.md` for PR reviewers?" (yes / no)
2. If no: skip this step entirely, proceed to STEP 8
3. If yes: gather context (git log, git diff, epic docs), plan the narrative structure, write the document, run validation loop (2 consecutive clean rounds), commit the document

**Time Estimate:** 0 minutes (skipped) or 20-40 minutes (opted in)

**Exit Condition:** S10.P2 complete after overview doc committed (or phase skipped after user declines)

**NEXT:** After S10.P2 complete (or skipped), proceed to STEP 8 (Push and Create PR)

---

### STEP 8: Push Branch and Create Pull Request

**Objective:** Push all commits to remote and create PR for user review.

**Actions:**

**8a. Verify Working Tree Clean, Then Push**

**🛑 BEFORE pushing, verify there are zero uncommitted changes:**
```bash
git status
```

**Required output:** `nothing to commit, working tree clean`

**If ANY files are shown as modified, deleted, or untracked:**
- Stage and commit them before proceeding
- Do NOT create the PR until `git status` is clean
- A PR created while uncommitted changes exist is incomplete — the PR will be missing those changes

**Do not declare the PR ready until the working tree is clean AND all commits are pushed.**

Push all commits (epic work + folder move + EPIC_TRACKER update):
```bash
git push origin {work_type}/SHAMT-{number}
```

After pushing, verify all commits are on the remote:
```bash
git log --oneline origin/{work_type}/SHAMT-{number}..HEAD
```

**Required output:** No output (empty = all commits pushed)

**8b. Check gh CLI Availability**

Run:
```bash
gh auth status 2>&1
```

- If exit code 0 → gh is installed and authenticated. Agent creates PR directly in Step 8c.
- If exit code non-zero → gh is not available or not authenticated. Skip to Step 8c-manual.

**8c. Create Pull Request (gh available)**

Use GitHub CLI to create PR directly:
```bash
gh pr create --base main --head {work_type}/SHAMT-{number} \
  --title "{commit_type}/SHAMT-{number}: Complete {epic_name} epic" \
  --body "See EPIC_README.md for details. All tests passing, ready for review."
```

**8c-manual. Create Pull Request (gh not available)**

Provide the user with instructions to create the PR manually:
- Navigate to repository on GitHub
- Click "Pull requests" → "New pull request"
- Select base: `main`, compare: `{work_type}/SHAMT-{number}`
- Fill in title and description
- Click "Create pull request"

**8d. Recommend a Squash Commit Message**

Before the user merges, recommend a squash commit message. GitHub squash-merges collapse all branch commits into one, so the message needs to summarize the entire epic.

Provide the user with a ready-to-use message in this format:

```text
{commit_type}/SHAMT-{number}: {short epic summary}

Features implemented:
- {feature_01 summary}
- {feature_02 summary}
- ...

Key changes:
- {notable technical change 1}
- {notable technical change 2}
- ...

Testing: {test count} tests passing. {any notable test highlights}
```

**Example output to user:**
> Here's a recommended squash commit message for the PR:
> ```
> feat/SHAMT-10: Refactor data_exporter — CLI args, DI, E2E mode
>
> Features implemented:
> - F01: Replace hardcoded paths with argparse CLI args
> - F01: Replace subprocess calls with direct imports
> - F01: Add --e2e-test mode writing to /tmp
>
> Key changes:
> - Eliminated hardcoded config dependency
> - DataExporter now accepts injected config object
> - E2E test mode writes to /tmp to avoid contaminating data/
>
> Testing: {N} tests passing. Full E2E run validated.
> ```

**8e. Wait for User to Merge PR**

- User reviews changes in GitHub UI
- User approves and merges using the recommended squash message (or their own)
- **DO NOT merge yourself** - user must merge

**8f. Sync Local Main After Merge**

After user confirms the PR is merged, sync local main:
```bash
git checkout main
git fetch origin
git reset --hard origin/main
```

**Important:** The PR includes all committed work so far (epic work, folder move, EPIC_TRACKER update). After the PR is merged, proceed to Step 8.5 (PR Comment Resolution, user-triggered) and then Step 9 (S10.P1 guide updates).

**See:** `reference/GIT_WORKFLOW.md` for PR creation details and templates

---

### STEP 8.5: PR Comment Resolution (User-Triggered)

**Objective:** Fetch PR review comments and create structured comment resolution files for systematic resolution.

**When to Execute:**
- User directs the agent to process PR comments (e.g., "get the PR comments and resolve them")
- PR has been reviewed and has comments to address

**Skip This Step If:**
- User does not request comment processing
- PR has no review comments

**Actions:**

**8.5a. Fetch PR Comments**

Retrieve all review comments from the PR:
```bash
# Get PR number from current branch
PR_NUMBER=$(gh pr view --json number -q '.number')

# Fetch all review comments
gh api repos/{owner}/{repo}/pulls/${PR_NUMBER}/comments
```

**8.5b. Create Comment Resolution File**

Create a comment resolution file using the template:
```bash
cp .shamt/guides/templates/comment_resolution_template.md \
   .shamt/epics/{epic_name}/pr_comment_resolution.md
```

Fill in the header fields (PR number, date, total comments) and create one entry per comment.

**File location:**
```text
.shamt/epics/{epic_name}/pr_comment_resolution.md
```

**8.5c. Work Through Resolutions**

For each comment:
1. Read the comment and understand what the reviewer is asking
2. Determine the appropriate resolution (fix code, explain, discuss with user)
3. If code change needed: make the change, commit, update the resolution entry with commit hash
4. If clarification needed: ask the user
5. If won't fix: document rationale in the resolution entry

**8.5d. Update Resolution Summary**

After all comments are processed, update the header:
```markdown
**Resolved:** {N}/{N}
```

Push any new commits:
```bash
git push origin {work_type}/SHAMT-{number}
```

**Time Estimate:** 0 minutes (skipped) or 15-30 minutes (triggered, depending on comment count)

**Exit Condition:** All comments resolved (or documented as Won't Fix / Discussed), resolution file committed

**NEXT:** Proceed to STEP 9 (S10.P1 — Guide Update from Lessons Learned)

---

### STEP 9: Guide Update from Lessons Learned (🚨 MANDATORY - S10.P1)

**Objective:** Capture lessons learned from epic (and PR comment insights if available) in a guide update proposal doc, deferred to master for implementation.

**⚠️ CRITICAL:** This is NOT optional. Every epic must run S10.P1 to continuously improve guides.

**READ THE FULL GUIDE:**
```text
stages/s10/s10_p1_guide_update_workflow.md
```

**Process Overview:**
1. Analyze all lessons_learned.md files (epic + all features)
2. Read pr_comment_resolution.md if it exists — extract guide improvement insights
3. Create GUIDE_UPDATE_PROPOSAL.md with prioritized proposals (P0-P3)
4. Present each proposal to user for individual approval
5. Create proposal doc in `.shamt/unimplemented_design_proposals/` and commit it
6. Update guide_update_tracking.md

**Time Estimate:** 20-45 minutes

**Exit Condition:** S10.P1 complete (verify guide_update_tracking.md updated and proposal doc created, if any proposals accepted)

**NEXT:** After S10.P1 complete, proceed to STEP 10 (Final Verification)

---

### STEP 10: Final Verification & Completion

**Objective:** Verify epic cleanup complete and celebrate completion!

**Actions:**

**10a. Verify All Commits Pushed**

Check that all commits are on remote:
```bash
git log --oneline origin/{work_type}/SHAMT-{number}..HEAD
```

**Expected:** No output (all commits pushed)

**10b. Verify PR Created**

If using `gh` CLI:
```bash
gh pr view
```

Or check GitHub web UI to confirm PR exists.

**10c. Verify Git Working Tree Clean**

Check git status:
```bash
git status
```

**Expected:** "Your branch is up to date with 'origin/{work_type}/SHAMT-{number}'", "nothing to commit, working tree clean"

**10d. Celebrate Epic Completion! 🎉**

The epic is now complete and ready for user review!

**What was accomplished:**
- ✅ Epic planned with {N} features
- ✅ All features implemented and tested
- ✅ Epic-level integration validated
- ✅ All validation loops passed
- ✅ Documentation complete
- ✅ Changes committed to git
- ✅ Epic archived in done/ folder

---

## Re-Reading Checkpoints

**You MUST re-read this guide when:**

1. **After Session Compaction** - Check EPIC_README.md Agent Status to see which step you're on
2. **After Test Failures** - Re-read after fixing tests
3. **After Commit Failures** - Re-read commit requirements
4. **Before Moving Epic** - Re-read move instructions
5. **When Encountering Confusion** - Re-read workflow overview and current step

**Re-Reading Protocol:**
1. Use Read tool to load ENTIRE guide
2. Find current step in EPIC_README.md Agent Status
3. Read "Workflow Overview" section
4. Read current step's detailed workflow
5. Proceed with renewed understanding

---

## Exit Criteria

**S10 is COMPLETE when ALL of the following are true:**

### Tests (Conditional per Testing Approach)
- [ ] Testing Approach confirmed from EPIC_README (A/B/C/D)
- [ ] **Option A:** No automated test requirement (gate skipped)
- [ ] **Options C/D:** All unit tests executed (`{TEST_COMMAND}`); exit code = 0; no failures or skips
- [ ] **Options B/D:** All integration scripts executed; all exit code 0

### Documentation
- [ ] EPIC_README.md complete and accurate
- [ ] epic_lessons_learned.md contains insights from all stages
- [ ] epic_smoke_test_plan.md reflects final implementation
- [ ] All feature README.md files complete

### PR Comment Resolution (Step 8.5 — Optional)
- [ ] If user requested comment processing: pr_comment_resolution.md created and committed
- [ ] If step skipped: documented that no PR comments were requested for processing

### Guide Updates (Step 9 — S10.P1)
- [ ] Found ALL lessons_learned.md files (systematic search)
- [ ] Read ALL files (epic + features + bugfixes + debugging)
- [ ] pr_comment_resolution.md analyzed (or confirmed absent)
- [ ] Created master checklist of ALL lessons + PR comment insights
- [ ] S10.P1 ran (proposal doc created and committed, or zero proposals noted)
- [ ] guide_update_tracking.md updated

### S9 Completion (Including User Testing)
- [ ] User tested complete system (S9 Step 6)
- [ ] User testing result: ZERO bugs found
- [ ] If bugs found: All fixed, restart S9 from S9.P1 (smoke testing), user re-tested
- [ ] Epic PR review passed (all categories)

### Git Commits
- [ ] All epic changes reviewed with git status and git diff
- [ ] Epic implementation commit created with clear message
- [ ] Commit successful (verified with git log)

### Epic Move
- [ ] done/ folder exists
- [ ] done/ folder cleaned up (max 10 epics maintained)
- [ ] Entire epic folder moved to done/
- [ ] Epic folder structure intact in done/
- [ ] Epic folder move committed

### .shamt/epics/EPIC_TRACKER.md Update
- [ ] Epic moved from Active to Completed table in .shamt/epics/EPIC_TRACKER.md
- [ ] Epic detail section added with full description
- [ ] Next Available Number incremented
- [ ] .shamt/epics/EPIC_TRACKER.md update committed
- [ ] .shamt/epics/PROCESS_METRICS.md updated with summary row for this epic and committed

### S10.P2 — Epic Overview Document (Step 7, Optional)

This phase is opt-in — the question must always be asked, but creating the document is not mandatory.

- [ ] User asked about `SHAMT-{N}-OVERVIEW.md` (yes or no)
- [ ] If opted in: `SHAMT-{N}-OVERVIEW.md` committed as standalone commit (`docs/SHAMT-{N}: Add epic overview document`)
- [ ] If declined: no file created; proceeded directly to Push and Create PR

### Pull Request (Step 8)
- [ ] gh CLI availability checked (`gh auth status`)
- [ ] All commits pushed to remote branch
- [ ] Pull Request created (agent via gh, or user via manual instructions)
- [ ] PR includes all final cleanup (epic work + folder move + EPIC_TRACKER)
- [ ] Squash commit message recommended to user
- [ ] User reviewed and merged PR
- [ ] Local main synced after merge (git fetch origin && git reset --hard origin/main)

### Final Verification
- [ ] Epic visible in done/ folder
- [ ] Original request accessible in root
- [ ] Git status clean
- [ ] EPIC_README.md updated with completion status

**Epic is COMPLETE when ALL completion criteria are met.**

---

## Summary

**S10 - Epic Cleanup finalizes the epic and archives it for future reference:**

**Key Activities:**
1. Run tests per Testing Approach (unit tests for C/D; integration scripts for B/D; none for A)
2. Verify all documentation complete
3. Commit epic implementation work with clear message
4. Move entire epic folder to done/ (max 10 epics, delete oldest if needed) and commit
5. Update .shamt/epics/EPIC_TRACKER.md (move to Completed, add details, increment number) and commit; append summary row to PROCESS_METRICS.md and commit
6. Run S10.P2 — ask user about epic overview document; if yes, create `SHAMT-{N}-OVERVIEW.md` at repository root and commit it (optional)
7. Check gh CLI availability, push branch, create Pull Request (agent via gh or user manual), recommend squash commit message, wait for merge, sync local main
8. Step 8.5 (user-triggered): Fetch PR comments, create pr_comment_resolution.md, work through resolutions, push new commits
9. Run S10.P1 — read all lessons + PR comment analysis, create guide update proposal doc (user-approved), commit proposal doc
10. Final verification and celebrate! 🎉

**Critical Success Factors:**
- Tests pass before committing (conditional per Testing Approach — unit tests for C/D, integration scripts for B/D, nothing for A)
- Complete documentation (README, lessons learned, test plan)
- ALL lessons applied (epic + features + bugfixes + debugging)
- User testing already passed in S9.P3 (prerequisite)
- Clear, descriptive commit messages (separate commits for epic work, folder move, EPIC_TRACKER)
- Entire epic folder moved to done/ (not individual features)
- Max 10 epics in done/ folder maintained
- .shamt/epics/EPIC_TRACKER.md updated BEFORE creating PR
- PR includes all final cleanup (no post-merge changes needed)

**Common Pitfalls:**
- Committing without running required tests (check Testing Approach first — Option A requires none; C/D need unit tests; B/D need integration scripts)
- Generic commit messages
- Only checking epic_lessons_learned.md (missing feature/bugfix/debugging lessons)
- Forgetting debugging lessons (highest priority guide updates)
  - **Why critical:** Debugging lessons from Phase 4b have highest P0/P1 priority
  - **Where to find:** {epic}/debugging/guide_update_recommendations.md
  - **What to look for:** Per-issue root causes (Phase 4b) + cross-pattern analysis (Phase 5)
  - **Application:** Debugging lessons should be applied FIRST (before general lessons)
- Moving features individually instead of entire epic
- Moving original request file (should stay in root)
- Exceeding 10 epics in done/ folder
- Writing the S10.P2 overview before planning the narrative structure — this produces a disorganized document that doesn't serve reviewers
- Skipping S10.P2 without asking the user — the phase is opt-in, but the question must always be asked

**Reference Files:**
- `reference/stage_10/commit_message_examples.md` - Commit message format and examples
- `reference/stage_10/epic_completion_template.md` - EPIC_README.md completion template
- `reference/stage_10/lessons_learned_examples.md` - Lesson extraction and application guide

---

## Next Stage

**🎉 EPIC COMPLETE - No Next Stage**

You've successfully completed all 10 stages of the epic workflow:
- ✅ S1: Epic Planning (Discovery, breakdown, Git setup)
- ✅ S2: Feature Deep Dives (spec.md, checklist.md for each feature)
- ✅ S3: Epic-Level Docs, Tests, and Approval (Gate 4.5)
- ✅ S4: (Deprecated — Test Scope Decision moved to S5 Step 0)
- ✅ S5-S8: Feature Loop (Planning → Execution → Testing → Alignment)
- ✅ S9: Epic-Level Final QC (100% test pass, user testing)
- ✅ S10: Epic Cleanup (guide updates, PR, archival)

**The epic is now:**
- Production-ready code (100% test pass rate)
- Fully documented (README, lessons learned)
- Properly archived (`.shamt/epics/done/`)
- Integrated into main branch (PR merged)

**Next Steps:**
1. Update EPIC_README.md Agent Status to "EPIC_COMPLETE" with timestamp
2. Document final status: "Epic [name] is complete and archived in .shamt/epics/done/"
3. Notify user: "Epic complete. All work committed and merged to main."

**No further stages exist for this epic. S10 is the final stage.**

**Well done!**

---

*End of s10_epic_cleanup.md*
