# FantasyFootballHelperScripts — KAI-14-critical_correctness_bugs Guide Update Proposals

**Status:** Pending Implementation
**Created:** 2026-03-26
**Source Epic:** KAI-14-critical_correctness_bugs
**Proposals:** 2 accepted, 0 modified, 0 rejected

---

## Overview

KAI-14 fixed four confirmed correctness bugs in a fantasy football data pipeline: a multi-year loop returning early, week-18 schedule exclusion, historical/live JSON format mismatch, and a missing empty-response guard. During the epic's S6-S9 workflow, two recurring patterns emerged that current guides do not address explicitly: (1) agents creating new test files sometimes incorrectly remove CODING_STANDARDS-required docstrings due to an ambiguous S6 self-check rule, and (2) S7.P2 has no explicit checklist item for verifying that new public symbols (constants, classes, methods) added by the feature have adequate documentation. Both gaps produce late findings (S7.P3 and S9.P4 respectively) that require extra QC rounds.

---

## Proposal P2-1: Add new-public-symbol documentation check to S7.P2 D12

**Priority:** P2
**Affected Guide:** `stages/s7/s7_p2_qc_rounds.md`
**Section:** Dimension 12 — Requirements Completion

### Problem

`MIN_EXPECTED_PLAYER_COUNT = 100` was added in S6 without an explaining comment. The S7.P2 validation loop has no explicit checklist item for "new public symbols have adequate documentation." D12 broadly covers "zero tech debt" but agents focus on functional requirements, not documentation completeness for newly-added symbols. The gap was caught in S9.P4 PR review (three LOW-priority documentation findings), adding an extra review round.

### Current State

D12 appears only in the summary table:

```markdown
12. Requirements Completion - 100% complete, zero tech debt
```

And in Critical Success Factors:

```markdown
- Zero tech debt tolerance (100% or INCOMPLETE)
```

There is no detailed D12 checklist equivalent to D13–D16 (which each have their own bullet lists).

### Proposed Change

Add a D12 detailed checklist after the D13–D16 section in `s7_p2_qc_rounds.md`:

```markdown
**Dim 12 — Requirements Completion:**
- [ ] All spec.md acceptance criteria verified (grep for each AC, trace to implementation)
- [ ] All TODO / placeholder items resolved — no `{TBD}`, `{fill in later}`, or `pass` in implementation
- [ ] New public symbols (module-level constants, public classes, public methods) added by this
  feature have adequate documentation per CODING_STANDARDS:
  - Named constants: explaining comment (purpose + rationale)
  - New classes: class docstring
  - New public methods: method docstring with Args/Returns
  - Format-change outputs: updated docstrings reflecting the new format
- [ ] Zero tech debt — no deferred decisions, no known-broken paths left
```

### Rationale

Adding an explicit bullet for new public symbol documentation makes the requirement concrete rather than relying on agents inferring it from "zero tech debt." The missing `MIN_EXPECTED_PLAYER_COUNT` comment was a direct result of S7.P2 not having this explicit check — it was caught three stages later in S9.P4 instead.

---

## Proposal P3-1: S6 Section 4.4 — Clarify CODING_STANDARDS docstrings on new test files

**Priority:** P3
**Affected Guide:** `stages/s6/s6_execution.md`
**Section:** Section 4.4: Code Comments Self-Check

### Problem

S6 Section 4.4 says "Remove all [inline comments, docstrings, or explanatory block comments]" with exception "Any overrides documented in CODING_STANDARDS.md." This exception is too vague — an agent creating a new test file removes all docstrings (treating them as added commentary) without recognizing that CODING_STANDARDS-required module/class/method docstrings are required overrides that MUST remain. This caused feature_01's new test file to lack module docstring, class docstring, and 3 method docstrings — caught in S7.P3 Round 1.

### Current State

```markdown
### 4.4: Code Comments Self-Check

Scan all code you have written or modified in this feature — including test files — for any inline
comments, docstrings, or explanatory block comments. Remove all of them.

**Allowed to remain:**
- License/copyright headers
- Tool-required markers (`# type: ignore`, `# noqa`, `// eslint-disable-next-line`, etc.)
- Any overrides documented in CODING_STANDARDS.md
```

### Proposed Change

```markdown
### 4.4: Code Comments Self-Check

Scan all code you have written or modified in this feature — including test files — for any inline
comments, docstrings, or explanatory block comments. Remove all of them.

**Allowed to remain:**
- License/copyright headers
- Tool-required markers (`# type: ignore`, `# noqa`, `// eslint-disable-next-line`, etc.)
- Any overrides documented in CODING_STANDARDS.md
- **CODING_STANDARDS-required docstrings on NEW files you created in this feature:** If
  CODING_STANDARDS requires module docstrings, class docstrings, and public method docstrings,
  a new test file you created MUST have them. Do NOT apply the "remove all docstrings" rule to
  required documentation on new files. Apply it only to unnecessary inline comments and
  explanatory text you added to existing files beyond what CODING_STANDARDS requires.
```

### Rationale

The explicit clarification prevents agents from misapplying the "remove all docstrings" rule to new files where docstrings are required by CODING_STANDARDS. The current "Any overrides documented in CODING_STANDARDS.md" bullet is technically correct but too brief — agents don't recognize that module/class/method docstrings on new test files are "required overrides."

---

## Rejected Proposals (for reference)

| ID | Title | Priority | Reason Rejected |
|----|-------|----------|-----------------|
| — | — | — | No rejections — both proposals approved |

---

## Implementation Notes

- Apply both proposals as a single batch
- Run full guide audit (3 consecutive clean rounds) before committing
- Update `reference/guide_update_tracking.md` with implementation entry
- Delete this file from `unimplemented_design_proposals/` after successful implementation and commit
