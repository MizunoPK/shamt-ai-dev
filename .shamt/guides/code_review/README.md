# Code Review Workflow

**Purpose:** Standalone review of any branch or PR without modifying the working directory. Produces a per-branch sub-folder with a validated overview document and versioned, copy-paste-ready review comments.

---

## When to Use

**Use this workflow when:**
- Reviewing a teammate's branch before merge
- Reviewing an open-source or cross-team PR
- Any branch that is NOT the agent's own current work

**Do NOT use for:**
- Reviewing your own epic's PR → use S9.P4 instead
- The branch cannot be fetched (does not exist locally or remotely) → halt and report to user

---

## Quick Start

User invokes with natural language:

> "Review branch `feat/my-feature`"
> "Do a code review of `kai/fix-auth`"
> "Review the changes on `origin/feature/TICKET-99`"

For a re-review of the same branch:

> "Re-review `feat/my-feature`"
> "Run a new review of `kai/fix-auth`"

**To run the workflow:** Read `code_review_workflow.md` and follow it completely.

Use the prompt shortcut from `prompts/special_workflows_prompts.md` (Code Review section) to invoke correctly.

---

## Output

Each review creates a sub-folder:

```text
.shamt/code_reviews/<sanitized-branch>/
├── overview.md                  — ELI5 + What/Why/How (validated, created first)
├── overview_validation_log.md   — validation log for the overview
├── review_v1.md                 — first code review
├── review_validation_log.md     — validation log for the review
└── review_v2.md                 — re-review (if requested; never overwrites v1)
```

Sanitization: replace `/` → `_`, keep alphanumeric, `-`, `_` only. Full examples in `output_format.md`.

The `.shamt/code_reviews/` directory is per-project and is NOT propagated via import. Commit review files to your project repo.

---

## Process Overview

1. **Access branch read-only** — `git fetch` if needed; `git diff`/`git show`/`git log` only; no checkout
2. **Write `overview.md`** — ELI5, What, Why, How — then run 5-dimension validation loop until clean
3. **Write `review_vN.md`** — review comments across 12 categories — then run 12-dimension validation loop until clean

Both validation loops exit on: **primary clean round + 2 independent sub-agents confirm zero issues.**

---

## Files

| File | Purpose |
|------|---------|
| `code_review_workflow.md` | Step-by-step executable workflow |
| `output_format.md` | Templates, sanitization rules, severity definitions, comment format |
| `s7_s9_code_review_variant.md` | S7/S9 variant workflow (skips overview.md, adds Dimension 13) |
