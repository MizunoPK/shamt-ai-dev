# SHAMT-26: Standardize Design Doc Lifecycle Management

**Status:** Implemented
**Created:** 2026-04-01
**Branch:** `feat/SHAMT-26`

---

## Problem Statement

Design doc handling in the master shamt-ai-dev repo is currently ad-hoc:

1. **Inconsistent storage location** — Master design docs live at repo root (`SHAMT{N}_DESIGN.md`) and are git-excluded, while child project proposals are exported to `design_docs/unimplemented/` at repo root (also outside `.shamt/`)
2. **No standardized creation process** — Design docs are created manually without a template or checklist
3. **No lifecycle management** — Design docs are excluded from git and manually deleted by the user with no archive or history
4. **No execution tracking** — Implementation progress within a design doc isn't tracked in a standardized way
5. **No clear validation workflow** — CLAUDE.md describes a 7-dimension validation loop but there's no guide for applying it
6. **No SHAMT-N numbering convention** — No guidance on how to determine the next number when creating a design doc

### Current State Summary

| Aspect | Current State | Problem |
|--------|---------------|---------|
| Master design docs | Repo root (`SHAMT{N}_DESIGN.md`), git-excluded via `.git/info/exclude` | Scattered, no archive, no history |
| Child proposals | Exported to `design_docs/unimplemented/` at repo root | Folder may not exist, inconsistent with master docs |
| Creation | Manual, freeform | No template, inconsistent structure |
| Planning | Ad-hoc within design doc | No standardized planning section |
| Execution | Work happens on feat branch | No progress tracking in design doc |
| Validation | 7-dimension loop in CLAUDE.md | No guide, no validation log |
| Cleanup | User manually deletes | No archive, history lost |
| Numbering | Agent scans existing files to find next N | Error-prone, no single source of truth |

---

## Goals

1. **Unified storage** — All design docs (master-originated and child-imported) in one location at repo root (NOT inside `.shamt/` to avoid sync conflicts)
2. **Standardized creation** — Template and checklist for creating new design docs
3. **Clear lifecycle** — Defined states: Draft → Validated → In Progress → Implemented → Archived
4. **Execution tracking** — Standard way to track implementation progress
5. **Validation workflow** — Guide for the 7-dimension validation loop with validation log
6. **Archive/history** — Keep implemented design docs for reference instead of deleting
7. **Version control** — Design docs should be committed (not git-excluded) for history and collaboration
8. **Clear numbering** — Single source of truth for SHAMT-N numbers

---

## Key Design Decision: Location Outside `.shamt/`

**Decision:** Design docs live at `design_docs/` at repo root, NOT inside `.shamt/`.

**Rationale:**
- Files inside `.shamt/guides/` and `.shamt/scripts/` are synced between master and child projects via import/export
- Design docs are **master-specific planning artifacts**, not shared guides
- Child projects have their own design docs for their own epics
- If design docs were inside `.shamt/`, they would propagate to child projects on import — this is incorrect behavior
- The `design_docs/` folder at repo root is already where the export script sends child proposals

**Sync behavior:** The `design_docs/` folder is:
- Version-controlled in master (committed to git)
- NOT synced to child projects (not inside `.shamt/`)
- Receives child proposals via export workflow (one-way flow: child → master)

---

## Detailed Design

### Proposal 1: Unified Design Doc Location

**Current:**
- Master design docs at repo root (`SHAMT{N}_DESIGN.md`), git-excluded
- Child proposals exported to `design_docs/unimplemented/` at repo root

**Proposed structure:**

```
shamt-ai-dev/
├── design_docs/                        # All design docs live here (NOT in .shamt/)
│   ├── active/                         # Currently being worked on
│   │   ├── SHAMT26_DESIGN.md           # Example master design doc
│   │   └── SHAMT26_VALIDATION_LOG.md   # Validation log lives alongside
│   ├── incoming/                       # Child project proposals awaiting review
│   │   └── {project}-{epic}-SHAMT-UPDATE-PROPOSAL.md
│   ├── archive/                        # Implemented design docs kept for reference
│   │   ├── SHAMT23_DESIGN.md           # Example archived design doc
│   │   └── rejected/                   # Rejected child proposals with rejection notes
│   └── NEXT_NUMBER.txt                 # Single source of truth for next SHAMT-N
└── .shamt/
    └── guides/
        └── templates/
            └── design_doc_template.md  # Template lives in shared guides
```

