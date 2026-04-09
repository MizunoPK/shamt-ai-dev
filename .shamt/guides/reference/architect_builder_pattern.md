# Architect-Builder Implementation Pattern

**Purpose:** Overview of the architect-builder implementation pattern that separates planning (S5 architect) from execution (S6 builder)

**Last Updated:** 2026-04-06 (SHAMT-32)

---

## Table of Contents

1. [Overview](#overview)
2. [When to Use This Pattern](#when-to-use-this-pattern)
3. [Decision Tree](#decision-tree)
4. [Pattern Mechanics](#pattern-mechanics)
5. [Handoff Package Format](#handoff-package-format)
6. [Error Recovery Protocol](#error-recovery-protocol)
7. [Parallelism Strategy](#parallelism-strategy)
8. [Token Savings Calculation](#token-savings-calculation)
9. [Task Tool Invocation Examples](#task-tool-invocation-examples)
10. [Common Mistakes and How to Avoid Them](#common-mistakes-and-how-to-avoid-them)
11. [Related Documentation](#related-documentation)
12. [Summary](#summary)

---

## Overview

The architect-builder pattern splits implementation into two distinct stages across S5 and S6:

**S5 Phase 1-2 - Architect (Sonnet/Opus):**
- Reads codebase and spec
- Creates mechanical, step-by-step implementation plan (Phase 1)
- Validates plan using 9-dimension validation loop (Phase 2)
- User approves validated plan (Gate 5)

**S6 - Handoff and Execution:**
- S6 Architect receives validated plan from S5
- Creates handoff package
- Spawns Haiku builder agent

**S6 Builder (Haiku):**
- Reads implementation plan from S5
- Executes steps mechanically in sequential order
- Reports completion or errors
- Does NOT make design decisions

**Key Benefit:** 60-70% token savings on implementation execution

---

## When to Use This Pattern

### MANDATORY Usage (S1-S10 Epic Workflow)

The architect-builder pattern is **MANDATORY** for all implementations in the S1-S10 epic workflow:

- **S5/S6 implementation** MUST use this pattern
- No traditional implementation option (architect executing own plan)
- Rationale: The S1-S10 epic workflow is exclusively for non-trivial changes

**Workflow:**
```
S5 Phase 1: Create mechanical implementation plan (direct from spec)
S5 Phase 2: Validate plan (9 dimensions, primary clean + 2 sub-agents)
Gate 5: User approves validated plan
S6: Architect receives validated plan → creates handoff package → spawns Haiku builder → builder executes
```

### Optional Usage (Outside Epic Workflow)

For master dev workflow and ad-hoc work outside S1-S10:

**Use the pattern when:**
- >10 file operations (CREATE, EDIT, DELETE, MOVE)
- Implementation will consume >100K tokens with traditional approach
- Complex dependencies - changes span multiple subsystems
- First-time implementation in unfamiliar codebase section

**Skip the pattern when:**
- 1-5 file changes with straightforward implementation
- Exploratory work (debugging, investigation, understanding codebase)
- Time-sensitive rapid iteration needed
- Prototype/spike code that will be rewritten

---

## Decision Tree

```
Are you in S6 of the S1-S10 epic workflow?
├─ YES → Use architect-builder pattern (MANDATORY)
└─ NO → Are you doing master dev or ad-hoc work?
    └─ YES → Check implementation size:
        ├─ >10 file operations? → Use pattern (RECOMMENDED)
        ├─ Complex dependencies? → Use pattern (RECOMMENDED)
        └─ <5 file operations, simple? → Skip pattern (traditional implementation)
```

---

## Pattern Mechanics

### Stage 1: Architect Creates Plan

**Step 1: Read Spec and Codebase**
- Understand all requirements from spec.md (or design doc for master work)
- Identify all affected files
- Plan exact file operations

**Step 2: Create Implementation Plan**
- Use format from `reference/implementation_plan_format.md`
- Every step is ultra-specific:
  ```markdown
  ### Step 15: Add authentication middleware
  **File:** `src/server.ts`
  **Operation:** EDIT
  **Details:**
  - Locate: `app.use(cors());`
  - Replace with: `app.use(cors());\napp.use(authenticate);`
  **Verification:** Read src/server.ts, confirm authenticate middleware present
  ```
- No design decisions left to builder
- File: `implementation_plan.md` (child) or `SHAMT{N}_IMPLEMENTATION_PLAN.md` (master)

**Step 3: Validate Plan (9 Dimensions)**
- Create validation log: `implementation_plan_validation_log.md`
- Run validation loop checking:
  1. Step Clarity
  2. Mechanical Executability
  3. File Coverage Completeness
  4. Operation Specificity
  5. Verification Completeness
  6. Error Handling Clarity
  7. Dependency Ordering
  8. Pre/Post Checklist Completeness
  9. Spec Alignment
- Exit when: primary clean round + 2 Haiku sub-agents confirm zero issues
- Update plan status to "Validated"

**Step 4: Create Handoff Package**
- Builder instructions (see Handoff Package Format section below)
- Plan location
- Error handling protocol
- Resume instructions (if resuming from partial execution)

**Step 5: Spawn Builder**
```python
Task(
    subagent_type="general-purpose",
    model="haiku",  # CRITICAL: use Haiku for token savings
    description="Execute implementation plan",
    prompt="{handoff package text}"
)
```

---

### Stage 2: Builder Executes Plan

**Builder Responsibilities:**
1. Read implementation plan file
2. Execute each step in sequential order (Step 1, 2, 3...)
3. Verify each step as specified
4. Report completion OR halt on first error
5. Do NOT make design decisions or deviate from plan
6. Do NOT spawn sub-agents or parallelize work

**Execution Flow:**
```
1. Read implementation_plan.md
2. Execute Step 1
3. Run Step 1 verification
4. If verification passes → Continue to Step 2
5. If verification fails → STOP, report error to architect
6. Repeat until all steps complete
7. Report completion to architect
```

**On Success:**
- Builder reports: "All steps completed successfully. Post-execution checklist complete."
- Architect proceeds to next stage (e.g., S7 QC)

**On Error:**
- Builder STOPS immediately
- Builder reports:
  - Step number where error occurred
  - Exact error message received
  - Which verification failed (if applicable)
  - Current state (what was completed before error)
- Architect receives error report and diagnoses

---

## Handoff Package Format

When spawning the builder agent, architect provides this exact format:

```markdown
You are a builder agent. Your role is to execute the implementation plan exactly as specified.

**Plan Location:** `{path/to/implementation_plan.md}`

**Your Responsibilities:**
1. Read the implementation plan file
2. Execute each step in sequential order (Step 1, 2, 3...)
3. Verify each step as specified
4. Report completion or halt on first error
5. DO NOT make design decisions or deviate from plan
6. DO NOT spawn sub-agents or parallelize work

**Error Handling Protocol:**
- If a step fails, STOP immediately - do not proceed to next step
- Report back to architect with:
  - Step number where error occurred
  - Exact error message received
  - Which verification failed (if applicable)
  - Current state (what was completed before error)
- Do NOT attempt retries, fixes, or workarounds
- Do NOT skip failed steps and continue
- Wait for architect instructions

**Resuming from Partial Execution:**
- If architect fixes plan and wants to resume, they will specify:
  - "Execute steps {N} through {M}" (e.g., "Execute steps 15 through 50")
- Start from the specified step number, skip completed steps

**Start by reading the implementation plan, then execute it step by step.**
```

---

## Error Recovery Protocol

When builder encounters an error:

### Builder Action:
1. **STOP execution** immediately
2. **Report error** with full context:
   - Step number: "Error at Step 23"
   - Error message: "ENOENT: no such file or directory, open 'src/missing.ts'"
   - Verification: "Verification failed: Could not read src/missing.ts"
   - State: "Steps 1-22 completed successfully, Step 23 failed"
3. **Wait** for architect instructions

### Architect Action:
1. **Receive error report** from builder
2. **Diagnose root cause:**
   - Plan error? (incorrect file path, missing step)
   - Transient issue? (file lock, timing)
   - Environment issue? (dependency not installed, directory doesn't exist)
3. **Take one of these actions:**
   - **Fix plan:** Update implementation plan, spawn new builder from Step 23
   - **Retry:** Determine transient issue, instruct builder to retry Step 23
   - **Investigate:** Pause implementation, investigate environment/codebase issue

### No Autonomous Recovery

**Builder NEVER:**
- Attempts retries without architect approval
- Makes fixes or workarounds
- Skips failed steps and continues
- Makes design decisions about "what was probably intended"

**Rationale:**
- Keeps builder role maximally simple (mechanical execution only)
- Architect is already running (spawned the builder), so round-trip cost is minimal
- Consistent "report everything" behavior vs. complex retry logic
- Architect has full context to make correct recovery decision

---

## Parallelism Strategy

### Sequential Execution (Default)

Builders execute steps **sequentially only**:
- Step 1 → Step 2 → Step 3 → ...
- No nested delegation
- No sub-agent spawning
- No parallelization logic

**Rationale:** Keeps builder role maximally simple

### Parallel Execution (Architect-Coordinated)

If parallelism is desired, **architect spawns multiple builders**:

**Example:** Feature touches backend, frontend, and tests
```python
# Architect spawns 3 builders in parallel (single message, 3 Task calls)

Task(
    model="haiku",
    description="Execute backend implementation",
    prompt="Execute steps 1-15 from implementation_plan.md (backend section)"
)

Task(
    model="haiku",
    description="Execute frontend implementation",
    prompt="Execute steps 16-30 from implementation_plan.md (frontend section)"
)

Task(
    model="haiku",
    description="Execute test implementation",
    prompt="Execute steps 31-45 from implementation_plan.md (test section)"
)
```

**Architect responsibilities when using parallelism:**
- Partition implementation plan into independent sections
- Ensure no dependencies between partitions (or sequence appropriately)
- Coordinate dependency ordering (e.g., "Builder B starts after Builder A completes Step 10")
- All builders report back to architect independently

**Rationale:**
- Architect has better information for dependency analysis
- Same simple execution model for each builder
- Same error handling protocol regardless of parallelism
- Plan format stays simple (no parallel markers needed)

---

## Token Savings Calculation

### Traditional Approach (Architect Executes)
```
Agent: Sonnet/Opus
Tasks: Read plan + Execute 50 file operations + Verify
Cost: ~150K tokens
```

### Architect-Builder Approach
```
Architect (Sonnet/Opus):
- Read spec: 10K tokens
- Create plan: 15K tokens
- Validate plan: 20K tokens
- Create handoff: 2K tokens
- Spawn builder: 1K tokens
Subtotal: 48K tokens

Builder (Haiku):
- Read plan: 5K tokens
- Execute 50 operations: 10K tokens
- Verify steps: 5K tokens
Subtotal: 20K tokens (but Haiku is ~10x cheaper than Sonnet)

Effective cost: 48K + (20K / 10) = 50K tokens equivalent
Savings: 67% reduction
```

**Real-world savings:** 60-70% for typical implementations

---

## Task Tool Invocation Examples

### Basic Handoff (Sequential Execution)

```python
Task(
    subagent_type="general-purpose",
    model="haiku",
    description="Execute implementation plan",
    prompt="""You are a builder agent. Your role is to execute the implementation plan exactly as specified.

**Plan Location:** `.shamt/epics/EPIC-001/features/auth/implementation_plan.md`

**Your Responsibilities:**
1. Read the implementation plan file
2. Execute each step in sequential order (Step 1, 2, 3...)
3. Verify each step as specified
4. Report completion or halt on first error
5. DO NOT make design decisions or deviate from plan
6. DO NOT spawn sub-agents or parallelize work

**Error Handling Protocol:**
- If a step fails, STOP immediately - do not proceed to next step
- Report back to architect with:
  - Step number where error occurred
  - Exact error message received
  - Which verification failed (if applicable)
  - Current state (what was completed before error)
- Do NOT attempt retries, fixes, or workarounds
- Do NOT skip failed steps and continue
- Wait for architect instructions

**Start by reading the implementation plan, then execute it step by step.**"""
)
```

### Resume from Failed Step

```python
Task(
    subagent_type="general-purpose",
    model="haiku",
    description="Resume implementation from Step 23",
    prompt="""You are a builder agent resuming implementation from a previous failure.

**Plan Location:** `.shamt/epics/EPIC-001/features/auth/implementation_plan.md`

**Resume Instructions:**
- Execute steps 23 through 50 (Steps 1-22 already completed)
- Start at Step 23, skip all prior steps
- Follow same responsibilities and error handling as initial execution

**Your Responsibilities:**
1. Read the implementation plan file
2. Execute steps 23-50 in sequential order
3. Verify each step as specified
4. Report completion or halt on first error
5. DO NOT make design decisions or deviate from plan

**Error Handling Protocol:**
- If a step fails, STOP immediately
- Report: step number, error message, verification status, current state
- Wait for architect instructions

**Start by reading the implementation plan, then execute from Step 23.**"""
)
```

### Parallel Execution (3 Builders)

```python
# Single message with 3 Task calls (parallel execution)

# Builder A - Backend
Task(
    subagent_type="general-purpose",
    model="haiku",
    description="Execute backend implementation (steps 1-15)",
    prompt="""Builder A: Backend implementation.

**Plan:** `.shamt/epics/EPIC-001/features/auth/implementation_plan.md`
**Scope:** Execute steps 1-15 only (backend section)

{Standard builder responsibilities and error handling}
"""
)

# Builder B - Frontend
Task(
    subagent_type="general-purpose",
    model="haiku",
    description="Execute frontend implementation (steps 16-30)",
    prompt="""Builder B: Frontend implementation.

**Plan:** `.shamt/epics/EPIC-001/features/auth/implementation_plan.md`
**Scope:** Execute steps 16-30 only (frontend section)

{Standard builder responsibilities and error handling}
"""
)

# Builder C - Tests
Task(
    subagent_type="general-purpose",
    model="haiku",
    description="Execute test implementation (steps 31-45)",
    prompt="""Builder C: Test implementation.

**Plan:** `.shamt/epics/EPIC-001/features/auth/implementation_plan.md`
**Scope:** Execute steps 31-45 only (test section)

{Standard builder responsibilities and error handling}
"""
)
```

---

## Common Mistakes and How to Avoid Them

### Mistake 1: Architect Executes Own Plan

❌ **Wrong:**
```
S5: Create and validate plan
S6: Architect reads plan and implements directly
```

✅ **Correct:**
```
S5: Create and validate plan
S6: Architect creates handoff → spawns Haiku builder → builder executes
```

**Why:** Pattern only saves tokens if builder (Haiku) executes. Executing your own plan defeats the purpose.

---

### Mistake 2: Vague Implementation Plan

❌ **Wrong:**
```markdown
### Step 5: Add authentication
**File:** `src/server.ts`
**Operation:** EDIT
**Details:** Add authentication middleware
```

✅ **Correct:**
```markdown
### Step 5: Add authentication middleware call
**File:** `src/server.ts`
**Operation:** EDIT
**Details:**
- Locate: `app.use(cors());`
- Replace with: `app.use(cors());\napp.use(authenticate);`
**Verification:** Read src/server.ts, confirm authenticate middleware call after cors
```

**Why:** Builder cannot interpret "Add authentication middleware" - needs exact locate/replace strings.

---

### Mistake 3: Skipping Plan Validation

❌ **Wrong:**
```
Create plan → immediately hand to builder
```

✅ **Correct:**
```
Create plan → validate (9 dimensions, 2 sub-agent confirmations) → hand to builder
```

**Why:** Unvalidated plans lead to builder failures, wasting builder time. Validation is cheaper than retries.

---

### Mistake 4: Builder Makes Design Decisions

❌ **Wrong:**
```
Builder encounters ambiguous step → builder chooses interpretation → executes
```

✅ **Correct:**
```
Builder encounters ambiguous step → builder STOPS → reports to architect → waits
```

**Why:** Builder role is mechanical execution only. Any design decision must come from architect.

---

### Mistake 5: Using Sonnet/Opus for Builder

❌ **Wrong:**
```python
Task(
    model="sonnet",  # or model="opus"
    description="Execute implementation plan",
    ...
)
```

✅ **Correct:**
```python
Task(
    model="haiku",  # CRITICAL: use Haiku for token savings
    description="Execute implementation plan",
    ...
)
```

**Why:** Pattern only saves tokens if builder uses Haiku. Using Sonnet/Opus for execution defeats the purpose.

---

## Related Documentation

- **Plan Format:** `reference/implementation_plan_format.md` - How to write mechanical plans
- **Validation Loop:** `reference/validation_loop_master_protocol.md` - Validation mechanics
- **Model Selection:** `reference/model_selection.md` - SHAMT-27 token optimization
- **S5 Guide:** `stages/s5/s5_v2_validation_loop.md` - Implementation planning phase
- **S6 Guide:** `stages/s6/s6_execution.md` - Execution phase with builder handoff
- **Templates:**
  - `templates/implementation_plan_template.md` - Copy-paste plan template
  - `templates/implementation_plan_validation_log_template.md` - Validation tracking template

---

## Summary

**The architect-builder pattern:**
- ✅ Separates planning (Sonnet/Opus) from execution (Haiku)
- ✅ Saves 60-70% tokens on implementation execution
- ✅ Forces planning discipline through validation
- ✅ Maintains quality through plan validation, not execution monitoring
- ✅ MANDATORY in S1-S10 epic workflow (S6)
- ✅ Optional in master dev workflow and ad-hoc work

**Remember:**
- Plans must be mechanically executable (no design decisions for builder)
- Validate plans before handoff (9 dimensions, 2 sub-agent confirmations)
- Always use `model="haiku"` for builder execution
- Error recovery: builder reports, architect diagnoses and decides
