# Shamt SDK

Two standalone Python scripts for CI automation via the OpenAI Agents SDK. Both support GitHub Actions (default) and Azure Pipelines via the `--provider` flag.

| Script | Purpose |
|--------|---------|
| `shamt-validate-pr.py` | PR validation gate — validates changed Shamt artifacts and posts results as a PR comment (GitHub) or PR thread (ADO) |
| `shamt-cron-janitor.py` | Stale-work scanner — finds proposals, design docs, and child syncs that have gone quiet; posts digest as GitHub Issue or ADO Work Item |

**Provider abstraction:** `pr_provider.py` defines the `PRProvider` protocol with `GitHubProvider` and `AzureDevOpsProvider` implementations. Provider is auto-detected from CI environment (`TF_BUILD=True` → ADO; `GITHUB_ACTIONS=true` → GitHub) or set via `--provider=github|ado`.

---

## Install

```bash
pip install -r .shamt/sdk/requirements.txt
```

Requires Python 3.11+. Dependencies: `openai`, `PyGithub`, `requests`.

---

## PR Validation Gate

### Enabling

Copy the workflow template to your repo:

```bash
cp .shamt/sdk/.github/workflows/shamt-validate.yml.template .github/workflows/shamt-validate.yml
```

Add your API key as a GitHub Actions secret (`OPENAI_API_KEY` or `ANTHROPIC_API_KEY`).

The workflow runs automatically on pull requests. `GITHUB_TOKEN` is provided by GitHub Actions — no additional setup needed for PR comments.

### Label gate (recommended for high-PR-volume repos)

To avoid running on every PR and managing API costs, restrict to PRs labeled `needs-shamt-review`:

1. In the workflow file, uncomment the `if: contains(...)` line.
2. Apply the `needs-shamt-review` label to PRs that touch Shamt artifacts.

### What it validates

Changed files matching:
- `**/*_DESIGN.md`
- `**/*_VALIDATION_LOG.md`
- `**/*spec*.md` / `**/*SPEC*.md`
- `**/AGENT_STATUS.md`

For each artifact: drives a Codex session through the `shamt-validation-loop` skill, checks internal consistency, completeness, and cross-references. Results are posted as a PR comment; the job exits non-zero if any artifact fails.

### Running locally

```bash
# GitHub
export OPENAI_API_KEY=sk-...
export GITHUB_TOKEN=ghp_...
export GITHUB_REPOSITORY=owner/repo
export GITHUB_EVENT_PATH=/path/to/event.json
python .shamt/sdk/shamt-validate-pr.py --provider=github

# Azure Pipelines (local test)
export AZURE_DEVOPS_PAT=...
export SYSTEM_COLLECTIONURI=https://dev.azure.com/myorg
export SYSTEM_TEAMPROJECT=myproject
export BUILD_REPOSITORY_NAME=myrepo
export SYSTEM_PULLREQUEST_PULLREQUESTID=42
python .shamt/sdk/shamt-validate-pr.py --provider=ado
```

---

## Azure Pipelines (ADO)

### Enabling

```bash
cp .shamt/sdk/azure-pipelines/shamt-validate.yml.template azure-pipelines/shamt-validate.yml
cp .shamt/sdk/azure-pipelines/shamt-cron-janitor.yml.template azure-pipelines/shamt-cron-janitor.yml
```

**Permission prerequisites:** `$(System.AccessToken)` requires explicit "Contribute to pull requests" permission setup. See `.shamt/sdk/azure-pipelines/README.md` for full instructions.

---

## Stale-Work Scanner (Janitor)

### Enabling

Copy the workflow template:

```bash
cp .shamt/sdk/.github/workflows/shamt-cron-janitor.yml.template .github/workflows/shamt-cron-janitor.yml
```

Create the `shamt-janitor` label in your repository (Settings → Labels) before enabling `SHAMT_POST_ISSUE=true`.

### What it scans

| Scan | Default threshold |
|------|------------------|
| `design_docs/incoming/` proposals | >30 days since last commit |
| `design_docs/active/` design docs | >4 weeks since last commit |
| `.shamt/config/last_import.txt` | >4 weeks since last master import |

### Running locally

```bash
export GITHUB_TOKEN=ghp_...
export GITHUB_REPOSITORY=owner/repo
export SHAMT_POST_ISSUE=false   # dry run
python .shamt/sdk/shamt-cron-janitor.py
```

### Thresholds

Override via environment variables:

```bash
SHAMT_INCOMING_MAX_DAYS=45
SHAMT_ACTIVE_MAX_WEEKS=6
SHAMT_SYNC_MAX_WEEKS=6
```

---

## CI Credential Management

The `OPENAI_API_KEY` (or `ANTHROPIC_API_KEY`) must be set as a GitHub Actions secret:

1. Go to your repo → Settings → Secrets and variables → Actions → New repository secret
2. Name: `OPENAI_API_KEY`, Value: your key
3. Reference in workflow: `${{ secrets.OPENAI_API_KEY }}`

The Agents SDK reads the key from the environment by default. Do not hardcode the key in workflow files.

`GITHUB_TOKEN` is provided automatically by GitHub Actions with the permissions declared in the workflow (`pull-requests: write` for the validation gate, `issues: write` for the janitor). No additional secret setup is needed for GitHub API operations.

---

## Extending

Both scripts are self-contained and dependency-minimal. To add a new scan type to the janitor:

1. Add a `scan_*()` function returning `list[dict]` with keys `path`, `age_days`, `type`, `reason`
2. Call it in `main()` and extend `findings`

To validate additional artifact patterns in the PR gate:

1. Add a glob to `ARTIFACT_PATTERNS`
2. Optionally add an exclusion to `SKIP_PATTERNS` via the env var `SHAMT_SKIP_ARTIFACTS`
