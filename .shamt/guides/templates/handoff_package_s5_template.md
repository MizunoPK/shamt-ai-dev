# S5 Handoff Package Template

**Purpose:** Template for generating handoff packages for secondary agents in S5 parallel implementation planning

**Usage:** Primary agent fills in placeholders (marked with `{...}`) and provides to user

---

## Handoff Package Format

```markdown
═══════════════════════════════════════════════════════════
I'm joining as a secondary agent for epic {EPIC_NAME} — S5 Implementation Planning.

**Configuration:**
Epic Path: {EPIC_PATH}
My Assignment: {FEATURE_FOLDER}
Primary Agent ID: {PRIMARY_AGENT_ID}
My Agent ID: {SECONDARY_AGENT_ID}
Starting Stage: S5 (Implementation Planning)

**Coordination:**
- Inbox: agent_comms/primary_to_{secondary_id}.md (check before every action)
- Outbox: agent_comms/{secondary_id}_to_primary.md (send updates)
- Checkpoint: agent_checkpoints/{secondary_id}.json (update every 15 min + at milestones)
- STATUS: {FEATURE_FOLDER}/STATUS (update at phase transitions)

**Context provided:**
- My spec: {FEATURE_FOLDER}/spec.md
- My checklist: {FEATURE_FOLDER}/checklist.md
- Epic README: EPIC_README.md
- Smoke test plan: research/epic_smoke_test_plan.md
- Other feature specs: {LIST_OF_OTHER_SPEC_PATHS}
- Pre-verified interfaces: {INTERFACES_OR_NONE}

**Sync Points:**
- After S5 validation loop passes: Signal completion (STAGE: S5, STATUS: WAITING_FOR_SYNC,
  READY_FOR_SYNC: true), WAIT for Primary to run S5-CA (Cross-Plan Alignment)
- After S5-CA completes: You will receive a notification listing which plans were updated.
  Re-read your implementation_plan.md if it was modified. Await combined Gate 5 notification.
- After combined Gate 5 approved: WAIT for Primary to send your S6 activation message.
  Do NOT proceed to S6 on your own.
- After S6 activation message: Read stages/s6/s6_execution.md and begin implementation.

**Milestone checkpoints (write at each):**
- Phase 1 draft complete (before starting validation loop)
- After each clean validation round

Begin S5 now. Read stages/s5/s5_v2_validation_loop.md — follow the Parallel mode notes
in Prerequisites and Gate 5 sections.
═══════════════════════════════════════════════════════════
```

---

## Example (Filled In)

```markdown
═══════════════════════════════════════════════════════════
I'm joining as a secondary agent for epic SHAMT-6-nfl_team_penalty — S5 Implementation Planning.

**Configuration:**
Epic Path: C:/Users/kmgam/code/[project name]/.shamt/epics/SHAMT-6-nfl_team_penalty
My Assignment: feature_02_team_penalty
Primary Agent ID: Agent-abc123
My Agent ID: Secondary-A
Starting Stage: S5 (Implementation Planning)

**Coordination:**
- Inbox: agent_comms/primary_to_secondary_a.md (check before every action)
- Outbox: agent_comms/secondary_a_to_primary.md (send updates)
- Checkpoint: agent_checkpoints/secondary_a.json (update every 15 min + at milestones)
- STATUS: feature_02_team_penalty/STATUS (update at phase transitions)

**Context provided:**
- My spec: feature_02_team_penalty/spec.md
- My checklist: feature_02_team_penalty/checklist.md
- Epic README: EPIC_README.md
- Smoke test plan: research/epic_smoke_test_plan.md
- Other feature specs:
    feature_01_player_json/spec.md
    feature_03_scoring_engine/spec.md
- Pre-verified interfaces: None (no shared interfaces pre-verified for this epic)

**Sync Points:**
- After S5 validation loop passes: Signal completion (STAGE: S5, STATUS: WAITING_FOR_SYNC,
  READY_FOR_SYNC: true), WAIT for Primary to run S5-CA (Cross-Plan Alignment)
- After S5-CA completes: You will receive a notification listing which plans were updated.
  Re-read your implementation_plan.md if it was modified. Await combined Gate 5 notification.
- After combined Gate 5 approved: WAIT for Primary to send your S6 activation message.
  Do NOT proceed to S6 on your own.
- After S6 activation message: Read stages/s6/s6_execution.md and begin implementation.

**Milestone checkpoints (write at each):**
- Phase 1 draft complete (before starting validation loop)
- After each clean validation round

Begin S5 now. Read stages/s5/s5_v2_validation_loop.md — follow the Parallel mode notes
in Prerequisites and Gate 5 sections.
═══════════════════════════════════════════════════════════
```

