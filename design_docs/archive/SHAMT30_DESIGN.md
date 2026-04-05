# SHAMT-30: Architect-Builder Implementation Pattern

**Status:** Implemented (Ready for Implementation Validation)
**Created:** 2026-04-04
**Implementation Completed:** 2026-04-04
**Branch:** `main` (all phases committed)
**Validation Log:** [SHAMT30_VALIDATION_LOG.md](./SHAMT30_VALIDATION_LOG.md)

---

## Problem Statement

Currently, the same agent that performs planning (architecture, design decisions) also executes implementation. This has several inefficiencies:

1. **Token waste:** High-capability models (Sonnet/Opus) used for planning continue running mechanical file edits that don't require deep reasoning
2. **Lack of implementation discipline:** Without rigid step-by-step plans, implementation can drift from the validated design
3. **No clear architect/builder separation:** Planning and building are blurred, making it harder to delegate effectively
4. **Missed optimization opportunity:** SHAMT-27 introduced model delegation, but we don't leverage it for the largest token consumer—implementation execution

**Impact:** Higher costs, slower execution, and risk of implementation drift from validated plans.

**Who is affected:** S6 implementation execution in the epic workflow, master dev workflow implementations, and ad-hoc implementations outside the epic workflow.

---

## Goals

1. Create a rigid, step-by-step implementation plan format that can be followed mechanically
2. Enable delegation of implementation execution to Haiku-tier agents
3. Separate "architect" (planning/validation) from "builder" (execution) roles clearly
4. Reduce implementation token costs by 60-70% through Haiku delegation
5. Ensure implementation fidelity—builders follow plans exactly as specified
6. Maintain quality through validation loops at architecture phase, not execution phase

---

## Detailed Design

### Proposal 1: Structured Implementation Plan Files with Builder Handoff

**Description:**

Introduce a new two-stage pattern:

**Stage 1: Architect (Main Agent - Sonnet/Opus)**
- Reads codebase, converts spec requirements to mechanical steps
- Creates one or more `IMPLEMENTATION_PLAN.md` files with rigid step-by-step instructions
- Each step is a direct file operation: "Edit file X, replace Y with Z" or "Create file A with content B"
- **MANDATORY:** Runs 9-dimension validation loop on the plan itself before execution begins
- Creates a handoff package for the builder agent

**Stage 2: Builder (Sub-Agent - Haiku)**
- Receives implementation plan + handoff package via Task tool
- Executes plan steps mechanically in **sequential order** (Step 1, 2, 3...)
- Reports completion or errors back to architect
- Does NOT make design decisions or deviate from plan
- Does NOT spawn sub-agents (no nested delegation)
- **Error recovery:** Reports immediately and stops, zero autonomous recovery attempts
- Architect handles any errors or edge cases discovered during execution

**Implementation Plan File Format:**

```markdown
# Implementation Plan: {Feature Name}

**Architect:** {main agent context}
**Created:** {timestamp}
**Validation Status:** Validated | Not Validated

## Pre-Execution Checklist
- [ ] All affected files identified
- [ ] Design validated via validation loop
- [ ] Edge cases documented
- [ ] Rollback strategy defined

## Implementation Steps

### Step 1: {Action}
**File:** `path/to/file.ts`
**Operation:** EDIT
**Details:**
- Locate: `{exact string to find}`
- Replace with: `{exact replacement}`
- Verification: {how to verify this step succeeded}

### Step 2: {Action}
**File:** `path/to/newfile.ts`
**Operation:** CREATE
**Content:**
```
{exact file content}
```
**Verification:** {verification step}

### Step 3: {Action}
...

## Post-Execution Checklist
- [ ] All steps completed without error
- [ ] Verification checks passed
- [ ] Tests run (if applicable)
- [ ] Ready for handoff back to architect
```

**Handoff Package Format:**

