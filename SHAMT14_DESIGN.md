# SHAMT-14 Design: Standalone Code Review System

**Branch:** `feat/child-sync-20260319` (current) → move to `feat/SHAMT-14`
**Date:** 2026-03-25
**Status:** FINAL — open questions resolved 2026-03-25

---

## Problem Statement

The S1-S10 epic workflow has a thorough PR review step (S9.P4), but it is tightly coupled to the epic lifecycle and operates on the agent's own work. There is no way to ask Shamt to review **someone else's branch or PR** and produce structured, shareable feedback.

Users reviewing external contributions — teammate branches, open-source PRs, or cross-team submissions — currently have to run the full review mentally or manually. This design adds a standalone `code_review` workflow that mirrors S9.P4's rigor while being completely decoupled from the epic flow.

---

## Goals

1. User can invoke the workflow with a single branch name
2. Shamt produces a `.shamt/code_reviews/<branch>/` sub-folder with an `overview.md` (branch summary + ELI5) and a versioned `review_v1.md` with PR-ready comments
3. Comments are copy-paste ready for posting into a GitHub/GitLab/Bitbucket PR
4. Comments are categorized, severity-tagged, and actionable
5. A validation loop (primary clean round + 2 independent sub-agent confirmations) ensures no issues are missed or incorrectly called out
6. The workflow never modifies the branch being reviewed
7. The output propagates to child projects via the normal import mechanism

---

## Non-Goals

- Making code changes to the reviewed branch
- Approving or rejecting a PR (no approve/request-changes automation)
- Replacing S9.P4 for the agent's own epic reviews
- Handling merge conflicts or rebase operations
- CI/CD integration

---

## Design Decisions

### 1. Branch Access Strategy

**Decision: `git diff` + `git show` (no checkout)**

The agent reads the diff and file contents using read-only git commands. It does not check out the branch, so the working directory and current branch are never disturbed.

Commands used:
```bash
# Fetch branch if remote-only
git fetch origin <branch>

# Get full diff vs merge base
git diff $(git merge-base main <branch>) <branch>

# Read a specific file at the branch tip
git show <branch>:<path/to/file>

# List files changed
git diff --name-only $(git merge-base main <branch>) <branch>

# Get commit log for the branch
git log main..<branch> --oneline
```

**Base branch:** Always `main`. The merge base is computed as `git merge-base main <branch>` — no per-PR target override.

**Rationale:** Checking out the branch would change HEAD, potentially trigger hooks, and leave the repo in an unexpected state if the review is interrupted. `git show` provides full file content for any file touched by the branch without any of those risks.

**Edge case — large diffs:** If `git diff` output exceeds a practical reading limit, the agent reads changed files individually via `git show` rather than trying to process the full diff at once.

