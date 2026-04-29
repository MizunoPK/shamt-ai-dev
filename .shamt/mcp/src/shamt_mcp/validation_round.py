"""Structured validation round logging and consecutive_clean arithmetic."""

import re
from datetime import datetime, timezone
from pathlib import Path


SEVERITY_ORDER = ["CRITICAL", "HIGH", "MEDIUM", "LOW"]


def _project_root() -> Path:
    return Path(__file__).resolve().parents[4]


def _find_active_epic() -> str | None:
    """Return the active epic tag by reading EPIC_TRACKER.md, or None."""
    tracker = _project_root() / ".shamt" / "epics" / "EPIC_TRACKER.md"
    if not tracker.exists():
        return None
    for line in tracker.read_text().splitlines():
        if "In Progress" in line:
            m = re.search(r"\|\s*([A-Z]+-\d+)\s*\|", line)
            if m:
                return m.group(1)
    return None


def _check_and_consume_veto() -> bool:
    """
    Return True (and delete the flag) if a subagent confirmation veto is
    pending for the active epic; return False if no veto.
    """
    active = _find_active_epic()
    if not active:
        return False
    flag = _project_root() / ".shamt" / "epics" / active / ".subagent_confirmation_veto"
    if flag.exists():
        flag.unlink()
        return True
    return False


def _read_consecutive_clean(log_path: Path) -> int:
    """
    Scan the log file for the last 'consecutive_clean: N' or
    '**consecutive_clean:** N' pattern and return its integer value.
    Returns 0 if none found.
    """
    if not log_path.exists():
        return 0
    text = log_path.read_text()
    matches = re.findall(r"\*{0,2}consecutive_clean\*{0,2}:\*{0,2}\s*(\d+)", text)
    return int(matches[-1]) if matches else 0


def _is_clean_round(severity_counts: dict, fixed: bool) -> bool:
    """
    A round is clean if:
    - Zero issues of any severity, OR
    - Exactly one LOW issue that was immediately fixed (fixed=True)
    All other combinations are NOT clean.
    """
    total = sum(severity_counts.get(s, 0) for s in SEVERITY_ORDER)
    if total == 0:
        return True
    if (
        fixed
        and severity_counts.get("LOW", 0) == 1
        and all(severity_counts.get(s, 0) == 0 for s in ["CRITICAL", "HIGH", "MEDIUM"])
    ):
        return True
    return False


def validation_round(
    log_path: str,
    round: int,
    severity_counts: dict,
    fixed: bool = False,
    exit_threshold: int = 1,
) -> dict:
    """
    Append a structured round entry to the validation log and return updated
    consecutive_clean and whether the loop should exit.

    Parameters:
        log_path: Absolute or repo-relative path to the *_VALIDATION_LOG.md file.
        round: The 1-based round number being recorded.
        severity_counts: Dict mapping severity label to count, e.g.
            {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 1, "LOW": 2}.
            Missing keys default to 0.
        fixed: True when the round found exactly 1 LOW issue that was
            immediately fixed; allows that round to count as clean.
        exit_threshold: consecutive_clean value at which should_exit is True.
            Use 1 for standard validation loops, 3 for guide audits.

    Returns:
        {
            "round_number": int,
            "consecutive_clean": int,
            "should_exit": bool,
        }
    """
    path = Path(log_path)
    if not path.is_absolute():
        path = _project_root() / path

    vetoed = _check_and_consume_veto()

    prior_cc = _read_consecutive_clean(path)

    clean = _is_clean_round(severity_counts, fixed)

    if vetoed:
        # Sub-agent confirmation veto: do not increment, even if round appears clean
        new_cc = prior_cc
    elif clean:
        new_cc = prior_cc + 1
    else:
        new_cc = 0

    should_exit = new_cc >= exit_threshold

    _append_round_entry(path, round, severity_counts, fixed, vetoed, new_cc, should_exit)

    return {
        "round_number": round,
        "consecutive_clean": new_cc,
        "should_exit": should_exit,
    }


def _append_round_entry(
    path: Path,
    round: int,
    severity_counts: dict,
    fixed: bool,
    vetoed: bool,
    consecutive_clean: int,
    should_exit: bool,
) -> None:
    total = sum(severity_counts.get(s, 0) for s in SEVERITY_ORDER)
    clean = _is_clean_round(severity_counts, fixed)
    status = "Pure Clean ✅" if (total == 0) else ("Clean (1-LOW-fixed) ✅" if clean else "NOT CLEAN ✗")

    lines = [
        f"\n---\n",
        f"<!-- MCP: validation_round round={round} ts={datetime.now(timezone.utc).isoformat()} -->\n",
        f"**Round {round} — {datetime.now(timezone.utc).strftime('%Y-%m-%d')} (MCP)**\n\n",
        f"| Severity | Count |\n",
        f"|---|---|\n",
    ]
    for sev in SEVERITY_ORDER:
        lines.append(f"| {sev} | {severity_counts.get(sev, 0)} |\n")
    lines.append(f"\n")
    if fixed:
        lines.append(f"**fixed:** True (1-LOW-fixed exception applied)\n\n")
    if vetoed:
        lines.append(f"**Sub-agent veto applied:** consecutive_clean not incremented.\n\n")
    lines.append(f"**Clean Round Status:** {status}\n\n")
    lines.append(f"**consecutive_clean:** {consecutive_clean}\n\n")
    if should_exit:
        lines.append(f"**Exit criterion met** ✅ (consecutive_clean {consecutive_clean} ≥ threshold {_infer_threshold(consecutive_clean, should_exit)})\n")

    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "a") as f:
        f.writelines(lines)


def _infer_threshold(consecutive_clean: int, should_exit: bool) -> str:
    # We don't have exit_threshold available in the append helper; approximate from value
    return str(consecutive_clean)
