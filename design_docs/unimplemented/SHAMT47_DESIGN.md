# SHAMT-47: Master Repo Self-Integration — Wiring Primitives into Master Dev Workflow

**Status:** Retired — folded into SHAMT-39, 40, 41, 43, 44, 45
**Created:** 2026-04-28
**Retired:** 2026-04-28
**Branch:** N/A
**Validation Log:** [SHAMT47_VALIDATION_LOG.md](./SHAMT47_VALIDATION_LOG.md)
**Depends on:** SHAMT-39, SHAMT-40, SHAMT-41, SHAMT-42, SHAMT-43, SHAMT-44, SHAMT-45

---

## Problem Statement

SHAMT-39 through SHAMT-46 introduce a rich set of primitives — skills, hooks, MCP tools, agent personas, composites, and SDK scripts — designed to enforce quality patterns across Shamt projects. However, the **master repo itself** does not consume these primitives for its own development workflow. The master dev workflow guide (`master_dev_workflow.md`) and `CLAUDE.md` describe design doc creation, validation, implementation, and guide audits in prose terms that predate the primitive system.

This creates two problems:

1. **Master operates below its own standard.** Child projects that adopt SHAMT-39+ will have automated validation-log stamping, stall detection, pre-push tripwires, MCP-driven round tracking, and sub-agent confirmation enforcement. Master — the repo that defines these patterns — runs none of them for its own work.

2. **No integration testing of primitives.** Master is the first repo where these primitives should run. If master doesn't use them, the first real integration test happens in a child project, where the feedback loop is slower (export → PR → review → merge → import).

**Impact of NOT solving this:** Master dev workflow continues to rely on manual adherence to validation protocols. Hooks that would catch mistakes (stale audits, bad commit format, validation stalls) don't fire. MCP tools that would automate bookkeeping (`shamt.next_number()`, `shamt.validation_round()`, `shamt.audit_run()`) aren't called. The quality gap between master's documented standards and its actual enforcement widens as the primitive system matures.

---

## Goals

1. Wire all master-applicable hooks into the master repo's host configuration so they fire during master dev work
2. Update `master_dev_workflow.md` to reference specific skills, MCP tools, composites, and agent personas at each step where they apply
3. Update `CLAUDE.md` to reference the primitive system for master dev work (Design Doc Lifecycle, Implementation Validation, Guide Audit sections)
4. Define the master repo's operational posture: which host(s) it runs on, which profiles/hooks/MCP tools are active
5. Ensure master design doc validation uses the `validation_loop_composite` (not just prose description of the 7-dimension loop)
6. Ensure master guide audits use the `shamt-guide-audit` skill and `shamt.audit_run()` MCP tool

---

## Detailed Design

### Proposal 1: Master Repo Operational Posture

**Description:** Define the master repo as a first-class Shamt project that runs on Claude Code (primary) with optional Codex support for automated child PR review. The master repo gets its own hook set, MCP registration, and profile configuration — but uses the master dev workflow (not S1-S11) for its own work.

The master repo's `.claude/settings.json` and `.claude/commands/` are already created by SHAMT-40. This proposal ensures the master-applicable subset of hooks and MCP tools are active in the master configuration.

**Master-applicable hooks (11 of 13):**

| Hook | Trigger | Master Use |
|------|---------|------------|
| `no-verify-blocker.sh` | PreToolUse (Bash) | Enforce commit discipline |
| `commit-format.sh` | PreToolUse (Bash) | Enforce `feat/SHAMT-N:` prefix |
| `validation-log-stamp.sh` | PostToolUse (Edit *VALIDATION_LOG.md) | Auto-stamp design doc validation rounds |
| `precompact-snapshot.sh` | PreCompact | Save RESUME_SNAPSHOT.md during design doc work |
| `session-start-resume.sh` | SessionStart | Restore context from RESUME_SNAPSHOT.md |
| `subagent-confirmation-receipt.sh` | SubagentStop | Write veto flag when confirmer reports issues |
| `validation-stall-detector.sh` | PostToolUse (validation log) | Alert on ≥3 rounds with no progress |
| `pre-push-tripwire.sh` | PreToolUse (git push) | Refuse push if audit/validation unclean |
| `stage-transition-snapshot.sh` | UserPromptSubmit | Capture design doc phase transitions |
| `shamt-statusline.sh` | Manual/prompt | Render session status |
| `architect-builder-enforcer.sh` | PreToolUse (Task during S6) | Not active in master dev workflow (no S6); included for completeness if master uses architect-builder pattern |

