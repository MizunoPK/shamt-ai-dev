# S10 Prompts: Epic Cleanup

**Stage:** 10
**Purpose:** Final verification, user testing, commit, and archival

---

## Starting S10: Epic Cleanup

**User says:** "Finalize epic" or "Commit and archive" or Agent detects S9 complete

**Prerequisite:** S9 complete (epic smoke testing, QC rounds, PR review all passed)

**Agent MUST respond:**

```markdown
I'm beginning S10 (Epic Cleanup).

**Guide I'm following:** stages/s10/s10_epic_cleanup.md (from CLAUDE.md Stage Workflow table)
**Prerequisites verified:**
- [x] Prior stage (S9) fully complete in EPIC_README.md Epic Completion Checklist - all 4 phases complete
- [x] User testing passed with ZERO bugs (S9.P3 gate)
- [x] Guide path matches CLAUDE.md Stage Workflow table
- [x] Read ENTIRE guide using Read tool

**The guide requires:**
- **Run Unit Tests** (100% pass required):
  - Execute: {TEST_COMMAND}
  - Verify exit code = 0
  - If ANY tests fail → Fix before committing
- **Documentation Verification**:
  - EPIC_README.md complete and accurate
  - epic_lessons_learned.md contains insights from all stages
  - epic_smoke_test_plan.md reflects final implementation
  - All feature README.md files complete
- **Update Guides** (if lessons identified):
  - Review epic_lessons_learned.md "Guide Improvements Needed"
  - Update .shamt/guides/ files if improvements identified
  - Update CLAUDE.md if workflow changed
  - Document guide updates
- **⚠️ USER TESTING (MANDATORY GATE - BEFORE COMMIT)**:
  - Ask user to test complete system themselves
  - User reports any bugs discovered during testing
  - If bugs found → Use debugging protocol to fix bugs
  - After ALL bug fixes → RESTART from S9.P1 (Epic Smoke Testing)
  - Complete full S9.P2 Validation Loop again (primary clean round + sub-agent confirmation required)
  - Return to user testing (S9.P3) after validation loop passes
  - Repeat until user testing passes with ZERO bugs
  - CANNOT commit without user approval
- **Final Commit and Pull Request**:
  - Review all changes (git status, git diff)
  - Stage all epic-related changes
  - Create commit with clear, descriptive message
  - Format: "{commit_type}/SHAMT-{number}: Complete {epic_name} epic"
  - Push branch to remote
  - Create Pull Request for user review using gh CLI
  - Wait for user to review and merge PR
  - Update .shamt/epics/EPIC_TRACKER.md after user merges
- **Move Epic to done/**:
  - Move ENTIRE epic folder: .shamt/epics/{epic}/ → .shamt/epics/done/{epic}/
  - Leave original epic request (.txt) in .shamt/epics/requests/ for reference
  - Verify folder structure intact after move
- **Final Verification**:
  - Epic in done/ folder
  - Original request still in .shamt/epics/requests/
  - Git shows clean state

**Prerequisites I'm verifying:**
✅ S9 complete (EPIC_README.md shows epic QC passed)
✅ No pending features or bug fixes
✅ All tests passing (verified recently)

**I'll now run unit tests to verify 100% pass rate...**

**Updating EPIC_README.md Agent Status:**
- Current Stage: S10 - Epic Cleanup
- Current Guide: stages/s10/s10_epic_cleanup.md
- Guide Last Read: {YYYY-MM-DD HH:MM}
- Critical Rules: "Unit tests 100% pass before commit", "User testing MANDATORY before commit", "If bugs found → RESTART S9", "Move ENTIRE epic folder", "Leave .txt in requests/"
- Next Action: Run {TEST_COMMAND}

Running unit tests...
```

---

## STEP 8.5: PR Comment Resolution (User-Triggered)

**Trigger:** User directs agent to process PR comments (e.g., "get the PR comments and resolve them")

**Prerequisite:** PR created in Step 8; reviewers have left feedback

**Agent MUST respond:**

```markdown
I'm processing PR comments for Step 8.5 (PR Comment Resolution).

**Actions:**
1. Fetching all review comments via gh API
2. Creating `.shamt/epics/{epic_name}/pr_comment_resolution.md` from template
3. Working through each comment (fix code / discuss / mark Won't Fix)
4. Pushing any new commits after resolving

**Template:** `.shamt/guides/templates/comment_resolution_template.md`

Fetching PR comments now...
```

**Full workflow:** See `stages/s10/s10_epic_cleanup.md` Step 8.5 for complete instructions.

---

## S10.P1: Guide Update from Lessons Learned + PR Comment Analysis (MANDATORY)

**Trigger:** After S10 STEP 8.5 complete (or skipped — no PR comments); the last step before final verification

**Prerequisite:** All lessons_learned.md files complete; PR comment resolution complete (or absent)

**Agent MUST transition to S10.P1:**

```markdown
I'm reading `stages/s10/s10_p1_guide_update_workflow.md` to create a guide update proposal doc from lessons learned...

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
- **Commit proposal doc** (separate from epic commit)

**User approval process:**
- Each proposal presented individually with before/after
- User can: Approve (apply as-is) / Modify (provide alternative) / Reject (skip) / Discuss (ask questions)
- Agent applies only approved changes or user modifications

**Why this matters:**
- Continuous guide improvement based on real implementation experience
- Future agents benefit from lessons learned in this epic
- Systematic feedback loop: implementation → lessons → guide updates
- User has full control over guide evolution

**Prerequisites I'm verifying:**
✅ S10 STEP 8 complete (PR created and merged)
✅ S10 STEP 8.5 complete or skipped (PR comment resolution)
✅ All lessons_learned.md files complete
✅ Ready to analyze lessons and create proposal

**I'll now analyze the lessons learned from this epic and create GUIDE_UPDATE_PROPOSAL.md...**

**Updating EPIC_README.md Agent Status:**
- Current Stage: S10.P1 - Guide Update from Lessons Learned
- Current Phase: GUIDE_ANALYSIS
- Current Guide: stages/s10/s10_p1_guide_update_workflow.md
- Guide Last Read: {YYYY-MM-DD HH:MM}
- Critical Rules: "Analyze ALL lessons", "Prioritize P0-P3", "Individual approval", "No guide edits — proposal doc only", "Commit proposal doc"
- Next Action: Read all lessons_learned.md files and identify guide gaps

Analyzing lessons learned...
```

**Full workflow:** See `prompts/guide_update_prompts.md` for complete prompts (presentation, approval, modifications, etc.)

---

*For prompts for other stages, see the [prompts index](../prompts_reference_v2.md)*
