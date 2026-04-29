# SHAMT-40 Validation Log

**Design Doc:** [SHAMT40_DESIGN.md](./SHAMT40_DESIGN.md)
**Validation Started:** 2026-04-28
**Validation Completed:** 2026-04-29
**Final Status:** Validated

---

## Validation Rounds

### Round 1 — 2026-04-28

#### Dimension 1: Completeness
**Status:** Pass

Problem Statement clear. Goals cover init extension, regen script, starter settings.json, import hook, ai_services.md update, and Experiment A. Files Affected covers all 12 entries. Phase 7.5 (master repo wiring) explicitly added for SHAMT-47 fold-in.

---

#### Dimension 2: Correctness
**Status:** Issues Found

**Issues:**
- Proposal 2 specifies a `master-only: true` frontmatter filter for skills ("Skills with `master-only: true` frontmatter are skipped on child projects"), but the regen script has no specified mechanism to detect whether it is running on the master repo vs. a child project. Without this, the implementer cannot implement the filter correctly. (Severity: LOW, Location: Proposal 2 — Master-only filter bullet)

**Fixes:**
- Added bullet to Proposal 2 specifying that `init.sh` writes `.shamt/config/repo_type.conf` (value: `master` or `child`) at init time, and the regen script reads this file to determine master vs. child mode and apply the filter accordingly.
- Added `.shamt/config/repo_type.conf` to Files Affected as CREATE.

---

#### Dimension 3: Consistency
**Status:** Pass

Three proposals are mutually consistent. CHEATSHEET.md passthrough entry aligns with SHAMT-39's authoring of the file. `_shamt_managed_blocks` convention is internally consistent.

---

#### Dimension 4: Helpfulness
**Status:** Pass

Init-script branch avoids breaking other AI service paths. Idempotent regen prevents content loss. Starter settings.json reserves blocks cleanly for SHAMT-41.

---

#### Dimension 5: Improvements
**Status:** Pass

Alternatives well-documented. Generated files vs. symlinks justified (cross-platform). Regen-on-import pattern solves the sync-freshness problem.

---

#### Dimension 6: Missing Proposals
**Status:** Pass

No important omissions. Phase 7.5 covers master repo dog-fooding.

---

#### Dimension 7: Open Questions
**Status:** Pass

Three open questions with recommendations. Cross-platform line endings and `_shamt_managed_blocks` semantics are addressed.

---

#### Round 1 Summary

**Total Issues:** 1
**Severity Breakdown:**
- CRITICAL: 0
- HIGH: 0
- MEDIUM: 0
- LOW: 1

**Clean Round Status:** Clean (1 Low Fix) ✅

**consecutive_clean:** 1

---

## Re-Validation — 2026-04-29

Round 1 above was from the prior session. This section records the fresh full re-validation run after SHAMT-39 merged to main.

### Re-Validation Round 1 — 2026-04-29

**2 MEDIUMs + 2 LOWs found. NOT clean. consecutive_clean = 0.**

**Issue 1 (MEDIUM — D2 Correctness):** Design doc said `AI_SERVICE=claude-code` (hyphen) but init.sh uses `AI_SERVICE="claude_code"` (underscore). The branch condition in Phase 4 would never match.
**Fix:** Changed all occurrences to `claude_code` throughout design doc; Phase 4 now explicitly states `if [ "$AI_SERVICE" = "claude_code" ]`.

**Issue 2 (MEDIUM — D2 Correctness / D1 Completeness):** Phase 5 said "if Claude Code is the detected host, run regen script" but specified no detection mechanism. init.sh does not persist AI service to any config file — so import.sh had nothing to read.
**Fix:** Added `.shamt/config/ai_service.conf` to Files Affected (CREATE); Phase 4 now writes it at init time (alongside `repo_type.conf`); Phase 5 now reads it. Graceful degradation if absent (pre-SHAMT-40 installs) specified.

**Issue 3 (LOW — D5 Improvements):** Regen's stale shim behavior not documented. If a skill/command is removed from `.shamt/`, its managed-header file in `.claude/` persists.
**Fix:** Added bullet to Proposal 2 stating stale files are not cleaned up and are identifiable by the managed header.

**Issue 4 (LOW — D6 Missing):** No version-control policy stated for generated `.claude/` shim files.
**Fix:** Added bullet to Proposal 2 stating generated shims are committed to version control (lock file pattern); user stages and commits after import + regen.

---

### Re-Validation Round 2 — 2026-04-29

**All 7 dimensions pass. 0 issues. CLEAN. consecutive_clean = 1.**

D1 Completeness: 14 Files Affected entries (ai_service.conf added). Phase 4 specifies branch condition. Phase 5 specifies detection mechanism with graceful degradation. Stale shim and version-control policies documented. Pass.

D2 Correctness: `AI_SERVICE=claude_code` matches init.sh. ai_service.conf in Phase 4, Phase 5, and Files Affected. Phase 5 silent skip for pre-SHAMT-40 installs. Model tier delegates to agents/README.md. Pass.

