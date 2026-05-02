# FantasyFootballHelperScripts — KAI-17-schedule_fetcher_enhancements Guide Update Proposals

**Status:** Pending Implementation
**Created:** 2026-04-30
**Source Epic:** KAI-17-schedule_fetcher_enhancements
**Proposals:** 4 accepted, 0 modified, 0 rejected

---

## Overview

KAI-17 added CLI flags, resilience improvements, and an E2E offline integration test to the schedule fetcher pipeline across 3 features (F1: CLI flags, F2: resilience, F3: E2E test). During S7.P3 reviews and S9.P4 epic review, several workflow process gaps were identified: an S7.P2/P3 commit sequencing issue that caused stale sub-agent reviews, deferral of lessons_learned.md fills leading to lower-quality retrospective summaries, a missing required S6 artifact that interrupted S7.P1 smoke testing, and a CRLF line ending class of issue not covered by D17 mechanical checks.

---

## Proposal P1-1: Commit S7.P2 fixes before spawning S7.P3 review sub-agent

**Priority:** P1
**Affected Guide:** `.shamt/guides/stages/s7/s7_p3_final_review.md`
**Section:** Step 1 preamble (before "Spawn fresh sub-agent")

### Problem

In F1, S7.P2 fixes were applied locally and then the S7.P3 fresh sub-agent was spawned without committing first. The sub-agent read from the pre-fix S6 commit state and flagged 2 issues that were already fixed locally — creating spurious findings that required extra explanation in the comment response log. Root cause: the S7.P3 guide does not require a commit step between S7.P2 completion and S7.P3 sub-agent spawn.

### Current State

```markdown
(Guide instructs to spawn sub-agent after S7.P2 completes, without an explicit commit step)
```

### Proposed Change

```markdown
Before spawning the S7.P3 fresh sub-agent: commit all S7.P2 fixes. The sub-agent reads
from committed files; uncommitted fixes are invisible to it, causing already-resolved
findings to appear in the review.
```

Add as a mandatory step between S7.P2 completion and S7.P3 sub-agent spawn in `s7_p3_final_review.md`.

### Rationale

Prevents the sub-agent from reviewing stale code. Eliminates spurious findings that require extra documentation to explain ("already fixed before the review ran"). One commit step eliminates the ambiguity entirely.

---

## Proposal P2-1: Fill lessons_learned.md sections at stage boundary, not retrospectively

**Priority:** P2
**Affected Guide:** `.shamt/guides/templates/epic_lessons_learned_template.md` and/or per-stage guides
**Section:** Template header / stage completion instructions

### Problem

The `epic_lessons_learned.md` template uses `{To be filled after SN}` placeholders throughout. Agents interpret this as license to defer all fills until S10, when context on S2–S8 events is stale and summaries become generic. In KAI-17, S2 cross-feature captures and per-stage sections were deferred and not populated until the retrospective fill at S10.

### Current State

```markdown
Template uses `{To be filled after SN}` in all sections with no reminder to fill immediately
at stage completion.
```

### Proposed Change

```markdown
Fill this file at the END of each stage, not retrospectively at S10. Each section should
be populated while events are fresh — S2 section after S2, S3 section after S3, etc.
```

Add as a reminder at the top of `epic_lessons_learned_template.md` (and optionally reinforce in each stage's guide at the stage-completion checkpoint).

### Rationale

Stage-by-stage captures are higher quality (fresh context). Retrospective fills at S10 miss details and produce generic summaries. A single reminder at the top of the template changes the behavior at low cost.

---

## Proposal P2-2: `implementation_checklist.md` as required S6 artifact

**Priority:** P2
**Affected Guide:** `.shamt/guides/stages/s6/` builder handoff instructions (or implementation plan template)
**Section:** Builder handoff checklist

### Problem

In F2, the Haiku builder completed S6 without creating `implementation_checklist.md`. The gap was not caught until S7.P1 prerequisites check, which interrupted the smoke testing flow and required manual creation out-of-band. Root cause: the S6 builder handoff does not list `implementation_checklist.md` as a required output — it only appears as a prerequisite item in S7.P1, which is too late to catch it.

### Current State

```markdown
Builder handoff does not list `implementation_checklist.md` as a required artifact.
It is only verified in S7.P1 prerequisites.
```

### Proposed Change

```markdown
Required artifacts before S6 is complete: (1) all code changes committed, (2) tests
passing, (3) `implementation_checklist.md` created and all items verified. If
`implementation_checklist.md` does not exist, create it before handoff.
```

Add to the S6 builder handoff checklist in `stages/s6/` guide(s).

### Rationale

Catches the gap at S6 (where it can be fixed in context) rather than at S7.P1 (where fixing it breaks the smoke testing flow). One explicit checklist item prevents a manual recovery step.

---

## Proposal P3-1: Add CRLF line ending check to S7.P2 D17

**Priority:** P3
**Affected Guide:** `.shamt/guides/stages/s7/s7_p2_qc_rounds.md`
**Section:** D17 checklist (Mechanical Code Quality)

### Problem

In F3, `pytest.ini` was silently converted from LF to CRLF by a Windows editor. The issue was caught at S7.P3 PR review — one stage later than it could have been. D17 covers tabs, whitespace, imports, and formatting, but not line endings. CRLF issues cause `pytest.ini` markers to fail silently on Linux and are invisible in most diff views.

### Current State

```markdown
D17 does not include a line endings check.
```

### Proposed Change

```markdown
[ ] Line endings: all files use LF (Unix), not CRLF (Windows). Check:
    `grep -Pl '\r' {new_files}` should return no output.
```

Add to D17 (Mechanical Code Quality) checklist in `s7_p2_qc_rounds.md`.

### Rationale

A one-line check in D17 catches this class of issue before S7.P3, particularly for config files (`pytest.ini`, `.cfg`, etc.) added in cross-platform environments.

---

## Rejected Proposals (for reference)

| ID | Title | Priority | Reason Rejected |
|----|-------|----------|-----------------|
| (none) | — | — | All 4 proposals approved |

---

## Implementation Notes

- Apply all proposals as a single batch
- Run full guide audit (3 consecutive clean rounds) before committing
- Update `reference/guide_update_tracking.md` with implementation entry
- Delete this file from `unimplemented_design_proposals/` after successful implementation and commit
