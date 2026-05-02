# S6 Cloud-Native Variant — Codex Cloud Builder

**Applies to:** Codex Cloud users running the S6 architect-builder pattern.

This guide supplements `s6_execution.md`. Read that guide first for the full S6 architect-builder protocol. This guide describes only what differs when the builder runs as a Codex Cloud task instead of a local CLI agent.

---

## When to Use the Cloud Variant

Use the cloud variant when:
- The epic branch is large (>20 file operations, risk of local resource exhaustion)
- You want container-disposability rollback semantics (failure leaves the repo clean)
- S7 QC fan-out will also run in cloud — natural alignment to keep S6 results in a cloud-accessible branch

Use the CLI variant when:
- You're on a metered Codex Cloud budget
- The implementation is small and runs in <15 minutes
- You need interactive debugging during execution

---

## Cloud Variant Flow

```text
Architect (CLI / IDE)
  ↓ creates & validates implementation plan (S5, same as CLI variant)
  ↓ commits plan to feat/EPIC branch
  ↓ launches cloud task with shamt-s6-builder profile
       ↓ Container starts from feat/EPIC branch
       ↓ cloud-setup.sh runs (MCP server, guide cache, AGENTS.md)
       ↓ Builder executes plan mechanically
       ↓ On success: opens PR from feat/EPIC to main
       ↓ On failure: container discarded; no local damage
Architect reviews the PR (→ S7)
```

---

## Step-by-Step

### Step 1 — Verify cloud prerequisites

Before launching:
- [ ] `requirements.toml` is at the project root (written by Shamt init)
- [ ] `cloud-environment.template.json` has been copied and configured for this project (see `.shamt/host/codex/cloud-README.md`)
- [ ] `EPIC_BRANCH` is set to the current epic branch name

### Step 2 — Commit the validated implementation plan

The cloud builder reads the plan from the repo, not from memory. Commit the plan before launching:

```bash
git add .shamt/epics/<EPIC>/HANDOFF_PACKAGE_S6.md
git commit -m "feat/SHAMT-N: S6 handoff package for cloud builder"
git push origin feat/EPIC
```

### Step 3 — Launch the cloud task

From the Codex Cloud project UI (or CLI):
1. Select profile `shamt-s6-builder`
2. Set branch to `feat/EPIC`
3. Start task with the builder prompt from `HANDOFF_PACKAGE_S6.md`

The container runs `cloud-setup.sh` automatically (installs MCP, warms guide cache, seeds AGENTS.md).

### Step 4 — Monitor execution

The cloud task streams progress. The `shamt-s6-builder` profile uses:
- Model: `DEFAULT_MODEL` (Haiku equivalent) — fast, low-cost mechanical execution
- Reasoning effort: `minimal`
- Sandbox: `workspace-write` (cannot escalate to `danger-full-access` per `requirements.toml`)

The builder follows the same mechanical execution protocol as the CLI variant (see `s6_execution.md` Step 2+).

### Step 5 — On success

The builder opens a PR from `feat/EPIC` to `main`. This PR is naturally the S7 review checkpoint — the architect reviews it using the S7 QC guides. No additional push step needed.

### Step 6 — On failure

If the cloud task fails mid-execution:
1. The container is discarded automatically — the `feat/EPIC` branch is unchanged.
2. The task reports which step failed.
3. The architect diagnoses and either:
   - Fixes the plan in `HANDOFF_PACKAGE_S6.md` and re-launches the cloud task, or
   - Falls back to CLI execution (`s6_execution.md`)

Container disposability means failure has zero local damage — the branch is clean at the last committed state.

---

## Container Disposability Rollback

The key safety property of the cloud variant: **the container has no persistent state**. If you kill a cloud task, reboot the container, or let it fail:
- The `feat/EPIC` branch reverts to whatever was last committed before the task started
- No partial file edits leak out of the container
- No venv corruption, no cache poisoning, no half-written files

This is the "disposable container rollback" described in the SHAMT-43 Experiment B validation.

---

## Sandbox Enforcement in Cloud Context

`requirements.toml` at the project root applies inside the cloud container. The `shamt-s6-builder` profile's `sandbox = "workspace-write"` is the effective ceiling. An attempt to escalate to `danger-full-access` inside a cloud task is rejected by `requirements.toml` enforcement.

---

## Cross-reference

- **CLI S6 protocol:** `s6_execution.md`
- **Cloud environment setup:** `.shamt/host/codex/cloud-README.md`
- **shamt-s6-builder profile:** `.shamt/host/codex/profiles/shamt-s6-builder.fragment.toml`
- **S7 cloud QC fan-out:** `s7/cloud_variant.md`
