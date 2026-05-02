# Shamt Azure Pipelines Templates

Azure Pipelines equivalents of the GitHub Actions workflow templates from SHAMT-43.

---

## Prerequisites

### 1. Grant "Contribute to pull requests" permission

`$(System.AccessToken)` does **not** have PR comment or status permissions by default.

1. Go to **Project Settings** → **Repositories** → select your repository → **Permissions**
2. Find **`{ProjectName} Build Service ({OrgName})`** (project-scoped, recommended)
3. Set **Contribute to pull requests** → **Allow**

### 2. Enable "Allow scripts to access the OAuth token"

In the pipeline job settings (classic UI: Agent job → Additional options; YAML: set at job or step level):

```yaml
# In your pipeline YAML, add at the job level:
jobs:
  - job: ShamtValidate
    pool:
      vmImage: 'ubuntu-latest'
    variables:
      - group: shamt-secrets
    steps:
      # ... your steps
```

Or enable the checkbox in the classic pipeline editor: **Agent job** → **Additional options** → ✅ **Allow scripts to access the OAuth token**.

### 3. Add OPENAI_API_KEY secret

1. Go to **Pipelines** → **Library** → **Variable groups** → create group `shamt-secrets`
2. Add variable `OPENAI_API_KEY` (mark as secret)
3. Link the variable group to your pipeline

---

## PR Validation Gate

### Enabling

Copy the template to your pipeline definitions:

```bash
cp .shamt/sdk/azure-pipelines/shamt-validate.yml.template azure-pipelines/shamt-validate.yml
```

Then create the pipeline in ADO: **Pipelines** → **New Pipeline** → **Azure Repos Git** → select the YAML file.

Add a **Build Validation branch policy** on your target branch (e.g., `main`):
- **Project Settings** → **Repositories** → **Policies** → **Branch Policies** → `main`
- Add **Build Validation** → select the Shamt Validate pipeline

### What it validates

Same artifact patterns as the GitHub Actions variant:
- `**/*_DESIGN.md`
- `**/*_VALIDATION_LOG.md`
- `**/*spec*.md` / `**/*SPEC*.md`
- `**/AGENT_STATUS.md`

Results are posted as PR comment threads. The pipeline sets a PR status (`succeeded`/`failed`) that can be required by branch policy.

### Label gate (recommended for high-PR-volume repos)

To avoid running on every PR, add a condition to the pipeline trigger or use ADO branch policies to require the label `needs-shamt-review` before the pipeline fires (via a Service Hook or a policy that checks labels).

---

## Stale-Work Scanner (Janitor)

### Enabling

```bash
cp .shamt/sdk/azure-pipelines/shamt-cron-janitor.yml.template azure-pipelines/shamt-cron-janitor.yml
```

Create the pipeline in ADO (same steps as above). The schedule (`cron: '0 8 * * 1'`) runs every Monday at 8 AM UTC.

When `SHAMT_POST_ISSUE=true`, the janitor creates an ADO Work Item (Bug type) tagged `shamt-janitor`. It closes the previous open item before creating a new one.

### Thresholds

Override via variables in the pipeline or variable group:

```yaml
variables:
  SHAMT_INCOMING_MAX_DAYS: '45'
  SHAMT_ACTIVE_MAX_WEEKS: '6'
  SHAMT_SYNC_MAX_WEEKS: '6'
```

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `TF401027: You need the Git 'PullRequestContribute' permission` | Build service account lacks PR write permission | See Prerequisites step 1 |
| `$(System.AccessToken)` is empty | OAuth token not enabled for the pipeline job | See Prerequisites step 2 |
| `OPENAI_API_KEY not set` | Secret not linked to pipeline | See Prerequisites step 3 |
| PR threads not appearing | Token has read-only scope | Verify "Contribute to pull requests" is set to **Allow** (explicit), not inherited |
