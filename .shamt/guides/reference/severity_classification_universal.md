# Universal Severity Classification

**Purpose:** Define the 4-level severity system used across ALL validation contexts in Shamt
**Audience:** All agents running validation loops
**Last Updated:** 2026-04-01
**Version:** 1.0 (SHAMT-24)

---

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [The 4 Severity Levels](#the-4-severity-levels)
3. [Clean Round Allowance Rule](#clean-round-allowance-rule)
4. [Context-Specific Classifications](#context-specific-classifications)
5. [Severity Decision Tree](#severity-decision-tree)
6. [Borderline Case Protocol](#borderline-case-protocol)
7. [Examples by Context](#examples-by-context)

---

## Quick Reference

### The 4 Severity Levels

| Level | Symbol | Definition | Clean Round Impact |
|-------|--------|------------|-------------------|
| **Critical** | CRITICAL | Blocks workflow or causes cascading failures | Counter resets to 0 |
| **High** | HIGH | Causes significant confusion or wrong decisions | Counter resets to 0 |
| **Medium** | MEDIUM | Reduces quality but doesn't block or confuse | Counter resets to 0 |
| **Low** | LOW | Cosmetic issues with minimal impact | 1 allowed per round |

### Clean Round Quick Reference

**For Audit Rounds (aggregated across all 4 sub-rounds in a round):**

| Total Issues Discovered in Round | Clean Round? | Counter Action |
|-----------------------------------|--------------|----------------|
| 0 issues found across all 4 sub-rounds | Yes (Pure Clean) | Increment |
| Exactly 1 LOW issue found & fixed (any sub-round) | Yes (Clean with 1 Low Fix) | Increment |
| 2+ LOW issues found (across all sub-rounds) | No | Reset to 0 |
| Any MEDIUM issue found (any sub-round) | No | Reset to 0 |
| Any HIGH issue found (any sub-round) | No | Reset to 0 |
| Any CRITICAL issue found (any sub-round) | No | Reset to 0 |

**Important:** Each sub-round must reach 0 issues before proceeding to the next sub-round. The "≤1 LOW allowance" applies to the TOTAL issues discovered during the entire round's first pass (all 4 sub-rounds combined), not to unfixed issues.

---

## The 4 Severity Levels

### CRITICAL: Blocks Workflow

**Definition:** Issues that prevent agents or users from completing tasks, cause cascading failures, or violate hard policy limits.

**Characteristics:**
- Breaks functionality (file paths that don't exist, broken links agents must follow)
- Policy violations (CLAUDE.md exceeds 40,000 character hard limit)
- Template errors (errors in templates propagate to ALL new epics)
- Safety issues (instructions that could destroy work)
- Data integrity risks (could corrupt or lose data)

**Impact:**
- Agent gets stuck (can't find file to read)
- User can't proceed (workflow instructions broken)
- Cascading failures (one error causes multiple downstream errors)
- Production outages or data loss

**Clean Round Impact:** Counter resets to 0. Must be fixed before any other work.

---

### HIGH: Causes Confusion

**Definition:** Issues that don't block workflow but cause significant confusion, wrong decisions, or time waste.

**Characteristics:**
- Inconsistent information (contradictions between documents)
- Misleading content (outdated references, wrong counts)
- Missing critical sections (no Prerequisites in stage guide)
- Ambiguous instructions (multiple valid interpretations)
- Wrong technical claims (incorrect function signatures, wrong file locations)

**Impact:**
- Agent unclear how to proceed
- User loses confidence in documentation
- Time wasted clarifying ambiguity
- Wrong decisions made based on unclear info
- Technical errors from incorrect information

**Clean Round Impact:** Counter resets to 0.

---

### MEDIUM: Reduces Quality

**Definition:** Issues that don't cause confusion but reduce artifact quality, usability, or maintainability.

**Characteristics:**
- File size issues (files >2000 lines but readable)
- Missing optional sections (no Table of Contents in long file)
- Minor count inaccuracies (says "15 files" but actually 16)
- Incomplete examples (missing edge case demonstrations)
- Suboptimal patterns (works but not best practice)

**Impact:**
- Harder to use artifacts (navigation difficulty)
- Reduced readability (file too long)
- Minor inaccuracies (counts slightly off)
- Maintenance burden (technical debt)

**Clean Round Impact:** Counter resets to 0.

---

### LOW: Cosmetic Issues

**Definition:** Minor improvements that don't affect functionality, clarity, or usability.

**Characteristics:**
- Minor formatting (extra blank lines, trailing whitespace)
- Trivial typos (misspelled word that's still clear)
- Style preferences ("OK" vs "Okay")
- Optional enhancements (could add example but not required)
- Spacing inconsistencies

**Impact:**
- Minimal to none
- Purely cosmetic
- User unlikely to notice

**Clean Round Impact:** 1 LOW issue allowed per round. 2+ LOW issues reset counter to 0.

---

## Clean Round Allowance Rule

### The Rule

A validation round is considered **clean** if EITHER:
1. **Pure Clean:** Zero issues found across all dimensions
2. **Clean (1 Low Fix):** Exactly one LOW-severity issue found AND fixed

A round is **NOT clean** if ANY of:
- 2 or more LOW-severity issues found
- Any MEDIUM-severity issue found
- Any HIGH-severity issue found
- Any CRITICAL-severity issue found

### Counter Logic

```text
Round with 0 issues       → consecutive_clean += 1 (Pure Clean)
Round with 1 LOW (fixed)  → consecutive_clean += 1 (Clean with 1 Low Fix)
Round with 2+ LOW (fixed) → consecutive_clean = 0  (Not Clean)
Round with any MEDIUM+    → consecutive_clean = 0  (Not Clean)
```

### Sub-Agent Exception

**Sub-agents do NOT get the 1 LOW allowance.** Any issue found by a sub-agent (even LOW) resets the counter to 0.

**Rationale:** Sub-agents are the final verification step. Finding anything indicates a gap in primary validation that needs to be addressed.

### Documentation Requirement

When documenting round results, distinguish between clean round types:

```markdown
**Round N Summary:**
- Total Issues: {0 or 1}
- Severity Breakdown: CRITICAL: 0, HIGH: 0, MEDIUM: 0, LOW: {0 or 1}
- Clean Round Status: **Pure Clean** ✅ / **Clean (1 Low Fix)** ✅ / **Not Clean** ❌
- Issue Details: [If 1 LOW: describe what was found and fixed]
- consecutive_clean: {N}
```

---

## Context-Specific Classifications

### Implementation Plans (S5)

| Issue Type | Severity | Reason |
|------------|----------|--------|
| Missing requirement task | HIGH | Scope gap |
| Wrong function signature | HIGH | Will cause code errors |
| Missing algorithm mapping | MEDIUM | Traceability gap |
| Task acceptance criteria too vague | MEDIUM | Implementation ambiguity |
| Minor typo in task description | LOW | Still clear |
| Extra blank line in plan | LOW | Cosmetic |

### Code Review

| Issue Type | Severity | Reason |
|------------|----------|--------|
| Security vulnerability | CRITICAL | Must block merge |
| Logic error / bug | HIGH | Causes wrong behavior |
| Missing error handling | HIGH | Will cause failures |
| Code duplication | MEDIUM | Maintenance burden |
| Missing documentation | MEDIUM | Usability impact |
| Naming inconsistency | LOW | Style preference |
| Trailing whitespace | LOW | Cosmetic |

### Guide Audits

| Issue Type | Severity | Reason |
|------------|----------|--------|
| Broken file path (workflow guide) | CRITICAL | Blocks agent |
| CLAUDE.md >40K characters | CRITICAL | Policy violation |
| Mixed notation in same file | HIGH | Causes confusion |
| Missing required section | HIGH | Incomplete guidance |
| File >2000 lines | MEDIUM | Readability |
| Count slightly off | MEDIUM | Minor inaccuracy |
| Trailing whitespace | LOW | Cosmetic |
| Extra blank line | LOW | Cosmetic |

### Specifications (S2)

| Issue Type | Severity | Reason |
|------------|----------|--------|
| Contradictory requirements | CRITICAL | Blocks implementation |
| Incomplete scope definition | HIGH | Ambiguous boundaries |
| Missing acceptance criteria | HIGH | No success measure |
| Unclear terminology | MEDIUM | Requires interpretation |
| Missing example | MEDIUM | Less clear |
| Minor formatting | LOW | Cosmetic |

### Epic Documentation (S3)

| Issue Type | Severity | Reason |
|------------|----------|--------|
| Missing feature spec reference | HIGH | Incomplete tracking |
| Wrong dependency order | HIGH | Will cause errors |
| Outdated status | MEDIUM | Stale information |
| Missing timeline notes | MEDIUM | Planning gap |
| Formatting inconsistency | LOW | Cosmetic |

---

## Severity Decision Tree

```text
Issue Discovered
       │
       ▼
   ┌───────────────────────────────────┐
   │ Does it BLOCK workflow?           │
   │ - Can't proceed without fixing    │
   │ - Will cause cascading failures   │
   │ - Violates hard policy limits     │
   └───────────────────────────────────┘
       │
   ┌───┴───┐
   YES     NO
   │       │
   ▼       ▼
CRITICAL  ┌───────────────────────────────────┐
          │ Does it CONFUSE users/agents?     │
          │ - Multiple valid interpretations  │
          │ - Wrong information               │
          │ - Missing critical context        │
          └───────────────────────────────────┘
               │
           ┌───┴───┐
           YES     NO
           │       │
           ▼       ▼
          HIGH    ┌───────────────────────────────────┐
                  │ Does it REDUCE quality/usability? │
                  │ - Harder to use                   │
                  │ - Less maintainable               │
                  │ - Minor inaccuracy                │
                  └───────────────────────────────────┘
                       │
                   ┌───┴───┐
                   YES     NO
                   │       │
                   ▼       ▼
                MEDIUM    LOW
```

### Quick Questions

1. **"If this isn't fixed, can workflow complete?"** → NO = CRITICAL
2. **"Will this cause agent or user confusion?"** → YES = HIGH
3. **"Does this reduce quality or usability?"** → YES = MEDIUM
4. **"Is this purely cosmetic?"** → YES = LOW

---

## Borderline Case Protocol

### The Rule

**When uncertain between two severity levels, classify as the HIGHER severity.**

- LOW vs MEDIUM unclear → Classify as **MEDIUM**
- MEDIUM vs HIGH unclear → Classify as **HIGH**
- HIGH vs CRITICAL unclear → Classify as **CRITICAL**

### Rationale

1. **Conservative approach:** Safer to fix more urgently than to dismiss
2. **Prevents gaming:** Can't exploit 1 LOW allowance by under-classifying
3. **Quality preservation:** Errs on side of higher quality
4. **Sub-agent will catch:** If classification is wrong, sub-agents will identify

### When to Escalate

If severity classification would change the clean round outcome AND you cannot confidently classify, escalate to user:

```markdown
**Severity Classification Uncertainty:**

Issue: [describe]
Options: LOW vs MEDIUM
Impact: If LOW → round is clean (1 LOW allowed); If MEDIUM → round not clean

Arguments for LOW:
- [reason 1]
- [reason 2]

Arguments for MEDIUM:
- [reason 1]
- [reason 2]

Applying "err on higher" rule → Classifying as MEDIUM

(User may override if disagrees)
```

---

## Examples by Context

### Example 1: Implementation Plan Validation

**Round 3 Findings:**
- Issue 1: Typo "teh" instead of "the" in Task 4 description
  - Still readable and clear
  - Classification: **LOW**

**Result:** 1 LOW issue → Fix → Counter increments (Clean with 1 Low Fix)

---

### Example 2: Code Review Validation

**Round 2 Findings:**
- Issue 1: Trailing whitespace on line 45
  - Purely cosmetic
  - Classification: **LOW**
- Issue 2: Extra blank line between functions
  - Purely cosmetic
  - Classification: **LOW**

**Result:** 2 LOW issues → Fix → Counter resets to 0 (Not Clean)

---

### Example 3: Guide Audit Validation

**Round 4 Findings:**
- Issue 1: Says "see s5_p1.md" but correct reference is "s5_v2_validation_loop.md"
  - Wrong file reference
  - Agent would go to wrong file
  - Classification: **HIGH**

**Result:** 1 HIGH issue → Fix → Counter resets to 0 (Not Clean)

---

### Example 4: Borderline Classification

**Issue:** Variable naming could be clearer but is technically correct
- "cnt" instead of "count"

**Analysis:**
- Doesn't block anything → Not CRITICAL
- Is it confusing? Somewhat, but most developers know "cnt" = "count"
- Does it reduce quality? Slightly (less readable)
- Borderline: LOW vs MEDIUM

**Application of "err higher" rule:** Classify as **MEDIUM**

---

## See Also

- **Master Protocol:** `reference/validation_loop_master_protocol.md` - Full validation loop process
- **Guide Audit Classification:** `audit/reference/issue_classification.md` - Audit-specific details
- **S5 Validation Loop:** `stages/s5/s5_v2_validation_loop.md` - Implementation planning context

---

*End of Universal Severity Classification v1.0 (SHAMT-24)*