D3 Consistency: `claude_code` underscore consistent throughout. ai_service.conf and repo_type.conf both written in Phase 4. Version-control policy aligns with init.sh's `.shamt/*.conf` exclude (not `.claude/`). Pass.

D4 Helpfulness: Proposals solve stated problem. Stale shim acknowledgment is sufficient (manual cleanup via managed header). Pass.

D5 Improvements: No new opportunities. Pass.

D6 Missing proposals: None. Pass.

D7 Open questions: Three questions with recommendations. No new unresolved decisions from today's fixes. Pass.

---

### Sub-Agent Confirmations — 2026-04-29

#### Sub-Agent A

**Result:** CONFIRMED CLEAN — zero issues found.

Verified: `AI_SERVICE=claude_code` in design doc and init.sh consistent; ai_service.conf in all three required locations; graceful pre-SHAMT-40 degradation stated; repo_type.conf consistent; Phase 7.5 explicit about master-only filter; Experiment A criterion specific and measurable.

---

#### Sub-Agent B

**Result:** CONFIRMED CLEAN — zero issues found.

Verified: Files Affected has 14 entries including all required CREATE/MODIFY/PASSTHROUGH rows; Proposal 2 covers all 7 behaviors (skills, agents, commands, master-only, idempotence, stale shims, version control); phase ordering correct for all dependencies; all 3 open questions have recommendations; regression check uses correct `cursor` value matching init.sh.

---

## Final Summary

**Total Validation Rounds:** 2 (original Round 1) + 2 (re-validation rounds) = 4 rounds total
**Sub-Agent Confirmations:** 2 — both CONFIRMED CLEAN ✅
**Exit Criterion Met:** YES ✅ — Re-validation Round 2 primary clean + both sub-agents confirmed zero issues

**Design Doc Status:** VALIDATED

**Key Improvements Made During Validation:**
- Specified master-vs-child detection mechanism for regen script (`.shamt/config/repo_type.conf` written by init.sh)
- Corrected `AI_SERVICE` value from `claude-code` to `claude_code` (matching init.sh underscore convention)
- Added `ai_service.conf` to Files Affected, Phase 4, and Phase 5 (solves import.sh host detection)
- Documented stale shim file behavior in Proposal 2 (not cleaned up; identifiable by managed header)
- Documented version-control policy for generated shims (commit them; lock-file pattern)

---

## Implementation Validation (Phase 9)

**Date:** 2026-04-29
**Artifact:** Full SHAMT-40 implementation (commit 66d8f8e + amendments)

### Round 1 — 2026-04-29

- D1 Completeness: MEDIUM — import.ps1 missing Claude Code regen hook (Phase 5 said "Mirror in PowerShell")
- D5 Documentation Sync: LOW — CLAUDE.md skills paragraph used future-tense language about wiring already deployed
- `consecutive_clean = 0`; fixes applied

**Fixes:**
- Added regen hook to import.ps1 (lines 299-313)
- Updated CLAUDE.md skills paragraph to present tense ("Claude Code host wiring is live (SHAMT-40)")

### Round 2 — 2026-04-29

All 5 dimensions: no issues. `consecutive_clean = 1`.

Sub-agent A: raised `\$` heredoc as CRITICAL — adjudicated FALSE POSITIVE. In unquoted `<<PYEOF` heredoc, `\$` → `$` (end-of-line anchor) in Python. Generated agents have correct populated content; direct empirical test confirmed match. No fix needed.

Sub-agent B: MEDIUM (D5) — regen README missing version-control / lock-file section (Proposal 2 explicitly specifies this). Genuine. `consecutive_clean = 0`.

**Fix:** Added "Version Control" section to `.shamt/scripts/regen/README.md` documenting lock-file pattern and gitignore rules.

### Round 3 — 2026-04-29

All 5 dimensions: no issues. `consecutive_clean = 1`.

Sub-agent C: MEDIUM (D3) — `.claude/settings.json` not created on master during Phase 7.5 (design doc says "Verify master's settings.json has statusLine, reserved blocks, project name resolved"). Genuine. `consecutive_clean = 0`.

Sub-agent D: Same `\$` heredoc false positive as sub-agent A. Adjudicated false positive.

**Fix:** Created `.claude/settings.json` on master by resolving `${PROJECT}` from settings.starter.json. Verified statusline renders.

### Round 4 — 2026-04-29

All 5 dimensions: no issues. `consecutive_clean = 1`.

Sub-agent E: CONFIRMED — zero issues found
Sub-agent F: CONFIRMED — zero issues found

**Exit criterion met:** primary clean round (Round 4) + 2 independent sub-agent confirmations.

**Implementation Validation Status: VALIDATED ✅**

---

## Final Implementation Summary

**Status:** IMPLEMENTED ✅
**Implementation commits:** `66d8f8e` (main implementation) + amendments (import.ps1 regen hook, regen README version-control section, CLAUDE.md phrasing)
**Post-implementation guide audit:** pending
