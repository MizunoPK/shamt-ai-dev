# SHAMT-2 Sync System Enhancements — Design

**Status:** Q22 pending resolution (Q1–Q21 resolved 2026-02-24)
**Source:** Post-SHAMT-1 improvement analysis (2026-02-24)
**Created:** 2026-02-24

---

## Overview

SHAMT-1 replaced the changelog-based sync system with a script-driven export/import flow. This design document captures twelve follow-on improvements identified after reviewing the completed implementation against the intent of the system. None of these change the fundamental architecture — they are usability, quality, and discoverability improvements that make the sync system more robust and self-guiding.

---

## Proposed Improvements

### 1. Import Freshness Check

**Problem:** `import.sh` / `import.ps1` silently imports from whatever state the local `shamt-ai-dev` repo is in. If the user forgets to `git pull` first, they receive stale content with no warning.

**Proposed behavior:**
- At the start of import, check whether the master repo's local `main` branch is behind the remote
- If behind: warn and ask the user whether to proceed anyway
- If the check fails for any reason (no remote, no git repo, network error): skip the check gracefully and continue — never block import due to check failure

**Open questions:** See Q1, Q2, Q3.

---

### 2. `last_sync.conf` Tracking

**Problem:** Child projects have no visibility into when they last synced with master or how stale their guides might be. Agents can't make informed decisions about whether an import is warranted.

**Proposed behavior:**
- After each successful import run, write/update `.shamt/last_sync.conf` with the sync date and the master repo's current git commit hash
- Agents can read this file to determine how old their last sync was
- Add a reference to this file in RULES_FILE.template under the Shamt Sync section

**Example format:**
```
2026-02-24 | abc1234f
```
(date | master HEAD commit hash at time of import)

**Open questions:** See Q4, Q5, Q6, Q14, Q20.

---

### 3. RULES_FILE.template — Import Guidance

**Problem:** The Shamt Sync section of RULES_FILE.template tells agents *how* to import but not *when*. Agents that never consult the sync guides will never know to prompt the user for a sync check.

**Proposed change:**
Add a "when to import" note and a reference to `last_sync.conf` to the Shamt Sync section of `scripts/initialization/RULES_FILE.template.md`.

**Draft addition:**
```
- **When to consider importing:** At the start of a new epic, or if the guides feel
  stale — check `.shamt/last_sync.conf` for the date of the last import, then run
  import.sh if an update seems warranted
```

**Open questions:** See Q7.

---

### 4. `guides/sync/README.md` and Root `README.md` Sync Section

**Problem:** Three guides exist in `guides/sync/` with no index. Agents navigating the guide system may not discover them or know which one to read for their situation. The root `README.md` also has no pointer to the sync guide system for developers encountering the repo for the first time.

**Proposed change:**
- Create a new `guides/sync/README.md` that lists the three guides, their one-line purposes, and the overall flow (improvement → CHANGES.md → export → PR → merge → import → validation loop)
- Add a minimal pointer in the root `README.md` alerting first-time users to the sync system and directing them to `guides/sync/README.md`

**Open questions:** See Q8, Q13.

---

### 5. Master CLAUDE.md — Audit Step in PR Review

**Problem:** The "Reviewing Child Project PRs" section in `CLAUDE.md` instructs the reviewer to check whether changes are generic, but does not include running the guide audit on the changed files. A child could submit a well-intentioned improvement that has formatting/consistency issues only the audit would catch.

**Proposed change:**
Add a step to the review checklist: after merging, run the full guide audit on the entire `.shamt/guides/` tree before those changes propagate to other child projects on their next import.

**Open questions:** See Q9.

---

### 6. Export Pre-flight Guidance

**Problem:** `export_workflow.md` guides users through the export process but does not suggest running the guide audit on changed files before exporting. Low-quality contributions could reach master.

**Proposed change:**
Add a mandatory Step 1.5 in `export_workflow.md` — between confirming CHANGES.md is current and running the export script — requiring that agents run the guide audit on any shared guide files they modified before exporting.

