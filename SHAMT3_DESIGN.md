# SHAMT-3 Post-Review Fixes and Improvements — Design

**Status:** Approved — implementing on feat/SHAMT-2
**Source:** Full system review conducted 2026-02-25 (post-SHAMT-2 audit)
**Created:** 2026-02-25

---

## Overview

After completing SHAMT-2's 15-round audit and a broad system review of the entire `.shamt/` tree — including a deep analysis of the sync scripts and workflow guides — twenty-four improvement items were identified. These fall into several categories: stale or incorrect content in guides and scripts, bugs in the sync scripts, documentation and structural gaps, policy decisions, and a meta-improvement to expand audit coverage to scripts so these classes of issues are caught in future audits.

None of these change the fundamental architecture of Shamt. They are correctness fixes, coverage expansions, and policy clarifications.

---

## Proposed Improvements

### 1. Epic Numbering Reset and Master Repo Tagging Redesign

**Problem:** The EPIC_TRACKER.md is stale (SHAMT-2 active but not recorded). More broadly, the current epic numbering will be reset when version 0 of the project is considered complete. Additionally, the way epic/feat branch tagging works when developing the master Shamt repo directly needs to be reconsidered — the current convention was inherited from the child project workflow and may not be the right fit for master-internal work.

**Decision:** Do not apply the simple EPIC_TRACKER.md update. Defer this improvement entirely until version 0 is complete. At that point, reset epic numbering and redesign the tagging convention for master repo work as a dedicated effort.

**Status:** Deferred — not part of SHAMT-3.

**Open questions:** None (deferred).

---

### 2. Fix pre_audit_checks.sh Stale Category A Exceptions

**Problem:** The `known_exceptions` array in `pre_audit_checks.sh` lists 14 `stages/s5/s5_p1_i3_*.md` files under "Category A: S5 iteration files." Those files were deleted from the repo (they are listed as INACTIVE in `known_exceptions.md`) and cannot appear in the check loop. The effect is:

- The script reports "Known exceptions skipped: 19" in its summary, which is false — only the 3 active Category C files can ever be matched
- The 3 active exceptions are labeled "Category B" in the script comment, but `known_exceptions.md` now calls them Category C
- The 14 dead entries are misleading to future maintainers

**Why this survived the 15-round audit:**
The audit system is focused on `.md` guide files. Its discovery patterns use grep and manual reading against markdown content. `pre_audit_checks.sh` is a shell script — while it lives inside `guides/audit/scripts/`, no audit dimension has a mechanism to parse the logic of shell scripts or verify that array entries in a script correspond to files that actually exist on disk. D9 (Content Accuracy) is the closest fit ("claims match reality") but in practice it checks claims made in guide prose, not shell script data structures. D1 (Cross-Reference Accuracy) checks file path references in markdown but does not parse shell arrays. This is a structural blind spot: when a shell script's internal state drifts from reality, no audit dimension catches it.

**Proposed fix:**
- Remove the 14 Category A entries from the `known_exceptions` array
- Update the comment label from "Category B" to "Category C"
- Update the summary output from "Known exceptions skipped: 19" to "Known exceptions skipped: 3"

**Proposed prevention (self-validating script):**
Add a self-check at the start of the script that verifies each `known_exceptions` entry actually exists on disk, and prints a warning for any that don't. This makes stale entries immediately visible the next time the script is run, rather than requiring a human to notice the mismatch.

**Open questions:** None — Q1 resolved: implementing on feat/SHAMT-2.

---

### 3. Fix discovery_report_template.md Stale Exit Criterion

**Problem:** The "Next Steps" section of `discovery_report_template.md` (line 260) says:

```text
**Proceed to Stage 5 (Loop Decision) IF:**
- [x] This is Round 3 or higher
```

This is the same "minimum 3 rounds" concept that SHAMT-2 replaced throughout the audit system with "3 consecutive zero-issue rounds." It survived the 15-round audit undetected. Every agent using this template to decide whether to exit will see "Round 3 or higher" as the check — the same logic that caused the premature completion claim that SHAMT-2 was created to fix.

**Why this survived the 15-round audit:**
Two compounding reasons:

1. **Different phrasing, same meaning.** SHAMT-2's search patterns targeted "minimum 3 rounds" and related variants. The template used "Round 3 or higher" — a semantically equivalent but textually distinct formulation that the grep patterns didn't cover. It was a blind spot in the pattern library, not a failure of the audit structure itself.

2. **Templates treated as forms, not as normative guidance.** The `discovery_report_template.md` is used to generate output reports — agents fill it in while working. There is a natural tendency to treat templates as passive containers rather than active guidance. The "Next Steps" section at the end of the template contains an embedded copy of the normative exit criterion from `stage_5_loop_decision.md`. When `stage_5_loop_decision.md` was updated, the template copy was not, because the connection between them wasn't explicit. This is a "copies of truth" problem: any time normative guidance is duplicated into a template, the copy can drift.

