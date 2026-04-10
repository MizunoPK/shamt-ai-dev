# S2 Parallelization Protocol - Complete Guide

**Version:** 1.0
**Scope:** S2 (Feature Deep Dives) parallelization only
**Risk Level:** LOW (documentation only, no code conflicts)
**Time Savings:** 40-60% reduction in S2 time for epics with 3+ features

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

### What is S2 Parallelization?

S2 parallelization enables **multiple agents to work on S2 (Feature Deep Dives) simultaneously**, each owning one feature. This reduces epic planning time by allowing features to be researched and specified in parallel instead of sequentially.

### Time Savings Example

**3-feature epic:**
```text
Sequential S2:
- Feature 1: 2 hours
- Feature 2: 2 hours
- Feature 3: 2 hours
Total: 6 hours

Parallel S2:
- All 3 features: 2 hours (max of 2, 2, 2)
Total: 2 hours

SAVINGS: 4 hours (67% reduction in S2 time)
```

**Epic-level impact:**
```text
Sequential Epic: S1(2h) + S2(6h) + S3(1h) + S4(0.5h) + S5-S8(15h) + S9(2h) + S10(1h) + S11(1h) = 28.5h
Parallel S2 Epic: S1(2h) + S2(2h) + S3(1h) + S4(0.5h) + S5-S8(15h) + S9(2h) + S10(1h) + S11(1h) = 24.5h

SAVINGS: 4 hours (14% epic-level reduction)
```

### Why S2 Only?

**Low Risk:**
- Documentation only (spec.md, checklist.md, README.md)
- No code changes = no merge conflicts
- Shared files are sectioned (minimal conflicts)
- S3 validates all specs (quality checkpoint)

**Fast Validation:**
- Test coordination mechanisms with minimal stakes
- Proves infrastructure before S5-S8 parallelization
- Foundation for future parallel work

**High Value:**
- 2-3 hours savings per feature
- Scales well (more features = more savings)
- User sees immediate benefit

### Scope

**Parallelizable:**
- ✅ S2.P1: Spec Creation & Refinement (all 3 iterations — I1 Discovery, I2 Checklist, I3 Refinement)

**Note:** The old 3-phase structure (S2.P1 Research, S2.P2 Specification, S2.P3 Refinement) has been superseded. All spec work is now in S2.P1 (`s2_p1_spec_creation_refinement.md`). S2.P2 Cross-Feature Alignment is run by Primary only after all agents complete S2.P1.

**Sequential (Unchanged):**
- ❌ S1: Epic Planning (Primary only)
- ❌ S3: Epic-Level Docs, Tests, and Approval (Primary only)
- ✅ S4: Interface Contract Definition (Primary only)
- ❌ S5-S8: Feature Implementation (sequential in this plan)
- ❌ S9-S11: Epic completion (Primary only)

---

## Architecture

### Agent Model

```text
┌─────────────────────────────────────────────────────────┐
│                    PRIMARY AGENT                        │
│  - Owns Feature 01                                      │
│  - Coordinates parallel work                            │
│  - Generates handoff packages                           │
│  - Monitors secondary agents                            │
│  - Handles escalations                                  │
│  - Runs S1, S3, S4, S5–S11                            │
└─────────────────────────────────────────────────────────┘
          │                                   │
          │ handoff package                   │ handoff package
          ▼                                   ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│   SECONDARY AGENT A      │    │   SECONDARY AGENT B      │
│  - Owns Feature 02       │    │  - Owns Feature 03       │
│  - Works on S2 only      │    │  - Works on S2 only      │
│  - Reports via comms/    │    │  - Reports via comms/    │
│  - Escalates to Primary  │    │  - Escalates to Primary  │
└──────────────────────────┘    └──────────────────────────┘

All agents work simultaneously on S2:
- Primary: S2 for Feature 01
- Secondary-A: S2 for Feature 02
- Secondary-B: S2 for Feature 03

After S2 complete → Sync → Primary runs S3 → Primary runs S4 (Interface Contract Definition)
```

### Directory Structure

**🚨 CRITICAL STRUCTURE REQUIREMENTS**

This structure is **MANDATORY**. Deviations will cause validation failures and coordination issues.

