---
name: shamt-validation-loop
description: >
  Runs the Shamt validation loop protocol on any artifact (spec, plan,
  guide, design doc, code). Tracks consecutive_clean, enforces the clean-round
  definition, runs adversarial self-check every round, and exits only after a
  primary clean round followed by 2 independent Haiku sub-agent confirmations.
triggers:
  - "run validation"
  - "validate this"
  - "start validation loop"
  - "validation loop"
  - "run a validation loop on"
source_guides:
  - guides/reference/validation_loop_master_protocol.md
  - guides/reference/severity_classification_universal.md
  - guides/composites/validation_loop_composite.md
master-only: false
version: "1.1 (SHAMT-44)"
---

# Skill: shamt-validation-loop

## Overview

The validation loop is a systematic, iterative quality process. Every round you
re-read the entire artifact, check all applicable dimensions, run an adversarial
self-check, and fix all issues before moving on. The loop exits when you achieve
a primary clean round (consecutive_clean = 1) AND 2 independent Haiku sub-agents
both confirm zero issues.

**Critical anti-shortcuts this skill prevents:**
- Declaring a clean round after finding issues (fixed or not)
- Partial artifact reads
- Skipping the adversarial self-check
- Skipping sub-agent confirmation
- Delegating validation rounds to sub-agents
- Not creating VALIDATION_LOG.md before Round 1

---

## When This Skill Triggers

Use this skill whenever an artifact needs systematic quality validation before
advancing — specs, implementation plans, design docs, guides, epic docs. Do NOT
use for simple checklists or one-time reviews.

---

## Protocol

### Pre-Loop Setup (Do Before Round 1)

1. Create `{artifact_name}_VALIDATION_LOG.md` in the artifact folder.
2. Write `consecutive_clean: 0` in the log header.
3. Identify all applicable dimensions (7 master + any scenario-specific).
4. Document reading plan for Round 1.

### Round Structure (Repeat Every Round)

**Step 1 — Pre-round gate.** Verify VALIDATION_LOG.md exists, consecutive_clean
is recorded, round plan is documented.

**Step 2 — Re-read entire artifact.** Use Read tool from line 1 to end. No
working from memory. No partial reads. Use a fresh reading pattern each round:
- Round 1: sequential (top to bottom)
- Round 2: reverse (bottom to top)
- Round 3+: random spot-checks, perspective shifts

**Step 3 — Check ALL dimensions.** Walk through every dimension systematically
(D1 → D7 → scenario dimensions). Document PASS or ISSUE for each. Do not skip
or batch dimensions.

**Step 4 — Verify ≥3 technical claims** against actual files using Read/grep
(not from memory). Document the specific tool calls and results.

**Step 5 — Tool-based verification.** Run linter, type checker, tests, security
scanner if configured. Document results or "N/A — no tools configured." Round
cannot be scored clean if tools report failures.

**Step 6 — Adversarial self-check.** Answer each question explicitly:
- "Are there scenarios I have not considered? Edge cases, error states,
  non-happy-path flows?"
- "Is there any part of the codebase I haven't read that could be relevant?"
- "Based on everything found this round, what would an adversarial reviewer ask?"
- "How do different components interact? Have I accounted for the seams?"
- "What am I assuming to be true without verifying? List top 3 unverified
  assumptions."

If a question surfaces an issue: add it to the issue list. If it surfaces an
open question requiring user input: handle via Open Questions Protocol (see below).

**Step 7 — Score the round and fix all issues.** Classify each issue by severity.
Fix immediately. Update consecutive_clean.

**Step 7b — MCP bookkeeping and metrics (if MCP is registered).** After fixing all issues, call:
```
shamt.validation_round(
    log_path="{path/to/VALIDATION_LOG.md}",
    round={N},
    severity_counts={"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0},
    fixed=False,       # True only if exactly 1 LOW was found and fixed
    exit_threshold=1   # default for validation loops
)
```
The tool appends a structured round entry and returns updated `consecutive_clean`
and `should_exit`. The prose dimension-by-dimension analysis is still written by
you (the primary agent); the MCP call handles counter arithmetic only. If MCP is
not registered, skip this step and update the log manually.

