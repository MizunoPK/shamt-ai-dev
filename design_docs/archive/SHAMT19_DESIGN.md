# SHAMT-19 Design: S10.P2 — Epic Overview Document Phase

**Status:** Draft
**Branch:** `feat/SHAMT-19`

---

## Problem

When an epic branch is ready for a PR, reviewers and future contributors have no single narrative document that explains:

- What problem the epic solved and why it mattered
- What changes were made and the reasoning behind each decision
- How the pieces fit together as a coherent whole

`EPIC_README.md` tracks status and planning intent. `EPIC_TRACKER.md` summarizes at a high level. Feature `README.md` files describe individual features in isolation. But none of these are written for a developer who is cold to the epic and needs to understand the branch quickly. PR reviewers currently must reconstruct the story from commits, diffs, and scattered feature READMEs — a high-friction, error-prone process that leads to shallow reviews.

---

## Solution

Add **S10.P2** — an opt-in phase in S10 Epic Cleanup — where the agent creates a `SHAMT-{N}-OVERVIEW.md` document at the repository root. The document is narrative-driven, tells the full story of the epic, and is explicitly authored for two audiences: PR reviewers and developers onboarding onto the work.

The phase is opt-in: the agent asks the user before starting. If the user declines, the phase is skipped without any side effects. If the user accepts, the agent:

1. Gathers all available context (git log, git diff, feature READMEs, EPIC_README, EPIC_TRACKER entry)
2. Plans the narrative structure before writing — explicitly reasons about story spine and organization
3. Creates the document
4. Runs a validation loop verifying correctness, completeness, and consistency
5. Commits the document to the branch as a standalone commit

---

## Position in S10 Flow

### S10 step order after this change

| # | Step | Notes |
|---|------|-------|
| 1 | Pre-Cleanup Verification | unchanged |
| 2 | Run Tests Per Testing Approach | unchanged |
| 2b | Investigate User-Reported Anomalies | optional, unchanged |
| 3 | Documentation Verification | unchanged |
| 4 | S10.P1 — Guide Update from Lessons Learned | unchanged |
| 5 | Final Commit (Epic Implementation) | unchanged |
| 6 | Move Epic to `done/` Folder | unchanged |
| 7 | Update `EPIC_TRACKER.md` | unchanged |
| **8** | **S10.P2 — Epic Overview Document** | **new — optional** |
| 9 | Push Branch and Create Pull Request | renumbered *(was Step 8)* |
| 10 | Final Verification & Completion | renumbered *(was Step 9)* |

### Rationale for this position

S10.P2 must occur **after** Step 7 (EPIC_TRACKER update) so the agent has the finalized epic summary to draw from — EPIC_TRACKER's epic detail section is the most complete prose description of the epic and informs the overview.

S10.P2 must occur **before** Step 9 (push + PR creation) so the overview document is committed to the branch and visible in the PR diff for reviewers.

---

## Document Specification

### File location

Repository root: `SHAMT-{N}-OVERVIEW.md` (e.g., `SHAMT-15-OVERVIEW.md`)

**Why root:** The file is intended for PR reviewers. Placing it at the root makes it immediately discoverable in the GitHub PR interface without navigating subdirectories. The `SHAMT-{N}` prefix makes it unambiguously epic-specific. The epic name slug is omitted from the filename (i.e., `SHAMT-15-OVERVIEW.md` rather than `SHAMT-15-user-auth-OVERVIEW.md`) to keep the filename short and clean — the SHAMT number alone is unique per project, and the epic name is fully described inside the document.

**Post-merge lifecycle:** The file remains in main after merge unless the team removes it. Teams may: (a) keep it permanently as historical documentation, (b) delete it in a follow-on cleanup commit, or (c) move it to a `docs/` folder. The Shamt framework does not prescribe a choice — the guide should mention the options and recommend the team decide at PR review time.

**Sync system interaction:** The Shamt export and import workflows operate exclusively on `.shamt/guides/` and `.shamt/scripts/`. A `SHAMT-{N}-OVERVIEW.md` file at the repository root is never touched by export or import — it is project-specific and stays local to the child project. No sync exclusion or gitignore entry is needed for this file.

