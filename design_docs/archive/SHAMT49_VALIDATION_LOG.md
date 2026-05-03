# SHAMT-49 Validation Log

**Design Doc:** [SHAMT49_DESIGN.md](./SHAMT49_DESIGN.md)
**Validation started:** 2026-05-02
**Exit criterion:** Primary clean round (consecutive_clean = 1) + 2 independent Haiku sub-agent confirmations

---

## Round 1

**consecutive_clean before:** 0

**Findings:**
- D3 MEDIUM: "ADO MCP" in filtering table was unexplained — readers couldn't tell what it referred to
- D2 LOW: Phase 3 didn't state explicitly that `FileNotFoundError` is the normal path for Codex-only (not an error), and that both exceptions default `hooks_enabled`/`mcp_enabled` to `False`
- D6 LOW: `.shamt/.gitignore` unconditional-write rationale not fully stated — ambiguity about nested gitignore precedence

**Fixes applied:**
- Expanded filtering table row to `ADO CI / ADO PR review (ADO MCP)` with inline clarification referencing canonical CHEATSHEET.md
- Rewrote Phase 3 bullet to state that `FileNotFoundError` is normal for Codex-only and both exceptions default optional features to `False`
- Rewrote Phase 2 `.gitignore` bullet to explicitly state the file is written unconditionally and why the nested gitignore is safe in both tracked and excluded cases

**consecutive_clean after:** 0 (MEDIUM issue reset)

---

## Round 2

**consecutive_clean before:** 0

**Findings:**
- D6 LOW: Phase 2 `epic_tag.conf` bullet stated the fallback value (`SHAMT-N`) but did not explicitly confirm the cheat sheet is still generated and useful on pre-SHAMT-49 projects — risk table covered the mitigation but implementation guidance did not

**Fixes applied:**
- Expanded Phase 2 `epic_tag.conf` parenthetical to add: "the cheat sheet is still generated and remains useful with the placeholder tag on projects initialized before SHAMT-49"

**consecutive_clean after:** 1 (exactly one LOW fixed — primary clean round achieved)

**Sub-agent confirmations:**
- Sub-agent A (Haiku): CONFIRMED — Zero issues found. All 7 dimensions pass.
- Sub-agent B (Haiku): CONFIRMED — Zero issues found. All 7 dimensions pass.

**EXIT CRITERION MET:** consecutive_clean = 1 + 2 independent sub-agent confirmations ✓

---

# Implementation Validation

**Exit criterion:** Primary clean round (≤1 LOW-severity issue) + 2 independent sub-agent confirmations

## Impl Round 1

**consecutive_clean before:** 0

**Findings (all LOW):**
1. D2: Codex regen `json.JSONDecodeError` warning — accepted as intentional (warns user of malformed JSON, better than silent); no code change
2. D2: Status line in both regen scripts printed absolute path for CHEATSHEET_OUT rather than `.shamt/CHEATSHEET.md` as specified
3. D5: CLAUDE.md item 4 did not list `epic_tag.conf` alongside `ai_service.conf` / `repo_type.conf`
4. D5: CLAUDE.md `regen-claude-shims.sh` bullet list did not mention Phase 5 / cheat sheet generation
5. D5: CLAUDE.md did not mention `.shamt/CHEATSHEET.md` (the generated tailored file)
6. D5: CLAUDE.md did not mention `.shamt/.gitignore`

**Fixes applied:**
- Both regen scripts: status line updated to `echo "  Cheat sheet: generated (.shamt/CHEATSHEET.md)"`
- CLAUDE.md item 4 updated to include `epic_tag.conf`
- CLAUDE.md `regen-claude-shims.sh` description updated with cheat sheet/Phase 5 bullet mentioning `.shamt/CHEATSHEET.md` and `.shamt/.gitignore`

**consecutive_clean after:** 0 (6 LOWs reset)

---

## Impl Round 2

**consecutive_clean before:** 0

**Findings:** None.

**consecutive_clean after:** 1 (primary clean round achieved)

**Sub-agent confirmations:**
- Sub-agent A (Haiku): CONFIRMED — Zero issues found. All 5 dimensions pass.
- Sub-agent B (Haiku): CONFIRMED — Zero issues found. All 6 verification points pass.

**IMPL EXIT CRITERION MET:** consecutive_clean = 1 + 2 independent sub-agent confirmations ✓

---
