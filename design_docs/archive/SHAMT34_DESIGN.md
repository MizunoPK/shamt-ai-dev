# SHAMT-34: Formalize S10 PR Creation, Comment Resolution, and Lessons Learned Integration

**Status:** Implemented
**Created:** 2026-04-09
**Branch:** `feat/SHAMT-34`
**Validation Log:** [SHAMT34_VALIDATION_LOG.md](./SHAMT34_VALIDATION_LOG.md)

---

## Problem Statement

S10 has three gaps around PR workflow and comment processing:

1. **PR creation is ambiguous.** Step 9 shows both `gh pr create` and a web UI fallback, but doesn't formalize that the agent should detect `gh` availability and create the PR autonomously when possible. The agent sometimes defers to the user unnecessarily.

2. **No comment resolution workflow exists.** After a PR is created and reviewers (human or AI) leave comments, there is no defined process for the agent to fetch those comments and produce structured comment resolution files. The user must manually relay comments or the agent improvises.

3. **PR comment insights are siloed.** Step 4b logs PR review findings into `audit/pr_review_findings_log.md`, a standalone file that is rarely referenced. The user wants PR comment analysis folded into the S10.P1 proposal doc instead — the same document that captures lessons learned and guide improvement proposals — so that a single artifact contains both lessons learned AND reviewer feedback for guide improvement purposes.

**Impact of NOT solving:** Agents continue to defer PR creation unnecessarily, comment resolution is ad-hoc with no standard format, and reviewer feedback that could improve guides is captured in a separate log that nobody reads.

---

## Goals

1. Formalize `gh` CLI detection in S10 Step 9 so the agent creates the PR autonomously when `gh` is installed and authenticated
2. Define a comment resolution workflow: agent fetches PR comments via `gh api`, creates structured comment resolution files, and works through resolutions
3. Replace the standalone `pr_review_findings_log.md` approach (Step 4b) with a section in the S10.P1 proposal doc that captures PR comment analysis for guide improvement purposes
4. Maintain backward compatibility — if `gh` is not available, the existing manual workflow still works

---

## Detailed Design

### Proposal 1: Conditional PR Creation via gh CLI

**Description:**

Add a `gh` availability check at the start of Step 9. If `gh auth status` succeeds, the agent creates the PR directly. If not, fall back to the existing "provide instructions to user" approach.

**Step 9 changes:**

```markdown
### 9a. Check gh CLI Availability

Run:
​```bash
gh auth status 2>&1
​```

- If exit code 0 → gh is installed and authenticated. Agent will create PR directly in Step 9b.
- If exit code non-zero → gh is not available or not authenticated. Skip to Step 9b-manual (provide PR creation instructions to user).
```

The existing `gh pr create` command in Step 9b remains unchanged — this proposal just formalizes the detection and removes the ambiguous "Or use GitHub Web UI" alternative when gh is available.

**Rationale:** Removes ambiguity and friction. When the tool is available, there's no reason for the agent to defer to the user for a mechanical operation.

---

### Proposal 2: PR Comment Resolution Workflow (New Step 9.5)

**Description:**

After the PR is created (Step 9) and the user directs the agent to process PR comments, add a new step where the agent fetches comments, creates comment resolution files, and works through each comment.

This step is **user-triggered** — the agent does not automatically fetch comments. The user tells the agent to process comments after reviewers have left feedback.

**New Step 9.5: PR Comment Resolution**

```markdown
### STEP 9.5: PR Comment Resolution (User-Triggered)

**Objective:** Fetch PR comments and create structured resolution files for systematic resolution.

**When to Execute:**
- User directs the agent to process PR comments (e.g., "get the PR comments and resolve them")
- PR has been reviewed and has comments to address

**Skip This Step If:**
- User does not request comment processing
- PR has no review comments

**Actions:**

**9.5a. Fetch PR Comments**

Retrieve all review comments from the PR:
​```bash
# Get PR number from current branch
PR_NUMBER=$(gh pr view --json number -q '.number')

