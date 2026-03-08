# Shamt Master — Backlog / Todo

Items discovered during development and testing that need to be addressed in the master guide/script system.

---

## Open Items

### 1. Prevent agents from replacing `SHAMT-{N}` placeholder in shared guides

**Discovered:** 2026-03-07 — first export sync test with a Copilot child project (JNJ-Hackathon / KAI tag).

**Status:** ✅ DONE — all three required locations addressed in previous sessions

**What was done:**
- `scripts/initialization/RULES_FILE.template.md`: "Shared Guide Rules" section added — explains `SHAMT-{N}` as a universal placeholder with ❌/✅ examples and a rule never to substitute it with the child epic tag
- `guides/sync/export_workflow.md`: Step 1.5 "Check for Epic Tag Contamination" added — grep command, explicit revert instructions, and acceptable vs. unacceptable contamination examples
- `guides/sync/import_workflow.md`: Rule added to Step 5 validation loop checklist — includes full explanatory paragraph clarifying that `SHAMT-{N}` is generic and any substitutions must be reverted immediately

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

**Status:** ✅ DONE — 2026-03-08

**What was done:**
- `guides/reference/validation_loop_discovery.md`: Added 6 new "What Counts as Issue" categories (zero questions asked, alternative interpretations, adjacent systems, implementation decisions, non-functional requirements, success criteria). Added "Adversarial Challenge" blocks to all 3 per-round checklists. Added 6 new exit criteria items. Bumped to v2.1.
- `guides/stages/s1/s1_p3_discovery_phase.md`: Expanded Step 4 question sources with 5 new categories + zero-questions hard callout. Strengthened MANDATORY CHECKPOINT 1 item 4 and added brainstorm verification item. Added anti-pattern for zero initial questions.
- `guides/templates/discovery_template.md`: Added 6-category question brainstorm table to Pending Questions section. Agents must fill each category or justify its omission.
- `DISCOVERY_LOOP_PROPOSAL.md`: Created at repo root documenting the change design (Revision 2, adversarial self-review applied).

**Note:** Creating a formal `EPIC_REQUEST_TEMPLATE.md` is explicitly out of scope for this change and may be tracked separately.

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

**Status:** ✅ DONE — 2026-03-08

**What was done:**
- `guides/templates/implementation_plan_template.md`: Added "Plan Summary" section (between Validation Loop Completion and User Approval) with 5 required fields — files to be modified/created, approach per component, known risks, implementation phases, and first S6 commit scope. Gate 5 note directs agents to show this section directly, not paraphrase.
- `guides/stages/s5/s5_v2_validation_loop.md`: Strengthened Gate 5 step 2 — replaced vague "highlight key sections" with explicit requirement to show Plan Summary section directly, verify all 5 fields present, state validation loop result, and require explicit approval. Added `🛑 MANDATORY CHECKPOINT: Gate 5` block immediately after Gate 5 step 4 with a 6-item checklist blocking S6 entry until approval is fully documented.

---
