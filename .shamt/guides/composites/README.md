# Shamt Composite Guides

Composite guides assemble **primitive components** (hooks, MCP tools, skills, sub-agents,
slash commands) into **end-to-end documented workflows**. Each composite is a single
reference showing how the parts fit together, with cross-links to each primitive's home
guide.

Composites do not replace the primitive guides — they sit on top of them and answer
"how do I use these together?"

---

## Index

| Composite | Purpose |
|-----------|---------|
| [`validation_loop_composite.md`](validation_loop_composite.md) | Full validation loop with `/loop`, MCP, stall detector, sub-agent confirmers |
| [`architect_builder_composite.md`](architect_builder_composite.md) | Planning → execution pipeline with worktree/container isolation and cloud variant |
| [`stale_work_janitor_composite.md`](stale_work_janitor_composite.md) | SDK cron janitor + issue triage + stale proposal cleanup |
| [`master_review_pipeline_composite.md`](master_review_pipeline_composite.md) | Master repo code/guide review: label trigger → skill → PR comment |
| [`metrics_observability_composite.md`](metrics_observability_composite.md) | Metrics sidecar + OTel + Grafana dashboards end-to-end |
| [`rollback_recovery_composite.md`](rollback_recovery_composite.md) | Stall detection + worktree/container disposability + tripwire guard |

---

## Relationship to Primitives

```
Primitive home guides         Composite guides (this folder)
─────────────────────         ──────────────────────────────
guides/reference/             composites/validation_loop_composite.md
  validation_loop_master_protocol.md   ← assembles ↑ + MCP + hooks + /loop

guides/reference/             composites/architect_builder_composite.md
  architect_builder_pattern.md         ← assembles ↑ + S5/S6 guides + cloud

.shamt/mcp/README.md          composites/metrics_observability_composite.md
.shamt/observability/         ← assembles ↑

.shamt/hooks/README.md        composites/rollback_recovery_composite.md
                              ← assembles stall-detector + tripwire + worktree
```

---

## Separation Rule

Composites must be **cross-cutting** (useful to all Shamt projects or all master work).
Project-specific workflows belong in the child project's CLAUDE.md, not here.

Each composite documents both Claude Code and Codex variants where the behavior differs.
Where behavior is identical across hosts, a single description suffices.
