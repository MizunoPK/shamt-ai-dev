# STAGE 10: Final Changes & Merge — Quick Reference Card

**Purpose:** One-page summary for finalizing the feature branch and getting it merged
**Use Case:** Quick lookup when doing final docs verification, committing, creating the PR, and verifying the merge
**Total Time:** 25-50 minutes (S10.P1 skipped) or 45-90 minutes (S10.P1 opted in)
**Note:** Tests were validated in S9 QC — no re-run needed in S10

---

## Workflow Overview

```text
STEP 1: Documentation Verification (10 min)
    ├─ Verify EPIC_README.md complete
    ├─ Verify epic_lessons_learned.md contains insights
    ├─ Verify epic_smoke_test_plan.md accurate
    ├─ Verify all feature README.md files complete
    └─ Review Architecture and Coding Standards docs
    ↓
STEP 2: Final Commit — Epic Implementation (10 min)
    ├─ Review changes (git status, git diff)
    ├─ Stage all epic-related changes
    └─ Create commit: "{commit_type}/SHAMT-{number}: {message}"
    ↓
STEP 3: S10.P1 — Epic Overview Document (0 or 20-40 min, optional)
    ├─ Ask user: create SHAMT-{N}-OVERVIEW.md? (yes / no)
    ├─ If no: skip to STEP 4
    ├─ Gather context, plan narrative, write document
    ├─ Run validation loop (primary clean round + sub-agent confirmation)
    └─ Commit overview document
    ↓
STEP 4: Push Branch and Create Pull Request (5 min + wait) ← MERGE VERIFICATION GATE
    ├─ Verify working tree clean, then push all commits
    ├─ Check gh auth status → agent creates PR if available, else manual instructions
    ├─ Recommend squash commit message to user
    ├─ Wait for user to signal merge
    ├─ On signal: git checkout main; git fetch; git reset --hard origin/main
    └─ Verify feature branch commits in git log → hand off to S11
    ↓
STEP 5: PR Comment Resolution (0 or 15-30 min, user-triggered, runs pre-merge)
    ├─ User requests comment processing → fetch via gh API
    ├─ Create pr_comment_resolution.md in epic folder
    ├─ Work through each comment (fix / discuss / won't fix)
    └─ Push any new commits
```

---

## Step Summary Table

| Step | Duration | Key Activities | Mandatory Gate? |
|------|----------|----------------|-----------------|
| 1 | 10 min | Documentation verification | No |
| 2 | 10 min | Final commit (epic implementation) | No |
| 3 | 0-40 min | S10.P1 — Epic overview document (opt-in) | No |
| 4 | 5 min + wait | Push, create PR, wait for merge, verify, hand off to S11 | ✅ YES (merge verify) |
| 5 | 0-30 min | PR comment resolution (user-triggered, pre-merge) | No |

---

## Mandatory Gate

### Merge Verification (Step 4)
**What it checks:** After user signals merge, agent checks out main and verifies feature branch commits appear in `git log`
**Pass Criteria:** At least one feature branch commit visible in `git log --oneline -10`
**If FAIL:** Halt — report to user what `git log` shows; wait for user guidance before proceeding to S11

---

## Commit Message Format

### Required Format:
```text
{commit_type}/SHAMT-{number}: {message}

{body}
```

### Commit Type:
- `feat` — Feature work (most epic commits)
- `fix` — Bug fix work

### Example:
```text
feat/SHAMT-1: Add JSON export format and configurable output paths

Major features:
- Add JSON export alongside existing CSV export
- Support configurable output directory via CLI arg

Key changes:
- data_exporter.py: Add JSON serialization support
- output_manager.py: Add configurable path handling

Testing:
- Epic smoke testing passed
- Epic QC Validation Loop passed
```

---

## Git Workflow (Steps 2–4)

### Step 2: Epic Implementation Commit
```bash
git status       # Review all modified files
git diff         # Review all changes
git add .shamt/epics/SHAMT-{N}-{epic_name}/
git add <any other changed files>
git commit -m "{commit_type}/SHAMT-{number}: {message}"
```

