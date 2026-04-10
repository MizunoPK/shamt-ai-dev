# S5 Parallelization Protocol - Complete Guide

**Version:** 1.0
**Scope:** S5 (Implementation Planning) parallelization
**Prerequisite:** S2 parallel mode completed (secondary agents exist with S2 context)
**Risk Level:** MEDIUM (implementation plans affect code; S5-CA resolves conflicts before coding begins)
**Time Savings:** ~4.5–7 hours gross per feature beyond the first (minus ~1 hour S5-CA overhead), for epics with 2+ features

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Complete Workflow](#complete-workflow)
4. [Coordination Mechanisms](#coordination-mechanisms)
5. [Agent Roles](#agent-roles)
6. [Sync Points](#sync-points)
7. [File Structure](#file-structure)
8. [User Experience](#user-experience)
9. [Troubleshooting](#troubleshooting)

---

## Overview

### What is S5 Parallelization?

S5 parallelization enables **multiple agents to work on S5 (Implementation Planning) simultaneously**, each producing an `implementation_plan.md` for their assigned feature. This reduces the planning-to-code time by allowing all features to be planned in parallel instead of sequentially.

### Time Savings Example

**2-feature epic:**
```text
Sequential S5:
- Feature 1: 4.5–7 hours
- Feature 2: 4.5–7 hours
Total: 9–14 hours

Parallel S5:
- Both features: 4.5–7 hours (max of the two)
Total: 4.5–7 hours

SAVINGS: 4.5–7 hours (50% reduction in S5 time)
```

**Epic-level impact:**
```text
Sequential Epic: S1(2h) + S2(2h) + S3(1h) + S4(0.5h) + S5(14h) + S6-S8(20h) + S9(2h) + S10(1h) + S11(1h) = 43.5h
Parallel S5 Epic: S1(2h) + S2(2h) + S3(1h) + S4(0.5h) + S5(7h) + S5-CA(1h) + S6-S8(20h) + S9(2h) + S10(1h) + S11(1h) = 37.5h

SAVINGS: ~6 hours (14% epic-level reduction)
```

### Why S5?

**High Value Per Feature:**
- Each feature takes 4.5–7 hours for S5 — much larger individual savings than S2's 2 hours
- Break-even threshold is just 2 features (vs. S2's 3+)
- Each additional feature beyond the first saves ~4.5–7 hours gross (~3.5–6 hours net after S5-CA overhead)

**Pre-Existing Infrastructure:**
- Secondary agents already exist from S2 parallel mode — can be reactivated without full setup
- Coordination protocols, STATUS files, checkpoints, and agent_comms channels are already in place
- Agents have existing context on their assigned features (spec.md, checklist.md)

**S5-CA Safety Net:**
- S5-CA (Cross-Plan Alignment) runs after all parallel S5 loops complete
- Catches and resolves conflicts between implementation plans before any code is written
- Combined Gate 5 presents all plans together for user review once (not per-feature)

### Prerequisite

**S5 parallel mode requires S2 parallel mode.** If S2 was sequential, S5 must also be sequential. The secondary agents who worked on S2 are the same agents assigned to S5.

**EPIC_README.md must contain:** `Parallel Mode (S5): enabled` to activate S5 parallel mode.

### Scope

**Parallelizable:**
- ✅ S5: Implementation Planning (each feature's `implementation_plan.md`)

**Sequential (Unchanged):**
- ❌ S1: Epic Planning (Primary only)
- ❌ S3: Epic-Level Docs, Tests, and Approval (Primary only)
- ❌ S5-CA: Cross-Plan Alignment (Primary only, runs after all S5 complete)
- ❌ S6-S8: Feature Implementation (sequential chain — Primary coordinates, one feature at a time)
- ❌ S9-S11: Epic completion (Primary only)

---

## Architecture

### Agent Model

```text
┌─────────────────────────────────────────────────────────┐
│                    PRIMARY AGENT                        │
│  - Owns Feature 01                                      │
│  - Generates/sends S5 handoff packages                  │
│  - Monitors secondary agents                            │
│  - Handles escalations                                  │
│  - Runs S5-CA after all features complete               │
│  - Presents combined Gate 5 to user                     │
│  - Coordinates sequential S6 chain (D8)                 │
└─────────────────────────────────────────────────────────┘
         │                    │
    Coordination         Coordination
         │                    │
┌────────────────┐    ┌────────────────┐
│  SECONDARY-A   │    │  SECONDARY-B   │
│  Feature 02    │    │  Feature 03    │
│  S5 only       │    │  S5 only       │
└────────────────┘    └────────────────┘
```

### Communication Channels

```text
Primary ←→ Secondary-A: agent_comms/primary_to_secondary_a.md
                        agent_comms/secondary_a_to_primary.md

Primary ←→ Secondary-B: agent_comms/primary_to_secondary_b.md
                        agent_comms/secondary_b_to_primary.md
```

### No EPIC_README Sectioning During S5

Unlike S2, secondary agents in S5 do not update EPIC_README.md sections during active work. All inter-agent coordination uses STATUS files and checkpoint files. EPIC_README.md progress is updated by Primary only.

---

## Complete Workflow

### Phase 1: SP2 Trigger — Gate 4 Approval + S4 Execution

**Trigger:** Primary receives Gate 4 approval from user (end of S3), then completes S4.

**Primary action:**
1. Read EPIC_README.md — confirm `Parallel Mode (S5): enabled`
2. **Run S4 solo** (read `stages/s4/s4_interface_contracts.md`) — secondary agents are NOT activated yet during S4
3. After S4 exits with `interface_contracts.md` created: proceed to Phase 2 (handoff package generation)
4. Do NOT begin S5 for your own feature until secondaries are activated

**See:** `s5_primary_agent_guide.md` → Phase 2 (SP2 Action)

---

### Phase 2: Generate and Send S5 Handoff Packages

**Primary action for each secondary agent:**

1. **Check secondary checkpoint:**
   - File: `agent_checkpoints/{secondary_id}.json`
   - Look for: `status: "WAITING"` or `status: "COMPLETE"` with recent timestamp

2. **If secondary is WAITING and not stale (checkpoint < 60 min old):**
   - Generate S5 handoff content (template: `templates/handoff_package_s5_template.md`)
   - Save handoff to `{feature_folder}/HANDOFF_PACKAGE_S5.md`
   - Send activation message via `agent_comms/primary_to_{secondary_id}.md`

3. **If secondary is terminated or stale (checkpoint > 60 min old, or file missing):**
   - Generate S5 handoff content and save to `{feature_folder}/HANDOFF_PACKAGE_S5.md`
   - Present fresh-spawn startup instruction to user (see below)

**Activation message format (for WAITING secondary):**
```markdown
## Message N (TIMESTAMP) ⏳ UNREAD
**Subject:** S5 Activation — Your Handoff Package Ready
**Action:** Begin S5 (Implementation Planning) for {FEATURE_FOLDER}
**Details:**
- S5 handoff package saved at: {FEATURE_FOLDER}/HANDOFF_PACKAGE_S5.md
- Read it now for full context and sync point instructions
- Begin S5 immediately after reading
**Next:** Read handoff package, then begin S5
**Acknowledge:** Reply when you start S5
```

**Fresh-spawn startup command (for terminated secondary):**
```text
You are a secondary agent for SHAMT-{N} for feature {X} (S5)
```
The agent will locate `{feature_folder}/HANDOFF_PACKAGE_S5.md` automatically and self-configure.

**After all secondaries activated:**
- Begin S5 for Feature 01 (your feature) simultaneously
- Proceed to Phase 3

**See:** `s5_primary_agent_guide.md` → Phase 2 for full procedure

---

### Phase 3: Parallel S5 Execution

**All agents work simultaneously:**

**Primary:**
- Begin S5 for Feature 01 (read: `stages/s5/s5_v2_validation_loop.md`)
- Follow Parallel mode notes in Prerequisites section
- Write milestone checkpoints at: Phase 1 exit, after each clean validation round
- Monitor secondary agents every 15 minutes (STATUS, checkpoints, inboxes)
- Handle escalations within 15 minutes

**Secondary agents (each):**
- Receive activation message or handoff package
- Self-configure (parse config, verify paths, update STATUS and checkpoint)
- Begin S5 for assigned feature
- Follow Parallel mode notes in `s5_v2_validation_loop.md`
- Write milestone checkpoints at: Phase 1 exit, after each clean validation round
- 15-minute coordination heartbeat (checkpoint + inbox check)
- Do NOT present Gate 5 to user — signal completion and enter WAITING_FOR_SYNC

**Duration:** Bounded by the slowest feature's S5 validation loop (typically 4.5–7 hours)

**See:** `s5_secondary_agent_guide.md` for secondary workflow
**See:** `s5_primary_agent_guide.md` → Phase 3 for coordination details

---

### Phase 4: SP3 — All S5 Complete, Run S5-CA

**Trigger:** All features signal completion (STATUS: WAITING_FOR_SYNC, READY_FOR_SYNC: true).

**Primary action:**
1. Verify all completion messages received from secondaries
2. Verify all STATUS files show WAITING_FOR_SYNC
3. Verify all checkpoints show S5 complete and are not stale
4. Run S5-CA (Cross-Plan Alignment): `stages/s5/s5_ca_cross_plan_alignment.md`
5. Send notification to secondaries listing which `implementation_plan.md` files were updated (if any)
6. Present combined Gate 5 to user (Phase 5)

**Secondary agents during S5-CA:**
- WAIT — do not proceed to Gate 5 or S6
- If notified of a plan update: re-read your `implementation_plan.md`
- Await combined Gate 5 notification (informational)

**See:** `stages/s5/s5_ca_cross_plan_alignment.md` for S5-CA procedure

---

### Phase 5: Combined Gate 5

**After S5-CA completes, Primary presents all implementation plans together:**
- Summary of each feature's plan (post-S5-CA)
- Any conflicts found and resolved during S5-CA
- S6 sequencing recommendation (if ordering dependencies exist)

**User reviews:**
- All plans at once (not one at a time per feature)
- Approves or requests changes

**If user requests minor changes:**
- Primary updates affected plan(s) directly
- Run targeted Dependency Re-Validation Protocol (see `s5_v2_validation_loop.md`)
- Re-present combined Gate 5

**If user requests significant rework:**
- STOP and clarify scope with user
- May require re-running S5 for affected feature(s) (re-enter Phase 3 for those features)

**After approval:** Gate 5 passes — proceed to SP4 (Phase 6)

**Secondary agents during Gate 5:**
- WAIT — do not proceed to S6

---

### Phase 6: SP4 — Sequential S6 Activation Chain

**After combined Gate 5 approved:**

**Primary action (D8 — Primary is central coordinator):**
1. Document Gate 5 approval
2. Begin S6 for Feature 01 (Primary's own feature)
3. After Feature 01 S7 complete: send S6 activation message to Secondary-A (Feature 02)
4. After Feature 02 S8 complete: send S6 activation message to Secondary-B (Feature 03)
5. Continue sequential chain until all features complete S6-S8

**Secondary agent S6 activation:**
- Wait for Primary's activation message
- Upon receipt: read `stages/s6/s6_execution.md`, update STATUS, begin implementation
- Run S6 → S7 → S8 for your feature
- After S8 complete: send completion message to Primary
- Primary then activates next feature in the chain

**Note:** If an ordering dependency was identified during S5-CA, re-verify the relevant dimensions
(D2/D5/D6/D7) against the prerequisite feature's completed code before finalizing your plan.

**See:** `s5_primary_agent_guide.md` → Phase 5 (SP4 Action) for coordination details

---

## Coordination Mechanisms

### 1. Agent Communication Files

**Messages between agents:**
- Primary inbox: `agent_comms/{secondary_id}_to_primary.md`
- Secondary inbox: `agent_comms/primary_to_{secondary_id}.md`

**Message format:**
```markdown
## Message N (TIMESTAMP) ⏳ UNREAD
**Subject:** Brief description
**Action:** What the recipient needs to do
**Details:** Additional context
**Next:** What happens next
**Acknowledge:** What response is needed (or "No action needed")
```

**Message processing:**
- Check inbox at every 15-min heartbeat
- Mark as READ after processing (change ⏳ UNREAD to ✅ READ)
- Respond to escalations within 15 minutes

**See:** `communication_protocol.md` for full details

---

### 2. Checkpoint Files

**Purpose:** Agent recovery state + staleness detection

**Files:**
- `agent_checkpoints/primary.json`
- `agent_checkpoints/secondary_a.json`
- etc.

**Required fields for S5:**
```json
{
  "agent_id": "Secondary-A",
  "feature": "feature_02_team_penalty",
  "stage": "S5",
  "phase": "Implementation Planning - Phase 1 Draft",
  "last_checkpoint": "2026-01-15T14:30:00Z",
  "next_checkpoint_expected": "2026-01-15T14:45:00Z",
  "status": "IN_PROGRESS",
  "can_resume": true,
  "recovery_instructions": "Resume S5 Phase 1 draft. Check implementation_plan.md for current state."
}
```

**Milestone checkpoints (S5-specific — write a full checkpoint at each):**
- Phase 1 exit: draft `implementation_plan.md` complete, before starting validation loop
- After each clean validation round

**Stale detection:**
- 30 min since `last_checkpoint`: Warning
- 60 min since `last_checkpoint`: Failure (assumed crashed)

**Note:** S5 validation rounds can be intensive. The 30-min warning may fire during deep work. Milestone checkpoints at Phase 1 exit and after each clean round are the primary staleness signal for S5.

**See:** `checkpoint_protocol.md` for complete details

---

### 3. STATUS Files

**Purpose:** Quick status checks without parsing JSON

**Files:**
- `feature_01_{name}/STATUS`
- `feature_02_{name}/STATUS`
- etc.

**Format during S5:**
```text
STAGE: S5
PHASE: Implementation Planning
AGENT: Secondary-A
UPDATED: 2026-01-15T14:30:00Z
STATUS: IN_PROGRESS
BLOCKERS: none
READY_FOR_SYNC: false
```

**Format after S5 complete (waiting for S5-CA):**
```text
STAGE: S5
PHASE: Implementation Planning
AGENT: Secondary-A
UPDATED: 2026-01-15T18:30:00Z
STATUS: WAITING_FOR_SYNC
BLOCKERS: none
READY_FOR_SYNC: true
```

**See:** `templates/feature_status_template.txt`

---

## Agent Roles

### Primary Agent

**Responsibilities:**

1. **Feature 01 Owner:**
   - Complete S5 for Feature 01 (full validation loop, primary clean round + sub-agent confirmation)
   - Write milestone checkpoints at Phase 1 exit and after each clean round

2. **Coordinator:**
   - Generate and send S5 handoff packages (SP2 action)
   - Monitor secondary agents (STATUS, checkpoints, inboxes) every 15 min
   - Handle escalations within 15 min
   - Run S5-CA after all features complete (SP3 action)
   - Present combined Gate 5 to user
   - Coordinate sequential S6 chain (SP4 action — D8)

3. **User Liaison:**
   - Present combined Gate 5 for user review
   - Escalate secondary questions to user
   - Report progress and savings

**Time Allocation:**
- 85% Feature 01 S5 work
- 15% Coordination

**See:** `s5_primary_agent_guide.md` for complete workflow

---

### Secondary Agent

**Responsibilities:**

1. **Feature Owner:**
   - Complete S5 for assigned feature (full validation loop, primary clean round + sub-agent confirmation)
   - Write milestone checkpoints at Phase 1 exit and after each clean round
   - Do NOT present Gate 5 to user — signal WAITING_FOR_SYNC

2. **Communicator:**
   - Update checkpoint every 15 min (plus at milestone exits)
   - Check inbox every 15 min
   - Report progress via STATUS file
   - Escalate when blocked >30 min

3. **Team Player:**
   - Signal completion correctly (STATUS: WAITING_FOR_SYNC, READY_FOR_SYNC: true)
   - Wait for Primary's S5-CA notification before proceeding
   - Re-read `implementation_plan.md` if notified of plan updates
   - Wait for Primary's S6 activation message before implementing

**Time Allocation:**
- 90% Feature S5 work
- 10% Coordination

**See:** `s5_secondary_agent_guide.md` for complete workflow

---

## Sync Points

### Sync Point 2 (SP2): After S4 → Before S5

**Trigger:** S4 complete (Gate 4 approved + `interface_contracts.md` created); Primary confirms `Parallel Mode (S5): enabled` in EPIC_README.

**Primary actions:**
1. Check EPIC_README for `Parallel Mode (S5): enabled`
2. For each secondary: check checkpoint file for status
3. If WAITING + not stale: send activation message pointing to `{feature_folder}/HANDOFF_PACKAGE_S5.md` (include `interface_contracts.md` path)
4. If terminated/stale: save handoff package, present fresh-spawn startup command to user
5. Wait for secondary acknowledgment messages
6. Begin S5 for Feature 01

**Exit criteria:**
- All secondary agents acknowledged activation OR user spawned fresh sessions
- Primary has begun S5 for Feature 01

**Status:** "S5 parallel work starting for all features"

**Note:** SP2 is extended from S2 parallel protocol. In S2 mode, SP2 covered S2→S3. In S5 mode, the additional SP2 action (S5 handoff generation and secondary activation) runs after S4 completes (not immediately after Gate 4 approval — S4 runs first).

---

### Sync Point 3 (SP3): After All S5 Complete → S5-CA

**Trigger:** All feature STATUS files show `STATUS: WAITING_FOR_SYNC` and `READY_FOR_SYNC: true`.

**Primary actions:**
1. Verify all completion messages received
2. Verify all STATUS files show WAITING_FOR_SYNC
3. Verify all checkpoints show S5 complete and are not stale
4. Run S5-CA: `stages/s5/s5_ca_cross_plan_alignment.md`
5. Send notification to secondaries listing which plans were updated
6. Present combined Gate 5 to user

**Secondary actions during SP3:**
- WAIT — do not proceed
- If notified of plan update: re-read `implementation_plan.md`
- Await Gate 5 notification (informational only, no action needed)

**Timeout:** 6 hours from when the first feature completes S5
- If timeout: stale agent protocol — escalate to user

**Status:** "All S5 complete — running Cross-Plan Alignment and combined Gate 5"

---

### Sync Point 4 (SP4): After Combined Gate 5 → S6 Activation Chain

**Trigger:** User approves combined Gate 5.

**Primary actions:**
1. Document Gate 5 approval
2. Begin S6 for Feature 01
3. After each feature's S8 complete: send S6 activation message to next feature's secondary
4. Continue until all features complete S6-S8

**Secondary actions:**
- WAIT for Primary's activation message
- Upon activation: read `stages/s6/s6_execution.md`, begin S6
- After S6 → S7 → S8 complete: send completion message to Primary

**Exit criteria:**
- All features completed S6-S8
- Primary sends final status update

**Status:** "Sequential S6 implementation chain in progress"

---

## File Structure

### New Files Created During S5 Parallel

**feature_XX_{name}/:**
- `HANDOFF_PACKAGE_S5.md` — S5 handoff package (generated by Primary at SP2)
- `implementation_plan.md` — Created during S5 execution

**Coordination files (already exist from S2 parallel — updated for S5):**
- `agent_comms/primary_to_{secondary_id}.md` — Activation messages, S5-CA notifications, S6 activation
- `agent_comms/{secondary_id}_to_primary.md` — Completion signals, escalations
- `agent_checkpoints/{secondary_id}.json` — Updated to `stage: "S5"` during S5 execution

**Epic-level research files (new during S5 parallel):**
- `research/S5_CA_PLAN_ALIGNMENT_{DATE}.md` — S5-CA alignment document

---

## User Experience

### Step 1: Gate 4 Approved + S4 Complete

User approves epic plan (Gate 4, end of S3). Primary runs S4 solo (Interface Contract Definition). After S4 exits, Primary begins SP2 action.

### Step 2: Secondary Activation

**If secondaries are still WAITING from S2 phase:**
```text
S3 complete. Activating secondary agents for S5 (Implementation Planning)...
- Sent activation message to Secondary-A (Feature 02) — agent still active.
- Sent activation message to Secondary-B (Feature 03) — agent still active.
Waiting for acknowledgment...
Both agents acknowledged. Beginning S5 for Feature 01.
```

**If secondaries have terminated:**
```text
S3 complete. Setting up S5 parallel work...
⚠️  Secondary-A checkpoint is stale (>60 min). Fresh session needed.
⚠️  Secondary-B checkpoint is stale (>60 min). Fresh session needed.

Handoff packages saved:
  feature_02_team_penalty/HANDOFF_PACKAGE_S5.md
  feature_03_scoring_update/HANDOFF_PACKAGE_S5.md

📋 SETUP INSTRUCTIONS

Open 2 new Claude Code sessions:

🚀 SECONDARY AGENT A (Feature 02):
In a new session, enter:
  You are a secondary agent for SHAMT-{N} for feature 02 (S5)

🚀 SECONDARY AGENT B (Feature 03):
In a new session, enter:
  You are a secondary agent for SHAMT-{N} for feature 03 (S5)
```

### Step 3: Agents Work in Parallel

User monitors across sessions:
- Primary: "Working on Feature 01 S5 — Phase 1 Draft..."
- Secondary-A: "Working on Feature 02 S5 — Validation Round 1..."
- Secondary-B: "Working on Feature 03 S5 — Phase 1 Draft..."

### Step 4: All S5 Complete, Running S5-CA

User sees (from Primary):
```text
✅ All 3 features completed S5 (Implementation Planning)!
Running S5-CA (Cross-Plan Alignment)...

S5-CA complete. 1 conflict found and resolved:
  - feature_02 and feature_03 both planned to use the same shared utility path.
  - Resolved: updated feature_03/implementation_plan.md to use the shared utility.

Presenting combined Gate 5...
```

### Step 5: Combined Gate 5

User reviews all implementation plans together and approves once.

### Step 6: Sequential S6 Chain

```text
Gate 5 approved! Beginning sequential implementation chain...

Feature 01 (Primary): Starting S6...
[After Feature 01 S7 complete]
  Activating Feature 02...
[After Feature 02 S8 complete]
  Activating Feature 03...
```

**User Effort:**
- Initial activation: 2–5 minutes
- During S5: Minimal (monitor; respond to escalations if asked)
- Gate 5: Review all plans once (not per-feature)
- Benefit: ~3.5–6 hours net saved per parallel feature (after S5-CA overhead)

---

## Troubleshooting

### Issue 1: Secondary Agent Doesn't Respond to Activation Message

**Symptoms:**
- Activation message sent >30 min ago
- No acknowledgment message
- No STATUS file update

**Diagnosis:**
- Secondary session crashed since S2 phase
- Secondary missed inbox message

**Fix:**
- Check secondary checkpoint — if stale, assume terminated
- Ensure `{feature_folder}/HANDOFF_PACKAGE_S5.md` is saved
- Present fresh-spawn startup command to user

---

### Issue 2: Secondary Agent Stale During S5 Execution

**Symptoms:**
- Checkpoint >30 min old with no update
- No messages from secondary

**Diagnosis:**
- S5 validation loops are long (4.5–7 hours) — some periods of no 15-min heartbeat are normal
- Key signal: milestone checkpoint should appear at Phase 1 exit (~1–2 hours in)

**Fix:**
- If no milestone checkpoint after 1.5+ hours from activation: send warning message
- If no response in 60 min: assume crashed — escalate to user
- User can: ask secondary to resume (check existing `implementation_plan.md`), or Primary absorbs the feature
- See: `stale_agent_protocol.md` for full recovery procedure

---

### Issue 3: S5-CA Finds a Spec Discrepancy

**Symptoms:**
- During S5-CA, Primary finds two plans that require contradictory spec-level behavior (not just plan-level)

**Fix:**
- STOP S5-CA immediately — do NOT proceed to Gate 5
- Escalate to user with exact discrepancy description
- User decides: update spec(s) and re-run affected S5(s), or accept one interpretation
- Document resolution in S5-CA alignment file
- Resume S5-CA after resolution

---

### Issue 4: Gate 5 Requires Significant Plan Rework

**Symptoms:**
- User requests major changes to one or more implementation plans during Gate 5

**Fix:**
- STOP — do not proceed to SP4
- Clarify scope of change request
- If minor (targeted dimensions): update plan, run Dependency Re-Validation Protocol, re-present Gate 5
- If significant: re-run S5 for affected feature(s) (return to Phase 3 for those features)
- Notify affected secondaries if their plans were updated by Primary

---

### Issue 5: Secondary Agent Crashes After Gate 5, Before S6 Activation

**Symptoms:**
- Primary sends S6 activation message but secondary doesn't respond
- No checkpoint activity from secondary

**Fix:**
- Check `{feature_folder}/HANDOFF_PACKAGE_S5.md` is present (already saved at SP2)
- Ask user to spawn fresh session with minimal startup command
- New session reads `HANDOFF_PACKAGE_S5.md` and existing `implementation_plan.md`
- Primary resends S6 activation message

---

## Performance Metrics

### Time Savings

**Expected S5 time savings (gross, before S5-CA overhead):**
- 2-feature epic: ~4.5–7 hours (50% S5 reduction)
- 3-feature epic: ~9–14 hours (67% S5 reduction)
- 4-feature epic: ~13.5–21 hours (75% S5 reduction)

**S5-CA overhead:** ~0.5–1 hour (subtract from gross for net savings)

### Break-Even Point

**S5 parallelization is worth it at 2 features** (vs. S2's 3+ threshold) because:
- Per-feature gross savings are 4.5–7 hours (vs. ~2 hours for S2)
- Pre-existing secondary agents reduce activation overhead
- S5-CA overhead (~1 hour) is well below the 2-feature gross savings floor of 4.5 hours

### Coordination Overhead

**Expected:**
- Primary coordination: ~15 min/hour (15%)
- Secondary coordination: ~5 min/hour (8%)
- Total overhead per session: ~1–1.5 hours

---

*End of s5_parallel_protocol.md*
