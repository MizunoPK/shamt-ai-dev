# SHAMT-{N}: {Title}

**Status:** Draft | Validated | In Progress | Implemented
**Created:** {date}
**Branch:** `feat/SHAMT-{N}`
**Validation Log:** [SHAMT{N}_VALIDATION_LOG.md](./SHAMT{N}_VALIDATION_LOG.md)

---

## Problem Statement

{What problem does this solve? Why does it matter? Who is affected? What is the impact of NOT solving this?}

**Example:** "The guide sync system has no way to track which child projects have adopted improvements, making it impossible to know if a guide change has propagated successfully. This creates uncertainty around guide currency across projects."

---

## Goals

{Numbered list of what success looks like. Goals should be concrete and measurable.}

**Example:**
1. Provide a mechanism for child projects to report adoption status of master guide changes
2. Allow master repo to track which projects have adopted which changes
3. Enable notification system for critical guide updates

---

## Detailed Design

Describe your technical approach. Include multiple proposals if appropriate.

### Proposal 1: {Title}

**Description:** {How does this approach work? What are the key components or steps?}

**Rationale:** {Why is this a good solution? What makes it better than alternatives?}

**Alternatives considered:** {What other approaches did you evaluate and why were they rejected?}

### Proposal 2: {Title}

{Repeat structure for alternative approaches}

**Recommended approach:** {State which proposal is recommended and why, based on specific reasoning}

---

## Files Affected

Document all files that will be created, modified, or deleted. Use a table for clarity:

| File | Status | Notes |
|------|--------|-------|
| `path/to/file.md` | CREATE | New guide file |
| `path/to/other.md` | MODIFY | Add new section |
| `old_file.md` | DELETE | Replaced by new approach |

---

## Implementation Plan

Break the work into logical phases with concrete, actionable steps. Each phase should produce tangible output.

### Phase 1: {Name}
{Brief description of what this phase accomplishes}
- [ ] Step 1 {specific action}
- [ ] Step 2 {specific action}
- [ ] Step 3 {verification or output}

### Phase 2: {Name}
{Brief description}
- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

**Note:** Each step should be actionable and verifiable. Define success criteria for each phase.

---

## Validation Strategy

Describe how you will verify that the implementation is correct and complete. Include:
- **Primary validation:** Design doc validation loop (7 dimensions)
- **Implementation validation:** After code is complete, verify against design (5 dimensions)
- **Testing approach:** Manual testing, automated checks, or both
- **Success criteria:** What specific outcomes prove success?

**Example:** "Run design doc validation loop (7 dimensions) until 3 consecutive clean rounds. After implementation, run implementation validation (5 dimensions). Verify all files listed in 'Files Affected' were created/modified as specified."

---

## Open Questions
{Unresolved decisions that need user input}

---

## Risks & Mitigation
{What could go wrong and how do we handle it?}

---

## Change History

| Date | Change |
|------|--------|
| {date} | Initial draft created |
