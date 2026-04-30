#!/usr/bin/env python3
"""
shamt-cron-janitor.py — Shamt stale-work scanner via Agents SDK

Runs on a weekly schedule (GitHub Actions cron). Scans for stale Shamt work:
  - design_docs/incoming/  — proposals older than 30 days
  - design_docs/active/    — design docs with no commit activity in N weeks
  - Child sync timestamps  — projects that haven't imported master in N weeks

Produces a digest file and optionally posts it as a GitHub issue.

Usage:
    python shamt-cron-janitor.py

Environment variables:
    GITHUB_TOKEN          — GitHub Actions token (issues: write for digest posting)
    GITHUB_REPOSITORY     — owner/repo
    OPENAI_API_KEY        — API key for Codex/OpenAI

Optional:
    SHAMT_INCOMING_MAX_DAYS    — max days for incoming proposals (default: 30)
    SHAMT_ACTIVE_MAX_WEEKS     — max weeks for active design docs without commits (default: 4)
    SHAMT_SYNC_MAX_WEEKS       — max weeks since last child import (default: 4)
    SHAMT_POST_ISSUE           — set to "true" to post digest as GitHub issue (default: false)
    SHAMT_DIGEST_PATH          — path to write digest file (default: .shamt/janitor-digest.md)
"""

import json
import os
import subprocess
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

try:
    from github import Github, GithubException
except ImportError:
    print("ERROR: Missing dependencies. Run: pip install -e .shamt/sdk", file=sys.stderr)
    sys.exit(1)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

INCOMING_MAX_DAYS = int(os.environ.get("SHAMT_INCOMING_MAX_DAYS", "30"))
ACTIVE_MAX_WEEKS = int(os.environ.get("SHAMT_ACTIVE_MAX_WEEKS", "4"))
SYNC_MAX_WEEKS = int(os.environ.get("SHAMT_SYNC_MAX_WEEKS", "4"))
POST_ISSUE = os.environ.get("SHAMT_POST_ISSUE", "false").lower() == "true"
DIGEST_PATH = Path(os.environ.get("SHAMT_DIGEST_PATH", ".shamt/janitor-digest.md"))

# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------

def git_last_commit_date(path: Path) -> datetime | None:
    """Return the date of the last commit touching path, or None."""
    try:
        result = subprocess.run(
            ["git", "log", "-1", "--format=%aI", "--", str(path)],
            capture_output=True, text=True, check=True
        )
        date_str = result.stdout.strip()
        if not date_str:
            return None
        return datetime.fromisoformat(date_str)
    except (subprocess.CalledProcessError, ValueError):
        return None


def file_age_days(path: Path) -> int | None:
    """Return file age in days based on last git commit, or None."""
    last_commit = git_last_commit_date(path)
    if not last_commit:
        return None
    now = datetime.now(timezone.utc)
    last_commit_utc = last_commit.astimezone(timezone.utc)
    return (now - last_commit_utc).days


# ---------------------------------------------------------------------------
# Scan functions
# ---------------------------------------------------------------------------

def scan_incoming_proposals() -> list[dict]:
    """Find proposals in design_docs/incoming/ older than INCOMING_MAX_DAYS."""
    incoming_dir = Path("design_docs/incoming")
    if not incoming_dir.exists():
        return []

    stale = []
    for proposal in sorted(incoming_dir.glob("*.md")):
        age = file_age_days(proposal)
        if age is not None and age > INCOMING_MAX_DAYS:
            stale.append({
                "path": str(proposal),
                "age_days": age,
                "type": "incoming_proposal",
                "reason": f"No activity for {age} days (threshold: {INCOMING_MAX_DAYS} days)",
            })
    return stale


def scan_active_design_docs() -> list[dict]:
    """Find active design docs with no commit activity in ACTIVE_MAX_WEEKS weeks."""
    active_dir = Path("design_docs/active")
    if not active_dir.exists():
        return []

    threshold_days = ACTIVE_MAX_WEEKS * 7
    stale = []
    for doc in sorted(active_dir.glob("*_DESIGN.md")):
        age = file_age_days(doc)
        if age is not None and age > threshold_days:
            stale.append({
                "path": str(doc),
                "age_days": age,
                "type": "stalled_design_doc",
                "reason": f"No commit activity for {age} days (threshold: {threshold_days} days / {ACTIVE_MAX_WEEKS} weeks)",
            })
    return stale