The `validation-log-stamp.sh` hook also fires on each log edit and emits a
`validation_round` metric to the sidecar log (and OTel if configured). This is
automatic — no extra action required.

**Step 8 — Post-round gate.** Update VALIDATION_LOG.md with all dimension results,
tool call evidence, adversarial self-check outcome, and updated consecutive_clean.

### Consecutive_clean State Machine

| Event | Counter Change |
|-------|---------------|
| Zero issues found (pure clean) | +1 |
| Exactly 1 LOW issue found and fixed | +1 |
| 2+ LOW issues found | Reset to 0 |
| Any MEDIUM, HIGH, or CRITICAL issue found | Reset to 0 |
| Sub-agent finds ANY issue (even LOW) | Reset to 0 |

Sub-agents do NOT get the 1-LOW allowance. Any issue found by a sub-agent resets
the counter.

**Fixing issues does not increment the counter.** A round where you found 3
issues and fixed them all still resets to 0. You need a round where you found
zero issues (or at most one LOW issue) to increment.

### Sub-Agent Confirmation (When consecutive_clean = 1)

Immediately after the primary clean round, spawn 2 Haiku sub-agents in parallel:

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues (sub-agent A)</parameter>
  <parameter name="prompt">
You are sub-agent A. Re-read {artifact_path} sequentially (top to bottom) and
check ALL dimensions listed below. Report ANY issue found (even LOW severity).
You do NOT get a 1-LOW allowance.

DIMENSIONS TO CHECK:
[List all 7 master + scenario dimensions]

SEVERITY REFERENCE:
- CRITICAL: Blocks workflow or causes cascading failures
- HIGH: Causes significant confusion or wrong decisions
- MEDIUM: Reduces quality but doesn't block
- LOW: Cosmetic, minimal impact

Output: "CONFIRMED: Zero issues found" OR list all issues with severity.
  </parameter>
</invoke>

<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Confirm zero issues (sub-agent B)</parameter>
  <parameter name="prompt">
You are sub-agent B. Re-read {artifact_path} in REVERSE order (bottom to top)
and check ALL dimensions listed below. Report ANY issue (even LOW severity).
You do NOT get a 1-LOW allowance.

[Same dimensions and severity reference as sub-agent A]

Output: "CONFIRMED: Zero issues found" OR list all issues with severity.
  </parameter>
</invoke>
```

- Both confirm zero issues → EXIT validation loop.
- Either finds an issue → fix, reset consecutive_clean to 0, continue.

### Open Questions Protocol

At end of each round, categorize unresolved questions:
- **Type A** (answerable by codebase research): Research now within this round.
  Do not score the round clean if Type A questions remain unresearched.
- **Type B** (requires user input): Stop. Present questions to user grouped by
  topic. Wait for answer before next round. If answer causes significant plan
  changes (affects 3+ tasks, changes core approach, invalidates a prior verified
  claim): restart validation from Round 1 and reset consecutive_clean to 0.

---

## The 7 Master Dimensions

Check every one of these in every round.

**D1: Empirical Verification** (CRITICAL priority)
Verify all code examples, file paths, class/function names, signatures against
actual source using tools (Read, grep, ls). NEVER verify from memory. Document
exact tool calls and results.

**D2: Completeness**
All required sections present per template. No TBD/TODO placeholders. All
requirements enumerated (not "...and others"). All acceptance criteria defined.

**D3: Internal Consistency**
No contradictory requirements ("use X" vs "use Y"). Consistent terminology
throughout. Examples match specifications. No circular dependencies.

**D4: Traceability**
Every requirement cites its source (Epic Request / User Answer / Derived).
No "assumption" as source. Design decisions cite rationale. Derived requirements
show derivation logic.

**D5: Clarity & Specificity**
No vague language: "should", "might", "probably", "appropriate", "reasonable",
"etc.". Specific values (timeouts in seconds, counts as numbers). Concrete
verbs. "Must" not "should."

**D6: Upstream Alignment**
No scope creep (nothing added the user didn't request). No missing scope (all
upstream requirements reflected). Changes from upstream incorporated. Correct
interpretation of user intent.

**D7: Standards Compliance**
Uses official template structure. Naming conventions match codebase. Code style
follows project standards. Documentation format matches project.

---

## Severity Classification

| Level | Definition | Clean Round Impact |
|-------|-----------|-------------------|
| CRITICAL | Blocks workflow, cascading failures, policy violations | Reset to 0 |
| HIGH | Significant confusion, wrong decisions, wrong technical claims | Reset to 0 |
| MEDIUM | Reduces quality/usability but doesn't block | Reset to 0 |
| LOW | Cosmetic, no functional impact | 1 allowed per round |

**Borderline rule:** When uncertain between two levels, classify as the HIGHER
level. LOW vs MEDIUM → MEDIUM. MEDIUM vs HIGH → HIGH.

**Quick questions:**
1. If not fixed, can workflow complete? NO → CRITICAL
2. Will this confuse agents or users? YES → HIGH
3. Does this reduce quality or usability? YES → MEDIUM
4. Purely cosmetic? YES → LOW

---

## Validation Log Format (Compact Default)

```markdown
## Validation Loop Log: {Artifact Name}

