# S4: Feature Testing Strategy — SUPERSEDED

> ⚠️ **This file describes the original S4 (Feature Testing Strategy), deprecated in SHAMT-6.**
> S4 has been reinstated as a new stage in SHAMT-36.
> See: `stages/s4/s4_interface_contracts.md` — the current S4 guide.

---

## Why S4 Was Deprecated

S4 produced 63-91 planned test cases per feature across 4 iterations (50-70 minutes of planning
time), then another full validation loop (15-20 minutes, 3 clean rounds required) on the test
plan itself. The test_strategy.md produced by S4 was immediately consumed by S5.P1.I1. S8.P2
then explicitly replaced S4's planned tests with tests derived from *actual implementation* —
acknowledging that S4's plans go stale on contact with real code.

The S4 stage had 0 formal gates, its sole output was immediately consumed by the next stage, and
the elaborate planning process was consistently overtaken by implementation reality.

---

## Where the Equivalent Functionality Now Lives

**Test scope decisions are now made at the start of S5, per feature:**

1. Read `stages/s5/s5_v2_validation_loop.md`
2. At Phase 1 (Draft Creation), complete the **Test Scope Decision** step first
3. The Test Scope Decision replaces S4 entirely: identify algorithmic functions (Options C/D),
   design the integration test script (Options B/D), or proceed directly (Option A)

The epic's Testing Approach (A/B/C/D) set at S1 determines what the Test Scope Decision requires.

---

## Migration: For Child Projects With In-Progress S4 Work

**If S4 is in progress but not complete:**
Stop S4. Record any algorithmic functions already identified (if any) in a brief note. Pick up
in S5 with the Test Scope Decision step. No test_strategy.md needs to be created.

**If S4 is already complete (test_strategy.md exists):**
Treat the existing test_strategy.md as the Test Scope Decision output. When S5 asks for the
test scope decision, reference the existing file rather than re-doing the work. The validation
loop on the test strategy (S4.I4) does not need to be re-run.

---

## Proceed To

📖 **READ:** `stages/s4/s4_interface_contracts.md`
🎯 **GOAL:** Define cross-feature interface contracts before per-feature implementation planning

---

*S4 content preserved for reference in `stages/s4/archive/s4_test_strategy_development.md` and
`stages/s4/archive/s4_validation_loop.md` (both marked deprecated).*
