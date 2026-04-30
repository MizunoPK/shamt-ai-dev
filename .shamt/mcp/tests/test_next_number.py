"""Tests for next_number — atomic SHAMT-N reservation."""

import threading
from pathlib import Path

import pytest

from shamt_mcp.next_number import next_number


@pytest.fixture()
def number_file(tmp_path):
    f = tmp_path / "NEXT_NUMBER.txt"
    f.write_text("10\n")
    return f


def test_reserves_current_and_increments(number_file):
    result = next_number(number_file)
    assert result["number"] == 10
    assert result["reserved"] is True
    assert "reserved_at" in result
    assert number_file.read_text().strip() == "11"


def test_sequential_calls_return_distinct_numbers(number_file):
    r1 = next_number(number_file)
    r2 = next_number(number_file)
    r3 = next_number(number_file)
    assert r1["number"] == 10
    assert r2["number"] == 11
    assert r3["number"] == 12
    assert number_file.read_text().strip() == "13"


def test_raises_on_missing_file(tmp_path):
    with pytest.raises(FileNotFoundError):
        next_number(tmp_path / "nonexistent.txt")


def test_concurrent_reservations_are_unique(number_file):
    """Simulate concurrent calls and verify no duplicates under threading."""
    results = []
    errors = []

    def reserve():
        try:
            results.append(next_number(number_file))
        except Exception as e:
            errors.append(e)

    threads = [threading.Thread(target=reserve) for _ in range(10)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert not errors, f"Errors during concurrent access: {errors}"
    numbers = [r["number"] for r in results]
    assert len(numbers) == len(set(numbers)), f"Duplicate reservations: {numbers}"
    assert sorted(numbers) == list(range(10, 20))