### Content sections

| # | Section | Purpose |
|---|---------|---------|
| 1 | **Epic Header** | Epic name, SHAMT number, branch name, date created |
| 2 | **Problem Statement** | What gap or problem this epic addressed; why it was needed; what would have continued without this work |
| 3 | **Goals** | Bulleted list of what this epic set out to achieve; maps to features |
| 4 | **Solution Overview** | High-level narrative of the approach taken; how the pieces relate to each other |
| 5 | **Architecture & Key Decisions** | Important design decisions made during the epic, with rationale — not just what was decided, but why alternatives were considered and rejected |
| 6 | **Changes by Feature / Component** | For each feature or logical grouping: the starting state, what changed, why it was done this way, and how it connects to the epic goals |
| 7 | **Complete File Changelog** | Table listing every changed file: `\| File \| Change Type \| Description \|` |
| 8 | **Testing Summary** | How the changes were tested, what scenarios were validated, results |
| 9 | **Out of Scope / Known Limitations** | What was explicitly excluded and why; any known issues or planned follow-on work |
| 10 | **Review Guidance** | How a PR reviewer should approach this branch; what to focus on; suggested review order |

### Narrative planning requirement

Before writing, the agent must explicitly reason through (in its own thinking, not in the final document) the following:

- **Story spine:** What is the through-line from problem to solution? One sentence that captures it.
- **Change organization:** Should changes be grouped by feature, by layer, or by impact? Which organization best serves a cold reader?
- **Foundation vs. dependent:** Which changes are foundational (must be understood first) vs. dependent (build on something else)? Present foundational changes earlier in Section 6.
- **Assumed knowledge:** What can be assumed? (Fellow developer, familiar with the stack, no epic context.) What cannot be assumed?

The agent documents this reasoning before generating any document content, so the structure is intentional rather than incidental.

---

## Validation Loop

After the document is created, the agent runs a validation loop before committing.

### Validation dimensions

1. **Correctness** — Every described code change matches the actual `git diff origin/main...HEAD`; no claims about changes that did not happen; no omissions that distort the picture of what was done
2. **Completeness** — Every file in the git diff is accounted for in the Complete File Changelog (Section 7); all goals stated in EPIC_README are addressed somewhere in the document
3. **Consistency** — No contradictions between the overview document and EPIC_README, feature READMEs, or EPIC_TRACKER; terminology is consistent throughout the document; no internal contradictions
4. **Clarity** — A developer with zero prior context on this epic could read this document and understand: what was done, why it was done, and how to review the changes effectively

### Exit criterion

**2 consecutive clean rounds** with zero issues found across all 4 dimensions.

- Each round checks all 4 dimensions independently
- Any issue found resets `consecutive_clean` to 0
- The agent states `consecutive_clean = {n}` explicitly at the end of every round
- If the same unresolvable issue persists for 3+ consecutive rounds, the agent surfaces it to the user rather than continuing to loop

The validation is performed by the primary agent (no sub-agent spawning — the overhead is not warranted for a single-document within-step validation loop).

---

## Affected Files

### Modified

- `.shamt/guides/stages/s10/s10_epic_cleanup.md`
  - Insert the S10.P2 prompt block between current Steps 7 and 8
  - Renumber current Step 8 → Step 9 and current Step 9 → Step 10
  - Update the Workflow Overview ASCII diagram (the `## Workflow Overview` fenced block) to insert a new `STEP 8: S10.P2` branch and renumber the existing Steps 8 and 9
  - Update the sentence "S10 has 9 main steps" (Quick Navigation section) to "S10 has 10 main steps"
  - Add a new row for Step 8 (S10.P2) to the Quick Navigation table, including time estimate (0 min if skipped; 20-40 min if opted in) — the link to `s10_p2_overview_workflow.md` belongs in the step's detail section only, consistent with how S10.P1's workflow file is referenced (not in the Quick Navigation table)
  - Update the Summary section's numbered activity list (currently 10 items) to insert the new S10.P2 item after item 6 (EPIC_TRACKER update) — this displaces items 7, 8, 9, and 10 to become items 8, 9, 10, and 11, resulting in 11 total items
  - Update the Exit Criteria section to add a note for S10.P2: it is opt-in and has no mandatory exit criterion item; if opted in, the agent marks it complete after the overview doc is committed
  - Update the total time estimate in **both** locations where it appears: the Overview section and the Quick Navigation section — the new range is **85-130 minutes (S10.P2 skipped) or 105-170 minutes (S10.P2 opted in)**
  - Update the Common Pitfalls section