When spawning the builder agent, architect provides:
```markdown
You are a builder agent. Your role is to execute the implementation plan exactly as specified.

**Plan Location:** `path/to/IMPLEMENTATION_PLAN.md`

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

**Builder Agent Invocation:**

```python
Task(
    subagent_type="general-purpose",
    model="haiku",  # Key: use cheap model for mechanical execution
    description="Execute implementation plan",
    prompt="{handoff package text} + plan location"
)
```

**Workflow Integration Points:**

This pattern is used in:
- **S6 (Implementation Execution):** MANDATORY for all epic workflow implementations
- **Master dev workflow:** Optional for guide implementations (smaller scale, different context)
- **Ad-hoc work:** Optional for work outside epic workflow

**Mandatory Usage (S1-S10 Epic Workflow):**

The architect-builder pattern is **MANDATORY** for all implementations in the S1-S10 epic workflow:
- S6 implementation execution MUST use this pattern (no traditional implementation option)
- If implementation plan is created and validated, builder handoff is MANDATORY
- NO EXCEPTIONS - no thresholds, no small change exemptions
- Rationale: The S1-S10 epic workflow is exclusively for non-trivial changes

**Optional Usage (Outside Epic Workflow):**

For master dev workflow and ad-hoc work outside S1-S10:
- Pattern is optional but recommended for >10 file operations
- Allows flexibility for quick guide fixes, emergency hotfixes, exploratory work

**Rationale:**

This approach:
- Creates explicit separation between thinking (architect) and doing (builder)
- Enables massive token savings (Haiku for 70%+ of implementation work)
- Forces discipline in planning—can't hand off a vague plan
- Validation happens at plan level, not execution level (cheaper)
- Builder failures bubble up cleanly to architect for resolution

**Error Recovery Protocol:**

When builder encounters an error:

1. **Builder:** Reports immediately with detailed error context (step number, exact error message, verification that failed, current state) and STOPS execution
2. **Architect:** Receives error report and diagnoses root cause (plan error vs. transient issue vs. environment issue)
3. **Architect:** Takes one of these actions:
   - Fix the implementation plan and spawn new builder from failed step
   - Determine it's transient and instruct builder to retry specific step
   - Investigate environment/codebase issue before continuing
4. **No autonomous recovery:** Builder never attempts retries, fixes, or workarounds

**Rationale:**
- Keeps builder role maximally simple (mechanical execution only)
- Architect is already running (spawned the builder), so round-trip cost is minimal
- Consistent "report everything" behavior vs. complex retry logic
- Architect has full context to make correct recovery decision

**Parallelism Strategy:**

Builders execute steps **sequentially only** - no nested delegation or sub-agent spawning.

**If parallelism is desired:**
- Architect spawns multiple builders in parallel
- Each builder receives a partitioned subset of the full plan
- Architect coordinates dependencies between builders
- All builders report back to architect independently
- Same simple execution model for each builder

**Example:** For a feature touching backend, frontend, and tests:
- Builder A: backend file changes (steps 1-15)
- Builder B: frontend file changes (steps 16-30)
- Builder C: test file changes (steps 31-45)
- All spawn in parallel via single architect message with 3 Task tool calls

**Rationale:**
- Keeps builder role maximally simple (no parallelization logic)
- Architect has better information for dependency analysis
- Same error handling model regardless of parallelism
- Plan format stays simple (no parallel markers needed)

**Alternatives considered:**

1. **Keep current pattern, just use Haiku for simple tasks**
   - Rejected: Doesn't force planning discipline, architect still does most work

2. **Natural language handoff instead of structured plan files**
   - Rejected: Harder for Haiku to follow precisely, more room for drift

3. **Builder can make minor decisions autonomously**
   - Rejected: Defeats the purpose—want mechanical execution, not second-guessing

**Recommended approach:** Proposal 1 with structured plan files and strict builder role boundaries.

---

### Proposal 2: Implementation Plan Validation Loop (9 Dimensions)

**Description:**

Implementation plans MUST be validated before builder handoff. This ensures plans are mechanically executable without design decisions.

**Relationship to S5 Validation:**

S5 currently validates implementation plans using 11 dimensions focused on design quality (algorithm traceability, integration gaps, etc.). SHAMT-30 **replaces** those 11 dimensions with these 9 dimensions **focused on mechanical executability**. The new dimensions ensure the plan can be executed by a Haiku builder without design decisions, rather than validating design choices (which are validated in S2 spec creation).

**The 9 Validation Dimensions:**

1. **Step Clarity** - Every step is unambiguous with no interpretation needed, exact file paths and operations specified
2. **Mechanical Executability** - Builder can execute without making design choices, no "figure it out" gaps
3. **File Coverage Completeness** - All files from spec are covered in plan steps, no missing files
4. **Operation Specificity** - EDIT steps have exact locate/replace strings, CREATE steps have full content, DELETE/MOVE operations are precise
5. **Verification Completeness** - Every step has a verification method, verifications are checkable by builder
6. **Error Handling Clarity** - Success/failure criteria explicit for each step, edge cases documented
7. **Dependency Ordering** - Steps are in correct execution order (e.g., create file before editing it), dependencies explicit
8. **Pre/Post Checklist Completeness** - Pre-execution checklist covers all prerequisites, post-execution checklist confirms completion
9. **Spec Alignment** - Implementation plan faithfully translates ALL spec requirements into mechanical steps, no spec requirements missing, no additions beyond spec scope

**Validation Process:**

Following the master validation loop protocol (`reference/validation_loop_master_protocol.md`):

1. Create `IMPLEMENTATION_PLAN_VALIDATION_LOG.md` before Round 1
2. Run validation rounds checking all 9 dimensions systematically
3. Track `consecutive_clean` counter explicitly (starts at 0)
4. A round is clean if: zero issues OR exactly one LOW-severity issue (fixed)
5. A round is NOT clean if: 2+ LOW issues, or any MEDIUM/HIGH/CRITICAL issue (resets `consecutive_clean = 0`)
6. When `consecutive_clean = 1`: spawn 2 Haiku sub-agents in parallel for confirmation
7. Both sub-agents must confirm zero issues to complete validation
8. Update implementation plan status to "Validated"

**Exit Criterion:** Primary clean round (≤1 LOW severity issue) + 2 independent Haiku sub-agents confirm zero issues

**Rationale:**

- Prevents vague plans from reaching builder (saves wasted execution time)
- Validation is cheaper than fixing builder failures (Opus validates once vs. multiple Haiku retries)
- Maintains quality bar consistent with other Shamt validation loops
- Forces architect to think through executability before handoff

**File Locations:**

Implementation plans live alongside the artifact they implement:

**Master work:**
- Implementation plan: `design_docs/active/SHAMT{N}_IMPLEMENTATION_PLAN.md`
- Validation log: `design_docs/active/SHAMT{N}_IMPL_PLAN_VALIDATION_LOG.md`
- Lives alongside design doc during implementation
- Moves to `design_docs/archive/` with design doc when complete

**Child epic work:**
- Implementation plan: `.shamt/epics/{epic}/features/{feature}/implementation_plan.md`
- Validation log: `.shamt/epics/{epic}/features/{feature}/implementation_plan_validation_log.md`
- Lives alongside spec.md, checklist.md, README.md
- Referenced in S10 lessons learned
- Moves to `epics/done/{epic}/` with rest of epic when complete

**Naming convention:**
- Master: `SHAMT{N}_IMPLEMENTATION_PLAN.md` (uppercase, with SHAMT number)
- Child: `implementation_plan.md` (lowercase, standard feature artifact name)

---

### Proposal 3: S2 Spec Validation Enhancement

**Description:**

The architect-builder pattern only works if S2 specs contain complete design/architecture documentation. If specs are incomplete, S5 architects must make design decisions, defeating the purpose of mechanical implementation plans.

**Required Enhancement:**

Add validation dimension to S2 spec creation ensuring specs are **implementation-ready**:

**New/Enhanced S2 Validation Dimension: Design Completeness**
- All architectural decisions documented with rationale
- All algorithm selections made and justified
- All data structures defined with types and schemas
- All interface contracts specified (function signatures, API endpoints)
- All error handling strategies defined
- All edge cases and failure modes addressed
- Spec contains enough detail that S5 implementation planning requires zero design decisions, only translation to file operations

**Integration Points:**
- S2.P2 spec validation workflow
- `.shamt/guides/reference/spec_validation.md`

**Rationale:**

Without this enhancement, S5 architects will encounter design gaps and either:
1. Make design decisions (violating the pattern's premise)
2. Return to S2 for clarification (workflow disruption)
3. Create incomplete implementation plans (builder failures)

Complete S2 specs are a **prerequisite** for effective architect-builder delegation.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/guides/reference/implementation_plan_format.md` | CREATE | Reference guide for plan file format with 9-dimension validation |
| `.shamt/guides/reference/architect_builder_pattern.md` | CREATE | Overview of pattern, when to use, handoff mechanics, validation requirements |
| `.shamt/guides/reference/model_selection.md` | MODIFY | Add architect-builder pattern to task catalog |
| `.shamt/guides/reference/spec_validation.md` | MODIFY | Add "Design Completeness" dimension ensuring specs are implementation-ready |
| `.shamt/guides/stages/s2/s2_p1_spec_creation_refinement.md` | MODIFY | Document requirement for complete design/architecture in specs |
| `.shamt/guides/stages/s2/s2_p2_spec_implementation.md` | MODIFY | Add/enhance "Design Completeness" validation dimension |
| `.shamt/guides/stages/s5/s5_v2_validation_loop.md` | MODIFY | Update to support mechanical implementation plan creation with 9-dimension validation |
| `.shamt/guides/stages/s6/s6_implementation_execution.md` | MODIFY | Make architect-builder pattern MANDATORY for all S6 execution |
| `.shamt/guides/master_dev_workflow/implementation_phase.md` | MODIFY | Add architect-builder pattern guidance |
| `.shamt/guides/templates/implementation_plan_template.md` | CREATE | Copy-paste template for mechanical implementation plans |
| `.shamt/guides/templates/implementation_plan_validation_log_template.md` | CREATE | Template for implementation plan validation logs |

