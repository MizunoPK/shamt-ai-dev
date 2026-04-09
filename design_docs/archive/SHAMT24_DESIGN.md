# SHAMT-24: Single Low-Severity Fix Allowance for Clean Rounds

**Status:** Implemented
**Created:** 2026-04-01
**Last Updated:** 2026-04-01
**Type:** Large change (affects 25-30 files across validation loop system)

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Current State Analysis](#current-state-analysis)
3. [Requirements](#requirements)
4. [Proposed Solution](#proposed-solution)
5. [Design Decisions](#design-decisions)
6. [Affected Files](#affected-files)
7. [Implementation Plan](#implementation-plan)
8. [Edge Cases](#edge-cases)
9. [Verification Strategy](#verification-strategy)
10. [Risks & Mitigation](#risks--mitigation)
11. [Expected Outcomes](#expected-outcomes)
12. [Open Questions](#open-questions)

---

## Problem Statement

### The Issue

The current validation loop protocol defines a "clean round" as one where **ZERO issues** are found. Any issue found—even a trivial typo or trailing whitespace—resets the `consecutive_clean` counter to 0, requiring the agent to continue validation rounds until a truly pristine round is achieved.

**Problem manifestation:**
- Round 4: Agent finds single trailing whitespace → fixes it → counter resets to 0
- Round 5: Agent finds extra blank line → fixes it → counter resets to 0
- Round 6: Agent finds typo "teh" → fixes it → counter resets to 0
- Round 7: Finally 0 issues → counter = 1 → spawn sub-agents

This creates **false precision**: cosmetic issues that don't impact quality force unnecessary validation rounds, increasing time without improving outcomes.

### User Request

> "I want to update all validation loop protocols such that if a single 'low severity' fix is made then that can still count as a clean round and does not constitute a failed round. If any medium or high priority fixes are made, or if multiple low priority fixes are made, then that still constitutes an un-clean round."

### Success Criteria

- Single low-severity fix per round counts as clean (counter increments)
- Multiple low-severity fixes OR any medium/high/critical resets counter to 0
- Applies uniformly across ALL validation contexts (guide audits, workflow validation loops, code reviews, sync workflows)
- No degradation in quality outcomes (sub-agent confirmation remains unchanged)
- 15-25% reduction in validation round counts

---

## Current State Analysis

### Validation Loop Landscape

The Shamt framework uses validation loops across 10+ contexts:

| Validation Context | Exit Criteria | Dimensions | Current Clean Rule |
|-------------------|---------------|------------|-------------------|
| **Master Protocol** | Primary clean + sub-agent | 7 master | Zero issues |
| **Guide Audit** | 3 consecutive clean rounds | 22 (across 4 sub-rounds) | Zero issues |
| **S5 Implementation Planning** | Primary clean + sub-agent | 18 (7 master + 11 S5) | Zero issues |
| **S7.P2 Feature QC** | Primary clean + sub-agent | 16 (7 master + 9 S7) | Zero issues |
| **S7.P3 Final Review** | Primary clean + sub-agent | 11 | Zero issues |
| **S9.P2 Epic QC** | Primary clean + sub-agent | 13 (7 master + 6 epic) | Zero issues |
| **S9.P4 Epic Final Review** | Primary clean + sub-agent | 12 | Zero issues |
| **Code Review (overview)** | Primary clean + sub-agent | 5 | Zero issues |
| **Code Review (review)** | Primary clean + sub-agent | 12 | Zero issues |
| **Import/Export Sync** | Validation gates | Varies | Zero issues |

### Existing Severity Classification

Guide audits already have a 4-level severity system at `.shamt/guides/audit/reference/issue_classification.md`:

- **Critical 🔴:** Blocks workflow (broken file paths, CLAUDE.md >40K chars)
- **High 🟠:** Causes confusion (old notation, contradictions)
- **Medium 🟡:** Reduces quality (file >1250 lines, missing TOCs)
- **Low 🟢:** Nice-to-have (trailing whitespace, trivial typos)

**Current Application:**
- **Guide audits:** Full 4-level system (Critical/High/Medium/Low) at `audit/reference/issue_classification.md`
- **Master validation protocol:** Partial 3-level system (High/Medium/Low) at lines 1284-1307, missing Critical level
  - Note: Line 1307 uses "CRITICAL" colloquially to emphasize policy importance ("ALL severity levels must be fixed"), not as a fourth severity level
- **Workflow-specific loops (S5, S7, S9, code review):** No explicit severity classification

**Gap:** Not uniformly applied across all validation contexts, and master protocol missing Critical severity level.

### Counter Tracking Mechanism

All validation loops track `consecutive_clean` explicitly:

```
consecutive_clean = 0  (initial state)

Round 1: Find 5 issues → Fix → counter = 0
Round 2: Find 2 issues → Fix → counter = 0
Round 3: Find 0 issues → counter = 1 (primary clean)
  └─> Spawn 2 sub-agents
       Sub-agent A: 0 issues ✅
       Sub-agent B: 0 issues ✅
  └─> EXIT
```

---

## Requirements

### User-Confirmed Requirements

From user decision workflow in plan mode:

1. ✅ **Scope:** Apply to ALL validation loops uniformly
2. ✅ **Guide Audit Level:** Apply at full round level (1 low-severity fix across all 4 sub-rounds)
3. ✅ **Severity System:** Use same 4-level system everywhere (Critical/High/Medium/Low)

### Functional Requirements

**FR-1: Clean Round Definition**
- ZERO issues found = clean round (counter increments)
- Exactly ONE low-severity issue (fixed) = clean round (counter increments)
- 2+ low-severity issues (all fixed) = NOT clean (counter resets to 0)
- Any medium/high/critical issue (even if fixed) = NOT clean (counter resets to 0)

**FR-2: Universal Severity Classification**
- Create cross-context severity classification guide
- Define Critical/High/Medium/Low for all validation contexts
- Provide context-specific examples (implementation plans, code reviews, guide audits, specs)

**FR-3: Counter Tracking Updates**
- Update all validation loop protocols with new counter reset logic
- Document "pure clean" vs "clean (1 low fix)" distinction
- Maintain explicit tracking requirement

**FR-4: Sub-Agent Confirmation Unchanged**
- Sub-agents do NOT get the 1 low-severity allowance
- ANY issue found by sub-agent (even low) resets counter to 0
- Rationale: Sub-agents are final verification; finding anything indicates gap in primary

**FR-5: Validation Log Documentation**
- Templates must include severity classification field
- Round summaries must distinguish "pure clean" vs "clean (1 low fix)"
- Severity breakdown required (Critical: N, High: N, Medium: N, Low: N)

### Non-Functional Requirements

**NFR-1: Consistency**
- Identical counter logic across all workflow validation loops
- Uniform severity definitions across all contexts
- Clear cross-references between guides

**NFR-2: Backward Compatibility**
- Historical validation logs remain valid
- No need to re-run previous validations
- Note in archived logs: "Used pre-SHAMT-24 clean round definition"

**NFR-3: Quality Preservation**
- No degradation in artifact quality
- Sub-agent confirmation gate unchanged
- Exit criteria maintain current rigor

---

## Proposed Solution

### Solution Architecture

```
┌────────────────────────────────────────────────────────────┐
│  Universal Severity Classification Guide (NEW)              │
│  .shamt/guides/reference/severity_classification_universal.md│
│  - 4-level system for ALL contexts                          │
│  - Context-specific examples                                 │
│  - Borderline case protocol                                  │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────┐
│  Master Validation Loop Protocol (UPDATED)                  │
│  .shamt/guides/reference/validation_loop_master_protocol.md │
│  - New counter reset logic                                   │
│  - Clean round classification                                │
│  - Updated examples                                          │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
         ┌────────────────────┴────────────────────┐
         │                                          │
         ▼                                          ▼
┌─────────────────────┐                  ┌─────────────────────┐
│ Workflow Validation │                  │  Guide Audit        │
│ Loops (CASCADED)    │                  │  Protocol (UPDATED) │
│ - S5, S7, S9        │                  │  - 3 consecutive OR │
│ - Code Review       │                  │    2 with ≤1 low    │
│ - Import/Export     │                  │  - Full round level │
└─────────────────────┘                  └─────────────────────┘
```

### Core Components

#### Component 1: Universal Severity Classification

**File:** `.shamt/guides/reference/severity_classification_universal.md` (NEW)

**Purpose:** Define 4-level severity system for ALL validation contexts

**Content:**
- Universal definitions (Critical/High/Medium/Low)
- Context-specific severity tables:
  - Implementation Plans (S5)
  - Code Review
  - Guide Audits
  - Specifications (S2)
  - Epic Documentation (S3)
- Severity decision tree
- Borderline case protocol: "When uncertain, err on higher severity"

**Status:** ⏸️ Not created (prematurely created file was deleted)

#### Component 2: Master Protocol Updates

**File:** `.shamt/guides/reference/validation_loop_master_protocol.md` (UPDATED)

**Key Changes:**

1. **Hard Stop Section (lines 10-32):**
   ```markdown
   2. **Track `consecutive_clean`** explicitly in the log:
      - Starts at 0
      - Resets to 0 when ANY of these occur:
        * Multiple low-severity issues found (2+)
        * Any medium, high, or critical severity issue found
      - Increments to 1 when EITHER:
        * Zero issues found (pure clean)
        * Exactly one low-severity issue found and fixed
   ```

2. **Core Validation Process section (counter reset rule subsection, approximately lines 195-209):**
   - Updated counter reset rule with examples
   - Example showing 2 LOW issues resetting counter
   - Example showing 1 LOW issue keeping counter at 1

3. **New Section (after line 233): "Issue Severity Classification (Universal)"**
   - Quick reference table
   - Link to universal severity guide
   - Severity decision shortcuts

4. **Quality Standards Section:**
   - **Pure Clean Round:** 0 issues, counter increments
   - **Clean with Single Low Fix:** 1 low issue, counter increments, document as "clean (1 low fix)"
   - **Not Clean:** 2+ low OR any medium/high/critical, counter resets

5. **Documentation Requirements:**
   - Round summary template includes severity breakdown
   - Clean round status field (Pure Clean / Clean (1 Low Fix) / Not Clean)

6. **Templates Section:**
   - Issue tracking template includes severity classification field with rationale

#### Component 3: Cascade to All Implementations

**Workflow Validation Loops (Primary clean + sub-agent confirmation):**
- S5 v2: Implementation planning (18 dimensions)
- S7.P2: Feature QC (16 dimensions)
- S7.P3: Final Review/PR (11 dimensions)
- S9.P2: Epic QC (12 dimensions)
- S9.P4: Epic Final Review (12 dimensions)
- Code Review: Overview (5 dims) + Review (12 dims)

**Standard Updates for Each:**
1. Add reference to `severity_classification_universal.md`
2. Update counter reset logic in "Critical Rules" sections
3. Add context-specific severity examples
4. Update round execution examples

**Example Update (S5 v2, lines 197-200):**
```markdown
Round 1: Find ~12 issues (3 HIGH, 6 MEDIUM, 3 LOW) → Fix all → Counter = 0
Round 2: Find ~8 issues (0 HIGH, 8 MEDIUM) → Fix all → Counter = 0
Round 3: Find 1 LOW issue → Fix → Counter = 1 (single low allowed) → Trigger sub-agent
  Sub-agent A: 2 MEDIUM issues → Fix → Counter = 0
Round 4: Find 0 issues → Counter = 1 (pure clean) → Trigger sub-agent
  Sub-agent A (top-to-bottom): 0 issues ✅
  Sub-agent B (bottom-to-top): 0 issues ✅
  Both confirmed → ✅ PASSED
```

**Guide Audit Protocol:**
- `.shamt/guides/audit/README.md`
- `.shamt/guides/audit/audit_overview.md`
- `.shamt/guides/audit/stages/stage_5_loop_decision.md`

**Updates:**
1. Exit Criteria: "3 consecutive clean rounds (where each round has ≤1 low-severity issue)"
2. Rationale: Maintains conservative 3-round requirement while allowing single low-severity fix benefit. Broader scope (22 dimensions, 4 sub-rounds) justifies keeping the 3-round minimum rather than reducing to primary clean + sub-agent pattern.
3. Full round level: 1 low across all 4 sub-rounds counts as clean
4. Add section: "Extending Severity Classification to New Contexts" with template for future validation types

**Sync Workflows:**
- `.shamt/guides/sync/import_workflow.md`
- `.shamt/guides/sync/export_workflow.md`

Update validation gate descriptions to reflect new clean criteria.

#### Component 4: CLAUDE.md Updates

**File:** `CLAUDE.md` (repo root)

**Critical Rules Section (line 141):**
```markdown
- Guide audits require 3 CONSECUTIVE clean rounds (where each round has ≤1 low-severity
  issue) to exit. Workflow validation loops exit on **primary clean round + independent
  sub-agent confirmation**. A round is clean if it has ZERO issues OR exactly ONE
  low-severity issue (fixed). Multiple low-severity issues OR any medium/high/critical
  severity issue resets consecutive_clean to 0. Track consecutive_clean explicitly.
```

**Design Doc Validation Section (line 92):**
```markdown
**Exit criterion:** Primary clean round (all 7 dimensions pass with no issues OR
exactly one low-severity issue) + independent sub-agent confirmation.

Any medium/high/critical issue OR multiple low-severity issues reset consecutive_clean to 0.
```

---

## Design Decisions

### Decision 1: Full Round Level for Guide Audits

**Context:** Guide audits have 4 sub-rounds per round (N.1, N.2, N.3, N.4)

**Options Considered:**
- **A:** Sub-round level (each sub-round can have 1 low)
- **B:** Full round level (1 low across all 4 sub-rounds)

**Decision:** Option B (Full round level)

**Rationale:**
- More conservative (maintains higher quality bar)
- Simpler to track and document
- Prevents 4 low-severity issues per round (too lenient)
- User confirmed: "Full round level (Recommended)"

### Decision 2: No Sub-Agent Allowance

**Context:** Should sub-agents also get the 1 low-severity allowance?

**Options Considered:**
- **A:** Sub-agents get same allowance (1 low = clean)
- **B:** Sub-agents have zero tolerance (any issue = reset)

**Decision:** Option B (Zero tolerance)

**Rationale:**
- Sub-agents are final verification step
- Finding anything (even low) indicates gap in primary validation
- Maintains integrity of "fresh eyes" confirmation
- Primary rounds get allowance (iterative improvement phase)
- Sub-agents are binary: confirm clean or identify gaps

### Decision 3: Universal Severity System

**Context:** Should all validation contexts use the same severity levels?

**Options Considered:**
- **A:** Universal 4-level system (Critical/High/Medium/Low)
- **B:** Simplified 3-level for workflows (High/Medium/Low)
- **C:** Custom per validation type

**Decision:** Option A (Universal 4-level system)

**Rationale:**
- Reduces cognitive load (learn once, apply everywhere)
- Already established in guide audit protocol
- Critical level needed for workflow-blocking issues
- Easier to cross-reference and maintain consistency
- User confirmed: "Yes, use same 4-level system (Recommended)"

### Decision 4: "Err on Higher Severity" Rule

**Context:** How to handle borderline classifications?

**Decision:** When severity is uncertain between two levels, classify as higher severity

**Rationale:**
- More conservative (safer)
- Prevents gaming the "1 low allowed" rule
- Encourages genuine quality assessment
- If LOW vs MEDIUM unclear → MEDIUM
- If MEDIUM vs HIGH unclear → HIGH

### Alternative Considered: Severity Budget System

**Not Selected:** A "severity point budget" approach was considered where each severity has points (LOW=1, MEDIUM=4, HIGH=10, CRITICAL=20) and "clean round = ≤3 points".

**Why Rejected:**
- More complex to track and explain
- Harder to implement consistently
- Binary "1 LOW allowed" rule is simpler and easier to understand
- Point system creates more edge cases (e.g., is 2 LOW + fractional credit better than 1 MEDIUM?)
- Can revisit if simple rule proves insufficient after 6 months of data

---

## Affected Files

### Critical Path (Must be updated in order)

1. **`.shamt/guides/reference/severity_classification_universal.md`** (NEW) - ✅ Created
   - Foundation for entire system

2. **`.shamt/guides/reference/validation_loop_master_protocol.md`** (UPDATE)
   - Master protocol that cascades to all implementations
   - ~1600 lines, 6 major sections need updates

3. **`CLAUDE.md`** (UPDATE)
   - High-level policy file read by all agents
   - 2 sections need updates (lines 92, 141)

4. **`.shamt/guides/audit/reference/issue_classification.md`** (UPDATE)
   - Add universal guide reference
   - Cross-reference table

### Workflow Validation Loops (Parallel after #2)

5. `.shamt/guides/stages/s5/s5_v2_validation_loop.md` (18 dimensions)
6. `.shamt/guides/stages/s7/s7_p2_qc_rounds.md` (16 dimensions)
7. `.shamt/guides/stages/s7/s7_p3_final_review.md` (11 dimensions)
8. `.shamt/guides/stages/s9/s9_p2_epic_qc_rounds.md` (13 dimensions)
9. `.shamt/guides/stages/s9/s9_p4_epic_final_review.md` (12 dimensions)
10. `.shamt/guides/code_review/code_review_workflow.md`

### Guide Audit Protocol (Parallel after #2)

11. `.shamt/guides/audit/README.md`
12. `.shamt/guides/audit/audit_overview.md`
13. `.shamt/guides/audit/stages/stage_5_loop_decision.md`

### Sync Workflows (Parallel after #2)

14. `.shamt/guides/sync/import_workflow.md`
15. `.shamt/guides/sync/export_workflow.md`

### Reference Validation Loops (Parallel after #2)

16. `.shamt/guides/reference/validation_loop_alignment.md`
17. `.shamt/guides/reference/validation_loop_discovery.md`
18. `.shamt/guides/reference/validation_loop_spec_refinement.md`
19. `.shamt/guides/reference/validation_loop_s9_epic_qc.md`
20. `.shamt/guides/reference/validation_loop_s7_feature_qc.md`
21. `.shamt/guides/reference/validation_loop_qc_pr.md`

**Total Files:** ~21-25 primary files + templates

---

## Implementation Plan

### Phase 1: Foundation (8-12 hours)

**Status:** 0/5 complete (prematurely created files were deleted)

- [ ] Create `severity_classification_universal.md`
- [ ] Update `audit/reference/issue_classification.md`
- [ ] Update `validation_loop_master_protocol.md`
- [ ] Update `CLAUDE.md`
- [ ] Initial self-review

### Phase 2: Core Workflows (10-14 hours)

- [ ] Update S5 validation loop
- [ ] Update S7.P2 + S7.P3
- [ ] Update S9.P2 + S9.P4
- [ ] Update Code Review workflow
- [ ] Update Guide Audit protocol
- [ ] Mid-point review

### Phase 3: Comprehensive Coverage (8-10 hours)

- [ ] Update remaining reference validation loops
- [ ] Update sync workflows
- [ ] Update all templates
- [ ] Final cross-reference check

### Phase 4: Validation & Cleanup (6-8 hours)

- [ ] Run full guide audit on entire `.shamt/guides/` tree
- [ ] Fix any issues found (must pass audit before merge)
- [ ] User walkthrough/review
- [ ] Final adjustments

**Total Estimated Time:** 32-44 hours

**Parallel Work Possible:**
- Phases 2-3 can be done in parallel after Phase 1 complete
- Different agents can work on S5/S7/S9 simultaneously

**Must Be Sequential:**
- Phase 1 must complete before Phases 2-3 begin (foundation dependency)
- Phase 4 must be after all file updates (audit entire system)

---

## Edge Cases

### EC-1: Unfixable Low-Severity Issues

**Scenario:** Agent finds 1 low-severity issue but requires user escalation (cannot fix without user input)

**Example:** Unclear which naming convention to use for variable

**Protocol:**
- Do NOT count round as clean
- Mark round as "PAUSED - awaiting user input"
- Document issue in validation log
- After user provides answer → fix issue → continue validation

**Rationale:** "Clean" means genuinely issue-free. If issue cannot be resolved, round is not clean.

### EC-1b: Fix Failure Due to Technical Error

**Scenario:** Agent finds 1 low-severity issue but the fix FAILS due to technical error (Edit tool error, file locked, git conflict, etc.)

**Example:** Agent finds trailing whitespace, attempts edit, but Edit tool returns "File has been unexpectedly modified" error

**Protocol:**
- **First Attempt:** Retry the fix operation once (may be transient error)
- **If retry fails:**
  - Do NOT count round as clean (counter remains at current value)
  - Document technical failure in validation log
  - Escalate to user: "Found 1 LOW issue but cannot fix due to technical error: [error details]. Please resolve and re-run validation."
  - PAUSE validation (do not continue to next round)
- **After user resolves:** Resume from current round, re-attempt fix

**Rationale:** Technical failures are distinct from content issues. If the fix cannot be applied due to tooling, the round cannot be counted as clean even though the agent correctly identified and attempted to fix the issue.

### EC-2: Sub-Agent Finds Low-Severity Issue

**Scenario:** Primary declares clean (0 issues), sub-agent A finds 1 low-severity issue

**Protocol:**
- Fix ALL issues found by sub-agent (even if just 1 low)
- Reset counter to 0
- Resume primary validation: Start new round (Round N+1) with full artifact re-read and all dimensions checked
  - Do NOT restart from Round 1 (preserve progress)
  - Do NOT just fix and continue (must re-validate with fresh eyes)
  - Treat as continuation of validation loop, not full restart

**Exception:** If sub-agent finding is OUTSIDE artifact scope (e.g., notices typo in separate reference file that is NOT the validation target):
- Protocol:
  1. Sub-agent documents finding: "Issue found in [file] which is outside validation scope for [artifact]"
  2. Wait for other sub-agent to complete
  3. If other sub-agent ALSO found the same out-of-scope issue → clearly out-of-scope
  4. If other sub-agent did NOT mention it → ambiguous, treat as in-scope (reset counter)
  5. If clearly out-of-scope (both sub-agents agree):
     - Fix the out-of-scope issue separately
     - Do NOT reset counter (validation of target artifact remains clean)
     - Document in validation log: "Out-of-scope issue fixed in [file]"
     - Continue with exit sequence (both sub-agents confirmed target artifact clean)

**Rationale:** Sub-agents are final verification. Finding anything in-scope indicates gap in primary validation and requires counter reset. However, sub-agents sometimes notice issues in reference files while validating target - if truly out-of-scope and both sub-agents confirm, fixing it doesn't invalidate the target artifact's clean status.

### EC-3: Validation Log Documentation

**Scenario:** How to document "clean with 1 low fix" vs "pure clean"?

**Template:**
```markdown
**Round N Summary:**
- Total Issues: {0 or 1}
- Severity Breakdown: CRITICAL: 0, HIGH: 0, MEDIUM: 0, LOW: {0 or 1}
- Clean Round Status:
  * **Pure Clean** (0 issues found) ✅
  * **Clean (1 Low Fix)** (1 low-severity issue found & fixed) ✅
  * **Not Clean** (multiple low OR any medium/high/critical) ❌
- Issues Details: [If 1 low: describe what was found and fixed]
- Clean Round Counter: {0 or 1}
- Next Action: [Continue / Trigger sub-agents / EXIT]
```

**Pattern Analysis:** If many "Clean (1 Low Fix)" rounds occur, investigate validation quality

### EC-4: Borderline Severity Classification

**Scenario:** Agent uncertain if issue is LOW or MEDIUM

**Example:** Variable naming that's acceptable but could be clearer

**Protocol:**
1. Apply "err on higher severity" rule: LOW vs MEDIUM unclear → classify as MEDIUM
2. If severity significantly impacts outcome (clean vs not clean) AND agent cannot determine confidently:
   - Pause validation
   - Document uncertainty in validation log
   - Escalate to user with arguments for each severity level
   - Resume after classification received

**When escalation NOT needed:**
- Both interpretations yield same outcome (both MEDIUM → both reset counter)
- Agent can confidently apply "err higher" rule

---

## Verification Strategy

### Self-Validation Checklist

After implementation, verify:

**Universal Coverage:**
- [ ] All 10+ validation loop types updated
- [ ] All references to "zero issues" updated to "zero issues OR 1 low"
- [ ] All counter reset logic updated consistently

**Consistency:**
- [ ] Severity definitions consistent across all contexts
- [ ] Counter logic identical in all workflows (except guide audit)
- [ ] Templates updated to match new logic

**Edge Cases:**
- [ ] Sub-agent confirmation protocol addresses low-severity findings
- [ ] Unfixable issues protocol documented
- [ ] Borderline severity classification addressed
- [ ] Documentation format clarified

**Cross-References:**
- [ ] All files reference `severity_classification_universal.md`
- [ ] Master protocol referenced from all implementations
- [ ] CLAUDE.md reflects new policy

### Test Scenarios

**Scenario 1: S5 Implementation Plan - Single Typo**
```
Round 1: 8 issues (2 HIGH, 4 MEDIUM, 2 LOW) → Fix → Counter = 0
Round 2: 1 LOW (typo in comment) → Fix → Counter = 1 ✅
  Sub-agent A: 0 issues ✅
  Sub-agent B: 0 issues ✅
Expected: EXIT successful
```

**Scenario 2: Code Review - Multiple Nitpicks**
```
Round 1: 5 CONCERN, 3 SUGGESTION → Fix → Counter = 0
Round 2: 2 NITPICK → Fix → Counter = 0 (multiple = reset)
Round 3: 0 issues → Counter = 1
Expected: Continue to sub-agents
```

**Scenario 3: Guide Audit - Pure Clean Path**
```
Round 1: 50 HIGH, 20 MEDIUM, 5 LOW → Fix → Counter = 0
Round 2: 8 MEDIUM, 2 LOW → Fix → Counter = 0
Round 3: 1 LOW (trailing space) → Fix → Counter = 1
Round 4: 1 LOW (formatting) → Fix → Counter = 2
Round 5: 0 issues → Counter = 3
Expected: EXIT (3 consecutive clean rounds achieved)
```

**Scenario 3b: Guide Audit - Clean with Low Fixes Path**
```
Round 1: 50 HIGH, 20 MEDIUM, 5 LOW → Fix → Counter = 0
Round 2: 8 MEDIUM, 2 LOW → Fix → Counter = 0
Round 3: 1 LOW (typo) → Fix → Counter = 1 (clean with 1 low)
Round 4: 1 LOW (whitespace) → Fix → Counter = 2 (clean with 1 low)
Round 5: 1 LOW (formatting) → Fix → Counter = 3 (clean with 1 low)
Expected: EXIT (3 consecutive clean rounds, each with ≤1 low)
```

**Scenario 4: Sub-Agent Finds Low-Severity Issue**
```
Round 4: Primary 0 issues → Counter = 1 → Spawn sub-agents
  Sub-agent A: 1 LOW (missed formatting) → Fix → Counter = 0
Round 5: Primary 0 issues → Counter = 1 → Spawn sub-agents
  Both sub-agents: 0 issues
Expected: EXIT successful
```

### Post-Implementation Audit

**Method:** Run full guide audit on entire `.shamt/guides/` tree

**Success Criteria:**
- All automated checks pass
- Manual audit finds 0 HIGH/CRITICAL issues
- Manual audit finds ≤3 MEDIUM issues
- All cross-references valid

**Mandatory:** Must pass audit before changes can be merged or propagated to child projects

---

## Risks & Mitigation

### Risk 1: Decreased Quality

**Description:** Allowing 1 low-severity fix could reduce scrutiny

**Likelihood:** Low
**Impact:** Medium

**Mitigations:**
- Sub-agent confirmation unchanged (final quality gate)
- "Low" definition is strict (cosmetic only)
- Multiple low still resets (prevents accumulation)
- User escalation for borderline cases
- Pattern analysis (many "clean (1 low)" → investigate)

### Risk 2: Classification Disputes

**Description:** Agents and users disagree on severity levels

**Likelihood:** Medium
**Impact:** Low

**Mitigations:**
- Clear decision tree in severity guide
- "Err on higher severity" rule
- Escalation protocol for disputes
- Examples library covering edge cases
- Explicit severity rationale required in validation logs

### Risk 3: Implementation Inconsistency

**Description:** Some files updated incorrectly or incompletely

**Likelihood:** Medium
**Impact:** High

**Mitigations:**
- Comprehensive self-validation checklist (above)
- Full guide audit before finalization (mandatory)
- Test scenarios to validate behavior
- Parallel review by second agent (optional)
- Phased rollout (Phase 1 foundation before cascade)

### Risk 4: Gaming the System

**Description:** Agents classify MEDIUM issues as LOW to stay "clean"

**Likelihood:** Low
**Impact:** Medium

**Mitigations:**
- "Err higher" rule (when uncertain, classify higher)
- Pattern analysis (suspicious if many "clean (1 low)" rounds)
- Sub-agents apply strict classification (catch gaming)
- Audit trail (severity rationale required)
- User escalation for significant borderline cases

### Risk 5: Child Project Confusion

**Description:** Child projects import mid-stream, unsure which rules to use

**Likelihood:** Low
**Impact:** Low

**Mitigations:**
- Clear communication (announcement message prepared)
- Migration guidance for in-progress work
- Backward compatibility (historical logs remain valid)
- Support channel for questions
- Gradual adoption (complete current loops with old rules)

### Risk 6: Perverse Incentives (Artificial Issue Creation)

**Description:** Agents deliberately find/create artificial LOW issues to demonstrate thoroughness (opposite of gaming)

**Likelihood:** Very Low
**Impact:** Low

**Example:** Agent creates trivial formatting "issue" where none exists, fixes it, claims thoroughness

**Mitigations:**
- "Pure clean" rounds are preferable and documented distinctly from "clean (1 low)"
- Pattern analysis: If agent consistently finds exactly 1 LOW every round → investigate
- Validation logs require severity rationale (why is this LOW severity?)
- Sub-agent confirmation catches artificial issues (fresh eyes will notice if issue wasn't real)
- User review of validation logs can identify suspicious patterns

### Rollback Strategy

**If SHAMT-24 causes issues post-deployment:**

1. **Identify symptoms:** Excessive "clean (1 low)" rounds (>50%), quality regression, user complaints
2. **Quick revert:** Use git to revert SHAMT-24 commits on main branch
3. **Communicate:** Notify child projects via announcement, recommend re-importing to get reverted guides
4. **Root cause:** Analyze what went wrong (gaming? Severity classification unclear? Sub-agent gate insufficient?)
5. **Redesign:** Address root cause before attempting SHAMT-24 v2

**Rollback feasibility:** High - changes are isolated to guide files, no code changes, backward compatible

---

## Expected Outcomes

### Quantitative Metrics

**Primary Metric: Round Count Reduction**
- **Target:** 15-25% reduction in validation round counts
- **Measurement:** Average rounds to primary clean (before vs after)
- **Baseline:** Current typical range: 6-8 rounds (S5), 4-6 rounds (S7/S9)
- **Expected:** New range: 5-6 rounds (S5), 3-5 rounds (S7/S9)

**Secondary Metrics:**
- Percentage of "clean (1 low)" vs "pure clean" rounds
- User satisfaction (survey: "fewer unnecessary rounds?")
- Quality outcomes (regression in artifact quality?)
- Gaming attempts (suspicious classification patterns?)

### Qualitative Outcomes

**User Experience:**
- Fewer "why restart for typo?" frustration moments
- More intuitive clean round definition
- Clearer issue classification (explicit severity)

**System Quality:**
- No degradation (sub-agent gate unchanged)
- More efficient validation (fewer false restarts)
- Better severity awareness (explicit classification required)

**Maintenance:**
- Consistent severity system across framework
- Single source of truth (universal severity guide)
- Easier to train new users (uniform rules)

### Success Indicators (6 months post-deployment)

**Positive:**
- Average round count reduced by 15-25%
- <20% of clean rounds are "clean (1 low)" (not >50%)
- Zero user reports of quality degradation
- Positive user feedback on efficiency

**Concerning:**
- >50% of clean rounds are "clean (1 low)" (possible gaming)
- Quality issues increase (regression)
- Frequent severity disputes (unclear guidelines)

**Decision Point:** If concerning indicators emerge, re-evaluate allowance

---

## Open Questions

### OQ-1: Guide Audit Different Standard

**Question:** Guide audits use "3 consecutive clean rounds" vs workflow loops "primary clean + sub-agent confirmation". Both now allow ≤1 low-severity issue per round. Is the 3-round minimum (vs 1-round + sub-agents) acceptable for guide audits?

**Context:** Workflow loops use "primary clean + 2 sub-agents" (minimum 1 round). Guide audits use "3 consecutive clean rounds" (minimum 3 rounds). Both allow ≤1 low per round. Guide audits have broader scope (22 dimensions, 4 sub-rounds) which justifies the higher 3-round minimum.

**Recommendation:** Approve - the 3-round requirement is MORE conservative than workflow loops, appropriate given broader scope.

**Status:** Resolved - design is internally consistent, awaiting user validation approval

### OQ-2: Historical Validation Logs

**Question:** Historical validation logs reference old rules. Should they be:
- **A:** Left as-is with footnotes
- **B:** Re-run for critical validations
- **C:** Annotated with "pre-SHAMT-24" marker

**Recommendation:** Option A (leave as-is)

**User Decision Required:** Confirm approach?

**Status:** Awaiting user input

### OQ-3: Future Refinements

**Question:** Should we consider graduated allowances in the future?
- Round 1-3: Allow 1 low
- Round 4-6: Allow 2 low
- Round 7+: Allow 3 low

**Recommendation:** Not in initial scope. Implement simple "1 low" rule, gather data for 6 months, revisit.

**User Decision Required:** Confirm future consideration?

**Status:** Out of scope for SHAMT-24

### OQ-4: Metrics Tracking

**Question:** Should we build automated metrics tracking for:
- Round count averages (before/after)
- Clean round type distribution (pure vs 1 low)
- Gaming pattern detection

**Recommendation:** Manual tracking for first 6 months, automate if value demonstrated.

**Implementation Note:** Metrics specified in "Expected Outcomes" (lines 797-843) are advisory goals only. SHAMT-24 does not include instrumentation/logging infrastructure for automated metric collection. Metrics assessment would be manual (e.g., comparing validation logs before/after) or deferred to future work.

**User Decision Required:** Required for SHAMT-24 or defer to future work?

**Status:** Awaiting user input - metrics are advisory/observational, not measurable without future instrumentation

---

## Validation Checklist

Before declaring SHAMT-24 design complete, confirm:

**Completeness:**
- [x] All problem aspects covered
- [x] All affected files identified
- [x] Edge cases addressed
- [x] Verification strategy defined

**Correctness:**
- [x] Proposed changes work as described
- [x] References to existing guides accurate
- [x] Examples valid and representative
- [x] No contradictions in design

**Consistency:**
- [x] Design internally consistent
- [x] No conflicts with existing SHAMT decisions
- [x] Aligns with guide audit conventions
- [x] Follows master dev workflow patterns

**Helpfulness:**
- [x] Solves stated problem effectively
- [x] Benefit worth complexity added
- [x] Alternative approaches considered
- [x] Trade-offs explicitly documented

**Clarity:**
- [x] Implementation path clear
- [x] Acceptance criteria defined
- [x] Risks identified and mitigated
- [x] Open questions surfaced

---

## Appendix A: Reference Files

**Created:**
- `C:\Users\kmgam\.claude\plans\sunny-tickling-newell.md` (Implementation plan)
- `SHAMT24_DESIGN.md` (This document)

**Prematurely Created (Deleted):**
- `.shamt/guides/reference/severity_classification_universal.md` (Was 412 lines, deleted to restart implementation properly)

**To Be Updated:** See [Affected Files](#affected-files) section

---

## Appendix B: Related Work

**SHAMT-20:** 8 workflow optimizations + full guide audit
- Established current 3 consecutive clean rounds standard for guide audits
- Evidence: 4 rounds, 104+ issues found
- Informed conservative approach in SHAMT-24

**SHAMT-7:** Original guide audit protocol design
- Created 22-dimension audit system
- Established 4-level severity classification
- Foundation for SHAMT-24 universal severity system

**S5 v2:** Implementation planning validation loop
- Replaced 22-iteration S5 v1 with validation loop approach
- Proved validation loop effectiveness (35-50% time savings)
- Validated sub-agent confirmation as quality gate

---

## Next Steps

1. **Validation:** Run design doc validation loop on SHAMT24_DESIGN.md
2. **User Review:** Present design to user for approval
3. **Implementation:** Proceed with Phase 1-4 implementation plan
4. **Testing:** Execute test scenarios on updated guides
5. **Audit:** Run full guide audit before merge
6. **Deploy:** Merge to main, announce to child projects via import workflow

---

**End of SHAMT24_DESIGN.md**
