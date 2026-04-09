# STAGE 11: Shamt Finalization — Quick Reference Card

**Purpose:** One-page summary for post-merge Shamt housekeeping
**Use Case:** Quick lookup after PR is merged — guide updates, epic archival, tracker update, final verification
**Total Time:** 45-80 minutes (including S11.P1 guide updates)
**Prerequisite:** S10 complete — PR merged, main/master checked out and verified

---

## Workflow Overview

```text
STEP 1: S11.P1 — Guide Update from Lessons Learned (20-45 min) ← MANDATORY (runs FIRST)
    ├─ Read ALL lessons_learned.md files (epic + features)
    ├─ Read pr_comment_resolution.md if it exists
    ├─ Create GUIDE_UPDATE_PROPOSAL.md (prioritized P0-P3)
    ├─ Present EACH proposal to user (individual approval)
    ├─ Create proposal doc in .shamt/unimplemented_design_proposals/
    ├─ Commit proposal doc
    └─ Update guide_update_tracking.md
    ↓
STEP 2: Move Epic to done/ Folder (5 min)
    ├─ Create done/ folder if doesn't exist
    ├─ Clean up done/ (max 10 epics, delete oldest if needed)
    ├─ Move entire epic folder using git mv
    ├─ Verify move successful
    ├─ Leave original .txt in .shamt/epics/requests/
    └─ Commit the folder move
    ↓
STEP 3: Update .shamt/epics/EPIC_TRACKER.md (5 min)
    ├─ Move epic from Active to Completed table
    ├─ Add epic detail section
    ├─ Increment Next Available Number
    ├─ Commit the EPIC_TRACKER.md update
    └─ Append summary row to PROCESS_METRICS.md and commit
    ↓
STEP 4: Final Verification & Completion (5 min)
    ├─ Verify epic in done/ folder
    ├─ Verify original request in .shamt/epics/requests/
    ├─ Verify git status clean
    └─ Celebrate epic completion! 🎉
```

---

## Step Summary Table

| Step | Duration | Key Activities | Mandatory? |
|------|----------|----------------|------------|
| 1 | 20-45 min | S11.P1 — Guide updates + PR comment analysis | ✅ YES |
| 2 | 5 min | Move epic to done/ folder (git mv + commit) | ✅ YES |
| 3 | 5 min | Update EPIC_TRACKER.md + PROCESS_METRICS.md + commit | ✅ YES |
| 4 | 5 min | Final verification and celebration | ✅ YES |

---

## Prerequisites (Verify Before Starting)

- [ ] User signaled PR is merged
- [ ] `git checkout main` completed
- [ ] `git fetch origin && git reset --hard origin/main` completed
- [ ] Feature branch commits visible in `git log --oneline -10`

**If merge verification fails:** HALT — report to user, wait for guidance

---

## Git Workflow (Steps 2–3)

### Step 2: Move Epic Folder
```bash
git mv .shamt/epics/SHAMT-{N}-{epic_name} .shamt/epics/done/SHAMT-{N}-{epic_name}
git commit -m "chore/SHAMT-{N}: Move completed epic to done/ folder"
```

### Step 3: Update EPIC_TRACKER and PROCESS_METRICS
```bash
# Edit .shamt/epics/EPIC_TRACKER.md (move to Completed, add details, increment number)
git add .shamt/epics/EPIC_TRACKER.md
git commit -m "chore/SHAMT-{N}: Update EPIC_TRACKER with completed epic"

# Append row to PROCESS_METRICS.md
git add .shamt/epics/PROCESS_METRICS.md
git commit -m "chore/SHAMT-{N}: append PROCESS_METRICS row"
```

---

## Critical Rules Summary

- ✅ Verify merge before any S11 action (git log on main)
- ✅ Run S11.P1 FIRST — before archiving the epic folder
- ✅ Use `git mv` for epic folder move (not shell `mv`)
- ✅ Keep original request file in `.shamt/epics/requests/`
- ✅ Max 10 epics in done/ folder (delete oldest if needed)
- ✅ EPIC_TRACKER update must include full detail section, not just table row

---

## Common Pitfalls

### ❌ Starting S11 before verifying the merge
**Solution:** `git log --oneline -10` on main — confirm feature branch commits are present

### ❌ Running archival before S11.P1
**Solution:** S11.P1 runs FIRST. Lesson files are easier to find while epic folder is in its working location

### ❌ Using shell mv instead of git mv
**Solution:** `git mv` stages both sides atomically; shell `mv` leaves dangling deletions

### ❌ Only updating the EPIC_TRACKER table row (forgetting the detail section)
**Solution:** Add the full detail section (type, branch, dates, description, features, commits, testing, lessons)

---

## Quick Checklist: "Am I Ready for Next Step?"

**Before Step 1:**
- [ ] On main, merge verified via git log
- [ ] epic_lessons_learned.md accessible
- [ ] All feature lessons_learned.md files accessible

**Step 1 → Step 2:**
- [ ] ALL lessons_learned.md files analyzed
- [ ] pr_comment_resolution.md analyzed (or confirmed absent)
- [ ] Proposals created and individually approved by user
- [ ] Proposal doc committed (or zero proposals noted)
- [ ] guide_update_tracking.md updated

**Step 2 → Step 3:**
- [ ] done/ folder exists
- [ ] done/ has 9 or fewer epics (before adding current)
- [ ] Entire epic folder moved using git mv
- [ ] Move verified (folder structure intact in done/)
- [ ] Original .txt still in .shamt/epics/requests/
- [ ] Folder move committed

**Step 3 → Step 4:**
- [ ] Epic moved from Active to Completed in EPIC_TRACKER.md
- [ ] Epic detail section added with full description
- [ ] Next Available Number incremented
- [ ] EPIC_TRACKER.md update committed
- [ ] PROCESS_METRICS.md row appended and committed

**Step 4 → Complete:**
- [ ] Epic visible in done/ folder
- [ ] Git status clean
- [ ] EPIC COMPLETE! 🎉

---

## File Outputs

**Step 1:**
- GUIDE_UPDATE_PROPOSAL.md (in epic folder)
- Proposal doc in `.shamt/unimplemented_design_proposals/` (if proposals accepted)
- Updated `reference/guide_update_tracking.md`

**Step 2:**
- `.shamt/epics/done/SHAMT-{N}-{epic_name}/` (entire epic folder moved)
- `.shamt/epics/requests/{epic_name}.txt` (stays in place)
- Git commit (epic folder move)

**Step 3:**
- Updated `.shamt/epics/EPIC_TRACKER.md`
- Updated `.shamt/epics/PROCESS_METRICS.md`
- 2 git commits (tracker + metrics)

---

## When to Use Which Guide

| Current Activity | Guide to Read |
|------------------|---------------|
| Starting S11 | `stages/s11/s11_shamt_finalization.md` |
| Guide update proposals | `stages/s11/s11_p1_guide_update_workflow.md` |
| Lessons learned examples | `reference/stage_10/lessons_learned_examples.md` |

---

## Next Stage

**🎉 EPIC COMPLETE — No Next Stage**

---

**Last Updated:** 2026-04-09
