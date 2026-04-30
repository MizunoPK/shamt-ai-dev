"""Tests for metrics_append MCP tool."""

import json
import shamt_mcp.metrics_append as _mod
from shamt_mcp.metrics_append import metrics_append


def test_metrics_append_valid(tmp_path, monkeypatch):
    monkeypatch.setattr(_mod, "_project_root", lambda: tmp_path)
    result = metrics_append(
        metric_name="validation_round",
        value=1.0,
        labels={"shamt_stage": "S7", "shamt_persona": "shamt-validator"},
    )
    assert result["accepted"] is True
    sidecar = tmp_path / ".shamt" / "metrics" / "sidecar.jsonl"
    assert sidecar.exists()
    event = json.loads(sidecar.read_text().strip())
    assert event["metric"] == "validation_round"
    assert event["value"] == 1.0


def test_metrics_append_unknown_metric(tmp_path, monkeypatch):
    monkeypatch.setattr(_mod, "_project_root", lambda: tmp_path)
    result = metrics_append(metric_name="not_real", value=1.0, labels={})
    assert result["accepted"] is False
    assert "Unknown metric" in result["error"]


def test_metrics_append_rejected_label(tmp_path, monkeypatch):
    monkeypatch.setattr(_mod, "_project_root", lambda: tmp_path)
    result = metrics_append(
        metric_name="validation_round",
        value=1.0,
        labels={"shamt_stage": "S7", "not_permitted": "bad"},
    )
    assert result["accepted"] is False
    assert "not_permitted" in result["rejected_labels"]


def test_metrics_append_appends_multiple(tmp_path, monkeypatch):
    monkeypatch.setattr(_mod, "_project_root", lambda: tmp_path)
    metrics_append("validation_round", 1.0, {"shamt_stage": "S7"})
    metrics_append("validation_round", 2.0, {"shamt_stage": "S8"})
    sidecar = tmp_path / ".shamt" / "metrics" / "sidecar.jsonl"
    lines = [l for l in sidecar.read_text().splitlines() if l.strip()]
    assert len(lines) == 2
