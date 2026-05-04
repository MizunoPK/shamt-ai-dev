---
name: shamt-lite-plan
description: >
  Run the Shamt Lite Implementation Planning protocol — read the validated spec,
  draft a mechanical step-by-step plan, validate it via the Lite validation loop,
  and either execute yourself or hand off to a Haiku builder. Outputs
  stories/{slug}/implementation_plan.md ready for Build phase.
triggers:
  - "plan this"
  - "create an implementation plan"
  - "shamt lite plan"
  - "plan from spec"
source_guides:
  - scripts/initialization/SHAMT_LITE.template.md
  - scripts/initialization/story_workflow_lite.template.md
  - scripts/initialization/templates/implementation_plan_lite.template.md
master-only: false
---

## Overview

Encodes Pattern 5 (Implementation Planning) from `SHAMT_LITE.md`. Use after spec is approved (Gate 2b), before Build.

**Output:** `stories/{slug}/implementation_plan.md`, validated and approved by user (Gate 3). Optionally hand off execution to a Haiku builder for material token savings on plans with >10 mechanical steps.

---

## When This Skill Triggers

- After spec approval (Gate 2b), before Build
- User says "plan this", "create an implementation plan", or "plan from spec"
- Any non-trivial feature or change involving multiple file operations
- When implementation will be delegated to a builder agent

---

## Inputs Required

- **Slug** — story slug; story folder exists with validated `spec.md`
- (or) **Spec path** — for non-story planning, the brief or spec to plan from

---

## Protocol — The 5-Step Process

### Step 1 — Read spec completely

Read `stories/{slug}/spec.md` (or the feature brief). Confirm all design decisions are resolved before creating the plan.

If unresolved Open Questions exist in the spec → halt and return to Spec phase.

### Step 2 — Create mechanical implementation plan

Write `stories/{slug}/implementation_plan.md` (use `templates/implementation_plan.template.md`). Each step must be **mechanical** — no design decisions left for the executor.

**Plan format:**

```markdown
# Implementation Plan

**Created:** [Date]
**Feature/Task:** [Brief description]
**Related:** stories/{slug}/spec.md

---

## Implementation Steps

### Step N: [Clear action description]
**Operation:** CREATE | EDIT | DELETE | MOVE
**File:** `path/to/file.ext`
**Details:**
- [Operation-specific details]

**Verification:** [How to verify — required when success depends on tooling]

---

## Notes

[Optional: gotchas, constraints, reminders]
```

**Operation formats:**

- **CREATE:** Specify file purpose and initial content (or reference template)
- **EDIT:** Exact locate string (5-10 lines context) + exact replacement string
- **DELETE:** File/section to delete + justification
- **MOVE:** Source → destination + reason

**Verification guidance:**

*Required when success depends on tooling:*
- Step compiles code, runs tests, or invokes linter
- Step adds a new API endpoint or config value loaded at runtime
- Step modifies a database schema or migration

*Optional (omit if self-evident):*
- Pure text replacements (typo fixes, wording changes)
- Markdown / docs / comment edits with no code impact
- Reordering imports for style

**Suggested model:** Sonnet (structured, pattern-following).

### Step 3 — Validate plan (7 plan dimensions)

Invoke the `shamt-lite-validate` skill with `artifact = stories/{slug}/implementation_plan.md`, `type = plan`. Exit: primary clean round + 1 Haiku sub-agent confirmation.

The 7 plan dimensions: Step Clarity, Mechanical Executability, File Coverage, Operation Specificity, Verification Completeness, Dependency Ordering, Requirements Alignment.

### Step 4 — User approval (Gate 3)

Present the validated plan to the user. User approves or requests changes.

Suggest: "Plan approved. Consider `/clear` before starting the Build phase."

### Step 5 — Execute (or hand off to a builder)

**Option A — Execute yourself.** Work through steps sequentially. Run verification after each step that requires it.

**Option B — Haiku builder handoff (recommended for >10 mechanical steps):**

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">{cheap-tier}</parameter>
  <parameter name="description">Execute implementation plan</parameter>
  <parameter name="prompt">You are a builder executing a validated implementation plan.

**Plan:** stories/{slug}/implementation_plan.md

**Critical rules:**
1. Follow steps exactly as written — make ZERO design decisions
2. Execute sequentially (Step 1, then 2, then 3...)
3. Run verification after each step that specifies one
4. If verification fails: STOP and report to architect
5. If any step is unclear: STOP and report to architect

**Report:**
- Success: "All steps completed."
- Error: "Step N failed: [describe what failed]"
- Unclear: "Step N is ambiguous: [describe ambiguity]"
  </parameter>
</invoke>
```

`{cheap-tier}` resolves to: `haiku-4-5` on Claude Code; `${DEFAULT_MODEL}` on Codex; `inherit` on Cursor.

**When to use builder handoff:** Plan has >10 steps + execution is truly mechanical (no design decisions needed during execution).

**When to skip builder handoff:** Small plans (1-5 steps), exploratory plans, plans with embedded design decisions.

After execution: test the feature against spec requirements. Verify no unintended side effects. If builder reports errors, diagnose, fix the plan, re-run or take over.

---

## Exit Criteria

- `stories/{slug}/implementation_plan.md` exists with each step mechanical
- Validation footer appended (`✅ Validated {date} — N rounds, 1 sub-agent confirmed`)
- User has explicitly approved (Gate 3)
- (Optional) Builder handoff complete and verified

---

## Common Mistakes

- **Steps that aren't mechanical.** "Write the function that handles X" is design, not mechanism. Spell out the function signature, body, and where it goes.
- **Missing locate strings on EDIT.** Without exact 5-10 line locate context, the executor can't safely apply the edit.
- **Skipping verification on tooling-dependent steps.** A step that adds an API endpoint without a verification check will fail silently downstream.
- **Handing off plans with <10 steps to a builder.** Overhead exceeds savings for small plans.
