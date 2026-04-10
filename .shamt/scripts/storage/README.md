# Shamt Storage Scripts

These scripts let you sync your `.shamt/` directory and AI rules files across machines using a dedicated **Storage repo** — a plain git repo you own and control.

---

## The Problem They Solve

`.shamt/` is gitignored in child projects by design. This keeps Shamt's internal state (epics, guide customizations, rules files) out of your project's history. But it also means moving to a new machine — or resuming work on a second machine — leaves you without your guide supplements, epic history, and AI rules file.

The store/get scripts use a separate "Storage repo" as a neutral carrier. You push to it from Machine A and pull on Machine B.

---

## Storage Repo Setup

Create a plain git repo to serve as your storage. One Storage repo can hold multiple projects.

```bash
# Create the repo
mkdir ~/RemoteStorage
cd ~/RemoteStorage
git init
git remote add origin git@github.com:you/RemoteStorage.git

# Clone it on each machine you use
git clone git@github.com:you/RemoteStorage.git ~/RemoteStorage
```

On first use, the scripts will ask you for the path to this repo and save it to `.shamt/storage_path.conf` (which is gitignored).

---

## Trigger Phrases

### Store (save this machine's state to Storage repo)

Tell your agent:
- "store the shamt files"
- "backup shamt to storage"
- "push shamt files to storage"
- "save shamt state"

### Get (restore from Storage repo to this machine)

Tell your agent:
- "get the shamt files from storage"
- "restore shamt from storage"
- "pull shamt files"
- "sync shamt from storage"

---

## Agent Procedure

### Store procedure

1. Check if `.shamt/storage_path.conf` exists.
2. If missing: ask the user — "What is the path to your Storage repo? (e.g., `/home/you/RemoteStorage`)" — save their answer to `.shamt/storage_path.conf`.
3. Run `bash .shamt/scripts/storage/store.sh` (or `& ".shamt\scripts\storage\store.ps1"` on Windows).
4. Report the script output to the user.

### Get procedure

1. Check if `.shamt/storage_path.conf` exists.
2. If missing: ask the user — "What is the path to your Storage repo?" — save their answer to `.shamt/storage_path.conf`.
3. Show the user what will be overwritten: list local `.shamt/` contents and any local rules files that would be replaced. Ask: "The get will overwrite your local `.shamt/` and rules files with the version from storage. Proceed? (y/N)"
4. Once the user confirms in chat, run `bash .shamt/scripts/storage/get.sh --force` (or `get.ps1 -Force`). The `--force` flag skips the script's own stdin prompt.
5. Report the script output to the user.

---

## Fresh Machine Bootstrapping

On a brand-new machine where Shamt is not yet installed:

1. **Initialize Shamt first:** Run `init.sh` (or `init.ps1`) to install the guide system and storage scripts into your project.
2. **Set up the Storage repo:** Clone your Storage repo to this machine.
3. **Run get:** Tell your agent "get the shamt files from storage" — provide the Storage repo path. This overwrites the freshly-initialized `.shamt/` with your saved state.

---

## What Gets Synced

**Stored:**
- All of `.shamt/` — guides, scripts, epics, supplements, templates
- AI rules files that exist in your project root: `CLAUDE.md`, `.github/copilot-instructions.md`, `.cursorrules`, `.windsurfrules`, `GEMINI.md`

**Excluded from storage (machine-local):**
- `.shamt/storage_path.conf` — path to Storage repo (machine-specific)
- `.shamt/shamt_master_path.conf` — path to master clone (machine-specific)
- `.shamt/rules_file_path.conf` — path to AI rules file (machine-specific)
- `.shamt/import_diff*.md` — temporary import artifacts

These files are excluded so that each machine keeps its own local paths, even after a get.

---

## Limitations of the cp Fallback

If `rsync` is not available (some minimal environments, Windows without WSL), `store.sh` and `get.sh` fall back to `cp -r`. Limitations:

- **store.sh cp fallback:** Excluded conf files are correctly removed after copying, but files deleted locally since the last store will remain in storage (no `--delete` equivalent).
- **get.sh cp fallback:** Local-only files in `.shamt/` that don't exist in storage are not removed (no `--delete` equivalent).

`store.ps1` and `get.ps1` always implement `--delete` equivalent logic (they iterate files and remove those absent from the source), so they do not have this limitation.

On most Linux and macOS systems, `rsync` is available and the cp fallback is not used.

---

## `storage_path.conf` and Gitignore

`.shamt/storage_path.conf` is a machine-local file that should not be committed. For projects initialized via `init.sh`, the `.shamt/*.conf` entry in `.git/info/exclude` covers it automatically. If you're on a project initialized before SHAMT-4, verify that `.shamt/*.conf` (or explicitly `.shamt/storage_path.conf`) is in your `.git/info/exclude` or `.gitignore`.

To add it manually:

```bash
echo ".shamt/*.conf" >> .git/info/exclude
```
