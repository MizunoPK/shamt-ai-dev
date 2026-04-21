# Severity Classification

**Extends Pattern 2 (Severity Classification) in SHAMT_LITE.md — read that first.**

**Purpose:** Extended examples, borderline cases, and edge cases for severity classification

---

## Borderline Case Protocol

**Rule: When uncertain between two severity levels, classify as the HIGHER severity.**

- LOW vs MEDIUM unclear → **MEDIUM**
- MEDIUM vs HIGH unclear → **HIGH**
- HIGH vs CRITICAL unclear → **CRITICAL**

**Rationale:** Conservative classification prevents gaming the 1 LOW allowance, catches real problems sooner, and errs on the side of quality. The sub-agent will catch any over-classification.

---

## Common Classification Examples

### Design Doc / Spec Validation

| Issue | Classification | Reasoning |
|-------|---------------|-----------|
| Missing "Files Affected" section | CRITICAL | Required section — plan phase cannot proceed |
| Proposed design contradicts stated architecture | HIGH | Will cause confusion and wrong implementation |
| Solution options listed in wrong order (best last) | MEDIUM | Suboptimal but readable |
| "Recieve" typo in one requirement | LOW | Cosmetic |

### Code Review

| Issue | Classification | Reasoning |
|-------|---------------|-----------|
| SQL injection in user input handler | CRITICAL | Data security breach risk |
| Missing error handling — uncaught exception crashes server | HIGH | Users will see failures |
| Inconsistent naming across files | MEDIUM | Reduces maintainability |
| Trailing whitespace on two lines | LOW | Cosmetic |

### Implementation Plan

| Issue | Classification | Reasoning |
|-------|---------------|-----------|
| Step references file that doesn't exist | CRITICAL | Builder gets stuck immediately |
| Step says "edit the login function" (no locate string) | HIGH | Builder cannot execute without guessing |
| Step order works but is suboptimal | MEDIUM | Inefficient but executable |
| Typo in a step description | LOW | Still executable |

---

## Edge Cases

**"Cosmetic but misleads reviewer"** → HIGH. If it causes confusion, it's HIGH — regardless of how cosmetic it looks.

**"Wrong but not yet blocking"** — A wrong file path in a step that hasn't been reached yet: still CRITICAL. It will block when reached.

**"Missing optional section"** — Optional sections that add no value: LOW. Optional sections that would significantly help the executor: MEDIUM.

**"Variable naming: `cnt` vs `count`"** — Borderline LOW/MEDIUM. Apply "err higher" rule → MEDIUM.

**"Minor count inaccuracy (says 5 files, actually 6)"** — Borderline LOW/MEDIUM. Does it affect planning? If someone would count and notice → MEDIUM. If nobody would act on the exact count → LOW.

**"Extra blank line between sections"** — LOW. Purely cosmetic.

**"Recommendation inconsistency: says 'use Option A' in one place, 'use Option B' in another"** — HIGH. Creates real confusion about which option to implement.

---

## The "Err Higher" Rule in Practice

When you notice yourself writing "this is borderline LOW/MEDIUM, I'll call it LOW" — stop and ask:
- Is there any scenario where this causes confusion? If yes → MEDIUM.
- Is there any scenario where this blocks workflow? If yes → CRITICAL/HIGH.

The 1 LOW allowance exists for genuinely cosmetic issues. Using it to paper over a MEDIUM you don't want to fix defeats validation.

---

*Extends Pattern 2 in SHAMT_LITE.md*