# Fetch all review comments
gh api repos/{owner}/{repo}/pulls/${PR_NUMBER}/comments
​```

**9.5b. Create Comment Resolution File**

Create a comment resolution file at:
​```text
.shamt/epics/{epic_name}/pr_comment_resolution.md
​```

**File format:**
​```markdown
# PR Comment Resolution — SHAMT-{N}

**PR:** #{PR_NUMBER}
**Date:** {YYYY-MM-DD}
**Total Comments:** {N}
**Resolved:** 0/{N}

---

## Comment 1: {short description}

**Author:** {reviewer}
**File:** {file_path}:{line}
**Category:** [Bug | Style | Logic | Performance | Security | Documentation | Question | Other]

### Comment
> {exact comment text}

### Resolution
**Status:** [ ] Pending | [ ] Fixed | [ ] Won't Fix | [ ] Discussed

{Agent's response: what was done to address the comment, or why it was marked won't fix}

**Commit:** {commit hash, if a code change was made}

---
​```

**9.5c. Work Through Resolutions**

For each comment:
1. Read the comment and understand what the reviewer is asking
2. Determine the appropriate resolution (fix code, explain, discuss with user)
3. If code change needed: make the change, commit, update the resolution entry
4. If clarification needed: ask the user
5. If won't fix: document rationale

**9.5d. Update Resolution Summary**

After all comments are processed, update the header:
​```markdown
**Resolved:** {N}/{N}
​```

Push any new commits:
​```bash
git push origin {work_type}/SHAMT-{number}
​```
```

**Rationale:** Provides a structured, traceable process for handling PR feedback. The resolution file serves as an audit trail and can be referenced in the S10.P1 proposal doc for guide improvement analysis.

---

### Proposal 3: Integrate PR Comment Analysis into S10.P1 Proposal Doc

**Description:**

Replace the standalone Step 4b (`pr_review_findings_log.md`) with an integrated section in the S10.P1 proposal doc. When S10.P1 runs, it analyzes not only `lessons_learned.md` files but also the `pr_comment_resolution.md` file (if it exists) to extract guide improvement insights from reviewer feedback.

**Changes to S10.P1 (`s10_p1_guide_update_workflow.md`):**

1. **Step 1 addition:** After reading all `lessons_learned.md` files, also read `pr_comment_resolution.md` if it exists in the epic folder.

2. **Step 2 addition:** When identifying guide gaps, include PR comment patterns. Ask: "Did any reviewer comment reveal a gap that S7/S9 QC should have caught? Could a guide change prevent this class of comment in the future?"

3. **Proposal doc addition:** Add a new section to the proposal doc template:

```markdown
## PR Review Comment Analysis

**PR:** #{PR_NUMBER}
**Total Comments:** {N}
**Comments with Guide Improvement Potential:** {N}

### Comment-Derived Insights

For each comment that suggests a guide improvement opportunity:

| # | Comment Summary | Category | Why QC Missed It | Proposed Guide Change |
|---|----------------|----------|-------------------|----------------------|
| 1 | {summary} | {category} | {analysis} | {specific proposal or "N/A"} |

### Patterns Observed

{Any patterns across multiple comments — e.g., "3 of 5 comments were about error handling, suggesting S7 Dimension X needs strengthening"}
```

**Changes to S10 main guide (`s10_epic_cleanup.md`):**

- **Remove Step 4 (S10.P1) and Step 4b** from their current positions
- **Delete Step 4b entirely** — `pr_review_findings_log.md` is deleted, no replacement step needed at this position
- **Move S10.P1** to a new step after Step 9.5 (PR Comment Resolution) so it has access to both lessons learned and PR comment data
- **Renumber all steps** to reflect the new ordering

**New S10 Step Order:**