**Open questions:** See Q10, Q12.

---

### 7. `shamt_master_path.conf` Update Documentation

**Problem:** When a user moves their local `shamt-ai-dev` repo or switches machines, `shamt_master_path.conf` becomes stale and all scripts fail. The error messages say "update the file" but the system provides no guidance on where or how this fits into the workflow — agents don't know what the file is or how to fix it.

**Proposed change:**
Add maintenance documentation explaining that `shamt_master_path.conf` holds the master repo path, and what to do if scripts fail to find master (see Q11 for location decision).

**Open questions:** See Q11.

---

### 8. Extend Audit Scope to Cover `guides/sync/`

**Problem:** The three guides in `guides/sync/` (separation_rule.md, export_workflow.md, import_workflow.md) were added in SHAMT-1 but are not included in the audit discovery scope. They are `.md` guide files in `.shamt/guides/` — the same type as every other audited file — but `stage_1_discovery.md`'s file coverage guidance predates their existence and does not include them.

**Proposed change:**
Update `guides/audit/stages/stage_1_discovery.md` to explicitly include `guides/sync/` in the file coverage scope, and update the Folders Checked header field in `guides/audit/templates/discovery_report_template.md` to enumerate `guides/sync/` as a required folder, so all three sync guides are included in every future audit run.

**Decision:** No open questions — straightforward scope addition.

---

### 9. Full Audit Coverage for `RULES_FILE.template.md`

**Problem:** `RULES_FILE.template.md` is currently only partially covered by the audit — it is checked via D8 (CLAUDE.md synchronization) for cross-reference accuracy, but is not in the discovery checklist as a first-class audited file. Every new Shamt project copies this template to create its rules file, which the agent loads at the start of every session. Quality issues in the template propagate to all child projects on initialization.

**Proposed change:**
Update `guides/audit/stages/stage_1_discovery.md` to include `scripts/initialization/RULES_FILE.template.md` as a first-class file in the audit scope. Update the Folders Checked / file coverage guidance in the discovery report template to include this file, so it is subject to all applicable audit dimensions (not just D8).

**Decision:** No open questions — the file's importance justifies full coverage.

---

### 10. Master Dev Workflow — Master-Only File Update Protocol

**Problem:** When a master Shamt epic changes system behavior (e.g., new sync scripts, new guides, new audit scope), three master-only files must be manually kept current: `CLAUDE.md`, root `README.md`, and `RULES_FILE.template.md`. These files are not propagated to child projects via import, so there is no forcing function to keep them accurate. Currently the master dev workflow has no explicit checklist item for reviewing and updating them.

**Proposed change:**
- Add an explicit step to `guides/master_dev_workflow/master_dev_workflow.md` directing the agent to review and update CLAUDE.md, README.md, and RULES_FILE.template.md as part of any epic that changes system behavior
- Add a note to `CLAUDE.md`'s Critical Rules section reinforcing this responsibility

**Open questions:** See Q15.

---

### 11. Context-Aware Audit — Master vs Child Behavior

**Problem:** The guide audit currently runs identically regardless of whether it is executed in the master Shamt repo or a child project. This misses two important opportunities:

1. **Master context:** CLAUDE.md, root README.md, and RULES_FILE.template.md are master-maintained files that should be audited with full dimension coverage when working in the master repo — not just partially via D8.

2. **Child context:** A child project's rules file (CLAUDE.md or equivalent) was generated from RULES_FILE.template.md at init time and diverges over time. The audit could compare the child's rules file against the current template to detect structural drift and flag sections that should be updated.

**Proposed change:**
- Update the audit overview and discovery report template to define two audit contexts: **master** and **child**
- In master context: include CLAUDE.md, README.md, and RULES_FILE.template.md in the discovery checklist as first-class audited files
- In child context: add an audit check that compares the child's rules file against `.shamt/scripts/initialization/RULES_FILE.template.md` and flags structural drift — missing sections, missing key guidance, or sections that diverge significantly from the template
- Add new audit dimension(s) if needed to support child context rules file comparison

