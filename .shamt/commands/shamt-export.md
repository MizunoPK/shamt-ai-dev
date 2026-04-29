# /shamt-export

**Purpose:** Export generic guide and script improvements from this child project back to the Shamt master repo via pull request.

**Invokes:** `shamt-export` skill

---

## Usage

```
/shamt-export
```

## Arguments

None. The export workflow is driven by `.shamt/CHANGES.md` and the separation rule.

## What Happens

1. The agent loads the `shamt-export` skill
2. Verifies `.shamt/CHANGES.md` is current and accurate
3. Compares the project rules file against `RULES_FILE.template.md` in master — identifies any generic sections that should be back-propagated
4. Scans changed files for epic tag contamination (project-specific content that leaked into generic files)
5. Runs a 3-round guide audit on the files being exported
6. Runs the export script: `bash .shamt/scripts/export/export.sh` (dry-run first)
7. Opens a pull request to the master Shamt repo with the exported changes

## Expected Output

- A pull request to `shamt-ai-dev` (or the configured master repo) with:
  - Only generic changes (no project-specific content)
  - CHANGES.md as context for reviewers
  - Guide audit confirming the changes are clean

## Notes

- Only export files in `.shamt/guides/` and `.shamt/scripts/` — project-specific configs in `.shamt/project-specific-configs/` are never exported
- The separation rule is strict: if project-specific content has leaked into generic files, the export skill will request changes before proceeding
- Proposal docs (`.shamt/unimplemented_design_proposals/`) are exported automatically without CHANGES.md entries — they land in master's `design_docs/incoming/`
