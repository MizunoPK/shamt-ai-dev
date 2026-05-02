#!/usr/bin/env python3
"""
shamt-validate-pr.py — Shamt PR validation gate via Agents SDK

Runs on pull_request events (GitHub Actions or Azure Pipelines). For each
changed Shamt artifact drives a Codex session through the shamt-validation-loop
skill and aggregates the results into a PR comment.

Exits non-zero if any artifact failed validation.

Usage:
    python shamt-validate-pr.py [--provider=github|ado]

Environment variables:
    OPENAI_API_KEY            — API key for Codex/OpenAI (or ANTHROPIC_API_KEY)
    SHAMT_PR_PROVIDER         — "github" or "ado" (auto-detected if not set)

GitHub Actions (provider=github):
    GITHUB_TOKEN              — token with pull_requests: write
    GITHUB_EVENT_PATH         — path to the GitHub Actions event JSON
    GITHUB_REPOSITORY         — owner/repo

Azure Pipelines (provider=ado):
    AZURE_DEVOPS_PAT          — PAT with Contribute to pull requests permission, OR
    SYSTEM_ACCESSTOKEN        — pipeline built-in token (requires permission setup;
                                see .shamt/sdk/azure-pipelines/README.md)
    SYSTEM_COLLECTIONURI      — ADO org URL (set automatically by Azure Pipelines)
    SYSTEM_TEAMPROJECT        — ADO project name (set automatically)
    BUILD_REPOSITORY_NAME     — repository name (set automatically)
    SYSTEM_PULLREQUEST_PULLREQUESTID — PR ID (set automatically on PR builds)

Optional:
    SHAMT_VALIDATION_TIMEOUT  — max seconds per artifact validation (default: 300)
    SHAMT_SKIP_ARTIFACTS      — comma-separated glob patterns to skip
"""

import argparse
import json
import os
import subprocess
import sys
import textwrap
from datetime import datetime, timezone
from pathlib import Path

try:
    from openai import OpenAI
except ImportError:
    print("ERROR: Missing dependencies. Run: pip install -r .shamt/sdk/requirements.txt", file=sys.stderr)
    sys.exit(1)

try:
    from pr_provider import detect_provider, PRContext
except ImportError:
    sys.path.insert(0, str(Path(__file__).parent))
    from pr_provider import detect_provider, PRContext

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

TIMEOUT = int(os.environ.get("SHAMT_VALIDATION_TIMEOUT", "300"))
SKIP_PATTERNS = [
    p.strip() for p in os.environ.get("SHAMT_SKIP_ARTIFACTS", "").split(",") if p.strip()
]

ARTIFACT_PATTERNS = [
    "**/*_DESIGN.md",
    "**/*_VALIDATION_LOG.md",
    "**/*spec*.md",
    "**/*SPEC*.md",
    "**/AGENT_STATUS.md",
]

# ---------------------------------------------------------------------------
# Changed files
# ---------------------------------------------------------------------------

def get_changed_artifacts(base_sha: str, head_sha: str) -> list[Path]:
    """Return changed files matching ARTIFACT_PATTERNS, excluding SKIP_PATTERNS."""
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", base_sha, head_sha],
            capture_output=True, text=True, check=True
        )
    except subprocess.CalledProcessError as e:
        print(f"ERROR: git diff failed: {e.stderr}", file=sys.stderr)
        return []

    changed = [Path(p.strip()) for p in result.stdout.splitlines() if p.strip()]
    matched = []
    for path in changed:
        if not path.exists():
            continue
        if any(path.match(pat) for pat in SKIP_PATTERNS):
            continue
        if any(path.match(pat) for pat in ARTIFACT_PATTERNS):
            matched.append(path)
    return matched


# ---------------------------------------------------------------------------
# Validation via Agents SDK
# ---------------------------------------------------------------------------

def validate_artifact(client: OpenAI, artifact: Path) -> dict:
    content = artifact.read_text(encoding="utf-8")
    prompt = textwrap.dedent(f"""
        You are running Shamt validation on a changed artifact from a pull request.

        Artifact path: {artifact}

        Artifact content:
        ---
        {content[:8000]}{'...(truncated)' if len(content) > 8000 else ''}
        ---

        Apply the shamt-validation-loop skill. Check for:
        1. Internal consistency — does the document contradict itself?
        2. Completeness — are required sections present?
        3. Correctness — are cross-references and file paths accurate?
        4. If this is a VALIDATION_LOG: is consecutive_clean tracking correct?
        5. If this is a DESIGN.md: are Files Affected and implementation phases aligned?

        Report findings as:
        - Status: PASS or FAIL
        - Issues: list of (severity, description) pairs, or empty list if none
        - Summary: one sentence

        Respond in JSON:
        {{
          "status": "PASS" | "FAIL",
          "issues": [{{"severity": "LOW|MEDIUM|HIGH|CRITICAL", "description": "..."}}],
          "summary": "..."
        }}
    """).strip()

    try:
        response = client.chat.completions.create(
            model="o4-mini",
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"},
            timeout=TIMEOUT,
        )
        result = json.loads(response.choices[0].message.content)
        result["artifact"] = str(artifact)
        return result
    except Exception as e:
        return {
            "artifact": str(artifact),
            "status": "ERROR",
            "issues": [{"severity": "HIGH", "description": f"Validation session failed: {e}"}],
            "summary": f"Validation error: {e}",
        }


