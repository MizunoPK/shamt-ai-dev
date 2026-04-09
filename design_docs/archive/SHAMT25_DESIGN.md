# SHAMT-25: Architecture & Coding Standards Document Maintenance

**Status:** Implemented
**Created:** 2026-04-01
**Branch:** feat/SHAMT-25 (not yet created)

---

## Problem Statement

ARCHITECTURE.md and CODING_STANDARDS.md are created during project initialization but have no systematic maintenance process. This leads to **document drift** where:

1. **Stale content**: Documents describe patterns that no longer exist or have evolved
2. **Missing content**: New architectural decisions and conventions aren't captured
3. **Reactive updates only**: Current S7.P2 checkbox "ARCHITECTURE.md updated (if architecture changed)" is easily skipped
4. **No validation**: Nothing checks if documented patterns match actual codebase
5. **Lost knowledge**: Implementation decisions made during epics aren't preserved

### Evidence of the Problem

- S7.P2 validation_loop_s7_feature_qc.md line 346 has a checkbox for ARCHITECTURE.md updates, but it's buried in a documentation subsection with no enforcement
- No audit dimension validates these files
- No workflow step explicitly reads these files before implementation
- S1.P3 Discovery doesn't reference existing architecture documentation
- S10 documentation verification doesn't mention these files

### Impact

- New agents don't benefit from documented architecture decisions
- Codebase conventions diverge from documented standards over time
- Architectural knowledge lives only in agent memory (lost on session end)
- Code reviews can't reference authoritative convention docs

---

## Goals

1. **Prevent drift**: Ensure ARCHITECTURE.md and CODING_STANDARDS.md stay current with codebase
2. **Capture decisions**: Document architectural and convention decisions as they're made
3. **Enable validation**: Allow systematic checking of doc accuracy
4. **Low overhead**: Don't add significant time to every feature (most features don't change architecture)
5. **Audit integration**: Enable periodic deep validation through the audit system

### Non-Goals

- Automatic code generation from architecture docs
- Enforcing coding standards via linting (separate concern)
- Versioning these docs independently from the codebase

---

## Proposed Solution

A multi-layered approach with workflow integration and audit validation:

### Layer 1: Workflow Integration (Light Touch)

Add checkpoints at strategic points in the S1-10 workflow where architecture/standards decisions are most likely to occur or be relevant.

### Layer 2: Audit Dimension (Deep Validation)

Add a new audit dimension that periodically validates document accuracy and freshness.

### Layer 3: Template Enhancements

Update the initialization templates to include metadata that supports maintenance.

---

## Detailed Design

### 1. S1.P3 Discovery Enhancement

**File:** `.shamt/guides/stages/s1/s1_p3_discovery_phase.md`

**Change:** Add "Architecture Context" section to Discovery template and process.

**New Section in DISCOVERY.md Template:**

```markdown
## Architecture Context

**ARCHITECTURE.md Review Date:** {YYYY-MM-DD}

### Relevant Existing Architecture
{Summary of components/patterns from ARCHITECTURE.md that this epic will interact with}

### Potential Architecture Changes
- [ ] This epic may add new modules/services
- [ ] This epic may change data flow patterns
- [ ] This epic may introduce new integration patterns
- [ ] This epic may add new dependencies
- [ ] No architecture changes expected

### Notes
{Any observations about current architecture docs — outdated sections, missing components, etc.}
```

**Process Addition to S1.P3.1 (Initialize Discovery Document):**

After Step 3 (Conduct Initial Research), add:

```markdown
### Step 3b: Review Architecture Context

1. Read ARCHITECTURE.md (if exists)
2. Read CODING_STANDARDS.md (if exists)
3. **Check for undocumented additions** (teammate changes, external updates):
   - Compare top-level source directories against ARCHITECTURE.md
   - Check if any new directories/modules exist that aren't documented
   - Check git log since Last Updated for dependency changes
   - If undocumented additions found: note them and plan to update docs during this epic
4. Document in DISCOVERY.md:
   - Which existing components/patterns are relevant
   - Whether this epic might require updates to either file
   - Any inaccuracies or undocumented additions noticed
   - Undocumented additions that should be addressed

### Undocumented Additions Quick Check

```bash
# Run at start of S1.P3 to detect teammate changes
LAST_UPDATED=$(grep -i "last updated" ARCHITECTURE.md | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
echo "ARCHITECTURE.md last updated: $LAST_UPDATED"
echo ""
echo "Source directories not mentioned in ARCHITECTURE.md:"
for dir in src/*/ app/*/ lib/*/; do
  [ -d "$dir" ] && ! grep -qi "$(basename $dir)" ARCHITECTURE.md && echo "  - $dir"
done
echo ""
echo "Commits since last update:"
git log --since="$LAST_UPDATED" --oneline | head -10
```
```

**Rationale:** Reading these docs during Discovery ensures the agent understands existing architecture before proposing features, surfaces any obvious staleness early, and **catches teammate changes that occurred between epics**.

---

### 2. S7.P3 Enhancement: Documentation Impact Assessment

**File:** `.shamt/guides/stages/s7/s7_p3_final_review.md`

**Change:** Add mandatory "Documentation Impact Assessment" step after PR validation loop, before Lessons Learned.

**New Section (Insert after Step 1, before Step 2):**

```markdown
## Step 1b: Documentation Impact Assessment

**Purpose:** Ensure architectural and convention decisions from this feature are captured in project documentation.

**Time:** 5-10 minutes

### Process

**1b-1. Review Feature Changes**

Consider what this feature introduced:
- New modules, classes, or services?
- New integration patterns or data flows?
- New coding patterns that should be followed?
- Decisions about how to handle specific scenarios?

**1b-2. Answer Assessment Questions**

Complete this checklist in the feature README.md:

```markdown
## Documentation Impact Assessment

**Date:** {YYYY-MM-DD}

### Architecture Impact
- [ ] This feature added new modules/services → Update ARCHITECTURE.md
- [ ] This feature changed data flow or integration patterns → Update ARCHITECTURE.md
- [ ] This feature added significant dependencies → Update ARCHITECTURE.md
- [ ] No architecture changes

### Coding Standards Impact
- [ ] This feature established patterns others should follow → Update CODING_STANDARDS.md
- [ ] This feature made convention decisions (naming, structure, etc.) → Update CODING_STANDARDS.md
- [ ] This feature revealed existing conventions are problematic → Update CODING_STANDARDS.md
- [ ] No coding standards changes

### Actions Taken
- [ ] Reviewed ARCHITECTURE.md — no updates needed
- [ ] Reviewed CODING_STANDARDS.md — no updates needed
- [ ] Updated ARCHITECTURE.md: {describe changes}
- [ ] Updated CODING_STANDARDS.md: {describe changes}
- [ ] Noted issues for S10 guide update process: {describe}
```

**1b-3. Make Updates (If Needed)**

If any checkbox indicates updates needed:
1. Open the relevant file
2. Add/modify the relevant section
3. Update the "Last Updated" date
4. Add entry to "Update History" table
5. Continue to Step 2 (Lessons Learned)

**⚠️ CRITICAL:** Do NOT proceed to Step 2 without completing this assessment. Even if no updates are needed, the assessment must be documented.
```

**Rationale:** S7.P3 is the natural point where a feature is complete and decisions are fresh. Making this mandatory ensures every feature is evaluated.

---

### 3. S10 Enhancement: Architecture/Standards Final Review

**File:** `.shamt/guides/stages/s10/s10_epic_cleanup.md`

**Change:** Enhance Step 3 (Documentation Verification) to include explicit review of these files.

**Addition to Step 3:**

```markdown
### 3e. Review Architecture and Coding Standards Documents

**Purpose:** Ensure epic-level changes are reflected in project documentation.

**Process:**

1. **Review ARCHITECTURE.md:**
   - Read the current document
   - Compare against changes made in this epic
   - Check: Are all new components/modules documented?
   - Check: Are data flows still accurate?
   - Check: Are integration patterns current?

2. **Review CODING_STANDARDS.md:**
   - Read the current document
   - Consider patterns established across all features
   - Check: Are new conventions documented?
   - Check: Do documented conventions match what we actually did?

3. **Cross-Feature Pattern Check:**
   - Did multiple features establish the same pattern? → Document it
   - Did we make consistent decisions about similar problems? → Document them
   - Did we deviate from documented conventions? → Either fix code or update doc

4. **Document Review Results:**

```markdown
## Architecture/Standards Review (S10)

**Review Date:** {YYYY-MM-DD}

### ARCHITECTURE.md
- [ ] Reviewed and current — no updates needed
- [ ] Updated: {list changes made}
- [ ] Issues noted for future: {list}

### CODING_STANDARDS.md
- [ ] Reviewed and current — no updates needed
- [ ] Updated: {list changes made}
- [ ] Issues noted for future: {list}

### Cross-Feature Patterns Documented
- {Pattern 1}: Added to {file}
- {Pattern 2}: Added to {file}
- None identified
```
```

**Rationale:** S10 is the last chance to capture knowledge before the epic is archived. The cross-feature perspective is valuable for identifying patterns that emerged organically.

---

### 4. New Audit Dimension: D23 — Architecture/Standards Currency

**File:** `.shamt/guides/audit/dimensions/d23_architecture_standards_currency.md` (new file)

```markdown
# D23: Architecture/Standards Currency

**Dimension Number:** 23
**Category:** Documentation Quality Dimensions
**Automation Level:** 50% automated
**Priority:** MEDIUM
**Last Updated:** 2026-04-01

**Focus:** Ensure ARCHITECTURE.md and CODING_STANDARDS.md accurately reflect the codebase
**Typical Issues Found:** 3-8 per audit

---

## Table of Contents

1. [What This Checks](#what-this-checks)
2. [Why This Matters](#why-this-matters)
3. [Automated Validation](#automated-validation)
4. [Manual Validation](#manual-validation)
5. [Common Issues](#common-issues)
6. [Remediation Patterns](#remediation-patterns)

---

## What This Checks

### ARCHITECTURE.md Validation

**Existence & Metadata:**
- [ ] File exists at expected location
- [ ] Has "Last Updated" date field
- [ ] Last Updated within acceptable freshness (60 days or justified)
- [ ] Has "Update History" table

**Reference Accuracy:**
- [ ] All file paths referenced actually exist
- [ ] All folder paths referenced actually exist
- [ ] All module/class names referenced exist in codebase

**Content Accuracy (Manual):**
- [ ] Component descriptions match actual implementation
- [ ] Data flow descriptions reflect current architecture
- [ ] Integration patterns described are actually used
- [ ] No deprecated patterns documented as current

**Completeness — Undocumented Additions (Semi-Automated):**
- [ ] All top-level source directories are mentioned in doc
- [ ] All significant modules (>5 files or >500 LOC) are documented
- [ ] New dependencies added since Last Updated are documented
- [ ] New configuration files/patterns are documented
- [ ] No major components missing from documentation

### CODING_STANDARDS.md Validation

**Existence & Metadata:**
- [ ] File exists at expected location
- [ ] Has "Last Updated" date field
- [ ] Last Updated within acceptable freshness (60 days or justified)
- [ ] Has "Update History" table

**Convention Accuracy (Manual - Sample Check):**
- [ ] Sample 3-5 documented conventions
- [ ] Each sampled convention matches actual codebase practice
- [ ] No rules that codebase systematically violates
- [ ] Code examples in doc compile/run correctly

**Completeness:**
- [ ] Major coding patterns in codebase are documented
- [ ] Project-specific conventions are captured
- [ ] No significant undocumented conventions

---

## Why This Matters

### Impact of Stale Architecture Docs

- **Wrong mental model:** Agents plan features against incorrect architecture
- **Integration failures:** Code assumes components that don't exist or work differently
- **Lost knowledge:** Architectural decisions not preserved for future reference
- **Onboarding friction:** New agents can't trust documentation

### Impact of Undocumented Additions

- **Hidden complexity:** Agent doesn't know about modules that exist
- **Duplicate work:** Agent rebuilds functionality that already exists
- **Integration blind spots:** New components may have undocumented interfaces
- **Dependency surprises:** Build/deploy issues from undocumented dependencies

### Impact of Stale Coding Standards

- **Inconsistent code:** Without authoritative conventions, styles diverge
- **Review friction:** No reference point for "correct" style
- **Repeated debates:** Same convention decisions made repeatedly
- **Technical debt:** Bad patterns propagate without documented alternatives

---

## Automated Validation

### Script: Check Architecture/Standards Files

```bash
#!/bin/bash
# D23 Automated Checks

echo "=== D23: Architecture/Standards Currency ==="

# Check file existence
for file in ARCHITECTURE.md CODING_STANDARDS.md; do
  if [ -f "$file" ]; then
    echo "✅ $file exists"
  else
    echo "❌ $file NOT FOUND"
  fi
done

# Check Last Updated dates
echo ""
echo "=== Last Updated Dates ==="
for file in ARCHITECTURE.md CODING_STANDARDS.md; do
  if [ -f "$file" ]; then
    LAST_UPDATED=$(grep -i "last updated" "$file" | head -1)
    echo "$file: $LAST_UPDATED"

    # Extract date and check freshness
    DATE=$(echo "$LAST_UPDATED" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
    if [ -n "$DATE" ]; then
      DAYS_OLD=$(( ($(date +%s) - $(date -d "$DATE" +%s)) / 86400 ))
      if [ "$DAYS_OLD" -gt 60 ]; then
        echo "  ⚠️  STALE: $DAYS_OLD days old"
      else
        echo "  ✅ Fresh: $DAYS_OLD days old"
      fi
    fi
  fi
done

# Check file path references in ARCHITECTURE.md
echo ""
echo "=== File Path Reference Check (ARCHITECTURE.md) ==="
if [ -f "ARCHITECTURE.md" ]; then
  grep -oE '\b(src|lib|app|tests|scripts)/[a-zA-Z0-9_/]+\.(py|ts|js|tsx|jsx|md)\b' ARCHITECTURE.md | \
    sort -u | while read path; do
      if [ -f "$path" ]; then
        echo "✅ $path"
      else
        echo "❌ BROKEN: $path"
      fi
    done
fi

# Check for Update History table
echo ""
echo "=== Update History Check ==="
for file in ARCHITECTURE.md CODING_STANDARDS.md; do
  if [ -f "$file" ]; then
    if grep -q "Update History" "$file"; then
      echo "✅ $file has Update History"
    else
      echo "⚠️  $file missing Update History table"
    fi
  fi
done

# Check for undocumented source directories
echo ""
echo "=== Undocumented Additions Check ==="
if [ -f "ARCHITECTURE.md" ]; then
  echo "Top-level source directories:"
  for dir in src/*/ app/*/ lib/*/ 2>/dev/null; do
    if [ -d "$dir" ]; then
      dirname=$(basename "$dir")
      if grep -qi "$dirname" ARCHITECTURE.md; then
        echo "  ✅ $dir — documented"
      else
        echo "  ❌ $dir — NOT DOCUMENTED"
      fi
    fi
  done

  # Check for dependency changes since Last Updated
  LAST_UPDATED=$(grep -i "last updated" ARCHITECTURE.md | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
  if [ -n "$LAST_UPDATED" ]; then
    echo ""
    echo "Dependency file changes since $LAST_UPDATED:"
    CHANGES=$(git log --since="$LAST_UPDATED" --oneline -- package.json pyproject.toml requirements.txt Cargo.toml go.mod 2>/dev/null | wc -l)
    if [ "$CHANGES" -gt 0 ]; then
      echo "  ⚠️  $CHANGES commits touched dependency files — review for undocumented deps"
      git log --since="$LAST_UPDATED" --oneline -- package.json pyproject.toml requirements.txt Cargo.toml go.mod 2>/dev/null | head -5
    else
      echo "  ✅ No dependency file changes"
    fi
  fi
fi
```

---

## Manual Validation

### Architecture Accuracy Check

1. **Select 3 major components** described in ARCHITECTURE.md
2. **For each component:**
   - Locate actual implementation files
   - Verify description matches reality
   - Check if interfaces/APIs match documentation
   - Verify dependencies are accurate

3. **Document findings:**
```markdown
### Architecture Accuracy Sample Check

| Component | Doc Location | Matches Reality? | Issues |
|-----------|--------------|------------------|--------|
| {Component 1} | Line {N} | ✅ / ❌ | {description} |
| {Component 2} | Line {N} | ✅ / ❌ | {description} |
| {Component 3} | Line {N} | ✅ / ❌ | {description} |
```

### Coding Standards Accuracy Check

1. **Select 5 documented conventions** from CODING_STANDARDS.md
2. **For each convention:**
   - Search codebase for examples
   - Verify code follows the convention
   - Note any systematic violations

3. **Document findings:**
```markdown
### Coding Standards Sample Check

| Convention | Doc Location | Followed? | Violation Examples |
|------------|--------------|-----------|-------------------|
| {Convention 1} | Line {N} | ✅ / ❌ | {file:line if violated} |
| {Convention 2} | Line {N} | ✅ / ❌ | {file:line if violated} |
| {Convention 3} | Line {N} | ✅ / ❌ | {file:line if violated} |
| {Convention 4} | Line {N} | ✅ / ❌ | {file:line if violated} |
| {Convention 5} | Line {N} | ✅ / ❌ | {file:line if violated} |
```

### Undocumented Additions Check (Reverse Drift)

**Purpose:** Detect when codebase has grown beyond what's documented — catches changes made by teammates, other tools, or forgotten commits.

1. **List top-level source directories:**
   ```bash
   # Find all top-level dirs in src/ (or equivalent)
   ls -d src/*/ app/*/ lib/*/ 2>/dev/null | sort
   ```

2. **Compare against ARCHITECTURE.md:**
   - For each directory, search for mention in ARCHITECTURE.md
   - Flag any directory not mentioned

3. **Check for new dependencies since Last Updated:**
   ```bash
   # Get Last Updated date from doc
   LAST_UPDATED=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' ARCHITECTURE.md | head -1)

   # Check git log for dependency file changes since then
   git log --since="$LAST_UPDATED" --oneline -- package.json pyproject.toml requirements.txt Cargo.toml
   ```

4. **Check for new config files/patterns:**
   ```bash
   # Find config files added since Last Updated
   git log --since="$LAST_UPDATED" --diff-filter=A --name-only -- '*.config.*' '*.json' '*.yaml' '*.toml' | sort -u
   ```

5. **Document findings:**
```markdown
### Undocumented Additions Check

**Last Updated in ARCHITECTURE.md:** {date}

| Item | Type | In Codebase Since | Documented? |
|------|------|-------------------|-------------|
| src/cache/ | Directory | 2026-03-15 | ❌ Missing |
| redis | Dependency | 2026-03-15 | ❌ Missing |
| docker-compose.yaml | Config | 2026-03-20 | ❌ Missing |

**Action Required:** Update ARCHITECTURE.md to include these additions.
```

---

## Common Issues

### Issue 1: Stale Last Updated Date

**Pattern:** Last Updated shows date from 3+ months ago despite recent changes

**Detection:** Automated date check

**Fix:**
- Review document content
- Update stale sections
- Update Last Updated date
- Add Update History entry

### Issue 2: Broken File References

**Pattern:** ARCHITECTURE.md references files that were moved/renamed/deleted

**Detection:** Automated path check

**Fix:**
- Update paths to current locations
- Remove references to deleted files
- Add references to new files

### Issue 3: Documented Convention Not Followed

**Pattern:** CODING_STANDARDS.md says "use X pattern" but codebase uses Y

**Detection:** Manual sample check

**Fix (choose one):**
- Update codebase to follow convention (if convention is correct)
- Update documentation to reflect actual practice (if practice is better)
- Document both as acceptable alternatives (if both are valid)

### Issue 4: Missing Major Component

**Pattern:** Significant module/service exists in codebase but not in ARCHITECTURE.md

**Detection:** Manual review during audit or epic completion

**Fix:**
- Add component documentation section
- Document purpose, interfaces, dependencies
- Update data flow diagrams if applicable

### Issue 5: Deprecated Pattern Still Documented

**Pattern:** Document describes pattern that was replaced in recent epic

**Detection:** Manual review, cross-reference with recent epic changes

**Fix:**
- Mark old pattern as deprecated OR remove entirely
- Add new pattern documentation
- Add Update History entry explaining change

### Issue 6: Undocumented Additions (Reverse Drift)

**Pattern:** New modules, dependencies, or patterns exist in codebase but aren't documented

**Cause:**
- Teammate made changes outside the Shamt workflow
- Dependency updates via automated tools (Dependabot, etc.)
- Hotfixes or quick changes that skipped documentation
- Another agent's epic that didn't update docs properly

**Detection:**
- Automated: Compare source directories against doc mentions
- Automated: Check git log for dependency file changes since Last Updated
- Manual: Review recent PRs/commits for architectural additions

**Fix:**
- Document the new component/dependency/pattern
- Update Last Updated date
- Add Update History entry
- If change is significant, consider whether it warrants architecture review

**Example:**
```bash
# Teammate added a new caching layer without updating docs
$ ls src/
api/  cache/  models/  utils/

$ grep -i "cache" ARCHITECTURE.md
# (no results)

# → Add cache/ module documentation to ARCHITECTURE.md
```

---

## Remediation Patterns

### Pattern 1: Full Document Refresh

**When:** Document is significantly stale (>6 months, many broken references)

**Process:**
1. Archive current document (copy to `archive/ARCHITECTURE_old.md`)
2. Start fresh using template
3. Document current architecture from codebase analysis
4. Review with user before committing

### Pattern 2: Incremental Update

**When:** Document is mostly current with a few issues

**Process:**
1. Fix broken references
2. Update stale sections
3. Add missing components
4. Update Last Updated and History
5. Commit with descriptive message

### Pattern 3: Convention Reconciliation

**When:** CODING_STANDARDS.md conflicts with actual practice

**Process:**
1. List all conflicts
2. For each conflict, determine which is "correct":
   - If doc is correct → Plan codebase fixes (separate epic)
   - If practice is better → Update doc
   - If both valid → Document both as alternatives
3. Present reconciliation plan to user
4. Implement agreed changes

---

## See Also

- **D1: Cross-Reference Accuracy** — Related file path validation
- **D9: Content Accuracy** — Related content validation patterns
- **S1.P3 Discovery** — Where architecture context is first gathered
- **S7.P3 Final Review** — Where documentation impact is assessed
- **S10 Epic Cleanup** — Where final review occurs
```

---

### 5. Template Enhancements

**File:** `.shamt/scripts/initialization/ARCHITECTURE.template.md`

**Changes:** Add metadata section and update guidance.

```markdown
# {PROJECT_NAME} Architecture

**Last Updated:** {YYYY-MM-DD}
**Maintained By:** AI agents during epic workflow (S7.P3, S10)

---

## Update History

| Date | Change | Epic/Reason |
|------|--------|-------------|
| {YYYY-MM-DD} | Initial creation | Project initialization |

---

## Update Triggers

Update this document when:
- New modules, services, or major components are added
- Data flow between components changes
- Integration patterns are added or modified
- Significant dependencies are added
- Architectural decisions are made that affect multiple features

---

## How to Update

1. Make changes to relevant sections
2. Update "Last Updated" date at top
3. Add row to "Update History" table
4. Commit with message: "docs: Update ARCHITECTURE.md — {brief description}"

---

{... rest of template content ...}
```

**File:** `.shamt/scripts/initialization/CODING_STANDARDS.template.md`

**Changes:** Add metadata section and update guidance.

```markdown
# {PROJECT_NAME} Coding Standards

**Last Updated:** {YYYY-MM-DD}
**Maintained By:** AI agents during epic workflow (S7.P3, S10)

---

## Update History

| Date | Change | Epic/Reason |
|------|--------|-------------|
| {YYYY-MM-DD} | Initial creation | Project initialization |

---

## Update Triggers

Update this document when:
- New coding patterns are established that others should follow
- Convention decisions are made (naming, structure, organization)
- Existing conventions are found problematic and changed
- Project-specific rules emerge from implementation experience

---

## How to Update

1. Make changes to relevant sections
2. Update "Last Updated" date at top
3. Add row to "Update History" table
4. Commit with message: "docs: Update CODING_STANDARDS.md — {brief description}"

---

{... rest of template content ...}
```

---

### 6. S7.P2 Dimension Update

**File:** `.shamt/guides/reference/validation_loop_s7_feature_qc.md`

**Change:** Elevate the architecture/standards check from a sub-bullet to a proper dimension component.

**Current (line ~346):**
```markdown
**Documentation:**
- [ ] All public functions have docstrings
- [ ] Complex logic has explanatory comments
- [ ] ARCHITECTURE.md updated (if architecture changed)
- [ ] README.md updated (if user-facing changes)
```

**Proposed:**
```markdown
**Documentation:**
- [ ] All public functions have docstrings
- [ ] Complex logic has explanatory comments
- [ ] README.md updated (if user-facing changes)

**Architecture/Standards Currency (see S7.P3 Step 1b for full assessment):**
- [ ] Considered whether this feature impacts ARCHITECTURE.md
- [ ] Considered whether this feature impacts CODING_STANDARDS.md
- [ ] If impacts identified: Flag for S7.P3 Step 1b assessment
```

**Rationale:** Move the actual update decision to S7.P3 where it gets proper attention, but keep awareness in S7.P2.

---

## Files Affected

| File | Change Type | Description |
|------|-------------|-------------|
| `.shamt/guides/stages/s1/s1_p3_discovery_phase.md` | Modify | Add Architecture Context section |
| `.shamt/guides/templates/discovery_template.md` | Modify | Add Architecture Context template |
| `.shamt/guides/stages/s7/s7_p3_final_review.md` | Modify | Add Step 1b Documentation Impact Assessment |
| `.shamt/guides/stages/s10/s10_epic_cleanup.md` | Modify | Add Step 3e Architecture/Standards Review |
| `.shamt/guides/audit/dimensions/d23_architecture_standards_currency.md` | Create | New audit dimension |
| `.shamt/guides/audit/README.md` | Modify | Add D23 to dimension list |
| `.shamt/guides/audit/audit_overview.md` | Modify | Update dimension count |
| `.shamt/guides/reference/validation_loop_s7_feature_qc.md` | Modify | Update documentation check |
| `.shamt/scripts/initialization/ARCHITECTURE.template.md` | Modify | Add metadata sections |
| `.shamt/scripts/initialization/CODING_STANDARDS.template.md` | Modify | Add metadata sections |
| `CLAUDE.md` (master) | Modify | Reference new maintenance workflow |
| `.shamt/scripts/initialization/RULES_FILE.template.md` | Modify | Reference maintenance workflow for child projects |

---

## Implementation Order

1. **Phase 1: Templates** (foundation)
   - Update ARCHITECTURE.template.md
   - Update CODING_STANDARDS.template.md

2. **Phase 2: Workflow Integration** (main changes)
   - Update s1_p3_discovery_phase.md + discovery_template.md
   - Update s7_p3_final_review.md
   - Update s10_epic_cleanup.md
   - Update validation_loop_s7_feature_qc.md

3. **Phase 3: Audit Dimension** (validation layer)
   - Create d23_architecture_standards_currency.md
   - Update audit/README.md
   - Update audit_overview.md

4. **Phase 4: Master Files** (propagation)
   - Update CLAUDE.md (master)
   - Update RULES_FILE.template.md

5. **Phase 5: Audit** (validation)
   - Run full guide audit
   - Fix any issues

---

## Open Questions

1. **Freshness threshold:** Is 60 days the right threshold for "stale" in D23? Should it be configurable per project?

2. **Enforcement level:** Should the S7.P3 Documentation Impact Assessment be a blocking gate, or advisory? Currently proposed as mandatory but not blocking.

3. **Audit frequency:** Should D23 be part of every audit, or only periodic deep audits?

4. **Child project adoption:** When child projects import updated guides, their existing ARCHITECTURE.md and CODING_STANDARDS.md won't have the new metadata fields. Should the import process add them, or leave existing files alone?

5. **Retroactive application:** Should we add guidance for projects that already have these files without the metadata? Create a migration guide?

6. **Teammate changes trigger:** When a teammate (or external process like Dependabot) makes changes outside the Shamt workflow, when should the agent check for undocumented additions?
   - Option A: At every S1.P3 Discovery (before starting new epic)
   - Option B: Only during D23 audit runs
   - Option C: Add a standalone "sync check" command that can be run on demand
   - Option D: All of the above

7. **Scope of undocumented additions check:** How deep should the automated check go?
   - Top-level directories only?
   - All directories with >N files?
   - Include individual significant files (e.g., new entry points)?

---

## Alternatives Considered

### Alternative A: Automatic Generation

**Idea:** Generate ARCHITECTURE.md automatically from codebase analysis.

**Rejected because:**
- Architecture docs capture intent and decisions, not just structure
- Automated generation produces shallow documentation
- Loses the human context of "why" decisions were made

### Alternative B: Version Control Integration

**Idea:** Use git hooks to enforce updates when certain files change.

**Rejected because:**
- Too rigid — not every code change needs doc update
- Hard to implement cross-platform
- Shamt workflow already has appropriate checkpoints

### Alternative C: Separate Documentation Epic

**Idea:** Create documentation-only epics periodically to update these files.

**Rejected because:**
- Delays knowledge capture (context lost by the time doc epic runs)
- Creates artificial separation between code and documentation
- Current proposal captures knowledge at the right time (feature completion)

---

## Success Criteria

1. **Measurable:** After 3 epics using new workflow, ARCHITECTURE.md and CODING_STANDARDS.md have been reviewed at each S7.P3 and S10 checkpoint (audit trail exists)

2. **Measurable:** D23 audit dimension can be run and produces actionable findings

3. **Qualitative:** Agents report that reading ARCHITECTURE.md during S1.P3 Discovery provides useful context

4. **Qualitative:** Document Last Updated dates stay within 60 days during active development

---

## Appendix: Example Documentation Impact Assessment

**Feature:** Add caching layer to API client

**S7.P3 Step 1b Assessment:**

```markdown
## Documentation Impact Assessment

**Date:** 2026-04-01

### Architecture Impact
- [x] This feature added new modules/services → Update ARCHITECTURE.md
  - Added: `src/cache/` module with Redis integration
- [ ] This feature changed data flow or integration patterns → Update ARCHITECTURE.md
- [x] This feature added significant dependencies → Update ARCHITECTURE.md
  - Added: redis-py dependency
- [ ] No architecture changes

### Coding Standards Impact
- [x] This feature established patterns others should follow → Update CODING_STANDARDS.md
  - Cache key naming convention: `{service}:{entity}:{id}`
- [ ] This feature made convention decisions (naming, structure, etc.) → Update CODING_STANDARDS.md
- [ ] This feature revealed existing conventions are problematic → Update CODING_STANDARDS.md
- [ ] No coding standards changes

### Actions Taken
- [ ] Reviewed ARCHITECTURE.md — no updates needed
- [ ] Reviewed CODING_STANDARDS.md — no updates needed
- [x] Updated ARCHITECTURE.md: Added Cache Layer section, updated dependency list
- [x] Updated CODING_STANDARDS.md: Added cache key naming convention
- [ ] Noted issues for S10 guide update process: {describe}
```

---

*End of SHAMT-25 Design Document*