**Hooks NOT applicable to master (2 of 13):**

| Hook | Reason |
|------|--------|
| `pre-export-audit-gate.sh` | Master doesn't export to itself |
| `user-testing-gate.sh` | S9-only child workflow |

**MCP tools active in master:**

| Tool | Master Use |
|------|------------|
| `shamt.next_number()` | Reserve SHAMT-N numbers at design doc creation |
| `shamt.validation_round()` | Track validation rounds with auto-computed consecutive_clean |
| `shamt.audit_run()` | Run guide audits programmatically |
| `shamt.epic_status()` | Query design doc work status (stage/phase/blockers) |
| `shamt.metrics.append()` | Emit duration/token metrics for design doc work |

**MCP tools NOT applicable to master:**

| Tool | Reason |
|------|--------|
| `shamt.export()` | Master doesn't export |
| `shamt.import()` | Master doesn't import |

**Rationale:** Master should eat its own dog food. The hook/MCP configuration for master is a strict subset of the child configuration — same files, same registration mechanism, just fewer entries. No new hooks or tools are needed.

**Alternatives considered:**
- *Master stays prose-only:* Rejected — quality gap widens as primitives mature; no integration testing venue.
- *Master adopts full S1-S11 workflow:* Rejected — master dev workflow is intentionally lighter; S1-S11 stage gates don't apply.
- *Create master-specific hooks/tools:* Rejected — the existing primitives already cover master's needs when the non-applicable ones are simply excluded.

---

### Proposal 2: Master Dev Workflow Guide Update

**Description:** Update `master_dev_workflow.md` to reference specific primitives at each step. The workflow structure stays the same (Steps 1–5 lightweight, branch+design doc for larger changes); only the tooling references change.

**Step-by-step integration points:**

| Existing Step | Primitive Integration |
|---------------|----------------------|
| **Step 1: Define the Change** | No change (prose-only) |
| **Step 2: Read Affected Guides** | Reference `shamt-guide-audit` skill for systematic reading; use `shamt.audit_run(scope="affected")` for targeted pre-read audit |
| **Step 3: Make Changes** | No change (manual editing) |
| **Step 3.5: Architect-Builder** | Reference `architect_builder_composite` and `shamt-architect`/`shamt-builder` agent personas; link to `reference/architect_builder_pattern.md` (already partially done) |
| **Step 4: Guide Audit** | Replace prose "run the audit" with: invoke `shamt-guide-audit` skill → calls `shamt.audit_run(scope="all")` → 3 consecutive clean rounds (tracked by `shamt.validation_round()`) |
| **Step 5: Commit** | `pre-push-tripwire` hook enforces clean audit + validation state; `commit-format` hook enforces prefix |
| **Branch + Design Doc: Reserve N** | Use `shamt.next_number()` MCP tool |
| **Branch + Design Doc: Validate** | Use `validation_loop_composite` (7D + `shamt.validation_round()` + `validation-log-stamp` hook + `shamt-validator` sub-agents) |
| **Branch + Design Doc: Implement** | Use `architect_builder_composite` when thresholds met (>10 file ops or >100K tokens) |
| **Branch + Design Doc: Impl Validation** | Use `validation_loop_composite` (5D variant) with `shamt.validation_round()` |
| **Branch + Design Doc: Guide Audit** | Same as Step 4 — `shamt-guide-audit` skill + `shamt.audit_run()` |
| **Session Management** | `precompact-snapshot` and `session-start-resume` hooks auto-manage context across compactions |

**Rationale:** The workflow structure is proven and doesn't need changing. What's missing is the concrete tool invocations. By adding primitive references, the guide becomes executable rather than aspirational — an agent reading the guide knows exactly which skill/tool/hook to invoke at each step.