**Edge case — branch not found:** If `git fetch origin <branch>` fails (branch doesn't exist on remote), the agent halts immediately and reports the error to the user. No output files are created.

---

### 2. Output Directory Structure

Each branch gets its own sub-folder inside `.shamt/code_reviews/`:

```
.shamt/code_reviews/<sanitized-branch-name>/
├── overview.md      — branch overview document (created first, before any review)
├── review_v1.md     — first code review
├── review_v2.md     — re-review (if user requests a new review of the same branch)
└── ...
```

Sanitization rule: replace `/` with `_`, strip any characters that are not alphanumeric, `-`, or `_`.

Examples:
- `feat/my-feature` → `feat_my-feature/`
- `kai/fix-login-bug` → `kai_fix-login-bug/`
- `bugfix/TICKET-123` → `bugfix_TICKET-123/`

**Review versioning:** The first review is always `review_v1.md`. When the user requests a re-review of the same branch, the agent creates `review_v2.md`, `review_v3.md`, and so on — never overwriting a previous version. The overview is never versioned; it is updated in-place to reflect the branch's current state before each re-review.

---

### 3. Branch Overview Document

Before producing any review comments, the agent creates `overview.md` in the branch sub-folder. This document serves as a shared-understanding checkpoint — the reviewer can confirm the agent understood the branch correctly before reading individual comments.

**Overview document structure:**

```markdown
# Branch Overview: <branch-name>

**Date:** YYYY-MM-DD
**Base:** main (merge base: <short SHA>)
**Commits:** N commits (<first SHA>..<last SHA>)
**Files changed:** N files (+X -Y lines)

---

## ELI5 — What Changed?

<2-4 sentence plain-English summary written for someone with no context on
this codebase. Avoid jargon. Focus on what the user of the software would
notice, not on implementation details.>

---

## What Does This Branch Do?

<Clear description of the branch's purpose and outcomes. What problem does
it solve? What feature does it add? What does the system do differently
after this branch is merged?>

## Why Was It Built?

<Intent and motivation behind the changes, drawn from commit messages, PR
description (if available), and code reading. If intent is not explicit,
state "inferred from commit messages / code structure.">

## How Does It Work?

<Technical walkthrough of the implementation: which files were changed, what
the key logic is, how components interact, and what the notable design
choices are. Organized by area of change when multiple subsystems are
touched.>

---

*Overview generated by Shamt code review workflow*
*Branch: <branch> | Base: main | Date: YYYY-MM-DD*
```

The overview is created using the same read-only git commands as the review (no checkout). If the user requests a re-review, the overview is updated in-place before the new versioned review file is created.

**Overview validation loop:** After drafting `overview.md`, the agent runs a validation loop on it before beginning the review. Exit criteria: primary clean round + 2 independent sub-agents confirm zero issues (same master protocol exit criteria). Dimensions checked every round:

| # | Dimension | What to Check |
|---|-----------|---------------|
| 1 | **Correctness** | Every factual claim (what changed, how it works) is verified against the diff or `git show` — not inferred from commit messages alone |
| 2 | **Completeness** | All files and hunks in the diff are accounted for in the overview; no significant change is silently omitted |
| 3 | **Consistency** | The ELI5, What, Why, and How sections agree with each other; no internal contradictions |
| 4 | **Clarity** | The ELI5 is genuinely understandable to a non-technical reader; the How section is specific enough to be useful to a code reviewer |
| 5 | **Scope** | The overview describes only what is in the diff; no speculation about future changes or unrelated context |

A validation log file is created in the branch sub-folder before the overview validation begins (`.shamt/code_reviews/<branch>/overview_validation_log.md`). On re-review, the existing overview validation log is overwritten — only the most recent overview validation is retained. After the overview loop exits clean, the review file validation loop begins.

---

### 4. Review Categories

Adapted from S9.P4's 11 categories, adjusted for general PR review (not epic-specific):

| # | Category | Focus |
|---|----------|-------|
| 1 | **Correctness** | Does the code do what the PR claims? Logic errors, edge cases, off-by-ones |
| 2 | **Code Quality** | Naming, readability, duplication, unnecessary complexity |
| 3 | **Comments & Documentation** | Inline comments, docstrings, README updates where appropriate |
| 4 | **Code Organization** | File structure, separation of concerns, function length, coupling |
| 5 | **Testing** | New tests added, coverage of new paths, test quality |
| 6 | **Security** | Input validation, auth checks, injection risks, sensitive data exposure |
| 7 | **Performance** | N+1 queries, unnecessary allocations, hot-path concerns |
| 8 | **Error Handling** | Missing error checks, swallowed exceptions, unclear failure modes |
| 9 | **Architecture & Design** | Pattern consistency with existing codebase, abstraction level |
| 10 | **Backwards Compatibility** | Breaking changes, API surface changes, deprecation handling |
| 11 | **Scope & Changes** | Does the PR match its stated purpose? Unrelated changes included? |
| 12 | **Context & Intent** | (External PR only) Does the author's intent appear sound? Misunderstandings of codebase? |

Category 12 is unique to external reviews. It flags cases where the PR author may have misunderstood the codebase's conventions, contracts, or design intent — not a bug, but a direction issue.

---

### 5. Comment Format

Each comment in the output file uses the following structure, designed to be copy-paste ready:

```markdown
### [BLOCKING] Category 1 — Correctness

**File:** `src/auth/login.py`, line 47

The `check_password` function returns `True` when the DB lookup times out
(line 47: `except TimeoutError: return True`). This means a DB outage
silently grants access to all users.

**Suggested fix:** Return `False` on timeout and log the error, or raise
an exception that the caller handles as an auth failure.
```

**Severity levels:**
- `BLOCKING` — must be fixed before merge; correctness, security, or data-loss risk
- `CONCERN` — should be addressed; quality, performance, or maintainability issue
- `SUGGESTION` — optional improvement; the code works but could be better
- `NITPICK` — minor style or preference; author can decide

The format is intentionally plain markdown. Users paste these blocks directly into PR comments. No special tooling required.

---

### 6. Output File Structure

Each branch sub-folder contains two file types: an overview and one or more versioned review files.

**Overview** (`.shamt/code_reviews/<branch>/overview.md`) — see §3 for full template.

**Review file** (`.shamt/code_reviews/<branch>/review_v1.md`, `review_v2.md`, etc.):

```markdown
# Code Review: <branch-name> (v1)

**Reviewed:** YYYY-MM-DD
**Base:** main (merge base: <short SHA>)
**Commits:** N commits (<first SHA>..<last SHA>)
**Files changed:** N files (+X -Y lines)
**Overview:** See `overview.md` for a full description of what this branch does.

---

## Review Comments

<Grouped by severity, then by category. Each group uses the comment
format above. If a category has no issues, it is omitted — only
categories with findings are listed.>

### BLOCKING

<comments...>

### CONCERN

<comments...>

### SUGGESTION

<comments...>

### NITPICK

<comments...>

---

## Validation Summary

**Rounds completed:** N
**Exit criteria:** Primary clean round + sub-agent confirmation
**Sub-agent A:** 0 issues ✅
**Sub-agent B:** 0 issues ✅
**Issues found and resolved during validation:** N

---

*Review generated by Shamt code review workflow*
*Branch: <branch> | Base: main | Date: YYYY-MM-DD | Version: v1*
```

---

### 7. Validation Loop

This section covers the **review file** validation loop. The overview validation loop (with its own 5 dimensions) is defined in §3 and runs first.

The review file validation loop follows the **master validation loop protocol** (`reference/validation_loop_master_protocol.md`) with the sub-agent confirmation exit criteria used in S9.P2. "Fixing issues" means updating the review file: removing false positives, adding missed issues, making vague comments specific, correcting file references, reclassifying severity.

**Exit criteria: primary clean round + sub-agent confirmation**
- Primary agent runs rounds until one round produces zero issues
- After the primary's first clean round: spawn 2 independent sub-agents in parallel
- Both sub-agents must independently confirm zero issues across all 12 dimensions
- If either sub-agent finds an issue, the counter resets and the primary continues
- Exit only when both sub-agents confirm clean

**Counter tracking (same as master protocol):**
```
clean_counter = 0   (tracked in review_validation_log.md)

After each round:
  - If any issues found: fix them in the review file, reset clean_counter to 0
  - If zero issues: clean_counter = 1 → trigger sub-agent confirmation
  - If sub-agents both confirm: EXIT (loop complete)
  - If a sub-agent finds issues: fix them, reset clean_counter to 0, continue
  - State "clean_counter = N" explicitly at end of every round
```

**VALIDATION_LOG.md** is created in the branch sub-folder at `.shamt/code_reviews/<branch>/review_validation_log.md` before Round 1 begins (separate from the overview validation log). On re-review, the review validation log is overwritten — only the most recent review validation is retained. Each round is logged with findings, fixes made, and the current clean_counter value.

---

#### 12 Dimensions (Checked Every Round)

These 12 dimensions are adapted from S9.P2's master (7) + epic-specific (5) structure, reframed to validate the review file rather than code.

**Master Dimensions (7) — apply to all validation loops:**

| # | Dimension | What to Check |
|---|-----------|---------------|
| 1 | **Empirical Verification** | Every comment cites a specific file and line that was verified with `git show <branch>:<file>` or diff reading — not from memory or assumption |
| 2 | **Completeness** | Every file in the diff has been examined; no hunks or files silently skipped |
| 3 | **Internal Consistency** | No comments contradict each other; similar issues across the diff are rated at the same severity |
| 4 | **Traceability** | Each comment traces back to a specific diff hunk; comments with no locatable source are removed |
| 5 | **Clarity & Specificity** | Every BLOCKING and CONCERN names exactly what is wrong and provides a concrete direction for resolution; no vague observations |
| 6 | **Codebase Alignment** | Comments do not flag patterns that are already established and consistent in the existing codebase (adapted from Upstream Alignment) |
| 7 | **Format Compliance** | Review follows `output_format.md` spec; severity tags, file references, and section structure are correct |

**Code Review-Specific Dimensions (5):**

| # | Dimension | What to Check |
|---|-----------|---------------|
| 8 | **Coverage Balance** | Comment distribution reflects actual risk — critical areas (auth, data writes, error paths) are not under-reviewed relative to trivial ones |
| 9 | **False Positive Audit** | Every BLOCKING and CONCERN is re-verified against the current diff to confirm the issue still holds; any that don't survive re-verification are removed |
| 10 | **Actionability** | Every comment gives the author enough context to make a concrete change; no comment identifies a problem without a path forward |
| 11 | **Severity Calibration** | BLOCKING is reserved for issues that genuinely cannot be merged safely; CONCERN/SUGGESTION/NITPICK distinctions are sound and applied consistently |
| 12 | **Scope Coherence** | Comments stay within what the PR is attempting; no scope creep into "while you're here, refactor X" unless it directly affects the PR's correctness or safety |

**Adversarial Self-Check (required before declaring any round clean):** Explicitly ask: "What would a thorough human reviewer catch that I have not flagged?" Re-read the diff from the perspective of a skeptic looking for things the agent let through. A round may not be scored clean if this step is skipped.

---

### 8. Guide Structure

New directory: `.shamt/guides/code_review/`

```
.shamt/guides/code_review/
├── README.md                    — overview, invocation, when to use
├── code_review_workflow.md      — step-by-step workflow guide
└── output_format.md             — complete format spec with templates
```

This mirrors the structure of other standalone workflow guides (e.g., `debugging/`, `missed_requirement/`).

---

### 9. Invocation

The user invokes the workflow with a natural language prompt:

> "Review branch `feat/my-feature`"
> "Do a code review of `kai/fix-auth`"
> "Review the changes on `origin/feature/TICKET-99`"

For a re-review of the same branch:

> "Re-review `feat/my-feature`"
> "Run a new review of `kai/fix-auth`"

The agent reads `guides/code_review/README.md` first, then `code_review_workflow.md`. After reading the guides, the agent:

1. Creates (or updates) `overview.md` in the branch sub-folder, then runs the overview validation loop (§3)
2. Determines the next version number (`review_v1.md` for a fresh review, `review_vN.md` for a re-review)
3. Produces the versioned review file and runs the review file validation loop (§7)

A prompt shortcut should be added to `guides/prompts/special_workflows_prompts.md`:

```markdown
## Code Review

**Trigger:** User asks to review a branch or PR, or re-review an already-reviewed branch

**Prompt:**
I need to review branch `{branch_name}`.

Read `.shamt/guides/code_review/README.md` and then
`.shamt/guides/code_review/code_review_workflow.md` and follow
the workflow to produce a review in `.shamt/code_reviews/{sanitized_branch}/`.

If a previous review exists for this branch, create the next versioned
review file (review_v2.md, review_v3.md, etc.) and update overview.md.
```

---

### 10. Propagation to Child Projects

The `code_review` guide directory is under `.shamt/guides/`, so it propagates to child projects automatically on their next `import` run. No changes to the export/import scripts are needed.

The `.shamt/code_reviews/` output directory does **not** propagate (it's a per-project artifact directory). Child projects will create their own on first use. No `.gitignore` entry is needed — the directory and its review files should be committed.

---

## Files to Create

| File | Purpose |
|------|---------|
| `.shamt/guides/code_review/README.md` | Overview, invocation, use cases |
| `.shamt/guides/code_review/code_review_workflow.md` | Step-by-step agent workflow |
| `.shamt/guides/code_review/output_format.md` | Format spec and copy-paste templates for both `overview.md` and versioned review files |

---

## Files to Update

| File | Change |
|------|--------|
| `CLAUDE.md` | Add "Code Review" section describing when/how to invoke the workflow |
| `README.md` | Add code review to the capability description |
| `scripts/initialization/RULES_FILE.template.md` | Add code review section so child project AI agents know about the workflow |
| `.shamt/guides/README.md` | Add `code_review/` entry to the guide index |
| `.shamt/guides/prompts/special_workflows_prompts.md` | Add code review invocation prompt |

---

## Resolved Decisions

| Question | Decision |
|----------|----------|
| Input format | Branch names only — no PR number support |
| Base branch | Always `main` — no per-invocation override |
| Review versioning | `review_v1.md`, `review_v2.md`, etc. — never overwrite a previous version |
| Overview versioning | `overview.md` — single file, updated in-place on re-review |
| Validation loops | Two loops per review: (1) overview loop (5 dimensions, §3), then (2) review file loop (12 dimensions, §7); both use primary clean round + 2 sub-agent exit criteria |

---

## Implementation Plan

Per master dev workflow: this is a "large change" (new guide files + CLAUDE.md + README + template updates), so it warrants a branch with this design doc.

**Branch:** `feat/SHAMT-14`
**Order of implementation:**
1. Create `.shamt/guides/code_review/` with all three guide files
2. Update `.shamt/guides/README.md`
3. Update `prompts/special_workflows_prompts.md`
4. Update `CLAUDE.md`, root `README.md`, `RULES_FILE.template.md`
5. Run full guide audit (3 consecutive clean rounds)
6. Open PR against `main`

---

*End of SHAMT14_DESIGN.md*
