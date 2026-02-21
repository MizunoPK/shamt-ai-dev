# S2 Refinement Phase - Phase 3 Examples: Interactive Question Resolution

**Guide Version:** 1.0
**Created:** 2026-02-05 (Split from refinement_examples.md)
**Purpose:** Detailed examples for Phase 3 (Interactive Question Resolution)
**Prerequisites:** Read stages/s2/s2_p3_refinement.md Phase 3 first
**Main Guide:** stages/s2/s2_p3_refinement.md
**Parent Reference:** reference/stage_2/refinement_examples.md

---

## Purpose

This reference provides detailed examples specifically for **Phase 3: Interactive Question Resolution** of the Refinement Phase (S2.P3).

**What's Covered:**
- Complete question-answer cycles (multiple examples)
- Agent behavior for different question types
- Immediate spec/checklist updates after answers
- Common question patterns and anti-patterns

**When to Use:** During S2.P3 Phase 3 when formulating questions or updating specs after receiving user answers

**Always read the main guide first.** This is a reference supplement, not a standalone guide.

---

## Phase 3 Examples: Interactive Question Resolution

### Example 1: Complete Question-Answer Cycle

**Agent asks Question 1:**

```markdown
I have a question about Feature 01 (rank priority Integration):

## Question 1: rank priority CSV Column Names

**Context:** I need to know the exact column names in the [ranking source] rank priority CSV to parse it correctly. You mentioned "use [ranking source] CSV format" but didn't specify the structure.

**Options:**

A. **Assume standard format: Name, Position, rank priority**
   - Pros: Common format, likely correct
   - Cons: Might be wrong, would require rework

B. **Ask you to provide sample CSV or column names**
   - Pros: Guaranteed correct, no guesswork
   - Cons: Requires you to provide file or info

C. **Support multiple formats with auto-detection**
   - Pros: Flexible, works with various sources
   - Cons: Complex, overkill for single data source

**My recommendation:** Option B - Can you provide the exact column names from the [ranking source] CSV, or share a sample file?

**What do you prefer?**
```

**User answers:**

```bash
The columns are: Name, Position, OverallRank

(Note: [ranking source] calls it "OverallRank" not "rank priority")
```

**Agent updates IMMEDIATELY:**

**Update checklist.md:**

```markdown
### Question 1: rank priority CSV Column Names
- [x] **RESOLVED:** Name, Position, OverallRank

**User's Answer:**
"The columns are: Name, Position, OverallRank ([ranking source] calls it 'OverallRank' not 'rank priority')"

**Implementation Impact:**
- CSV parsing will use columns: ['Name', 'Position', 'OverallRank']
- Internal field name remains rank_value for clarity
- Update spec.md data structures section
- Update rank_loader implementation
```

**Update spec.md:**

```markdown
### Data Structure: rank priority CSV Format

**Source:** User Answer to Checklist Question 1
**Traceability:** User confirmed on 2026-01-10

**CSV Format:**
```
Name,Position,OverallRank
Record-A,QB,5
Christian McCaffrey,RB,1
Tyreek Hill,WR,8
```markdown

**Column Definitions:**
- **Name** (string): Item full name (e.g., "Record-A")
- **Position** (string): Position abbreviation (QB, RB, WR, TE, K, DST)
- **OverallRank** (integer): rank value from [ranking source] (1-300)
  - Note: [ranking source] uses "OverallRank" terminology, but we'll refer to it as rank priority internally

**Implementation:**
```
## rank_loader.py
def load_rank_data(filepath: Path) -> Dict[str, int]:
    """Load rank data from [ranking source] CSV.

    Args:
        filepath: Path to CSV file

    Returns:
        Dictionary mapping "name_position" to rank value
    """
    df = read_csv_with_validation(
        filepath,
        required_columns=['Name', 'Position', 'OverallRank']
    )

    rank_dict = {}
    for _, row in df.iterrows():
        key = f"{row['Name']}_{row['Position']}"
        rank_dict[key] = int(row['OverallRank'])

    return rank_dict
```text
```

**Agent evaluates for new questions:**

```markdown
**New questions from this answer:**
- NONE - Answer was complete and clear

**Other questions resolved:**
- Question 4 (Item Key Format) - Implicitly answered
  - User provided Name and Position columns
  - Can use "name_position" as key
  - Mark Q4 as resolved with note
```

