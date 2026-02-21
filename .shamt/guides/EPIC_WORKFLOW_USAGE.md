# Shamt Epic Workflow — Comprehensive Usage Guide

This file provides a complete overview of the Shamt S1–S10 epic-driven development workflow.

**For stage-specific detail:** Read the full guide for each stage (listed below).
**For phase transition prompts:** See `prompts_reference_v2.md` or `prompts/`

---

## Workflow Overview

```
S1: Epic Planning → S2: Feature Deep Dives → S3: Cross-Feature Sanity Check →
S4: Epic Testing Strategy → S5-S8: Feature Loop → S9: Epic Final QC → S10: Epic Cleanup

Per-feature loop: S5 (Plan) → S6 (Execute) → S7 (Test) → S8 (Align) → repeat or S9
```

**Notation:**
- **S#** = Stage (e.g., S1, S5)
- **S#.P#** = Phase (e.g., S2.P1, S5.P1)
- **S#.P#.I#** = Iteration (e.g., S5.P1.I2)

---

## Stage-by-Stage Detailed Workflows

### S1: Epic Planning

**Guide:** `stages/s1/s1_epic_planning.md`

Key activities:
- Assign KAI/SHAMT number (ask user for next available or custom)
- Create epic folder and EPIC_README.md
- Create git branch: `{work_type}/{EPIC_TAG}-{N}`
- Run S1.P3 Discovery Phase (MANDATORY — research loop until 3 consecutive clean iterations)
- Break epic into features
- Get user approval on feature breakdown

**Outputs:** Epic folder, EPIC_README.md, feature folder structure, git branch

---

### S2: Feature Deep Dives

**Guide:** `stages/s2/s2_feature_deep_dive.md`

Key activities:
- For each feature: create `spec.md`, `checklist.md`, `RESEARCH_NOTES.md`
- Run S2.P1 Spec Creation Refinement Validation Loop (Gates 1, 2, 3)
- Gate 3: User approval of checklist (all questions answered before S5)

**Parallelization option:** `parallel_work/s2_parallel_protocol.md` (3+ features)

**Outputs:** `spec.md`, `checklist.md`, `RESEARCH_NOTES.md` per feature

---

### S3: Cross-Feature Alignment and Epic Strategy

**Guide:** `stages/s3/s3_epic_planning_approval.md`

Key activities:
- Review all feature specs for conflicts and gaps
- Write epic testing strategy and documentation
- Gate 4.5: User approval (3-tier rejection handling)

**Outputs:** Epic testing strategy, cross-feature alignment documented

---

### S4: Feature Testing Strategy

**Guide:** `stages/s4/s4_feature_testing_strategy.md`

Key activities:
- For each feature: create `test_strategy.md`
- Run validation loop (4 iterations)

**Outputs:** `test_strategy.md` per feature

---

### S5: Implementation Planning (Per Feature)

**Guide:** `stages/s5/s5_v2_validation_loop.md`

Two-phase approach:
1. **Draft Creation** (60-90 min): Write `implementation_plan.md`
2. **Validation Loop** (3.5-6 hours): 11 dimensions, 3 consecutive clean rounds required

Gate 5: User approval of implementation plan (3-tier rejection handling)

**Outputs:** `implementation_plan.md` (user-approved)

---

### S6: Execution (Per Feature)

**Guide:** `stages/s6/s6_execution.md`

Key activities:
- Create `implementation_checklist.md`
- Implement code following implementation plan
- Track progress in checklist

**Outputs:** Implemented code, `implementation_checklist.md`

---

### S7: Testing and Review (Per Feature)

**Guides:**
- `stages/s7/s7_p1_smoke_testing.md` — S7.P1 Smoke Testing
- `stages/s7/s7_p2_qc_rounds.md` — S7.P2 QC Rounds (3 rounds)
- `stages/s7/s7_p3_final_review.md` — S7.P3 Final Review

**🚨 Restart Protocol:** If ANY issues found → restart from S7.P1 (not just fix and continue)

**Outputs:** Feature committed to git, `lessons_learned.md`

---

### S8: Cross-Feature Alignment (Per Feature)

**Guides:**
- `stages/s8/s8_p1_cross_feature_alignment.md` — Update remaining feature specs
- `stages/s8/s8_p2_epic_testing_update.md` — Update epic smoke test plan

**After S8:** Either start S5 for next feature (if more features) or proceed to S9

---

### S9: Epic Final QC

**Guide:** `stages/s9/s9_epic_final_qc.md`

**Guides:**
- `stages/s9/s9_p1_epic_smoke_testing.md` — Epic smoke test
- `stages/s9/s9_p2_epic_qc_rounds.md` — Epic QC Validation Loop (3 rounds)
- `stages/s9/s9_p3_user_testing.md` — User testing (ZERO bugs required)
- `stages/s9/s9_p4_epic_final_review.md` — Final review

**🚨 Restart Protocol:** If ANY issues found → restart from S9.P1

**Exit criteria:** User reports ZERO bugs, all tests pass

---

### S10: Epic Cleanup

**Guide:** `stages/s10/s10_epic_cleanup.md`

Key activities:
- Run unit tests (100% pass required)
- Verify all documentation
- S10.P1 Guide Updates (MANDATORY — analyze lessons, propose changes, get user approval, apply, write changelog if universal)
- Commit epic work
- Move epic to `done/` folder
- Update `EPIC_TRACKER.md`
- Create PR for user review

---

## Setup and First Use

1. Initialize Shamt in your project: run `init.sh` or `init.ps1` from `.shamt/initialization/`
2. Tell your AI agent: "Read `.shamt/init_config.md` and complete the Shamt initialization."
3. Start your first epic: tell your agent "Help me develop [epic description]"
4. Agent starts at S1 — reads `stages/s1/s1_epic_planning.md`

---

## Common Patterns

### Starting a New Epic
- Agent starts S1, assigns next SHAMT number, creates branch
- Runs Discovery Phase (S1.P3) — research loop
- Breaks epic into features, gets user approval

### Resuming In-Progress Work
- Check `.shamt/epics/` for active epic folders
- Read EPIC_README.md → Agent Status section
- Read the guide listed in Agent Status
- Continue from exact step listed

### Debugging Protocol
When issue root cause is unknown: `debugging/debugging_protocol.md`

### Missed Requirement Protocol
When new requirement discovered: `missed_requirement/missed_requirement_protocol.md`

---

## Quick Reference

**Phase transition prompts (MANDATORY):** `prompts_reference_v2.md` or `prompts/`

**Gate reference:** `reference/mandatory_gates.md`

**Common mistakes:** `reference/common_mistakes.md`

**Git conventions:** `reference/GIT_WORKFLOW.md`

**Decision tree:** `reference/PROTOCOL_DECISION_TREE.md`

**Audit system:** `audit/README.md`

**Changelog system:** `changelog_application/`