**Alternatives considered:**
- *Rewrite the guide from scratch around composites:* Rejected — the existing structure is clear and well-tested; adding primitive references is additive, not disruptive.
- *Create a separate "master dev workflow v2" guide:* Rejected — one guide is better than two; the update is backward-compatible (agents without primitives can still follow the prose instructions).

---

### Proposal 3: CLAUDE.md Updates

**Description:** Update three sections of `CLAUDE.md` to reference the primitive system:

1. **Master Dev Workflow section:** Add a "Primitives Available" subsection listing the active hooks, MCP tools, and composites for master dev work. Reference `master_dev_workflow.md` for step-by-step integration.

2. **Design Doc Lifecycle section:** Add notes at each lifecycle state indicating which primitives fire:
   - **Draft:** `shamt.next_number()` for reservation; `precompact-snapshot` hook for context preservation
   - **Validated:** `validation_loop_composite` drives the 7D loop; `shamt.validation_round()` tracks rounds; `validation-log-stamp` auto-stamps; `shamt-validator` sub-agents for confirmation
   - **In Progress:** `architect_builder_composite` for large implementations; `validation-stall-detector` for stall alerts; `pre-push-tripwire` for push gating
   - **Implemented:** `shamt.audit_run()` for final guide audit; `shamt.metrics.append()` for retrospective metrics

3. **Implementation Validation section:** Reference the `validation_loop_composite` (5D variant) explicitly, noting it uses the same machinery as design doc validation but with different dimensions.

**Rationale:** `CLAUDE.md` is the agent's first point of reference. If it doesn't mention the primitives, they won't be used. The updates are concise — subsection additions, not rewrites.

**Alternatives considered:**
- *Don't update CLAUDE.md, rely on guide references:* Rejected — CLAUDE.md is loaded first; agents may not read the guide if CLAUDE.md doesn't hint at primitive availability.

---

### Proposal 4: Master-Specific Composite Guidance

**Description:** Add a "Master Dev Variant" section to each of the 4 master-applicable composites in `.shamt/guides/composites/`:

| Composite | Master Dev Variant Notes |
|-----------|--------------------------|
| `validation_loop_composite.md` | Master uses for design doc validation (7D) and implementation validation (5D). Exit: primary clean + 2 sub-agents (same as child). No `/loop` auto-pacing for master — validation is manual-invoke. |
| `architect_builder_composite.md` | Optional for master (decision criteria in `master_dev_workflow.md` Step 3.5). When used: architect creates plan in `design_docs/active/SHAMT{N}_IMPLEMENTATION_PLAN.md`; builder executes. No S6 enforcement hook — master triggers builder manually. |
| `stale_work_janitor_composite.md` | Add master-internal scan targets: `design_docs/active/` (design docs with no commits >4 weeks), `design_docs/incoming/` (proposals >30 days untriaged). These supplement the existing child-sync scans. |
| `rollback_recovery_composite.md` | Master uses stall detection + reasoning escalation for design doc validation stalls. Worktree rollback for builder errors during guide implementation. |

The `master_review_pipeline_composite.md` and `metrics_observability_composite.md` already cover master use cases (child PR review and metrics emission respectively) and don't need master-dev variants.

**Rationale:** Composites are documented for the S1-S11 workflow. Without master-specific guidance, an agent working in the master repo won't know how to adapt them. A dedicated section per composite is lightweight and precise.

**Alternatives considered:**
- *Create separate master-variant composite files:* Rejected — duplicates content; a section within each composite is sufficient.
- *Rely on agents to infer master applicability:* Rejected — the differences are non-obvious (no S6 enforcement, no `/loop` auto-pacing, optional vs. mandatory architect-builder).

---

### Proposal 5: Agent Persona Configuration for Master

**Description:** Ensure the master repo's agent configuration (`.claude/agents/` or equivalent) includes the master-applicable agent personas:

| Agent | Master Use |
|-------|------------|
| `shamt-validator` | Sub-agent confirmation during design doc validation and guide audits |
| `shamt-builder` | Builder execution for large design doc implementations (optional) |
| `shamt-architect` | Design doc creation and implementation planning |
| `shamt-guide-auditor` | Full guide audit (40+ dimensions) |
| `shamt-code-reviewer` | Child PR code review |
| `shamt-master-reviewer` | Child PR guide review (master-only) |

Agents NOT configured for master: `shamt-spec-aligner` (S2-only), `shamt-discovery-researcher` (S1-only).

The regen scripts (`.shamt/scripts/regen/regen-claude-shims.sh`) already handle agent persona generation. This proposal ensures the master repo's regen configuration includes these personas.

**Rationale:** Agent personas are the execution layer — they're what actually gets invoked when a skill or composite runs. Without them registered in the master config, the skills reference agents that don't exist.

**Alternatives considered:**
- *Use ad-hoc Task tool calls instead of named personas:* Rejected — named personas carry model tier, reasoning effort, and tool restrictions; ad-hoc calls lose these constraints.

---

### Proposal 6: Child PR Review Workflow Integration

**Description:** Update the child PR review workflow in `CLAUDE.md` (the "Reviewing Child Project PRs" section) to reference the `master_review_pipeline_composite`:

- **Step 1 (Read PR diff):** Use `shamt-code-reviewer` agent for code changes; `shamt-master-reviewer` skill for guide changes
- **Step 2 (Separation rule check):** Already manual; no change
- **Step 3 (Approve/request changes):** No change
- **Step 4 (Post-merge guide audit):** Use `shamt-guide-audit` skill → `shamt.audit_run(scope="all")`
- **Step 5 (Commit audit fixes):** `pre-push-tripwire` enforces clean state

Also reference the Codex variant: `@codex` mention trigger on incoming PRs drives the `master_review_pipeline_composite` as a cloud task.

**Rationale:** The child PR review process is described in CLAUDE.md prose but doesn't reference the composite that automates it. This bridges the gap.

**Alternatives considered:**
- *Fully automate child PR review (no human in loop):* Rejected — master maintainer should approve/reject; automation assists review, doesn't replace it.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/guides/master_dev_workflow/master_dev_workflow.md` | MODIFY | Add primitive references at each step (Proposal 2) |
| `CLAUDE.md` | MODIFY | Add "Primitives Available" subsection to Master Dev Workflow; add lifecycle state primitive notes to Design Doc Lifecycle; reference validation_loop_composite in Implementation Validation; update child PR review steps (Proposals 3, 6) |
| `.shamt/guides/composites/validation_loop_composite.md` | MODIFY | Add "Master Dev Variant" section (Proposal 4) |
| `.shamt/guides/composites/architect_builder_composite.md` | MODIFY | Add "Master Dev Variant" section (Proposal 4) |
| `.shamt/guides/composites/stale_work_janitor_composite.md` | MODIFY | Add master-internal scan targets to "Master Dev Variant" section (Proposal 4) |
| `.shamt/guides/composites/rollback_recovery_composite.md` | MODIFY | Add "Master Dev Variant" section (Proposal 4) |
| `.shamt/scripts/regen/regen-claude-shims.sh` | MODIFY | Ensure master repo regen config includes master-applicable agent personas (Proposal 5) |
| `.shamt/scripts/regen/regen-codex-shims.sh` | MODIFY | Ensure master repo regen config includes `shamt-master-reviewer` for Codex @codex trigger (Proposal 5) |

---

## Implementation Plan

### Phase 1: Master Dev Workflow Guide Update
- [ ] Read current `master_dev_workflow.md` in full
- [ ] Add primitive references at each step per Proposal 2 mapping table
- [ ] Preserve existing prose — add tool references as supplementary guidance, not replacements
- [ ] Verify all referenced skill/tool/hook names match SHAMT-39/41/44 exactly

### Phase 2: CLAUDE.md Updates
- [ ] Add "Primitives Available" subsection under "Master Dev Workflow" section (Proposal 3.1)
- [ ] Add primitive lifecycle notes under "Design Doc Lifecycle" section (Proposal 3.2)
- [ ] Reference `validation_loop_composite` in "Implementation Validation" section (Proposal 3.3)
- [ ] Update "Reviewing Child Project PRs" section with composite references (Proposal 6)