**Key decisions:**
- Design docs at repo root in `design_docs/` — NOT inside `.shamt/` (avoids sync conflicts)
- Version-controlled (committed to git) — history and collaboration
- Three states via folder: `incoming/` → `active/` → `archive/`
- Master-originated design docs go directly to `active/`
- Child proposals go to `incoming/` for review before promotion
- Template lives in `.shamt/guides/templates/` (shared with child projects)
- Validation logs live alongside their design docs (same folder)

---

### Proposal 2: SHAMT-N Numbering Convention

**Problem:** Currently agents scan existing files to find the next N, which is error-prone.

**Solution:** Create `design_docs/NEXT_NUMBER.txt` containing a single integer.

**Workflow:**
1. When creating a new design doc, read `NEXT_NUMBER.txt` (e.g., contains `27`)
2. Create `SHAMT27_DESIGN.md`
3. Increment the file to `28`
4. Commit the number file alongside the design doc

**Initial value:** After migrating existing docs, set to the next available number.

**Alternative considered:** Use git tags or scan files. Rejected because:
- Git tags require git commands and may not be up-to-date locally
- Scanning files is error-prone if files are in different states/folders

---

### Proposal 3: Design Doc Template

Create a standardized template at `.shamt/guides/templates/design_doc_template.md`:

```markdown
# SHAMT-{N}: {Title}

**Status:** Draft | Validated | In Progress | Implemented
**Created:** {date}
**Branch:** `feat/SHAMT-{N}`
**Validation Log:** [SHAMT{N}_VALIDATION_LOG.md](./SHAMT{N}_VALIDATION_LOG.md)

---

## Problem Statement
{What problem does this solve? Why does it matter?}

---

## Goals
{Numbered list of what success looks like}

---

## Detailed Design

### Proposal 1: {Title}
{Description, rationale, alternatives considered}

### Proposal 2: {Title}
{...}

---

## Files Affected
{Table or list of files that will be created/modified/deleted}

---

## Implementation Plan

### Phase 1: {Name}
- [ ] Step 1
- [ ] Step 2

### Phase 2: {Name}
- [ ] Step 1
- [ ] Step 2

---

## Validation Strategy
{How will we know the implementation is correct?}

---

## Open Questions
{Unresolved decisions that need user input}

---

## Risks & Mitigation
{What could go wrong and how do we handle it?}

---

## Change History

| Date | Change |
|------|--------|
| {date} | Initial draft created |
```

---

### Proposal 4: Design Doc Lifecycle States

| State | Location | Meaning |
|-------|----------|---------|
| **Draft** | `active/` | Being written, not yet validated |
| **Validated** | `active/` | Passed 7-dimension validation, ready for implementation |
| **In Progress** | `active/` | Implementation underway on branch |
| **Implemented** | `archive/` | Implementation complete, branch merged |
| **Incoming** | `incoming/` | Child proposal awaiting review (special state) |

**State transitions:**

```
[Child Proposal] → incoming/ → (review & promote) → active/ (Draft) → Validated → In Progress → archive/
[Master Design]  → active/ (Draft) → Validated → In Progress → archive/ (Implemented)
```

**Child proposal promotion:** When a child proposal is promoted from `incoming/` to `active/`:
1. Review the proposal content
2. If it warrants a full design doc, create a new `SHAMT{N}_DESIGN.md` in `active/` that incorporates the proposal
3. Delete or archive the original proposal file
4. The proposal naming convention (`{project}-{epic}-SHAMT-UPDATE-PROPOSAL.md`) is preserved for traceability in the archive if kept

**Rejected proposals:** Move to `archive/rejected/` with a rejection note at the top of the file explaining why.

---

### Proposal 5: Validation Guide

Create `.shamt/guides/design_doc_validation/` with:

1. **README.md** — Overview and when to validate
2. **validation_workflow.md** — Step-by-step 7-dimension validation process
3. **validation_log_template.md** — Template for recording validation rounds

**The 7 Dimensions (from CLAUDE.md):**
1. Completeness — All aspects covered, problem fully stated, edge cases addressed
2. Correctness — Factual claims accurate, proposed changes work as described
3. Consistency — Internal consistency, no conflicts with existing guides
4. Helpfulness — Proposals solve the stated problem, benefit worth complexity
5. Improvements — Simpler or better alternatives considered
6. Missing proposals — Important items not left out of scope
7. Open questions — Unresolved decisions surfaced

**Exit criterion:** Primary clean round (all 7 pass with ≤1 LOW-severity issue) + 2 independent sub-agent confirmations

**Validation log lifecycle:**
1. Create `SHAMT{N}_VALIDATION_LOG.md` in `active/` when starting validation (use template)
2. Log lives alongside the design doc throughout its lifecycle
3. When design doc moves to `archive/`, validation log moves with it

---

### Proposal 6: Implementation Execution Tracking

The design doc's **Implementation Plan** section serves as the execution tracker:

1. Use checkbox format for steps: `- [ ]` → `- [x]`
2. Update checkboxes as implementation proceeds
3. Add notes inline when steps complete: `- [x] Step 1 (done in commit abc123)`
4. Status field in header reflects overall progress

**Example:**

```markdown
## Implementation Plan

### Phase 1: Create folder structure
- [x] Create `design_docs/active/` (done in commit abc123)
- [x] Create `design_docs/incoming/`
- [x] Create `design_docs/archive/`

### Phase 2: Create template
- [ ] Create design doc template
- [ ] Create validation log template
```

---

### Proposal 7: Update Master Dev Workflow

Update `.shamt/guides/master_dev_workflow/master_dev_workflow.md` to reference:

1. New design doc location (`design_docs/active/`)
2. Design doc template
3. Validation workflow
4. Lifecycle states and transitions
5. SHAMT-N numbering convention

Update CLAUDE.md to fully document the design doc process:

1. **Update Project Structure section** — Add `design_docs/` folder to the tree diagram
2. **Update Master Dev Workflow section** — Change design doc location from repo root to `design_docs/active/`
3. **Add new "Design Doc Lifecycle" section** covering:
   - When to create a design doc (large changes, multi-guide, needs planning)
   - How to create: read `NEXT_NUMBER.txt`, use template, increment number
   - Lifecycle states: Draft → Validated → In Progress → Implemented
   - Folder transitions: `active/` → `archive/`
4. **Update Design Doc Validation section** — Point to `.shamt/guides/design_doc_validation/` for detailed workflow
5. **Add Implementation Validation section** — Document the 5-dimension post-implementation validation loop
6. **Document child proposal handling** — `incoming/` folder, promotion process, `archive/rejected/` for rejections

---

### Proposal 8: Update Export/Import Scripts

**Export script changes (`export.sh`, `export.ps1`):**
- Change destination from `$MASTER_DIR/design_docs/unimplemented` to `$MASTER_DIR/design_docs/incoming`
- Update variable naming for clarity

**Import script verification:**
- Import scripts only sync `.shamt/guides/` and `.shamt/scripts/`
- `design_docs/` is NOT inside `.shamt/`, so import scripts require NO changes
- This confirms design docs won't accidentally propagate to child projects

**Export workflow guide (`export_workflow.md`):**
- Update path reference from `design_docs/unimplemented/` to `design_docs/incoming/`

---

### Proposal 9: Clean Up Git Exclusions

**Current state:** `.git/info/exclude` contains `SHAMT*_DESIGN.md` to exclude design docs at repo root.

**After migration:**
- Design docs move to `design_docs/` folder and are version-controlled
- Remove `SHAMT*_DESIGN.md` from `.git/info/exclude`
- Design docs are now committed and tracked

---

### Proposal 10: Implementation Validation Loop

After Phases 1-4 complete (folder structure, templates/guides, script updates, migration), run a validation loop to verify the design doc was fully and correctly implemented.

