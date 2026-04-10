# S11: Shamt Finalization

**Guide Version:** 1.0
**Last Updated:** 2026-04-09
**Prerequisites:** S10 complete (PR merged, main/master verified up to date)
**Next Stage:** None (Epic complete)

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

**BEFORE starting S11 — including when resuming a prior session — you MUST:**

1. **Quick entry point:** `reference/stage_11/stage_11_reference_card.md` — covers the full S11 workflow
2. **Full guide (this file):** Read entirely for detailed step instructions or when encountering edge cases
3. **Verify ALL prerequisites** using the checklist below — especially merge verification
4. **THEN AND ONLY THEN** begin Shamt finalization

**Rationale:** S11 runs on main, not the feature branch. Starting S11 before the merge is verified will archive the wrong state and pollute the tracker.

---

## 🚫 FORBIDDEN SHORTCUTS

You CANNOT:
- Start S11 without verifying that the feature branch was merged (check git log on main)
- Skip S11.P1 (guide updates) — every epic must run it; it is the first step precisely so lessons are captured before archival
- Move the epic folder to done/ before S11.P1 is complete

If you are about to do any of the above: STOP and re-read the relevant section.

---

## Overview

**What is S11?**
S11 is the Shamt-specific housekeeping stage that runs after the feature branch is merged. It captures lessons learned, archives the epic, updates the tracker, and performs final verification — all operating on main.

**When do you use this guide?**
- S10 is complete: PR merged, main/master checked out and verified
- You are on main with the merged epic commits visible in git log

**Key Outputs:**
- ✅ Guide update proposals captured (S11.P1)
- ✅ Epic folder archived in `.shamt/epics/done/`
- ✅ EPIC_TRACKER.md and PROCESS_METRICS.md updated
- ✅ Final verification complete; epic closed

**Phase Structure:**
- **S11.P1 (Guide Updates):** MANDATORY — runs first, before archival

**Time Estimate:**
45-80 minutes (S11.P1 runs) or 15-30 minutes (no proposals accepted in S11.P1)

**Model Selection for Token Optimization (SHAMT-27):**

S11 can save 20-30% tokens through delegation:

```text
Primary Agent (Opus):
├─ Spawn Haiku → Run file existence checks, count epics in done/
├─ Spawn Sonnet → Read documentation for S11.P1 lessons analysis
├─ Primary handles → Guide proposals, tracker update writing, decision-making
└─ Primary executes → Git operations, file moves, final verification
```

**See:** `reference/model_selection.md` for Task tool examples.

---

## 🛑 Critical Rules