**Update checklist.md Question 4:**

```markdown
### Question 4: Item Matching Key Format
- [x] **RESOLVED:** Use "name_position" key (derived from Q1 answer)

**Context:** User's answer to Q1 confirmed CSV has Name and Position columns, which are sufficient for unique matching.

**Implementation:**
- Key format: "{name}_{position}" (e.g., "Record-A_QB")
- Normalize both sources before matching (remove extra spaces, consistent casing)
```

**Agent moves to next question:**

```markdown
I have a question about Feature 01 (rank priority Integration):

## Question 2: Valid rank priority Value Range

**Context:** I need to know the min/max rank values for validation and error handling. Your CSV might have different ranges depending on league depth.

**Options:**

A. **1-300 (standard 12-team league)**
   - Most common format
   - Assumes roster depth of ~25 items

B. **1-500 (deeper league)**
   - Supports 14-16 team leagues
   - More comprehensive rankings

C. **No upper limit validation**
   - Accept any positive integer
   - More flexible but less validation

**My recommendation:** Option A (1-300) since [ranking source] standard format is 12-team leagues, but confirm if you have deeper league.

**What rank priority range does your league use?**
```

{Cycle continues for all questions...}

---

### Example 2: User Requests Clarification

**Agent asks Question 3:**

```markdown
## Question 3: rank priority Multiplier Calculation Formula

**Context:** You said "factor rank priority into scoring recommendations" but didn't specify how much impact it should have. I need to know whether high-rank priority items get a small boost or large boost.

**Options:**

A. **Config-based ranges**
   - Define in league_config.json: rank priority 1-50 = 1.2x, 51-100 = 1.1x, etc.
   - Pros: Flexible, tune without code changes
   - Cons: Requires config updates

B. **Linear formula**
   - Formula: multiplier = 1.0 + ((300 - rank) / 300) * 0.2
   - Pros: Simple, continuous
   - Cons: Less control

C. **Exponential formula**
   - Higher impact for top picks
   - Pros: Reflects real draft value
   - Cons: Complex

**My recommendation:** Option A (config-based)

**What do you prefer?**
```

**User requests clarification:**

```text
Can you explain the difference in impact? Like, if Record-A has rank priority 5 vs a item with no rank data, what's the scoring difference for each option?
```

**Agent provides clarification:**

```markdown
Good question! Let me illustrate with concrete examples:

**Scenario:** Record-A (rank priority 5) vs Backup QB (no rank data)
- Base projected points: Mahomes 450, Backup 200

**Option A (Config-based):**
- Mahomes: rank priority 5 → in range 1-50 → multiplier 1.2x → final score: 450 * 1.2 = 540
- Backup: No rank priority → default 1.0x → final score: 200 * 1.0 = 200
- **Difference:** 60 point boost (13% increase)

**Option B (Linear):**
- Mahomes: multiplier = 1.0 + ((300-5)/300)*0.2 = 1.197x → 450 * 1.197 = 539
- Backup: No rank priority → 1.0x → 200
- **Difference:** ~60 point boost (similar to config)

**Option C (Exponential):**
- Mahomes: multiplier = 1.0 + (300/5)*0.05 = 4.0x → 450 * 4.0 = 1800 (!)
- Backup: 200
- **Difference:** 1350 point boost (300% increase!) - probably too extreme

**Key differences:**
- **Config:** You can tune ranges exactly how you want
- **Linear:** Automatic calculation, but fixed impact
- **Exponential:** Very high impact for top picks (might be too much)

**My recommendation:** Start with config-based Option A with conservative multipliers:
- rank priority 1-50: 1.15x (15% boost)
- rank priority 51-100: 1.08x (8% boost)
- rank priority 101-200: 1.03x (3% boost)
- rank priority 201+: 1.0x (neutral)

This gives top picks a noticeable boost without dominating the scoring.

**Does that help clarify? Which option do you prefer?**
```

**User decides:**

```bash
Okay, config-based with your recommended ranges sounds good. Let's go with Option A.
```

**Agent updates IMMEDIATELY:**

{Same update process as Example 1...}

