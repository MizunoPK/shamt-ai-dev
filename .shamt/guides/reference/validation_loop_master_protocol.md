# Master Validation Loop Protocol

**Version:** 2.4 (SHAMT-24: Single Low-Severity Fix Allowance)
**Last Updated:** 2026-04-01
**Purpose:** Universal validation loop protocol with master dimensions that apply to ALL validation contexts
**Extends:** This master protocol is extended by scenario-specific validation loop guides

---

🚨🚨🚨 **HARD STOP — READ BEFORE PROCEEDING** 🚨🚨🚨

**The validation loop is the most frequently violated protocol in this workflow.** Agents consistently shortcut it by:
- Declaring "primary clean round" after finding issues in every round they ran
- Skipping the sub-agent confirmation step entirely and declaring the loop complete
- Not creating the required VALIDATION_LOG.md file
- Reading partial sections instead of the full artifact
- Not checking all dimensions systematically (finding issues "organically" instead)

**If you are about to run a validation loop, you MUST:**

1. **Create `VALIDATION_LOG.md`** in the feature/artifact folder BEFORE starting Round 1
2. **Track `consecutive_clean`** explicitly in the log:
   - Starts at 0
   - Resets to 0 when ANY of these occur:
     * Multiple LOW-severity issues found (2+)
     * Any MEDIUM, HIGH, or CRITICAL severity issue found
   - Increments to 1 when EITHER:
     * Zero issues found (pure clean)
     * Exactly one LOW-severity issue found and fixed (clean with 1 low fix)
   - See `reference/severity_classification_universal.md` for severity definitions
3. **Use `read_file` to read the ENTIRE artifact** every single round — partial reads do not count
4. **Walk through ALL dimensions** (master + scenario-specific) and document each as PASS or ISSUE
5. **Verify ≥3 technical claims** against source code every round using tools (read_file, grep_search)
6. **Never delegate rounds to subagents** — you must do the reads and checks yourself
7. **When `consecutive_clean = 1` (primary clean round): spawn 2 independent sub-agents in parallel** — both must confirm zero issues to complete the exit sequence (see Exit Criteria for the required sub-agent confirmation protocol)
8. **Complete the Adversarial Self-Check** after checking all dimensions in each round — a round may not be scored clean if this step is skipped

**A round where you found multiple issues OR any MEDIUM/HIGH/CRITICAL issue is NOT a clean round — the counter resets to 0. Exception: Exactly 1 LOW-severity issue (fixed) still counts as a clean round.**

🚨🚨🚨 **END OF HARD STOP** 🚨🚨🚨

---

## Table of Contents

