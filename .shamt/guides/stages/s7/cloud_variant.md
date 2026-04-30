# S7 Cloud-Native Variant — Codex Cloud QC Fan-Out

**Applies to:** Codex Cloud users running the S7 QC phase.

This guide supplements the S7 stage guides (`s7_p1_smoke_testing.md`, `s7_p2_qc_rounds.md`, `s7_p3_final_review.md`). Read those guides first for the full S7 protocol. This guide describes only what differs when QC validation rounds run as parallel Codex Cloud tasks.

---

## When to Use the Cloud Variant

Use the cloud QC fan-out when:
- The feature PR has many validation dimensions to check (>4 dimensions in parallel)
- You want to run all dimensions simultaneously rather than sequentially
- The S6 cloud builder was used — QC is a natural continuation in cloud

Use the CLI variant when:
- Budget is a concern (parallel cloud tasks multiply cost)
- The feature is simple and sequential validation is fast enough
- You need interactive follow-up after each round

---

## Cloud QC Fan-Out Flow

```
Architect / Primary agent (CLI / IDE)
  ↓ reviews PR opened by S6 cloud builder
  ↓ for each validation dimension:
       ↓ launches a parallel cloud task with shamt-validator profile
       ↓ each task reads the PR diff + validation guides
       ↓ each task produces a structured validation report
  ↓ aggregates results from all tasks
  ↓ applies fixes if needed
  ↓ re-runs failed dimensions (new cloud tasks)
  → passes when all dimensions report zero issues
```

In the CLI variant, validation dimensions run sequentially under `consecutive_clean` tracking. In the cloud variant, all dimensions run in parallel — each cloud task is one dimension, and they all run in isolated containers simultaneously.

---

## Step-by-Step

### Step 1 — Define validation dimensions for this feature

Before launching, list the dimensions to validate (from `s7_p2_qc_rounds.md`):
- D1: Correctness
- D2: Edge cases
- D3: Security
- D4: Performance
- D5: Test coverage
- D6: Documentation
- D7+: Feature-specific dimensions

### Step 2 — Launch parallel cloud tasks

For each dimension, start a Codex Cloud task with:
- Profile: `shamt-validator`
- Branch: the feature PR branch
- Prompt: dimension-specific validation prompt from the S7 guides

Cloud tasks run simultaneously. The `shamt-validator` profile uses:
- Model: `FRONTIER_MODEL` (Opus equivalent) — deep validation, full reasoning
- Reasoning effort: `low`
- Sandbox: `read-only` (validators never write)
- Approval policy: `never` (fully automatic — no human approval required per dimension)

### Step 3 — Collect and aggregate results

Wait for all cloud tasks to complete. Each produces a validation report. Aggregate:
- PASS dimensions — noted, no action
- FAIL dimensions — collect issues, apply fixes to the PR branch

### Step 4 — Re-run failed dimensions

After applying fixes, re-run only the failed dimensions as new cloud tasks (don't re-run passing dimensions). Repeat until all dimensions pass.

### Step 5 — Continue to S7.P3 Final Review

When all cloud QC dimensions pass, proceed to `s7_p3_final_review.md` (same as CLI variant).

---

## Mapping to consecutive_clean

The cloud fan-out replaces the sequential `consecutive_clean` tracking:
- **Cloud equivalent of consecutive_clean=1:** all parallel tasks pass in a single fan-out
- **Cloud equivalent of 2 sub-agent confirmations:** 2 independent cloud tasks (different container instances) both confirm zero issues for the same artifact

You do not need to run 3 sequential rounds in the cloud variant. One parallel fan-out where all tasks pass = exit criterion met (analogous to primary clean round + 2 confirmations).

---

## Cross-reference

- **CLI S7 protocol:** `s7_p2_qc_rounds.md`
- **shamt-validator profile:** `.shamt/host/codex/profiles/shamt-validator.fragment.toml`
- **S6 cloud builder:** `s6/cloud_variant.md`
- **S9 cloud epic QC:** `s9/cloud_variant.md`
- **Cloud-task-as-confirmer-instance:** `reference/validation_loop_master_protocol.md` (cloud variant section)
