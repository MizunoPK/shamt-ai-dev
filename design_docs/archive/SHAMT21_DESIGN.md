# SHAMT-21 Design: Cross-Machine Shamt Storage Sync

**Status:** Draft
**Branch:** `feat/SHAMT-21`

---

## Problem

In a child Shamt project, `.shamt/` and the AI rules file (e.g., `CLAUDE.md`) are typically
gitignored — deliberately kept out of the project repo to avoid leaking agent state into
version control. This is correct behavior for a production codebase.

The consequence: when a user works on the same project from multiple machines (home desktop,
laptop, work computer), these files do not follow them. On each new machine the user must
re-initialize from scratch, losing accumulated epic state, guide customizations, project-specific
configs, and ongoing in-progress work. There is no mechanism today to transfer Shamt state
between machines.

The workaround of temporarily un-gitignoring `.shamt/` and pushing to the project repo is
fragile, accidental-disclosure-prone, and requires manual cleanup.

---

## Solution

Add two scripts — **store** and **get** — to a new `.shamt/scripts/storage/` directory.
These scripts use a dedicated "Storage repo" (an ordinary git repo the user owns and clones on
each machine) as a neutral carrier for Shamt state. The Storage repo is separate from both the
Shamt master repo and the child project repo.

```
Child project ──store──► Storage repo (subfolder) ──push──► remote
Child project ◄──get──── Storage repo (subfolder) ◄──pull── remote
```

The user clones the Storage repo on each machine at any path they choose. Each child project
gets its own subfolder inside the Storage repo, named after the child project's root directory.

A `.conf` file in the child project's `.shamt/` records the local path to the Storage repo
clone. If the `.conf` file is absent, the AI agent asks the user for the path and saves it
before running the script.

**Example** (from the user's environment):
- Child project: `~/code/FantasyFootballHelperScripts/`
- Storage repo:  `~/code/RemoteStorage/`
- Subfolder in Storage: `~/code/RemoteStorage/FantasyFootballHelperScripts/`

---

## Store Script Behavior

Trigger phrase examples: "store the shamt files", "backup shamt to storage",
"push shamt files to storage", "save shamt state".

Steps:

1. Read `.shamt/storage_path.conf`. If missing, halt with an error directing the agent to ask
   the user for the path (the agent then creates the `.conf` file and re-runs the script).
2. Validate the Storage repo path exists on disk.
3. Derive the project subfolder name from the child project's root directory name (basename of
   the absolute project root path).
4. Create `{StorageRepo}/{ProjectName}/` if it does not exist.
5. Sync `.shamt/` to `{StorageRepo}/{ProjectName}/.shamt/` using rsync-style copy:
   - Copy all files and directories from `.shamt/`
   - **Exclude** machine-specific conf files: `storage_path.conf`,
     `shamt_master_path.conf`, `rules_file_path.conf`
   - **Exclude** temporary import diff files: `import_diff*.md`
   - Delete files in the destination that no longer exist in the source (mirror sync)
6. Detect and copy AI rules files from the project root to
   `{StorageRepo}/{ProjectName}/`. Known locations (copy each that exists):
   - `CLAUDE.md` (Claude Code)
   - `.github/copilot-instructions.md` (GitHub Copilot)
   - `.cursorrules` (Cursor)
   - `.windsurfrules` (Windsurf)
   - `GEMINI.md` (Gemini) — add as discovered
7. In the Storage repo: stage all changes, commit with message
   `sync: {ProjectName} — {YYYY-MM-DD}`, push to remote.
8. Print a summary of what was copied and whether the push succeeded.

---

## Get Script Behavior

Trigger phrase examples: "get the shamt files from storage", "restore shamt from storage",
"pull shamt files", "sync shamt from storage".

Steps:

1. Read `.shamt/storage_path.conf`. If missing, halt with an error directing the agent to ask
   the user for the path.
2. Validate the Storage repo path exists on disk.
3. Check the Storage repo for uncommitted changes (`git -C {StorageRepo} diff --quiet && git
   -C {StorageRepo} diff --cached --quiet`). If the Storage repo is dirty (uncommitted changes
   detected), halt with an error: the Storage repo is in an inconsistent state — the user must
   investigate and clean it up before a get can proceed. Unlike `export.sh` (which warns and
   continues when the destination has uncommitted changes), the get script halts here because a
   dirty source repo means the local state may be partially written or manually edited, and
   proceeding with that state could restore corrupted data.
4. Attempt `git -C {StorageRepo} pull`. If the pull fails (no remote configured, no network),
   print a warning and continue with the local Storage repo state — do not halt. This mirrors
   the pattern in `import.sh` where the freshness check is wrapped in a conditional `if git
   fetch ... ; then ... else warn and continue ... fi`.
