# Metrics and Observability Composite

**What this is:** The full metrics pipeline assembled from its component parts — hook
emission, `shamt.metrics_append()` MCP tool, sidecar log, OTel collector, Prometheus,
Tempo, and Grafana dashboards. Read this guide to understand how the pieces interact;
read each component's home guide for full configuration detail.

**Note:** This composite covers all Shamt contexts (child and master). There is no
separate "Master Dev Variant" section because metrics emission and observability are
useful in both contexts.

---

## Component Map

| Component | Where it lives | Role |
|-----------|---------------|------|
| `shamt.metrics_append()` | `.shamt/mcp/` | MCP tool: validates labels, writes sidecar, best-effort OTLP |
| `sidecar.jsonl` | `.shamt/metrics/sidecar.jsonl` | Local queryable metrics log (one JSON line per event) |
| `validation-log-stamp.sh` | `.shamt/hooks/` | Emits `validation_round` metric on each log edit |
| `stage-transition-snapshot.sh` | `.shamt/hooks/` | Emits `shamt_session_active` metric at stage transitions |
| `architect-builder-enforcer.sh` | `.shamt/hooks/` | Emits `builder_runs_total` metric on S6 spawns |
| `subagent-confirmation-receipt.sh` | `.shamt/hooks/` | Emits `confirmer_run` metric on sub-agent completion |
| OTel collector | `.shamt/observability/otel-collector.yaml` | Receives OTLP; exports to Prometheus (scrape endpoint :8889) |
| Prometheus | `.shamt/observability/prometheus.yml` | Scrapes OTel collector :8889; stores time series |
| Tempo | `.shamt/observability/tempo.yaml` | OTLP trace ingress :4317; local trace storage |
| Grafana dashboards | `.shamt/observability/grafana/` | Visualizes: overview, validation loop, architect-builder, savings |
| Docker Compose | `.shamt/observability/docker-compose.yml` | Local stack: otel-collector + prometheus + tempo + grafana |

---

## How the Pieces Work Together

### 1. Emission: Hooks → `shamt.metrics_append()`

Each hook emits metrics at meaningful events via `shamt.metrics_append()`:

| Hook | Metric emitted | When |
|------|---------------|------|
| `validation-log-stamp.sh` | `validation_round` | Every validation log edit |
| `stage-transition-snapshot.sh` | `shamt_session_active` | Stage transition phrase detected |
| `architect-builder-enforcer.sh` | `builder_runs_total` | S6 builder Task spawn |
| `subagent-confirmation-receipt.sh` | `confirmer_run` | Sub-agent confirmation completes |

The MCP tool validates labels against a per-metric permit-list before writing. Unknown
labels are rejected with `accepted=False` to prevent cardinality explosion.

### 2. Sidecar Log

Every accepted `metrics_append()` call appends to `.shamt/metrics/sidecar.jsonl`:

```jsonl
{"ts": "2026-04-30T12:00:00Z", "metric": "validation_round", "value": 1.0, "labels": {"shamt_stage": "S7", "shamt_persona": "shamt-validator"}, "epic_id": null}
```

The sidecar log is queryable locally without Grafana:
```bash
# Count validation rounds by stage
grep '"validation_round"' .shamt/metrics/sidecar.jsonl | python3 -c "
import sys, json, collections
counts = collections.Counter(json.loads(l)['labels'].get('shamt_stage','?') for l in sys.stdin)
print(dict(counts))
"
```

### 3. OTel OTLP Emission

If `SHAMT_OTEL_ENDPOINT` is set, `shamt.metrics_append()` also sends OTLP to the
collector. This is **best-effort**: failures are silently swallowed to never block the
agent workflow.

```bash
export SHAMT_OTEL_ENDPOINT=http://localhost:4317
```

### 4. Local Docker Stack

Start the full observability stack locally:

```bash
cd .shamt/observability
docker compose up -d
```

Services:
- OTel collector: `:4317` (OTLP gRPC), `:4318` (OTLP HTTP), `:8889` (Prometheus scrape)
- Prometheus: `:9090`
- Tempo: `:3200`
- Grafana: `:3000` (anonymous Admin access enabled by default; no login required in the shipped compose config)

**Port layout note:** The OTel collector exposes its Prometheus exporter on `:8889`
(not `:9090`, which is the Prometheus server). Prometheus scrapes `otel-collector:8889`.

### 5. Grafana Dashboards

Four dashboards in `.shamt/observability/grafana/`:

| Dashboard | File | Purpose |
|-----------|------|---------|
| Shamt Overview | `shamt-overview.json` | High-level epic health, stage distribution |
| Validation Loop | `shamt-validation-loop.json` | Round counts, stall frequency, consecutive_clean trends |
| Architect–Builder | `shamt-architect-builder.json` | Builder run counts, error rates, step latency |
| Savings Tracker | `shamt-savings-tracker.json` | Actual vs. projected token savings (SHAMT-27/30) |

Import dashboards: Grafana → Dashboards → Import → Upload JSON file.

### Bootstrapping Caveat

The observability stack is only useful once there are metrics to visualize. During the
first 1–2 epics after setup, the dashboards will be sparse. This is expected. The
sidecar log provides local queryability before the full stack is running.

Do not let the "no data in dashboards" signal block usage — start emitting metrics
immediately even if the visual layer is not yet configured.

---

## Metrics Permit-List

Labels permitted per metric (additional labels are rejected):

| Metric | Permitted labels |
|--------|----------------|
| `validation_round` | `shamt_stage`, `shamt_persona`, `severity_summary`, `shamt_epic`, `shamt_loop_type` |
| `audit_round` | `shamt_stage`, `dimensions_checked`, `issues_found_by_severity`, `shamt_epic` |
| `builder_step` | `step_index`, `file_op_count`, `shamt_stage`, `shamt_epic` |
| `builder_runs_total` | `shamt_variant`, `status`, `shamt_epic` |
| `confirmer_run` | `shamt_persona`, `model`, `shamt_epic`, `shamt_stage` |
| `shamt_session_active` | `shamt_stage`, `shamt_persona`, `shamt_epic` |
| `shamt_tokens_saved` | `method`, `shamt_stage`, `shamt_epic` |
| `shamt_tool_calls` | `shamt_stage`, `shamt_persona`, `tool_name` |
