# SHAMT-52 Validation Log

**Design Doc:** [SHAMT52_DESIGN.md](./SHAMT52_DESIGN.md)
**Validation Started:** 2026-05-03
**Validation Completed:** 2026-05-03
**Final Status:** Validated ✅

---

## Validation Rounds

### Round 1 — 2026-05-03

**Issues found:**
- HIGH (Correctness, Depends-on header line 8): References "Proposal 9 host-agnostic XML" (v1 numbering) and links to v1's `SHAMT51_DESIGN.md`. Should reference the actually-implemented v2 — Proposal 8 in `SHAMT51_DESIGN_v2.md`.

**Fixes applied:**
- Updated header to point at `SHAMT51_DESIGN_v2.md` and reference Proposal 8.

**Round 1 Summary:**
- Total: 1 issue (1 HIGH)
- Clean? No. consecutive_clean = 0.

---

### Round 2 — 2026-05-03

**Issues found:**
- MEDIUM (Correctness, Phase 3 gitignore step): Said "Add `cursor` to `.shamt/.gitignore`" — sounds like adding the literal word "cursor" rather than the specific resolution-file path. Misleading.

**Fixes applied:**
- Reworded to "Add `.shamt/host/cursor/.model_resolution.local.toml` to `.shamt/.gitignore` (mirrors the existing entry for the Codex resolution file)".

**Round 2 Summary:**
- Total: 1 issue (1 MEDIUM)
- Clean? No. consecutive_clean = 0.

---

### Round 3 — 2026-05-03

**Issues found:**
- LOW (Helpfulness, Phase 5 audit step): Said "Run guide audit on `.shamt/guides/` (3 consecutive clean rounds)" without specifying full-tree scope or citing CLAUDE.md Critical Rules. Inconsistent with SHAMT-51 v2's identical step.

**Fixes applied:**
- Reworded for parity with SHAMT-51 v2's audit step: "Run guide audit on the entire `.shamt/guides/` tree (3 consecutive clean rounds, per CLAUDE.md "Critical Rules" — not just files affected by SHAMT-52)".

**Round 3 Summary:**
- Total: 1 issue (1 LOW, fixed)
- Clean (1 LOW Fix) ✅
- consecutive_clean = 1.

**Notes:** Primary clean round achieved. Sub-agents will be spawned in parallel with SHAMT-51 v2 and SHAMT-53 sub-agent calls.

---

## Sub-Agent Confirmations (Attempt 1)

### Sub-Agent A — 2026-05-03

**Result:** Confirmed zero issues. ✅

### Sub-Agent B — 2026-05-03

**Result:** Found 4 findings (mix of substantive and stylistic).