```markdown
.shamt/epics/SHAMT-N-epic_name/
├── EPIC_README.md                 # Sectioned (agents own sections)
├── epic_smoke_test_plan.md
├── epic_lessons_learned.md
│
├── .epic_locks/                   # NEW - Lock files
│   ├── epic_readme.lock
│   └── epic_smoke_test_plan.lock
│
├── agent_comms/                   # NEW - Communication FILES (no subdirs)
│   ├── primary_to_secondary_a.md
│   ├── secondary_a_to_primary.md
│   ├── primary_to_secondary_b.md
│   └── secondary_b_to_primary.md
│
├── agent_checkpoints/             # NEW - Checkpoint .json FILES (no subdirs)
│   ├── primary.json
│   ├── secondary_a.json
│   └── secondary_b.json
│
├── feature_01_player_json/        # Primary's feature
│   ├── STATUS                     # NEW - Quick status (REQUIRED for ALL features)
│   ├── HANDOFF_PACKAGE.md         # NEW - Handoff for secondaries (if applicable)
│   ├── README.md
│   ├── spec.md
│   ├── checklist.md
│   └── lessons_learned.md
│
├── feature_02_team_penalty/       # Secondary-A's feature
│   ├── STATUS                     # REQUIRED
│   ├── HANDOFF_PACKAGE.md         # Handoff for this secondary
│   └── [same structure]
│
└── feature_03_scoring_update/     # Secondary-B's feature
    ├── STATUS                     # REQUIRED
    ├── HANDOFF_PACKAGE.md         # Handoff for this secondary
    └── [same structure]
```

### Prohibited Structures

**❌ DO NOT create these directories:**

```markdown
❌ parallel_work/                    # Use agent_comms/ and agent_checkpoints/ instead
❌ agent_comms/coordination/         # Coordination files go directly in agent_comms/
❌ agent_comms/agent_checkpoints/    # Checkpoints go in top-level agent_checkpoints/
❌ agent_comms/inboxes/              # Communication files go directly in agent_comms/
❌ agent_comms/parallel_work/        # No subdirectories under agent_comms/
```

**Rule:** Only THREE top-level coordination directories allowed:
1. `.epic_locks/` - Lock files
2. `agent_comms/` - Communication FILES only (no subdirectories)
3. `agent_checkpoints/` - Checkpoint .json FILES only (no subdirectories)

### Handoff Package Format (HANDOFF_PACKAGE.md)

**Purpose:** Each feature's handoff package provides secondary agents with the minimal context needed to work independently on that feature.

**Location:** `feature_XX_{name}/HANDOFF_PACKAGE.md` (created by Primary after S2.P1 validation completes)

**Required Contents:**

```markdown
## Handoff Package: Feature XX {feature_name}

**Created By:** Primary Agent
**Date:** {YYYY-MM-DD HH:MM}
**Feature:** feature_XX_{name}
**Secondary Agent Assignment:** {agent_id} (or "TBD if not yet spawned")

### Context From Discovery

**Epic-Level Goals:**
[1-2 sentences from DISCOVERY.md about how this feature fits the epic]

**Feature-Specific Requirements:**
[Bullet list of feature-specific requirements extracted from DISCOVERY.md]

**Feature Integration Points:**
[Which other features does this integrate with? What are the touchpoints?]

### Research Findings (From S2.P1 Research)

**Code Locations Relevant to This Feature:**
- [File:line] - [description]
- [File:line] - [description]

**Existing Patterns to Follow:**
- [Pattern 1 with example]
- [Pattern 2 with example]

**External Dependencies (if any):**
- [Library/API with compatibility notes]

### Specification Status

**Spec.md Status:** DRAFT / VALIDATED / USER_APPROVED
**Current Version:** {version}
**Checklist Items:** {N} total, {answered} answered, {pending} pending

### Outstanding Questions

If checklist.md has pending questions, list them here:

| # | Question | Context | Required By |
|---|----------|---------|-------------|
| {N} | {question text} | [brief context] | S2.P1.I2 (before user approval) |

### Known Constraints

- [Any constraint from epic or discovery that affects implementation]
- [Technical limitation affecting scope]

### Next Steps for Secondary Agent

1. **S2.P1.I2:** Resolve outstanding questions (if any)
2. **S2.P1.I3:** Run validation loop (reference: reference/validation_loop_spec_refinement.md)
3. **Gate 3:** Get user approval
4. **Report:** Submit status file with READY_FOR_SYNC = true
5. **Wait:** Primary will run S2.P2 (cross-feature alignment) after all secondaries complete S2.P1

**Escalation Contact:** [Primary Agent ID - use this for issues]
**Escalation Method:** Create message in agent_comms/{YOUR_ID}_to_PRIMARY.md

---

### Optional: Implementation Preview (Added by Primary if helpful)

[If Primary foresees specific implementation challenges, include rough notes here. Optional.]
```

**Validation:**
- Handoff must be created AFTER S2.P1 validation passes (Gate 1 passed)
- Must include all 6 required sections above
- Secondary agents use this to understand context before starting their S2.P1

#### Copy-Paste Template

**Use this template to create HANDOFF_PACKAGE.md in each feature folder after S2.P1 validation:**

