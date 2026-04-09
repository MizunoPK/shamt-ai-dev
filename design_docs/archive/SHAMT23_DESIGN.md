# SHAMT-23: Close the Gap with GitHub Copilot Code Review

**Status:** Draft
**Created:** 2026-03-31
**Last Updated:** 2026-04-01

---

## Constraints & Assumptions

**Scope Boundary:**
- This design focuses on **workflow guide changes only** — modifications to `.shamt/guides/` files
- CI/CD pipeline configuration is **out of scope** — child projects are responsible for ensuring their CI pipelines run the same linters
- This design assumes child projects will set `LINT_COMMAND` in their rules file to match their CI configuration

**Dependencies:**
- Baseline data collection must complete before Phase 1 implementation (see Prerequisites)
- Existing guides `security_checklist.md` and `common_mistakes.md` have been audited for overlap

**Existing Guide Audit Results:**
- `guides/reference/security_checklist.md` — Already contains comprehensive security patterns (path traversal, SQL injection, XSS, auth, etc.). **Proposal 2 will reference and extend this guide, not duplicate it.**
- `guides/reference/common_mistakes.md` — Contains workflow anti-patterns, minimal overlap with code quality proposals.

---

## Problem Statement

When code is pushed to GitHub, the Copilot code reviewer consistently finds a significant number of worthwhile improvements that our S7/S9 QC phases miss. This indicates a gap in our validation approach that allows mechanical and pattern-based issues to slip through.

---

## Root Cause Analysis

### Why Copilot Finds More Issues

| Factor | Copilot Approach | S7/S9 Approach | Gap |
|--------|------------------|----------------|-----|
| **Tool Integration** | Runs ESLint, CodeQL, PMD automatically | LLM-only judgment | No deterministic checking |
| **Context Gathering** | Indexes full repo before reviewing | Reads files sequentially per round | No pre-indexed understanding |
| **Issue Targeting** | Concrete patterns (operator confusion, null checks, unused imports) | Abstract dimensions ("Completeness", "Consistency") | Vague targets vs specific patterns |
| **Automation** | Always runs on every PR push | Manual trigger, requires following guides | Friction and opportunity for shortcuts |
| **Hybrid Approach** | LLM + deterministic rules together | LLM only | No backup for LLM blind spots |

### Key Insight

The gap isn't about validation rigor — S7/S9's multi-round validation loops with sub-agent confirmation are thorough. The gap is about **what type of checking** is performed. Copilot catches mechanical/deterministic issues through linters that the LLM might not notice during "fresh eyes" reading.

---

## Proposals

### Proposal 1: Mandatory Linting Gate

**Priority:** High
**Impact:** Catches 50%+ of mechanical issues
**Effort:** Low
**Affected Files:** `guides/stages/s7/s7_p1_smoke_testing.md`, `guides/stages/s9/s9_p1_epic_smoke_testing.md`, `scripts/initialization/RULES_FILE.template.md`

**Description:**
Add a mandatory linting step as a prerequisite before S7.P1 and S9.P1 smoke testing. The linter must pass with zero errors before QC can begin.

**Implementation:**

1. Add to S7.P1 prerequisites checklist:
   ```markdown
   **Linting (if project has linter configured):**
   - [ ] Run project linter: `{LINT_COMMAND}` (e.g., `ruff check .`, `eslint .`, `cargo clippy`)
   - [ ] Zero errors (warnings acceptable per project standards)
   - [ ] If linter not configured: document in EPIC_README that linting is N/A
   ```

2. Add to S9.P1 prerequisites checklist (same pattern)

3. Update `RULES_FILE.template.md` to include a `LINT_COMMAND` variable

**Rationale:**
Linters catch operator confusion (`=` vs `==`), unused imports, dead code, type errors, and style violations deterministically. These are exactly the "small stuff" Copilot catches via ESLint/CodeQL integration.

---

### Proposal 2: Optional Security Scan Dimension