**Open questions:** See Q16, Q17, Q18, Q21, Q22.

---

### 12. Audit Dimension Renumbering

**Problem:** The 18 audit dimensions are numbered D1–D18 sequentially, but their sub-round groupings do not follow the numbers. Each sub-round contains a non-contiguous mix:
- **Core (N.1):** D1, D2, D3, D8
- **Content (N.2):** D4, D5, D6, D13, D14
- **Structural (N.3):** D9, D10, D11, D12, D18
- **Advanced (N.4):** D7, D15, D16, D17

When an agent works through a sub-round checklist, the dimension numbers jump around, making it hard to track which group a dimension belongs to at a glance. D7 appears in Advanced, D8 appears in Core, D18 appears in Structural — none of this is obvious from the number alone.

**Proposed change:**
Renumber the dimensions so each sub-round occupies a consecutive block:
- **Core (N.1):** D1–D4 (currently D1, D2, D3, D8)
- **Content (N.2):** D5–D9 (currently D4, D5, D6, D13, D14)
- **Structural (N.3):** D10–D14 (currently D9, D10, D11, D12, D18)
- **Advanced (N.4):** D15–D18 (currently D7, D15, D16, D17)

This requires updating all references to dimension numbers throughout the audit guide system (dimension files, audit_overview.md, README.md, stage guides, templates, quick reference, pattern library). Existing output reports in `audit/outputs/` are historical and will retain old numbers — a migration note should be added.

**Open questions:** See Q19.

---

## Open Questions

### Q22 — D19: behavior when `rules_file_path.conf` path is stale or missing

`rules_file_path.conf` stores an absolute path (written by init.sh using `$(pwd)` at init time). If the project directory has moved or was cloned to a different path, the stored path is stale and D19 cannot locate the child's rules file.

What should D19 do when the stored path is invalid?

- **A** — Skip D19 gracefully with a note ("rules file not found at stored path — re-run init to update `rules_file_path.conf`; D19 skipped") — consistent with the design-wide pattern of skipping gracefully on check failure
- **B** — Flag as an audit finding (LOW severity) requiring the user to re-run init before D19 can run

---

## Resolved Questions

**Q1 → B:** Print a note ("no remote configured — skipping freshness check") and continue.

**Q2 → A:** Warn + prompt: "master appears to be behind origin/main. Proceed anyway? [y/N]"

**Q3 → A:** Use `git fetch`, then compare local `main` against `origin/main`. More accurate than ls-remote; the local state change (updating remote tracking refs) is acceptable.

**Q4 → A:** Write `last_sync.conf` on every import run, including no-change runs. Records that a check was performed.

**Q5 → A:** Always gitignore `last_sync.conf`, unconditionally (same treatment as `shamt_master_path.conf`). It is operational state, not config.

**Q6 → A:** Minimal format — `YYYY-MM-DD | <short-hash>` on one line, easy to parse.

**Q7 → A:** Reference `last_sync.conf` by name in the RULES_FILE.template note.

**Q8 → B + root README.md:** `guides/sync/README.md` includes full flow overview (export → PR → merge → import cycle). Additionally, add a minimal pointer in the root `README.md` alerting first-time users to the sync system.

**Q9 → A:** Full audit — run the complete guide audit on the entire `.shamt/guides/` tree after merging a child PR.

**Q10 → A:** Add the audit note as a standalone Step 1.5 between Step 1 (verify CHANGES.md) and Step 2 (run export script) in `export_workflow.md`.

**Q11 → C:** Both locations — RULES_FILE.template for proactive awareness; `import_workflow.md` and `export_workflow.md` Common Situations for operational context when scripts fail.

**Q12 → B:** Mandatory — "run the guide audit on any shared guide files you modified before exporting."

