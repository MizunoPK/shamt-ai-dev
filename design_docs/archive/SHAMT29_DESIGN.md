# SHAMT-29: Model Selection Integration at Execution Points

**Status:** Validated
**Created:** 2026-04-04
**Branch:** `feat/SHAMT-29`
**Validation Log:** [SHAMT29_VALIDATION_LOG.md](./SHAMT29_VALIDATION_LOG.md)

---

## Problem Statement

The SHAMT-27 model selection system is well-designed and documented in `reference/model_selection.md`, but **agents are not using it in practice** because the Task tool syntax is not present at execution points in the workflow guides.

**Current State:**
- `reference/model_selection.md` contains comprehensive guidance (820 lines) with XML examples for Task tool invocation
- Workflow guides show pattern diagrams like "Spawn Haiku → X" in overview sections
- Step-by-step procedures say "spawn 2 sub-agents" but **do not show the actual Task tool call**
- Agents must remember to consult a separate reference document to find the syntax

**Impact:**
- Agents are not spawning sub-agents with proper model delegation
- Token optimization savings (30-50% per workflow) are not being realized
- Sub-agent confirmations are either skipped or use default Sonnet instead of Haiku (95% cost increase)
- The 70-80% savings on confirmations specifically are completely missed

**Root Cause:**
The guides assume agents will:
1. Read the step saying "spawn 2 sub-agents in parallel"
2. Recall that SHAMT-27 exists
3. Navigate to `reference/model_selection.md`
4. Find the relevant example
5. Adapt the XML to their current context
6. Return to the workflow and continue

This is too many indirections at execution time. Agents need the Task tool syntax **at the point where they need to use it**.

**Who is affected:**
- All agents executing validation loops (S1, S2, S5, S7, S8, S9, S10, design doc validation, import validation)
- All agents running guide audits
- All agents performing code reviews
- All agents in discovery phase or other exploratory workflows