**Implementation Validation Dimensions:**

1. **Completeness** — Was every proposal implemented? Walk through P1-P10 and verify: P1-P9 have corresponding file changes, P10 is documented in CLAUDE.md (via P7).
2. **Correctness** — Does the implementation match what was proposed? Check that folder structure, file contents, and script changes match the design.
3. **Files Affected Accuracy** — Were all files in the "Files Affected" table actually created/modified/moved as specified?
4. **No Regressions** — Did the implementation break anything that was working before?
5. **Documentation Sync** — Do CLAUDE.md, master_dev_workflow.md, and export_workflow.md accurately reflect the new system?

**Exit criterion:** Same as design doc validation — primary clean round (≤1 LOW-severity issue) + 2 independent sub-agent confirmations.

**After implementation validation passes:** Run a full guide audit on the entire `.shamt/guides/` tree (not just files affected by this design doc) to ensure the repo is in a healthy state. The audit must achieve 3 consecutive clean rounds.

---

## Files Affected

| File | Action | Description |
|------|--------|-------------|
| `design_docs/active/` | Create | Folder for active design docs |
| `design_docs/incoming/` | Create | Folder for child proposals |
| `design_docs/archive/` | Create | Folder for implemented design docs |
| `design_docs/archive/rejected/` | Create | Folder for rejected proposals |
| `design_docs/NEXT_NUMBER.txt` | Create | Next SHAMT-N number registry |
| `.shamt/guides/templates/design_doc_template.md` | Create | Design doc template |
| `.shamt/guides/design_doc_validation/README.md` | Create | Validation overview |
| `.shamt/guides/design_doc_validation/validation_workflow.md` | Create | Validation process |
| `.shamt/guides/design_doc_validation/validation_log_template.md` | Create | Validation log template |
| `.shamt/guides/master_dev_workflow/master_dev_workflow.md` | Modify | Reference new location/workflow |
| `.shamt/guides/sync/export_workflow.md` | Modify | Update child proposal destination path |
| `.shamt/scripts/export/export.sh` | Modify | Change destination to `design_docs/incoming` |
| `.shamt/scripts/export/export.ps1` | Modify | Change destination to `design_docs/incoming` |
| `CLAUDE.md` | Modify | Update design doc location and process |
| `.git/info/exclude` | Modify | Remove `SHAMT*_DESIGN.md` pattern |
| `SHAMT23_DESIGN.md` (repo root) | Move | To `design_docs/archive/` (implemented) |
| `SHAMT24_DESIGN.md` (repo root) | Move | To `design_docs/active/` (in progress) |
| `SHAMT25_DESIGN.md` (repo root) | Move | To `design_docs/active/` (in progress) |
| `SHAMT26_DESIGN.md` (this file) | Move | To `design_docs/active/` (validated) |
| `*_VALIDATION_LOG.md` (if exist) | Move | To same folder as corresponding design doc |

---

## Implementation Plan

### Phase 1: Create Folder Structure
- [x] Create `design_docs/` directory at repo root
- [x] Create `design_docs/active/` subdirectory
- [x] Create `design_docs/incoming/` subdirectory
- [x] Create `design_docs/archive/` subdirectory
- [x] Create `design_docs/archive/rejected/` subdirectory
- [x] Create `design_docs/NEXT_NUMBER.txt` with initial value

### Phase 2: Create Templates and Guides
- [x] Create `.shamt/guides/templates/design_doc_template.md`
- [x] Create `.shamt/guides/design_doc_validation/README.md`
- [x] Create `.shamt/guides/design_doc_validation/validation_workflow.md`
- [x] Create `.shamt/guides/design_doc_validation/validation_log_template.md`

### Phase 3: Update Existing Guides and Scripts
- [x] Update `.shamt/guides/master_dev_workflow/master_dev_workflow.md`
- [x] Update `.shamt/guides/sync/export_workflow.md`
- [x] Update `.shamt/scripts/export/export.sh`
- [x] Update `.shamt/scripts/export/export.ps1`
- [x] Update `CLAUDE.md`
- [x] Update `.git/info/exclude` (verified no `SHAMT*_DESIGN.md` pattern exists)