**Proposed fix:**
Rather than embedding the exit criterion directly in the template, replace the criterion list with a reference to the normative source:

```text
**Proceed to Stage 5 (Loop Decision) IF:**
See exit criteria in `stages/stage_5_loop_decision.md` — all criteria must pass.
Key criterion: consecutive_clean >= 3.
```

This eliminates the divergence risk entirely. The template no longer holds a copy of guidance that lives elsewhere; it points to the single authoritative source.

**Open questions:** None — Q1 resolved: implementing on feat/SHAMT-2.

---

### 4. Fix validation_loop_master_protocol.md Flowchart Language

**Problem:** The process flow diagram in `validation_loop_master_protocol.md` (lines 132, 148) says:

```text
Issues Found? → FIX ALL IMMEDIATELY → RESTART from Round 1
```

This is inconsistent with the counter examples in the same document, which correctly show continuing to Round N+1 after fixing — not literally restarting from Round 1. An agent reading the flowchart could interpret "RESTART from Round 1" as meaning it should re-number its rounds from 1 and discard its round history, which is not the intended behavior.

**Why this survived the 15-round audit:**
Two reasons:

1. **SHAMT-2's search patterns weren't looking for this.** The audit was narrowly scoped to propagating the "3 consecutive zero-issue rounds" / `consecutive_clean` language to replace "minimum 3 rounds." The phrase "RESTART from Round 1" is a different class of problem — an internal inconsistency between a diagram and its own examples — not a "minimum 3" vs "consecutive" issue. It wasn't in the pattern library for that audit cycle.

2. **ASCII diagrams are effectively invisible to grep.** The text "RESTART from Round 1" appears inside a box-drawing flowchart, not in prose. Grep-based discovery patterns don't naturally surface problems embedded in ASCII art. D10 (Intra-File Consistency) is the correct dimension for catching inconsistency between a diagram and explanatory examples in the same file, but D10 in practice focuses on formatting and structural consistency, not semantic disagreements between a visual element and its prose counterpart. Manual spot-checking is the only mechanism that would catch this — and `validation_loop_master_protocol.md` was not a primary focus of SHAMT-2's manual reading passes, since changes to that file weren't part of that epic's scope.

**Proposed change:**
Update the flowchart arrows to:

```text
Issues Found? → FIX ALL IMMEDIATELY → Counter resets to 0 → Continue to Round N+1
```

**Open questions:** None — straightforward clarification.

---

### 5. Fix validation_loop_master_protocol.md Exit Criteria Wording

**Problem:** The Exit Criteria section of `validation_loop_master_protocol.md` lists as its first criterion:

```text
- [ ] At least 3 rounds completed
```

This can be read as "any 3 rounds, even if they had issues" rather than the intended "3 consecutive zero-issue rounds." This is the same ambiguity class that SHAMT-2 corrected across the audit system, but `validation_loop_master_protocol.md` was not in the audit scope for that work.

**Why this survived the 15-round audit:**
Same root cause as Improvements 3 and 4 — textual phrasing divergence combined with file not being a primary search target:

1. **Different phrasing, same problem.** SHAMT-2's search patterns targeted "minimum 3 rounds" and variants. "At least 3 rounds completed" is semantically equivalent but textually distinct — the grep patterns didn't cover it. This is the same blind spot that allowed the discovery_report_template.md issue to survive.

2. **File not actively targeted.** `validation_loop_master_protocol.md` was not modified during SHAMT-2 and was not a focus of manual spot-checks. The audit's manual reading passes naturally concentrate on files being changed or on root-level files. A reference document that was unchanged throughout the epic is easy to overlook in the spot-check sample.

**Proposed change:**
Replace the first criterion with:

```text
- [ ] 3 consecutive zero-issue rounds achieved (consecutive_clean = 3)
```

**Open questions:** None — same fix pattern as SHAMT-2.

---

### 6. Expand pre_audit_checks.sh Scan Scope

**Problem:** SHAMT-2 added `guides/sync/` and `scripts/initialization/RULES_FILE.template.md` as first-class audit targets in `stage_1_discovery.md`. However, the automated pre-audit script (`pre_audit_checks.sh`) has coverage gaps for these files:

- D8 (TODO/TBD check) does not cover `guides/sync/` — the grep only targets `stages/`, `templates/`, `prompts/`, `reference/`
- D11 (file size check) does not cover `guides/sync/` — the `find` command only targets `stages/`
- D14 (character compliance) does not cover `RULES_FILE.template.md` — though it does already cover `guides/sync/` (see note below)

The sync guides can accumulate D8 and D11 issues without the automated pre-check catching them. `RULES_FILE.template.md` can accumulate D14 issues without detection.

