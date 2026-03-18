# Parallel Work System - S2 and S5 Parallel Modes

**Purpose:** Coordinate multiple agents working on S2 (feature planning) and S5 (implementation planning) in parallel

**When to use:**
- S2 parallel: Epics with 3+ features (40-60% time reduction for S2 phase)
- S5 parallel: Epics with 2+ features where S2 parallel was used (~4.5-7 hours gross savings per parallel feature)

---

## Quick Navigation

### S2 Parallel (Feature Planning)
- **[s2_parallel_protocol.md](s2_parallel_protocol.md)** - Complete S2 parallel overview with 9-phase workflow
- **[s2_primary_agent_guide.md](s2_primary_agent_guide.md)** - Primary agent workflow for S2 (coordinator + Feature 01)
- **[s2_secondary_agent_guide.md](s2_secondary_agent_guide.md)** - Secondary agent workflow for S2 (feature owner)

### S5 Parallel (Implementation Planning)
- **[s5_parallel_protocol.md](s5_parallel_protocol.md)** - Complete S5 parallel overview
- **[s5_primary_agent_guide.md](s5_primary_agent_guide.md)** - Primary agent workflow for S5 (coordinator + Feature 01)
- **[s5_secondary_agent_guide.md](s5_secondary_agent_guide.md)** - Secondary agent workflow for S5 (feature owner)
- **[stages/s5/s5_ca_cross_plan_alignment.md](../stages/s5/s5_ca_cross_plan_alignment.md)** - S5-CA Cross-Plan Alignment (Primary only, runs after all S5 complete)

### Infrastructure Protocols
- **[lock_file_protocol.md](lock_file_protocol.md)** - File locking for shared resources
- **[communication_protocol.md](communication_protocol.md)** - Agent-to-agent messaging
- **[checkpoint_protocol.md](checkpoint_protocol.md)** - Crash recovery and staleness detection

### Recovery Protocols
- **[stale_agent_protocol.md](stale_agent_protocol.md)** - Handling crashed/hung agents
- **[sync_timeout_protocol.md](sync_timeout_protocol.md)** - Sync point timeout handling

### Templates
- **[templates/handoff_package_s2_template.md](../templates/handoff_package_s2_template.md)** - S2 secondary agent handoff
- **[templates/handoff_package_s5_template.md](../templates/handoff_package_s5_template.md)** - S5 secondary agent handoff
- **[templates/feature_status_template.txt](../templates/feature_status_template.txt)** - STATUS file format
- **[templates/epic_readme_template.md](../templates/epic_readme_template.md)** - EPIC_README with parallel sections

---

## System Overview

**Agent Roles:**
- **Primary Agent:** Coordinator + Feature 01 owner (85% feature work, 15% coordination)
- **Secondary Agent:** Feature owner only (90% feature work, 10% coordination)

**Coordination Mechanisms:**
- Checkpoints (every 15 minutes) - Crash recovery + staleness detection
- Communication (file-based messaging) - Async agent-to-agent messaging
- STATUS Files (per feature) - Quick status check
- Locks (shared files) - Prevent race conditions

**Sync Points:**

| SP | Transition | Trigger | Actor | Action |
|----|-----------|---------|-------|--------|
| SP1 | S1 → S2 | S1 complete, user accepts parallel offer | Primary | Generate S2 handoffs, start secondary sessions |
| SP2 (extended) | S2 → S3; S3 → S5 | All S2 complete; then Gate 4.5 approval | Primary | Verify S2 complete, run S3 solo; then generate S5 handoffs and activate secondaries |
| SP3 (new) | S5 → S5-CA → Gate 5 | All S5 complete (all STATUS: WAITING_FOR_SYNC) | Primary | Run S5-CA (cross-plan alignment) + present combined Gate 5 |
| SP4 (new) | Gate 5 → S6 chain | Combined Gate 5 approved | Primary | Activate Feature 01 for S6; after each S8, activate next feature |

**Note:** SP2 is extended in S5 parallel mode. The original SP2 action (S2→S3) is unchanged. The new SP2 action (S3→S5) runs after Gate 4.5 approval: Primary generates S5 handoff packages and activates secondary agents.

---

## Quick Start

**For Primary Agent:**
1. Read [s2_primary_agent_guide.md](s2_primary_agent_guide.md)
2. Generate handoff packages for secondaries
3. Execute S2 for Feature 01 while coordinating

**For Secondary Agent:**
1. Read [s2_secondary_agent_guide.md](s2_secondary_agent_guide.md)
2. Receive handoff package from Primary
3. Execute S2 for assigned feature

---

## Integration with Workflow

| Stage | Event | Notes |
|-------|-------|-------|
| S1 Steps 5.8-5.9 | Offer S2 parallel work | If 3+ features |
| S1 Final Step | Generate S2 handoffs | If parallel enabled |
| S2 | Detect Primary vs Secondary role | S2 Router |
| S3 Start | Sync verification (S2 complete) | See `s3_parallel_work_sync.md` |
| S3 Gate 4.5 (SP2) | Generate S5 handoffs, activate secondaries | If S2 parallel was used and S5 parallel enabled |
| S5 | All features implement planning in parallel | Requires S2 parallel as prerequisite; see `s5_parallel_protocol.md` |
| After all S5 (SP3) | S5-CA + combined Gate 5 | Primary runs `s5_ca_cross_plan_alignment.md` |
| After Gate 5 (SP4) | Sequential S6 chain | Primary activates features one at a time |

**Note:** Parallel work is OPTIONAL — workflow works identically in sequential mode.

**S5 parallel requires S2 parallel.** If S2 was sequential, S5 must also be sequential.

---

**See:** Master protocol for complete details and decision guides.
