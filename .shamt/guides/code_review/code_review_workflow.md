# Code Review Workflow — Step-by-Step Guide

**Entry point:** This guide is read after `README.md`. If you have not read `README.md`, do that first.

---

## 🚨 MANDATORY READING PROTOCOL

**BEFORE starting, you MUST:**

1. Use the prompt shortcut from `prompts/special_workflows_prompts.md` (Code Review section)
2. Confirm the branch name with the user if ambiguous
3. Verify prerequisites (branch exists, you have read access)

---

## Overview of Steps

```
Step 1: Access the branch (read-only)
Step 2: Create output directory
Step 3: Write overview.md
Step 4: Run overview validation loop (5 dimensions)
Step 5: Determine review version number
Step 6: Write review_vN.md
Step 7: Run review file validation loop (12 dimensions)
```

**Model Selection for Token Optimization (SHAMT-27):**

Code reviews can save 30-40% tokens through delegation:

```
Primary Agent (Opus):
├─ Spawn Haiku → Git operations (branch fetch, file list, commit messages)
├─ Spawn Sonnet → Overview.md ELI5 section (summarization)
├─ Primary handles → Issue classification, actionable comments, adversarial self-check
├─ Primary writes → review_vN.md
└─ Spawn Sonnet → Final formatting
```

**See:** `reference/model_selection.md` for Task tool examples.

---

## Step 1 — Access the Branch

**Goal:** Read all diff and file content using read-only git commands. Never check out the branch.

```bash
# If branch is remote-only, fetch it first
git fetch origin <branch>

# Get full diff vs merge base with main
git diff $(git merge-base main <branch>) <branch>

# List files changed
git diff --name-only $(git merge-base main <branch>) <branch>

# Read a specific file at the branch tip
git show <branch>:<path/to/file>

# Get commit log for the branch
git log main..<branch> --oneline
```

**If `git fetch` fails:** Halt immediately. Report to the user: "Branch `<branch>` could not be found locally or on origin. Please verify the branch name and try again." Do not create any output files.

**Edge case — large diffs:** If `git diff` output is too large to process at once, read changed files individually via `git show <branch>:<file>` rather than processing the full diff.

---

## Step 2 — Create Output Directory

Sanitize the branch name:
- Replace `/` with `_`
- Strip any character that is not alphanumeric, `-`, or `_`

Create `.shamt/code_reviews/<sanitized-branch>/` if it does not exist.

Full sanitization examples and the complete sub-folder structure are in `output_format.md`.

---

## Step 3 — Write `overview.md`

Create (or update in-place for re-reviews) `.shamt/code_reviews/<sanitized-branch>/overview.md`.

Use the template from `output_format.md`. Populate each section:

**Header block:** Date, base branch, merge base SHA, commit range, file count.

**ELI5 — What Changed?**
- 2-4 sentences in plain English
- Written for someone with no context on this codebase
- Avoid jargon; focus on observable behaviour, not implementation
- Do not mention file names or function names

**What Does This Branch Do?**
- Clear statement of purpose and outcomes
- What problem does it solve? What feature does it add?
- What does the system do differently after this branch is merged?

**Why Was It Built?**
- Intent and motivation from commit messages, PR description (if available), and code reading
- If intent is not explicit: state "inferred from commit messages / code structure"

**How Does It Work?**
- Technical walkthrough: which files were changed, key logic, how components interact
- Notable design choices
- Organize by area of change when multiple subsystems are touched

---

## Step 4 — Overview Validation Loop

🚨 **Read the Hard Stop section at the top of `reference/validation_loop_master_protocol.md` before starting.**

**Create `overview_validation_log.md`** in the branch sub-folder BEFORE Round 1. On re-review, overwrite the existing log.

### 5 Dimensions — Checked Every Round

| # | Dimension | What to Check |
|---|-----------|---------------|
| 1 | **Correctness** | Every factual claim (what changed, how it works) is verified against the diff or `git show` — not inferred from commit messages alone |
| 2 | **Completeness** | All files and hunks in the diff are accounted for in the overview; no significant change is silently omitted |
| 3 | **Consistency** | The ELI5, What, Why, and How sections agree with each other; no internal contradictions |
| 4 | **Clarity** | The ELI5 is genuinely understandable to a non-technical reader; the How section is specific enough to be useful to a code reviewer |
| 5 | **Scope** | The overview describes only what is in the diff; no speculation about future changes or unrelated context |

