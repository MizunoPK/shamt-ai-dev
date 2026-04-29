"""Atomic SHAMT-N reservation via OS-level file locking."""

import os
import platform
from datetime import datetime, timezone
from pathlib import Path


def _project_root() -> Path:
    """Resolve project root from this file's location: .shamt/mcp/src/shamt_mcp/ → project root."""
    return Path(__file__).resolve().parents[4]


def next_number(number_file: Path | None = None) -> dict:
    """
    Atomically reserve the next SHAMT-N number.

    Reads design_docs/NEXT_NUMBER.txt, increments it, writes back under an
    exclusive OS-level lock to prevent concurrent reservation races.

    Returns:
        {"number": int, "reserved": True, "reserved_at": ISO-8601 timestamp}
    """
    if number_file is None:
        number_file = _project_root() / "design_docs" / "NEXT_NUMBER.txt"

    if not number_file.exists():
        raise FileNotFoundError(f"NEXT_NUMBER.txt not found: {number_file}")

    if platform.system() == "Windows":
        return _next_number_windows(number_file)
    else:
        return _next_number_unix(number_file)


def _next_number_unix(number_file: Path) -> dict:
    import fcntl

    with open(number_file, "r+") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        try:
            raw = f.read().strip()
            current = int(raw)
            next_n = current + 1
            f.seek(0)
            f.write(f"{next_n}\n")
            f.truncate()
        finally:
            fcntl.flock(f, fcntl.LOCK_UN)

    return {
        "number": current,
        "reserved": True,
        "reserved_at": datetime.now(timezone.utc).isoformat(),
    }


def _next_number_windows(number_file: Path) -> dict:
    import msvcrt

    with open(number_file, "r+b") as f:
        # Lock the first 1 byte exclusively
        msvcrt.locking(f.fileno(), msvcrt.LK_NBLCK, 1)
        try:
            raw = f.read().decode().strip()
            current = int(raw)
            next_n = current + 1
            f.seek(0)
            f.write(f"{next_n}\n".encode())
            f.truncate()
        finally:
            f.seek(0)
            msvcrt.locking(f.fileno(), msvcrt.LK_UNLCK, 1)

    return {
        "number": current,
        "reserved": True,
        "reserved_at": datetime.now(timezone.utc).isoformat(),
    }
