"""
Shamt MCP server.

Exposes seven tools:
  shamt.next_number()       — atomic SHAMT-N reservation
  shamt.validation_round()  — structured round-log append + consecutive_clean tracking
  shamt.audit_run()         — record completed guide audit result for export gate
  shamt.epic_status()       — structured snapshot of active epic stage/phase/blocker
  shamt.metrics_append()    — emit Shamt-domain metric to sidecar log + OTel
  shamt.export_pipeline()   — drive export pipeline with pre-condition checks
  shamt.import_pipeline()   — drive import pipeline

Usage (stdio, default):
    python -m shamt_mcp

Usage (HTTP, port 7400 — for Codex Cloud):
    python -m shamt_mcp --http [--port PORT] [--host HOST]
"""

import argparse
import sys

from mcp.server.fastmcp import FastMCP

from .audit_run import audit_run as _audit_run
from .epic_status import epic_status as _epic_status
from .export_pipeline import export_pipeline as _export_pipeline
from .import_pipeline import import_pipeline as _import_pipeline
from .metrics_append import metrics_append as _metrics_append
from .next_number import next_number as _next_number
from .validation_round import validation_round as _validation_round

mcp = FastMCP("shamt")


@mcp.tool()
def next_number() -> dict:
    """
    Atomically reserve the next SHAMT-N design-doc number.

    Returns:
        number (int): The reserved SHAMT-N number (use this one).
        reserved (bool): Always True on success.
        reserved_at (str): ISO-8601 UTC timestamp of reservation.
    """
    return _next_number()


@mcp.tool()
def validation_round(
    log_path: str,
    round: int,
    severity_counts: dict,
    fixed: bool = False,
    exit_threshold: int = 1,
) -> dict:
    """
    Append a structured round entry to a validation log and return updated
    consecutive_clean state.

    Parameters:
        log_path: Path to the *_VALIDATION_LOG.md file (absolute or repo-relative).
        round: 1-based round number being recorded.
        severity_counts: Dict of severity → count, e.g.
            {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 1}.
        fixed: True when exactly 1 LOW issue was found and immediately fixed.
        exit_threshold: consecutive_clean value at which should_exit becomes True.
            Default 1 for validation loops; pass 3 for guide audits.

    Returns:
        round_number (int), consecutive_clean (int), should_exit (bool).
    """
    return _validation_round(
        log_path=log_path,
        round=round,
        severity_counts=severity_counts,
        fixed=fixed,
        exit_threshold=exit_threshold,
    )


@mcp.tool(name="audit_run")
def _tool_audit_run(
    scope: str,
    consecutive_clean: int,
    exit_criterion_met: bool,
    issues_by_severity: dict,
    audited_at: str | None = None,
) -> dict:
    """
    Record a completed guide audit result.

    Writes .shamt/audit/last_run.json for the pre-export-audit-gate hook.

    Parameters:
        scope: What was audited (e.g., ".shamt/guides/").
        consecutive_clean: Final consecutive_clean value when audit exited.
        exit_criterion_met: True when 3 consecutive clean rounds were achieved.
        issues_by_severity: Final round severity counts.
        audited_at: ISO-8601 timestamp; defaults to now.

    Returns:
        recorded (bool), path (str), exit_criterion_met (bool).
    """
    return _audit_run(
        scope=scope,
        consecutive_clean=consecutive_clean,
        exit_criterion_met=exit_criterion_met,
        issues_by_severity=issues_by_severity,
        audited_at=audited_at,
    )


@mcp.tool(name="epic_status")
def _tool_epic_status(epic_id: str = "active") -> dict:
    """
    Return a structured snapshot of an epic's current state.

    Parameters:
        epic_id: Epic identifier (e.g. "KAI-007") or "active" to auto-detect.

    Returns:
        epic_id, name, stage, phase, step, blocker, consecutive_clean, status, found.
    """
    return _epic_status(epic_id=epic_id)


@mcp.tool(name="metrics_append")
def _tool_metrics_append(
    metric_name: str,
    value: float,
    labels: dict,
    epic_id: str | None = None,
) -> dict:
    """
    Emit a Shamt-domain metric event to the sidecar log and optionally OTel.

    Validates labels against a per-metric permit-list to prevent cardinality
    explosion. Unknown labels are rejected with accepted=False.

    Parameters:
        metric_name: Permitted metric name (validation_round, audit_round,
            builder_step, builder_runs_total, confirmer_run, shamt_session_active,
            shamt_tokens_saved, shamt_tool_calls).
        value: Numeric value (counter increment, gauge, or duration_ms).
        labels: Label key→value dict. Must match the metric's permit-list.
        epic_id: Optional epic identifier attached to the event.

    Returns:
        accepted (bool), metric_name (str), rejected_labels (list[str]).
    """
    return _metrics_append(
        metric_name=metric_name,
        value=value,
        labels=labels,
        epic_id=epic_id,
    )


@mcp.tool(name="export_pipeline")
def _tool_export_pipeline(epic_id: str, dry_run: bool = False) -> dict:
    """
    Drive the Shamt export pipeline with pre-condition checks.

    Verifies CHANGES.md exists and audit is clean before invoking export.sh.

    Parameters:
        epic_id: Epic to export (e.g. "KAI-007").
        dry_run: If True, check pre-conditions only — do not push or open PR.

    Returns:
        ok (bool), dry_run (bool), checks (dict), error (str | None).
    """
    return _export_pipeline(epic_id=epic_id, dry_run=dry_run)


@mcp.tool(name="import_pipeline")
def _tool_import_pipeline(dry_run: bool = False) -> dict:
    """
    Drive the Shamt import pipeline.

    Parameters:
        dry_run: If True, fetch and diff only — do not apply changes.

    Returns:
        ok (bool), dry_run (bool), changed_files (list[str]), error (str | None).
    """
    return _import_pipeline(dry_run=dry_run)


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="shamt-mcp",
        description="Shamt MCP server",
    )
    parser.add_argument(
        "--http",
        action="store_true",
        help="Run as HTTP server (for Codex Cloud containers)",
    )
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="HTTP bind host (default: 0.0.0.0)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=7400,
        help="HTTP bind port (default: 7400)",
    )
    args = parser.parse_args()

    if args.http:
        import uvicorn

        # FastMCP streamable-HTTP transport (MCP 1.x)
        app = mcp.streamable_http_app()
        uvicorn.run(app, host=args.host, port=args.port)
    else:
        mcp.run(transport="stdio")


if __name__ == "__main__":
    main()
