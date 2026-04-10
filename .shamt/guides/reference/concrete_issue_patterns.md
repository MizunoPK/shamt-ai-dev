# Concrete Issue Patterns

**Purpose:** Language-specific patterns and mechanical issues to check during validation loops
**Created:** 2026-04-01
**Last Updated:** 2026-04-01

**Applicable Stages:**
- S7.P2: Feature QC Validation Loop (Dimension 17)
- S9.P2: Epic QC Validation Loop (Dimension 13)

---

## Overview

This reference provides concrete, checkable patterns for validation loop dimensions. Instead of vague concepts like "check error handling," this guide provides specific patterns to look for.

**How to use:** During validation rounds, consult this guide for specific patterns relevant to your project's language. Check each applicable pattern explicitly.

---

## 1. Mechanical Code Quality (Linter-Type Issues)

These issues are typically caught by linters but should be verified manually if no linter is configured.

### Universal Patterns (All Languages)

- [ ] No unused imports (grep for each import, verify it's referenced)
- [ ] No unused variables (declared but never read)
- [ ] No dead code (unreachable after return/throw/break)
- [ ] No duplicate code blocks (copy-paste without abstraction)
- [ ] Consistent string quote style (single vs double per project standard)
- [ ] Consistent indentation (no mixed tabs/spaces)
- [ ] No trailing whitespace
- [ ] No commented-out code blocks (delete or restore)
- [ ] No debug statements left in (console.log, print, debugger)
- [ ] No magic numbers without constants (except 0, 1, -1)

---

## 2. Error Handling Patterns

### Python

- [ ] No bare `except:` — always specify exception type
- [ ] No `except Exception:` that swallows and continues silently
- [ ] `finally` blocks don't mask exceptions
- [ ] File/network operations have error handling
- [ ] Error messages include context (what failed, with what input)
- [ ] No `# TODO: handle error` comments — implement or remove

### TypeScript/JavaScript

- [ ] Async functions have try/catch or .catch()
- [ ] Promise rejections are handled
- [ ] No unhandled promise in event handlers
- [ ] Error boundaries for React components (if applicable)

### Go

- [ ] All returned errors checked (no `_` for error values)
- [ ] Errors wrapped with context (`fmt.Errorf("context: %w", err)`)

---

## 3. Type Safety Patterns

### Python

- [ ] No `# type: ignore` without justification comment
- [ ] Optional types have None checks before use
- [ ] Dict access uses `.get()` or `in` check for unknown keys

### TypeScript

- [ ] No `any` type (use `unknown` if type is truly unknown)
- [ ] No non-null assertions (`!`) without justification
- [ ] Optional chaining (`?.`) used for nullable access
- [ ] Strict null checks enabled (tsconfig)

---

## 4. Import & Dependency Patterns

### Universal

- [ ] No circular imports (A imports B imports A)
- [ ] Import order follows project convention (stdlib, third-party, local)
- [ ] Test-only dependencies in dev group, not main dependencies
- [ ] No wildcard imports (`from x import *`) unless explicitly allowed

### Quick Checks

- Python: `ruff check --select F401 {changed_files}`
- TypeScript: `npx tsc --noEmit --noUnusedLocals`

---

## 5. Security Patterns

**Reference:** See `reference/security_checklist.md` for comprehensive security patterns.

### Quick Security Scan

- [ ] No `eval()` or `exec()` with user input
- [ ] No SQL string concatenation (use parameterized queries)
- [ ] No `os.system()` or `subprocess.shell=True` with user input
- [ ] No `innerHTML` with user content (use `textContent`)
- [ ] File paths validated and bounded (no path traversal)
- [ ] API keys in environment variables, not hardcoded

---

## 6. Cross-Layer Consistency Patterns

### Frontend-Backend Type Alignment

- [ ] Frontend TypeScript types mirror backend Pydantic model constraints exactly
  - Backend `Literal["jpeg", "png"]` → Frontend `"jpeg" | "png"` (NOT `string`)
  - Backend `int` with `Field(ge=0)` → Frontend with matching runtime validation
- [ ] Data flows through the FULL pipeline with consistent metadata
- [ ] Frontend timeouts >= backend worst-case execution time (with buffer)
- [ ] Constants shared (single source of truth), not independently constructed

---

## 7. Test Quality Patterns

### Mock/Stub Consistency

- [ ] Mock return values match mock state configuration
  - If `mock_output.output_format = "jpeg"`, save stub returns `.jpeg` URL
- [ ] Assertions match what real code would produce given mock state
- [ ] No hardcoded assertions against arbitrary values

### Coverage Adequacy

- [ ] All requirements have tests
- [ ] All edge cases have tests (boundary values, empty input)
- [ ] All error paths have tests
- [ ] Integration tests with real objects (not just mocks)

---

## Language-Specific Quick Reference

### Python

| Pattern Category | Tool Check | Manual Check |
|------------------|------------|--------------|
| Unused imports | `ruff check --select F401` | grep each import |
| Type safety | `mypy src/` | Review Optional usage |
| Security | `bandit -r src/` | Review user input handling |

### TypeScript/JavaScript

| Pattern Category | Tool Check | Manual Check |
|------------------|------------|--------------|
| Unused imports | `npx tsc --noEmit --noUnusedLocals` | grep each import |
| Type safety | TypeScript strict mode | Review `any` usage |
| Security | `npm audit` | Review innerHTML, eval |

### Go

| Pattern Category | Tool Check | Manual Check |
|------------------|------------|--------------|
| Unused imports | `go vet` | grep each import |
| Error handling | `errcheck` | Review error returns |
| Security | `gosec ./...` | Review user input handling |

---

## Integration with Validation Loops

### S7 Feature QC (Dimension 17 — Mechanical Code Quality)

Add to each round's checklist:
- [ ] Consulted `reference/concrete_issue_patterns.md` for applicable patterns
- [ ] Checked Universal Patterns (Section 1)
- [ ] Checked language-specific patterns (Sections 2-4)
- [ ] Security quick scan completed (Section 5)

### S9 Epic QC (Dimension 13 — Mechanical Code Quality)

Same checklist applied across ALL features in the epic, plus:
- [ ] Patterns consistent across features (same style, same conventions)
- [ ] No feature has mechanical issues that others don't

---

**END OF CONCRETE ISSUE PATTERNS**
