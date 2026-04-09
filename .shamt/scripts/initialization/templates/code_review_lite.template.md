# Code Review Template

Use this template structure for code reviews in Shamt Lite.

---

## Overview Document

**Filename:** `overview.md`
**Purpose:** High-level description of what the branch/PR does

```markdown
# Branch Overview: <branch-name>

**Date:** YYYY-MM-DD
**Base:** <base branch> (merge base: <short SHA>)
**Commits:** N commits (<first SHA>..<last SHA>)
**Files changed:** N files (+X -Y lines)

---

## ELI5 — What Changed?

<2-4 sentence plain-English summary for someone with no context. Avoid jargon.
Focus on what the user would notice, not implementation details.>

---

## What Does This Branch Do?

<Clear description of purpose and outcomes. What problem does it solve? What
feature does it add? What does the system do differently after this is merged?>

## Why Was It Built?

<Intent and motivation from commit messages, PR description, and code reading.
If intent is not explicit, state "inferred from commit messages / code structure.">

## How Does It Work?

<Technical walkthrough: which files were changed, what the key logic is, how
components interact, notable design choices. Organize by area of change when
multiple subsystems are touched.>

---

*Overview generated using Shamt Lite code review workflow*
*Branch: <branch> | Base: <base> | Date: YYYY-MM-DD*
```

---

## Review Document

**Filename:** `review.md` (or `review_v1.md`, `review_v2.md` for versioning)
**Purpose:** Structured feedback organized by severity

```markdown
# Code Review: <branch-name>

**Reviewed:** YYYY-MM-DD
**Base:** <base branch> (merge base: <short SHA>)
**Commits:** N commits (<first SHA>..<last SHA>)
**Files changed:** N files (+X -Y lines)
**Overview:** See `overview.md` for full description

---

## Review Comments

<Grouped by severity, then by category. Omit severity levels with no findings.>

### BLOCKING

<Must be fixed before merge — bugs, security issues, data loss risks>

#### [BLOCKING] Category — <Category Name>

**File:** `path/to/file.ext`, line N

<Description of issue. Be specific: what line, what it does wrong, what the consequence is.>

**Suggested fix:** <Concrete direction — what to change and why.>

---

### CONCERN

<Should be addressed — quality, performance, or maintainability issues>

#### [CONCERN] Category — <Category Name>

**File:** `path/to/file.ext`, line N

<Description>

**Suggested fix:** <Direction>

---

### SUGGESTION

<Optional improvements — code works but could be better>

#### [SUGGESTION] Category — <Category Name>

**File:** `path/to/file.ext`, line N

<Description>

**Suggested fix:** <Direction>

---

### NITPICK

<Minor style or preference — author decides>

#### [NITPICK] Category — <Category Name>

**File:** `path/to/file.ext`, line N

<Description>

**Suggested fix:** <Direction>

---

## Validation Summary

**Rounds completed:** N
**Exit criteria:** Primary clean round + sub-agent confirmation
**Sub-agent A:** 0 issues ✅
**Sub-agent B:** 0 issues ✅
**Issues found and resolved during validation:** N

---

*Review generated using Shamt Lite code review workflow*
*Branch: <branch> | Base: <base> | Date: YYYY-MM-DD*
```

---

## Severity Definitions

| Severity | Meaning |
|----------|---------|
| **BLOCKING** | Must be fixed before merge. Correctness bug, security vulnerability, or data-loss risk. |
| **CONCERN** | Should be addressed. Quality, performance, or maintainability issue that will cause real problems. |
| **SUGGESTION** | Optional improvement. The code works but could be better. |
| **NITPICK** | Minor style or preference. Author decides. |

---

## Review Categories

Use these categories when organizing feedback:

1. **Correctness** - Logic errors, bugs, incorrect behavior
2. **Security** - Vulnerabilities, unsafe practices
3. **Performance** - Inefficiencies, scalability issues
4. **Maintainability** - Code clarity, organization, complexity
5. **Testing** - Test coverage, test quality
6. **Edge Cases** - Unhandled scenarios, missing validation
7. **Naming** - Variable, function, class naming
8. **Documentation** - Comments, docstrings, README updates
9. **Error Handling** - Exception handling, error recovery
10. **Concurrency** - Race conditions, thread safety
11. **Dependencies** - Library usage, version constraints
12. **Architecture** - Design patterns, structure, coupling

---

*Template for Code Reviews in Shamt Lite*
