# Shamt Cheat Sheet

Quick reference for all Shamt operations, stage flow, and sub-agent personas.

---

## Slash Commands

| Command | Description |
|---------|-------------|
| `/shamt-start-epic {request}` | Begin a new epic — initialize folders, enter S1 Discovery |
| `/shamt-validate {artifact}` | Run a validation loop on any artifact (spec, plan, design doc) |
| `/shamt-audit` | Run the full guide audit on `.shamt/guides/` (23 dimensions + D-DRIFT/D-COVERAGE, 3 clean rounds) |
| `/shamt-export` | Export generic guide improvements to master via pull request |
| `/shamt-import` | Run post-import validation after `import.sh` completes |
| `/shamt-status` | Print current epic, stage, last action, and blockers |
| `/shamt-resume` | Re-hydrate context after compaction or new session |
| `/shamt-promote {proposal}` | (Master only) Promote incoming proposal to active design doc |

---

## S1–S11 Stage Flow

| Stage | Name | Key Artifact |
|-------|------|-------------|
| **S1** | Epic Planning & Discovery | `EPIC_README.md`, `DISCOVERY.md` |
| **S2** | Feature Deep Dive & Spec | `spec.md`, `checklist.md` |
| **S3** | Epic Documentation & Approval | Updated `EPIC_README.md` (Gate 3/4) |
| **S4** | Testing Strategy & Interface Contracts | `TEST_STRATEGY.md`, `interface_contracts.md` |
| **S5** | Implementation Planning | `implementation_plan.md` (validated, Gate 5) |
| **S6** | Implementation Execution | Code changes (Haiku builder executes plan) |
| **S7** | Feature Smoke + QC + PR Review | `SMOKE_RESULTS.md`, QC rounds, `review_v1.md` |
| **S8** | Cross-Feature Alignment | `S8_ALIGNMENT_VALIDATION_*.md` |
| **S9** | Epic Smoke + QC + PR Review | Epic-level QC rounds, `epic_review_v1.md` |
| **S10** | Final Changes & Merge | Architecture/Standards updates, merge |
| **S11** | Export & Cleanup | `CHANGES.md` entries, export PR |

---

## Sub-Agent Persona Quick Reference

| Persona | Tier | Sandbox | Primary Use |
|---------|------|---------|-------------|
| `shamt-validator` | cheap (Haiku) | read-only | Sub-agent confirmation of validation rounds |
| `shamt-builder` | cheap (Haiku) | workspace-write | Mechanical execution of implementation plans |
| `shamt-architect` | reasoning (Opus) | read-only | Creating and validating implementation plans |
| `shamt-guide-auditor` | balanced (Sonnet) | read-only | Guide audit rounds (23 dimensions + D-DRIFT/D-COVERAGE) |
| `shamt-code-reviewer` | balanced (Sonnet) | read-only | Code review (formal, S7.P3, S9.P4) |
| `shamt-spec-aligner` | balanced (Sonnet) | read-only | S8 cross-feature spec alignment |
| `shamt-discovery-researcher` | balanced (Sonnet) | read-only + web | S1 discovery research |

**Master-applicable personas:** validator, builder, architect, guide-auditor, code-reviewer  
**Child-only personas:** spec-aligner, discovery-researcher

---

## Key Rules At a Glance

| Rule | Detail |
|------|--------|
| **Validation loop exit** | Primary clean round (consecutive_clean = 1) + 2 Haiku sub-agents both confirm zero issues |
| **Guide audit exit** | 3 consecutive clean rounds (NOT 1+2 sub-agents) |
| **Clean round** | 0 issues OR exactly 1 LOW issue found and fixed |
| **Sub-agent allowance** | ZERO — any finding (even LOW) resets the counter |
| **ONE question at a time** | Never batch spec questions; wait for answer before next question |
| **INVESTIGATION ≠ RESOLVED** | User must explicitly approve before a question is resolved |
| **Builder role** | Execute only — STOP and report on any error, never make design decisions |
| **Code review** | Read-only git commands only; never check out the branch |
| **Re-review** | Create review_v2.md, review_v3.md — never overwrite previous versions |

---

## Active Enforcement (Hooks — SHAMT-41/44)