- `.shamt/guides/reference/stage_10/stage_10_reference_card.md`
  - Update the Workflow Overview ASCII diagram to insert Step 8 (S10.P2) and renumber Steps 8→9 and 9→10
  - Update the Step Summary Table to add the new row for Step 8 (S10.P2) and renumber Steps 8→9 and 9→10
  - Update the Total Time figure from "85-130 minutes" to reflect the two scenarios
  - Update the Git Workflow section: renumber the Step 8 heading to Step 9 — the section has headings for Steps 5, 6, 7, and 8; only the Step 8 heading requires renumbering (Steps 5–7 are unchanged, and there is no existing Step 9 heading to rename)
  - Update the Critical Rules Summary: change "before creating PR in Step 8" to "before creating PR in Step 9"
  - Update Common Pitfalls (Pitfall 7): change "before creating PR in Step 8" to "before creating PR in Step 9"
  - Update the File Outputs section: rename the "**Step 8:**" heading to "**Step 9:**"; add a new "**Step 8:**" block above it listing the S10.P2 output ("`SHAMT-{N}-OVERVIEW.md` at repository root (if opted in)")
  - Update the Quick Checklist: rename the existing "**Step 8 → Step 9:**" transition block to "**Step 9 → Step 10:**"; add a new "**Step 8 → Step 9:**" transition block between the existing "**Step 7 → Step 8:**" and the renamed "**Step 9 → Step 10:**" blocks, with checklist items for S10.P2 completion (overview doc committed or phase skipped); rename "**Step 9 → Complete:**" to "**Step 10 → Complete:**"
  - Update the Exit Conditions section ("All 9 steps complete (1-9)") to reflect 10 steps

- `.shamt/guides/reference/stage_10/epic_completion_template.md`
  - Update the "When to use" line (line 4): change "Step 8d of S10 (Final Verification & Completion)" to "Step 10 of S10 (Final Verification & Completion)" — note: this reference was already stale before SHAMT-19 (the current guide places Final Verification at Step 9, not Step 8d); SHAMT-19 renumbers it to Step 10

### New

- `.shamt/guides/stages/s10/s10_p2_overview_workflow.md`
  - Detailed step-by-step execution guide for S10.P2 (mirrors the role that `s10_p1_guide_update_workflow.md` plays for S10.P1)

---

## Detailed Phase Design

The following is the intended execution flow for S10.P2 as it will appear in the new guide file.

### Step 1 — Ask the user

> "Would you like to create an epic overview document (`SHAMT-{N}-OVERVIEW.md`) for PR reviewers and future contributors? This document will narrate the epic's goals, decisions, and code changes in detail. It will be committed to the branch and visible in the PR diff. (yes / no)"

If **no**: Note the decision, skip to current Step 8 (now Step 9). No file is created, no note is added to EPIC_README.

If **yes**: Continue to Step 2.

### Step 2 — Gather context

Run the following in parallel:

- `git log origin/main..HEAD --stat` — full commit history with file stats
- `git diff origin/main...HEAD --name-status` — all changed files categorized
- Read `EPIC_README.md`
- Read all feature `README.md` files found under the epic folder
- Read `epic_lessons_learned.md`
- Read the epic's entry in `EPIC_TRACKER.md` (the detail section added in Step 7)

### Step 3 — Plan the narrative

Before writing a single section, reason through the four narrative planning questions (story spine, change organization, foundation vs. dependent, assumed knowledge). State the chosen organization approach and why.

