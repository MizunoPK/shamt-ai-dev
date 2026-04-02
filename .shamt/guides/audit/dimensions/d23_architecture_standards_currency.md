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

**Completeness - Undocumented Additions (Semi-Automated):**
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
        echo "  ✅ $dir - documented"
      else
        echo "  ❌ $dir - NOT DOCUMENTED"
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
      echo "  ⚠️  $CHANGES commits touched dependency files - review for undocumented deps"
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

**Purpose:** Detect when codebase has grown beyond what's documented - catches changes made by teammates, other tools, or forgotten commits.

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

# -> Add cache/ module documentation to ARCHITECTURE.md
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
   - If doc is correct -> Plan codebase fixes (separate epic)
   - If practice is better -> Update doc
   - If both valid -> Document both as alternatives
3. Present reconciliation plan to user
4. Implement agreed changes

---

## See Also

- **D1: Cross-Reference Accuracy** - Related file path validation
- **D9: Content Accuracy** - Related content validation patterns
- **S1.P3 Discovery** - Where architecture context is first gathered
- **S7.P3 Final Review** - Where documentation impact is assessed
- **S10 Epic Cleanup** - Where final review occurs