---

## Implementation Plan

### Phase 1: Core Reference Documentation
Create the foundational reference guides that define the pattern

- [ ] Create `implementation_plan_format.md` with:
  - Plan file structure (pre-checklist, steps, post-checklist)
  - Step format specification (file, operation, details, verification)
  - Examples for CREATE, EDIT, DELETE, MOVE operations
  - 9-dimension validation requirements
  - Validation log format and tracking
  - File location conventions (master vs. child)
  - Verification best practices
- [ ] Create `architect_builder_pattern.md` with:
  - Pattern overview and rationale
  - When to use vs. when not to use (decision tree)
  - Validation loop requirement (9 dimensions, exit criteria)
  - Handoff package format and examples
  - Task tool invocation examples
  - Error handling protocol
  - Token savings calculations
- [ ] Create `implementation_plan_template.md` for copy-paste convenience
- [ ] Create `implementation_plan_validation_log_template.md` for validation tracking
- [ ] Commit Phase 1: `feat/SHAMT-30: Add architect-builder pattern reference guides`

### Phase 2: Model Selection Integration
Update model selection guide to include this pattern

- [ ] Read current `.shamt/guides/reference/model_selection.md`
- [ ] Add architect-builder pattern to "Key Workflows" section
- [ ] Add "Implementation Execution (Builder)" to task catalog with Haiku recommendation
- [ ] Add examples to "Task Tool Examples" section
- [ ] Commit Phase 2: `feat/SHAMT-30: Integrate architect-builder pattern into model selection guide`

