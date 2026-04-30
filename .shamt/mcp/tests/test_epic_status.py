"""Tests for epic_status MCP tool."""

import shamt_mcp.epic_status as _mod
from shamt_mcp.epic_status import epic_status


def test_epic_status_no_tracker(tmp_path, monkeypatch):
    monkeypatch.setattr(_mod, "_project_root", lambda: tmp_path)
    result = epic_status("active")
    assert result["found"] is False


def test_epic_status_finds_active(tmp_path, monkeypatch):
    monkeypatch.setattr(_mod, "_project_root", lambda: tmp_path)
    tracker_dir = tmp_path / ".shamt" / "epics"
    tracker_dir.mkdir(parents=True)
    (tracker_dir / "EPIC_TRACKER.md").write_text(
        "| KAI-007 | Test epic | S6 | In Progress |\n"
        "| KAI-006 | Done epic | S11 | Done |\n"
    )
    result = epic_status("active")
    assert result["found"] is True
    assert result["epic_id"] == "KAI-007"
    assert result["stage"] == "S6"


def test_epic_status_specific_epic(tmp_path, monkeypatch):
    monkeypatch.setattr(_mod, "_project_root", lambda: tmp_path)
    tracker_dir = tmp_path / ".shamt" / "epics"
    tracker_dir.mkdir(parents=True)
    (tracker_dir / "EPIC_TRACKER.md").write_text(
        "| KAI-005 | Old epic | S11 | Done |\n"
    )
    result = epic_status("KAI-005")
    assert result["found"] is True
    assert result["epic_id"] == "KAI-005"
