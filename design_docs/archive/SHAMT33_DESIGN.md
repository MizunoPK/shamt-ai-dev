# SHAMT-33: Standardize S7/S9 PR Review Using Code Review Framework

**Status:** Implemented
**Created:** 2026-04-07
**Validated:** 2026-04-07
**Implemented:** 2026-04-07
**Branch:** `feat/SHAMT-33`
**Validation Log:** [SHAMT33_VALIDATION_LOG.md](./SHAMT33_VALIDATION_LOG.md)

---

## Problem Statement

S7.P3 (Final Review) and S9.P4 (Epic Final Review) currently use custom PR review checklists (11 categories for S7, 5 categories for S9) that differ structurally from the formal code review workflow in `.shamt/guides/code_review/`. This creates:

1. **Inconsistent review quality:** Different frameworks mean different quality bars across workflows
2. **Redundant category design:** Maintaining 3 separate category systems (11 S7 categories, 5 S9 categories, 12 formal code review categories) increases maintenance burden
3. **Lost learnings:** Improvements to the formal code review framework don't propagate to S7/S9 reviews
4. **Missing implementation verification:** Neither S7 nor S9 PR reviews explicitly validate that implementation matches the validated implementation plan and spec files
5. **Context bias risk:** Reviews performed by the primary agent (who implemented the code) carry implementation bias

**Impact of NOT solving:**
- Lower review quality in S7/S9 compared to formal code reviews
- Implementation drift from plans goes undetected
- Continued maintenance burden for 3 separate systems
- Child projects propagate the inconsistent review patterns

---

## Goals

1. **Unify review structure:** S7.P3 and S9.P4 use the same framework as formal code review (12 review categories + 13 validation dimensions: 7 master + 6 code-review-specific including new Implementation Fidelity dimension)
2. **Eliminate context bias:** Fresh sub-agent performs the review with no prior implementation knowledge
3. **Verify implementation fidelity:** Add explicit dimension validating implementation matches validated plan and spec
4. **Produce actionable artifacts:** Generate review_vN.md with copy-paste-ready PR comments
5. **Enable primary agent response:** Primary agent addresses each review comment systematically
6. **Maintain scope distinction:** S7 reviews feature scope, S9 reviews epic scope (same framework, different focus)

---

## Detailed Design

### Proposal 1: Fresh Sub-Agent Code Review Pattern (Recommended)

**Description:**

Replace the current primary-agent PR review loops in S7.P3 and S9.P4 with a fresh sub-agent code review pattern:

1. **S7.P3 - Feature PR Review:**
   - Primary agent spawns a fresh sub-agent (Opus) with no prior context
   - Sub-agent runs code review workflow against the feature branch
   - Sub-agent produces `review_v1.md` with severity-tagged comments
   - Primary agent reads the review and addresses each comment (fix code, document decision, or escalate to user)
   - No overview.md creation/validation (skip Steps 3-4 of formal workflow)

2. **S9.P4 - Epic PR Review:**
   - Primary agent spawns a fresh sub-agent (Opus) with no prior context
   - Sub-agent runs code review workflow against the epic branch
   - Sub-agent produces `review_v1.md` with epic-scoped comments
   - Primary agent reads the review and addresses each comment
   - No overview.md creation/validation

3. **New Dimension - Implementation Fidelity:**
   - Add 13th dimension to code review validation: "Implementation Fidelity"
   - Verifies every proposal in the implementation plan has corresponding code
   - Verifies spec requirements are fully addressed
   - Catches implementation drift, missing features, scope creep

**Rationale:**

