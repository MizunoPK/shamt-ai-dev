# Shamt Sync Flow Redesign — Proposal

**Status:** Design complete. All questions resolved. Ready for Phase 2 implementation.
**Source:** `proposed_new_flow.txt`
**Created:** 2026-02-23
**Effort Size:** Large — multi-session implementation

---

## Overview

This proposal replaces the current changelog-based sync system between the master Shamt repo and child projects with a script-driven export/import flow. The primary architectural enabler is a new `project-specific-configs/` folder that cleanly separates project-specific content from shared guide content, making automated file syncing safe and reliable.

The current system requires agents on both ends to read, assess, and apply structured changelog files — a high-friction, error-prone process. The proposed system reduces this to scripts and a PR review.

---

## Current System

### How It Works

**Initialization:**
1. User runs `init.sh` / `init.ps1` from the target project directory
2. Script gathers project info (name, epic tag, AI service, git platform)
3. Creates `.shamt/` folder structure and copies guides from master
4. Writes `init_config.md` as a handoff to the agent
5. Agent completes initialization: writes ARCHITECTURE.md, CODING_STANDARDS.md, customizes guides

**Child-to-Master sync (improvements flowing up):**
1. Child agent writes a structured changelog file to `.shamt/changelogs/outbound/`
2. User manually places the file in master's `.shamt/changelogs/unapplied_external_changes/`
3. Master agent reads the file, assesses universality, applies changes to master guides
4. Master agent runs the full guide audit before publishing
5. Master agent publishes a versioned outbound changelog to `.shamt/outbound_changelogs/`
6. Master agent updates `CHANGELOG_INDEX.md` with the new version number

**Master-to-Child sync (improvements flowing down):**
1. User manually downloads the new versioned changelog file from master
2. User places it in their child's `.shamt/changelogs/unapplied_external_changes/`
3. Child agent reads the file, assesses applicability to their project
4. Child agent applies the change, resolves any conflicts (escalates to user if needed)
5. Child agent moves the file to `applied_external_changes/` and updates their index

### Problems with the Current System

- **High agent overhead:** Both master and child require agent sessions just to move content between repos
- **Manual file handling:** Users must manually copy files between repos on their filesystem
- **Fragile conflict detection:** Child agents must compare incoming changelog diffs against their locally modified guides — they don't know what they changed vs. what master changed
- **No clean separation:** Child guides are directly modified, so any guide file may contain a mix of master content and project-specific customizations. This makes automated syncing impossible.
- **Version number theater:** Tracking `v0001`, `v0002` etc. adds ceremony without much value in a personal/small-team context
- **Universality judgment is unreliable:** Master agent assessing whether a child improvement is "universal" based on a changelog description is a weak signal

---

## Proposed System

### Core Architectural Changes

Two new structural elements replace the old changelog system:

**1. `.shamt/project-specific-configs/`** — holds all project-specific content. The shared guide and script files remain generic and universally applicable.

**What lives in `project-specific-configs/`:**
- ARCHITECTURE.md and CODING_STANDARDS.md for this project
- Project-specific rules supplements (test commands, project conventions, stack details)
- Any project-specific overrides or extensions to guide default behavior
- Notes written during S10 lessons learned that are project-specific
- Audit exceptions and known issues specific to this project
- `init_config.md` (the initialization handoff file)

**What does NOT go in `project-specific-configs/`:**
- Any content that should apply to all Shamt projects
- Changes to shared guide logic, workflow steps, or scripts

**2. `.shamt/scripts/`** — holds the core operational scripts (initialization, export, and import), organized into subfolders. Both `guides/` and `scripts/` are treated as shared and are synced between master and child via the export/import scripts. Everything else in `.shamt/` is project-specific and never synced.

```
.shamt/
  guides/                     ← shared, synced
  scripts/                    ← shared, synced
    initialization/           ← init scripts, templates, ai_services.md
    export/                   ← export script and helpers
    import/                   ← import script and helpers
  project-specific-configs/   ← never synced
  epics/                      ← never synced
  CHANGES.md                  ← never synced
  shamt_master_path.conf      ← never synced
  rules_file_path.conf        ← never synced
```

