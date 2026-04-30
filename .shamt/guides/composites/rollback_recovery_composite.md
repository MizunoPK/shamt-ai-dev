# Rollback and Recovery Composite

**What this is:** The full rollback and recovery workflow assembled from its component
parts — worktree/container disposability, stall detection, reasoning-effort escalation,
and the pre-push tripwire guard.

---

## Component Map

| Component | Where it lives | Role |
|-----------|---------------|------|
| Git worktrees (Claude Code) | `git worktree` CLI | Isolated execution environment; discard on failure |
| Container disposability (Codex Cloud) | Codex Cloud infra | Container discarded on error; no local damage |
| `validation-stall-detector.sh` | `.shamt/hooks/` | Detects `consecutive_clean=0` stalls; writes `STALL_ALERT.md` |
| `pre-push-tripwire.sh` | `.shamt/hooks/` | Final guard: audit clean + validation non-zero + builder log clear |
| Reasoning-effort escalation | Guide references | Switch primary agent to Opus when stalled |
| `STALL_ALERT.md` | `.shamt/epics/<epic>/` | Written by stall detector; signals human review needed |

---

## How the Pieces Work Together

### 1. Worktree / Container Isolation

**Claude Code (worktrees):**

Before starting any S6 implementation or risky refactor:
```bash
git worktree add ../epic-workspace feat/SHAMT-N
```

The builder works entirely within the worktree. If the build fails or the plan is wrong:
```bash
git worktree remove --force ../epic-workspace
# Main working tree is untouched
```

On success:
```bash
git -C ../epic-workspace add -A
git -C ../epic-workspace commit -m "feat/SHAMT-N: ..."
# Then merge or fast-forward to main branch
git worktree remove ../epic-workspace
```

**Codex Cloud (containers):**

Each cloud task runs in a fresh container. On task failure, the container is discarded —
no residue in the local working tree, no partially-applied changes. On success, the task
opens a PR from the container's committed branch.

The architect never needs to `git reset` or `git checkout .` to recover from a builder
error. Container disposability provides this by default.

### 2. Stall Detection

The `validation-stall-detector.sh` hook fires on every validation log edit. It counts
trailing `consecutive_clean=0` rounds. When the count reaches `SHAMT_STALL_THRESHOLD`
(default: 3):

1. Writes `.shamt/epics/<active>/STALL_ALERT.md`
2. Emits a warning to stderr (informational — hook always exits 0)

A stall means either:
- The artifact genuinely has hard issues that require deeper reasoning
- The validator is being too strict (false positives)
- The artifact is too large for holistic validation

### 3. Stall Recovery Escalation Ladder

When `STALL_ALERT.md` is written, respond in this order:

1. **Review last round's findings.** Are the issues genuine? Or is the validator flagging
   issues that are too minor (LOW borderline), incorrect (design-doc/implementation
   confusion), or already fixed?

2. **Switch primary agent to Opus.** If using Haiku or Sonnet, switch to Opus for the
   next validation round. Opus's deeper reasoning often finds the signal through noise.
   On Claude Code: manually specify `model="opus"` in the Task spawn or switch the
   main conversation model.

3. **Decompose the artifact.** If the artifact is large (>500 lines), validate sub-sections
   independently. Create separate validation logs per section; merge conclusions after
   all sections pass.

4. **Escalate to human judgment.** If the loop has been stuck ≥5 rounds, present the
   user with: (a) the last 3 rounds' findings, (b) a recommendation on whether to
   accept the artifact with known issues, (c) a proposal to restructure the artifact.
   Do NOT continue looping indefinitely without explicit user authorization.

### 4. Pre-Push Tripwire

The `pre-push-tripwire.sh` hook intercepts every `git push`. It verifies three conditions:

**Check A — Audit freshness:** `.shamt/audit/last_run.json` must exist, have
`exit_criterion_met: true`, and be ≤7 days old. Configurable via `SHAMT_AUDIT_MAX_AGE_DAYS`.

**Check B — Validation log non-zero:** The active epic's validation log must show
`consecutive_clean ≥ 1`. A push with a stuck validation loop (consecutive_clean=0) is
blocked.

**Check C — Builder log clear:** If a builder handoff log exists (S6 just completed),
it must show no `UNRESOLVED ERROR` or `status: failed` entries.

If any check fails: push is blocked with a specific message explaining the failure.

**Emergency bypass:**
```bash
SHAMT_BYPASS_TRIPWIRE=1 git push origin main
```
Use only in genuine emergencies (hotfixes under active incident). The bypass is logged
to stderr so the decision is visible.

### 5. Recovery After Builder Error

If the S6 builder errors (worktree or cloud):

1. Diagnose: read the builder's error output
2. Assess: is this a plan error (wrong file path, wrong operation type) or an execution
   error (file conflict, dependency mismatch)?
3. **Plan error:** Update the relevant step in the validated plan. No need to re-validate
   from scratch if the change is mechanical (path fix, operation type fix).
4. **Execution error:** If the error reveals a design flaw, update the plan AND re-run
   the 9-dimension validation loop before re-spawning the builder.
5. Discard the worktree / container (clean slate)
6. Re-spawn the builder with the corrected plan

---

## Master Dev Variant

Master repo uses the same rollback and recovery patterns with two adjustments:

- **Worktrees are optional** (not required) for master dev work. Use them for large
  changes (>10 file operations) where rollback is valuable. Skip for small fixes.
- **No active epic / stall detector STALL_ALERT.md:** The stall detector will emit
  to stderr but cannot find an active epic in `EPIC_TRACKER.md` for master work.
  This is expected. Respond to the stderr signal directly rather than looking for
  `STALL_ALERT.md` in an epic folder.

The pre-push tripwire is active on master. Master work still requires:
- A recent passing guide audit
- Validation log non-zero (if a validation loop was run for the change)
- No unresolved builder errors in any handoff log

The tripwire's bypass (`SHAMT_BYPASS_TRIPWIRE=1`) is available for master hotfixes.
