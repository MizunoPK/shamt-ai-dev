"""
Shamt MCP server.

Exposes two tools:
  shamt.next_number()       — atomic SHAMT-N reservation
  shamt.validation_round()  — structured round-log append + consecutive_clean tracking

Usage (stdio, default):
    python -m shamt_mcp

Usage (HTTP, SHAMT-43):
    python -m shamt_mcp --http
"""

import argparse
import sys

from mcp.server.fastmcp import FastMCP

from .next_number import next_number as _next_number
from .validation_round import validation_round as _validation_round

mcp = FastMCP("shamt")


@mcp.tool()
def next_number() -> dict:
    """
    Atomically reserve the next SHAMT-N design-doc number.

    Reads design_docs/NEXT_NUMBER.txt, increments it under an OS-level
    exclusive lock, and returns the reserved number.

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
        log_path: Path to the *_VALIDATION_LOG.md file (absolute or
            repo-relative).
        round: 1-based round number being recorded.
        severity_counts: Dict of severity → count, e.g.
            {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 1}.
        fixed: True when exactly 1 LOW issue was found and immediately fixed
            (the "1-LOW-fixed" clean-round exception). Ignored for all other
            severity combinations.
        exit_threshold: consecutive_clean value at which should_exit becomes
            True. Default 1 for validation loops; pass 3 for guide audits.

    Returns:
        round_number (int): The round number recorded.
        consecutive_clean (int): Updated consecutive clean count.
        should_exit (bool): True when consecutive_clean >= exit_threshold.
    """
    return _validation_round(
        log_path=log_path,
        round=round,
        severity_counts=severity_counts,
        fixed=fixed,
        exit_threshold=exit_threshold,
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="shamt-mcp",
        description="Shamt MCP server (next_number + validation_round)",
    )
    parser.add_argument(
        "--http",
        action="store_true",
        help="Run as HTTP server (for Codex Cloud — activates in SHAMT-43; not yet implemented)",
    )
    args = parser.parse_args()

    if args.http:
        # HTTP transport scaffold — SHAMT-43 activates this entrypoint
        print(
            "HTTP transport is not yet implemented. See SHAMT-43.",
            file=sys.stderr,
        )
        sys.exit(1)

    mcp.run(transport="stdio")


if __name__ == "__main__":
    main()