**The pointer convention:**
`project-specific-configs/` mirrors the guide folder structure. Supplement files for a given guide go in the corresponding mirrored directory — e.g., supplements for S5 guides go in `.shamt/project-specific-configs/guides/stages/s5/`. This means pointer notes reference a predictable directory path, not a specific filename, so any number of supplement files can exist there.

Pointers are added to shared guide files only when a supplement is actually created — never preemptively. Once a pointer is added by any child project and exported to master via PR, it flows to all future child projects permanently. This marks the section as a known extension point for all future users.

Pointer format:
```markdown
> **Project-specific supplement:** Check `.shamt/project-specific-configs/guides/[mirrored-path]/`
> for any extensions to this section. If none exist for your project, consider whether
> a supplement is appropriate during initialization, S10, or audit.
```

This pointer is the only project-specific content allowed in a shared guide file.

---

### Initialization Flow (Updated)

1. User clones `shamt-ai-dev` locally
2. User runs `init.sh` / `init.ps1` from target project, provides project info
3. Script creates `.shamt/` folder structure (now including `project-specific-configs/`) and copies guides and scripts from master (excluding `guides/audit/outputs/`)
4. Script writes `project-specific-configs/init_config.md` handoff and provides agent prompt
5. **Agent re-reads the validation loop protocol, then runs a validation loop** to complete initialization:
   - Analyzes codebase structure, languages, frameworks
   - Asks user clarifying questions until fully understood
   - Writes ARCHITECTURE.md, CODING_STANDARDS.md to `project-specific-configs/`
   - Generates rules file at its AI-service-required path from the shared template in `scripts/initialization/`
   - Validates all outputs meet quality bar before closing

This is essentially the same as today, with two changes: project-specific outputs go into `project-specific-configs/`, and the agent uses a formal validation loop rather than a one-pass task list.

---

### Child-to-Master Sync (Export)

1. Child agent makes improvements to shared guide or script files (not project-specific-configs) during normal S10 or audit work
2. These changes are tracked in a `.shamt/CHANGES.md` file (simple running log — not a structured format)
3. User runs an **export script** from the child project directory:
   - Script compares child's `guides/` and `scripts/` against master via direct file comparison
   - Copies all differing files to their mirrored paths in the local `shamt-ai-dev` repo
   - Outputs a summary of what was copied
4. User creates a branch in `shamt-ai-dev` and opens a PR against `main`
5. PR review (human or agent) replaces the current master agent universality assessment
6. PR merged → master is updated

---

### Master-to-Child Sync (Import)

1. User pulls latest `main` from `shamt-ai-dev` locally
2. User runs an **import script** from the child project directory:
   - Script compares master's `guides/` and `scripts/` against child via direct file comparison
   - Copies all differing files into the child's `.shamt/`; removes files that no longer exist in master
   - Never touches `project-specific-configs/`, `epics/`, `CHANGES.md`, `.conf` files, or `guides/audit/outputs/`
   - Generates `.shamt/import_diff.md` with unified diffs of all changed files (split into numbered files `import_diff_1.md`, `import_diff_2.md`, etc. when combined diff exceeds 1000 lines)
   - Outputs the agent validation prompt at the end
3. User provides the agent prompt to their AI agent in the child project
4. **Agent re-reads the validation loop protocol, then runs a validation loop** to assess the impact:
   - Reviews what changed in the shared guides via the diff files
   - Checks whether any `project-specific-configs/` files need to be updated to accommodate the changes
   - Checks whether any existing pointers in shared guides are now stale or broken
   - Updates project-specific files as needed, validates all is consistent
   - Deletes diff files when complete

---

## Changes Required

### New: `project-specific-configs/` folder

- Add to `.shamt/` folder structure in `init.sh` and `init.ps1`
- Add to the structure documentation in `CLAUDE.md` and relevant guides
- Write the separation rule as a clear, prominent agent-facing protocol (guide file in `.shamt/guides/`)
- Update `init_config.md` template to direct agent to write outputs into `project-specific-configs/`
- Update S10 and audit guides to enforce the separation rule

### New: `.shamt/scripts/` folder structure

