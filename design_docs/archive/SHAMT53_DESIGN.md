# SHAMT-53: Full-Shamt Codex Skills Migration (`~/.codex/prompts/` → `.agents/skills/`)

**Status:** Implemented (2026-05-04). Guide audit: 5 rounds, consecutive_clean = 3.
**Created:** 2026-05-03
**Branch:** `feat/SHAMT-53`
**Validation Log:** [SHAMT53_VALIDATION_LOG.md](./SHAMT53_VALIDATION_LOG.md)
**Type:** Design Proposal — full-Shamt scope (not Lite)
**Related:** [SHAMT-42](../archive/SHAMT42_DESIGN.md) (the original Codex parity design that introduced the interim), [SHAMT-51 v2](./SHAMT51_DESIGN_v2.md) (which surfaced this gap during research; OQ 8 resolution split SHAMT-53 into a separate design doc)

---

## TL;DR

SHAMT-42 deployed full-Shamt skills to `~/.codex/prompts/shamt-<name>.md` as an "interim, deprecated-but-functional" surface. The interim was chosen because Codex's native Skills surface wasn't stable when SHAMT-42 was designed. **Codex Skills launched December 2025** and is now GA. The interim should move to `.agents/skills/<name>/SKILL.md` — repo-shareable, project-scoped, the canonical SKILL.md convention shared with Claude and Cursor.

This is full-Shamt scope (NOT Lite). It changes deployment behavior for every existing full-Shamt-on-Codex child project: skills move from a per-user home directory to the project tree, where they become git-shareable. The change is mostly mechanical (update `regen-codex-shims.sh` deployment target) plus documentation, plus a one-shot cleanup of the orphaned per-user files.

Risk surface: every existing full-Shamt-on-Codex child project must re-run `regen-codex-shims.sh` to pick up the new behavior. Slash invocation changes from `/prompts:shamt-<name>` to `/skills` menu or `$shamt-<name>` mention.

---

## Problem Statement

`.shamt/host/codex/README.md` ("Skills Surface (Interim)") states:

> Shamt skills are currently deployed to `~/.codex/prompts/shamt-<name>.md`. This is the deprecated-but-functional custom-prompts directory. Invoke with `/prompts:shamt-<name>`.
>
> When Codex's new skills surface stabilizes, the regen target will move to the canonical Codex skills location. The migration path: update `regen-codex-shims.sh`'s Phase 1 to write to the new location and stop writing to `~/.codex/prompts/`.

That stabilization happened in December 2025. Codex Skills are GA. They live at `.agents/skills/<name>/SKILL.md` (repo) or `~/.agents/skills/` (user) or `/etc/codex/skills` (admin). They're invokable via `/skills` (interactive menu) or `$skill-name` (mention syntax) — and crucially, they're **repo-shareable**, which the custom-prompts surface is not.

**Concrete trigger:** Every full-Shamt-on-Codex child project today has a quirk: skills installed in the developer's home directory rather than committed alongside the project. Teammates running `git pull` don't get the skills automatically; they need to run regen on their own machine. This creates onboarding friction and version-skew risk (one developer's `~/.codex/prompts/shamt-<name>.md` may be older than another's).

**Impact of not solving:** The interim is deprecated-but-functional today. As Codex iterates on its prompts directory, the interim could break or get removed. More immediately, every developer continues to deal with per-machine deployment of Shamt skills instead of `git pull` shipping them.

---

## Goals

1. Migrate full-Shamt's `regen-codex-shims.sh` to deploy skills to `.agents/skills/<name>/SKILL.md` (project-scoped, repo-shareable) instead of `~/.codex/prompts/shamt-<name>.md`.
2. Provide a one-shot cleanup mechanism so existing child projects can remove orphaned per-user skill files after migration.
3. Update slash-invocation guidance throughout the master repo's guides (anywhere `/prompts:shamt-*` is referenced becomes `/skills` menu or `$shamt-*`).
4. Update `.shamt/host/codex/README.md` to remove the "deprecated-but-functional interim" language and reflect the new canonical surface.
5. Provide a clear migration path for child projects: re-run `regen-codex-shims.sh`, optionally run cleanup, verify slash invocation still works.

