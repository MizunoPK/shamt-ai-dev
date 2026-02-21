# S2 Refinement Phase - Phase 6 Examples: Acceptance Criteria & User Approval

**Guide Version:** 1.0
**Created:** 2026-02-05 (Split from refinement_examples.md)
**Purpose:** Detailed examples for Phase 6 (Acceptance Criteria & User Approval)
**Prerequisites:** Read stages/s2/s2_p3_refinement.md Phase 6 first
**Main Guide:** stages/s2/s2_p3_refinement.md
**Parent Reference:** reference/stage_2/refinement_examples.md

---

## Purpose

This reference provides detailed examples specifically for **Phase 6: Acceptance Criteria & User Approval** of the Refinement Phase (S2.P3).

**What's Covered:**
- Acceptance criteria templates for different feature types
- User approval workflows (clean approval, approval with modifications)
- Handling approval feedback and iterations
- Final spec validation before S3

**When to Use:** During S2.P3 Phase 6 when creating acceptance criteria or preparing for Gate 3 (User Checklist Approval)

**Always read the main guide first.** This is a reference supplement, not a standalone guide.

---

## Phase 6 Examples: Acceptance Criteria & User Approval

### Example 1: Complete Acceptance Criteria

```markdown
---

## Acceptance Criteria (USER MUST APPROVE)

**Feature 01: rank priority Integration**

When this feature is complete, the following will be true:

### Behavior Changes

**New Functionality:**
1. rank data can be loaded from CSV file at `data/priority_rankings.csv`
   - File format: Name, Position, OverallRank columns
   - Loaded automatically during RecordManager initialization
   - Players matched using name+position normalization (via Feature 05 utility)

2. Draft recommendations incorporate rank multipliers
   - High rank priority items (1-50) get 15% scoring boost
   - Mid rank priority items (51-100) get 8% scoring boost
   - Lower rank priority items get smaller or no boost
   - Players without rank data use neutral 1.0x multiplier

3. Command-line flag `--use-rank` available
   - When enabled: Requires rank priority CSV (fails if missing)
   - When disabled (default): Graceful degradation if CSV missing

**Modified Functionality:**
1. RecordManager.calculate_total_score() includes rank multiplier
   - Before: `total_score = base * injury * matchup * team`
   - After: `total_score = base * injury * matchup * team * rank`
   - Order of multiplication doesn't affect result (commutative)

2. DataRecord class has new fields
   - Before: name, position, team, projected_value, attribute_status
   - After: (all above) + rank_value, rank_multiplier
   - rank_value: Optional[int] (None if not in CSV)
   - rank_multiplier: float (default 1.0)

**No Changes:**
- Draft mode UI will not change (no visual indication of rank priority)
- Trade analyzer will not use rank priority (only scoring recommendations)
- Other scoring multipliers (injury, matchup, team) unchanged
- RecordManager public interface unchanged (no new parameters)

---

### Files Modified

**New Files Created:**
1. `[module]/loaders/rank_loader.py`
   - Purpose: Load and parse rank data from CSV
   - Exports:
     - `load_rank_data(filepath: Path) -> Dict[str, int]`
     - `load_rank_data_with_fallback(filepath: Path, require: bool) -> Dict[str, int]`
   - Lines: ~80 lines (loader + error handling)

2. `data/priority_rankings.csv` (template file)
   - Purpose: Example rank data structure for users
   - Format: Name,Position,OverallRank header + sample rows
   - Note: Users must replace with actual [ranking source] data

3. `tests/[module]/loaders/test_rank_loader.py`
   - Purpose: Test CSV loading, parsing, error handling
   - Tests: 12 unit tests
     - Valid CSV loading
     - Missing file handling
     - Invalid format handling
     - Item matching
     - Fallback behavior (require flag)

4. `tests/[module]/util/test_RecordManager_rank.py`
   - Purpose: Test rank multiplier calculation and integration
   - Tests: 15 unit tests
     - rank multiplier calculation (various ranges)
     - Missing rank priority handling (default 1.0)
     - Integration with calculate_total_score
     - Config-based multiplier ranges

**Existing Files Modified:**
1. `[module]/util/RecordManager.py`
   - Lines modified: Approximately 125-180 (calculate_total_score region)
   - Changes:
     - `load_players()` method: Add call to load rank data
     - `calculate_total_score()` method: Add rank multiplier to calculation
   - Methods added:
     - `_calculate_rank_multiplier(item: DataRecord) -> float` (new, ~25 lines)
   - Methods modified:
     - `calculate_total_score()`: Add 1 line for rank priority multiplication
     - `load_players()`: Add 3 lines for rank data loading

2. `[module]/util/DataRecord.py`
   - Lines modified: 15-25 (dataclass definition)
   - Changes:
     - Add field: `rank_value: Optional[int] = None`
     - Add field: `rank_multiplier: float = 1.0`

3. `[module]/util/ConfigManager.py`
   - Lines modified: Approximately 180-220 (multiplier methods)
   - Methods added:
     - `get_rank_multiplier(rank: int) -> float` (new, ~20 lines)
   - Pattern: Follow existing get_attribute_multiplier() structure

4. `data/league_config.json`
   - Section added: `rank_multipliers` with range configuration
   - Format:
     ```
     "rank_multipliers": {
       "ranges": [
         {"min": 1, "max": 50, "multiplier": 1.15},
         {"min": 51, "max": 100, "multiplier": 1.08},
         {"min": 101, "max": 200, "multiplier": 1.03},
         {"min": 201, "max": 500, "multiplier": 1.0}
       ]
     }
     ```text

5. `run_[module].py`
   - Lines modified: Argument parser section (~line 25)
   - Changes: Add `--use-rank` command-line flag
   - Usage: `python run_[module].py --use-rank`

---

### Data Structures

**New Data Structures:**
1. rank priority Dictionary (internal)
   - Type: `Dict[str, int]`
   - Key format: "name_position" (e.g., "Record-A_QB")
   - Value: rank value (1-300)
   - Example: {"Record-A_QB": 5, "Christian McCaffrey_RB": 1}

**Modified Data Structures:**
1. `DataRecord` class
   - New fields:
     - `rank_value: Optional[int]` - rank value from CSV (1-300), None if not found
     - `rank_multiplier: float` - Calculated multiplier (0.8-1.2 range), default 1.0
   - Location: [module]/util/DataRecord.py

2. Config JSON structure
   - New section: `rank_multipliers` with range-based multipliers
   - Format: List of range objects (min, max, multiplier)

---

### API/Interface Changes

**New Public Methods:**
1. `ADPDataLoader.load_rank_data(filepath: Path) -> Dict[str, int]`
   - Purpose: Load rank data from CSV file
   - Parameters:
     - filepath: Path to rank priority CSV (required columns: Name, Position, OverallRank)
   - Returns: Dictionary mapping item key to rank value
   - Raises: FileNotFoundError if file missing, ValueError if invalid format

2. `ADPDataLoader.load_rank_data_with_fallback(filepath: Path, require: bool = False) -> Dict[str, int]`
   - Purpose: Load rank data with optional graceful degradation
   - Parameters:
     - filepath: Path to rank priority CSV
     - require: If True, raise exception on missing file (for --use-rank flag)
   - Returns: Dictionary of rank data, or empty dict if file missing and require=False

3. `ConfigManager.get_rank_multiplier(rank: int) -> float`
   - Purpose: Get rank multiplier from config based on rank value
   - Parameters:
     - rank: rank value (1-500)
   - Returns: Multiplier float (typically 0.8-1.2 range)

**Modified Public Methods:**
- NONE (RecordManager.calculate_total_score signature unchanged)

**No API Changes:**
- RecordManager public interface maintained (user constraint honored)
- Existing multiplier methods unchanged

---

### Testing

**New Tests:**
- Unit tests: 27 tests total
  - rank_loader tests: 12 tests
  - RecordManager rank priority tests: 15 tests
- Integration tests: 3 tests
  - Full scoring with all multipliers (including rank priority)
  - CSV loading → item matching → multiplier calculation → scoring
- Test files: 2 new test files
  - `tests/[module]/loaders/test_rank_loader.py`
  - `tests/[module]/util/test_RecordManager_rank.py`

**Test Coverage:**
- Target: 100% coverage for new code
- Edge cases covered:
  - Missing rank priority CSV file (with and without --use-rank flag)
  - Item not in rank data (defaults to 1.0 multiplier)
  - Invalid rank values (<1 or >300)
  - Corrupt CSV format
  - Multiple items with similar names (matching logic)
  - Empty CSV file
  - Config file missing rank_multipliers section

---

### Dependencies

**This Feature Depends On:**
- Feature 05: Item Name Matching Utility (must be implemented first)
  - Uses normalize_player_name() function for CSV matching
  - Blocks: Cannot start Feature 01 implementation until Feature 05 complete

**Features That Depend On This:**
- NONE (Feature 01 is independent, doesn't block other features)

**External Dependencies:**
- [ranking source] rank priority CSV data (user must provide)
- csv_utils.read_csv_with_validation() (already exists in codebase)
- No new Python package dependencies

---

### Edge Cases & Error Handling

**Edge Cases Handled:**
1. Item not in rank priority CSV
   - Behavior: Set rank_value = None, rank_multiplier = 1.0 (neutral)
   - No error raised, graceful default

2. rank priority CSV file missing
   - Default mode: Log WARNING, continue with all multipliers = 1.0
   - --use-rank mode: Raise FileNotFoundError with clear message

3. Invalid rank value (< 1 or > 300)
   - Behavior: Log warning, use neutral multiplier 1.0
   - Validation in get_rank_multiplier()

4. Corrupt CSV format (missing columns, wrong types)
   - Behavior: Raise ValueError with specific error message
   - Caught by read_csv_with_validation()

5. Multiple items with same name
   - Behavior: Match using name+position key (normalization from Feature 05)
   - Example: "Mike Williams_WR" (LAC) vs "Mike Williams_WR" (was on NYJ)
   - Note: Normalization handles this, but still potential ambiguity (user data quality)

**Error Conditions:**
1. rank priority CSV not found (--use-rank mode)
   - User sees: "rank priority CSV not found at data/priority_rankings.csv. Provide file or remove --use-rank flag."
   - System does: Raises FileNotFoundError, stops execution

2. rank priority CSV invalid format
   - User sees: "Invalid rank priority CSV format: missing required columns [OverallRank]"
   - System does: Raises ValueError, stops execution

3. Config missing rank_multipliers section
   - User sees: "Config missing rank_multipliers section, using default ranges"
   - System does: Log warning, use hardcoded default ranges

---

### Documentation

**User-Facing Documentation:**
- README.md updated with:
  - "rank priority Integration" section under Features
  - How to provide rank priority CSV data
  - --use-rank flag usage
  - Example rank priority CSV format
- Examples added:
  - Sample data/priority_rankings.csv with 10 example items
  - Command-line usage: `python run_[module].py --use-rank`

**Developer Documentation:**
- Docstrings added to:
  - rank_loader.py: All public functions
  - RecordManager._calculate_rank_multiplier(): Implementation details
  - ConfigManager.get_rank_multiplier(): Config format and range logic
- Architecture docs: No updates needed (follows existing multiplier pattern)

---

## User Approval

- [ ] **I approve these acceptance criteria**

**Approval Timestamp:** {To be filled after user approval}

**Approval Notes:**
{Any clarifications or modifications requested by user}

---

**Next Steps After Approval:**
1. Agent marks approval checkbox [x]
2. Agent documents approval timestamp
3. Agent updates Feature Tracking in EPIC_README.md
4. Agent proceeds to next feature OR S3 (if all features complete)
```

