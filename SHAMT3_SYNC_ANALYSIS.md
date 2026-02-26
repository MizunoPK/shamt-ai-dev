# SHAMT-3 Sync Flow — Current State Analysis

**Purpose:** Narrative description of what the sync system currently does, so gaps can be identified
**Source:** Direct reading of all four scripts and three sync guides, 2026-02-25

---

## Overview

The sync system has two directions:

- **Export:** Child project → Master repo (child contributes an improvement)
- **Import:** Master repo → Child project (child receives upstream updates)

Each direction has a bash script (Linux/Mac) and a PowerShell script (Windows), plus a guide. There is no automation linking export and import — both require the user to manually trigger the script.

---

## Export Flow

### What triggers it

A child project has improved one or more shared guides or scripts and wants to contribute those improvements back to master so other projects can benefit. The guide (`export_workflow.md`) requires three preconditions before running the script:

1. The changes are generic (applicable to any Shamt project)
2. CHANGES.md is current — every modified file is documented with a reason
3. The guide audit has been run on every modified file and passed

### What the script does

The script (`export.sh` / `export.ps1`) runs from the child project root. It:

1. Reads `.shamt/shamt_master_path.conf` to locate the master repo on disk. Exits with an error if the file is missing or the path doesn't exist.

2. Iterates through every file in the child's `.shamt/guides/` and `.shamt/scripts/` trees.

3. For each file, compares it against the corresponding file in master:
   - If the file does not exist in master → copies it to master (new file)
   - If the file differs from master → copies it to master (update)
   - If the file is identical → skips it
   - Bash uses `diff -q` for comparison; PowerShell uses MD5 hash

4. Always skips `guides/audit/outputs/` — audit output history is child-specific and never exported.

5. Prints a summary of what was copied.

6. Prints next steps, which tell the user to go to the master repo, create a branch (`feat/child-sync-YYYY-MM-DD`), commit the changes, and open a PR.

**What the script does NOT do:**
- It does not detect files that exist in master but have been deleted from the child. A child deletion is invisible to the export — only additions and modifications are propagated.
- It does not check master's git status before writing. If master has uncommitted changes, they are mixed with the exported files.
- It does not check which branch master is currently on. The next steps suggest branching from wherever HEAD is.

### What happens after the script

The user manually:
1. Goes to the master repo
2. Creates a branch and commits the exported files
3. Opens a PR against `main`

The master maintainer (or agent) reviews the PR diff, checking whether the changes are genuinely generic. If they are, the PR is merged. If project-specific content has leaked into shared files, the maintainer requests changes.

After merging, the master maintainer is expected to run a guide audit on the changed files before considering the merge complete. This step is documented in `CLAUDE.md` but has no enforcement mechanism.

---

## Import Flow

### What triggers it

A child project wants to pull in upstream improvements from master. The sync guide recommends doing this at the start of a new epic or when guides feel stale. The user checks `.shamt/last_sync.conf` to see when they last synced, then decides whether to run the import.

### What the script does

The script (`import.sh` / `import.ps1`) runs from the child project root. It:

1. Reads `.shamt/shamt_master_path.conf` to locate the master repo. Same error handling as export.

2. **Freshness check:** Attempts to `git fetch origin main` on the master repo. If master's local `main` is behind `origin/main`, it warns the user and asks whether to proceed anyway. If the fetch fails (no remote, offline), it silently skips the check and continues. This ensures the child doesn't import a stale master.
   - Note: In `import.ps1`, the "proceed anyway" prompt calls `Prompt-Input`, which is not defined anywhere in the script. This crashes on Windows when the freshness warning triggers.

3. **Copy phase:** Iterates through every file in master's `.shamt/guides/` and `.shamt/scripts/` trees.
   - New files (exist in master, not in child) → copied to child, recorded as "new"
   - Changed files (differ between master and child) → a unified diff is recorded, then the file is copied to child
   - Identical files → skipped
   - Always skips `guides/audit/outputs/`

