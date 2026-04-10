# S4: Interface Contract Definition

> **SCOPE:** This stage runs **once per epic**, after S3 is complete and Gate 4 is passed. It is not
> repeated per feature. Working directory is the **epic folder root**.

🚨 **MANDATORY READING PROTOCOL**

**Before starting this stage — including when resuming a prior session:**
1. Read this guide entirely before beginning work
2. Verify prerequisites (Gate 4 passed, S2.P2 integration points available)
3. Determine your path: **Full path** (≥1 integration point) or **Fast-skip** (zero integration points)
4. Update epic EPIC_README.md Agent Status with guide name + timestamp

---

## 🚫 FORBIDDEN SHORTCUTS

You CANNOT:
- Skip S4 and proceed directly to S5 — `interface_contracts.md` must exist before any feature begins S5
- Define contracts from general knowledge or spec summaries alone — for **existing** code, verify from source; for **new** code, derive from what all consuming features require
- Run only the fast-skip path when S2.P2 actually identified integration points — the fast-skip is only for genuine zero-integration cases
- Skip the validation loop (full-path only) — contracts are planning inputs; errors here propagate to every feature's S5

If you are about to do any of the above: STOP and re-read the relevant section.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Overview](#overview)
- [Choosing Your Path](#choosing-your-path)
- [Full Path (≥1 Integration Point)](#full-path-1-integration-point)
- [Fast-Skip Path (Zero Integration Points)](#fast-skip-path-zero-integration-points)
- [interface_contracts.md Format](#interface_contractsmd-format)
- [S4 Validation Loop (Full Path Only)](#s4-validation-loop-full-path-only)
- [Parallel Mode](#parallel-mode)
- [Exit Criteria](#exit-criteria)
- [Next Stage](#next-stage)

---

## Prerequisites

**Before starting S4:**

- [ ] S3 complete (all three phases: P1, P2, P3)
- [ ] Gate 4 passed — user explicitly approved epic plan in S3.P3
- [ ] S2.P2 (Cross-Feature Alignment) completed — integration points documented
- [ ] EPIC_README.md shows S3 complete
- [ ] Working directory: Epic folder root

**If any prerequisite fails:**
- Complete missing S3 work before proceeding
- Do NOT create `interface_contracts.md` before Gate 4 passes

---

## Overview

**Purpose:** Define all cross-feature interface contracts before per-feature implementation planning begins. Features then plan against agreed contracts rather than assumptions, reducing conflict discovery rate in S5-CA.

**What is a contract?** Any shared technical boundary between two or more features: a function signature, a data schema, a file format, a shared configuration key, an API endpoint shape.

**Time estimates:**
- **Full path** (≥1 integration point): ~30-45 minutes
- **Fast-skip** (zero integration points): ~5-10 minutes

**Output:** `interface_contracts.md` in the epic folder root — created by both paths (fast-skip creates a minimal "no contracts" stub).

---

## Choosing Your Path

**Read your S2.P2 Cross-Feature Alignment output:**

```text
Did S2.P2 identify any integration points between features?
  └─ YES (≥1 integration point): → Full Path
  └─ NO (zero integration points identified)
       AND this is a single-feature epic, OR all features are fully independent: → Fast-Skip Path
```

**When in doubt, use the Full Path.** The fast-skip is only appropriate when you are confident no shared interfaces exist.

---

## Full Path (≥1 Integration Point)

**~30-45 minutes total**

### Step 1: Review S2.P2 Output (5-10 min)

Read all Cross-Feature Alignment notes produced in S2.P2:
- `epic/research/S2_P2_COMPARISON_MATRIX_GROUP_{N}.md` (or equivalent)
- EPIC_README.md integration dependencies section

For each integration point flagged, note:
- Which features are involved
- What type of dependency it is (data flow, function call, file, config, API)
- Which feature produces the shared artifact and which features consume it

### Step 2: Classify Contracts by Type (5 min)

Group the integration points by contract type:

| Type | Example |
|------|---------|
| Function/method signature | `calculate_score(items: list[Item]) -> float` |
| Data schema | Fields in a shared dataclass or dict |
| File format | Column names in a shared CSV, fields in a shared JSON |
| Shared constant | `MAX_BATCH_SIZE = 500` |
| Configuration key | `config["output_dir"]` |
| API endpoint | `POST /api/results` with request/response shape |

### Step 3: Define Each Contract (15-20 min)

For each contract:

**If the interface already exists in the codebase:**
- Read the actual source file (use Read tool)
- Record the exact current signature/schema (file path + line number)
- Mark status as `confirmed`

**If the interface is new (created by this epic):**
- Derive the interface from what ALL consuming features require (read their spec.md files)
- Choose the simplest form that satisfies all consumers
- Mark status as `proposed`

Do NOT leave any field as TBD. If you cannot define a contract completely, the consuming feature's spec likely has a gap — escalate to user before proceeding.

### Step 4: Map Producer/Consumer Relationships (5 min)

For each contract, identify:
- **Producer:** Which feature creates or modifies this interface
- **Consumer(s):** Which features call or read this interface

If a contract has multiple producers (two features both modify the same function), that is itself a conflict — document it and escalate to user before S5 begins. Do not proceed to S5 with a contested producer.

### Step 5: Create interface_contracts.md (5-10 min)

Create `interface_contracts.md` in the epic folder root using the format specified in [interface_contracts.md Format](#interface_contractsmd-format) below.

### Step 6: Validation Loop

See [S4 Validation Loop](#s4-validation-loop-full-path-only) below.

---

## Fast-Skip Path (Zero Integration Points)

**~5-10 minutes — no validation loop required**

1. Confirm that S2.P2 found zero integration points and that all features are independent (or this is a single-feature epic)
2. Create `interface_contracts.md` with the following content:

```markdown
# Interface Contracts

**Epic:** {epic_name}
**Created:** {date}
**S4 Path:** Fast-skip

## Result

No cross-feature contracts identified.

**Reason:** {one of: "Single-feature epic" / "S2.P2 found zero integration points between features — all features are independent"}

## Proceed To

S5 — all features may begin implementation planning independently.
```

3. Proceed directly to S5 (or SP2 handoff in parallel mode).

---

## interface_contracts.md Format

**Full-path contracts document structure:**

```markdown
# Interface Contracts

**Epic:** {epic_name}
**Created:** {date}
**S4 Path:** Full

## Contract Registry

| Name | Type | Producer | Consumer(s) | Status |
|------|------|----------|-------------|--------|
| {name} | {type} | {feature_N} | {feature_M, feature_P} | confirmed / proposed |

---

## Contract Details

### {Contract Name}

**Type:** {function signature / data schema / file format / shared constant / config key / API endpoint}

**Definition:**
{Full signature, schema, format spec, or value — no TBD}

**Producer:** `{feature_N}_{name}/` — {brief description of what it does}

**Consumer(s):**
- `{feature_M}_{name}/` — {how it uses this contract}
- `{feature_P}_{name}/` — {how it uses this contract}

**Source:** `{path/to/file.py:line_N}` (existing) / `new` (to be created in S6)

**Status:** `confirmed` (verified from source) / `proposed` (new interface)

**Notes:** {any caveats, e.g., "signature may expand in Feature M's S5 if additional params needed — update here if so"}

---
{repeat for each contract}
```

**Required fields per contract:** name, type, definition (no TBD), producing feature, consuming feature(s), source, status.

**Living document rule:** `interface_contracts.md` may be updated during S5 if a spec change affects a contract (the agent discovering the change updates the file directly). It is frozen (no further edits) after S5-CA exits.

---

## S4 Validation Loop (Full Path Only)

**Reference:** `reference/validation_loop_master_protocol.md`

Run a validation loop on `interface_contracts.md` with the following 5 dimensions:

### Dimension 1: Contract Completeness
- Does every integration point from S2.P2 have a corresponding contract entry in the registry?
- Is any integration point from S2.P2 unaccounted for?

### Dimension 2: Contract Specificity
- Are all definition fields fully specified? (No TBD, no "see spec", no vague descriptions)
- Are all signatures complete (all parameters, return types)?
- Are all schema fields named with types?

### Dimension 3: Contract Correctness
- For `confirmed` contracts: is the file:line reference accurate? Does the recorded definition match the actual source?
- For `proposed` contracts: is the definition consistent with what each consuming feature's spec.md requires?
- Are there any type mismatches or incompatible assumptions between the definition and the specs?

### Dimension 4: Producer/Consumer Accuracy
- Does each contract correctly identify which feature(s) produce vs. consume it?
- Are any producers or consumers missing from the registry table?
- If multiple features produce the same contract: has this been escalated to the user?

### Dimension 5: No Conflicting Definitions
- Are there two contract entries that define the same interface differently?
- Does any contract definition contradict another contract's definition?

**Exit criterion:** Primary clean round + sub-agent confirmation.

**Zero tolerance:** Any finding in any dimension resets the clean counter to 0. Fix immediately.

**Track:**
```text
Round 1: [N findings] — consecutive_clean = 0
Round 2: 0 findings  — consecutive_clean = 1  → spawn 2 sub-agents in parallel
  Sub-agent A: 0 issues ✅
  Sub-agent B: 0 issues ✅
✅ EXIT
```

---

## Parallel Mode

**In parallel S5 mode:**

- Primary agent runs S4 **alone** — secondary agents have NOT been activated yet during S4
- Secondaries are not waiting at a sync point; they simply have not been started
- **SP2 (secondary agent activation) fires after S4 exits**, not at Gate 4 approval
- After S4 validation loop passes (full path) or fast-skip document is created: proceed to SP2 handoff

**What to include in S5 handoff packages (parallel mode):**
- Add `interface_contracts.md` path to the handoff package
- Instruct secondary agents to read it before starting S5 Phase 1

---

## Exit Criteria

**S4 complete when ALL true:**

- [ ] `interface_contracts.md` created in epic folder root
- [ ] **Full path:** Validation loop passed (primary clean round + sub-agent confirmation); all 5 dimensions clean
- [ ] **Fast-skip:** Minimal document created with reason stated; no validation loop required
- [ ] No "TBD" fields in any contract definition
- [ ] No contested producers (or escalated to user and resolved)
- [ ] EPIC_README.md Agent Status updated: Phase = S4_COMPLETE

---

## Next Stage

**After S4 complete:**

**Sequential mode:**
📖 **READ:** `stages/s5/s5_v2_validation_loop.md` (first feature)
🎯 **GOAL:** Implementation planning — begin with reading `interface_contracts.md` at Step 0

**Parallel mode:**
📖 **READ:** `parallel_work/s5_primary_agent_guide.md` → Phase 2 (SP2 Action)
🎯 **GOAL:** Generate S5 handoff packages (include `interface_contracts.md` path) and activate secondaries

---

*End of s4_interface_contracts.md*
