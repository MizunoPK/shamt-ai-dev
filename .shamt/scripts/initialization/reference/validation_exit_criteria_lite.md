# Validation Loop Exit Criteria

**Extends Pattern 1 (Validation Loops) in SHAMT_LITE.md — read that first.**

**Purpose:** Extended mechanics, counter logic examples, and common mistakes for Lite validation loops

---

## Lite Exit Criterion

**Primary clean round + 1 independent Haiku sub-agent confirmation.**

This applies to all Lite validation loops: specs, plans, code reviews, and ad-hoc artifacts. It does not apply to master Shamt design docs or full Shamt validation loops (those use 2 sub-agents per master repo policy).

---

## Counter Logic

```text
Initial state: consecutive_clean = 0

Round finds 0 issues:
  → consecutive_clean = 1 → trigger sub-agent

Round finds exactly 1 LOW issue (and fixes it):
  → consecutive_clean = 1 → trigger sub-agent

Round finds 2+ LOW issues:
  → consecutive_clean = 0 → fix all, continue

Round finds any MEDIUM/HIGH/CRITICAL issue:
  → consecutive_clean = 0 → fix all, continue

Sub-agent finds ANY issue (even LOW):
  → consecutive_clean = 0 → fix, continue to next round
```

### Example Sequences

**Scenario 1: Quick exit (2 rounds)**
```
Round 1: 3 MEDIUM issues → consecutive_clean = 0 → Fix → Continue
Round 2: 0 issues → consecutive_clean = 1 → Spawn Haiku sub-agent
Sub-agent: 0 issues ✅ → COMPLETE
```

**Scenario 2: Sub-agent finds issue (3 rounds)**
```
Round 1: 2 HIGH, 1 MEDIUM → consecutive_clean = 0 → Fix → Continue
Round 2: 1 LOW → consecutive_clean = 1 → Spawn Haiku sub-agent
Sub-agent: 1 LOW issue ❌ → consecutive_clean = 0 → Fix → Continue
Round 3: 0 issues → consecutive_clean = 1 → Spawn Haiku sub-agent
Sub-agent: 0 issues ✅ → COMPLETE
```

**Scenario 3: Multiple LOW issues slow exit (3 rounds)**
```
Round 1: 1 HIGH, 2 LOW → consecutive_clean = 0 → Fix → Continue
Round 2: 2 LOW → consecutive_clean = 0 → Fix → Continue
Round 3: 1 LOW → consecutive_clean = 1 → Spawn Haiku sub-agent
Sub-agent: 0 issues ✅ → COMPLETE
```

---

## Sub-Agent Exception Rule

Sub-agents do NOT get the 1 LOW allowance. ANY issue found by a sub-agent (including LOW) resets `consecutive_clean = 0`.

**Rationale:** The sub-agent is the final verification step with fresh eyes. If it finds anything — even cosmetic — the primary validation missed something. Fix and re-run.

---

## Fresh Eyes Principle

Re-read the ENTIRE artifact every single round. Do not rely on memory of prior rounds.

**Why:** First-pass reading misses issues that jump out on re-read. Memory-based validation is unreliable — you remember what you wrote, not what's actually there.

**How:** Vary reading patterns across rounds (top-to-bottom, section-by-section, reverse order) to catch different classes of issues.

---

## Common Mistakes

**Exiting after primary clean round:** `consecutive_clean = 1` means trigger the sub-agent — it does NOT mean validation is complete. Wait for sub-agent confirmation.

**Deferring issues:** All issues must be fixed immediately before moving to the next round. Never defer or batch fixes.

**Applying the 1 LOW allowance to sub-agents:** Sub-agents report any issue found, no exceptions. No 1 LOW grace period.

**Reading from memory:** Must physically re-read the artifact. Memory validation is unreliable and defeats the purpose of fresh eyes.

**Continuing with unresolved ambiguity:** If an issue is ambiguous (is this HIGH or MEDIUM?), classify higher and fix before continuing.

---

## Validation Dimensions Quick Reference

See Pattern 1 in SHAMT_LITE.md for the full dimension lists per artifact type:
- Specs: 7 dimensions (Completeness, Correctness, Consistency, Helpfulness, Improvements, Missing proposals, Open questions)
- Implementation Plans: 7 dimensions (Step Clarity, Mechanical Executability, File Coverage, Operation Specificity, Verification Completeness, Dependency Ordering, Requirements Alignment)
- Code Reviews: 5 dimensions (Correctness, Completeness, Helpfulness, Severity Accuracy, Evidence)
- General Artifacts: 4 dimensions (Completeness, Clarity, Accuracy, Actionability)

---

*Extends Pattern 1 in SHAMT_LITE.md*
