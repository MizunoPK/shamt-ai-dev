# SHAMT-46: Azure DevOps PR Integration — Provider Abstraction and ADO MCP Wiring

**Status:** Validated
**Created:** 2026-04-28
**Branch:** `feat/SHAMT-46`
**Validation Log:** [SHAMT46_VALIDATION_LOG.md](./SHAMT46_VALIDATION_LOG.md)
**Depends on:** SHAMT-39 (canonical content), SHAMT-40 (Claude Code wiring + regen scripts), SHAMT-41 (hooks + MCP), SHAMT-42 (Codex wiring + regen scripts), SHAMT-43 (SDK CI scripts), SHAMT-44 (master review pipeline composite)
**Companion docs:** `CODEX_INTEGRATION_THEORIES.md`, `CLAUDE_INTEGRATION_THEORIES.md`, `FUTURE_ARCHITECTURE_OVERVIEW.md`

---

## Problem Statement

SHAMT-43 designs the Shamt PR integration surface — `shamt-validate-pr.py` (CI gate), `shamt-cron-janitor.py` (scheduled scanner), and the `@codex`-driven master review pipeline. All three are **hardcoded to GitHub**: the SDK scripts read GitHub Actions environment variables, post comments via the GitHub API, and the `@codex` mention trigger is a GitHub-native feature. The workflow templates are GitHub Actions YAML.

This means any team running Azure DevOps (ADO) for source control and pull requests gets **none** of the PR integration benefits. They can't:
- Get AI-driven validation feedback posted as PR comments on their ADO pull requests
- Read existing PR comment threads to understand review context
- Initiate AI reviewers on ADO PRs
- Use the master review pipeline on ADO-hosted child projects
- Run CI gates on ADO Pipelines instead of GitHub Actions

This is a significant gap. Azure DevOps is widely used in enterprise environments and has a mature PR model with comment threads, reviewer voting, branch policies, and required reviewers — all of which map naturally to Shamt's review and validation workflows.

Critically, Microsoft now ships an **official Azure DevOps MCP Server** (`@azure-devops/mcp`, open-source at `microsoft/azure-devops-mcp`) that exposes a comprehensive PR toolset over MCP — the same protocol Shamt's `shamt-mcp` server already uses. This means the integration can be achieved without writing raw REST API calls; agents can interact with ADO PRs through typed MCP tool calls, exactly as they do with the local `shamt-mcp` server.

**Impact of NOT solving:** Enterprise teams on ADO cannot use Shamt's most visible automation features — automated PR validation, AI-initiated code review, and the master review pipeline. They get the guide system and the workflow but miss the CI/CD integration layer entirely.

---

## Goals

1. Introduce a **PR provider abstraction** in the Shamt SDK scripts (`shamt-validate-pr.py`, `shamt-cron-janitor.py`) so the same validation logic can target GitHub or Azure DevOps without code duplication.
2. Author **Azure DevOps Pipeline templates** (YAML) as counterparts to the existing GitHub Actions workflow templates, so ADO teams can enable CI gates with the same copy-to-project workflow.
3. Document how to wire the **Azure DevOps MCP Server** (`@azure-devops/mcp`) into Shamt's host configuration (`.claude/settings.json`, `.codex/config.toml`) so agents can read PR details, comment threads, diffs, and post review comments on ADO PRs during interactive sessions.
4. Author an `ado_pr_review_workflow` guide that describes how to initiate AI review on an ADO PR — the ADO equivalent of the `@codex` mention trigger on GitHub.
5. Extend init scripts to support `--pr-provider=github|ado|both` so projects declare their PR provider at setup time.
6. Ensure the master review pipeline (SHAMT-44 composite) can operate on ADO-hosted child projects that submit PRs to a GitHub-hosted master repo, or on fully ADO-hosted setups.

---

## Background: Azure DevOps MCP Server Capabilities

Microsoft's official Azure DevOps MCP Server (`@azure-devops/mcp`, npm package `@azure-devops/mcp`) provides a comprehensive PR toolset via MCP:

### PR Tools Available (Repositories domain)

