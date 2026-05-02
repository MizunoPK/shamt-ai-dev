"""
pr_provider.py — PR provider abstraction for Shamt SDK scripts

Defines PRProvider protocol + GitHubProvider + AzureDevOpsProvider.

Provider auto-detection from CI environment:
    GitHub Actions:  GITHUB_ACTIONS=true
    Azure Pipelines: TF_BUILD=True

Explicit override via --provider=github|ado CLI flag or SHAMT_PR_PROVIDER env var.
"""

from __future__ import annotations

import base64
import json
import os
import urllib.request
import urllib.parse
from dataclasses import dataclass, field
from typing import Protocol, runtime_checkable


# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------

@dataclass
class PRContext:
    pr_id: str
    repo: str
    base_sha: str
    head_sha: str
    base_ref: str
    head_ref: str
    org: str = ""
    project: str = ""


@dataclass
class ChangedFile:
    path: str
    diff: str = ""


@dataclass
class CommentResult:
    comment_id: str
    url: str = ""


@dataclass
class CommentThread:
    thread_id: str
    status: str
    comments: list[str] = field(default_factory=list)
    file_path: str = ""


# ---------------------------------------------------------------------------
# Protocol
# ---------------------------------------------------------------------------

@runtime_checkable
class PRProvider(Protocol):
    """Minimal interface for PR operations used by Shamt SDK scripts."""

    def get_pr_context(self) -> PRContext: ...
    def get_pr_diff(self, pr_id: str) -> list[ChangedFile]: ...
    def post_pr_comment(self, pr_id: str, body: str) -> CommentResult: ...
    def post_file_comment(self, pr_id: str, file_path: str,
                          line: int, body: str) -> CommentResult: ...
    def get_pr_threads(self, pr_id: str) -> list[CommentThread]: ...
    def set_pr_status(self, pr_id: str, state: str, description: str) -> None: ...


# ---------------------------------------------------------------------------
# GitHub implementation
# ---------------------------------------------------------------------------

class GitHubProvider:
    def __init__(self) -> None:
        try:
            from github import Github, GithubException
            self._Github = Github
            self._GithubException = GithubException
        except ImportError:
            raise RuntimeError("PyGithub not installed. Run: pip install -e .shamt/sdk")

        self._token = os.environ.get("GITHUB_TOKEN", "")
        self._repo_name = os.environ.get("GITHUB_REPOSITORY", "")
        self._gh = self._Github(self._token) if self._token else self._Github()

    def get_pr_context(self) -> PRContext:
        import json
        from pathlib import Path
        event_path = os.environ.get("GITHUB_EVENT_PATH", "")
        if not event_path or not Path(event_path).exists():
            raise RuntimeError("GITHUB_EVENT_PATH not set or file not found")
        with open(event_path) as f:
            event = json.load(f)
        pr = event.get("pull_request", {})
        return PRContext(
            pr_id=str(pr.get("number", "")),
            repo=self._repo_name,
            base_sha=pr.get("base", {}).get("sha", "HEAD~1"),
            head_sha=pr.get("head", {}).get("sha", "HEAD"),
            base_ref=pr.get("base", {}).get("ref", "main"),
            head_ref=pr.get("head", {}).get("ref", ""),
        )

    def get_pr_diff(self, pr_id: str) -> list[ChangedFile]:
        import subprocess
        ctx = self.get_pr_context()
        try:
            result = subprocess.run(
                ["git", "diff", "--name-only", ctx.base_sha, ctx.head_sha],
                capture_output=True, text=True, check=True
            )
            return [ChangedFile(path=p.strip()) for p in result.stdout.splitlines() if p.strip()]
        except subprocess.CalledProcessError:
            return []

    def post_pr_comment(self, pr_id: str, body: str) -> CommentResult:
        try:
            repo = self._gh.get_repo(self._repo_name)
            pr = repo.get_pull(int(pr_id))
            # Remove previous shamt comment if present
            for c in pr.get_issue_comments():
                if "shamt-validate-pr.py" in (c.body or ""):
                    c.delete()
                    break
            comment = pr.create_issue_comment(body)
            return CommentResult(comment_id=str(comment.id), url=comment.html_url)
        except self._GithubException as e:
            raise RuntimeError(f"GitHub API error: {e}") from e

    def post_file_comment(self, pr_id: str, file_path: str,
                          line: int, body: str) -> CommentResult:
        try:
            repo = self._gh.get_repo(self._repo_name)
            pr = repo.get_pull(int(pr_id))
            ctx = self.get_pr_context()
            comment = pr.create_review_comment(body, ctx.head_sha, file_path, line)
            return CommentResult(comment_id=str(comment.id), url=comment.html_url)
        except self._GithubException as e:
            raise RuntimeError(f"GitHub API error: {e}") from e

    def get_pr_threads(self, pr_id: str) -> list[CommentThread]:
        try:
            repo = self._gh.get_repo(self._repo_name)
            pr = repo.get_pull(int(pr_id))
            threads = []
            for c in pr.get_review_comments():
                threads.append(CommentThread(
                    thread_id=str(c.id),
                    status="active",
                    comments=[c.body or ""],
                    file_path=c.path or "",
                ))
            return threads
        except self._GithubException as e:
            raise RuntimeError(f"GitHub API error: {e}") from e

    def set_pr_status(self, pr_id: str, state: str, description: str) -> None:
        try:
            repo = self._gh.get_repo(self._repo_name)
            ctx = self.get_pr_context()
            commit = repo.get_commit(ctx.head_sha)
            commit.create_status(
                state=state,
                description=description,
                context="shamt-validate-pr",
            )
        except self._GithubException as e:
            raise RuntimeError(f"GitHub API error: {e}") from e


