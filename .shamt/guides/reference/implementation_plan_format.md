# Implementation Plan Format Reference

**Purpose:** Specification for creating mechanical, executable implementation plans for the architect-builder pattern

**Last Updated:** 2026-04-04 (SHAMT-30)

---

## Overview

Implementation plans are **mechanically executable** documents that translate spec requirements into exact file operations. They are validated before execution and handed off to Haiku builder agents for mechanical execution.

**Key Principle:** Every step must be executable without design decisions. If a builder agent needs to make a choice, the plan is incomplete.

---

## File Structure

```markdown
# Implementation Plan: {Feature Name}

**Architect:** {architect context - e.g., "Primary agent for epic EPIC-001"}
**Created:** {timestamp}
**Validation Status:** Validated | Not Validated

## Pre-Execution Checklist
- [ ] All affected files identified
- [ ] Design validated via validation loop
- [ ] Edge cases documented
- [ ] Rollback strategy defined

## Implementation Steps

{Steps go here - see Step Format section below}

## Post-Execution Checklist
- [ ] All steps completed without error
- [ ] Verification checks passed
- [ ] Tests run (if applicable)
- [ ] Ready for handoff back to architect
```

---

## Step Format Specification

Each step follows this exact structure:

```markdown
### Step {N}: {Action Description}
**File:** `path/to/file.ts`
**Operation:** {EDIT | CREATE | DELETE | MOVE}
**Details:**
{Operation-specific details - see below}
**Verification:** {How to verify this step succeeded}
```

### Operation Types

#### EDIT Operation

```markdown
### Step 15: Add authentication middleware import
**File:** `src/server.ts`
**Operation:** EDIT
**Details:**
- Locate: `import { cors } from 'cors';`
- Replace with: `import { cors } from 'cors';\nimport { authenticate } from './middleware/auth';`
**Verification:** Read src/server.ts, confirm authenticate import present after cors import
```

**Requirements:**
- `Locate` string must be exact (including whitespace, quotes, semicolons)
- `Replace with` string must be exact with explicit newlines (`\n`) where needed
- Locate string must be unique in the file (or provide sufficient context to make it unique)

#### CREATE Operation

```markdown
### Step 23: Create authentication middleware file
**File:** `src/middleware/auth.ts`
**Operation:** CREATE
**Details:**
```
export function authenticate(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  // Verify token logic here
  next();
}
```
**Verification:** File src/middleware/auth.ts exists, contains authenticate function export
```

**Requirements:**
- Content must be complete, ready to write to file
- Include all necessary imports, exports, types
- Specify exact indentation (spaces or tabs)

#### DELETE Operation

```markdown
### Step 42: Remove deprecated utility file
**File:** `src/utils/old-helper.ts`
**Operation:** DELETE
**Details:**
- Delete entire file
**Verification:** File src/utils/old-helper.ts does not exist
```

**Requirements:**
- Confirm file exists before attempting delete
- Verification checks absence of file

#### MOVE Operation

```markdown
### Step 8: Move config file to new location
**File:** `config/app.json`
**Operation:** MOVE
**Details:**
- Move from: `config/app.json`
- Move to: `src/config/app.json`
**Verification:** File src/config/app.json exists, original config/app.json does not exist
```

**Requirements:**
- Specify both source and destination paths
- Verification checks both absence of old and presence of new

---

## Verification Best Practices

**Good Verifications:**
- ✅ "Read src/server.ts, confirm authenticate middleware call present after cors()"
- ✅ "File exists at path/to/file.ts with export function myFunction"
- ✅ "Run `git status`, confirm src/new-file.ts appears in untracked files"