**Priority:** High
**Impact:** Catches security vulnerabilities
**Effort:** Medium
**Affected Files:** `guides/reference/validation_loop_s7_feature_qc.md`, `guides/reference/validation_loop_s9_epic_qc.md`, `guides/reference/security_checklist.md`, `scripts/initialization/RULES_FILE.template.md`

**Description:**
Add an optional security scan dimension for projects that use security scanning tools. This proposal **extends the existing `security_checklist.md`** (which already covers manual security patterns) by adding automated scanner integration.

**Existing Guide Integration:**
- `guides/reference/security_checklist.md` already contains manual security checks (path traversal, SQL injection, XSS, etc.)
- This proposal adds **automated scanner invocation** as a complement to manual checks
- The dimension will reference `security_checklist.md` for manual verification patterns

**Dimension Numbering:**
- If implemented alone: Dim 17 for S7, Dim 13 for S9
- If implemented with Proposal 6 (Mechanical Issues): Dim 18 for S7, Dim 14 for S9

See Open Question 4 for dimension numbering strategy.

**Language-Specific Security Tool Mapping:**

| Language | Recommended Tool | Example Command |
|----------|------------------|-----------------|
| Python | Bandit | `bandit -r src/ -ll` |
| JavaScript/TypeScript | ESLint security plugin + npm audit | `npm audit --audit-level=high` |
| Go | gosec | `gosec ./...` |
| Java | SpotBugs + FindSecBugs | `mvn spotbugs:check` |
| Multi-language | Semgrep | `semgrep --config auto .` |
| Any (GitHub repos) | CodeQL | GitHub Actions integration |

**Implementation:**

1. Add to S7.P2 validation loop guide:
   ```markdown
   **Dim 17/18 — Security Scan (Optional, if project uses security scanner):**
   - [ ] Run security scanner: `{SECURITY_SCAN_COMMAND}` (see language mapping in guides)
   - [ ] Zero high-severity findings
   - [ ] Medium-severity findings reviewed and either fixed or documented as accepted risk
   - [ ] Manual security checks per `guides/reference/security_checklist.md` also pass
   - [ ] If no security scanner configured: skip automated scan, but still verify manual checklist
   ```

2. Mirror for S9.P2 (as dimension 13/14)

3. Update `RULES_FILE.template.md` to include optional `SECURITY_SCAN_COMMAND` variable with language mapping reference

4. Update `security_checklist.md` to add language-specific tool recommendations section

**Rationale:**
Copilot's CodeQL integration catches SQL injection, XSS, path traversal, and other security patterns. Adding explicit security scanning closes this gap for security-conscious projects. By extending the existing `security_checklist.md`, we avoid duplication and maintain a single source of truth for security guidance.

---

### Proposal 3: Concrete Issue Checklists Per Dimension

**Priority:** High
**Impact:** Gives LLM specific targets instead of vague concepts
**Effort:** Medium-High
**Affected Files:** `guides/reference/validation_loop_s7_feature_qc.md`, `guides/reference/validation_loop_s9_epic_qc.md`, `guides/reference/validation_loop_master_protocol.md`

**Description:**
Under each abstract dimension, add concrete patterns to look for. Transform dimensions from "check this concept" to "look for these specific issues."

**Implementation:**

Expand each dimension with concrete sub-checks. Example for existing dimensions:

**Dimension 9 — Error Handling Completeness (S7):**
```markdown
**Current (Abstract):**
- [ ] All errors handled gracefully

**Proposed (Concrete):**
- [ ] No bare `except:` or `catch {}` blocks — all exceptions specify type
- [ ] No swallowed exceptions (catch block that does nothing or only logs)
- [ ] All file/network operations have error handling
- [ ] Error messages include context (what failed, with what input)
- [ ] No `# TODO: handle error` comments — implement or remove
- [ ] Async operations have error boundaries
- [ ] User-facing errors are actionable (not raw stack traces)
```

**Dimension 13 — Import & Dependency Hygiene (S7):**
```markdown
**Current:**
- [ ] No unused imports in ANY changed file

