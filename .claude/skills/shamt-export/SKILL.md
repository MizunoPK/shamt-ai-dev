<!-- Managed by Shamt — do not edit. Run regen-claude-shims.sh to regenerate. -->
---
name: shamt-export
description: >
  Exports generic guide and script improvements from a child project back to the
  shamt-ai-dev master repo via PR. Covers verifying CHANGES.md, comparing the
  rules file against RULES_FILE.template.md, scanning for epic tag contamination,
  running the guide audit, running the export script, and opening a PR.
triggers:
  - "run export"
  - "export to master"
  - "export workflow"
  - "export my changes"
source_guides:
  - guides/sync/export_workflow.md
master-only: false
---

## Overview

Export is how improvements you've made to shared guides and scripts flow back to the master Shamt repo for distribution to other projects.

Export when you have made improvements to files in `.shamt/guides/` or `.shamt/scripts/` that are:
- **Generic** — applicable to any Shamt project, not just this one
- **Deliberate** — an intentional improvement, not an accidental modification
- **Recorded** — documented in `.shamt/CHANGES.md`

Do not export if all your changes are in `.shamt/project-specific-configs/` — those are project-specific by definition and never exported.

Export typically happens after S11.P1 guide updates or after an audit that improved shared guides.

---

## When This Skill Triggers

- User says "run export", "export to master", "export workflow", or "export my changes"
- S11 guide-update work is complete and ready to share upstream
- User wants to submit guide improvements to the master repo

---

## Protocol

### Step 1: Verify CHANGES.md Is Current

Before exporting, confirm that `.shamt/CHANGES.md` accurately documents what you changed and why. PR reviewers will use this as context.

If entries are missing, add them now:

```markdown
## YYYY-MM-DD — [brief description]
- Modified: `.shamt/guides/path/to/file.md`
- Reason: [one line]
```

**Note:** Proposal docs in `.shamt/unimplemented_design_proposals/` do NOT require CHANGES.md entries — the export script moves them to master automatically and they are not modifications to shared files.

---

### Step 1.2: Compare Your Rules File Against the Template

The rules file (e.g., `CLAUDE.md`) lives outside `.shamt/` and is NOT exported automatically. Generic improvements you have added to it will not reach other Shamt projects unless you back-propagate them to `RULES_FILE.template.md` in the master repo.

Compare:
- Your rules file (wherever it lives for this AI service)
- `{master_repo}/scripts/initialization/RULES_FILE.template.md`

For each section in your rules file NOT in the template, ask: *would this apply to any Shamt project regardless of tech stack?*

**Signs of generic content (back-propagate to template):**
- Rules about Shamt workflow behavior (validation loops, stage transitions, missed requirements)
- Rules about how agents interact with Shamt system files
- Conventions that apply regardless of language or domain

**Signs of project-specific content (leave in rules file only):**
- References to your actual tech stack or test commands (`pytest`, `tsc --noEmit`, etc.)
- Historical context specific to this project
- Your project's epic tag as a literal value rather than `{{EPIC_TAG}}`

**If generic additions exist:**
1. Add the content to `RULES_FILE.template.md` in the master repo
2. Replace your epic tag with `{{EPIC_TAG}}` wherever it appears as a template variable
3. Add a CHANGES.md entry for the template modification

**If no generic additions:** Note "Rules file compared — no template updates needed" and proceed.

> Model delegation: Spawn Sonnet to read CHANGES.md and compare rules file against template.

---

### Step 1.5: Check for Epic Tag Contamination

Before running the audit, scan shared guides for your project's epic tag. If it appears inside `.shamt/guides/` files, those are contaminated and must not be exported.

```bash
grep -r "YOUR_EPIC_TAG-{N}" .shamt/guides/
# Example: grep -r "KAI-{N}" .shamt/guides/
```

If any matches are found:
1. **Stop** — do not proceed to Step 2 until resolved
2. For each affected file: revert the epic tag substitution back to `SHAMT-{N}`, preserving other legitimate changes
3. Re-run the grep to confirm zero matches before continuing

**What counts as contamination vs. acceptable:**
- Workflow instruction text with your epic tag instead of `SHAMT-{N}` — REVERT
- Attribution comments in file metadata (e.g., "Added from KAI-1 lessons learned") — acceptable, do not revert

> Model delegation: Spawn Haiku to grep for epic tag contamination.

---

