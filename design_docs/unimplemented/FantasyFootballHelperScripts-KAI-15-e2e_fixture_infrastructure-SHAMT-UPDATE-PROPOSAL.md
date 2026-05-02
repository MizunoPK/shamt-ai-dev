# FantasyFootballHelperScripts — KAI-15-e2e_fixture_infrastructure Guide Update Proposals

**Status:** Pending Implementation
**Created:** 2026-03-30
**Source Epic:** KAI-15-e2e_fixture_infrastructure
**Proposals:** 4 accepted, 0 modified, 0 rejected

---

## Overview

KAI-15 established shared fixture infrastructure for deterministic offline E2E integration tests, adding `ESPN_FIXTURE_DIR` (offline mode) and `ESPN_RECORD_FIXTURES_DIR` (fixture recording) env vars across two fetcher packages, plus committed fixture data files and test helpers. The epic surfaced four process gaps: premature git branch creation in S1 (branch sat idle for S1–S5 because `.shamt/` is git-excluded); missing README documentation for new env vars (caught in S9.P4 as M5); uncommitted QC fixes when sub-agents were spawned causing an extra round; and internal planning labels in error messages never cleaned up (caught in S9.P4 as M3).

**Note:** `RULES_FILE.template.md` line 327 also contains "Create git branch" under "Starting S1 Epic Planning" and will need to be updated along with `s1_epic_planning.md` when Proposal P2-1 is implemented.

---

## Proposal P2-1: Move git branch creation from S1 to S6

**Priority:** P2
**Affected Guide(s):**
- `.shamt/guides/stages/s1/s1_epic_planning.md` — Step 1.0: Create Git Branch for Epic
- `.shamt/guides/stages/s6/s6_execution.md` — Workflow Overview + add new Step 0
- `.shamt/scripts/initialization/RULES_FILE.template.md` — line 327 in "Starting S1 Epic Planning"

### Problem

On projects where `.shamt/` is git-excluded, the git branch created in S1 sits completely idle from S1 through S5 — no source code changes are made during planning. The branch has nothing to commit until S6 introduces the first source code change. Creating it in S1 is premature and potentially confusing on these projects.

### Current State — s1_epic_planning.md Step 1.0

```markdown
### Step 1.0: Create Git Branch for Epic

**CRITICAL:** Create branch BEFORE making any changes to codebase.

**Steps:**
1. Verify you're on main branch (`git checkout main`)
2. Pull latest changes (`git pull origin main`)
3. Read .shamt/epics/EPIC_TRACKER.md to identify "Next Available Number"
4. **Ask user for SHAMT number preference** (use AskUserQuestion):
   - Option A: Use next available number (e.g., SHAMT-9) - Recommended
   - Option B: Specify custom SHAMT number (user provides number)
   - **Rationale:** Allows user control over epic numbering for organizational purposes
5. Determine work type (epic/feat/fix) - typically "epic" for multi-feature work
6. Create and checkout branch (`git checkout -b {work_type}/SHAMT-{number}`)
7. Update .shamt/epics/EPIC_TRACKER.md (add to Active table, increment next number if using next available)
8. Commit .shamt/epics/EPIC_TRACKER.md update immediately

**Why branch first:** Keeps main clean, allows parallel work, enables rollback
```

### Proposed Change — s1_epic_planning.md Step 1.0

```markdown
### Step 1.0: Assign Epic Number (EPIC_TRACKER Update)

**Steps:**
1. Read .shamt/epics/EPIC_TRACKER.md to identify "Next Available Number"
2. **Ask user for SHAMT number preference** (use AskUserQuestion):
   - Option A: Use next available number (e.g., SHAMT-9) - Recommended
   - Option B: Specify custom SHAMT number (user provides number)
   - **Rationale:** Allows user control over epic numbering for organizational purposes
3. Update .shamt/epics/EPIC_TRACKER.md (add to Active table, increment next number)
4. If .shamt/ is NOT git-excluded in this project: commit the EPIC_TRACKER.md update.
   If .shamt/ IS git-excluded: update is local-only — skip commit.

**Note:** Git branch creation is deferred to S6 Step 0 (immediately before writing code).
Since all S1–S5 artifacts live in .shamt/ (often git-excluded), the branch would sit
idle with nothing to commit from S1 through S5.
```

### Proposed Addition — s6_execution.md Workflow Overview (before Step 1)

```markdown
Step 0: Create Git Branch (FIRST ACTION in S6, before writing any code)
   ├─ Verify on main branch (`git checkout main`)
   ├─ Pull latest changes (`git pull origin main`)
   ├─ Read SHAMT number assigned in S1 (from .shamt/epics/EPIC_TRACKER.md)
   ├─ Determine work type (epic/feat/fix) — typically "epic"
   └─ Create and checkout branch: `git checkout -b {work_type}/SHAMT-{number}`
```

### Proposed Addition — s6_execution.md Detailed Workflow (new Step 0 section)

```markdown
## Step 0: Create Git Branch

**CRITICAL:** This is the FIRST ACTION in S6 — before writing any code.

**Steps:**
1. Verify you're on main branch (`git checkout main`)
2. Pull latest changes (`git pull origin main`)
3. Read the SHAMT number assigned during S1 (from .shamt/epics/EPIC_TRACKER.md)
4. Determine work type (epic/feat/fix) — typically "epic" for multi-feature epics
5. Create and checkout branch: `git checkout -b {work_type}/SHAMT-{number}`

**Why here (not S1):** All S1–S5 artifacts live in .shamt/ (often git-excluded). No
source code changes are made until S6, so the branch has nothing to commit until now.
Creating it in S6 keeps the branch lifecycle aligned with actual code changes.
```