### Step 4 — Write the document

Create `SHAMT-{N}-OVERVIEW.md` at the repository root. Follow the content section spec from this design doc. Write the document with the cold-reader audience in mind at all times — if something would be confusing to someone with no epic context, explain it.

### Step 5 — Validation loop

Run the validation loop as specified in the Validation Loop section above. Fix any issues found before declaring a clean round. Continue until `consecutive_clean = 2`.

### Step 6 — Commit

```
git add SHAMT-{N}-OVERVIEW.md
git commit -m "docs/SHAMT-{N}: Add epic overview document"
```

The `docs/SHAMT-{N}:` format uses the slash convention consistent with the other S10 sub-commits (e.g., `chore/SHAMT-{N}: Move completed epic to done/`, `chore/SHAMT-{N}: Update EPIC_TRACKER`). The `docs` type is used (rather than `chore`) because this commit produces a substantive documentation artifact visible to PR reviewers, not a housekeeping operation.

Verify the commit with `git log -1 --stat`.

---

## Edge Cases & Failure Modes

### User declines
Skip S10.P2 entirely. Do not create any placeholder files. Do not add a note to EPIC_README (the absence of the file is unambiguous). Proceed to Step 9 (push + PR).

### Git diff is very large (100+ changed files)
Group changes by feature/component in Section 6 (Changes by Feature) rather than listing every file individually in the narrative. Section 7 (Complete File Changelog) still lists every file, but one sentence per file suffices. Do not truncate the changelog.

### Validation loop stalls (same issue across 3+ rounds)
Stop looping. Describe to the user exactly what keeps being flagged and why it is difficult to resolve. Ask for guidance before continuing. This prevents infinite loops on genuinely ambiguous or subjective content.

### Branch has already been pushed before S10.P2
If the user already ran `git push` manually before this phase (uncommon but possible), S10.P2 still creates and commits the document normally. The agent then pushes the additional commit in Step 9 as usual. The guide should note this case explicitly.

### Overview document grows very large (10,000+ words)
Prioritize depth in Sections 5 (Architecture & Key Decisions) and 6 (Changes by Feature). Keep Section 7 (File Changelog) at one sentence per file. Keep Section 8 (Testing) and Section 10 (Review Guidance) concise. Signal length by priority: decisions and rationale > change descriptions > testing > guidance.

### Epic has a very small diff (1-3 files)
The document structure is the same, but most sections will be short. This is expected and fine. Do not pad sections to fill space — a concise overview of a small epic is still valuable.

---

## Implementation Notes

When implementing, the `s10_p2_overview_workflow.md` guide file should:

- Be structured with numbered steps matching the Detailed Phase Design above
- Include example commands (git commands, file paths)
- Include an example document skeleton (section headers and 1-sentence descriptions) so the agent has a concrete template to follow
- Mirror the formatting conventions of `s10_p1_guide_update_workflow.md` for consistency

When modifying `s10_epic_cleanup.md`:

- The S10.P2 prompt block should be concise (5-10 lines) in the main guide — full detail lives in the separate workflow file, the same pattern used for S10.P1
- The step header in the main guide should be labeled `(optional)` to visually distinguish it from mandatory steps like S10.P1 which carries a `🚨 MANDATORY` marker — e.g.: `**STEP 8: S10.P2 — Epic Overview Document (optional)**`
- The time estimate for S10.P2 when opted in: approximately 20-40 minutes depending on epic size
- Update the total time estimate in both locations (Overview section and Quick Navigation section) to: **85-130 minutes (S10.P2 skipped) or 105-170 minutes (S10.P2 opted in)** — when opted in, the minimum increases from 85 to 105 (85 + 20) and the maximum from 130 to 170 (130 + 40)
- Add to Common Pitfalls: "Writing the overview before planning the narrative structure — this produces a disorganized document"
- Add to Common Pitfalls: "Skipping S10.P2 without asking the user — the phase is opt-in, but the question must always be asked"

---

## Open Questions

None — scope is clear and well-bounded.
