# Design Doc Validation Workflow

This guide provides the step-by-step process for validating a design doc using the 7-dimension validation loop.

---

## Prerequisites

Before starting validation:
- [ ] Design doc exists at `design_docs/active/SHAMT{N}_DESIGN.md`
- [ ] Design doc is in Draft status
- [ ] Design doc has all required sections (Problem Statement, Goals, Proposals, Implementation Plan, etc.)

---

## Step 1: Create Validation Log

Create `SHAMT{N}_VALIDATION_LOG.md` in the same folder as the design doc using the template at `.shamt/guides/design_doc_validation/validation_log_template.md`.

Initialize the log with:
- Design doc name
- Validation start date
- Link to design doc

---

## Step 2: Run Validation Round 1

For each of the 7 dimensions, analyze the design doc and identify issues:

### Dimension 1: Completeness
- Are all necessary aspects covered?
- Is the problem fully stated?
- Are all affected files identified?
- Are edge cases and failure modes addressed?
- Does the implementation plan cover all proposals?

### Dimension 2: Correctness
- Are factual claims accurate?
- Do proposed changes actually work the way described?
- Are references to existing guides/files accurate?
- Are file paths correct?

### Dimension 3: Consistency
- Is the design internally consistent?
- Do proposals conflict with each other?
- Does it conflict with existing guide conventions or other SHAMT decisions?
- Are folder structures mentioned consistently?

### Dimension 4: Helpfulness
- Do the proposals actually solve the stated problem?
- Is the benefit worth the complexity added?
- Are the solutions practical?

### Dimension 5: Improvements
- Are there simpler or better ways to achieve the same goal?
- Have alternatives been considered?
- Are rejected alternatives documented with rationale?

### Dimension 6: Missing Proposals
- Is anything important left out of scope that should be addressed here?
- Are there related concerns that should be handled together?

### Dimension 7: Open Questions
- Are there unresolved decisions that need to be surfaced before implementation?
- Are all open questions documented?
- Do open questions have clear paths to resolution?

---

## Step 3: Classify and Document Issues

For each issue found:
1. Classify severity using the universal severity system:
   - **CRITICAL**: Blocks workflow or causes cascading failures
   - **HIGH**: Causes significant confusion or wrong decisions
   - **MEDIUM**: Reduces quality but doesn't block or confuse
   - **LOW**: Cosmetic issues with minimal impact

2. Document in validation log:
   - Dimension
   - Issue description
   - Severity
   - Location in design doc (line numbers if possible)

---

## Step 4: Fix Issues

Fix all issues found in the round. Update the design doc and document fixes in the validation log.

---

## Step 5: Assess Clean Round Status

A round is **clean** if:
- ZERO issues found (Pure Clean), OR
- Exactly ONE LOW-severity issue found AND fixed (Clean with 1 Low Fix)

A round is **NOT clean** if:
- 2 or more LOW-severity issues found
- Any MEDIUM-severity issue found
- Any HIGH-severity issue found
- Any CRITICAL-severity issue found

Update `consecutive_clean` counter:
- Clean round → increment `consecutive_clean`
- Not clean round → reset `consecutive_clean = 0`

Document the round summary in the validation log:
```markdown
**Round N Summary:**
- Total Issues: {count}
- Severity Breakdown: CRITICAL: {n}, HIGH: {n}, MEDIUM: {n}, LOW: {n}
- Clean Round Status: **Pure Clean** / **Clean (1 Low Fix)** / **Not Clean**
- consecutive_clean: {count}
```

---

## Step 6: Repeat or Exit

**If `consecutive_clean < 1`:**
- Return to Step 2 for another validation round

**If `consecutive_clean = 1`:**
- Proceed to Step 7 (sub-agent confirmation)

---

## Step 7: Sub-Agent Confirmation

Spawn 2 independent sub-agents in parallel to confirm zero issues.

Each sub-agent:
1. Reads the design doc
2. Runs full 7-dimension validation
3. Reports total issues found with severities
4. States "CONFIRMED: Zero issues found" if no issues, or lists all issues if any found

**IMPORTANT**: Sub-agents do NOT get the 1 LOW allowance. Any issue found (even LOW) must be reported.

---

## Step 8: Evaluate Sub-Agent Results

**If both sub-agents confirm zero issues:**
- Validation is complete ✅
- Proceed to Step 9

**If either sub-agent finds issues:**
- Review the sub-agent findings
- Fix valid issues
- Reset `consecutive_clean = 0`
- Return to Step 2 for another validation round

---

## Step 9: Finalize Validation

1. Update design doc:
   - Change Status field from "Draft" to "Validated"
   - Add entry to Change History table

2. Update validation log:
   - Add final summary
   - Record validation completion date
   - State final result: "Design doc validated successfully"

3. Keep validation log alongside design doc in `design_docs/active/`

---

## Exit Criterion Summary

Validation exits when:
1. Primary clean round achieved (Round N with ≤1 LOW issue)
2. Both sub-agents confirm zero issues

Track `consecutive_clean` explicitly and state it at the end of every round.

---

## Common Issues and Tips

**Issue: Sub-agents find different issues than primary validation**
- Sub-agents provide fresh perspectives
- Their findings are valid and should be addressed
- This resets the process but improves design quality

**Issue: Many rounds needed**
- Complex designs naturally require more rounds
- Each round improves the design
- Focus on fixing issues correctly rather than quickly

**Issue: Unsure about severity classification**
- Use the severity decision tree in `reference/severity_classification_universal.md`
- When uncertain between two levels, classify as HIGHER severity
- Document reasoning in validation log

**Tip: Read related files**
- To verify correctness, read files mentioned in proposals
- Check export/import scripts if sync behavior is mentioned
- Verify file paths exist or will be created

**Tip: Think like a future implementer**
- Could someone implement this design without asking questions?
- Are there ambiguous instructions?
- Is every file path clear and unambiguous?