### Proposed Change — RULES_FILE.template.md line 327

```markdown
# BEFORE:
✅ **DO:** Create git branch

# AFTER: (remove this line entirely from the S1 checklist — branch creation is now S6)
```

### Rationale

Aligns branch lifecycle with when code changes actually begin. Removes a confusing no-op step on git-excluded projects. The EPIC_TRACKER update (number assignment) stays in S1 since that's a planning decision; only the `git checkout -b` command moves to S6.

---

## Proposal P2-2: Add env var documentation task to S5 Validation Loop Dimension 9

**Priority:** P2
**Affected Guide:** `.shamt/guides/stages/s5/s5_v2_validation_loop.md`
**Section:** Dimension 9: Implementation Completeness — `Documentation tasks added` checklist item (Line ~821)

### Problem

KAI-15 introduced two env vars (`ESPN_FIXTURE_DIR`, `ESPN_RECORD_FIXTURES_DIR`) but neither feature's implementation plan included a task to document them in the README. The gap was caught in S9.P4 (M5 — requiring a retroactive bug fix commit). Had the Dimension 9 checklist included an env var documentation reminder, the missing README task would have been caught during S5 validation before any code was written.

### Current State

```markdown
- [ ] Documentation tasks added (docstrings, ARCHITECTURE.md, etc.)
```

### Proposed Change

```markdown
- [ ] Documentation tasks added (docstrings, ARCHITECTURE.md, etc.)
- [ ] **If feature introduces new env vars or CLI options:** README documentation task included
      (env var name, purpose, usage example — treat new env vars like new CLI flags)
```

### Rationale

Env vars are invisible to future developers unless documented. By adding this check to Dimension 9, agents reviewing the implementation plan will notice if a documentation task is missing for any new env var. The condition gate ("if feature introduces new env vars") keeps it focused and non-intrusive for features that don't add env vars.

---

## Proposal P3-1: Add "commit before spawning sub-agents" to S9.P2 Issue Handling

**Priority:** P3
**Affected Guide:** `.shamt/guides/stages/s9/s9_p2_epic_qc_rounds.md`
**Section:** "Issue Handling: Fix and Continue" — Step 2 "Fix ALL Issues Immediately" (Lines ~709–713)

### Problem

After applying QC fixes, those fixes were on disk but not committed before sub-agents were spawned. Sub-agents flagged the uncommitted state as an issue, requiring an additional fix round. The current guide says to fix and continue, but doesn't mention committing before spawning.

### Current State

```markdown
### Step 2: Fix ALL Issues Immediately

- Fix each issue before proceeding
- Re-run ALL tests (must pass 100%)
- Do NOT defer any issues
```

### Proposed Change

```markdown
### Step 2: Fix ALL Issues Immediately

- Fix each issue before proceeding
- Re-run ALL tests (must pass 100%)
- Do NOT defer any issues
- **Commit fixes before spawning sub-agents** — uncommitted fixes leave the working tree
  dirty; sub-agents will flag this as an additional issue, requiring another fix round.
  Commit after each fix round, before spawning confirmation agents.
```

### Rationale

A concrete reminder prevents an easily-avoidable extra round. Sub-agents checking code quality will notice and flag uncommitted changes. Committing before spawning ensures sub-agents see a clean, consistent state.

---

## Proposal P3-2: Add internal-label scan to S9.P2 Dimension 9 (Epic Cohesion)

**Priority:** P3
**Affected Guide:** `.shamt/guides/stages/s9/s9_p2_epic_qc_rounds.md`
**Section:** "Dimension 9: Epic Cohesion" — "What to check" list (Lines ~443–444)

### Problem

`tests/fixtures/helpers.py` contained an error message with `"(F3)"` — an internal epic planning label written in F1 before F3 was implemented, never cleaned up. No QC checklist item prompted agents to scan for such labels. The issue was caught in S9.P4 rather than S9.P2 or S7.

### Current State

```markdown
## Dimension 9: Epic Cohesion

**Objective:** Validate epic cohesion and consistency across all features.

**What to check:**
- Code style consistent across ALL features
- Naming conventions consistent
```

### Proposed Change

```markdown
## Dimension 9: Epic Cohesion

**Objective:** Validate epic cohesion and consistency across all features.

**What to check:**
- Code style consistent across ALL features
- Naming conventions consistent
- Error messages and log strings do not contain internal planning labels (e.g., "(F3)",
  "(Task 2.1)") — these are useful during development but must be replaced with
  developer-facing language before delivery. Scan with: `grep -r "(F[0-9]" src/ tests/`
```

### Rationale

Internal planning labels in error messages are a temporal artifact written early in development and never cleaned up. Adding an explicit scan to Dimension 9 catches this class of issue during S9.P2 rather than requiring S9.P4 to catch it.

---

## Rejected Proposals (for reference)

*(None — all 4 proposals approved)*

---

## Implementation Notes

- Apply all proposals as a single batch
- Run full guide audit (3 consecutive clean rounds) before committing
- Update `reference/guide_update_tracking.md` with implementation entry
- Delete this file from `unimplemented_design_proposals/` after successful implementation and commit
- Note: P2-1 also requires updating `RULES_FILE.template.md` line 327 (remove "Create git branch" from S1 checklist)