```markdown
## Handoff Package: Feature XX {feature_name}

**Created By:** {Your Agent ID}
**Date:** {YYYY-MM-DD HH:MM}
**Feature:** feature_XX_{name}
**Secondary Agent Assignment:** {agent_id}

### Context From Discovery

**Epic-Level Goals:**
[1-2 sentences from DISCOVERY.md]

**Feature-Specific Requirements:**
- [Requirement 1]
- [Requirement 2]

**Feature Integration Points:**
[List features this integrates with and touchpoints]

### Research Findings (From S2.P1 Research)

**Code Locations Relevant to This Feature:**
- {file.py:line} - {description}
- {file.py:line} - {description}

**Existing Patterns to Follow:**
- [Pattern name]: [example or location]

**External Dependencies:**
- {library/API}: {compatibility notes}

### Specification Status

**Spec.md Status:** DRAFT / VALIDATED / USER_APPROVED
**Current Version:** {version}
**Checklist Items:** {total}, {answered} answered, {pending} pending

### Outstanding Questions

| # | Question | Context | Due |
|---|----------|---------|-----|
| 1 | [question] | [context] | S2.P1.I2 |

### Known Constraints

- [constraint 1]
- [constraint 2]

### Next Steps for Secondary Agent

1. **S2.P1.I2:** Resolve questions
2. **S2.P1.I3:** Run validation loop
3. **Gate 3:** Get user approval
4. **Report:** READY_FOR_SYNC = true
5. **Wait:** Primary runs S2.P2

**Escalation:** {primary-agent-id} via agent_comms/
```

### File Format Requirements

**Checkpoint files:**
- ✅ MUST use `.json` extension: `secondary_a.json`
- ❌ NOT `.md`: `secondary_a.md` or `secondary_a_checkpoint.md`
- Format: JSON with defined schema (see checkpoint_protocol.md)

**Communication files:**
- ✅ MUST be individual `.md` files: `primary_to_secondary_a.md`
- ❌ NOT directories: `inboxes/from_primary/`
- Format: Markdown with message structure

