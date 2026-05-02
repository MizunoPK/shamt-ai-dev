# ADO PR Review Workflow

**What this is:** How to initiate and run AI-driven reviews on Azure DevOps pull requests.
This is the ADO counterpart to the `@codex` mention pattern on GitHub.

**Prerequisite:** ADO MCP Server wired into your host config. See `.shamt/guides/reference/azure_devops_integration.md` for setup.

---

## Trigger Options

ADO has no native "tag an AI agent in a PR comment" feature equivalent to GitHub's `@codex`. Three patterns are available:

### Option A — Interactive Agent Session (recommended for most teams)

Best for: teams that review PRs interactively; no extra infrastructure required.

**Steps:**

1. Open a Shamt agent session (Claude Code or Codex CLI) in the project repo.
2. Say: `"Review PR #123 on ADO"` or `"Review the open PR targeting main"`.
3. The agent uses the ADO MCP Server tools to:
   - List PRs → `mcp_ado_repo_list_pull_requests_by_repo_or_project`
   - Get PR details → `mcp_ado_repo_get_pull_request_by_id`
   - Get the diff → `mcp_ado_repo_get_pull_request_changes`
   - Read existing threads → `mcp_ado_repo_list_pull_request_threads`
4. The agent loads the `shamt-code-review` skill and runs the review dimensions against the diff.
5. The agent posts findings as ADO comment threads via `mcp_ado_repo_create_pull_request_thread`:
   - File-positioned threads for inline findings (code issues, spec mismatches)
   - Top-level threads for general findings (architecture, missing tests)
6. The agent optionally casts a reviewer vote via `mcp_ado_repo_vote_pull_request`:
   - `waitForAuthor` — issues found that need addressing
   - `approveWithSuggestions` — clean review with minor suggestions

**D-COVERAGE note:** This workflow uses the existing `shamt-code-review` skill. No dedicated ADO skill is needed — the skill applies the same review dimensions regardless of where the diff comes from; only the I/O layer (reading the diff, posting comments) is ADO-specific, handled by the ADO MCP tools.

---

### Option B — CI Pipeline Trigger (recommended for automated gates)

Best for: teams that want automated PR validation on every push; integrates with ADO branch policies.

**Steps:**

1. Copy the pipeline template:
   ```bash
   cp .shamt/sdk/azure-pipelines/shamt-validate.yml.template azure-pipelines/shamt-validate.yml
   ```
2. Create the pipeline in ADO and add a **Build Validation branch policy** on your target branch.
3. On PR creation or update, Azure Pipelines runs `shamt-validate-pr.py --provider=ado`.
4. The script identifies changed Shamt artifacts, drives validation, and posts structured comment threads.
5. The script sets a PR status (`succeeded`/`failed`) that the branch policy checks before merge.

**Setup requirements:** See `.shamt/sdk/azure-pipelines/README.md` for the permission prerequisites (`$(System.AccessToken)` requires explicit "Contribute to pull requests" permission).

---

### Option C — ADO Service Hook → External Agent (advanced)

Best for: large organizations that want fully automated, event-driven review without manual session initiation.

**Steps:**

1. Configure an ADO Service Hook (webhook) on "Pull request created" / "Pull request updated" events.
2. The webhook fires to an external endpoint (e.g., an Azure Function or self-hosted runner).
3. The endpoint spawns a headless agent session (via `codex exec` or the Agents SDK) that runs `shamt-code-review`.
4. The agent posts review findings as ADO comment threads.

**Trade-offs:** Requires external infrastructure (Azure Function or equivalent). Closest analog to `@codex` on GitHub. Recommended only for large orgs or when interactive reviews aren't feasible.

---

## ADO-Specific Review Behaviors

### Thread Statuses

ADO comment threads have explicit statuses that interact with branch policies and the UI:

| Status | When to use |
|--------|------------|
| `active` | Review finding that needs addressing (default for issues) |
| `pending` | Raised for discussion, not yet requiring action |
| `fixed` | Author marked as resolved — agent reads this on re-review |
| `wontFix` | Finding acknowledged but intentionally not addressed |
| `closed` | Informational thread, no action needed |
| `byDesign` | Behavior is intentional |

**Shamt convention:** Post review findings as `active` threads. When the author addresses a finding, they can mark it `fixed`. On re-review, the agent reads `fixed` and `closed` threads to identify what has been resolved.

### Reviewer Voting

The agent can cast a review vote. **Shamt convention:**
- `waitForAuthor` — findings exist that require changes
- `approveWithSuggestions` — clean review with minor, non-blocking suggestions
- **Never** cast `approve` or `reject` without explicit user instruction

### Required Reviewers and Branch Policies

ADO branch policies can require specific reviewer groups and minimum approval counts. Shamt's AI review complements (not replaces) human required reviewers. The AI vote (`approveWithSuggestions`) does not satisfy a "required reviewer" policy unless the AI's identity is explicitly added as a required reviewer — which is not recommended.

---

## Re-Review Pattern

When a PR author pushes new commits or marks threads as `fixed`:

1. Agent uses `mcp_ado_repo_list_pull_request_threads` to read all threads (including resolved ones).
2. Agent identifies which previous findings are now `fixed` or `closed`.
3. Agent gets the updated diff via `mcp_ado_repo_get_pull_request_changes` (latest iteration).
4. Agent runs the review against the new changes, focusing on:
   - Previously `active` threads: are they now addressed?
   - New changes: any new issues introduced?
5. Agent posts new threads for remaining / new issues.
6. Agent updates its vote as appropriate.

**Re-review command:** `"Re-review PR #123 — I've addressed the feedback"` in an interactive session.

---

## Cross-Provider Setup

If your project uses both GitHub and ADO (e.g., GitHub for open-source forks, ADO for internal work), set `--pr-provider=both` during init. Both the GitHub Actions templates and the Azure Pipelines templates will be available, and both the GitHub API and the ADO MCP Server will be registered in your host config.

See `.shamt/guides/reference/azure_devops_integration.md` for full setup details.
