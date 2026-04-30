# Master Dev Workflow — Guide Improvement Process

This guide defines the standardized process for improving the master Shamt guides directly (as opposed to receiving improvements via a child project PR).

Use this when:
- You've identified a gap, error, or improvement opportunity in the master guides
- You're making structural changes to the guide system
- You're adding new guides or sections

This process is intentionally lighter than the full S1-S11 epic workflow. It's aligned with S11's lessons-learned update approach.

**Model Selection for Token Optimization (SHAMT-27):**

Master dev workflow can save 15-25% tokens through delegation:

```text
Primary Agent (Opus):
├─ Spawn Haiku → Verify guide file paths, count files affected
├─ Spawn Sonnet → Read guides to understand current state
├─ Primary handles → Design decisions, guide writing, audit running
└─ Primary executes → Git operations, commits, PR creation
```

**See:** `reference/model_selection.md` for Task tool examples.

---

## Primitives Available

The following cross-cutting workflows are available as documented composites. Reference
these rather than re-deriving the assembly from scratch:

| Composite | When to use in master dev |
|-----------|--------------------------|
| [`composites/validation_loop_composite.md`](../composites/validation_loop_composite.md) | Any design doc validation or implementation validation loop |
| [`composites/architect_builder_composite.md`](../composites/architect_builder_composite.md) | Step 3.5 — large implementation tasks |
| [`composites/rollback_recovery_composite.md`](../composites/rollback_recovery_composite.md) | When worktree isolation or stall recovery is needed |
| [`composites/stale_work_janitor_composite.md`](../composites/stale_work_janitor_composite.md) | Recurring janitor scans for incoming proposals and stale docs |
| [`composites/master_review_pipeline_composite.md`](../composites/master_review_pipeline_composite.md) | Child PR review, guide audit post-merge |
| [`composites/metrics_observability_composite.md`](../composites/metrics_observability_composite.md) | Metrics emission and dashboard setup |

---

## When to Use This vs. the Full Epic Workflow

| Scope | Use |
|-------|-----|
| Single guide fix, clarification, or small addition | This workflow |
| New guide section (< 1 guide file) | This workflow |
| New guide files or significant restructuring | Full epic workflow (S1-S11) with SHAMT epic tracking |
| Multi-guide cross-cutting changes | Full epic workflow |

---

## Step 1: Define the Change

