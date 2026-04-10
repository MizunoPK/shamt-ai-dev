# S4: Interface Contract Definition — Quick Reference Card

**Purpose:** One-page summary for defining cross-feature interface contracts before S5 planning begins
**Use Case:** Quick lookup when starting S4 after Gate 4 approval
**Total Time:** Full path ~30-45 min / Fast-skip ~5-10 min

> **SCOPE:** Runs **once per epic**, after S3 complete and Gate 4 passed.

---

## Path Decision

```text
Did S2.P2 identify any integration points?
  ├─ YES → Full Path (~30-45 min + validation loop)
  └─ NO  → Fast-Skip (~5-10 min, no validation loop)
```

---

## Workflow Overview

```text
FULL PATH
─────────────────────────────────────────────────────────
STEP 1: Review S2.P2 output (5-10 min)
    └─ Read cross-feature alignment notes; list every integration point
    ↓
STEP 2: Classify contracts by type (5 min)
    └─ function sig / data schema / file format / constant / config key / API
    ↓
STEP 3: Define each contract (15-20 min)
    ├─ Existing code: verify from source (file:line), status = confirmed
    └─ New code: derive from all consuming features' specs, status = proposed
    ↓
STEP 4: Map producer/consumer relationships (5 min)
    └─ Escalate to user if multiple producers for same contract
    ↓
STEP 5: Create interface_contracts.md in epic folder root (5-10 min)
    ↓
STEP 6: Validation loop → primary clean round + sub-agent confirmation
    └─ 5 dimensions (see below)
    ↓
DONE → proceed to S5 (or SP2 in parallel mode)

FAST-SKIP PATH
─────────────────────────────────────────────────────────
Create minimal interface_contracts.md stating "no contracts"
No validation loop needed → proceed to S5
```

---

## S4 Validation Dimensions (Full Path Only)

| # | Dimension | What to Check |
|---|-----------|---------------|
| 1 | Contract Completeness | Every S2.P2 integration point has a contract entry |
| 2 | Contract Specificity | All definitions fully specified — zero TBD fields |
| 3 | Contract Correctness | confirmed = source verified; proposed = consistent with all specs |
| 4 | Producer/Consumer Accuracy | All producers and consumers correctly identified |
| 5 | No Conflicting Definitions | No two entries define the same interface differently |

---

## interface_contracts.md Required Fields (per contract)

| Field | Notes |
|-------|-------|
| `name` | Short identifier |
| `type` | function sig / data schema / file format / constant / config key / API endpoint |
| `definition` | Full signature or schema — NO TBD |
| `producing feature(s)` | Feature that creates/modifies this interface |
| `consuming feature(s)` | Features that call/read this interface |
| `source` | `existing: path/file.py:line_N` or `new` |
| `status` | `confirmed` (verified) or `proposed` (new) |

---

## Phase Summary Table

| Step | Duration | Key Output | Gate? |
|------|----------|------------|-------|
| 1-5 (full) | 30-45 min | interface_contracts.md | No |
| Validation loop | 15-20 min | All 5 dimensions clean | No (agent-validated only) |
| Fast-skip | 5-10 min | interface_contracts.md (stub) | No |

**S4 has ZERO formal user gates.** Contracts are technical derivations of user-approved specs; they surface at Gate 5 when implementation plans are reviewed.

---

## Key Rules

- ✅ `interface_contracts.md` must exist before ANY feature begins S5
- ✅ Full path validation loop: primary clean round + sub-agent confirmation required
- ✅ Fast-skip: no validation loop needed
- ✅ No TBD fields in any contract definition
- ✅ Multiple producers for same contract → escalate to user before S5
- ✅ Parallel mode: SP2 fires AFTER S4 exits (not at Gate 4 approval)
- ✅ `interface_contracts.md` is a living document through S5-CA; frozen after S5-CA exits

---

## Common Pitfalls

### ❌ Pitfall 1: Skipping S4 for "simple" multi-feature epics
**Problem:** "The features seem independent so I'll just go to S5"
**Solution:** Check S2.P2 output. If zero integration points confirmed → fast-skip. If any integration points exist → full path. Never skip S4 entirely.

### ❌ Pitfall 2: TBD fields in contract definitions
**Problem:** "I'll figure out the signature in S5"
**Solution:** Define the contract now. If you can't, the spec has a gap — escalate to user.

### ❌ Pitfall 3: Defining contracts from memory
**Problem:** "I know what this function looks like"
**Solution:** Use Read tool to verify existing signatures from source. Mark confirmed only after reading the actual file.

### ❌ Pitfall 4: Activating secondary agents before S4 is done (parallel mode)
**Problem:** "I'll start S4 while secondaries begin S5"
**Solution:** Secondaries haven't been activated yet at this point. SP2 fires after S4 exits.

---

## Prerequisites Checklist

**Before starting S4:**
- [ ] S3 complete (P1, P2, P3 all done)
- [ ] Gate 4 passed (user explicitly approved epic plan)
- [ ] S2.P2 Cross-Feature Alignment completed
- [ ] Working directory: Epic folder root

---

## Exit Conditions

**S4 is complete when:**
- [ ] `interface_contracts.md` exists in epic folder root
- [ ] Full path: validation loop passed (primary clean round + sub-agent confirmation)
- [ ] Fast-skip: minimal stub created with reason documented
- [ ] No TBD fields anywhere
- [ ] EPIC_README.md Agent Status: S4_COMPLETE

**Next Stage:** S5 (sequential) or SP2 handoff (parallel)

---

## When to Use Which Guide

| Current Activity | Guide to Read |
|------------------|---------------|
| Starting S4 | `stages/s4/s4_interface_contracts.md` |
| Validation loop (full path) | `reference/validation_loop_master_protocol.md` |
| Parallel mode handoff | `parallel_work/s5_primary_agent_guide.md` → Phase 2 |

---

**Last Updated:** 2026-04-09
