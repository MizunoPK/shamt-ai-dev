# Guide Update Prompts: Lessons Learned to Guide Improvements

**Stage:** 7.5 (Between user testing and final commit)
**Purpose:** Create guide update proposal doc from epic lessons learned (deferred to master for implementation)

---

## Starting S10.P1: Guide Update from Lessons Learned (MANDATORY)

**User says:** Agent detects S9 user testing passed (S9 Step 6), OR user says "apply lessons to guides"

**Prerequisite:** S9 user testing passed (zero bugs), all lessons_learned.md files complete

**Agent MUST respond:**

```markdown
I'm reading `stages/s10/s10_p1_guide_update_workflow.md` to create a guide update proposal doc from lessons learned...

**The guide requires:**
- **Analyze ALL lessons_learned.md files** from this epic:
  - epic_lessons_learned.md (epic-level lessons)
  - feature_XX_{name}/lessons_learned.md (all feature-level lessons)
- **Identify guide gaps:** For each lesson, determine which guide(s) could have prevented the issue
- **Create prioritized proposals** in GUIDE_UPDATE_PROPOSAL.md:
  - P0 (Critical): Prevents catastrophic bugs, mandatory gate gaps
  - P1 (High): Significantly improves quality, reduces major rework
  - P2 (Medium): Moderate improvements, clarifies ambiguity
  - P3 (Low): Minor improvements, cosmetic fixes
- **Get user approval INDIVIDUALLY:** Each proposal gets Approve/Modify/Reject/Discuss
- **Create proposal doc** (`{project_name}-{epic_name}-SHAMT-UPDATE-PROPOSAL.md`) in `.shamt/unimplemented_design_proposals/`
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
✅ S9 user testing passed (S9 Step 6)
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

---

## Presenting Proposals to User

**Trigger:** Agent completes GUIDE_UPDATE_PROPOSAL.md with all prioritized proposals

**Agent MUST present:**

```bash
🚨 **S10.P1: Guide Update Proposals Ready for Review**

I've analyzed all lessons learned from this epic and created prioritized guide update proposals.

**Summary:**
- Total lessons analyzed: {N} ({epic-level} epic, {feature-level} feature)
- Total proposals: {N}
  - P0 (Critical): {N} proposals - prevents catastrophic bugs
  - P1 (High): {N} proposals - significantly improves quality
  - P2 (Medium): {N} proposals - moderate improvements
  - P3 (Low): {N} proposals - minor improvements

**Proposal file:** `GUIDE_UPDATE_PROPOSAL.md`

**How to review:**
1. I'll present each proposal starting with P0 (critical)
2. For each proposal, you'll see:
   - The lesson learned (what went wrong/right)
   - Which guide(s) would be updated
   - Before/after comparison (exact text changes)
   - Rationale (how this prevents future issues)
3. Please respond for each proposal:
   - ✅ **Approve** - Apply as proposed
   - ✏️ **Modify** - Provide alternative text
   - ❌ **Reject** - Skip this change
   - 💬 **Discuss** - Ask questions or request clarification

**I'll start with P0 (Critical) proposals - these prevent major bugs:**

---

**Proposal P0-1:** {Title}

**Lesson Learned:**
> "{Quote from lessons_learned.md}"

**Problem:** {What went wrong and why}

**Affected Guide:** `{path/to/guide.md}` - Section: "{section}"

**Current text (BEFORE):**
```
{Current guide text}
```bash

**Proposed change (AFTER):**
```
{Proposed new text - highlighting additions/changes}
```markdown

**Why this helps:** {How this prevents future agents from same issue}

**Your decision for Proposal P0-1:** Approve / Modify / Reject / Discuss?
```

---

## After User Approval

**Trigger:** User has reviewed all proposals and provided decisions

**Agent MUST respond:**

```bash
✅ **Guide Update Approvals Received**

**Summary of decisions:**
- Total proposals: {N}
- Approved: {N} proposals
- Modified: {N} proposals (user provided alternatives)
- Rejected: {N} proposals
- Pending discussion: {N} proposals