# ---------------------------------------------------------------------------
# Azure DevOps implementation
# ---------------------------------------------------------------------------

class AzureDevOpsProvider:
    """
    Azure DevOps implementation using ADO REST API 7.1.

    Credentials:
        AZURE_DEVOPS_PAT     — Personal Access Token (preferred)
        SYSTEM_ACCESSTOKEN   — Azure Pipelines built-in token (requires
                               'Contribute to pull requests' permission on the
                               build service account + 'Allow scripts to access
                               the OAuth token' enabled on the pipeline job)
    """

    _API_VERSION = "api-version=7.1"

    def __init__(self) -> None:
        pat = os.environ.get("AZURE_DEVOPS_PAT") or os.environ.get("SYSTEM_ACCESSTOKEN", "")
        if not pat:
            raise RuntimeError(
                "AZURE_DEVOPS_PAT or SYSTEM_ACCESSTOKEN must be set for ADO provider"
            )
        self._auth = base64.b64encode(f":{pat}".encode()).decode()

        self._org_url = self._resolve_org_url()
        self._project = self._resolve_project()
        self._repo = self._resolve_repo()
        self._pr_id = self._resolve_pr_id()

    def _resolve_org_url(self) -> str:
        uri = os.environ.get("SYSTEM_COLLECTIONURI", "")
        if uri:
            return uri.rstrip("/")
        raise RuntimeError("SYSTEM_COLLECTIONURI not set — required for ADO provider in Azure Pipelines")

    def _resolve_project(self) -> str:
        return os.environ.get("SYSTEM_TEAMPROJECT", "")

    def _resolve_repo(self) -> str:
        return os.environ.get("BUILD_REPOSITORY_NAME", "")

    def _resolve_pr_id(self) -> str:
        return os.environ.get("SYSTEM_PULLREQUEST_PULLREQUESTID", "")

    def _request(self, method: str, url: str, body: dict | None = None) -> dict:
        data = json.dumps(body).encode() if body is not None else None
        headers = {
            "Authorization": f"Basic {self._auth}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req) as resp:
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            body_text = e.read().decode(errors="replace")
            raise RuntimeError(f"ADO API {method} {url} → HTTP {e.code}: {body_text}") from e

    def _pr_base_url(self, pr_id: str) -> str:
        return (
            f"{self._org_url}/{urllib.parse.quote(self._project)}/_apis/git"
            f"/repositories/{urllib.parse.quote(self._repo)}/pullrequests/{pr_id}"
        )

    def get_pr_context(self) -> PRContext:
        if not self._pr_id:
            raise RuntimeError("SYSTEM_PULLREQUEST_PULLREQUESTID not set — not a PR build")
        url = f"{self._pr_base_url(self._pr_id)}?{self._API_VERSION}"
        pr = self._request("GET", url)
        return PRContext(
            pr_id=self._pr_id,
            repo=self._repo,
            base_sha=pr.get("lastMergeTargetCommit", {}).get("commitId", ""),
            head_sha=pr.get("lastMergeSourceCommit", {}).get("commitId", ""),
            base_ref=pr.get("targetRefName", "").replace("refs/heads/", ""),
            head_ref=pr.get("sourceRefName", "").replace("refs/heads/", ""),
            org=self._org_url,
            project=self._project,
        )

    def get_pr_diff(self, pr_id: str) -> list[ChangedFile]:
        url = (
            f"{self._pr_base_url(pr_id)}/iterations?{self._API_VERSION}"
        )
        iterations = self._request("GET", url).get("value", [])
        if not iterations:
            return []
        latest_iter = iterations[-1]["id"]
        changes_url = (
            f"{self._pr_base_url(pr_id)}/iterations/{latest_iter}"
            f"/changes?{self._API_VERSION}"
        )
        data = self._request("GET", changes_url)
        files = []
        for change in data.get("changeEntries", []):
            item = change.get("item", {})
            path = item.get("path", "").lstrip("/")
            if path:
                files.append(ChangedFile(path=path))
        return files

    def post_pr_comment(self, pr_id: str, body: str) -> CommentResult:
        url = f"{self._pr_base_url(pr_id)}/threads?{self._API_VERSION}"
        payload = {
            "comments": [{"parentCommentId": 0, "content": body, "commentType": 1}],
            "status": "closed",
        }
        result = self._request("POST", url, payload)
        thread_id = str(result.get("id", ""))
        return CommentResult(comment_id=thread_id)

    def post_file_comment(self, pr_id: str, file_path: str,
                          line: int, body: str) -> CommentResult:
        url = f"{self._pr_base_url(pr_id)}/threads?{self._API_VERSION}"
        payload = {
            "comments": [{"parentCommentId": 0, "content": body, "commentType": 1}],
            "status": "active",
            "threadContext": {
                "filePath": f"/{file_path}",
                "rightFileStart": {"line": line, "offset": 1},
                "rightFileEnd": {"line": line, "offset": 1},
            },
        }
        result = self._request("POST", url, payload)
        thread_id = str(result.get("id", ""))
        return CommentResult(comment_id=thread_id)

    def get_pr_threads(self, pr_id: str) -> list[CommentThread]:
        url = f"{self._pr_base_url(pr_id)}/threads?{self._API_VERSION}"
        data = self._request("GET", url)
        threads = []
        for t in data.get("value", []):
            comments = [c.get("content", "") for c in t.get("comments", [])]
            threads.append(CommentThread(
                thread_id=str(t.get("id", "")),
                status=_ado_thread_status(t.get("status", 1)),
                comments=comments,
                file_path=(t.get("threadContext") or {}).get("filePath", "").lstrip("/"),
            ))
        return threads

    def set_pr_status(self, pr_id: str, state: str, description: str) -> None:
        # ADO status state mapping: GitHub "success"/"failure" → ADO "succeeded"/"failed"
        ado_state = {"success": "succeeded", "failure": "failed", "error": "error"}.get(state, state)
        url = (
            f"{self._org_url}/{urllib.parse.quote(self._project)}/_apis/git"
            f"/repositories/{urllib.parse.quote(self._repo)}"
            f"/pullrequests/{pr_id}/statuses?{self._API_VERSION}"
        )
        payload = {
            "state": ado_state,
            "description": description,
            "context": {"name": "shamt-validate-pr", "genre": "shamt"},
        }
        self._request("POST", url, payload)


def _ado_thread_status(status_int: int) -> str:
    return {1: "active", 2: "fixed", 3: "wontFix", 4: "closed",
            5: "byDesign", 6: "pending"}.get(status_int, "active")


# ---------------------------------------------------------------------------
# Auto-detection
# ---------------------------------------------------------------------------

def detect_provider(override: str = "") -> PRProvider:
    """
    Return the appropriate provider.
    override: "github", "ado", or "" (auto-detect from env).
    """
    source = override or os.environ.get("SHAMT_PR_PROVIDER", "")
    if not source:
        if os.environ.get("TF_BUILD", "").lower() == "true":
            source = "ado"
        else:
            source = "github"

    if source == "ado":
        return AzureDevOpsProvider()
    return GitHubProvider()
