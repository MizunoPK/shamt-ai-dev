# SHAMT-43: Codex Cloud, OpenTelemetry Observability, and Agents SDK CI

**Status:** Validated
**Created:** 2026-04-27
**Branch:** `feat/SHAMT-43`
**Validation Log:** [SHAMT43_VALIDATION_LOG.md](./SHAMT43_VALIDATION_LOG.md)
**Depends on:** SHAMT-42 (Codex CLI parity must exist before Cloud and SDK can ride on top)
**Companion docs:** `CODEX_INTEGRATION_THEORIES.md`, `FUTURE_ARCHITECTURE_OVERVIEW.md`

---

## Problem Statement

After SHAMT-42, Codex CLI is operational with skills, profiles, hooks, MCP, and admin enforcement. Three Codex-native capabilities remain unintegrated:

1. **Codex Cloud / containers** — disposable isolated execution environments, parallel task fan-out, GitHub `@codex` mention triggering. The Codex doc §2.8 / §3.2 / §3.4 identify this as the architecture's biggest leverage point: S6 builder execution becomes a cloud task with container-disposability rollback semantics; S7 / S9 QC fan-out runs 6+ parallel cloud tasks; the master review pipeline ships as `@codex` on child PRs.
2. **OpenTelemetry observability** — Codex emits OTel out of the box. The Claude doc §3.5 cross-cutting workflow (metrics & observability loop) becomes ~70% pre-built on Codex if the framework wires up an OTel collector with Shamt-aware dashboards. Without this, the framework's projected token savings (30–80% across multiple proposals) remain unmeasured.
3. **Agents SDK** — the Python/TypeScript library that lets external programs drive Codex sessions. Concrete value: a `shamt-validate-pr.py` CI script that runs on GitHub Actions, drives Codex through `shamt-validation-loop`, posts results as a PR comment. Turns Shamt validation from interactive discipline into automatic PR gate.

This design doc lights up all three. It validates Codex doc Experiment B: a real S6 cloud-task implementation completes with `requirements.toml` enforcement, container disposability rollback works on simulated failure, OTel dashboards render stage / sub-agent / tool breakdowns.

---

## Goals