---

### Example 2: User Approval Process

**Agent presents acceptance criteria:**

```markdown
## Feature 01 (rank priority Integration) - Ready for Approval

I've completed the deep dive for Feature 01. Here's a summary:

**Spec Status:**
- All 6 checklist questions resolved (user answers incorporated)
- Cross-feature alignment complete (compared to Feature 00, zero conflicts)
- Scope validated (13 checklist items, within limits)

**What This Feature Will Do:**
Load rank data from [ranking source] CSV and factor it into scoring recommendations as a scoring multiplier, following the same pattern as existing injury/matchup multipliers.

**Impact:**
- Files modified: 2 new files (rank_loader.py, template CSV), 5 existing files modified
- New fields on DataRecord: rank_value, rank_multiplier
- Command-line flag: --use-rank (optional strict mode)
- Test coverage: 27 new unit tests, 3 integration tests

**Full Details:**

Please review the "Acceptance Criteria" section in spec.md:
`.shamt/epics/SHAMT-1-improve_recommendation_engine/feature_01_rank_integration/spec.md`

**Acceptance Criteria Section includes:**
- Exact behavior changes (what's new, what's modified, what's unchanged)
- All files that will be modified (new: 4 files, modified: 5 files)
- Data structure changes (new fields on DataRecord, new config section)
- API/interface changes (3 new methods, zero breaking changes)
- Testing approach (27 unit tests, 100% coverage)
- Edge cases and error handling (5 edge cases documented)
- Documentation updates (README + docstrings)

**Next Steps:**

If you approve these acceptance criteria:
- I'll mark the approval checkbox and timestamp
- I'll mark Feature 01 as "S2 Complete" in epic tracking
- I'll proceed to next feature (Feature 02) or S3 if all features done

If you want changes:
- Let me know what to modify
- I'll update the spec and re-present for approval

**Do you approve these acceptance criteria?**
```