5. Derive the project subfolder name from the child project's root directory name.
6. Validate `{StorageRepo}/{ProjectName}/` exists. If missing, halt with a clear error:
   the project has not been stored yet — the user should run store first on their other machine.
7. Print what will be overwritten: list the local `.shamt/` contents and any local rules files
   that would be replaced. Then, unless `--force` is passed, require interactive stdin
   confirmation before proceeding. When run through an agent, the agent handles confirmation
   in chat and passes `--force` to skip the stdin prompt (see Agent Procedure).
8. Copy `{StorageRepo}/{ProjectName}/.shamt/` → child project `.shamt/`:
   - Mirror sync: copy all files, delete local files that no longer exist in storage
   - **Preserve** these files if they already exist locally (excluded from sync — neither overwritten nor deleted):
     - `.shamt/storage_path.conf` — keep the local version (path differs per machine)
     - `.shamt/shamt_master_path.conf` — keep the local version (path differs per machine)
     - `.shamt/rules_file_path.conf` — keep the local version (absolute path to rules file differs per machine; created by `init.sh`)
     - `.shamt/import_diff*.md` — keep any local import diff files; they are not in Storage (excluded on store) and should not be silently deleted by the mirror sync's `--delete` behavior
9. Copy AI rules files from `{StorageRepo}/{ProjectName}/` to their correct project locations
   (inverse of store — CLAUDE.md → project root, copilot-instructions.md → `.github/`, etc.).
10. Print a summary of what was restored.

---

## Configuration File

**Path:** `.shamt/storage_path.conf`
**Content:** A single line: the absolute path to the Storage repo root (no trailing newline,
whitespace trimmed on read — matches the convention of `shamt_master_path.conf`).

**Example:**
```
/home/kai/code/RemoteStorage
```

This file is machine-specific and must NOT be committed to the Storage repo (excluded by the
store script). It is also already gitignored in the child project along with the rest of
`.shamt/`, so no additional gitignore configuration is needed.

---

## Storage Repo Structure

The Storage repo is an ordinary git repo the user creates and clones on each machine.
Its internal structure is entirely managed by the store/get scripts. The user does not
manually edit it.

```
RemoteStorage/
├── FantasyFootballHelperScripts/
│   ├── .shamt/
│   │   ├── epics/
│   │   ├── guides/
│   │   ├── scripts/
│   │   ├── project-specific-configs/
│   │   ├── last_sync.conf
│   │   └── ...
│   └── CLAUDE.md
├── AnotherProject/
│   ├── .shamt/
│   └── CLAUDE.md
└── (other projects ...)
```

The Storage repo has no Shamt framework of its own. It is a plain git repo used purely as a
file carrier. No `.shamt/` folder exists at its root — only per-project subfolders.

---

## AI Agent Integration

### Trigger Recognition

The rules file template (`RULES_FILE.template.md`) must include a **Shamt Storage Sync** section
describing the trigger phrases and the agent procedure. Child project rules files inherit this
section when initialized from the updated template. Existing child projects receive the section
on their next `import.sh` run (which updates the guides and scripts but NOT the rules file
directly — the rules file must be manually updated or re-initialized; see Open Questions OQ3).

### Agent Procedure (Store)

When a store trigger phrase is detected:

1. Check if `.shamt/storage_path.conf` exists.
2. If **missing**: ask the user — "What is the path to your Storage repo? (e.g., `/home/you/RemoteStorage`)" — save their answer to `.shamt/storage_path.conf`.
3. Run `bash .shamt/scripts/storage/store.sh` (or `store.ps1` on Windows).
4. Report the script output to the user.

### Agent Procedure (Get)

When a get trigger phrase is detected:

1. Check if `.shamt/storage_path.conf` exists.
2. If **missing**: ask the user — "What is the path to your Storage repo? (e.g., `/home/you/RemoteStorage`)" — save their answer to `.shamt/storage_path.conf`.
3. Show the user what will be overwritten: list local `.shamt/` contents and any local rules files that would be replaced. Ask the user to confirm before proceeding ("The get will overwrite your local `.shamt/` and rules files with the version from storage. Proceed? (y/N)").
4. Once the user confirms in chat, run `bash .shamt/scripts/storage/get.sh --force` (or `get.ps1 -Force` on Windows). The `--force` flag skips the script's own stdin prompt since the agent already confirmed with the user in chat.
5. Report the script output to the user.

---

## What Is and Is NOT Stored

### Stored (everything in `.shamt/` except exclusions below)

