"""Emit a Shamt-domain metric event to sidecar log and optionally OTel."""

import json
import os
from datetime import datetime, timezone
from pathlib import Path


def _project_root() -> Path:
    return Path(__file__).resolve().parents[4]


# Permitted label sets per metric name. Unknown labels are rejected.
PERMITTED_LABELS: dict[str, set[str]] = {
    "validation_round": {"shamt_stage", "shamt_persona", "severity_summary", "shamt_epic", "shamt_loop_type"},
    "audit_round": {"shamt_stage", "dimensions_checked", "issues_found_by_severity", "shamt_epic"},
    "builder_step": {"step_index", "file_op_count", "shamt_stage", "shamt_epic"},
    "builder_runs_total": {"shamt_variant", "status", "shamt_epic"},
    "confirmer_run": {"shamt_persona", "model", "shamt_epic", "shamt_stage"},
    "shamt_session_active": {"shamt_stage", "shamt_persona", "shamt_epic"},
    "shamt_tokens_saved": {"method", "shamt_stage", "shamt_epic"},
    "shamt_tool_calls": {"shamt_stage", "shamt_persona", "tool_name"},
}


def metrics_append(
    metric_name: str,
    value: float,
    labels: dict,
    epic_id: str | None = None,
) -> dict:
    """
    Emit a Shamt-domain metric event.

    Writes to `.shamt/metrics/sidecar.jsonl` for local queryability and
    optionally emits an OTLP span if `SHAMT_OTEL_ENDPOINT` is set in the
    environment.

    Parameters:
        metric_name: One of the permitted metric names (see PERMITTED_LABELS).
        value: Numeric value (counter increment, gauge reading, or duration_ms).
        labels: Dict of label key → value. Unknown labels for the given metric
            are rejected with a warning (accepted=False).
        epic_id: Optional epic identifier to attach to the event. If omitted,
            auto-detected from EPIC_TRACKER.md.

    Returns:
        {"accepted": bool, "metric_name": str, "rejected_labels": list[str]}
    """
    permitted = PERMITTED_LABELS.get(metric_name)
    if permitted is None:
        return {
            "accepted": False,
            "metric_name": metric_name,
            "rejected_labels": [],
            "error": f"Unknown metric '{metric_name}'. Permitted: {sorted(PERMITTED_LABELS)}",
        }

    rejected = [k for k in labels if k not in permitted]
    if rejected:
        return {
            "accepted": False,
            "metric_name": metric_name,
            "rejected_labels": rejected,
            "error": f"Unknown labels for '{metric_name}': {rejected}. Permitted: {sorted(permitted)}",
        }

    ts = datetime.now(timezone.utc).isoformat()
    event = {
        "ts": ts,
        "metric": metric_name,
        "value": value,
        "labels": labels,
        "epic_id": epic_id,
    }

    sidecar_dir = _project_root() / ".shamt" / "metrics"
    sidecar_dir.mkdir(parents=True, exist_ok=True)
    with open(sidecar_dir / "sidecar.jsonl", "a") as f:
        f.write(json.dumps(event) + "\n")

    _try_emit_otlp(metric_name, value, labels, ts)

    return {"accepted": True, "metric_name": metric_name, "rejected_labels": []}


def _try_emit_otlp(metric_name: str, value: float, labels: dict, ts: str) -> None:
    """Best-effort OTLP emission; silently skips if endpoint not configured."""
    endpoint = os.environ.get("SHAMT_OTEL_ENDPOINT")
    if not endpoint:
        return
    try:
        import urllib.request
        import urllib.error

        # Minimal OTLP/HTTP JSON payload (metrics format)
        payload = {
            "resourceMetrics": [{
                "resource": {"attributes": [{"key": k, "value": {"stringValue": str(v)}} for k, v in labels.items()]},
                "scopeMetrics": [{
                    "scope": {"name": "shamt-mcp"},
                    "metrics": [{
                        "name": metric_name,
                        "gauge": {
                            "dataPoints": [{
                                "asDouble": float(value),
                                "timeUnixNano": str(int(datetime.fromisoformat(ts).timestamp() * 1e9)),
                            }]
                        }
                    }]
                }]
            }]
        }
        data = json.dumps(payload).encode()
        req = urllib.request.Request(
            f"{endpoint.rstrip('/')}/v1/metrics",
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        urllib.request.urlopen(req, timeout=2)
    except Exception:
        pass  # OTLP emission is best-effort; never break the agent flow
