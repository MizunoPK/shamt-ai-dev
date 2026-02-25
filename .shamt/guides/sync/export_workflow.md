# Shamt Export Workflow

Export is how improvements you've made to shared guides and scripts flow back to the master Shamt repo for distribution to other projects.

---

## When to Export

Export when you have made improvements to files in `.shamt/guides/` or `.shamt/scripts/` that are:

- **Generic** — applicable to any Shamt project, not just this one
- **Deliberate** — an intentional improvement, not an accidental modification
- **Recorded** — documented in `.shamt/CHANGES.md`

Export typically happens after S10.P1 guide updates or after an audit that improved shared guides.

Do not export if all your changes are in `.shamt/project-specific-configs/` — those are project-specific by definition and never exported.

---

## Step 1: Verify Your CHANGES.md Is Current

Before exporting, confirm that `.shamt/CHANGES.md` accurately documents what you changed and why. PR reviewers will use this as context.

If entries are missing, add them now:

```markdown
## YYYY-MM-DD — [brief description]
- Modified: `.shamt/guides/path/to/file.md`
- Reason: [one line]
```

---

## Step 1.5: Run the Full Guide Audit

Before exporting, run the guide audit on the entire `.shamt/guides/` tree (starting from `guides/audit/README.md`). The audit must achieve 3 consecutive zero-issue rounds before you proceed to Step 2.

This step is **mandatory**. Exporting without a full audit risks submitting changes that are internally inconsistent with other guides — cross-references, terminology, or workflow descriptions may need to be updated in files you didn't directly modify.

---

## Step 2: Run the Export Script

From the project root:

```bash
bash .shamt/scripts/export/export.sh
# or on Windows:
# & ".shamt\scripts\export\export.ps1"
```

The script:
1. Reads the master path from `.shamt/shamt_master_path.conf`
2. Compares your `guides/` and `scripts/` against master by content comparison
3. Copies all differing files to the master repo
4. Excludes `guides/audit/outputs/` (your audit history stays local)
5. Prints a summary of what was copied

Review the output. If files were exported that you didn't intend to change, investigate before opening a PR.

---

## Step 3: Open a PR in shamt-ai-dev

```bash
cd /path/to/shamt-ai-dev

git checkout main
git checkout -b feat/child-sync-YYYY-MM-DD
git add -A .shamt/guides/ .shamt/scripts/
git commit -m "sync: [brief description of improvement]"
git push origin feat/child-sync-YYYY-MM-DD
```

Then open a PR against `main` in the shamt-ai-dev repository.

**PR description should include:**
- A brief summary of what changed and why
- The relevant entries from your `.shamt/CHANGES.md`
- Which project contributed the improvement (if you want attribution)

---

## Step 4: PR Review

The master repo maintainer (or agent) reviews the PR diff:

- **Approves** if the changes are genuinely generic and improve the guide system
- **Requests changes** if project-specific content has leaked into shared files
- **Rejects** if the change is specific to your project or contradicts a Shamt design decision

After the PR is merged, the improvement is available to all Shamt projects on their next import.

---

## What Makes a Good Export

**Good to export:**
- A clarification that prevents a common agent mistake
- A new guide section that addresses a workflow gap
- A corrected procedure that was previously wrong or ambiguous
- A new template or reference file

**Do not export:**
- Examples using your project's actual code, filenames, or APIs
- Guide customizations that only make sense for your tech stack
- Test command overrides or language-specific instructions
- Content in `project-specific-configs/` (never exported by the script)

---

## Common Situations

**Export script fails with "Master directory not found":**
`.shamt/shamt_master_path.conf` is stale — the master repo has moved or you're on a different machine. Update the file with the current path to your local `shamt-ai-dev` clone:

```bash
echo "/path/to/shamt-ai-dev" > .shamt/shamt_master_path.conf
```

---

## Relationship to CHANGES.md

`CHANGES.md` is written during S10 and audit work, at the time you make the change. The export workflow uses it at export time. Think of it as the PR description written incrementally as you work.

If you export without a complete `CHANGES.md`, reviewers have no context for the diff. Keep it current.