### Phase 4: Migrate Existing Design Docs
- [x] Move `SHAMT23_DESIGN.md` to `design_docs/archive/` (confirmed implemented)
- [x] Move `SHAMT24_DESIGN.md` to `design_docs/active/`
- [x] Move `SHAMT25_DESIGN.md` to `design_docs/active/`
- [x] Move `SHAMT26_DESIGN.md` to `design_docs/active/`
- [x] Move any existing validation logs alongside their design docs (none found)
- [x] Set `NEXT_NUMBER.txt` to 27 (done in Phase 1)

### Phase 5: Implementation Validation Loop
- [x] Run implementation validation loop (see Proposal 10)
- [x] Verify all proposals were implemented completely (all P1-P10 verified)
- [x] Verify all proposals were implemented correctly (matches design spec)
- [x] Fix any discrepancies found (none found)
- [x] Achieve primary clean round + 2 sub-agent confirmations (both confirmed zero issues)

### Phase 6: Full Guide Audit
- [ ] Run full guide audit on entire `.shamt/guides/` tree (not just affected guides)
- [ ] Fix any audit findings (even if unrelated to this design doc)
- [ ] Achieve 3 consecutive clean rounds

---

## Validation Strategy

### Pre-Implementation (Design Validation)
1. **7-dimension validation loop** on the design doc itself
2. Exit: primary clean round + 2 sub-agent confirmations

### Post-Implementation

**Phase 5: Implementation Validation Loop**
1. **Completeness** — Every proposal (P1-P10) implemented
2. **Correctness** — Implementation matches design
3. **Files Affected Accuracy** — All files created/modified/moved as specified
4. **No Regressions** — Nothing broken
5. **Documentation Sync** — CLAUDE.md, workflows reflect new system
6. Exit: primary clean round + 2 sub-agent confirmations

**Phase 6: Full Guide Audit**
1. Run audit on entire `.shamt/guides/` tree
2. Fix all findings (even unrelated to this design doc)
3. Exit: 3 consecutive clean rounds

---

## Open Questions

*All open questions have been resolved.*

### Resolved Decisions

1. **Version control design docs?** → **Yes** — Design docs will be committed to git for history, archive, and collaboration.

2. **Rejected child proposals?** → **Move to `archive/rejected/`** — Add a rejection note at the top of the file explaining why.

3. **SHAMT-23 status?** → **Archive** — SHAMT-23 is fully implemented and will be moved to `design_docs/archive/`.

---

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Existing design docs at root forgotten after migration | Medium | Low | Clear migration checklist in Phase 4 |
| Child project export scripts break with new path | Medium | Medium | Update export script, update export workflow guide |
| Too much process overhead for small changes | Low | Medium | Lightweight workflow remains for single-guide fixes (no design doc required) |
| NEXT_NUMBER.txt gets out of sync | Low | Low | Always increment immediately after reserving a number |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-01 | Initial draft created |
| 2026-04-01 | V1 validation: Fixed CRITICAL issue (wrong export destination), added sync isolation rationale, added SHAMT-N numbering, added rejected proposal handling, added .git/info/exclude cleanup, verified import scripts need no changes |
| 2026-04-01 | User decisions: version control = yes, rejected proposals → archive/rejected, SHAMT-23 = complete (archive) |
| 2026-04-01 | Added Proposal 10 (Implementation Validation Loop), split Phase 5 into Phase 5 (implementation validation) + Phase 6 (full guide audit) |
| 2026-04-01 | Expanded CLAUDE.md update plan in Proposal 7 to cover full design doc lifecycle documentation |
| 2026-04-01 | R3 validation: Fixed P1-P9/P1-P10 inconsistency (MEDIUM), added validation logs to Files Affected (LOW), updated SHAMT-23 parenthetical (LOW) |
| 2026-04-01 | R4 sub-agent findings: Added archive/rejected/ to P1 diagram (LOW), clarified validation log lifecycle in P5 (LOW), clarified timing in P10 (LOW) |