Before touching any files, write a one-paragraph description of:
- What the current guide says (or doesn't say)
- What the problem or gap is
- What the improvement should be

This becomes the basis for your commit message or PR description.

---

## Step 2: Read the Affected Guides

Use the Read tool to load the full content of every guide you plan to modify.

Do not work from memory. Even if you just read the guide, re-read it now.

---

## Step 3: Make the Changes

Apply your improvements to the guide files.

Rules:
- Fix ALL issues in one pass — do not leave partial fixes
- If you discover scope is larger than expected → stop and switch to full epic workflow
- No deferred issues — fix everything or don't change anything

**If your changes affect system behavior** (new sync scripts, new guides, new audit scope, new workflow steps, changed commands or file locations): also review and update the three master-only files that are not propagated to child projects via import:
- [ ] `CLAUDE.md` (root) — does the PR review checklist, Critical Rules, or workflow description need updating?
- [ ] Root `README.md` — does the sync or initialization description need updating?
- [ ] `scripts/initialization/RULES_FILE.template.md` — does the Shamt Sync section or any other section need updating?

These files are the agent's first point of reference and are not kept current by the import mechanism — they require deliberate manual updates when behavior changes.

---

## Step 3.5: Implementation Approach (Optional: Architect-Builder Pattern)

**For implementation tasks** (as opposed to documentation-only changes), you can optionally use the architect-builder pattern for token optimization.

### When to Use Architect-Builder Pattern

**Use the pattern when:**
- **>10 file operations** (CREATE, EDIT, DELETE, MOVE)
- **Implementation will consume >100K tokens** with traditional approach (architect executing own plan)
- **Complex dependencies** - changes span multiple subsystems
- **First-time implementation** in unfamiliar codebase section

**Skip the pattern when:**
- **1-5 file changes** with straightforward implementation
- **Exploratory work** (debugging, investigation, understanding codebase)
- **Time-sensitive rapid iteration** needed
- **Prototype/spike code** that will be rewritten

### How to Use the Pattern

If using architect-builder pattern for master dev work:

1. **Create mechanical implementation plan:**
   - Read: `reference/implementation_plan_format.md` (plan specification)
   - Use template: `templates/implementation_plan_template.md`
   - Create: `design_docs/active/SHAMT{N}_IMPLEMENTATION_PLAN.md`
   - Format: Step-by-step file operations (CREATE/EDIT/DELETE/MOVE) with exact details

2. **Validate mechanical plan (9 dimensions):**
   - Create: `design_docs/active/SHAMT{N}_IMPL_PLAN_VALIDATION_LOG.md`
   - Run validation loop (9 dimensions from `reference/implementation_plan_format.md`)
   - Exit when: primary clean round + 2 Haiku sub-agents confirm zero issues
   - Update plan status to "Validated"

3. **Hand off to Haiku builder:**
   - Create handoff package (see `reference/architect_builder_pattern.md`, "Handoff Package Format")
   - Spawn Haiku builder using Task tool with `model="haiku"`
   - Builder executes plan mechanically
   - On success: proceed to Step 4 (audit)
   - On error: diagnose, fix plan, resume from failed step

4. **After builder completes:**
   - Move plan and validation log to `design_docs/archive/` with design doc
   - Proceed to Step 4 (guide audit)

**Token savings:** 60-70% on implementation execution (Haiku builder vs. Sonnet/Opus architect)

**See:**
- `reference/architect_builder_pattern.md` - Complete pattern documentation and decision tree
- `reference/implementation_plan_format.md` - Mechanical plan specification (9 validation dimensions)
- [`composites/architect_builder_composite.md`](../composites/architect_builder_composite.md) — End-to-end composite (plan mode, async builder, worktree rollback)

**Note:** Architect-builder pattern is **optional** for master dev workflow (use judgment based on thresholds above). It is **mandatory** for S1-S11 epic workflow S6 (no exceptions).

---

## Step 4: Run the Guide Audit

After making changes:

1. Open `.shamt/guides/audit/README.md`
2. Run the pre-audit checks: `bash .shamt/guides/audit/scripts/pre_audit_checks.sh` (if applicable)
3. Work through the audit stages
4. Fix any issues found before proceeding
5. The audit must pass cleanly. Record the result with `shamt.audit_run()` MCP tool so the pre-push tripwire can verify it. See [`composites/master_review_pipeline_composite.md`](../composites/master_review_pipeline_composite.md) for the `/loop`-driven guide audit flow.

---

## Step 5: Commit

```bash
git add .shamt/guides/ .shamt/scripts/ .shamt/skills/ .shamt/agents/ .shamt/commands/ .shamt/hooks/
git commit -m "feat/SHAMT-[N]: [brief description of guide improvement]"
```

Note: the `commit-format` hook (SHAMT-41) enforces the `feat/SHAMT-N:` prefix — commits with non-conforming messages are blocked. The `pre-push-tripwire` hook will be available after SHAMT-44.

For master-internal improvements, commit directly to a branch and open a PR against `main`. Child projects will receive the improvement on their next import.

---

## Session Management

The `precompact-snapshot.sh` and `session-start-resume.sh` hooks (SHAMT-41) auto-manage context across compaction events when `features.shamt_hooks=true` is set. On session start, if a `RESUME_SNAPSHOT.md` exists for the active epic, its content is injected as agent context automatically. No manual GUIDE_ANCHOR / Resume Instructions step is needed for sessions where these hooks fire.

---

## Larger Changes: Branch + Design Doc

For multi-guide or cross-cutting changes, use a branch with a design doc:

1. **Reserve SHAMT-N number:** Use `shamt.next_number()` MCP tool (atomic — handles concurrent sessions safely) OR read `design_docs/NEXT_NUMBER.txt` manually, use that number, increment the file
2. **Create branch:** `feat/SHAMT-[N]`
3. **Create design doc:** Use the template at `.shamt/guides/templates/design_doc_template.md` to create `design_docs/active/SHAMT[N]_DESIGN.md`
4. **Validate design doc:** Follow `.shamt/guides/design_doc_validation/validation_workflow.md` to validate the design (7-dimension validation loop with sub-agent confirmation). Use `shamt.validation_round()` with `exit_threshold=1` to track rounds; `validation-log-stamp` hook auto-stamps log edits. See [`composites/validation_loop_composite.md`](../composites/validation_loop_composite.md) for the full assembled picture including `/loop` self-pacing and stall detection.
5. **Implement:** Make changes across the affected guides and scripts. After implementing, run a D-COVERAGE pass: (a) if you modified a guide that is a `source_guides:` reference in a SKILL.md, update the skill body where warranted — if a modified source guide now diverges from its SKILL.md, update the skill body in the same commit; (b) if you modified a SKILL.md, add to the corresponding source guides any protocol content not present in any source guide. The D-DRIFT / D-COVERAGE audit dimensions will catch gaps, but catching them during implementation is cheaper.
6. **Validate implementation:** Run implementation validation loop (see design doc Proposal 10 pattern). Use `shamt.validation_round()` with `exit_threshold=1`. See [`composites/validation_loop_composite.md`](../composites/validation_loop_composite.md) for `/loop` self-pacing.
7. **Guide audit:** Run the full guide audit (3 consecutive clean rounds required; ≤1 LOW per round is clean). See [`composites/master_review_pipeline_composite.md`](../composites/master_review_pipeline_composite.md) for `/loop`-driven audit flow.
8. **Archive design doc:** Move `SHAMT[N]_DESIGN.md` and validation log to `design_docs/archive/`
9. **Open PR:** PR against `main` — child projects receive the changes on their next import run

**Design doc lifecycle states:**
- **Draft** → Being written, not yet validated
- **Validated** → Passed 7-dimension validation, ready for implementation
- **In Progress** → Implementation underway on branch
- **Implemented** → Implementation complete, moved to archive

**What NOT to do for master work:**
- Do not maintain `.shamt/epics/EPIC_TRACKER.md` — SHAMT-N numbers are sequence markers, not epic IDs
- Do not follow S1-S11 stage gates or phase transitions
- Do not create epic folders in `.shamt/epics/`

**Scope threshold:** Judgment call. Single-guide fix → lightweight workflow (Steps 1-5 above). Multi-guide or requires planning → branch + design doc. There is no formal gate between the two.