### Step 4: Push and Create PR
```bash
git status       # Verify working tree clean
git push origin {work_type}/SHAMT-{number}
gh auth status 2>&1  # Check gh CLI availability
# If gh available:
gh pr create --base main --head {work_type}/SHAMT-{number} \
  --title "{commit_type}/{N}: Complete {epic_name} epic" \
  --body "..."
# Recommend squash commit message, wait for merge signal
# On signal:
git checkout main && git fetch origin && git reset --hard origin/main
git log --oneline -10  # Verify merge
```

---

## Critical Rules Summary

- ✅ Documentation verified before committing (Step 1)
- ✅ Working tree must be clean before pushing (git status)
- ✅ Create PR — do not just push and leave
- ✅ Wait for user to signal merge; verify before handing off to S11
- ✅ Step 5 (PR comment resolution) runs BEFORE merge, not after
- ✅ S10 ends when main is verified; S11 begins from there

---

## Common Pitfalls

### ❌ Pushing without clean working tree
**Solution:** Always run `git status` and commit any remaining changes before pushing

### ❌ Skipping S10.P1 without asking user
**Solution:** The question must always be asked — S10.P1 is opt-in but the question is mandatory

### ❌ Writing overview doc without planning narrative structure first
**Solution:** Complete Step 3 narrative planning in s10_p1_overview_workflow.md before writing a single section

### ❌ Proceeding to S11 without verifying the merge
**Solution:** git checkout main → git reset --hard origin/main → git log to confirm

---

## Quick Checklist: "Am I Ready for Next Step?"

**Before Step 1:**
- [ ] S9 complete (EPIC_README.md shows ✅)
- [ ] No pending features or bug fixes

**Step 1 → Step 2:**
- [ ] EPIC_README.md verified complete
- [ ] epic_lessons_learned.md verified complete
- [ ] epic_smoke_test_plan.md verified accurate
- [ ] All feature README.md files verified complete
- [ ] Architecture and Coding Standards reviewed

**Step 2 → Step 3:**
- [ ] git status and git diff reviewed
- [ ] All epic-related changes staged
- [ ] Epic implementation commit created with clear message
- [ ] Commit verified (git log)

**Step 3 → Step 4:**
- [ ] User asked about creating epic overview document (yes or no)
- [ ] If opted in: `SHAMT-{N}-OVERVIEW.md` committed at repository root
- [ ] If declined: no file created

**Step 4 → S11:**
- [ ] Working tree clean (git status)
- [ ] All commits pushed to remote branch
- [ ] Pull Request created
- [ ] Squash commit message recommended to user
- [ ] User signaled PR is merged
- [ ] git checkout main && git reset --hard origin/main completed
- [ ] Merge verified via git log
- [ ] Step 5: If user requested comment processing → pr_comment_resolution.md created and completed
- [ ] Ready to proceed to S11

---

## File Outputs

**Step 2:**
- Git commit (epic implementation work)

**Step 3 (if opted in):**
- `SHAMT-{N}-OVERVIEW.md` at repository root
- Git commit (overview document)

**Step 4:**
- Remote branch with all commits pushed
- Pull Request created and merged by user

**Step 5 (if triggered):**
- `.shamt/epics/{epic_name}/pr_comment_resolution.md`
- Git commit(s) for any code fixes from comment resolution

---

## When to Use Which Guide

| Current Activity | Guide to Read |
|------------------|---------------|
| Starting S10 | `stages/s10/s10_epic_cleanup.md` |
| Epic overview document | `stages/s10/s10_p1_overview_workflow.md` |
| Commit message format | `reference/stage_10/commit_message_examples.md` |
| Epic completion format | `reference/stage_10/epic_completion_template.md` |
| After merge | `stages/s11/s11_shamt_finalization.md` |

---

## Next Stage

**S11: Shamt Finalization**
After merge is verified: `stages/s11/s11_shamt_finalization.md`

---

**Last Updated:** 2026-04-09
