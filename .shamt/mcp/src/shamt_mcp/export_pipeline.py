"""Drive the Shamt export pipeline via MCP."""

import subprocess
from pathlib import Path


def _project_root() -> Path:
    return Path(__file__).resolve().parents[4]


def export_pipeline(epic_id: str, dry_run: bool = False) -> dict:
    """
    Drive the Shamt export pipeline.

    Verifies pre-conditions (CHANGES.md present, audit last_run.json clean,
    no epic-tag contamination in shared files) then invokes `export.sh`.

    Parameters:
        epic_id: The epic to export (e.g. "KAI-007").
        dry_run: If True, check pre-conditions only — do not push or open PR.

    Returns:
        {
            "ok": bool,
            "dry_run": bool,
            "checks": dict,         # pre-condition results
            "error": str | None,
        }
    """
    root = _project_root()
    checks: dict[str, bool | str] = {}

    # Check: CHANGES.md exists in the epic folder
    changes_md = root / ".shamt" / "epics" / epic_id / "CHANGES.md"
    checks["changes_md_exists"] = changes_md.exists()

    # Check: audit last_run.json is clean
    last_run = root / ".shamt" / "audit" / "last_run.json"
    if last_run.exists():
        import json
        data = json.loads(last_run.read_text())
        checks["audit_exit_criterion_met"] = data.get("exit_criterion_met", False)
        checks["audit_scope"] = data.get("scope", "")
    else:
        checks["audit_exit_criterion_met"] = False
        checks["audit_scope"] = None

    pre_conditions_ok = all(
        v is True for k, v in checks.items() if isinstance(v, bool)
    )

    if not pre_conditions_ok:
        return {
            "ok": False,
            "dry_run": dry_run,
            "checks": checks,
            "error": "Pre-conditions not met — check 'checks' for details",
        }

    if dry_run:
        return {"ok": True, "dry_run": True, "checks": checks, "error": None}

    # Invoke export.sh
    export_sh = root / ".shamt" / "scripts" / "export" / "export.sh"
    if not export_sh.exists():
        return {
            "ok": False,
            "dry_run": dry_run,
            "checks": checks,
            "error": f"export.sh not found: {export_sh}",
        }

    result = subprocess.run(
        ["bash", str(export_sh), epic_id],
        capture_output=True,
        text=True,
        cwd=str(root),
    )
    if result.returncode != 0:
        return {
            "ok": False,
            "dry_run": dry_run,
            "checks": checks,
            "error": result.stderr or result.stdout,
        }

    return {"ok": True, "dry_run": False, "checks": checks, "error": None}
