# Validation Loop Exit Criteria

**Purpose:** Define how to run validation loops and when they're complete

---

## What is a Validation Loop?

A systematic quality assurance process that validates artifacts (specs, plans, code, documentation) through iterative rounds until achieving:
1. Primary clean round (zero issues or exactly 1 LOW-severity issue)
2. Two independent sub-agents confirm zero issues

---

## Core Process

### Round Structure

Each validation round follows this pattern:

```text
1. Read artifact completely with fresh perspective
   ↓
2. Identify issues across relevant dimensions
   ↓
3. Classify each issue by severity (CRITICAL/HIGH/MEDIUM/LOW)
   ↓
4. Fix ALL issues immediately (zero tolerance for deferred issues)
   ↓
5. Update consecutive_clean counter:
   - 0 issues → counter = 1 (primary clean round)
   - 1 LOW issue → counter = 1 (clean with 1 low fix)
   - 2+ LOW issues OR any MEDIUM/HIGH/CRITICAL → counter = 0
   ↓
6. Check exit condition:
   - If counter < 1: Loop to step 1 (next round)
   - If counter = 1: Proceed to sub-agent confirmation
```

### Fresh Eyes Principle

**Critical:** Re-read the ENTIRE artifact every single round (not from memory)

**Why:** First-pass reading misses 40%+ of important details. Memory-based validation is unreliable.

**How:**
- Round 1: Sequential read (top to bottom)
- Round 2: Different order (bottom to top, by section, random)
- Round 3+: Vary reading patterns each round

---

## Exit Criteria

### Primary Clean Round

A round is considered **clean** if EITHER:
- **Pure Clean:** Zero issues found
- **Clean (1 Low Fix):** Exactly 1 LOW-severity issue found and fixed

A round is **NOT clean** if:
- 2+ LOW-severity issues found
- Any MEDIUM-severity issue found
- Any HIGH-severity issue found
- Any CRITICAL-severity issue found

### Sub-Agent Confirmation

When primary clean round is achieved (`consecutive_clean = 1`):

1. **Spawn 2 independent sub-agents in parallel**
2. Each sub-agent:
   - Reads the artifact completely
   - Validates across all relevant dimensions
   - Reports total issues found
3. **Exit condition:**
   - Both sub-agents confirm zero issues → **VALIDATION COMPLETE** ✅
   - Either sub-agent finds issues → Reset `consecutive_clean = 0`, fix issues, continue loop

**Important:** Sub-agents do NOT get the 1 LOW allowance. ANY issue found by a sub-agent (even LOW) means they cannot confirm.

---

## Counter Logic

### consecutive_clean Tracking

```text
Initial state: consecutive_clean = 0

Round N finds 0 issues:
  → consecutive_clean = 1 (primary clean round achieved)
  → Trigger sub-agent confirmation

Round N finds exactly 1 LOW issue (and fixes it):
  → consecutive_clean = 1 (clean with 1 low fix)
  → Trigger sub-agent confirmation

Round N finds 2+ LOW issues:
  → consecutive_clean = 0 (not clean)
  → Fix all issues, continue to Round N+1

Round N finds any MEDIUM/HIGH/CRITICAL issue:
  → consecutive_clean = 0 (not clean)
  → Fix all issues, continue to Round N+1

Sub-agent finds ANY issue (even LOW):
  → consecutive_clean = 0 (cannot confirm)
  → Fix issues, continue to next round
```

### Example Sequences

**Scenario 1: Quick Exit (2 rounds)**
```
Round 1: Found 3 MEDIUM issues → consecutive_clean = 0 → Fix → Continue
Round 2: Found 0 issues → consecutive_clean = 1 → Trigger sub-agents
Sub-agent A: 0 issues ✅
Sub-agent B: 0 issues ✅
→ COMPLETE
```

**Scenario 2: Multiple Rounds (4 rounds)**
```
Round 1: Found 5 issues (2 HIGH, 3 MEDIUM) → consecutive_clean = 0 → Fix → Continue
Round 2: Found 1 MEDIUM issue → consecutive_clean = 0 → Fix → Continue
Round 3: Found 1 LOW issue → consecutive_clean = 1 → Trigger sub-agents
Sub-agent A: Found 1 LOW issue ❌ → consecutive_clean = 0 → Fix → Continue
Round 4: Found 0 issues → consecutive_clean = 1 → Trigger sub-agents
Sub-agent A: 0 issues ✅
Sub-agent B: 0 issues ✅
→ COMPLETE
```

---

## Documentation Requirements

### Track Progress

Document each round in a validation log:

```markdown
### Round 1

**Reading Pattern:** Sequential (top to bottom)

**Issues Found:** 3
- Issue 1: Missing section X (Severity: HIGH)
- Issue 2: Typo in line 42 (Severity: LOW)
- Issue 3: Unclear description (Severity: MEDIUM)

**Fixes Applied:**
- Added section X with details
- Fixed typo
- Clarified description

**consecutive_clean:** 0 (3 issues found)

---

### Round 2

**Reading Pattern:** Reverse order (bottom to top)

**Issues Found:** 0

**consecutive_clean:** 1 (primary clean round achieved)

**Action:** Spawning sub-agents for confirmation

---

### Sub-Agent Confirmations

**Sub-Agent A:** 0 issues found ✅
**Sub-Agent B:** 0 issues found ✅

**Result:** VALIDATION COMPLETE ✅
```

---

## Common Mistakes

### ❌ Wrong: Exiting After First Clean Round

```
Round 3: 0 issues found → consecutive_clean = 1
Agent declares: "Validation complete!"
```

**Problem:** Skipped sub-agent confirmation step. Not complete until BOTH sub-agents confirm.

---

### ❌ Wrong: Deferring Issues

```
Round 2: Found 2 MEDIUM issues
Agent says: "I'll fix these later, continuing validation..."
```

**Problem:** ALL issues must be fixed immediately before continuing.

---

### ❌ Wrong: Reading from Memory

```
Round 3: Agent checks artifact from memory of Round 2
```

**Problem:** Must re-read ENTIRE artifact with fresh perspective every round.

---

### ❌ Wrong: Allowing Sub-Agent LOW Issues

```
Sub-agent A: Found 1 LOW issue
Agent says: "That's allowed, sub-agent confirms"
```

**Problem:** Sub-agents do NOT get the 1 LOW allowance. ANY issue = cannot confirm.

---

## Validation Dimensions

When validating, check these dimensions (adapt based on your artifact type):

### Generic Dimensions (applicable to most artifacts)

1. **Completeness:** Are all necessary aspects covered?
2. **Correctness:** Are factual claims accurate?
3. **Consistency:** Are there internal contradictions?
4. **Clarity:** Is everything understandable?

### Spec-Specific Dimensions

5. **Scope:** Is in/out/deferred clearly defined?
6. **Acceptance Criteria:** How will success be measured?

### Code-Specific Dimensions

5. **Correctness:** Logic errors, bugs?
6. **Security:** Vulnerabilities?
7. **Performance:** Efficiency concerns?
8. **Maintainability:** Code quality?

### Plan-Specific Dimensions

5. **Feasibility:** Can this actually be implemented?
6. **Dependencies:** Are prerequisites identified?

Choose dimensions relevant to what you're validating. Check ALL chosen dimensions EVERY round.

---

*Adapted from Shamt Master Validation Loop Protocol*