- `epics/` — all epic folders including in-progress work, EPIC_TRACKER.md
- `guides/` — all stage guides and reference material
- `scripts/` — all export/import/storage scripts
- `project-specific-configs/` — ARCHITECTURE.md, CODING_STANDARDS.md, etc.
- `last_sync.conf` — date and hash of last master import (portable: contains a sync date and git hash, not a machine-specific path)
- Any other `.shamt/` files not in the exclusion list

### NOT Stored (machine-specific or temporary)

| File | Reason |
|------|--------|
| `.shamt/storage_path.conf` | Machine-specific path — different on every machine |
| `.shamt/shamt_master_path.conf` | Machine-specific path — different on every machine |
| `.shamt/rules_file_path.conf` | Machine-specific absolute path to the AI rules file — created by `init.sh`, differs per machine |
| `.shamt/import_diff*.md` | Temporary files generated by import script — not persistent state |

### Rules files (stored at project root or canonical location)

Copied by name and restored to their canonical location:

| File | Location | Service |
|------|----------|---------|
| `CLAUDE.md` | Project root | Claude Code |
| `.github/copilot-instructions.md` | `.github/` subdir | GitHub Copilot |
| `.cursorrules` | Project root | Cursor |
| `.windsurfrules` | Project root | Windsurf |
| `GEMINI.md` | Project root (assumed) | Gemini — add as confirmed in `ai_services.md` |

Only files that actually exist in the project are stored. Files not present are not created.

---

## Affected Files

### New

- `.shamt/scripts/storage/store.sh` — bash store script
- `.shamt/scripts/storage/store.ps1` — PowerShell store script
- `.shamt/scripts/storage/get.sh` — bash get script
- `.shamt/scripts/storage/get.ps1` — PowerShell get script
- `.shamt/scripts/storage/README.md` — usage and design notes

### Modified

- `.shamt/scripts/initialization/RULES_FILE.template.md`
  - Add a **Shamt Storage Sync** section describing trigger phrases and agent procedure
  - Place it near the existing **Shamt Sync** section for locality

- Root `README.md`
  - Add a brief mention of the storage sync feature in the project structure / usage sections

- `.shamt/guides/sync/import_workflow.md`
  - Add a new step (after the existing "Check for New Files and Deletions" step) that handles
    `RULES_FILE.template.md` changes: "If `scripts/initialization/RULES_FILE.template.md`
    appears in the import diff, compare the new template against your project's rules file.
    Apply any new sections that are absent from your rules file. This is how new agent
    capabilities (e.g., new trigger phrases) reach existing child projects after an import."
  - Place this as its own named step so it is not skipped as part of the general supplement
    check — `RULES_FILE.template.md` is a template, not a guide, and the supplement/pointer
    logic does not apply to it

- `CLAUDE.md` (master-only, not propagated via import)
  - No change needed — master dev workflow does not use Storage sync (Storage is for child projects)

- `.shamt/scripts/initialization/init.sh` (and `init.ps1`)
  - No change needed — `init.sh` copies `.shamt/scripts/` recursively; the new `storage/`
    subdirectory is automatically included without any modification to `init.sh`

- `.shamt/scripts/import/import.sh` (and `import.ps1`)
  - No change needed — `import.sh` copies `.shamt/scripts/` recursively from master; the new
    `storage/` subdirectory is automatically propagated to child projects on their next import
    without any modification to `import.sh`

---

## Script Design Details

### Bash scripts (Linux / Mac)

Follow the style and conventions of the existing `export.sh` / `import.sh`:
- `set -e` at the top
- `============================================================` banners
- Conf file read with `tr -d '[:space:]'` for whitespace trimming
- Exit with clear error messages when conf file or directory is missing
- `--dry-run` flag for both scripts (store: shows what would be copied/pushed without doing it; get: shows what would be overwritten locally without modifying anything)
- `--force` flag for get script (skips the interactive stdin confirmation — used when the agent has already confirmed with the user in chat)

For get script interactive confirmation (only runs when `--force` is NOT passed):
```bash
read -rp "  Proceed? [y/N]: " _confirm
_confirm="${_confirm:-N}"
if [[ ! "$_confirm" =~ ^[Yy]$ ]]; then
    echo "  Get cancelled."
    exit 0
fi
```

Directory mirroring (store and get) uses `rsync -a --delete` if rsync is available, falling
back to `cp -r` + manual deletion if not. The fallback is acceptable because the Storage repo
is a clean copy-from-source operation with no need for delta transfers.

