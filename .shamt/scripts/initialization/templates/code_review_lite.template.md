# Code Review Template

Use this template for code reviews in Shamt Lite. Two modes:

- **Story mode:** `stories/{slug}/code_review/review_v1.md` only — no overview.md (the story folder provides context via ticket.md, spec.md, and implementation_plan.md)
- **Formal mode:** `.shamt/code_reviews/<branch>/overview.md` + `review_v1.md` — use when reviewing someone else's branch or PR

---

## Overview Document (Formal Mode Only)

**Filename:** `overview.md`
**When:** Reviewing an external branch or PR (not used in story mode)

```markdown
# Branch Overview: <branch-name>

**Date:** YYYY-MM-DD
**Base:** <base branch> (merge base: <short SHA>)
**Commits:** N commits (<first SHA>..<last SHA>)
**Files changed:** N files (+X -Y lines)

---

## What Does This Branch Do?

<Clear description of purpose and outcomes. What problem does it solve? What
feature does it add? What does the system do differently after this is merged?>

## Why Was It Built?

<Intent and motivation from commit messages, PR description, and code reading.
If intent is not explicit, state "inferred from commit messages / code structure.">

## How Does It Work?

<Technical walkthrough: which files were changed, what the key logic is, how
components interact, notable design choices. Organize by area when multiple
subsystems are touched.>

---
✅ Validated YYYY-MM-DD — N rounds, 1 sub-agent confirmed
*Branch: <branch> | Base: <base>*
```

---

## Review Document (Both Modes)

**Filename:** `review_v1.md` (or `review_v2.md`, `review_v3.md` on re-review — never overwrite)

**Story mode path:** `stories/{slug}/code_review/review_v1.md`
**Formal mode path:** `.shamt/code_reviews/<branch>/review_v1.md`

```markdown
# Code Review: <branch-name or story-slug>

**Reviewed:** YYYY-MM-DD
**Base:** <base branch> (merge base: <short SHA>)
**Commits:** N commits | **Files changed:** N files (+X -Y lines)
[Formal mode: **Overview:** See `overview.md`]
[Story mode: **Story:** stories/{slug}/]

---

## Review Comments

<Grouped by severity, then by category. Omit severity sections with no findings.>

### BLOCKING

<Must be fixed before merge — correctness bug, security vulnerability, data-loss risk>

#### [BLOCKING] — <Category Name>

**File:** `path/to/file.ext`, line N

<Description: what it does wrong and what the consequence is.>

**Suggested fix:** <What to change and why.>

---

### CONCERN

<Should be addressed — quality, performance, or maintainability issue>

#### [CONCERN] — <Category Name>

**File:** `path/to/file.ext`, line N

<Description>

**Suggested fix:** <Direction>

---

### SUGGESTION

<Optional improvement — code works but could be better>

#### [SUGGESTION] — <Category Name>

**File:** `path/to/file.ext`, line N

<Description>

**Suggested fix:** <Direction>

---

### NITPICK

<Minor style or preference — author decides>

#### [NITPICK] — <Category Name>

**File:** `path/to/file.ext`, line N

<Description>

---
✅ Validated YYYY-MM-DD — N rounds, 1 sub-agent confirmed
*Review generated using Shamt Lite code review workflow*
```

---

## Severity Definitions

| Severity | Meaning |
|----------|---------|
| **BLOCKING** | Must be fixed before merge — correctness bug, security vulnerability, data-loss risk |
| **CONCERN** | Should be addressed — quality, performance, or maintainability issue |
| **SUGGESTION** | Optional improvement — code works but could be better |
| **NITPICK** | Minor style or preference — author decides |

---

## Review Categories

1. **Correctness** — Logic errors, bugs, incorrect behavior
2. **Security** — Vulnerabilities, unsafe practices
3. **Performance** — Inefficiencies, scalability issues
4. **Maintainability** — Code clarity, organization, complexity
5. **Testing** — Test coverage, test quality
6. **Edge Cases** — Unhandled scenarios, missing validation
7. **Naming** — Variable, function, class naming
8. **Documentation** — Comments, docstrings, README updates
9. **Error Handling** — Exception handling, error recovery
10. **Concurrency** — Race conditions, thread safety
11. **Dependencies** — Library usage, version constraints
12. **Architecture** — Design patterns, structure, coupling

---

*Template for Code Reviews in Shamt Lite*