| New Step | Content | Old Step |
|----------|---------|----------|
| Step 1 | Pre-Cleanup Verification | Step 1 (unchanged) |
| Step 2 | Run Tests Per Testing Approach | Step 2 (unchanged) |
| Step 2b | Investigate Anomalies (optional) | Step 2b (unchanged) |
| Step 3 | Documentation Verification | Step 3 (unchanged) |
| Step 4 | Final Commit (Epic Implementation) | Step 5 |
| Step 5 | Move Epic to done/ Folder | Step 6 |
| Step 6 | Update EPIC_TRACKER.md | Step 7 |
| Step 7 | S10.P2 — Epic Overview Document (optional) | Step 8 |
| Step 8 | Push Branch and Create PR (with gh detection) | Step 9 |
| Step 8.5 | PR Comment Resolution (user-triggered) | NEW (Step 9.5) |
| Step 9 | S10.P1 — Guide Update from Lessons Learned + PR Comment Analysis | Step 4 (moved) |
| Step 10 | Final Verification & Completion | Step 10 (unchanged) |

**Rationale:** Consolidates all guide improvement signals (lessons learned + reviewer feedback) into a single artifact. The proposal doc becomes the one-stop reference for anyone looking to understand what could be improved. The standalone `pr_review_findings_log.md` is deleted entirely (it has zero entries and was never adopted) — the PR comment analysis section in the proposal doc fully replaces it.

**Alternatives considered:**

- *Keep Step 4b separate but cross-reference the proposal doc:* Rejected because it still results in two separate files to maintain, and the findings log has no entries after months of use — suggesting it's not integrated enough into the workflow.
- *Automate PR comment fetching without user trigger:* Rejected because comments arrive asynchronously and the agent can't know when review is complete without user signal.

---

