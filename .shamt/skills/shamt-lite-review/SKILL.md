---
name: shamt-lite-review
description: >
  Run the Shamt Lite Code Review pattern. Two modes — story mode (review code you
  just built; output review_v1.md only) and formal mode (review someone else's
  branch/PR; output overview.md + review_v1.md). Read-only git access; never
  checks out the branch. Validated, copy-paste-ready feedback grouped by severity
  and 12 categories.
triggers:
  - "review this branch"
  - "review the changes"
  - "shamt lite review"
  - "code review"
  - "review my code"
source_guides:
  - scripts/initialization/SHAMT_LITE.template.md
  - scripts/initialization/story_workflow_lite.template.md
  - scripts/initialization/templates/code_review_lite.template.md
master-only: false
---

## Overview

Encodes Pattern 4 (Code Review Process) from `SHAMT_LITE.md`. Two modes:

- **Story mode** — reviewing code you/the agent just built for an active story. Output: `stories/{slug}/code_review/review_v1.md` only. No `overview.md` (the story folder provides context). Used in story Phase 5.
- **Formal mode** — reviewing someone else's branch or PR. Output: `.shamt/code_reviews/<branch>/overview.md` (validated) + `review_v1.md` (validated).

Mode is determined by context: if a story slug is referenced or you just built code, use story mode; if reviewing an external branch, use formal mode.

---

## When This Skill Triggers

- Story Phase 5 — reviewing code you just built (story mode)
- User says "review this branch", "review the changes", or asks for a code review of someone else's work (formal mode)
- Re-review request — create `review_v2.md`, `review_v3.md`, etc. Never overwrite.

---

## Inputs Required

- **Story mode:** slug (story folder exists with `ticket.md`, `spec.md`, `implementation_plan.md`)
- **Formal mode:** branch name (must be fetchable via `git fetch origin <branch>`)

---

## Critical Rule — Never Check Out the Branch

Use **read-only git commands only**. Never `git checkout` another branch — your local working tree must remain on the original branch throughout the review.

---

## Protocol — Formal Mode (7 Steps)

### Step 1 — Fetch branch metadata (read-only)

```bash
git fetch origin <branch-name>
git merge-base origin/main origin/<branch-name>
git log origin/main..origin/<branch-name> --oneline
git diff --stat origin/main...origin/<branch-name>
git diff origin/main...origin/<branch-name>
```

If branch cannot be fetched: halt immediately and report to user.

**Suggested model for Steps 1 and any git metadata work:** Haiku (mechanical).

### Step 2 — Create review directory

`.shamt/code_reviews/<sanitized-branch>/` (e.g., `feat/add-export` → `feat-add-export`).

### Step 3 — Write `overview.md` (formal mode only)

Three sections:

**What Does This Branch Do?** Purpose, outcomes, what the system does differently after merge.

**Why Was It Built?** Intent from commit messages and PR description. If unclear, prefix the explanation with "inferred from commit messages / code structure."

**How Does It Work?** Technical walkthrough: files changed, key logic, component interactions. Organize by area when multiple subsystems touched.

### Step 4 — Validate `overview.md`

Invoke `shamt-lite-validate` with `artifact = .shamt/code_reviews/<branch>/overview.md`, `type = general` (4 dimensions: Completeness, Clarity, Accuracy, Actionability). Exit: primary clean round + 1 Haiku sub-agent.

Append validation footer:

```
---
✅ Validated {date} — N rounds, 1 sub-agent confirmed
```

### Step 5 — Write `review_v1.md` (both modes)

Findings grouped by severity, then by category. Omit severity sections with no findings.

**4 Severity Levels:** BLOCKING / CONCERN / SUGGESTION / NITPICK

**12 Review Categories:**

1. Correctness  2. Security  3. Performance  4. Maintainability  5. Testing
6. Edge Cases  7. Naming  8. Documentation  9. Error Handling  10. Concurrency
11. Dependencies  12. Architecture

**Format each finding:**

```markdown
#### [SEVERITY] — <Category Name>

**File:** `path/to/file.ext`, line N

<Description: what's wrong and what the consequence is.>

**Suggested fix:** <Concrete direction.>
```

If no issues found: write "No issues found." in the relevant sections. Do not fabricate findings.

**Suggested model for issue finding/classification:** Opus.

### Step 6 — Validate `review_v1.md`

Invoke `shamt-lite-validate` with `artifact = .shamt/code_reviews/<branch>/review_v1.md` (or `stories/{slug}/code_review/review_v1.md`), `type = code review` (5 dimensions: Correctness, Completeness, Helpfulness, Severity Accuracy, Evidence). Exit: primary clean round + 1 Haiku sub-agent.

Append validation footer.

### Step 7 — Re-review versioning

On re-review: create `review_v2.md`, `review_v3.md`, etc. Never overwrite previous versions. The previous version remains the historical record of what the reviewer saw at that point.

---

## Protocol — Story Mode (variant)

Story mode is identical to formal mode **except**:

- **Skip Steps 2, 3, 4** (no overview.md). The story folder (`ticket.md`, `spec.md`, `implementation_plan.md`) provides context.
- **Output path:** `stories/{slug}/code_review/review_v1.md` (not `.shamt/code_reviews/`).
- **Focus during Step 5:** "Does the code match the spec and plan?" — implementation fidelity is a primary lens.

Steps 1, 5, 6, 7 are unchanged.

---

## Exit Criteria

- `review_v1.md` (and `overview.md` if formal mode) exist with validation footer
- 1 Haiku sub-agent has confirmed each artifact
- All findings have severity, category, file path/line, description, and suggested fix
- "No issues found." is a valid review — do not fabricate findings

---

## Common Mistakes

- **Checking out the branch.** Read-only git only. The working tree must stay on the original branch.
- **Fabricating findings.** If the diff is clean, write "No issues found." Don't invent issues to fill space.
- **Overwriting on re-review.** Always create `review_v2.md`, `review_v3.md`. Versions are the historical record.
- **Wrong mode.** Story mode skips overview.md. Formal mode requires it. Match the mode to the context.
- **Skipping severity classification.** Without severity, the reviewer can't prioritize. Use BLOCKING / CONCERN / SUGGESTION / NITPICK.