### Phase 3: S2 Spec Validation Enhancement
Ensure S2 specs are implementation-ready (prerequisite for architect-builder pattern)

- [ ] Read current S2 spec validation workflow (`.shamt/guides/stages/s2/s2_p2_spec_implementation.md`)
- [ ] Read current spec validation reference (`.shamt/guides/reference/spec_validation.md`)
- [ ] Add/enhance "Design Completeness" dimension to S2 validation:
  - All architectural decisions documented
  - All algorithm selections made and justified
  - All data structures defined
  - All interface contracts specified
  - All error handling strategies defined
  - Sufficient detail for mechanical implementation planning
- [ ] Update S2.P1 to document requirement for complete design/architecture in specs
- [ ] Commit Phase 3: `feat/SHAMT-30: Enhance S2 spec validation for implementation-ready specs`

### Phase 4: S5 Implementation Planning Enhancement
Update S5 to support mechanical implementation plan creation and validation

- [ ] Read current S5 v2 validation loop guide (`.shamt/guides/stages/s5/s5_v2_validation_loop.md`)
- [ ] Update S5 Phase 1 (Draft Creation) guidance:
  - Emphasize mechanical step-by-step format
  - Reference implementation plan format guide
  - Show examples of ultra-specific steps (exact locate/replace strings)
