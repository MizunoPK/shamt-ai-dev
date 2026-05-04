---
name: shamt-lite-validate
description: >
  Run a Shamt Lite validation loop on any artifact (spec, implementation plan,
  code review, or general document). Iterative re-read with severity classification,
  exit on primary clean round + 1 Haiku sub-agent confirmation. The Lite variant of
  the master Shamt validation loop — single sub-agent (not two).
triggers:
  - "validate this"
  - "run a validation loop"
  - "shamt lite validate"
  - "validate spec"
  - "validate plan"
  - "validate review"
source_guides:
  - scripts/initialization/SHAMT_LITE.template.md
master-only: false
---

## Overview

Encodes Pattern 1 (Validation Loops) and Pattern 2 (Severity Classification) from `SHAMT_LITE.md`. Use after creating any significant artifact — spec, plan, code review, or general document — to iteratively self-review until quality threshold is met.

**Lite exit criterion:** primary clean round + **1 independent Haiku sub-agent confirmation**. (Full Shamt uses 2; Lite uses 1.)

---

## When This Skill Triggers

- After creating a spec, plan, or code review
- User says "validate this", "run a validation loop", or names an artifact to validate
- After writing any work artifact that benefits from iterative self-review

---

## Inputs Required

- **Artifact path** — relative or absolute path to the file to validate
- **Artifact type** — spec / plan / code review / general (determines which dimensions apply)

If artifact type is ambiguous, infer from filename or content; otherwise ask the user.

---

## Protocol — The 8-Step Validation Process

Track `consecutive_clean` (start at 0). Repeat steps 1–6 each round.

### Step 1 — Read the artifact completely with fresh perspective

Re-read the entire artifact top-to-bottom every round. Do not rely on memory of prior rounds.

### Step 2 — Identify issues across relevant dimensions

Pick the dimension set that matches the artifact:

**Specs (7 dimensions)**
1. Completeness — All sections filled? Requirements gap-free?
2. Correctness — Research accurate? File paths correct?
3. Consistency — Design internally consistent? Aligned with `ARCHITECTURE.md`?
4. Helpfulness — Does it solve the ticket?
5. Improvements — Simpler approach available?
6. Missing proposals — Any design element left unaddressed?
7. Open questions — Blocking decisions unresolved?

**Implementation Plans (7 dimensions)**
1. Step Clarity — Every step has a clear action description?
2. Mechanical Executability — All design decisions made, none left to executor?
3. File Coverage — All affected files listed?
4. Operation Specificity — EDIT steps have exact locate/replace strings?
5. Verification Completeness — Steps that need it have verification methods?
6. Dependency Ordering — Steps in correct sequence?
7. Requirements Alignment — Plan covers all spec requirements?

**Code Reviews (5 dimensions)**
1. Correctness — Issues accurately described?
2. Completeness — All changed files reviewed?
3. Helpfulness — Suggested fixes actionable?
4. Severity Accuracy — Classifications correct?
5. Evidence — File paths and line numbers match the diff?

**General Artifacts (4 dimensions)**
1. Completeness — All sections filled?
2. Clarity — Easy to understand?
3. Accuracy — Facts and references correct?
4. Actionability — Can someone act on this?

### Step 3 — Classify each issue by severity

Use Pattern 2 quick-classification:

1. "If not fixed, can workflow complete?" → NO = **CRITICAL**
2. "Will this cause confusion?" → YES = **HIGH**
3. "Does this reduce quality noticeably?" → YES = **MEDIUM**
4. Otherwise = **LOW**

Borderline → classify HIGHER. Better to fix a MEDIUM that might be LOW than to miss a HIGH classified as MEDIUM.

### Step 4 — Fix ALL issues immediately

Fix each issue in the artifact now. Do not defer or batch.

### Step 5 — Update consecutive_clean counter

- **Clean round** = ZERO issues OR exactly ONE LOW issue (which you fixed)
- **Not clean** = 2+ LOW issues OR any MEDIUM/HIGH/CRITICAL issue
- If clean: `consecutive_clean = consecutive_clean + 1`
- If not clean: `consecutive_clean = 0`

State `consecutive_clean` explicitly at the end of each round.

### Step 6 — Check exit condition

- `consecutive_clean = 0` → return to Step 1
- `consecutive_clean = 1` → spawn 1 Haiku sub-agent (Step 7)

### Step 7 — Spawn sub-agent for independent confirmation

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">{cheap-tier}</parameter>
  <parameter name="description">Sub-agent confirmation</parameter>
  <parameter name="prompt">You are confirming zero issues after primary validation.

**Artifact:** {artifact_path_or_description}
**Dimensions:** {list the dimensions from Step 2 for this artifact type}
**Task:** Re-read the entire artifact. Report ANY issue found (even LOW severity).
If zero issues found, state "CONFIRMED: Zero issues found."

{Relevant context about the artifact}
  </parameter>
</invoke>
```

`{cheap-tier}` resolves to: `haiku-4-5` on Claude Code; `${DEFAULT_MODEL}` on Codex; `inherit` on Cursor.

**Sub-agent exception:** sub-agents do NOT get the 1-LOW allowance. ANY issue found by the sub-agent (even LOW) resets `consecutive_clean = 0` and returns to Step 1.

### Step 8 — Add validation footer

When the sub-agent confirms zero issues, append a single-line footer to the artifact:

```
---
✅ Validated {date} — N rounds, 1 sub-agent confirmed
```

Validation is complete.

---

## Exit Criteria

- Primary clean round achieved (`consecutive_clean = 1`)
- 1 Haiku sub-agent re-read the artifact and confirmed zero issues
- Validation footer appended

---

## Quick Reference

```
1. Re-read artifact completely (fresh every round)
2. Find issues across dimensions
3. Classify CRITICAL / HIGH / MEDIUM / LOW
4. Fix ALL immediately
5. Update counter:
   0 issues OR 1 LOW fixed → consecutive_clean + 1
   Otherwise               → consecutive_clean = 0
6. consecutive_clean = 1 → spawn 1 Haiku sub-agent
7. Sub-agent finds 0 issues → DONE ✅
8. Append: ✅ Validated {date} — N rounds, 1 sub-agent confirmed
```

```
CRITICAL → blocks workflow / causes failure
HIGH     → causes confusion or wrong decisions
MEDIUM   → reduces quality noticeably
LOW      → cosmetic only

When uncertain → classify HIGHER
One LOW per round is OK; two LOW = not clean
Sub-agents get NO LOW allowance
```
