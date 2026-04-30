"""Tests for validation_round — consecutive_clean arithmetic and log append."""

from pathlib import Path

import pytest

from shamt_mcp.validation_round import (
    _is_clean_round,
    _read_consecutive_clean,
    validation_round,
)


# --- _is_clean_round unit tests -----------------------------------------------

def test_zero_issues_is_clean():
    assert _is_clean_round({}, False) is True


def test_one_low_fixed_is_clean():
    assert _is_clean_round({"LOW": 1}, True) is True


def test_one_low_not_fixed_is_not_clean():
    assert _is_clean_round({"LOW": 1}, False) is False


def test_two_lows_fixed_is_not_clean():
    assert _is_clean_round({"LOW": 2}, True) is False


def test_one_medium_is_not_clean():
    assert _is_clean_round({"MEDIUM": 1}, False) is False


def test_one_medium_fixed_is_not_clean():
    # fixed only applies to exactly-1-LOW; MEDIUM is never excused
    assert _is_clean_round({"MEDIUM": 1}, True) is False


def test_one_low_one_medium_fixed_is_not_clean():
    assert _is_clean_round({"LOW": 1, "MEDIUM": 1}, True) is False


# --- _read_consecutive_clean unit tests ---------------------------------------

def test_reads_zero_from_empty_file(tmp_path):
    log = tmp_path / "LOG.md"
    log.write_text("")
    assert _read_consecutive_clean(log) == 0


def test_reads_zero_when_file_missing(tmp_path):
    assert _read_consecutive_clean(tmp_path / "nonexistent.md") == 0


def test_reads_value_from_plain_pattern(tmp_path):
    log = tmp_path / "LOG.md"
    log.write_text("consecutive_clean: 2\n")
    assert _read_consecutive_clean(log) == 2


def test_reads_value_from_bold_pattern(tmp_path):
    log = tmp_path / "LOG.md"
    log.write_text("**consecutive_clean:** 3\n")
    assert _read_consecutive_clean(log) == 3


def test_reads_last_value_when_multiple(tmp_path):
    log = tmp_path / "LOG.md"
    log.write_text("consecutive_clean: 1\nconsecutive_clean: 0\nconsecutive_clean: 2\n")
    assert _read_consecutive_clean(log) == 2


# --- validation_round integration tests ----------------------------------------

def test_clean_round_increments(tmp_path):
    log = tmp_path / "LOG.md"
    log.write_text("consecutive_clean: 0\n")
    result = validation_round(str(log), 1, {"LOW": 0}, False, 3)
    assert result["consecutive_clean"] == 1
    assert result["should_exit"] is False
    assert result["round_number"] == 1


def test_dirty_round_resets_to_zero(tmp_path):
    log = tmp_path / "LOG.md"
    log.write_text("consecutive_clean: 2\n")
    result = validation_round(str(log), 2, {"MEDIUM": 1}, False, 3)
    assert result["consecutive_clean"] == 0
    assert result["should_exit"] is False


def test_exit_at_threshold(tmp_path):
    log = tmp_path / "LOG.md"
    log.write_text("consecutive_clean: 2\n")
    result = validation_round(str(log), 3, {}, False, 3)
    assert result["consecutive_clean"] == 3
    assert result["should_exit"] is True


def test_exit_threshold_1(tmp_path):
    log = tmp_path / "LOG.md"
    log.write_text("consecutive_clean: 0\n")
    result = validation_round(str(log), 1, {}, False, 1)
    assert result["consecutive_clean"] == 1
    assert result["should_exit"] is True


def test_veto_prevents_increment(tmp_path, monkeypatch):
    import importlib
    vr_module = importlib.import_module("shamt_mcp.validation_round")

    # Patch _check_and_consume_veto to return True (veto active)
    monkeypatch.setattr(vr_module, "_check_and_consume_veto", lambda: True)
    log = tmp_path / "LOG.md"
    log.write_text("consecutive_clean: 1\n")
    result = validation_round(str(log), 2, {}, False, 3)
    # Veto: should not increment even though round is clean
    assert result["consecutive_clean"] == 1
    assert result["should_exit"] is False


def test_creates_log_if_absent(tmp_path):
    log = tmp_path / "new_LOG.md"
    result = validation_round(str(log), 1, {}, False, 1)
    assert log.exists()
    assert result["consecutive_clean"] == 1


def test_appends_structured_entry(tmp_path):
    log = tmp_path / "LOG.md"
    log.write_text("consecutive_clean: 0\n")
    validation_round(str(log), 1, {"LOW": 1}, True, 3)
    content = log.read_text()
    assert "MCP: validation_round" in content
    assert "consecutive_clean" in content
