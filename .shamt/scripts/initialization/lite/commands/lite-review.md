# /lite-review

**Purpose:** Run the Shamt Lite Code Review pattern — story mode (review code you just built) or formal mode (review someone else's branch/PR).

**Invokes:** `shamt-lite-review` skill

---

## Usage

```
/lite-review {target}
```

## Arguments

- `{target}` (required) — either a story slug (story mode) or a branch name (formal mode).
  - Story mode example: `/lite-review add-export` → reads `stories/add-export/`
  - Formal mode example: `/lite-review feat/add-export-button` → reviews `origin/feat/add-export-button` against `origin/main`

## What Happens

1. The agent loads the `shamt-lite-review` skill
2. Step 1 — fetches branch metadata (read-only git; **never checks out the branch**)
3. **Story mode:** skips Steps 2-4. **Formal mode:** creates `.shamt/code_reviews/<sanitized-branch>/`, writes `overview.md` (What/Why/How), validates it (4 general dimensions, 1 sub-agent)
4. Step 5 — writes `review_v1.md` grouped by severity (BLOCKING / CONCERN / SUGGESTION / NITPICK) and 12 categories
5. Step 6 — runs `/lite-validate` on the review (5 review dimensions, 1 sub-agent)
6. Step 7 — on re-review: creates `review_v2.md`, `review_v3.md` etc. Never overwrites.

## Expected Output

- **Story mode:** `stories/{slug}/code_review/review_v1.md` with validation footer
- **Formal mode:** `.shamt/code_reviews/<branch>/overview.md` and `review_v1.md`, both with validation footers

## Notes

- The skill is **read-only with git** — it never checks out the branch you're reviewing.
- "No issues found." is a valid review — do not fabricate findings to fill space.
- Pattern 4 from `SHAMT_LITE.md` is the source.