# ---------------------------------------------------------------------------
# Comment formatting
# ---------------------------------------------------------------------------

def build_comment(results: list[dict], ctx: PRContext) -> str:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    passed = sum(1 for r in results if r.get("status") == "PASS")
    failed = sum(1 for r in results if r.get("status") in ("FAIL", "ERROR"))
    total = len(results)

    status_emoji = "✅" if failed == 0 else "❌"
    lines = [
        f"## {status_emoji} Shamt Validation — {passed}/{total} artifacts passed",
        f"",
        f"**Run:** `{ctx.head_sha[:8]}` → `{ctx.base_ref}` — {ts}",
        f"",
    ]

    for r in results:
        art = r["artifact"]
        st = r.get("status", "ERROR")
        emoji = "✅" if st == "PASS" else "❌" if st == "FAIL" else "⚠️"
        lines.append(f"### {emoji} `{art}`")
        lines.append(f"**Status:** {st} — {r.get('summary', '')}")
        issues = r.get("issues", [])
        if issues:
            lines.append("")
            lines.append("**Issues:**")
            for issue in issues:
                lines.append(f"- **{issue['severity']}**: {issue['description']}")
        lines.append("")

    if failed > 0:
        lines.append("---")
        lines.append("_Fix the issues above and push again to re-run validation._")
    else:
        lines.append("---")
        lines.append("_All changed Shamt artifacts passed validation._")

    lines.append(f"_Generated by [shamt-validate-pr.py](../.shamt/sdk/shamt-validate-pr.py)_")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Shamt PR validation gate")
    parser.add_argument("--provider", choices=["github", "ado"], default="",
                        help="PR provider (auto-detected from env if not set)")
    args = parser.parse_args()

    provider = detect_provider(args.provider)
    ctx = provider.get_pr_context()

    if not ctx.pr_id:
        print("Not a pull_request event — nothing to validate.")
        sys.exit(0)

    print(f"Shamt PR validation: PR #{ctx.pr_id} ({ctx.head_sha[:8]}) [{type(provider).__name__}]")

    artifacts = get_changed_artifacts(ctx.base_sha, ctx.head_sha)
    if not artifacts:
        print("No Shamt artifacts changed in this PR.")
        try:
            provider.post_pr_comment(ctx.pr_id, "✅ **Shamt Validation** — no Shamt artifacts changed in this PR.")
        except Exception:
            pass
        sys.exit(0)

    print(f"Found {len(artifacts)} artifact(s) to validate:")
    for a in artifacts:
        print(f"  {a}")

    api_key = os.environ.get("OPENAI_API_KEY") or os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("ERROR: OPENAI_API_KEY (or ANTHROPIC_API_KEY) not set", file=sys.stderr)
        sys.exit(1)

    client = OpenAI(api_key=api_key)
    results = []
    for artifact in artifacts:
        print(f"Validating {artifact}...")
        result = validate_artifact(client, artifact)
        results.append(result)
        print(f"  → {result.get('status', 'ERROR')}: {result.get('summary', '')}")

    comment = build_comment(results, ctx)
    try:
        provider.post_pr_comment(ctx.pr_id, comment)
        print(f"Posted validation comment to PR #{ctx.pr_id}")
    except Exception as e:
        print(f"WARNING: Failed to post PR comment: {e}", file=sys.stderr)

    # Set PR status
    failed = sum(1 for r in results if r.get("status") in ("FAIL", "ERROR"))
    try:
        state = "failure" if failed else "success"
        desc = f"{len(results) - failed}/{len(results)} artifacts passed"
        provider.set_pr_status(ctx.pr_id, state, desc)
    except Exception as e:
        print(f"WARNING: Failed to set PR status: {e}", file=sys.stderr)

    if failed > 0:
        print(f"\n{failed}/{len(results)} artifact(s) failed validation.")
        sys.exit(1)

    print(f"\nAll {len(results)} artifact(s) passed validation.")
    sys.exit(0)


if __name__ == "__main__":
    main()
