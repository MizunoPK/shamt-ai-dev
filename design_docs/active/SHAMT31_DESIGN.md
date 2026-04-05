# SHAMT-31: Add Structured Implementation Plans to Shamt Lite

**Status:** Draft
**Created:** 2026-04-05
**Branch:** `feat/SHAMT-31`
**Validation Log:** [SHAMT31_VALIDATION_LOG.md](./SHAMT31_VALIDATION_LOG.md)

---

## Problem Statement

Shamt Lite currently provides 5 core patterns (validation loops, severity classification, discovery, code review, question brainstorming) but lacks **implementation planning guidance**. Users who adopt Shamt Lite for quality workflows have no structured approach for creating mechanical implementation plans.

**Impact of NOT solving this:**
- Shamt Lite users miss out on the 60-70% token savings from the architect-builder pattern (SHAMT-30)
- Implementation work remains unstructured and error-prone
- No systematic way to validate plans before execution
- Gap between "discovery complete" and "start coding" with no planning discipline

**Who is affected:**
- Developers using Shamt Lite for lightweight quality workflows
- Projects that don't need full S1-S10 epic tracking but want implementation discipline
- Users who want standalone implementation planning without the full Shamt framework

**Why it matters:**
The architect-builder pattern (SHAMT-30) proved highly valuable in full Shamt (60-70% token savings, clear separation of planning and execution). Shamt Lite users deserve access to this same discipline in a lightweight, standalone form.

---

## Goals

1. **Add Pattern 6 (Implementation Planning)** to `SHAMT_LITE.template.md` with standalone, executable instructions
2. **Create implementation plan template** in `templates/implementation_plan_lite.template.md`
3. **Maintain Shamt Lite principles:**
   - Standalone and complete (no dependencies on full Shamt)
   - Part 1 contains everything needed to execute the pattern
   - Optional reference files provide depth
4. **Adapt architect-builder pattern for Lite context:**
   - No S1-S10 workflow references
   - No epic tracking requirements
   - Focus on core planning discipline
   - Optional builder handoff (not mandatory like full Shamt)
5. **Keep total file count reasonable** — target ≤12 files total (currently 8 files: 1 main + 3 reference + 4 templates)

---

## Detailed Design

### Proposal 1: Pattern 6 in Main File + Implementation Plan Template

**Description:**

Add Pattern 6 (Implementation Planning) to `SHAMT_LITE.template.md` Part 1 with complete, standalone instructions. Create a companion template file for copy-paste convenience.

