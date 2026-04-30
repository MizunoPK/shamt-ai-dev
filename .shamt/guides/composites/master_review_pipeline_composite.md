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
- Separation rule: `guides/sync/README.md` (separation rule section)

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