4. **Delete phase:** Iterates through every file in the child's `.shamt/guides/` and `.shamt/scripts/` trees. Any file that exists in the child but not in master is deleted from the child. This propagates master deletions. Also skips `guides/audit/outputs/`.
   - Empty parent directories are not removed after deletion.

5. **Diff file generation:** All recorded diffs are assembled into one or more `import_diff.md` files, split at section boundaries to stay under 1000 lines each. Written to `.shamt/import_diff.md` (or `import_diff_1.md`, `import_diff_2.md`, etc.). These files are not gitignored.

6. **Summary:** Prints a list of updated and deleted files.

7. **Agent prompt:** Prints a ready-to-paste prompt for the user to send to their AI agent, instructing it to read the validation loop protocol, review the diffs, check supplements, check pointers, run a 3-consecutive-clean-round validation loop, and delete the diff files when done.

8. **`last_sync.conf`:** Writes the current date and master's HEAD commit hash to `.shamt/last_sync.conf`. This file is gitignored. Written at the very end of the script — if the script is killed after syncing but before this line, the sync date is not recorded.

### What the agent does after the script

The import guide (`import_workflow.md`) describes six steps the agent performs:

1. **Re-read validation loop protocol** — mandatory before doing anything else.

2. **Read the import diffs** — understand exactly what changed in each shared file.

3. **Check supplements** — for each changed file, verify that this project's `project-specific-configs/` supplements are still accurate and consistent with the new guide content.

4. **Check pointers** — for each changed file, verify that existing pointer notes are still correctly placed. Check whether new extension points in the changed guides warrant new supplements.

5. **Handle new files and deletions** — read new files, assess whether supplements are needed. Check whether any deleted guides had associated supplements that should also be removed.

6. **Run a validation loop** — 3 consecutive zero-issue rounds using the master protocol.

After passing the validation loop, the agent deletes the diff files and commits the import.

---

## The Full Cycle

```
Child improves a shared guide
         |
         v
Document in .shamt/CHANGES.md
         |
         v
Run guide audit on modified files (mandatory pre-flight)
         |
         v
Run export script → copies additions/modifications to master working tree
         |
         v
User manually: checkout master, create branch, commit, open PR
         |
         v
Master maintainer reviews PR (is it generic?) + runs guide audit on changed files
         |
         v
PR merged to main
         |
         v
Other projects: run import script → copies additions/modifications/deletions from master
         |
         v
Agent runs import validation (supplement check, pointer check, validation loop)
         |
         v
Agent commits import result
         |
         v
Project is up to date
```

---

## What the System Covers

- **Additions and modifications:** Fully automated in both directions. Export copies changed files to master; import copies changed files from master to child.
- **Deletions master→child:** Fully handled by import's delete phase.
- **Deletions child→master:** Not handled. A child deleting a shared file has no mechanism to propose that deletion to master.
- **Audit outputs:** Excluded in both directions — correctly treated as child-local.
- **project-specific-configs/:** Never touched by either script — correctly excluded.
- **epics/:** Not included in either script's scope — correctly excluded.
- **Freshness gating:** Import checks that master is up to date before pulling. Export has no equivalent check on master's state.
- **Diff visibility:** Import provides a unified diff for every changed file so the agent can see exactly what changed. Export provides no equivalent diff — the maintainer reviews the PR diff directly in git.
- **last_sync.conf:** Records when the last import happened. No equivalent for export (no record of when a child last contributed).

---

## Asymmetries Between Export and Import

| Concern | Export | Import |
|---------|--------|--------|
| Deletion propagation | Not implemented | Fully implemented |
| Freshness check | None | Yes (master vs origin/main) |
| Pre-flight validation | Guide audit (manual, guide-enforced) | None (handled post-import by agent) |
| Diff output for review | None (reviewer uses git diff in PR) | Generated and written to disk |
| State record | None | `last_sync.conf` |
| Master branch check | None | N/A |
| Master working tree check | None | N/A |