**User reviews and approves:**

```text
Yes, this looks good. I approve.

One minor note: For the --use-rank flag documentation, can you emphasize that it's optional? I don't want users to think they HAVE to use it.
```

**Agent updates with approval:**

```markdown
✅ Approved! Thank you.

I'll update the documentation to emphasize the flag is optional.

**Updated Documentation Section:**

**User-Facing Documentation:**
- README.md updated with:
  - "rank priority Integration (Optional)" section under Features
  - **Emphasis: --use-rank flag is OPTIONAL**
    - Default behavior: Works with or without rank data (graceful)
    - Optional strict mode: Use --use-rank to require rank data
  - How to provide rank priority CSV data (if desired)
  - Example rank priority CSV format

**Marking approval in spec.md:**

```
## User Approval

- [x] **I approve these acceptance criteria**

**Approval Timestamp:** 2026-01-10 16:20

**Approval Notes:**
User approved on 2026-01-10 with request to emphasize --use-rank flag is optional (not required). Updated documentation section to clarify default behavior works with or without rank data.
```markdown

**Updating Feature Tracking:**

```
## Feature Tracking (in EPIC_README.md)

| Feature | Name | S2 Complete | S5 Complete | Status |
|---------|------|------------------|------------------|--------|
| 01 | rank priority Integration | [x] 2026-01-10 | [ ] | S2 Done |
| 02 | Injury Risk | [ ] | [ ] | In Progress |
```markdown

**Next: Begin S2 for Feature 02 (Injury Risk Assessment)**

Would you like me to start Feature 02, or do you want to review anything else about Feature 01?
```

---

## Success Criteria Summary

**Refinement Phase (S2.P3) passes when:**

✅ **Phase 3 (Interactive Question Resolution):**
- All checklist questions resolved (zero open items)
- Each question asked ONE AT A TIME
- Spec and checklist updated IMMEDIATELY after each answer
- New questions evaluated after each answer
- User answers documented verbatim or paraphrased

✅ **Phase 4 (Dynamic Scope Adjustment):**
- Checklist item count documented
- If >35 items: Split proposed to user, user decided
- If new work discovered: Evaluated (new feature vs expanded scope)
- Scope adjustments documented

✅ **Phase 5 (Cross-Feature Alignment):**
- Compared to ALL features with "S2 Complete"
- Systematic pairwise comparison performed
- Conflicts identified (if any)
- Conflicts resolved or user consulted
- Alignment verification documented in spec.md

✅ **Phase 6 (Acceptance Criteria & User Approval):**
- Acceptance Criteria section created in spec.md
- Complete coverage: behavior, files, structures, API, tests, edge cases, docs
- Presented to user for approval
- User APPROVED (explicit confirmation)
- Approval checkbox marked [x]
- Approval timestamp documented

**Ready for next feature or S3 when all phases complete with user approval.**

---

*End of refinement_examples.md*
