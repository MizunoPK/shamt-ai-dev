# Validation Loop Composite

**What this is:** The full validation loop assembled from its component parts — skill,
MCP tool, auto-stamp hook, stall-detector hook, and `/loop` self-pacing (Claude Code)
or driver script (Codex). Read this guide to understand how the pieces interact; read
the primitive guides for full detail on each part.

---

## Component Map

| Component | Where it lives | Role |
|-----------|---------------|------|
| `shamt-validation-loop` skill | `.shamt/skills/shamt-validation-loop/SKILL.md` | Protocol: round structure, dimensions, exit criteria |
| `shamt.validation_round()` | `.shamt/mcp/` | MCP bookkeeping: appends round entry, returns `consecutive_clean` |
| `validation-log-stamp.sh` | `.shamt/hooks/` | Auto-stamps timestamp on every validation log edit |
| `validation-stall-detector.sh` | `.shamt/hooks/` | Alerts when `consecutive_clean=0` for ≥3 rounds |
| `/shamt-validate` command | `.shamt/commands/` | Invocation entry point |
| `/loop` (Claude Code) | Built into Claude Code CLI | Optional self-pacing via `ScheduleWakeup` — use when context exhaustion is a risk |
| `shamt-validator` sub-agent | `.shamt/agents/shamt-validator.yaml` | Runs confirmation sub-tasks |
| Codex driver script | see below | Polls log until exit condition met |

**Primitive home guides:**
- Full protocol: `guides/reference/validation_loop_master_protocol.md`
- Severity classification: `guides/reference/severity_classification_universal.md`
- Hooks: `.shamt/hooks/README.md`
- MCP tools: `.shamt/mcp/README.md`

---

## How the Pieces Work Together

### 1. Invocation

**Claude Code:** Run `/shamt-validate` or type "run validation loop on {artifact}". The
skill fires and runs all rounds in a single invocation until exit criteria are met.
For very large artifacts or sessions at risk of context exhaustion, prefix with `/loop`
to enable `ScheduleWakeup` self-pacing between rounds (advanced/optional).

**Codex:** Either invoke the `shamt-validation-loop` skill manually each round, or run
the driver script (see "Codex Variant" below) which loops automatically.

### 2. Each Round

The skill runs one full round:
1. Re-reads the entire artifact
2. Checks all applicable dimensions (D1–D7 + scenario dimensions)
3. Verifies ≥3 technical claims with Read/grep
4. Runs adversarial self-check
5. Scores and fixes all issues

After fixing: calls `shamt.validation_round()` with the severity counts. The MCP tool
appends a structured entry to the log and returns `{"consecutive_clean": N, "should_exit": false}`.

The `validation-log-stamp.sh` hook fires automatically on the log edit, appending an
ISO-8601 timestamp. The `validation-stall-detector.sh` hook also fires, checking whether
`consecutive_clean=0` has appeared ≥3 times in a row.

### 3. Stall Detection

If `consecutive_clean=0` for ≥`SHAMT_STALL_THRESHOLD` (default: 3) consecutive rounds,
`validation-stall-detector.sh` writes `.shamt/epics/<active>/STALL_ALERT.md` with
recommended escalation steps:

1. Check if validator is being too strict
2. Switch primary agent to Opus for the next round
3. Decompose the artifact — validate sub-sections independently
4. Escalate to human judgment

The hook is informational (always exits 0). No automatic intervention.

### 4. Sub-Agent Confirmation

When `consecutive_clean = 1`, the skill spawns 2 Haiku sub-agents in parallel:

```xml
<invoke name="Task">
  <parameter name="model">haiku</parameter>
  <parameter name="description">Validation confirmer A</parameter>
  <parameter name="prompt">
    [Full artifact + dimensions. Report zero issues or list with severity.]
  </parameter>
</invoke>
```

**Both confirmers must report zero issues** to exit. If either finds an issue:
- Fix the issue
- Reset `consecutive_clean = 0` via `shamt.validation_round()`
- Continue (do not schedule another `/loop` iteration until the fix is logged)

**Codex Cloud variant:** When Codex Cloud is available, launch 2 cloud tasks with
`shamt-validator` profile instead of in-session sub-agents. Same exit criterion; stronger
independence guarantee (container isolation). See "Cloud-Task-as-Confirmer-Instance Variant"
in the SKILL.md.

### 5. Exit

When both sub-agents confirm zero issues:
- Log "EXIT — validation complete" in `VALIDATION_LOG.md`
- Do **not** call `ScheduleWakeup` again (loop ends)
- Report to user: "Validation complete. `consecutive_clean = 1`, confirmers A and B both
  zero. Artifact is validated."

---

## Claude Code Flow Diagram

```
User: "validate {artifact}"
    │
    ▼
/shamt-validate triggers shamt-validation-loop skill
    │
    ▼
Round N ──────────────────────────────────────────────┐
    │                                                  │
    ├─ Read artifact (full pass)                       │
    ├─ Check D1–D7 + scenario dims                     │
    ├─ Verify ≥3 claims with Read/grep                 │
    ├─ Adversarial self-check                          │
    ├─ Fix all issues                                  │
    ├─ Call shamt.validation_round() → consecutive_clean│
    ├─ Hook: validation-log-stamp fires                │
    ├─ Hook: validation-stall-detector fires           │
    │                                                  │
    ├─ consecutive_clean = 0? ─── continue to Round N+1 ─┘
    │           (if /loop active: ScheduleWakeup(30s) first)
    └─ consecutive_clean = 1?
         │
         ▼
    Spawn 2 Haiku sub-agents (parallel)
         │
    Both zero? ── YES ──▶ EXIT ✅
         │
        NO ──▶ Fix, reset counter ──▶ Round N+1
```

---

## Codex Variant

Codex has no native `/loop`. Two options:

**Option A — Manual round invocation:** After each round, the skill ends its response.
The user or operator re-invokes for the next round. The log tracks state across sessions.

**Option B — Driver script:**

```bash
#!/usr/bin/env bash
LOG="$1"   # path to VALIDATION_LOG.md
while true; do
    codex exec --profile shamt-validator \
        "Run one validation round on $(dirname "$LOG"). Update $LOG."
    last_clean=$(grep -o 'consecutive_clean.*[0-9]' "$LOG" | tail -1 | grep -o '[0-9]*$' || echo 0)
    if [ "$last_clean" -ge 1 ]; then break; fi
    sleep 30
done
```

---

## Master Dev Variant

Master repo validation loops follow the same composite, with one exception:

- **No EPIC_TRACKER.md active epic:** The stall-detector won't write `STALL_ALERT.md`
  to an epic folder (no active epic found). It still emits the stall message to stderr.
  This is expected behavior for master work.
- **`/loop` use:** Optional — prefix with `/loop` only if context exhaustion is a risk (very large artifact, 5+ expected rounds).
- **Sub-agent confirmations:** Use Haiku (same as child workflow). 2 confirmers required.

---

## Metrics Integration

The `validation-log-stamp.sh` hook emits a `validation_round` metric on each log edit
(wired as of SHAMT-44 Phase 5 — this is live, not deferred). No extra action required
from the skill. See `metrics_observability_composite.md` for the full metrics picture.