```text
┌─────────────────────────────────────────────────────────────────┐
│ CRITICAL RULES FOR STAGE 11                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ 1. ⚠️ VERIFY MERGE BEFORE STARTING (Prerequisite)               │
│    - git log on main must show feature branch commits           │
│    - If commits not visible: STOP, report to user               │
│                                                                  │
│ 2. ⚠️ RUN S11.P1 FIRST — BEFORE ARCHIVAL (Step 1)              │
│    - Guide updates must run before epic folder is moved         │
│    - Lessons are easier to analyze while epic folder is in      │
│      its working location                                       │
│                                                                  │
│ 3. ⚠️ MOVE ENTIRE EPIC FOLDER (NOT INDIVIDUAL FEATURES)         │
│    - Move: .shamt/epics/{epic}/                                 │
│    - To: .shamt/epics/done/{epic}/                              │
│    - Use git mv, not shell mv                                   │
│    - Keep original epic request (.txt) in .shamt/epics/requests/│
│                                                                  │
│ 4. ⚠️ MAINTAIN MAX 10 EPICS IN done/ FOLDER                     │
│    - Count epics in done/ before moving current epic            │
│    - If count >= 10: Delete oldest epic(s) to make room         │
│    - After move: done/ should have 10 or fewer epics            │
│                                                                  │
│ 5. ⚠️ UPDATE EPIC_TRACKER.md BEFORE FINAL VERIFICATION (Step 3) │
│    - Move epic from Active to Completed table                   │
│    - Add epic detail section with commits                       │
│    - Increment "Next Available Number"                          │
│    - Commit EPIC_TRACKER.md and PROCESS_METRICS.md updates      │
│                                                                  │
│ 6. ⚠️ UPDATE CLAUDE.md IF GUIDES IMPROVED                       │
│    - Check epic_lessons_learned.md for guide improvements       │
│    - Update .shamt/guides/ files if needed                      │
│    - Update CLAUDE.md if workflow changed                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites Checklist

**Before starting S11, verify:**

### Merge Verification (MANDATORY)
- [ ] User has signaled that the PR has been merged
- [ ] `git checkout main` completed
- [ ] `git fetch origin && git reset --hard origin/main` completed
- [ ] Feature branch commits visible in `git log --oneline -10`

**If merge verification fails (commits not visible):**
- ❌ STOP — Do NOT proceed with S11
- Report to user: describe what `git log` shows and what was expected
- Wait for user guidance

### S10 Completion
- [ ] S10 exit criteria met (documentation verified, final commit created, PR created and merged)
- [ ] Working directory is main (not the feature branch)

### Documentation Availability
- [ ] epic_lessons_learned.md is accessible in epic folder
- [ ] All feature lessons_learned.md files accessible
- [ ] pr_comment_resolution.md checked (note whether present or absent)

**If ANY checklist item is unchecked, STOP. Do NOT proceed to S11 until all prerequisites are met.**

---

## Workflow Overview

```text
STAGE 11: Shamt Finalization
│
├─> STEP 1: S11.P1 — Guide Update from Lessons Learned (MANDATORY)
│   ├─ Read ALL lessons_learned.md files (epic + features)
│   ├─ Read pr_comment_resolution.md if it exists
│   ├─ Identify guide gaps from lessons AND PR comment patterns
│   ├─ Create GUIDE_UPDATE_PROPOSAL.md (prioritized P0-P3)
│   ├─ Present each proposal to user (individual approval)
│   ├─ Create proposal doc in .shamt/unimplemented_design_proposals/
│   └─ Commit proposal doc and update tracking
│
├─> STEP 2: Move Epic to done/ Folder
│   ├─ Create done/ folder if doesn't exist
│   ├─ Clean up done/ folder (max 10 epics, delete oldest if needed)
│   ├─ Move entire epic folder to done/ using git mv
│   ├─ Verify move successful (folder structure intact)
│   ├─ Verify done/ has 10 or fewer epics
│   ├─ Leave original epic request (.txt) in .shamt/epics/requests/
│   └─ Commit the epic folder move
│
├─> STEP 3: Update .shamt/epics/EPIC_TRACKER.md
│   ├─ Move epic from Active to Completed table
│   ├─ Add epic detail section with full description
│   ├─ Increment "Next Available Number"
│   ├─ Commit the EPIC_TRACKER.md update
│   └─ Append summary row to PROCESS_METRICS.md and commit
│
└─> STEP 4: Final Verification & Completion
    ├─ Verify epic in done/ folder
    ├─ Verify original request still in .shamt/epics/requests/
    ├─ Verify git shows clean state
    └─ Celebrate epic completion! 🎉