**Issues Found:**
- MEDIUM (Improvements, OQ 1 & 2): Sub-agent argued the OQs need explicit recommended defaults. **Triaged as non-issue:** the OQs DO already include "Recommendation:" lines with specific values. SA B was over-reading the "User confirmation required" framing.
- LOW (Improvements, Phase 0 re-research depth): SA B suggested tightening Phase 0 to "spot-check on path schemas ONLY, skip frontmatter." **Triaged as non-issue:** the doc's existing "quick spot-check first; escalate to full pass only if anything looks different" is a spot-check approach already.
- MEDIUM (Completeness, Phase 2): `.shamt/host/cursor/.model_resolution.local.toml.example` is in Files Affected as CREATE, but Phase 2's checklist doesn't include authoring it. Real gap.
- MEDIUM (Completeness, Phase 2): Regen script should append a managed header to deployed `.mdc` files (mirroring SHAMT-42's regen pattern), but Phase 2 doesn't specify this. Real gap.

**Status:** Cannot Confirm ❌ (because of the two real Phase 2 gaps)

---

**Outcome:** Two real gaps in Phase 2 (the OQ recommendations and Phase 0 framings hold up on re-read). consecutive_clean resets to 0. Returning to primary validation for Round 4.

---

### Round 4 — 2026-05-03

**Issues found:**
- MEDIUM (Completeness, Phase 2): `.example` file creation not in checklist.
- MEDIUM (Completeness, Phase 2): Managed-header step not in checklist.

**Fixes applied:**
- Added Phase 2 checkbox: "Append a managed header to all deployed `.mdc` files... Mirrors the managed-header pattern used by `regen-claude-shims.sh` and `regen-codex-shims.sh`."
- Added Phase 2 checkbox: "Author `.shamt/host/cursor/.model_resolution.local.toml.example` showing both common values..."

**Round 4 Summary:**
- Total: 2 issues (2 MEDIUM)
- Clean? No. consecutive_clean = 0.

---

### Round 5 — 2026-05-03

**Issues found:** None.

The Round 4 fixes (managed-header step, `.example` file step) are integrated into Phase 2 and read cleanly. Other sections unchanged from earlier rounds; no new issues surface.

**Round 5 Summary:**
- Total: 0 issues
- Pure clean ✅
- consecutive_clean = 1.

**Notes:** Primary clean round achieved. Spawning fresh sub-agents (Attempt 2).

---

## Sub-Agent Confirmations (Attempt 2 — final)

### Sub-Agent A — 2026-05-03

**Result:** Confirmed zero issues. ✅

### Sub-Agent B — 2026-05-03

**Result:** Confirmed zero issues. ✅

---

## Final Summary

**Total Validation Rounds:** 5
**Sub-Agent Attempts:** 2 (Attempt 1: A clean, B caught managed-header + .example file gaps; Attempt 2: both confirmed clean)
**Exit Criterion Met:** Yes ✅

**Design Doc Status:** Validated

**Key Improvements Made During Validation:**
- Depends-on header updated to point at SHAMT-51 v2 (Proposal 8) instead of v1 (Proposal 9)
- Phase 3 gitignore step rewritten with specific path
- Phase 5 audit step rewritten to specify entire-tree scope per CLAUDE.md Critical Rules
- Phase 2 augmented with managed-header step for deployed `.mdc` files
- Phase 2 augmented with `.example` model-resolution file authoring step

**Validation Completed:** 2026-05-03
**Next Step:** User review of OQs (OQ 1-3), then SHAMT-51 v2 implementation completes (prerequisite), then SHAMT-52 implementation.

---

## Re-Validation (post-SHAMT-51 impl) — 2026-05-04

**Context:** SHAMT-51 v2 fully implemented and guide-audited. Re-validating SHAMT-52 to catch stale references and incorporate knowledge from SHAMT-51's implementation validation findings.

### Round 1 — 2026-05-04

**Issues found:**

- MEDIUM (Correctness, Proposal 1 step 1 + Phase 2 checklist): Proposal 1 said "copy verbatim" for skills. But 3 of 5 `shamt-lite-*` skills (`shamt-lite-story`, `shamt-lite-validate`, `shamt-lite-plan`) contain `<parameter name="model">{cheap-tier}</parameter>` XML that must be substituted at deploy time. SHAMT-51's impl-validation (Sub-Agent A1 CRITICAL finding) established the required pattern: targeted XML-tag sed substitution. `regen-lite-cursor.sh` must substitute `{cheap-tier}` → `$CHEAP_MODEL`. Phase 2 mentioned "substitute into agent files" but omitted skill files.
- LOW (Correctness, Phase 2 + OQ 1 resolution): `lite-review` `paths:` was `stories/**/code_review.md` — but code review artifacts live inside `stories/{slug}/code_review/` as `review_v1.md` etc. Correct glob: `stories/**/code_review/**`.
- LOW (Correctness, Phase 2): "`lite-token-discipline`" listed as one of "five skills" — no such shamt-lite-* skill exists. The five skills are: story, validate, spec, plan, review. Corrected to `lite-story`.

**Fixes applied:**
- Proposal 1 step 1: updated to describe `{cheap-tier}` targeted XML substitution (→ `$CHEAP_MODEL`) with reference to regen-lite-claude/codex.sh as the pattern.
- Phase 2 checklist: `CHEAP_MODEL` substitution step now explicitly covers both skill files and agent files.
- Phase 2 `paths:` list: `code_review.md` → `code_review/**`; `lite-token-discipline` → `lite-story`.
- OQ 1 resolution text: `code_review.md` → `code_review/**`.
- Change History: new row documenting all re-validation fixes.

**Round 1 Summary:**
- Total: 1 MEDIUM + 2 LOW = 3 issues (all fixed)
- Clean? No. consecutive_clean = 0.

---

### Round 2 — 2026-05-04

**Issues found:**

- LOW (Completeness, Files Affected table): `.shamt/.gitignore` listed as MODIFY step in Phase 3 but was missing from the Files Affected table.

**Fixes applied:**
- Added `.shamt/.gitignore` MODIFY row to Files Affected table (noting the entry mirrors the Codex resolution file entry from SHAMT-51).

**Round 2 Summary:**
- Total: 1 LOW (fixed)
- Clean (1 LOW Fix) ✅
- consecutive_clean = 1.

**Notes:** Primary clean round achieved. Spawning 2 Haiku sub-agents.

---

## Re-Validation Sub-Agent Confirmations — 2026-05-04

### Sub-Agent A — Confirmed ✅

"CONFIRMED: Zero issues found." Verified all 7 dimensions. Verified the 5 specific checklist items (A–E): `{cheap-tier}` XML substitution correctly specified; CHEAP_MODEL covers both skill and agent files; `lite-review` glob is `code_review/**`; skill names include `lite-story` not `lite-token-discipline`; `.shamt/.gitignore` MODIFY in Files Affected table.

### Sub-Agent B — Confirmed ✅

"CONFIRMED: Zero issues found." Independent full 7-dimension walk. Verified SHAMT-51 v2 is correctly referenced (Proposal 8 not Proposal 9). Confirmed all 4 targeted checks passed. Design assessed as "production-ready for implementation."

---

## Re-Validation Final Status

**Total Re-Validation Rounds:** 2 (post-SHAMT-51-impl)
**Exit Criterion Met:** Yes ✅ (primary clean round + 2 sub-agent confirmations)
**Design Doc Status:** Validated ✅ (re-validated 2026-05-04 post-SHAMT-51 impl)

**Key fixes made during re-validation:**
1. Proposal 1 step 1: "copy verbatim" → deploy with `{cheap-tier}` targeted XML substitution to `$CHEAP_MODEL`
2. Phase 2 CHEAP_MODEL step: now covers skill files AND agent files (not just agent files)
3. Phase 2 `paths:` list: `code_review.md` → `code_review/**`; `lite-token-discipline` → `lite-story`
4. OQ 1 resolution text: path corrected to `code_review/**`
5. Files Affected table: `.shamt/.gitignore` MODIFY row added

**Next Step:** Implement SHAMT-52 on `feat/SHAMT-52` branch (SHAMT-51 prerequisite is fulfilled).

---

## Implementation Validation — 2026-05-04

**Branch:** `feat/SHAMT-52`

### Round 1 — 2026-05-04

**5 Dimensions checked:**

1. **Completeness:** All 4 proposals implemented. 5 `.mdc` files authored (all under 500-line cap). 2 regen scripts (bash + PowerShell). `init_lite.sh/.ps1` extended with `--host=cursor`. Documentation: `ai_services.md`, `host/cursor/README.md`, `CLAUDE.md`, `SHAMT_LITE.template.md`, `.shamt/.gitignore`.

2. **Correctness:** `{cheap-tier}` XML targeted substitution verified (→ `$CHEAP_MODEL`; footnote preserved). `paths:` injected for spec/plan/review; absent for story/validate. `alwaysApply:` on core + validation; `globs:` on spec/plan/review. Smoke test passed (`init_lite.sh --host=cursor`, custom CHEAP_MODEL, idempotent re-run).

3. **Files Affected Accuracy:** All CREATE/MODIFY entries delivered. **One acknowledged deviation:** design doc said write resolution file to `.shamt/host/cursor/`; implementation writes to `shamt-lite/host/cursor/` (consistent with how Codex Lite writes to `shamt-lite/host/codex/`). Regen script reads `.shamt/host/cursor/` first then falls back. `.shamt/.gitignore` entry added for full-Shamt projects. LOW severity (consistent, not a regression).

4. **No Regressions:** Default no-flag behavior unchanged. Claude/Codex flows unchanged. `regen-lite-claude.sh/.ps1` and `regen-lite-codex.sh/.ps1` untouched. CLAUDE.md: 39,988 bytes (under 40,000 limit).

5. **Documentation Sync:** `CLAUDE.md` host wiring table updated with `--host=cursor` row and Cursor host directory entry. `SHAMT_LITE.template.md` Host Wiring table updated. `ai_services.md` Cursor entry updated to "full-wiring (Lite)". `host/cursor/README.md` documents schema, no-AGENTS.md decision, drift risk.

**Round 1 Summary:**
- Total: 1 LOW (acknowledged deviation — shamt-lite/host/cursor/ path for Lite consistency)
- Clean (1 LOW, acknowledged) ✅
- consecutive_clean = 1.

### Sub-Agent Confirmations — 2026-05-04

**Sub-Agent A:** CONFIRMED: Zero issues found. Full 5-dimension walk; verified all 10 specific check items (XML substitution, paths injection, .mdc frontmatter, init_lite.sh, CLAUDE.md size, docs).

**Sub-Agent B:** CONFIRMED: Zero issues found in implementation quality. Independently verified {cheap-tier} targeted substitution (lines cited), paths injection function, .mdc frontmatter, init_lite.sh model resolution placement, CLAUDE.md under 40K.

### Implementation Validation Final Status

**Implementation Status:** Validated ✅
**Exit Criterion Met:** Yes (primary clean round + 2 sub-agent confirmations)
**Deviation Acknowledged:** resolution file at `shamt-lite/host/cursor/` instead of `.shamt/host/cursor/` — Lite-consistent; regen has fallback.






