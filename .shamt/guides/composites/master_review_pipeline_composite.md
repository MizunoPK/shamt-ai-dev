# Master Review Pipeline Composite

**What this is:** The full master repo review pipeline assembled from its component
parts — label trigger, `shamt-master-reviewer` skill, guide audit skill, and PR comment
posting. Covers both the automated Codex Cloud path (SHAMT-43) and the Claude Code
interactive path.

**Note:** This composite covers both child PR review (code changes, guide changes) and
master-side review routines. It does not need a separate "Master Dev Variant" section
because the master repo IS the subject of this composite.

---

## Component Map

| Component | Where it lives | Role |
|-----------|---------------|------|
| `shamt-master-reviewer` skill | `.shamt/skills/shamt-master-reviewer/SKILL.md` | Checks separation rule, guide quality, merge fitness |
| `shamt-code-reviewer` agent | `.shamt/agents/shamt-code-reviewer.yaml` | Formal code review for code changes |
| `shamt-guide-auditor` agent | `.shamt/agents/shamt-guide-auditor.yaml` | Guide audit on imported changes |
| `master-reviewer-workflow.yml` | `.shamt/host/codex/master-reviewer-workflow.yml.template` | Codex Cloud: PR label → cloud task → review comment |
| `/shamt-audit` command | `.shamt/commands/` | Guide audit entry point |
| `/loop` (Claude Code) | Built into Claude Code CLI | Drives multi-round review iterations |

**Primitive home guides:**
- Code review workflow: `guides/code_review/code_review_workflow.md`
- Guide audit workflow: `guides/audit/`
- Separation rule: `guides/sync/separation_rule.md`

---

## How the Pieces Work Together

### Trigger: PR labeled `needs-shamt-review`

**Codex Cloud path (automated):**
1. PR is labeled `needs-shamt-review` on GitHub
2. `master-reviewer-workflow.yml` fires a Codex Cloud task with `shamt-master-reviewer`
   profile
3. Task loads the skill, reads the PR diff via GitHub API
4. Posts a draft review comment with:
   - Separation rule compliance verdict (pass/fail)
   - For guide changes: quality assessment and merge fitness
   - For code changes: routes to `shamt-code-reviewer` for formal review
5. On task failure: posts a retry comment (not silent failure)

**Claude Code interactive path:**
1. PR arrives (GitHub notification or user reports it)
2. User or operator runs `/shamt-validate` on the PR diff, or invokes
   `shamt-master-reviewer` skill directly
3. If a long review with multiple rounds: use `/loop` to self-pace the review iterations
   (ScheduleWakeup between rounds)
4. Output: formal review in `.shamt/code_reviews/<branch>/review_vN.md` (for code) or
   direct comment in the PR (for guide changes)

### Separation Rule Check

For every child PR with guide changes, the reviewer checks:
- Are the changed files in `guides/` (shared) or `epics/` (child-only)?
- Do any shared guide changes contain project-specific content (team names, project IDs,
  child-repo paths, specific S1-S11 epic IDs)?
- If project-specific content leaked: request changes before merging

### Post-Merge Audit

After merging a child PR that changes guides, run a full guide audit on the entire
`.shamt/guides/` tree (not just the changed files):

```
/shamt-audit .shamt/guides/
```

The audit must achieve 3 consecutive clean rounds before the merge is considered complete
and the changes can propagate to other child projects on their next import.

### Guide Audit with `/loop` (Claude Code)

The guide audit is a natural candidate for `/loop` driving — each round checks a
different dimension set and the loop runs until 3 consecutive clean rounds:

```
ScheduleWakeup(
    delaySeconds=60,  # Guide audits are slower than spec validation
    reason="guide audit round N complete — consecutive_clean=X; firing next round",
    prompt="Continue guide audit — run next round"
)
```

The stall-detector hook fires on each audit log edit. If audit is stalled (0 clean rounds
for ≥3 consecutive rounds), a `STALL_ALERT.md` is written.

---

## Codex Side (SHAMT-43)

The automated review workflow was designed in SHAMT-43. Key files:
- Template: `.shamt/host/codex/master-reviewer-workflow.yml.template`
- Copy to: `.github/workflows/master-reviewer.yml`
- Requires: `OPENAI_API_KEY` secret + `GITHUB_TOKEN` (automatic)
- Trigger: label `needs-shamt-review` applied to any PR

Full detail: `guides/sync/export_workflow.md` (child side) and
`guides/sync/import_workflow.md` (post-import validation).

---

## ADO-Hosted Variant (SHAMT-46)

For projects where the master repo and/or child projects are hosted on Azure DevOps.

**Reference:** For full ADO PR review setup, trigger options, thread statuses, and voting conventions, see: `.shamt/guides/reference/ado_pr_review_workflow.md`

### Scenario 1: GitHub master + ADO child

The child submits a PR to the master GitHub repo (via fork or mirror). The existing GitHub-based master review pipeline works as-is:
- Master reviewer runs on the GitHub PR (unchanged)
- Child team reads GitHub PR comments (requires GitHub access for ADO-primary teams)
- No changes to the review pipeline needed

### Scenario 2: Fully ADO-hosted (master + child both on ADO)

The master reviewer operates on ADO PRs using the ADO MCP Server instead of `@codex`:

**Trigger options** (from `ado_pr_review_workflow.md`):
- **Option B (CI pipeline):** Azure Pipelines runs `shamt-validate-pr.py --provider=ado` on PR creation. Copy `.shamt/sdk/azure-pipelines/shamt-validate.yml.template` and add a Build Validation branch policy.
- **Option C (Service Hook):** ADO Service Hook → external endpoint → headless agent session. Closest analog to `@codex` on GitHub; requires external infrastructure.

**Review execution:** The same `shamt-master-reviewer` skill, guide audit skill, and separation rule logic apply — they are provider-agnostic and operate on diffs. Only the I/O layer changes:
1. Agent reads PR diff via `mcp_ado_repo_get_pull_request_changes`
2. Runs separation rule check and guide audit on changed files
3. Posts review findings as ADO comment threads (`mcp_ado_repo_create_pull_request_thread`)
4. Casts reviewer vote (`waitForAuthor` or `approveWithSuggestions`)

**Post-merge audit:** After merging a child PR, run the full guide audit (same as GitHub path):
```
/shamt-audit .shamt/guides/
```

### Cross-Provider Setup

To support both GitHub and ADO, run init with `--pr-provider=both`. Both the ADO MCP Server and the GitHub Actions/Azure Pipelines templates will be configured. The regen scripts register both in host settings when `pr_provider.conf` contains `both`.