**Note on D14 coverage:** The D14 Python scan uses `os.walk('.')` starting from the `guides/` working directory (the script cd's two levels up from `guides/audit/scripts/`). This recursive walk already includes `guides/sync/` — no change is needed for D14 to cover sync files. The gap for D14 is only `RULES_FILE.template.md`, which lives outside the `guides/` tree at `scripts/initialization/`.

**Why this survived the 15-round audit:**
This is a scope synchronization gap — the documented audit scope and the script's implemented scope diverged without either being wrong in isolation:

1. **Two sources of truth, no link between them.** The audit scope is defined in `stage_1_discovery.md` (which files to check). The automated pre-check scope is defined in the script itself (which directories to scan). When SHAMT-2 updated `stage_1_discovery.md` to include `sync/` and `RULES_FILE.template.md`, it was a guide change. Updating the script to match would have been a separate, coordinated action — and no mechanism exists to require or remind an agent to keep these in sync.

2. **D3 (Workflow Integration) is the closest fit but doesn't reach here.** D3 checks whether process steps described in guides are internally consistent across the guide system. In principle, it could catch "stage_1_discovery.md says to scan `sync/` but the script doesn't" — but in practice D3 focuses on step descriptions and flow logic in guide prose, not on verifying that a shell script's scan targets match a guide's scope list.

**Proposed change:**
- Add `sync/` to the D8 TODO/TBD grep scope
- Add the `RULES_FILE.template.md` path to the D14 character compliance Python scan (`sync/` is already covered by the existing recursive walk)
- Add `sync/` to the D11 file size check (same 1250-line threshold)

Intentional exclusions:
- D14 for `sync/`: already covered — no change needed
- D12 (structure validation): sync files don't follow stage-guide structure; adding them would require maintained known exceptions with no quality gain
- D17 (TOC check): all these files are well under 500 lines
- D8 for `RULES_FILE.template.md`: the template uses `{{PLACEHOLDER}}` syntax and `[Agent: ...]` markers — neither matches TODO/TBD/FIXME; coverage would produce no findings and has zero value
- D11 for `RULES_FILE.template.md`: the file is approximately 100 lines, well under the 1250-line threshold; coverage has zero value

**Open questions:** None — Option B (D8, D14, D11) selected per Q2 resolution; scope within each dimension clarified above.

---

### 7. Audit Outputs Management Policy

**Problem:** The master repo now has 80+ audit output files committed in `.shamt/guides/audit/outputs/` from the SHAMT-2 validation work. Child projects start fresh (the init script clears their `outputs/` at init time and the import script excludes it). But there is no guidance on what the master does with its own accumulated outputs over time.

**Decision:** Add `.shamt/guides/audit/outputs/` to the master's `.gitignore` (create the file if it does not yet exist — there is currently no `.gitignore` at the repo root). Outputs are transient working documents and should not be committed. Document the policy in `audit/README.md`.

**Open questions:** None — Q6 resolved: Option A (gitignore only; committed files remain in history).

---

### 8. Clarify separation_rule.md for Master Context

**Problem:** `separation_rule.md` instructs: "When you modify any file in `.shamt/guides/` or `.shamt/scripts/`, record it in `.shamt/CHANGES.md`." This is correct for child projects. In the master repo, `CHANGES.md` does not exist and is not used — the PR description serves this purpose. A master agent reading `separation_rule.md` without having read `CLAUDE.md` could try to create `CHANGES.md` in the master repo.

**Why this survived the 15-round audit:**
This issue is invisible to the audit because the audit evaluates guide content for internal correctness, not for contextual completeness across all deployment scenarios:

1. **The file is correct for its primary audience.** `separation_rule.md` is accurate and consistent for child projects. The gap only appears when read from the master context, which the audit has no mechanism to simulate.

2. **No dimension cross-references guides against CLAUDE.md.** The master-specific behavior is defined in `CLAUDE.md`, not within the guide system itself. No audit dimension checks whether shared guide instructions are complete across all operating contexts (master vs child).

**Proposed change:**
Add a one-line note to the `CHANGES.md` section of `separation_rule.md`:

```text
Note: This applies to child projects only. In master context (no shamt_master_path.conf present),
the PR description serves this purpose — do not create CHANGES.md in the master repo.
```

**Open questions:** None — straightforward clarification.

---

### 9. Fix Export Script to Propagate Deletions

**Problem:** The import script propagates deletions from master to child (correct). The export script does not propagate deletions from child to master — only additions and modifications are copied. This is a bug: if a child project's improvement involves removing a shared file (e.g., consolidating two guides), that deletion should propagate back to master via the export/PR workflow just like any other change.

**Why this survived the 15-round audit:**
1. **Scripts are outside the audit scope.** The export script's logic is never audited — no dimension reads or validates `.sh` or `.ps1` files. The absence of deletion-detection code in the script is structurally invisible.

2. **The asymmetry with import was not surfaced as a question.** The import script correctly implements `remove_deleted`. No audit dimension checks whether the export script implements equivalent functionality in the reverse direction. D3 (Workflow Integration) checks that guide descriptions are internally consistent but does not cross-reference script implementations for functional parity between import and export.

**Proposed fix:**
Update the export script to detect files that exist in the master's `.shamt/guides/` tree but are absent from the child's corresponding tree (Q7=Option A). The script deletes detected files from master's working tree and reports them in the summary alongside additions and modifications. The PR diff will show the deletion automatically.

Also: update `export_workflow.md` to document how deletions are handled, and update the next-step commit instructions accordingly (see Improvement 14 for the `git add -A` change).

**Open questions:** None — Q7 resolved: Option A (delete from master tree directly).

---

### 10. SHAMT-2 Epic Closure Documentation

**Status:** Dropped. Epic tracking will not be maintained for master repo work (see Improvement 12). Creating retroactive closure artifacts for SHAMT-2 has no value given that direction.

---

### 11. License Decision

**Status:** Dropped. No outside users yet; revisit before any public release.

---

### 12. Formalize Master Repo Development Flow

**Problem:** The master Shamt repo has no documented policy that clearly distinguishes its development process from the child project S1-S10 epic workflow. The current `master_dev_workflow.md` describes a lighter process for small guide changes, and `CLAUDE.md` references a full S1-S10 epic flow for larger work — but neither document clearly states the actual operating model: major sets of changes use `feat/SHAMT-N` branches with the same commit format as child projects, but master work is **not** tracked as epics, does not require EPIC_TRACKER.md entries, and does not follow the S1-S10 stage structure.

This ambiguity means:
- An agent starting master work doesn't know whether to create an epic folder, update the tracker, or follow stage gates
- The SHAMT-N numbering has been used for branch names but the tracker hasn't been maintained
- The design docs (`SHAMT2_DESIGN.md`, `SHAMT3_DESIGN.md`) have been used as a lightweight planning substitute with no defined relationship to the guide system

**Proposed change:**
Update `master_dev_workflow.md` and `CLAUDE.md` to explicitly define the master development model:

- **Branch and commit naming:** Major sets of changes use `feat/SHAMT-N` branches and `feat/SHAMT-N: {message}` commits — same format as child projects, used for organizational clarity and history
- **No epic tracking:** EPIC_TRACKER.md is not maintained for master repo work. SHAMT-N numbers are sequence markers for change sets, not epic identifiers
- **No S1-S10 flow:** Master work does not follow stage gates, phase transitions, or the validation loop structure of the epic workflow
- **Design docs as planning artifacts:** For significant multi-improvement changes, a design doc at the repo root (e.g., `SHAMT2_DESIGN.md`) serves as the planning and decision record — lightweight, unstructured, lives outside `.shamt/`
- **Scope decision:** Use the master dev workflow (lightweight) for single-guide fixes. Use a design doc + branch for multi-guide or cross-cutting changes. The threshold is judgment, not a gate.

**Open questions:** None — the model is clear from the user's direction. Implementation is documentation updates only.

---

### 13. Fix `Prompt-Input` Undefined in import.ps1

**Problem:** `import.ps1` line 58 calls `Prompt-Input`, a function that does not exist in PowerShell or anywhere in the script:

```powershell
$proceedChoice = Prompt-Input "  Proceed anyway? [y/N]" "N"
```

The bash equivalent uses the built-in `read -rp`. The PowerShell equivalent should use `Read-Host`. This crashes at runtime only when the freshness check triggers — i.e., when the master repo has a live remote and is behind `origin/main`. It crashes exactly when it matters most.

**Why this survived the 15-round audit:**
Same structural blind spot as Improvement 2 — scripts are outside the audit's coverage area:

1. **The audit only covers `.md` files.** No audit dimension reads or validates `.ps1` files.

2. **The bug is only reachable in a specific network condition.** In most runs the freshness check is skipped entirely, making the bug easy to overlook manually as well.

**Proposed fix:**
Replace the `Prompt-Input` call with `Read-Host`:

```powershell
$proceedChoice = Read-Host "  Proceed anyway? [y/N]"
if ([string]::IsNullOrEmpty($proceedChoice)) { $proceedChoice = "N" }
```

**Open questions:** None — straightforward bug fix.

---

### 14. Update Export Next Steps to Stage Deletions (Bundled with Improvement 9)

**Problem:** Once Improvement 9 is implemented (export script detects child deletions), the suggested next steps in both scripts and `export_workflow.md` tell the user to stage changes with:

```bash
git add .shamt/guides/ .shamt/scripts/
```

`git add` on a directory only stages additions and modifications — deleted files are not staged. A user following the next steps after Improvement 9 would open a PR with the deletion changes silently missing.

**Why this would survive the audit:**
1. **The issue doesn't exist yet — it will be introduced by Improvement 9.** No audit dimension checks whether guide instructions will remain accurate after a planned code change.

2. **Script next-steps text and guide instructions are treated as independent artifacts.** The `git add` command in the next-steps output section is separated from the detection logic by ~30 lines and is easy to overlook as a consequence.

**Proposed fix:**
Update the next steps in both `export.sh` and `export.ps1` to use `git add -A` scoped to the shamt directories:

```bash
git add -A .shamt/guides/ .shamt/scripts/
```

Update `export_workflow.md` Step 3 to match.

**Dependency:** Must be implemented together with Improvement 9.

**Open questions:** None — must be bundled with Improvement 9.

---

### 15. Fix export_workflow.md "File Hash" Description

**Problem:** `export_workflow.md` Step 2 says the script compares files "by file hash." The PowerShell script uses MD5 hashes (accurate). The bash script uses `diff -q` — a content comparison, not a hash. Both detect changes correctly, but the guide description is inaccurate for bash users.

**Why this survived the 15-round audit:**
1. **D9 doesn't cross-reference guide prose against script implementations.** Scripts are structurally outside the audit's scope.

2. **The inaccuracy is functionally harmless.** The outcome is the same — changed files are detected — making this easy to dismiss as a wording detail.

**Proposed fix:**
Update `export_workflow.md` Step 2 to say "by content comparison" — accurate for both implementations.

**Open questions:** None — documentation-only fix.

---

### 16. Fix import.ps1 Agent Prompt Backtick Escaping

**Problem:** `import.ps1` line 277 contains:

```powershell
Write-Host "3. For each changed file, check whether your ``project-specific-configs/```"
```

In PowerShell double-quoted strings, `` ` `` is the escape character. The sequence at the end — three backticks before the closing `"` — is problematic: the third backtick escapes the `"`, making it a literal quote rather than the string terminator, likely leaving the string unclosed. The bash equivalent correctly produces `` `project-specific-configs/` `` with single backticks on each side.

**Why this survived the 15-round audit:**
1. **Scripts are outside the audit scope.**
2. **PowerShell backtick escaping is non-obvious** — the line reads plausibly correct at a glance.
3. **The bug only surfaces at runtime when the import produces changes** — easy to miss in testing.

**Proposed fix:**
Update the line to use consistent backtick escaping (single backtick on each side):

```powershell
Write-Host "3. For each changed file, check whether your ``project-specific-configs/``"
```

**Open questions:** None — fix to match bash output.

---

### 17. Add PowerShell Equivalent for import_workflow.md Step 6 Delete Command

**Problem:** `import_workflow.md` Step 6 provides only a bash command for deleting diff files:

```bash
rm -f .shamt/import_diff.md .shamt/import_diff_*.md
```

No PowerShell equivalent is provided. The rest of the import guide supports both platforms; this step is inconsistent.

**Why this survived the 15-round audit:**
D17 (Accessibility and Usability) in practice focuses on structural clarity rather than platform parity of inline commands. No dimension explicitly checks that bash commands in guides have PowerShell equivalents where appropriate.

**Proposed fix:**
Add a PowerShell equivalent below the bash command:

```powershell
# PowerShell:
Remove-Item .shamt\import_diff.md, .shamt\import_diff_*.md -ErrorAction SilentlyContinue
```

**Proposed audit improvement:**
D17 should include a check: for any guide that describes platform-specific steps for one platform, verify that a corresponding equivalent exists for the other.

**Open questions:** None — documentation-only fix.

---

### 18. Add Master Working Tree Check to Export Script

**Problem:** The export script copies files directly into master's working directory with no check that master's working tree is clean first. If the master maintainer has uncommitted changes when the export runs, those changes get mixed with the child's exported files.

**Why this survived the 15-round audit:**
Script behavior gap — same structural blind spot as all other script issues. D3 checks that the export workflow guide describes a coherent process, but does not verify the script implements safeguards the guide doesn't mention.

**Proposed fix:**
Add a pre-flight check in both `export.sh` and `export.ps1` that warns (but does not abort) if master's working tree has uncommitted changes:

```bash
if ! git -C "$MASTER_DIR" diff --quiet || ! git -C "$MASTER_DIR" diff --cached --quiet; then
    echo "  Warning: master working tree has uncommitted changes."
    echo "  Exported files will be mixed with existing changes. Proceed with care."
    echo ""
fi
```

**Proposed audit improvement:**
`export_workflow.md` Step 2 should document this check explicitly, making it verifiable by D9 on future audits.

**Open questions:** None.

---

### 19. Add `git checkout main` to Export Next Steps

**Problem:** The export script's suggested next steps and `export_workflow.md` Step 3 both instruct:

```bash
cd /path/to/shamt-ai-dev
git checkout -b feat/child-sync-YYYY-MM-DD
```

If master is currently on a feature branch, this creates the sync branch off the feature branch rather than `main`. The resulting PR would be against the wrong base.

**Why this survived the 15-round audit:**
Neither D3 nor D9 naturally simulates following a sequence of git commands mentally and asking "what if the user is on the wrong branch?" Procedural correctness of git workflows requires step-by-step simulation, which is not part of any dimension's standard discovery pattern.

**Proposed fix:**
Update both the script's next steps output and `export_workflow.md` Step 3 to include `git checkout main` before branching:

```bash
cd /path/to/shamt-ai-dev
git checkout main
git checkout -b feat/child-sync-YYYY-MM-DD
git add -A .shamt/guides/ .shamt/scripts/
git commit -m "sync: [brief description of improvement]"
```

**Note:** The `git add -A` here is bundled with Improvement 14.

**Open questions:** None.

---

### 20. Gitignore import_diff Files

**Problem:** The import script writes diff files to `.shamt/import_diff.md` (and `import_diff_N.md`) inside the version-controlled `.shamt/` directory. These are temporary working files, but they are not gitignored. If an agent forgets to delete them or commits before Step 6, they get committed as project files with immediately stale content.

This is the same class of issue that `last_sync.conf` had before SHAMT-2.

**Why this survived the 15-round audit:**
No audit dimension checks `.gitignore` entries against the set of known transient files written by Shamt scripts. The `last_sync.conf` fix was reactive, not a proactive policy.

**Proposed fix:**
- Add `import_diff*.md` to the master's `.gitignore` (note: master has no `.gitignore` yet — I7 creates it; master's `.gitignore` gets `outputs/` from I7 and `import_diff*.md` from I20; `last_sync.conf` is not needed in master's `.gitignore` since master never runs the import script)
- Update the init script to also write `import_diff*.md` to the `.gitignore` it generates for new child projects (alongside the existing `last_sync.conf` entry)
- Add a migration note to `import_workflow.md` for projects initialized before this fix

**Proposed audit improvement:**
Add a check to `pre_audit_checks.sh` that verifies `import_diff*.md` is present in the project's `.gitignore`. (`last_sync.conf` is excluded from this check: master never generates it and child projects had it added to their init script by SHAMT-2.)

**Open questions:** None.

---

### 21. Move `write_last_sync` Earlier in Import Script

**Problem:** In both import scripts, the changes path writes `last_sync.conf` at the very end — after diff generation, summary output, and the agent prompt. If the script is killed after syncing files but before the final line, files are synced but `last_sync.conf` is not updated.

**Why this survived the 15-round audit:**
Script implementation ordering detail — invisible to all audit dimensions. The current placement is logical from a "write state after completing all work" perspective, and the risk only materializes in an abnormal termination scenario.

**Proposed fix:**
Move `write_last_sync` to immediately after the sync phases complete (after `remove_deleted`, before diff file generation and output).

**Open questions:** None.

---

### 22. Remove Empty Directories After File Deletion in Import

**Problem:** The `remove_deleted` function in both import scripts deletes individual files but does not clean up empty parent directories. If a deleted file was the only file in a subdirectory, the empty directory remains.

**Why this survived the 15-round audit:**
Script behavior detail — invisible to all audit dimensions. The issue only manifests visually after an import that includes a deletion, which is an uncommon code path.

**Proposed fix:**
After each file deletion in `remove_deleted`, check whether the parent directory is now empty and remove it if so. Repeat up the tree until a non-empty directory or the `.shamt/` root is reached.

**Open questions:** None — low-priority cleanup.

---

### 23. Expand Audit Scope to Cover Scripts

**Problem:** A recurring theme across Improvements 2, 13, 14, 15, 16, 17, 18, 19, 20, 21, and 22 is that the audit system has no coverage of `.sh` and `.ps1` script files. Every issue in these files is structurally invisible to all 19 audit dimensions because the audit only operates on `.md` guide files.

**Why this gap exists:**
The audit system was designed around guide files. Scripts were added to the sync system incrementally and were never formally brought into audit scope. The absence of script coverage was never explicitly decided — it was the default state that was never revisited.

**Proposed change:**
Add a lightweight script review step to the audit system:

- Add a **D9 extension**: when auditing `export_workflow.md` and `import_workflow.md`, cross-reference each prose description of script behavior against the actual script to verify accuracy
- Add the four script files (`export.sh`, `export.ps1`, `import.sh`, `import.ps1`) to the audit file list in `stage_1_discovery.md`
- Add a **manual script review checklist** to `stage_1_discovery.md` covering:
  - Verify all function calls in `.ps1` files resolve to defined or built-in functions
  - Verify bash and PowerShell scripts are functionally equivalent
  - Verify script next-steps output matches the corresponding guide's instructions
  - Verify transient output files are gitignored
  - Verify script ordering (state writes happen before output, not after)

**Open questions:** None — Q8 resolved: Option A (new D20 dimension). Q9 resolved: Option A (D9 extension coexists with D20 — add to D9 section of `stage_1_discovery.md`).

---

### 24. Require Full Audit Before Export (Not Just Modified Files)

**Problem:** `export_workflow.md` Step 1.5 currently says to run the guide audit on every shared guide file "you modified." This is too narrow. When a file is modified, other files that reference it, depend on it, or need to reflect its changes may also need updating. Exporting without a full audit risks propagating internally inconsistent changes to master.

**Proposed fix:**
Update Step 1.5 to require a full guide audit of the entire `.shamt/guides/` tree, achieving 3 consecutive zero-issue rounds before proceeding to Step 2.

**Open questions:** None — straightforward policy tightening.

---

## Open Questions

### Q1: Timing of Improvements 2 and 3

**Resolved:** All improvements (I2–I24) are being applied on `feat/SHAMT-2`. No SHAMT-3 branch — everything lands here.

---

### Q2: pre_audit_checks.sh Scope Expansion — Additional Checks

**Resolved:** Option B — D8, D14, and D11. Scope clarification: add `sync/` to D8 and D11; add only `RULES_FILE.template.md` to D14 (D14 already covers `guides/sync/` via the existing recursive `os.walk` scan starting from `guides/`). D12 excluded (requires maintaining new known exceptions for files that don't follow stage-guide structure; benefit does not justify the overhead).

---

### Q3: Audit Outputs Management Policy

**Resolved:** Option A — gitignore `.shamt/guides/audit/outputs/` in master.

---

### Q4: SHAMT-2 Closure Form

**Resolved:** Dropped — Improvement 10 is not being pursued.

---

### Q5: License

**Resolved:** Dropped — Improvement 11 is not being pursued.

---

### Q6: Handling Already-Committed Outputs Files (Improvement 7)

**Resolved:** Option A — gitignore only. Leave committed files as-is; they will stop being updated but remain in history.

---

### Q7: Export Deletion Behavior (Improvement 9)

**Resolved:** Option A — delete from master's working tree directly. The PR diff will show deletions automatically.

---

### Q8: Script Checklist Structure (Improvement 23)

**Resolved:** Option A — new D20 dimension (Script Integrity), with its own section in `stage_1_discovery.md` alongside D1–D19.

---

### Q9: I23 D9 Extension Scope

**Resolved:** Option A — both apply. The D9 extension is added as a check in the D9 section of `stage_1_discovery.md`; D20 is its own new section. They are complementary: D9 checks that guides accurately describe scripts, D20 checks that scripts themselves are correct.

---

### Q10: I17 D17 Platform Parity Audit Check

**Resolved:** Option A — include in this branch. Add the D17 platform parity check to `stage_1_discovery.md` as part of Phase 3.

---

## Resolved Questions

| # | Topic | Resolution |
|---|-------|------------|
| Q1 | Timing of I2/I3 | All improvements on feat/SHAMT-2 |
| Q2 | pre_audit_checks.sh scope | Option B: D8, D14, D11 |
| Q3 | Audit outputs management | Option A: gitignore outputs/ |
| Q4 | SHAMT-2 closure form | Dropped (I10 not pursued) |
| Q5 | License | Dropped (I11 not pursued) |
| Q6 | Handling committed outputs files | Option A: gitignore only |
| Q7 | Export deletion behavior | Option A: delete from master tree directly |
| Q8 | Script checklist structure | Option A: new D20 dimension (Script Integrity) |
| Q9 | I23 D9 extension scope | Option A: coexists with D20 — add D9 extension to D9 section |
| Q10 | I17 D17 platform parity check | Option A: include in this branch, add to Phase 3 |

---

## Design Decisions

**Q1 — Branch:** All improvements implemented on `feat/SHAMT-2`. No separate SHAMT-3 branch.

**Q2 — pre_audit_checks.sh scope expansion checks:** Option B (D8, D14, D11). Clarification: D14 already covers `guides/sync/` via the existing recursive `os.walk` — only `RULES_FILE.template.md` (outside the `guides/` tree) needs to be added for D14. D8 and D11 need `sync/` added. D12 excluded — sync files don't follow stage-guide structure and adding them would require maintained known exceptions with no meaningful quality gain.

**Q3 — Audit outputs management policy:** Option A — gitignore `.shamt/guides/audit/outputs/` in master. Outputs are transient; document policy in `audit/README.md`.

**Q6 — Already-committed outputs files:** Option A — gitignore only. Files remain in history, stop being updated.

**Q7 — Export deletion behavior:** Option A — delete from master's working tree directly. Mirrors import's `remove_deleted` behavior. PR diff shows deletion automatically.

**Q8 — Script checklist structure:** Option A — new D20 dimension (Script Integrity) in `stage_1_discovery.md`.

**Q9 — I23 D9 extension scope:** Option A — both apply. Add D9 extension check (guide-to-script accuracy) to the D9 section of `stage_1_discovery.md`; D20 is a separate new section covering script integrity. They are complementary, not redundant.

**Q10 — I17 D17 platform parity check:** Option A — include in this branch. Add a D17 check to `stage_1_discovery.md`: for any guide that describes platform-specific steps for one platform, verify a corresponding equivalent exists for the other.

---

## Implementation Phases

### Phase 0 — Script Correctness Fixes

- Fix pre_audit_checks.sh stale exceptions + add self-validating entry check (I2, including Proposed Prevention)
- Fix discovery_report_template.md exit criterion (I3)

### Phase 1 — Guide Correctness Fixes

- Fix validation_loop_master_protocol.md flowchart language (I4)
- Fix validation_loop_master_protocol.md exit criteria wording (I5)
- Fix separation_rule.md master context note (I8)
- Fix export_workflow.md "file hash" description (I15)
- Require full audit before export, not just modified files (I24)
- Add PowerShell equivalent for import_workflow.md Step 6 delete command (I17)
- Add `git checkout main` to export next steps — script + guide (I19)

### Phase 2 — Sync Script Fixes

- Fix export script to propagate deletions (I9, Q7=Option A: delete directly)
- Update export next steps to stage deletions with `git add -A` (I14, bundled with I9; note: I19 in Phase 1 already changes `git add` to `git add -A` in scripts and guide — by Phase 2, verify this is in place, then focus I14's work on confirming the deletion detection in I9 is correctly integrated)
- Fix `Prompt-Input` undefined in import.ps1 (I13)
- Fix import.ps1 agent prompt backtick escaping (I16)
- Add master working tree check to export script + document check in `export_workflow.md` Step 2 (I18)
- Gitignore import_diff files — init script + guide migration note (I20; note: master `.gitignore` is created in Phase 4 by I7; implement I20's master `.gitignore` entry as part of Phase 4 alongside I7, not independently here)
- Move `write_last_sync` earlier in import script (I21)
- Remove empty directories after file deletion in import (I22)

### Phase 3 — Audit Scope Expansion

- Expand pre_audit_checks.sh scan scope (I6)
- Add pre_audit_checks.sh transient file check (`import_diff*.md` present in `.gitignore`) (I20 audit improvement; `last_sync.conf` excluded — master never generates it and child projects had it added by SHAMT-2's init script)
- Expand audit scope to cover scripts — new D20 dimension + D9 extension in D9 section (I23, Q8=Option A, Q9=Option A)
- Add D17 platform parity check to `stage_1_discovery.md` — verify bash commands in guides have PowerShell equivalents where applicable (I17 audit improvement, Q10=Option A)

### Phase 4 — Policy

- Create master `.gitignore` with `outputs/` (I7) and `import_diff*.md` (I20) entries; document outputs policy in `audit/README.md` (I7+I20 combined; Q6=Option A: gitignore only)

### Phase 5 — Master Dev Flow Documentation

- Formalize master repo development flow (I12)

### Phase 6 — Validation

- Run full guide audit on entire `.shamt/guides/` tree
- Run manual script review pass per new D20 checklist (I23)
- Confirm pre_audit_checks.sh changes work correctly

---

## Open Questions Summary

| # | Topic | Status |
|---|-------|--------|
| Q1 | Improvements 2–3 timing | Resolved: all on feat/SHAMT-2 |
| Q2 | pre_audit_checks.sh scope — D8/D11 need sync/, D14 needs RULES_FILE.template.md only | Resolved: Option B (D8, D14, D11) |
| Q3 | Audit outputs management — gitignore, clean at close, or no action | Resolved: Option A (gitignore) |
| Q4 | SHAMT-2 closure form | Resolved: Dropped |
| Q5 | License | Resolved: Dropped |
| Q6 | Handling 80+ already-committed outputs files (I7) | Resolved: Option A (gitignore only) |
| Q7 | Export deletion behavior — delete from master tree or report only (I9) | Resolved: Option A (delete directly) |
| Q8 | Script checklist structure — new D20 dimension or distributed across existing (I23) | Resolved: Option A (new D20) |
| Q9 | I23 D9 extension — coexists with D20 or subsumed? | Resolved: Option A (coexists — add to D9 section) |
| Q10 | I17 D17 platform parity audit check — in scope for this branch? | Resolved: Option A (include in Phase 3) |

---

*This document is the centralized reference for SHAMT-3 improvements. Update it as decisions are made and questions are resolved.*