1. [Overview](#overview)
2. [When to Use This Protocol](#when-to-use-this-protocol)
3. [Core Validation Process](#core-validation-process)
4. [Universal Dimensions (Master - Always Checked)](#universal-dimensions-master---always-checked)
5. [Round-by-Round Execution](#round-by-round-execution)
   - [Round Structure](#round-structure-every-round)
   - [Adversarial Self-Check](#adversarial-self-check-run-after-all-dimensions-before-post-round-gate)
6. [Open Questions Protocol](#open-questions-protocol)
7. [Documentation Requirements](#documentation-requirements)
8. [Quality Standards](#quality-standards)
9. [Anti-Shortcut Enforcement](#anti-shortcut-enforcement)
10. [Exit Criteria](#exit-criteria)
11. [Real-World Examples](#real-world-examples)
12. [Common Mistakes](#common-mistakes)
13. [How Scenario-Specific Loops Extend This Master](#how-scenario-specific-loops-extend-this-master)
14. [Templates](#templates)


---

## Overview

**What is the Validation Loop?**
The Validation Loop is a systematic quality assurance process that validates artifacts (specs, plans, code, documentation) through iterative rounds until achieving a primary clean round followed by independent sub-agent confirmation.

**Why use Validation Loops?**
- **Prevents cascading failures**: Catch issues early before propagating downstream
- **Eliminates redundant re-verification**: Check all concerns every round (no need to restart)
- **Guarantees quality**: Primary clean round + independent sub-agent confirmation ensures genuine fresh-eyes validation
- **Consistent approach**: Same process across all stages and artifacts

**Key Innovation (from S5 v2):**
- Instead of sequential iterations checking different concerns (S5 v1 had 22 iterations)
- Use validation dimensions checked EVERY round (S5 v2 has 11 dimensions)
- Fix issues immediately, continue validation (no restart from beginning)
- Exit when primary clean round achieved + 2 independent sub-agents confirm zero issues

---

## When to Use This Protocol

**Use Validation Loops for:**
- ✅ Specifications (S2: Feature specs)
- ✅ Plans (S5: Implementation plans)
- ✅ Test strategies (S5 Step 0: Test scope decision)
- ✅ Documentation (S3: Epic documentation)
- ✅ Code quality (S7: QC rounds)
- ✅ Cross-artifact alignment (S8: Spec alignment)
- ✅ Epic-level validation (S9: Epic QC)

**Do NOT use for:**
- ❌ Simple checklists (use regular checklist)
- ❌ One-time verification (use standard review)
- ❌ User approval gates (use approval protocol)

**Typical Timing:**
- After creating draft artifact
- Before user approval gates
- After fixing issues (continue validation)

---

## Core Validation Process

### Fundamental Principles

**1. Zero Deferred Issues**
- ALL issues must be fixed immediately (not "later")
- No severity threshold (ALL levels matter: LOW, MEDIUM, HIGH)
- Cannot proceed to next round with open issues
- Fix → Re-validate → Repeat

**2. Primary Clean Round + Sub-Agent Confirmation Required**
- Round N: 0 issues found ✅ (consecutive_clean = 1 — primary clean round)
- Spawn 2 independent sub-agents in parallel:
  - Sub-agent A: 0 issues ✅
  - Sub-agent B: 0 issues ✅
- **THEN and ONLY THEN**: Exit validation loop

**3. Fresh Eyes Every Round**
- Re-read ENTIRE artifact each round (not from memory)
- Use different reading patterns/perspectives
- Approach as if seeing for first time
- Don't assume previous rounds were thorough

**4. All Dimensions Every Round**
- Check EVERY dimension EVERY round (master + scenario-specific)
- Cannot skip dimensions
- Cannot batch dimensions
- Systematic top-to-bottom review

### Process Flow

```text
┌─────────────────────────────────────────────────────────────┐
│              VALIDATION LOOP PROCESS FLOW                    │
└─────────────────────────────────────────────────────────────┘

Draft Artifact Created
         │
         ▼
    ┌─────────────────┐
    │   ROUND 1       │
    │                 │
    │ Check ALL       │
    │ Dimensions      │
    │ (Master +       │
    │  Specific)      │
    └─────────────────┘
         │
         ├─→ Issues Found? → FIX ALL IMMEDIATELY → Round 2
         │
         └─→ 0 Issues? → Continue to Round 2
                │
                ▼
           ┌─────────────────┐
           │   ROUND 2       │
           │                 │
           │ Re-read ENTIRE  │
           │ artifact with   │
           │ fresh eyes      │
           │                 │
           │ Check ALL       │
           │ Dimensions      │
           └─────────────────┘
                │
                ├─→ Issues Found? → FIX ALL IMMEDIATELY → Counter resets to 0 → Continue to Round N+1
                │
                └─→ 0 Issues? → Counter = 1 (PRIMARY CLEAN ROUND)
                       │
                       ▼
                  ┌──────────────────────────┐
                  │   SUB-AGENT CONFIRMATION │
                  │                          │
                  │ Spawn 2 independent      │
                  │ sub-agents in parallel   │
                  │                          │
                  │ Each checks ALL          │
                  │ Dimensions fresh         │
                  └──────────────────────────┘
                       │
                       ├─→ Either sub-agent finds issues? → FIX ALL → Counter resets to 0 → Continue to Round N+1
                       │
                       └─→ Both sub-agents: 0 Issues? ✅
                              │
                              ▼
                       ┌──────────────┐
                       │   SUCCESS    │
                       │              │
                       │ Primary clean│
                       │ + sub-agent  │
                       │ confirmed    │
                       │              │
                       │ EXIT LOOP    │
                       └──────────────┘
```

**Counter Reset Rule:**
- Clean round counter starts at 0
- Counter increments when round is clean:
  - **Pure Clean:** Zero issues found
  - **Clean (1 Low Fix):** Exactly one LOW-severity issue found and fixed
- Counter resets to 0 when round is NOT clean:
  - Multiple LOW-severity issues found (2+)
  - Any MEDIUM, HIGH, or CRITICAL severity issue found
- Need counter = 1 to exit, then sub-agent confirmation (see Exit Criteria)
- See `reference/severity_classification_universal.md` for severity definitions

**Example (showing severity-based counter logic):**
- Round 1: 5 issues (2 HIGH, 2 MEDIUM, 1 LOW) → Fix all → Counter = 0
- Round 2: 2 issues (2 LOW) → Fix → Counter = 0 (multiple LOW = not clean)
- Round 3: 1 issue (1 LOW typo) → Fix → Counter = 1 (single LOW allowed) → spawn 2 sub-agents
  - Sub-agent A: 1 MEDIUM issue found → Fix → Counter resets to 0
- Round 4: 0 issues → Counter = 1 (pure clean) → spawn 2 sub-agents
  - Sub-agent A: 0 issues ✅
  - Sub-agent B: 0 issues ✅
- ✅ **EXIT**

**Sub-agent exception:** Sub-agents do NOT get the 1 LOW allowance. ANY issue found by a sub-agent (even LOW) resets the counter to 0.

🚨 **MECHANICAL VALIDATION WARNING** 🚨

Signs you are doing mechanical validation (PROHIBITED):
- Checking boxes without using tools
- Saying "verified from previous analysis" without re-reading
- Moving through dimensions quickly without finding any issues
- Cannot point to specific tool calls that verified specific claims

**If 3+ consecutive rounds find zero issues, you MUST:**
1. Re-read entire artifact with `read_file`
2. Pick 5 random technical claims and verify against codebase
3. Look specifically for contradictions, outdated info, wrong examples
4. Only proceed if you can document the verification work done

**Fresh Eyes Enforcement (Required Each Round):**
- [ ] Used `read_file` to re-read ENTIRE artifact (not partial)
- [ ] Changed perspective: read for different concern than previous round
- [ ] Identified at least 3 specific technical claims to verify against codebase
- [ ] Found evidence of careful re-reading (noted different details than previous round)

**If you cannot check all 4 boxes above, you have NOT done proper validation.**

---

## Issue Severity Classification (Universal)

**Full Guide:** `reference/severity_classification_universal.md`

### Quick Reference

| Level | Definition | Clean Round Impact |
|-------|------------|-------------------|
| **CRITICAL** | Blocks workflow or causes cascading failures | Counter resets to 0 |
| **HIGH** | Causes significant confusion or wrong decisions | Counter resets to 0 |
| **MEDIUM** | Reduces quality but doesn't block or confuse | Counter resets to 0 |
| **LOW** | Cosmetic issues with minimal impact | 1 allowed per round |

### Severity Decision Shortcuts

1. **"If this isn't fixed, can workflow complete?"** → NO = CRITICAL
2. **"Will this cause agent or user confusion?"** → YES = HIGH
3. **"Does this reduce quality or usability?"** → YES = MEDIUM
4. **"Is this purely cosmetic?"** → YES = LOW

### Borderline Cases

**When uncertain between two severity levels, classify as the HIGHER severity.**

- LOW vs MEDIUM unclear → Classify as **MEDIUM**
- MEDIUM vs HIGH unclear → Classify as **HIGH**
- HIGH vs CRITICAL unclear → Classify as **CRITICAL**

---

## Universal Dimensions (Master - Always Checked)

These 7 dimensions apply to **ALL** validation loops, regardless of context.

### Dimension 1: Empirical Verification ⚡ CRITICAL

**Question:** Is everything claimed/referenced verified against actual reality (not assumptions)?

**Core Principle:** "Never assume - always verify from source of truth"

**Why This is Dimension 1:**
- If working with made-up facts, nothing else matters
- Must establish reality BEFORE checking completeness/consistency
- Catches issues earlier (before propagating downstream)
- Prevents cascading failures from wrong assumptions

🚨 **MANDATORY TOOL USAGE FOR CODE/FILE CLAIMS** 🚨
- [ ] Use `read_file` to verify ALL code examples, signatures, and patterns against actual source
- [ ] Use `grep_search` or `file_search` to verify ALL file names, paths, and counts
- [ ] Use `list_dir` to verify ALL directory structure claims
- [ ] NEVER verify code/file claims from memory or assumption

**Evidence Required:**
- Document the exact tool calls made for each verification (tool name + file/pattern)
- Copy-paste actual results that confirm or contradict claims
- Update artifact immediately if any verification fails

**Checklist:**

**Code References:**
- [ ] All class names verified from source code (use grep/Read, not memory)
- [ ] All method/function names verified from source code
- [ ] All function signatures copy-pasted from actual code (not paraphrased)
- [ ] All return types verified from source code
- [ ] All parameter types verified from source code (including optional/default values)
- [ ] All exception types verified from source code

**File System:**
- [ ] All file paths verified to exist (use ls/Read, not assumption)
- [ ] All directory paths verified to exist
- [ ] All referenced data files verified to exist (actual ls output)
- [ ] All import paths verified to work (test imports)

**Configuration:**
- [ ] All config keys verified from actual config files (exact key names)
- [ ] All config value types verified (string vs int vs bool)
- [ ] All environment variables verified from actual environment

**External Dependencies:**
- [ ] All library imports verified from requirements.txt or actual imports
- [ ] All version numbers verified from actual installed versions
- [ ] All API endpoints verified from actual API (if applicable)

**Data Structures:**
- [ ] All CSV column names verified from actual files (read header row)
- [ ] All JSON keys verified from actual files (read actual JSON)
- [ ] All database table names verified from schema (if applicable)
- [ ] All field names verified from source of truth

**Evidence Documentation:**
- [ ] Every verified item has source location (file:line)
- [ ] Copy-paste of actual code provided (not summary or paraphrase)
- [ ] Verification method documented (Read tool / grep / ls command)
- [ ] Verification timestamp included
- [ ] No "assumption" or "probably" as verification method

**Common Violations:**

❌ **WRONG - Made-up function signature:**
```markdown
Task 3: Call ConfigManager.get_rank_multiplier(rank: int) -> float
Source: Assumption based on spec description
```

✅ **CORRECT - Verified from source:**
```markdown
Task 3: Call ConfigManager.get_rank_multiplier(rank: int) -> Tuple[float, int]
Source: Verified from [module]/util/ConfigManager.py:234
Verification method: Read tool
Verification timestamp: 2026-02-10 14:30

Actual signature:
    def get_rank_multiplier(self, rank: int) -> Tuple[float, int]:
        """
        Calculate rank multiplier based on rank value.

        Args:
            rank (int): rank value (1-500)

        Returns:
            Tuple[float, int]: (multiplier, rating)
        """
```

❌ **WRONG - Made-up file path:**
```markdown
Load data from: data/priority_rankings.csv
Verification: Not checked (assumed from spec)
```

✅ **CORRECT - Verified path:**
```markdown
Load data from: data/rankings/priority.csv
Verification method: ls command
Verification timestamp: 2026-02-10 14:32

Command: ls -la data/rankings/priority.csv
Output: -rw-r--r-- 1 user user 45832 Feb 10 10:15 data/rankings/priority.csv

Note: Spec mentioned "priority_rankings.csv" but actual file is in rankings/ subdirectory
```

❌ **WRONG - Assumed class name:**
```markdown
Integration: PlayerDataManager.load_players()
Source: Mentioned in epic request as "record manager"
```

✅ **CORRECT - Verified class name:**
```markdown
Integration: RecordManager.load_items()
Source: Verified from [module]/util/RecordManager.py:23
Verification method: grep command

Command: grep -r "class RecordManager" --include="*.py"
Output: [module]/util/RecordManager.py:23:class RecordManager:

Note: Epic request used phrase "record manager" but actual class is RecordManager (no "Data")
```

**Verification Evidence Template:**
```markdown
## Dimension 1: Empirical Verification

**Item:** [Function/Class/File/Config being verified]
**Claimed in artifact:** [What the spec/plan/doc says]
**Verification method:** [Read tool / grep / ls / import test]
**Verification timestamp:** [YYYY-MM-DD HH:MM]
**Source location:** [file:line]
**Actual reality:** [Copy-paste from actual source]
**Match status:** ✅ MATCH / ❌ MISMATCH (updated artifact)
```

---

### Dimension 2: Completeness

**Question:** Are all required sections/elements present per template/checklist?

**Checklist:**

**Structural Completeness:**
- [ ] All mandatory sections present (per template)
- [ ] No "TBD" or "TODO" placeholders remaining
- [ ] No "..." or "etc." without specifics
- [ ] All cross-references point to existing content

**Content Completeness:**
- [ ] All requirements/tasks enumerated (not "and others")
- [ ] All edge cases identified (not "handle errors")
- [ ] All dependencies listed (not "various dependencies")
- [ ] All acceptance criteria defined (not "works correctly")

**Example Completeness:**
- [ ] All examples include expected input AND output
- [ ] All code examples are syntactically complete
- [ ] All examples reference real code/data (verified in Dimension 1)

**Cross-Reference Completeness:**
- [ ] All references to other documents include section/line numbers
- [ ] All "see X" references exist and are correct
- [ ] All links/paths are valid (verified in Dimension 1)

**Common Violations:**

❌ **WRONG - Incomplete requirements:**
```markdown
## Requirements
1. Load record data
2. Calculate scores
3. Handle errors
... (additional requirements TBD)
```

✅ **CORRECT - Complete enumeration:**
```markdown
## Requirements
1. Load record data from CSV
2. Validate record data structure
3. Calculate rank-based scores
4. Apply position-specific adjustments
5. Handle missing data gracefully
6. Handle invalid rank values (< 1 or > 500)
7. Handle file not found errors
8. Log all operations

(8 total requirements - all enumerated)
```

---

### Dimension 3: Internal Consistency

**Question:** Are there any contradictions or conflicts within this artifact?

**Checklist:**

**Statement Consistency:**
- [ ] No contradictory requirements ("must use X" vs "must use Y")
- [ ] No contradictory approaches (sync in one place, async in another)
- [ ] No contradictory data types (string vs int for same field)

**Terminology Consistency:**
- [ ] Same concept uses same term throughout (not "player_count" then "num_players")
- [ ] Abbreviations defined and used consistently
- [ ] Field/variable names consistent throughout

**Example Consistency:**
- [ ] Examples match specifications
- [ ] Code examples use same variable names as spec
- [ ] Sample data matches described structure

**Dependency Consistency:**
- [ ] No circular dependencies (A depends on B, B depends on A)
- [ ] Execution order is possible (no impossible orderings)
- [ ] Prerequisites are consistent with workflow

**Common Violations:**

❌ **WRONG - Contradictory approach:**
```markdown
## Section 1: Data Loading
Use synchronous file reading for predictable timing.

## Section 4: Performance
Use async file reading for better performance.
```

✅ **CORRECT - Consistent approach:**
```markdown
## Section 1: Data Loading
Use synchronous file reading for predictable timing and simpler error handling.

## Section 4: Performance
Optimize synchronous reading with buffering and batch processing.
```

❌ **WRONG - Inconsistent terminology:**
```markdown
## Section 2
Load player_count from config.

## Section 5
Validate that num_players is positive.
```

✅ **CORRECT - Consistent terminology:**
```markdown
## Section 2
Load player_count from config.

## Section 5
Validate that player_count is positive.
```

---

### Dimension 4: Traceability

**Question:** Can every decision/requirement be traced to an authoritative source?

**Checklist:**

**Requirement Traceability:**
- [ ] All requirements cite source (Epic Request / User Answer / Derived)
- [ ] No requirements with "assumption" as source
- [ ] Derived requirements explain derivation logic clearly
- [ ] User answers include question context and date

**Decision Traceability:**
- [ ] All design decisions cite rationale
- [ ] All "why" questions answered with source
- [ ] All trade-offs documented with reasoning
- [ ] All deviations from normal patterns explained

**Source Citation Format:**
- [ ] Epic references include line numbers (e.g., "Epic request line 45")
- [ ] User answer references include question number and date
- [ ] Derived requirements show derivation chain
- [ ] Code references include file:line

**Common Violations:**

❌ **WRONG - No source cited:**
```markdown
## Requirement 5
System must handle timeout after 30 seconds.
```

✅ **CORRECT - Source traced:**
```markdown
## Requirement 5
System must handle timeout after 30 seconds.

**Source:** User Answer to Question 12 (2026-02-08)
**Question:** "What timeout should we use for API calls?"
**Answer:** "30 seconds is standard for our APIs"
```

❌ **WRONG - Assumption as source:**
```markdown
## Requirement 8
Use JSON format for output files.

**Source:** Assumption (most Python projects use JSON)
```

✅ **CORRECT - Proper source or question:**
```markdown
## Requirement 8
Use JSON format for output files.

**Source:** Epic request line 67: "...output should be in JSON format for easy parsing..."
```

**Derived Requirement Example:**
```markdown
## Requirement 12 (Derived)
Log all API calls with timestamps.

**Source:** Derived from Requirements 5 and 9
**Derivation Logic:**
- Requirement 5: Must handle API timeouts
- Requirement 9: Must debug production issues
- Derivation: To debug timeouts in production, we need timestamps of API calls
- Therefore: Log all API calls with timestamps
```

---

### Dimension 5: Clarity & Specificity

**Question:** Is language specific, concrete, and unambiguous (no vague terms)?

**Checklist:**

**Banned Vague Terms:**
- [ ] No "should" (use "must" or "will")
- [ ] No "might" or "may" (specify conditions)
- [ ] No "probably" or "likely" (verify or make definite)
- [ ] No "usually" or "typically" (specify exact behavior)
- [ ] No "appropriate" or "reasonable" (specify criteria)
- [ ] No "etc." or "and so on" (enumerate completely)

**Specific Values Required:**
- [ ] Timeouts specified in seconds (not "reasonable timeout")
- [ ] Counts specified as numbers (not "several" or "many")
- [ ] Ranges specified with min/max (not "between 1 and 10-ish")
- [ ] Percentages exact (not "most" or "almost all")

**Concrete Actions:**
- [ ] Verbs are action-oriented (not "deal with errors")
- [ ] Steps are implementable (not "handle appropriately")
- [ ] Conditions are measurable (not "when ready")

**Unambiguous Language:**
- [ ] "Or" clarified (inclusive or exclusive?)
- [ ] "All" vs "some" explicit
- [ ] Order specified when matters (not "do A and B")

**Common Violations:**

❌ **WRONG - Vague language:**
```markdown
## Task 3
Handle errors appropriately.
Timeout should be reasonable.
Validate input as needed.
```

✅ **CORRECT - Specific language:**
```markdown
## Task 3
Handle errors with try/except blocks:
- FileNotFoundError: Log error, return empty list
- ValueError: Log error, raise with context
- ConnectionError: Retry 3 times with 5-second delays, then raise

Timeout: 30 seconds (per Requirement 5)

Validate input:
- Check rank value is integer between 1 and 500
- Raise ValueError if out of range
```

❌ **WRONG - "Should" instead of "must":**
```markdown
The system should validate record data.
```

✅ **CORRECT - Definitive language:**
```markdown
The system must validate record data before processing.
```

---

### Dimension 6: Upstream Alignment

**Question:** Does this artifact align with its parent/upstream artifacts?

**Checklist:**

**No Scope Creep:**
- [ ] All requirements trace to upstream (no additions)
- [ ] No features/tasks added that weren't requested
- [ ] No "improvements" beyond stated scope
- [ ] Enhancements flagged as optional/future (not required)

**No Missing Scope:**
- [ ] All upstream requirements reflected downstream
- [ ] No upstream items omitted without justification
- [ ] All explicit user requests included
- [ ] All epic goals addressed

**Change Propagation:**
- [ ] Upstream changes reflected in this artifact
- [ ] Version alignment (if upstream updated, this updated)
- [ ] References to upstream are current (not stale)

**Interpretation Accuracy:**
- [ ] Understands upstream intent correctly
- [ ] No misinterpretation of requirements
- [ ] Clarifications from user incorporated

**Common Violations:**

❌ **WRONG - Scope creep:**
```markdown
Epic Request: "Load rank data and calculate multipliers"

Spec Requirements:
1. Load rank data from CSV
2. Calculate multipliers based on rank priority
3. Generate visualization dashboard ← NOT REQUESTED
4. Export to multiple formats ← NOT REQUESTED
```

✅ **CORRECT - Scope match:**
```markdown
Epic Request: "Load rank data and calculate multipliers"

Spec Requirements:
1. Load rank data from CSV (Epic request line 12)
2. Validate rank values (Derived from requirement 1)
3. Calculate multipliers based on rank priority (Epic request line 13)
4. Return multiplier values (Derived from requirement 3)

Future Enhancements (out of scope for this feature):
- Visualization dashboard
- Export to multiple formats
```

❌ **WRONG - Missing scope:**
```markdown
Epic Request: "Handle errors gracefully and log all operations"

Plan Tasks:
1. Implement data loading
2. Implement calculation
← Missing: Error handling (epic requirement)
← Missing: Logging (epic requirement)
```

✅ **CORRECT - Complete scope:**
```markdown
Epic Request: "Handle errors gracefully and log all operations"

Plan Tasks:
1. Implement data loading
2. Implement calculation
3. Implement error handling (Epic requirement line 45)
4. Implement operation logging (Epic requirement line 46)
```

---

### Dimension 7: Standards Compliance

**Question:** Does this follow project conventions, templates, and established patterns?

**Checklist:**

**Template Compliance:**
- [ ] Uses official template structure (not custom format)
- [ ] All template sections present
- [ ] Section ordering matches template
- [ ] Required metadata included (dates, versions, etc.)

**Naming Conventions:**
- [ ] File names follow project pattern (snake_case for Python)
- [ ] Variable names follow codebase style
- [ ] Class names follow conventions (PascalCase for Python)
- [ ] Function names follow conventions (snake_case for Python)

**Code Style Compliance:**
- [ ] Import organization follows project standard (see CODING_STANDARDS.md)
- [ ] Docstring format matches project (Google style)
- [ ] Type hints used where required
- [ ] Error handling follows project patterns

**Documentation Standards:**
- [ ] Headers follow markdown standards
- [ ] Code blocks have language specifiers
- [ ] Lists are consistently formatted
- [ ] Links use proper markdown syntax

**Common Violations:**

❌ **WRONG - Custom format instead of template:**
```markdown
## My Feature Spec

## What it does
...

## How it works
...
```

✅ **CORRECT - Using official template:**
```markdown
## Feature Spec: rank priority Integration

## Discovery Context
...

## Feature Requirements
### Objective
...

### Scope
...

### Components Affected
...
```

❌ **WRONG - Inconsistent naming:**
```markdown
def LoadPlayerData():  # PascalCase (wrong for Python)
    player_count = ...
    numPlayers = ...  # camelCase (inconsistent)
```

✅ **CORRECT - Consistent naming:**
```markdown
def load_record_data():  # snake_case (Python convention)
    """Load record data from CSV file."""
    player_count = ...
    total_players = ...  # snake_case (consistent)
```

---

## Round-by-Round Execution

### Mandatory Pre-Round Gate (EVERY Round)

**Before starting ANY round, verify these 4 conditions. If any fail, STOP and fix before proceeding.**

```text
PRE-ROUND GATE CHECKLIST:
[ ] VALIDATION_LOG.md exists in the artifact folder
[ ] Current consecutive_clean value is written in the log (starts at 0)
[ ] Plan for this round documented: reading pattern, which artifact sections, which claims to spot-check
[ ] Previous round (if any) is fully documented with all dimensions and resolution
```

**If VALIDATION_LOG.md does not exist, create it now using the template in the Documentation Requirements section before proceeding.**

### Round Structure (EVERY Round)

Each round follows these steps in this exact order:

1. **Pre-Round Gate** — verify VALIDATION_LOG.md exists, consecutive_clean is recorded, round plan documented
2. **Re-read entire artifact** — use Read tool, no working from memory, fresh eyes
3. **Check ALL dimensions** — all master dimensions + all scenario-specific dimensions, systematically (1→N)
4. **Tool-Based Verification** — run available automated checks to complement LLM review (see section below)
5. **Adversarial Self-Check** — run after all dimensions, before scoring the round (see section below)
6. **Post-Round Gate** — update VALIDATION_LOG.md, document all dimensions, update consecutive_clean

**Steps 4 and 5 may not be skipped. A round may not be scored clean if either is skipped.**

---

### Tool-Based Verification (Run After Dimensions, Before Adversarial Self-Check)

**Purpose:** Run available automated tools to catch issues that pattern-based LLM review might miss.

**Why This Step Exists:** LLMs can have blind spots for certain mechanical issues (unused imports, type errors, security patterns) that static analysis tools catch reliably. This step ensures deterministic verification complements LLM review.

**Run These Checks (If Project Has Them Configured):**

```text
TOOL VERIFICATION CHECKLIST:
[ ] Linter: `{LINT_COMMAND}` — zero errors required
[ ] Type checker: `mypy`, `tsc --noEmit`, etc. — zero errors required
[ ] Security scanner: `{SECURITY_SCAN_COMMAND}` — zero high-severity findings
[ ] Test suite: `{TEST_COMMAND}` — 100% pass rate required
```

**If no tools are configured:** Document "N/A - no linter/type checker/security scanner configured for this project" in the validation log and proceed.

**What to Document:**
```markdown
## Tool Verification (Round N)

### Linter
- Command: `ruff check .`
- Result: ✅ 0 errors / ⚠️ N errors found
- Issues: [list any issues to fix]

### Type Checker
- Command: `mypy --ignore-missing-imports .`
- Result: ✅ 0 errors / ⚠️ N errors found
- Issues: [list any issues to fix]

### Security Scanner
- Command: `bandit -r src/ -ll`
- Result: ✅ 0 high-severity / ⚠️ N findings
- Issues: [list any issues to fix]

### Tests
- Command: `pytest -v`
- Result: ✅ 100% passing / ⚠️ N failures
- Failures: [list any failures to fix]
```

**If Any Tool Reports Issues:**
- Add issues to this round's issue list
- Fix before scoring the round
- Round cannot be scored clean with tool failures

**This step may NOT be skipped.** Even if all dimensions pass, tool failures constitute validation issues.

---

### Adversarial Self-Check (Run After Tool Verification, Before Post-Round Gate)

For each question below, state the answer explicitly or record it as an open question
if no answer can be found. Answering "nothing found" is only valid after genuinely
working through each question — not after deciding the artifact looks correct.

- **Uncovered scenarios:** "Are there scenarios in this feature/epic that I have not
  considered? What are the edge cases, error states, and non-happy-path flows?"
- **Codebase gaps:** "Is there any part of the codebase I have not read that could be
  relevant to this artifact? What would I find if I looked at [related module / config /
  dependency]?"
- **Emergent questions:** "Based on everything I've found in this round, are there open
  questions I have not yet asked? What would an adversarial reviewer ask about this artifact?"
- **Application interactions:** "How do the different applications, services, or modules
  involved interact with each other? Have I accounted for the seams between them?"
- **Assumption audit:** "What am I assuming to be true that I have not verified? List the
  top 3 unverified assumptions in this artifact."

If any question surfaces a new issue: add it to this round's issue list and fix it before
scoring the round. The round may not be scored clean if the Adversarial Self-Check is skipped.

If any question surfaces an open question that cannot be answered locally: handle it via the
Open Questions Protocol (see below).

---

### Mandatory Post-Round Gate (EVERY Round)

**After completing a round, verify these 6 conditions before moving to the next round.**

```text
POST-ROUND GATE CHECKLIST:
[ ] VALIDATION_LOG.md updated with this round's full results
[ ] ALL dimensions documented (PASS or ISSUE for each — 7 master + scenario-specific)
[ ] ≥3 technical claims verified with tool evidence documented in log
[ ] Full artifact re-read evidenced (read_file calls covering line 1 through end)
[ ] Tool-Based Verification completed (linter, type checker, tests — or "N/A" documented)
[ ] Adversarial Self-Check completed (all 5 questions answered or recorded as open questions)
[ ] consecutive_clean updated correctly:
    - If ANY issues found this round → consecutive_clean = 0 (even if you fixed them)
    - If ZERO issues found → consecutive_clean = previous + 1
```

**Do NOT proceed to the next round until all 6 boxes are checked.**

---

### Round 1: Initial Validation

**Purpose:** First systematic check of all dimensions

**Process:**
1. **Re-read entire artifact** (use Read tool, don't work from memory)
2. **Check each dimension sequentially** (1→2→3→4→5→6→7)
3. **Document findings** in validation log
4. **Categorize issues** by dimension and severity

**Documentation:**
```markdown
## Round 1 Results

**Timestamp:** 2026-02-10 15:00
**Artifact:** feature_02_spec.md (v1.0)

### Dimension 1: Empirical Verification
- ❌ ISSUE 1 (HIGH): Function signature assumed, not verified
  - Location: Section 3.2, line 45
  - Problem: Claims ConfigManager.get_rank() returns float
  - Reality: Returns Tuple[float, int] per ConfigManager.py:234
  - Fix: Update section 3.2 with correct signature

- ❌ ISSUE 2 (MEDIUM): File path not verified
  - Location: Section 2.1, line 12
  - Problem: References data/priority.csv
  - Reality: Actual path is data/rankings/priority.csv (verified with ls)
  - Fix: Update file path

### Dimension 2: Completeness
- ✅ PASS: All sections present

### Dimension 3: Internal Consistency
- ❌ ISSUE 3 (LOW): Inconsistent terminology
  - Location: Sections 2.1 and 4.3
  - Problem: Uses both "player_count" and "num_players"
  - Fix: Standardize on "player_count"

... (continue for all 7 dimensions)

**Round 1 Summary:**
- Total issues found: 8
- HIGH: 2, MEDIUM: 3, LOW: 3
- Issues must be fixed before Round 2
- Clean round counter: 0
```

**After Round 1:**
- Fix ALL issues immediately (no deferring)
- Update artifact
- Prepare for Round 2

---

### Round 2: Fresh Eyes Validation

**Purpose:** Re-validate with fresh perspective after fixes

**Process:**
1. **CRITICAL: Re-read ENTIRE artifact** (don't skip to changed sections)
2. **Use different reading pattern** (bottom-up, random spot-checks, etc.)
3. **Check ALL dimensions** (not just ones with issues in Round 1)
4. **Look for cross-cutting impacts** (did fix in Section 2 affect Section 5?)

**Fresh Eyes Techniques:**
- Read in reverse order (last section to first)
- Read out of sequence (random sections)
- Focus on different aspects (data flow vs error handling)
- Pretend you've never seen this before

**Documentation:**
```markdown
## Round 2 Results

**Timestamp:** 2026-02-10 15:45
**Artifact:** feature_02_spec.md (v1.1 - after Round 1 fixes)
**Reading pattern:** Bottom-up (Section 5→4→3→2→1)

### Dimension 1: Empirical Verification
- ✅ PASS: All issues from Round 1 fixed and verified
- ❌ ISSUE 9 (MEDIUM): New discovery - missed in Round 1
  - Location: Section 4.5, line 89
  - Problem: References PlayerDataManager class
  - Reality: Actual class is RecordManager (verified grep)
  - Fix: Update class name

### Dimension 2: Completeness
- ✅ PASS: Complete

... (continue for all 7 dimensions)

**Round 2 Summary:**
- Total issues found: 2 (new issues, not from Round 1)
- HIGH: 0, MEDIUM: 2, LOW: 0
- Issues must be fixed
- Clean round counter: RESETS to 0 (issues found)
```

**If issues found:**
- Fix ALL issues
- **Counter resets to 0**
- Continue to Round 3

**If 0 issues:**
- Counter = 1
- Continue to Round 3

---

### Round 3+: Achieving Clean Rounds

**Purpose:** Continue validation until primary clean round + sub-agent confirmation

**Process (same as Round 2):**
1. Re-read entire artifact with fresh eyes
2. Use different reading pattern
3. Check ALL dimensions
4. Document findings

**Counter Logic:**

**Scenario A: Issue found in first clean attempt**
```markdown
Round 1: 8 issues → Fix → Counter = 0
Round 2: 2 issues → Fix → Counter = 0
Round 3: 1 issue → Fix → Counter = 0  ← RESET
Round 4: 0 issues → Counter = 1 → spawn 2 sub-agents
  Sub-agent A: 1 issue → Fix → Counter = 0  ← RESET
Round 5: 0 issues → Counter = 1 → spawn 2 sub-agents
  Sub-agent A: 0 issues ✅  Sub-agent B: 0 issues ✅
✅ EXIT
```

**Scenario B: Clean primary round, clean sub-agents on first try**
```markdown
Round 1: 5 issues → Fix → Counter = 0
Round 2: 0 issues → Counter = 1 → spawn 2 sub-agents
  Sub-agent A: 0 issues ✅  Sub-agent B: 0 issues ✅
✅ EXIT
```

**Maximum Rounds:**
- No hard maximum (continue until primary clean round + sub-agent confirmation)
- Typical: 4-7 rounds total
- If exceeding 10 rounds: Re-evaluate approach (may need to redesign artifact)

---

## Open Questions Protocol

An open question is any question raised during a validation round that the agent
cannot confidently answer from information already gathered.

### At the end of each round:

**Step 1 — Categorize open questions**
For each open question from this round:
- Type A: Answerable by codebase research (a specific file, function, or config not yet read)
- Type B: Requires user input (a product decision, an external constraint, a business rule)

If a question is ambiguous (could be Type A or Type B): treat it as Type A and attempt
research first. Only escalate to Type B if the research confirms no answer exists in the
codebase.

**Step 2 — Resolve Type A questions before stating the round result**
If any Type A questions exist: do the research now, within this round. Read the relevant
files and update the round's findings before scoring the round clean or not-clean.

A round may not be scored as clean if Type A questions remain unresearched.

**Step 3 — Pause for Type B questions before starting the next round**
If any Type B questions remain after Step 2:
- Do NOT start the next round
- Present the open questions to the user clearly, grouped by topic
- Explain why each question blocks the next round (what dimension or decision it affects)
- Wait for user input before proceeding
- When the user answers: incorporate those answers explicitly in all dimensions of the
  next round, not just the dimension that raised the question
- **If the user's answer requires significant plan changes**: restart **the validation loop from Round 1**
  (i.e., Round 1 of Phase 2 — do not redo Phase 1/draft creation unless the answer
  fundamentally invalidates the draft itself) and reset the `consecutive_clean` to 0. Minor
  clarifications that don't change the plan do not require a restart.

  **"Significant" means any of:**
  - The answer affects 3 or more tasks in the implementation plan
  - The answer changes the core approach or algorithm (regardless of task count)
  - The answer invalidates a claim verified in a prior clean round (e.g., a "verified"
    interface is now wrong, a "confirmed" assumption was false)

  If none of these apply, treat the answer as a minor clarification and continue without
  restarting.
- **If the user is unavailable:** record the open questions in Agent Status under
  "Blocked: awaiting user input on [question summary]" and suspend the loop. Resume when
  the user returns and provides answers.

**Step 4 — No Type B questions: continue normally**
If no Type B questions remain after Steps 2 and 3: proceed to the next round.

---

## Documentation Requirements

### Validation Log Template

**File:** `{artifact_name}_VALIDATION_LOG.md`

**Structure:**
```markdown
## Validation Loop Log: {Artifact Name}

**Artifact:** {file name and version}
**Validation Start:** {YYYY-MM-DD HH:MM}
**Validation End:** {YYYY-MM-DD HH:MM}
**Total Rounds:** {N}
**Final Status:** ✅ PASSED (primary clean round + sub-agent confirmation)

---

## Round 1

**Timestamp:** {YYYY-MM-DD HH:MM}
**Reading Pattern:** Sequential (top to bottom)
**Artifact Version:** v1.0

**Round X Documentation Required:**
- **Artifacts re-read:** [List of read_file calls made]
- **Technical claims verified:** [List of grep_search/file_search calls made]
- **Specific findings:** [What new details did you notice this round?]
- **Fresh eyes evidence:** [How did you approach differently than last round?]
- **Tools used:** [Document every verification tool call with file/pattern]

### Dimension 1: Empirical Verification
[Checklist items with ✅ PASS or ❌ ISSUE]

### Dimension 2: Completeness
[Checklist items]

... (all 7 master dimensions)

### Scenario-Specific Dimensions
[If applicable - e.g., S5 has 5 additional dimensions]

**Round 1 Summary:**
- Total Issues: {N}
- Severity Breakdown: HIGH: {N}, MEDIUM: {N}, LOW: {N}
- Clean Round Counter: {0-1}
- Next Action: Fix {N} issues, proceed to Round 2

---

## Round 2

**Timestamp:** {YYYY-MM-DD HH:MM}
**Reading Pattern:** Bottom-up
**Artifact Version:** v1.1 (after Round 1 fixes)

[Same structure as Round 1]

---

## Round N (Final Clean Round)

**Timestamp:** {YYYY-MM-DD HH:MM}
**Reading Pattern:** Random spot-checks
**Artifact Version:** v1.X

### All Dimensions: ✅ PASS

**Round N Summary:**
- Total Issues: 0 ✅
- Clean Round Counter: 1 ✅ (primary clean round)
- Sub-agent A: 0 issues ✅
- Sub-agent B: 0 issues ✅
- Status: VALIDATION COMPLETE

---

## Validation Summary

**Total Rounds:** {N}
**Total Issues Found:** {N}
**Total Issues Fixed:** {N}
**Exit Condition:** Primary clean round + sub-agent confirmation ✅

**Issue Breakdown by Dimension:**
- Dimension 1 (Empirical Verification): {N} issues
- Dimension 2 (Completeness): {N} issues
- Dimension 3 (Internal Consistency): {N} issues
- Dimension 4 (Traceability): {N} issues
- Dimension 5 (Clarity): {N} issues
- Dimension 6 (Upstream Alignment): {N} issues
- Dimension 7 (Standards): {N} issues

**Time Spent:**
- Round 1: {X} minutes
- Round 2: {X} minutes
- ...
- Total: {X} hours

**Lessons Learned:**
- [Most common issue type]
- [Patterns noticed]
- [Process improvements for next validation]
```

---

### Compact Format (Default)

The compact format is the **default** for all validation logs. Verbose prose remains available for complex multi-step issues where a table cell cannot capture the nuance.

**Scope:** Applies regardless of filename — `VALIDATION_LOG.md`, `S8_ALIGNMENT_VALIDATION_{feature_NN}.md`, or any other loop log file.

```markdown
## Validation Loop Log: {Artifact Name}

**Artifact:** {file name and version}
**Validation Start:** {YYYY-MM-DD HH:MM}
**Validation End:** {YYYY-MM-DD HH:MM}
**Total Rounds:** {N}
**Final Status:** ✅ PASSED (primary clean round + sub-agent confirmation)

---

| # | Pattern | D1 | D2 | D3 | D4 | D5 | D6 | D7 | {extra dims} | Issues | Counter |
|---|---------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:---:|--------|:-------:|
| 1 | Sequential | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | D8✅ D9❌ | 3 found + fixed | 0 |
| 2 | Reverse | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | All ✅ | 0 (adv-check clean) | 1 → spawn |

**Sub-agents (Round 2):**
- Agent A: 0 issues ✅
- Agent B: 0 issues ✅ → EXIT

**Issue Notes:**
- R1-D3: {brief description + tool call evidence — e.g., "Read s2_primary_guide.md:45 — step references file that no longer exists"}
- R1-D6: {brief description + tool call evidence}

**Spot-check Notes (clean rounds):**
- R2: Read {file}:{line}, Grep {pattern} → {N} matches ✅
```

**Rules:**

- **Adversarial check:** Inline the result in the Issues column as `0 (adv-check clean)` when it surfaces no issues. If it surfaces an issue, log it as a normal issue (increments the issue count and resets `consecutive_clean`).
- **Tool call evidence:** Each ❌ dimension entry **must** cite the specific tool call that found the issue in Issue Notes (e.g., `Read file.md:45`, `Grep "pattern" → 3 matches`). This preserves the ≥3 technical claims requirement.
- **Clean round tool evidence:** Each clean round must have ≥1 tool call citation in Spot-check Notes (preserves verification, not just assertion).
- **Extra dimensions:** Scenario-specific dimensions (e.g., S5's D8–D12) appear in the `{extra dims}` column. List them inline as `D8✅ D9❌` or `All ✅` if all pass.
- **Verbose fallback:** For a complex issue that requires multi-step explanation, add a prose block under Issue Notes below the table entry rather than forcing it into the table.

---

## Quality Standards

### Issue Severity Classification

**Full Guide:** `reference/severity_classification_universal.md`

**CRITICAL Severity:**
- Blocks workflow (broken file paths, missing required files)
- Policy violations (CLAUDE.md >40K characters)
- Template errors that propagate (broken template = all new epics broken)
- Safety issues (incorrect git commands, data loss risks)

**HIGH Severity:**
- Made-up facts (Dimension 1 violations)
- Missing critical requirements (Dimension 2)
- Logic contradictions (Dimension 3)
- No source for requirements (Dimension 4)
- Unusable/unimplementable (Dimension 5)
- Scope creep or missing scope (Dimension 6)

**MEDIUM Severity:**
- Minor verification gaps (class name wrong but similar)
- Missing optional sections
- Terminology inconsistencies
- Vague language that could be interpreted
- Minor deviations from templates

**LOW Severity:**
- Formatting inconsistencies
- Typos that don't affect meaning
- Style guideline deviations
- Documentation formatting

**ALL severity levels must be fixed** (no "we'll fix LOW later").

### Clean Round Status

| Status | Definition | Counter Action |
|--------|------------|----------------|
| **Pure Clean** | 0 issues found | Increment |
| **Clean (1 Low Fix)** | Exactly 1 LOW issue found and fixed | Increment |
| **Not Clean** | 2+ LOW issues OR any MEDIUM/HIGH/CRITICAL | Reset to 0 |

Document clean round status in validation log:
```markdown
**Round N Summary:**
- Total Issues: {0 or 1}
- Severity Breakdown: CRITICAL: 0, HIGH: 0, MEDIUM: 0, LOW: {0 or 1}
- Clean Round Status: **Pure Clean** ✅ / **Clean (1 Low Fix)** ✅ / **Not Clean** ❌
- consecutive_clean: {N}
```

### Reading Patterns for Fresh Eyes

**Round 1:** Sequential (top to bottom)
**Round 2:** Reverse (bottom to top)
**Round 3:** Random spot-checks (different sections)
**Round 4:** Perspective shift (from user POV, from implementer POV)
**Round 5+:** Combination approaches

### Time Expectations

**Per Round:**
- Short artifacts (specs): 15-20 minutes
- Medium artifacts (plans): 30-40 minutes
- Long artifacts (epic docs): 45-60 minutes

**Total Validation:**
- Typical: 4-7 rounds × per-round time
- Example (medium artifact): 5 rounds × 35 min = ~3 hours
- Includes fix time between rounds

---

🎯 **SPOT-CHECK REQUIREMENT (Technical Documents)** 🎯

Before declaring validation complete, agent MUST:
- [ ] Select 3 random code examples and verify exact syntax against source
- [ ] Select 3 random file/directory references and verify existence  
- [ ] Select 3 random version numbers and verify against package files
- [ ] Document the specific spot-checks performed (what was verified, which tool used)
- [ ] Any failures restart validation counter to 0

---

## Anti-Shortcut Enforcement

**These rules address the 6 most common ways agents shortcut validation loops.**

### Shortcut 1: "Fixed = Clean"
**What agents do:** Find 3 issues in Round 2, fix them all, then count Round 2 as consecutive_clean = 1.
**Why it's wrong:** A round where issues were found is NOT clean, regardless of whether you fixed them. The fix could have introduced new issues. You need a FRESH round with zero discoveries.
**Rule:** `consecutive_clean` only increments on rounds where you found ZERO issues across ALL dimensions.

### Shortcut 2: "Partial Re-Read"
**What agents do:** Read only the sections they changed, or only sections 200-400 of a 500-line artifact.
**Why it's wrong:** Fresh eyes means re-reading the ENTIRE artifact. Fixes in one section can create inconsistencies in another section you didn't re-read.
**Rule:** Every round must use `read_file` covering line 1 through the last line. For artifacts >200 lines, use 2-3 sequential reads covering all content.

### Shortcut 3: "Organic Dimension Checking"
**What agents do:** Find 2 issues while reading, fix them, and declare "all dimensions checked" without actually walking the dimension checklists.
**Why it's wrong:** Walking the checklist for each dimension catches issues that casual reading misses. If you only find issues "organically," you're not checking the dimensions you DIDN'T find issues in.
**Rule:** After reading the artifact, walk through each dimension's checklist items one by one. Document PASS or ISSUE for EACH dimension in the log.

### Shortcut 4: "Delegated Validation"
**What agents do:** Use subagents to run validation rounds, or ask a subagent to "verify these 5 claims."
**Why it's wrong:** Subagents don't have the context of previous rounds. They can't provide "fresh eyes" because they've never seen the artifact before — they provide "no eyes." The point is that YOU re-read with a different perspective.
**Rule:** The agent running the validation loop must do ALL reads and checks itself. Subagents are never used for validation rounds.

### Shortcut 5: "No Log File"
**What agents do:** Run validation rounds in their head (or in conversation), never create the required VALIDATION_LOG.md file.
**Why it's wrong:** Without a log, there's no evidence the validation happened, no way to verify the consecutive_clean, and no audit trail. The log also forces the agent to be systematic.
**Rule:** `VALIDATION_LOG.md` MUST be created BEFORE Round 1. Each round must be documented in it before proceeding to the next round.

### Shortcut 6: "3-Round Express"
**What agents do:** Run exactly 3 rounds, find issues in Rounds 1-2, declare Round 3 clean, exit.
**Why it's wrong:** If you found issues in Rounds 1 and 2, you need a primary clean round + sub-agent confirmation AFTER the last round with issues. Once the first fully clean round is achieved, spawn 2 independent sub-agents; both must confirm zero issues. Typical validation is 4-7 rounds total.
**Rule:** `consecutive_clean` must reach 1 (then sub-agent confirmation completes the exit). If issues were found in Rounds 1 and 2, the earliest possible exit is after Round 3 (clean) + sub-agent confirmation.

---

## Exit Criteria

**Minimum standard:** Primary clean round + sub-agent confirmation with all dimensions passing and all
exit criteria met.

**Sub-agent confirmation trigger (when `consecutive_clean = 1`):**
When the primary clean round is achieved, proceed immediately to spawn 2 independent sub-agents
per the Sub-Agent Confirmation Protocol below. No user checkpoint is required before running
sub-agents — the sub-agent step IS the exit gate.

If either sub-agent finds issues: fix immediately, reset `consecutive_clean = 0`, and continue
validation until a new primary clean round + sub-agent confirmation is achieved.

**Interaction with the 10-round re-evaluation threshold:**
If round 10+ is reached without achieving a primary clean round, present a single checkpoint
to the user:

> "Round 10 reached (re-evaluation threshold) without achieving a primary clean round.
> Three options:
> (a) Accept the artifact now — you are satisfied that the remaining issues are not blocking.
> (b) Continue validation — you are explicitly authorizing proceeding past the 10-round threshold.
> (c) Re-evaluate the artifact — the number of rounds needed suggests a structural issue
>     worth addressing before proceeding."

Option (a) requires explicit user authorization; silence or a vague acknowledgment does not
count.

**Validation Loop is COMPLETE when ALL of the following are true:**

- [ ] Primary agent declared a clean round (consecutive_clean = 1) AND both sub-agents independently confirmed zero issues
- [ ] All 7 master dimensions checked every round
- [ ] All scenario-specific dimensions checked every round
- [ ] Validation log complete with all rounds documented
- [ ] Final artifact version tagged/noted
- [ ] Summary section completed in validation log

### Sub-Agent Confirmation Protocol

When `consecutive_clean = 1` (primary clean round achieved):

1. **Spawn 2 independent sub-agents in parallel**
2. **Sub-agent A**: Re-reads artifact top-to-bottom, checks all master + scenario dimensions
3. **Sub-agent B**: Re-reads artifact bottom-to-top (or in different order), checks all dimensions
4. **Both must report zero issues** to complete the exit sequence
5. **If either sub-agent finds an issue**: Fix immediately, reset `consecutive_clean = 0`, continue validation

**Fallback (when sub-agents unavailable):** If the workflow environment cannot spawn sub-agents, fall back to the old exit standard: 3 consecutive clean rounds from the primary agent alone.

**Cannot exit if:**
- Sub-agent confirmation not yet completed
- Either sub-agent found any issue
- ❌ Skipped any dimensions in any round
- ❌ Deferred any issues (even LOW severity)
- ❌ Worked from memory (didn't re-read)
- ❌ Last round found issues without fixing them all

---

## Real-World Examples

### Example 1: Clean First-Pass (Feature 02 — Rigorous Implementation)
- **Rounds:** 3 total (all clean)
- **Why:** Granular implementation checklist, test-first development, requirements traceability
- **Key:** Upfront rigor (97 tests, line-item tracking) reduced validation to minimum rounds
- **Takeaway:** "Typical 4-7 rounds" assumes issues to find. Rigorous implementation can achieve 3 clean rounds on first pass.

### Example 2: Shortcut Caught → Restart → Proper Validation (Feature 03)
- **Failed attempt:** 4 "rounds" with 0 read_file calls, 0 grep_search calls. Agent declared "3 clean rounds." User caught immediately.
- **Proper attempt (after restart):** 5 rounds, 23 read_file calls, 8 grep_search calls. Found 5 real issues. 3 consecutive clean rounds (Rounds 3-5).
- **Takeaway:** Validation without tool usage evidence is always fake. The restart found 5 real issues that the shortcut missed.

### Example 3: Shortcut Missed Security Vulnerability (Feature 01)
- **Failed attempt:** "Checkbox" validation missed path traversal vulnerability in file serving endpoint.
- **Proper attempt (after restart with fresh eyes):** Found and fixed critical security bug (path traversal allowing read of any backend file).
- **Takeaway:** Fake validation doesn't just miss code quality issues — it misses security vulnerabilities.

---

## Common Mistakes

### Mistake 1: Skipping Dimension 1 (Empirical Verification)

❌ **WRONG:**
```markdown
Round 1 Check:
- Dimension 2 (Completeness): ✅ PASS
- Dimension 3 (Consistency): ✅ PASS
[Skipped Dimension 1 - "looks fine"]
```

✅ **CORRECT:**
```markdown
Round 1 Check:
- Dimension 1 (Empirical Verification):
  - [ ] Verified ConfigManager.get_rank() signature from source
  - [ ] Verified file path data/rankings/priority.csv exists
  - [ ] Verified RecordManager class name from grep
  - Result: ❌ 2 issues found (wrong signature, wrong path)
```

**Why this matters:** Dimension 1 violations cascade (if function signature is wrong, everything depending on it is wrong)

---

### Mistake 2: Working from Memory Instead of Re-Reading

❌ **WRONG:**
```markdown
Round 3:
"I remember fixing Section 3.2 in Round 1, so I'll skip reading it again.
Just checking new sections..."
```

✅ **CORRECT:**
```markdown
Round 3:
"Re-reading ENTIRE artifact from beginning, even sections I know I fixed.
Using bottom-up reading pattern for fresh perspective..."
```

**Why this matters:** Fresh eyes catch issues missed when working from memory

---

### Mistake 3: Deferring LOW Severity Issues

❌ **WRONG:**
```markdown
Round 2 Summary:
- HIGH issues: 0
- MEDIUM issues: 0
- LOW issues: 3 (formatting, will fix later)
- Counter: 1 ✅ [WRONG - issues still exist]
```

✅ **CORRECT:**
```markdown
Round 2 Summary:
- HIGH issues: 0
- MEDIUM issues: 0
- LOW issues: 3 (formatting - MUST FIX NOW)
- Fix all 3 LOW issues
- Counter: RESETS to 0 (issues found)
```

**Why this matters:** Zero deferred issues principle - ALL issues matter

---

### Mistake 4: Not Resetting Counter When Issues Found

❌ **WRONG:**
```markdown
Round 3: 1 issue found → Fixed
Round 4: 0 issues
Counter: 1 [then immediately declares EXIT without sub-agent confirmation]
```

✅ **CORRECT:**
```markdown
Round 3: 1 issue found → Fixed
Counter: RESETS to 0
Round 4: 0 issues → Counter = 1 (primary clean round) → spawn 2 sub-agents
  Sub-agent A: 0 issues ✅  Sub-agent B: 0 issues ✅
EXIT ✅
```

---

### Mistake 5: Batching Dimensions Instead of Checking All

❌ **WRONG:**
```markdown
Round 1: Check Dimensions 1-3
Round 2: Check Dimensions 4-7
[Never check all dimensions in single round]
```

✅ **CORRECT:**
```markdown
Round 1: Check ALL 7 dimensions + scenario-specific
Round 2: Check ALL 7 dimensions + scenario-specific
Round 3: Check ALL 7 dimensions + scenario-specific
```

**Why this matters:** Issues can span dimensions (fixing D1 might affect D6)

---

## How Scenario-Specific Loops Extend This Master

### Extension Pattern

**All scenario-specific validation loops:**
1. **Reference this master protocol** ("See validation_loop_master_protocol.md")
2. **Inherit all 7 master dimensions** (always checked)
3. **Add 4-11 scenario-specific dimensions** (context-dependent)
4. **Total dimensions: 11-18** per scenario

### Example: S5 Implementation Planning Loop

**Full Guide:** `stages/s5/s5_v2_validation_loop.md` — 18 total dimensions per round (7 master + 11 S5-specific) covering requirements coverage, interface verification, algorithm traceability, task quality, data flow, error handling, integration, test coverage, performance, implementation readiness, and spec alignment.

## Templates

### Quick Checklist Template (Per Round)

```markdown
## Round {N} Checklist

**Master Dimensions:**
- [ ] D1: Empirical Verification (everything verified from source)
- [ ] D2: Completeness (all sections present)
- [ ] D3: Internal Consistency (no contradictions)
- [ ] D4: Traceability (all decisions sourced)
- [ ] D5: Clarity & Specificity (no vague language)
- [ ] D6: Upstream Alignment (matches parent artifacts)
- [ ] D7: Standards Compliance (follows templates)

**Scenario-Specific Dimensions:**
- [ ] D8: [Scenario dimension 1]
- [ ] D9: [Scenario dimension 2]
... (as applicable)

**Round Result:**
- Total Issues: {N}
- Severity Breakdown: CRITICAL: {N}, HIGH: {N}, MEDIUM: {N}, LOW: {N}
- Clean Round Status: **Pure Clean** / **Clean (1 Low Fix)** / **Not Clean**
- consecutive_clean: {N}
- Next Action: [Fix issues / Continue to next round / Trigger sub-agents / EXIT]
```

### Issue Tracking Template

```markdown
## Issue {N}

**Dimension:** [1-7 or scenario-specific]
**Severity:** [CRITICAL / HIGH / MEDIUM / LOW]
**Severity Rationale:** [Why this severity level? 1-2 sentences]
**Location:** [Section, line number]
**Found in Round:** {N}

**Problem:**
[What is wrong]

**Expected:**
[What should it be]

**Fix:**
[How to fix it]

**Verification:**
[How to verify fix]

**Fixed:** [ ] Yes [Timestamp]
**Verified in Round:** {N}
```

### Round Summary Template

```markdown
**Round {N} Summary:**
- Total Issues: {0, 1, or N}
- Severity Breakdown: CRITICAL: {N}, HIGH: {N}, MEDIUM: {N}, LOW: {N}
- Clean Round Status:
  * **Pure Clean** (0 issues found) ✅
  * **Clean (1 Low Fix)** (1 LOW-severity issue found & fixed) ✅
  * **Not Clean** (2+ LOW OR any MEDIUM/HIGH/CRITICAL) ❌
- Issues Fixed This Round: [List if any]
- consecutive_clean: {N}
- Next Action: [Continue / Trigger sub-agents / EXIT]
```

---

*End of Master Validation Loop Protocol v2.4 (SHAMT-24)*