**Q13 → B:** Add a reference to `guides/sync/README.md` in RULES_FILE.template's Shamt Sync section.

**Q14 → B:** Do not mention `last_sync.conf` in the import agent prompt. It is written automatically and requires no agent action.

**Q15 → A:** Add as a checklist item within the existing workflow steps in `master_dev_workflow.md` (not a dedicated phase or section).

**Q16 → A:** Check for the presence of `.shamt/shamt_master_path.conf`. If the file exists, the audit is running in a child project. If absent, it is running in the master repo.

**Q17 → B:** Structural + key content — verify all major sections exist AND that critical guidance (Shamt Sync section, Git Conventions) has not been removed or substantially altered.

**Q18 → A:** New named dimension: D19 — "Rules File Template Alignment" — applied in child context only.

**Q19 → A:** Renumber first (Improvement 12 before Improvement 11). Establish the clean D1–D18 scheme, then add D19 for Rules File Template Alignment as part of Improvement 11. The Advanced block will extend to D15–D19 after both improvements are complete.

**Q20 → B:** Do not add gitignore handling to the import script. Init handles it for new projects. For existing child projects importing SHAMT-2, add a migration note to `import_workflow.md` instructing them to manually add `.shamt/last_sync.conf` to their `.gitignore`.

**Q21 → A:** D19 reads `.shamt/rules_file_path.conf` (written by init.sh at initialization time) to locate the child's rules file. This file already stores the full path to the rules file regardless of AI service.

---

## Design Decisions

### Freshness Check
- `git fetch` approach; compare local `main` against `origin/main` after fetch
- No remote: print a note and skip (never block)
- Behind remote: warn and prompt `[y/N]`; default is No (do not proceed)
- Any other failure: skip gracefully, continue import

### `last_sync.conf`
- Written after every import run (including no-change runs)
- Format: `YYYY-MM-DD | <short-hash>` (one line)
- Always gitignored — new projects: init.sh adds it unconditionally; existing projects: migration note in import_workflow.md instructs manual addition (per Q20 → B)
- Located at `.shamt/last_sync.conf` in the child project

### RULES_FILE.template Additions
- Add "when to import" note referencing `last_sync.conf` by name
- Add a reference to `guides/sync/README.md` in the Shamt Sync section
- Add `shamt_master_path.conf` maintenance note (per Q11 → C)

### guides/sync/README.md
- Full flow overview: all three guides listed with one-line purposes + the export → PR → merge → import cycle illustrated
- Root `README.md` gets a minimal pointer to the sync system for first-time users

### Audit Integration
- Export pre-flight: mandatory audit step added as Step 1.5 in `export_workflow.md`
- PR review: full guide audit on entire `.shamt/guides/` tree, added to CLAUDE.md review checklist

### shamt_master_path.conf Documentation
- RULES_FILE.template: brief note explaining what the file is and how to update it
- import_workflow.md and export_workflow.md: operational note in Common Situations

### Master Dev Workflow Update Protocol
- Master-only file update responsibility added as a checklist item within existing workflow steps (not a dedicated phase)
- Applies to CLAUDE.md, root README.md, and RULES_FILE.template.md

### Audit Context Detection
- Presence-based: if `.shamt/shamt_master_path.conf` exists → child context; if absent → master context
- No agent declaration required — automatic at audit start

### Child Context Rules File Comparison
- Structural + key content check: verify all major sections present AND critical guidance not removed or substantially altered
- Key sections to verify: Shamt Sync, Git Conventions (any section with Shamt-specific workflow guidance)
- Implemented as new D19: Rules File Template Alignment
- Rules file location: read `.shamt/rules_file_path.conf` (written by init.sh; stores full path regardless of AI service)

### Audit Dimension Renumbering Order
- Improvement 12 (renumber D1–D18) runs before Improvement 11 (add D19)
- After renumbering: Core D1–D4, Content D5–D9, Structural D10–D14, Advanced D15–D18
- After Improvement 11: Advanced extends to D15–D19

---

