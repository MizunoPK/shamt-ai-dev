"""Tests for export_pipeline and import_pipeline MCP tools."""

import json
import shamt_mcp.export_pipeline as _export_mod
import shamt_mcp.import_pipeline as _import_mod
from shamt_mcp.export_pipeline import export_pipeline
from shamt_mcp.import_pipeline import import_pipeline


def test_export_dry_run_missing_changes_md(tmp_path, monkeypatch):
    monkeypatch.setattr(_export_mod, "_project_root", lambda: tmp_path)
    result = export_pipeline("KAI-007", dry_run=True)
    assert result["ok"] is False
    assert result["checks"]["changes_md_exists"] is False


def test_export_dry_run_passes_with_clean_audit(tmp_path, monkeypatch):
    monkeypatch.setattr(_export_mod, "_project_root", lambda: tmp_path)
    epic_dir = tmp_path / ".shamt" / "epics" / "KAI-007"
    epic_dir.mkdir(parents=True)
    (epic_dir / "CHANGES.md").write_text("## Changes\n- something\n")
    audit_dir = tmp_path / ".shamt" / "audit"
    audit_dir.mkdir(parents=True)
    (audit_dir / "last_run.json").write_text(json.dumps({
        "exit_criterion_met": True,
        "scope": ".shamt/guides/",
    }))
    result = export_pipeline("KAI-007", dry_run=True)
    assert result["ok"] is True
    assert result["dry_run"] is True


def test_import_missing_script(tmp_path, monkeypatch):
    monkeypatch.setattr(_import_mod, "_project_root", lambda: tmp_path)
    result = import_pipeline(dry_run=True)
    assert result["ok"] is False
    assert "import.sh not found" in result["error"]
