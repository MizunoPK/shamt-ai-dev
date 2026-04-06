<!--
This is the S5 implementation plan template (mechanical format).
S5 produces mechanical plans with step-by-step file operations (CREATE, EDIT, DELETE, MOVE).
This plan is validated using 9 dimensions and handed off to a Haiku builder in S6.
-->

# Implementation Plan: {Feature Name}

**Architect:** {architect context - e.g., "Primary agent for EPIC-001" or "Sonnet for SHAMT-30"}
**Created:** {YYYY-MM-DD}
**Validation Status:** Not Validated

---

## Pre-Execution Checklist

- [ ] All affected files identified
- [ ] Design validated via validation loop
- [ ] Edge cases documented
- [ ] Rollback strategy defined

---

## Implementation Steps

### Step 1: {Action Description}
**File:** `path/to/file.ts`
**Operation:** {EDIT | CREATE | DELETE | MOVE}
**Details:**
{Operation-specific details}
**Verification:** {How to verify this step succeeded}

### Step 2: {Action Description}
**File:** `path/to/another/file.ts`
**Operation:** {EDIT | CREATE | DELETE | MOVE}
**Details:**
{Operation-specific details}
**Verification:** {How to verify this step succeeded}

<!-- Add more steps as needed -->

---

## Post-Execution Checklist

- [ ] All steps completed without error
- [ ] Verification checks passed
- [ ] Tests run (if applicable)
- [ ] Ready for handoff back to architect

---

## Notes

<!-- Optional section for additional context, rollback strategy, or edge case documentation -->