## Proposed Implementation Phases

### Phase 1 — Design Finalization (Q22 pending)
- Q1–Q14 resolved (2026-02-24)
- Q15–Q19 resolved (2026-02-24)
- Q20–Q21 resolved (2026-02-24)
- Q22 pending resolution

### Phase 2 — Script Changes
- Update `scripts/import/import.sh` and `import.ps1`: add freshness check (git fetch → compare → prompt), write `last_sync.conf`
- Update `scripts/initialization/init.sh` and `init.ps1`: unconditionally gitignore `.shamt/last_sync.conf`

### Phase 3 — Guide and Template Changes
- Create `guides/sync/README.md` (full flow overview)
- Update root `README.md` (minimal sync system pointer for first-time users)
- Update `scripts/initialization/RULES_FILE.template.md` (when-to-import note, last_sync.conf reference, sync/README.md reference, shamt_master_path.conf maintenance note)
- Update `guides/sync/export_workflow.md` (Step 1.5 mandatory audit; Common Situations shamt_master_path.conf note)
- Update `guides/sync/import_workflow.md` (Common Situations `shamt_master_path.conf` note; SHAMT-2 migration note: manually add `.shamt/last_sync.conf` to `.gitignore` for existing projects)
- Update `CLAUDE.md`: add full audit step to PR review checklist (Improvement 5); add master-only file update responsibility to Critical Rules section (Improvement 10)
- Update `guides/audit/stages/stage_1_discovery.md` and `guides/audit/templates/discovery_report_template.md`: add `guides/sync/` and `RULES_FILE.template.md` to file coverage scope; define master vs child context; add master-context file coverage
- Update `guides/master_dev_workflow/master_dev_workflow.md` (master-only file update step per Q15)
- Renumber audit dimensions first (Improvement 12): update all dimension files, `audit_overview.md`, `audit/README.md`, stage guides, templates, quick reference, pattern library, and discovery report template — establishing D1–D18 as the clean base
- Then implement Improvement 11: add D19 (Rules File Template Alignment) as the new Advanced context dimension

### Phase 4 — Validation
- Run guide audit against all updated files
- Validate import script changes end-to-end

---

## Open Questions Summary

| # | Topic | Status |
|---|-------|--------|
| Q1 | Freshness check — no remote configured | Resolved → B |
| Q2 | Freshness check — prompt vs warn-only | Resolved → A |
| Q3 | Freshness check — implementation method | Resolved → A |
| Q4 | last_sync.conf — write on no-change runs | Resolved → A |
| Q5 | last_sync.conf — gitignore behavior | Resolved → A |
| Q6 | last_sync.conf — format | Resolved → A |
| Q7 | RULES_FILE.template — reference style | Resolved → A |
| Q8 | sync/README.md — scope | Resolved → B + root README.md |
| Q9 | PR review audit — full vs targeted | Resolved → A |
| Q10 | Export pre-flight — placement | Resolved → A |
| Q11 | shamt_master_path.conf docs — location | Resolved → C |
| Q12 | Export pre-flight audit — mandatory vs advisory | Resolved → B |
| Q13 | sync/README.md — external discoverability | Resolved → B |
| Q14 | Import agent prompt — mention last_sync.conf | Resolved → B |
| Q15 | Master dev workflow — update protocol prominence | Resolved → A |
| Q16 | Audit context detection — master vs child | Resolved → A |
| Q17 | Child context — rules file comparison depth | Resolved → B |
| Q18 | Child context check — new dimension vs D8 extension | Resolved → A |
| Q19 | Dimension renumbering — before or after Improvement 11 | Resolved → A |
| Q20 | last_sync.conf gitignore — existing child projects | Resolved → B |
| Q21 | D19 — locating the child's rules file | Resolved → A |
| Q22 | D19 — behavior when rules_file_path.conf path is stale | Pending |

---

*This document is the centralized reference for the SHAMT-2 improvements. Update it as decisions are made and questions are resolved.*
