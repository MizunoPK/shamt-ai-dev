# SHAMT-44: Cross-Cutting Composites — Validation Loop, Architect-Builder, Stale-Work, Metrics, Rollback

**Status:** Validated
**Created:** 2026-04-27
**Branch:** `feat/SHAMT-44`
**Validation Log:** [SHAMT44_VALIDATION_LOG.md](./SHAMT44_VALIDATION_LOG.md)
**Depends on:** SHAMT-39, SHAMT-40, SHAMT-41, SHAMT-42, SHAMT-43 (the primitives must all exist before they can be composed)
**Companion docs:** `CLAUDE_INTEGRATION_THEORIES.md` (§3), `CODEX_INTEGRATION_THEORIES.md` (§3), `FUTURE_ARCHITECTURE_OVERVIEW.md`

---

## Problem Statement

After SHAMT-39 through SHAMT-43, every primitive the framework needs exists: skills (39), Claude Code wiring (40), hooks + minimal MCP (41), Codex parity (42), Cloud + OTel + SDK (43). Each primitive is independently useful, but the source theorization docs (Claude doc §3, Codex doc §3) identify six cross-cutting workflows where multiple primitives compose for a single Shamt outcome:

1. **Validation loop as a first-class object** — skill + sub-agent + MCP-backed log + auto-stamp hook + `/loop` self-pacing
2. **Architect–builder pipeline** — plan mode + builder sub-agent + worktree/container isolation + MCP + `/loop` + push notification
3. **Stale-work janitor** — recurring routine / `@codex` GitHub Actions cron + sub-agents + scanning MCP
4. **Master review pipeline** — `@codex` mention + master-reviewer skill + audit skill (Codex side mostly built in SHAMT-43; Claude Code side adds the `/loop`-based analog)
5. **Metrics & observability loop** — hooks + MCP `metrics.append` + OTel collector + dashboards + on-demand query
6. **Rollback / recovery loop** — worktree-as-rollback (Claude Code) / container-disposability (Codex) + stall detection + pre-push tripwire + reasoning-effort escalation

The primitives are deployed; the composites need explicit assembly. Without this design doc, users can build each composite ad-hoc but the patterns won't be documented, the Shamt-specific MCP `metrics.append` won't exist, the stall-detection hook won't exist, and the `/loop` integration into the validation loop won't be wired. SHAMT-44 ships the composites as documented, supported workflows.

---

## Goals

1. Wire `/loop` (Claude Code) into the validation-loop skill so rounds self-pace; document the equivalent pattern on Codex (manual round invocation per session, or `codex exec` with a driver script).
2. Extend the `shamt-mcp` server with the remaining tools that the cross-cutting workflows need: `audit_run`, `epic_status`, `metrics.append`, `export`, `import`. Defer `shamt-meta-orchestrator` to SHAMT-45 (still speculative).
3. Author the additional hooks the rollback / recovery loop needs: stall detection (validation log not advancing for ≥N rounds), pre-push tripwire that verifies builder log clean exit and validation log final state.
4. Document the cross-cutting workflows in their composed form in the framework guides, with explicit references to which primitives each uses and how they compose.
5. Light up the metrics/observability loop end-to-end: hooks emit `shamt.metrics.append()` calls, the OTel collector ingests Shamt-specific events alongside stock OTel, Grafana dashboards from SHAMT-43 visualize the combined picture.
6. Validate all six composites end-to-end on a real epic — at minimum, run a complete S1–S10 epic where the validation loop, architect-builder pipeline, metrics emission, and rollback boundaries are all observably working.

---

## Detailed Design

### Proposal 1: Validation loop with `/loop` self-pacing

**Description:** Update the `shamt-validation-loop` skill (from SHAMT-39) so that on Claude Code, the round mechanics run inside `/loop`:

- Skill invocation triggers `/loop` with the validation-log artifact path as the loop target.
- Each iteration: agent reads the artifact, performs primary review, calls `shamt.validation_round()`, optionally spawns sub-agent confirmers.
- Exit condition: `consecutive_clean ≥ 1` AND both confirmer sub-agents report zero issues (per `validation_loop_master_protocol.md`).
- Between iterations: `/loop` sleeps a configurable interval (default 30s for fast cycles, longer for human-paced reviews).