**STATUS files:**
- ✅ MUST be plain text key-value format
- ✅ REQUIRED for ALL features (including Feature 01 - Primary's feature)
- Location: `feature_XX_{name}/STATUS`

### Coordination Infrastructure

**Four coordination systems:**

1. **Lock Files** (`.epic_locks/`)
   - Prevent race conditions on shared files
   - File-based atomic locking
   - 5-minute timeout (auto-release)
   - Used for: EPIC_README.md, epic_smoke_test_plan.md

2. **Communication Channels** (`agent_comms/`)
   - Agent-to-agent messaging
   - One writer per file (zero conflicts)
   - Markdown format (human-readable)
   - Used for: Escalations, updates, coordination

3. **Checkpoint Files** (`agent_checkpoints/`)
   - Crash recovery system
   - JSON format, updated every 15 min
   - Contains: stage, progress, recovery instructions
   - Used for: Resume after crash, stale detection

4. **STATUS Files** (`feature_XX/STATUS`)
   - Quick status checks
   - Plain text key-value format
   - One per feature (no conflicts)
   - Used for: Current stage, blockers, ready state

---

## Complete Workflow

### Phase 1: S1 Epic Planning (Primary Solo)

**Standard S1 workflow, plus:**

#### Step: Analyze Features for Parallelization

**After creating feature folders:**

1. Count features and assess benefit
2. Analyze dependencies between features
3. Document parallelization decision

**Decision criteria:**
- 2 features: Modest benefit (~2 hours saved)
- 3 features: Good benefit (~4 hours saved)
- 4+ features: High benefit (~6+ hours saved)

**Note:** Dependencies matter for S5-S8, but NOT for S2 (specs can be written in parallel even if features depend on each other for implementation)

---

### Phase 2: Offer Parallel Work (Primary)

**After S1 complete:**

#### Step 1: Calculate Time Savings

```text
Sequential: (Feature count) × (2 hours per feature)
Parallel: 2 hours (max of all features)
Savings: Sequential - Parallel
```

#### Step 2: Present Offering to User

**Use template:**
```markdown
✅ S1 (Epic Planning) complete!

I've identified {N} features for this epic:
- feature_01: {description} (2 hours S2)
- feature_02: {description} (2 hours S2)
- feature_03: {description} (2 hours S2)

🚀 PARALLEL WORK OPPORTUNITY

I can enable parallel work for S2 (Feature Deep Dives), reducing planning time:

**Sequential approach:** {N} × 2 hours = {total} hours
**Parallel approach:** 2 hours (simultaneously)

TIME SAVINGS: {savings} hours ({percent}% reduction)

**COORDINATION:**
- I'll spawn {N-1} secondary agents automatically. No new terminals needed.
- I'll coordinate all agents via EPIC_README.md
- Implementation (S5-S8) remains sequential in this plan

Would you like to:
1. ✅ Enable parallel work for S2
2. ❌ Continue sequential
3. ❓ Discuss parallelization approach
```

#### Step 3: Handle Response

- **Option 1 (Enable):** Proceed to Phase 3
- **Option 2 (Sequential):** Continue standard workflow
- **Option 3 (Discuss):** Answer questions, re-present

---

### Phase 3: Generate Handoff Packages (Primary)

**When user accepts:**

#### Step 1: Create Infrastructure

```bash
mkdir -p .epic_locks
mkdir -p agent_comms
mkdir -p agent_checkpoints
```

#### Step 2: Assign Features to Agents

```text
Primary: Feature 01 (always)
Secondary-A: Feature 02
Secondary-B: Feature 03
Secondary-C: Feature 04 (if exists)
etc.
```

#### Step 3: Generate Handoff Packages

**For each secondary agent:**

Use template from `templates/handoff_package_s2_template.md`:

```bash
generate_s2_handoff_package \
  "{EPIC_NAME}" \
  "{EPIC_PATH}" \
  "{FEATURE_FOLDER}" \
  "{PRIMARY_AGENT_ID}" \
  "{SECONDARY_AGENT_ID}"
```

**Output:** Copy-paste ready handoff package

#### Step 4: Spawn Secondaries via Task Tool

Spawn all secondaries in a **single parallel response** using the Task tool:

- `subagent_type: general-purpose, run_in_background: true`
- Prompt: `"You are a secondary agent for SHAMT-{N} for feature {N}. Your handoff package is at /absolute/path/to/{feature_folder}/HANDOFF_PACKAGE.md. Read it and follow its instructions."`
- **IMPORTANT:** Use absolute paths — sub-agents have no guaranteed working directory

Record `output_file` paths in primary checkpoint under `sub_agent_output_files`.

Report: "Spawned {N-1} secondary agents. No new terminals needed."

**Begin Feature 01 work immediately** — do not wait for secondaries to start.

Handle immediate Task call failures: offer manual terminal fallback (user opens session, enters one-line startup) or sequential fallback (Primary takes the feature).

#### Step 5: First-Heartbeat Check (15 min)

At the first coordination heartbeat (~15 min after spawning):
- Verify STATUS file created for each secondary's feature folder
- Verify checkpoint JSON created for each secondary in `agent_checkpoints/`
- If either absent → spawning failure → same escalation as Step 4 failure
- If both present → secondary successfully started; continue monitoring

**Proceed to Phase 4** (already underway for Feature 01)

---

### Phase 4: Parallel S2 Work

**All agents work simultaneously:**

#### Primary Responsibilities

**85% Feature 01 work:**
- Execute S2.P1 for Feature 01 (all 3 iterations using `s2_p1_spec_creation_refinement.md`)

**15% Coordination:**
- Check inboxes every 15 min
- Respond to escalations within 15 min
- Monitor STATUS files
- Check checkpoints for staleness
- Update sync status

**Work in time blocks:**
```text
45 min: Deep work on Feature 01
15 min: Coordination (inbox, status, escalations)
Repeat
```

#### Secondary Responsibilities

**90% Feature work:**
- Execute S2.P1 for assigned feature (all 3 iterations using `s2_p1_spec_creation_refinement.md`)

**10% Coordination:**
- Update checkpoint every 15 min
- Check inbox every 15 min
- Update STATUS file every 15 min
- Update EPIC_README.md section
- Escalate if blocked >30 min

#### Coordination Heartbeat (All Agents)

**Every 15 minutes:**

1. **Update checkpoint:**
   ```json
   {
     "last_checkpoint": "now",
     "stage": "current stage",
     "current_step": "what I'm doing",
     "completed_steps": ["step1", "step2"],
     "files_modified": ["spec.md"]
   }
   ```

2. **Check inbox:**
   ```bash
   grep "⏳ UNREAD" agent_comms/{inbox_file}
   ```

3. **Read and process messages:**
   - Mark as READ
   - Take action
   - Reply if needed

4. **Update STATUS:**
   ```text
   STAGE: S2.P2
   STATUS: IN_PROGRESS
   BLOCKERS: none
   READY_FOR_SYNC: false
   ```

5. **Update EPIC_README.md (if progress changed):**
   - Acquire lock
   - Update your section only
   - Release lock

---

### Phase 5: Escalation Handling (Primary)

**When receiving escalation from secondary:**

#### Step 1: Read Escalation

```markdown
Subject: ESCALATION - Spec Ambiguity
Issue: Unclear if feature should use CSV or API
Blocked For: 30 minutes
```

#### Step 2: Determine Action

**Can you answer?**
- Yes → Respond directly
- No → Ask user, then respond

#### Step 3: Ask User (if needed)

**In your session:**
```markdown
Secondary-A has a question about Feature 02:
[Explain question]

Options:
A) Approach 1
B) Approach 2
C) Approach 3

Which approach?
```

#### Step 4: Send Response

**To Secondary-A:**
```markdown
## Message X (TIMESTAMP) ⏳ UNREAD
**Subject:** Re: ESCALATION - Spec Ambiguity
**Action:** Use Option A
**Details:** User confirmed [explanation]
**Next:** Update spec.md, proceed with S2.P2
**Acknowledge:** Reply when updated
```

#### Step 5: Wait for Acknowledgment

**Secondary replies:**
```markdown
Subject: Re: ESCALATION response
Action: Spec updated
Next: Continuing S2.P2
```

**Mark as READ and continue**

---

### Phase 6: Sync Point - S2 Complete

**When all features complete S2.P1:**

#### Step 1: Verify All Complete

```bash
# Check all STATUS files
for STATUS in feature_*/STATUS; do
  READY=$(grep "READY_FOR_SYNC" "$STATUS" | cut -d' ' -f2)
  echo "$STATUS: $READY"
done

# All should show: true
```

#### Step 2: Update Sync Status

**In EPIC_README.md:**
```markdown
## Sync Status

**Current Sync Point:** After S2 → Before S3
**Status:** ALL COMPLETE (3 of 3 features)

| Feature | Agent | Complete | Time |
|---------|-------|----------|------|
| feature_01 | Primary | ✅ | 14:00 |
| feature_02 | Sec-A | ✅ | 14:25 |
| feature_03 | Sec-B | ✅ | 14:30 |

All features complete! Proceeding to S3.
```

#### Step 3: Notify User

```markdown
✅ All 3 features completed S2!

**Total S2 Time:** 2.5 hours
**Time Saved:** 3.5 hours (vs 6 hours sequential)

🔄 Now running S3 (Epic-Level Docs, Tests, and Approval)
```

#### Step 4: Notify Secondaries

```markdown
## Message (TIMESTAMP) ⏳ UNREAD
**Subject:** S2 Complete - Running S3
**Status:** All features done
**Next:** I'm running S3 alone
**Your Action:** WAIT - no action needed
```

---

### Phase 7: S3 Epic-Level Docs, Tests, and Approval (Primary Solo)

**Run S3 alone:**

1. Follow guide: `stages/s3/s3_epic_planning_approval.md`
2. S3.P1: Create epic smoke test plan (integration tests across all features)
3. S3.P2: Refine EPIC_README.md with feature summaries and arch decisions
4. S3.P3: Gate 4 — get user approval of epic plan (mandatory before S4)
5. S4: Validate feature contracts
5. Complete S3

**No parallel work in S3** (requires holistic view)

---

### Phase 8: S4 — Interface Contract Definition

**S4: Interface Contract Definition (Primary only)**
Run S4 to define cross-feature interface contracts before S5 begins.
See `stages/s4/s4_interface_contracts.md`.

**Test Scope Decision is Step 0b of S5 (per feature):**
- Read Testing Approach (A/B/C/D) from EPIC_README
- Follow `stages/s5/s5_v2_validation_loop.md` Step 0b for each feature

---

### Phase 9: Notify Completion (Primary)

**Send final messages to secondaries:**

```markdown
## Message (TIMESTAMP) ⏳ UNREAD
**Subject:** S3 Complete - Running S4
**Status:** All planning complete; S4 (Interface Contract Definition) starting
**Findings:** No conflicts found
**Next:** S4 contract validation, then implementation (S5-S8)
**Your Action:** Can close sessions or idle

Thank you for parallel work during S2!

**Results:**
- Time: 2.5 hours
- Saved: 3.5 hours (58%)
- Issues: None
- Overhead: 20%
```

**Secondaries can now:**
- Close sessions (S2 work done)
- OR keep open to monitor progress
- No active work required

---

## Coordination Mechanisms

### 1. Lock File System

**Purpose:** Serialize access to shared files

**Files:**
- `.epic_locks/epic_readme.lock`
- `.epic_locks/epic_smoke_test_plan.lock`

**Protocol:**
```bash
# Acquire lock
while ! try_acquire_lock "epic_readme"; do
  sleep 5
done

# Perform operation
edit_file "EPIC_README.md"

# Release lock
release_lock "epic_readme"
```

**Timeout:** 5 minutes (auto-release if holder crashes)

**See:** `lock_file_protocol.md` for complete details

### 2. Communication Channels

**Purpose:** Agent-to-agent messaging

**Files:**
- `agent_comms/primary_to_secondary_a.md` (P writes, A reads)
- `agent_comms/secondary_a_to_primary.md` (A writes, P reads)
- Similar for Secondary-B, C, etc.

**Message format:**
```markdown
## Message 3 (2026-01-15 14:30) ⏳ UNREAD
**Subject:** Message subject
**Action:** What to do
**Details:** Context
**Next:** Next steps
**Acknowledge:** How to respond
```

**Read receipts:**
- ⏳ UNREAD → ✅ READ

**See:** `communication_protocol.md` for complete details

### 3. Checkpoint System

**Purpose:** Crash recovery

**Files:**
- `agent_checkpoints/primary.json`
- `agent_checkpoints/secondary_a.json`
- etc.

**Format:**
```json
{
  "agent_id": "Secondary-A",
  "stage": "S2.P2",
  "last_checkpoint": "2026-01-15T14:30:00Z",
  "recovery_instructions": "Resume from S2.P2, 80% done",
  "files_modified": ["spec.md", "checklist.md"]
}
```

**Update frequency:** Every 15 minutes

**Stale detection:**
- 30 min: Warning
- 60 min: Failure (assumed crashed)

**See:** `checkpoint_protocol.md` for complete details

### 4. STATUS Files

**Purpose:** Quick status checks

**Files:**
- `feature_01_player_json/STATUS`
- `feature_02_team_penalty/STATUS`
- etc.

**Format:**
```text
STAGE: S2.P2
PHASE: Specification
AGENT: Secondary-A
UPDATED: 2026-01-15T14:30:00Z
STATUS: IN_PROGRESS
BLOCKERS: none
READY_FOR_SYNC: false
```

**Benefits:**
- One file per feature (no conflicts)
- Easy to parse (key-value)
- Quick scan by Primary

**See:** `templates/feature_status_template.txt`

---

## Agent Roles

### Primary Agent

**Responsibilities:**

1. **Feature 01 Owner:**
   - Complete S2.P1 for Feature 01 (all 3 iterations)
   - After all secondaries complete, run S2.P2 Cross-Feature Alignment (Primary only)

2. **Coordinator:**
   - Generate handoff packages
   - Monitor secondary agents (STATUS, checkpoints)
   - Handle escalations (respond within 15 min)
   - Run S3 solo
   - Run S4 (Interface Contract Definition) solo
   - Manage sync points

3. **User Liaison:**
   - Offer parallel work
   - Present handoff packages
   - Escalate secondary questions to user
   - Report progress and savings

**Time Allocation:**
- 85% Feature 01 work
- 15% Coordination

**Best Practice:** Choose simplest/smallest feature as Feature 01

**See:** `s2_primary_agent_guide.md` for complete workflow

### Secondary Agent

**Responsibilities:**

1. **Feature Owner:**
   - Complete S2.P1 for assigned feature (all 3 iterations)
   - Full S2.P1 workflow for one feature

2. **Communicator:**
   - Update checkpoint every 15 min
   - Check inbox every 15 min
   - Report progress via STATUS
   - Escalate when blocked >30 min

3. **Team Player:**
   - Coordinate via established protocols
   - Don't block other agents
   - Signal completion when done
   - Wait for Primary to run S3

**Time Allocation:**
- 90% Feature work
- 10% Coordination

**Key Principle:** Own ONE feature, escalate when stuck

**See:** `s2_secondary_agent_guide.md` for complete workflow

---

## Sync Points

### Sync Point 1: After S1 → Before S2

**Trigger:** Primary completes S1

**Actions:**
1. Primary offers parallel work
2. User accepts or declines
3. If accepted: Primary generates handoffs
4. Primary spawns secondaries via Task tool
5. Secondaries start automatically
6. ALL agents begin S2 simultaneously

**Status:** "Parallel work starting"

### Sync Point 2: After S2 → Before S3

**Trigger:** All agents complete S2.P1

**Status Checks:**
```bash
# All STATUS files must show:
READY_FOR_SYNC: true
```

**Actions:**
1. Primary verifies all complete
2. Primary updates sync status
3. Primary notifies user and secondaries
4. Primary proceeds to S3 (solo)

**Timeout:** 2 hours from first completion
- If timeout: Defer slow features to later
- Proceed with completed features

**Status:** "Waiting for all features to complete S2"

### Sync Point 3: After S3 → Before S5

**Trigger:** Primary completes S3 and S4

**Actions:**
1. Primary notifies secondaries (S3 done)
2. Secondaries close sessions or idle
3. Primary proceeds to S5 (sequential implementation)

**Status:** "S2 parallel work complete, implementation sequential"

**Note:** In S2 plan only, S5-S8 remains sequential

---

## File Structure

### Epic-Level Files

**EPIC_README.md:**
- Sectioned (each agent owns a section)
- Requires lock for updates
- Contains: Agent Assignment, Sync Status, Progress sections

**epic_smoke_test_plan.md:**
- Updated in S3.P1 (Primary only; S4 validates contracts)
- Requires lock (though only Primary uses in S2 plan)

**epic_lessons_learned.md:**
- Updated in S9.P4 (not affected by S2 parallelization)

### Coordination Files

**.epic_locks/:**
- `epic_readme.lock` - Lock for EPIC_README.md
- `epic_smoke_test_plan.lock` - Lock for test plan

**agent_comms/:**
- `primary_to_secondary_a.md` - P→A inbox
- `secondary_a_to_primary.md` - A→P outbox
- `primary_to_secondary_b.md` - P→B inbox
- `secondary_b_to_primary.md` - B→P outbox
- etc.

**agent_checkpoints/:**
- `primary.json` - Primary checkpoint
- `secondary_a.json` - Secondary-A checkpoint
- `secondary_b.json` - Secondary-B checkpoint
- etc.

### Feature-Level Files

**feature_XX_{name}/:**
- `STATUS` - NEW: Quick status (key-value)
- `README.md` - Agent Status, guide tracking
- `spec.md` - Requirements (created in S2.P2)
- `checklist.md` - User questions (created in S2.P2)
- `lessons_learned.md` - Retrospective (created in S7.P3, not S2)

---

## User Experience

### User Workflow

**Step 1: Primary Offers Parallel Work**

User sees:
```text
🚀 PARALLEL WORK OPPORTUNITY
Save 4 hours by enabling parallel S2 work

Would you like to:
1. ✅ Enable
2. ❌ Continue sequential
3. ❓ Discuss
```

**Step 2: User Accepts**

User responds: "1" or "Enable parallel work"

**Step 3: Primary Spawns Secondary Agents Automatically**

User sees:
```text
🚀 SPAWNING SECONDARY AGENTS

Spawning 2 secondary agents automatically. No new terminals needed.

✅ Secondary Agent A spawned (Feature 02)
✅ Secondary Agent B spawned (Feature 03)

Beginning Feature 01 work now.
```

**Step 4: Agents Work in Parallel**

Primary begins Feature 01 immediately after spawning secondaries.

**Step 5: Agents Work in Parallel**

User sees (in each session):
- Primary: "Working on Feature 01 S2.P2..."
- Secondary-A: "Working on Feature 02 S2.P1..."
- Secondary-B: "Working on Feature 03 S2.P1 I3 (Refinement)..."

**Step 6: Agents Complete**

User sees (from Primary):
```text
✅ All 3 features completed S2!
Time: 2.5 hours
Saved: 3.5 hours

Now running S3...
```

**Step 7: Secondaries Idle**

User sees (from secondaries):
```text
S2 complete for my feature.
Waiting for Primary to run S3.
You can close this session or keep open to monitor.
```

**User Effort:**
- Initial: None (agents spawned automatically)
- During: Minimal (just monitor)
- Benefit: 4 hours saved

---

## Troubleshooting

### Issue 1: Secondary Agent Won't Start

**Symptoms:**
- Task tool spawn call failed (error returned immediately)
- OR: No checkpoint file created within 15 min of spawning
- OR: No STATUS file created within 15 min of spawning

**Diagnosis:**
- Check Task tool call succeeded (no error in output)
- Verify handoff file path is absolute and file exists on disk
- Verify epic folder and feature folder exist

**Fix:**
- If Task call failed: Re-attempt spawn; offer manual terminal fallback (user opens new Claude Code session and enters one-line startup command) or sequential fallback (Primary takes the feature)
- If first-heartbeat check fails (15 min): Secondary spawned but not initializing — verify handoff package path is absolute and correct, then re-spawn via Task tool
- Re-generate handoff package with correct absolute paths if needed

### Issue 2: Lock Contention (All Agents Waiting)

**Symptoms:**
- Agents report "Waiting for lock..."
- Multiple retries
- Slow progress

**Diagnosis:**
- Check `.epic_locks/epic_readme.lock`
- See who holds lock and for how long

**Fix:**
- Wait for lock holder to finish (should be <30 seconds)
- If >5 minutes: Lock may be stale, Primary can force-release
- Reduce EPIC_README update frequency if chronic

### Issue 3: Secondary Agent Stale (No Checkpoint Update)

**Symptoms:**
- Primary sees "Secondary-A checkpoint >30 min old"
- No recent STATUS updates
- No messages from secondary

**Diagnosis:**
- Secondary session crashed
- Secondary stuck/blocked
- Secondary forgot to update checkpoint

**Fix:**
- Primary sends warning message
- If no response in 30 more min: Assume crashed
- Options:
  - User restarts secondary (resume from checkpoint)
  - Primary defers feature to later
  - Primary restarts feature with new secondary

### Issue 4: Escalation Not Answered

**Symptoms:**
- Secondary escalated >1 hour ago
- No response from Primary
- Secondary still blocked

**Diagnosis:**
- Primary missed escalation
- Primary busy with own feature
- Primary session crashed

**Fix:**
- Secondary checks if escalation message sent correctly
- Secondary sends follow-up message: "URGENT: Still blocked"
- User alerts Primary in that session
- Primary responds immediately

### Issue 5: Sync Timeout (Not All Features Complete)

**Symptoms:**
- Primary: "2 of 3 features complete, waiting..."
- 2 hours elapsed
- Feature 03 still in progress

**Diagnosis:**
- Secondary-B slower than expected
- Secondary-B blocked but didn't escalate
- Secondary-B crashed

**Fix:**
- Primary checks Secondary-B STATUS and checkpoint
- If working but slow: Extend timeout OR defer to later
- If crashed: Defer feature, proceed with 2 features
- User decides: Wait longer OR continue

### Issue 6: Git Conflicts in EPIC_README.md

**Symptoms:**
- Git shows conflicts in EPIC_README.md
- Multiple agents edited same section
- Merge conflict on commit

**Diagnosis:**
- Agents edited outside their sections
- Lock protocol not followed
- Sectioning not used

**Fix:**
- Verify sectioning exists (BEGIN/END markers)
- Ensure agents only edit their sections
- Use lock protocol for all updates
- Resolve conflict manually (keep all changes)

---

## Performance Metrics

### Time Savings

**Expected:**
- 2-feature epic: ~2 hours (50% S2 reduction)
- 3-feature epic: ~4 hours (67% S2 reduction)
- 4-feature epic: ~6 hours (75% S2 reduction)

**Measured:**
- Total S2 time (start to completion)
- Individual feature times
- Coordination overhead
- Net savings

### Coordination Overhead

**Target:** <10% of parallel time

**Components:**
- Lock operations: ~5 min
- Communication: ~5 min
- Checkpoints: ~2 min
- STATUS updates: ~3 min
- **Total: ~15 min per 2.5-hour epic = 10%**

**Measured:**
- Time spent in coordination heartbeats
- Lock wait times
- Message response times
- Escalation handling time

### Quality Metrics

**Target:** No increase in S3 issues

**Measured:**
- S3 conflicts found
- Spec completeness
- Checklist resolution rate
- Comparison to sequential baseline

---

## Summary

### What We Built

**S2 parallelization enables:**
- ✅ Multiple agents working simultaneously on S2
- ✅ 40-60% reduction in S2 time
- ✅ Low-risk (documentation only)
- ✅ Full coordination infrastructure
- ✅ Crash recovery
- ✅ Simple user experience (automatic agent spawning)

### Key Components

1. **Lock file system** - Prevents conflicts
2. **Communication channels** - Agent messaging
3. **Checkpoint system** - Crash recovery
4. **STATUS files** - Quick status
5. **Sectioned EPIC_README** - Owned sections
6. **Handoff packages** - Auto-configuration
7. **Agent guides** - Primary and Secondary workflows

### Best Practices

1. **Primary owns simplest feature** (minimize workload)
2. **Check coordination every 15 min** (all agents)
3. **Escalate blockers >30 min** (secondaries)
4. **Respond to escalations within 15 min** (Primary)
5. **Use time blocks** (45 min work, 15 min coordination)
6. **Trust the protocols** (locks, messages, checkpoints)

## Structure Validation

### Validation Script

**Location:** `parallel_work/scripts/validate_structure.sh`

**Purpose:** Validates coordination infrastructure for parallel S2 work

**Usage:**
```bash
# From project root
bash .shamt/guides/parallel_work/scripts/validate_structure.sh \
  .shamt/epics/SHAMT-N-epic_name/

# Output:
# ✅ PASSED - structure valid
# ⚠️  PASSED WITH WARNINGS - functional but has style issues
# ❌ FAILED - critical issues found
```text

**When to run:**
1. **After Primary creates infrastructure** (Phase 3, Step 1)
2. **Before generating handoff packages** (Phase 3, Step 3)
3. **After all secondaries start** (Phase 4, start)
4. **If coordination issues occur** (troubleshooting)

**What it checks:**
- ✅ Required directories exist (.epic_locks, agent_comms, agent_checkpoints)
- ❌ Prohibited directories don't exist (parallel_work, nested dirs)
- ✅ Checkpoint files use .json extension
- ✅ Checkpoint files follow naming convention (primary.json, secondary_a.json)
- ❌ No subdirectories under agent_comms/
- ✅ Communication files follow naming convention
- ✅ All features have STATUS files
- ✅ Lock files use .lock extension

**Example output:**
```text
==================================================
Parallel S2 Structure Validation
==================================================
Epic Path: .shamt/epics/SHAMT-8-logging_refactoring

📁 Checking Required Directories...
✅ Required directory exists: .epic_locks
✅ Required directory exists: agent_comms
✅ Required directory exists: agent_checkpoints

🚫 Checking Prohibited Directories...
❌ ERROR: Prohibited directory found: parallel_work

📄 Checking Checkpoint Files...
❌ ERROR: Checkpoint file not .json format: secondary_a.md

💬 Checking Communication Files...
❌ ERROR: Subdirectory in agent_comms/: inboxes

📋 Checking Feature STATUS Files...
❌ ERROR: Missing STATUS file: feature_01/STATUS

==================================================
Validation Summary
==================================================
❌ FAILED
Errors: 10
Warnings: 8
```

---

**See Also:**
- `lock_file_protocol.md` - Lock system details
- `communication_protocol.md` - Messaging details
- `checkpoint_protocol.md` - Recovery details
- `s2_primary_agent_guide.md` - Primary workflow
- `s2_secondary_agent_guide.md` - Secondary workflow
- `stale_agent_protocol.md` - Failure handling
- `sync_timeout_protocol.md` - Sync timeout handling
- `scripts/validate_structure.sh` - Structure validation script