**Artifact:** {file name and version}
**Validation Start:** {YYYY-MM-DD HH:MM}
**Validation End:** {YYYY-MM-DD HH:MM}
**Total Rounds:** {N}
**Final Status:** PASSED / IN PROGRESS

---

| # | Pattern | D1 | D2 | D3 | D4 | D5 | D6 | D7 | Extra | Issues | Counter |
|---|---------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:-----:|--------|:-------:|
| 1 | Sequential | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | N/A | 2 found+fixed | 0 |
| 2 | Reverse | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | 0 (adv-check clean) | 1 → spawn |

**Sub-agents (Round 2):**
- Agent A: 0 issues ✅
- Agent B: 0 issues ✅ → EXIT

**Issue Notes:**
- R1-D2: {description + tool call evidence, e.g. "Read spec.md:45 — section missing"}
- R1-D6: {description + tool call evidence}

**Spot-check Notes (clean rounds):**
- R2: Read {file}:{line}, Grep {pattern} → {N} matches ✅
```

Each ❌ dimension entry must cite the specific tool call that found the issue.
Each clean round must have at least one tool call citation.

---

## `/loop` Self-Pacing (Claude Code)

On Claude Code, the validation loop can self-pace using the `/loop` dynamic mode so
each round fires automatically rather than requiring a manual re-invoke.

### Activating `/loop` for a validation loop

When the user invokes `/shamt-validate` or "run validation loop" on Claude Code:

1. Run Round 1 normally (read artifact, check all dimensions, fix issues, update log).
2. After the round is scored and logged, call `ScheduleWakeup` with:
   - `delaySeconds`: 30 (fast feedback; use 60 for large artifacts or human-paced review)
   - `reason`: `"validation round N complete — consecutive_clean=X; firing next round"`
   - `prompt`: the same `/shamt-validate` invocation that started the loop
3. On each `/loop` wake-up, check if exit criteria are already met (consecutive_clean = 1
   AND sub-agent confirmations pending or complete). If met, **do not** schedule another
   wake-up — the loop ends.
4. When consecutive_clean = 1, spawn 2 Haiku sub-agents (see Sub-Agent Confirmation
   section) **before** scheduling the next wake-up. If both confirm zero issues, the loop
   ends. If either finds an issue, fix, reset counter, and schedule the next round.

**`/loop` and sub-agents:** `/loop` does not restart sub-agents that are already running.
Spawn confirmers once at the end of the primary clean round. Do not re-schedule a wake-up
until confirmers have reported; use the confirmer results to decide whether to exit or
continue.

**Stall detection:** The `validation-stall-detector.sh` hook fires automatically on each
validation log edit. If `consecutive_clean = 0` for ≥3 consecutive rounds, the hook
writes a `STALL_ALERT.md` in the active epic folder. Recommended responses (in order):
1. Review whether the validator is being too strict
2. Switch primary agent to Opus (deeper reasoning) for the next round
3. Decompose the artifact — validate sub-sections independently
4. Escalate to human judgment

### Codex equivalent (no native `/loop`)

Codex does not have a native `/loop` command. Two alternatives:

**Option A — Manual round invocation (simplest):** After each round, the agent ends
its response; the user re-invokes the validation skill for the next round. The validation
log tracks state across invocations. Use this when the team needs to inspect each round.

**Option B — `codex exec` driver script:** Create a small driver script that loops
until the exit condition is observable from the file system:

```bash
#!/usr/bin/env bash
# validate-driver.sh — run until consecutive_clean >= 1
set -euo pipefail
LOG="$1"
while true; do
    codex exec --profile shamt-validator \
        "Run one validation round on the artifact linked from $LOG. " \
        "Update the log. If consecutive_clean >= 1 and both sub-agents confirmed, exit."
    last_clean=$(grep -o 'consecutive_clean.*[0-9]' "$LOG" | tail -1 | grep -o '[0-9]*$' || echo 0)
    if [ "$last_clean" -ge 1 ]; then break; fi
    sleep 30
