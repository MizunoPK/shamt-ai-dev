"""Tests for audit_run MCP tool."""

import json
import shamt_mcp.audit_run as _mod
from shamt_mcp.audit_run import audit_run


def test_audit_run_writes_json(tmp_path, monkeypatch):
    monkeypatch.setattr(_mod, "_project_root", lambda: tmp_path)
    result = audit_run(
        scope=".shamt/guides/",
        consecutive_clean=3,
        exit_criterion_met=True,
        issues_by_severity={"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0},
    )
    assert result["recorded"] is True
    assert result["exit_criterion_met"] is True
    from pathlib import Path
    out = json.loads(Path(result["path"]).read_text())
    assert out["scope"] == ".shamt/guides/"
    assert out["consecutive_clean"] == 3


def test_audit_run_failed_audit(tmp_path, monkeypatch):
    monkeypatch.setattr(_mod, "_project_root", lambda: tmp_path)
    result = audit_run(
        scope=".shamt/guides/",
        consecutive_clean=0,
        exit_criterion_met=False,
        issues_by_severity={"CRITICAL": 0, "HIGH": 1, "MEDIUM": 0, "LOW": 0},
    )
    assert result["exit_criterion_met"] is False
    from pathlib import Path
    out = json.loads(Path(result["path"]).read_text())
    assert out["issues_by_severity"]["HIGH"] == 1