Active when `features.shamt_hooks=true` in `.claude/settings.json`. Hooks registered by `regen-claude-shims.sh`.

| Hook | Event | Blocks / Requires |
|------|-------|-------------------|
| `no-verify-blocker.sh` | PreToolUse (Bash) | `--no-verify` and `--no-gpg-sign` git flags |
| `commit-format.sh` | PreToolUse (Bash) | Commits not matching `feat/SHAMT-N:` or `fix/SHAMT-N:` prefix |
| `pre-export-audit-gate.sh` *(child-only)* | UserPromptSubmit + PreToolUse | Export if audit is stale (>7 days) or `exit_criterion_met=false` |
| `validation-log-stamp.sh` | PostToolUse (Edit on `*VALIDATION_LOG.md`) | Appends timestamp after each log edit (always passes) |
| `validation-stall-detector.sh` | PostToolUse (Edit on `*VALIDATION_LOG.md`) | Detects `consecutive_clean=0` for ≥N rounds; writes `STALL_ALERT.md` |
| `architect-builder-enforcer.sh` | PreToolUse (Task) | S6 Task spawns that don't use `shamt-builder` persona |
| `user-testing-gate.sh` *(child-only)* | PreToolUse (Bash) | `git push` in S9 unless user-testing artifact shows "ZERO bugs found" |
| `pre-push-tripwire.sh` | PreToolUse (Bash `git push`) | Blocks push if audit is stale, active validation shows `consecutive_clean=0`, or builder log has errors |
| `precompact-snapshot.sh` | PreCompact | Writes `RESUME_SNAPSHOT.md` before auto-compaction |
| `session-start-resume.sh` | SessionStart | Injects `RESUME_SNAPSHOT.md` as agent context on start |
| `subagent-confirmation-receipt.sh` | SubagentStop | Writes veto flag if confirming sub-agent reports issues |
| `stage-transition-snapshot.sh` | UserPromptSubmit | Writes `RESUME_SNAPSHOT.md` on stage-advance phrases |

**MCP tools (SHAMT-41/44):** `shamt.next_number()` · `shamt.validation_round()` · `shamt.audit_run()` · `shamt.epic_status()` · `shamt.metrics_append()` · `shamt.export_pipeline()` · `shamt.import_pipeline()`

---

## CI Automation (SHAMT-43/46)

All pipelines are **opt-in** — copy the workflow template manually; none run automatically after init.

### GitHub Actions

| Tool | Purpose | Enable |
|------|---------|--------|
| `shamt-validate-pr.py` | Validates changed Shamt artifacts on PRs; posts structured comment; exits non-zero on failure | Copy `.shamt/sdk/.github/workflows/shamt-validate.yml.template` → `.github/workflows/shamt-validate.yml`; add `OPENAI_API_KEY` secret |
| `shamt-cron-janitor.py` | Weekly scan: proposals >30d old, stalled design docs, stale child syncs; posts digest as GitHub issue | Copy `.shamt/sdk/.github/workflows/shamt-cron-janitor.yml.template` → `.github/workflows/shamt-cron-janitor.yml`; create `shamt-janitor` label |
| Master reviewer pipeline | `@codex` on a child PR triggers Codex Cloud review using `shamt-master-reviewer` skill; posts draft comment; label-gated via `needs-shamt-review` | **Master repo only:** copy `.shamt/host/codex/master-reviewer-workflow.yml.template` → `.github/workflows/master-reviewer.yml`; enable Codex Cloud on the repo |

**Label gate (recommended):** Uncomment the `if: contains(..., 'needs-shamt-review')` line in `shamt-validate.yml` to restrict to labeled PRs.

### Azure Pipelines (ADO — SHAMT-46)

| Tool | Purpose | Enable |
|------|---------|--------|
| `shamt-validate-pr.py --provider=ado` | PR validation gate; posts findings as ADO PR comment threads; sets PR status | Copy `.shamt/sdk/azure-pipelines/shamt-validate.yml.template`; add Build Validation branch policy |
| `shamt-cron-janitor.py --provider=ado` | Weekly stale-work scan; posts digest as ADO Work Item | Copy `.shamt/sdk/azure-pipelines/shamt-cron-janitor.yml.template` |

