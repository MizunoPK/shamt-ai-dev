# Code Review Workflow — Step-by-Step Guide

**Entry point:** This guide is read after `README.md`. If you have not read `README.md`, do that first.

---

## Table of Contents

1. [Mandatory Reading Protocol](#-mandatory-reading-protocol)
2. [Overview of Steps](#overview-of-steps)
3. [S7/S9 Variant Usage](#s7s9-variant-usage)
4. [Step 1 — Access the Branch](#step-1--access-the-branch)
5. [Step 2 — Create Output Directory](#step-2--create-output-directory)
6. [Step 3 — Write overview.md](#step-3--write-overviewmd)
7. [Step 4 — Overview Validation Loop](#step-4--overview-validation-loop)
8. [Step 5 — Determine Review Version Number](#step-5--determine-review-version-number)
9. [Step 6 — Write review_vN.md](#step-6--write-review_vnmd)
10. [Step 7 — Review File Validation Loop](#step-7--review-file-validation-loop)
11. [After the Workflow Completes](#after-the-workflow-completes)

---

## 🚨 MANDATORY READING PROTOCOL

**BEFORE starting, you MUST:**

1. Use the prompt shortcut from `prompts/special_workflows_prompts.md` (Code Review section)
2. Confirm the branch name with the user if ambiguous
3. Verify prerequisites (branch exists, you have read access)

---

## Overview of Steps

```text
Step 1: Access the branch (read-only)
Step 2: Create output directory
Step 3: Write overview.md
Step 4: Run overview validation loop (5 dimensions)
Step 5: Determine review version number
Step 6: Write review_vN.md
Step 7: Run review file validation loop (12 dimensions)
```

**Model Selection for Token Optimization (SHAMT-27):**

Code reviews MUST use strategic model delegation (30-40% token savings). This is mandatory, not optional.

```text
Primary Agent (Opus):
├─ Spawn Haiku → Git operations (branch fetch, file list, commit messages)
├─ Spawn Sonnet → Overview.md ELI5 section (summarization)
├─ Primary handles → Issue classification, actionable comments, adversarial self-check
├─ Primary writes → review_vN.md
├─ Spawn 2x Haiku (parallel) → Overview validation sub-agent confirmation
└─ Spawn 2x Haiku (parallel) → Review validation sub-agent confirmation
```

**Mandatory enforcement:** Use Task tool with appropriate model parameter for all delegatable tasks. See inline examples below.

**See:** `reference/model_selection.md` for additional Task tool examples.

---

## S7/S9 Variant Usage

**When invoked from S7.P3 (Feature PR Review) or S9.P4 (Epic PR Review):**

This code review workflow is used with the following modifications:

### Modified Step Sequence

**Standard workflow:** Step 1 → Step 2 → Step 3 → Step 4 → Step 5 → Step 6 → Step 7

**S7/S9 variant:** Step 1 → Step 2 → **[Skip 3-4]** → Step 5 → Step 6 → Step 7

**Skipped steps:**
- **Step 3:** Write overview.md (NOT needed for internal S7/S9 reviews)
- **Step 4:** Run overview validation loop (NOT needed for internal S7/S9 reviews)

**Why skip overview.md?**
- Primary agent already has full implementation context (they implemented the code)
- Saves ~20-30% of review tokens
- review_vN.md is the actionable artifact — overview is supplementary for external reviews

### Additional Dimension for S7/S9

**Step 7 validation includes Dimension 13 (Implementation Fidelity):**

When reviewing S7.P3 or S9.P4 branches, Step 7 validates **13 dimensions** (not 12):
- **7 Master Dimensions** (standard)
- **6 Code Review-Specific Dimensions** (standard 5 + Implementation Fidelity)

**Dimension 13 — Implementation Fidelity:**
- **S7.P3 context:** Verify every proposal in validated implementation plan has corresponding code; all spec requirements addressed; no scope creep; no missing features
- **S9.P4 context:** Verify all feature implementation plans collectively satisfy epic goals; verify no epic-level requirements missed; verify no scope creep at epic level

**Context requirements:**
- S7.P3: Feature implementation plan + feature spec must be accessible
- S9.P4: All feature implementation plans + all feature specs + epic request file must be accessible

### Scope Differences

**S7.P3 (Feature PR Review):**
- **Scope:** Feature-level code quality
- **12 review categories:** Standard interpretation (per-feature concerns)
- **Dimension 13:** Feature-level implementation fidelity

**S9.P4 (Epic PR Review):**
- **Scope:** Epic-level concerns (cross-feature integration, architectural coherence)
- **12 review categories:** Epic-scope interpretation (cross-feature concerns, NOT per-feature quality — S7.P3 already did that)
- **Dimension 13:** Epic-level implementation fidelity (all features collectively satisfy epic goals)

### Complete S7/S9 Variant Documentation

**See:** `code_review/s7_s9_code_review_variant.md` for complete S7/S9 variant workflow, Task tool examples, and comment addressing protocol.

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

**Task Tool Example for Git Operations (Haiku):**

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Fetch branch and get file list</parameter>
  <parameter name="prompt">Fetch the branch and get the list of changed files for code review.

**Branch:** {branch_name}
**Base branch:** main

**Commands to run:**
1. git fetch origin {branch_name}
2. git diff --name-only $(git merge-base main {branch_name}) {branch_name}
3. git log main..{branch_name} --oneline

Report:
- Fetch success/failure
- List of changed files (one per line)
- List of commits with messages
  </parameter>
</invoke>
```

**Why Haiku?** Git operations are mechanical tasks with no deep reasoning required (70-80% token savings).

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

**Task Tool Example for ELI5 Generation (Sonnet):**

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">sonnet</parameter>
  <parameter name="description">Generate ELI5 summary for overview</parameter>
  <parameter name="prompt">Generate an ELI5 (Explain Like I'm 5) summary of the branch changes.

**Branch:** {branch_name}
**Changed files:** {file_list}
**Commit messages:** {commit_messages}
**Diff summary:** {brief_diff_context}

**Requirements:**
- 2-4 sentences in plain English
- Understandable to someone with NO context on this codebase
- Focus on observable behavior, not implementation details
- Avoid jargon, file names, function names
- Describe what the user/system can now do that it couldn't before (or what changed in behavior)

Write the ELI5 section only.
  </parameter>
</invoke>
```

**Why Sonnet?** ELI5 generation requires summarization and clear communication but not deep technical reasoning (40-50% token savings vs Opus).

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

After `consecutive_clean = 1` (primary clean round), EXECUTE THE FOLLOWING TASK TOOL CALLS IN A SINGLE MESSAGE:

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues in overview.md (sub-agent A)</parameter>
  <parameter name="prompt">You are sub-agent A confirming zero issues in code review overview.md.

**Overview file:** .shamt/code_reviews/{sanitized_branch}/overview.md
**Branch:** {branch_name}
**Primary agent claims:** Primary clean round achieved (zero issues OR 1 LOW fixed)

**Your task:** Re-read overview.md and verify ALL 5 dimensions:
1. **Correctness:** Every factual claim verified against diff/git show (not inferred)
2. **Completeness:** All files and hunks in diff accounted for
3. **Consistency:** ELI5, What, Why, How sections agree with each other
4. **Clarity:** ELI5 understandable to non-technical reader; How section specific enough
5. **Scope:** Overview describes only what's in the diff (no speculation)

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found in overview.md - all 5 dimensions verified".

**Context:**
- Files changed: {count}
- Commits: {count}
- Validation rounds completed: {N}
  </parameter>
</invoke>

<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues in overview.md (sub-agent B)</parameter>
  <parameter name="prompt">You are sub-agent B confirming zero issues in code review overview.md.

**Overview file:** .shamt/code_reviews/{sanitized_branch}/overview.md
**Branch:** {branch_name}
**Primary agent claims:** Primary clean round achieved (zero issues OR 1 LOW fixed)

**Your task:** Re-read overview.md and verify ALL 5 dimensions:
1. **Correctness:** Every factual claim verified against diff/git show (not inferred)
2. **Completeness:** All files and hunks in diff accounted for
3. **Consistency:** ELI5, What, Why, How sections agree with each other
4. **Clarity:** ELI5 understandable to non-technical reader; How section specific enough
5. **Scope:** Overview describes only what's in the diff (no speculation)

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found in overview.md - all 5 dimensions verified".

**Context:**
- Files changed: {count}
- Commits: {count}
- Validation rounds completed: {N}
  </parameter>
</invoke>
```

**Why Haiku?** Sub-agent confirmations are focused verification tasks (70-80% token savings). Haiku excels at dimensional checking without requiring deep reasoning.

**What happens next:**
- Both confirm zero issues → Exit overview loop, proceed to Step 5
- Either sub-agent finds issues → Fix, reset `consecutive_clean = 0`, continue primary rounds

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

```text
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

### Validation Dimensions — Checked Every Round

**Note:** Code reviews have **12 dimensions** (7 master + 5 code-review-specific) for formal external reviews, or **13 dimensions** (7 master + 6 code-review-specific) when invoked from **S7.P3 or S9.P4** (adds Implementation Fidelity dimension).

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

**Code Review-Specific Dimensions (5 standard, +1 for S7/S9):**

| # | Dimension | What to Check |
|---|-----------|---------------|
| 8 | **Coverage Balance** | Comment distribution reflects actual risk — critical areas (auth, data writes, error paths) are not under-reviewed relative to trivial ones |
| 9 | **False Positive Audit** | Every BLOCKING and CONCERN is re-verified against the current diff to confirm the issue still holds; any that don't survive re-verification are removed |
| 10 | **Actionability** | Every comment gives the author enough context to make a concrete change; no comment identifies a problem without a path forward |
| 11 | **Severity Calibration** | BLOCKING is reserved for issues that genuinely cannot be merged safely; CONCERN/SUGGESTION/NITPICK distinctions are sound and consistently applied |
| 12 | **Scope Coherence** | Comments stay within what the PR is attempting; no scope creep into "while you're here, refactor X" unless it directly affects correctness or safety |

**S7/S9-Specific Dimension (only when invoked from S7.P3 or S9.P4):**

| # | Dimension | What to Check |
|---|-----------|---------------|
| 13 | **Implementation Fidelity** | Every proposal in the validated implementation plan has corresponding code changes; all spec requirements are addressed in implementation; no scope creep (no features not in spec); no missing features (all spec requirements fully implemented) |

**Context:** Dimension 13 applies only to S7.P3 (Feature PR Review) and S9.P4 (Epic PR Review) contexts where validated implementation plans and specs exist. Formal code reviews of external PRs check only dimensions 1-12.

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
3. Check all dimensions (12 for formal reviews, 13 for S7/S9) and document PASS or ISSUE for each
4. Run the Adversarial Self-Check
5. Fix any issues found immediately in the review file
6. State `consecutive_clean = N` at the end of the round

**Counter tracking:**
```text
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

After `consecutive_clean = 1` (primary clean round), EXECUTE THE FOLLOWING TASK TOOL CALLS IN A SINGLE MESSAGE:

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues in review_vN.md (sub-agent A)</parameter>
  <parameter name="prompt">You are sub-agent A confirming zero issues in code review review_vN.md.

**Review file:** .shamt/code_reviews/{sanitized_branch}/review_v{N}.md
**Branch:** {branch_name}
**Primary agent claims:** Primary clean round achieved (zero issues OR 1 LOW fixed), passed adversarial self-check

**Your task:** Re-read review_vN.md and verify ALL dimensions (12 for formal reviews, 13 for S7/S9):

**Master Dimensions (7):**
1. **Empirical Verification:** Every comment cites specific file + line verified with git show
2. **Completeness:** Every file in diff examined, no hunks skipped
3. **Internal Consistency:** No contradictory comments, similar issues rated consistently
4. **Traceability:** Each comment traces to specific diff hunk
5. **Clarity & Specificity:** BLOCKING/CONCERN have exact problem + concrete fix
6. **Codebase Alignment:** Comments don't flag existing codebase patterns
7. **Format Compliance:** Follows output_format.md spec

**Code Review-Specific Dimensions (5):**
8. **Coverage Balance:** Comment distribution reflects actual risk
9. **False Positive Audit:** BLOCKING/CONCERN re-verified against current diff
10. **Actionability:** Every comment gives author concrete change path
11. **Severity Calibration:** BLOCKING reserved for genuine merge blockers
12. **Scope Coherence:** Comments within PR scope, no scope creep

**S7/S9-Specific Dimension (only if invoked from S7.P3 or S9.P4):**
13. **Implementation Fidelity:** Every proposal in implementation plan has corresponding code; all spec requirements addressed; no scope creep; no missing features

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found in review_v{N}.md - all dimensions verified".

**Context:**
- Review categories present: {count}
- BLOCKING issues: {count}
- CONCERN issues: {count}
- Validation rounds completed: {N}
  </parameter>
</invoke>

<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues in review_vN.md (sub-agent B)</parameter>
  <parameter name="prompt">You are sub-agent B confirming zero issues in code review review_vN.md.

**Review file:** .shamt/code_reviews/{sanitized_branch}/review_v{N}.md
**Branch:** {branch_name}
**Primary agent claims:** Primary clean round achieved (zero issues OR 1 LOW fixed), passed adversarial self-check

**Your task:** Re-read review_vN.md and verify ALL dimensions (12 for formal reviews, 13 for S7/S9):

**Master Dimensions (7):**
1. **Empirical Verification:** Every comment cites specific file + line verified with git show
2. **Completeness:** Every file in diff examined, no hunks skipped
3. **Internal Consistency:** No contradictory comments, similar issues rated consistently
4. **Traceability:** Each comment traces to specific diff hunk
5. **Clarity & Specificity:** BLOCKING/CONCERN have exact problem + concrete fix
6. **Codebase Alignment:** Comments don't flag existing codebase patterns
7. **Format Compliance:** Follows output_format.md spec

**Code Review-Specific Dimensions (5):**
8. **Coverage Balance:** Comment distribution reflects actual risk
9. **False Positive Audit:** BLOCKING/CONCERN re-verified against current diff
10. **Actionability:** Every comment gives author concrete change path
11. **Severity Calibration:** BLOCKING reserved for genuine merge blockers
12. **Scope Coherence:** Comments within PR scope, no scope creep

**S7/S9-Specific Dimension (only if invoked from S7.P3 or S9.P4):**
13. **Implementation Fidelity:** Every proposal in implementation plan has corresponding code; all spec requirements addressed; no scope creep; no missing features

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found in review_v{N}.md - all dimensions verified".

**Context:**
- Review categories present: {count}
- BLOCKING issues: {count}
- CONCERN issues: {count}
- Validation rounds completed: {N}
  </parameter>
</invoke>
```

**Why Haiku?** Sub-agent confirmations are focused verification tasks (70-80% token savings). Haiku excels at dimensional checking.

**What happens next:**
- Both confirm zero issues → Exit review loop, code review complete
- Either sub-agent finds issues → Fix, reset `consecutive_clean = 0`, continue primary rounds

---

## After the Workflow Completes

The branch sub-folder now contains:
- `overview.md` — validated branch description
- `overview_validation_log.md` — overview validation history
- `review_vN.md` — validated review comments, copy-paste ready
- `review_validation_log.md` — review validation history

Tell the user the review is complete and the files are at `.shamt/code_reviews/<sanitized-branch>/`. They can copy individual comment blocks directly into GitHub/GitLab/Bitbucket PR comment boxes.