---

## Detailed Design

### Proposal 1: Update `regen-codex-shims.sh` Phase 1 deployment target

**Description:** In `.shamt/scripts/regen/regen-codex-shims.sh` (and `.ps1`), change the skills deployment phase:

**Current (interim):**
```
For each shamt-<name>/SKILL.md in .shamt/skills/ (filtered by master-only):
  Copy verbatim to ~/.codex/prompts/shamt-<name>.md
```

**New (canonical):**
```
For each <name>/SKILL.md in .shamt/skills/ (filtered by master-only):
  Copy verbatim to <PROJECT>/.agents/skills/<name>/SKILL.md
```
(Here `<name>` is the full skill directory name, e.g., `shamt-validator`, `shamt-builder`.)

The `.agents/skills/` directory becomes git-tracked content in the child project. Teammates pull skills alongside code.

**Rationale:** Codex Skills is the canonical surface. Per-project deployment matches every other host (Claude `.claude/skills/`, Cursor `.cursor/skills/`).

**Filtering preserved.** `master-only: true` skills are still skipped on child projects; `master-only: false` skills still deploy. Same filter logic; only the destination changes.

**Idempotency preserved.** Re-running regen overwrites existing `.agents/skills/<name>/SKILL.md` files; user-authored skills under different names are untouched.

**Alternatives considered:**
- *(A) Dual-write transition.* Have regen write to BOTH `.agents/skills/` and `~/.codex/prompts/` for one or two release cycles to ease migration. Rejected: doubles the maintenance surface, doesn't solve the per-machine problem (teammates still need to wait for the cycle to end), and Codex's prompts surface is "deprecated-but-functional" so we shouldn't keep writing to it.
- *(B) Leave the interim in place; add `.agents/skills/` as a parallel path.* Rejected: defeats the goal of repo-shareability.

### Proposal 2: One-shot cleanup script for orphaned interim files

**Description:** New script at `.shamt/scripts/cleanup/cleanup-codex-prompts-interim.sh` (and `.ps1`). Behavior:

1. Scan `~/.codex/prompts/` for files matching `shamt-*.md`.
2. For each match, check whether the corresponding skill exists in `.agents/skills/<name>/SKILL.md` in the current project.
3. If yes (skill is now in project tree): delete the per-user copy with `rm`. Print: `"Removed orphaned interim: ~/.codex/prompts/<name>.md (now at .agents/skills/<name>/)"`.
4. If no (project doesn't have the skill — possibly a different project, possibly user's manual addition): skip with a warning. Print: `"Skipped ~/.codex/prompts/<name>.md (no matching skill in project tree; may belong to another project)"`.
5. Print summary at end.

**Rationale:** Cleanup is opt-in, not automatic. The script is conservative: it only removes files for which a project-tree replacement exists. This avoids accidentally deleting a per-user skill that belongs to a different project the developer is also working on.

**Invocation:** Documented as a one-time post-migration step:
```
bash .shamt/scripts/cleanup/cleanup-codex-prompts-interim.sh
```

**Not run automatically by regen.** Intentional — cleanup is destructive (file deletion) and the user should opt into it explicitly.

**Alternatives considered:**
- *(A) Have `regen-codex-shims.sh` automatically delete orphaned files.* Rejected for safety. Users may have multiple projects, and a regen in one project shouldn't delete files that belong to another.
- *(B) Skip cleanup entirely; let users delete manually.* Rejected for friendliness — Shamt should provide the tooling even if it's opt-in.

### Proposal 3: Slash-invocation and path-reference updates

**Description:** Audit master content for two distinct kinds of stale references:

**(a) Invocation syntax (`/prompts:shamt-<name>`)** — slash commands that won't work post-migration:

| Old syntax | New equivalent |
|---|---|
| `/prompts:shamt-validator` | `/skills` menu → select `shamt-validator`, OR `$shamt-validator` mention |
| `/prompts:shamt-builder` | `/skills` menu → select `shamt-builder`, OR `$shamt-builder` mention |
| (etc.) | |

**(b) Path references (`~/.codex/prompts/...`)** — file path mentions that describe the deprecated location, in prose or in code:

| Old path reference | New equivalent |
|---|---|
| `~/.codex/prompts/<name>.md` | `<PROJECT>/.agents/skills/<name>/SKILL.md` |
| `~/.codex/prompts/shamt-master-reviewer.md` | `<PROJECT>/.agents/skills/shamt-master-reviewer/SKILL.md` |

**Files to audit (enumerated by Phase 1's two-pattern grep — see Phase 1 below):**
- `.shamt/host/codex/README.md` — the primary "interim" doc; replaced wholesale per Proposal 4.
- `.shamt/host/codex/master-reviewer-workflow.yml.template` — lines 73 (comment) and 82 (Python `os.path.expanduser("~/.codex/prompts/shamt-master-reviewer.md")`). NOT a simple string replacement: the Python in line 82 reads the skill file from disk for use in the workflow. Post-migration this must read from `<repo>/.agents/skills/shamt-master-reviewer/SKILL.md` (project-tree path, not user home). **Path-resolution strategy:** the workflow runs as a GitHub Actions job; the runner's working directory is `$GITHUB_WORKSPACE` (the repo root). Replacement Python: `skill_path = os.path.join(os.environ.get("GITHUB_WORKSPACE", os.getcwd()), ".agents/skills/shamt-master-reviewer/SKILL.md")`. The `os.getcwd()` fallback handles non-Actions invocation (manual runs, local testing). Update the comment on line 73 to: `# The skill is loaded from <repo>/.agents/skills/shamt-master-reviewer/SKILL.md (deployed by regen-codex-shims.sh)`.
- `.shamt/scripts/initialization/ai_services.md` — line ~29 describes the Codex entry's "Notes" with the interim path. Rewrite to say `regen-codex-shims.sh` deploys skills to `.agents/skills/` (canonical Codex Skills surface, GA Dec 2025). Note: commands still deploy to `~/.codex/prompts/`; do not remove that from the description.
- `.shamt/guides/sync/import_workflow.md` — line ~59 mentions `~/.codex/prompts/` in the post-import regen behavior summary for skills. Update skills-specific portion to `.agents/skills/`. Commands-related references in this file (if any) stay unchanged.
- `.shamt/scripts/regen/regen-codex-shims.sh` — has both interim path references and inline comments referencing them; updated by Proposal 1 + this audit pass.
- `.shamt/scripts/regen/README.md` — rewritten by SHAMT-52's guide audit; skills rows (~lines 21, 78) describe deployment to `~/.codex/prompts/shamt-<name>.md`. Update to `.agents/skills/<name>/SKILL.md`. The commands row (~line 80, `Commands → ~/.codex/prompts/`) is **correct** and must NOT be changed.
- `.shamt/commands/README.md` line 26 (`**Codex** → ~/.codex/prompts/<name>.md`) — **DO NOT MODIFY**. This describes command deployment, not skill deployment. Commands continue to deploy to `~/.codex/prompts/` after SHAMT-53; this line is correct.
- `.shamt/guides/composites/*.md` — architect-builder composite, validation-loop composite, etc. Phase 1's grep will surface specific lines.
- Any other file Phase 1's grep finds that isn't on this list.

**Rationale:** Stale invocation guidance is silent broken behavior; stale path references mislead future readers about where Shamt deploys content. Both kinds need cleanup. The master-reviewer-workflow template is the most consequential since it's executable Python — a stale path means the workflow will fail at runtime.

**Approach:** Phase 1 below produces the canonical file list via two complementary greps.

### Proposal 4: `.shamt/host/codex/README.md` rewrite

**Description:** Remove the entire "Skills Surface (Interim)" section (currently warns that the surface is deprecated-but-functional and migration is pending). Replace with:

```
## Skills Surface

Shamt skills deploy to `<PROJECT>/.agents/skills/<name>/SKILL.md` — Codex's
canonical project-scoped Skills surface (GA since December 2025).

Invoke via `/skills` (interactive menu in chat composer) or `$skill-name`
(mention syntax). Skills are repo-shareable: committing `.agents/skills/`
to git ensures all teammates get the skills on `git pull`.

To migrate from the previous interim (`~/.codex/prompts/shamt-<name>.md`):
1. Pull the latest master content (or run `import.sh`).
2. Re-run `regen-codex-shims.sh`.
3. (Optional) Run `bash .shamt/scripts/cleanup/cleanup-codex-prompts-interim.sh`
   to remove orphaned per-user files.
```

**Rationale:** The README is the authoritative reference for Codex host wiring. It must reflect current state, not historical interim.

---

## Files Affected

**Legend:**
- `MODIFY` / `CREATE` apply to **master-stored** files.
- `AUDIT` means: Phase 1's grep is authoritative; modify only if hits are found, otherwise skip. Used for files where stale references are *plausible* but not confirmed at design time.
- `KEEP` means: Phase 1's grep will find this file, but it must **not** be changed. The reference is intentional and correct post-SHAMT-53.
- No `DEPLOYED` files in this design — the changes affect the *master* regen logic; the *deployed* changes are handled by child projects re-running their existing import + regen.

| File | Status | Notes |
|---|---|---|
| `.shamt/scripts/regen/regen-codex-shims.sh` | MODIFY | Phase 1 (skills) writes to `<PROJECT>/.agents/skills/<name>/SKILL.md` instead of `~/.codex/prompts/shamt-<name>.md` |
| `.shamt/scripts/regen/regen-codex-shims.ps1` | MODIFY | Same change on Windows |
| `.shamt/scripts/cleanup/cleanup-codex-prompts-interim.sh` | CREATE | One-shot cleanup of orphaned per-user files (Bash) |
| `.shamt/scripts/cleanup/cleanup-codex-prompts-interim.ps1` | CREATE | Windows variant |
| `.shamt/host/codex/README.md` | MODIFY | Replace "Skills Surface (Interim)" with new "Skills Surface" section pointing at `.agents/skills/` |
| `.shamt/host/codex/master-reviewer-workflow.yml.template` | MODIFY | Update line 73 (comment) and line 82 Python call. Replacement: `skill_path = os.path.join(os.environ.get("GITHUB_WORKSPACE", os.getcwd()), ".agents/skills/shamt-master-reviewer/SKILL.md")`. Comment becomes: `# The skill is loaded from <repo>/.agents/skills/shamt-master-reviewer/SKILL.md (deployed by regen-codex-shims.sh)`. Verify the workflow still runs end-to-end on a test PR. |
| `.shamt/scripts/initialization/ai_services.md` | MODIFY | Update Codex entry "Notes" (line ~29) — remove "(interim)" annotation; describe `.agents/skills/` as the canonical skill-deployment surface. Note: commands still deploy to `~/.codex/prompts/` (only skills migrate in SHAMT-53). |
| `.shamt/guides/sync/import_workflow.md` | MODIFY | Update line ~59's post-import regen behavior summary — change `~/.codex/prompts/` mention for skills to `.agents/skills/` |
| `.shamt/scripts/regen/README.md` | MODIFY | Updated by SHAMT-52's guide audit to document all 10 regen scripts. Now contains 3 stale `~/.codex/prompts/` references for full-Shamt skills: table row (~line 21) and two detail-section lines (~lines 78 and 80). Update to reflect `.agents/skills/<name>/SKILL.md` as the new skills destination. Note: commands still reference `~/.codex/prompts/` in this file — leave those lines as-is. |
| `.shamt/commands/README.md` | KEEP | Line 26 (`**Codex** → ~/.codex/prompts/<name>.md`) describes **command** deployment, not skill deployment. Commands do NOT migrate in SHAMT-53. This line is correct post-migration and must not be changed. Phase 1's grep will surface it; annotate as intentional. |
| `.shamt/guides/composites/*.md` (audit only) | AUDIT | Initial grep on these files at design time found zero hits, but they're the most likely candidates for stale slash-invocation references. Phase 1's grep is the authoritative pass; if no hits, skip. If hits found, update accordingly. |
| (any additional files surfaced by Phase 1's two-pattern grep) | MODIFY | Phase 1 cross-checks against this table; additions go here |
| `CLAUDE.md` (root) | MODIFY | Two updates: (a) "Codex Host Parity (SHAMT-42)" skills line (~line 164, currently "Skills: deploys to `~/.codex/prompts/shamt-<name>.md` (interim)") → reword to reflect `.agents/skills/<name>/SKILL.md` as the canonical surface. (b) "Canonical Content Layer (SHAMT-39)" section (~line 115) currently says "Regen scripts copy command bodies verbatim to `.claude/commands/` (Claude Code) and `~/.codex/prompts/` (Codex)." — add parenthetical to prevent post-migration confusion: update to "...and `~/.codex/prompts/` (Codex commands only; skills deploy to `.agents/skills/`)". The commands line in Codex Host Parity (~line 166) stays unchanged (commands still deploy to `~/.codex/prompts/`). |

---

## Implementation Plan

### Phase 1: Reconnaissance and inventory

**Two complementary grep passes are required** — invocation syntax and path references are different concerns:

- [ ] Pass 1: `grep -rn "/prompts:shamt-" .shamt/` — enumerate files referencing the interim slash invocation syntax. Save to `SHAMT53_INVOCATION_AUDIT.md`.
- [ ] Pass 2: `grep -rn "~/.codex/prompts" .shamt/` — enumerate files referencing the interim file path. Save to the same audit file (separate section).
- [ ] **Scope is `.shamt/` only** (per OQ 3 resolution). Do NOT grep `design_docs/active/` or `design_docs/archive/` — both are preserved verbatim as historical record.
- [ ] Reconcile: classify each hit as (a) needs rewriting (most cases), (b) legitimate historical reference (cleanup-script docstring, README migration-notes paragraph), or (c) Python/code that needs path swap plus logic verification (e.g., `master-reviewer-workflow.yml.template`).
- [ ] Verify Codex Skills GA documentation (WebFetch on `https://developers.openai.com/codex/skills`) is current. Confirm the `.agents/skills/<name>/SKILL.md` schema and invocation syntax (`/skills`, `$skill-name`).
- [ ] Cross-check the Phase 1 file list against this design doc's Files Affected table — any file the grep finds that's not in the table must be added before Phase 4 begins.

### Phase 2: Update `regen-codex-shims.sh` and `.ps1`

- [ ] Locate Phase 1 (skills deployment) in the existing script.
- [ ] Change destination from `~/.codex/prompts/shamt-<name>.md` to `<TARGET>/.agents/skills/<name>/SKILL.md`.
- [ ] Update directory creation logic (`mkdir -p <TARGET>/.agents/skills/<name>/` per skill).
- [ ] Verify `master-only` filtering still applies.
- [ ] Verify idempotency.
- [ ] **Do NOT modify Phase 3 (commands → `~/.codex/prompts/`).** Commands continue deploying to `~/.codex/prompts/` after SHAMT-53; only Phase 1 (skills) changes.
- [ ] Same on Windows variant.

### Phase 3: Author cleanup script

- [ ] Write `cleanup-codex-prompts-interim.sh` per Proposal 2 spec (scan, match, conservative delete, summary).
- [ ] Write `.ps1` variant.
- [ ] Manual test on a fresh test directory with synthetic `~/.codex/prompts/shamt-test.md` + matching `.agents/skills/shamt-test/SKILL.md` → confirm removal.
- [ ] Test the "no match" path → confirm warning + skip.

### Phase 4: Master content updates

- [ ] Rewrite `.shamt/host/codex/README.md` Skills Surface section.
- [ ] Walk the file list from Phase 1; update each `/prompts:shamt-*` reference to `/skills`-menu or `$shamt-*` syntax.
- [ ] Update `CLAUDE.md` (root) "Codex Host Parity (SHAMT-42)" section to note the migration.
- [ ] Add a brief migration-history note to the new Codex README section: "Before SHAMT-53 (which migrated full-Shamt's Codex regen to use the GA Skills surface), Shamt skills were deployed to `~/.codex/prompts/shamt-<name>.md` as a deprecated-but-functional interim. Codex Skills became GA in December 2025; the master regen migrated in SHAMT-53 (2026). Migration tooling for child projects: see `cleanup-codex-prompts-interim.sh`."
- [ ] **Add a Lite + full coexistence subsection to `.shamt/host/codex/README.md`** (per OQ 4 resolution). Cover both regen scripts that write to `.agents/skills/`:
  - `regen-codex-shims.sh` (full-Shamt) → deploys skills with prefix `shamt-*` (excluding `shamt-lite-*`)
  - `regen-lite-codex.sh` (Lite, from SHAMT-51) → deploys skills with prefix `shamt-lite-*`
  - Both scripts coexist safely because their prefixes do not overlap. A child project running both Lite and full Shamt simply ends up with both prefix groups in `.agents/skills/`.

### Phase 5: Validation

- [ ] Run guide audit on entire `.shamt/guides/` tree (3 consecutive clean rounds, per CLAUDE.md "Critical Rules").
- [ ] Run implementation validation loop (5 dimensions).
- [ ] End-to-end test: simulate an existing full-Shamt-on-Codex child project. Run import + regen + cleanup. Verify slash invocation works on the new surface.

### Phase 6: PR + release notes

- [ ] Open `feat/SHAMT-53` PR.
- [ ] Include a "Migration Notes" section in the PR description listing exactly what child projects need to do (re-run regen; optionally run cleanup; update any local docs that reference `/prompts:shamt-*`). **Per OQ 2 resolution this is a hard cutover** — call out explicitly that no transitional dual-write release is shipped, so child projects must re-run regen on their next sync.
- [ ] After merge: archive design doc.

---

## Validation Strategy

**Primary validation (this design doc):** 7-dimension validation loop. Exit: primary clean round + 2 independent Haiku sub-agent confirmations.

**Implementation validation:** 5-dimension validation loop. Same exit criterion.

**Testing approach:**
- *Regen output test:* Run `regen-codex-shims.sh` on a fresh empty directory. Verify `.agents/skills/<name>/SKILL.md` files are created with correct content. Verify `~/.codex/prompts/shamt-*.md` are NOT written.
- *Cleanup test:* Manually create `~/.codex/prompts/shamt-test.md` and `.agents/skills/shamt-test/SKILL.md`. Run cleanup script. Verify the per-user file is removed and the project file is preserved.
- *Cleanup safety test:* Create `~/.codex/prompts/shamt-orphaned-from-other-project.md` with no project-tree match. Run cleanup. Verify the file is preserved and a warning is printed.
- *Slash invocation test:* In a Codex CLI session pointed at the test project, run `/skills` and verify `shamt-*` skills appear in the menu. Run `$shamt-validator` and verify it spawns.
- *Guide audit:* Verify the full audit comes clean after master content updates (no stale `/prompts:shamt-*` references remain).

**Success criteria:**
- After running regen, full-Shamt skills are present in `<PROJECT>/.agents/skills/` and absent from `~/.codex/prompts/`.
- All slash invocation references in master guides use `/skills` or `$shamt-*` syntax.
- Cleanup script behaves conservatively — only removes files with a project-tree match.
- An existing full-Shamt-on-Codex child project can migrate by running `regen` + `cleanup` and continue working without code changes.

---

## Open Questions

(All resolved 2026-05-04.)

1. **Cleanup invocation: opt-in script vs. regen prompt.** Should the cleanup script run as a separate explicit invocation (current Proposal 2), or should `regen-codex-shims.sh` prompt at the end?
   - **Resolved (2026-05-04): Explicit script.** Cleanup is a separate `cleanup-codex-prompts-interim.sh` invocation; regen-codex-shims.sh stays fully non-interactive. Better for CI/automation and matches the rest of the regen-script family. Implementation: Proposal 2 stands as written.

2. **Backward compat for slash invocation.** Should we ship a single transitional release where `regen-codex-shims.sh` writes skills to BOTH `.agents/skills/` AND `~/.codex/prompts/` so existing child projects don't lose `/prompts:shamt-*` until they migrate?
   - **Resolved (2026-05-04): No — hard cutover.** SHAMT-53 is a single-step migration. The interim is deprecated-but-functional in Codex; perpetuating it adds complexity and a follow-up removal release. Child projects migrate proactively on next regen. Implementation: PR description must include a "Migration steps" section explicitly calling out the cutover.

3. **Inventory scope for Phase 1.** Phase 1's `grep` enumeration covers `.shamt/`. Should it also cover `design_docs/active/` and `design_docs/archive/`?
   - **Resolved (2026-05-04): Only `.shamt/`.** Both `design_docs/active/` and `design_docs/archive/` are preserved verbatim as historical record — they document the era they were written in. Implementation: Phase 1's grep targets `.shamt/`; reconciliation step explicitly excludes `design_docs/`.

4. **Coordination with SHAMT-51 (Lite-on-Codex).** SHAMT-51 introduces `regen-lite-codex.sh` which writes Lite skills to `.agents/skills/`. SHAMT-53 changes `regen-codex-shims.sh` to do the same for full-Shamt skills. The two scripts coexist and both write to `.agents/skills/` using different prefixes (`shamt-lite-*` vs `shamt-*`). Should we explicitly document this coexistence?
   - **Resolved (2026-05-04): Brief README note.** Add a short subsection to `.shamt/host/codex/README.md` covering both regen scripts and the prefix-based naming convention. Cheap insurance against confusion when child projects use both Lite and full Shamt. Implementation: add the README subsection in Phase 4 (Documentation and registry updates); Files Affected already includes the README.

5. **Confirm Proposal 2's same-PR bundling of the cleanup script.** Proposal 2 commits to bundling `cleanup-codex-prompts-interim.sh` in the SHAMT-53 PR (vs. shipping it as a follow-up). Splitting would orphan users between SHAMT-53 merge and cleanup-script merge.
   - **Resolved (2026-05-04): Same PR.** Cleanup script ships in the SHAMT-53 PR. Implementation: Proposal 2 stands as written; no change.

---

## Risks & Mitigation

**R1: Existing child projects break on next regen.** A child project that runs the new regen but doesn't update local docs/scripts that reference `/prompts:shamt-*` keeps an inconsistent state — skills exist in `.agents/skills/` but local references point at `~/.codex/prompts/`.
- *Mitigation:* PR description must include explicit migration steps. Cleanup script is the safety net for the home-directory side. Master-side guide updates fix the master-side references; child projects pull those via `import.sh`.

**R2: Cleanup script accidentally deletes user data.** A naive scan/delete could remove per-user files that belong to a different project.
- *Mitigation:* Conservative match logic (Proposal 2 step 3): only delete if the corresponding skill exists in the *current* project's `.agents/skills/`. Files without a project-tree match are preserved with a warning.

**R3: Codex Skills surface changes between research date and implementation.** Skills GA Dec 2025; SHAMT-53 implementation may be weeks or months later.
- *Mitigation:* Phase 1 includes a WebFetch verification of the current schema. Pin to documented behavior; treat undocumented frontmatter fields as forward-incompatible.

**R4: Slash invocation friction during migration.** Users who run regen but haven't internalized the new invocation syntax (`/skills` menu vs. `/prompts:shamt-*`) experience temporary confusion.
- *Mitigation:* The new `.shamt/host/codex/README.md` Skills Surface section is the canonical reference. PR description and migration notes echo the change. The `$shamt-*` mention syntax is also documented as a quick alternative.

**R5: Audit churn.** Updating slash references across master guides may surface dimension-D-DRIFT issues during the audit (skill body or guide refs that aren't quite consistent post-edit).
- *Mitigation:* Phase 5's audit is mandatory; budget time for fix-up rounds. The architect-builder composite's Codex variant guide is the most likely to need careful editing.

**R6: User has skill files in `~/.codex/prompts/` that they hand-authored (not Shamt-managed).** A naive cleanup that just removes everything matching `shamt-*` could nuke user content.
- *Mitigation:* The cleanup script's match logic checks for a corresponding `.agents/skills/<name>/` in the project. User-authored skills with `shamt-` prefix that don't have a project match are preserved. Document this in the cleanup script header so users understand the check.

---

## Change History

| Date | Change |
|---|---|
| 2026-05-03 | Initial draft. Surfaced as a cross-cutting follow-up during SHAMT-51 research (OQ 8 resolved as separate design doc). |
| 2026-05-04 | OQ 1–5 resolved. Phase 1 scoped to `.shamt/`; Phase 4 augmented with Lite+full coexistence subsection; Phase 6 PR description requires explicit hard-cutover migration notes. |