**Proposed (Expanded):**
- [ ] No unused imports (verify each import is referenced in file)
- [ ] No duplicate imports (same module imported twice)
- [ ] No wildcard imports (`from x import *`) unless explicitly allowed
- [ ] Import order follows project convention (stdlib, third-party, local)
- [ ] No circular imports (A imports B imports A)
- [ ] Test-only dependencies in dev group, not main dependencies
```

**Deliverable:**
Create a new reference file `reference/concrete_issue_patterns.md` with language-specific patterns, then reference it from validation loop guides.

---

### Proposal 4: Pre-Validation Context Gathering Step

**Priority:** Medium
**Impact:** Mimics Copilot's "full context gathering" phase
**Effort:** Medium
**Affected Files:** `guides/stages/s7/s7_p2_qc_rounds.md`, `guides/stages/s9/s9_p2_epic_qc_rounds.md`

**Description:**
Before Round 1 of validation, require the agent to gather structured context about the changes, similar to how Copilot indexes the repo before reviewing.

**Implementation:**

Add a "Context Gathering" step before Round 1:

```markdown
## Pre-Validation Context Gathering (Before Round 1)

**Run these commands and document results in VALIDATION_LOOP_LOG.md:**

1. **Change Summary:**
   ```bash
   git diff --stat HEAD~N  # or vs feature branch base
   ```
   Document: Total files changed, lines added/removed

2. **Deferred Work Scan:**
   ```bash
   grep -rn "TODO\|FIXME\|HACK\|XXX" src/
   ```
   Document: Count and locations of deferred work markers

3. **Import/Dependency Analysis:**
   - For Python: `ruff check --select F401 .` (unused imports)
   - For TypeScript: `npx tsc --noEmit --noUnusedLocals`
   Document: Any findings

4. **Type Coverage (if applicable):**
   - For Python: `mypy src/ --ignore-missing-imports`
   - For TypeScript: Check for `any` usage
   Document: Type errors or coverage gaps

5. **Test Status:**
   ```bash
   {TEST_COMMAND}
   ```
   Document: Pass/fail count, any skipped tests

**Only proceed to Round 1 after context gathering is complete.**
```

**Rationale:**
Copilot gathers "full project context—source files, directory structure, references" before making suggestions. This step ensures the agent has structured knowledge before starting validation.

---

### Proposal 5: Adversarial Linter Check

**Priority:** Medium
**Impact:** Forces agent to think like a linter
**Effort:** Low
**Affected Files:** `guides/stages/s7/s7_p2_qc_rounds.md`, `guides/stages/s9/s9_p2_epic_qc_rounds.md`, `guides/code_review/code_review_workflow.md`

**Description:**
Add an adversarial self-check question specifically about mechanical issues that linters catch.

**Implementation:**

Add to the "Self-Check Checklist" in S7.P2 and S9.P2:

```markdown
### Adversarial Linter Check (Required Before Declaring Round Clean)

Before scoring a round as clean, explicitly answer:

> "What would ESLint/Ruff/CodeQL flag in this code that I haven't checked?"

Consider:
- [ ] Unused variables or imports?
- [ ] Operator confusion (= vs ==, == vs ===)?
- [ ] Missing null/undefined checks?
- [ ] Unreachable code after return/throw?
- [ ] Inconsistent string quotes or formatting?
- [ ] Type coercion issues?
- [ ] Security patterns (eval, innerHTML, SQL string concat)?