| Tool | Purpose |
|------|---------|
| `mcp_ado_repo_list_pull_requests_by_repo_or_project` | List PRs with filters (status, author, reviewer, source/target branch) |
| `mcp_ado_repo_list_pull_requests_by_commits` | Find PRs containing specific commits |
| `mcp_ado_repo_get_pull_request_by_id` | Get full PR details (including work item refs, labels, changed files) |
| `mcp_ado_repo_get_pull_request_changes` | Get file-level diff with line-by-line content |
| `mcp_ado_repo_create_pull_request` | Create new PRs (with description, draft mode, labels, linked work items) |
| `mcp_ado_repo_update_pull_request` | Update PR properties (title, description, status, merge strategy, auto-complete) |
| `mcp_ado_repo_update_pull_request_reviewers` | Add/remove reviewers |
| `mcp_ado_repo_vote_pull_request` | Cast review vote (approve, approve with suggestions, wait for author, reject) |
| `mcp_ado_repo_list_pull_request_threads` | List all comment threads on a PR |
| `mcp_ado_repo_list_pull_request_thread_comments` | List comments within a specific thread |
| `mcp_ado_repo_create_pull_request_thread` | Create new comment thread (general or file-positioned with line ranges) |
| `mcp_ado_repo_update_pull_request_thread` | Update thread status (active, fixed, won't fix, closed, by design, pending) |
| `mcp_ado_repo_reply_to_comment` | Reply to an existing comment in a thread |

### Additional ADO Tools Relevant to Shamt

| Tool | Purpose |
|------|---------|
| `mcp_ado_wit_link_work_item_to_pull_request` | Link work items to PRs (traceability) |
| `mcp_ado_pipelines_run_pipeline` | Trigger pipeline runs (CI gate orchestration) |
| `mcp_ado_pipelines_get_build_status` | Check pipeline/build status |
| `mcp_ado_pipelines_get_builds` | List builds with filters |

### Setup

The ADO MCP Server runs locally via `npx @azure-devops/mcp <org-name>` (stdio transport) or as a **Remote MCP Server** (public preview, streamable HTTP). Authentication is via Microsoft Entra ID (browser-based OAuth on first use) or PAT. Domains can be filtered: `"-d", "core", "repositories"` loads only the PR-relevant tools.

A Remote MCP Server variant is now in public preview, which will eventually replace the local server. Both local and remote are supported during the transition.

---

## Detailed Design

### Proposal 1: PR Provider Abstraction Layer

**Description:** Introduce a thin provider interface in the SDK scripts that abstracts the operations SHAMT-43's scripts perform on a git hosting platform:

```python
# .shamt/sdk/pr_provider.py

class PRProvider(Protocol):
    """Minimal interface for PR operations used by Shamt SDK scripts."""

    def get_pr_context(self) -> PRContext:
        """Read PR metadata from CI environment variables."""
        ...

    def get_pr_diff(self, pr_id: str) -> list[ChangedFile]:
        """Get the list of changed files with diff content."""
        ...

    def post_pr_comment(self, pr_id: str, body: str) -> CommentResult:
        """Post a top-level comment on the PR."""
        ...

    def post_file_comment(self, pr_id: str, file_path: str,
                          line: int, body: str) -> CommentResult:
        """Post an inline comment on a specific file and line."""
        ...

    def get_pr_threads(self, pr_id: str) -> list[CommentThread]:
        """Read existing comment threads on the PR."""
        ...

    def set_pr_status(self, pr_id: str, state: str,
                      description: str) -> None:
        """Set a status check on the PR (e.g., succeeded/failed)."""
        ...


class GitHubProvider(PRProvider):
    """GitHub implementation using PyGithub / GitHub API."""
    ...

class AzureDevOpsProvider(PRProvider):
    """Azure DevOps implementation using ADO REST API."""
    ...
```

**Provider detection** in CI:
- **GitHub Actions:** Presence of `GITHUB_ACTIONS=true` env var, PR number from `GITHUB_EVENT_PATH`
- **Azure Pipelines:** Presence of `TF_BUILD=True` env var, PR ID from `SYSTEM_PULLREQUEST_PULLREQUESTID`, repo from `BUILD_REPOSITORY_NAME`, org from `SYSTEM_COLLECTIONURI`

The provider is auto-detected from environment or explicitly set via `--provider=github|ado` CLI flag.

**Key ADO REST API mappings for the provider:**

| Operation | ADO REST API Endpoint |
|-----------|----------------------|
| Get PR context | `GET {org}/{project}/_apis/git/repositories/{repo}/pullrequests/{id}?api-version=7.1` |
| Get PR diff | `GET .../pullrequests/{id}/iterations/{iterationId}/changes?api-version=7.1` |
| Post comment thread | `POST .../pullrequests/{id}/threads?api-version=7.1` |
| Post inline comment | Same as above, with `threadContext.filePath` and `rightFileStart/EndLine` |
| Read threads | `GET .../pullrequests/{id}/threads?api-version=7.1` |
| Set PR status | `POST {org}/{project}/_apis/git/repositories/{repo}/pullrequests/{id}/statuses?api-version=7.1` |

Authentication: PAT via `AZURE_DEVOPS_PAT` env var (CI secret) or `SYSTEM_ACCESSTOKEN` (Azure Pipelines built-in). The ADO provider sets `Authorization: Basic base64(:PAT)` on all requests.

**Scope note:** The `PRProvider` protocol covers PR-specific operations only. `shamt-cron-janitor.py` posts stale-work digests as GitHub Issues or ADO Work Items — these are fundamentally different APIs (GitHub Issues API vs. ADO Work Item Tracking API) that don't share a shape with PR comment operations. The janitor shares the `--provider` flag and CI environment detection logic with `shamt-validate-pr.py` but uses provider-specific issue/work-item APIs directly rather than the `PRProvider` protocol.

**Rationale:** The abstraction is minimal — only the 6 operations the PR validation script actually uses. No attempt to abstract the entire git hosting API. This keeps the interface tight and testable. Future providers (GitLab, Bitbucket) would implement the same interface.

**Alternatives considered:**
- *Use the ADO MCP Server from within the SDK scripts:* The SDK scripts run in CI where MCP servers may not be available or practical to start. Direct REST API calls are simpler for headless automation. The MCP server is better suited for interactive agent sessions (see Proposal 3). Rejected for SDK scripts, adopted for interactive use.
- *Separate `shamt-validate-pr-ado.py` script:* Code duplication of all validation logic. The core (identify changed artifacts, drive validation, format results) is identical across providers. Rejected.
- *Single unified API client library:* Over-engineering for 6 methods. A protocol + two implementations is sufficient. Rejected.

### Proposal 2: Azure Pipelines Workflow Templates

**Description:** Author Azure Pipelines YAML templates as counterparts to the GitHub Actions templates from SHAMT-43:

**`.shamt/sdk/azure-pipelines/shamt-validate.yml.template`** — PR validation gate:
```yaml
trigger: none

pr:
  branches:
    include:
      - main
      - 'feat/*'

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: '3.11'

  - script: |
      pip install -r .shamt/sdk/requirements.txt
      python .shamt/sdk/shamt-validate-pr.py --provider=ado
    displayName: 'Run Shamt PR Validation'
    env:
      AZURE_DEVOPS_PAT: $(System.AccessToken)
      SYSTEM_COLLECTIONURI: $(System.CollectionUri)
      SYSTEM_PULLREQUEST_PULLREQUESTID: $(System.PullRequest.PullRequestId)
      BUILD_REPOSITORY_NAME: $(Build.Repository.Name)
      SYSTEM_TEAMPROJECT: $(System.TeamProject)
```

**`.shamt/sdk/azure-pipelines/shamt-cron-janitor.yml.template`** — Scheduled stale-work scanner:
```yaml
trigger: none

schedules:
  - cron: '0 8 * * 1'  # Weekly Monday 8 AM UTC
    displayName: 'Weekly Shamt Janitor'
    branches:
      include:
        - main
    always: true

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: '3.11'

  - script: |
      pip install -r .shamt/sdk/requirements.txt
      python .shamt/sdk/shamt-cron-janitor.py --provider=ado
    displayName: 'Run Shamt Janitor'
    env:
      AZURE_DEVOPS_PAT: $(System.AccessToken)
```

**Post-validation comment format for ADO:**
ADO comment threads have a richer model than GitHub PR comments — threads have explicit statuses (`active`, `fixed`, `wontFix`, `closed`, `byDesign`, `pending`) and can be positioned on specific file lines. The ADO provider leverages this:
- **General validation summary:** Posted as a top-level thread with the full results table
- **Per-artifact issues:** Posted as file-positioned threads on the changed artifact, with thread status set to `active`
- **Clean validation:** Posted as a top-level thread with status `closed` (informational, doesn't block)

ADO also supports **PR statuses** (a lightweight check mechanism similar to GitHub status checks). The validation script posts a status via `POST .../pullrequests/{id}/statuses` with `state: succeeded|failed` and a `targetUrl` pointing to the pipeline run. This integrates with ADO branch policies that can require specific statuses to pass before merge.

**Rationale:** Azure Pipelines is the natural CI/CD system for ADO-hosted repos. The template pattern (copy to project, fill in vars) matches the GitHub Actions template pattern from SHAMT-43. Using `$(System.AccessToken)` avoids requiring a separate PAT for CI — the pipeline's identity has PR comment permissions by default.

**Alternatives considered:**
- *Generic CI template (e.g., shell script only):* Loses the tight ADO-specific integration (PR triggers, system variables, access token). Rejected.
- *Azure DevOps Service Hook (webhook) instead of pipeline:* More complex setup, harder to debug, and the script still needs a compute environment. Pipelines are the standard pattern. Rejected.

### Proposal 3: ADO MCP Server Wiring for Interactive Sessions

**Description:** When a Shamt-on-Claude-Code or Shamt-on-Codex project targets ADO for source control, the init/regen scripts register the Azure DevOps MCP Server alongside the Shamt MCP Server. This gives the agent direct, typed access to ADO PR operations during interactive sessions.

**Claude Code wiring** (`.claude/settings.json`):
```json
{
  "mcpServers": {
    "shamt": {
      "command": "python",
      "args": [".shamt/mcp/server.py"],
      "type": "stdio"
    },
    "ado": {
      "command": "npx",
      "args": ["-y", "@azure-devops/mcp", "SHAMT_ADO_ORG_PLACEHOLDER", "-d", "core", "repositories"],
      "type": "stdio"
    }
  }
}
```

**Codex wiring** (`.codex/config.toml`):
```toml
[mcp_servers.ado]
command = "npx"
args = ["-y", "@azure-devops/mcp", "{ado_org}", "-d", "core", "repositories"]
type = "stdio"
```

The **domain filter** (`-d core,repositories`) is critical — loading all ADO domains (work items, wikis, test plans, pipelines, search, advanced security) would add 60+ tools to the agent's tool inventory, causing confusion and model overhead. The `core` + `repositories` domains provide PR operations plus project/team context, which is what Shamt needs. Users who also want work-item or pipeline tools can add those domains to their own config.

**Init script extension:** When `--pr-provider=ado` or `--pr-provider=both` is passed to `init.sh`:
1. Check that `npx` is available (Node.js 20+ is a prerequisite of the ADO MCP Server).
2. Prompt for the ADO organization name (stored in `.shamt/config/ado_org.txt` for subsequent regen runs).
3. Register the ADO MCP server in the host-specific settings file (resolving `SHAMT_ADO_ORG_PLACEHOLDER` to the actual org name at write time, same pattern as SHAMT-40's `${PROJECT}` resolution).
4. Emit a one-time instruction: "On first ADO MCP tool use, your browser will open for Microsoft Entra authentication."

**Rationale:** The ADO MCP Server is Microsoft's official, maintained, first-party integration. Using it instead of building a custom ADO REST client for interactive sessions is dramatically less work and inherits Microsoft's ongoing investment. The typed MCP tools (`mcp_ado_repo_list_pull_request_threads`, `mcp_ado_repo_create_pull_request_thread`, etc.) map directly to the operations Shamt's review skills need.

**Alternatives considered:**
- *Build a custom ADO adapter inside `shamt-mcp`:* Reinvents the wheel. Microsoft already maintains the official MCP server. Rejected.
- *Always register all ADO MCP domains:* Tool overload. The agent sees 70+ ADO tools and becomes confused about which to use. Domain filtering is essential. Rejected.
- *Skip interactive ADO integration, only support CI:* Loses the ability to interactively review ADO PRs from within the agent session ("read the comments on PR #123 and address the feedback"). This is the user's primary ask. Rejected.

### Proposal 4: ADO PR Review Workflow Guide

**Description:** Author `.shamt/guides/reference/ado_pr_review_workflow.md` documenting how to initiate and run AI-driven reviews on ADO pull requests. This is the ADO counterpart to the `@codex` mention pattern on GitHub.

Since ADO has no equivalent of GitHub's `@codex` mention (there is no native "tag an AI agent in a PR comment" feature), the workflow uses different trigger mechanisms:

**Trigger Option A — Interactive agent session:**
1. User opens a Shamt agent session (Claude Code or Codex CLI) in the project repo.
2. User says: "Review PR #123 on ADO" (or "review the open PR targeting main").
3. Agent uses the ADO MCP Server tools to: list PRs → get PR details → get PR changes/diff → read existing comment threads.
4. Agent loads the `shamt-code-review` skill (from SHAMT-39) and runs the review dimensions against the diff.
5. Agent posts review findings as ADO comment threads (file-positioned where applicable) via `mcp_ado_repo_create_pull_request_thread`.
6. Agent optionally casts a review vote via `mcp_ado_repo_vote_pull_request`.

**Trigger Option B — CI pipeline trigger:**
1. ADO Pipeline runs `shamt-validate-pr.py --provider=ado` on PR creation/update.
2. Script identifies changed Shamt artifacts, drives validation, posts structured comment threads.
3. Script sets PR status (succeeded/failed) for branch policy integration.

**Trigger Option C — ADO Service Hook → external agent (advanced):**
1. Configure an ADO Service Hook (webhook) on "Pull request created" / "Pull request updated" events.
2. Webhook fires to an external endpoint (e.g., an Azure Function or a self-hosted agent runner).
3. Endpoint spawns a headless agent session (via `codex exec` or Agents SDK) that runs the review.
4. This is the closest analog to `@codex` on GitHub — event-driven, fully automated. But requires external infrastructure.

The guide documents all three options with setup instructions, trade-offs, and recommendations:
- **Option A** for teams that review interactively (most common; no extra infrastructure)
- **Option B** for teams that want automated CI gates (copy pipeline template, done)
- **Option C** for teams that want fully automated event-driven review (requires infrastructure; recommended only for large orgs)

**Key ADO-specific behaviors the guide documents:**
- **Thread statuses:** Review findings posted as `active` threads. When the author addresses a finding, they can mark the thread `fixed` — the agent can read this on re-review.
- **Reviewer voting:** The agent can cast a vote (`approve`, `approveWithSuggestions`, `waitForAuthor`, `reject`). The guide recommends `waitForAuthor` for issues and `approveWithSuggestions` for clean reviews — never `approve` or `reject` without human confirmation.
- **Required reviewers and branch policies:** ADO branch policies can require specific reviewer groups and minimum approvals. The guide documents how Shamt's AI review complements (not replaces) human required reviewers.
- **Re-review pattern:** On re-review, the agent reads existing threads (including `fixed`/`closed` ones), identifies which issues are resolved, posts new threads for remaining/new issues, and updates its vote.

**Rationale:** Without this guide, an ADO user knows the MCP tools exist but not how to compose them into a Shamt review workflow. The guide bridges "I have ADO MCP tools" to "I can run a structured AI code review on my ADO PR."

### Proposal 5: Init Script and Config Extensions

**Description:** Extend `init.sh` / `init.ps1` with PR provider awareness:

New flag: `--pr-provider=github|ado|both` (default: auto-detected from existing config or prompted).

Behavior:
- `--pr-provider=github`: Current behavior. GitHub Actions templates available. No ADO MCP registration.
- `--pr-provider=ado`: Register ADO MCP Server. Copy Azure Pipelines templates to `.shamt/sdk/azure-pipelines/`. Prompt for ADO org name. Store in `.shamt/config/ado_org.txt`.
- `--pr-provider=both`: Both GitHub and ADO configurations. For teams using GitHub for open-source forks and ADO for internal repos, or during migrations.

New config file: `.shamt/config/pr_provider.conf` stores the chosen provider(s) so `regen-*-shims.sh` scripts know which MCP servers to register on subsequent runs.

The `regen-claude-shims.sh` and `regen-codex-shims.sh` scripts (in `.shamt/scripts/regen/`, from SHAMT-40 / SHAMT-42) read `pr_provider.conf` and conditionally register the ADO MCP server in the host settings.

**Rationale:** Aligns with the existing multi-host pattern (`--host=claude|codex|claude,codex` from SHAMT-42). Provider choice is a project-level decision made once at init and respected by all subsequent regen runs.

### Proposal 6: Cross-Provider Master Review Pipeline

**Description:** Update the master review pipeline composite (SHAMT-44) to handle the scenario where:
- Master repo is on GitHub (common for open-source Shamt repos)
- Child project is on ADO (enterprise team)
- Child submits a PR to master on GitHub (via fork or mirror)

In this scenario, the existing GitHub-based master review pipeline works as-is for the PR review. The cross-provider concern is the **feedback loop**: after the master reviewer posts comments on the GitHub PR, the child team needs to see and address them. This is a workflow concern, not a technical one — the guide documents:

1. Child exports changes via `shamt export` (unchanged).
2. Child opens PR to master (on GitHub — unchanged).
3. Master reviewer runs on the GitHub PR (unchanged).
4. Child team reads GitHub PR comments (may require GitHub access for the ADO-primary team).

For fully ADO-hosted setups (master and children both on ADO):
- The master review pipeline uses the ADO MCP Server instead of `@codex`.
- The master reviewer skill, guide audit skill, and separation rule logic are provider-agnostic (they read diffs and apply rules — the source of the diff doesn't matter).
- Review findings are posted as ADO comment threads on the ADO PR.
- Trigger is Option B (CI pipeline) or Option C (service hook) from Proposal 4.

**Rationale:** The master review pipeline's intelligence (separation rule, guide audit) is already provider-agnostic — it operates on diffs and files. Only the I/O layer (where to read the diff from, where to post comments) is provider-specific, and that's handled by Proposals 1 and 3.

### Recommended approach

All six proposals together. They form a coherent layer: abstraction (P1), CI templates (P2), interactive MCP wiring (P3), workflow documentation (P4), init integration (P5), and cross-provider scenario handling (P6).

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/sdk/pr_provider.py` | CREATE | Provider abstraction: `PRProvider` protocol, `GitHubProvider`, `AzureDevOpsProvider` |
| `.shamt/sdk/shamt-validate-pr.py` | MODIFY | Refactor to use `PRProvider` instead of direct GitHub API calls; add `--provider` flag |
| `.shamt/sdk/shamt-cron-janitor.py` | MODIFY | Refactor issue-posting to use provider-specific API (GitHub Issues API / ADO Work Items API); PR provider abstraction not applicable since janitor posts to issues, not PRs |
| `.shamt/sdk/requirements.txt` | MODIFY | Add `requests` (for ADO REST API calls in `AzureDevOpsProvider`; likely already present for GitHub provider) |
| `.shamt/sdk/azure-pipelines/shamt-validate.yml.template` | CREATE | ADO Pipeline PR validation gate |
| `.shamt/sdk/azure-pipelines/shamt-cron-janitor.yml.template` | CREATE | ADO Pipeline weekly cron janitor |
| `.shamt/sdk/azure-pipelines/README.md` | CREATE | Setup instructions for ADO pipeline templates |
| `.shamt/sdk/README.md` | MODIFY | Add ADO provider documentation, `--provider` flag usage |
| `.shamt/guides/reference/ado_pr_review_workflow.md` | CREATE | Full ADO PR review workflow guide (Triggers A/B/C, thread statuses, voting, re-review) |
| `.shamt/host/claude/settings.starter.json` | MODIFY | Add conditional ADO MCP server block (commented out by default, uncommented by init when `--pr-provider=ado`) |
| `.shamt/host/codex/config.starter.toml` | MODIFY | Add conditional ADO MCP server block |
| `.shamt/config/pr_provider.conf.template` | CREATE | Template for PR provider config |
| `.shamt/config/ado_org.txt.template` | CREATE | Placeholder for ADO org name |
| `.shamt/scripts/initialization/init.sh` | MODIFY | Add `--pr-provider` flag, ADO MCP registration logic, ADO org prompt |
| `.shamt/scripts/initialization/init.ps1` | MODIFY | Mirror |
| `.shamt/scripts/regen/regen-claude-shims.sh` | MODIFY | Read `pr_provider.conf`, conditionally register ADO MCP |
| `.shamt/scripts/regen/regen-codex-shims.sh` | MODIFY | Read `pr_provider.conf`, conditionally register ADO MCP |
| `.shamt/guides/composites/master_review_pipeline_composite.md` | MODIFY | Add "ADO-hosted" and "cross-provider" variant sections |
| `.shamt/commands/CHEATSHEET.md` | MODIFY | Add ADO PR review commands and setup instructions |
| `CLAUDE.md` | MODIFY | New section "Azure DevOps PR Integration (SHAMT-46)" |
| `.shamt/scripts/initialization/ai_services.md` | MODIFY | Add note about ADO MCP Server as a companion integration alongside AI service choice |

---

## Implementation Plan

### Phase 1: PR Provider Abstraction
- [ ] Author `pr_provider.py` with `PRProvider` protocol, `GitHubProvider`, `AzureDevOpsProvider`.
- [ ] Implement `AzureDevOpsProvider` using ADO REST API 7.1 (PR get, diff, comment threads, status).
- [ ] Implement auto-detection logic (GitHub Actions vs Azure Pipelines environment).
- [ ] Refactor `shamt-validate-pr.py` to use the provider interface.
- [ ] Refactor `shamt-cron-janitor.py`: add `--provider=github|ado` flag for CI environment detection and authentication (shared with `shamt-validate-pr.py`), but use provider-specific issue/work-item APIs directly since the janitor posts digests as GitHub Issues or ADO Work Items (not PR comments). The `PRProvider` protocol is PR-scoped and does not apply to issue creation.
- [ ] Add `--provider=github|ado` CLI flag to both scripts.
- [ ] Unit tests for both providers with mocked API responses.

### Phase 2: Azure Pipelines Templates
- [ ] Author `shamt-validate.yml.template` for ADO Pipeline PR trigger.
- [ ] Author `shamt-cron-janitor.yml.template` for ADO Pipeline scheduled trigger.
- [ ] Author `azure-pipelines/README.md` with setup instructions.
- [ ] Test on a sample ADO project with a deliberately-broken spec; verify comment threads are posted correctly and PR status is set.

### Phase 3: ADO MCP Server Wiring
- [ ] Add `--pr-provider` flag to `init.sh` / `init.ps1`.
- [ ] Implement ADO org prompt and `ado_org.txt` storage.
- [ ] Implement conditional ADO MCP registration in host settings files.
- [ ] Update `.shamt/scripts/regen/regen-claude-shims.sh` to read `pr_provider.conf`.
- [ ] Update `.shamt/scripts/regen/regen-codex-shims.sh` to read `pr_provider.conf`.
- [ ] Verify ADO MCP tools are accessible from a Claude Code / Codex session after init.

### Phase 4: Workflow Guide and Documentation
- [ ] Author `ado_pr_review_workflow.md` (Triggers A/B/C, thread statuses, voting, re-review).
- [ ] Update `master_review_pipeline_composite.md` with ADO and cross-provider variants.
- [ ] Update `CHEATSHEET.md` with ADO commands.
- [ ] Update `CLAUDE.md` with SHAMT-46 section.
- [ ] Update `ai_services.md` with ADO MCP Server note.

### Phase 5: Validation
- [ ] Run design doc validation loop (7 dimensions).
- [ ] After implementation, run implementation validation (5 dimensions).
- [ ] Test end-to-end: ADO PR created → pipeline runs → validation comments posted → PR status set.
- [ ] Test interactive: Agent session → "review PR #N on ADO" → findings posted as threads.

---

## Validation Strategy

- **Primary validation:** Design doc validation loop (7 dimensions) until primary clean round + 2 sub-agent confirmations.
- **Implementation validation:** After code is complete, verify against design (5 dimensions).
- **Testing approach:**
  - Unit tests for `AzureDevOpsProvider` with mocked ADO REST responses.
  - Integration test on a real ADO project (requires ADO org access) for the CI pipeline template.
  - Interactive test: run agent session with ADO MCP wired, verify PR thread creation works.
- **Success criteria:**
  - `shamt-validate-pr.py --provider=ado` posts structured comment threads on an ADO PR.
  - ADO Pipeline template triggers on PR creation and runs validation.
  - Agent in interactive session can read ADO PR threads and post review findings via MCP tools.
  - The PR provider abstraction is clean enough that a GitLab provider could be added with < 100 lines.

---

## Open Questions

1. **ADO MCP Server: Local vs Remote?** The Remote MCP Server is in public preview and will eventually replace the local server. Should Shamt wire the local server (stable, documented) or the remote server (newer, may become the only option)? **Recommendation:** Wire the local server now with a documented migration path to remote.

2. **Authentication in CI:** `$(System.AccessToken)` in Azure Pipelines has limited scope. Does it have permission to post PR comments and set PR statuses by default? **Needs verification** — if not, the template needs to document the required pipeline permissions or use a PAT secret instead.

3. **ADO MCP Server version pinning:** Should Shamt pin a specific version of `@azure-devops/mcp` or use `@latest`? Pinning avoids breakage; `@latest` gets improvements. **Recommendation:** Pin in templates, document how to update.

4. **Thread status mapping:** When the agent posts a review finding, should the thread status be `active` (default) or `pending`? ADO treats these differently in the UI and branch policy evaluation.

5. **Cross-org PRs:** ADO PRs are scoped to a single ADO organization. Cross-org PRs (child on org A, master on org B) would require the ADO MCP Server to authenticate to both orgs. Is this a supported scenario? If so, two MCP server instances may be needed.

6. **GitLab / Bitbucket:** This design deliberately limits scope to GitHub + ADO. Should the provider abstraction be designed with a third provider in mind, or keep it minimal and extend later? **Recommendation:** Keep the protocol minimal (6 methods); a GitLab provider can be added later without changing the interface.

---

## Risks & Mitigation

| Risk | Severity | Mitigation |
|------|----------|------------|
| ADO MCP Server is in preview; breaking changes possible | MEDIUM | Pin version in templates. The provider abstraction for SDK scripts uses direct REST API calls (stable 7.1 API), not the MCP server, so CI scripts are insulated. |
| ADO REST API rate limiting in large orgs | LOW | The validation script makes O(N) calls where N is the number of changed artifacts. Unlikely to hit limits. Document rate-limit headers for awareness. |
| Microsoft Entra auth complexity for first-time MCP setup | MEDIUM | Document the one-time browser auth flow. For CI, use `$(System.AccessToken)` which requires no interactive auth. |
| ADO branch policies may block bot-posted PR statuses | LOW | Document required pipeline permissions. Recommend using build validation policies (which check pipeline status) rather than custom status policies. |
| Provider abstraction may not cover future operations | LOW | Keep the protocol minimal (6 methods). Extend when new operations are needed rather than pre-abstracting. |
| ADO thread model is richer than GitHub comments; abstraction may lose fidelity | LOW | The abstraction is one-way (Shamt → provider). ADO-specific features (thread statuses, file-positioned threads) are used in the `AzureDevOpsProvider` implementation even if `GitHubProvider` doesn't support the equivalent. The protocol's `post_file_comment` maps to both GitHub inline comments and ADO positioned threads. |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-28 | Initial draft created |
| 2026-04-28 | Round 1 fixes: corrected regen script paths from `scripts/export/` to `scripts/regen/` (Issue 2.1); clarified ADO_ORG placeholder resolution pattern (Issue 2.2); resolved `requirements.txt` to `requests` (Issue 2.3); added SHAMT-40/42 to dependency list (Issue 3.1); aligned goal 4 naming with file name (Issue 3.2) |
| 2026-04-28 | Round 2 sub-agent fix: clarified PRProvider scope — protocol is PR-only; janitor uses provider-specific issue/work-item APIs directly since it posts digests as issues, not PR comments |
| 2026-04-28 | Validation: added missing Validation Log header field; corrected Files Affected path for master_review_pipeline_composite.md from `.shamt/guides/reference/` to `.shamt/guides/composites/` (per SHAMT-44) |