1. Author `.shamt/host/codex/cloud-environment.template.json` (or whatever Codex Cloud's environment manifest format is at implementation time) with setup scripts to install the Shamt MCP server, pre-cache the guide tree, seed AGENTS.md.
2. Author `.shamt/observability/` containing an OTel collector preset, Shamt-aware Grafana dashboard JSON, and documentation for wiring into a child project (and into a shared org-level collector if available).
3. Author `.shamt/sdk/shamt-validate-pr.py` (PR-validation gate) and `.shamt/sdk/shamt-cron-janitor.py` (scheduled stale-work scanner) as standalone scripts using the OpenAI Agents SDK. Each ships with a GitHub Actions workflow template children can copy.
4. Author the `shamt-master-reviewer` workflow on the master repo: `@codex` on incoming child PRs fires the `shamt-master-reviewer` skill (from SHAMT-39), applies the separation rule, posts a draft review comment.
5. Update `validation_loop_master_protocol.md` and S6/S7/S9 stage guides to describe the cloud-native variants (validation loop fan-out, cloud builder, container-disposability rollback) and when to use them.
6. Validate Codex doc Experiment B: real S6 cloud task completes; `requirements.toml`-enforced sandbox blocks an attempted `danger-full-access` escalation; container disposability cleanly recovers from simulated failure; OTel dashboards show meaningful breakdowns.

---

## Detailed Design

### Proposal 1: Cloud environment manifest with Shamt-aware setup

**Description:** Codex Cloud spawns containers from `codex-universal` plus a per-project setup script. Author `.shamt/host/codex/cloud-environment.template.json` (filename TBD per current Codex Cloud documentation at implementation time) declaring:

```jsonc
{
  "image": "codex-universal:latest",
  "setup_script": ".shamt/host/codex/cloud-setup.sh",
  "maintenance_script": ".shamt/host/codex/cloud-maintenance.sh",
  "environment_variables": {
    "SHAMT_MCP_PATH": ".shamt/mcp"
  },
  "secrets": ["GITHUB_TOKEN"],   // setup-only; removed before agent phase
  "network_policy": "limited",
  "branch": "${EPIC_BRANCH}"
}
```

The setup script installs the Shamt MCP server (HTTP-served, since cloud STDIO MCP is constrained), pre-caches the guide tree, seeds AGENTS.md if missing, and verifies `requirements.toml` is in place. The maintenance script refreshes deps on cached-container resume.

**Rationale:** Cloud is shaped around per-project setup; treating it as code shipped via the master repo (not user-configured per project) is consistent with Shamt's master-controls-substrate principle.

**Alternatives considered:**
- *No cloud environment, use Cloud's defaults:* Loses Shamt-specific setup, makes MCP-on-Cloud unreliable. Rejected.
- *Custom container image:* Higher complexity, harder to maintain. The setup-script-on-codex-universal pattern is the documented approach. Rejected.

### Proposal 2: OpenTelemetry collector preset and dashboards

**Description:** `.shamt/observability/otel-collector.yaml` is a ready-to-run OTel collector configuration with:
- OTLP receivers
- Routing pipelines tagged by Shamt domain (stage, sub-agent persona, hook name)
- Default exporter to local Prometheus + Tempo (for self-hosted) plus a templated cloud exporter for shared deployments

`.shamt/observability/grafana/` contains JSON dashboard files:
- `shamt-overview.json` — request duration, token usage, tool call counts by stage / persona
- `shamt-validation-loop.json` — round counts, severity distributions, time-to-exit per validation loop
- `shamt-architect-builder.json` — S6 builder execution duration, error rates, model spend
- `shamt-savings-tracker.json` — measured vs. projected savings claims (cache hit rate, sub-agent vs. parent token ratio, etc.)

`.shamt/observability/README.md` documents:
- How to wire OTel into a Codex project's `.codex/config.toml` `[otel]` block
- How to run a local collector via Docker
- How to import the Grafana dashboards
- For Claude Code projects: a brief note that OTel is not native; wiring requires the metrics-emitting MCP tool from SHAMT-44

**Rationale:** OTel is essentially free observability on Codex. Shipping the collector config and dashboards as templates lets a child project go from "no observability" to "Grafana dashboard with Shamt-domain breakdowns" in a single setup step.

### Proposal 3: Agents SDK CI script

**Description:** `.shamt/sdk/shamt-validate-pr.py` is a standalone Python script using the OpenAI Agents SDK. Behavior:

1. Read GitHub Actions environment variables (PR number, base ref, head ref).
2. Identify changed artifacts in the PR diff (specs, validation logs, design docs).
3. For each, drive a Codex session through the `shamt-validation-loop` skill.
4. Aggregate results and post a structured comment to the PR.
5. Exit non-zero if any artifact failed validation.

The script is self-contained — minimal dependencies (Agents SDK, GitHub API client, requests). Ships with `.shamt/sdk/.github/workflows/shamt-validate.yml.template` that children copy to `.github/workflows/shamt-validate.yml` to enable the CI gate.

Also ships `.shamt/sdk/shamt-cron-janitor.py` — a companion script for scheduled stale-work scanning (counterpart to the stale-work janitor composite in SHAMT-44). The cron-janitor drives a Codex session to:
1. Scan `design_docs/incoming/` for proposals older than 30 days.
2. Scan `design_docs/active/` for stalled design docs (no commit activity in N weeks).
3. Check child sync timestamps for projects that haven't imported master updates in N weeks.
4. Produce a digest file and optionally post it as a GitHub issue.

Ships with `.shamt/sdk/.github/workflows/shamt-cron-janitor.yml.template` for weekly GitHub Actions scheduling. Children copy this to `.github/workflows/` to enable the recurring sweep.

**Rationale:** Both SDK scripts have the same dependency footprint and the same "drive Codex sessions from CI" shape; authoring them together avoids a separate SHAMT-N for what is essentially the second file in the SDK bundle. `shamt-cron-janitor.py` is the Codex-native realization of the recurring janitor work the Claude doc §2.4 / §3.3 identifies as a routine.

### Proposal 4: Master review pipeline via `@codex`

**Description:** On the master repo, configure `@codex` mentions on incoming child PRs to fire the `shamt-master-reviewer` skill (authored in SHAMT-39 as `master-only`). The workflow:

1. Child opens PR to master.
2. Maintainer (or automation) tags `@codex` with prompt "review for separation-rule compliance and run guide audit on touched files."
3. Codex Cloud spawns task; reads PR diff; loads `shamt-master-reviewer` skill; loads `shamt-guide-audit` skill for any touched guide files; produces draft review comment.
4. Maintainer reviews the draft; iterates with further `@codex` mentions or merges.

This requires (a) the `shamt-master-reviewer` skill from SHAMT-39, (b) Codex Cloud being available on the master repo, (c) the workflow template deployed to the master repo's `.github/workflows/` (not to child projects), (d) `@codex` configuration enabling the mention-trigger, (e) `requirements.toml` allowing the cloud task to write PR comments.

**Rationale:** This is the master review pipeline (Claude doc §2.17 / §3.4) shipping as a primitive instead of a speculative deployment. On Codex this is configuration, not implementation.

### Proposal 5: Stage guide updates for cloud-native variants

**Description:** S6, S7, and S9 are the stages where cloud execution adds the most leverage: S6 is long-running builder execution (ideal for disposable containers), S7 is parallel QC fan-out across validation dimensions, and S9 is the final epic QC gate (same fan-out shape as S7). S8 (post-merge bug discovery) is reactive and ad-hoc; S10 (final changes and merge) requires human-in-the-loop merge decisions; S11 (finalization) is administrative cleanup — none benefit from cloud-task execution, so no cloud variants are authored for them.

S6 stage guides currently describe the architect-builder pattern as a CLI-only flow (architect spawns Haiku builder via Task tool; monitors). Add a "Cloud-native variant" section describing:
- Architect runs locally (CLI or IDE)
- Validated plan is committed to the repo
- S6 fires a Codex Cloud task with `shamt-s6-builder` profile
- Cloud task executes the plan in a clean container; opens a PR on success or discards container on failure
- Architect reviews the PR (which is naturally S7's review checkpoint)

Similar additions in S7 / S9 for QC fan-out (parallel cloud tasks per validation dimension) and `validation_loop_master_protocol.md` (cloud-task-as-confirmer-instance variant).

**Rationale:** The cloud variants are operationally distinct; documenting them in the stage guides ensures users on Codex know the option exists and when to use it.

### Recommended approach

All five proposals together. SHAMT-43 is essentially "everything Codex offers that Claude Code doesn't" in one design doc. Splitting further would create artificial dependencies among proposals that share validation infrastructure.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/host/codex/cloud-environment.template.json` | CREATE | Cloud manifest template (verify exact filename per current Codex docs) |
| `.shamt/host/codex/cloud-setup.sh` | CREATE | Container setup: install MCP, cache guides, seed AGENTS.md |
| `.shamt/host/codex/cloud-maintenance.sh` | CREATE | Maintenance script for cached-container resume |
| `.shamt/host/codex/cloud-README.md` | CREATE | Cloud setup + secrets handling + network policy guidance |
| `.shamt/observability/otel-collector.yaml` | CREATE | OTel collector config with Shamt domain tags |
| `.shamt/observability/grafana/shamt-overview.json` | CREATE | Top-level Grafana dashboard |
| `.shamt/observability/grafana/shamt-validation-loop.json` | CREATE | Validation-loop-specific dashboard |
| `.shamt/observability/grafana/shamt-architect-builder.json` | CREATE | S6 builder dashboard |
| `.shamt/observability/grafana/shamt-savings-tracker.json` | CREATE | Measured vs. projected savings |
| `.shamt/observability/README.md` | CREATE | Wiring guide for Codex / Claude Code |
| `.shamt/sdk/shamt-validate-pr.py` | CREATE | Agents SDK CI script — PR validation gate |
| `.shamt/sdk/shamt-cron-janitor.py` | CREATE | Agents SDK scheduled script — stale-work scanner |
| `.shamt/sdk/pyproject.toml` | CREATE | SDK script dependencies (shared by both scripts) |
| `.shamt/sdk/README.md` | CREATE | Install + invoke + extend |
| `.shamt/sdk/.github/workflows/shamt-validate.yml.template` | CREATE | GitHub Actions PR-trigger workflow template |
| `.shamt/sdk/.github/workflows/shamt-cron-janitor.yml.template` | CREATE | GitHub Actions weekly-cron workflow template |
| `.shamt/host/codex/master-reviewer-workflow.yml.template` | CREATE | `@codex`-driven master PR review workflow; master-only — copy to `.github/workflows/` on the master repo only; child regen scripts skip this file |
| `.shamt/guides/stages/s6/cloud_variant.md` | CREATE | Documents cloud-native architect-builder |
| `.shamt/guides/stages/s7/cloud_variant.md` | CREATE | Documents cloud QC fan-out |
| `.shamt/guides/stages/s9/cloud_variant.md` | CREATE | Documents cloud epic QC fan-out |
| `.shamt/guides/reference/validation_loop_master_protocol.md` | MODIFY | Add cloud-task-as-confirmer-instance variant |
| `.shamt/guides/reference/architect_builder_pattern.md` | MODIFY | Reference cloud variant |
| `.shamt/scripts/initialization/init.sh` | MODIFY | Optional `--with-cloud` flag for Codex hosts; copies cloud-environment template |
| `.shamt/scripts/initialization/init.ps1` | MODIFY | Mirror |
| `.shamt/commands/CHEATSHEET.md` | MODIFY | Add "CI Automation" section describing `shamt-validate-pr.py` (automatic PR validation gate), `shamt-cron-janitor.py` (scheduled stale-work scanner), and the `@codex` master review pipeline — including how to enable each via their GitHub Actions workflow templates. |
| `CLAUDE.md` | MODIFY | New section "Codex Cloud, OTel, and SDK (SHAMT-43)" |

---

## Implementation Plan

### Phase 1: Cloud environment + setup scripts
- [ ] Verify current Codex Cloud manifest format (filename, schema) per developers.openai.com/codex/cloud at implementation time.
- [ ] Author `cloud-environment.template.json`, `cloud-setup.sh`, `cloud-maintenance.sh`.
- [ ] Setup script: install shamt-mcp via HTTP-served pattern; cache guide tree; seed AGENTS.md if missing.
- [ ] Document secrets handling: `GITHUB_TOKEN` is setup-only; service account tokens for MCP auth resolved at setup; `shell_environment_policy` allows specific vars into agent phase.

### Phase 2: OTel collector and Grafana dashboards
- [ ] Author `otel-collector.yaml` with OTLP receivers and Shamt-domain pipelines.
- [ ] Author 4 Grafana dashboard JSON files (overview, validation loop, architect-builder, savings tracker).
- [ ] Document local-dev setup (Docker compose) and shared-deployment patterns.
- [ ] Wire `[otel]` block into Codex starter config.toml (built on SHAMT-42's `.shamt/host/codex/config.starter.toml`).

### Phase 3: Agents SDK scripts
- [ ] Author `shamt-validate-pr.py`.
- [ ] Implement: load PR context from GitHub Actions env, identify changed artifacts, drive Codex sessions per artifact, post structured PR comment.
- [ ] Author the PR-trigger GitHub Actions workflow template.
- [ ] Test on a synthetic PR with a deliberately-broken spec; verify the script catches it and posts an actionable comment.
- [ ] Author `shamt-cron-janitor.py`.
- [ ] Implement: scan `incoming/` (age >30 days), `active/` (no commit in N weeks), child sync timestamps (no import in N weeks); produce digest file; optionally post to GitHub issue via API.
- [ ] Author the weekly-cron GitHub Actions workflow template.
- [ ] Test by running against a repo with seeded stale items; verify digest is accurate and GitHub issue is created.
- [ ] Update `CHEATSHEET.md` with a "CI Automation" section describing each script's purpose, how to enable it via its GitHub Actions template, and the `@codex` master review pipeline. This ensures users can discover automated Shamt tooling without reading SDK documentation.

### Phase 4: Master review pipeline configuration
- [ ] Author `master-reviewer-workflow.yml.template` for the master repo's `.github/workflows/`.
- [ ] Configure `@codex` mention trigger to invoke the workflow.
- [ ] Verify the `shamt-master-reviewer` skill (from SHAMT-39) loads correctly when the cloud task runs.
- [ ] Test on a real child PR.

### Phase 5: Stage guide updates
- [ ] Author S6/S7/S9 cloud_variant.md files.
- [ ] Update `validation_loop_master_protocol.md` and `architect_builder_pattern.md` to reference cloud variants.
- [ ] Cross-link from CLI-flow descriptions to cloud-flow descriptions and back.

### Phase 6: Init script extension
- [ ] Add `--with-cloud` flag to init for Codex hosts.
- [ ] When set, copy `cloud-environment.template.json` to repo and instruct user on Cloud project registration.

### Phase 7: Validation — Codex doc Experiment B
- [ ] On a test child project (post-SHAMT-42), enable Cloud + OTel + SDK CI.
- [ ] Run a real S6 implementation as a cloud task.
- [ ] Verify: container disposability cleanly recovers from simulated failure (kill the cloud task mid-execution; verify container discarded, no local damage).
- [ ] Attempt to escalate sandbox to `danger-full-access` from inside a cloud task; verify `requirements.toml` rejects.
- [ ] Run OTel collector and view Grafana dashboards: confirm stage / sub-agent / tool breakdowns are visible.
- [ ] Open a synthetic PR with a broken spec; verify `shamt-validate-pr.py` catches it via the GitHub Actions workflow.
- [ ] Pass criterion: all four sub-tests pass.

### Phase 8: Implementation validation
- [ ] Implementation validation loop (5 dimensions).
- [ ] Full guide audit (3 clean rounds).

---

## Validation Strategy

- **Primary:** Design doc validation loop on this doc.
- **Implementation:** Each file in "Files Affected" matches spec.
- **Empirical (Experiment B):** Cloud task with rollback + sandbox enforcement + OTel dashboards + SDK PR gate.
- **Cloud rollback test:** Kill cloud task mid-run; confirm container is discarded and no local state corrupts.
- **OTel rendering test:** Run a validation loop; confirm spans appear in Grafana with stage, persona, tool labels.
- **SDK CI test:** Synthetic PR with deliberately-broken spec gets caught by `shamt-validate-pr.py`; passing PR completes cleanly.
- **Success criteria:**
  1. Cloud builds and runs S6 builder with disposable container.
  2. requirements.toml prevents sandbox escalation in cloud context.
  3. OTel collector receives traces; Grafana renders them.
  4. SDK CI gate fires on PRs and produces actionable output.
  5. Master review pipeline draft-reviews a child PR via `@codex`.

---

## Open Questions

1. **Cloud manifest filename and schema:** Current Codex Cloud doc may have changed; verify at implementation time. **Recommendation:** Start of Phase 1 includes a documentation-verification step.
2. **MCP-on-Cloud behavior:** STDIO MCP servers in containers are uncertain. **Recommendation:** Default to HTTP-served MCP for cloud tasks; document the deployment pattern (small HTTP server reachable from cloud network).
3. **OTel collector hosting:** Does Shamt master ship a hosted collector or expect each project to run their own? **Recommendation:** Local-Docker default for individuals; documented org-level deployment pattern; no hosted master collector (privacy, cost).
4. **GitHub Actions workflow opt-in:** Should children automatically copy the SDK workflow on init, or require explicit `shamt enable-ci` step? **Recommendation:** Explicit step. CI gates affect repo behavior visibly; opt-in respects user agency.
5. **Master review pipeline cost:** `@codex` cloud tasks cost API tokens. Master should rate-limit. **Recommendation:** Document that frequent PRs consume budget; consider conditional triggering (e.g., only when label `needs-shamt-review` is applied).

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Codex Cloud manifest schema changes between authoring and implementation | Documentation-verification step at Phase 1 start; templates are easy to regenerate |
| Cloud MCP STDIO doesn't work; HTTP MCP requires deploying a server | Document the HTTP-MCP deployment pattern; provide a Docker-compose template; if unfeasible for some users, validation work can fall back to CLI-only validation |
| OTel collector hosting decision varies by org | Document multiple paths (local Docker, hosted Honeycomb/Datadog/Grafana Cloud, org-self-hosted); ship the config, let users choose backend |
| SDK script breaks on Agents SDK version changes | Pin SDK version in `pyproject.toml`; document upgrade path; CI runs against pinned version |
| Master review pipeline burns through API budget on PR storms | Add a rate-limit guard or label-trigger; document cost expectations |
| Container disposability rollback corrupts cached artifacts | Cloud caches are 12h; corrupted-cache scenario triggers full rebuild on next setup-script run; document the recovery |
| GitHub Action runs against wrong base ref | Workflow template uses `${{ github.event.pull_request.base.ref }}` — verified pattern |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-27 | Initial draft created |
| 2026-04-27 | Validated — added master-only deployment note to master-reviewer workflow template in Files Affected and Proposal 4 |
| 2026-04-27 | Added shamt-cron-janitor.py and its cron workflow template to Proposal 3, Files Affected, and Phase 3 |
| 2026-04-27 | Added scope justification to Proposal 5: explains why S6/S7/S9 get cloud variants and S8/S10/S11 do not |
| 2026-04-27 | Added CHEATSHEET.md MODIFY entry to Files Affected; Phase 3 step to add "CI Automation" section covering SDK scripts and @codex master review |
