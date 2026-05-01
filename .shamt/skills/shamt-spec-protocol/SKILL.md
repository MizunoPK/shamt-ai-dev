---
name: shamt-spec-protocol
description: >
  Runs the S2 spec refinement validation loop: 10 dimensions (7 master +
  3 spec-specific), ONE-question-at-a-time rule, INVESTIGATION COMPLETE ≠
  QUESTION RESOLVED, embedded Gates 1/2/3. Validates that every requirement
  has a source, research gaps are eliminated before asking users, scope matches
  the epic exactly, and design completeness is sufficient for mechanical planning.
triggers:
  - "run spec validation"
  - "validate the spec"
  - "spec refinement loop"
  - "refine the spec"
source_guides:
  - guides/reference/validation_loop_spec_refinement.md
  - guides/reference/critical_workflow_rules.md
master-only: false
version: "1.1 (SHAMT-45)"
---

# Skill: shamt-spec-protocol

## Overview

This skill governs spec creation and refinement (S2). It combines two protocols:

1. **Critical Workflow Rules** — Governs how questions are asked during spec
   creation (one at a time, INVESTIGATION COMPLETE ≠ QUESTION RESOLVED).
2. **Spec Refinement Validation Loop** — 10-dimension validation loop that must
   pass before user approval (Gate 3 for feature specs, Gate 4 for epic docs).

Both protocols must be applied. The workflow rules govern the creation phase;
the validation loop governs the quality gate before handing off to the user.

---

## When This Skill Triggers

Use this skill when:
- Creating or refining a feature spec (S2.P1.I3)
- Refining epic documentation (S3.P2)
- The artifact being validated is a specification document

---

## Protocol Part 1: Critical Workflow Rules (Spec Creation)

These rules govern how you interact with the user while building the spec.
Copy them into Agent Status at the start of S2.P1.

### S1 Feature Breakdown Approval Gate

After completing S1 Discovery and proposing the feature breakdown, use `AskUserQuestion`
to present the approval gate with structured options:

```python
AskUserQuestion(
    question="S1 feature breakdown ready for approval. Review the proposed breakdown "
             "in DISCOVERY.md. How would you like to proceed?",
    options=["approve as-is", "request changes", "reject scope"]
)
```

On Codex headless: present as a PR comment with the three options; parse the reply.

- **"approve as-is"**: proceed to S2.
- **"request changes"**: apply changes, re-present.
- **"reject scope"**: halt; re-open scope discussion at S1.

### Rule 1: ONE Question at a Time (Never Batch)

```text
CORRECT sequence:
  1. Ask one question
  2. Wait for user answer
  3. Update spec.md and checklist.md IMMEDIATELY
  4. Evaluate whether new questions arise
  5. Ask next question (one at a time)

WRONG:
  - Ask "Here are my 5 questions: ..."
  - Ask two questions in the same message
  - Batch questions to save round-trips
```

### Rule 1.5: INVESTIGATION COMPLETE ≠ QUESTION RESOLVED

This is the most commonly violated rule. Understand the distinction:

```text
WRONG flow:
  Agent investigates codebase → agent decides answer is clear →
  agent marks question RESOLVED → agent adds requirement to spec
  (No user ever saw or approved this)

CORRECT flow:
  Agent investigates codebase → status becomes PENDING USER APPROVAL →
  agent presents finding to user → user explicitly approves →
  agent marks RESOLVED → agent adds requirement to spec
```

Research findings replace the need to ask a question only if the finding is
objective (e.g., "the file is at this path") and not a design decision. Any
question that involves a choice, preference, or trade-off requires explicit
user approval even if you have a recommendation.

### S2.P1.I2 Checklist Resolution Gate

When the checklist reaches Iteration 2 (S2.P1.I2) and multiple plausible approaches exist
for a question, use `AskUserQuestion` to present structured options rather than free-text prose:

```python
AskUserQuestion(
    question="S2.P1.I2 — [Question N]: [brief restatement of the question]",
    options=["[option A]", "[option B]", "[option C]", "other — describe"]
)
```

For questions that are genuinely open (no predefined options make sense), fall back to a
free-text follow-up after the user selects "other — describe."

**Codex /fork variant:** When a checklist question has multiple plausible answers, on Codex
use `/fork` to explore each branch in parallel; on Claude Code, run sequential exploration
with explicit comparison before presenting the result to the user.

On Codex headless: post the question as a PR comment with a numbered list; parse the reply.

### Rule 2: Update Spec and Checklist Immediately After Each Answer

Do not batch updates. After every user answer:
- Update spec.md to reflect the new information
- Update checklist.md to mark the question resolved with the answer
- Document the user's exact words or a close paraphrase

### Rule 3: Checklist >35 Items → Stop and Propose Split