**Not affected (workflows that don't spawn sub-agents):**
- Debugging guides (troubleshooting workflows, no validation loops)
- Parallel work guides (coordination protocols, no sub-agent spawning)
- Missed requirement recovery guides (realignment workflows, no sub-agent confirmations)

---

## Goals

1. **Embed Task tool XML examples at every execution point** where model delegation should occur
2. **Make model selection mandatory** (change "can save tokens" to "MUST use this pattern")
3. **Reduce indirection** — agents should not need to consult separate reference docs during workflow execution
4. **Achieve 80%+ adoption** of Haiku for sub-agent confirmations across validation loops
5. **Preserve reference/model_selection.md** as the comprehensive guide while adding execution-point examples

**Success Metrics:**
- Every validation loop guide has embedded Task tool example at sub-agent confirmation step
- Every guide audit section has embedded Task tool example for dimension delegation
- Language changes from "can delegate" to "MUST delegate" with enforcement
- Post-implementation: agents spawn Haiku sub-agents without being prompted

---

## Detailed Design

**Note:** The recommended approach consists of TWO complementary design components, both of which will be implemented together. They are not alternatives — both are required to solve the problem.

### Design Component 1: Inline Task Tool Examples

**Description:**
Add complete, copy-paste-ready Task tool invocation examples directly in the step-by-step sections of workflow guides at the exact point where agents need to spawn sub-agents or delegate work.

**Example Implementation:**

**Before (validation_loop_master_protocol.md:1575-1582):**
```markdown
### Sub-Agent Confirmation Protocol

When `consecutive_clean = 1` (primary clean round achieved):

1. Spawn 2 independent sub-agents in parallel
2. Sub-agent A: Re-reads artifact top-to-bottom, checks all dimensions
3. Sub-agent B: Re-reads artifact bottom-to-top, checks all dimensions
4. Both must report zero issues to complete the exit sequence
```

**After:**
```markdown
### Sub-Agent Confirmation Protocol

When `consecutive_clean = 1` (primary clean round achieved):

**EXECUTE THE FOLLOWING TASK TOOL CALLS IN A SINGLE MESSAGE:**

<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues (sub-agent A)</parameter>
  <parameter name="prompt">You are sub-agent A confirming zero issues after primary validation.

**Artifact to validate:** {artifact_path}
**Validation dimensions:** {list all master + scenario dimensions}
**Your task:** Re-read the entire artifact from top to bottom and verify ALL dimensions.

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found".

See the handoff package below for complete context.

{paste sub-agent handoff package template here}
</parameter>
</invoke>

<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues (sub-agent B)</parameter>
  <parameter name="prompt">You are sub-agent B confirming zero issues after primary validation.

**Artifact to validate:** {artifact_path}
**Validation dimensions:** {list all master + scenario dimensions}
**Your task:** Re-read the entire artifact from BOTTOM TO TOP (reverse order) and verify ALL dimensions.

CRITICAL: Report ANY issue found, even LOW severity. If zero issues found, state "CONFIRMED: Zero issues found".

See the handoff package below for complete context.

{paste sub-agent handoff package template here}
</parameter>
</invoke>

**Why Haiku?** Sub-agent confirmations are focused verification tasks (70-80% token savings with no quality loss). See `reference/model_selection.md` for rationale.

**What happens next:**
- If BOTH sub-agents confirm zero issues → EXIT validation loop ✅
- If EITHER sub-agent finds an issue → Fix immediately, reset consecutive_clean = 0, continue to next round
```

**Rationale:**
- Zero cognitive load — agents see exactly what to execute
- Copy-paste ready with placeholder variables clearly marked
- Embedded justification ("Why Haiku?") reinforces the pattern
- No need to navigate away from workflow guide

**Alternatives considered:**
- **Alternative A: Reference link only** — Current approach, already proven insufficient
- **Alternative B: Separate "Task Tool Examples" section in each guide** — Still requires scrolling/searching, doesn't solve execution-point problem
- **Alternative C: Use code snippets without XML** — Doesn't show actual tool syntax, agents wouldn't know how to invoke

**Why inline examples:** Zero indirection and enables copy-paste execution at the exact point of need.

---

### Design Component 2: Enforcement Language Changes

**Description:**
Change optional/suggestive language to mandatory imperative language throughout guides.

**Before:**
- "can save 40-50% tokens"
- "Use strategic model delegation"
- "See reference/model_selection.md for examples"

**After:**
- "MUST use model delegation (saves 40-50% tokens, mandatory per SHAMT-29)"
- "Execute the Task tool calls below"
- "DO NOT spawn sub-agents without specifying model=haiku (see examples below)"

**Locations for language changes:**
- validation_loop_master_protocol.md (Hard Stop section)
- All stage guides (S1, S2, S5, S7, S8, S9, S10)
- audit/README.md
- code_review/code_review_workflow.md
- design_doc_validation/validation_workflow.md

**Rationale:**
SHAMT is a quality-focused system with mandatory gates. Model selection should be treated the same way — not as an optional optimization, but as a required practice.

**Why both components are needed:**
- Component 1 (inline examples) without Component 2 (enforcement) = agents might still treat it as optional suggestion
- Component 2 (enforcement) without Component 1 (inline examples) = mandatory requirement with no execution support
- Together: Clear mandate + immediate execution support = high adoption rate

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/guides/reference/validation_loop_master_protocol.md` | MODIFY | Add inline Task tool examples at Sub-Agent Confirmation Protocol section (line ~1575); add enforcement language to Hard Stop section (line ~27-35) |
| `.shamt/guides/stages/s1/s1_p3_discovery_phase.md` | MODIFY | Add Task tool examples at validation loop trigger point |
| `.shamt/guides/stages/s2/s2_p1_spec_creation_refinement.md` | MODIFY | Add Task tool examples for sub-agent confirmations |
| `.shamt/guides/stages/s5/s5_v2_validation_loop.md` | MODIFY | Add Task tool examples at Phase 2 validation loop section (line ~530-545) |
| `.shamt/guides/stages/s7/s7_p2_qc_rounds.md` | MODIFY | Add Task tool examples for sub-agent confirmations |
| `.shamt/guides/stages/s9/s9_p2_epic_qc_rounds.md` | MODIFY | Add Task tool examples for sub-agent confirmations |
| `.shamt/guides/stages/s8/s8_p1_cross_feature_alignment.md` | MODIFY | Add Task tool examples for alignment validation sub-agent confirmations |
| `.shamt/guides/stages/s9/s9_p4_epic_final_review.md` | MODIFY | Add Task tool examples at validation sections |
| `.shamt/guides/stages/s10/s10_p1_guide_update_workflow.md` | MODIFY | Add Task tool examples for validation |
| `.shamt/guides/audit/README.md` | MODIFY | Add Task tool examples at round execution section (currently line ~68-109) |
| `.shamt/guides/audit/stages/stage_5_loop_decision.md` | MODIFY | Add Task tool examples for audit sub-agent confirmations |
| `.shamt/guides/code_review/code_review_workflow.md` | MODIFY | Add Task tool examples at Steps 4 and 7 (validation loops) |
| `.shamt/guides/design_doc_validation/validation_workflow.md` | MODIFY | Add Task tool examples for 7-dimension validation sub-agent confirmations |
| `.shamt/guides/sync/import_workflow.md` | MODIFY | Add Task tool examples for post-import validation |
| `.shamt/guides/reference/model_selection.md` | MODIFY | Add note at top: "This is the comprehensive reference. For execution-point examples, see the workflow guides directly." |
| `CLAUDE.md` | MODIFY | Update Model Selection summary to reflect mandatory enforcement |
| `.shamt/scripts/initialization/SHAMT_LITE.template.md` | MODIFY | Add Task tool example for sub-agent confirmations in validation loop section |

**Total:** 17 files modified, 0 created, 0 deleted

---

## Implementation Plan

### Phase 1: Core Validation Loop Integration (Highest Priority)

**Goal:** Embed Task tool examples in the master validation loop protocol and all stage-specific validation loops.

- [ ] Update `validation_loop_master_protocol.md`:
  - [ ] Add Task tool XML example at Sub-Agent Confirmation Protocol section (line ~1575)
  - [ ] Update Hard Stop section (line ~27-35) to add "MUST use Haiku for sub-agent confirmations" with enforcement language
  - [ ] Add enforcement note: "DO NOT spawn sub-agents without model parameter"
- [ ] Update `s1_p3_discovery_phase.md`:
  - [ ] Find validation loop exit criteria section
  - [ ] Add inline Task tool example for spawning 2 Haiku sub-agents
  - [ ] Update enforcement language ("MUST spawn" not "should spawn")
- [ ] Update `s2_p1_spec_creation_refinement.md`:
  - [ ] Add Task tool example at spec validation sub-agent confirmation step
- [ ] Update `s5_v2_validation_loop.md`:
  - [ ] Add Task tool example at Phase 2 validation loop section (line ~530-545)
  - [ ] Update "Model Selection for Token Optimization" section to include inline example
- [ ] Update `s7_p2_qc_rounds.md`:
  - [ ] Add Task tool example for QC validation sub-agent confirmations
- [ ] Update `s9_p2_epic_qc_rounds.md`:
  - [ ] Add Task tool example for epic QC sub-agent confirmations
- [ ] Update `s8_p1_cross_feature_alignment.md`:
  - [ ] Add Task tool example for alignment validation sub-agent confirmations
- [ ] Update `s9_p4_epic_final_review.md`:
  - [ ] Add Task tool example at pr_review_issues validation section
- [ ] Update `s10_p1_guide_update_workflow.md`:
  - [ ] Add Task tool example for lessons learned validation
- [ ] Verify all 8 stage guides have consistent Task tool examples (use same template format)

**Phase 1 Exit Criteria:** All validation loop guides have embedded Task tool examples at sub-agent confirmation steps.

---

### Phase 2: Guide Audit Integration

**Goal:** Embed Task tool examples in guide audit workflow for dimension delegation.

- [ ] Update `audit/README.md`:
  - [ ] Add inline Task tool examples at "Model Selection for Token Optimization" section (line ~68-109)
  - [ ] Show example: Spawn Haiku for pre-audit script execution
  - [ ] Show example: Spawn Haiku for file counting operations
  - [ ] Show example: Spawn Sonnet for structural dimensions
  - [ ] Show example: Spawn 2x Haiku for sub-agent confirmations
  - [ ] Change language from "can save 40-50%" to "MUST use delegation (saves 40-50%)"
- [ ] Update `audit/stages/stage_5_loop_decision.md`:
  - [ ] Add Task tool examples for audit sub-agent confirmations at loop exit step
  - [ ] Use Haiku model for sub-agent confirmations

**Phase 2 Exit Criteria:** Guide audit documentation has embedded examples for all delegation points.

---

### Phase 3: Other Workflows

**Goal:** Add Task tool examples to remaining workflows (code review, design doc validation, import).

- [ ] Update `code_review/code_review_workflow.md`:
  - [ ] Add Task tool example at Step 1 (git operations with Haiku)
  - [ ] Add Task tool example at Step 3 (Sonnet for ELI5 generation)
  - [ ] Add Task tool example at Step 4 (overview validation sub-agents)
  - [ ] Add Task tool example at Step 7 (review validation sub-agents)
- [ ] Update `design_doc_validation/validation_workflow.md`:
  - [ ] Add Task tool examples for 7-dimension validation sub-agent confirmations
  - [ ] Use same format as validation_loop_master_protocol.md for consistency
- [ ] Update `sync/import_workflow.md`:
  - [ ] Add Task tool example for post-import validation loop sub-agents
- [ ] Update `.shamt/scripts/initialization/SHAMT_LITE.template.md`:
  - [ ] Add Task tool example for sub-agent confirmations in validation loop section
  - [ ] Use same format as validation_loop_master_protocol.md for consistency

**Phase 3 Exit Criteria:** All workflow guides with sub-agent spawning have embedded Task tool examples.

---

### Phase 4: Meta Documentation Updates

**Goal:** Update top-level documentation to reflect mandatory enforcement.

- [ ] Update `reference/model_selection.md`:
  - [ ] Add note at top: "IMPORTANT: This is the comprehensive reference guide. Workflow guides contain execution-point examples — use those during active work. Consult this guide for rationale, edge cases, and complete task catalog."
  - [ ] Verify all examples in this file are still accurate
  - [ ] Add cross-references to workflow guides showing inline examples
- [ ] Update `CLAUDE.md`:
  - [ ] Update "Model Selection for Token Optimization (SHAMT-27)" section
  - [ ] Change from "When to Use" to "MUST Use" language
  - [ ] Add note: "As of SHAMT-29, model selection is mandatory at all execution points. See workflow guides for inline Task tool examples."
  - [ ] Update key workflows bullets to emphasize mandatory enforcement

**Phase 4 Exit Criteria:** Meta documentation reflects mandatory status and points to execution examples.

---

### Phase 5: Template Standardization

**Goal:** Create reusable template snippets for consistency across guides.

- [ ] Document standard Task tool template for sub-agent confirmations:
  - [ ] Template for validation loop sub-agents (2x Haiku parallel)
  - [ ] Template for Haiku file operations
  - [ ] Template for Sonnet structural analysis
  - [ ] Template for Opus primary validation
- [ ] Add template section to `reference/model_selection.md` under "Task Tool Examples"
- [ ] Verify all Phase 1-3 implementations use consistent template format

**Phase 5 Exit Criteria:** All guides use standardized Task tool template format.

---

## Validation Strategy

### Design Doc Validation (7 Dimensions)
Run design doc validation loop until primary clean round + 2 independent sub-agent confirmations (using Haiku per SHAMT-27).

**Dimensions to validate:**
1. **Completeness** — Are all execution points identified? All workflow guides with sub-agent spawning listed?
2. **Correctness** — Are Task tool XML examples syntactically correct? Will they work as written?
3. **Consistency** — Do all guides use the same template format? Is terminology consistent?
4. **Helpfulness** — Will this actually solve the adoption problem? Are examples clear enough?
5. **Improvements** — Is there a simpler way to achieve the same goal?
6. **Missing proposals** — Are there execution points we missed? Other workflows not covered?
7. **Open questions** — Any unresolved decisions?

### Implementation Validation (5 Dimensions)
After Phases 1-5 complete, run implementation validation:

1. **Completeness** — Were all 17 files modified as specified? All inline examples added?
2. **Correctness** — Do the Task tool examples match the specification? Are placeholders clearly marked?
3. **Files Affected Accuracy** — Verify Files Affected table is accurate (no files missed, no extra files)
4. **No Regressions** — Did we break any existing workflows? Are validation loops still documented correctly?
5. **Documentation Sync** — Do CLAUDE.md, README.md, and workflow guides align on mandatory enforcement?

### Testing Approach
**Manual verification:**
- Search for "spawn.*sub-agent" across all guides → verify each has inline Task tool example
- Search for "model=haiku" → verify sub-agent confirmations use Haiku
- Search for "can save.*tokens" → verify changed to "MUST use" language
- Read one validation loop guide end-to-end → verify execution flow is clear

**Automated checks:**
- Run grep to verify all validation loop guides contain `<parameter name="model">haiku</parameter>` at sub-agent confirmation sections
- Count instances of inline Task tool examples vs execution points (should be 1:1)

**Success criteria:**
- All 17 files have Task tool examples at execution points
- Zero instances of "spawn sub-agents" without accompanying Task tool XML
- Language enforcement updated in all workflow overviews
- Guide audit passes (3 consecutive clean rounds) after implementation

---

## Open Questions

**Q1:** Should we add Task tool examples for *every* delegation point (including Sonnet/Opus use cases), or focus only on sub-agent confirmations (Haiku)?

**Recommendation:** Focus on sub-agent confirmations (highest ROI, 70-80% savings, used in every validation loop) for Phase 1-3. Add comprehensive examples for all delegation patterns in Phase 5 if time permits.

**Q2:** Should inline examples include the full sub-agent handoff package template, or just reference it?

**Recommendation:** Include a condensed version inline (key fields only) and reference the full template. Balance between copy-paste convenience and guide file size.

**Q3:** Do we update Shamt Lite files as well?

**Recommendation:** Yes, update `SHAMT_LITE.template.md` validation loop section to include inline Task tool example for sub-agent confirmations. Shamt Lite users also benefit from token savings.

---

## Risks & Mitigation

### Risk 1: Guide file size increase
**Impact:** Adding XML examples increases file length, may make guides harder to navigate

**Mitigation:**
- Use collapsible sections or clear headers before Task tool examples
- Keep examples concise (remove unnecessary comments)
- Ensure examples are at the exact point of need, not scattered throughout

### Risk 2: Template drift
**Impact:** If we update Task tool syntax in one guide but not others, inconsistency emerges

**Mitigation:**
- Phase 5 creates standardized templates
- Use grep to find all Task tool examples when updating
- Guide audit will catch inconsistencies (D4 Consistency dimension)

### Risk 3: Agents ignore examples anyway
**Impact:** Even with inline examples, agents may skip them if not explicitly told to execute

**Mitigation:**
- Use imperative language: "EXECUTE THE FOLLOWING TASK TOOL CALLS"
- Add enforcement in Hard Stop sections: "Sub-agent confirmations MUST use model=haiku"
- Include "Why Haiku?" explanation immediately after example to reinforce

### Risk 4: Placeholders not replaced correctly
**Impact:** Agents copy-paste but forget to replace {artifact_path} or {dimensions}

**Mitigation:**
- Use clearly marked placeholders: `{artifact_path}`, `{list dimensions here}`
- Add note above example: "Replace all {placeholders} with actual values"
- Show before/after example in at least one guide

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-04 | Initial draft created |
| 2026-04-04 | Validation completed - Status changed to Validated |
