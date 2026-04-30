---
name: shamt-architect-builder
description: >
  Implements the two-stage architect-builder pattern: architect (Sonnet/Opus)
  creates a mechanical, step-by-step implementation plan and validates it with a
  9-dimension validation loop, then spawns a Haiku builder agent to execute the
  plan sequentially. Saves 60-70% tokens on implementation execution. Mandatory
  for all S6 implementations; optional for ad-hoc work with >10 file operations.
triggers:
  - "implement using architect-builder"
  - "spawn a builder"
  - "create implementation plan"
  - "use architect-builder pattern"
source_guides:
  - guides/reference/architect_builder_pattern.md
  - guides/reference/implementation_plan_format.md
  - guides/composites/architect_builder_composite.md
master-only: false
version: "1.1 (SHAMT-44)"
---

# Skill: shamt-architect-builder

## Overview

The architect-builder pattern separates planning (expensive model) from execution
(cheap model) for a 60-70% reduction in implementation token cost.

- **Architect (Sonnet/Opus):** reads codebase and spec, creates a mechanically
  executable plan, validates it through a 9-dimension loop, then spawns the builder.
- **Builder (Haiku):** reads the plan and executes each step sequentially in order.
  Makes zero design decisions. Reports any error immediately and waits.

---

## When This Skill Triggers

### Mandatory (S1-S11 Epic Workflow)

All S6 implementations MUST use architect-builder. No exceptions. No option to
have the architect execute its own plan.

```text
S5 Phase 1: Architect creates mechanical implementation plan
S5 Phase 2: Architect validates plan (9 dimensions + 2 Haiku sub-agents)
Gate 5: User approves validated plan
S6: Architect creates handoff package → spawns Haiku builder → builder executes
```

### Optional (Master Dev / Ad-hoc Work)

Use when:
- More than 10 file operations (CREATE, EDIT, DELETE, MOVE)
- Implementation would consume >100K tokens with traditional approach
- Complex dependencies spanning multiple subsystems
- First-time implementation in unfamiliar codebase section

Skip when:
- 1–5 file changes with straightforward implementation
- Exploratory work (debugging, investigation, prototyping)
- Rapid iteration where plan quality matters less than speed

**Decision tree:**
```text
In S6 of S1-S11 epic workflow?
├─ YES → Use architect-builder (MANDATORY)
└─ NO → >10 file ops or complex dependencies?
    ├─ YES → Use architect-builder (RECOMMENDED)
    └─ NO  → Traditional implementation (skip pattern)
```

---

## Protocol

### Stage 1: Architect Creates the Plan

**Step 1 — Read spec and codebase.**
Understand all requirements. Identify every affected file. Plan exact operations.

**Step 2 — Write the implementation plan.**

File naming:
- Master work: `design_docs/active/SHAMT{N}_IMPLEMENTATION_PLAN.md`
- Child epic work: `.shamt/epics/{epic}/features/{feature}/implementation_plan.md`

Every step in the plan must follow this exact format:

```markdown
### Step {N}: {Action Description}
**File:** `path/to/file.ext`
**Operation:** EDIT | CREATE | DELETE | MOVE
**Details:**
{See operation types below}
**Verification:** {Mechanically checkable check — read file, confirm string present,
check file exists/absent, run simple command}
```

**EDIT operation:** Provide exact locate and replace strings. Locate must be
unique in the file. Use explicit `\n` for newlines.
```markdown
**Details:**
- Locate: `import { cors } from 'cors';`
- Replace with: `import { cors } from 'cors';\nimport { authenticate } from './middleware/auth';`
```

**CREATE operation:** Provide complete, ready-to-write file content. All imports,
exports, and types included. Builder cannot fill in placeholder comments.

**DELETE operation:** Confirm file exists first. Verification checks absence.

**MOVE operation:** Specify both source and destination. Verification checks old
path is gone and new path exists.

**Verification rules:**
- Good: "Read src/server.ts, confirm authenticate import present after cors"
- Good: "File src/auth.ts exists, contains authenticate function export"
- Bad: "Check that it works" (vague, requires judgment)
- Bad: "Make sure authentication works" (requires testing, not verification)

**Step 3 — Add pre/post checklists.**
```markdown
## Pre-Execution Checklist
- [ ] All affected files identified
- [ ] Design validated via validation loop
- [ ] Edge cases documented
- [ ] Rollback strategy defined

## Post-Execution Checklist
- [ ] All steps completed without error
- [ ] Verification checks passed
- [ ] Tests run (if applicable)
- [ ] Ready for handoff back to architect
```

### Stage 2: Architect Validates the Plan (9 Dimensions)

Create `implementation_plan_validation_log.md` and run the validation loop.

The 9 dimensions checked every round:

| # | Dimension | Key Question |
|---|-----------|-------------|
| 1 | Step Clarity | Every step unambiguous, exact paths and ops specified, no TBD |
| 2 | Mechanical Executability | Builder can execute with zero design choices |
| 3 | File Coverage Completeness | All files from spec covered, none missing |
| 4 | Operation Specificity | EDIT has exact locate/replace; CREATE has full content |
| 5 | Verification Completeness | Every step has a mechanically checkable verification |
| 6 | Error Handling Clarity | Success/failure criteria explicit; report-to-architect protocol clear |
| 7 | Dependency Ordering | Steps in correct order; files created before edited |
| 8 | Pre/Post Checklist Completeness | Prereqs covered; rollback defined |
| 9 | Spec Alignment | All spec requirements in plan; nothing beyond spec scope |

Exit criterion: primary clean round (consecutive_clean = 1, ≤1 LOW issue fixed)
+ 2 Haiku sub-agents both confirm zero issues. See shamt-validation-loop skill
for full loop mechanics.

**After validation passes:** Set plan status to "Validated."

### Stage 3: Architect Creates Handoff Package

```markdown
You are a builder agent. Your role is to execute the implementation plan exactly
as specified.

**Plan Location:** `{absolute/path/to/implementation_plan.md}`

**Your Responsibilities:**
1. Read the implementation plan file.
2. Execute each step in sequential order (Step 1, 2, 3...).
3. Verify each step as specified.
4. Report completion or halt on first error.
5. DO NOT make design decisions or deviate from the plan.
6. DO NOT spawn sub-agents or parallelize work.

**Error Handling Protocol:**
- If a step fails, STOP immediately. Do not proceed to the next step.
- Report to architect:
  - Step number where error occurred
  - Exact error message received
  - Which verification failed (if applicable)
  - Current state (what completed before error)
- Do NOT attempt retries, fixes, or workarounds.
- Do NOT skip failed steps and continue.
- Wait for architect instructions.

**Resuming from Partial Execution:**
If architect fixes the plan and wants to resume: "Execute steps {N} through {M}".
Start from that step, skip all prior steps.

Start by reading the implementation plan, then execute it step by step.
```

### Stage 4: Architect Spawns Haiku Builder

```python
Task(
    subagent_type="general-purpose",
    model="haiku",  # CRITICAL: Haiku provides 60-70% savings; never use Sonnet/Opus
    description="Execute implementation plan",
    prompt="{handoff package text}"
)
```

### Stage 5: Architect Handles Builder Result

**On success:** Builder reports "All steps completed. Post-execution checklist
complete." Architect proceeds to next stage (e.g., S7 QC).

**On error:** Architect diagnoses root cause:
- Plan error (wrong path, missing step) → fix plan, spawn new builder from
  failed step
- Transient issue (file lock, timing) → instruct builder to retry that step
- Environment issue (dependency missing, directory absent) → resolve environment,
  spawn new builder

**Parallel execution (architect-coordinated only):**
If independent work streams exist, architect can spawn multiple builders in
parallel in a single message. Each builder gets its own step range. Architect
partitions the plan so no cross-builder dependencies exist, or sequences
builders appropriately.

---

## Common Mistakes

**Mistake 1: Architect executes own plan.**
Pattern saves tokens only if Haiku executes. Architect executing its own plan
defeats the purpose.

**Mistake 2: Vague locate strings or incomplete CREATE content.**
"import express" matches multiple lines. "// Implementation here" gives builder
nothing to execute. Every string must be exact and complete.

**Mistake 3: Skipping plan validation.**
Unvalidated plans cause builder failures that cost more to recover from than
the validation would have. Always validate before handoff.

**Mistake 4: Builder makes design decisions.**
If a step is ambiguous, builder STOPS and reports. Builder never chooses an
interpretation and proceeds.

**Mistake 5: Using Sonnet or Opus for the builder.**
Always `model="haiku"`. Using a more expensive model for mechanical execution
defeats the purpose of the pattern.

**Mistake 6: Steps out of dependency order.**
Cannot EDIT a file that doesn't exist. CREATE first, then EDIT.

---

## Exit Criteria

This skill is complete when:

- [ ] Implementation plan is created with all steps in mechanical format
- [ ] Plan is validated (9 dimensions, primary clean round + 2 Haiku sub-agents)
- [ ] Plan status set to "Validated"
- [ ] Handoff package created
- [ ] Haiku builder spawned with `model="haiku"`
- [ ] Builder completes successfully OR architect diagnoses error and either
  fixes plan and re-spawns, or escalates to user

---

## Quick Reference

```
Architect: reads spec + codebase → creates mechanical plan → validates (9D) → spawns Haiku
Builder:   reads plan → executes each step in order → verifies each → reports or halts

Plan operations: CREATE | EDIT | DELETE | MOVE
  EDIT: exact locate string + exact replace string
  CREATE: complete ready-to-write content
  DELETE: confirm exists first; verify absence after
  MOVE: source + destination; verify both states

9 validation dimensions: Step Clarity, Mechanical Executability, File Coverage,
  Operation Specificity, Verification Completeness, Error Handling Clarity,
  Dependency Ordering, Checklist Completeness, Spec Alignment

Builder error protocol: STOP → report step + error + state → wait
Builder NEVER: retries, makes fixes, skips steps, makes design decisions

Model: ALWAYS haiku for builder (model="haiku" parameter)
Savings: 60-70% on implementation execution
```