A round may NOT be scored clean if this check is skipped.
```

**Rationale:**
The code_review_workflow has an "Adversarial Self-Check" but it's generic. This specific linter-focused check forces the agent to consider mechanical issues.

---

### Proposal 6: New Dimension — Mechanical Issues

**Priority:** Medium
**Impact:** Explicit dimension for linter-type issues
**Effort:** Medium
**Affected Files:** `guides/reference/validation_loop_s7_feature_qc.md` (add dimension 17 for S7, dimension 13 for S9)

**Description:**
Add a dedicated dimension for mechanical issues that are typically caught by linters but might be missed by semantic review.

**Note:** If both Proposal 2 (Security Scan) and Proposal 6 (Mechanical Issues) are implemented:
- S7: Dim 17 = Mechanical Issues, Dim 18 = Security Scan (optional)
- S9: Dim 13 = Mechanical Issues, Dim 14 = Security Scan (optional)

Mechanical Issues is mandatory (every project benefits); Security Scan is optional (only for projects with security scanners configured).

**Implementation:**

```markdown
**Dim 17 — Mechanical Code Quality (S7) / Dim 13 (S9):**
- [ ] No unused imports (grep for each import, verify it's referenced)
- [ ] No unused variables (declared but never read)
- [ ] No dead code (unreachable after return/throw/break)
- [ ] No duplicate code blocks (copy-paste without abstraction)
- [ ] Consistent string quote style (single vs double)
- [ ] Consistent indentation (no mixed tabs/spaces)
- [ ] No trailing whitespace
- [ ] No commented-out code blocks (delete or restore)
- [ ] No debug statements left in (console.log, print, debugger)
- [ ] No magic numbers without constants (except 0, 1, -1)
```

**Rationale:**
Making mechanical issues an explicit dimension ensures they're checked every round, even if the project doesn't have a linter configured.

---

### Proposal 7: Tool Verification Requirement

**Priority:** Medium
**Impact:** Reduces pure "reading" validation
**Effort:** Low
**Affected Files:** `guides/reference/validation_loop_master_protocol.md`

**Description:**
Require each validation round to include at least one tool-based verification, not just reading.

**Implementation:**

Add to round structure:

```markdown
### Round N Structure

Each round MUST include:
1. Re-read entire codebase (existing requirement)
2. Check all dimensions (existing requirement)
3. **At least ONE tool-based verification** (NEW):
   - Run a grep/search for a specific pattern
   - Run linter on a subset of files
   - Run type checker
   - Execute a test
   - Run a security scan command

   Document the tool command and output in VALIDATION_LOOP_LOG.md
```

**Rationale:**
Pure reading-based validation can become a "checkbox exercise" (as noted in the S7.P2 guide's historical examples). Requiring tool use ensures empirical verification.

---

### Proposal 8: Per-Language Issue Catalogs

**Priority:** Low-Medium
**Impact:** Language-specific patterns Copilot catches
**Effort:** High (ongoing maintenance)
**Affected Files:** New file `guides/reference/concrete_issue_patterns.md` (consolidated with Proposals 3, 6)

**Description:**
Create catalogs of common issues by language that the validation loop should check for.

**Implementation:**

Create `reference/language_specific_patterns.md`:

```markdown
# Language-Specific Issue Patterns

## Python

**Error Handling:**
- [ ] No bare `except:` — always specify exception type
- [ ] No `except Exception:` that swallows and continues
- [ ] `finally` blocks don't mask exceptions

**Type Safety:**
- [ ] No `# type: ignore` without justification comment
- [ ] Optional types have None checks before use
- [ ] Dict access uses `.get()` or `in` check for unknown keys

**Security:**
- [ ] No `eval()` or `exec()` with user input
- [ ] No `pickle.load()` on untrusted data
- [ ] No `os.system()` or `subprocess.shell=True` with user input
- [ ] SQL uses parameterized queries, not f-strings

**Style:**
- [ ] f-strings preferred over `.format()` or `%`
- [ ] `pathlib.Path` preferred over `os.path`
- [ ] Context managers (`with`) for file/resource handling

---

## TypeScript/JavaScript

**Type Safety:**
- [ ] No `any` type (use `unknown` if type is truly unknown)
- [ ] No non-null assertions (`!`) without justification
- [ ] Optional chaining (`?.`) used for nullable access

**Error Handling:**
- [ ] Async functions have try/catch or .catch()
- [ ] Promise rejections are handled
- [ ] No unhandled promise in event handlers

**Security:**
- [ ] No `innerHTML` with user content (use `textContent`)
- [ ] No `eval()` or `new Function()`
- [ ] URLs validated before fetch/redirect

**Style:**
- [ ] `const` preferred over `let` when not reassigned
- [ ] No `var` usage
- [ ] Template literals preferred over string concat

---

## Go

(Add patterns for each language used in child projects)
```

**Rationale:**
Copilot's linter integration includes language-specific rules. Having our own catalog ensures the LLM checks for the same patterns.

---

### Proposal 9: Linter Commands in Prerequisites

**Priority:** Low (Quick Win)
**Impact:** Simple gate before QC
**Effort:** Very Low
**Affected Files:** `guides/stages/s7/s7_p2_qc_rounds.md`, `guides/stages/s9/s9_p2_epic_qc_rounds.md`

**Description:**
Add a single checkbox to prerequisites requiring linter to pass.

**Implementation:**

Add to S7.P2 Prerequisites Checklist:

```markdown
**Code Quality (if project has linter):**
- [ ] Linter passes: `{LINT_COMMAND}` exit code 0
```

**Rationale:**
Minimal change that creates a gate. Even without full Proposal 1 implementation, this reminds agents to run linters.

---

### Proposal 10: Track PR Review Findings for Continuous Improvement

**Priority:** Low (Ongoing Process)
**Impact:** Data-driven guide improvement
**Effort:** Low per instance, ongoing
**Affected Files:** `guides/audit/pr_review_findings_log.md` (new), `guides/stages/s10/s10_p1_pr_review.md` or equivalent

**Description:**
When any PR reviewer (human, Copilot, other AI models) catches something S7/S9 missed, document it to improve the guides over time. This log is populated during S10 when processing PR comments.

**Implementation:**

1. Create `.shamt/guides/audit/pr_review_findings_log.md`:
   ```markdown
   # PR Review Findings Log

   Track issues caught by PR reviewers (humans, Copilot, other AI) that S7/S9 missed, to improve validation guides.

   ## Entry Format

   ### {Date} — {Project/Epic}
   **Source:** {Human / Copilot / Claude / Other AI / Tool name}
   **PR:** {repo/PR_number}
   **Finding:** {Description of what was flagged}
   **Category:** {unused-import, error-handling, security, type-safety, code-style, logic-bug, etc.}
   **Which dimension should have caught this:** {Dim N — Name, or "None — new pattern"}
   **Root Cause:** {Why S7/S9 missed it}
   **Proposed Guide Update:** {Specific addition to guides, or "N/A — edge case"}
   **Status:** {Pending / Added to guides / Won't fix}
   ```

2. Add step to S10 workflow: "When processing PR comments, add any findings that S7/S9 should have caught to `pr_review_findings_log.md`"

3. Periodically review the log and update validation guides with recurring patterns

**Rationale:**
Continuous improvement based on real data from all review sources. Over time, the guides will cover patterns that any reviewer (human or AI) consistently catches. Integrating into S10 ensures the log is maintained as a natural part of the workflow rather than an afterthought.

---

## Proposal Relationships & Consolidation

### Linting Proposals (1 vs 9)

Proposals 1 and 9 both add linting requirements but at different phases:

| Proposal | Phase | Purpose |
|----------|-------|---------|
| **Proposal 9** | S7.P2/S9.P2 prerequisites | Quick win — reminds agent to run linter before validation loop |
| **Proposal 1** | S7.P1/S9.P1 smoke testing | Full gate — blocks QC entirely if linter fails |

**Relationship:** Proposal 9 is a lightweight version of Proposal 1. Implement Proposal 9 first as a quick win. Once validated, promote to full Proposal 1 (moving the gate earlier to P1). After Proposal 1 is implemented, Proposal 9 becomes redundant (P2 prerequisite is implicitly satisfied if P1 passed).

### Pattern Checklist Proposals (3, 6, 8)

Proposals 3, 6, and 8 all add concrete patterns to check:

| Proposal | Scope | Content |
|----------|-------|---------|
| **Proposal 3** | Expand existing dimensions | Add concrete sub-checks under existing abstract dimensions |
| **Proposal 6** | New dimension | Dedicated "Mechanical Issues" dimension for linter-type issues |
| **Proposal 8** | Language-specific | Separate catalogs per language (Python, TypeScript, Go, etc.) |

**Consolidation Decision:** Create a single reference file `guides/reference/concrete_issue_patterns.md` that contains:
1. Concrete sub-checks organized by dimension (Proposal 3)
2. A dedicated "Mechanical Issues" section (Proposal 6)
3. Language-specific appendices (Proposal 8)

This avoids creating 3 separate files with overlapping content. The validation loop guides reference this single consolidated file.

---

## Implementation Priority

**Note on Priority vs Phase:** "Priority" in each proposal indicates **business impact** (how much it helps close the Copilot gap). "Phase" indicates **implementation order** based on effort and dependencies. High-priority items may appear in later phases if they require more effort or depend on earlier work.

### Phase 1: Quick Wins (Immediate, Low Effort)
- **Proposal 9:** Add linter prerequisite checkbox (lightweight, no guide restructuring)
- **Proposal 5:** Add adversarial linter check question (single paragraph addition)

**Rationale:** These require minimal changes and can be deployed immediately to start gathering data.

### Phase 2: Core Improvements (Medium Effort)
- **Proposal 1:** Full mandatory linting gate (supersedes Proposal 9)
- **Proposals 3+6+8 (consolidated):** Create `concrete_issue_patterns.md` with all pattern content

**Rationale:** These require moderate guide restructuring but deliver the core improvements.

### Phase 3: Advanced Features (Higher Effort, Dependencies)
- **Proposal 2:** Optional security scan dimension (extends existing `security_checklist.md`)
- **Proposal 4:** Pre-validation context gathering
- **Proposal 7:** Tool verification requirement
- **Proposal 10:** Copilot findings tracking process

**Rationale:** These require more effort or benefit from learnings from earlier phases.

---

## Files Affected Summary

All paths relative to `.shamt/`:

| File | Proposals |
|------|-----------|
| `guides/stages/s7/s7_p1_smoke_testing.md` | 1 |
| `guides/stages/s7/s7_p2_qc_rounds.md` | 4, 5, 9 |
| `guides/stages/s9/s9_p1_epic_smoke_testing.md` | 1 |
| `guides/stages/s9/s9_p2_epic_qc_rounds.md` | 4, 5, 9 |
| `guides/reference/validation_loop_s7_feature_qc.md` | 2, 3, 6 |
| `guides/reference/validation_loop_s9_epic_qc.md` | 2, 3, 6 |
| `guides/reference/security_checklist.md` | 2 (extend with tool mapping) |
| `guides/reference/validation_loop_master_protocol.md` | 3, 7 |
| `guides/code_review/code_review_workflow.md` | 5 |
| `scripts/initialization/RULES_FILE.template.md` | 1, 2 |
| **New:** `guides/reference/concrete_issue_patterns.md` | 3, 6, 8 (consolidated) |
| **New:** `guides/audit/pr_review_findings_log.md` | 10 |
| `guides/stages/s10/s10_p1_pr_review.md` (or equivalent) | 10 |

---

## Open Questions

1. **Linter flexibility:** Should we mandate a specific linter per language, or allow projects to choose? (Recommendation: allow choice, just require *some* linter)

2. **Failure handling:** If linter has warnings but no errors, should that block QC? (Recommendation: errors block, warnings don't)

3. **Security scan scope:** Should security scanning be mandatory for certain project types (e.g., web apps with user input)? (Recommendation: optional but strongly encouraged)

4. **Dimension renumbering:** Adding new dimensions changes the count. Should we renumber or use 17+ for optional dimensions? (Recommendation: use 17+ for optional)

5. **False positive handling:** How should agents handle linter findings that are intentional or project-specific exceptions?
   - (Recommendation: Projects document exceptions in `CODING_STANDARDS.md` with justification. Agent checks if finding matches a documented exception before flagging as issue. For ad-hoc exceptions, agent presents to user with "This appears intentional — confirm or fix?")

6. **Baseline measurement:** How do we establish the current issue count from Copilot to measure improvement?
   - (Recommendation: Before implementing changes, collect data from next 3-5 PRs: count Copilot comments, categorize by type. Document baseline in this design doc or `PROCESS_METRICS.md`. After implementation, compare.)

7. **CI/CD integration:** Should linting also be enforced in CI pipelines to catch issues before code reaches Copilot?
   - (Recommendation: Out of scope for this design — this design focuses on workflow guides, not CI/CD configuration. However, projects with CI pipelines should ensure their lint commands match what's documented in `LINT_COMMAND`. A future design doc could address CI/CD integration specifically.)

---

## Prerequisites Before Implementation

**Establish Baseline (Required before Phase 1):**

### Baseline Data Collection Protocol

**Step 1: Identify PRs (3-5 PRs that went through S7/S9)**
- Select PRs from child projects that completed S7/S9 QC before Copilot review
- Exclude PRs that were trivial (< 50 lines changed) or didn't involve code

**Step 2: For each PR, collect data in this format:**

```markdown
## PR: {repo}/{PR_number}
**Date:** {date}
**Lines Changed:** {added} / {removed}
**S7/S9 Completed:** Yes/No

### Copilot Findings
| # | Finding | Category | Fixed? | Should S7/S9 have caught? |
|---|---------|----------|--------|---------------------------|
| 1 | {description} | {category} | Yes/No/Dismissed | Yes/No/Unclear |

**Categories:** unused-import, unused-variable, error-handling, security, type-safety, code-style, logic-bug, performance, documentation, other

### Summary
- Total Copilot comments: {N}
- Fixed (actual issues): {N}
- Dismissed (false positives or intentional): {N}
- Should have been caught by S7/S9: {N}
```

**Step 3: Calculate baseline metrics:**
- Average fixable issues per PR: `sum(fixed) / count(PRs)`
- Top 5 categories by frequency
- S7/S9 miss rate: `sum(should_have_caught) / sum(fixed)`

**Step 4: Document baseline in "Baseline Data" section of this design doc**

**Definition of "Fixable Issue":**
An issue is "fixable" if:
1. The code change was made to address it, OR
2. It was dismissed with explicit justification (e.g., "intentional for performance")

An issue is NOT "fixable" if:
1. It was a false positive (Copilot misunderstood the code)
2. It was a style preference with no correctness impact

**Timeline:** Complete baseline collection within 2 weeks or 5 PRs, whichever comes first.

---

## Baseline Data

*(To be filled after baseline collection completes)*

| Metric | Value |
|--------|-------|
| PRs analyzed | TBD |
| Avg fixable issues per PR | TBD |
| Top categories | TBD |
| S7/S9 miss rate | TBD |

---

---

## Success Criteria

This initiative is successful when:

1. **Measurable:** Copilot finds <50% as many *fixable* issues on PRs that went through S7/S9 (compared to established baseline)
2. **Process:** Linting is a documented prerequisite in all child projects
3. **Coverage:** Concrete issue checklists cover the top 10 patterns from baseline data
4. **Adoption:** At least 3 child projects report using the new linting gates

---

## References

- [GitHub Copilot Code Review Docs](https://docs.github.com/en/copilot/concepts/agents/code-review)
- [Linter Integration Announcement (Nov 2025)](https://github.blog/changelog/2025-11-20-linter-integration-with-copilot-code-review-now-in-public-preview/)
- [Agentic Code Review Features (Oct 2025)](https://github.blog/changelog/2025-10-28-new-public-preview-features-in-copilot-code-review-ai-reviews-that-see-the-full-picture/)
- [GitHub Copilot PR Automation Features](https://www.augmentcode.com/tools/github-copilot-ai-code-review)

---

**END OF DESIGN DOC**
