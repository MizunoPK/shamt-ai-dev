# S5 Primary Agent Guide (Parallel Work)

**Purpose:** Guide for Primary agent coordinating parallel S5 work

**Role:** Coordinator + Feature 01 owner

**Stages:** S3 Gate 4.5 approval → SP2 (S5 handoff) → S5 (parallel) → S5-CA → Gate 5 → SP4 (S6 chain)

---

## Table of Contents

- [Overview](#overview)
- [Workflow Overview](#workflow-overview)
- [Phase 1: S3 Gate 4.5 Approval (SP2 Trigger)](#phase-1-s3-gate-45-approval-sp2-trigger)
- [Phase 2: SP2 Action — Generate and Send S5 Handoff Packages](#phase-2-sp2-action--generate-and-send-s5-handoff-packages)
- [Phase 3: Parallel S5 Execution](#phase-3-parallel-s5-execution)
- [Phase 4: SP3 — Run S5-CA (Cross-Plan Alignment)](#phase-4-sp3--run-s5-ca-cross-plan-alignment)
- [Phase 5: Combined Gate 5 and SP4 — S6 Activation Chain](#phase-5-combined-gate-5-and-sp4--s6-activation-chain)
- [Common Scenarios](#common-scenarios)
- [Tools and References](#tools-and-references)
- [Summary Checklist](#summary-checklist)

---

## Overview

When S5 parallelization is enabled, the Primary agent has **dual responsibilities**:

1. **Coordinator:** Manage parallel S5 work, send handoffs, monitor secondaries, run S5-CA, coordinate S6 chain
2. **Feature 01 Owner:** Complete S5 for Feature 01 (in parallel with secondaries)

**Time Distribution:**
- 85% Feature 01 S5 work (your implementation planning)
- 15% Coordination (handoffs, monitoring, S5-CA, Gate 5, S6 coordination)

**Key Principle:** Choose the **simplest/smallest feature** as Feature 01 to minimize your workload and maximize coordination capacity.

**Prerequisite:** S2 parallel mode was used for this epic. Secondary agents exist and have context on their features.

---

## Workflow Overview

```text
S3 Gate 4.5 Approval
       ↓
SP2 Action: Check secondary status → Generate S5 handoffs → Activate secondaries
       ↓
Parallel S5 Execution: Feature 01 (you) + Secondary agents simultaneously
       ↓
SP3: All S5 complete → Run S5-CA → Send notifications
       ↓
Combined Gate 5: Present all plans → User approves
       ↓
SP4: Activate S6 chain sequentially (Feature 01 → 02 → 03 ...)
```

---

## Phase 1: S3 Gate 4.5 Approval (SP2 Trigger)

**When S3 Gate 4.5 is approved by user:**

1. **Confirm S5 parallel mode is enabled:**
   - Read EPIC_README.md
   - Look for: `Parallel Mode (S5): enabled`
   - If not present or set to disabled: run S5 sequentially (this guide does not apply)

2. **Proceed to Phase 2 (SP2 Action) immediately:**
   - Do NOT begin S5 for your feature yet
   - Generate handoff packages for secondaries first
   - Activate secondaries before starting your own S5

---

## Phase 2: SP2 Action — Generate and Send S5 Handoff Packages

### Step 1: Check Each Secondary's Checkpoint Status

**For each secondary agent (Secondary-A, Secondary-B, ...):**

1. Read checkpoint file: `agent_checkpoints/{secondary_id}.json`
2. Check fields: `status`, `last_checkpoint`, `stage`

**Interpret status:**

| Checkpoint state | Meaning | Action |
|-----------------|---------|--------|
| `status: "WAITING"` or `status: "COMPLETE"`, checkpoint <60 min old | Agent is still active | Send activation message |
| checkpoint >60 min old, or file missing | Agent terminated or crashed | Fresh spawn needed |

### Step 2: Generate S5 Handoff Package

**For each secondary agent:**

1. Use template: `templates/handoff_package_s5_template.md`

2. Fill in placeholders:
   - `{EPIC_NAME}` — epic folder name (e.g., SHAMT-12-my_epic)
   - `{EPIC_PATH}` — full absolute path to epic folder
   - `{FEATURE_FOLDER}` — feature folder assigned to this secondary
   - `{PRIMARY_AGENT_ID}` — your agent ID
   - `{SECONDARY_AGENT_ID}` — this secondary's ID (Secondary-A, Secondary-B, etc.)
   - `{LIST_OF_OTHER_SPEC_PATHS}` — all other features' spec.md paths (not this secondary's own)
   - `{INTERFACES_OR_NONE}` — pre-verified interface data (optional; see D4 note below)

3. Save package to `{feature_folder}/HANDOFF_PACKAGE_S5.md`

**D4 — Pre-verified interfaces (optional):**
If 2+ features reference the same external method/interface, you may verify it once and include the
result in `{INTERFACES_OR_NONE}`. Do this during handoff generation, before starting your own S5.
This avoids redundant source-code reads by multiple agents.

### Step 3: Activate Each Secondary

**Case A: Secondary is WAITING and not stale**

Send activation message to their inbox (`agent_comms/primary_to_{secondary_id}.md`):

```markdown
## Message N (TIMESTAMP) ⏳ UNREAD
**Subject:** S5 Activation — Your Handoff Package Ready
**Action:** Begin S5 (Implementation Planning) for {FEATURE_FOLDER}
**Details:**
- S5 handoff package saved at: {FEATURE_FOLDER}/HANDOFF_PACKAGE_S5.md
- Read it for your full context, coordination paths, and sync point instructions
- Begin S5 immediately after reading
**Next:** Read handoff package, then begin S5
**Acknowledge:** Reply when you start S5
```

**Case B: Secondary is terminated or stale**

Present fresh-spawn startup instruction to user:

```text
⚠️  Secondary-{X} checkpoint is stale (>{minutes} min old). A fresh session is needed.

Handoff package saved at: {feature_folder}/HANDOFF_PACKAGE_S5.md

🚀 SECONDARY AGENT {X} — STARTUP

In a new Claude Code session, enter:
  You are a secondary agent for SHAMT-{N} for feature {X} (S5)

The agent will locate the handoff package automatically and self-configure.
```

### Step 4: Wait for Acknowledgment

Monitor `agent_comms/{secondary_id}_to_primary.md` for each secondary's "started S5" reply.

**If no acknowledgment after 15 minutes:**
- For Case A (WAITING): Re-send activation message; if still no response after 15 more minutes, treat as terminated and present fresh-spawn instruction
- For Case B (fresh spawn): Wait for user to confirm new session started

### Step 5: Begin S5 for Feature 01

Once all secondaries are activated (or user has opened fresh sessions):
- Begin your own S5 for Feature 01
- Read: `stages/s5/s5_v2_validation_loop.md`
- Follow Parallel mode notes in Prerequisites section

---

## Phase 3: Parallel S5 Execution

**You now have dual responsibilities:**

### Responsibility 1: Feature 01 S5 Implementation

**Work on your feature:**

1. Read and follow: `stages/s5/s5_v2_validation_loop.md`
2. Follow the **Parallel mode** notes in Prerequisites and Gate 5 sections
3. Write milestone checkpoints at:
   - Phase 1 exit (draft `implementation_plan.md` complete, before validation)
   - After each clean validation round
4. Do NOT present Gate 5 to user — signal WAITING_FOR_SYNC when validation loop passes

**Work in focused blocks:**
- 45 min: Deep work on Feature 01 S5
- 15 min: Coordination (check inboxes, STATUS files, checkpoints)
- Repeat

### Responsibility 2: Coordination

**Every 15 minutes:**

1. **Check inboxes for messages from each secondary:**
   - `agent_comms/secondary_a_to_primary.md`
   - `agent_comms/secondary_b_to_primary.md`
   - etc.

2. **Look for unread messages (marked ⏳ UNREAD):**
   - Escalations (subject contains "ESCALATION")
   - Blockers
   - Completion signals (STATUS: WAITING_FOR_SYNC)

3. **Respond to escalations within 15 minutes:**
   - If you can answer from codebase knowledge: answer directly
   - If user input needed: ask user in your session, then relay answer
   - Send response to secondary's inbox
   - Wait for secondary acknowledgment if needed

4. **Check STATUS files:**
   - `feature_01_{name}/STATUS`
   - `feature_02_{name}/STATUS`
   - etc.
   - Look for: BLOCKERS, STATUS, READY_FOR_SYNC

5. **Check checkpoints for staleness:**
   - `agent_checkpoints/secondary_a.json`
   - If `last_checkpoint` > 30 min ago: send warning
   - If `last_checkpoint` > 60 min ago: assume crashed — escalate to user
   - Note: Milestone checkpoint at Phase 1 exit (~1–2 hours in) is primary S5 staleness signal

6. **Track completion:**
   - Count features with `READY_FOR_SYNC: true`
   - When all features complete: proceed to Phase 4 (SP3)

### Milestone Checkpoints (Your Own)

Write a full checkpoint at:
- Phase 1 exit (before starting validation loop)
- After each clean validation round

Checkpoint format:
```json
{
  "agent_id": "Primary",
  "feature": "feature_01_{name}",
  "stage": "S5",
  "phase": "Implementation Planning - Validation Round 2 (clean)",
  "last_checkpoint": "{timestamp}",
  "status": "IN_PROGRESS",
  "can_resume": true,
  "recovery_instructions": "Feature 01 S5 validation complete 2 clean rounds. Waiting for secondaries."
}
```

### Escalation Handling Workflow

**When you receive an escalation message:**

1. Read escalation: subject starts with "ESCALATION"
2. Determine action:
   - Can you answer from codebase knowledge? → Respond directly
   - Need user input? → Ask user in YOUR session, then send response to secondary

3. **If asking user:**
   ```text
   [To user in this session]

   Secondary-A has a question about Feature 02:
   - Planning to use module X for the implementation
   - Question: Should they use approach A or approach B?

   Which approach?
   ```

4. **After user answers:** Send response to secondary's inbox
5. Wait for secondary acknowledgment; resume your S5 work

---

## Phase 4: SP3 — Run S5-CA (Cross-Plan Alignment)

**When all features signal completion (all STATUS files: WAITING_FOR_SYNC, READY_FOR_SYNC: true):**

### Step 1: Verify All Complete

1. Confirm all completion messages received from secondaries
2. Confirm all STATUS files show `STATUS: WAITING_FOR_SYNC` and `READY_FOR_SYNC: true`
3. Confirm all checkpoints show S5 complete and are not stale

**If any secondary is stale (no checkpoint update >60 min):**
- Do NOT proceed to S5-CA
- Send message to secondary: "Status check — are you complete with S5?"
- Wait 15 minutes; if no response, escalate to user (see `stale_agent_protocol.md`)

### Step 2: Run S5-CA

**Read and follow:** `stages/s5/s5_ca_cross_plan_alignment.md`

This guide covers:
- Step 0: Sync verification (all plans present, all agents confirmed complete)
- Step 1: Prioritized pairwise plan comparison
- Step 2: Conflict resolution (update plans directly, run Dependency Re-Validation Protocol on affected dimensions)
- Step 3: 3 consecutive clean validation rounds
- Step 4: S6 sequencing recommendation (if ordering dependencies found)
- Step 5: Document and notify

**You have write access to all feature `implementation_plan.md` files.** Update directly when conflicts require changes.

**If a spec discrepancy is found during S5-CA:**
- STOP immediately — do not proceed to Gate 5
- Escalate to user with exact discrepancy description
- Do NOT resolve spec discrepancies yourself

### Step 3: Notify Secondaries of S5-CA Results

After S5-CA completes, send notification to each secondary:

```markdown
## Message N (TIMESTAMP) ⏳ UNREAD
**Subject:** S5-CA Complete — Re-read Your Plan If Updated
**Action:** {See Details}
**Details:**
S5-CA (Cross-Plan Alignment) is complete.

Plans updated during S5-CA:
- feature_02_team_penalty/implementation_plan.md — UPDATED (see section D5)
- feature_03_scoring_update/implementation_plan.md — NO CHANGE

If your plan was updated: please re-read implementation_plan.md now.
If your plan was not updated: no action needed.

Proceeding to combined Gate 5 (user review of all plans).
**Next:** Await Gate 5 notification (informational only — no action needed from you)
**Acknowledge:** No action needed
```

---

## Phase 5: Combined Gate 5 and SP4 — S6 Activation Chain

### Combined Gate 5

**Present all implementation plans together to user:**

Structure your Gate 5 presentation as:
1. Summary of each feature's plan (high-level: approach, key decisions, test scope)
2. S5-CA results (conflicts found and resolved, or "no conflicts found")
3. S6 sequencing recommendation (if ordering dependencies found)
4. Request approval

```markdown
## Gate 5: Implementation Plans — All Features

### S5-CA Summary
[Conflicts resolved, or "No conflicts found — all plans are consistent"]

### Feature 01: {feature_name}
[Brief summary of implementation approach]
Full plan: {FEATURE_FOLDER}/implementation_plan.md

### Feature 02: {feature_name}
[Brief summary]
Full plan: {FEATURE_FOLDER}/implementation_plan.md

### Feature 03: {feature_name}
[Brief summary]
Full plan: {FEATURE_FOLDER}/implementation_plan.md

### S6 Sequencing
[Recommended implementation order, if ordering dependencies exist]
[Or: "No ordering constraints — features can implement in any order"]

---

Please review all plans. Approve to begin implementation (S6), or request changes.
```

**If user requests changes:**

| Change type | Action |
|------------|--------|
| Minor (targeted dimensions) | Update plan directly, run Dependency Re-Validation Protocol, re-present Gate 5 |
| Significant (major rework) | STOP — clarify scope; may require re-running S5 for affected features |
| Spec update needed | STOP — update spec, re-run S5 for affected features; do not proceed to Gate 5 until re-run |

**After user approval:** Notify secondaries:

```markdown
## Message N (TIMESTAMP) ⏳ UNREAD
**Subject:** Gate 5 Approved — Await S6 Activation Message
**Action:** Stay on standby — I will send your S6 activation message when it is your turn
**Details:**
- Combined Gate 5 has been approved
- S6 implementation will proceed sequentially
- Feature 01 begins first; you will receive an activation message when it is your turn
**Next:** WAIT for your S6 activation message. Do NOT begin S6 on your own.
**Acknowledge:** No action needed
```

### SP4 — Sequential S6 Activation Chain

**After Gate 5 approval, coordinate S6 sequentially (D8):**

**If ordering dependencies found during S5-CA:**
- Follow the recommended S6 sequence from the S5-CA alignment document
- Prerequisite features implement first; dependent features implement after

**If no ordering dependencies:**
- Default sequence: Feature 01 → Feature 02 → Feature 03 (ascending order)

**Activation flow:**

1. **Begin S6 for Feature 01** (your feature)
   - Read: `stages/s6/s6_execution.md`
   - Complete S6 → S7

2. **After Feature 01 S7 complete:** Send S6 activation message to Secondary-A:
   ```markdown
   ## Message N (TIMESTAMP) ⏳ UNREAD
   **Subject:** S6 Activation — Your Turn to Implement
   **Action:** Begin S6 (Implementation) for {FEATURE_FOLDER}
   **Details:**
   - Feature 01 has completed S6-S7
   - It is now your turn to implement {FEATURE_FOLDER}
   - Read stages/s6/s6_execution.md and begin S6
   - After S6 → S7 → S8 complete, send me a completion message
   **Next:** Read s6_execution.md and begin S6 now
   **Acknowledge:** Reply when you start S6
   ```

3. **Monitor Secondary-A's S6 progress** (check STATUS, checkpoints, inboxes)

4. **After Secondary-A's S8 complete:** Send S6 activation message to Secondary-B

5. **Continue until all features complete S6-S8**

**If a secondary doesn't respond to S6 activation:**
- Check checkpoint staleness
- If stale: assume terminated — present fresh-spawn instruction to user
- User spawns fresh session; new session reads `HANDOFF_PACKAGE_S5.md` and `implementation_plan.md`
- Resend S6 activation message

---

## Common Scenarios

### Scenario 1: Secondary Escalates with User Question

1. Receive escalation message from Secondary-A
2. If you can answer: send answer directly
3. If user input needed: ask user in your session
4. User responds; send answer to Secondary-A
5. Secondary-A acknowledges and resumes S5
6. You resume your Feature 01 S5 work

**Timeline:** 5–15 minutes depending on user response time

### Scenario 2: Secondary Goes Stale During S5 (No Checkpoint for 60+ Min)

1. Detect staleness: `last_checkpoint` > 60 min ago
2. Send warning message to secondary's inbox
3. Wait 15 minutes for response
4. If no response: assume crashed — escalate to user
5. User options: restart secondary with minimal startup command, or Primary absorbs the feature

### Scenario 3: You Complete Feature 01 S5 First

1. Complete S5 validation loop (3 consecutive clean rounds)
2. Update STATUS: `STATUS: WAITING_FOR_SYNC`, `READY_FOR_SYNC: true`
3. Update checkpoint: phase: "S5 complete — waiting for secondaries"
4. Continue monitoring secondary agents
5. Wait for all to complete before running S5-CA

### Scenario 4: S5-CA Finds a Conflict

1. Identify conflict: e.g., two features plan to use the same file path for different purposes
2. Decide resolution: which plan to update to resolve conflict
3. Update affected `implementation_plan.md` directly
4. Run Dependency Re-Validation Protocol on affected dimensions
5. Continue S5-CA (need 3 consecutive clean rounds after all conflicts resolved)
6. Document conflict and resolution in S5-CA alignment file

### Scenario 5: User Requests Change During Gate 5

1. Understand scope of change: minor or significant?
2. If minor: update affected plan, run targeted re-validation, re-present Gate 5
3. If significant: STOP — discuss scope, determine if S5 re-run is needed
4. If spec update needed: STOP — update spec, re-run S5 for affected feature(s)
5. After change complete: re-present Gate 5

---

## Tools and References

**Handoff templates:** `templates/handoff_package_s5_template.md`
**S5-CA procedure:** `stages/s5/s5_ca_cross_plan_alignment.md`
**Communication:** `communication_protocol.md`
**Checkpoints:** `checkpoint_protocol.md`
**Stale agent recovery:** `stale_agent_protocol.md`
**Full protocol:** `s5_parallel_protocol.md`

---

## Summary Checklist

**Before Starting S5 (SP2 Action):**
- [ ] S3 Gate 4.5 approved
- [ ] EPIC_README confirms `Parallel Mode (S5): enabled`
- [ ] Checked all secondary checkpoints
- [ ] Generated S5 handoff packages for all secondaries
- [ ] Saved handoff packages to feature folders
- [ ] Activated secondaries (activation message or fresh spawn)
- [ ] Received acknowledgment from all secondaries
- [ ] Begun S5 for Feature 01

**During Parallel S5 (Phase 3):**
- [ ] Working on Feature 01 S5 (45-min blocks)
- [ ] Writing milestone checkpoints at Phase 1 exit and after each clean round
- [ ] Checking inboxes every 15 min
- [ ] Responding to escalations within 15 min
- [ ] Monitoring STATUS files every 15 min
- [ ] Monitoring checkpoints for staleness

**After Feature 01 S5 Complete:**
- [ ] STATUS: WAITING_FOR_SYNC, READY_FOR_SYNC: true
- [ ] Monitoring secondaries until all complete

**SP3 — S5-CA:**
- [ ] All features confirmed complete (STATUS, checkpoints, messages)
- [ ] S5-CA complete (3 consecutive clean rounds)
- [ ] Notifications sent to secondaries (listing updated plans)

**Gate 5:**
- [ ] Combined Gate 5 presented to user (all plans together)
- [ ] User approved
- [ ] Secondaries notified: "Gate 5 approved, await S6 activation"

**SP4 — S6 Chain:**
- [ ] Feature 01 S6 begun
- [ ] Feature 01 S7 complete → activation message sent to Feature 02
- [ ] Feature 02 S8 complete → activation message sent to Feature 03
- [ ] All features completed S6-S8

**Next:** Proceed to S9 (Epic Final QC)