---

### Example 3: User Suggests Alternative

**Agent asks Question 5:**

```markdown
## Question 5: Behavior When rank priority CSV Missing

**Context:** Need to handle case where rank priority CSV file is missing or can't be read.

**Options:**

A. **Fail with error**
   - Stop execution, force user to provide file
   - Pros: Ensures data is loaded
   - Cons: Breaks recommendation engine if file missing

B. **Default all items to neutral (1.0)**
   - Log warning, continue without rank priority
   - Pros: Graceful degradation
   - Cons: Silent failure

C. **Prompt for file location**
   - Interactive recovery
   - Pros: User-friendly
   - Cons: Requires interaction

**My recommendation:** Option B (graceful degradation)

**What do you prefer?**
```

**User suggests alternative:**

```text
How about a hybrid approach? Try to load the file, and if it fails, show a prominent warning but continue. However, if the user explicitly enabled --use-rank flag, then fail with error since they clearly wanted rank data.

That way:
- Default behavior: graceful degradation
- Explicit rank priority flag: fail if missing (user expects it)
```

**Agent incorporates alternative:**

```markdown
Excellent idea! That's better than my options. Let me update the spec with your hybrid approach:

**Updated Approach (User-Suggested):**

1. **Check if --use-rank flag provided (command-line argument)**

2. **If --use-rank flag:**
   - Try to load rank priority CSV
   - If missing/unreadable: FAIL with clear error message
     - Error: "rank priority CSV not found at {path}. Provide file or remove --use-rank flag."
   - Rationale: User explicitly requested rank data, should fail if unavailable

3. **If NO --use-rank flag (default):**
   - Try to load rank priority CSV
   - If missing/unreadable: Log WARNING, continue with all multipliers = 1.0
     - Warning: "rank priority CSV not found, using neutral multipliers. Use --use-rank to require rank data."
   - Rationale: Graceful degradation, doesn't break existing functionality

**Benefits of this approach:**
- ✅ Default behavior: robust, doesn't break
- ✅ Explicit mode: fail-fast, ensures data quality
- ✅ Clear messaging: user knows what happened

**I'll update the spec with this logic. Does that match your intent?**
```

**User confirms:**

```text
Perfect, that's exactly what I meant.
```

**Agent updates spec.md with alternative:**

```markdown
### Requirement 6: Handle Missing rank priority CSV

**Description:** Gracefully handle missing or unreadable rank priority CSV file, with behavior dependent on user intent

**Source:** User Answer to Checklist Question 5 (user-suggested hybrid approach)
**Traceability:** User confirmed on 2026-01-10

**Implementation:**

**1. Add command-line flag:**
```
## run_[module].py
parser.add_argument('--use-rank', action='store_true',
                   help='Require rank data (fail if CSV missing)')
```markdown

**2. rank priority loading logic:**
```
def load_rank_data_with_fallback(filepath: Path, require: bool = False) -> Dict[str, int]:
    """Load rank data with graceful degradation or strict mode.

    Args:
        filepath: Path to rank priority CSV
        require: If True, raise exception if file missing (--use-rank flag)

    Returns:
        Dictionary of rank data, or empty dict if file missing (when require=False)

    Raises:
        FileNotFoundError: If require=True and file missing
    """
    try:
        return load_rank_data(filepath)
    except FileNotFoundError:
        if require:
            # User explicitly wanted rank data, fail with clear error
            raise FileNotFoundError(
                f"rank priority CSV not found at {filepath}. "
                f"Provide file or remove --use-rank flag."
            )
        else:
            # Default mode: graceful degradation
            logger.warning(
                f"rank priority CSV not found at {filepath}. "
                f"Using neutral multipliers (1.0). "
                f"Use --use-rank to require rank data."
            )
            return {}  # Empty dict, all items default to 1.0
```bash

**Edge Cases:**
- User runs `python run_[module].py` (no flag)
  - Missing CSV: WARNING logged, continues with multipliers = 1.0
- User runs `python run_[module].py --use-rank`
  - Missing CSV: ERROR raised, execution stops
- CSV exists but corrupt:
  - Same behavior as missing (handled by try/except)
```

---

## Phase 4 Examples: Dynamic Scope Adjustment
