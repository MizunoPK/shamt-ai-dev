# S10 Prompts: Final Changes & Merge

**Stage:** 10
**Purpose:** Documentation verification, final commit, optional overview doc, PR creation, and merge verification

---

## Starting S10: Final Changes & Merge

**User says:** "Finalize epic" or "Create the PR" or Agent detects S9 complete

**Prerequisite:** S9 complete (epic smoke testing, QC rounds, user testing passed with ZERO bugs)

**Agent MUST respond:**

```markdown
I'm beginning S10 (Final Changes & Merge).

**Guide I'm following:** stages/s10/s10_epic_cleanup.md
**Prerequisites verified:**
- [x] S9 fully complete in EPIC_README.md — all phases complete
- [x] User testing passed with ZERO bugs (S9 Step 6)
- [x] Read ENTIRE guide using Read tool

**The guide requires:**
- **Documentation Verification** (Step 1):
  - EPIC_README.md complete and accurate
  - epic_lessons_learned.md contains insights from all stages
  - epic_smoke_test_plan.md reflects final implementation
  - All feature README.md files complete
- **Final Commit** (Step 2):
  - Review all changes (git status, git diff)
  - Stage all epic-related changes
  - Create commit: "{commit_type}/SHAMT-{number}: Complete {epic_name} epic"
- **Epic Overview Document** (Step 3, optional):
  - Ask user: "Would you like to create SHAMT-{N}-OVERVIEW.md?"
  - If yes: gather context, plan narrative, write, validate, commit
- **Push and Create PR** (Step 4):
  - Verify working tree clean, push all commits
  - Create PR using gh CLI (or manual instructions)
  - Recommend squash commit message
  - Wait for user to signal merge
  - On signal: checkout main, verify merge via git log, hand off to S11

**Note:** Tests were verified in S9 QC — no test re-run needed in S10.

**Updating EPIC_README.md Agent Status:**
- Current Stage: S10 - Final Changes & Merge
- Current Guide: stages/s10/s10_epic_cleanup.md
- Guide Last Read: {YYYY-MM-DD HH:MM}
- Next Action: Step 1 — Documentation Verification

Verifying documentation...
```

---

## STEP 5: PR Comment Resolution (User-Triggered)

**Trigger:** User directs agent to process PR comments (e.g., "get the PR comments and resolve them")

**Prerequisite:** PR created in Step 4; reviewers have left feedback; PR not yet merged

**Agent MUST respond:**

```markdown
I'm processing PR comments for Step 5 (PR Comment Resolution).

**Actions:**
1. Fetching all review comments via gh API
2. Creating `.shamt/epics/{epic_name}/pr_comment_resolution.md` from template
3. Working through each comment (fix code / discuss / mark Won't Fix)
4. Pushing any new commits after resolving

**Template:** `.shamt/guides/templates/comment_resolution_template.md`

Fetching PR comments now...
```

**Full workflow:** See `stages/s10/s10_epic_cleanup.md` Step 5 for complete instructions.

---

*For prompts for other stages, see the [prompts index](../prompts_reference_v2.md)*
