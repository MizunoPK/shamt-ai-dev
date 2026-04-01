# Validation Loop: QC and PR Review

**Extends:** Master Validation Loop Protocol
**See:** `reference/validation_loop_master_protocol.md`

**Applicable Stages:**
- S7.P2: Feature Validation Loop (primary clean round + sub-agent confirmation, post-smoke testing)
- S7.P3: Feature PR Review (final review before commit)
- S9.P2: Epic Validation Loop (primary clean round + sub-agent confirmation, post-epic smoke testing)
- S10 Step 9: Push Branch and Create PR (pre-push verification — see s10_epic_cleanup.md)

**Version:** 2.0 (Updated to extend master protocol)
**Last Updated:** 2026-02-10

---

🚨 **BEFORE STARTING: Read the Hard Stop section at the top of `reference/validation_loop_master_protocol.md`** 🚨

---

## Table of Contents

1. [What's Being Validated](#whats-being-validated)
2. [What Counts as "Issue"](#what-counts-as-issue)
3. [Fresh Eyes Patterns Per Round](#fresh-eyes-patterns-per-round)
4. [Specific Criteria](#specific-criteria)
5. [Example Round Sequence](#example-round-sequence)
6. [Common Issues in QC/PR Context](#common-issues-in-qcpr-context)
7. [Integration with Stages](#integration-with-stages)
8. [Exit Criteria Specific to QC/PR](#exit-criteria-specific-to-qcpr)
9. [Issue Handling: Fix and Continue](#issue-handling-fix-and-continue)

---

## What's Being Validated

Code, tests, and implementation correctness including:
- Source code matches implementation plan
- All tests pass (100% pass rate)
- No bugs found during review
- All requirements implemented
- Integration points work correctly
- Code quality and maintainability

---

## What Counts as "Issue"

An issue in QC/PR context is any of:
- **Test failures:** Any test fails (unit, integration, or end-to-end)
- **Code not matching plan:** Implementation deviates from implementation_plan.md without justification
- **Bugs found during review:** Logic errors, edge cases not handled, incorrect behavior
- **Missing requirements:** Requirement in spec.md not implemented
- **Integration problems:** Integration points don't work as specified
- **Code quality issues:** Hard-coded values, missing error handling, poor naming
- **Performance issues:** Code performs poorly on expected data volumes
- **Security issues:** Vulnerabilities introduced (SQL injection, XSS, etc.)

---

## Fresh Eyes Patterns Per Round

### Round 1: Automated Tests + Sequential Code Review
**Pattern:**
1. Run ALL tests (unit, integration, end-to-end)
2. Verify 100% pass rate
3. Read code files sequentially (alphabetical or logical order)
4. Check code matches implementation plan
5. Check for obvious bugs (null checks, error handling, etc.)
6. Document ALL issues found

**Checklist:**
- [ ] All tests pass (100% pass rate)
- [ ] Code matches implementation_plan.md
- [ ] All requirements from spec.md implemented
- [ ] Error handling present for all failure scenarios
- [ ] No hard-coded values (use config/constants)

### Round 2: Different File Order + Manual Verification
**Pattern:**
1. Re-run ALL tests (verify still 100% pass)
2. Read code files in different order (reverse, by module, by dependency, etc.)
3. Manual verification of critical logic paths
4. Check integration points work correctly
5. Check for edge cases not covered by tests
6. Document ALL issues found

**Checklist:**
- [ ] Tests still pass after code review
- [ ] Critical logic verified manually
- [ ] Integration points work as specified
- [ ] Edge cases handled correctly
- [ ] No code quality issues (naming, structure, etc.)

### Round 3: Random Spot-Checks + Integration Verification
**Pattern:**
1. Re-run ALL tests (final verification)
2. Random spot-check 5 files or functions
3. End-to-end integration verification (call stack traced)
4. Performance check (expected data volumes)
5. Security check (common vulnerabilities)
6. Document ALL issues found

**Checklist:**
- [ ] Random spot-checks reveal no issues
- [ ] End-to-end integration works correctly
- [ ] Performance acceptable on expected data
- [ ] No security vulnerabilities found
- [ ] Ready for commit/PR

---

## Specific Criteria

**All of these MUST pass for loop to exit:**

**Code Correctness:**
- [ ] All tests pass (100% pass rate)
- [ ] Code matches implementation_plan.md (or justified deviations documented)
- [ ] All requirements from spec.md implemented
- [ ] No bugs found during review
- [ ] Integration points work correctly

**Code Quality:**
- [ ] Error handling present for all failure scenarios
- [ ] No hard-coded values (use config/constants)
- [ ] Clear variable/function naming
- [ ] No code duplication (DRY principle)
- [ ] Logging present for debugging

**Performance & Security:**
- [ ] Performance acceptable on expected data volumes
- [ ] No security vulnerabilities (SQL injection, XSS, etc.)
- [ ] Resource cleanup (file handles, connections, etc.)

**Documentation:**
- [ ] Code comments for complex logic
- [ ] Docstrings for public functions
- [ ] README updated if needed

---

## Example Round Sequence

```text
Round 1: Automated tests + sequential review
- Run tests: 2 tests fail (test_player_fetch, test_trade_validation)
- Fix: Debug and fix both test failures
- Sequential review: Found hard-coded API key in fetcher.py
- Fix: Move API key to config file
- Continue to Round 2

Round 2: Different order + manual verification
- Run tests: All pass (100% pass rate)
- Review in reverse order: Found missing error handling in optimizer.py
- Fix: Add try/except with proper error logging
- Manual verification: Integration point F1→F2 returns wrong data type
- Fix: Add type conversion in F1's output
- Continue to Round 3

Round 3: Random spot-checks + integration
- Run tests: All pass (100% pass rate)
- Random spot-check 5 functions: 0 issues found
- Integration verification: End-to-end call stack works correctly
- Check: 0 issues found → (count = 1 clean) → Trigger sub-agent confirmation
  - Sub-agent A: 0 issues ✅
  - Sub-agent B: 0 issues ✅
  - Both confirmed → PASSED ✅
```

---

## Common Issues in QC/PR Context

1. **Test failures:** Tests fail → Debug and fix code or test
2. **Code not matching plan:** Implementation uses approach X, plan specified approach Y → Align with plan or document justification
3. **Missing error handling:** Function doesn't handle null input → Add error handling
4. **Hard-coded values:** API URL hard-coded → Move to config
5. **Integration problems:** F1 calls F2 but F2 expects different parameters → Fix interface
6. **Performance issues:** Code loads entire 10GB file into memory → Use streaming
7. **Security issues:** User input not sanitized → Add input validation

---

## Integration with Stages

**S7.P2 Validation Loop (Feature-Level):**
- Use this protocol after implementation complete
- Check ALL 17 dimensions every primary round (7 master + 10 S7 QC-specific)
- Exit after primary clean round + sub-agent confirmation
- Must pass before S7.P3 (PR Review)

**S7.P3 PR Review (Feature-Level):**
- Use this protocol for final pre-commit review
- Verify ALL issues from S7.P2 fixed
- Must pass before feature commit

**S9.P2 Epic Validation Loop (Epic-Level):**
- Use this protocol after all features complete
- Check ALL 13 dimensions every primary round (7 master + 6 epic-specific)
- Exit after primary clean round + sub-agent confirmation
- Must pass before S9.P3 (User Testing)

---

## Exit Criteria Specific to QC/PR

**Can only exit when ALL true:**
- [ ] Primary agent declared a clean round AND both sub-agents independently confirmed zero issues (see master protocol Exit Criteria for the sub-agent confirmation protocol)
- [ ] All tests pass (100% pass rate)
- [ ] Code matches implementation plan
- [ ] All requirements implemented
- [ ] Integration points work
- [ ] No bugs found during review
- [ ] Code quality acceptable
- [ ] Ready for commit (S7.P3) or user testing (S9.P3)

---

## Issue Handling: Fix and Continue

**CRITICAL:** If ANY issues found in ANY round:

1. **Fix ALL issues immediately** (no deferring)
2. **Re-run ALL tests** to verify fixes didn't break anything
3. **Reset clean round counter to 0**
   - Fixes can introduce new issues
   - Must verify fix quality through complete validation
4. **Continue validation until primary clean round + sub-agent confirmation**

**Key difference from old approach:**
- **Old (restart protocol):** Any issue → Restart from S7.P1 (smoke testing)
- **New (fix and continue):** Any issue → Fix immediately → Reset `consecutive_clean` → Continue validation

**Why counter resets:**
- Fixing Issue A can introduce Issue B
- Fresh eyes needed to catch fix-induced issues
- Cannot guarantee quality by spot-checking only fixed areas
- Historical evidence: 40% of fixes introduce new issues

**Example:**
```bash
Round 1: 5 issues → Fix ALL → Continue (counter = 0)
Round 2: 2 issues (1 missed, 1 introduced by fix) → Fix ALL → Continue (counter = 0)
Round 3: 0 issues → (counter = 1 clean) → Trigger sub-agent confirmation
  Sub-agent A: 0 issues ✅
  Sub-agent B: 0 issues ✅
  → PASSED ✅
```

---

**Remember:** Follow all 7 principles from master protocol. This guide only specifies HOW to apply them in QC/PR context, not WHETHER to apply them.
