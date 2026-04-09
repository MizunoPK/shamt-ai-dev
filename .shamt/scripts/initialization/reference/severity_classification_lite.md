# Severity Classification

**Purpose:** 4-level severity system for classifying issues during validation and code review

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

| Total Issues Discovered in Round | Clean Round? | Counter Action |
|-----------------------------------|--------------|----------------|
| 0 issues found | Yes (Pure Clean) | Increment |
| Exactly 1 LOW issue found & fixed | Yes (Clean with 1 Low Fix) | Increment |
| 2+ LOW issues found | No | Reset to 0 |
| Any MEDIUM issue found | No | Reset to 0 |
| Any HIGH issue found | No | Reset to 0 |
| Any CRITICAL issue found | No | Reset to 0 |

---

## The 4 Severity Levels

### CRITICAL: Blocks Workflow

**Definition:** Issues that prevent agents or users from completing tasks, cause cascading failures, or violate hard policy limits.

**Characteristics:**
- Breaks functionality (file paths that don't exist, broken links)
- Policy violations (exceeds hard limits)
- Template errors (errors propagate to all uses)
- Safety issues (instructions that could destroy work)
- Data integrity risks (could corrupt or lose data)

**Impact:**
- Agent gets stuck (can't find required file)
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
- Missing critical sections (incomplete guidance)
- Ambiguous instructions (multiple valid interpretations)
- Wrong technical claims (incorrect signatures, wrong file locations)

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
- File size issues (files very long but still readable)
- Missing optional sections (no table of contents in long file)
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

---

## Common Examples

### Example 1: Design Doc Validation

**Round 3 Findings:**
- Issue 1: Typo "teh" instead of "the" in description
  - Still readable and clear
  - Classification: **LOW**

**Result:** 1 LOW issue → Fix → Counter increments (Clean with 1 Low Fix)

---

### Example 2: Code Review

**Round 2 Findings:**
- Issue 1: Trailing whitespace on line 45
  - Purely cosmetic
  - Classification: **LOW**
- Issue 2: Extra blank line between functions
  - Purely cosmetic
  - Classification: **LOW**

**Result:** 2 LOW issues → Fix → Counter resets to 0 (Not Clean)

---

### Example 3: Specification Validation

**Round 4 Findings:**
- Issue 1: Says "see config.md" but correct reference is "configuration.md"
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

*Adapted from Shamt Universal Severity Classification*