If the checklist grows past 35 items, the feature is likely too large. Stop,
propose splitting into multiple features, get user approval before splitting.
If approved, return to S1 to create the new features.

### Rule 4: Cross-Feature Alignment is Mandatory

Before finalizing the spec, compare it to ALL features already at "S2 Complete."
Look for conflicts, duplicates, and incompatible assumptions. Resolve conflicts
before proceeding. Document the alignment verification.

### Rule 5: Acceptance Criteria Require User Approval

Create an "Acceptance Criteria" section in spec.md listing exact files,
structures, and behaviors. Present it to the user and wait for explicit approval.
Document approval timestamp.

### Rule 6: Every User Answer Creates a Traceable Requirement

Source format: `"User Answer to Question N (checklist.md, YYYY-MM-DD)"`
Add to spec.md immediately. Update checklist to mark the question resolved.

---

## Protocol Part 2: Spec Refinement Validation Loop

After spec creation (checklist questions resolved, research complete), run the
10-dimension validation loop before presenting for user approval.

### Pre-Loop Setup

1. Create `spec_VALIDATION_LOG.md` in the feature folder.
2. Set `consecutive_clean: 0`.
3. Identify applicable dimensions (all 10 for feature specs).

### The 10 Dimensions (Check Every Round)

#### 7 Master Dimensions (always checked)

**D1: Empirical Verification**
Verify all file paths, class names, function signatures, and config keys from
actual source using Read/grep. NEVER from memory. Document every tool call.

**D2: Completeness**
All spec sections present (Objective, Scope, Components, Algorithms, Edge Cases,
Acceptance Criteria). All requirements enumerated. No TBD placeholders. All
integration points documented.

**D3: Internal Consistency**
No contradictory requirements. Consistent terminology throughout. Examples match
specs. Dependencies are acyclic.

**D4: Traceability**
Every requirement cites source: Epic Request / User Answer / Derived. No
"assumption" as source. Derived requirements show derivation logic. User answer
references include question number and date.

**D5: Clarity & Specificity**
No vague language ("should", "might", "probably", "appropriate", "reasonable").
Specific values (timeouts in seconds, counts as numbers). Measurable acceptance
criteria. "Must" not "should."

**D6: Upstream Alignment**
Spec aligns with DISCOVERY.md findings. No scope creep. All epic requirements
reflected. Epic intent preserved.

**D7: Standards Compliance**
Follows spec template. Naming conventions match codebase. Documentation format
matches project standards.

#### 3 Spec-Specific Dimensions

**D8: Research Completeness (embeds Gate 1)**

Question: Is ALL implementation research complete? Are there any research gaps
still in the checklist?

Checklist:
- [ ] All components to be modified identified (specific files:line numbers)
- [ ] All external dependencies verified from source code (not assumed)
- [ ] All existing patterns examined (similar features read, not guessed)
- [ ] All data formats verified (actual CSV/JSON read)
- [ ] No checklist questions are research gaps (questions the agent should have
  researched themselves)

Research gaps vs valid questions:
```text
RESEARCH GAP (should NOT be in checklist — agent should research this):
  - "What file is ConfigManager in?"
  - "What parameters does get_rank_multiplier take?"
  - "Where is the record data stored?"

VALID CHECKLIST QUESTION (requires user decision):
  - "Should we cache rank data, or reload every time?"
  - "What timeout should we use for file operations?"
  - "Should multipliers be configurable or hardcoded?"
```

Cannot pass Gate 1 if any research gaps remain in the checklist.

**D9: Scope Boundary Validation (embeds Gate 2)**

Question: Does the spec match epic scope exactly — no creep, no missing requirements?

Checklist:
- [ ] Every requirement traces to epic request, user answer, or derivation
- [ ] No features added that the user didn't request
- [ ] No "improvements" beyond stated scope (put in "Out of Scope (future)" section)
- [ ] All epic requirements present in spec
- [ ] All explicit user requests included
- [ ] All Discovery findings reflected

Cannot pass Gate 2 if any scope creep or missing requirements exist.

**D10: Design Completeness**

Question: Does the spec have enough architectural and design detail that S5
mechanical planning requires zero design decisions?

Checklist:
- [ ] All major architecture choices documented with rationale
- [ ] Component structure defined (modules, classes, functions)
- [ ] All algorithms chosen, named, and justified
- [ ] All data structures defined with types
- [ ] All function signatures specified (parameters, return types)
- [ ] All API endpoints defined (routes, methods, request/response schemas)
- [ ] All error scenarios identified with handling approach per scenario
- [ ] All file operations identified: which files will be created, modified,
  deleted, moved
- [ ] All implementation locations specified (file, class/function, approx. line)
  with enough precision for direct translation to mechanical plan steps
