# Architect–Builder Composite

**What this is:** The full architect–builder pipeline assembled from its component parts —
plan mode, S5/S6 guides, builder sub-agent, worktree/container isolation, cloud variant,
and `run_in_background` async dispatch. Read this guide to understand how the pieces
interact; read the primitive guides for full detail on each part.

---

## Component Map

| Component | Where it lives | Role |
|-----------|---------------|------|
| `shamt-architect` persona | `.shamt/agents/shamt-architect.yaml` | Plans (S5); creates handoff (S6); monitors builder |
| `shamt-builder` persona | `.shamt/agents/shamt-builder.yaml` | Executes plan mechanically (S6) |
| S5 guide | `guides/stages/s5/` | Architect creates + validates mechanical plan |
| S6 guide | `guides/stages/s6/` | Architect creates handoff; spawns builder |
| `architect-builder-enforcer.sh` | `.shamt/hooks/` | Blocks non-builder Task spawns in S6 |
| Plan mode (Claude Code) | Built into Claude Code | S5: prevents implementation writes during planning |
| `run_in_background` (Claude Code) | Agent tool parameter | S6: architect spawns builder asynchronously |
| Cloud S6 builder | `guides/stages/s6/cloud_variant.md` | Codex Cloud: container executes plan, opens PR |

**Primitive home guides:**
- Pattern overview: `guides/reference/architect_builder_pattern.md`
- Plan format: `guides/reference/implementation_plan_format.md`
- Plan template: `guides/templates/implementation_plan_template.md`
- Validation log template: `guides/templates/implementation_plan_validation_log_template.md`

---

## How the Pieces Work Together

### S5: Architect Plans

**Plan mode is ACTIVE during S5.** On Claude Code, the architect enters Plan mode before
reading the codebase. Plan mode prevents any file writes during the planning phase; the
architect can read, search, and reason, but cannot implement. This ensures the validated
plan commits to the architectural decisions before any code is written.

S5 flow:
1. Architect (Sonnet/Opus) reads codebase, spec, and existing guides
2. Creates a mechanical step-by-step implementation plan (CREATE/EDIT/DELETE/MOVE operations
   with exact file paths, content, and verification steps)
3. Runs the 9-dimension implementation plan validation loop
4. User approves at Gate 5 (no architect proceeds without approval)
5. Exits Plan mode

### S6: Handoff and Async Execution

The architect creates a builder handoff package containing:
- The full validated implementation plan
- Builder instructions (mechanical execution only — no design decisions)
- Error handling protocol (what to report and when)
- Verification checklist

Then spawns the builder **asynchronously** using `run_in_background=True`:

```python
Agent(
    subagent_type="general-purpose",
    model="haiku",
    description="S6 builder: execute implementation plan",
    prompt="[full handoff package content]",
    run_in_background=True
)
```

**While the builder runs**, the architect can perform concurrent work:
- Update `EPIC_METRICS.md` with plan-phase metrics
- Draft the S7 smoke test plan
- Review any blocking open questions
- Answer user questions about the plan

The architect is **notified automatically** when the builder completes or errors
(Claude Code delivers the completion notification). Do not poll.

### S6: Builder Execution

The Haiku builder executes the plan sequentially:
- One step at a time, in dependency order
- No design decisions — if a step is unclear, report immediately (do not guess)
- Verify each step against the verification checklist before moving to the next
- Report: "COMPLETE: all N steps executed" OR "ERROR at step M: {description}"

### S6: Architect Handles Builder Output

**On success:** Architect reviews the builder's checklist results, runs any smoke tests
specified in the handoff, and confirms no regressions.

**On builder error:** Architect diagnoses, updates the plan (not a full re-plan unless
the error reveals a design flaw), and re-spawns the builder for the remaining steps.

**`architect-builder-enforcer.sh` hook:** In S6, any Task spawn that does not use
`shamt-builder` persona is blocked. This prevents the architect from accidentally executing
implementation itself, bypassing the token-saving delegation.

### Plan Mode in S10.P1

Plan mode also applies in S10.P1 (overview document authoring). The S10 overview is a
read-heavy narrative synthesis; no implementation writes should occur until the narrative
is complete. Enforce: architect reads all S1–S9 artifacts in plan mode before writing
the overview document.

---

## Multi-Feature Parallel Work (S2)

For epics with multiple independent features, S2 parallel work uses `run_in_background`:

1. Primary agent coordinates; each feature gets its own sub-agent
2. Each sub-agent runs in a **distinct worktree** (Claude Code) or **separate container**
   (Codex Cloud) — no shared mutable state
3. Sub-agents report back on completion; primary agent integrates results

**Note:** The `parallel_work/` guides predate `run_in_background`. Consult this composite
for the current recommended pattern; the `parallel_work/` guides are legacy references
for context on the design intent.

---

## Codex Cloud Variant

Architect commits the validated plan, then launches a Codex Cloud task with the
`shamt-s6-builder` profile. The cloud container:
1. Clones the branch
2. Executes the mechanical plan
3. Runs verification checklist
4. Opens a PR on success OR discards container on failure (container disposability = zero
   local damage on error)

The architect (Codex CLI session) polls or is notified via PR creation. No `run_in_background`
needed — cloud tasks are inherently async.

Full detail: `guides/stages/s6/cloud_variant.md`

---

## Master Dev Variant

The architect–builder pattern is **optional** for master dev work. Use it when:
- >10 file operations
- Estimated >100K tokens with traditional approach
- Complex dependencies between files
- Unfamiliar area of the codebase

Skip it when:
- 1–5 file changes
- Exploratory work or rapid iteration
- Prototyping

See the decision tree in `guides/reference/architect_builder_pattern.md`.

When used in master dev work, follow the same S5 → S6 flow. Plan mode applies in S5.
The `architect-builder-enforcer.sh` hook is active in master work for any Task spawns
during implementation phases.
