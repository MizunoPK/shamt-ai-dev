# /shamt-import

**Purpose:** Run the post-import validation workflow after the user has run `import.sh` to pull updates from the Shamt master repo.

**Invokes:** `shamt-import` skill

---

## Usage

```
/shamt-import
```

## Arguments

None. This command assumes `import.sh` (or `import.ps1`) has already been run and has produced one or more `.shamt/import_diff*.md` files.

## What Happens

1. The agent loads the `shamt-import` skill
2. Reads all import diff files (`.shamt/import_diff.md`, `import_diff_1.md`, etc.)
3. For each changed file: checks whether the project's supplement files need updating
4. Checks pointer files for consistency with the updated shared files
5. Handles any new files added by master or deletions of files that were previously imported
6. Applies new sections from `RULES_FILE.template.md` to the project rules file (if any)
7. Reviews preserved child-only files for any necessary updates
8. Runs a validation loop (primary clean round + 2 Haiku sub-agent confirmations) on the import state
9. Deletes the diff files
10. Commits the result

## Expected Output

- All supplement files and pointers updated to reflect the imported changes
- Project rules file updated with any new generic sections from the template
- Diff files deleted
- A clean commit with the import result

## Notes

- Run this command immediately after `import.sh` completes — the diff files are the source of truth for what changed
- The validation loop in step 8 checks that the import didn't break any project-specific configurations
- If a changed file has project-specific supplements, those supplements take priority and must be preserved

<!-- Managed by Shamt — do not edit. Run regen-claude-shims.sh to regenerate. -->