### Round Structure

Each round:
1. Re-read the entire `overview.md` from line 1 to end (use read_file — partial reads do not count)
2. Check all 5 dimensions and document PASS or ISSUE for each
3. Fix any issues found immediately in the file
4. State `consecutive_clean = N` at the end of the round

**Counter rules:**
- Clean round = ZERO issues OR exactly 1 LOW-severity issue (fixed)
- Counter resets to 0 if: 2+ LOW issues OR any MEDIUM/HIGH/CRITICAL issue
- Zero or 1 LOW → `consecutive_clean = 1` → trigger sub-agent confirmation (see Exit Criteria)
- See `reference/severity_classification_universal.md` for severity definitions

### Exit Criteria

After `consecutive_clean = 1` (primary clean round):
1. Spawn 2 independent sub-agents in parallel
2. Each sub-agent reads the full `overview.md` and checks all 5 dimensions
3. Both must independently confirm zero issues
4. If either sub-agent finds an issue: fix it, reset `consecutive_clean = 0`, continue primary rounds
5. Exit only when both sub-agents confirm clean

After the overview loop exits, proceed to Step 5.

---

## Step 5 — Determine Review Version Number

Check the branch sub-folder:
- No `review_v*.md` files exist → create `review_v1.md`
- `review_v1.md` exists → create `review_v2.md`
- `review_v1.md` and `review_v2.md` exist → create `review_v3.md`
- And so on — never overwrite a previous version

---

## Step 6 — Write `review_vN.md`

Create `.shamt/code_reviews/<sanitized-branch>/review_vN.md`.

Use the template from `output_format.md`.

### How to Write Review Comments

Check all 12 categories below. For each category, read the relevant diff hunks and files. Only include categories with actual findings — omit categories with no issues.

Group findings by severity (BLOCKING first, then CONCERN, SUGGESTION, NITPICK). Each comment uses the block format from `output_format.md`:

```
### [SEVERITY] Category N — <Name>
**File:** `path/to/file`, line N
<Description of the issue>
**Suggested fix:** <Concrete direction>
```

### 12 Review Categories

| # | Category | Focus |
|---|----------|-------|
| 1 | **Correctness** | Logic errors, edge cases, off-by-ones — does the code do what the PR claims? |
| 2 | **Code Quality** | Naming, readability, duplication, unnecessary complexity |
| 3 | **Comments & Documentation** | Inline comments, docstrings, README updates where appropriate |
| 4 | **Code Organization** | File structure, separation of concerns, function length, coupling |
| 5 | **Testing** | New tests added, coverage of new paths, test quality |
| 6 | **Security** | Input validation, auth checks, injection risks, sensitive data exposure |
| 7 | **Performance** | N+1 queries, unnecessary allocations, hot-path concerns |
| 8 | **Error Handling** | Missing error checks, swallowed exceptions, unclear failure modes |
| 9 | **Architecture & Design** | Pattern consistency with existing codebase, abstraction level |
| 10 | **Backwards Compatibility** | Breaking changes, API surface changes, deprecation handling |
| 11 | **Scope & Changes** | Does the PR match its stated purpose? Any unrelated changes? |
| 12 | **Context & Intent** | (External PRs only) Does the author's intent appear sound? Misunderstandings of codebase? |

### Severity Definitions

| Severity | When to Use |
|----------|-------------|
| `BLOCKING` | Must be fixed before merge — correctness bug, security issue, or data-loss risk |
| `CONCERN` | Should be addressed — real quality, performance, or maintainability problem |
| `SUGGESTION` | Optional improvement — the code works but could be better |
| `NITPICK` | Minor style or preference — author decides |

---

## Step 7 — Review File Validation Loop

🚨 **Read the Hard Stop section at the top of `reference/validation_loop_master_protocol.md` before starting.**

**Create `review_validation_log.md`** in the branch sub-folder BEFORE Round 1. On re-review, overwrite the existing log.

"Fixing issues" means updating the review file: removing false positives, adding missed issues, making vague comments specific, correcting file/line references, reclassifying severity.

### 12 Dimensions — Checked Every Round

**Master Dimensions (7) — apply to all validation loops:**