Master and child both use this layout under `.shamt/scripts/`:
```
scripts/
  initialization/   ← init scripts, templates (RULES_FILE.template.md, etc.)
  export/           ← export script and any helpers
  import/           ← import script and any helpers
```

Both `guides/` and `scripts/` are treated as shared — compared and synced between master and child. Everything else in `.shamt/` is project-specific and never synced.

### New: Export script (`scripts/export/export.sh` / `export.ps1`)

- Reads master path from `.shamt/shamt_master_path.conf`
- Compares child's `guides/` and `scripts/` against master via direct file comparison
- Copies all differing files to their mirrored paths in the local `shamt-ai-dev` repo
- Excludes everything outside `guides/` and `scripts/`
- Prints a summary of what was exported and reminds user to open a PR

### New: Import script (`scripts/import/import.sh` / `import.ps1`)

- Reads master path from `.shamt/shamt_master_path.conf`
- Compares master's `guides/` and `scripts/` against child via direct file comparison
- Copies all differing files into the child's `.shamt/`
- Never touches `project-specific-configs/`, `epics/`, `CHANGES.md`, `shamt_master_path.conf`, `rules_file_path.conf`, or `guides/audit/outputs/`
- Removes files from child's `guides/` and `scripts/` that no longer exist in master (full sync)
- Generates `.shamt/import_diff.md` (split into numbered files, each under 1000 lines, when combined diff exceeds 1000 lines) with unified diffs of all changed files
- Outputs agent prompt instructing agent to re-read validation loop protocol, run validation loop, and delete diff files when done

### New: `.shamt/CHANGES.md`

- Simple running log of changes made to shared files (`guides/` or `scripts/`) in this child project
- Written by the agent during S10 and audit work whenever a shared file is modified
- Used as reference material for PR reviewers when export is run
- Format: date, one-line description, list of modified paths, one-line reason — no structured IDs or versioning

### Updated: `init_config.md` template

- Move from `.shamt/init_config.md` to `.shamt/project-specific-configs/init_config.md`
- Update agent task list: write ARCHITECTURE.md and CODING_STANDARDS.md to `project-specific-configs/`
- Update agent task: generate rules file at AI-service-required path using template from `scripts/initialization/`
- Add instruction: agent must re-read validation loop protocol before beginning, then run a full validation loop (not a one-pass checklist)

### Updated: Initialization scripts (`scripts/initialization/init.sh` / `init.ps1`)