- **Fresh perspective:** Sub-agent has zero implementation bias (doesn't remember design decisions, shortcuts, or assumptions)
- **Proven framework:** Reuses battle-tested code review framework (12 review categories + 12 validation dimensions, expanding to 13 for S7/S9)
- **Actionable output:** review_vN.md format is already copy-paste-ready and familiar
- **Token efficiency:** Skipping overview.md saves ~20-30% of review tokens
- **Implementation verification:** New dimension explicitly validates plan adherence
- **Consistent quality:** All Shamt PR reviews now use same quality bar

**Alternatives considered:**

- **Alternative A - Hybrid approach (keep current categories, add sub-agent):**
  - Keep S7's 11 categories and S9's 5 categories
  - Add fresh sub-agent execution
  - Rejected: Doesn't solve the inconsistency or maintenance burden

- **Alternative B - Primary agent with mandatory re-read:**
  - Keep primary agent as reviewer
  - Add mandatory context refresh steps (re-read spec, re-read plan)
  - Rejected: Cannot eliminate implementation bias (agent remembers design decisions even after re-reading)

**Recommended approach:** Proposal 1 (Fresh Sub-Agent Code Review Pattern)

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/guides/stages/s7/s7_p3_final_review.md` | MODIFY | Replace Step 1 (PR Review Validation Loop) with fresh sub-agent code review pattern; remove 11-category checklist |
| `.shamt/guides/stages/s9/s9_p4_epic_final_review.md` | MODIFY | Replace Step 6 (Epic Final Review) with fresh sub-agent code review pattern; remove 5-category checklist; add epic-scope focus guidance |
| `.shamt/guides/code_review/code_review_workflow.md` | MODIFY | Add S7/S9 variant usage section; add Dimension 13 (Implementation Fidelity) to Step 7 validation dimensions for S7/S9 contexts |
| `.shamt/guides/code_review/s7_s9_code_review_variant.md` | CREATE | Document S7/S9 code review variant (skip overview.md, include Dimension 13, scope guidance) |
| `.shamt/guides/code_review/output_format.md` | MODIFY | Document S7/S9 usage pattern (no overview.md requirement) |
| `.shamt/guides/reference/severity_classification_universal.md` | N/A | No changes (already used by code review workflow) |
| `.shamt/scripts/initialization/RULES_FILE.template.md` | MODIFY | Update S7.P3 and S9.P4 descriptions to reference code review framework |

---

## Implementation Plan

### Phase 1: Add Implementation Fidelity Dimension

**Goal:** Extend code review validation with implementation verification

- [ ] Read `code_review/code_review_workflow.md` Step 7 to understand code-review-specific dimension structure
- [ ] Add Dimension 13 (Implementation Fidelity) as a code-review-specific dimension:
  - **What to check:** Every proposal in validated implementation plan has corresponding code changes
  - **What to check:** All spec requirements are addressed in implementation
  - **What to check:** No scope creep (no features not in spec)
  - **What to check:** No missing features (all spec requirements implemented)
  - **Context:** S7/S9 reviews only (not formal external reviews)
- [ ] Add dimension to validation counter rules (clean round = ≤1 LOW across all 13 dimensions for S7/S9 reviews)
- [ ] Update dimension count in Step 7: "13 dimensions (7 master + 6 code-review-specific)" for S7/S9 contexts

**Success criteria:** Dimension 13 definition complete, integrated into code review validation loop as code-review-specific dimension for S7/S9 contexts

---

### Phase 2: Create S7/S9 Code Review Variant Guide

**Goal:** Document how to use code review workflow for S7/S9 contexts

- [ ] Create `.shamt/guides/code_review/s7_s9_code_review_variant.md`:
  - When to use (S7.P3, S9.P4)
  - Differences from formal code review (skip overview.md, add Dimension 13)
  - Fresh sub-agent invocation pattern
  - Primary agent comment response protocol
  - Scope distinctions (S7 = feature scope, S9 = epic scope)
- [ ] Add Task tool examples for spawning sub-agent with code review prompt
- [ ] Document comment addressing workflow (read review_v1.md, fix/document/escalate each comment)

**Success criteria:** Variant guide complete, validated, ready for S7/S9 integration

---

### Phase 3: Update S7.P3 to Use Code Review Framework

**Goal:** Replace S7.P3 Step 1 with fresh sub-agent code review pattern

- [ ] Read current `stages/s7/s7_p3_final_review.md` Step 1
- [ ] Replace Step 1 (PR Review Validation Loop) with:
  - **Step 1a:** Spawn fresh sub-agent (Opus) to run code review
  - **Step 1b:** Sub-agent executes code review workflow (skip overview.md, include Dimension 13)
  - **Step 1c:** Primary agent reads review_v1.md
  - **Step 1d:** Primary agent addresses each comment (fix/document/escalate)
- [ ] Remove 11-category checklist section (Categories 1-11)
- [ ] Update Critical Rules to reference code review framework
- [ ] Update Prerequisites to reference validated implementation plan availability
- [ ] Add reference link to `code_review/s7_s9_code_review_variant.md`

**Success criteria:** S7.P3 uses code review framework, old 11-category system removed

---

### Phase 4: Update S9.P4 to Use Code Review Framework

**Goal:** Replace S9.P4 Step 6 with fresh sub-agent code review pattern

- [ ] Read current `stages/s9/s9_p4_epic_final_review.md` Step 6
- [ ] Replace Step 6 (Epic Final Review) with:
  - **Step 6a:** Spawn fresh sub-agent (Opus) to run epic-scoped code review
  - **Step 6b:** Sub-agent executes code review workflow with epic-scope guidance (skip overview.md, include Dimension 13, focus on cross-feature concerns)
  - **Step 6c:** Primary agent reads review_v1.md
  - **Step 6d:** Primary agent addresses each comment
- [ ] Remove 5-category checklist section (Categories 1-5)
- [ ] Add epic-scope guidance (focus on cross-feature integration, architecture coherence, not per-feature code quality)
- [ ] Update Critical Rules to reference code review framework
- [ ] Add reference link to `code_review/s7_s9_code_review_variant.md`

**Success criteria:** S9.P4 uses code review framework, old 5-category system removed, epic-scope distinction preserved

---

### Phase 5: Update Code Review Workflow for S7/S9 Context

**Goal:** Document S7/S9 usage in formal code review guides

- [ ] Read `code_review/code_review_workflow.md`
- [ ] Add section "S7/S9 Variant Usage" before Step 1:
  - When invoked from S7.P3 or S9.P4
  - Skip Steps 3-4 (overview.md creation/validation)
  - Include Dimension 13 in Step 7 validation
  - Proceed: Step 1 → Step 2 → Step 5 → Step 6 → Step 7 (with 13 dimensions)
- [ ] Update Step 7 dimension table to include Dimension 13 (conditionally for S7/S9)
- [ ] Update `code_review/output_format.md` to note S7/S9 reviews don't produce overview.md

**Success criteria:** Code review workflow documents S7/S9 variant, step sequence clear

---

### Phase 6: Update RULES_FILE Template

**Goal:** Propagate S7/S9 changes to child projects via init template

- [ ] Read `scripts/initialization/RULES_FILE.template.md`
- [ ] Update S7.P3 description (line ~180-200) to reference code review framework
- [ ] Update S9.P4 description (line ~220-240) to reference code review framework
- [ ] Remove references to "11 categories" and "5 categories"
- [ ] Add note: "S7/S9 PR reviews use the code review framework (12 review categories + 13 validation dimensions: 7 master + 6 code-review-specific including Implementation Fidelity)"

**Success criteria:** RULES_FILE template updated, will propagate on next child project init

---

## Validation Strategy

**Primary validation:** Design doc validation loop (7 dimensions)
- Run validation loop until primary clean round + 2 independent sub-agents confirm zero issues
- Track consecutive_clean explicitly
- See `design_doc_validation/validation_workflow.md`

**Implementation validation:** After Phases 1-6 complete (5 dimensions)
- Completeness: All proposals implemented (walk through proposal list)
- Correctness: Implementation matches design (check file contents, dimension definitions)
- Files Affected Accuracy: All files in table above created/modified
- No Regressions: Existing code review workflow still works for formal reviews
- Documentation Sync: CLAUDE.md, master_dev_workflow.md reflect new system

**Testing approach:**
1. **Manual validation:** Read updated S7.P3 and S9.P4 guides end-to-end, verify clarity
2. **Cross-reference check:** Verify code review workflow references are accurate
3. **Dimension integration check:** Verify Dimension 13 appears in correct validation loops
4. **Full guide audit:** Run guide audit on entire `.shamt/guides/` tree (3 consecutive clean rounds required)

**Success criteria:**
- Design doc validation achieves primary clean round + 2 sub-agent confirmations
- Implementation validation achieves primary clean round + 2 sub-agent confirmations
- Full guide audit achieves 3 consecutive clean rounds
- All files in "Files Affected" table have expected changes

---

## Design Decisions

**The following decisions were made during validation:**

### Decision 1: S9.P4 Category Scope
**Chosen:** Full 12 categories (same as S7, but with epic-scope interpretation)

**Rationale:** Simpler to maintain one category list. Sub-agent naturally skips categories with no epic-level findings. Avoids creating divergent category systems for S7 vs S9.

---

### Decision 2: Dimension 13 Scope
**Chosen:** S7/S9 only (not added to formal code reviews)

**Rationale:** Formal code reviews are for external PRs that don't have implementation plans. Dimension 13 (Implementation Fidelity) requires validated implementation plans to check against, which only exist in Shamt S1-S10 workflow contexts.

---

### Decision 3: Comment Addressing Policy
**Chosen:** BLOCKING/CONCERN must fix; SUGGESTION/NITPICK walk through with user

**Comment Response Protocol:**
- **BLOCKING comments:** Must be fixed before proceeding (correctness bugs, security issues, data-loss risks)
- **CONCERN comments:** Must be fixed before proceeding (real quality/performance/maintainability problems)
- **SUGGESTION comments:** Walk through with user one-by-one for judgment call (optional improvements)
- **NITPICK comments:** Walk through with user one-by-one for judgment call (minor style/preference)

**Implementation:** S7.P3 and S9.P4 guides will include explicit step: "For each SUGGESTION/NITPICK comment, present to user with context and ask: Fix, Document as 'acknowledged/won't fix', or Escalate?"

---

## Risks & Mitigation

**Risk 1: Sub-agent doesn't understand epic/feature context**
- **Mitigation:** Provide sub-agent with explicit context in prompt (spec files, implementation plan, branch name, scope guidance)
- **Mitigation:** S9.P4 prompt includes "focus on epic-scope concerns: cross-feature integration, architectural consistency"

**Risk 2: Review takes longer (sub-agent spawning + primary agent response)**
- **Mitigation:** Token efficiency from skipping overview.md offsets sub-agent spawn cost
- **Mitigation:** Fresh perspective likely catches issues faster (fewer validation rounds)

**Risk 3: Primary agent "rubber stamps" sub-agent review (doesn't genuinely address comments)**
- **Mitigation:** S7.P3 and S9.P4 guides explicitly require: read each comment, take action (fix code OR document why won't fix OR escalate to user)
- **Mitigation:** Add checkpoint: "Have you addressed ALL BLOCKING and CONCERN comments?"
- **Mitigation:** SUGGESTION/NITPICK comments are walked through with user one-by-one for judgment (per Decision 3)

**Risk 4: Dimension 13 overlaps with existing dimensions**
- **Mitigation:** Define Dimension 13 scope narrowly (implementation plan fidelity only, not general correctness)
- **Mitigation:** Other dimensions check code correctness, this checks plan adherence

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-07 | Initial draft created |
| 2026-04-07 | Validation complete (3 rounds, 5 issues fixed, sub-agent confirmation passed) |
| 2026-04-07 | Design decisions finalized: Q1=Full 12 categories for S9, Q2=Dimension 13 S7/S9 only, Q3=SUGGESTION/NITPICK walk through with user |
| 2026-04-07 | Implementation complete (Phases 1-6 finished, all files modified/created as specified) |