**Setup:** Run `init.sh --pr-provider=ado` (or `--pr-provider=both`). See `.shamt/sdk/azure-pipelines/README.md` for permission prerequisites (`$(System.AccessToken)` requires explicit "Contribute to pull requests" grant).

**Interactive ADO PR review:** In an agent session: `"Review PR #123 on ADO"` — agent uses ADO MCP tools to read diff and post review threads. See `.shamt/guides/reference/ado_pr_review_workflow.md`.

---

## Cross-Cutting Composites (SHAMT-44)

Six assembled workflows. Each composite shows how the component primitives work together.
Read the composite first; read the primitive guides for full detail.

| Composite | When to use | Guide |
|-----------|------------|-------|
| Validation loop | Any artifact validation (spec, plan, guide, design doc) | `composites/validation_loop_composite.md` |
| Architect–builder | Large implementations (>10 file ops or >100K tokens) | `composites/architect_builder_composite.md` |
| Stale-work janitor | Weekly cleanup, post-event follow-up | `composites/stale_work_janitor_composite.md` |
| Master review pipeline | Child PR review, post-merge guide audit | `composites/master_review_pipeline_composite.md` |
| Metrics / observability | Hook emission, OTel, Grafana dashboards | `composites/metrics_observability_composite.md` |
| Rollback / recovery | Stall detection, worktree rollback, pre-push guard | `composites/rollback_recovery_composite.md` |

---

## Status Line Format (SHAMT-45)

Enhanced render (when `shamt-statusline.sh` is configured as `statusLine` command):

```
SHAMT-42 | S5.P2 | round 3 | effort: high | stall: none | profile: shamt-s5
SHAMT-42 | S5.P2 | round 3 | effort: high | stall: warn | profile: shamt-s5
```

Fields: `effort` (from AGENT_STATUS.md `Reasoning:` / `Effort:` field), `stall` (`warn` when `STALL_ALERT.md` present, otherwise `none`), `profile` (from `SHAMT_ACTIVE_PROFILE` env var or derived as `shamt-s{N}` from stage).

---

## Gate Prompts (AskUserQuestion — SHAMT-45)

Structured gates at key workflow checkpoints. On Codex headless, post as PR comment; parse reply.

> `shamt-validation-loop` is the internal skill invoked by `/shamt-validate` — use `/shamt-validate` to trigger these gates; do not invoke the skill directly.

| Gate | Stage | Skill | Options |
|------|-------|-------|---------|
| Testing-approach selection | S1 | `shamt-discovery` | A — Manual e2e / B — Integration scripts / C — Manual + smoke / D — Scripts + smoke |
| Feature breakdown approval | S1 | `shamt-spec-protocol` | `approve as-is` / `request changes` / `reject scope` |
| Checklist resolution | S2.P1.I2 | `shamt-spec-protocol` | Per-question options (free-text fallback via "other") |
| Plan approval (Gate 5) | S5 | `shamt-architect-builder` | `approve` / `request changes` / `reject` |
| Stall escalation | any | `shamt-validation-loop` | `Apply recommended escalation` / `Continue without escalation` / `Decompose artifact` / `Escalate to human review` |
| User-testing zero-bug confirmation | S9 | `shamt-validation-loop` | `ZERO bugs found` / `bugs found` (requires reason if bugs found) |

---

## Memory Quick Reference (SHAMT-45)

**Decision rule:** Would another agent on another machine need this to continue work?

- **YES** → Shamt artifact (`.shamt/epics/<active>/`) — stage, round, spec, plan, validation log
- **NO** → Harness memory (`~/.claude/projects/<path>/memory/`) — preferences, project facts, external references

Full separation rules: `.shamt/guides/reference/memory_tiers.md`

---

## Severity Quick Reference

| Level | Definition | Clean Round Impact |
|-------|-----------|-------------------|
| CRITICAL | Blocks workflow or causes cascading failures | Counter resets to 0 |
| HIGH | Causes significant confusion or wrong decisions | Counter resets to 0 |
| MEDIUM | Reduces quality but doesn't block | Counter resets to 0 |
| LOW | Cosmetic, minimal impact | 1 allowed per round (primary agent only) |

When uncertain between two levels: classify as the **higher** severity.

<!-- Managed by Shamt — do not edit. Run regen-claude-shims.sh to regenerate. -->
