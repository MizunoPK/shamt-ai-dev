# Validation Loop: S9 Epic QC

**Extends:** Master Validation Loop Protocol
**See:** `reference/validation_loop_master_protocol.md`

**Applicable Stages:**
- S9.P2: Epic QC Validation Loop (post-feature epic validation)

**Version:** 2.0 (Created to extend master protocol)
**Last Updated:** 2026-02-10

---

🚨 **BEFORE STARTING: Read the Hard Stop section at the top of `reference/validation_loop_master_protocol.md`** 🚨

---

## Table of Contents

1. [Model Selection for Token Optimization (SHAMT-27)](#model-selection-for-token-optimization-shamt-27)
2. [Overview](#overview)
3. [Master Dimensions (7) - Always Checked](#master-dimensions-7---always-checked)
4. [S9 Epic QC Dimensions (6) - Context-Specific](#s9-epic-qc-dimensions-6---context-specific)
5. [Total Dimensions: 13 (+1 Optional)](#total-dimensions-13-1-optional)
6. [What's Being Validated](#whats-being-validated)
7. [Fresh Eyes Patterns Per Round](#fresh-eyes-patterns-per-round)
8. [Common Issues in S9 QC Context](#common-issues-in-s9-qc-context)
9. [Exit Criteria](#exit-criteria)
10. [Integration with S9](#integration-with-s9)

---

## Model Selection for Token Optimization (SHAMT-27)

S9 Epic QC validation can save 35-45% tokens through delegation (13 dimensions):

```text
Primary Agent (Opus):
├─ Spawn Haiku → Run full test suite, count features/files
├─ Spawn Sonnet → Read cross-feature integration code, check consistency patterns
├─ Primary handles → 13-dimension validation, architectural alignment, cohesion analysis
├─ Primary writes → Validation log, epic lessons learned
├─ Spawn Haiku (2x in parallel) → Sub-agent confirmations
└─ Primary completes → Exit after both confirm zero issues
```

**See:** `reference/model_selection.md` for Task tool examples.

---

## Overview

**Purpose:** Validate epic as a cohesive whole after all features complete

**What this validates:**
- All features working together as integrated system
- Cross-feature integration points
- Epic-wide architectural consistency
- Original epic goals achieved
- Ready for user testing

**Quality Standard:**
- All features integrated correctly
- Consistent patterns across features
- Original epic success criteria met
- Zero cross-feature issues
- Ready for S9.P3 (User Testing)

**Uses:** All 7 master dimensions + 6 S9 epic-specific dimensions = 13 total (+1 optional security scan dimension)

---

## Master Dimensions (7) - Always Checked

**See `reference/validation_loop_master_protocol.md` for complete checklists.**

These universal dimensions apply to S9 Epic QC validation:

### Dimension 1: Empirical Verification
- [ ] All cross-feature interfaces verified from actual source code
- [ ] All integration points verified to exist (file:line references)
- [ ] All test commands verified to work (100% pass rate confirmed)
- [ ] All epic requirements traced to actual implementations

### Dimension 2: Completeness
- [ ] All features complete and integrated
- [ ] All cross-feature integration points implemented
- [ ] All epic success criteria implemented
- [ ] All error handling across features complete
- [ ] All edge cases across features handled

### Dimension 3: Internal Consistency
- [ ] No contradictions between features
- [ ] Naming conventions consistent across features
- [ ] Error handling approach consistent across features
- [ ] Coding patterns consistent across features
- [ ] Architectural patterns compatible

### Dimension 4: Traceability
- [ ] Every feature traces to epic requirement
- [ ] All integration points documented with source/destination
- [ ] All tests trace to requirements
- [ ] No orphan features (features without epic justification)

### Dimension 5: Clarity & Specificity
- [ ] No vague error messages across features
- [ ] Consistent logging format across features
- [ ] Clear naming conventions consistent across features
- [ ] Specific success criteria verification

### Dimension 6: Upstream Alignment
- [ ] Implementation matches original epic request (`.shamt/epics/requests/{epic_name}.txt`)
- [ ] All original user goals achieved
- [ ] All acceptance criteria met
- [ ] No scope creep (no unrequested features)

### Dimension 7: Standards Compliance
- [ ] Follows project coding standards across all features
- [ ] Follows project structure/organization
- [ ] Uses project utilities consistently
- [ ] Import organization consistent across features
- [ ] Error handling follows project patterns

---

## S9 Epic QC Dimensions (6) - Context-Specific

These 5 dimensions are specific to S9.P2 Epic QC validation:

### Dimension 8: Cross-Feature Integration

**Question:** Do features integrate correctly with each other?

**Checklist:**

**Integration Point Verification:**
- [ ] All integration points between features identified
- [ ] All interface contracts verified (method signatures match)
- [ ] Data flow verified between all features
- [ ] Error propagation tested across feature boundaries

**Data Exchange:**
- [ ] Data structures compatible across features
- [ ] Data validation present at feature boundaries
- [ ] Data transformation correct between features
- [ ] Shared resources accessed correctly by all features

**Example Verification:**
```python
## Integration: Feature 01 -> Feature 02
from feature_01.RecordManager import DataRecordDataManager
from feature_02.RatingSystem import RatingSystem

## Verify data flows correctly
items = PlayerDataManager().get_all_items()
rated_players = RatingSystem().apply_ratings(items)

## Verify no data loss
assert len(rated_players) == len(items)
assert all(hasattr(p, 'rating') for p in rated_players)
```

---

### Dimension 9: Epic Cohesion

**Question:** Is the epic architecturally cohesive and consistent?

**Checklist:**

**Code Style Consistency:**
- [ ] Import style consistent across features
- [ ] Naming conventions consistent (snake_case, PascalCase)
- [ ] Docstring style consistent (Google style)
- [ ] Logging format consistent

**Pattern Consistency:**
- [ ] Design patterns compatible across features
- [ ] Similar operations use similar approaches
- [ ] Configuration access consistent
- [ ] Resource management consistent

**Common Violations:**

Wrong - Inconsistent patterns:
```python
## Feature 01: get_all_items()
## Feature 02: get_rated_players()  # Consistent
## Feature 03: fetch_recommendations()  # Different pattern
```

Correct - Consistent patterns:
```python
## Feature 01: get_all_items()
## Feature 02: get_rated_players()
## Feature 03: get_recommendations()  # Consistent
```

---

### Dimension 10: Error Handling Consistency

**Question:** Is error handling consistent across all features?

**Checklist:**

**Error Handling Approach:**
- [ ] Same exception hierarchy used across features
- [ ] Error messages follow same format
- [ ] Error logging consistent (level, context, format)
- [ ] Error recovery patterns consistent

**Boundary Error Handling:**
- [ ] Errors at feature boundaries handled consistently
- [ ] Upstream errors handled the same way
- [ ] Downstream errors propagated consistently
- [ ] Critical errors escalated the same way

**Common Violations:**

Wrong - Inconsistent error handling:
```python
## Feature 01: Raises DataProcessingError
except FileNotFoundError:
    raise DataProcessingError("Record data not found")

## Feature 03: Returns None
except FileNotFoundError:
    return None  # Inconsistent
```

Correct - Consistent error handling:
```python
## Feature 01: Raises DataProcessingError
except FileNotFoundError:
    raise DataProcessingError("Record data not found")

## Feature 03: Also raises DataProcessingError
except FileNotFoundError:
    raise DataProcessingError("Settings not found")
```

---

### Dimension 11: Architectural Alignment

**Question:** Are features architecturally aligned and compatible?

**Checklist:**

**Design Pattern Compatibility:**
- [ ] Patterns are compatible (Manager, System, Engine)
- [ ] No conflicting architectural approaches
- [ ] Feature boundaries clear and consistent
- [ ] Dependency directions correct (no circular)

**Layer Consistency:**
- [ ] All features follow same layering (if applicable)
- [ ] Data access patterns consistent
- [ ] Configuration patterns consistent
- [ ] API patterns consistent (if applicable)

---

### Dimension 12: Success Criteria Completion

**Question:** Does the epic meet all original success criteria?

**Checklist:**

**Original Epic Request:**
- [ ] Re-read original `.shamt/epics/requests/{epic_name}.txt`
- [ ] All user goals achieved
- [ ] All stated requirements implemented
- [ ] No missing functionality

**Epic Success Criteria:**
- [ ] All epic success criteria (from S3 epic ticket) met (100%)
- [ ] Performance meets expectations
- [ ] User experience flow works correctly
- [ ] End-to-end scenarios all work

**Example Verification:**
```markdown
## Original Epic Goals (from `.shamt/epics/requests/{epic_name}.txt`)

Goal 1: "Integrate rank data into scoring recommendations"
Verified: Feature 01 fetches rank priority, Feature 02 applies ratings, Feature 03 uses in recommendations

Goal 2: "Allow users to adjust rating multipliers"
Verified: Feature 02 includes multiplier config, Feature 03 respects adjustments

Goal 3: "Generate top 200 ranked items"
Verified: Feature 03 outputs exactly 200 ranked items
```

---

### Dimension 13: Mechanical Code Quality (Epic-Wide)

**Question:** Have all mechanical/linter-type issues been checked across ALL features?

**Reference:** See `reference/concrete_issue_patterns.md` for complete patterns.

**Checklist:**

- [ ] Consulted `reference/concrete_issue_patterns.md`
- [ ] Universal patterns checked across ALL features (unused imports, dead code, etc.)
- [ ] Language-specific patterns checked across ALL features
- [ ] Security quick scan completed across ALL features
- [ ] Patterns consistent across features (same style, same conventions)
- [ ] If linter available: `{LINT_COMMAND}` returns exit code 0 for entire epic

**Epic-Specific Focus:**
- Verify mechanical quality CONSISTENT across all features
- Check that features don't introduce conflicting patterns
- Ensure no feature has mechanical issues that others don't

**Common Violations:**

❌ **WRONG — Inconsistent patterns across features:**
- Feature 01 uses single quotes, Feature 02 uses double quotes
- Feature 01 has unused imports, Feature 02 is clean

✅ **CORRECT — Consistent mechanical quality:**
- All features follow same quote style
- All features have zero unused imports

---

### Dimension 14: Security Scan (Optional, Epic-Wide)

**Question:** Has the project's security scanner been run across ALL features with zero high-severity findings?

**Reference:** See `reference/security_checklist.md` for complete security patterns and tool mapping.

**Applicability:** This dimension is OPTIONAL. Only check if the project has a security scanner configured (check `SECURITY_SCAN_COMMAND` in project rules file).

**Checklist (if security scanner configured):**

- [ ] Run security scanner: `{SECURITY_SCAN_COMMAND}` across entire epic
- [ ] Zero high-severity findings across ALL features
- [ ] Medium-severity findings reviewed and either fixed or documented as accepted risk
- [ ] Manual security checks per `reference/security_checklist.md` Quick Security Review Checklist pass for ALL features
- [ ] Security patterns CONSISTENT across all features

**If no security scanner configured:**
- [ ] Skip automated scan
- [ ] Still verify manual security checklist from `reference/security_checklist.md` across ALL features

**Epic-Specific Focus:**
- Verify security measures CONSISTENT across all features
- Check that features don't introduce conflicting security approaches
- Ensure cross-feature data flow doesn't create security gaps

**Language-Specific Security Tools:**

| Language | Recommended Tool | Example Command |
|----------|------------------|-----------------|
| Python | Bandit | `bandit -r src/ -ll` |
| JavaScript/TypeScript | ESLint security plugin + npm audit | `npm audit --audit-level=high` |
| Go | gosec | `gosec ./...` |
| Java | SpotBugs + FindSecBugs | `mvn spotbugs:check` |
| Multi-language | Semgrep | `semgrep --config auto .` |

---

## Total Dimensions: 13 (+1 Optional)

**Every validation round checks ALL 13 mandatory dimensions (+1 optional):**
- 7 Master dimensions (universal)
- 6 Epic QC dimensions (context-specific)
- 1 Optional security scan dimension (if project has security scanner configured)

**Process:** See master protocol for sub-agent confirmation exit requirement

---

## What's Being Validated

### S9.P2: Epic QC Validation Loop

**Artifact:** Complete epic (all features together)

**Validates:**
- Cross-feature integration
- Epic-wide consistency
- Architectural alignment
- Original epic goals
- User experience flow

**Success Criteria:**
- All 13 dimensions checked every primary round
- Primary clean round + sub-agent confirmation achieved
- ZERO issues found
- Ready for user testing

---

## Fresh Eyes Patterns Per Round

**See master protocol for general fresh eyes principles.**

Epic-specific reading patterns:

### Round 1: Sequential Review + Integration Focus

**Pattern:**
1. Read features sequentially (Feature 01, 02, 03...)
2. Check integration points between features
3. Verify data flow across feature boundaries
4. Check all 13 dimensions

**Checklist:**
- [ ] All 13 dimensions checked (7 master + 6 epic)
- [ ] Integration points verified
- [ ] Data flow validated
- [ ] Tests passing (100%)

### Round 2: Reverse Order + Consistency Focus

**Pattern:**
1. Read features in reverse order (Feature 03, 02, 01...)
2. Focus on consistency across features
3. Compare patterns between features
4. Check all 13 dimensions

**Checklist:**
- [ ] All 13 dimensions checked
- [ ] Naming consistency verified
- [ ] Error handling consistency verified
- [ ] Architectural patterns compatible

### Round 3: Random Spot-Checks + Success Criteria

**Pattern:**
1. Random spot-check 3-5 integration points
2. Verify success criteria from original epic request
3. End-to-end scenario validation
4. Check all 13 dimensions

**Checklist:**
- [ ] All 13 dimensions checked
- [ ] Spot-checked integrations work correctly
- [ ] Success criteria met (100%)
- [ ] Ready for user testing

---

## Common Issues in S9 QC Context

### Issue 1: Integration Point Failures

**Symptom:** Features don't communicate correctly

**Example:**
```python
## Feature 01 returns List[DataRecord]
## Feature 02 expects Dict[str, DataRecord]
## Integration fails with TypeError
```

**Fix:** Verify interface contracts match, add data transformation if needed

---

### Issue 2: Inconsistent Error Handling

**Symptom:** Different features handle errors differently

**Example:**
```python
## Feature 01: raises exception on error
## Feature 02: returns None on error
## Integration breaks due to unexpected None
```

**Fix:** Standardize error handling approach across all features

---

### Issue 3: Missing Success Criteria

**Symptom:** Epic doesn't fully meet original request

**Example:**
```markdown
Original goal: "Generate top 200 items"
Implementation: Only generates top 100 items
```

**Fix:** Review original epic request and implement missing functionality

---

### Issue 4: Architectural Inconsistencies

**Symptom:** Features use incompatible patterns

**Example:**
```python
## Feature 01: Singleton pattern for config
## Feature 02: Instance-based config
## Conflict when accessing shared configuration
```

**Fix:** Standardize architectural patterns across features

---

## Exit Criteria

**Epic QC validation is COMPLETE when ALL of the following are true:**

**From Master Protocol:**
- [ ] Primary agent declared a clean round (ZERO issues OR exactly 1 LOW-severity issue fixed) AND both sub-agents independently confirmed zero issues (see master protocol Exit Criteria for the sub-agent confirmation protocol)
- [ ] Sub-agent confirmations use **Haiku model** for token efficiency (70-80% savings) - see `reference/model_selection.md`
- [ ] Counter logic: 2+ LOW issues OR any MEDIUM/HIGH/CRITICAL resets counter; see `reference/severity_classification_universal.md`
- [ ] All 7 master dimensions checked every primary round
- [ ] All 6 epic QC dimensions checked every primary round
- [ ] VALIDATION_LOOP_LOG.md complete with all rounds documented

**Epic QC Specific:**
- [ ] All cross-feature integration points work correctly
- [ ] Consistent patterns across all features
- [ ] Error handling consistent across features
- [ ] Architectural patterns compatible
- [ ] All success criteria met (100%)
- [ ] Original epic goals achieved
- [ ] Ready for user testing (S9.P3)

**Cannot exit if:**
- Any integration point fails
- Inconsistent patterns across features
- Missing success criteria
- Architectural conflicts
- Sub-agent confirmation not yet achieved

---

## Integration with S9

### S9.P2: Epic QC Validation Loop

**When:** After S9.P1 (Epic Smoke Testing) passes

**Validates:** Complete epic (all features together)

**Process:**
1. Use this validation loop protocol
2. Check all 13 dimensions (7 master + 6 epic)
3. Exit when primary clean round + sub-agent confirmation
4. Proceed to S9.P3 (User Testing)

**Threshold:** Primary clean round + both sub-agents confirm zero issues

---

## Example Validation Round Sequence

```text
Round 1: Sequential Review + Integration
- Read all features sequentially
- Check all 13 dimensions
- Issues found: 3
  - D8 (Integration): Feature 02 -> 03 data format mismatch
  - D9 (Cohesion): Inconsistent naming pattern in Feature 03
  - D12 (Success Criteria): Missing multiplier config validation
- Fix all 3 issues
- Clean counter: 0

Round 2: Reverse Order + Consistency
- Read features in reverse
- Check all 13 dimensions
- Issues found: 1
  - D10 (Error Handling): Feature 01 returns None, Feature 02 expects exception
- Fix issue
- Clean counter: 0

Round 3: Spot-Checks + Verification
- Random spot-check integration points
- Check all 13 dimensions
- Issues found: 0
- Clean counter: 1

Round 4: Primary Clean Round
- Fresh eyes, complete re-read
- Check all 13 dimensions
- Issues found: 0
- Clean counter: 1 → Triggering sub-agent confirmation

Sub-agent A (top-to-bottom): 0 issues ✅
Sub-agent B (bottom-to-top): 0 issues ✅
Both confirmed → VALIDATION COMPLETE
```

---

## Summary

**S9 Epic QC Validation Loop:**
- **Extends:** Master Validation Loop Protocol (7 universal dimensions)
- **Adds:** 6 epic QC-specific dimensions + 1 optional security scan dimension
- **Total:** 13 mandatory dimensions checked every primary round (+1 optional if security scanner configured)
- **Process:** Primary clean round + 2 independent sub-agents confirming zero issues
- **Focus:** Cross-feature integration, consistency, success criteria
- **Quality:** Epic works as cohesive whole, ready for user testing

**Key Principle:**
> "Every feature must work together seamlessly as a unified epic, with consistent patterns and complete success criteria achievement."

---

*End of S9 Epic QC Validation Loop v2.0*
