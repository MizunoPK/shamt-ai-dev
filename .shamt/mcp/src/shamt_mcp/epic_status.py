"""Structured snapshot of the active epic's stage/phase/blocker state."""

import re
from pathlib import Path


def _project_root() -> Path:
    return Path(__file__).resolve().parents[4]


def _parse_tracker(tracker_path: Path) -> list[dict]:
    """Parse EPIC_TRACKER.md rows into dicts."""
    epics = []
    if not tracker_path.exists():
        return epics
    for line in tracker_path.read_text().splitlines():
        # Match table rows: | EPIC-N | name | S? | status |
        m = re.match(r"\|\s*([A-Z]+-\d+)\s*\|\s*([^|]+)\|\s*([^|]+)\|\s*([^|]+)\|", line)
        if m:
            epics.append({
                "id": m.group(1).strip(),
                "name": m.group(2).strip(),
                "stage": m.group(3).strip(),
                "status": m.group(4).strip(),
            })
    return epics


def _read_agent_status(epic_id: str) -> dict:
    root = _project_root()
    # Try .shamt/epics/<epic_id>/AGENT_STATUS.md
    status_file = root / ".shamt" / "epics" / epic_id / "AGENT_STATUS.md"
    if not status_file.exists():
        return {}
    text = status_file.read_text()
    result = {}
    for key, pattern in [
        ("stage", r"Stage:\s*(\S+)"),
        ("phase", r"Phase:\s*(\S+)"),
        ("step", r"Step:\s*(.+)"),
        ("blocker", r"Blocker:\s*(.+)"),
        ("consecutive_clean", r"consecutive_clean:\s*(\d+)"),
    ]:
        m = re.search(pattern, text, re.IGNORECASE)
        if m:
            val = m.group(1).strip()
            result[key] = int(val) if key == "consecutive_clean" else val
    return result


def epic_status(epic_id: str = "active") -> dict:
    """
    Return a structured snapshot of an epic's current state.

    Parameters:
        epic_id: The epic identifier (e.g. "KAI-007") or "active" to auto-detect
            from EPIC_TRACKER.md.

    Returns:
        {
            "epic_id": str,
            "name": str,
            "stage": str,
            "phase": str,
            "step": str,
            "blocker": str,
            "consecutive_clean": int,
            "status": str,          # tracker row status
            "found": bool,
        }
    """
    root = _project_root()
    tracker = root / ".shamt" / "epics" / "EPIC_TRACKER.md"
    epics = _parse_tracker(tracker)

    if epic_id == "active":
        active = next((e for e in epics if "progress" in e["status"].lower()), None)
        if not active:
            return {"found": False, "epic_id": None, "error": "No epic in progress"}
        epic_id = active["id"]
        tracker_row = active
    else:
        tracker_row = next((e for e in epics if e["id"] == epic_id), {})

    agent = _read_agent_status(epic_id)

    return {
        "found": True,
        "epic_id": epic_id,
        "name": tracker_row.get("name", ""),
        "stage": agent.get("stage") or tracker_row.get("stage", ""),
        "phase": agent.get("phase", ""),
        "step": agent.get("step", ""),
        "blocker": agent.get("blocker", "none"),
        "consecutive_clean": agent.get("consecutive_clean", 0),
        "status": tracker_row.get("status", ""),
    }