**Proposals to capture in proposal doc:**

{For each approved/modified proposal:}
✅ Proposal P{X}-{N}: {Title}
   - Affected guide: {guide_path}
   - Change: {brief description}

**Next steps:**
1. Create proposal doc in `.shamt/unimplemented_design_proposals/`
2. Commit proposal doc
3. Update reference/guide_update_tracking.md
4. Proceed to S10 Step 5 (Final Commit)

Creating proposal doc...
```

---

## After Creating Proposal Document

**Trigger:** Agent completes creating the proposal doc (or determines zero proposals accepted)

**Agent MUST respond:**

```markdown
✅ **Guide Update Proposal Doc Created**

**Proposal doc:**
- File: `{project_name}-{epic_name}-SHAMT-UPDATE-PROPOSAL.md`
- Location: `.shamt/unimplemented_design_proposals/`
- Commit: {proposal_commit_hash} (or "not committed — gitignored")

**Proposals captured:**
- P0 (Critical): {N}
- P1 (High): {N}
- P2 (Medium): {N}
- P3 (Low): {N}
- Rejected: {N}

**Updated tracking:**
- ✅ reference/guide_update_tracking.md updated
- ✅ Proposal doc path logged
- ✅ Rejected proposals documented with rationale

**Next step:** When ready to send proposals to master, run `bash .shamt/scripts/export/export.sh` — this automatically moves the proposal doc to the master repo's `design_docs/unimplemented/`.

**Next: S10 Step 5 - Final Commit**

I'll now proceed with creating the epic commit.

Following `stages/s10/s10_epic_cleanup.md` Step 5...
```

---

## Handling "Modify" Responses

**Trigger:** User requests modification instead of approving as-is

**Agent MUST respond:**

```markdown
📝 **Modification Request Received for Proposal P{X}-{N}**

**Your modification:**
> {User's alternative text}

**I'll capture your version in the proposal doc instead of my original proposal.**

**Recording your modification:**
- Affected guide: {path/to/guide.md}
- Section: {section}
- Using your text: "{user's text preview...}"

Modification recorded ✅

{Continue with next proposal if more exist}
```

---

## Handling "Discuss" Responses

**Trigger:** User requests discussion/clarification on proposal

**Agent MUST respond:**

```markdown
💬 **Discussion Request for Proposal P{X}-{N}**

**Your question/concern:**
> {User's question or concern}

**My response:**
{Agent provides clarification, examples, or additional context}

**Would you like to:**
1. Approve the original proposal
2. Propose a modification
3. Reject this proposal
4. Continue discussion

Please let me know your decision.
```

---

## Handling "Reject" Responses

**Trigger:** User rejects proposal

**Agent MUST respond:**

```markdown
❌ **Proposal P{X}-{N} Rejected**

**Understood.** I'll skip this guide update.

**Documenting rejection:**
- Adding to reference/guide_update_tracking.md "Rejected Lessons" section
- Rationale: {User's reason if provided, or "User declined"}

This helps avoid re-proposing the same change in future epics.

{Continue with next proposal if more exist}
```

---

## If No Proposals Generated

**Trigger:** Agent analyzes lessons but finds no actionable guide improvements

**Agent MUST respond:**

```markdown
✅ **Lessons Learned Analyzed - No Guide Updates Needed**

I've analyzed all lessons learned from this epic:
- Epic lessons: {N}
- Feature lessons: {N}
- Total: {N} lessons

**Analysis result:**
All lessons were either:
- Specific to this epic's domain (not generalizable to guides)
- Already covered by existing guide content
- User-specific decisions (not guide issues)

**No guide update proposals to present.**

**Next: S10 Step 5 - Final Commit**

I'll proceed directly to creating the epic commit.

Following `stages/s10/s10_epic_cleanup.md` Step 5...
```

---

*For prompts for other stages, see the [prompts index](../prompts_reference_v2.md)*