### Phase 3: Composite Master Dev Variants
- [ ] Add "Master Dev Variant" section to `validation_loop_composite.md`
- [ ] Add "Master Dev Variant" section to `architect_builder_composite.md`
- [ ] Add master-internal scan targets to `stale_work_janitor_composite.md`
- [ ] Add "Master Dev Variant" section to `rollback_recovery_composite.md`

### Phase 4: Agent Persona and Regen Configuration
- [ ] Verify `regen-claude-shims.sh` generates master-applicable personas
- [ ] Verify `regen-codex-shims.sh` includes `shamt-master-reviewer` for @codex trigger
- [ ] Add master repo persona subset configuration if not already present

### Phase 5: Validation
- [ ] Run design doc validation (7 dimensions) via `validation_loop_composite`
- [ ] Run guide audit on all modified guides via `shamt.audit_run(scope="all")`
- [ ] Verify no circular references (master_dev_workflow.md → composite → master_dev_workflow.md)

---

## Validation Strategy

- **Primary validation:** Design doc validation loop (7 dimensions) with `shamt.validation_round()` tracking and 2 sub-agent confirmation
- **Implementation validation:** After changes applied, run implementation validation (5 dimensions) verifying all Files Affected entries were correctly modified
- **Guide audit:** Full guide audit (3 consecutive clean rounds) on all `.shamt/guides/` including modified composites
- **Smoke test:** After implementation, manually walk through the master dev workflow guide and verify every primitive reference resolves to an existing artifact name in the SHAMT-39+ design chain
- **Success criteria:** An agent reading `master_dev_workflow.md` can identify exactly which skill/tool/hook/composite to invoke at every step of both the lightweight and design-doc workflows

---

## Open Questions

1. **Does master repo run on Claude Code, Codex, or both?**
   Recommendation: Claude Code primary (interactive dev), Codex secondary (automated child PR review via @codex). Document this posture explicitly.

2. **Should `architect-builder-enforcer` hook be active in master?**
   Recommendation: No — master's use of architect-builder is optional, not mandatory. The enforcer prevents non-builder agents from executing in S6, which doesn't exist in master workflow. If master adopts architect-builder, it's voluntary.

3. **Should master emit OTel metrics for its own design doc work?**
   Recommendation: Yes, if OTel infrastructure is available. Metrics provide retrospective data on validation round counts, token spend, and implementation duration. If no collector is running, the MCP tool gracefully no-ops.

4. **How deeply should composites document the master variant?**
   Recommendation: One section per composite (3-5 paragraphs) covering: what triggers it, how it differs from S1-S11 usage, and what to omit. Not a full rewrite.

---

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Circular references between guide and composites | Agent enters infinite reference loop | Verify no guide references a composite that references the same guide step |
| Primitive names change in SHAMT-39+ before implementation | Stale references in master_dev_workflow.md | All names verified against current design docs at implementation time; implementation plan Step 1 includes name verification |
| Master dev workflow becomes too tool-heavy for simple fixes | Lightweight workflow loses its simplicity | Keep Steps 1-5 (lightweight) simple — primitive references are optional hints, not mandatory invocations. Only the design-doc path requires full primitive usage |
| Agent persona configuration diverges between master and child | Master and child use different persona names/configs | Same regen scripts produce both; master just excludes non-applicable personas |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-28 | Initial draft created |
| 2026-04-28 | Retired — all proposals folded into existing design docs as implementation phases. SHAMT-39 Phase 5.5 (persona subset), SHAMT-40 Phase 7.5 (master regen), SHAMT-41 Phase 6.5 (hooks + MCP + master_dev_workflow.md), SHAMT-43 Phase 4.5 (SDK + CI deployment + child PR review), SHAMT-44 Phase 4.5 (composite master dev variants + Primitives Available in CLAUDE.md), SHAMT-45 Phase 9.5 (finalization + lifecycle annotations). NEXT_NUMBER.txt remains at 48 (47 is consumed). |