- [ ] Update S5 Phase 2 (Validation Loop) to REPLACE current 11 dimensions with 9 dimensions from Proposal 2
- [ ] Document that output is a mechanically executable plan ready for builder handoff
- [ ] Commit Phase 4: `feat/SHAMT-30: Update S5 for mechanical implementation plans with 9-dimension validation`

### Phase 5: S6 Implementation Execution Update
Update S6 to mandate architect-builder pattern for all epic workflow implementations

- [ ] Read current S6 guide
- [ ] Update S6 to reflect MANDATORY builder handoff:
  - S5 produces validated implementation plan
  - S6 receives plan and creates handoff package
  - S6 spawns Haiku builder via Task tool
  - Builder executes plan mechanically
  - Architect handles any errors reported by builder
- [ ] Document no exceptions: all epic workflow implementations use this pattern
- [ ] Show handoff package format for S6 context
- [ ] Commit Phase 5: `feat/SHAMT-30: Make architect-builder pattern mandatory in S6`

### Phase 6: Optional Integration (Master Dev, Ad-hoc)
Add optional architect-builder delegation for non-epic workflow contexts

- [ ] Master dev workflow: Add optional architect-builder pattern guidance
- [ ] Document when to use (>10 file operations) vs. traditional implementation
- [ ] Show handoff package example for master dev context
- [ ] Note that pattern is mandatory in epic workflow, optional elsewhere
- [ ] Commit Phase 6: `feat/SHAMT-30: Add optional architect-builder pattern to master dev workflow`

### Phase 7: CLAUDE.md Update
Update master instructions to reflect new pattern

- [ ] Read current `CLAUDE.md`
- [ ] Add architect-builder pattern to "Model Selection" section
- [ ] Document mandatory usage in S1-S10 epic workflow (S6 execution)
- [ ] Document optional usage in master dev workflow and ad-hoc work
- [ ] Document 9-dimension validation requirement before builder handoff
- [ ] Add to "Critical Rules": "S6 implementation execution MUST use architect-builder pattern"
- [ ] Commit Phase 7: `feat/SHAMT-30: Update CLAUDE.md with architect-builder pattern`

---

## Validation Strategy

**Design Doc Validation (7 dimensions):**
- Run validation loop on this design doc
- Exit criterion: Primary clean round + 2 independent sub-agent confirmations
- Focus areas: Completeness of plan format, correctness of handoff mechanics, consistency with SHAMT-27 model selection

**Implementation Validation (5 dimensions):**
- After Phases 1-4 complete, verify:
  1. All reference guides created with complete content
  2. Model selection guide accurately updated
  3. Stage guide integrations preserve existing workflow, add optional delegation
  4. CLAUDE.md reflects new pattern
  5. No regressions to existing workflows

**Testing approach:**
- Manual test: Create a sample implementation plan for a hypothetical feature
- Manual test: Simulate handoff to Haiku agent using Task tool (dry run)
- Verify plan format enables mechanical execution without design decisions

**Success criteria:**
1. Reference guides provide complete specification for creating and executing plans
2. Stage guides give clear guidance on when to use pattern
3. Template file is copy-paste ready
4. Pattern can be explained to a user in <2 minutes using the reference guides