### Step 2: Run the Full Guide Audit

Before exporting, run the guide audit on the entire `.shamt/guides/` tree (starting from `guides/audit/README.md`). The audit must achieve **3 consecutive clean rounds** (≤1 LOW per round) before proceeding to Step 3.

This step is **mandatory**. Exporting without a full audit risks submitting changes that are internally inconsistent with other guides.

---

### Step 3: Run the Export Script

From the project root:

```bash
# Preview what would change without modifying master:
bash .shamt/scripts/export/export.sh --dry-run

# Apply the export:
bash .shamt/scripts/export/export.sh
```

The script:
1. Reads the master path from `.shamt/shamt_master_path.conf`
2. Warns if master's working tree has uncommitted changes
3. Compares your `guides/` and `scripts/` against master by content
4. Copies all differing files to master; deletes from master any files absent from your child
5. Excludes `guides/audit/outputs/` (your audit history stays local)
6. Moves any files in `.shamt/unimplemented_design_proposals/` to master's `design_docs/incoming/`
7. Prints a summary of what was copied, deleted, and moved

Review the output. If files were exported that you didn't intend to change, investigate before opening a PR.

**If proposal files were moved**, commit the deletions in your child project before proceeding:

```bash
git add -A .shamt/unimplemented_design_proposals/
git commit -m "docs(proposals): Move guide update proposals to master"
```

**If export script fails with "Master directory not found":**
Update `.shamt/shamt_master_path.conf` with the current path to your local `shamt-ai-dev` clone.

> Model delegation: Spawn Haiku to run the export script and verify file existence.

---

### Step 4: Open a PR in shamt-ai-dev

```bash
cd /path/to/shamt-ai-dev

git checkout main
git checkout -b feat/child-sync-YYYY-MM-DD
git add -A .shamt/guides/ .shamt/scripts/
git commit -m "sync: [use the message printed by the export script]"
git push origin feat/child-sync-YYYY-MM-DD
```

The export script prints a ready-to-use commit message in its "Next steps" output — copy it exactly. If `gh` CLI is available, the script also prints a ready-to-run `gh pr create` command.

**PR description template:**

```markdown
## Summary
<!-- Brief description of what improved and why -->

## Changes
<!-- Paste relevant entries from .shamt/CHANGES.md -->

## Source project
<!-- Optional: which project contributed this improvement -->
```

---

### Step 5: PR Review

The master repo maintainer reviews the PR diff:
- **Approves** if the changes are genuinely generic and improve the guide system
- **Requests changes** if project-specific content has leaked into shared files
- **Rejects** if the change is specific to your project or contradicts a Shamt design decision

After the PR is merged, the improvement is available to all Shamt projects on their next import.

---

## Exit Criteria

Export workflow is complete when ALL of the following are true:

- [ ] CHANGES.md verified current with all guide changes documented
- [ ] Rules file compared against RULES_FILE.template.md; generic additions back-propagated
- [ ] Epic tag contamination check passed (zero matches in shared guides)
- [ ] Full guide audit passed: 3 consecutive clean rounds (≤1 LOW each)
- [ ] Export script run; output reviewed; no unintended exports
- [ ] Proposal files committed (if any were moved by export script)
- [ ] PR opened in shamt-ai-dev with CHANGES.md content in description
- [ ] PR reviewed and approved by master maintainer (may be async)

---

## Quick Reference

### The separation rule

| Content type | Export? |
|---|---|
| Generic workflow clarification | Yes |
| New guide section for a workflow gap | Yes |
| Corrected procedure | Yes |
| New template or reference file | Yes |
| Proposal docs from `unimplemented_design_proposals/` | Yes (always) |
| Examples using your project's actual code/filenames | No |
| Guide customizations for your tech stack only | No |
| Test command overrides or language-specific instructions | No |
| Content in `project-specific-configs/` | No (never exported by script) |
| Files in `.shamt/skills/`, `.shamt/agents/`, `.shamt/commands/` | No (master-authored one-way imports — propose via CHANGES.md instead) |

### CHANGES.md is the PR description

Write CHANGES.md entries at the time you make changes — not at export time. Think of it as the PR description written incrementally. Reviewers use it as context for the diff.

### Model selection

- Run export script, verify files, grep for contamination: Haiku
- Read CHANGES.md, compare rules file against template: Sonnet
- Review changes, separation rule decisions, PR content: Opus (primary)