done
```

Run with: `bash validate-driver.sh path/to/VALIDATION_LOG.md`

**Note on Codex `/loop` equivalent:** A native Codex equivalent to `/loop` may appear in
a future Codex release. Until then, Option B (driver script) is the closest approximation.

---

## Cloud-Task-as-Confirmer-Instance Variant

When running on Codex Cloud, sub-agent confirmations can be dispatched as isolated cloud
tasks instead of in-session spawned agents. The rest of this protocol applies unchanged.

### Why cloud tasks

- **Container isolation:** each cloud task starts from a clean container — no shared state
  between the primary validator and the confirmers
- **True independence:** cloud tasks are provably independent (different container, different
  session context) — stronger independence guarantee than same-session sub-agents
- **Parallelism at depth-1 limit:** Codex enforces `agents.max_depth = 1`; cloud tasks
  sidestep this limit because they are separate top-level sessions, not nested sub-agents

### How it works

After the primary agent reaches `consecutive_clean = 1`:

1. Launch 2 cloud tasks, each with:
   - Profile: `shamt-validator`
   - Branch: current working branch
   - Prompt: same artifact + dimensions as the primary round
2. Wait for both tasks to complete
3. Collect results:
   - Both report zero issues → EXIT criterion met (same as CLI sub-agent confirmation)
   - One or both report issues → fixes apply, `consecutive_clean` resets to 0, new
     primary round begins

### Cloud confirmer prompt

```
You are a Shamt validation confirmer (independent sub-agent role). The primary
validator found zero issues. Your job: verify independently across all dimensions.

Artifact: [path or content]
Dimensions: [same list as primary round]

Report: CONFIRMED CLEAN (0 issues) or list of issues found with severity.
```

### When NOT to use cloud confirmers

- Small validations where CLI sub-agent confirmations are faster and cheaper
- When Codex Cloud is not available on the project
- During S9.P3 user testing (human-in-the-loop; cloud automation does not apply)

---

## Exit Criteria

Validation loop is COMPLETE when ALL are true:

- [ ] consecutive_clean = 1 (primary clean round achieved by primary agent)
- [ ] Both Haiku sub-agents independently confirmed zero issues
- [ ] All 7 master dimensions checked every primary round
- [ ] All scenario-specific dimensions checked every primary round
- [ ] VALIDATION_LOG.md complete with all rounds documented
- [ ] Final artifact version noted in log
- [ ] Summary section completed in validation log

**Cannot exit if:**
- Sub-agent confirmation not completed
- Either sub-agent found any issue
- Any dimension skipped in any round
- Any issue deferred (even LOW severity)
- Any round scored from memory without Read tool call

**10-round threshold:** If round 10 arrives without a primary clean round, present
the user with three options: (a) accept now, (b) continue explicitly, (c) re-evaluate
the artifact. Proceed only with explicit user choice.

---

## Quick Reference

```
consecutive_clean starts at 0
Clean round → +1 (0 issues, or exactly 1 LOW fixed)
Not-clean round → reset to 0 (2+ LOW, or any MEDIUM/HIGH/CRITICAL)
Sub-agent issue → reset to 0 (no 1-LOW allowance for sub-agents)
Exit condition: consecutive_clean = 1 AND both Haiku sub-agents confirm zero issues
```

**Model guidance:**
- Primary validation work: Opus (deep reasoning)
- File searches, grep, existence checks: Haiku (delegate to save tokens)
- Code reading, structural analysis: Sonnet
- Sub-agent confirmations: ALWAYS Haiku (70-80% savings, no quality loss)
