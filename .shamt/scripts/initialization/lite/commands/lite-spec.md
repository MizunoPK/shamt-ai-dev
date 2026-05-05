# /lite-spec

**Purpose:** Run the Shamt Lite Spec Protocol on a ticket — research, design dialog, validated spec.

**Invokes:** `shamt-lite-spec` skill

---

## Usage

```
/lite-spec {slug}
```

## Arguments

- `{slug}` (required) — story slug. Story folder must exist with a populated `stories/{slug}/ticket.md`.

## What Happens

1. The agent loads the `shamt-lite-spec` skill
2. Step 1 — ingests the ticket from `stories/{slug}/ticket.md` (3-5 bullet summary)
3. Step 2 — runs targeted research scoped to ticket references
4. Step 3 — drafts a spec skeleton with 8 sections at `stories/{slug}/spec.md`
5. Step 4 — proposes 1-3 design options inline; **Gate 2a** waits for explicit user approval
6. Step 5 — fleshes out the spec with the agreed design
7. Step 6 — runs `/lite-validate` on the spec (7 spec dimensions, 1 sub-agent)
8. Step 7 — **Gate 2b** presents the validated spec for final approval

## Expected Output

- `stories/{slug}/spec.md` with all 8 sections, validation footer, and user approval

## Notes

- Skill halts if `ticket.md` is empty or missing — populate it first.
- Pattern 3 from `SHAMT_LITE.md` is the source.
- For non-story specs (ad-hoc design), invoke the skill directly with a brief instead of a slug.
