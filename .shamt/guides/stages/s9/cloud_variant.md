# S9 Cloud-Native Variant — Codex Cloud Epic QC Fan-Out

**Applies to:** Codex Cloud users running the S9 epic-level QC phase.

This guide supplements the S9 stage guides (`s9_epic_final_qc.md`, `s9_p1_epic_smoke_testing.md`, `s9_p2_epic_qc_rounds.md`, `s9_p3_user_testing.md`, `s9_p4_epic_final_review.md`). Read those guides for the full S9 protocol. This guide describes only what differs when epic-level QC runs as parallel Codex Cloud tasks.

---

## S9 vs. S7 Cloud Fan-Out

S9 epic QC has the same shape as S7 feature QC fan-out — parallel cloud tasks per validation dimension — but operates at epic scope:

| | S7 (feature QC) | S9 (epic QC) |
|---|---|---|
| Subject | single feature PR | entire epic (all features combined) |
| Validation scope | feature-level correctness, edge cases | cross-feature integration, epic acceptance criteria |
| Fan-out tasks | one per S7 dimension | one per S9 dimension (larger scope per task) |
| Duration | faster (feature scope) | slower (epic scope — longer cloud task runtime) |

The cloud architecture is identical: parallel Codex Cloud tasks with `shamt-validator` profile, all read-only, collected and aggregated by the primary agent.

---

## When to Use the Cloud Variant

Use the S9 cloud epic QC when:
- The S6 and S7 cloud variants were used — natural continuation
- The epic is large (many features, many validation dimensions — parallel tasks save hours)
- You want container-isolated validation (no shared state between validators)

---

## Epic QC Fan-Out Flow

```
Primary agent (CLI / IDE)
  ↓ merges all feature PRs to the epic integration branch
  ↓ for each S9 epic validation dimension:
       ↓ launches a parallel cloud task with shamt-validator profile
       ↓ each task validates one dimension of the full epic
  ↓ aggregates results
  ↓ applies fixes, re-runs failed dimensions
  → passes when all epic dimensions pass
  → proceeds to S9.P3 user testing (same as CLI)
```

---

## Step-by-Step

### Step 1 — Prepare the epic integration branch

Ensure all feature PRs are merged to the epic integration branch and the branch is pushed. Cloud tasks run against this branch.

### Step 2 — Define S9 epic validation dimensions

Use the full dimension list from `s9_p2_epic_qc_rounds.md`: **7 Master Dimensions + 6 Epic-Specific Dimensions (D8–D13: Cross-Feature Integration, Epic Cohesion, Error Handling Consistency, Architectural Alignment, Success Criteria Completion, Mechanical Code Quality Epic-Wide) = 13 total**. Read that guide for the complete list. One cloud task per dimension.

### Step 3 — Launch parallel cloud tasks

Same pattern as S7 cloud fan-out. One cloud task per S9 dimension, all with:
- Profile: `shamt-validator`
- Branch: epic integration branch
- Prompt: S9-dimension-specific validation prompt

### Step 4 — Aggregate, fix, and re-run

Same as S7 cloud fan-out. Apply fixes, re-run failed dimensions. When all pass, exit criterion is met.

### Step 5 — S9.P3 and S9.P4 (no cloud change)

S9.P3 user testing and S9.P4 epic final review proceed as described in the CLI guides — these phases involve human interaction and are not cloud-automated.

---

## Cloud Task Runtime Budgeting

Epic-scope cloud tasks are larger than feature-scope tasks. Budget accordingly:
- Each S9 cloud validator may run 5-15 minutes depending on epic size
- If the epic has N dimensions and each task runs T minutes, parallel fan-out takes ~T minutes total (vs. N×T sequentially)
- Codex Cloud tasks beyond their timeout are discarded cleanly — no damage

If a cloud task times out, split the dimension into sub-dimensions and re-run.

---

## Cross-reference

- **CLI S9 protocol:** `s9_p2_epic_qc_rounds.md`
- **S7 cloud QC fan-out:** `s7/cloud_variant.md`
- **shamt-validator profile:** `.shamt/host/codex/profiles/shamt-validator.fragment.toml`
- **Validation loop cloud variant:** `reference/validation_loop_master_protocol.md`
