"""Record a completed guide audit result for the pre-export-audit-gate hook."""

import json
from datetime import datetime, timezone
from pathlib import Path


def _project_root() -> Path:
    return Path(__file__).resolve().parents[4]


def audit_run(
    scope: str,
    consecutive_clean: int,
    exit_criterion_met: bool,
    issues_by_severity: dict,
    audited_at: str | None = None,
) -> dict:
    """
    Record the result of a completed guide audit.

    Writes `.shamt/audit/last_run.json` so the `pre-export-audit-gate.sh`
    hook can gate exports without re-running the audit.

    Parameters:
        scope: Path or label describing what was audited (e.g., ".shamt/guides/").
        consecutive_clean: Final consecutive_clean value when the audit exited.
        exit_criterion_met: True when 3 consecutive clean rounds were achieved.
        issues_by_severity: Dict of severity → count for the final round,
            e.g. {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0}.
        audited_at: ISO-8601 timestamp; defaults to now.

    Returns:
        {"recorded": True, "path": str, "exit_criterion_met": bool}
    """
    ts = audited_at or datetime.now(timezone.utc).isoformat()

    result = {
        "scope": scope,
        "consecutive_clean": consecutive_clean,
        "exit_criterion_met": exit_criterion_met,
        "issues_by_severity": {
            k: issues_by_severity.get(k, 0)
            for k in ("CRITICAL", "HIGH", "MEDIUM", "LOW")
        },
        "audited_at": ts,
    }

    out_dir = _project_root() / ".shamt" / "audit"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "last_run.json"
    out_path.write_text(json.dumps(result, indent=2) + "\n")

    return {"recorded": True, "path": str(out_path), "exit_criterion_met": exit_criterion_met}
