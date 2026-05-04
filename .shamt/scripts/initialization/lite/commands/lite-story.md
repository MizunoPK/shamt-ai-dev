# /lite-story

**Purpose:** Run the full Shamt Lite six-phase story workflow (Intake → Spec → Plan → Build → Review → Polish).

**Invokes:** `shamt-lite-story` skill

---

## Usage

```
/lite-story {slug}
```

## Arguments

- `{slug}` (optional) — story slug. If omitted, the skill will prompt for one. The story folder will be created at `stories/{slug}/`.

## What Happens

1. The agent loads the `shamt-lite-story` skill
2. Phase 1 (Intake): captures the ticket at `stories/{slug}/ticket.md` (Gate 1: user confirms slug + content)
3. Phase 2 (Spec): runs the 7-step Spec Protocol via `shamt-lite-spec` (Gate 2a: design dialog, Gate 2b: validated spec approved)
4. Phase 3 (Plan): runs the 5-step Implementation Planning protocol via `shamt-lite-plan` (Gate 3: validated plan approved)
5. Phase 4 (Build): executes the plan (or hands off to a Haiku builder)
6. Phase 5 (Review): runs `shamt-lite-review` in story mode
7. Phase 6 (Polish): captures generalizable lessons in commit messages and `CHANGES.md` entries

## Notes

- Phase boundaries are natural `/clear` breakpoints. After Gate 2b and Gate 3, consider clearing context.
- For ad-hoc work without the full six-phase wrapper, invoke individual skills directly: `/lite-spec`, `/lite-plan`, `/lite-review`, `/lite-validate`.
- See `SHAMT_LITE.md` and `story_workflow_lite.md` for protocol details.
