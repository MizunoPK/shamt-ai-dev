# SHAMT-6 Design: Testing Strategy Overhaul

**Status:** Validated — ready for user review
**Branch:** feat/SHAMT-6 (to be created)
**Scope:** Multi-guide cross-cutting change — testing model across S1, S3, S4, S5, S6, S7, S8, S9, S10

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Design Principles](#2-design-principles)
3. [Proposed Testing Model](#3-proposed-testing-model)
4. [Key Decision: Epic Test Approach Preference](#4-key-decision-epic-test-approach-preference)
5. [S1 Changes — Epic Test Preference Question](#5-s1-changes)
6. [S3 Changes — Align Epic Smoke Test Plan to New Model](#6-s3-changes)
7. [S4 Changes — Deprecate, Redirect to S5](#7-s4-changes)
8. [S5 Changes — Absorb Test Scope, Drive Integration Script Design](#8-s5-changes)
9. [S6 Changes — Conditional Execution, Integration Script Creation](#9-s6-changes)
10. [S7 Changes — Replace Manual Smoke with Script Execution](#10-s7-changes)
11. [S8 Changes — Script Maintenance Instead of Plan Document](#11-s8-changes)
12. [S9 Changes — Run All Integration Scripts at Epic Level](#12-s9-changes)
13. [S10 Changes — Conditional Gates](#13-s10-changes)
14. [New Artifact: Integration Test Script Pattern](#14-new-artifact-integration-test-script-pattern)
15. [Complete File Change List](#15-complete-file-change-list)
16. [Migration Notes](#16-migration-notes)
17. [Open Questions](#17-open-questions)

---

## 1. Problem Statement

The current Shamt testing model invests heavily in upfront test planning (S4) and unit test
execution (S6, S10), but the epic dev environment consistently demonstrates that this investment
has low signal value relative to its token and time cost.

**Evidence from the guides themselves:**

The `smoke_testing_pattern.md` reference file documents the core problem directly:

> "Real-world case: Feature passed 2,369 unit tests (100%) but smoke testing revealed output
> files missing 80% of required data."

This is not an isolated note — it is used as the *primary justification* for why Part 3 E2E
smoke testing is the most critical validation step. The guides implicitly argue against their
own S4 unit test planning apparatus.

**Why unit tests underperform in this environment:**

The features in a typical Shamt epic are data-pipeline oriented: they load CSVs, apply domain
scoring formulas, and write results to output files. Their correctness is determined by whether
the right values appear in the right places when run against real data — not by whether mocked
functions return expected values in isolation. The S4 guides themselves note that "Feature Works
in Tests But Not with Real Data" is the most common failure mode.

**The S4 overhead:**

S4 produces 63-91 planned test cases per feature across 4 iterations (50-70 minutes of planning
time), then another full validation loop (15-20 minutes, 3 clean rounds required) on the test
*plan* itself, producing a `test_strategy.md` that is immediately merged into
`implementation_plan.md` at S5.P1.I1. S8.P2 then explicitly replaces S4's planned tests with
tests derived from *actual implementation* — acknowledging that S4's plans go stale on contact
with real code.

**What this proposal does:**

- Makes the testing approach an explicit epic-level preference, set once at S1
- Retains unit tests for the narrow class of functions that genuinely benefit from them
  (pure algorithmic logic)
- Shifts the primary testing model to automated E2E integration test scripts — runnable
  artifacts, not planning documents
- Deprecates S4 and folds the residual "what to test" decision into the start of S5
- Makes multiple downstream gates conditional on the epic's test preference

---

## 2. Design Principles

**P1 — Tests should produce signal, not compliance artifacts.**
A test that passes 100% while the system is broken is worse than no test — it creates false
confidence. Every test type retained must demonstrate real-world value.

**P2 — Automation is the goal, not documentation.**
The current smoke testing process produces documentation (step-by-step instructions) that a
human or agent manually follows. An automated integration test script is strictly better: it
is reusable, regression-safe, and self-verifying.

**P3 — The epic preference is set once, respected everywhere.**
Rather than making every guide aware of a global concept through implicit convention, the
testing approach is recorded once (S1) in the epic's EPIC_README and consulted explicitly
by each downstream stage.

**P4 — Narrow unit tests, deep integration tests.**
When unit tests are used, they cover a specific, bounded case: pure algorithmic functions
with no I/O dependencies where mocking is not required (the function takes primitive inputs
and returns primitive outputs). Anything touching files, config, external objects, or
multi-step pipelines belongs in integration tests.

**P5 — S4 should not exist as a stage if its work can fold cleanly into S5.**
S4 has 0 formal gates, produces an artifact that is immediately consumed by S5, and its
elaborate planning process is frequently overtaken by implementation reality. Folding its
residual value into S5 is a structural simplification, not a loss.

---

## 3. Proposed Testing Model

### Test Types Retained

| Type | When Used | What It Tests | Format |
|------|-----------|---------------|--------|
| Unit tests | Opt-in; algorithmic functions only | Pure functions with no I/O; boundary math | Standard test framework |
| Automated E2E integration script | Opt-in (recommended default) | Feature or epic running end-to-end with real-ish data | Runnable script with assertions |
| Smoke testing (S7.P1) | Always | Basic import, entry point, and E2E execution sanity | Runs integration script if opted in (B/D); manual if not (A/C) |
| Epic-level integration (S9) | Always | All features working together | Integration scripts if opted in (B/D); manual smoke plan if not (A/C) |

### Test Types Removed / Restructured

| Removed | Reason | Replacement |
|---------|--------|-------------|
| S4 test strategy planning (63-91 tests planned per feature) | Elaborate plans go stale; S8.P2 replaces them anyway | Brief "test scope" decision at start of S5 |
| S4 validation loop (3 clean rounds on the test plan) | Excessive overhead for a planning document that gets replaced | No replacement needed |
| Mocked integration tests | Mocks hide real integration issues | Real-data E2E integration scripts |
| Configuration tests (S4.I3) | Over-planned; rarely survive implementation | Covered by integration script's real config |

### What "Algorithmic Functions" Means

A function qualifies for a unit test if:
- It takes primitive inputs (numbers, strings, lists of primitives)
- It returns a deterministic primitive output
- It has no I/O dependencies (no file reads, API calls, or external object calls)
- Mocking is not required to test it

**Examples that qualify:**
- `calculate_rank_multiplier(priority_rank: int) -> float`
- `normalize_name(name: str) -> str`
- `clamp_value(value: float, min_val: float, max_val: float) -> float`

**Examples that do not qualify:**
- `load_rank_data(csv_path: str) -> DataFrame` — has file I/O
- `RecordManager.calculate_total_score(item)` — depends on external object state
- Any function that requires a mock to test meaningfully

---

## 4. Key Decision: Epic Test Approach Preference

The test approach is set at S1, recorded in the epic's EPIC_README, and consulted at S3, S4
(redirect), S5, S6, S7, S8, S9, and S10.

### The S1 Question

> **"What automated testing approach should this epic use?"**
>
> A. **Smoke testing only** — no automated test scripts; manual E2E smoke testing at S7 and S9
> B. **Automated E2E integration scripts only** (Recommended) — runnable scripts that assert
>    on real-data outputs; no unit tests
> C. **Unit tests for algorithmic functions only** — pure function tests; no integration scripts
> D. **Both** — algorithmic unit tests + automated E2E integration scripts

**Why 4-way rather than two binary questions:**
Two independent yes/no questions create 4 combinations anyway, but they invite the agent to
reason about each independently without surfacing the trade-offs. A single 4-way question
makes the options and their implications explicit, and produces a single stored value that is
unambiguous to read downstream.

**Recording the preference:**
The choice is stored in:
1. The epic ticket (new `Testing Approach:` field)
2. The EPIC_README header (new `Testing Approach:` field)

Every downstream stage that branches on this value reads EPIC_README — it is already the
authoritative source for epic-level context. Since S5-S8 guides run in a per-feature subfolder
context, each stage guide should include the explicit instruction: "Read `Testing Approach`
from the epic's EPIC_README (located at the epic folder root, one level above this feature
folder)." The field name is `Testing Approach:` and the value is one of: A, B, C, D.

### How Each Choice Affects Downstream Stages

| Stage | Option A (Smoke only) | Option B (Integration scripts) | Option C (Unit tests) | Option D (Both) |
|-------|----------------------|-------------------------------|----------------------|-----------------|
| S3.P1 | Full (45-60 min) — manual smoke plan is the testing reference | Trimmed (10-15 min) — epic success criteria only; scripts are the strategy | Full (45-60 min) — manual smoke plan is the testing reference | Trimmed (10-15 min) — epic success criteria only |
| S4 | Redirect stub → S5 | Redirect stub → S5 | Redirect stub → S5 | Redirect stub → S5 |
| S5 | No test scope section | Design integration test script | List algorithmic functions + unit test tasks | Both |
| S6 | No test-after-step requirement | Run integration script at phase checkpoints | Run unit tests after each step | Run both |
| S7.P1 Part 3 | Manual 6-step smoke | Run integration script | Manual 6-step smoke (unit tests are S6 prerequisite, not Part 3) | Run integration script (unit tests are S6 prerequisite) |
| S9 | Manual epic smoke test | Run all feature integration scripts | Run all unit tests | Run all |
| S10 Gates 7.1 / 7.1b | Skip both | Gate 7.1b: Run integration scripts | Gate 7.1: Run unit tests | Gate 7.1: unit tests + Gate 7.1b: integration scripts |

---

## 5. S1 Changes

### File: `stages/s1/s1_epic_planning.md`

**Where to add:** Step 5 (Epic Structure Creation), before creating EPIC_README and epic ticket.

**What to add:**

A dedicated decision point titled "Test Approach Decision" that:
1. Presents the 4 options with brief explanations
2. Prompts the agent to ask the user (this is not an autonomous decision — the agent cannot
   choose; it must surface the question and record the user's answer)
3. Specifies exactly where the answer is recorded (epic ticket `Testing Approach:` field and
   EPIC_README header)

**Critical rule to add:** The test approach is set once at S1. It is not re-decided per feature.
If the user wants to change it mid-epic, they must explicitly request the change; the agent
records the update in EPIC_README with a note.

### File: `templates/epic_ticket_template.md`

**What to add:** `Testing Approach: [A/B/C/D — description]` field in the epic header section,
alongside existing fields like epic name, scope, features. (The `Integration Test Convention:`
field lives in EPIC_README only, not the epic ticket — it's a technical detail, not a planning
artifact.)

### File: `templates/epic_readme_template.md`

Add two fields to the header block:
- `Testing Approach: [A/B/C/D — description]` — set at S1
- `Integration Test Convention: [language/framework | directory | naming | run command]` — set at S5 on first feature using integration scripts; blank for Options A and C

---

## 6. S3 Changes

### File: `stages/s3/s3_epic_planning_approval.md`

S3.P1's value depends on the testing approach. For options without integration scripts, it
remains essential. For options with integration scripts, the scripts themselves collectively
become the epic-level test strategy — S3.P1 is reduced to a lightweight success-criteria
exercise.

**Changes:**

**If Option A or C (no integration scripts):**
S3.P1 is unchanged in scope and time (45-60 min). The `epic_smoke_test_plan.md` it produces
is the primary testing reference for S7 and S9 manual smoke testing. Without it, there is
no guide for those stages. The full validation loop on this document is retained.

**If Option B or D (integration scripts):**
S3.P1 is trimmed to a focused 10-15 minute step:
- Define epic success criteria only: what does "the whole epic is complete and working" mean?
  Express as 3-5 measurable conditions (e.g., "all output files present with non-zero row
  counts", "cross-feature totals are consistent"). These are different from per-feature
  assertions — they describe overall epic health.
- Create a minimal `epic_smoke_test_plan.md` with just the success criteria section. Do NOT
  attempt to enumerate test scenarios or integration points at S3 — the integration scripts
  (designed at S5, built at S6) are the actual test strategy and will cover this with real
  implementation detail.
- No separate validation loop on this document at S3 (the integration scripts themselves
  are validated through S7 and S9 execution).

**Rationale for B/D trim:** Running all per-feature integration scripts in sequence at S9
already constitutes an epic-level integration test. A 45-60 minute planning document
produced before any features are implemented adds overhead without adding coverage — the
same problem S4 had at the feature level.

**Gate 4.5 language (all options):** Update the approval checklist to reference "testing
approach confirmed" instead of "feature-level test strategy approved" — the feature-level
detail is deferred to S5.

---

## 7. S4 Changes

### Decision: Deprecate S4 as a stage; fold residual value into S5

**Rationale:**
- S4 has 0 formal gates — it is already structurally the weakest stage
- Its sole output (`test_strategy.md`) is immediately consumed by S5.P1.I1 with no
  independent use
- The validation loop on a test plan (S4.I4) is overhead on an artifact that S8.P2
  later replaces based on actual implementation
- Folding into S5 reduces stage count without losing any required function

### What Happens to Each S4 File

| File | Action |
|------|--------|
| `stages/s4/s4_feature_testing_strategy.md` | Replace content with redirect stub: "S4 is deprecated. Test scope decisions now live in S5. See `stages/s5/s5_v2_validation_loop.md`." |
| `stages/s4/s4_test_strategy_development.md` | Mark deprecated in header; content preserved for reference but removed from workflow |
| `stages/s4/s4_validation_loop.md` | Mark deprecated; no redirect needed (the S4 validation loop is removed entirely) |

### Redirect Stub Content

The stub in `s4_feature_testing_strategy.md` should explain:
- Why S4 was deprecated (factual, not verbose)
- Where the equivalent functionality now lives (S5 start)
- What existing child projects with in-progress S4 work should do (complete S5's test
  scope section instead; any `test_strategy.md` files already created can be referenced
  but do not need to be re-validated through the old process)

### S5 Prerequisite Update

`stages/s5/s5_v2_validation_loop.md` currently requires `S4 complete - test_strategy.md
created for this feature` as a prerequisite. This requirement is removed. The new
prerequisite is: "Test approach confirmed in EPIC_README."

---

## 8. S5 Changes

### File: `stages/s5/s5_v2_validation_loop.md`

**Phase 1 (Draft Creation) gets a new first step: "Test Scope Decision"**

This replaces the entire S4 process and takes approximately 10-15 minutes per feature.

**Test Scope Decision process:**

1. Read the epic's Testing Approach from EPIC_README
2. Read the feature's spec.md
3. Based on the Testing Approach:

   **If Option C or D (unit tests included):**
   - Identify every function in the spec that qualifies as "algorithmic" per the definition
     in this guide (primitive inputs → deterministic primitive output, no I/O)
   - List them explicitly (e.g., `calculate_multiplier()`, `normalize_name()`)
   - These become unit test tasks in the implementation plan
   - If fewer than 2 qualifying functions exist, note this and skip unit tests for this
     feature even if the epic preference includes them

   **If Option B or D (integration scripts included):**

   First, discover the project's test infrastructure (recorded once per epic in EPIC_README
   under `Integration Test Convention:`):
   - Check EPIC_README for an existing `Integration Test Convention:` field. If already
     populated (set on a prior feature), use it and skip the rest of this discovery step.
   - If not yet set: search the codebase for existing integration tests. If found, note
     their language, file naming convention, directory location, and assertion style —
     the new scripts must follow this pattern exactly.
   - If no integration tests exist, check for any tests at all (unit tests, smoke tests)
     to determine the project's test language and conventions.
   - If no tests exist at all, ask the user: "Where should integration tests live in this
     project, and which language/framework should they use?" Record the answer.

   Then, for this feature:
   - Identify the primary E2E scenario: what does the user invoke, what output files or
     data changes result, and what specific values indicate correct behavior?
   - Draft the integration test script's assertion list (3-5 key assertions)
   - This becomes a dedicated implementation task: "Create integration test script"

   **If Option A (smoke only):**
   - No test scope decision needed; proceed directly to implementation plan draft

4. Embed the test scope decision in the implementation plan draft (new "Test Strategy"
   section replaces the old `test_strategy.md` merge step)

**Validation Loop: Dimension updates**

The existing 11 dimensions include test coverage requirements that reference the old S4 model.
Two dimensions require updates:

- **Dimension 4 (Task Specification Quality):** Remove requirement that test tasks follow
  the S4 unit/integration/edge/config taxonomy. Replace with: "If unit tests are in scope,
  test tasks specify which algorithmic functions are covered. If integration script is in
  scope, one task exists for creating the integration test script with assertion list."

- **Dimension 10 (Implementation Readiness / Gate 24):** The GO/NO-GO checklist currently
  requires "Test coverage >90%." Update to: "Test scope matches epic's Testing Approach;
  if unit tests included, algorithmic functions identified; if integration script included,
  script design documented."

---

## 9. S6 Changes

### File: `stages/s6/s6_execution.md`

**Current:** "All unit tests passing (100% pass rate)" after each implementation step —
stated unconditionally in Key Outputs and Critical Rules.

**Change:** Make test execution conditional on the epic's Testing Approach.

**New behavior:**

- **Option A (smoke only):** No test-after-step requirement during S6. Integration sanity
  comes from S7.P1. The implementation checklist still tracks completion but does not gate
  on test pass rates. Mini-QC checkpoints (every 5-7 tasks) continue to apply as the quality
  mechanism during implementation.

- **Option B (integration scripts):** After completing each implementation phase (not each
  individual step), run the partially-built integration test script. It may fail early;
  the point is to catch regressions as the feature is built. Full pass is required at
  phase completion.

- **Option C (unit tests only):** Existing behavior — run unit tests after each step,
  100% pass required before proceeding.

- **Option D (both):** Run unit tests after each step; run integration script at phase
  boundaries.

**New integration test script creation step:**

If the epic includes integration scripts (Options B or D), S6 includes an explicit early task
to create the integration test script skeleton — scaffolded with the assertion list from the
S5 test scope decision, initially with all assertions failing or skipped. This is fleshed out
as implementation progresses.

**Integration test script placement:**

Follow the `Integration Test Convention:` recorded in EPIC_README during S5 discovery:
- If integration tests already exist in the project, place the new script alongside them
  using the same naming convention.
- If this is the first integration test in the project, place it in the location the user
  confirmed at S5 discovery.

One script per feature. The scripts are run together in S9.

---

## 10. S7 Changes

### File: `stages/s7/s7_p1_smoke_testing.md`

**Prerequisites section:** Remove "All unit tests passing (100% pass rate)" as a prerequisite
for starting smoke testing. Replace with:

- If unit tests opted in: "Unit tests passing for algorithmic functions identified in S5"
- If integration script opted in: "Integration test script created (may have partial passes)"
- If smoke only: No automated test prerequisite

**Part 3 (E2E Execution Test):**

Currently a 6-step manual process. Update as follows:

- **If integration script opted in (Option B or D):** Parts 1 and 2 (Import Test, Entry
  Point Test) are unchanged. Part 3 is replaced by running the feature's integration test
  script. Read `Integration Test Convention:` from EPIC_README for the script location and
  invocation command. The existing 6 steps (prepare environment, prepare test data, execute
  feature, validate structure, validate data values, check logs) are now encoded in the
  script. The agent's job is to run the script and verify it passes, not to manually execute
  each step. If the script fails, investigate root cause and fix per the existing smoke test
  failure protocol (restart from Part 1 after fixing).

- **If smoke only or unit tests only (Option A or C):** All 3 parts of the existing manual
  process are retained unchanged. For Option C, unit tests are a prerequisite to starting
  S7.P1 (they must already be passing from S6), not a replacement for Part 3 — the manual
  E2E smoke test still runs to validate real-data behavior that unit tests cannot cover.

**Documentation note:** The test scenario and expected results artifacts currently created
in Part 3 (`test_scenario.md`, `expected_results.md`) are superseded by the integration test
script itself when Option B or D is in use. They do not need to be created separately — the
script is the documentation.

---

## 11. S8 Changes

### File: `stages/s8/s8_p2_epic_testing_update.md`

S8.P2 currently focuses on updating the `epic_smoke_test_plan.md` document based on
implementation discoveries. This is valuable work regardless of test approach, but needs
to be extended for integration scripts.

**Additional step for Options B and D (integration scripts):**

After completing the existing steps (review actual implementation, identify gaps, update
epic_smoke_test_plan.md), add:

> **Step 3b: Update Integration Test Script**
>
> Review the feature's integration test script against actual implementation. Read
> `Integration Test Convention:` from EPIC_README for the script location and invocation
> command.
> - Verify assertions reflect real output structure (field names, value ranges)
> - Add assertions for integration points discovered during development
> - Remove assertions for behaviors that changed
> - Run the updated script to confirm it passes with the actual implementation
> - Commit the updated script alongside epic_smoke_test_plan.md

**Key distinction to reinforce:** The integration test script captures testable behaviors;
the `epic_smoke_test_plan.md` captures the human-readable rationale and update history. Both
evolve together at S8.P2.

---

## 12. S9 Changes

### File: `stages/s9/s9_p1_epic_smoke_testing.md`

S9 currently runs the epic_smoke_test_plan.md as a manual process (Part 4: cross-feature
integration). This changes as follows:

**If integration scripts opted in (Option B or D):**

After Parts 1-3 (Import, Entry Point, E2E), Part 4 is:
- Run all feature integration scripts in sequence from the location recorded in EPIC_README
  under `Integration Test Convention:`
- Each script must pass (exit code 0)
- If any script fails, document which feature's script failed and why, fix the issue,
  and restart from Part 1 per the existing failure protocol
- epic_smoke_test_plan.md remains as the guide for human-readable scenario documentation,
  but the pass/fail determination in Part 4 comes from script execution results

**If smoke only (Option A) or unit tests only (Option C):**
- Existing manual Part 4 process is unchanged
- For Option C: The S9 validation loop should also verify that all unit tests for features
  in this epic pass together (no cross-feature regressions) — run the epic's feature test
  suites collectively before declaring S9 complete

The S9 epic validation loop (`stages/s9/s9_p2_epic_qc_rounds.md`) should include a new
check: "All integration scripts pass (exit code 0)" — conditional on testing approach B or D.

---

## 13. S10 Changes

### File: `stages/s10/s10_epic_cleanup.md`

**Gate 7.1 (Unit Tests — 100% Pass):**

Currently unconditional. New behavior:

- **If unit tests not opted in (Options A or B):** Gate 7.1 is skipped. Note in the
  gate documentation: "Unit tests not in scope for this epic per S1 test approach decision."
- **If unit tests opted in (Options C or D):** Gate 7.1 is retained; 100% pass required.

**New Gate 7.1b (Integration Scripts — all pass):**

- **If integration scripts opted in (Options B or D):** Before user testing, run all
  integration scripts. All must pass (exit code 0). Failure → fix and rerun (does not
  require returning to S9 unless the fix is a behavior change).
- **If integration scripts not opted in:** Gate 7.1b is skipped.

**Gate 7.2 (User Testing)** — no change.

### File: `reference/mandatory_gates.md`

Update the S6 and S10 gate descriptions to reflect conditional behavior. Update the quick
summary table to show which gates are conditional.

Specifically:
- S6 row: "Unit tests after each step" → conditional; describe all 4 behaviors
- S10 "Unit Tests" row: conditional on test approach; add new row for integration scripts

---

## 14. New Artifact: Integration Test Script Pattern

### New file: `reference/integration_test_script_pattern.md`

This guide covers the conventions for integration test scripts created during S6 and
maintained through S8.

**Content:**

### What an Integration Test Script Does

An integration test script executes the feature (or a subset of it) end-to-end with
production-like data and asserts that the output is correct. It is not a unit test —
it does not mock dependencies. It runs the actual code against real or real-like data.

### Codebase Conformance (Required)

Integration test scripts must conform to the project's existing test infrastructure.
This is not optional — a non-conforming script creates a parallel test system that
will not be maintained.

**Discovery order (recorded once per epic in EPIC_README under `Integration Test Convention:`):**

0. **Check EPIC_README first.** If `Integration Test Convention:` is already populated
   (set on a prior feature this epic), use it. Do not re-run discovery.

1. **Existing integration tests:** Search the codebase for integration test files. If
   found, examine their language, framework, directory structure, file naming convention,
   assertion style, and how they are invoked. The new scripts must follow this pattern.

2. **Existing tests of any kind:** If no integration tests exist, check for unit tests
   or other tests to determine the project's test language and framework conventions.
   Follow the same language and framework; the structure can be adapted for integration
   scope.

3. **No tests exist:** Ask the user: "Where should integration tests live in this project,
   and which language/framework should they use?" Record the answer in EPIC_README under
   `Integration Test Convention:` before creating any test files.

**The `Integration Test Convention:` field in EPIC_README records:**
- Language and framework (e.g., "Python/pytest", "Python/stdlib unittest", "bash/bats")
- Directory location (e.g., `tests/integration/`, `test/`, `epics/{epic}/integration_tests/`)
- File naming convention (e.g., `test_{feature}_integration.py`, `{feature}_e2e_test.py`)
- How to run all scripts (e.g., `pytest tests/integration/`, `bash run_tests.sh`)

### Structure

The script structure follows the project's test framework. The sections below describe
what the script must cover regardless of framework, using Python as an illustrative example.

**Required coverage (framework-agnostic):**

1. **Feature execution** — invoke the feature's entry point end-to-end (no mocking)
2. **Output structure** — verify expected output files exist and have required fields
3. **Output values** — verify data values are correct, non-empty, and non-uniform
4. **Integration points** — verify cross-feature data dependencies are satisfied

**Python/subprocess example** (adapt to project's actual framework and conventions):

```python
# Integration test: {feature_name}
# Follow project's existing test structure — this is an example only.
# Location: {discovered from EPIC_README Integration Test Convention}

def test_feature_execution():
    """Feature runs end-to-end without error."""
    # Invoke entry point; assert exit code 0

def test_output_structure():
    """Output files exist and have required fields."""
    # Assert expected output files exist
    # Assert required columns/keys present

def test_output_values():
    """Output data values are correct (not placeholders, not uniform)."""
    # Assert values in expected ranges
    # Assert non-uniform distribution (algorithm ran, not default-filled)

def test_integration_points():
    """Cross-feature integration points are satisfied."""
    # Assert downstream data structures updated correctly
```

### Key Conventions

1. **Exit code is the contract.** Pass = exit code 0, fail = non-zero. Scripts are run
   by S7, S9, and S10 gates by checking exit code. No custom output parsing.

2. **Use real or real-like data, never mocks.** Scripts must run against the project's
   actual data directory or a representative subset of it.

3. **Assert values, not existence.** File presence is not sufficient. Assert that values
   are in expected ranges, are not placeholders, and show variance across records.

4. **Scripts are additive, not replaced.** When S8.P2 discovers new integration points,
   assertions are added to the existing script. The script grows as the feature matures.

5. **Language and framework follow the project.** Use whatever the project already uses.
   If the project has no tests at all, use the same language as the main codebase unless
   the user specifies otherwise.

6. **Location and naming follow the project.** Use the `Integration Test Convention:`
   field recorded in EPIC_README. One script per feature; all scripts runnable
   independently and runnable together for epic-level validation (S9).

### Running All Scripts (S9 / S10)

How to run all scripts depends on the framework recorded in `Integration Test Convention:`.
Examples:

```bash
# pytest
pytest tests/integration/ -v

# bash scripts
for script in integration_tests/*.sh; do bash "$script" || exit 1; done

# Python stdlib
for script in integration_tests/test_*_e2e.py; do python "$script" || exit 1; done
```

Use the invocation method that matches the project's framework. The S9 guide update
should reference the specific invocation command recorded in EPIC_README, not a generic
example.

---

## 15. Complete File Change List

### Files to Modify

| File | Change Type | Description |
|------|-------------|-------------|
| `stages/s1/s1_epic_planning.md` | Add section | Test approach decision in Step 5; agent must ask user |
| `stages/s3/s3_epic_planning_approval.md` | Update | S3.P1 conditional: A/C unchanged (45-60 min, full validation loop); B/D trimmed (10-15 min, success criteria only, no validation loop); Gate 4.5 checklist updated |
| `stages/s4/s4_feature_testing_strategy.md` | Replace | Redirect stub pointing to S5 |
| `stages/s4/s4_test_strategy_development.md` | Deprecate | Mark deprecated in header; preserve for reference |
| `stages/s4/s4_validation_loop.md` | Deprecate | Mark deprecated; no redirect |
| `stages/s5/s5_v2_validation_loop.md` | Update | Remove S4 prerequisite; add Test Scope Decision step; update Dimensions 4 and 10 |
| `stages/s6/s6_execution.md` | Update | Make test-after-step conditional; add integration script creation task |
| `stages/s7/s7_p1_smoke_testing.md` | Update | Conditional prerequisites; Part 3 runs script if opted in |
| `stages/s8/s8_p2_epic_testing_update.md` | Update | Add Step 3b for integration script maintenance |
| `stages/s9/s9_p1_epic_smoke_testing.md` | Update | Part 4 runs integration scripts if opted in |
| `stages/s9/s9_p2_epic_qc_rounds.md` | Update | Add conditional check: "All integration scripts pass (exit code 0)" |
| `stages/s10/s10_epic_cleanup.md` | Update | Gate 7.1 conditional; add Gate 7.1b for integration scripts |
| `reference/mandatory_gates.md` | Update | Conditional gate descriptions; S6 and S10 rows |
| `templates/epic_ticket_template.md` | Update | Add `Testing Approach:` field |
| `templates/epic_readme_template.md` | Update | Add `Testing Approach:` and `Integration Test Convention:` fields to header block |
| `templates/feature_test_strategy_template.md` | Revise (conditional) | Narrow to algorithmic functions only; mark as applicable for Options C and D only; remove coverage matrix |
| `reference/stage_5/stage_5_reference_card.md` | Update | Remove S4 dependency reference |
| `reference/stage_5/s5_v2_quick_reference.md` | Update | Same |

### Files to Create

| File | Description |
|------|-------------|
| `reference/integration_test_script_pattern.md` | New: conventions for E2E integration test scripts; codebase conformance requirement; discovery process |

### Files to Check (May Need Minor Updates)

| File | Check For |
|------|-----------|
| `audit/dimensions/d18_stage_flow_consistency.md` | References to S4 in stage flow |
| `reference/critical_workflow_rules.md` | Unit test pass rate requirements |
| `reference/qc_rounds_pattern.md` | Unit test references in QC round dimensions |
| `stages/s7/s7_p2_qc_rounds.md` | Unit test pass dimensions |
| `stages/s9/s9_epic_final_qc.md` | Unit test pass requirements |
| `stages/s9/s9_p3_user_testing.md` | Any unit test prerequisites |
| `EPIC_WORKFLOW_USAGE.md` | Stage list and descriptions |
| `guides/README.md` | Stage overview |

---

## 16. Migration Notes

### For Child Projects With In-Progress Epics

**If S4 is in progress but not complete:**
The agent should stop S4, record the algorithmic functions already identified (if any)
in a brief note, and pick up in S5 with the Test Scope Decision step. No `test_strategy.md`
needs to be created.

**If S4 is already complete (test_strategy.md exists):**
Treat the existing `test_strategy.md` as the Test Scope Decision output. When S5 asks for
the test scope decision, reference the existing file rather than re-doing the work. The
validation loop on the test strategy (S4.I4) does not need to be re-run.

**If unit tests are already written (during S6):**
Existing tests are not deleted. The change is about future test planning — existing tests
continue to run. At S10 Gate 7.1, if tests exist they must pass regardless of the epic's
test approach setting (the setting gates what *new* tests are planned, not whether *existing*
tests are executed).

**If the epic is already past S1 (no Testing Approach field in EPIC_README):**
After receiving this sync update, the agent should add the `Testing Approach:` field to the
EPIC_README at the start of the next work session and ask the user which option applies. The
recommended default for any epic already in progress is **Option A (smoke only)** — it
requires no backfilling of test artifacts and preserves the manual smoke testing the epic has
been using. If the user wants to adopt integration scripts mid-epic (Option B or D), they can
choose to do so. For any remaining features that haven't been implemented yet: run the
S5 discovery step (check/set `Integration Test Convention:` in EPIC_README), then include
the integration script creation task in S6.

### For Child Projects Starting New Epics

The test approach question appears at S1. There is no backward compatibility concern —
the decision is new information that did not exist before.

### Sync Compatibility

The guide changes in this proposal are all in `.shamt/guides/` files that are propagated
to child projects via the standard sync import. No changes to `.shamt/scripts/` are
required, so the sync mechanism itself is not affected.

---

## 17. Open Questions

**Q1: What if the project's test infrastructure doesn't support Python integration scripts?**

**Resolved.** See Section 14. Scripts must conform to the project's existing test
infrastructure (language, framework, location, naming). Python is an illustrative example
only. Discovery process at S5 determines the actual convention; result recorded in
EPIC_README under `Integration Test Convention:`.

**Q2: Should S3.P1 (Epic Testing Strategy) be simplified now that feature-level test
planning has moved to S5?**

**Resolved.** See Section 6. For Options A/C: unchanged. For Options B/D: trimmed to
10-15 minutes (epic success criteria only); no validation loop on the document at S3.

**Q3: Should the skip logic for S4 be "skip entirely" or "skim and redirect"?**

**Resolved.** Redirect stub for now. The stub approach is safer for migration — agents
following old guides won't hit a missing file. After one full import cycle confirms child
projects have updated, remove S4 from stage flow documentation entirely.

**Q4: The S1 question requires user input — does this fit the current S1 flow?**

**Resolved.** Yes. S1 already requires user confirmation at multiple points (Discovery
approval, epic ticket validation, feature breakdown). Bundle the test approach question
into the epic ticket validation step: "Before I finalize the epic ticket, one question:
[4-way test approach question]." Agent writes the answer directly into the epic ticket
and EPIC_README before creating the folder structure. User interaction count unchanged.

---

*End of SHAMT6_DESIGN.md — Validated (6 rounds, 3 consecutively clean)*
