# S5 v2 Validation Loop: Example Execution

**Parent Guide:** `stages/s5/s5_v2_validation_loop.md`
**Purpose:** Worked example showing a complete S5 v2 validation loop from draft to exit (mechanical implementation plan)

---

## Example Validation Loop Execution

```text
DRAFT CREATION: 90 minutes
- Created mechanical implementation plan with all 9 dimensions
- 45 steps (CREATE, EDIT, DELETE operations)
- Quality estimate: ~70%

─────────────────────────────────────────────────────────
ROUND 1: Sequential read, D1-4 focus (30 min)
─────────────────────────────────────────────────────────
Issues found: 12

Dimension 1 (Step Clarity):
- Step 15: File path missing extension (spec says .py)
- Step 22: "Add method" - which class? Not specified

Dimension 2 (Mechanical Executability):
- Step 8: EDIT operation has vague locate string ("near line 45")
- Step 12: "Create function" - no signature specified, builder would need to make design choice

Dimension 3 (File Coverage Completeness):
- Missing file: spec.md line 67 mentions util/helpers.py but no CREATE step exists
- Test file test_rank_priority.py not in plan (spec requires unit tests)

Dimension 4 (Operation Specificity):
- Step 18 EDIT: locate string "def calculate_rank" matches 3 functions - not unique
- Step 25 CREATE: Only has function signature, missing full content for create operation

Action: Fix all 12 issues → implementation_plan.md updated
Clean count: RESET to 0
Next: Round 2

─────────────────────────────────────────────────────────
ROUND 2: Reverse read, D5-8 focus (35 min)
─────────────────────────────────────────────────────────
Issues found: 8

Dimension 5 (Verification Completeness):
- Step 10: "Verify method exists" - not checkable by builder (needs: "grep for 'def get_multiplier' in file")
- Step 14: No verification method specified at all

Dimension 6 (Error Handling Clarity):
- Missing edge case handling: What if CSV has wrong columns? No steps for error handling
- Step 32: Success criteria "code works" - not explicit/measurable

Dimension 7 (Dependency Ordering):
- Step 28 edits RecordManager class before Step 35 creates it (create must come first)
- Step 19 calls normalize_name() but Step 40 creates it (dependency ordering broken)

Dimension 8 (Pre/Post Checklist Completeness):
- Pre-execution checklist missing edge case: empty string item names
- Post-execution checklist doesn't verify test files created

Action: Fix all 8 issues → implementation_plan.md updated
Clean count: RESET to 0
Next: Round 3

─────────────────────────────────────────────────────────
ROUND 3: Spot-checks, D9 focus (25 min)
─────────────────────────────────────────────────────────
Issues found: 3

Dimension 9 (Spec Alignment):
- spec.md Requirement R5 (rank calculation algorithm) has no corresponding steps in plan
- Step 42 adds logging functionality not mentioned in spec (scope creep)
- spec.md says "approximate line 450" but Step 15 uses "~line 120" (misalignment)

Action: Fix all 3 issues → implementation_plan.md updated
Clean count: RESET to 0
Next: Round 4

─────────────────────────────────────────────────────────
ROUND 4: Sequential read, all 9 dimensions (30 min)
─────────────────────────────────────────────────────────
Issues found: 0 ✅

All 9 mechanical dimensions validated:

✅ D1: Step Clarity - All steps unambiguous, exact file paths specified
✅ D2: Mechanical Executability - Builder can execute without design choices
✅ D3: File Coverage Completeness - All spec files covered (src + tests), no missing files
✅ D4: Operation Specificity - All EDIT steps have unique locate strings, CREATE steps have full content
✅ D5: Verification Completeness - All steps have mechanical verification methods
✅ D6: Error Handling Clarity - Success/failure criteria explicit, 12 edge cases documented in steps
✅ D7: Dependency Ordering - Steps in correct execution order (create → edit), dependencies explicit
✅ D8: Pre/Post Checklist Completeness - Both checklists complete with all prerequisites/verifications
✅ D9: Spec Alignment - All spec requirements translated to steps, no additions beyond spec scope

Clean count: 1 → Triggering sub-agent confirmation
Next: Sub-agent parallel confirmation

─────────────────────────────────────────────────────────
SUB-AGENT CONFIRMATION
─────────────────────────────────────────────────────────
Primary agent declared clean round (counter = 1).
Spawning 2 independent Haiku sub-agents in parallel.

Sub-agent A (top-to-bottom read):
Issues found: 0 ✅
All 9 dimensions checked. Confirmed zero issues.
Mechanical plan ready for Haiku builder execution.

Sub-agent B (bottom-to-top read):
Issues found: 0 ✅
All 9 dimensions checked. Confirmed zero issues.
All file operations (CREATE/EDIT/DELETE) properly specified.

Both sub-agents confirmed → ✅ PASSED

─────────────────────────────────────────────────────────
VALIDATION LOOP COMPLETE
─────────────────────────────────────────────────────────

Total time: 90 min draft + 130 min validation = 3h 40min
Total rounds: 4 primary + sub-agent confirmation
Total issues fixed: 23
Final quality: 99%+ (validated by sub-agent parallel confirmation)

Mechanical plan contains:
- 45 implementation steps (CREATE: 8 files, EDIT: 12 files, DELETE: 0 files)
- All steps with exact locate/replace strings for EDIT operations
- All CREATE operations with full file content
- All verification methods specified mechanically
- Dependencies ordered correctly
- Pre/Post checklists complete

Next: Hand off validated mechanical plan to Haiku builder in S6
```

---

## See Also

- `stages/s5/s5_v2_validation_loop.md` — main S5 v2 guide (workflow, 9 dimensions, exit criteria)
- `stages/s5/s5_v2_troubleshooting.md` — common issues, fixes, and anti-patterns
- `reference/implementation_plan_format.md` — mechanical plan format specification