| # | Dimension | What to Check |
|---|-----------|---------------|
| 1 | **Empirical Verification** | Every comment cites a specific file and line verified with `git show <branch>:<file>` or diff reading — not from memory or assumption |
| 2 | **Completeness** | Every file in the diff has been examined; no hunks or files silently skipped |
| 3 | **Internal Consistency** | No comments contradict each other; similar issues across the diff are rated at the same severity |
| 4 | **Traceability** | Each comment traces back to a specific diff hunk; comments with no locatable source are removed |
| 5 | **Clarity & Specificity** | Every BLOCKING and CONCERN names exactly what is wrong and provides a concrete direction for resolution; no vague observations |
| 6 | **Codebase Alignment** | Comments do not flag patterns already established and consistent in the existing codebase |
| 7 | **Format Compliance** | Review follows `output_format.md` spec — severity tags, file references, section structure are correct |

**Code Review-Specific Dimensions (5):**

| # | Dimension | What to Check |
|---|-----------|---------------|
| 8 | **Coverage Balance** | Comment distribution reflects actual risk — critical areas (auth, data writes, error paths) are not under-reviewed relative to trivial ones |
| 9 | **False Positive Audit** | Every BLOCKING and CONCERN is re-verified against the current diff to confirm the issue still holds; any that don't survive re-verification are removed |
| 10 | **Actionability** | Every comment gives the author enough context to make a concrete change; no comment identifies a problem without a path forward |
| 11 | **Severity Calibration** | BLOCKING is reserved for issues that genuinely cannot be merged safely; CONCERN/SUGGESTION/NITPICK distinctions are sound and consistently applied |
| 12 | **Scope Coherence** | Comments stay within what the PR is attempting; no scope creep into "while you're here, refactor X" unless it directly affects correctness or safety |

### Adversarial Self-Check (Required Before Declaring Any Round Clean)

Before scoring a round as clean, explicitly ask:

> "What would a thorough human reviewer catch that I have not flagged?"

Re-read the diff from the perspective of a skeptic looking for things you let through. A round may NOT be scored clean if this step is skipped.

### Adversarial Linter Check (Required Before Declaring Any Round Clean)

Before scoring a round as clean, explicitly answer:

> "What would ESLint/Ruff/CodeQL flag in this code that I haven't checked?"

Consider:
- [ ] Unused variables or imports?
- [ ] Operator confusion (= vs ==, == vs ===)?
- [ ] Missing null/undefined checks?
- [ ] Unreachable code after return/throw?
- [ ] Inconsistent string quotes or formatting?
- [ ] Type coercion issues?
- [ ] Security patterns (eval, innerHTML, SQL string concat)?

A round may NOT be scored clean if this check is skipped.

### Round Structure

Each round:
1. Re-read the entire `review_vN.md` from line 1 to end (use read_file — partial reads do not count)
2. Re-verify ≥3 specific technical claims against `git show` or diff (document the tool calls)
3. Check all 12 dimensions and document PASS or ISSUE for each
4. Run the Adversarial Self-Check
5. Fix any issues found immediately in the review file
6. State `consecutive_clean = N` at the end of the round

**Counter tracking:**
```
consecutive_clean = 0   (tracked in review_validation_log.md)

After each round:
  - Clean round = ZERO issues OR exactly 1 LOW-severity issue (fixed)
  - 2+ LOW issues OR any MEDIUM/HIGH/CRITICAL: reset consecutive_clean to 0
  - Clean round: consecutive_clean = 1 → trigger sub-agent confirmation
  - Both sub-agents confirm zero issues: EXIT
  - A sub-agent finds ANY issue: fix, reset consecutive_clean to 0, continue
  - State "consecutive_clean = N" explicitly at end of every round
  - See reference/severity_classification_universal.md for severity definitions
```

### Exit Criteria

Same as overview loop: primary clean round + 2 independent sub-agents both confirm zero issues across all 12 dimensions.

---

## After the Workflow Completes

The branch sub-folder now contains:
- `overview.md` — validated branch description
- `overview_validation_log.md` — overview validation history
- `review_vN.md` — validated review comments, copy-paste ready
- `review_validation_log.md` — review validation history

Tell the user the review is complete and the files are at `.shamt/code_reviews/<sanitized-branch>/`. They can copy individual comment blocks directly into GitHub/GitLab/Bitbucket PR comment boxes.