On Codex (no native `/loop`), document the equivalent pattern: a small `codex exec` driver script that re-invokes the validation skill until the file-observable exit condition is met.

**Rationale:** Externalizes loop state from agent context to the file system. Each iteration starts with a fresh-ish context (after the harness's automatic context management); the agent doesn't accumulate round-count history in conversation. Direct realization of Claude doc §3.1 / §5 row 5.

### Proposal 2: Extend `shamt-mcp` with remaining tools

**Description:** Add to the SHAMT-41 minimal server:

- `shamt.audit_run(scope: str) -> AuditResult` — runs guide audit at the named scope; returns issues by severity. Writes `.shamt/audit/last_run.json` for the pre-export-audit-gate hook.
- `shamt.epic_status(epic_id: str | "active") -> EpicStatus` — structured snapshot of stage / phase / step / blockers / open validation rounds.
- `shamt.metrics.append(epic_id: str, metric_name: str, value: float, labels: dict) -> {accepted: bool}` — emit a Shamt-domain metric event. Server writes to OTel via OTLP and to a local sidecar log for queryability without Grafana.
- `shamt.export(epic_id: str, dry_run: bool) -> ExportResult` — drive the export pipeline (verify CHANGES.md, scan for epic-tag contamination, run audit, push, open PR).
- `shamt.import(dry_run: bool) -> ImportResult` — drive the import pipeline; surface diffs for review.

These give the agent typed verbs for the operations that today exist as bash scripts. `metrics.append` is the load-bearing one for the metrics & observability loop.

**Rationale:** Carving out the remaining tools after the SHAMT-41 minimal proved the MCP-server pattern works. Each tool is justified by a cross-cutting workflow that needs it.

### Proposal 3: Stall-detection and pre-push-tripwire hooks

**Description:** Add to `.shamt/hooks/`:

- `validation-stall-detector.sh` — fires on PostToolUse of validation log. Parses recent history; if `consecutive_clean = 0` for ≥3 rounds, emits a PushNotification ("validation loop stalled at round N — likely needs human judgment or model escalation") and writes a hint to `.shamt/epics/<active>/STALL_ALERT.md`.
- `pre-push-tripwire.sh` — fires on PreToolUse of `git push`. Verifies (a) `.shamt/audit/last_run.json` is fresh and clean, (b) the active epic's validation log shows `consecutive_clean ≥ 1`, (c) builder handoff log (if S6 just completed) shows no unresolved errors. Refuses push otherwise.

Stall detection pairs with the reasoning-effort escalation rule (already proposed in SHAMT-45 — cross-reference; here the hook fires the alert and documents the recommended response). Pre-push tripwire is the final guard before changes leave the worktree/container.

**Rationale:** These two hooks complete the rollback / recovery loop by adding the stall detection (Claude doc §3.6 / Codex doc §3.6) and the pre-push final guard. Without them, the rollback loop is half-built.

### Proposal 4: Document the composites in the guides

**Description:** Author six new guide files under `.shamt/guides/composites/`:

- `validation_loop_composite.md` — describes the validation loop as a composed workflow: skill + sub-agent + MCP + auto-stamp hook + `/loop`. Cross-references each primitive's home guide.
- `architect_builder_composite.md` — CLI flow + cloud variant (SHAMT-43) + worktree/container rollback + push on builder error. S6 architect uses `Agent run_in_background` to spawn the builder asynchronously; while the builder runs, the architect can concurrently update EPIC_METRICS.md or prepare the S7 smoke plan, and is notified on builder completion or error. For S2 multi-feature parallel work, each feature's sub-agent runs in the background with a distinct worktree (Claude Code) or container (Codex), coordinated by the primary agent; note that the `parallel_work/` guides predate `run_in_background` and should be revised during Phase 4 to reflect this primitive. Plan mode applies in S5 (the architect cannot write code while planning) and also in S10.P1 (overview document narrative is read-heavy; no implementation writes until the narrative is complete); both are called out in this composite guide.
- `stale_work_janitor_composite.md` — two categories of scheduled work, both documented here:
  - **Recurring weekly scans:** `incoming/` triage (proposals >30 days old), `active/` design doc sweep (no commit in N weeks), child sync timestamp check (no import in N weeks). Claude Code: cron job + Stop hook; Codex: `shamt-cron-janitor.py` via GitHub Actions schedule (SHAMT-43).
  - **One-shot post-event triggers:** (a) post-S10 merge → +1 week: schedule an agent to recheck that lessons-learned from S11 were actually propagated and metrics were populated — more honest than doing it inline at S11.P3 when context is exhausted; (b) post-export PR open → +3 days: check if master merged the PR; if yes, kick off import on the originating child, closing the upstream/downstream loop without the user needing to remember. Both one-shots are set up by the skill at the relevant event point and scheduled via Claude Code cron or `shamt-cron-janitor.py`.
- `master_review_pipeline_composite.md` — Codex side from SHAMT-43; Claude Code side via `/loop` driving `shamt-master-reviewer` skill.
- `metrics_observability_composite.md` — hooks emit `metrics.append()`, OTel collector ingests, Grafana dashboards visualize. Includes the bootstrapping caveat from the overview doc §3.5.
- `rollback_recovery_composite.md` — worktree disposability (Claude Code) / container disposability (Codex) + stall detection + pre-push tripwire + escalation.

Each composite guide names the primitives it uses (with file path references) and includes a short "when to invoke" decision tree.

**Rationale:** Without explicit composite documentation, users have to re-derive the pattern each time. Composites are the load-bearing user-facing workflows; guides should reflect that.

### Proposal 5: Wire metrics emission

**Description:** Update existing hooks (from SHAMT-41 / SHAMT-42) and skill bodies to call `shamt.metrics.append()` at meaningful events:

- Validation loop: `metrics.append("validation_round", duration_ms, {stage, persona, severity_summary})` at each round end
- Builder: `metrics.append("builder_step", duration_ms, {step_index, file_op_count})` per step
- Audit: `metrics.append("audit_round", duration_ms, {dimensions_checked, issues_found_by_severity})`
- Sub-agent confirmation: `metrics.append("confirmer_run", duration_ms, {persona, model, tokens_used})`

OTel collector pipeline (from SHAMT-43) routes these to Tempo/Prometheus tagged with their labels. Grafana `shamt-savings-tracker.json` dashboard surfaces measured-vs-projected savings.

**Rationale:** Closes the empirical-validation loop. The framework's projected token-savings claims (model_selection: 30–50%, architect-builder: 60–70%, sub-agent confirmation: 70–80%) become measurable. Connects directly to the `bootstrapping caveat` in the overview doc §3.5.

### Recommended approach

All five proposals together. SHAMT-44 is the assembly step — without it, the primitives shipped in SHAMT-39 through SHAMT-43 don't compose into the workflows the source docs theorize.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/skills/shamt-validation-loop/SKILL.md` | MODIFY | Add `/loop` integration on Claude Code; document Codex equivalent |
| `.shamt/mcp/src/shamt_mcp/audit_run.py` | CREATE | New MCP tool |
| `.shamt/mcp/src/shamt_mcp/epic_status.py` | CREATE | New MCP tool |
| `.shamt/mcp/src/shamt_mcp/metrics_append.py` | CREATE | New MCP tool, emits to OTel + local log |
| `.shamt/mcp/src/shamt_mcp/export_pipeline.py` | CREATE | New MCP tool |
| `.shamt/mcp/src/shamt_mcp/import_pipeline.py` | CREATE | New MCP tool |
| `.shamt/mcp/src/shamt_mcp/server.py` | MODIFY | Register new tools |
| `.shamt/hooks/validation-stall-detector.sh` (+ .ps1) | CREATE | Stall detection hook |
| `.shamt/hooks/pre-push-tripwire.sh` (+ .ps1) | CREATE | Final-guard hook |
| `.shamt/hooks/README.md` | MODIFY | Document new hooks |
| `.shamt/guides/composites/validation_loop_composite.md` | CREATE | Composite workflow guide |
| `.shamt/guides/composites/architect_builder_composite.md` | CREATE | Composite workflow guide |
| `.shamt/guides/composites/stale_work_janitor_composite.md` | CREATE | Composite workflow guide |
| `.shamt/guides/composites/master_review_pipeline_composite.md` | CREATE | Composite workflow guide |
| `.shamt/guides/composites/metrics_observability_composite.md` | CREATE | Composite workflow guide |
| `.shamt/guides/composites/rollback_recovery_composite.md` | CREATE | Composite workflow guide; includes "Master Dev Variant" section |
| `.shamt/guides/composites/README.md` | CREATE | Index + decision tree for picking a composite |
| `.shamt/guides/master_dev_workflow/master_dev_workflow.md` | MODIFY | Add composite references at Steps 3.5, 4, design-doc validation, implementation validation, and session management; add "Primitives Available" overview |
| `.shamt/skills/shamt-architect-builder/SKILL.md` | MODIFY | Reference composite guide; reference cloud variant from SHAMT-43 |
| `.shamt/skills/shamt-guide-audit/SKILL.md` | MODIFY | Call `shamt.audit_run()` MCP verb; extend audit scope to cover `guides/composites/` — the seven new composite guides must be included in the full guide audit walk. Without this, the composites directory would be silently unaudited. |
| `.shamt/scripts/regen/regen-claude-shims.sh` | MODIFY | Register new hooks; verify metrics emission compatible |
| `.shamt/scripts/regen/regen-codex-shims.sh` | MODIFY | Mirror |
| `.shamt/observability/grafana/shamt-savings-tracker.json` | MODIFY | Update queries to consume metrics emitted by hooks/skills |
| `.shamt/observability/README.md` | MODIFY | Document the bootstrapping caveat (§3.5 in overview) |
| `.shamt/guides/parallel_work/*.md` | MODIFY | Phase 4: revise to reflect `run_in_background` primitive; specific files enumerated at Phase 4 start after reviewing current parallel_work/ content |
| `.shamt/commands/CHEATSHEET.md` | MODIFY | Add "Composites" section listing all six cross-cutting workflows (validation loop, architect-builder, stale-work janitor, master review pipeline, metrics/observability, rollback/recovery) with a one-line "when to use" and a pointer to the relevant composite guide. |
| `CLAUDE.md` | MODIFY | New section "Cross-Cutting Composites (SHAMT-44)" — references each composite guide; add "Primitives Available" subsection to Master Dev Workflow section |

---

## Implementation Plan

### Phase 1: MCP server tool additions
- [ ] Implement `audit_run`, `epic_status`, `metrics.append`, `export`, `import` in shamt-mcp.
- [ ] `metrics.append` emits to OTel via OTLP exporter (configurable endpoint) and to a local sidecar log.
- [ ] Register tools in the server entry point.
- [ ] Unit tests per tool.
- [ ] Update `.shamt/mcp/README.md` with the expanded surface.

### Phase 2: New hooks
- [ ] Author `validation-stall-detector.sh` (and .ps1).
- [ ] Author `pre-push-tripwire.sh` (and .ps1).
- [ ] Update `.shamt/hooks/README.md`.
- [ ] Test each: deny-path scenarios, pass-through scenarios.

### Phase 3: `/loop` integration in validation-loop skill
- [ ] Update `shamt-validation-loop` SKILL.md body to invoke `/loop` on Claude Code.
- [ ] Document the Codex equivalent (driver script with `codex exec`).
- [ ] Verify regen still produces a valid `.claude/skills/shamt-validation-loop/SKILL.md`.

### Phase 4: Composite guides authoring
- [ ] Author each of the six composite guides.
- [ ] Each guide:
  - Names the primitives composed
  - Shows the data flow / interaction sequence
  - Cross-references home guides for deeper detail
  - Includes "when to use" criteria
- [ ] Author the index README.
- [ ] Update `CHEATSHEET.md` with a "Composites" section listing each composite, a one-line "when to use" description, and a file path pointer to the composite guide. This makes the composites discoverable from the cheat sheet without reading the composite guides first.

### Phase 4.5: Master dev variants in composites
- [ ] Add "Master Dev Variant" section to `validation_loop_composite.md`:
  - Master uses for design doc validation (7D) and implementation validation (5D)
  - Exit: primary clean + 2 sub-agents (same as child)
  - No `/loop` auto-pacing for master — validation is manual-invoke
- [ ] Add "Master Dev Variant" section to `architect_builder_composite.md`:
  - Optional for master (decision criteria in `master_dev_workflow.md` Step 3.5)
  - Architect creates plan in `design_docs/active/SHAMT{N}_IMPLEMENTATION_PLAN.md`
  - No S6 enforcement hook — master triggers builder manually
- [ ] Add master-internal scan targets to `stale_work_janitor_composite.md`:
  - `design_docs/active/` — design docs with no commits >4 weeks
  - `design_docs/incoming/` — proposals >30 days untriaged
  - Supplement existing child-sync scans
- [ ] Add "Master Dev Variant" section to `rollback_recovery_composite.md`:
  - Stall detection + reasoning escalation for design doc validation stalls
  - Worktree rollback for builder errors during guide implementation
- [ ] Note: `master_review_pipeline_composite` and `metrics_observability_composite` already cover master use cases (child PR review and metrics emission respectively) and do not need separate master-dev variant sections. Document this decision in each composite's guide.
- [ ] Update `master_dev_workflow.md` to reference composites at each applicable step:
  - Step 3.5: reference `architect_builder_composite`
  - Step 4: reference `validation_loop_composite` for guide audit round tracking
  - Larger Changes section, sub-step "Validate design doc" (sub-step 4): reference `validation_loop_composite` (7D variant)
  - Larger Changes section, sub-step "Validate implementation" (sub-step 6): reference `validation_loop_composite` (5D variant)
  - Larger Changes section, "Guide audit" (sub-step 7): reference `shamt.audit_run()` + `validation_loop_composite`
- [ ] Add "Primitives Available" subsection to CLAUDE.md's "Master Dev Workflow" section listing all active hooks, MCP tools, composites, skills, and agent personas for master dev work.

### Phase 5: Metrics emission wiring
- [ ] Update existing hooks (validation-log-stamp, etc.) to call `metrics.append()`.
- [ ] Update existing skill bodies (validation-loop, architect-builder, guide-audit) to emit metrics at meaningful events.
- [ ] Update Grafana dashboard `shamt-savings-tracker.json` to consume the new metric names.

### Phase 6: Regen + CLAUDE.md updates
- [ ] Regen scripts pick up the new hooks automatically (no changes needed if the regen logic walks `.shamt/hooks/`).
- [ ] Verify regen produces hook registrations for the new hooks in both Claude Code and Codex.
- [ ] Add CLAUDE.md section "Cross-Cutting Composites (SHAMT-44)".

### Phase 7: End-to-end validation — Real epic
- [ ] On a test child project with all SHAMT-39..-43 deployed, run a full S1–S10 epic.
- [ ] Verify each composite is observably working:
  - Validation loop: `/loop` self-paces; rounds tracked in MCP; metrics emitted.
  - Architect-builder: planned in S5, executed in S6, rollback boundary observable.
  - Stale-work janitor: scheduled run produces digest.
  - Master review pipeline: child's PR to its master triggers `@codex` review.
  - Metrics dashboard: Grafana shows stage / persona / tool breakdowns for the epic.
  - Rollback / recovery: simulated failure (kill builder mid-run) cleanly recovers.
- [ ] Pass criterion: all six composites observably operational on the test epic.

### Phase 8: Implementation validation
- [ ] Implementation validation loop (5 dimensions).
- [ ] Full guide audit (3 clean rounds).

---

## Validation Strategy

- **Primary:** Design doc validation loop on this doc.
- **Implementation:** All files in "Files Affected" match spec.
- **Empirical:** Real S1–S10 epic with all six composites observably operational.
- **MCP tool tests:** Each new tool has unit tests covering happy path + at least one failure mode.
- **Composite guide quality:** Each guide includes a decision tree; reviewer can answer "when do I use this?" without reading the source.
- **Metrics dashboard:** After running the test epic, Grafana surfaces meaningful breakdowns; savings-tracker dashboard shows measured ratios for the major proposals.
- **Success criteria:**
  1. `/loop` integration in validation skill works on Claude Code; Codex equivalent documented.
  2. All five new MCP tools functional.
  3. Stall-detection and pre-push-tripwire hooks fire correctly.
  4. Six composite guides authored and indexed.
  5. End-to-end epic produces visible metrics in Grafana.

---

## Open Questions

1. **`/loop` interval defaults:** What's a reasonable default sleep between iterations? **Recommendation:** 30s for validation loops (fast feedback); 5min for builder monitoring (slower-changing); user-configurable.
2. **`metrics.append` cardinality controls:** Unbounded label cardinality is a known OTel pitfall. **Recommendation:** Document permitted label sets per metric name in `.shamt/observability/README.md`; the MCP tool validates labels against a schema and rejects unknown labels with a warning.
3. **Composite guides vs. existing reference guides:** Risk of duplication. **Recommendation:** Composite guides cite home guides for protocol detail; composites describe the *composition*, not the primitive content.
4. **Codex equivalent of `/loop` for validation:** `codex exec` driver scripts are awkward compared to Claude Code's `/loop`. **Recommendation:** Document the gap honestly; investigate whether a Codex-side `/loop`-equivalent skill or built-in lands in a future Codex release.
5. **Stall-detection threshold:** ≥3 rounds without progress. Is 3 the right number? **Recommendation:** Configurable via env var; default 3 from SHAMT-44 onward; adjust based on Phase 7 validation observations.

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| `/loop` interaction with sub-agent spawning gets confused | Test in Phase 3; document any quirks (e.g., does `/loop` restart sub-agents on each iteration or persist them?) |
| MCP `metrics.append` cardinality explodes Prometheus storage | Schema-validate labels; alert on cardinality growth; document permitted labels |
| Stall detector fires on legitimately-hard validations | Threshold is configurable; alert is informational, not blocking; user can extend `consecutive_clean=0` window |
| Pre-push tripwire blocks legitimate hot-fix pushes | Provide a documented bypass (`SHAMT_BYPASS_TRIPWIRE=1` env var) for emergencies; require a manual confirmation prompt |
| Composite guides bloat the guide tree | Composites live in their own subdir (`composites/`); index makes them discoverable; not concatenated into RULES_FILE |
| End-to-end epic validation fails mid-stage | Diagnose per-composite; SHAMT-44 doesn't ship until all six are observably working |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-27 | Initial draft created |
| 2026-04-27 | Validated — removed duplicate Files Affected entry for shamt-validation-loop/SKILL.md |
| 2026-04-27 | Specified run_in_background usage and plan-mode sites (S5 + S10.P1) in architect-builder composite spec; enumerated recurring-scan and one-shot post-event routines in stale-work janitor composite spec |
| 2026-04-27 | Added CHEATSHEET.md MODIFY entry to Files Affected; Phase 4 step to add "Composites" section with all six cross-cutting workflows |
| 2026-04-27 | Extended shamt-guide-audit SKILL.md MODIFY note: must extend audit scope to cover `guides/composites/` so the seven new composite guides are included in full guide audit walks. |
| 2026-04-28 | SHAMT-47 fold-in: Added Phase 4.5 (master dev variants in composites); added `master_dev_workflow.md` to Files Affected; updated CLAUDE.md note to include Primitives Available subsection; each composite gets a "Master Dev Variant" section |
| 2026-04-28 | Validation fix: Step references in Phase 4.5 now use explicit "Larger Changes section, sub-step N" instead of ambiguous names; added explicit note on why master_review_pipeline and metrics_observability composites don't need master-dev variants |