- [ ] No "TBD" or "appropriate" or "figure it out" in critical sections
- [ ] Builder agent could execute from this spec (via architect's mechanical plan)

Cannot exit loop if design completeness is insufficient for mechanical planning.

### Round Structure

Follow the same round structure as the master validation loop:

1. Pre-round gate (log exists, consecutive_clean recorded)
2. Re-read entire spec with fresh eyes (new reading pattern each round)
3. Check all 10 dimensions systematically
4. Verify ≥3 technical claims with tools
5. Run adversarial self-check
6. Score round, fix all issues, update consecutive_clean

Round reading patterns:
- Round 1: Sequential + traceability focus (every requirement has source)
- Round 2: Reverse + gap detection (implicit requirements, acceptance criteria)
- Round 3+: Random spot-checks + alignment (DISCOVERY.md, epic intent)

### Consecutive_clean Rules (Same as Master Protocol)

| Event | Counter Change |
|-------|---------------|
| Zero issues (pure clean) | +1 |
| Exactly 1 LOW issue found and fixed | +1 |
| 2+ LOW issues found | Reset to 0 |
| Any MEDIUM, HIGH, or CRITICAL | Reset to 0 |
| Sub-agent finds ANY issue | Reset to 0 |

### Sub-Agent Confirmation (When consecutive_clean = 1)

Spawn 2 Haiku sub-agents in parallel. Both must confirm zero issues. Sub-agents
check all 10 dimensions (not just the spec-specific ones). Sub-agents do NOT
get the 1-LOW allowance.

```python
Task(model="haiku", description="Spec validation sub-agent A",
     prompt="Re-read {spec_path} sequentially. Check all 10 dimensions
             (D1-D7 master + D8 Research Completeness, D9 Scope Boundary,
             D10 Design Completeness). Report ANY issue even LOW.
             Output: CONFIRMED: Zero issues found OR list all issues.")

Task(model="haiku", description="Spec validation sub-agent B",
     prompt="Re-read {spec_path} in reverse. Check all 10 dimensions.
             Report ANY issue even LOW.
             Output: CONFIRMED: Zero issues found OR list all issues.")
```

---

## Embedded Gates

| Gate | Location | Pass Condition |
|------|----------|----------------|
| Gate 1: Research Completeness | D8 checked every round | Zero research gaps in checklist |
| Gate 2: Spec-to-Epic Alignment | D9 checked every round | No scope creep, no missing scope |
| Gate 3: User Approval | After validation loop exits | User explicitly approves spec |

Gates 1 and 2 are embedded inside the validation loop — they pass when their
respective dimensions pass every round including sub-agent confirmation. Gate 3
is a separate step: present the validated spec to the user and wait for explicit
approval before proceeding to S5.

---

## Exit Criteria

**Validation loop is COMPLETE when ALL are true:**

- [ ] consecutive_clean = 1 (primary clean round by primary agent)
- [ ] Both Haiku sub-agents confirm zero issues
- [ ] All 10 dimensions checked every primary round
- [ ] Validation log complete with all rounds documented
- [ ] Gate 1 passed (D8): Zero research gaps
- [ ] Gate 2 passed (D9): Scope matches epic exactly
- [ ] D10 passed: Complete architectural/design detail
- [ ] All requirements have sources (Epic / User Answer / Derived)
- [ ] All acceptance criteria are measurable
- [ ] Spec is ready for Gate 3 user approval

**Cannot exit if:**
- Any research gaps remain in checklist
- Any scope creep (unrequested features in scope)
- Any missing epic requirements
- Any requirements without traceable sources
- Any vague acceptance criteria ("works correctly," "handles errors")
- Design completeness insufficient for mechanical implementation planning
- Any issue deferred

---

## Quick Reference

```
CRITICAL WORKFLOW RULES during spec creation:
  1. ONE question at a time — never batch
  1.5. INVESTIGATION COMPLETE ≠ QUESTION RESOLVED
       (needs explicit user approval, not just agent research)
  2. Update spec + checklist IMMEDIATELY after each answer
  3. >35 checklist items → stop, propose split
  4. Cross-feature alignment is mandatory
  5. Acceptance criteria require explicit user approval
  6. Every user answer → traceable requirement with source

VALIDATION LOOP (10 dimensions):
  D1–D7: Master dimensions (every loop)
  D8: Research Completeness (Gate 1 embedded) — no research gaps in checklist
  D9: Scope Boundary (Gate 2 embedded) — no creep, no missing scope
  D10: Design Completeness — enough detail for mechanical planning

EXIT: consecutive_clean = 1 + 2 Haiku sub-agents both confirm zero issues
THEN: Present spec to user for Gate 3 approval (separate from loop)
```
