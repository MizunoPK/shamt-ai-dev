# S5 Secondary Agent Guide (Parallel Work)

**Purpose:** Guide for Secondary agents working on assigned features during parallel S5

**Role:** Feature owner (single feature — Implementation Planning only)

**Stages:** Activation → S5 (Implementation Planning) → WAITING_FOR_SYNC → S6 (when activated)

---

## Table of Contents

- [Overview](#overview)
- [Startup Workflow](#startup-workflow)
- [S5 Work Workflow](#s5-work-workflow)
- [Coordination Heartbeat (Every 15 Minutes)](#coordination-heartbeat-every-15-minutes)
- [Escalation Workflow](#escalation-workflow)
- [Completion Signal](#completion-signal)
- [Post-Completion Waiting](#post-completion-waiting)
- [S6 Activation](#s6-activation)
- [Common Scenarios](#common-scenarios)
- [Tools and References](#tools-and-references)
- [Summary Checklist](#summary-checklist)

---

## Overview

When you join as a Secondary agent for S5, you'll receive an S5 handoff package with your configuration. Your responsibilities:

1. **Feature Owner:** Complete S5 (Implementation Planning) for your assigned feature — produce `implementation_plan.md`
2. **Communicator:** Report progress, signal completion correctly, wait for S5-CA and Gate 5
3. **Implementer:** After Primary's S6 activation message, run S6 → S7 → S8 for your feature

**Time Distribution:**
- 90% Feature S5 work (your implementation planning)
- 10% Coordination (checkpoints, inbox checks, status updates)

**Key Principle:** You own ONE feature. Focus on it, escalate when blocked, and wait for the correct sync signals before advancing.

**Critical:** Do NOT present Gate 5 to the user yourself. Signal WAITING_FOR_SYNC and let Primary run S5-CA and combined Gate 5.

---

## Startup Workflow

### Step 1: Receive Your S5 Handoff Package

**Option A: Activation message (if session is still active from S2)**
- Primary sends you an activation message in your inbox: `agent_comms/primary_to_{your_id}.md`
- Message says: "S5 handoff package ready at: {feature_folder}/HANDOFF_PACKAGE_S5.md"
- Read that file for your full configuration

**Option B: Fresh session startup**
- User gives you a minimal startup command (e.g., "You are a secondary agent for SHAMT-{N} for feature 02 (S5)")
- Self-locate your handoff package:
  1. Find epic folder: Glob pattern `SHAMT-{N}-*` in `.shamt/epics/`
  2. Find handoff: `{epic_folder}/{feature_folder}/HANDOFF_PACKAGE_S5.md`
  3. Read the file — it contains all context and instructions
- Fallback: If not found, ask user to provide the handoff package content

### Step 2: Parse Your Configuration

**Extract from handoff package:**
- Epic path: full absolute path to epic folder
- Feature assignment: which feature folder you own
- Agent ID: your identifier (Secondary-A, Secondary-B, etc.)
- Primary agent ID
- Coordination paths:
  - Inbox: `agent_comms/primary_to_{your_id}.md`
  - Outbox: `agent_comms/{your_id}_to_primary.md`
  - Checkpoint: `agent_checkpoints/{your_id}.json`
  - STATUS: `{feature_folder}/STATUS`
- Context files: spec.md, checklist.md, EPIC_README.md, smoke test plan, other feature spec paths
- Pre-verified interfaces (if Primary provided them)

### Step 3: Verify Paths Exist

Verify the following exist before proceeding:
- Epic folder
- `{feature_folder}/spec.md` (must be complete — Gate 3 passed during S2)
- `{feature_folder}/checklist.md` (must be complete)
- `agent_comms/` directory (created by Primary during S2)
- `agent_checkpoints/` directory (created by Primary during S2)

**If any path is missing:** Stop and notify user. Do not proceed until paths are confirmed.

### Step 4: Create or Update Your Checkpoint File

**File:** `agent_checkpoints/{your_id}.json`

```json
{
  "agent_id": "Secondary-A",
  "agent_type": "secondary",
  "session_id": "{generate_unique_id}",
  "feature": "feature_02_team_penalty",
  "stage": "S5",
  "phase": "Implementation Planning - Starting",
  "last_checkpoint": "{current_timestamp}",
  "next_checkpoint_expected": "{15_minutes_from_now}",
  "status": "IN_PROGRESS",
  "can_resume": true,
  "blockers": [],
  "files_modified": [],
  "recovery_instructions": "Just started S5. Begin Phase 1 draft of implementation_plan.md.",
  "current_step": "Configuring agent from S5 handoff package",
  "completed_steps": [
    "Received S5 handoff package",
    "Verified epic and feature paths"
  ],
  "next_steps": [
    "Create STATUS file",
    "Send initial message to Primary",
    "Begin S5 Phase 1 draft"
  ]
}
```

**If checkpoint file already exists from S2 phase:** Update it (do not create a new file). Change `stage` to `"S5"` and update `phase`, `last_checkpoint`, `status`, and `recovery_instructions`.

### Step 5: Update Your STATUS File

**File:** `{feature_folder}/STATUS`

```text
STAGE: S5
PHASE: Implementation Planning
AGENT: Secondary-A
AGENT_ID: {your_session_id}
UPDATED: {current_timestamp}
STATUS: IN_PROGRESS
BLOCKERS: none
NEXT_ACTION: Begin S5 Phase 1 draft (implementation_plan.md)
READY_FOR_SYNC: false
ESTIMATED_COMPLETION: {estimated_timestamp}
```

### Step 6: Send Initial Message to Primary

**File:** `agent_comms/{your_id}_to_primary.md`

Append (do not overwrite):

```markdown
## Message 1 (TIMESTAMP) ⏳ UNREAD
**Subject:** S5 Secondary Agent Started
**Action:** I've started S5 implementation planning for {FEATURE_FOLDER}
**Details:** S5 handoff package received and configuration complete
**Next:** Beginning S5 Phase 1 (Draft Creation) now
**Acknowledge:** No action needed
```

### Step 7: Confirm Startup (to user, if fresh session)

```text
✅ Configuration verified
   Epic: {EPIC_NAME}
   Feature: {FEATURE_FOLDER}
   Primary: {PRIMARY_AGENT_ID}
   My ID: {SECONDARY_AGENT_ID}

✅ Coordination channels confirmed
   Inbox: agent_comms/primary_to_{your_id}.md
   Outbox: agent_comms/{your_id}_to_primary.md

✅ Checkpoint initialized
   File: agent_checkpoints/{your_id}.json

✅ STATUS file updated

📨 Sent initial message to Primary

🚀 Starting S5 (Implementation Planning)
   Reading: stages/s5/s5_v2_validation_loop.md
   Following Parallel mode notes in Prerequisites and Gate 5 sections
```

---

## S5 Work Workflow

### Read the S5 Guide

**Read and follow:** `stages/s5/s5_v2_validation_loop.md`

**Pay attention to Parallel mode notes in:**
- Prerequisites section (starting context, milestone checkpoints)
- Gate 5 section (do NOT present Gate 5; signal WAITING_FOR_SYNC instead)

### Your Starting Context

Use the files from your handoff package:
- `{feature_folder}/spec.md` — your feature's requirements
- `{feature_folder}/checklist.md` — resolved questions from S2
- `EPIC_README.md` — epic context
- `research/epic_smoke_test_plan.md` — smoke test plan
- Other features' spec.md files (listed in handoff package) — for interface consistency
- Pre-verified interfaces (if provided in handoff package)

### Milestone Checkpoints (Required)

Write a full checkpoint at these milestones:

**1. Phase 1 exit (draft complete, before starting validation loop):**
```json
{
  "stage": "S5",
  "phase": "Implementation Planning - Phase 1 Draft Complete",
  "status": "IN_PROGRESS",
  "last_checkpoint": "{timestamp}",
  "recovery_instructions": "Phase 1 draft complete. implementation_plan.md exists. Begin validation loop.",
  "can_resume": true
}
```

**2. After each clean validation round:**
```json
{
  "stage": "S5",
  "phase": "Implementation Planning - Validation Round {N} (clean)",
  "status": "IN_PROGRESS",
  "last_checkpoint": "{timestamp}",
  "recovery_instructions": "Completed {N} validation rounds. Consecutive clean: {consecutive_clean}/1 required before sub-agent confirmation. Continue validation.",
  "can_resume": true
}
```

### Coordination During S5

**Every 15 minutes:**
1. Update checkpoint (at minimum, update `last_checkpoint` timestamp)
2. Check inbox for messages from Primary
3. Update STATUS file if progress changed

**If blocked >30 minutes:**
- Send escalation message to Primary (see Escalation Workflow)
- Update STATUS: `BLOCKERS: {description}`

---

## Coordination Heartbeat (Every 15 Minutes)

### Step 1: Update Checkpoint

Update at minimum:
- `last_checkpoint` → current timestamp
- `next_checkpoint_expected` → 15 minutes from now
- `current_step` → where you are in S5
- `files_modified` → add any new files changed

### Step 2: Check Inbox

**File:** `agent_comms/primary_to_{your_id}.md`

```bash
# Look for unread messages
grep "⏳ UNREAD" agent_comms/primary_to_{your_id}.md
```

**For each unread message:**
1. Read message
2. Take action as directed
3. Mark as READ (change ⏳ UNREAD to ✅ READ)
4. Reply if acknowledgment requested

### Step 3: Update STATUS File

Update `UPDATED` timestamp and any changed fields.

### Step 4: Set Next Heartbeat

Continue working; repeat in 15 minutes.

---

## Escalation Workflow

### When to Escalate

**Escalate to Primary when:**
- User question needed (can't resolve from codebase)
- Spec ambiguity (can't determine correct interpretation)
- Integration concern (affects another feature's plan)
- Blocked >30 minutes (can't make progress)
- Major technical decision (architecture-level)

**Don't escalate for:**
- Implementation approach choices (decide yourself)
- Code structure decisions (your feature)
- Test design decisions (decide yourself)
- Minor clarifications resolvable from codebase

### Escalation Message Template

Append to `agent_comms/{your_id}_to_primary.md`:

```markdown
## Message N (TIMESTAMP) ⏳ UNREAD
**Subject:** ESCALATION - {Brief description}
**Blocker:** Unable to proceed with S5 Phase {N}
**Issue:** {Specific problem — e.g., "Spec says X but codebase shows Y. Unclear which to follow."}

**Attempted:**
- {What you tried to resolve it yourself}
- {What you checked}

**Stuck For:** {N} minutes
**Need:** {User clarification / Primary decision / Codebase info}
**Blocked Since:** {time}
**Urgency:** HIGH (blocking S5 Phase {N})
**Acknowledge:** Reply with decision or "escalating to user"
```

### After Escalating

1. Update STATUS: `BLOCKERS: Escalated to Primary — waiting for response`
2. Update checkpoint: `"status": "BLOCKED"`, `"blockers": ["{description}"]`
3. Check inbox every 5 minutes (urgent mode)
4. When response received: take action, acknowledge, update STATUS to clear blocker

---

## Completion Signal

### After S5 Validation Loop Passes (Primary Clean Round + Sub-Agent Confirmation)

**Step 1: Verify implementation_plan.md is complete**
- All required sections present
- All S5 validation dimensions clean
- Test plans documented

**Step 2: Update STATUS**
```text
STAGE: S5
PHASE: Implementation Planning
AGENT: Secondary-A
AGENT_ID: {your_session_id}
UPDATED: {current_timestamp}
STATUS: WAITING_FOR_SYNC
BLOCKERS: none
NEXT_ACTION: Waiting for Primary to run S5-CA and combined Gate 5
READY_FOR_SYNC: true
```

**Step 3: Update Checkpoint**
```json
{
  "stage": "S5",
  "phase": "Implementation Planning - Complete",
  "status": "WAITING",
  "last_checkpoint": "{timestamp}",
  "can_resume": false,
  "recovery_instructions": "S5 complete. implementation_plan.md finalized. Waiting for S5-CA.",
  "ready_for_next_stage": true
}
```

**Step 4: Send Completion Message to Primary**

Append to `agent_comms/{your_id}_to_primary.md`:

```markdown
## Message N (TIMESTAMP) ⏳ UNREAD
**Subject:** S5 Complete for {FEATURE_FOLDER}
**Status:** {FEATURE_FOLDER} S5 (Implementation Planning) complete
**Files Ready:**
- implementation_plan.md (complete, all dimensions validated)

**Validation:** primary clean round + sub-agent confirmation achieved
**Blockers:** None
**Ready for S5-CA:** Yes
**Awaiting:** Your S5-CA and combined Gate 5
**Acknowledge:** No action needed, proceed when all features ready
```

**Step 5: Enter Waiting State**
- Do NOT present Gate 5 to the user
- Do NOT proceed to S6
- Monitor inbox and wait for Primary's notifications

---

## Post-Completion Waiting

### Step 1: Enter Waiting State

Your S5 work is done. Wait for Primary to:
1. Verify all features complete
2. Run S5-CA (Cross-Plan Alignment)
3. Send you a notification listing which plans were updated
4. Present combined Gate 5 to user
5. Send you Gate 5 notification (informational)
6. Send you S6 activation message (when it is your turn)

### Step 2: Monitor Inbox

**Check inbox every 15 minutes:**
- Primary may send messages about S5-CA progress
- Primary will notify you if your `implementation_plan.md` was updated

### Step 3: When Primary Sends S5-CA Notification

Primary sends a notification listing which plans were updated. Example:

```markdown
Subject: S5-CA Complete — Re-read Your Plan If Updated
Details:
  - feature_02_team_penalty/implementation_plan.md — UPDATED (see section D5)
  - feature_03_scoring_update/implementation_plan.md — NO CHANGE
```

**Your action:**
- If your plan was updated: re-read `{feature_folder}/implementation_plan.md`
- If your plan was not updated: no action needed
- Mark message as READ

### Step 4: When Primary Sends Gate 5 Notification

Primary notifies you that combined Gate 5 has passed:

```markdown
Subject: Gate 5 Approved — Await S6 Activation Message
Details: Combined Gate 5 has been approved. Await your S6 activation message.
```

**Your action:**
- Mark message as READ
- Continue waiting — do NOT begin S6
- Await S6 activation message (may arrive after Feature 01 completes S6-S7)

---

## S6 Activation

### Step 1: Receive S6 Activation Message

Primary sends activation message when it is your turn:

```markdown
Subject: S6 Activation — Your Turn to Implement
Action: Begin S6 (Implementation) for {FEATURE_FOLDER}
Details: Feature 01 has completed S6-S7. It is now your turn.
```

### Step 2: Re-verify Plan After Prerequisite Feature Completes (If Applicable)

If your feature had an ordering dependency on a prerequisite feature (noted in your `implementation_plan.md` or the S5-CA alignment document):

Before beginning S6, re-verify the dimensions flagged for re-check (typically D2, D5, D6, D7):
- Check that the prerequisite feature's completed code matches the assumptions in your `implementation_plan.md`
- If differences found: update your plan and note the change; do not escalate unless a spec discrepancy is found
- If plan update requires significant rework: escalate to Primary before beginning S6

### Step 3: Begin S6

1. Update STATUS:
   ```text
   STAGE: S5
   PHASE: S6 Active
   STATUS: IN_PROGRESS
   NEXT_ACTION: S6 implementation
   READY_FOR_SYNC: false
   ```

2. Update checkpoint: `"stage": "S5"`, `"phase": "S6 Active - Starting"`
   (Note: STAGE in STATUS stays S5 while checkpoint can reflect current sub-stage)

3. Send acknowledgment to Primary:
   ```markdown
   ## Message N (TIMESTAMP) ⏳ UNREAD
   **Subject:** S6 Started for {FEATURE_FOLDER}
   **Action:** I've begun S6 (Implementation) for {FEATURE_FOLDER}
   **Next:** Will update you after S6 → S7 → S8 complete
   **Acknowledge:** No action needed
   ```

4. Read: `stages/s6/s6_execution.md`
5. Begin implementation

### Step 4: Complete S6 → S7 → S8

Follow the stage guides for S6, S7, and S8 for your feature.

After S8 complete, send completion message to Primary:

```markdown
## Message N (TIMESTAMP) ⏳ UNREAD
**Subject:** S8 Complete for {FEATURE_FOLDER}
**Status:** {FEATURE_FOLDER} S6-S8 (Implementation + QC + Alignment) complete
**Details:** All implementation and testing complete for this feature
**Blockers:** None
**Acknowledge:** No action needed — Primary activates next feature
```

---

## Common Scenarios

### Scenario 1: You Complete S5 Before Other Features

1. Signal completion (WAITING_FOR_SYNC)
2. Enter waiting state
3. Monitor inbox every 15 minutes
4. Wait for Primary's S5-CA notification and Gate 5 notification
5. Then wait for S6 activation message

### Scenario 2: Primary Updates Your Plan During S5-CA

1. Receive S5-CA notification: "Your plan was updated"
2. Read updated `implementation_plan.md`
3. Understand what changed and why (noted in S5-CA alignment document if needed)
4. Mark notification as READ
5. Continue waiting

### Scenario 3: Your Session Crashes Mid-S5

1. User restarts session
2. User says: "You are a secondary agent for SHAMT-{N} for feature {X} (S5)" or pastes handoff again
3. Read `{feature_folder}/HANDOFF_PACKAGE_S5.md` for configuration
4. Read existing `{feature_folder}/implementation_plan.md` to check progress
5. Read existing checkpoint: look for `recovery_instructions`
6. Resume from where you left off (if Phase 1 draft exists: begin validation; if partially validated: continue validation)
7. Update checkpoint with new session ID
8. Send message to Primary: "Resumed S5 after crash — continuing from {step}"

### Scenario 4: You Receive a Message During WAITING State

1. Read message
2. If it says "re-read your implementation_plan.md": do so
3. If it says "Gate 5 approved, await S6 activation": acknowledge (mark READ), continue waiting
4. If it says "S6 Activation — Your Turn": proceed with S6 startup (Step 3 above)
5. For any other message: take action as directed

### Scenario 5: Primary Doesn't Send S6 Activation for a Long Time

1. Check if Primary is actively working (their STATUS file, if accessible)
2. If you've been waiting >1 hour after Gate 5 notification: send a polite check-in
   ```markdown
   Subject: S6 Readiness Check
   Action: Checking in — I'm ready for S6 activation when Feature 01 completes S6-S7
   Details: Awaiting your S6 activation message; no urgency, just confirming readiness
   Acknowledge: Reply when you send activation
   ```
3. Continue waiting; do NOT begin S6 without the activation message

---

## Tools and References

**S5 guide:** `stages/s5/s5_v2_validation_loop.md`
**S6 guide:** `stages/s6/s6_execution.md`
**Communication:** `communication_protocol.md`
**Checkpoints:** `checkpoint_protocol.md`
**Full S5 parallel protocol:** `s5_parallel_protocol.md`

---

## Summary Checklist

**Startup:**
- [ ] Received S5 handoff package (activation message or fresh session)
- [ ] Parsed configuration from handoff package
- [ ] Verified epic and feature paths exist
- [ ] spec.md and checklist.md confirmed complete
- [ ] Checkpoint file created or updated (stage: S5)
- [ ] STATUS file updated (STAGE: S5, STATUS: IN_PROGRESS)
- [ ] Initial message sent to Primary
- [ ] Read s5_v2_validation_loop.md (Parallel mode notes)

**During S5:**
- [ ] Working on implementation_plan.md
- [ ] Updating checkpoint every 15 min (at minimum, update last_checkpoint)
- [ ] Writing milestone checkpoint at Phase 1 exit
- [ ] Checking inbox every 15 min
- [ ] Escalating when blocked >30 min
- [ ] Writing milestone checkpoint after each clean validation round

**Completion Signal:**
- [ ] S5 validation loop passed (primary clean round + sub-agent confirmation)
- [ ] STATUS updated: WAITING_FOR_SYNC, READY_FOR_SYNC: true
- [ ] Checkpoint updated: status WAITING, ready_for_next_stage: true
- [ ] Completion message sent to Primary
- [ ] Entered waiting state (NOT presenting Gate 5)

**Post-Completion Waiting:**
- [ ] Monitoring inbox every 15 min
- [ ] S5-CA notification received and processed (re-read plan if updated)
- [ ] Gate 5 notification received (informational — no action)
- [ ] Waiting for S6 activation message

**S6 Activation:**
- [ ] S6 activation message received
- [ ] Re-verified plan against prerequisite feature's code (if ordering dependency)
- [ ] STATUS updated, acknowledgment sent to Primary
- [ ] Read s6_execution.md
- [ ] S6 begun
- [ ] S6 → S7 → S8 complete
- [ ] Completion message sent to Primary

**Next:** Primary activates next feature in the S6 chain