```

---

## Quick Navigation

| Step | Focus Area | Time | Mandatory? |
|------|-----------|------|------------|
| **Step 1** | S11.P1 Guide Updates | 20-45 min | ✅ YES |
| **Step 2** | Move Epic to done/ | 5 min | ✅ YES |
| **Step 3** | Update EPIC_TRACKER.md | 5 min | ✅ YES |
| **Step 4** | Final Verification | 5 min | ✅ YES |

**Total Time:** 45-80 minutes (including S11.P1)

---

## Detailed Workflow

### STEP 1: S11.P1 — Guide Update from Lessons Learned (MANDATORY)

**Objective:** Capture lessons learned from the epic and PR review in a guide update proposal doc, deferred to master for implementation.

**⚠️ CRITICAL:** This is NOT optional. Every epic must run S11.P1. Run it FIRST — before archiving the epic folder — so the lessons files are in their working location.

**READ THE FULL GUIDE:**
```text
stages/s11/s11_p1_guide_update_workflow.md
```

**Process Overview:**
1. Analyze all lessons_learned.md files (epic + all features)
2. Read pr_comment_resolution.md if it exists — extract guide improvement insights
3. Create GUIDE_UPDATE_PROPOSAL.md with prioritized proposals (P0-P3)
4. Present each proposal to user for individual approval
5. Create proposal doc in `.shamt/unimplemented_design_proposals/` and commit it
6. Update guide_update_tracking.md

**Time Estimate:** 20-45 minutes

**Exit Condition:** S11.P1 complete (guide_update_tracking.md updated; proposal doc created if any proposals accepted)

**NEXT:** After S11.P1 complete, proceed to STEP 2 (Move Epic to done/)

---

### STEP 2: Move Epic to done/ Folder

**Objective:** Move the completed epic folder to done/ for archival.

**2a. Create done/ Folder (If Doesn't Exist)**

```bash
ls .shamt/epics/
```

If done/ doesn't exist:
```bash
mkdir .shamt/epics/done
```

**2b. Clean Up done/ Folder (Max 10 Epics)**

Check current epic count:
```bash
ls -d .shamt/epics/done/*/ | wc -l
```

**If count is 10 or more:**

1. List epics by date (oldest first):
   ```bash
   # Linux/Mac
   ls -lt .shamt/epics/done/ | tail -n +2
   ```

2. Delete oldest epic(s) to bring count to 9 or fewer:
   ```bash
   rm -rf .shamt/epics/done/{oldest_epic_name}
   ```

3. Verify count after deletion:
   ```bash
   ls -d .shamt/epics/done/*/ | wc -l
   ```

**If count is less than 10:** No deletion needed, proceed.

**2c. Move Entire Epic Folder to done/**

Use **`git mv`** (not shell `mv`):

```bash
git mv .shamt/epics/SHAMT-{N}-{epic_name} .shamt/epics/done/SHAMT-{N}-{epic_name}
```

**⚠️ CRITICAL: Use `git mv`, NOT shell `mv`.** Shell `mv` leaves old paths as unstaged deletions; `git mv` stages both sides atomically.

**2d. Verify Move Successful**

```bash
ls .shamt/epics/done/SHAMT-{N}-{epic_name}/
```

Verify:
- ✅ All features present
- ✅ All epic-level files present (EPIC_README.md, epic_lessons_learned.md, etc.)
- ✅ No files left behind in original location

**2e. Verify done/ Folder Count**

```bash
ls -d .shamt/epics/done/*/ | wc -l
```

**Expected:** 10 or fewer

**2f. Leave Original Epic Request in Requests Folder**

Do NOT move the request file from `.shamt/epics/requests/`. It stays permanently for reference.

**2g. Commit the Epic Folder Move**

```bash
git commit -m "chore/SHAMT-{N}: Move completed epic to done/ folder

Epic SHAMT-{N} ({epic_name}) is complete and archived.

"
```

---

### STEP 3: Update .shamt/epics/EPIC_TRACKER.md

**Objective:** Update EPIC_TRACKER.md to move epic from Active to Completed and record full epic details.

**3a. Move Epic from Active to Completed Table**

Edit `.shamt/epics/EPIC_TRACKER.md`:
1. Remove the epic's row from the "Active Epics" table
2. Add the epic's row to the "Completed Epics" table with completion date and done/ location

**3b. Add Epic Detail Section**

Add a detailed section below "## Epic Details" with:
- Type, branch, dates, location
- Description (1-2 paragraphs)
- Features implemented (list)
- Key changes (bullet points)
- Commit history (hashes + messages)
- Testing results
- Lessons learned (summary + link to epic_lessons_learned.md)

**3c. Increment Next Available Number**

Update "Next Available Number" field to SHAMT-{N+1}

**3d. Commit the EPIC_TRACKER.md Update**

```bash
git add .shamt/epics/EPIC_TRACKER.md
git commit -m "chore/SHAMT-{N}: Update EPIC_TRACKER with completed epic

Move SHAMT-{N} from Active to Completed.
Increment Next Available Number to SHAMT-{N+1}.

"
```

**3e. Append to .shamt/epics/PROCESS_METRICS.md**

Read EPIC_METRICS.md from the archived epic folder to compute the summary row.

If PROCESS_METRICS.md does not yet exist, create it with this header:
```markdown
| Epic | Date | Features | Total Time | S5 Avg Rounds | S7 Avg Rounds | S9 Rounds | S9P3 Restarts | Top Reset Dim |
|------|------|:--------:|:----------:|:-------------:|:-------------:|:---------:|:-------------:|---------------|
```

Append one row and commit:
```bash
git add .shamt/epics/PROCESS_METRICS.md
git commit -m "chore/SHAMT-{N}: append PROCESS_METRICS row"
```

---

### STEP 4: Final Verification & Completion

**Objective:** Verify S11 is complete and celebrate.

**4a. Verify Epic in done/ Folder**

```bash
ls .shamt/epics/done/SHAMT-{N}-{epic_name}/
```

**4b. Verify Original Request Accessible**

```bash
ls .shamt/epics/requests/
```

**4c. Verify Git Status Clean**

```bash
git status
```

**Expected:** `nothing to commit, working tree clean`

**4d. Celebrate Epic Completion! 🎉**

The epic is complete!

**What was accomplished:**
- ✅ Epic planned and implemented (S1–S9)
- ✅ Feature branch merged to main (S10)
- ✅ Lessons learned captured in guide proposals (S11.P1)
- ✅ Epic archived in done/ folder
- ✅ EPIC_TRACKER.md and PROCESS_METRICS.md updated
- ✅ Shamt system ready for next epic

---

## Exit Criteria

**S11 is COMPLETE when ALL of the following are true:**

### Prerequisites
- [ ] Merge verified: feature branch commits visible in git log on main

### S11.P1 — Guide Updates (Step 1)
- [ ] All lessons_learned.md files analyzed (epic + features)
- [ ] pr_comment_resolution.md analyzed (or confirmed absent)
- [ ] GUIDE_UPDATE_PROPOSAL.md created
- [ ] User reviewed all proposals individually
- [ ] Proposal doc created in `.shamt/unimplemented_design_proposals/` (if any proposals accepted)
- [ ] Proposal doc committed (or zero proposals noted)
- [ ] reference/guide_update_tracking.md updated

### Epic Move (Step 2)
- [ ] done/ folder exists
- [ ] done/ folder has 10 or fewer epics
- [ ] Entire epic folder moved to done/ using git mv
- [ ] Epic folder structure intact in done/
- [ ] Epic folder move committed
- [ ] Original request still in .shamt/epics/requests/

### EPIC_TRACKER.md Update (Step 3)
- [ ] Epic moved from Active to Completed table
- [ ] Epic detail section added with full description
- [ ] Next Available Number incremented
- [ ] EPIC_TRACKER.md update committed
- [ ] PROCESS_METRICS.md updated with summary row and committed

### Final Verification (Step 4)
- [ ] Epic visible in done/ folder
- [ ] Git status clean
- [ ] Epic completion celebrated

**Epic and Shamt finalization are COMPLETE when ALL criteria above are met.**

---

## Summary

**S11 — Shamt Finalization closes out the Shamt system state after the epic merge:**

**Key Activities:**
1. S11.P1: Read all lessons + PR comment analysis, create guide update proposal doc (user-approved), commit proposal doc — runs FIRST, before archival
2. Move entire epic folder to done/ (max 10 epics, delete oldest if needed), commit
3. Update EPIC_TRACKER.md (move to Completed, add details, increment number), append to PROCESS_METRICS.md, commit
4. Final verification and celebration

**Critical Success Factors:**
- Merge verified before any S11 action
- S11.P1 runs before archival (lessons are easier to find in working location)
- Use `git mv` for epic folder move (not shell `mv`)
- EPIC_TRACKER.md update includes full detail section, not just table update

**Common Pitfalls:**
- Starting S11 before verifying the merge
- Running archival before S11.P1 — makes lesson files harder to find
- Using shell `mv` instead of `git mv` for the epic folder move
- Only updating the EPIC_TRACKER table but forgetting the detail section

**Reference Files:**
- `reference/stage_11/stage_11_reference_card.md` — Quick reference for this stage
- `stages/s11/s11_p1_guide_update_workflow.md` — Full guide for guide update proposals

---

## Next Stage

**🎉 EPIC COMPLETE — No Next Stage**

You've successfully completed all stages of the epic workflow:
- ✅ S1: Epic Planning
- ✅ S2: Feature Deep Dives
- ✅ S3: Epic-Level Docs, Tests, and Approval
- ✅ S5–S8: Feature Loop (Planning → Execution → Testing → Alignment)
- ✅ S9: Epic Final QC
- ✅ S10: Final Changes & Merge
- ✅ S11: Shamt Finalization