**Structure:**
1. **Part 1, Pattern 6** (in SHAMT_LITE.template.md):
   - When to use implementation planning
   - 5-step process: Read spec → Create plan → Validate plan → Execute → Verify
   - Inline format specification (CREATE, EDIT, DELETE, MOVE operations)
   - Simplified 7-dimension validation (adapted from 9 dimensions in full Shamt)
   - Exit criterion: 1 clean round without sub-agent confirmations (simpler than full Shamt's "primary clean + 2 sub-agent confirmations" pattern)
   - Rationale for lighter validation: Implementation plans are narrower scope than discovery docs; single clean round provides sufficient quality assurance
   - Optional builder handoff section (how to use with Task tool)

2. **templates/implementation_plan_lite.template.md**:
   - Copy-paste ready template
   - Pre-Execution Checklist
   - Implementation Steps section with example steps
   - Post-Execution Checklist
   - Notes section

**File Location Convention:**
- Simple single-location approach: `implementation_plan.md` in project root or feature subdirectory
- No master/child complexity (unlike full Shamt)
- Users choose location based on project structure

**Simplified 7 Validation Dimensions** (reduced from 9 for Lite):
1. Step Clarity — Every step has clear action description
2. Mechanical Executability — No design decisions left to executor
3. File Coverage — All affected files listed
4. Operation Specificity — Exact locate/replace strings for EDITs
5. Verification — Each step has verification method
6. Dependency Ordering — Steps in correct sequence
7. Requirements Alignment — All documented requirements (from discovery, user request, or feature brief) covered

**Removed dimensions from full Shamt version:**
- Error Handling Clarity (kept simple for Lite)
- Pre/Post Checklist Completeness (checklists are simpler in Lite)

**Rationale:**
- **Standalone completeness:** Part 1 contains everything needed (format spec inline, validation dimensions explained)
- **Lightweight:** Reduced from 9 to 7 validation dimensions, 1 clean round instead of 3
- **Optional builder handoff:** Full Shamt makes it mandatory, Lite makes it optional
- **Familiar structure:** Follows existing Pattern 1-5 format

**Alternatives considered:**

**Alternative A: Reference file for plan format**
- Create `reference/implementation_plan_format_lite.md`
- Part 1 references it for details
- **Rejected:** Violates "Part 1 is standalone" principle; adds file count

**Alternative B: Skip validation dimensions entirely**
- Just provide template, no validation guidance
- **Rejected:** Validation is core to Shamt Lite's value proposition

**Alternative C: Full architect-builder pattern with mandatory handoff**
- Port SHAMT-30 directly to Lite
- **Rejected:** Too heavyweight for Lite users; mandatory handoff inappropriate without S1-S10 workflow

**Recommended approach:** Proposal 1 — Pattern 6 in main file with simplified validation and optional builder handoff

---

### Proposal 2: Minimal Template Only (No Pattern in Main File)

**Description:**

Add only `templates/implementation_plan_lite.template.md` without Pattern 6 in the main SHAMT_LITE.template.md file. Users discover it in Part 3 (Templates) section.

**Rationale:**
- Keeps SHAMT_LITE.template.md from growing too large
- Template is self-documenting
- Follows "templates are copy-paste convenience" principle

**Rejected because:**
- Breaks "Part 1 is standalone" principle
- No validation guidance means lower quality
- Template alone doesn't teach the discipline
- Inconsistent with Patterns 1-5 which are all in Part 1

---

**Recommended approach:** **Proposal 1** — Full Pattern 6 in Part 1 with validation dimensions and template

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/scripts/initialization/SHAMT_LITE.template.md` | MODIFY | Add Pattern 6 (Implementation Planning) to Part 1, update Part 3 templates section |
| `.shamt/scripts/initialization/templates/implementation_plan_lite.template.md` | CREATE | New copy-paste template for implementation plans |
| `.shamt/scripts/initialization/init_lite.sh` | MODIFY | Add copy command for new template |
| `.shamt/scripts/initialization/init_lite.ps1` | MODIFY | Add copy command for new template (PowerShell) |

**Shamt Lite deployment file count:** 8 → 9 files (within reasonable limits: 1 main + 3 reference + 5 templates)

---

## Implementation Plan

### Phase 1: Design Pattern 6 Content
- [ ] Draft Pattern 6 text for Part 1 (When to use, 5-step process, format specification)
- [ ] Define 7 validation dimensions (adapt from SHAMT-30's 9 dimensions)
- [ ] Write inline examples for CREATE, EDIT, DELETE, MOVE operations
- [ ] Document optional builder handoff (Task tool example)
- [ ] Define exit criterion (1 clean round, not 3)

### Phase 2: Create Implementation Plan Template
- [ ] Design template structure (metadata, checklists, steps format)
- [ ] Add example steps showing all 4 operation types
- [ ] Include inline comments explaining template usage
- [ ] Add verification checklist items

### Phase 3: Update SHAMT_LITE.template.md
- [ ] Insert Pattern 6 in Part 1 after Pattern 5 (before Part 2)
- [ ] Update "5 core patterns" references to "6 core patterns" throughout file (verify exact count during implementation)
- [ ] Add template reference in Part 3 (Templates section)
- [ ] Update table of contents
- [ ] Update "What you get" list (line 19-24)
- [ ] Update Quick Reference section: Add Pattern 6 to "When to use which pattern?" table
- [ ] Add "Implementation Planning Cheat Sheet" to Quick Reference section

### Phase 4: Validation
- [ ] Run design doc validation loop (7 dimensions, primary clean round + 2 sub-agents)
- [ ] Verify inline examples are accurate and executable
- [ ] Test template by creating a real implementation plan
- [ ] Verify SHAMT_LITE.template.md Part 1 remains standalone (no external dependencies)

### Phase 5: Integration Verification
- [ ] Update init_lite.sh: Add copy command for `templates/implementation_plan_lite.template.md` to deployment directory
- [ ] Update init_lite.ps1: Add corresponding PowerShell copy command for the template
- [ ] Verify template does NOT use {{PROJECT_NAME}} variable (plans are feature-scoped, not project-scoped)
- [ ] Optionally add {{DATE}} variable to template "Created" field (if desired)
- [ ] Test init_lite scripts copy new template correctly
- [ ] Confirm deployment file count is 11 files
- [ ] Run implementation validation (5 dimensions)

---

## Validation Strategy

**Primary validation:**
- Design doc validation loop (7 dimensions: Completeness, Correctness, Consistency, Helpfulness, Improvements, Missing proposals, Open questions)
- Exit: Primary clean round + 2 independent sub-agent confirmations

**Implementation validation:**
- After implementation complete, run 5-dimension validation:
  1. Completeness — Pattern 6 fully added, template created
  2. Correctness — Content matches design doc
  3. Files Affected Accuracy — Both files modified/created as specified
  4. No Regressions — Existing Patterns 1-5 unchanged
  5. Documentation Sync — "5 patterns" → "6 patterns" updated everywhere

**Testing approach:**
- Create a real implementation plan using Pattern 6 instructions (manual test)
- Verify 7-dimension validation process works
- Test template copy-paste usability
- Confirm Part 1 standalone principle maintained

**Success criteria:**
1. Pattern 6 content added to Part 1 with complete standalone instructions
2. Template file created and functional
3. SHAMT_LITE.template.md "5 patterns" → "6 patterns" updated (6 locations)
4. Implementation validation passes (5 dimensions)
5. Manual test: Can create and validate a plan using only Part 1 instructions

---

## Open Questions (All Resolved)

All design decisions have been made and documented in the main proposal:

1. **Builder handoff approach:** Optional (documented with Task tool example, but not required)
2. **Validation exit criterion:** 1 clean round without sub-agent confirmations (lighter than full Shamt)
3. **File location convention:** `implementation_plan.md` in project root or feature directory (no master/child complexity)
4. **Builder handoff criteria:** Use when: (1) plan >20 steps, (2) Haiku access available, (3) implementation is mechanical (documented in Risks section line 251)

---

## Risks & Mitigation

**Risk 1: SHAMT_LITE.template.md becomes too large**
- Current size: 1159 lines
- Pattern 6 estimated: ~200-250 lines (similar to Pattern 3: Discovery)
- New total: ~1400 lines
- **Mitigation:** Keep Pattern 6 focused; inline only essential format spec; use concise examples
- **Acceptable because:** File is still under 1500 lines; Part 1 standalone principle is worth the size

**Risk 2: 7 dimensions is still too complex for Lite users**
- Full Shamt has 9 dimensions, we're reducing to 7
- **Mitigation:** Keep dimension explanations simple; provide quick reference checklist
- **Fallback:** Could reduce to 5 dimensions if needed (cut Dependency Ordering, Spec Alignment)

**Risk 3: Users skip validation and just use template**
- Template might be used without validation discipline
- **Mitigation:** Template includes inline reminder to run validation; Part 1 emphasizes validation importance
- **Acceptable because:** Even template usage without validation is better than no structure

**Risk 4: Optional builder handoff confuses users**
- Users may not understand when to use it
- **Mitigation:** Clear "When to use builder handoff" section with decision criteria
- **Decision criteria:** Use handoff if: (1) plan >20 steps, (2) Haiku access available, (3) implementation is mechanical

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-05 | Initial draft created |