---

## Placeholder Mapping

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{EPIC_NAME}` | Epic folder name (SHAMT-N-name format) | SHAMT-6-nfl_team_penalty |
| `{EPIC_PATH}` | Full absolute path to epic folder | C:/Users/.../SHAMT-6-nfl_team_penalty |
| `{FEATURE_FOLDER}` | Feature folder name assigned to this secondary | feature_02_team_penalty |
| `{PRIMARY_AGENT_ID}` | Primary agent's unique ID | Agent-abc123 |
| `{SECONDARY_AGENT_ID}` | This secondary agent's ID | Secondary-A, Secondary-B, etc. |
| `{secondary_id}` | Lowercase agent ID for file names | secondary_a, secondary_b, etc. |
| `{LIST_OF_OTHER_SPEC_PATHS}` | Newline-separated paths to all other features' spec.md files | feature_01_.../spec.md |
| `{INTERFACES_OR_NONE}` | Pre-verified interface data (if Primary pre-verified shared interfaces) or "None" | See D4 note below |

**D4 — Pre-verified shared interfaces (optional):**
Before generating handoff packages, Primary may pre-verify external methods referenced by 2+
features and include the results directly in this field. This avoids redundant source-code reads
by multiple agents. If used, replace `{INTERFACES_OR_NONE}` with the verification data inline.
Do this during handoff generation, not during Primary's active S5 Phase 1 work.

---

## Generation Steps (Primary Agent)

1. For each secondary agent (Feature 02, 03, ...):
   a. Fill in all placeholders
   b. Set `{LIST_OF_OTHER_SPEC_PATHS}` to all features' spec.md paths except this agent's own
   c. If pre-verified interfaces apply, replace `{INTERFACES_OR_NONE}` with the data
   d. Save package to `{FEATURE_FOLDER}/HANDOFF_PACKAGE_S5.md` (NOT in agent_comms/)
   e. Present package to user for copy-paste into secondary's session

2. Verify all agent_comms/ channels exist (create if missing — see communication_protocol.md)

3. Send Sync Point 2 activation message to each secondary (or notify user to spawn fresh session)

---

## Secondary Agent Self-Configuration

**When secondary agent receives handoff package:**

1. **Parse configuration:** Extract epic path, feature assignment, agent ID, coordination paths

2. **Verify paths exist:**
   - Epic folder exists
   - Feature folder exists
   - spec.md exists and is complete (Gate 3 passed during S2)

3. **Update or create checkpoint file** (`agent_checkpoints/{secondary_id}.json`):
   - `stage`: "S5"
   - `phase`: "Implementation Planning - Starting"
   - `status`: "IN_PROGRESS"
   - `recovery_instructions`: "Resume S5 Phase 1 draft. Check implementation_plan.md for current state."

4. **Update STATUS file** (`{FEATURE_FOLDER}/STATUS`):
   ```
   STAGE: S5
   PHASE: Implementation Planning
   STATUS: IN_PROGRESS
   READY_FOR_SYNC: false
   ```

5. **Send initial message to Primary:**
   ```markdown
   ## Message 1 (TIMESTAMP) ⏳ UNREAD
   **Subject:** S5 Secondary Agent Started
   **Action:** I've started S5 implementation planning for {FEATURE_FOLDER}
   **Details:** Handoff package received and configuration complete
   **Next:** Beginning S5 Phase 1 (Draft Creation) now
   **Acknowledge:** No action needed
   ```

6. **Begin S5:**
   - Read guide: `stages/s5/s5_v2_validation_loop.md`
   - Follow the **Parallel mode** notes in the Prerequisites and Gate 5 sections
   - Update checkpoint every 15 min
   - Write milestone checkpoints at Phase 1 exit and after each clean validation round
   - Check inbox every 15 min

---

## Notes

- Handoff package is **copy-paste ready** (no manual editing by user)
- All configuration is **auto-populated by Primary**
- Secondary agent **self-configures from package**
- Package can be **reused if agent crashes** (same configuration)
- This template is for **S5 parallel mode only** — in sequential mode, no handoff package is needed

**See also:**
- `parallel_work/s5_parallel_protocol.md` — full S5 parallel workflow
- `parallel_work/s5_primary_agent_guide.md` — Primary's handoff generation steps
- `parallel_work/s5_secondary_agent_guide.md` — Secondary's full startup and execution guide
- `templates/handoff_package_s2_template.md` — S2 equivalent template