For conf file exclusion during mirroring, rsync `--exclude` flags are used:
```bash
rsync -a --delete \
  --exclude="storage_path.conf" \
  --exclude="shamt_master_path.conf" \
  --exclude="rules_file_path.conf" \
  --exclude="import_diff*.md" \
  "$CHILD_SHAMT_DIR/" "$DEST_SHAMT_DIR/"
```

For the `cp -r` fallback (when rsync is unavailable), the exclusion list cannot be expressed as rsync flags. Implementation must use selective per-file/per-directory copying (copy everything except excluded files) or copy all then explicitly `rm` the excluded files from the destination. The fallback implementation must be documented in a comment in the script itself.

### PowerShell scripts (Windows)

Follow the style of the existing `export.ps1` / `import.ps1`. Use `Copy-Item` with `-Recurse`
and implement the same exclusion list. The interactive confirmation uses `Read-Host`.

### Commit message format (store script)

```
sync: {ProjectName} — {YYYY-MM-DD}
```

If nothing has changed in the Storage repo since the last store (git status clean after staging),
the commit step is skipped and a "Already up to date" message is printed. The push is also
skipped in that case.

### Push failure handling (store script)

If `git push` fails (no remote configured, no network, permission denied), the script:
- Reports the failure with the git error output
- Prints a note that local Storage files were copied successfully but the remote is not updated
- Exits with a non-zero exit code

This is non-fatal from a local-use perspective — the user can push manually later.

Because `set -e` is active, the push must be wrapped in a conditional rather than run bare — a failing bare `git push` would exit the script immediately before the reporting code runs:
```bash
if ! git -C "$STORAGE_DIR" push; then
    echo "  Warning: push failed — local Storage files were copied but remote is not updated."
    echo "  You can push manually: git -C \"$STORAGE_DIR\" push"
    exit 1
fi
```

---

## Edge Cases and Failure Modes

### First-time use (Storage subfolder doesn't exist yet)
Store script creates `{StorageRepo}/{ProjectName}/` automatically. Get script halts with a
helpful error: "No storage found for {ProjectName}. Run store on another machine first."

### Storage repo has uncommitted changes on get
The get script runs a pre-pull dirty-tree check (step 3). If uncommitted changes are detected,
the script halts with a clear error before attempting the pull: the user must investigate and
clean up the Storage repo manually. This is an unusual state — the Storage repo should only
ever be modified by the store script.

### Storage repo is ahead of remote on get
`git pull` will fast-forward. Normal operation.

