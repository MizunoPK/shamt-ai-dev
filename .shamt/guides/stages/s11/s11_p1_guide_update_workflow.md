# S11.P1: Guide Update from Lessons Learned

**File:** `s11_p1_guide_update_workflow.md`

---


## Table of Contents

1. [S11.P1: Guide Update from Lessons Learned](#s11p1-guide-update-from-lessons-learned)
2. [Overview](#overview)
3. [Critical Rules](#critical-rules)
4. [Prerequisites Checklist](#prerequisites-checklist)
5. [Step-by-Step Workflow](#step-by-step-workflow)
6. [Agent Status](#agent-status)
7. [Exit Criteria](#exit-criteria)
8. [Common Pitfalls](#common-pitfalls)
9. [Quick Reference: Proposal Quality Checklist](#quick-reference-proposal-quality-checklist)
10. [Example Proposal (For Reference)](#example-proposal-for-reference)

---
🚨 **MANDATORY READING PROTOCOL**

**Before starting this guide:**
1. Use Read tool to load THIS ENTIRE GUIDE
2. Acknowledge critical requirements (see "Critical Rules" section below)
3. Verify prerequisites (see "Prerequisites Checklist" section below)
4. Update EPIC_README.md Agent Status with guide name + timestamp

**DO NOT proceed without reading this guide.**

**After session compaction:**
- Check EPIC_README.md Agent Status for current step
- READ THIS GUIDE again (full guide, not summary)
- Continue from "Next Action" in Agent Status

---

## 🚫 FORBIDDEN SHORTCUTS

You CANNOT:
- Draft guide change proposals based on general knowledge without reviewing the actual lessons_learned.md files — start with Step 1: Review lessons_learned.md from ALL completed features before proposing any changes
- Submit proposals without completing the Quick Reference: Proposal Quality Checklist — every proposal must pass the quality checklist before submission to avoid low-quality or premature guide changes

If you are about to do any of the above: STOP and re-read the relevant section.

---

## Overview

**What is this phase?**
S11.P1 is the mandatory guide improvement workflow where you analyze lessons learned from the epic and propose specific guide updates to help future agents, with user approval for each change individually.

**When do you use this guide?**
- S10 complete (PR merged, main/master verified up to date)
- All lessons_learned.md files are complete
- Beginning S11 (Shamt Finalization)

**Key Outputs:**
- ✅ GUIDE_UPDATE_PROPOSAL.md created with prioritized proposals (P0-P3)
- ✅ User reviewed and approved/rejected each proposal individually
- ✅ Proposal doc created in `.shamt/unimplemented_design_proposals/`
- ✅ Proposal doc committed
- ✅ reference/guide_update_tracking.md updated

**Time Estimate:**
20-45 minutes (depends on number of lessons and proposals)

**Exit Condition:**
S11.P1 is complete when all proposals have been reviewed by user, proposal doc created and committed (if any proposals accepted), and tracking updated

**Model Selection for Token Optimization (SHAMT-27):**

S11.P1 guide updates MUST use delegation for token efficiency (15-25% savings):

```text
Primary Agent (Opus):
├─ Spawn Haiku → Read lessons_learned.md files
├─ Spawn Sonnet → Read guide files to identify improvement opportunities
├─ Primary handles → Analyze patterns, write proposals, prioritize (P0-P3)
├─ Primary writes → GUIDE_UPDATE_PROPOSAL.md, tracking updates
└─ Spawn 2x Haiku → Verify proposal doc accuracy (sub-agent confirmation)
```

**Mandatory enforcement:** Use Haiku sub-agents for proposal doc verification (Step 5.7). See inline example below.

**See:** `reference/model_selection.md` for additional Task tool examples.

---

## Critical Rules

```text
┌─────────────────────────────────────────────────────────────┐
│ CRITICAL REQUIREMENTS - READ BEFORE PROCEEDING              │
└─────────────────────────────────────────────────────────────┘

1. ⚠️ Analyze ALL lessons_learned.md files
   - epic_lessons_learned.md (epic-level)
   - feature_XX_{name}/lessons_learned.md (ALL features)
   - Do NOT skip any lessons

2. ⚠️ Individual approval for EACH proposal
   - User reviews proposals one at a time
   - User can: Approve / Modify / Reject / Discuss
   - Do NOT batch approvals or assume approval

3. ⚠️ Do NOT edit any guide files — create a proposal doc only
   - All accepted/modified proposals go into the proposal doc
   - If user rejects → document in proposal doc's rejected table
   - Do NOT apply any changes directly to guide files

4. ⚠️ Prioritize ALL proposals (P0-P3)
   - P0 (Critical): Prevents catastrophic bugs, mandatory gate gaps
   - P1 (High): Significantly improves quality, reduces major rework
   - P2 (Medium): Moderate improvements, clarifies ambiguity
   - P3 (Low): Minor improvements, cosmetic fixes

5. ⚠️ Separate commit for the proposal doc
   - Proposal doc committed separately from epic code
   - Commit message: "docs(proposals): Add guide update proposals from SHAMT-{N}-{epic_name}"
   - Do NOT mix proposal doc with epic commits

6. ⚠️ Check gitignore BEFORE committing the proposal doc
   - Run `git check-ignore .shamt/unimplemented_design_proposals/` before staging
   - If directory is gitignored → create file locally, skip commit, inform user
   - NEVER use `git add -f` to force-commit gitignored files
   - If NOT gitignored → proceed with normal `git add` and `git commit`

7. ⚠️ Update tracking after creating the proposal doc
   - Add entries to reference/guide_update_tracking.md
   - Document accepted, modified, and rejected proposals
   - Record path to proposal doc and proposal commit hash
   - Update metrics section
```

---

## Prerequisites Checklist

**Verify BEFORE starting S11.P1:**

- [ ] S10 complete — PR merged, main/master verified up to date
- [ ] epic_lessons_learned.md exists and is complete
- [ ] All feature lessons_learned.md files exist and are complete
- [ ] pr_comment_resolution.md checked (present or absent noted)
- [ ] Ready to analyze lessons and create proposals

**If any prerequisite fails:**
- ❌ STOP - Do NOT proceed with S11.P1
- Return to previous step to complete prerequisites

---

## Step-by-Step Workflow

### Step 1: Read All Lessons Learned

**Purpose:** Gather all lessons from epic to identify guide improvement opportunities

**Actions:**

1.1. **Read epic-level lessons:**
```bash
## Read epic lessons
cat {epic_folder}/epic_lessons_learned.md
```

Note:
- How many lessons documented?
- Which lessons are about process/guides vs domain-specific?
- Any patterns emerging?

1.2. **Read all feature-level lessons:**
```bash
## Read each feature's lessons
cat {epic_folder}/feature_01_{name}/lessons_learned.md
cat {epic_folder}/feature_02_{name}/lessons_learned.md
...
```

Note:
- Common issues across features?
- Feature-specific vs generalizable lessons?
- Any repeated mistakes?

1.3. **Read PR comment resolution file (if it exists):**
```bash
## Check for PR comment resolution file
ls {epic_folder}/pr_comment_resolution.md 2>/dev/null && cat {epic_folder}/pr_comment_resolution.md
```

Note:
- Were any comments fixed or marked Won't Fix?
- Do any comments reveal a gap that S7/S9 QC should have caught?
- Are there patterns across multiple comments (e.g., 3 of 5 comments about error handling)?

1.4. **Tally total inputs:**
- Epic lessons: {N}
- Feature lessons: {N} across {N} features
- PR comments with guide improvement potential: {N} (0 if no resolution file)
- Total: {N} lessons/comments to analyze

**Checkpoint:**
- [ ] All epic_lessons_learned.md read
- [ ] All feature lessons_learned.md read
- [ ] pr_comment_resolution.md read (or confirmed absent)
- [ ] Total input count documented

---

### Step 2: Identify Guide Gaps

**Purpose:** For each lesson, determine which guide(s) could have prevented the issue

**Actions:**

2.1. **For each lesson, ask:**
- What went wrong? (or what went right?)
- Why did it occur? (root cause)
- Which guide(s) could have prevented this?
- What specific guidance was missing/unclear/wrong?
- Is this a one-time issue or systemic pattern?

2.2. **Use common lesson → guide mappings:**

| Lesson Pattern | Likely Affected Guide(s) |
|----------------|--------------------------|
| Missed requirement in spec | stages/s2/s2_p1_spec_creation_refinement.md |
| Wrong interface assumed | stages/s5/s5_v2_validation_loop.md (Dimension 2) |
| Algorithm traceability incomplete | stages/s5/s5_v2_validation_loop.md (Dimension 3) |
| Integration gap not identified | stages/s5/s5_v2_validation_loop.md (Dimension 7) |
| Test coverage insufficient | stages/s5/s5_v2_validation_loop.md (Dimension 8) |
| Gate not enforced | reference/mandatory_gates.md |
| QC round missed issue | stages/s7/s7_p2_qc_rounds.md |
| Smoke test didn't catch bug | stages/s7/s7_p1_smoke_testing.md |
| Epic integration issue | stages/s9/s9_p2_epic_qc_rounds.md |
| Spec misinterpretation | stages/s5/s5_v2_validation_loop.md (D9: Gate 23a - Spec Alignment) |
| Checklist question unclear | templates/feature_checklist_template.md |
| Implementation plan vague | templates/implementation_plan_template.md |
| Prompt not followed | prompts/{stage}_prompts.md |
| Workflow diagram unclear | EPIC_WORKFLOW_USAGE.md → "Workflow Stages" |
| Reference card missing info | reference/stage_{N}_reference_card.md |

2.3. **Determine priority for each:**

**P0 (Critical) - Must fix:**
- Prevents catastrophic bugs (week+ of rework)
- Mandatory gate was missing/unclear and caused major issue
- Spec misinterpretation led to implementing wrong solution
- Safety/security vulnerability in process

**P1 (High) - Strongly recommended:**
- Significantly improves quality
- Reduces common rework patterns (days of rework)
- Prevents moderate bugs
- Clarifies ambiguous requirements that caused confusion

**P2 (Medium) - Consider:**
- Moderate quality improvement
- Clarifies minor ambiguity
- Improves workflow efficiency
- Better examples/templates

**P3 (Low) - Nice-to-have:**
- Minor improvement
- Cosmetic/formatting
- Adds optional convenience
- Reduces minor friction

2.4. **Analyze PR comments for guide improvement potential (if resolution file exists):**

For each PR comment in `pr_comment_resolution.md`, ask:
- Did this reviewer comment reveal a gap that S7/S9 QC should have caught?
- Could a guide change prevent this class of comment in the future?
- Is there a pattern across multiple comments suggesting a systemic gap?

If yes to any of the above → treat as a guide gap, assign priority, create a proposal.

2.5. **Filter out non-actionable lessons:**

**Skip if lesson is:**
- Domain-specific (only applies to this epic's subject matter)
- Already covered by guides (no gap to fill)
- User-specific decision (not a guide issue)
- One-time environmental issue (not preventable by guides)

**Checkpoint:**
- [ ] Each lesson analyzed for guide impact
- [ ] PR comments analyzed for guide improvement potential (if file exists)
- [ ] Guide gaps identified and documented
- [ ] Priorities assigned (P0/P1/P2/P3)
- [ ] Non-actionable lessons filtered out
- [ ] Ready to create proposals

---

### Step 3: Create GUIDE_UPDATE_PROPOSAL.md

**Purpose:** Document all proposed guide changes in structured format for user review

**Actions:**

3.1. **Create file using template:**
```bash
## Copy template
cp .shamt/guides/templates/guide_update_proposal_template.md \
   {epic_folder}/GUIDE_UPDATE_PROPOSAL.md
```

3.2. **Fill in summary section:**
- Epic name and SHAMT number
- Total lessons analyzed (epic + feature counts)
- Total proposals (breakdown by P0/P1/P2/P3)
- Recommended action (prioritize P0 and P1)

3.3. **Create proposals grouped by priority:**

**For each guide gap identified:**

a. **Write proposal header:**
   - Proposal ID (P0-1, P1-2, etc.)
   - Short descriptive title

b. **Quote lesson learned:**
   - Direct quote from lessons_learned.md
   - Source file and lesson number

c. **Explain root cause:**
   - Why this issue occurred
   - What was missing/unclear in guides

d. **Identify affected guide(s):**
   - Path to guide file
   - Section name
   - Line numbers (if known)

e. **Show before/after:**
   - Current state: exact text from guide
   - Proposed change: new text with improvements
   - Make differences clear (use formatting if helpful)

f. **Provide rationale:**
   - How this specific change prevents future issues
   - Why this guidance helps

g. **Assess impact:**
   - Who benefits (which agents/stages)
   - When it helps (specific situations)
   - Severity if unfixed (specific bad outcome)

h. **Add user decision checkboxes:**
   - [ ] Approve
   - [ ] Modify
   - [ ] Reject
   - [ ] Discuss

3.4. **Group proposals by priority:**
- Start with P0 (Critical)
- Then P1 (High)
- Then P2 (Medium)
- Then P3 (Low)

Within each priority, order by impact (highest impact first)

**Checkpoint:**
- [ ] GUIDE_UPDATE_PROPOSAL.md created
- [ ] All proposals documented with before/after
- [ ] Proposals grouped and ordered by priority
- [ ] User decision sections included
- [ ] File is clear and ready for user review

---

### Step 4: Present Proposals to User

**Purpose:** Get user approval for each proposal individually

**Actions:**

4.1. **Use the presentation prompt:**
- Read prompts/guide_update_prompts.md
- Use "Presenting Proposals to User" prompt
- Present summary first, then individual proposals

4.2. **Present P0 proposals first:**
- These are critical fixes
- User should prioritize reviewing these
- Explain why each is P0 priority

4.3. **For each proposal, show:**
- Lesson learned (what went wrong)
- Problem (why it occurred)
- Affected guide and section
- Before/after comparison
- Rationale (how this helps)
- Ask: "Your decision for Proposal P{X}-{N}:
  - **Approve** — apply exactly as written
  - **Modify** — apply with changes (you provide alternative text)
  - **Reject** — skip this proposal
  - **Discuss** — ask questions or request clarification first"

4.4. **Collect user decisions:**

**If user says "Approve":**
- Mark proposal as approved
- Continue to next proposal

**If user says "Modify":**
- Ask user to provide alternative text
- Document user's modification
- Mark proposal as modified
- Continue to next proposal

**If user says "Reject":**
- Mark proposal as rejected
- Ask for brief rationale (optional)
- Continue to next proposal

**If user says "Discuss":**
- Answer user's questions
- Provide additional context/examples
- Revise proposal if needed
- Re-present for decision
- Do NOT proceed until decision made

4.5. **Continue through all priorities:**
- After P0, present P1 proposals
- After P1, present P2 proposals
- After P2, present P3 proposals

4.6. **Summarize decisions:**
```text
Total proposals: {N}
Approved: {N}
Modified: {N}
Rejected: {N}
```

**Checkpoint:**
- [ ] All proposals presented to user
- [ ] User made decision for each proposal
- [ ] Modified proposals have user's alternative text
- [ ] Rejected proposals have rationale (if provided)
- [ ] Decision summary documented

---

### Step 5: Create Proposal Document

**Purpose:** Write all accepted and rejected proposals into a durable proposal doc for export to master. Do NOT edit any guide files.

**🚨 CRITICAL:** Do NOT edit any files in `.shamt/guides/`. Proposals are deferred to master for implementation.

**Actions:**

5.1. **Determine the proposal doc filename:**
- Project name: read from `.shamt/project-specific-configs/init_config.md` (the "Project Name" field)
- Epic name: the current epic identifier (e.g. `SHAMT-5-auth-rework`)
- Filename: `{project_name}-{epic_name}-SHAMT-UPDATE-PROPOSAL.md`
- Example: `myapp-SHAMT-3-user-auth-SHAMT-UPDATE-PROPOSAL.md`

5.2. **If zero proposals were accepted:** Skip this step entirely. Note in the tracking update: "No proposals accepted — no proposal doc created." Proceed to Step 7.

5.3. **Create the proposal doc** at `.shamt/unimplemented_design_proposals/{filename}`:

Use this template structure:

```markdown
# {project_name} — {epic_name} Guide Update Proposals

**Status:** Pending Implementation
**Created:** {YYYY-MM-DD}
**Source Epic:** {epic_name}
**Proposals:** {N} accepted, {N} modified, {N} rejected

---

## Overview

{2–4 sentences: what the epic was, what went wrong or was learned,
and why these proposals were generated}

---

## Proposal {ID}: {Title}

**Priority:** P0 / P1 / P2 / P3
**Affected Guide:** `.shamt/guides/path/to/guide.md`
**Section:** {section name}

### Problem

{What was the issue and why did it occur}

### Current State

\`\`\`markdown
{exact current text from the guide}
\`\`\`

### Proposed Change

\`\`\`markdown
{exact new text — for "modified" proposals, use the user's version}
\`\`\`

### Rationale

{How this change prevents the issue for future agents}

---

## Rejected Proposals (for reference)

| ID | Title | Priority | Reason Rejected |
|----|-------|----------|-----------------|
| P1-2 | {title} | P1 | {user's reason} |

---

## PR Review Comment Analysis

*(Include this section only if `pr_comment_resolution.md` exists in the epic folder)*

**PR:** #{PR_NUMBER}
**Total Comments:** {N}
**Comments with Guide Improvement Potential:** {N}

### Comment-Derived Insights

| # | Comment Summary | Category | Why QC Missed It | Proposed Guide Change |
|---|----------------|----------|-------------------|----------------------|
| 1 | {summary} | {category} | {analysis} | {specific proposal or "N/A"} |

### Patterns Observed

{Any patterns across multiple comments — e.g., "3 of 5 comments were about error handling, suggesting S7 Dimension X needs strengthening"}

---

## Implementation Notes

- Apply all proposals as a single batch
- Run full guide audit (3 consecutive clean rounds) before committing
- Update `reference/guide_update_tracking.md` with implementation entry
- Delete this file from `design_docs/unimplemented/` after successful implementation and commit
```

5.4. **For each approved proposal:** populate using the template above with "Current State" and "Proposed Change" showing the original proposed text.

5.5. **For each modified proposal:** populate the same way but use the user's version in "Proposed Change".

5.6. **For rejected proposals:** add to the "Rejected Proposals" table only (do not create a full proposal block).

5.7. **Verify the proposal doc:** After writing the proposal doc, spawn 2 independent Haiku sub-agents to verify that all accepted/modified proposals are correctly captured with exact current text quoted from the source guides.

**Sub-Agent Confirmation Protocol:**

Spawn 2 parallel Haiku sub-agents (A and B) to verify the proposal doc. Each must confirm that:
- All approved proposals from Step 4 are present
- All modified proposals use the user's version
- Current state quotes match the actual guide files
- Proposed changes are captured exactly as approved/modified
- Rejected proposals are in the table only

**Why Haiku?** Proposal doc verification is mechanical checking (70-80% token savings vs Opus). Haiku excels at focused verification tasks.

**Example Task tool invocation:**

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Verify proposal doc (sub-agent A)</parameter>
  <parameter name="prompt">You are sub-agent A verifying the proposal doc after Step 5 creation.

**Proposal doc path:** `.shamt/unimplemented_design_proposals/{filename}`
**User decisions:** {N} approved, {N} modified, {N} rejected

**Your task:** Verify the proposal doc is accurate:
1. Read the proposal doc
2. Read GUIDE_UPDATE_PROPOSAL.md to see all user decisions from Step 4
3. For each approved proposal: verify it appears in proposal doc with original proposed text
4. For each modified proposal: verify it appears with user's modified version
5. For each rejected proposal: verify it appears ONLY in rejected table
6. Verify "Current State" quotes match actual guide files (spot-check 3-5 proposals)

**Report format:**
- If ALL checks pass: "CONFIRMED: Proposal doc accurate - all {N} approved/modified proposals correctly captured"
- If ANY issue found: Report the specific discrepancy (missing proposal, wrong version, misquoted current state, etc.)

**Context:**
- Proposal decisions from Step 4: {paste summary of approved/modified/rejected with IDs}
- Total lessons analyzed: {N}
- Epic: {epic_name}
  </parameter>
</invoke>

<!-- Spawn sub-agent B with identical prompt, changing only "sub-agent A" → "sub-agent B" -->
```

**What happens next:**
- Both sub-agents confirm zero issues → proceed to checkpoint
- Either sub-agent finds issue → fix the proposal doc, re-verify, repeat until both confirm zero issues

**Checkpoint:**
- [ ] Proposal doc created at `.shamt/unimplemented_design_proposals/{filename}` (or skipped if zero accepted)
- [ ] All accepted/modified proposals documented with current + proposed text
- [ ] Rejected proposals in the table
- [ ] No guide files edited

---

### Step 6: Commit the Proposal Document

**Purpose:** Commit the proposal doc as a standalone commit separate from epic code.

**Skip this step if Step 5 was skipped** (zero accepted proposals). Proceed to Step 7.

**Actions:**

6.0. **Check if `.shamt/unimplemented_design_proposals/` is gitignored (MANDATORY before staging):**
```bash
git check-ignore .shamt/unimplemented_design_proposals/ 2>/dev/null
```

- If the directory is reported as ignored → **STOP. Do NOT commit.**
  - Proposal doc exists locally (on disk) but will not be committed
  - Inform user: "Proposal doc created locally but not committed — `.shamt/unimplemented_design_proposals/` is gitignored in this project."
  - Proceed to Step 7 (record `Proposal commit: (not committed — gitignored)` in tracking)
- If NO output (not ignored) → proceed with Steps 6.1–6.3

🚨 **NEVER use `git add -f` or `git add --force`.** Respect the project's gitignore decisions.

6.1. **Stage the proposal doc:**
```bash
git add .shamt/unimplemented_design_proposals/
```

6.2. **Create commit:**
```bash
git commit -m "docs(proposals): Add guide update proposals from SHAMT-{N}-{epic_name}

Proposals: {N} accepted, {N} modified, {N} rejected

See .shamt/unimplemented_design_proposals/{project_name}-SHAMT-{N}-{epic_name}-SHAMT-UPDATE-PROPOSAL.md"
```

6.3. **Verify commit:**
```bash
git log -1 --stat
```

Check:
- Only the proposal doc was committed (not epic code, not guide files)
- Commit message is clear

**Checkpoint:**
- [ ] Proposal doc staged and committed (or skipped — gitignored)
- [ ] Commit message references the proposal doc filename
- [ ] No guide files in this commit

---

### Step 7: Update Tracking

**Purpose:** Document applied lessons in tracking file for history and pattern analysis

**Actions:**

7.1. **Open tracking file:**
```bash
## Edit tracking file
## Add entries to Applied Lessons Log, Rejected Lessons, and Metrics
```

7.2. **Add to Applied Lessons Log:**
- For each accepted/modified proposal:
  - Epic: SHAMT-{N}-{epic_name}
  - Priority: P0/P1/P2/P3
  - Lesson Summary: {brief description}
  - Affected Guide(s): {paths}
  - Date: {YYYY-MM-DD}
  - Proposal doc: `.shamt/unimplemented_design_proposals/{filename}` (or "no proposals accepted")
  - Proposal commit: {commit_hash} (or "not committed — gitignored")

7.3. **Add to Rejected Lessons:**
- For each rejected proposal:
  - Epic: SHAMT-{N}-{epic_name}
  - Priority: P0/P1/P2/P3
  - Lesson Summary: {brief description}
  - Proposed Guide(s): {paths}
  - Date Rejected: {YYYY-MM-DD}
  - User Rationale: {user's reason}

7.4. **Update Metrics:**
- Increment total epics completed
- Add proposal counts to totals
- Update approval rates by priority
- Update most frequently proposed guides list (based on Affected Guide(s) field)

7.5. **Check for patterns:**
- If same lesson appears 2+ times, consider creating Pattern Analysis entry
- Document common patterns in Pattern Analysis section

7.6. **Commit tracking update:**
```bash
git add .shamt/guides/reference/guide_update_tracking.md
git commit -m "docs(tracking): Update guide tracking for SHAMT-{N}-{epic_name}"
```

**Checkpoint:**
- [ ] Applied Lessons Log updated
- [ ] Rejected Lessons documented
- [ ] Metrics updated
- [ ] Patterns checked
- [ ] Tracking commit created

---

### Step 8: Consider Exporting Improvements to Master

**Purpose:** If guide improvements are generic enough to benefit other projects, record them for export to the master Shamt repo.

**When to record for export:**
- The improvement addresses a genuine gap or error in the guide system
- The change would benefit any project using Shamt (not just this project's tech stack)
- The improvement is to core workflow steps, gates, or clarifications — not project-specific examples

**When NOT to export:**
- The change is domain-specific (only makes sense for this project's language/framework)
- The change is minor wording tweaks with no functional impact
- The change contradicts a deliberate Shamt design decision

**Always do first (regardless of export decision):**

8.0. **Review your rules file against the master template:**

Compare your project's rules file (wherever it lives: `CLAUDE.md`, `.github/copilot-instructions.md`, etc.) against `.shamt/scripts/initialization/RULES_FILE.template.md`. For each section in your rules file not present in the template, ask: *would this apply to any Shamt project regardless of tech stack?*

- **If generic additions exist** → add them to the template (replace your epic tag with `{{EPIC_TAG}}`), then add a `CHANGES.md` entry for each:
  ```markdown
  ## YYYY-MM-DD — Rules file template: [section name]
  - Modified: `scripts/initialization/RULES_FILE.template.md`
  - Rules file section: [section name or brief description]
  - Reason: [why this is generic]
  ```
- **If no generic additions** → note "Rules file compared — no template updates needed" and continue.

**Do this step regardless of whether you plan to export.** The rules file template is not touched by the export script (it lives outside `.shamt/guides/` and `.shamt/scripts/`), so it must be updated manually here before any export opportunity is presented to the user.

---

**Note: No CHANGES.md entry is needed for the proposal doc.** The proposal doc in `.shamt/unimplemented_design_proposals/` is exported to master automatically when `export.sh` is run — it is not a modification to a shared guide or script file, so it does not require a CHANGES.md entry.

If a proposal doc was created:
- Inform the user: "Guide update proposals have been captured in `.shamt/unimplemented_design_proposals/`. When ready to export, run `bash .shamt/scripts/export/export.sh` — this will move the proposal doc to the master repo's `design_docs/unimplemented/` directory automatically."

If zero proposals were accepted:
- Note "No export warranted — no proposals accepted" in your completion announcement and proceed.

**Reference:** See `sync/export_workflow.md` for the full export process.

**Checkpoint:**
- [ ] Rules file compared against `RULES_FILE.template.md`; template updated with generic additions (or "no updates needed" noted)
- [ ] User informed about proposal doc export path (if applicable) or "no proposals accepted" noted

---

### Step 9: Mark S11.P1 Complete

**Purpose:** Update EPIC_README.md and announce completion

**Actions:**

9.1. **Update EPIC_README.md Agent Status:**

```markdown
## Agent Status

**Last Updated:** {YYYY-MM-DD HH:MM}
**Current Phase:** EPIC_FINALIZATION
**Current Step:** Ready for final commit and PR
**Current Guide:** stages/s11/s11_shamt_finalization.md
**Guide Last Read:** NOT YET (will read when starting Step 7)

**Progress:** S11.P1 complete (proposal doc created)
**Next Action:** Proceed to S11 Step 2 (Move Epic to done/ Folder)
**Blockers:** None

**S11.P1 Summary:**
- Proposals: {N} ({approved} approved, {modified} modified, {rejected} rejected)
- Proposals deferred: {N} (in {project_name}-SHAMT-{N}-{epic_name}-SHAMT-UPDATE-PROPOSAL.md)
- Commits: {N} (proposal doc + tracking)
```

9.2. **Announce completion:**

Use prompt from prompts/guide_update_prompts.md "After Creating Proposal Document" section

**Checkpoint:**
- [ ] EPIC_README.md updated
- [ ] Agent Status shows S11.P1 complete
- [ ] Next action is S11 Step 2 (Move Epic to done/ Folder)
- [ ] Completion announced to user

---

## Exit Criteria

**S11.P1 is complete when:**
- [ ] All lessons_learned.md files analyzed
- [ ] pr_comment_resolution.md analyzed (or confirmed absent)
- [ ] GUIDE_UPDATE_PROPOSAL.md created with all proposals
- [ ] If pr_comment_resolution.md exists: PR Review Comment Analysis section included in proposal doc
- [ ] User reviewed all proposals individually
- [ ] Proposal doc created in `.shamt/unimplemented_design_proposals/` (if any proposals accepted)
- [ ] Proposal doc committed (or skipped — gitignored / no accepted proposals)
- [ ] reference/guide_update_tracking.md updated
- [ ] Rules file compared against template; template updated if generic additions found
- [ ] User informed about proposal doc export (or "no proposals accepted" noted)
- [ ] EPIC_README.md shows S11.P1 complete
- [ ] Ready to proceed to S11 Step 2 (Move Epic to done/ Folder)

---

## Common Pitfalls

```text
┌────────────────────────────────────────────────────────────┐
│ "If You're Thinking This, STOP" - Anti-Pattern Detection  │
└────────────────────────────────────────────────────────────┘

❌ "This lesson seems minor, I'll skip it"
   ✅ STOP - Analyze ALL lessons, let priority system categorize

❌ "No guide gaps found, lessons are all domain-specific"
   ✅ VERIFY - Re-read lessons with fresh eyes, look for patterns

❌ "I'll update tracking later"
   ✅ STOP - Update tracking immediately while context fresh

❌ "I'll apply the proposals directly to the guide files"
   ✅ STOP - Proposals are deferred to .shamt/unimplemented_design_proposals/
   Do NOT edit any .shamt/guides/ files. Create the proposal doc only.
```

---

## Quick Reference: Proposal Quality Checklist

**Each proposal should have:**
- [ ] Clear lesson quote from lessons_learned.md
- [ ] Specific root cause explanation
- [ ] Exact guide path and section
- [ ] Before/after comparison (exact text)
- [ ] Rationale linking lesson → guide fix
- [ ] Impact assessment (who/when/severity)
- [ ] Priority correctly assigned (P0/P1/P2/P3)
- [ ] User decision checkboxes

**Red flags (fix before presenting):**
- Vague before/after ("improve clarity" without specific text)
- No clear connection between lesson and guide change
- Priority doesn't match severity description
- Missing rationale or impact assessment
- Proposing changes to code instead of guides

---

## Example Proposal (For Reference)

### Proposal P0-1: Add Spec Validation Historical Context to Mandatory Gates

**Lesson Learned:**
> "S5 Validation Loop Dimension 9 (Spec Alignment) caught that implementation_plan.md misinterpreted spec.md about week_N+1 folder logic. Spec said 'create week folders' but implementation plan said 'no code changes needed for folders.' This validation dimension prevented a week+ of rework implementing the wrong solution."

**Source File:** `epic_lessons_learned.md` - Lesson #3

**Root Cause:**
Agent rushed through S5 Phase 1 (Draft Creation) and made assumptions about folder handling instead of carefully reading spec.md. Dimension 9's spec alignment check (plan vs. spec.md requirements) caught the discrepancy during Validation Loop.

**Affected Guide(s):**
- `stages/s5/s5_v2_validation_loop.md` - Section: "Dimension 9: Spec Alignment"

**Current State (BEFORE):**
```markdown
### Dimension 9: Spec Alignment

**What to Check:**
- [ ] Implementation plan faithfully translates ALL spec requirements into steps
- [ ] No spec requirements missing from plan
- [ ] No additions beyond spec scope
```

**Proposed Change (AFTER):**
```markdown
### Dimension 9: Spec Alignment

**Historical Context:**
- Feature 02 catastrophic bug: implementation_plan.md misinterpreted spec.md
- Plan stated "no code changes needed" when spec actually required week_N+1 folder logic
- Dimension 9 specifically designed to prevent this type of bug
- Spec alignment check catches spec misinterpretations before implementation

**What to Check:**
- [ ] Implementation plan faithfully translates ALL spec requirements into steps
- [ ] No spec requirements missing from plan
- [ ] No additions beyond spec scope
```

**Rationale:**
Adding historical context shows future agents WHY this dimension exists and what happens if it's skipped. Real example makes the importance concrete instead of abstract.

**Impact Assessment:**
- **Who benefits:** All agents doing S5 v2 Validation Loop (Dimension 9)
- **When it helps:** When validating implementation_plan.md against spec.md
- **Severity if unfixed:** Critical - agents may skip or rush through Dimension 9 without understanding its importance, leading to week+ of rework from spec misinterpretation

**User Decision:** [ ] Approve  [ ] Modify  [ ] Reject  [ ] Discuss

**User Feedback/Modifications:**
```json
{User writes response here}
```

---

## Next Phase

**This is a sub-workflow of S11 (Shamt Finalization).**

**After completing S11.P1 (Guide Updates):** Return to `stages/s11/s11_shamt_finalization.md` to continue with:
- Step 2: Move Epic to done/ Folder

**📖 RETURN TO:** `stages/s11/s11_shamt_finalization.md`

---

*End of s11_p1_guide_update_workflow.md*

**Last Updated:** 2026-01-11
