# SHAMT-30: Architect-Builder Implementation Pattern

**Status:** Draft
**Created:** 2026-04-04
**Branch:** `feat/SHAMT-30`
**Validation Log:** [SHAMT30_VALIDATION_LOG.md](./SHAMT30_VALIDATION_LOG.md)

---

## Problem Statement

Currently, the same agent that performs planning (architecture, design decisions) also executes implementation. This has several inefficiencies:

1. **Token waste:** High-capability models (Sonnet/Opus) used for planning continue running mechanical file edits that don't require deep reasoning
2. **Lack of implementation discipline:** Without rigid step-by-step plans, implementation can drift from the validated design
3. **No clear architect/builder separation:** Planning and building are blurred, making it harder to delegate effectively
4. **Missed optimization opportunity:** SHAMT-27 introduced model delegation, but we don't leverage it for the largest token consumer—implementation execution

**Impact:** Higher costs, slower execution, and risk of implementation drift from validated plans.

**Who is affected:** All Shamt workflows with implementation phases (S2-S6, S9, master dev workflow, code reviews with fixes).

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
- Reads codebase, designs solution, validates approach
- Creates one or more `IMPLEMENTATION_PLAN.md` files with rigid step-by-step instructions
- Each step is a direct file operation: "Edit file X, replace Y with Z" or "Create file A with content B"
- Runs validation loops on the *plan itself* before execution begins
- Creates a handoff package for the builder agent

**Stage 2: Builder (Sub-Agent - Haiku)**
- Receives implementation plan + handoff package via Task tool
- Executes plan steps mechanically in order
- Reports completion or errors back to architect
- Does NOT make design decisions or deviate from plan
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
2. Execute each step in order (Step 1, 2, 3...)
3. Verify each step as specified
4. Report completion or halt on first error
5. DO NOT make design decisions or deviate from plan

**Error Handling:**
- If a step fails, STOP immediately
- Report the error and the step number back to me
- Do not attempt to fix or work around errors

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

This pattern can be used in any phase with significant implementation:
- **S2.P2 (Spec Implementation):** Architect creates plan from spec, builder executes
- **S4 (Code Development):** Architect plans feature implementation, builder writes code
- **S6 (Bug Fixes):** Architect diagnoses + plans fix, builder applies it
- **S9.P3 (Epic Implementation):** Same pattern at epic scale
- **Master dev workflow:** Architect plans guide changes, builder edits files

**When to Use This Pattern:**
- Implementation requires >5 file operations
- Clear plan can be written without needing runtime decisions
- Token savings justify the overhead (large implementations)

**When NOT to Use This Pattern:**
- Exploratory work (debugging, discovery)
- Simple 1-2 file changes
- Implementation requires frequent design decisions based on code inspection

**Rationale:**

This approach:
- Creates explicit separation between thinking (architect) and doing (builder)
- Enables massive token savings (Haiku for 70%+ of implementation work)
- Forces discipline in planning—can't hand off a vague plan
- Validation happens at plan level, not execution level (cheaper)
- Builder failures bubble up cleanly to architect for resolution

**Alternatives considered:**

1. **Keep current pattern, just use Haiku for simple tasks**
   - Rejected: Doesn't force planning discipline, architect still does most work

2. **Natural language handoff instead of structured plan files**
   - Rejected: Harder for Haiku to follow precisely, more room for drift

3. **Builder can make minor decisions autonomously**
   - Rejected: Defeats the purpose—want mechanical execution, not second-guessing

