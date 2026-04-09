# S10.P1: Epic Overview Document

**File:** `s10_p1_overview_workflow.md`

---


## Table of Contents

1. [S10.P1: Epic Overview Document](#s10p2-epic-overview-document)
2. [Overview](#overview)
3. [Critical Rules](#critical-rules)
4. [Prerequisites Checklist](#prerequisites-checklist)
5. [Step-by-Step Workflow](#step-by-step-workflow)
6. [Exit Criteria](#exit-criteria)
7. [Common Pitfalls](#common-pitfalls)
8. [Example Document Skeleton](#example-document-skeleton)

---
🔔 **OPTIONAL READING PROTOCOL**

**Before starting this guide:**
1. Use Read tool to load THIS ENTIRE GUIDE
2. Acknowledge critical requirements (see "Critical Rules" section below)
3. Verify prerequisites (see "Prerequisites Checklist" section below)

**This phase is opt-in.** If the user declines when asked in Step 1, skip this guide entirely and proceed to Step 9 (Push and Create PR) in `stages/s10/s10_epic_cleanup.md`.

**After session compaction:**
- Re-read this guide before continuing
- Check what step you were on and resume from there

---

## 🚫 FORBIDDEN SHORTCUTS

You CANNOT:
- Write the overview document before completing the narrative planning in Step 3 — planning first is what produces a coherent, useful document
- Skip asking the user (Step 1) and proceed directly to writing — the phase is opt-in and the question must always be asked

If you are about to do any of the above: STOP and re-read the relevant section.

---

## Overview

**What is this phase?**
S10.P2 is the optional epic overview document phase where you create `SHAMT-{N}-OVERVIEW.md` — a narrative document that explains the full story of the epic to PR reviewers and developers onboarding onto the work.

**When do you use this guide?**
- Step 7 (EPIC_TRACKER update) is complete
- You are about to proceed to Step 9 (Push and Create PR)
- The user has said "yes" to creating the overview document

**Key Outputs (if opted in):**
- ✅ `SHAMT-{N}-OVERVIEW.md` created at repository root
- ✅ Validation loop passed (2 consecutive clean rounds)
- ✅ Overview document committed as standalone commit

**Time Estimate:**
20-40 minutes depending on epic size and number of features

**Exit Condition:**
S10.P2 is complete when the overview document is committed (if opted in) or the user has declined (if not). Either outcome is a valid completion.

---

## Critical Rules

```text
┌─────────────────────────────────────────────────────────────┐
│ CRITICAL REQUIREMENTS - READ BEFORE PROCEEDING              │
└─────────────────────────────────────────────────────────────┘

1. ⚠️ ALWAYS ask the user before starting
   - Ask using the exact prompt in Step 1
   - If user declines: skip this entire guide, proceed to Step 9
   - If user accepts: continue through all 6 steps

2. ⚠️ Plan the narrative BEFORE writing a single section
   - Complete Step 3 (narrative planning) in full before Step 4
   - State the story spine, organization choice, and rationale
   - Writing without planning produces a disorganized document

3. ⚠️ The document is for a cold reader
   - Assume the reader is a developer with NO prior context on this epic
   - Explain everything that would be confusing without context
   - Do not assume familiarity with decisions made during the epic

4. ⚠️ Complete File Changelog must be exhaustive
   - Every file in `git diff origin/main...HEAD` must appear in Section 7
   - No file omissions — partial changelogs mislead reviewers
   - One sentence per file is sufficient for large diffs

5. ⚠️ Validation loop required before committing
   - Run the 4-dimension validation loop (Step 5)
   - Exit criterion: Primary clean round + sub-agent confirmation (consistent with master validation loop protocol)
   - If the same issue persists 3+ rounds: surface to user rather than looping

6. ⚠️ Standalone commit
   - Commit ONLY the overview document in this commit
   - Commit message: "docs/SHAMT-{N}: Add epic overview document"
   - Do NOT mix this commit with other changes
```

---

## Prerequisites Checklist

**Verify BEFORE starting S10.P2:**

- [ ] Step 7 (EPIC_TRACKER update) is complete and committed
- [ ] User has said "yes" to creating the overview document (Step 1 completed)
- [ ] No uncommitted changes in working tree (run `git status`)
- [ ] Ready to gather context and write the overview

**If any prerequisite fails:**
- ❌ STOP - Do NOT proceed with S10.P2
- Return to the prerequisite step to resolve

---

## Step-by-Step Workflow

### Step 1: Ask the User

**Purpose:** Get explicit user consent before investing time on this optional phase.

**Ask exactly:**

> "Would you like to create an epic overview document (`SHAMT-{N}-OVERVIEW.md`) for PR reviewers and future contributors? This document will narrate the epic's goals, decisions, and code changes in detail. It will be committed to the branch and visible in the PR diff. (yes / no)"

**If user says no:** Note the decision, skip to Step 9 (Push and Create PR) in `stages/s10/s10_epic_cleanup.md`. Do not create any files.

**If user says yes:** Continue to Step 2.

---

### Step 2: Gather Context

**Purpose:** Collect all available information about the epic before writing.

**Run the following in parallel:**

2a. **Git history and file list:**
```bash
git log origin/main..HEAD --stat
git diff origin/main...HEAD --name-status
```

2b. **Read epic documentation:**
- Read `EPIC_README.md`
- Read `epic_lessons_learned.md`
- Read the epic's detail section in `.shamt/epics/EPIC_TRACKER.md`

2c. **Read all feature README files:**
```bash
## Find all feature README files
ls .shamt/epics/done/SHAMT-{N}-{epic_name}/
```
Read each feature's `README.md` file.

**After gathering:**
- Note total number of changed files
- Note number of features
- Note any especially significant design decisions documented in EPIC_README
- Note the EPIC_TRACKER detail section — this is the most complete prose summary of the epic

**Checkpoint:**
- [ ] git log and git diff output reviewed
- [ ] EPIC_README.md read
- [ ] epic_lessons_learned.md read
- [ ] EPIC_TRACKER detail section read
- [ ] All feature README files read

---

### Step 3: Plan the Narrative

**Purpose:** Reason through the story structure BEFORE writing a single section. An intentional structure produces a document that reads as a coherent whole; writing without planning produces a disconnected list.

**Before writing anything, answer all four questions:**

**3a. Story spine:**
> "What is the one sentence that captures the through-line from problem to solution?"

State it explicitly. Example: "This epic replaced an ad-hoc CLI invocation pattern with a structured multi-agent Task-spawning protocol, eliminating race conditions and context leakage in parallel agent workflows."

**3b. Change organization:**
> "Should Section 6 (Changes by Feature/Component) be organized by feature, by layer (frontend/backend/infra), or by impact (foundational first)? Which organization best serves a cold reader of this specific epic?"

State the chosen organization and why.

**3c. Foundation vs. dependent:**
> "Which changes are foundational (must be understood first before other changes make sense) vs. dependent (build on something else)?"

List foundational changes first in Section 6. Dependent changes can reference what they build on.

**3d. Assumed knowledge:**
> "What can be assumed? (Fellow developer familiar with the stack, no epic context.) What must be explained?"

List what needs explanation. Do not pad sections explaining obvious things — focus explanation on decisions and non-obvious choices.

**State your choices** before moving to Step 4. This documents the reasoning and makes the structure intentional.

**Checkpoint:**
- [ ] Story spine stated (one sentence)
- [ ] Organization approach chosen and justified
- [ ] Foundational vs. dependent changes identified
- [ ] Assumptions documented

---

### Step 4: Write the Document

**Purpose:** Create `SHAMT-{N}-OVERVIEW.md` at the repository root following the section specification.

**File location:** Repository root (e.g., `/SHAMT-15-OVERVIEW.md`)

**Write all 10 sections:**

| # | Section | What to include |
|---|---------|-----------------|
| 1 | **Epic Header** | Epic name, SHAMT number, branch name, date created |
| 2 | **Problem Statement** | What gap or problem this epic addressed; why it was needed; what would have continued without this work |
| 3 | **Goals** | Bulleted list of what this epic set out to achieve; maps to features |
| 4 | **Solution Overview** | High-level narrative of the approach taken; how the pieces relate to each other |
| 5 | **Architecture & Key Decisions** | Important design decisions, with rationale — not just what was decided, but why alternatives were considered and rejected |
| 6 | **Changes by Feature / Component** | For each feature: starting state, what changed, why, and how it connects to epic goals. Order foundational changes first. |
| 7 | **Complete File Changelog** | Table: `\| File \| Change Type \| Description \|` — every file in the git diff, one row per file |
| 8 | **Testing Summary** | How changes were tested, what scenarios were validated, results |
| 9 | **Out of Scope / Known Limitations** | What was explicitly excluded and why; known issues; planned follow-on work |
| 10 | **Review Guidance** | How a PR reviewer should approach this branch; what to focus on; suggested review order |

**Writing guidelines:**

- **Section 2 (Problem Statement):** Be specific. "The existing workflow lacked X" is vague. "Agents spawning parallel subtasks had no coordination protocol, causing Y" is concrete.
- **Section 5 (Architecture & Key Decisions):** This is the most valuable section for reviewers. Explain not just what was decided but what alternatives were rejected and why.
- **Section 6 (Changes by Feature):** Use the organization chosen in Step 3. Present foundational changes before dependent ones. Each feature entry should stand alone — a reviewer reading only that entry should understand what changed and why.
- **Section 7 (Complete File Changelog):** List every file from `git diff origin/main...HEAD --name-status`. Change Type values: `Added`, `Modified`, `Deleted`, `Renamed`. One sentence description per file. Do not truncate.
- **Section 10 (Review Guidance):** Write this from the perspective of "what would help me review this if I knew nothing about it?" Suggest a review order. Call out any particularly complex or risky changes to scrutinize.

**Edge cases:**

- **Large diff (100+ changed files):** Group changes by feature/component in Section 6 rather than listing every file in the narrative. Section 7 still lists every file, but one sentence per file is sufficient.
- **Small diff (1-3 files):** Same structure, but most sections will be short. Do not pad sections to fill space.
- **Large document (10,000+ words):** Prioritize depth in Sections 5 and 6. Keep Section 7 at one sentence per file. Keep Sections 8 and 10 concise.

**Checkpoint:**
- [ ] `SHAMT-{N}-OVERVIEW.md` created at repository root
- [ ] All 10 sections present
- [ ] Section 7 lists every file from git diff
- [ ] Cold-reader perspective maintained throughout

---

### Step 5: Validation Loop

**Purpose:** Verify the document is correct, complete, consistent, and clear before committing.

**Run `git diff origin/main...HEAD --name-status` to get the authoritative file list** before starting validation.

**Check all 4 dimensions in every round:**

**Dimension 1 — Correctness:**
- Every described code change matches the actual `git diff origin/main...HEAD`
- No claims about changes that did not happen
- No omissions that distort the picture of what was done
- All file paths and names are correct

**Dimension 2 — Completeness:**
- Every file in the git diff is accounted for in Section 7 (Complete File Changelog)
- All goals stated in `EPIC_README.md` are addressed somewhere in the document
- No feature was omitted from Section 6

**Dimension 3 — Consistency:**
- No contradictions between this document and `EPIC_README.md`
- No contradictions between this document and feature `README.md` files
- No contradictions between this document and the EPIC_TRACKER entry
- Terminology is consistent throughout (same names for same things)
- No internal contradictions between sections

**Dimension 4 — Clarity:**
- A developer with zero prior context on this epic could read this document and understand: what was done, why it was done, and how to review the changes effectively
- The Review Guidance section (Section 10) is actionable, not generic
- Architecture decisions (Section 5) explain the "why," not just the "what"

**Exit criterion:** Primary clean round (zero issues) + independent sub-agent confirmation (consistent with master validation loop protocol)

**Round tracking:**
- State `consecutive_clean = {n}` at the end of every round
- Any issue found resets `consecutive_clean` to 0
- Fix all issues before starting the next round
- If the same issue persists across 3+ consecutive rounds, STOP looping — describe the issue to the user and ask for guidance

**Checkpoint:**
- [ ] Primary validation round completed with zero issues (consecutive_clean = 1)
- [ ] 2 independent sub-agents spawned in parallel to confirm zero issues
- [ ] Both sub-agents confirmed zero issues (validation loop exits)
- [ ] All issues found during validation have been fixed

---

### Step 6: Commit

**Purpose:** Commit the overview document as a standalone commit.

**6a. Stage only the overview document:**
```bash
git add SHAMT-{N}-OVERVIEW.md
```

**6b. Create the commit:**
```bash
git commit -m "docs/SHAMT-{N}: Add epic overview document"
```

The `docs/SHAMT-{N}:` format uses the slash convention consistent with other S10 sub-commits (e.g., `chore/SHAMT-{N}: Move completed epic to done/`, `chore/SHAMT-{N}: Update EPIC_TRACKER`). The `docs` type is used (rather than `chore`) because this commit produces a substantive documentation artifact visible to PR reviewers.

**6c. Verify the commit:**
```bash
git log -1 --stat
```

Verify:
- Only `SHAMT-{N}-OVERVIEW.md` in the commit stat
- Commit message format is correct
- File is at repository root (not in a subdirectory)

**Checkpoint:**
- [ ] Only the overview document staged
- [ ] Commit created with correct message format
- [ ] Commit verified with `git log -1 --stat`
- [ ] S10.P2 complete — proceed to Step 9 (Push and Create PR)

---

## Exit Criteria

**S10.P2 is complete when ONE of the following is true:**

**Option A — Opted in:**
- [ ] User said "yes" in Step 1
- [ ] All context gathered (Step 2)
- [ ] Narrative planned (story spine, organization, foundation/dependent, assumed knowledge)
- [ ] `SHAMT-{N}-OVERVIEW.md` created at repository root with all 10 sections
- [ ] Validation loop passed (primary clean round + sub-agent confirmation)
- [ ] Overview document committed as standalone commit (`docs/SHAMT-{N}: Add epic overview document`)
- [ ] Commit verified with `git log -1 --stat`
- [ ] Ready to proceed to Step 9 (Push and Create PR)

**Option B — Declined:**
- [ ] User said "no" in Step 1
- [ ] No files created
- [ ] Ready to proceed to Step 9 (Push and Create PR)

---

## Common Pitfalls

```text
┌────────────────────────────────────────────────────────────┐
│ "If You're Thinking This, STOP" - Anti-Pattern Detection  │
└────────────────────────────────────────────────────────────┘

❌ "I'll start writing the document and figure out the structure as I go"
   ✅ STOP - Complete narrative planning (Step 3) before writing a single section

❌ "I'll skip asking the user and just create the document"
   ✅ STOP - Always ask first (Step 1). The phase is opt-in.

❌ "Section 7 is getting long, I'll just include the most important files"
   ✅ STOP - Complete File Changelog must list every file. One sentence per file is fine.

❌ "The reviewer is smart, they'll understand what the architecture decisions mean"
   ✅ Explain the "why" explicitly. Section 5 is the most valuable section to reviewers.

❌ "One clean validation round is probably enough"
   ✅ STOP - The exit criterion is primary clean round + sub-agent confirmation. Complete both.

❌ "I'll note the same validation issue and loop again hoping it resolves itself"
   ✅ STOP - If the same issue persists 3+ rounds, surface it to the user.
```

---

## Example Document Skeleton

Use this skeleton as a template when writing the document. Replace each `[...]` with actual content.

```markdown
# SHAMT-{N}: {Epic Name} — Epic Overview

**SHAMT Number:** {N}
**Branch:** feat/SHAMT-{N}
**Date Created:** {YYYY-MM-DD}

---

## 1. Problem Statement

[What gap or problem existed before this epic. What would have continued if the work had not been done. Be specific: name the concrete failure mode or missing capability.]

---

## 2. Goals

- [Goal 1 — maps to feature_01]
- [Goal 2 — maps to feature_02]
- [Goal 3 — maps to feature_03]

---

## 3. Solution Overview

[High-level narrative of the approach. How the pieces fit together. Why this approach was chosen over alternatives. Written for a developer who understands the stack but knows nothing about this epic.]

---

## 4. Architecture & Key Decisions

### Decision 1: [Decision title]

**Context:** [Why this decision was needed]
**Decision:** [What was decided]
**Alternatives considered:** [What else was evaluated and why it was rejected]
**Rationale:** [Why this was the right choice for this epic]

### Decision 2: [Decision title]

[Same structure]

---

## 5. Changes by Feature / Component

### Feature 01: [Feature name]

**Starting state:** [What existed before this feature]
**Changes made:** [What was implemented and why]
**Connection to epic goals:** [How this feature contributes to the overall epic objectives]

### Feature 02: [Feature name]

[Same structure]

---

## 6. Complete File Changelog

| File | Change Type | Description |
|------|-------------|-------------|
| `path/to/file.py` | Modified | [One sentence description of what changed] |
| `path/to/new_file.py` | Added | [One sentence description of what this file does] |
| `path/to/old_file.py` | Deleted | [One sentence description of why it was removed] |

---

## 7. Testing Summary

[How the changes were tested. What scenarios were validated. Test pass rates. Any manual testing performed. What would break if the changes were incorrect.]

---

## 8. Out of Scope / Known Limitations

- [Thing explicitly excluded from this epic and why]
- [Known issue or edge case not addressed]
- [Planned follow-on work in a future epic]

---

## 9. Review Guidance

**Suggested review order:**
1. [Read X first — it establishes the foundational pattern]
2. [Then read Y — it implements the pattern in the main flow]
3. [Then read Z — it handles edge cases that depend on X and Y]

**Key areas to focus on:**
- [Section of code where the most complex logic lives]
- [Any behavior change that might have non-obvious side effects]
- [Any pattern that future features will need to follow]

**What is not worth detailed scrutiny:**
- [Mechanical changes — file renames, format updates, etc.]

**Post-merge lifecycle:** This file (`SHAMT-{N}-OVERVIEW.md`) will remain in main unless explicitly removed. The team may: (a) keep it as historical documentation, (b) delete it in a follow-on cleanup commit, or (c) move it to a `docs/` folder. Decide at review time.
```

---

## Next Phase

**This is a sub-workflow of S10 (Epic Cleanup).**

**After completing S10.P2 (or if user declined):** Return to `stages/s10/s10_epic_cleanup.md` to continue with:
- Step 9: Push Branch and Create Pull Request

**📖 RETURN TO:** `stages/s10/s10_epic_cleanup.md`

---

*End of s10_p1_overview_workflow.md*

**Last Updated:** 2026-03-28
