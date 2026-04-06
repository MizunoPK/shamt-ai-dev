# SHAMT-32: Consolidate S5 to Architect-Builder Pattern Only

**Status:** Draft
**Created:** 2026-04-06
**Branch:** `feat/SHAMT-32`
**Validation Log:** [SHAMT32_VALIDATION_LOG.md](./SHAMT32_VALIDATION_LOG.md)

---

## Problem Statement

SHAMT-30 introduced a critical bug: **naming collision and template confusion** between two different implementation plan formats:

1. **Task-based plan** (S5's original 11-section format): High-level planning with Requirements → Tasks, Algorithm Traceability Matrix, Data Flow, Error Handling, Test Coverage, Performance, Implementation Readiness, Spec Alignment
2. **Mechanical plan** (architect-builder pattern): Step-by-step file operations with exact EDIT/CREATE/DELETE/MOVE instructions

**The bug:**
- S5 guide (line 340) instructs: `cp templates/implementation_plan_template.md` and create a plan with 11 sections
- The actual `implementation_plan_template.md` file contains the **mechanical format** (Step 1, File, Operation, Details, Verification)
- Both plans are called `implementation_plan.md`
- SHAMT-30 design doc (lines 217-222) acknowledges both exist but uses the same filename for both

**Impact:**
- Child projects create **two implementation plans per feature** (one task-based, one mechanical)
- Agents are confused about which format to use when copying the template
- S5 validation (18 dimensions) doesn't match the mechanical plan validation (9 dimensions)
- Template doesn't match S5 instructions (expects 11 sections, gets mechanical steps)

**Who is affected:** All child projects using S1-S10 epic workflow (S5/S6 stages)

**Impact of NOT solving this:**
- Continued confusion and duplicate work in child projects
- Agents waste time creating both plans unnecessarily
- Validation dimensions mismatch causes quality issues
- Template divergence makes guide adoption unpredictable

---

## Goals

1. Eliminate template/filename confusion by consolidating to a single implementation plan format
2. Update S5 to produce ONLY mechanical implementation plans (architect-builder pattern)
3. Replace S5's 18-dimension validation (7 master + 11 task-based) with 9-dimension mechanical validation
4. Remove all references to "task-based" implementation plans from S5/S6 guides
5. Ensure `implementation_plan_template.md` matches what S5 actually produces
6. Maintain mandatory architect-builder pattern usage in S1-S10 epic workflow
7. Ensure child projects create exactly ONE implementation plan per feature

---

## Detailed Design

### Proposal 1: Consolidate S5 to Mechanical-Only Implementation Plans

**Description:**

Rewrite S5 to produce mechanical implementation plans directly, eliminating the task-based intermediate format. The new workflow:

1. **S5 Phase 1 (Draft Creation):** Create mechanical implementation plan using step-by-step file operations
   - Instead of "Requirements → Tasks", directly translate spec requirements to file operations
   - Instead of "Algorithm Traceability Matrix", embed algorithm traceability in step details/verification
   - Instead of "Data Flow", ensure steps follow correct dependency ordering
   - Instead of separate sections, fold all planning concerns into mechanical step format

2. **S5 Phase 2 (Validation Loop):** Validate mechanical plan using 9 dimensions
   - Replace current 18 dimensions (7 master + 11 task-based) with 9 dimensions (from SHAMT-30 Proposal 2)
   - Use `reference/implementation_plan_format.md` as the validation specification
   - Exit criteria remains: primary clean round + 2 Haiku sub-agent confirmations

3. **S6 (Implementation Execution):** Hand off validated mechanical plan to Haiku builder
   - No intermediate translation needed (plan is already mechanical)
   - Builder executes steps sequentially as specified
   - Architect monitors and handles errors

**Changes to S5 Guide Structure:**

**Current S5 Phase 1 (Draft Creation):**
- Step 0: Test Scope Decision
- Step 1: Setup
- Step 2: Requirements → Tasks (15-20 min)
- Step 3: Dependencies Quick Pass (10-15 min)
- Step 4: Algorithm Traceability (15-20 min)
- Step 5: Data Flow (10-15 min)
- Step 6: Error Cases & Edge Cases (10-15 min)
- Step 7: Create Remaining Sections (10-15 min)

**New S5 Phase 1 (Mechanical Draft Creation):**
- Step 0: Test Scope Decision (unchanged - still needed to determine test creation steps)
- Step 1: Setup (copy mechanical template, create validation log)
- Step 2: Spec Analysis & File Identification (15-20 min)
  - Read spec.md completely
  - Identify ALL files to be created/modified/deleted
  - Identify external dependencies and verify interfaces
  - Note algorithmic functions for test creation (from Step 0)
- Step 3: Create Pre-Execution Checklist (5-10 min)
  - List all affected files
  - Document edge cases
  - Define rollback strategy
- Step 4: Draft Mechanical Steps (45-60 min)
  - For EACH spec requirement: translate to file operation steps (CREATE, EDIT, DELETE, MOVE)
  - Include exact file paths, operation types, and verification methods
  - For EDIT operations: include approximate locate strings (exact strings come in validation)
  - For CREATE operations: include function signatures and structure (full content comes in validation)
  - Embed algorithm traceability in step details (e.g., "Step 15: Implement rank multiplier calculation (spec.md Algorithms section, step 3)")
  - Include test creation steps based on Testing Approach from Step 0
- Step 5: Order Steps by Dependency (10-15 min)
  - Ensure steps execute in correct order (create before edit, dependencies first)
  - Add dependency notes in step details where needed
- Step 6: Create Post-Execution Checklist (5 min)
  - Standard verification items

**Current S5 Phase 2 (Validation Loop):**
- 18 dimensions (7 master + 11 implementation planning)
- Dimensions focused on task quality, algorithm matrices, data flow sections, integration tables

**New S5 Phase 2 (Mechanical Validation Loop):**
- 9 dimensions (SHAMT-30 mechanical validation dimensions)
- Dimensions focused on step clarity, mechanical executability, operation specificity, verification completeness

**The 9 Mechanical Validation Dimensions:**

1. **Step Clarity** - Every step unambiguous, exact file paths and operations specified
2. **Mechanical Executability** - Builder can execute without design choices, no "figure it out" gaps
3. **File Coverage Completeness** - All files from spec covered in plan steps, no missing files
4. **Operation Specificity** - EDIT steps have exact locate/replace strings, CREATE steps have full content, DELETE/MOVE precise
5. **Verification Completeness** - Every step has verification method, verifications checkable by builder
6. **Error Handling Clarity** - Success/failure criteria explicit for each step, edge cases documented
7. **Dependency Ordering** - Steps in correct execution order, dependencies explicit
8. **Pre/Post Checklist Completeness** - Pre-execution checklist covers prerequisites, post-execution confirms completion
9. **Spec Alignment** - Plan faithfully translates ALL spec requirements into mechanical steps, no additions beyond spec scope

**Rationale:**

This approach:
- **Eliminates confusion:** One plan format, one template, one validation process
- **Maintains SHAMT-30 intent:** Architect-builder pattern was always meant to be mandatory in S1-S10
- **Simplifies workflow:** No intermediate translation from task-based to mechanical
- **Reduces time:** Eliminates duplicate work (creating two plans)
- **Improves quality:** Validation dimensions match the artifact being validated
- **Token savings maintained:** Still hand off to Haiku builder in S6 (60-70% savings)

**Alternatives considered:**

1. **Keep both formats, rename files**
   - Create `task_based_plan.md` and `mechanical_plan.md`
   - Rejected: Adds complexity, still requires two plans per feature
   - Doesn't align with SHAMT-30's intent (mandatory architect-builder in S1-S10)

2. **Make mechanical plan optional in S5**
   - Produce task-based plan in S5, optionally convert to mechanical before S6
   - Rejected: SHAMT-30 already made architect-builder mandatory in S1-S10
   - Optional conversion contradicts mandatory usage requirement
   - Reintroduces the same confusion about when to use which format

3. **Keep task-based in S5, auto-generate mechanical in S6**
   - S5 produces task-based plan with 11 sections
   - S6 reads task-based plan and generates mechanical plan automatically
   - Rejected:
     - Auto-generation defeats architect-builder validation requirement (mechanical plan MUST be validated)
     - Still requires maintaining two formats and validation dimension sets
     - Adds complexity without solving the core confusion

**Recommended approach:** Proposal 1 (consolidate to mechanical-only)

---

### Proposal 2: Update S2 Design Completeness Validation

**Description:**

SHAMT-30 Proposal 3 added "Design Completeness" as a validation dimension in S2 to ensure specs are implementation-ready (contain complete design/architecture). This was a **prerequisite** for mechanical implementation planning.

With the shift to mechanical-only S5, we need to **strengthen** this dimension to ensure specs contain enough detail for agents to translate directly to file operations.

**New S2 Design Completeness Requirements:**

Specs must include:
- All architectural decisions documented with rationale
- All algorithm selections made and justified with **step-by-step breakdowns**
- All data structures defined with types and schemas
- All interface contracts specified (function signatures, parameters, return types)
- All error handling strategies defined with specific error types
- All edge cases addressed with handling strategies
- **NEW: All file operations identified** (which files will be created/modified, which modules)
- **NEW: All implementation locations specified** (e.g., "Add get_rank_multiplier() method to RecordManager class in [module]/util/RecordManager.py ~line 450")
- Spec contains enough detail that S5 mechanical planning requires **zero design decisions**, only translation to file operations

**Integration Point:** `.shamt/guides/reference/spec_validation.md` and `.shamt/guides/stages/s2/s2_p2_spec_implementation.md`

**Rationale:**

Without complete specs, S5 agents will encounter design gaps when creating mechanical plans and either:
1. Make design decisions (violating the mechanical executability requirement)
2. Create incomplete plans (builder failures)
3. Return to S2 for clarification (workflow disruption)

Strengthening S2 ensures mechanical plans can be created purely from spec content.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/guides/stages/s5/s5_v2_validation_loop.md` | MODIFY | Major rewrite: Replace Phase 1 steps, replace 18 dimensions with 9 dimensions, update examples |
| `.shamt/guides/stages/s5/README.md` | MODIFY | Update overview to reflect mechanical-only approach |
| `.shamt/guides/stages/s6/s6_implementation_execution.md` | MODIFY | Remove "Approach 1: Traditional", architect-builder is only approach |
| `.shamt/guides/reference/implementation_plan_format.md` | MODIFY | Clarify this is THE implementation plan format (not "mechanical" vs "task-based") |
| `.shamt/guides/reference/architect_builder_pattern.md` | MODIFY | Update "When to Use" section - mandatory in S1-S10, remove optional language for epic workflow |
| `.shamt/guides/reference/spec_validation.md` | MODIFY | Strengthen "Design Completeness" dimension per Proposal 2 |
| `.shamt/guides/stages/s2/s2_p1_spec_creation_refinement.md` | MODIFY | Add requirements for file operation identification and implementation locations |
| `.shamt/guides/stages/s2/s2_p2_spec_implementation.md` | MODIFY | Update "Design Completeness" validation dimension with file operations and locations |
| `.shamt/guides/templates/implementation_plan_template.md` | MODIFY | Add header comments clarifying this is the S5 output format |
| `.shamt/guides/templates/VALIDATION_LOOP_LOG_S5_template.md` | MODIFY | Update dimension list from 18 to 9, change dimension names to mechanical validation dimensions |
| `.shamt/guides/reference/model_selection.md` | MODIFY | Update S5 delegation examples to reflect 9 dimensions instead of 18 |
| `CLAUDE.md` | MODIFY | Update "Architect-Builder Pattern" section to clarify S5 produces mechanical plans directly |
| `.shamt/guides/templates/feature_spec_template.md` | MODIFY | Add sections for file operations and implementation locations (supports Proposal 2) |

---

## Implementation Plan

### Phase 1: S2 Spec Validation Enhancement (Prerequisite)
Ensure S2 specs are detailed enough for mechanical S5 planning

- [ ] Read current `.shamt/guides/reference/spec_validation.md`
- [ ] Update "Design Completeness" dimension with:
  - Requirement: All file operations identified (files to create/modify, modules affected)
  - Requirement: All implementation locations specified (file, class/function, approximate line)
  - Requirement: Sufficient detail for zero-design-decision mechanical planning
- [ ] Read current `.shamt/guides/stages/s2/s2_p1_spec_creation_refinement.md`
- [ ] Add guidance for documenting file operations and implementation locations during spec creation
- [ ] Read current `.shamt/guides/stages/s2/s2_p2_spec_implementation.md`
- [ ] Update Design Completeness validation checks to verify file operations and locations are specified
- [ ] Read current `.shamt/guides/templates/feature_spec_template.md`
- [ ] Add sections: "## Implementation Locations" (table: requirement → file → location) and "## File Operations" (table: file → operation type → purpose)
- [ ] Commit Phase 1: `feat/SHAMT-32: Strengthen S2 Design Completeness for mechanical planning`

### Phase 2: S5 Guide Rewrite
Convert S5 from task-based to mechanical-only planning

- [ ] Read current `.shamt/guides/stages/s5/s5_v2_validation_loop.md` completely (all 1532 lines)
- [ ] Create backup: `cp s5_v2_validation_loop.md s5_v2_validation_loop.md.SHAMT32_backup`
- [ ] Rewrite Phase 1 (Draft Creation) with new steps:
  - Step 0: Test Scope Decision (minimal changes - still needed for test step creation)
  - Step 1: Setup (update to reference mechanical template)
  - Step 2: Spec Analysis & File Identification (NEW - replaces old Step 2)
  - Step 3: Pre-Execution Checklist (NEW - replaces old Step 3)
  - Step 4: Draft Mechanical Steps (NEW - replaces old Steps 4-6)
  - Step 5: Order Steps by Dependency (NEW - replaces old Step 7)
  - Step 6: Post-Execution Checklist (NEW)
- [ ] Rewrite Phase 2 (Validation Loop) section:
  - Replace "The 11 Implementation Planning Dimensions" with "The 9 Mechanical Validation Dimensions"
  - Update all dimension descriptions to match `reference/implementation_plan_format.md`
  - Remove references to task-based artifacts (algorithm matrices, data flow diagrams, integration tables)
  - Update round structure examples to show mechanical validation
- [ ] Update "Architect-Builder Pattern Integration" section (lines 187-223):
  - Remove "two approaches" language
  - State that S5 produces mechanical plans directly (no intermediate task-based plan)
  - Remove sentence "Both are called 'implementation_plan.md' but use different formats" (now only one format)
- [ ] Update all examples throughout guide to show mechanical steps instead of tasks
- [ ] Update "Round-by-Round Reading Patterns" section to reference 9 dimensions
- [ ] Update "Example Validation Loop Execution" to show mechanical validation issues
- [ ] Update Anti-Patterns section if any reference task-based planning
- [ ] Update Exit Criteria section: change "All 18 dimensions validated" to "All 9 dimensions validated"
- [ ] Update Sub-Agent Confirmation Protocol: change dimension count from 18 to 9
- [ ] Read current `.shamt/guides/stages/s5/README.md`
- [ ] Update overview to clarify S5 produces mechanical implementation plans (not task-based)
- [ ] Commit Phase 2: `feat/SHAMT-32: Rewrite S5 for mechanical-only planning`

### Phase 3: S6 Guide Simplification
Remove "traditional implementation" option, architect-builder is only approach

- [ ] Read current `.shamt/guides/stages/s6/s6_implementation_execution.md`
- [ ] Remove "Approach 1: Traditional (Architect executes own plan)" section entirely
- [ ] Remove "Approach 2: Architect-Builder Pattern" heading (it's no longer an alternative, it's THE approach)
- [ ] Rewrite guide opening to state: "S6 receives a validated mechanical implementation plan from S5 and hands it off to a Haiku builder agent for execution"
- [ ] Update workflow description to remove choice language ("you can choose", "two options")
- [ ] Ensure guide flows directly from "validated mechanical plan received" to "create handoff package and spawn builder"
- [ ] Commit Phase 3: `feat/SHAMT-32: Make architect-builder mandatory in S6`

### Phase 4: Reference Guide Updates
Update supporting reference guides for consistency

- [ ] Read current `.shamt/guides/reference/implementation_plan_format.md`
- [ ] Remove language distinguishing "mechanical" vs "task-based" (there's only one format now)
- [ ] Update opening to state: "This is THE implementation plan format produced by S5 and executed in S6"
- [ ] Read current `.shamt/guides/reference/architect_builder_pattern.md`
- [ ] Update "When to Use" section:
  - S1-S10 epic workflow: MANDATORY (all S5/S6 implementations) - remove "no exceptions" defensive language since it's now obvious
  - Master dev workflow: Optional (simpler use case)
  - Ad-hoc work: Optional (outside epic workflow)
- [ ] Remove any language about "converting task-based to mechanical" (no conversion needed, S5 produces mechanical directly)
- [ ] Read current `.shamt/guides/reference/model_selection.md`
- [ ] Update S5 delegation examples: change from "18 dimensions" to "9 dimensions"
- [ ] Update task catalog if any entries reference task-based planning
- [ ] Commit Phase 4: `feat/SHAMT-32: Update reference guides for mechanical-only planning`

### Phase 5: Template Updates
Ensure templates match new workflow

- [ ] Read current `.shamt/guides/templates/implementation_plan_template.md`
- [ ] Add header comment at top:
```markdown
<!--
This is the S5 implementation plan template (mechanical format).
S5 produces mechanical plans with step-by-step file operations (CREATE, EDIT, DELETE, MOVE).
This plan is validated using 9 dimensions and handed off to a Haiku builder in S6.
-->
```
- [ ] Verify template structure matches `reference/implementation_plan_format.md`
- [ ] Read current `.shamt/guides/templates/VALIDATION_LOOP_LOG_S5_template.md`
- [ ] Update dimension list from 18 to 9
- [ ] Change dimension names from "D1: Requirements Completeness" to "D1: Step Clarity" (mechanical dimension names)
- [ ] Update round tracking template to reference 9 dimensions
- [ ] Commit Phase 5: `feat/SHAMT-32: Update templates for mechanical planning`

### Phase 6: Master Dev Workflow Integration
Clarify how mechanical planning applies to master dev work

- [ ] Read current `.shamt/guides/master_dev_workflow/implementation_phase.md`
- [ ] Review "architect-builder pattern guidance" section added in SHAMT-30
- [ ] Clarify that mechanical planning is **optional** for master dev workflow (not mandatory like S1-S10)
- [ ] Add decision criteria: use mechanical planning for >10 file operations, unfamiliar codebases, complex dependencies
- [ ] Show example of lightweight master dev work that skips mechanical planning (quick guide fixes, 1-3 file changes)
- [ ] Commit Phase 6: `feat/SHAMT-32: Clarify mechanical planning optional for master dev`

### Phase 7: CLAUDE.md Update
Update master instructions to reflect consolidated approach

- [ ] Read current `CLAUDE.md` sections on S5, S6, and architect-builder pattern
- [ ] Update "Architect-Builder Implementation Pattern (SHAMT-30)" section:
  - Remove language about "two-stage pattern" (architecting then building) - S5 is always architecting
  - State: "S5 produces mechanical implementation plans validated using 9 dimensions"
  - State: "S6 hands off validated mechanical plan to Haiku builder for execution"
  - Remove: "Both plans are called 'implementation_plan.md' but use different formats" (now only one format)
- [ ] Update S5/S6 workflow descriptions if referenced elsewhere in CLAUDE.md
- [ ] Commit Phase 7: `feat/SHAMT-32: Update CLAUDE.md for mechanical-only S5`

### Phase 8: Documentation & Validation Log Template Creation
Create validation log template for this design doc and ensure documentation is complete

- [ ] Create `design_docs/active/SHAMT32_VALIDATION_LOG.md` using design doc validation log template
- [ ] Review all phases above and ensure no files are missing from "Files Affected" table
- [ ] Verify all commit messages use `feat/SHAMT-32:` prefix
- [ ] Commit Phase 8: `feat/SHAMT-32: Add validation log template`

---

## Validation Strategy

**Design Doc Validation (7 dimensions):**
- Run validation loop on this design doc
- Exit criterion: Primary clean round + 2 independent sub-agent confirmations
- Focus areas:
  - Completeness: Are all affected files identified? Is S5 rewrite comprehensive?
  - Correctness: Do the 9 dimensions match SHAMT-30 Proposal 2? Is S2 enhancement appropriate?
  - Consistency: Does this align with SHAMT-30's intent (mandatory architect-builder)?
  - Helpfulness: Does this actually solve the naming collision bug?
  - Improvements: Are there simpler ways to fix this?
  - Missing proposals: Should we consider other approaches?
  - Open questions: Any unresolved decisions?

**Implementation Validation (5 dimensions):**
- After Phases 1-7 complete, verify:
  1. **Completeness:** All proposals implemented, all files in "Files Affected" table modified/created as specified
  2. **Correctness:** S5 guide produces mechanical plans with 9-dimension validation, template matches S5 output, S6 guide has no "traditional approach" option
  3. **Files Affected Accuracy:** Verify each file listed was actually modified/created/moved
  4. **No Regressions:** S5/S6 workflow still produces validated implementation plans, token savings maintained (Haiku builder in S6)
  5. **Documentation Sync:** CLAUDE.md, README.md, and all referenced guides accurately reflect mechanical-only approach

**Testing approach:**
- Manual test: Create a sample mechanical implementation plan following new S5 Phase 1 steps
- Manual test: Run 9-dimension validation on sample plan
- Verify plan format matches `implementation_plan_template.md`
- Verify no references to "task-based" or "11 sections" remain in S5 guide

**Success criteria:**
1. S5 guide produces mechanical implementation plans directly (no intermediate task-based format)
2. `implementation_plan_template.md` matches S5 Phase 1 output format
3. Zero references to "task-based plan" or "11 dimensions" in S5/S6 guides (outside historical context)
4. S2 specs include file operations and implementation locations
5. Child projects create exactly ONE implementation plan per feature (mechanical format)

---

## Open Questions

None at this time. All decisions required for implementation are documented in this design doc.

---

## Risks & Mitigation

**Risk 1: Mechanical plans are more verbose than task-based plans, increasing S5 time**
- Mitigation: Mechanical plans require more precision, but Phase 1 draft creation time remains ~60-90 minutes (same as before). Validation loop may take 1-2 additional rounds (30-60 min), but this eliminates the need for a separate mechanical plan creation step before S6. Net time savings of 1-2 hours by eliminating duplicate work.

**Risk 2: Agents struggle to create mechanical plans directly from specs without task-based intermediate step**
- Mitigation:
  - Strengthen S2 Design Completeness (Proposal 2) ensures specs contain file operations and locations
  - New S5 Phase 1 Step 2 (Spec Analysis & File Identification) provides structured approach to translation
  - Validation loop catches gaps and guides agents toward mechanical precision
  - Agents are already creating mechanical plans in current SHAMT-30 workflow (after task-based), so capability exists

**Risk 3: In-flight child projects using old S5 format encounter breaking changes on next import**
- Mitigation:
  - Add migration note in S5 guide: "If you have existing task-based implementation plans from prior S5 versions, complete them using architect-builder pattern (create mechanical plan from task-based plan). New features should use mechanical-only S5."
  - Document in master CHANGELOG.md: "BREAKING: S5 now produces mechanical implementation plans directly (SHAMT-32)"
  - Child projects on old S5 can finish current epic, then import and adopt new S5 for next epic

**Risk 4: S5 Phase 1 draft creation becomes too complex without task-based structure**
- Mitigation:
  - New S5 Phase 1 steps provide clear structure (6 steps vs previous 7 steps)
  - Step 4 (Draft Mechanical Steps) includes guidance on embedding traceability in step details
  - Validation loop ensures plans are complete and mechanically executable
  - Template provides clear format to follow

**Risk 5: Loss of high-level planning artifacts (algorithm matrices, data flow diagrams, integration tables)**
- Mitigation:
  - These artifacts served as validation evidence in task-based planning
  - Mechanical plans embed this information differently:
    - Algorithm traceability: In step details/verification (e.g., "Step 15 implements spec.md Algorithms section step 3")
    - Data flow: In dependency ordering (steps execute in correct order)
    - Integration: In interface verification (external dependencies verified before use)
  - Validation dimensions ensure completeness without requiring separate artifact sections
  - If high-level overview is needed, Pre-Execution Checklist and step comments provide context

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-06 | Initial draft created |
