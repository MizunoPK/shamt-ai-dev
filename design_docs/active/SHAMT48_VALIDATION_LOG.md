# SHAMT-48 Validation Log

**Design Doc:** [SHAMT48_DESIGN.md](./SHAMT48_DESIGN.md)
**Validation started:** 2026-05-02
**Exit criterion:** Primary clean round (consecutive_clean = 1) + 2 independent Haiku sub-agent confirmations

---

## Round 1

**consecutive_clean before:** 0

**Findings:**
- D1 MEDIUM: Risk table `python3 not on PATH` row covers only MCP. Phase 4 also uses `python3 -c` for `features.shamt_hooks` JSON patch — if Python3 absent, hooks dir copied but flag not set, regen won't install registrations.
- D2 LOW: ADO CI template source paths unspecified ("copy ADO template" with no path from `$SHAMT_SOURCE_DIR`).
- D7 LOW: `init_lite.sh`/`init_lite.ps1` and `shamt-add-host.sh` scope not addressed — ambiguity for implementers.

**Fixes applied:**
- Added dedicated risk row for Python3 absence during `features.shamt_hooks` JSON patch with explicit warning text and fallback note
- Specified ADO template source paths with "verify exact path at implementation time" note
- Added "Scope Exclusions" section explicitly noting `init_lite.sh` and `shamt-add-host.sh` are out of scope

**consecutive_clean after:** 0 (MEDIUM issue reset)

---

## Round 2

**consecutive_clean before:** 0

**Sub-agent B finding (after primary claimed consecutive_clean=1):**
- D3 LOW: MCP setup location inconsistency — lines 77-90 described setup as "whichever host block runs first (or shared block before both)" but Phases 4-5 describe per-host separate application with double-install guard. Text and phases were contradictory.

**Fix applied:**
- Updated MCP setup prose to "applied in each host wiring block that runs (with a double-install guard in the Codex block for dual-host)" — consistent with Phase 4-5 description.

**consecutive_clean after:** 0 (sub-agent finding resets)

---

## Round 3

**consecutive_clean before:** 0

**Sub-agent A findings (after primary claimed consecutive_clean=1):**
- D3 LOW: Line 73 truncated hooks-skip message `print("  Hooks: skipped...")` inconsistent with Phase 2's full text `print("  Hooks: skipped (.shamt/hooks/ not found)")`.
- D2 LOW: Line 112 GitHub janitor template copy missing full source path prefix `$SHAMT_SOURCE_DIR/.shamt/sdk/.github/workflows/`.

**Sub-agent B findings:** 5 LOWs reported; assessed as implementation-level details outside design doc scope (guard asymmetry is intentional, settings.json existence already explained, cp error handling covered by non-blocking principle, Python command is implementer task, ADO path already noted for verification).

**Fixes applied:**
- Updated line 73 to `print("  Hooks: skipped (.shamt/hooks/ not found)")` — consistent with Phase 2 text
- Updated line 112 GitHub janitor copy to include full source path

**consecutive_clean after:** 0 (sub-agent findings reset)

---

## Round 4

**consecutive_clean before:** 0

**Findings:** Zero issues across all 7 dimensions.

**consecutive_clean after:** 1

**Sub-agent A:** CONFIRMED — Zero issues found in SHAMT-48.
**Sub-agent B:** CONFIRMED — Zero issues found in SHAMT-48.

**Exit criterion met.** Primary clean round + 2 independent Haiku sub-agent confirmations.

---

## Result: VALIDATED

**Rounds total:** 4  
**Exit:** Round 4 primary clean + both sub-agents confirmed zero issues