---

## Open Questions

1. ~~**Plan validation mechanics:**~~ **RESOLVED** - Implementation plans MUST go through 9-dimension validation loop before builder handoff. Exit criterion: primary clean round + 2 Haiku sub-agents confirm zero issues.

2. ~~**Error recovery protocol:**~~ **RESOLVED** - Builder reports immediately and stops, zero autonomous recovery. Error report includes: step number, exact error message, verification that failed, current state. Architect diagnoses and decides: fix plan, retry step, or investigate environment.

3. ~~**Nested delegation:**~~ **RESOLVED** - No nested delegation. Builders execute steps sequentially only, cannot spawn sub-agents. For parallelism: architect spawns multiple builders in parallel with partitioned plans. Keeps builder role maximally simple.

4. ~~**Plan file location:**~~ **RESOLVED** - Plans live alongside the artifact they implement. Master: `design_docs/active/SHAMT{N}_IMPLEMENTATION_PLAN.md` (with design doc). Child: `.shamt/epics/{epic}/features/{feature}/implementation_plan.md` (with spec.md). Plans move to archive/done with parent artifacts when complete.

5. ~~**Mandatory vs. optional:**~~ **RESOLVED** - MANDATORY for S1-S10 epic workflow (all S6 implementations), no exceptions. Optional for master dev workflow and ad-hoc work. Rationale: Epic workflow is for non-trivial changes only; builder handoff is mandatory if pattern is used (no executing your own validated plan).

---

## Risks & Mitigation

**Risk 1: Mandatory usage adds overhead to all S6 implementations**
- Mitigation: Pattern is mandatory only in S1-S10 epic workflow which is exclusively for non-trivial changes where overhead is justified. For master dev and ad-hoc work, pattern remains optional with clear "when to use" guidance (>10 file operations).

**Risk 2: Plans become outdated if codebase changes between planning and execution**
- Mitigation: Execute plans promptly after creation, architect re-validates plan if delays occur

**Risk 3: Builder agents misinterpret plan steps despite rigid format**
- Mitigation: Plan format includes verification steps, builder halts on first unclear instruction

**Risk 4: Pattern adds complexity to already-complex workflow guides**
- Mitigation: Keep integration minimal in stage guides (link to reference, don't duplicate content)

**Risk 5: Builders fail silently or don't report errors clearly**
- Mitigation: Handoff package explicitly instructs: "STOP and report on first error"

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-04 | Initial draft created |
| 2026-04-04 | Added Proposal 2: 9-dimension implementation plan validation loop (mandatory) |
| 2026-04-04 | Added Proposal 3: S2 spec validation enhancement for implementation-ready specs |
| 2026-04-04 | Resolved Open Question 1: Validation loop required before builder handoff |
| 2026-04-04 | Updated Files Affected and Implementation Plan phases to reflect S2 and S5 changes |
| 2026-04-04 | Resolved Open Question 2: Error recovery protocol - report immediately, zero autonomous recovery |
| 2026-04-04 | Resolved Open Question 3: No nested delegation - builders execute sequentially, architect handles parallelism |
| 2026-04-04 | Resolved Open Question 4: Plan file locations - live alongside implemented artifact, archive with parent |
| 2026-04-04 | Resolved Open Question 5: Pattern is MANDATORY for S1-S10 epic workflow (S6), optional for master dev/ad-hoc |
| 2026-04-04 | Validation Round 1: Fixed 5 issues (1 HIGH, 1 MEDIUM, 3 LOW) - clarified affected workflows, S5 dimension replacement, Risk 1, resume protocol |
| 2026-04-04 | Validation Round 2: Fixed 1 issue (1 LOW) - removed redundant resume point from step format. PRIMARY CLEAN ROUND achieved |
| 2026-04-04 | Sub-agent confirmations: Both Haiku sub-agents confirmed zero issues. Design doc validated successfully |
| 2026-04-04 | Status updated from Draft to Validated |