def scan_child_sync_timestamps() -> list[dict]:
    """Find .shamt/config/last_import.txt files older than SYNC_MAX_WEEKS weeks."""
    threshold_days = SYNC_MAX_WEEKS * 7
    stale = []

    # In the master repo, child sync timestamps are not tracked here.
    # In a child project, .shamt/config/last_import.txt is written by import.sh.
    sync_file = Path(".shamt/config/last_import.txt")
    if sync_file.exists():
        try:
            ts_str = sync_file.read_text().strip()
            ts = datetime.fromisoformat(ts_str)
            ts_utc = ts.astimezone(timezone.utc)
            age = (datetime.now(timezone.utc) - ts_utc).days
            if age > threshold_days:
                stale.append({
                    "path": str(sync_file),
                    "age_days": age,
                    "type": "stale_child_sync",
                    "reason": f"Last master import was {age} days ago (threshold: {threshold_days} days / {SYNC_MAX_WEEKS} weeks). Run import.sh to pull latest guides.",
                })
        except (ValueError, OSError):
            pass

    return stale


# ---------------------------------------------------------------------------
# Digest
# ---------------------------------------------------------------------------

def build_digest(findings: list[dict]) -> str:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    total = len(findings)

    lines = [
        f"# Shamt Janitor Digest — {ts}",
        f"",
        f"**Total stale items found:** {total}",
        f"",
    ]

    if total == 0:
        lines.append("No stale items found. Everything is up to date. ✅")
        return "\n".join(lines)

    # Group by type
    by_type: dict[str, list[dict]] = {}
    for f in findings:
        by_type.setdefault(f["type"], []).append(f)

    type_labels = {
        "incoming_proposal": f"Incoming Proposals (>{INCOMING_MAX_DAYS} days old)",
        "stalled_design_doc": f"Stalled Design Docs (>{ACTIVE_MAX_WEEKS} weeks without commits)",
        "stale_child_sync": f"Stale Child Sync (>{SYNC_MAX_WEEKS} weeks since last import)",
    }

    for type_key, items in by_type.items():
        label = type_labels.get(type_key, type_key)
        lines.append(f"## {label} ({len(items)})")
        lines.append("")
        for item in items:
            lines.append(f"- **`{item['path']}`** — {item['reason']}")
        lines.append("")

    lines.append("---")
    lines.append("_Generated by [shamt-cron-janitor.py](../.shamt/sdk/shamt-cron-janitor.py)_")
    return "\n".join(lines)


def post_github_issue(digest: str) -> None:
    token = os.environ.get("GITHUB_TOKEN")
    repo_name = os.environ.get("GITHUB_REPOSITORY", "")
    if not token or not repo_name:
        print("WARNING: GITHUB_TOKEN or GITHUB_REPOSITORY not set — skipping issue creation", file=sys.stderr)
        return

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    title = f"Shamt Janitor: stale work digest {ts}"

    try:
        gh = Github(token)
        repo = gh.get_repo(repo_name)

        # Close previous open janitor issues to avoid accumulation
        for issue in repo.get_issues(state="open", labels=["shamt-janitor"]):
            issue.edit(state="closed")

        issue = repo.create_issue(
            title=title,
            body=digest,
            labels=["shamt-janitor"],
        )
        print(f"Created GitHub issue #{issue.number}: {issue.html_url}")
    except GithubException as e:
        print(f"WARNING: Failed to create GitHub issue: {e}", file=sys.stderr)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print("Shamt Janitor: scanning for stale work...")

    findings = []
    findings.extend(scan_incoming_proposals())
    findings.extend(scan_active_design_docs())
    findings.extend(scan_child_sync_timestamps())

    digest = build_digest(findings)

    # Write digest file
    DIGEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    DIGEST_PATH.write_text(digest, encoding="utf-8")
    print(f"Digest written to {DIGEST_PATH}")

    print(digest)

    if POST_ISSUE and findings:
        post_github_issue(digest)
    elif POST_ISSUE and not findings:
        print("No stale items — skipping issue creation.")

    # Exit non-zero only on errors, not on stale findings
    # (stale work is a warning, not a CI failure)
    sys.exit(0)


if __name__ == "__main__":
    main()
