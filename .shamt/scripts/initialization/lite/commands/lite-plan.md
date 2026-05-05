# /lite-plan

**Purpose:** Run the Shamt Lite Implementation Planning protocol — produce a mechanical, validated implementation plan from an approved spec.

**Invokes:** `shamt-lite-plan` skill

---

## Usage

```
/lite-plan {slug}
```

## Arguments

- `{slug}` (required) — story slug. Spec must exist and be approved at `stories/{slug}/spec.md`.

## What Happens

1. The agent loads the `shamt-lite-plan` skill
2. Step 1 — reads the spec; halts if Open Questions remain unresolved
3. Step 2 — drafts a mechanical step-by-step plan at `stories/{slug}/implementation_plan.md` (CREATE/EDIT/DELETE/MOVE operations)
4. Step 3 — runs `/lite-validate` on the plan (7 plan dimensions, 1 sub-agent)
5. Step 4 — **Gate 3** presents the validated plan for user approval
6. Step 5 — executes the plan (or hands off to a Haiku builder if >10 mechanical steps)

## Expected Output

- `stories/{slug}/implementation_plan.md` with each step mechanical, validation footer, and user approval
- (Optional) Builder execution complete and verified

## Notes

- Builder handoff is **recommended** for plans with >10 mechanical steps; the cheap-tier builder (Haiku on Claude / DEFAULT_MODEL on Codex) executes sequentially while the architect monitors.
- Builder handoff is **not recommended** for plans with <10 steps — overhead exceeds savings.
- Pattern 5 from `SHAMT_LITE.md` is the source.
