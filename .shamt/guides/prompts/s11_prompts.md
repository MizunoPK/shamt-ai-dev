# S11 Prompts: Shamt Finalization

**Stage:** 11
**Purpose:** Guide update proposals, epic archival, tracker update, and final verification

---

## Starting S11: Shamt Finalization

**Trigger:** User signals PR is merged, OR agent detects S10 Step 4 complete (merge verified)

**Prerequisite:** S10 complete — PR merged, main/master checked out and verified

**Agent MUST respond:**

```markdown
I'm beginning S11 (Shamt Finalization).

**Guide I'm following:** stages/s11/s11_shamt_finalization.md
**Prerequisites verified:**
- [x] S10 complete — PR merged
- [x] On main branch; feature branch commits visible in git log
- [x] Read ENTIRE guide using Read tool

**The guide requires:**
- **S11.P1 — Guide Updates** (Step 1, MANDATORY — runs FIRST):
  - Read ALL lessons_learned.md files (epic + features)
  - Read pr_comment_resolution.md if it exists
  - Create prioritized proposals (P0-P3)
  - Get user approval individually per proposal
  - Create proposal doc in `.shamt/unimplemented_design_proposals/`
  - Commit proposal doc; update guide_update_tracking.md
- **Move Epic to done/** (Step 2):
  - Move ENTIRE epic folder using git mv
  - Max 10 epics in done/ (delete oldest if needed)
  - Commit the folder move
- **Update EPIC_TRACKER.md** (Step 3):
  - Move epic from Active to Completed table
  - Add full detail section
  - Increment Next Available Number
  - Commit tracker + PROCESS_METRICS.md updates
- **Final Verification** (Step 4):
  - Verify epic in done/, git status clean
  - Celebrate! 🎉

**Updating EPIC_README.md Agent Status:**
- Current Stage: S11 - Shamt Finalization
- Current Guide: stages/s11/s11_shamt_finalization.md
- Guide Last Read: {YYYY-MM-DD HH:MM}
- Next Action: Step 1 — S11.P1 Guide Update from Lessons Learned

Analyzing lessons learned...
```

---

## S11.P1: Guide Update from Lessons Learned (MANDATORY)

**Trigger:** Beginning of S11 (Step 1)

**Prerequisite:** S10 complete, on main, merge verified

**Agent MUST transition to S11.P1:**

```markdown
I'm reading `stages/s11/s11_p1_guide_update_workflow.md` to create a guide update proposal doc from lessons learned...

**The guide requires:**
- **Analyze ALL lessons_learned.md files** from this epic:
  - epic_lessons_learned.md (epic-level lessons)
  - feature_XX_{name}/lessons_learned.md (all feature-level lessons)
  - pr_comment_resolution.md (if it exists — PR reviewer feedback)
- **Identify guide gaps:** For each lesson, determine which guide(s) could have prevented the issue
- **Create prioritized proposals** in GUIDE_UPDATE_PROPOSAL.md:
  - P0 (Critical): Prevents catastrophic bugs, mandatory gate gaps
  - P1 (High): Significantly improves quality, reduces major rework
  - P2 (Medium): Moderate improvements, clarifies ambiguity
  - P3 (Low): Minor improvements, cosmetic fixes
- **Get user approval INDIVIDUALLY:** Each proposal gets Approve/Modify/Reject/Discuss
- **Create proposal doc** in `.shamt/unimplemented_design_proposals/`
- **Commit proposal doc** (separate commit)

**Prerequisites I'm verifying:**
✅ S10 complete (PR merged, on main)
✅ All lessons_learned.md files accessible
✅ Ready to analyze lessons and create proposals

**I'll now analyze the lessons learned from this epic and create GUIDE_UPDATE_PROPOSAL.md...**

**Updating EPIC_README.md Agent Status:**
- Current Stage: S11.P1 - Guide Update from Lessons Learned
- Current Phase: GUIDE_ANALYSIS
- Current Guide: stages/s11/s11_p1_guide_update_workflow.md
- Guide Last Read: {YYYY-MM-DD HH:MM}
- Next Action: Read all lessons_learned.md files and identify guide gaps

Analyzing lessons learned...
```

**Full workflow:** See `prompts/guide_update_prompts.md` for complete prompts (presentation, approval, modifications, etc.)

---

*For prompts for other stages, see the [prompts index](../prompts_reference_v2.md)*