**Bad Verifications:**
- ❌ "Check that it works" (too vague)
- ❌ "Verify imports are correct" (builder can't determine "correct")
- ❌ "Make sure authentication works" (requires testing, not verification)

**Principle:** Verification should be mechanically checkable by reading file contents or running simple commands.

---

## 9-Dimension Validation Requirements

Before builder handoff, implementation plans MUST be validated using these 9 dimensions:

### 1. Step Clarity
- Every step is unambiguous with no interpretation needed
- Exact file paths and operations specified
- No "TODO" or "TBD" in steps

### 2. Mechanical Executability
- Builder can execute without making design choices
- No "figure it out" gaps
- No steps requiring external knowledge beyond the plan

### 3. File Coverage Completeness
- All files from spec are covered in plan steps
- No missing files
- Files created before they are edited

### 4. Operation Specificity
- EDIT steps have exact locate/replace strings
- CREATE steps have full content
- DELETE/MOVE operations are precise

### 5. Verification Completeness
- Every step has a verification method
- Verifications are checkable by builder (read file, run command)
- No subjective verifications ("looks good")

### 6. Error Handling Clarity
- Success/failure criteria explicit for each step
- Edge cases documented
- What to do if verification fails is clear (report to architect)

### 7. Dependency Ordering
- Steps are in correct execution order
- Create file before editing it
- Dependencies explicit (e.g., "Step 5 must complete before Step 6")

### 8. Pre/Post Checklist Completeness
- Pre-execution checklist covers all prerequisites
- Post-execution checklist confirms completion
- Rollback strategy defined

### 9. Spec Alignment
- Implementation plan faithfully translates ALL spec requirements
- No spec requirements missing
- No additions beyond spec scope

**Exit Criterion:** Primary clean round (≤1 LOW severity issue) + 2 independent Haiku sub-agents confirm zero issues

**See:** `reference/validation_loop_master_protocol.md` for validation loop mechanics

---

## Validation Log Format

Create `implementation_plan_validation_log.md` (or `SHAMT{N}_IMPL_PLAN_VALIDATION_LOG.md` for master work) alongside the implementation plan.

Use template: `templates/implementation_plan_validation_log_template.md`

**Structure:**
```markdown
# Implementation Plan Validation Log

**Plan:** [implementation_plan.md](./implementation_plan.md)
**Validation Started:** {date}
**Status:** In Progress | Validated

## Validation Rounds

### Round 1 - {date}
{9 dimensions checked, issues documented}

### Round 2 - {date}
{...}

## Sub-Agent Confirmations
{Both sub-agents confirm zero issues}

## Final Summary
**consecutive_clean:** {count}
**Status:** Validated
```

---

## File Location Conventions

### Master Work
- Implementation plan: `design_docs/active/SHAMT{N}_IMPLEMENTATION_PLAN.md`
- Validation log: `design_docs/active/SHAMT{N}_IMPL_PLAN_VALIDATION_LOG.md`
- Lives alongside design doc during implementation
- Moves to `design_docs/archive/` with design doc when complete

### Child Epic Work
- Implementation plan: `.shamt/epics/{epic}/features/{feature}/implementation_plan.md`
- Validation log: `.shamt/epics/{epic}/features/{feature}/implementation_plan_validation_log.md`
- Lives alongside spec.md, checklist.md, README.md
- Referenced in S10 lessons learned
- Moves to `epics/done/{epic}/` with rest of epic when complete

### Naming Convention
- Master: `SHAMT{N}_IMPLEMENTATION_PLAN.md` (uppercase, with SHAMT number)
- Child: `implementation_plan.md` (lowercase, standard feature artifact name)

---

## Complete Example

```markdown
# Implementation Plan: User Authentication Feature

**Architect:** Primary agent for EPIC-AUTH-001
**Created:** 2026-04-04
**Validation Status:** Validated

## Pre-Execution Checklist
- [x] All affected files identified (3 files: server.ts, auth.ts, auth.test.ts)
- [x] Design validated via validation loop (2 rounds, both sub-agents confirmed)
- [x] Edge cases documented (missing token, invalid token, expired token)
- [x] Rollback strategy defined (git revert steps documented)

## Implementation Steps

### Step 1: Create authentication middleware file
**File:** `src/middleware/auth.ts`
**Operation:** CREATE
**Details:**
```
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export function authenticate(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}
```
**Verification:** File src/middleware/auth.ts exists, contains authenticate function with JWT verification logic

### Step 2: Add authentication middleware import to server
**File:** `src/server.ts`
**Operation:** EDIT
**Details:**
- Locate: `import { cors } from 'cors';`
- Replace with: `import { cors } from 'cors';\nimport { authenticate } from './middleware/auth';`
**Verification:** Read src/server.ts, confirm authenticate import present after cors import

### Step 3: Apply authentication middleware to protected routes
**File:** `src/server.ts`
**Operation:** EDIT
**Details:**
- Locate: `app.get('/api/profile', (req, res) => {`
- Replace with: `app.get('/api/profile', authenticate, (req, res) => {`
**Verification:** Read src/server.ts, confirm authenticate middleware applied to /api/profile route

### Step 4: Create authentication middleware tests
**File:** `src/middleware/auth.test.ts`
**Operation:** CREATE
**Details:**
```
import { authenticate } from './auth';
import { Request, Response, NextFunction } from 'express';

describe('authenticate middleware', () => {
  it('should reject requests without token', () => {
    const req = { headers: {} } as Request;
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() } as unknown as Response;
    const next = jest.fn() as NextFunction;

    authenticate(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ error: 'No token provided' });
    expect(next).not.toHaveBeenCalled();
  });

  // Additional tests...
});
```
**Verification:** File src/middleware/auth.test.ts exists, contains test for missing token scenario

## Post-Execution Checklist
- [ ] All steps completed without error
- [ ] Verification checks passed (all 4 steps verified)
- [ ] Tests run (npm test passes)
- [ ] Ready for handoff back to architect
```

---

## Common Mistakes to Avoid

### Mistake 1: Vague Locate Strings

❌ **Bad:**
```markdown
**Details:**
- Locate: `import express`
- Replace with: `import express from 'express';\nimport jwt from 'jsonwebtoken';`
```

✅ **Good:**
```markdown
**Details:**
- Locate: `import express from 'express';`
- Replace with: `import express from 'express';\nimport jwt from 'jsonwebtoken';`
```

**Why:** "import express" could match multiple lines. Be exact.

---

### Mistake 2: Incomplete CREATE Content

❌ **Bad:**
```markdown
**Operation:** CREATE
**Details:**
```
// Auth middleware
export function authenticate() {
  // Implementation here
}
```
```

✅ **Good:**
```markdown
**Operation:** CREATE
**Details:**
```
import { Request, Response, NextFunction } from 'express';

export function authenticate(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  next();
}
```
```

**Why:** Builder cannot fill in "Implementation here" - provide complete code.

---

### Mistake 3: Subjective Verification

❌ **Bad:**
```markdown
**Verification:** Make sure the authentication works correctly
```

✅ **Good:**
```markdown
**Verification:** Read src/middleware/auth.ts, confirm JWT verification logic present with error handling for missing/invalid tokens
```

**Why:** "Works correctly" requires testing and judgment. Builder needs mechanical check.

---

### Mistake 4: Missing File Creation Before Edit

❌ **Bad:**
```markdown
### Step 1: Add export to new file
**File:** `src/utils/helper.ts`
**Operation:** EDIT
**Details:**
- Locate: `// Helper functions`
- Replace with: `export function helper() {}\n// Helper functions`
```

✅ **Good:**
```markdown
### Step 1: Create utility file
**File:** `src/utils/helper.ts`
**Operation:** CREATE
**Details:**
```
// Helper functions
```
**Verification:** File src/utils/helper.ts exists

### Step 2: Add export to utility file
**File:** `src/utils/helper.ts`
**Operation:** EDIT
**Details:**
- Locate: `// Helper functions`
- Replace with: `export function helper() {}\n// Helper functions`
**Verification:** Read src/utils/helper.ts, confirm helper function export present
```

**Why:** Can't edit a file that doesn't exist yet. Create first, then edit.

---

## Resume Protocol

If builder execution fails mid-plan, architect can resume from a specific step:

**Handoff package includes:**
```markdown
**Resuming from Partial Execution:**
- If architect fixes plan and wants to resume, they will specify:
  - "Execute steps {N} through {M}" (e.g., "Execute steps 15 through 50")
- Start from the specified step number, skip completed steps
```

**Example:**
- Builder fails at Step 23
- Architect fixes plan
- Architect spawns new builder: "Execute steps 23 through 50"
- New builder starts at Step 23, skips 1-22

---

## Related Documentation

- **Pattern Overview:** `reference/architect_builder_pattern.md`
- **Validation Loop:** `reference/validation_loop_master_protocol.md`
- **Template:** `templates/implementation_plan_template.md`
- **Validation Log Template:** `templates/implementation_plan_validation_log_template.md`
- **Model Selection:** `reference/model_selection.md` (Haiku for builder execution)
