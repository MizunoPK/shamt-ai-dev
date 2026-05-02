# Audio Journals — AJ-2 Google Drive Integration Guide Update Proposals

**Status:** Pending Implementation
**Created:** 2026-05-01
**Source Epic:** AJ-2-google_drive_integration
**Proposals:** 2 accepted, 0 modified, 0 rejected

---

## Overview

AJ-2 implemented Google Drive integration (OAuth 2.0 auth, audio file listing/download, shared retry utility, Config/DB v2 migration). S9.P4 epic review found that per-file skip logging required by R8 was absent — caught at epic review level rather than the earlier S7.P3 feature review. Root cause: D13 Implementation Fidelity does not require checking spec-enumerated sub-items, only that requirement categories are addressed. Separately, a pre-planned test file entry in ARCHITECTURE.md became stale when a S2 testing approach question changed test scope; no guide step prompted updating ARCHITECTURE.md at that point.

---

## Proposal P2-1: D13 — Add spec-enumerated sub-item check to Implementation Fidelity

**Priority:** P2
**Affected Guide:** `.shamt/guides/code_review/code_review_workflow.md`
**Section:** Dimension 13 table row

### Problem

R8 enumerated specific logging items including "Skip messages for already-processed files." The implementation had a general debug log but no per-file skip INFO log. D13 passed at S7.P3 because R8 "had logging," but the specific sub-items were not individually verified. The gap was caught only at S9.P4 (epic review). A requirement with sub-items can satisfy "all requirements addressed" while missing specific sub-items.

### Current State

```markdown
| 13 | **Implementation Fidelity** | Every proposal in the validated implementation plan has corresponding code changes; all spec requirements are addressed in implementation; no scope creep (no features not in spec); no missing features (all spec requirements fully implemented) |
```

### Proposed Change

```markdown
| 13 | **Implementation Fidelity** | Every proposal in the validated implementation plan has corresponding code changes; all spec requirements are addressed in implementation; no scope creep (no features not in spec); no missing features (all spec requirements fully implemented). For requirements that enumerate specific items (e.g., logging messages, error message text, output formats), verify each enumerated item is present — not just that the requirement category is addressed. |
```

### Rationale

This addition forces reviewers to check at sub-item granularity, not just category level. Without it, a requirement like "R8 logging: skip messages, retry messages, download progress" can pass D13 if any logging exists, regardless of which items are present. The one-sentence addition is minimal but closes a class of missed-sub-requirement issues that otherwise survive to epic review.

---

## Proposal P3-1: S2 I2 — Check ARCHITECTURE.md after testing scope question resolves

**Priority:** P3
**Affected Guide:** `.shamt/guides/stages/s2/s2_feature_deep_dive.md`
**Section:** I2 — Checklist Resolution

### Problem

Testing approach Q3 for F01 resolved to "Testing Approach B — no unit tests." ARCHITECTURE.md's directory structure had a pre-planned `tests/test_retry.py` entry. No guide step prompted checking ARCHITECTURE.md after a testing scope decision. The stale entry persisted to S7.P3 Step 1b (Documentation Impact Assessment) where it was caught and removed as a separate action.

### Current State

```markdown
**I2 — Checklist Resolution (45-90 min):**
- Resolve all checklist questions with user ONE at a time
- Update spec.md in real-time after each answer
```

### Proposed Change

```markdown
**I2 — Checklist Resolution (45-90 min):**
- Resolve all checklist questions with user ONE at a time
- Update spec.md in real-time after each answer
- After resolving any question that changes test scope (e.g., testing approach): check ARCHITECTURE.md directory structure for pre-planned test file entries that this decision makes stale; remove them now rather than discovering them in S7.P3.
```

### Rationale

Testing approach decisions made in S2 can silently invalidate pre-planned test file entries in ARCHITECTURE.md. A one-line reminder at the point of Q-resolution costs nothing and prevents the stale entry from persisting through S5–S6 to S7.P3, where it requires a separate fix commit.

---

## Rejected Proposals (for reference)

*(None — both proposals approved)*

---

## Implementation Notes

- Apply both proposals as a single batch
- Run full guide audit (primary clean round + sub-agent confirmation) before committing
- Update `reference/guide_update_tracking.md` with implementation entry
- Delete this file from `unimplemented_design_proposals/` after successful implementation and commit
