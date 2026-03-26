# S5 v2 Validation Loop: Example Execution

**Parent Guide:** `stages/s5/s5_v2_validation_loop.md`
**Purpose:** Worked example showing a complete S5 v2 validation loop from draft to exit

---

## Example Validation Loop Execution

```text
DRAFT CREATION: 90 minutes
- Created implementation_plan.md with all 11 dimensions
- Quality estimate: ~70%

─────────────────────────────────────────────────────────
ROUND 1: Sequential read, D1-4 focus (30 min)
─────────────────────────────────────────────────────────
Issues found: 12

Dimension 1:
- Missing requirement: spec.md line 45 (item name normalization)
- Missing requirement: spec.md line 67 (case-insensitive matching)

Dimension 2:
- ConfigManager.get_rank_multiplier() interface not verified
- csv_utils.read_csv_with_validation() parameters assumed

Dimension 3:
- Algorithm matrix only 28 mappings, need 40+
- Missing error handling algorithms

Dimension 4:
- Task 3 acceptance criteria vague ("handle multiplier")
- Task 7 has no test names specified
- Task 9 implementation location not specified

Action: Fix all 12 issues → implementation_plan.md updated
Clean count: RESET to 0
Next: Round 2

─────────────────────────────────────────────────────────
ROUND 2: Reverse read, D5-8 focus (35 min)
─────────────────────────────────────────────────────────
Issues found: 8

Dimension 5:
- Task 1 loads data, but consumption not verified
- Data flow missing transformation step (normalization)

Dimension 6:
- Missing error: What if rank priority CSV has wrong columns?
- Edge case not handled: Empty string item names

Dimension 8:
- Resume/persistence tests not planned
- Test coverage 85% (need >90%)

Dimension 9:
- O(n²) matching algorithm identified, no optimization plan

Action: Fix all 8 issues → implementation_plan.md updated
Clean count: RESET to 0
Next: Round 3

─────────────────────────────────────────────────────────
ROUND 3: Spot-checks, D9-11 focus (25 min)
─────────────────────────────────────────────────────────
Issues found: 3

Dimension 11:
- spec.md contradicts epic notes on error handling approach

Dimension 4:
- Task 15 acceptance criteria still not measurable

Dimension 7:
- Backward compatibility analysis missing migration path

Action: Fix all 3 issues → implementation_plan.md updated
Clean count: RESET to 0
Next: Round 4

─────────────────────────────────────────────────────────
ROUND 4: Sequential read, all dimensions (30 min)
─────────────────────────────────────────────────────────
Issues found: 0 ✅

All 18 dimensions validated:

**Master Dimensions (7):**
✅ Master D1: Empirical Verification - All interfaces verified from source code
✅ Master D2: Completeness - All sections present, all requirements mapped
✅ Master D3: Internal Consistency - No contradictions found
✅ Master D4: Traceability - All tasks trace to requirements/tests
✅ Master D5: Clarity & Specificity - All acceptance criteria measurable
✅ Master D6: Upstream Alignment - Matches spec.md exactly
✅ Master D7: Standards Compliance - Follows template structure

**Implementation Planning Dimensions (11):**
✅ D1: All requirements mapped (spec + tests)
✅ D2: All interfaces verified from source
✅ D3: 42 algorithm mappings complete
✅ D4: All tasks specific with acceptance criteria
✅ D5: Data consumption verified
✅ D6: 12 errors, 18 edge cases documented
✅ D7: All methods have callers, backward compat verified
✅ D8: Test coverage 92%
✅ D9: Performance optimized, <1% regression
✅ D10: 5 implementation phases, mocks audited
✅ D11: Spec aligned with epic notes

Clean count: 1 → Triggering sub-agent confirmation
Next: Sub-agent parallel confirmation

─────────────────────────────────────────────────────────
SUB-AGENT CONFIRMATION
─────────────────────────────────────────────────────────
Primary agent declared clean round (counter = 1).
Spawning 2 independent sub-agents in parallel.

Sub-agent A (top-to-bottom read):
Issues found: 0 ✅
All 18 dimensions checked. Confirmed zero issues.

Sub-agent B (bottom-to-top read):
Issues found: 0 ✅
All 18 dimensions checked. Confirmed zero issues.

Both sub-agents confirmed → ✅ PASSED

─────────────────────────────────────────────────────────
VALIDATION LOOP COMPLETE
─────────────────────────────────────────────────────────

Total time: 90 min draft + 130 min validation = 3h 40min
Total rounds: 4 primary + sub-agent confirmation
Total issues fixed: 23
Final quality: 99%+ (validated by sub-agent parallel confirmation)

Next: Present implementation_plan.md to user (Gate 5)
```

---

## See Also

- `stages/s5/s5_v2_validation_loop.md` — main S5 v2 guide (workflow, dimensions, exit criteria)
- `stages/s5/s5_v2_troubleshooting.md` — common issues, fixes, and anti-patterns