- Move from `.shamt/initialization/` to `.shamt/scripts/initialization/`
- Create `project-specific-configs/` folder during init
- Copy `.shamt/guides/` from master to child during init, excluding `guides/audit/outputs/` (consistent with import script exclusion — child projects do not receive master's audit history)
- Copy `.shamt/scripts/` from master to child during init
- Remove all changelog folder creation (clean break)
- Prompt for `shamt-ai-dev` path; write to `.shamt/shamt_master_path.conf`
- Write rules file path to `.shamt/rules_file_path.conf`
- Both `.conf` files are project-specific and must not be exported
- Always add `.shamt/shamt_master_path.conf` to `.gitignore` (machine-specific path — always excluded regardless of user's broader choice)
- Prompt user whether to gitignore `.shamt/` and the rules file; apply entries to `.gitignore` based on their answer (two lines in `.gitignore`: one for `.shamt/`, one for the rules file path)
- Update done message to reference export and import script locations

### New: `.shamt/rules_file_path.conf`

- Stores the path to this project's rules file (e.g., `CLAUDE.md`, `.cursorrules`)
- Written by init script at init time
- Allows the agent to locate the rules file without knowing which AI service was chosen
- Project-specific — never exported or imported

### Updated: Agent-facing guides

Files that need updating to reflect the new system:
- `.shamt/guides/changelog_application/` — delete entire folder; replace with new export and import workflow guides (location TBD during Phase 4)
- `CLAUDE.md` (master) — update structure diagram, changelog section, publishing section

### Removed: Current changelog exchange system

The following become obsolete and must be deleted as part of Phase 2:

**From master repo:**
- `.shamt/outbound_changelogs/` (including `CHANGELOG_INDEX.md`)
- `.shamt/changelogs/` (including `unapplied_external_changes/` and `applied_external_changes/`)
- `.shamt/initialization/` → replaced by `.shamt/scripts/initialization/`

**From child project init:**
- `changelogs/outbound/`, `changelogs/unapplied_external_changes/`, `changelogs/applied_external_changes/` — no longer created

**Conceptually retired:**
- Structured changelog file format (SHAMT-CHANGELOG-NNN, universality assessment fields)
- Version numbering scheme (`v0001`, `v0002`, etc.)
- Master agent universality assessment step

---

## Resolved Questions

**Q1: Where should `shamt-ai-dev` path be stored for scripts?**
**Decision: Config file.** Stored at `.shamt/shamt_master_path.conf`, written once at init time. Scripts read it automatically — no argument required on each run. This file is always gitignored (see Q17) regardless of the user's broader `.shamt/` choice (see Q13), because it contains a machine-specific absolute path.

**Q2: Should the existing changelog folder structure be removed from init, or kept?**
**Decision: Remove entirely.** The changelog system has never been used in production. Clean break — no folders, no guides, no dead structure.

**Q3: How should the export script identify which shared files were modified?**
**Decision: File comparison.** Directly compare child's shared guide and script files against the `shamt-ai-dev` source files on disk. Export always means "copy everything that differs from master" — no SHA tracking needed.

**Q4: What's the intended scope of the pointer convention?**
**Decision: Both.** Agent adds pointers at the time it creates a project-specific supplement (during S10/audit work), AND reviews existing pointers during import validation to ensure they're still accurate after master changes.

**Q5: Should the import agent prompt include the diff of what changed?**
**Decision: Temp diff files.** Import script generates one or more temporary diff files in `.shamt/` summarizing what changed. The agent prompt instructs the agent to read those files, run the validation loop, then delete the diff files when finished.

**Q6: What should replace the existing changelog guides?**
**Decision: Write new, delete old.** Delete `changelog_application/` folder entirely. Write new export and import workflow guides (location determined during Phase 4 implementation).

**Q7: Where does `init_config.md` live?**
**Decision:** `project-specific-configs/init_config.md` — matches the original proposal and is consistent with the separation rule since it contains project-specific data.

**Q8: What is the exact scope of the export and import scripts?**
**Decision:** Both scripts compare and sync `guides/` and `scripts/` only — direct path mirror between child and master. Everything else (epics, project-specific-configs, CHANGES.md, shamt_master_path.conf, rules_file_path.conf) is excluded. Note: `guides/audit/outputs/` is excluded from the import scope as a sub-exception within `guides/` (see Q15); the export script has no equivalent exclusion since child projects don't write to `guides/audit/outputs/`.

**Q9: How do updated scripts reach child projects?**
**Decision:** Resolved by Q8 — `scripts/` is in import scope, so improvements to export.sh, import.sh, and init scripts flow to child projects automatically on next import.

**Q10: What happens to the master repo's existing structure?**
**Decision:** Master repo cleanup happens in Phase 2, same phase as init script overhaul. Folders to delete from master: `.shamt/outbound_changelogs/`, `.shamt/changelogs/`, `.shamt/initialization/` (replaced by `.shamt/scripts/initialization/`). Master CLAUDE.md structure diagram updated in Phase 2 as well.

**Q11: Confirm D1, D3, D4**
**Decision:** All three confirmed. See Design Decisions section for final wording.

**Q12: Should `master_dev_workflow/` guides be included in Phase 4?**
**Decision: Yes.** Update `master_dev_workflow/` guides in Phase 4 to remove references to the old changelog system and reflect the new export/import flow.

**Q13: Should `.shamt/` and the rules file be gitignored in child projects?**
**Decision: User choice at init time.** The init script prompts the user whether they want `.shamt/` and the rules file committed to the project repo or gitignored. The script applies `.gitignore` entries based on the answer. This accommodates solo developers who prefer local-only tooling and teams who want Shamt configuration tracked in the repo.

**Q14: What is the threshold for splitting `import_diff.md` into numbered files?**
**Decision: 1000-line threshold.** The Read tool's default limit is 2000 lines per read. The split threshold is set at half of this — 1000 lines — so each diff file stays comfortably within a single read. The import script splits when the combined diff exceeds 1000 lines total; each resulting file stays under 1000 lines.

**Q15: Should `guides/audit/outputs/` be excluded from the import script scope?**
**Decision: Exclude.** Add `guides/audit/outputs/` to the import script's exclusion list alongside `project-specific-configs/`, `epics/`, etc. Child projects do not receive master's audit history.

**Q16: How should the import script handle files deleted from master?**
**Decision: Full sync (copy + delete).** Import script also removes files from child's `guides/` and `scripts/` that no longer exist in master. Keeps child in exact sync with master.

**Q17: Should `shamt_master_path.conf` always be gitignored, even when the user opts to commit `.shamt/`?**
**Decision: Always gitignore it.** Init script unconditionally adds `.shamt/shamt_master_path.conf` to `.gitignore`. The file contains a machine-specific absolute path that would break export and import for any other developer who clones the repo. The user's Q13 choice still governs everything else in `.shamt/`.

---

### Design Decisions (Confirmed)

**D1: Validation loop at init and import — confirmed**
Both init completion and post-import agent work use the validation loop protocol. The agent must explicitly re-read the validation loop protocol file before beginning either loop.

**D2: `CHANGES.md` format — confirmed**
Simple markdown log, newest entry at top. Entry format:
```
## YYYY-MM-DD — [brief description]
- Modified: `.shamt/[path]`
- Reason: [one line]
```
Covers changes to both `guides/` and `scripts/` files. No IDs, no structured fields. Written by agent, read by PR reviewers.

**D3: Project-specific content locations — confirmed**
ARCHITECTURE.md and CODING_STANDARDS.md go in `project-specific-configs/`. The rules file template lives in `scripts/initialization/` (shared). The rules file itself is generated at its AI-service-required path during init. The rules file path is stored in `.shamt/rules_file_path.conf` for agent reference.

**D4: Scripts folder structure — confirmed**
Export and import scripts live in `.shamt/scripts/export/` and `.shamt/scripts/import/` respectively. Init scripts live in `.shamt/scripts/initialization/`. All are copied into child projects at init time and synced via export/import thereafter.

---

## Proposed Implementation Phases

### Phase 1 — Design Finalization (complete)
- ~~Resolve all blocking design questions~~ — done (Q15, Q16, Q17 resolved)
- ~~Define the exact separation rule as agent-facing language~~ — done
- ~~Define the pointer convention format precisely~~ — done
- ~~Define `CHANGES.md` format~~ — done
- ~~Define the import diff file format and agent prompt template~~ — done

#### Phase 1 Decisions

**Separation rule (agent-facing language):**
> All content in `.shamt/guides/` and `.shamt/scripts/` must be generic — applicable to any Shamt project, regardless of tech stack, domain, or conventions. Never write project-specific information into these files.
>
> Project-specific content belongs exclusively in `.shamt/project-specific-configs/`. This includes architecture and coding standards, project-specific rules or rule supplements, project-specific overrides or extensions to any guide's default behavior, and lessons learned or audit notes that apply only to this project.
>
> The only exception: when a shared guide file has been supplemented, that file must contain a pointer note directing the agent to check for the supplement. The pointer is the only project-specific content permitted in a shared guide file. There is no equivalent pointer mechanism for scripts — scripts must be universally applicable as written.
>
> When in doubt: if the content would need to change when used in a different project, it is project-specific.

**Pointer convention:**
- `project-specific-configs/` mirrors the guide folder structure. Supplements for a given guide go in the corresponding mirrored directory (e.g. supplements for s5 guides go in `.shamt/project-specific-configs/guides/stages/s5/`).
- Pointers are only added when a supplement is actually created — never preemptively.
- Once added by any child project, the pointer is exported to master and flows to all future child projects permanently — marking that section as a known extension point.
- Pointer format:
  ```markdown
  > **Project-specific supplement:** Check `.shamt/project-specific-configs/guides/[mirrored-path]/`
  > for any extensions to this section. If none exist for your project, consider whether
  > a supplement is appropriate during initialization, S10, or audit.
  ```
- Placement: immediately after the relevant section heading, or at the top of the file if the supplement covers the whole file.

**`CHANGES.md` format:**
- Location: `.shamt/CHANGES.md` in child projects
- Newest entries at top
- Each entry: date header, one-line description, list of modified files, one-line reason
- No IDs or structured fields beyond that
- Written by agent during S10/audit when a shared file is modified; read by PR reviewers on export

**Import diff file:**
- Location: `.shamt/import_diff.md` (temporary; deleted by agent after validation loop)
- If the combined diff exceeds 1000 lines, script splits into `import_diff_1.md`, `import_diff_2.md`, etc., each under 1000 lines
- Format: one section per changed file, with unified diff of the changes
- Agent prompt template (printed by script at end of import):
  ```
  Shamt has been updated from master (guides and/or scripts). To complete the import:

  1. Re-read the validation loop protocol file before proceeding
  2. Read the import diff: `.shamt/import_diff.md` if present, or `.shamt/import_diff_1.md`,
     `import_diff_2.md`, etc. if the combined diff exceeded 1000 lines and was split
  3. For each changed file, assess whether your project-specific-configs/ supplements
     are still accurate and consistent with the new guide content
  4. Check whether any existing pointers in the changed guide files are still accurately placed
  5. Check whether any new pointers should be added to the changed guide files
  6. Update any affected project-specific files as needed
  7. Run a validation loop until 3 consecutive clean rounds are achieved
  8. Delete all import diff files when complete
  ```

### Phase 2 — Structure, Init, and Master Repo Cleanup
- Create `.shamt/scripts/` with `initialization/`, `export/`, `import/` subfolders (new folder — does not yet exist on master)
- Move init scripts from `.shamt/initialization/` to `.shamt/scripts/initialization/`
- Delete obsolete master repo folders: `.shamt/outbound_changelogs/`, `.shamt/changelogs/`
- Update init scripts: create `project-specific-configs/`, copy `guides/` from master (excluding `guides/audit/outputs/`), copy `scripts/` from master; remove all changelog folder creation
- Add `shamt-ai-dev` path prompt; write to `.shamt/shamt_master_path.conf`
- Write rules file path to `.shamt/rules_file_path.conf`
- Always add `.shamt/shamt_master_path.conf` to `.gitignore` unconditionally (machine-specific path — see Q17)
- Prompt user whether to gitignore `.shamt/` and the rules file; apply `.gitignore` entries based on their choice
- Move `init_config.md` output to `project-specific-configs/init_config.md`
- Update `init_config.md` template: ARCHITECTURE.md and CODING_STANDARDS.md to `project-specific-configs/`, rules file generated from `scripts/initialization/` template, validation loop protocol re-read instruction
- Update master `CLAUDE.md` structure diagram to reflect new layout

### Phase 3 — Export and Import Scripts
- Write `scripts/export/export.sh` and `export.ps1`
- Write `scripts/import/import.sh` and `import.ps1`
- Export script: full `guides/` and `scripts/` comparison against master; no sub-exclusions within `guides/`
- Import script: `guides/` and `scripts/` comparison against master, with `guides/audit/outputs/` excluded; full sync (copy + delete for removed files)
- Import generates `import_diff.md` (or numbered split files) and outputs agent prompt
- Test both scripts end-to-end

### Phase 4 — Guide Updates
- Delete `.shamt/guides/changelog_application/` folder entirely
- Write new import workflow guide (location TBD during Phase 4)
- Write new export/PR workflow guide (location TBD during Phase 4)
- Add separation rule guide to `.shamt/guides/`
- Update S10 and audit guides to reference the separation rule and `project-specific-configs/`
- Update `master_dev_workflow/` guides to remove references to the old changelog system and reflect the new export/import flow

### Phase 5 — Validation
- Run the audit against all updated guides
- Test full round-trip: init a test project → make a guide change → export → PR → import → agent validation loop
- Close out and update this document

---

## Open Questions

None — all questions resolved. See Resolved Questions section.

---

*This document is the centralized reference for the sync flow redesign effort. Update it as decisions are made and questions are resolved.*