**Recommended approach:** Proposal 1 with structured plan files and strict builder role boundaries.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/guides/reference/implementation_plan_format.md` | CREATE | Reference guide for plan file format |
| `.shamt/guides/reference/architect_builder_pattern.md` | CREATE | Overview of pattern, when to use, handoff mechanics |
| `.shamt/guides/reference/model_selection.md` | MODIFY | Add architect-builder pattern to task catalog |
| `.shamt/guides/stages/s2/s2_p2_spec_implementation.md` | MODIFY | Add optional architect-builder delegation |
| `.shamt/guides/stages/s4/s4_p1_code_development.md` | MODIFY | Add optional architect-builder delegation |
| `.shamt/guides/stages/s6/s6_p1_bug_fixing.md` | MODIFY | Add optional architect-builder delegation |
| `.shamt/guides/stages/s9/s9_p3_epic_implementation.md` | MODIFY | Add optional architect-builder delegation |
| `.shamt/guides/master_dev_workflow/implementation_phase.md` | MODIFY | Add architect-builder pattern guidance |
| `.shamt/guides/templates/implementation_plan_template.md` | CREATE | Copy-paste template for implementation plans |

---

## Implementation Plan

### Phase 1: Core Reference Documentation
Create the foundational reference guides that define the pattern

- [ ] Create `implementation_plan_format.md` with:
  - Plan file structure (pre-checklist, steps, post-checklist)
  - Step format specification (file, operation, details, verification)
  - Examples for CREATE, EDIT, DELETE, MOVE operations
  - Verification best practices
- [ ] Create `architect_builder_pattern.md` with:
  - Pattern overview and rationale
  - When to use vs. when not to use (decision tree)
  - Handoff package format and examples
  - Task tool invocation examples
  - Error handling protocol
  - Token savings calculations
- [ ] Create `implementation_plan_template.md` for copy-paste convenience
- [ ] Commit Phase 1: `feat/SHAMT-30: Add architect-builder pattern reference guides`

### Phase 2: Model Selection Integration
Update model selection guide to include this pattern

- [ ] Read current `.shamt/guides/reference/model_selection.md`
- [ ] Add architect-builder pattern to "Key Workflows" section
- [ ] Add "Implementation Execution (Builder)" to task catalog with Haiku recommendation
- [ ] Add examples to "Task Tool Examples" section
- [ ] Commit Phase 2: `feat/SHAMT-30: Integrate architect-builder pattern into model selection guide`

### Phase 3: Stage Guide Updates
Integrate pattern into workflow guides as an optional delegation strategy

For each affected stage guide:
- [ ] S2.P2: Add "Optional: Architect-Builder Delegation" subsection after planning steps
- [ ] S4.P1: Add delegation guidance for large feature implementations
- [ ] S6.P1: Add delegation option after root cause analysis, before fix implementation
- [ ] S9.P3: Add delegation guidance for epic-scale implementations
- [ ] Master dev workflow: Add architect-builder option to implementation phase
- [ ] Each integration should:
  - Link to `architect_builder_pattern.md` reference
  - Include decision criteria (when to use this pattern)
  - Show handoff package example specific to that stage
  - Maintain "optional" framing—not mandatory for all implementations
- [ ] Commit Phase 3: `feat/SHAMT-30: Add architect-builder delegation to stage guides`

### Phase 4: CLAUDE.md Update
Update master instructions to reflect new pattern

- [ ] Read current `CLAUDE.md`
- [ ] Add architect-builder pattern to "Model Selection" section
- [ ] Note that implementation plans should be validated before handoff
- [ ] Add to "Critical Rules" if appropriate
- [ ] Commit Phase 4: `feat/SHAMT-30: Update CLAUDE.md with architect-builder pattern`

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

1. **Plan validation mechanics:** Should implementation plans go through their own mini validation loop before handoff? Or is architect judgment sufficient?
   - Leaning toward: Optional validation for complex plans, architect judgment for simple ones

2. **Error recovery protocol:** When builder hits an error, should they report back immediately or attempt simple retries?
   - Leaning toward: Report immediately, no autonomous recovery

3. **Nested delegation:** Can a builder spawn its own sub-agents for parallel work, or must all parallelism be planned by architect?
   - Leaning toward: No nested delegation—keep builder role simple

4. **Plan file location:** Where should implementation plans live? Alongside design docs, in a temp directory, or stage-specific locations?
   - Leaning toward: `design_docs/active/SHAMT{N}_IMPLEMENTATION_PLAN.md` for master work, `.shamt/temp/IMPL_PLAN_{epic}.md` for child epic work

5. **Mandatory vs. optional:** Should this pattern be mandatory for implementations >N steps, or always optional with guidance?
   - Leaning toward: Always optional, strong guidance for >10 file operations

---

## Risks & Mitigation

**Risk 1: Overhead doesn't justify savings for small tasks**
- Mitigation: Clear "when to use" guidance, always keep pattern optional

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
