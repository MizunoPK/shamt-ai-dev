# S10: Final Changes & Merge

**Guide Version:** 3.0
**Last Updated:** 2026-04-09
**Prerequisites:** S9 complete (Epic Final QC passed, user testing passed with ZERO bugs)
**Next Stage:** S11 (Shamt Finalization) — begins after PR is merged

---

## Table of Contents

1. [MANDATORY READING PROTOCOL](#-mandatory-reading-protocol)
2. [Overview](#overview)
3. [Critical Rules](#-critical-rules)
4. [Prerequisites Checklist](#prerequisites-checklist)
5. [Workflow Overview](#workflow-overview)
6. [Quick Navigation](#quick-navigation)
7. [Detailed Workflow](#detailed-workflow)
8. [Exit Criteria](#exit-criteria)
9. [Summary](#summary)

---

## 🚨 MANDATORY READING PROTOCOL

**BEFORE starting S10 — including when resuming a prior session — you MUST:**

1. **Quick entry point:** `reference/stage_10/stage_10_reference_card.md` — covers the full S10 workflow
2. **Full guide (this file):** Read entirely for detailed step instructions or when encountering edge cases
3. **Acknowledge critical requirements** by listing them explicitly
4. **Verify ALL prerequisites** using the checklist below
5. **THEN AND ONLY THEN** begin S10

**Rationale:** S10 is the final stage before the PR lands on main. This stage ensures:
- All documentation is complete and accurate
- The final commit is clean and well-described
- The PR is created with all relevant commits
- The feature branch is verified merged before handing off to S11

Rushing this process results in incomplete documentation, missing commits, or a poorly described PR.

---

## 🚫 FORBIDDEN SHORTCUTS

You CANNOT:
- Skip documentation verification because "docs were updated during S5-S9" — verify them explicitly in Step 1
- Push without confirming the working tree is clean — an incomplete PR is worse than a delayed one
- Proceed to S11 without first verifying the merge — check out main/master and confirm the branch commits appear in git log

If you are about to do any of the above: STOP and re-read the relevant section.

---

## Overview

**What is S10?**
S10 finalizes the feature branch: it verifies documentation, creates the final commit, optionally creates an epic overview document, pushes, creates the PR, and waits for the user to signal that the branch has been merged. Once the merge is verified, S10 hands off to S11 (Shamt Finalization).

**When do you use this guide?**
- After S9 (Epic Final QC) is complete
- All features implemented and validated
- User testing passed (S9.P3 — zero bugs)

**Key Outputs:**
- ✅ Documentation verified complete (README, lessons learned, etc.)
- ✅ Final commit created
- ✅ PR created and merged by user
- ✅ main/master verified up to date; ready to proceed to S11

**Phase Structure:**
- **S10.P1 (Epic Overview):** OPTIONAL — user decides whether to create narrative overview document (Step 3)
- **Step 5 (PR Comment Resolution):** OPTIONAL — user-triggered; runs before merge if reviewer feedback arrives

**Time Estimate:**
25-50 minutes (S10.P1 skipped) or 45-90 minutes (S10.P1 opted in)

**Model Selection for Token Optimization (SHAMT-27):**

S10 can save 15-25% tokens through delegation:

```text
Primary Agent (Opus):
├─ Spawn Sonnet → Read documentation for completeness checks
├─ Primary handles → Commit message writing, decision-making
└─ Primary executes → Git operations, final verification
```

**See:** `reference/model_selection.md` for Task tool examples.

---

## 🛑 Critical Rules

```text
┌─────────────────────────────────────────────────────────────────┐
│ CRITICAL RULES FOR STAGE 10                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ 1. ⚠️ VERIFY ALL DOCUMENTATION COMPLETE (Step 1)                │
│    - EPIC_README.md complete and accurate                       │
│    - epic_lessons_learned.md contains insights                  │
│    - All feature README.md files complete                       │
│                                                                  │
│ 2. ⚠️ COMMIT MESSAGE MUST USE CORRECT FORMAT (Step 2)           │
│    - Format: "{commit_type}/SHAMT-{number}: {message}"          │
│    - commit_type is "feat" or "fix"                             │
│    - Message: 100 chars or less for first line                  │
│    - Body: List major features and changes                      │
│                                                                  │
│ 3. ⚠️ VERIFY CLEAN WORKING TREE BEFORE PUSHING (Step 4)         │
│    - git status must show "nothing to commit, working tree      │
│      clean" before pushing                                      │
│    - Do NOT push with uncommitted changes                       │
│                                                                  │
│ 4. ⚠️ CREATE PULL REQUEST — DO NOT JUST PUSH (Step 4)           │
│    - Push branch to remote: git push origin {work_type}/SHAMT-N│
│    - Create PR using gh CLI (or provide manual instructions)    │
│    - Recommend squash commit message to user                    │
│                                                                  │
│ 5. ⚠️ VERIFY MERGE BEFORE HANDING OFF TO S11 (Step 4)          │
│    - Wait for user to signal the PR has been merged             │
│    - On signal: git checkout main; git fetch origin;            │
│      git reset --hard origin/main                               │
│    - Verify: feature branch commits appear in git log           │
│    - If verification fails: halt and report to user             │
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
- [ ] User testing passed (S9.P3 — ZERO bugs reported by user)
- [ ] Epic PR review passed (all 11 categories)
- [ ] No pending issues from S9

**Note:** Tests were validated as part of S9 QC. No test re-run is needed before the S10 commit — no new code has been written since S9 passed.

### Feature Completion Status
- [ ] ALL features show "S8.P2 (Epic Testing Update) complete" in EPIC_README.md
- [ ] No features in progress
- [ ] No pending bug fixes

### Documentation Status
- [ ] EPIC_README.md exists
- [ ] epic_lessons_learned.md exists with insights from all stages
- [ ] epic_smoke_test_plan.md exists
- [ ] All feature README.md files exist

**If ANY checklist item is unchecked, STOP. Do NOT proceed to S10 until all prerequisites are met.**

---

## Workflow Overview

```text
STAGE 10: Final Changes & Merge
│
├─> STEP 1: Documentation Verification
│   ├─ Verify EPIC_README.md complete
│   ├─ Verify epic_lessons_learned.md contains insights
│   ├─ Verify epic_smoke_test_plan.md accurate
│   ├─ Verify all feature README.md files complete
│   └─ Review Architecture and Coding Standards documents
│
├─> STEP 2: Final Commit (Epic Implementation)
│   ├─ Review all changes with git status and git diff
│   ├─ Stage all epic-related changes
│   └─ Create commit with clear message
│
├─> STEP 3: S10.P1 — Epic Overview Document (optional)
│   ├─ Ask user: create SHAMT-{N}-OVERVIEW.md? (yes / no)
│   ├─ If no: skip to STEP 4
│   └─ If yes: gather context, plan narrative, write doc, validate, commit
│
├─> STEP 4: Push Branch and Create Pull Request
│   ├─ Verify working tree clean
│   ├─ Push all commits to remote
│   ├─ Create PR using gh CLI (or provide manual instructions)
│   ├─ Recommend squash commit message to user
│   ├─ Wait for user to signal merge
│   ├─ On signal: git checkout main; git fetch origin;
│   │   git reset --hard origin/main
│   └─ Verify merge via git log → hand off to S11
│
└─> STEP 5: PR Comment Resolution (User-Triggered)
    ├─ Triggered by user during PR review (before merge)
    ├─ Fetch all review comments via gh API
    ├─ Create pr_comment_resolution.md in epic folder
    ├─ Work through each comment (fix / discuss / won't fix)
    └─ Push any new commits
```

---

## Quick Navigation

| Step | Focus Area | Time | Mandatory Gate? |
|------|-----------|------|-----------------|
| **Step 1** | Documentation Verification | 10 min | No |
| **Step 2** | Final Commit (Epic Work) | 10 min | No |
| **Step 3** | S10.P1 Epic Overview Document | 0 min (skipped) / 20-40 min (opted in) | No |
| **Step 4** | Push, Create PR, Verify Merge, Hand off to S11 | 5 min + wait | ✅ YES (merge verification) |
| **Step 5** | PR Comment Resolution | 0 min (skipped) / 15-30 min (triggered) | Optional |

**Total Time:** 25-50 minutes (S10.P1 skipped) or 45-90 minutes (S10.P1 opted in)

**Reference Files:**

| Reference | Description | Location |
|-----------|-------------|----------|
| **Commit Message Examples** | Format, examples, anti-patterns | `reference/stage_10/commit_message_examples.md` |
| **Epic Completion Template** | EPIC_README completion format | `reference/stage_10/epic_completion_template.md` |

---

## Detailed Workflow

### STEP 1: Documentation Verification

**Objective:** Verify all epic documentation is complete and accurate.

**1a. Verify EPIC_README.md Complete**

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

**1b. Verify epic_lessons_learned.md Contains Insights**

Read epic_lessons_learned.md and verify:
- ✅ Insights from ALL stages present (Stages 1-6)
- ✅ Lessons from ALL features documented
- ✅ "Guide Improvements Needed" sections present
- ✅ Cross-epic insights documented
- ✅ Recommendations actionable

**If incomplete:** Add missing stage insights, document lessons from all features, add cross-epic patterns.

**1c. Verify epic_smoke_test_plan.md Accurate**

Read epic_smoke_test_plan.md and verify:
- ✅ "Last Updated" shows recent S8.P2 (Epic Testing Update) update
- ✅ Update History table shows all features contributed
- ✅ Test scenarios reflect ACTUAL implementation
- ✅ Integration tests included (added during S8.P2)
- ✅ Epic success criteria still accurate

**If outdated:** Update test plan to reflect final implementation.

**1d. Verify All Feature README.md Files Complete**

For EACH feature folder, read README.md and verify:
- ✅ README.md exists
- ✅ All sections present
- ✅ Status shows "S8.P2 (Epic Testing Update) complete"
- ✅ No placeholders or TODOs
- ✅ Workflow checklist all checked

**If ANY feature README incomplete:** Update incomplete README files.

**1e. Review Architecture and Coding Standards Documents**

**Purpose:** Ensure epic-level changes are reflected in project documentation.

1. **Review ARCHITECTURE.md:**
   - Read the current document
   - Compare against changes made in this epic
   - Check: Are all new components/modules documented?
   - Check: Are data flows still accurate?

2. **Review CODING_STANDARDS.md:**
   - Read the current document
   - Consider patterns established across all features
   - Check: Are new conventions documented?

3. **Document Review Results:**

```markdown
## Architecture/Standards Review (S10)

**Review Date:** {YYYY-MM-DD}

### ARCHITECTURE.md
- [ ] Reviewed and current - no updates needed
- [ ] Updated: {list changes made}

### CODING_STANDARDS.md
- [ ] Reviewed and current - no updates needed
- [ ] Updated: {list changes made}
```

---

### STEP 2: Final Commit (Epic Implementation)

**Objective:** Commit all epic implementation work (code changes, tests, documentation) with a clear, descriptive message.

**2a. Review All Changes**

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
- ✅ EPIC_METRICS.md exists and is updated through S9

**2b. Stage All Epic Changes**

```bash
git add {file1} {file2} {file3}
git add .shamt/epics/{epic_name}/
```

**2c. Create Commit with Clear Message**

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
- Epic smoke testing passed
- Epic QC Validation Loop passed (primary clean round + sub-agent confirmation)
```

**Create commit using HEREDOC:**
```bash
git commit -m "$(cat <<'EOF'
feat/SHAMT-{N}: Complete {epic_name} epic

{content following format above}
EOF
)"
```

**Detailed Examples:** See `reference/stage_10/commit_message_examples.md`

**2d. Verify Commit Successful**

```bash
git log -1 --stat
```

Verify commit message is clear and all epic files are included.

**Note:** Do NOT push yet — Step 3 may add an additional overview doc commit before pushing.

---

### STEP 3: S10.P1 — Epic Overview Document (optional)

**Objective:** Optionally create a narrative overview document for PR reviewers.

**READ THE FULL GUIDE:**
```text
stages/s10/s10_p1_overview_workflow.md
```

**Process Overview:**
1. Ask the user: "Would you like to create a `SHAMT-{N}-OVERVIEW.md` for PR reviewers?" (yes / no)
2. If no: skip this step entirely, proceed to STEP 4
3. If yes: gather context (git log, git diff, epic docs), plan the narrative structure, write the document, run validation loop (primary clean round + sub-agent confirmation), commit the document

**Time Estimate:** 0 minutes (skipped) or 20-40 minutes (opted in)

**Exit Condition:** S10.P1 complete after overview doc committed (or phase skipped after user declines)

**NEXT:** After S10.P1 complete (or skipped), proceed to STEP 4 (Push and Create PR)

---

### STEP 4: Push Branch and Create Pull Request

**Objective:** Push all commits to remote, create PR for user review, wait for merge signal, verify merge, and hand off to S11.

**4a. Verify Working Tree Clean, Then Push**

**🛑 BEFORE pushing, verify there are zero uncommitted changes:**
```bash
git status
```

**Required output:** `nothing to commit, working tree clean`

**If ANY files are shown as modified, deleted, or untracked:**
- Stage and commit them before proceeding
- Do NOT create the PR until `git status` is clean

Push all commits:
```bash
git push origin {work_type}/SHAMT-{number}
```

After pushing, verify all commits are on the remote:
```bash
git log --oneline origin/{work_type}/SHAMT-{number}..HEAD
```

**Required output:** No output (empty = all commits pushed)

**4b. Check gh CLI Availability**

```bash
gh auth status 2>&1
```

- If exit code 0 → gh is installed and authenticated. Agent creates PR directly in Step 4c.
- If exit code non-zero → gh is not available. Skip to Step 4c-manual.

**4c. Create Pull Request (gh available)**

```bash
gh pr create --base main --head {work_type}/SHAMT-{number} \
  --title "{commit_type}/SHAMT-{number}: Complete {epic_name} epic" \
  --body "See EPIC_README.md for details. All tests passing, ready for review."
```

**4c-manual. Create Pull Request (gh not available)**

Provide the user with instructions to create the PR manually:
- Navigate to repository on GitHub
- Click "Pull requests" → "New pull request"
- Select base: `main`, compare: `{work_type}/SHAMT-{number}`
- Fill in title and description

**4d. Recommend a Squash Commit Message**

Provide the user with a ready-to-use squash commit message:

```text
{commit_type}/SHAMT-{number}: {short epic summary}

Features implemented:
- {feature_01 summary}
- {feature_02 summary}

Key changes:
- {notable technical change 1}
- {notable technical change 2}

Testing: {test count} tests passing. {any notable test highlights}
```

**4e. Note About PR Comment Resolution**

If reviewer comments arrive before the PR is merged, the user can trigger **Step 5 (PR Comment Resolution)** at any point before merging. Step 5 is independent of the waiting period here — it runs in parallel with the wait.

**4f. Wait for User to Signal Merge**

- User reviews changes in GitHub UI
- User approves and merges using the recommended squash message (or their own)
- **DO NOT merge yourself** — user must merge
- Wait until user explicitly signals the PR has been merged

**4g. Verify Merge and Hand Off to S11**

After user signals merge:

```bash
git checkout main
git fetch origin
git reset --hard origin/main
```

Verify the feature branch commits appear in main:
```bash
git log --oneline -10
```

Confirm at least one commit from the feature branch is visible in the log.

**If verification fails** (commits not visible, unexpected state):
- HALT — do NOT proceed to S11
- Report to user: describe what `git log` shows and what was expected
- Wait for user guidance before continuing

**If verification passes:** S10 is complete. Proceed to **S11 (Shamt Finalization)**.

**See:** `reference/GIT_WORKFLOW.md` for PR creation details and templates

---

### STEP 5: PR Comment Resolution (User-Triggered)

**Objective:** Fetch PR review comments and work through structured resolutions before the PR is merged.

**When to Execute:**
- User directs the agent to process PR comments (e.g., "get the PR comments and resolve them")
- PR has been reviewed and has comments to address
- This step runs BEFORE merge — it is triggered during the waiting period in Step 4f

**Skip This Step If:**
- User does not request comment processing
- PR has no review comments

**5a. Fetch PR Comments**

```bash
PR_NUMBER=$(gh pr view --json number -q '.number')
gh api repos/{owner}/{repo}/pulls/${PR_NUMBER}/comments
```

**5b. Create Comment Resolution File**

```bash
cp .shamt/guides/templates/comment_resolution_template.md \
   .shamt/epics/{epic_name}/pr_comment_resolution.md
```

Fill in the header fields (PR number, date, total comments) and create one entry per comment.

**5c. Work Through Resolutions**

For each comment:
1. Read the comment and understand what the reviewer is asking
2. Determine the appropriate resolution (fix code, explain, discuss with user)
3. If code change needed: make the change, commit, update the resolution entry with commit hash
4. If clarification needed: ask the user
5. If won't fix: document rationale in the resolution entry

**5d. Update Resolution Summary**

After all comments are processed, update the header:
```markdown
**Resolved:** {N}/{N}
```

Push any new commits:
```bash
git push origin {work_type}/SHAMT-{number}
```

**Time Estimate:** 0 minutes (skipped) or 15-30 minutes (triggered)

**Exit Condition:** All comments resolved (or documented as Won't Fix / Discussed), resolution file committed

---

## Exit Criteria

**S10 is COMPLETE when ALL of the following are true:**

### Documentation (Step 1)
- [ ] EPIC_README.md complete and accurate
- [ ] epic_lessons_learned.md contains insights from all stages
- [ ] epic_smoke_test_plan.md reflects final implementation
- [ ] All feature README.md files complete
- [ ] Architecture and Coding Standards reviewed

### Git Commit (Step 2)
- [ ] All epic changes reviewed with git status and git diff
- [ ] Epic implementation commit created with clear message
- [ ] Commit verified with git log

### S10.P1 — Epic Overview Document (Step 3, Optional)
- [ ] User asked about `SHAMT-{N}-OVERVIEW.md` (yes or no)
- [ ] If opted in: `SHAMT-{N}-OVERVIEW.md` committed as standalone commit
- [ ] If declined: no file created; proceeded directly to Step 4

### Pull Request (Step 4)
- [ ] Working tree verified clean before pushing
- [ ] All commits pushed to remote branch
- [ ] Pull Request created (agent via gh, or user via manual instructions)
- [ ] Squash commit message recommended to user
- [ ] User signaled PR is merged
- [ ] Agent checked out main/master; git reset --hard origin/main
- [ ] Merge verified: feature branch commits visible in git log
- [ ] Ready to proceed to S11

### PR Comment Resolution (Step 5, Optional)
- [ ] If user requested comment processing: pr_comment_resolution.md created and committed
- [ ] If step skipped: documented that no PR comments were requested for processing

**S10 is COMPLETE when ALL applicable criteria above are met.**

---

## Summary

**S10 — Final Changes & Merge finalizes the feature branch and gets it into main:**

**Key Activities:**
1. Verify all documentation complete (README, lessons learned, test plan, feature READMEs)
2. Commit epic implementation work with clear message
3. S10.P1: Ask user about epic overview document; if yes, create `SHAMT-{N}-OVERVIEW.md` and commit it (optional)
4. Verify working tree clean, push branch, create PR, recommend squash commit message, wait for merge signal, verify merge via git log
5. (User-triggered, pre-merge) Step 5: Fetch PR comments, create pr_comment_resolution.md, work through resolutions, push new commits

**Critical Success Factors:**
- Documentation verified before committing (Step 1 — don't skip)
- Clean working tree before pushing (git status must be clean)
- Merge verified before handing off to S11 (git log check)
- Step 5 (PR comment resolution) runs BEFORE merge, not after

**Common Pitfalls:**
- Pushing without verifying the working tree is clean
- Skipping S10.P1 without asking the user — the phase is opt-in, but the question must always be asked
- Writing the overview doc before planning the narrative structure — produces a disorganized document
- Proceeding to S11 without verifying the merge

**Reference Files:**
- `reference/stage_10/commit_message_examples.md` — Commit message format and examples
- `reference/stage_10/epic_completion_template.md` — EPIC_README completion template
- `reference/stage_10/stage_10_reference_card.md` — Quick reference for this stage

---

## Next Stage

**S11: Shamt Finalization**

After S10 completes (merge verified, main/master up to date), proceed to:

```text
stages/s11/s11_shamt_finalization.md
```

S11 covers the Shamt-specific housekeeping that happens after the merge: guide update proposals from lessons learned, epic folder archival, EPIC_TRACKER update, and final verification.
