# Azure DevOps PR Integration (SHAMT-46)

**What this is:** Reference guide for Shamt's Azure DevOps PR integration — PR provider abstraction, ADO MCP Server wiring, Azure Pipelines CI templates, and the cross-provider master review pattern.

**Design doc:** `design_docs/archive/SHAMT46_DESIGN.md` (after implementation) or `design_docs/active/` (during implementation).

---

## Overview

SHAMT-46 adds ADO support to three Shamt subsystems:

| Subsystem | GitHub (existing) | ADO (new) |
|-----------|------------------|-----------|
| CI validation gate | GitHub Actions (`shamt-validate.yml.template`) | Azure Pipelines (`azure-pipelines/shamt-validate.yml.template`) |
| Stale-work janitor | GitHub Actions + GitHub Issues | Azure Pipelines + ADO Work Items |
| Interactive PR review | N/A (no `@github` agent trigger) | ADO MCP Server + `shamt-code-review` skill |
| Master review pipeline | `@codex` GitHub PR trigger | ADO Service Hook or manual session |

---

## Setup

### 1. Init with ADO provider

```bash
bash .shamt/scripts/initialization/init.sh --pr-provider=ado
# or: --pr-provider=both  (GitHub + ADO)
```

You will be prompted for your ADO organization name (stored in `.shamt/config/ado_org.txt`).

### 2. Re-run regen after changing provider

```bash
bash .shamt/scripts/regen/regen-claude-shims.sh   # Claude Code
bash .shamt/scripts/regen/regen-codex-shims.sh    # Codex
```

The regen scripts read `.shamt/config/pr_provider.conf` and register the ADO MCP server in `.claude/settings.json` or `.codex/config.toml` when `pr_provider.conf` contains `ado`.

### 3. Prerequisites for CI (Azure Pipelines)

- Grant **"Contribute to pull requests"** to the build service account (Project Settings → Repositories → Permissions)
- Enable **"Allow scripts to access the OAuth token"** in the pipeline job
- Add `OPENAI_API_KEY` as a pipeline secret (Library → Variable Groups)

Full instructions: `.shamt/sdk/azure-pipelines/README.md`

---

## Provider Configuration Files

| File | Purpose |
|------|---------|
| `.shamt/config/pr_provider.conf` | Stores the chosen provider: `github`, `ado`, or `both` |
| `.shamt/config/ado_org.txt` | ADO organization name (e.g., `myorg` from `dev.azure.com/myorg`) |
| `.shamt/config/pr_provider.conf.template` | Template (default: `github`) |
| `.shamt/config/ado_org.txt.template` | Template placeholder |

---

## PR Provider Abstraction (`pr_provider.py`)

`PRProvider` protocol with 6 operations — the minimal surface both SDK scripts need:

```python
class PRProvider(Protocol):
    def get_pr_context(self) -> PRContext: ...
    def get_pr_diff(self, pr_id: str) -> list[ChangedFile]: ...
    def post_pr_comment(self, pr_id: str, body: str) -> CommentResult: ...
    def post_file_comment(self, pr_id: str, file_path: str, line: int, body: str) -> CommentResult: ...
    def get_pr_threads(self, pr_id: str) -> list[CommentThread]: ...
    def set_pr_status(self, pr_id: str, state: str, description: str) -> None: ...
```

**Provider detection:** `detect_provider()` auto-detects from `TF_BUILD=True` (Azure Pipelines) vs `GITHUB_ACTIONS=true` (GitHub Actions). Override with `--provider=github|ado` CLI flag or `SHAMT_PR_PROVIDER` env var.

**Scope note:** `PRProvider` covers PR operations only. `shamt-cron-janitor.py` posts stale-work digests as GitHub Issues or ADO Work Items — these use provider-specific APIs directly since they are not PR comment operations.

**Extensibility:** A GitLab provider can be added with < 100 lines by implementing the same 6-method protocol.

---

## ADO MCP Server Wiring

The Azure DevOps MCP Server (`@azure-devops/mcp`, npm) is registered alongside the Shamt MCP Server for interactive sessions:

**Claude Code** (`.claude/settings.json`):
```json
"mcpServers": {
  "ado": {
    "command": "npx",
    "args": ["-y", "@azure-devops/mcp", "<your-org>", "-d", "core", "repositories"],
    "type": "stdio"
  }
}
```

**Codex** (`.codex/config.toml`):
```toml
[mcp_servers.ado]
command = "npx"
args = ["-y", "@azure-devops/mcp", "<your-org>", "-d", "core", "repositories"]
type = "stdio"
```

**Domain filter:** `-d core repositories` loads only PR-relevant tools (13 PR tools + project context). Loading all domains adds 60+ tools, causing model confusion. Users who also need work-item or pipeline tools can add those domains manually.

**Authentication:** Browser-based Microsoft Entra OAuth on first use. For CI, use `$(System.AccessToken)` — no interactive auth required.

**Local vs Remote MCP Server:** Shamt wires the local server (`npx @azure-devops/mcp`) which is stable and well-documented. The Remote MCP Server (public preview) may eventually replace it. When it does, update the `command`/`args` in `regen-*-shims.sh`.

---

## ADO PR Review Workflow

For how to initiate and run AI-driven reviews on ADO PRs (trigger options, thread statuses, voting, re-review pattern), see: **`.shamt/guides/reference/ado_pr_review_workflow.md`**

---

## Azure Pipelines Templates

| Template | Purpose | Location |
|----------|---------|----------|
| `shamt-validate.yml.template` | PR validation gate | `.shamt/sdk/azure-pipelines/` |
| `shamt-cron-janitor.yml.template` | Weekly stale-work scanner | `.shamt/sdk/azure-pipelines/` |

Copy to your repo:
```bash
cp .shamt/sdk/azure-pipelines/shamt-validate.yml.template azure-pipelines/shamt-validate.yml
cp .shamt/sdk/azure-pipelines/shamt-cron-janitor.yml.template azure-pipelines/shamt-cron-janitor.yml
```

---

## Cross-Provider Master Review Pipeline

For the scenario where the master repo is on GitHub and a child project is on ADO (or both on ADO), see the ADO variant sections in: **`.shamt/guides/composites/master_review_pipeline_composite.md`**

Key points:
- For GitHub master + ADO child: the child submits a PR to master on GitHub (via fork or mirror); the existing GitHub-based master review pipeline works as-is.
- For fully ADO-hosted (master + children both on ADO): the master reviewer uses the ADO MCP Server; trigger via Option B (CI pipeline) or Option C (Service Hook) from `ado_pr_review_workflow.md`.
- The `shamt-master-reviewer` skill, guide audit skill, and separation rule logic are provider-agnostic — they operate on diffs and apply rules regardless of hosting platform.

---

## Open Questions (for implementation reference)

| # | Status | Notes |
|---|--------|-------|
| Local vs Remote ADO MCP Server | Resolved: use local | Wire local now; document migration when Remote GA |
| `$(System.AccessToken)` scope | Resolved: NOT granted by default | Requires explicit permission setup — see `azure-pipelines/README.md` |
| Version pinning | Resolved: pin in templates | Document update procedure in `azure-pipelines/README.md` |
| Thread status (`active` vs `pending`) | Resolved: use `active` | Standard "needs attention" state for review findings |
| Cross-org PRs | Deferred | Two MCP instances may be needed; document as known limitation |
| GitLab / Bitbucket | Deferred | Keep `PRProvider` minimal (6 methods); extend later |