### Storage repo has no remote (local-only or NFS use)
`git pull` will fail. The get script must handle this gracefully: print a warning ("No remote
configured or pull unavailable — proceeding with local Storage state") and continue. This is
consistent with how `import.sh` handles its freshness check failure. The local copy in the
Storage repo is used as-is.

### Storage repo is behind remote on store
After committing, the push will fail with "rejected — remote contains work that you do not have
locally." The script reports this and suggests `git pull` in the Storage repo before retrying.
(This happens when the user stored from another machine without getting first on this one.)

### Local `.shamt/` has conf files but no other content (fresh machine)
Get script will restore fully. The preserved conf files stay intact. This is the primary use
case — starting fresh on a new machine.

### Get when `.shamt/` does not exist at all
The get script creates `.shamt/` as part of the copy. The storage_path.conf is not restored
from storage (it was excluded when stored). The conf file that triggered the get was already
created by the agent (per the agent procedure above) before running the script.

### rsync not available (some minimal Linux environments)
The scripts fall back to `cp -r` + targeted deletion. The fallback is documented in the
`storage/README.md` and in a comment in the script itself.

### Project root directory name contains spaces
All path variables must be quoted in bash scripts. The project name derived from `basename`
must be sanitized (replace spaces with underscores) for use as the Storage subfolder name.
Print the sanitized name in the script output so the user knows which subfolder to look for.

### Fresh machine — storage scripts not yet installed
On a brand-new machine, the child project is cloned from git but `.shamt/` does not exist (it
is gitignored). The user cannot run `get.sh` because the scripts haven't been installed yet.

**Required workflow for new machines:**

1. Clone the Storage repo on this machine (e.g., `git clone <remote> ~/code/RemoteStorage`).
   The get script validates the Storage repo path exists on disk — this must happen before
   providing the path.
2. Run `init.sh` from the local Shamt master repo clone — this creates a standard `.shamt/`
   including the storage scripts at `.shamt/scripts/storage/`.
3. When prompted for the storage repo path (or before running `get`), provide the path so the
   agent saves `.shamt/storage_path.conf`.
4. Run `get` — this restores the full project-specific state (epics, guides customizations,
   project-specific configs, rules file) from the Storage repo, overwriting the generic
   `.shamt/` installed by `init.sh`.

The `init.sh` step ensures the storage scripts exist before the user needs to run them. The
subsequent `get` replaces the generic initialization state with the saved project state.

This bootstrapping requirement must be documented in `storage/README.md`. See also OQ7.

### Rules file in a subdirectory (`.github/copilot-instructions.md`)
The store script must preserve the subdirectory structure when copying into the Storage
subfolder. The get script must recreate the subdirectory (`.github/`) if it doesn't exist on
the target machine.

---

## Open Questions

**OQ1: Should the get script always require confirmation or should `--force` skip it?**
The destructive risk of get (overwriting all of `.shamt/`) warrants confirmation by default.
A `--force` flag enables non-interactive use (e.g., scripted automation). Recommend: include
`--force` in the initial implementation to keep the agent workflow clean (the agent can pass
`--force` after asking the user in chat rather than having the script pause for stdin).

**OQ2: Should `.shamt/storage_path.conf` be added to `.gitignore` in the init script?**
The file lives inside `.shamt/`, which is gitignored via `.git/info/exclude` on machines where
`init.sh` has been run. Specifically, `init.sh` line 243–244 adds `.shamt/*.conf` to
`.git/info/exclude`, which covers `storage_path.conf`. However, `.git/info/exclude` is
machine-local — it is NOT committed to the repo and does NOT travel with the clone. On machines
where `init.sh` has NOT been run, `.shamt/*.conf` is not protected. For the intended workflow
(init.sh → get on every new machine), this is adequate. If a child project's `.shamt/` is
tracked in git (uncommon), `storage_path.conf` could be accidentally committed. The Shamt
Storage Sync README should note this and recommend ensuring `.shamt/*.conf` is also in the
project's committed `.gitignore` if `.shamt/` is tracked.

**OQ3: How do existing child projects get the new Storage Sync section in their rules file?**
Resolved in design: `import_workflow.md` is being updated (see Affected Files) to add a step
directing the agent to compare `RULES_FILE.template.md` against the project's rules file
whenever that template appears in the import diff, and to apply any new sections. On their
next import after SHAMT-21 is merged, existing child projects will see the template change in
their import diff, and the import workflow will instruct the agent to apply the new Storage
Sync section to the project's rules file.

**OQ4: What if the user has multiple Storage repos or wants to use a different Storage repo for
a second machine?**
The design is one Storage repo per user, shared across all machines. The `.conf` file stores a
single path. If a user needs multiple Storage repos (rare), they can update `storage_path.conf`
manually. No multi-repo support in scope for SHAMT-21.

**OQ5: Should the store script verify that the Storage repo has a remote configured before
running?**
If the Storage repo has no remote, the push step will fail but the local copy will succeed.
This is useful (local backup still works). Recommend: run the push as a best-effort step with
a warning if no remote is configured, rather than failing upfront.

**OQ6: Should store/get have a `--dry-run` flag?**
Store: yes — mirrors export.sh's existing pattern. Shows what would be copied and what the
commit message would be, without touching the Storage repo.
Get: yes — shows what would be overwritten locally, without modifying anything.
Recommend: implement `--dry-run` for both. *(Resolved in design — both scripts get `--dry-run`.)*

**OQ7: What is the exact bootstrapping workflow for a fresh machine?**
The user has cloned the child project on a new machine. `.shamt/` does not exist. The storage
scripts do not exist. How do they run `get`?

Resolved in design (see Edge Cases — "Fresh machine" section): run `init.sh` first to get a
standard `.shamt/` with storage scripts, then run `get` to replace it with saved state. The
implementation must document this clearly in `storage/README.md` and in the Shamt Storage Sync
section added to `RULES_FILE.template.md`. It should also be noted that this requires the user
to have their local master repo clone available on the new machine (for `init.sh`) — if they
do not, they can alternatively copy the storage scripts directly from the Storage repo's
`{ProjectName}/.shamt/scripts/storage/` subfolder and run them manually as a one-time bootstrap.

**OQ8: Should `init.sh` prompt for the Storage repo path during initialization?**
The design leaves Storage repo path discovery entirely to the agent at first use (agent detects
missing `storage_path.conf` and asks the user). An alternative would be to have `init.sh` ask
for the Storage repo path during initialization and write `storage_path.conf` immediately.
Recommendation: keep this out of scope for SHAMT-21. Adding Storage repo prompting to `init.sh`
increases initialization complexity and is not needed — users may not have a Storage repo yet
when they first initialize a project. The current design (agent asks on first trigger) is
simpler and defers the question to when it's actually needed.

---

**Last Updated:** 2026-03-30