**Recommended approach:** All three proposals together. They are complementary:
- Proposal 1 enables autonomous PR creation
- Proposal 2 gives a structured way to handle comments that come back
- Proposal 3 ensures those comments feed into guide improvement via the existing S10.P1 mechanism

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/guides/stages/s10/s10_epic_cleanup.md` | MODIFY | Update Step 9 (gh detection), add Step 9.5 (comment resolution), remove Step 4b, move S10.P1 to after Step 9.5, renumber steps, update workflow overview diagram |
| `.shamt/guides/stages/s10/s10_p1_guide_update_workflow.md` | MODIFY | Add PR comment analysis to Steps 1-2, add proposal doc section template |
| `.shamt/guides/reference/stage_10/stage_10_reference_card.md` | MODIFY | Add Step 9.5 to workflow overview, update step table |
| `.shamt/guides/templates/comment_resolution_template.md` | CREATE | Template for `pr_comment_resolution.md` |
| `.shamt/guides/audit/pr_review_findings_log.md` | DELETE | Replaced by PR comment analysis section in S10.P1 proposal doc |
| `.shamt/guides/prompts/s10_prompts.md` | MODIFY | Add prompt for PR comment resolution step |
| `.shamt/scripts/initialization/RULES_FILE.template.md` | MODIFY | Update S10 section if PR workflow is mentioned |

---

## Implementation Plan

### Phase 1: Formalize gh CLI Detection (Step 9 Update)
- [x] Read current Step 9 in `s10_epic_cleanup.md`
- [x] Add `gh auth status` check as Step 8b
- [x] Split Step 8c into 8c (agent creates PR when gh available) and 8c-manual (fallback instructions)
- [x] Update reference card with gh detection note
- [x] Verify Step 8 still reads correctly end-to-end

### Phase 2: Add Comment Resolution Workflow (New Step 8.5)
- [x] Create `templates/comment_resolution_template.md` with the file format
- [x] Add Step 8.5 to `s10_epic_cleanup.md` after Step 8
- [x] Add Step 8.5 to the Workflow Overview diagram
- [x] Add Step 8.5 to the Quick Navigation table
- [x] Add Step 8.5 exit criteria to Exit Criteria section
- [x] Add prompt for comment resolution to `s10_prompts.md`
- [x] Update reference card

### Phase 3: Reorder S10 Workflow and Integrate PR Comments into S10.P1
- [x] Move S10.P1 from Step 4 to after Step 8.5 as Step 9 in `s10_epic_cleanup.md`
- [x] Remove Step 4b (Log PR Review Findings) from `s10_epic_cleanup.md`
- [x] Renumber steps in `s10_epic_cleanup.md` to reflect new ordering
- [x] Update Workflow Overview diagram with new step order
- [x] Update Quick Navigation table with new step numbers
- [x] Update Step 1 in `s10_p1_guide_update_workflow.md` to include reading `pr_comment_resolution.md`
- [x] Update Step 2 to include PR comment analysis in guide gap identification
- [x] Add "PR Review Comment Analysis" section to the proposal doc template in Step 5
- [x] Update S10.P1 exit criteria to include PR comment analysis (when resolution file exists)
- [x] Delete `pr_review_findings_log.md`
- [x] Remove all references to `pr_review_findings_log.md` across guides

### Phase 4: Cross-References and Consistency
- [x] Update all cross-references between affected files to reflect new step numbers
- [x] Update exit criteria in `s10_epic_cleanup.md` to match new ordering
- [x] Verify exit criteria are complete and consistent
- [x] Verified `RULES_FILE.template.md` — no S10 PR workflow step references, no update needed
- [x] Update reference card with new step ordering

### Phase 5: Validation
- [ ] Run implementation validation after all changes
- [ ] Run full guide audit (3 consecutive clean rounds)

---

## Validation Strategy

- **Primary validation:** Design doc validation loop (7 dimensions) until primary clean round + 2 independent sub-agent confirmations
- **Implementation validation:** After implementation, verify all files in "Files Affected" table were created/modified as specified (5 dimensions)
- **Testing approach:** Manual review — verify the workflow reads correctly, step references are consistent, and the template is usable
- **Success criteria:**
  - Step 9 clearly branches on `gh auth status`
  - Step 9.5 has a complete, usable template and clear trigger conditions
  - S10.P1 proposal doc includes PR comment analysis section when resolution file exists
  - All cross-references (workflow overview, quick nav, exit criteria, reference card) are updated
  - Guide audit passes 3 consecutive clean rounds

---

## Open Questions

1. ~~**Step ordering for S10.P1 and PR comments:**~~ **RESOLVED — Option A selected.** Move S10.P1 entirely to after PR Comment Resolution. See "New S10 Step Order" table in Proposal 3 for the authoritative renumbered step sequence. Step 4b is removed entirely.

2. ~~**Deprecation of `pr_review_findings_log.md`:**~~ **RESOLVED — Delete entirely.** File has zero entries after months of existence, was never adopted, and is fully replaced by the PR comment analysis section in the S10.P1 proposal doc.

---

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `gh` not installed in some environments | Medium | Low | Fallback to manual workflow is preserved |
| PR has no comments (Step 9.5 is a no-op) | High | None | Step is explicitly user-triggered and skippable |
| Proposal doc becomes too long with PR comment analysis | Low | Low | Section is tabular and concise by design |
| Step renumbering causes stale references | Medium | Medium | Phase 4 dedicated to cross-reference sweep across all affected files |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-09 | Initial draft created |
| 2026-04-09 | Resolved Open Question 1: Move S10.P1 entirely to after Step 9.5 (Option A). Updated workflow ordering, implementation plan, and risk table. |
| 2026-04-09 | Changed `pr_review_findings_log.md` from deprecation to full deletion. File has zero entries and is fully replaced by proposal doc PR comment analysis section. |
| 2026-04-09 | Validation Round 1: Fixed 3 issues (2 MEDIUM, 1 LOW). Resolved Open Question 2, added concrete step renumbering table, rewrote stale Proposal 3 description. |
| 2026-04-09 | Validation Round 2: Fixed 1 LOW issue (stale step numbers in Open Questions). Clean round achieved. |
| 2026-04-09 | Validation complete: Both sub-agents confirmed zero issues. Status changed to Validated. |
