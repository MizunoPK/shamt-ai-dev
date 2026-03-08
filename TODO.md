# Shamt Master — Backlog / Todo

Items discovered during development and testing that need to be addressed in the master guide/script system.

---

## Open Items

### 1. Prevent agents from replacing `SHAMT-{N}` placeholder in shared guides

**Discovered:** 2026-03-07 — first export sync test with a Copilot child project (JNJ-Hackathon / KAI tag).

**Problem:** After importing, the Copilot agent replaced `SHAMT-{N}` example references throughout the shared guides with the project's own epic tag (`KAI-{N}`). When those guide files are later exported back to master, they carry project-specific epic tag contamination that would propagate to all future child projects via import.

**What needs to change:** Agents working in child projects must understand that `SHAMT-{N}` in the shared guides (`.shamt/guides/`) is a generic placeholder, not a literal reference to the master SHAMT project. They should never substitute it with the child project's epic tag. This rule needs to be clearly stated in:
- The rules file template (`scripts/initialization/RULES_FILE.template.md`)
- The export workflow guide (`guides/sync/export_workflow.md`) — as a pre-export check
- Possibly the import workflow guide as an explicit post-import rule

---

### 2. Auto-generate a placeholder `last_sync.conf` on import

**Discovered:** 2026-03-07 — first export sync test.

**Status:** ✅ DONE — 2026-03-07

**What was done:**
- `import.sh`/`import.ps1`: already wrote `last_sync.conf` unconditionally (before the "already up to date" early exit) — no change needed
- `init.sh`/`init.ps1`: now write `last_sync.conf` during the "Writing config files" step, using the master HEAD hash at initialization time

---

### 3. Formalize epic request creation and deepen initial discovery

**Discovered:** 2026-03-07

**Problem/Opportunity:** The current epic request format and S1 discovery process are relatively lightweight. Epic request files lack a structured, formal template that guides the user and agent through thorough upfront discovery — leading to ambiguity that surfaces late in the workflow.

**What needs to change:**
- Create a formal `EPIC_REQUEST_TEMPLATE.md` (or improve the existing one) with structured sections that prompt deep exploration: goals, constraints, unknowns, risks, affected systems, success criteria
- Expand the S1 epic planning guide to include a genuine discovery/Q&A phase — the agent should ask clarifying questions before producing a spec, not after
- Consider a dedicated "discovery round" step before any spec writing begins

---

### 5. Automate and standardize git procedures for the export workflow

**Discovered:** 2026-03-07 — first export sync test.

**Problem:** The current export workflow requires manual git steps — branch creation, staging, committing, and opening a PR are all done ad-hoc with no standard conventions enforced. This makes exports error-prone and inconsistent across different runs.

**What needs to change:**
- Define a standard branch naming convention for export syncs (e.g., `feat/child-sync-{YYYYMMDD}` or `feat/sync-{child-tag}-{YYYYMMDD}`)
- Add a git automation step to the export script or export workflow guide that creates the branch automatically before copying files
- Define the standard commit message format for export sync commits
- Add a post-export checklist step that guides the reviewer through opening a PR (or script it if `gh` CLI is available)
- Consider adding a dry-run mode to the export script that shows what would be copied/deleted before making changes

---

### 4. Add user review step for implementation plan before execution begins

**Discovered:** 2026-03-07

**Problem/Opportunity:** After spec and test strategy are finalized, the agent currently moves into implementation without giving the user an explicit opportunity to review and approve the execution plan. This can lead to wasted work if the planned approach diverges from user expectations.

**What needs to change:**
- Add a step in the workflow (likely at the S4→S5 transition or within S5) where the agent produces an implementation plan summary and pauses for explicit user approval before any code is written
- Define what the plan summary must include: file-level scope, approach per component, known risks, order of operations
- Update the relevant stage guides (S4, S5) and any validation loop checkpoints to enforce this gate

---
