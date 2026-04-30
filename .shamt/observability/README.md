# Shamt Observability

OpenTelemetry collector preset and Grafana dashboards for Shamt projects.

---

## Quick Start (Local Docker)

```bash
docker compose -f .shamt/observability/docker-compose.yml up -d
```

This starts:
- OTel Collector (OTLP gRPC 4317, HTTP 4318)
- Prometheus (metrics scrape, port 9090)
- Tempo (traces, port 3200)
- Grafana (dashboards, port 3000)

Then import the dashboards:
1. Open Grafana at `http://localhost:3000` (admin / admin)
2. Go to **Dashboards → Import**
3. Import each JSON from `.shamt/observability/grafana/`

---

## Wiring OTel into a Codex Project

Codex CLI exposes a `[telemetry]` block in `.codex/config.toml`. To enable:

```toml
[telemetry]
otlp_endpoint = "http://localhost:4317"
```

The `config.starter.toml` ships with this block commented out. Uncomment it and point `otlp_endpoint` at your collector (local Docker or org-hosted).

Shamt-domain labels (`shamt.stage`, `shamt.persona`, `shamt.hook`, `shamt.epic`, `shamt.round`) are emitted as span attributes by:
- The Shamt MCP tools (`shamt.validation_round`, `shamt.next_number`) — set `shamt.epic` and `shamt.stage` on each call
- The hooks bundle — `stage-transition-snapshot.sh` and `subagent-confirmation-receipt.sh` emit `shamt.stage` and `shamt.round`

If your Codex version does not emit OTLP natively, the metrics-emitting MCP tool (SHAMT-44) provides a fallback: it calls `shamt.metrics.append()` which emits spans directly from the MCP server.

---

## Wiring OTel into a Claude Code Project

OTel is not native to Claude Code. Use the metrics-emitting MCP tool from SHAMT-44:
- `shamt.metrics.append(metric_name, labels, value)` — emits an OTel span from the Shamt MCP server
- The MCP server forwards spans to the configured OTLP endpoint

Wire the collector by adding `otlp_endpoint` to the MCP server's environment (set `SHAMT_OTEL_ENDPOINT` in the terminal or in `.claude/settings.json`'s `env` block).

---

## Dashboards

| Dashboard | Description |
|-----------|-------------|
| `shamt-overview.json` | Request duration, token usage, tool call counts by stage / persona |
| `shamt-validation-loop.json` | Round counts, severity distributions, time-to-exit per validation loop |
| `shamt-architect-builder.json` | S6 builder execution duration, error rates, model spend (CLI + Cloud) |
| `shamt-savings-tracker.json` | Measured vs. projected token savings (cache hit rate, sub-agent / builder ratios) |

---

## OTel Collector Configuration

`otel-collector.yaml` is the ready-to-run collector config. Key design decisions:

- **Receivers:** OTLP gRPC (4317) + HTTP (4318) — handles both Codex and Claude Code SDK clients
- **Shamt attribute processor:** promotes `shamt.*` span attributes to resource attributes for efficient Grafana filtering
- **Shamt-only filter:** drops spans with no Shamt label (raw model API calls) to keep the collector focused
- **Exporters:** Prometheus (metrics) + Tempo (traces) for local-Docker default; cloud exporter template (commented out) for shared deployments

---

## Org-Level / Shared Deployment

For teams sharing a collector:

1. Deploy the collector on a shared host with access to your team's Prometheus + Tempo instances.
2. Uncomment the `otlp/cloud` exporter in `otel-collector.yaml` and set:
   ```
   OTEL_EXPORTER_OTLP_ENDPOINT=<your-collector-url>
   OTEL_EXPORTER_OTLP_HEADERS_AUTHORIZATION=<your-token>
   ```
3. Point each developer's `.codex/config.toml` `[telemetry]` block at the shared collector.

Shamt master does **not** ship a hosted collector (privacy, cost). The collector config and dashboards are templates — each team runs their own.

---

## Metric Names

| Metric | Type | Labels |
|--------|------|--------|
| `shamt_tool_calls_total` | counter | `shamt_stage`, `shamt_persona`, `tool_name` |
| `shamt_tokens_total` | counter | `shamt_stage`, `shamt_persona`, `model_tier`, `token_type` |
| `shamt_tokens_saved_total` | counter | `method` (`cache_read`, `haiku_subagent`, `haiku_builder`) |
| `shamt_span_duration_seconds` | histogram | `shamt_stage`, `shamt_persona` |
| `shamt_validation_consecutive_clean` | gauge | `shamt_epic`, `shamt_loop_type` |
| `shamt_validation_rounds_total` | counter | `shamt_epic`, `shamt_loop_type` |
| `shamt_validation_issues_total` | counter | `severity`, `dimension` |
| `shamt_validation_clean_rounds_total` | counter | `shamt_loop_type` |
| `shamt_validation_exit_duration_seconds` | histogram | `shamt_loop_type` |
| `shamt_builder_runs_total` | counter | `shamt_variant` (`cli`, `cloud`), `status` |
| `shamt_builder_duration_seconds` | histogram | `shamt_variant` |
| `shamt_builder_errors_total` | counter | `shamt_variant`, `shamt_error_type` |
| `shamt_session_active` | gauge | `shamt_stage`, `shamt_persona` |

Permitted label values are validated by the MCP tool (see SHAMT-44 OQ2). Unknown labels are rejected with a warning to prevent cardinality explosion.
