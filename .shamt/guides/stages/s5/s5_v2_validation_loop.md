# S5 v2: Implementation Planning with Validation Loop

**Extends:** Master Validation Loop Protocol
**See:** `reference/validation_loop_master_protocol.md`

**Stage:** S5 (Implementation Planning)
**Version:** 2.3 (Consolidated to mechanical-only planning - SHAMT-32)
**Created:** 2026-02-09
**Last Updated:** 2026-04-06
**Status:** Active (replaces S5 v1 22-iteration workflow)

---

## Table of Contents

1. [Overview](#overview)
   - [What is S5 v2?](#what-is-s5-v2)
   - [How S5 v2 Differs from S5 v1](#how-s5-v2-differs-from-s5-v1)
   - [When to Use This Guide](#when-to-use-this-guide)
   - [Relationship to Master Validation Loop Protocol](#relationship-to-master-validation-loop-protocol)
1. [📐 THE TWO-PHASE APPROACH](#📐-the-two-phase-approach)
1. [🚀 PHASE 1: DRAFT CREATION](#🚀-phase-1-draft-creation)
   - [Step-by-Step Process](#step-by-step-process)
   - [Draft Creation Exit Criteria](#draft-creation-exit-criteria)
1. [🔄 PHASE 2: VALIDATION LOOP](#🔄-phase-2-validation-loop)
   - [Validation Loop Protocol](#validation-loop-protocol)
   - [Round Structure](#round-structure)
   - [The 9 Mechanical Validation Dimensions](#the-9-mechanical-validation-dimensions)
   - [Round-by-Round Reading Patterns](#round-by-round-reading-patterns)
   - [Example Validation Loop Execution](#example-validation-loop-execution)
1. [🛑 SPECIAL CASES & PROTOCOLS](#🛑-special-cases--protocols)
   - [If Validation Loop Exceeds 10 Rounds](#if-validation-loop-exceeds-10-rounds)
   - [If spec.md Discrepancies Found (Dimension 9: Spec Alignment)](#if-specmd-discrepancies-found-dimension-9-spec-alignment)
   - [If Draft Quality <70% After 90 Minutes](#if-draft-quality-70-after-90-minutes)
1. [⚠️ COMMON ISSUES & FIXES](#⚠️-common-issues--fixes)
   - [Issue 1: "Can't find all spec requirements in steps"](#issue-1-cant-find-all-spec-requirements-in-steps)
   - [Issue 2: "Locate strings taking too long to find"](#issue-2-locate-strings-taking-too-long-to-find)
   - [Issue 3: "Fixes introducing new issues"](#issue-3-fixes-introducing-new-issues)
   - [Issue 4: "Validation loop stuck at 8-9 rounds"](#issue-4-validation-loop-stuck-at-8-9-rounds)
   - [Issue 5: "Unsure if something is an issue"](#issue-5-unsure-if-something-is-an-issue)
1. [🚫 ANTI-PATTERNS TO AVOID](#🚫-anti-patterns-to-avoid)
   - [❌ Anti-Pattern 1: "Working from Memory"](#❌-anti-pattern-1-working-from-memory)
   - [❌ Anti-Pattern 2: "Deferring Minor Issues"](#❌-anti-pattern-2-deferring-minor-issues)
   - [❌ Anti-Pattern 3: "Stopping at 3 Rounds Total"](#❌-anti-pattern-3-stopping-at-3-rounds-total)
   - [❌ Anti-Pattern 4: "Batching Fixes"](#❌-anti-pattern-4-batching-fixes)
   - [❌ Anti-Pattern 5: "Skipping Re-Reading After Small Fix"](#❌-anti-pattern-5-skipping-re-reading-after-small-fix)
   - [❌ Anti-Pattern 6: "Saying 'Efficiently' or 'Quickly'"](#❌-anti-pattern-6-saying-efficiently-or-quickly)
1. [Exit Criteria](#exit-criteria)
   - [Validation Loop Exit Criteria](#validation-loop-exit-criteria)
   - [Gate 5: User Approval](#gate-5-user-approval)
   - [🛑 MANDATORY CHECKPOINT: Gate 5](#-mandatory-checkpoint-gate-5)
1. [📊 TRACKING & DOCUMENTATION](#📊-tracking--documentation)
   - [Update Agent Status](#update-agent-status)
   - [Validation Loop Log](#validation-loop-log)
1. [📚 REFERENCE](#📚-reference)

---

## 🚨 MANDATORY READING PROTOCOL

Before starting this stage — including when resuming a prior session:
1. Use Read tool to load THIS ENTIRE GUIDE — not just the overview
   - Quick entry point: `reference/stage_5/stage_5_reference_card.md` — use for second or later features
   - Full guide (this file): required for first feature and edge cases
2. Verify prerequisites checklist below
3. Update feature README.md Agent Status with guide name + timestamp

DO NOT start work based on the overview alone.

---

## 🚫 FORBIDDEN SHORTCUTS

You CANNOT:
- Draft an implementation plan based on general knowledge — follow Steps 0–7 in Phase 1
- Skip Phase 2 (Validation Loop) because Phase 1 is "done enough"
- Present the plan to the user or stop before sub-agent confirmation without completing the exit sequence — see `reference/validation_loop_master_protocol.md` Exit Criteria for the required protocol
- Proceed to S6 without Gate 5 user approval

If you are about to do any of the above: STOP and re-read the relevant section.

---

## Prerequisites

**Before starting S5 v2:**

- [ ] Test approach confirmed in EPIC_README (`Testing Approach:` field set at S1)
- [ ] Feature spec.md complete (all sections filled, no TBD)
- [ ] Feature checklist.md resolved (all user questions answered, Gate 3 passed)
- [ ] S5 v2 template available: `templates/implementation_plan_template.md`
- [ ] Feature README.md exists with Agent Status section

**Note:** S4 is deprecated. The `test_strategy.md` prerequisite has been removed. Test scope
decisions are now made during Phase 1 of S5 (Test Scope Decision step).

**Parallel mode (S5): If running as a secondary agent in parallel S5:**
- You must have received an S5 handoff package from Primary (Sync Point 2 activation)
- Use the handoff package as your starting context (spec.md, checklist.md, EPIC_README.md, smoke test plan, other feature spec paths)
- Write milestone checkpoints at: Phase 1 exit (draft complete, before validation loop), after each clean validation round
- After your validation loop passes: signal completion and enter WAITING_FOR_SYNC — do NOT proceed to Gate 5
- Gate 5 in parallel mode is combined: Primary will run S5-CA and present all plans together; you will receive a notification when combined Gate 5 passes
- See: `parallel_work/s5_secondary_agent_guide.md` → Completion Signal

**If any prerequisite missing:**
- ❌ Do NOT start S5 - Return to complete missing prerequisites

---

## Overview

### What is S5 v2?

S5 v2 is a **validation loop-based approach** to implementation planning that systematically refines `implementation_plan.md` through iterative validation rounds until it meets all quality criteria.

**Key Innovation:** Instead of 22 sequential iterations, S5 v2 uses a **2-phase approach**:
1. **Phase 1:** Create draft implementation_plan.md (60-90 min, ~70% quality)
2. **Phase 2:** Validation Loop refines to 99%+ quality (3.5-6 hours, 6-8 rounds typical)

**Exit Criteria:** Primary clean round + independent sub-agent confirmation

---

### How S5 v2 Differs from S5 v1

| Aspect | S5 v1 (Old) | S5 v2 (New) |
|--------|-------------|-------------|
| **Structure** | 22 iterations, 3 rounds | 9 dimensions, 1 validation loop |
| **Time** | 9-11 hours | 4.5-7 hours (35-50% savings) |
| **Format** | Task-based planning | Mechanical step-by-step planning |
| **Quality** | Subjective (agent self-reports) | Objective (primary clean round + sub-agent confirmation) |
| **Verification** | Single pass per iteration | Multiple passes until clean |
| **Issue Deferral** | Possible to defer | Impossible (must fix before next round) |

---

### When to Use This Guide

**Use S5 v2 when:**
- Starting implementation planning (S4 is deprecated; proceed to S5 directly after S3)
- Creating implementation_plan.md for a new feature
- All spec.md requirements finalized and user-approved (Gate 3 passed)
- Re-entering from S8 alignment loop to plan the next feature in the epic

---

### Relationship to Master Validation Loop Protocol

**S5 v2 uses mechanical validation dimensions** for validating step-by-step implementation plans.

**Validation Structure:**
- **9 Mechanical Validation Dimensions** (S5-specific, detailed below)
- Dimensions focus on: step clarity, mechanical executability, file coverage, operation specificity, verification, error handling, dependency ordering, checklists, spec alignment

**How Validation Works:**

Each validation round checks all 9 dimensions systematically:
1. **Step Clarity** - Every step unambiguous, exact paths specified
2. **Mechanical Executability** - Builder can execute without design choices
3. **File Coverage Completeness** - All files from spec covered, test files included
4. **Operation Specificity** - EDIT/CREATE/DELETE/MOVE operations are precise
5. **Verification Completeness** - Every step has mechanical verification method
6. **Error Handling Clarity** - Success/failure criteria explicit, edge cases documented
7. **Dependency Ordering** - Steps in correct execution order
8. **Pre/Post Checklist Completeness** - Both checklists complete
9. **Spec Alignment** - Plan translates ALL spec requirements, no additions

**Severity Classification:** Uses universal 4-level system from `reference/severity_classification_universal.md`:
- **CRITICAL:** Blocks execution (missing files, broken operations, undefined steps)
- **HIGH:** Causes wrong implementation (incorrect locate strings, missing requirements)
- **MEDIUM:** Reduces quality (vague verifications, incomplete checklists)
- **LOW:** Cosmetic (typos, formatting)

**Core Validation Process:** Same as master protocol - primary clean round + sub-agent confirmation required, fresh eyes every round. A round is clean if it has ZERO issues OR exactly ONE LOW-severity issue (fixed). Multiple LOW-severity issues OR any MEDIUM/HIGH/CRITICAL issue resets `consecutive_clean` to 0.

---

### Architect-Builder Pattern Integration (SHAMT-30, SHAMT-32)

**S5 creates mechanical implementation plans** validated using the 9-dimension process described in this guide.

**For S6 execution:**
- **MANDATORY** for all S6 execution in S1-S10 epic workflow (no exceptions)
- S5 produces mechanical implementation plan directly (no intermediate task-based plan)
- Plan uses step-by-step file operations (CREATE, EDIT, DELETE, MOVE)
- Plan validated using 9-dimension validation loop
- After Gate 5 user approval: Haiku builder agent executes mechanical plan (60-70% token savings)

**S5 Workflow:**
1. Complete S5 Phase 1 (Draft Creation): Create mechanical implementation plan
2. Complete S5 Phase 2 (Validation Loop): Validate using 9 dimensions
3. Gate 5: Present validated plan to user for approval
4. After approval: Proceed to S6 (architect-builder execution)

**S6 Handoff:**
- Read: `reference/architect_builder_pattern.md` (pattern overview)
- Read: `stages/s6/s6_execution.md` (S6 execution workflow)
- Create handoff package for builder
- Spawn Haiku builder agent
- Monitor execution and handle errors

**See:**
- `reference/architect_builder_pattern.md` - Full pattern documentation
- `reference/implementation_plan_format.md` - Mechanical plan format specification
- `templates/implementation_plan_template.md` - Mechanical plan template
- `stages/s6/s6_execution.md` - S6 execution workflow

---

## 📐 THE TWO-PHASE APPROACH

```text
┌─────────────────────────────────────────────────────────────┐
│                    PHASE 1: DRAFT CREATION                   │
│                       (60-90 minutes)                         │
└─────────────────────────────────────────────────────────────┘
                              ↓
    Create implementation_plan.md with all 11 sections
    Quality target: 70% (structure + major content present)
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  PHASE 2: VALIDATION LOOP                    │
│                    (3.5-6 hours, 6-8 rounds)                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
    Round 1: Find ~12 issues (3 HIGH, 6 MEDIUM, 3 LOW) → Fix all → Counter = 0
    Round 2: Find ~8 issues (0 HIGH, 8 MEDIUM) → Fix all → Counter = 0
    Round 3: Find 1 LOW issue (typo) → Fix → Counter = 1 (single low allowed) → Trigger sub-agent
      Sub-agent A: 2 MEDIUM issues → Fix → Counter = 0
    Round 4: Find 0 issues → Counter = 1 (pure clean) → Trigger sub-agent confirmation
      Sub-agent A (top-to-bottom): 0 issues ✅
      Sub-agent B (bottom-to-top): 0 issues ✅
      Both confirmed → ✅ PASSED
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    GATE 5: USER APPROVAL                     │
│                       (5-10 minutes)                          │
└─────────────────────────────────────────────────────────────┘
                              ↓
                        PROCEED TO S6
```

---

## 🚀 PHASE 1: DRAFT CREATION

⚠️ **Before starting Phase 1, confirm:**
- [ ] Phase 2 (Validation Loop) is mandatory after Phase 1 — I will not skip it
- [ ] I will not present the plan to the user or exit before completing the sub-agent confirmation — see master protocol Exit Criteria for the required sequence

Phase 1 produces a ~70% quality draft. Phase 2 is what makes it production-ready. Gate 5 (user approval) follows Phase 2.

If you navigated here via the Table of Contents: go back to the beginning and read sequentially — the MANDATORY READING PROTOCOL and FORBIDDEN SHORTCUTS at the top apply to you.

---

**Goal:** Create implementation_plan.md with mechanical implementation steps

**Time:** 60-90 minutes

**Quality Target:** ~70% complete (steps present, approximate details OK, known gaps OK)

---

### Step-by-Step Process

#### **Step 0: Test Scope Decision (10-15 minutes — replaces S4)**

This step replaces the entire S4 stage. Complete it before creating the draft.

**0.1: Read the epic's Testing Approach from EPIC_README**

The `Testing Approach:` field in the epic's EPIC_README (at the epic folder root, one level above this feature folder) is one of: A, B, C, or D.

**0.2: Based on Testing Approach, decide what tests this feature needs:**

**If Option C or D (unit tests included):**
- Read the feature's spec.md
- Identify every function in the spec that qualifies as "algorithmic":
  - Takes primitive inputs (numbers, strings, lists of primitives)
  - Returns a deterministic primitive output
  - Has no I/O dependencies (no file reads, API calls, external object calls)
  - Mocking is NOT required to test it meaningfully
- Examples that qualify: `calculate_rank_multiplier(rank: int) -> float`, `normalize_name(name: str) -> str`
- Examples that do NOT qualify: `load_rank_data(csv_path)` (file I/O), `RecordManager.calculate_total_score(item)` (depends on external object state)
- List qualifying functions explicitly (e.g., `calculate_multiplier()`, `normalize_name()`)
- These become unit test tasks in the implementation plan
- **If fewer than 2 qualifying functions exist:** Note this and skip unit tests for this feature even if the epic preference includes them

**If Option B or D (integration scripts included):**

First, discover the project's test infrastructure (recorded once per epic in EPIC_README):
- **Check EPIC_README for `Integration Test Convention:` field.** If already populated (set on a prior feature), use it. Skip steps i-iii.
- (i) Search the codebase for existing integration tests. If found, note their language, framework, directory location, naming convention, assertion style, and run command. The new script must follow this pattern exactly.
- (ii) If no integration tests exist, check for any tests at all to determine the project's test language and conventions.
- (iii) If no tests exist at all, ask the user: "Where should integration tests live in this project, and which language/framework should they use?" Record the answer in EPIC_README under `Integration Test Convention:` before proceeding.

Then, for this feature:
- Identify the primary E2E scenario: what does the user invoke, what output files or data changes result, what specific values indicate correct behavior?
- Draft the integration test script's assertion list (3-5 key assertions):
  - Feature executes end-to-end without error
  - Expected output files exist with required fields
  - Output values are correct, non-empty, and non-uniform
  - Integration points with other features are satisfied
- This becomes a dedicated implementation task: "Create integration test script for {feature_name}"

**If Option A (smoke only):**
- No test scope decision needed. Proceed directly to Step 1 below.

**0.3: Document the test scope decision in a brief note**

Write 3-5 lines in the implementation plan draft's "Test Strategy" section:
- Which option applies
- Qualifying algorithmic functions (if C/D) or "None qualifying"
- Integration script assertion list (if B/D) or "Not applicable"
- Integration test convention from EPIC_README (if B/D)

---

#### **Step 1: Setup (5 minutes)**

1. **Copy mechanical implementation plan template:**
   ```bash
   cp templates/implementation_plan_template.md feature_XX_{name}/implementation_plan.md
   ```

2. **Open files for reference:**
   - Feature spec.md (requirements source)
   - Feature checklist.md (verify all resolved)
   - EPIC_README (for Testing Approach and Integration Test Convention)

3. **Create Validation Loop Log:**
   ```bash
   cp templates/VALIDATION_LOOP_LOG_S5_template.md feature_XX_{name}/VALIDATION_LOOP_LOG.md
   ```

#### **Step 2: Spec Analysis & File Identification (15-20 minutes)**

**Goal:** Analyze spec.md and identify ALL files to be created/modified/deleted, verify external dependencies

**Process:**
1. **Read spec.md completely** - understand all requirements
2. **Identify all files to be created/modified/deleted:**
   - List every file that will be touched by this feature
   - Note operation type for each (CREATE, EDIT, DELETE, MOVE)
   - Use spec.md "Implementation Locations" and "File Operations" sections if present
3. **Identify external dependencies:**
   - List methods/classes this feature will call
   - Verify interfaces from actual source code (file:line references)
   - No assumptions - read actual code
4. **Note algorithmic functions for test creation** (from Step 0):
   - If unit tests in scope (Options C/D): which functions need unit tests
   - If integration script in scope (Options B/D): which files/endpoints the script will test

**Example File List (Draft Quality):**
```markdown
Files to be created:
- [module]/util/rank_loader.py - Load rank data from CSV

Files to be modified:
- [module]/util/RecordManager.py (~line 450) - Add get_rank_multiplier() method
- [module]/scoring/score_calculator.py (~line 200) - Apply rank multiplier to scores
- tests/unit/test_rank_loader.py - Unit tests for rank_loader (Option C/D only)

External dependencies verified:
- ConfigManager.get_config() (file: [module]/util/ConfigManager.py:234) - Returns dict
- csv_utils.read_csv_with_validation() (file: utils/csv_utils.py:45) - Params: filepath, required_columns
```

**Draft Quality Bar:**
- All major files identified (70%+ coverage acceptable)
- External dependencies listed (exact verification comes in validation loop)
- Test files noted based on Testing Approach

#### **Step 3: Pre-Execution Checklist (5-10 minutes)**

**Goal:** Create checklist of prerequisites before implementation begins

**Process:**
1. List all affected files (from Step 2)
2. Document edge cases from spec.md
3. Define rollback strategy

**Example (Draft Quality):**
```markdown
## Pre-Execution Checklist

- [ ] All affected files identified (see Step 2 file list)
- [ ] Design validated via validation loop
- [ ] Edge cases documented:
  - Empty rank file: use default multiplier
  - Duplicate items: use first occurrence
  - Invalid rank values: clamp to range 1-500
- [ ] Rollback strategy: Git branch can be reset if implementation fails
```

#### **Step 4: Draft Mechanical Steps (45-60 minutes)**

**Goal:** Translate spec requirements into mechanical file operation steps

**🚨 CRITICAL: Test Creation Steps are MANDATORY (where applicable)**

Historical evidence from SHAMT-8 Feature 04 shows test creation steps missing from implementation plan caused 56 tests to be missing until S7.P3 PR review (2-4 hour rework). **Test creation is implementation work**, not verification work.

**Process:**
1. For EACH spec requirement: create mechanical steps (CREATE, EDIT, DELETE, MOVE)
2. Include exact file paths and operation types
3. For EDIT operations: approximate locate strings (exact strings come in validation)
4. For CREATE operations: function signatures and structure (full content comes in validation)
5. Embed algorithm traceability in step details (e.g., "Step 15: Implement rank multiplier calculation (spec.md Algorithms section, step 3)")
6. Include test creation steps based on Testing Approach:
   - **If unit tests in scope (Options C/D):** Create steps for test files covering algorithmic functions from Step 0
   - **If integration script in scope (Options B/D):** Create step for integration test script with assertion list from Step 0
   - **If smoke only (Option A):** No test creation steps

**Example Mechanical Steps (Draft Quality):**
```markdown
## Implementation Steps

### Step 1: Create rank loader module
**File:** `[module]/util/rank_loader.py`
**Operation:** CREATE
**Details:**
- Create function: load_rank_data(csv_path: str) -> List[RankItem]
- Implements spec.md Algorithms step 1 (Load rank from CSV)
- Read CSV using csv_utils.read_csv_with_validation()
- Return list of rank items with fields: item_name, rank_value
- Handle errors: file not found → return [], malformed CSV → skip invalid rows
**Verification:** File exists, contains load_rank_data() function with correct signature

### Step 2: Add rank multiplier method to RecordManager
**File:** `[module]/util/RecordManager.py`
**Operation:** EDIT
**Details:**
- Locate: `class RecordManager:` (approximate - will refine in validation)
- Add method: get_rank_multiplier(item_name: str) -> float
- Implements spec.md Algorithms step 3 (Calculate multiplier)
- Call rank_loader.load_rank_data() to get rankings
- Match item_name to ranking, return multiplier value
- If no match: return default multiplier 1.0
**Verification:** Read RecordManager.py, confirm get_rank_multiplier() method exists

### Step 3: Create unit tests for rank loader (Option C/D)
**File:** `tests/unit/test_rank_loader.py`
**Operation:** CREATE
**Details:**
- Test functions identified in Step 0: load_rank_data()
- Tests: test_load_valid_csv, test_load_missing_file, test_load_malformed_csv
- Implements Testing Approach from EPIC_README (Option C or D)
**Verification:** Test file exists with 3+ test functions
```

**Draft Quality Bar:**
- 70%+ of spec requirements have mechanical steps
- File paths and operation types specified
- Approximate details OK (validation loop will refine)
- Test steps present where applicable

#### **Step 5: Order Steps by Dependency (10-15 minutes)**

**Goal:** Ensure steps execute in correct order

**Process:**
1. Review all steps from Step 4
2. Ensure files are created before they are edited
3. Ensure dependencies are satisfied (e.g., import added before it's used)
4. Add dependency notes in step details where needed
5. Reorder steps if necessary

**Example:**
- Step 1: Create rank_loader.py (must happen before Step 2 imports it)
- Step 2: Add import to RecordManager.py
- Step 3: Add get_rank_multiplier() method to RecordManager
- Step 4: Create unit tests (depends on Steps 1-3 being complete)

**Draft Quality Bar:**
- No obvious dependency violations
- Create operations before edit operations for same file

#### **Step 6: Post-Execution Checklist (5 minutes)**

**Goal:** Define completion verification checklist

**Process:**
Create standard checklist for builder to verify after execution

**Example:**
```markdown
## Post-Execution Checklist

- [ ] All steps completed without error
- [ ] Verification checks passed for each step
- [ ] Tests run (if applicable - Option C/D)
- [ ] No syntax errors (file can be imported/compiled)
- [ ] Ready for handoff back to architect
```

---

### Draft Creation Exit Criteria

**Stop Phase 1 when ANY of these true:**

1. **Time limit reached:** 90 minutes elapsed (stop even if only 70% complete)
2. **Minimum content present:**
   - ✅ All 11 dimension sections exist
   - ✅ 70%+ of spec requirements have tasks
   - ✅ 70%+ of algorithms mapped
   - ✅ Basic error/edge cases listed

**Quality Expectation:** ~70% complete with known gaps

**Next Action:** Update Agent Status, proceed to Phase 2 (Validation Loop)

**🚨 Before entering Phase 2:** Review your Phase 1 "Known Gaps" section. ANY gap documented as "may need more detail" or "to be added" MUST be resolved NOW — before Round 1 begins.

> **Why:** If a Known Gap reaches Round 1, it becomes a Round 1 issue. Round 1 will not be clean. This is fine (fix-and-continue handles it), but it's more efficient to fix gaps at the Phase 1/Phase 2 boundary than inside the loop. The "known gaps OK" quality target applies during Phase 1 drafting — not when you START the loop.

---

## 🔄 PHASE 2: VALIDATION LOOP

**Goal:** Iteratively refine implementation_plan.md until it passes all criteria

**Time:** 3.5-6 hours (typically 6-8 rounds)

**Quality Target:** 99%+ complete (primary clean round + sub-agent confirmation)

---

### Validation Loop Protocol

**Master Protocol:** See `reference/validation_loop_master_protocol.md`

**S5 Context:** Validating implementation_plan.md against 9 mechanical dimensions

**Exit Criteria:** Primary clean round + independent sub-agent confirmation

**Model Selection for Token Optimization (SHAMT-27):**

MUST use strategic model delegation (mandatory per SHAMT-29) to save 35-45% tokens per validation:

```
Primary Agent (Opus):
├─ Spawn Haiku → File path checks, step numbering, checklist format (D1, D8)
├─ Spawn Sonnet → Operation specificity, verification clarity (D4, D5)
├─ Primary handles → Mechanical executability, spec alignment, dependency ordering (D2, D7, D9)
├─ Primary handles → Adversarial self-check
└─ Spawn 2x Haiku (parallel) → Sub-agent confirmations (see Exit Criteria below for Task tool syntax)
```

**See:** `reference/model_selection.md` for complete rationale and additional Task tool examples.

---

### Round Structure

Each round follows this pattern:

```text
1. BREAK (2-5 minutes)
   - Clear mental model from previous round
   - Take actual break (don't work from memory)

2. RE-READ ENTIRE implementation_plan.md
   - Use Read tool (no working from memory)
   - Assume everything is wrong (fresh skepticism)

3. CHECK ALL 9 MECHANICAL DIMENSIONS
   - Step Clarity, Mechanical Executability, File Coverage Completeness
   - Operation Specificity, Verification Completeness, Error Handling Clarity
   - Dependency Ordering, Pre/Post Checklist Completeness, Spec Alignment
   - Systematically validate against each dimension
   - Use reading pattern for this round
   - Document EVERY issue found (no matter how minor)

4. ADVERSARIAL SELF-CHECK (run after all dimensions, before scoring)
   - See master protocol for the 5 required questions
   - Any new issues found → add to this round's issue list
   - Any open questions that can't be answered locally → Open Questions Protocol
   - This step may not be skipped — a round may not be scored clean if it is

5. REPORT FINDINGS
   - Count issues by dimension (including any from Adversarial Self-Check)
   - Report: "Round N: X issues found across Y dimensions"

6. FIX OR CONTINUE
   - If multiple LOW issues OR any MEDIUM/HIGH/CRITICAL: Fix ALL → Round N+1, RESET counter to 0
   - If exactly 1 LOW issue: Fix → Counter = 1 (clean with 1 low fix) → trigger sub-agent confirmation
   - If 0 issues: Counter = 1 (pure clean) → trigger sub-agent confirmation
   - See `reference/severity_classification_universal.md` for severity definitions
```

---

### The 9 Mechanical Validation Dimensions

**These are the core validation dimensions for mechanical implementation plans.**

**Every validation round checks all 9 dimensions:**
1. Step Clarity
2. Mechanical Executability
3. File Coverage Completeness
4. Operation Specificity
5. Verification Completeness
6. Error Handling Clarity
7. Dependency Ordering
8. Pre/Post Checklist Completeness
9. Spec Alignment

**📍 WHERE EVIDENCE GOES:**
- All mechanical steps and checklists go IN implementation_plan.md
- Validation Loop Log tracks rounds/issues, NOT the plan content itself

---

#### **Dimension 1: Step Clarity**

**What to Check:**
- [ ] Every step is unambiguous with no interpretation needed
- [ ] Exact file paths specified for all operations
- [ ] No "TODO" or "TBD" in steps
- [ ] Step numbering sequential with no gaps
- [ ] Each step has clear action description

**Evidence Required:**
- All steps have explicit file paths
- All steps have specific operation types (CREATE, EDIT, DELETE, MOVE)

**Example Issue:**
- "Step 5 file path is vague: 'somewhere in util folder' → Must specify exact path like [module]/util/rank_loader.py"

**How to Fix:**
- Rewrite Step 5 with exact file path
- Ensure operation type is explicit

---

#### **Dimension 2: Mechanical Executability**

**What to Check:**
- [ ] Builder can execute without making design choices
- [ ] No "figure it out" gaps (e.g., "implement the logic")
- [ ] No steps requiring external knowledge beyond the plan
- [ ] No decisions left to builder (all choices made by architect)

**Evidence Required:**
- Every step contains complete execution details
- No vague instructions

**Example Issue:**
- "Step 8 says 'add appropriate error handling' → Builder can't determine 'appropriate'. Must specify exact error types and handling strategy"

**How to Fix:**
- Rewrite Step 8: "Wrap in try-except, catch FileNotFoundError, log warning, return []"
- Remove all subjective language from steps

---

#### **Dimension 3: File Coverage Completeness**

**What to Check:**
- [ ] All files from spec are covered in plan steps
- [ ] No missing files mentioned in spec but absent from plan
- [ ] Files created before they are edited (dependency order)
- [ ] **🚨 CRITICAL: Test creation steps present (where applicable based on Testing Approach)**

**Evidence Required:**
- File list matches spec.md requirements
- Test files included based on Testing Approach (Options C/D)

**Example Issue:**
- "spec.md mentions modifying score_calculator.py but no step exists for that file"
- "Testing Approach is Option C (unit tests) but no test file creation step for algorithmic functions"

**How to Fix:**
- Add step for score_calculator.py modification
- Add test creation step for identified algorithmic functions (from Step 0)

**Historical Evidence:**
- SHAMT-8 Feature 04: 56 tests missing because test creation steps were omitted
- Fix: Dimension 3 now validates test file coverage based on Testing Approach

---

#### **Dimension 4: Operation Specificity**

**What to Check:**
- [ ] EDIT steps have exact locate/replace strings
- [ ] CREATE steps have full content (or detailed structure in draft, full content in validation)
- [ ] DELETE operations specify exact file paths
- [ ] MOVE operations specify both source and destination
- [ ] All external dependencies verified from actual source code (file:line references)

**Evidence Required:**
- EDIT operations have unique locate strings
- CREATE operations have complete content or detailed structure
- No vague operation descriptions

**Example Issue:**
- "Step 3 EDIT operation has vague locate string: 'find the imports section' → Must use exact line like 'import { cors } from \"cors\";'"

**How to Fix:**
- Read actual file to find exact locate string
- Update Step 3 with unique, exact locate text
- For CREATE: ensure function signatures, imports, structure are complete

---

#### **Dimension 5: Verification Completeness**

**What to Check:**
- [ ] Every step has a verification method
- [ ] Verifications are mechanically checkable (read file, run command, check output)
- [ ] No subjective verifications ("looks good", "works correctly")
- [ ] Verification specifies what to check and where

**Evidence Required:**
- All steps have explicit verification methods
- Verifications are actionable by builder

**Example Issue:**
- "Step 7 verification: 'Verify imports are correct' → Builder can't determine 'correct'. Must specify: 'Read server.ts line 3, confirm authenticate import present'"

**How to Fix:**
- Rewrite verifications to be mechanical: read specific file, check specific content
- Remove subjective language

---

#### **Dimension 6: Error Handling Clarity**

**What to Check:**
- [ ] Success/failure criteria explicit for each step
- [ ] Edge cases documented in pre-execution checklist
- [ ] What to do if verification fails is clear (report to architect)
- [ ] Error scenarios from spec.md are covered in steps

**Evidence Required:**
- Pre-execution checklist includes edge cases
- Steps specify error handling where applicable

**Example Issue:**
- "Step 4 doesn't specify what happens if file not found → Must add: If file doesn't exist, report to architect and halt"

**How to Fix:**
- Update step to include failure handling
- Document edge cases in pre-execution checklist

---

#### **Dimension 7: Dependency Ordering**

**What to Check:**
- [ ] Steps are in correct execution order
- [ ] Create file before editing it
- [ ] Dependencies explicit (e.g., "Step 5 must complete before Step 6")
- [ ] Import added before code uses it

**Evidence Required:**
- Step sequence makes logical sense
- No backward dependencies

**Example Issue:**
- "Step 2 edits rank_loader.py but Step 5 creates it → Wrong order, must create before edit"

**How to Fix:**
- Reorder steps: move Step 5 (CREATE) before Step 2 (EDIT)
- Add dependency note if needed

---

#### **Dimension 8: Pre/Post Checklist Completeness**

**What to Check:**
- [ ] Pre-execution checklist covers all prerequisites
- [ ] Pre-execution checklist includes edge cases
- [ ] Pre-execution checklist defines rollback strategy
- [ ] Post-execution checklist confirms completion
- [ ] Post-execution checklist includes test verification (if applicable)

**Evidence Required:**
- Both checklists present and complete

**Example Issue:**
- "Pre-execution checklist missing rollback strategy → Add: 'Rollback: git reset --hard if implementation fails'"

**How to Fix:**
- Add missing items to pre-execution checklist
- Ensure post-execution checklist covers all completion criteria

---

#### **Dimension 9: Spec Alignment**

**What to Check:**
- [ ] Implementation plan faithfully translates ALL spec requirements into steps
- [ ] No spec requirements missing from plan
- [ ] No additions beyond spec scope
- [ ] Algorithms from spec.md traced to specific steps (embedded in step details)
- [ ] Data flow from spec.md reflected in step ordering

**Evidence Required:**
- Every spec requirement has corresponding step(s)
- No steps that implement unrequested features

**Example Issue:**
- "spec.md requirement 'Handle item name matching' (line 67) has no corresponding step"

**How to Fix:**
- Add step implementing item name matching
- Reference spec.md line 67 in step details
- Verify all spec requirements covered

---

### Round-by-Round Reading Patterns

**Vary patterns each round to catch different issue types**

**Every round checks all 9 mechanical dimensions, but with varying focus areas:**

#### **Round 1: Sequential + Step Clarity Focus**
- Read implementation_plan.md top to bottom
- Primary focus: D1-D3 (Step Clarity, Mechanical Executability, File Coverage)
- Check: All steps present, paths specified, operations clear, files complete
- Pattern: Line-by-line completeness check

#### **Round 2: Reverse + Operation Specificity Focus**
- Read implementation_plan.md bottom to top
- Primary focus: D4-D6 (Operation Specificity, Verification, Error Handling)
- Check: EDIT locate strings exact, CREATE content complete, verifications mechanical
- Pattern: Reverse reading catches issues missed in forward read

#### **Round 3: Spot-Checks + Alignment Focus**
- Random spot-check 5-10 steps
- Primary focus: D7-D9 (Dependency Ordering, Checklists, Spec Alignment)
- Check: Steps in correct order, checklists complete, all spec requirements covered
- Pattern: Sample validation (not exhaustive)

#### **Round 4+: Alternate Patterns**
- **Round 4:** Sequential again (fresh eyes on whole document, all 9 dimensions)
- **Round 5:** Focus on recent changes (did fixes introduce issues?)
- **Round 6:** Cross-dimension validation (do all dimensions pass?)
- **Round 7+:** Deep dive into previously clean dimensions

---

### Example Validation Loop Execution

```text
DRAFT CREATION: 90 minutes
- Created implementation_plan.md with mechanical steps
- Quality estimate: ~70%

─────────────────────────────────────────────────────────
ROUND 1: Sequential read, D1-3 focus (30 min)
─────────────────────────────────────────────────────────
Issues found: 10

Dimension 1 (Step Clarity):
- Step 5 file path vague: "in util folder" → Must specify exact path
- Step 8 has "TODO" in details section

Dimension 2 (Mechanical Executability):
- Step 3 says "add appropriate error handling" → Must specify exact errors
- Step 12 requires design choice: "choose best data structure"

Dimension 3 (File Coverage):
- spec.md mentions score_calculator.py but no step for it
- Missing test file creation step (Testing Approach is Option C)

Action: Fix all 10 issues → implementation_plan.md updated
Clean count: RESET to 0
Next: Round 2

─────────────────────────────────────────────────────────
ROUND 2: Reverse read, D4-6 focus (35 min)
─────────────────────────────────────────────────────────
Issues found: 7

Dimension 4 (Operation Specificity):
- Step 2 EDIT locate string not exact: "find imports" → Must use exact line
- Step 7 CREATE missing function signature details

Dimension 5 (Verification):
- Step 9 verification vague: "check it works" → Must specify what to check
- Step 15 verification subjective: "looks correct"

Dimension 6 (Error Handling):
- Pre-execution checklist missing edge cases
- Step 4 doesn't specify what to do if file not found

Action: Fix all 7 issues → implementation_plan.md updated
Clean count: RESET to 0
Next: Round 3

─────────────────────────────────────────────────────────
ROUND 3: Spot-checks, D7-9 focus (25 min)
─────────────────────────────────────────────────────────
Issues found: 2

Dimension 7 (Dependency Ordering):
- Step 2 edits rank_loader.py but Step 10 creates it → Wrong order

Dimension 9 (Spec Alignment):
- spec.md requirement "Handle item name matching" has no step

Action: Fix all 2 issues → implementation_plan.md updated
Clean count: RESET to 0
Next: Round 4

─────────────────────────────────────────────────────────
ROUND 4: Sequential read, all 9 dimensions (30 min)
─────────────────────────────────────────────────────────
Issues found: 0 ✅

All 9 mechanical dimensions validated:

✅ D1: Step Clarity - All steps unambiguous, exact paths specified
✅ D2: Mechanical Executability - Builder can execute without design choices
✅ D3: File Coverage Completeness - All spec files covered, test files present
✅ D4: Operation Specificity - EDIT locate strings exact, CREATE content complete
✅ D5: Verification Completeness - All verifications mechanical and checkable
✅ D6: Error Handling Clarity - Edge cases documented, failure criteria explicit
✅ D7: Dependency Ordering - Steps in correct execution order
✅ D8: Pre/Post Checklist Completeness - Both checklists complete
✅ D9: Spec Alignment - All spec requirements translated to steps

Clean count: 1 → Triggering sub-agent confirmation
Next: Sub-agent parallel confirmation

─────────────────────────────────────────────────────────
SUB-AGENT CONFIRMATION
─────────────────────────────────────────────────────────
Primary agent declared clean round (counter = 1).
Spawning 2 independent sub-agents in parallel.

Sub-agent A (top-to-bottom read):
Issues found: 0 ✅
All 9 dimensions checked. Confirmed zero issues.

Sub-agent B (bottom-to-top read):
Issues found: 0 ✅
All 9 dimensions checked. Confirmed zero issues.

Both sub-agents confirmed → ✅ PASSED

─────────────────────────────────────────────────────────
VALIDATION LOOP COMPLETE
─────────────────────────────────────────────────────────

Total time: 90 min draft + 120 min validation = 3h 30min
Total rounds: 4 primary + sub-agent confirmation
Total issues fixed: 19
Final quality: 99%+ (validated by sub-agent parallel confirmation)

Next: Present implementation_plan.md to user (Gate 5)
```

---

## 🛑 SPECIAL CASES & PROTOCOLS

### If Validation Loop Exceeds 10 Rounds

**Problem:** Still finding issues after 10 rounds (max limit reached)

**Action:**
1. STOP the validation loop
2. Document all issues found in last 3 rounds
3. Escalate to user with summary:
   - "I've completed 10+ rounds of validation"
   - "Issues continue to be found: [describe pattern]"
   - "Possible causes: [architecture issue? scope too large? unclear requirements?]"
   - "I need guidance on how to proceed"
4. Await user decision

**User Options:**
- Adjust scope (remove some requirements)
- Return to S2 (spec needs refinement)
- Override validation (accept current state)
- Provide additional context/clarification

---

### If spec.md Discrepancies Found (Dimension 9: Spec Alignment)

**Problem:** spec.md contradicts epic notes, EPIC_TICKET.md, or SPEC_SUMMARY.md

**Action:**
1. STOP validation loop immediately
2. Document ALL discrepancies found
3. Report to user with question:
   - "Found discrepancy between spec.md and [source]"
   - "spec.md says: [X]"
   - "[source] says: [Y]"
   - "Which should be correct?"
4. Await user decision
5. After user clarifies: Update spec.md OR implementation_plan.md
6. **RESTART validation loop from Round 1** (spec changes invalidate prior validation)

**Why restart is required:** Spec changes ripple through all implementation steps. Must re-validate everything.

---

### If Draft Quality <70% After 90 Minutes

**Problem:** Phase 1 time limit reached but draft quality below 70%

**Action:**
1. STOP Phase 1 at 90 minutes (do not extend)
2. Document draft quality: "X% complete after 90 min"
3. Proceed to Phase 2 anyway
4. Validation loop will catch missing content (that's its purpose)

**Why this works:** Validation loop systematically finds gaps. Better to start validating at 70% than spend extra time polishing draft to 85%.

---

## ⚠️ COMMON ISSUES & FIXES

### Issue 1: "Can't find all spec requirements in steps"

**Symptom:** Some spec.md requirements have no corresponding implementation steps

**Cause:** Missed requirements during Step 4 (Draft Mechanical Steps)

**Fix:**
- Re-read spec.md completely
- Create implementation steps for missing requirements
- Embed algorithm traceability in step details (reference spec.md sections)
- Verify all requirements covered in Dimension 9 (Spec Alignment)

---

### Issue 2: "Locate strings taking too long to find"

**Symptom:** Spending >30 minutes finding exact locate strings for EDIT operations

**Cause:** Trying to make all locate strings exact in single round

**Fix:**
- In Round 1: Use approximate locate strings (draft quality)
- In Round 2: Make 3-5 most critical locate strings exact
- In Round 3: Make remaining locate strings exact
- Don't block on exactness - spread across rounds

---

### Issue 3: "Fixes introducing new issues"

**Symptom:** Round 4 finds issues in sections that were clean in Round 3

**Cause:** Normal! Fixes can introduce new issues. That's why the primary clean round must find zero issues before triggering sub-agent confirmation.

**Fix:**
- This is expected behavior, not a problem
- Keep fixing issues and re-validating
- Counter resets when issues found (by design)
- Eventually, fixes won't introduce new issues → primary clean round + sub-agent confirmation → exit

---

### Issue 4: "Validation loop stuck at 8-9 rounds"

**Symptom:** Approaching 10 round limit, still finding issues

**Cause:** May indicate fundamental problem (unclear requirements, wrong approach)

**Fix:**
- Before Round 10: Ask yourself "What pattern do I see in recent issues?"
- If same dimension keeps failing: Root cause may be spec clarity issue
- If issues scattered: May need to slow down and be more thorough
- At Round 10: Escalate to user (don't force to continue)

---

### Issue 5: "Unsure if something is an issue"

**Symptom:** Found something that might be wrong, but not sure if it counts as issue

**Cause:** Unclear validation criteria

**Fix:**
- **If in doubt, call it an issue**
- Better to flag and fix than miss a real issue
- Validation loop will catch if fix was unnecessary (next round will be clean)
- Conservative approach: assume everything is wrong until proven right

---

## 🚫 ANTI-PATTERNS TO AVOID

### ❌ Anti-Pattern 1: "Working from Memory"

**Wrong:** "I remember I checked this in Round 1, so I'll skip it in Round 2"

**Right:** Re-read ENTIRE implementation_plan.md every round using Read tool

**Why:** Memory-based validation misses issues. Fresh eyes each round catches what memory overlooks.

---

### ❌ Anti-Pattern 2: "Deferring Minor Issues"

**Wrong:** "This is a minor typo, I'll fix it later" (mark as low priority, continue)

**Right:** Fix ALL issues immediately before next round, no matter how minor

**Why:** "Later" never comes. Small issues compound. Validation loop requires zero deferred issues.

---

### ❌ Anti-Pattern 3: "Stopping at 3 Rounds Total"

**Wrong:** "I've done 3 rounds (found 5, 3, 1 issues), I'm done"

**Right:** Need a primary clean round (zero issues found) then sub-agent confirmation (might be rounds 4, 5, 6+)

**Why:** Exit criteria is a primary clean round + sub-agent confirmation, not just completing N rounds total.

---

### ❌ Anti-Pattern 4: "Batching Fixes"

**Wrong:** "I'll note all issues from Rounds 1-3, then fix them all at once"

**Right:** Fix all issues from Round N immediately before Round N+1

**Why:** Fixes from Round 1 might change what you find in Round 2. Can't batch.

---

### ❌ Anti-Pattern 5: "Skipping Re-Reading After Small Fix"

**Wrong:** "I only changed one line, I don't need to re-read everything"

**Right:** Re-read ENTIRE implementation_plan.md every round (fixes can introduce new issues)

**Why:** One-line fix in Dimension 1 might create issue in Dimension 7 (integration). Must check everything.

---

### ❌ Anti-Pattern 6: "Saying 'Efficiently' or 'Quickly'"

**Wrong:** "I'll efficiently complete this validation round"

**Right:** Follow every step systematically, checking all dimensions

**Why:** "Efficiently" is code for "cutting corners." Validation loop exists to prevent mistakes from cutting corners.

---

## Exit Criteria

### Validation Loop Exit Criteria

**Can ONLY exit when ALL true:**

1. ✅ Primary agent declared a clean round AND both sub-agents independently confirmed zero issues (see sub-agent confirmation protocol below)
2. ✅ The sub-agent confirmation step was completed and both returned zero issues
3. ✅ All 9 dimensions validated in final clean rounds (mechanical validation dimensions)
4. ✅ All mechanical steps and checklists present in implementation_plan.md
5. ✅ Confidence level >= MEDIUM
6. ✅ implementation_plan.md version incremented (v0.1 draft → v1.0 validated)

**If ANY criterion fails:** Continue validation loop

---

### Sub-Agent Confirmation Protocol

When `consecutive_clean = 1` (primary clean round achieved), EXECUTE THE FOLLOWING TASK TOOL CALLS IN A SINGLE MESSAGE:

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues in implementation_plan.md (sub-agent A)</parameter>
  <parameter name="prompt">You are sub-agent A confirming zero issues in implementation_plan.md after primary validation.

**Artifact to validate:** .shamt/epics/requests/{epic_name}/features/{feature_NN}/implementation_plan.md
**Validation dimensions:** All 9 mechanical dimensions from s5_v2_validation_loop.md
**Your task:** Re-read the entire implementation_plan.md from top to bottom and verify ALL dimensions.

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found".

Check: Step clarity, mechanical executability, file coverage, operation specificity, verification completeness, error handling, dependency ordering, checklists, spec alignment.
</parameter>
</invoke>

<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues in implementation_plan.md (sub-agent B)</parameter>
  <parameter name="prompt">You are sub-agent B confirming zero issues in implementation_plan.md after primary validation.

**Artifact to validate:** .shamt/epics/requests/{epic_name}/features/{feature_NN}/implementation_plan.md
**Validation dimensions:** All 9 mechanical dimensions from s5_v2_validation_loop.md
**Your task:** Re-read the entire implementation_plan.md from BOTTOM TO TOP (reverse order) and verify ALL dimensions.

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found".

Check: Step clarity, mechanical executability, file coverage, operation specificity, verification completeness, error handling, dependency ordering, checklists, spec alignment.
</parameter>
</invoke>
```

**Why Haiku?** Sub-agent confirmations are focused verification (70-80% token savings per SHAMT-27). See `reference/model_selection.md`.

**What happens next:**
- Both confirm zero issues → Validation loop complete, proceed to Gate 5 (User Approval) ✅
- Either finds issues → Reset consecutive_clean = 0, fix issues, continue validation loop

---

### Gate 5: User Approval

**Purpose:** Get explicit user sign-off on implementation plan before code execution begins

**Pass Criteria:**
- Validation loop passed (primary clean round + sub-agent confirmation documented)
- Plan Summary section exists with all 5 required fields: files modified/created, approach per component, known risks, implementation phases, first S6 commit scope
- User has reviewed Plan Summary directly (section text shown, not paraphrased)
- User gave explicit approval (said "yes", "approved", "looks good", not silence or partial response)
- Approval timestamp documented in implementation_plan.md

**If fail:**
- Make requested changes
- Re-validate affected dimensions in validation loop
- Update Plan Summary if changes affect approach
- Re-present for approval

**After validation loop passes:**

1. **Update implementation_plan.md:**
   - Add validation completion timestamp
   - Add "Validated: primary clean round + sub-agent confirmation (round X)"
   - Increment version to v1.0

2. **Present to user:**
   - Show the **Plan Summary section** of implementation_plan.md directly; do not paraphrase or summarize verbally
   - The Plan Summary must contain all 5 required fields: files to be modified/created, approach per component, known risks, implementation phases, and first S6 commit scope
   - If Plan Summary section is missing or incomplete: fill it now before presenting
   - State explicitly: "Validation loop passed ({N} primary rounds, sub-agent confirmation complete). Requesting your approval to proceed to S6."
   - Request explicit approval (silence or partial response does not count)

3. **Wait for user response:**
   - If approved: Document approval timestamp, proceed to S6
   - If changes requested: Make changes, re-validate affected dimensions, re-submit

4. **Document approval:**
   - Add "User Approved: [timestamp] by [user]" to implementation_plan.md
   - Update feature README.md Agent Status: "S5 complete, S6 ready"

## 🛑 MANDATORY CHECKPOINT: Gate 5

**Before reading s6_execution.md or writing any implementation code, verify ALL:**

- [ ] Validation loop passed (primary clean round + sub-agent confirmation documented in implementation_plan.md)
- [ ] Plan Summary section exists in implementation_plan.md with all 5 required fields filled
- [ ] Plan Summary was shown to user directly (section text, not a verbal summary)
- [ ] User gave explicit approval (not assumed from silence or a partial response)
- [ ] Approval documented in implementation_plan.md with timestamp
- [ ] Feature README.md Agent Status updated to "S5 complete, S6 ready"

**If ANY item is unchecked:** Do NOT proceed to S6 — complete the missing step first.

**If user requested changes:** Make changes, re-validate affected dimensions, update Plan Summary if needed, re-present for approval.

**Parallel mode behavior:**
If running in parallel S5 mode, do NOT present Gate 5 to the user now. Instead:
- Update STATUS file: `STATUS: WAITING_FOR_SYNC`, `READY_FOR_SYNC: true`, `STAGE: S5`
- Update checkpoint: `status: "WAITING"`, `ready_for_next_stage: true`
- Send completion message to Primary (see `parallel_work/s5_secondary_agent_guide.md` → Completion Signal)
- Primary will run S5-CA (Cross-Plan Alignment) and present a combined Gate 5 to the user for all features together
- You will receive a notification when combined Gate 5 passes; no action needed on your end
- You will receive an S6 activation message from Primary when it is your turn to proceed to S6

---

## 📊 TRACKING & DOCUMENTATION

### Update Agent Status

**After Phase 1 (Draft Creation):**
```markdown
**Stage:** S5 (Implementation Planning)
**Phase:** Phase 2 - Validation Loop
**Progress:** Draft created (70% quality), starting validation
**Last Updated:** [timestamp]
**Current Guide:** stages/s5/s5_v2_validation_loop.md
**Next Action:** Begin validation Round 1
```

**After Each Validation Round:**
```markdown
**Stage:** S5 (Implementation Planning)
**Phase:** Phase 2 - Validation Loop
**Progress:** Round N complete, X issues found and fixed
**Clean Count:** Y (0 = issues found this round; 1 = primary clean round → trigger sub-agent confirmation)
**Last Updated:** [timestamp]
**Next Action:** Round N+1 validation
```

**After Validation Loop Passes:**
```markdown
**Stage:** S5 (Implementation Planning)
**Phase:** Gate 5 - User Approval
**Progress:** Validation loop passed (primary clean round + sub-agent confirmation)
**Quality:** 99%+ (round X primary clean, sub-agents confirmed)
**Last Updated:** [timestamp]
**Next Action:** Present implementation_plan.md for user approval
```

---

### Validation Loop Log

Use `VALIDATION_LOOP_LOG_S5_template.md` to track each round: timestamp, reading pattern, issues found (by dimension), fixes applied, clean count, next action. If session interrupted, log shows exactly where to resume.

---

## 📚 REFERENCE

**Related Guides:**
- `reference/validation_loop_master_protocol.md` - Master validation loop protocol (7 universal dimensions)
- `prompts_reference_v2.md` - Phase transition prompts
- `templates/implementation_plan_template.md` - Starting template
- `templates/VALIDATION_LOOP_LOG_S5_template.md` - Tracking template

---

## Next Phase

**After completing S5 (Implementation Planning):**

- Gate 5 approval received from user
- Implementation plan finalized and user-approved
- Proceed to: `stages/s6/s6_execution.md` (Implementation Execution)

**See also:** `prompts_reference_v2.md` → "Starting S6" prompt

---


**This guide is complete and ready for use. Begin with Phase 1: Draft Creation when S3 is complete (Gate 4.5 passed) and spec.md is finalized. (S4 is deprecated — Test Scope Decision is now Step 0 of S5.)**

---

## Dependency Re-Validation Protocol

**Trigger:** The user informs you that a dependency epic (recorded in this epic's `EPIC_README.md` `## Dependencies` section) has completed and merged.

**When it runs:** After Gate 5 approval and before you begin S6. If multiple dependencies exist, re-validate separately as each one completes — do not batch.

**Scope (not a full S5 redo):**

1. Read the completed dependency's merged code changes. The user should provide the PR URL or commit range — epic artifacts are gitignored and not in git history.
2. Re-read this epic's `implementation_plan.md`.
3. Run a focused validation pass checking only:
   - API/interface changes from the dependency that affect this plan
   - New files or changed file paths referenced in this plan
   - Design decisions made in the dependency that contradict assumptions in this plan
4. If issues found: update the implementation plan accordingly. Do **not** restart all of S5.
5. If a foundational architectural change invalidates the plan's core approach: **STOP and escalate immediately.**

   **ESCALATION PROTOCOL:**
   - Document the architectural issue in the validation loop log with specific details
   - Report to user: "I found foundational architectural change: [specific issue]. Current plan assumes [what was assumed] but implementation requires [what's needed]."
   - **Do not self-repair.** Await user decision:
     - Re-validate against new architecture (user approves changes)
     - Create new design doc (if scope changes significantly)
     - Proceed as-is (user accepts the new approach)
   - Update implementation plan only after explicit user approval
   - A full S5 re-run is NOT the fallback — user judgment is required first.

**What requires a plan update:**
- A function or class this plan calls has changed its signature
- A file this plan references has moved or been deleted
- A data model or schema changed in a way that affects this epic's work
- An architectural decision was made in the dependency that contradicts an assumption in this plan

**What does NOT require a plan update:**
- Line number changes in files this plan references
- New files added by the dependency that this plan doesn't touch
- Formatting or comment changes

**After re-validation:** Update the `Re-Validation Status` field in this epic's `EPIC_README.md` `## Dependencies` table to "Done — {date}", then proceed to S6.
