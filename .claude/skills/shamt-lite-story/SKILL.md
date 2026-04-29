<!-- Managed by Shamt — do not edit. Run regen-claude-shims.sh to regenerate. -->
---
name: shamt-lite-story
description: >
  Executes the six-phase Shamt Lite story workflow (Intake → Spec → Plan → Build →
  Review → Polish) for ticket-based work. Encodes the 5 core quality patterns
  (Validation Loops, Severity Classification, Spec Protocol, Code Review, Implementation
  Planning) and token discipline. Designed for projects using Shamt Lite without the
  full S1-S11 epic framework.
triggers:
  - "start a story"
  - "run lite story workflow"
  - "shamt lite"
  - "six-phase story"
source_guides:
  - scripts/initialization/SHAMT_LITE.template.md
  - scripts/initialization/story_workflow_lite.template.md
master-only: false
---

## Overview

Shamt Lite provides 5 core quality patterns and a six-phase story workflow for taking tickets from received to shipped and learned from. Use it when working from a ticket (Jira, Linear, Slack, verbal) and wanting systematic quality without the full S1-S11 epic framework.

**Files used:**
- `SHAMT_LITE.md` — 5 patterns + token discipline (standalone)
- `story_workflow_lite.md` — Full phase-by-phase narrative
- `CHANGES.md` — Polish-phase upstream candidates accumulate here
- `stories/{slug}/` — Per-story work folder

**Context-clear breakpoints (advisory):**
- After Gate 2b (spec approved) → suggest `/clear` before Plan
- After Gate 3 (plan approved) → suggest `/clear` before Build

---

## When This Skill Triggers

- User says "start a story", "run lite story workflow", "shamt lite", or "six-phase story"
- Working from a ticket and wanting the six-phase workflow
- Starting any ticket-based development work in a Shamt Lite project

---

## Workflow Overview

| Phase | Artifact | Gate |
|---|---|---|
| 1. Intake | `stories/{slug}/ticket.md` | User confirms slug + content |
| 2. Spec | `stories/{slug}/spec.md` | (2a) Design approved, (2b) Spec approved |
| 3. Plan | `stories/{slug}/implementation_plan.md` | User approves validated plan |
| 4. Build | code changes | Verification checklist in plan |
| 5. Review | `stories/{slug}/code_review/review_v1.md` | Review is the artifact |
| 6. Polish | commit messages + CHANGES.md entries | User signals "polishing complete" |

---

## Protocol

### Phase 1: Intake

**Purpose:** Capture the ticket and establish the story folder.

**Model:** Haiku (mechanical)

**Steps:**

1. If the user has not named a slug, ask: "What slug should I use for this story?" Do not guess.
2. If `stories/{slug}/` already exists, warn the user and halt. Do not overwrite.
3. Create `stories/{slug}/ticket.md` — accept any format (Jira HTML, Slack thread, email, voice memo). Use `templates/ticket.template.md` as a structure hint; the file is freeform.
4. Report to user: slug created, path, content summary (1-2 sentences). Ask if they want to proceed to Spec.

**Gate:** User confirms slug and ticket content are correct.

---

### Phase 2: Spec

**Purpose:** Research the ticket, align on design, produce a validated spec.

**Models:** Sonnet for research (Steps 1-3), Opus or Sonnet for design dialog (Step 4), Opus for validation (Step 6)

**Step 1 — Ingest the ticket**

Read `stories/{slug}/ticket.md`. Extract: what's being asked, acceptance criteria (explicit or implied), links/due dates/constraints. Output 3-5 bullet summary in-agent. Do NOT write to disk yet.

If ticket.md is empty or missing: halt and ask user to populate it. Do not fabricate from conversation context.

**Step 2 — Targeted research**

Scope to what the ticket references:
- Grep for referenced file paths, function names, feature names
- Read `ARCHITECTURE.md` and `CODING_STANDARDS.md` if present
- Skim related code

Document findings in spec.md under "Research Findings" (3-10 bullets).

**Step 3 — Draft spec skeleton**

Create `stories/{slug}/spec.md` (use `templates/spec.template.md`) with sections:
- Ticket Summary
- Research Findings
- Problem Statement
- Proposed Design / Architecture — placeholder: "TBD, awaiting user alignment"
- Requirements (functional + non-functional)
- Files Affected (best-effort)
- Out of Scope
- Open Questions

**Step 4 — Architecture/design dialog (Gate 2a)**

Propose 1-3 design options inline in chat (not in spec.md yet):
- **1 option:** Acceptable when choice is obvious from research
- **2-3 options:** Required when a non-trivial user-facing design fork exists

For each option: brief description, pros, cons, effort (S/M/L). Recommend one.

When options have open sub-questions, use the 6-category question brainstorm framework:

| Category | Example questions |
|---|---|
| Functional requirements | What must X do exactly? |
| User workflow / edge cases | What if only some records need this? |
| Implementation approach | Server-side vs. client-side? |
| Constraints | Perf targets, auth requirements? |
| Scope boundaries | Does this include Y? |
| Success criteria | How will user verify it works? |

**Wait for explicit user confirmation before proceeding. Do not fill in the spec's design section without user approval.**

**Step 5 — Flesh out spec**

Fill in "Proposed Design / Architecture" with the agreed approach. Refine Requirements, Files Affected, Out of Scope.

**Step 6 — Validation loop (7 spec dimensions)**

Run a validation loop. Track `consecutive_clean` (start at 0).

Each round — re-read spec.md completely, check all 7 dimensions:
1. Completeness — all sections filled, requirements gap-free?
2. Correctness — research accurate, file paths correct?
3. Consistency — design internally consistent, aligned with ARCHITECTURE.md?
4. Helpfulness — does the spec solve the ticket, is design achievable?
5. Improvements — simpler approach available, over-engineered?
6. Missing proposals — any important design element unaddressed?
7. Open questions — unresolved decision that would block planning?

Clean round: ZERO issues OR exactly ONE LOW issue (fixed). Otherwise reset to 0.

When `consecutive_clean = 1` → spawn 1 Haiku sub-agent:

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Sub-agent confirmation — spec validation</parameter>
  <parameter name="prompt">Confirm zero issues in stories/{slug}/spec.md.

Re-read the entire spec. Check all 7 dimensions: Completeness, Correctness,
Consistency, Helpfulness, Improvements, Missing proposals, Open questions.
Report ANY issue found, even LOW severity.
If zero issues: state "CONFIRMED: Zero issues found."</parameter>
</invoke>
```

Sub-agent finds issues → fix all, reset `consecutive_clean = 0`, continue. Sub-agent confirms zero → add validation footer and proceed.

Validation footer:
```
---
✅ Validated {date} — N rounds, 1 sub-agent confirmed
```

**Step 7 — User approval (Gate 2b)**

Present validated spec. User approves or requests changes.

Suggest: "Spec approved. Consider `/clear` before starting the Plan phase."

---

### Phase 3: Plan

**Purpose:** Create a validated, mechanical implementation plan.

**Model:** Sonnet for plan creation and validation

**Step 1 — Read spec completely.** Confirm all design decisions are resolved.

**Step 2 — Create `stories/{slug}/implementation_plan.md`** (use `templates/implementation_plan.template.md`).

Each step must be **mechanical** — no design decisions left for the executor. Use these operation formats:

- **CREATE:** Specify file purpose and initial content
- **EDIT:** Exact locate string (5-10 lines context) + exact replacement string
- **DELETE:** File/section to delete + justification
- **MOVE:** Source → destination + reason

Add Verification field when success depends on tooling (compilation, tests, runtime config loading). Omit for self-evident steps (pure text edits, comment changes).

**Step 3 — Validate plan (7 plan dimensions)**

Run validation loop same as spec, using these 7 dimensions:
1. Step Clarity — every step has a clear action?
2. Mechanical Executability — all design decisions made, none left to executor?
3. File Coverage — all affected files listed?
4. Operation Specificity — EDIT steps have exact locate/replace strings?
5. Verification Completeness — steps needing it have verification methods?
6. Dependency Ordering — steps in correct sequence?
7. Requirements Alignment — plan covers all spec requirements?

Exit: primary clean round + 1 Haiku sub-agent. Add validation footer.

**Step 4 — User approval (Gate 3)**

Present validated plan. User approves or requests changes.

Suggest: "Plan approved. Consider `/clear` before starting the Build phase."

**Optional builder handoff** (if plan has >10 mechanical steps):

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  <parameter name="description">Execute implementation plan</parameter>
  <parameter name="prompt">You are a builder executing a validated implementation plan.

Plan: stories/{slug}/implementation_plan.md

Critical rules:
1. Follow steps exactly as written — make ZERO design decisions
2. Execute sequentially (Step 1, then 2, then 3...)
3. Run verification after each step that specifies one
4. If verification fails: STOP and report to architect
5. If any step is unclear: STOP and report to architect

Report: "All steps completed." or "Step N failed: [describe what failed]"</parameter>
</invoke>
```

---

### Phase 4: Build

**Purpose:** Execute the implementation plan.

**Model:** Haiku (mandatory if plan is mechanical and >10 steps)

Work through `stories/{slug}/implementation_plan.md` step by step. Follow each step exactly as written. Run verification after steps that require it.

Post-execution: test the feature against spec requirements, verify no unintended side effects.

**Gate:** None — verification steps in the plan serve as the gate.

---

### Phase 5: Review

**Purpose:** Self-review (or peer review) of the code changes.

**Models:** Opus for issue finding/classification, Haiku for git metadata

**Story mode** (reviewing code you just built):
- Output: `stories/{slug}/code_review/review_v1.md` only
- No overview.md — the story folder (ticket.md, spec.md, plan) provides context
- Focus: "does the code match the spec and plan?"

**Step 1 — Gather diff using read-only git commands only. NEVER check out another branch.**

```bash
git diff HEAD~N HEAD  # or appropriate range
git diff --stat HEAD~N HEAD
```

**Step 2 — Write review_v1.md.** Group by severity (BLOCKING / CONCERN / SUGGESTION / NITPICK), use 12 categories:
1. Correctness  2. Security  3. Performance  4. Maintainability  5. Testing
6. Edge Cases  7. Naming  8. Documentation  9. Error Handling  10. Concurrency
11. Dependencies  12. Architecture

Finding format:
```markdown
#### [SEVERITY] — <Category Name>

**File:** `path/to/file.ext`, line N

<What's wrong and what the consequence is.>

**Suggested fix:** <Concrete direction.>
```

If no issues found: write "No issues found." Do not fabricate findings.

**Step 3 — Validate review (5 dimensions):** Correctness, Completeness, Helpfulness, Severity Accuracy, Evidence. Exit: primary clean round + 1 Haiku sub-agent. Add validation footer.

**Re-reviews:** Create `review_v2.md`, `review_v3.md`, etc. Never overwrite.

---

### Phase 6: Polish

**Purpose:** Apply reviewer feedback AND capture generalizable lessons.

**Models:** Sonnet for fix application, Opus for root-cause analysis and upstream proposals

**Trigger:** User pastes a PR comment, verbal feedback, or points out an issue. Each trigger is one polish cycle. Multiple cycles per story are normal.

**Per polish cycle — 5 steps:**

**Step 1 — Apply the fix.** Make the code change.

**Step 2 — Root-cause analysis.** Ask:
- Why did this slip through Spec, Plan, Build, and Review?
- Missing question in Spec Step 4 or 6?
- Gap in CODING_STANDARDS.md or ARCHITECTURE.md?
- Something a review dimension would have caught?
- One-off — genuinely not preventable by any standard?

| Issue type | Proposal target |
|---|---|
| Code style, naming, or pattern | `CODING_STANDARDS.md` |
| Architectural decision or structural principle | `ARCHITECTURE.md` |
| Something a spec question would have caught | Spec template or Pattern 3 |
| Something a review dimension would have caught | Code review categories |
| Framework behavior agent got wrong | Pattern wording in `SHAMT_LITE.md` |
| One-off with no generalizable lesson | Commit message only |

**Step 3 — Propose upstream changes.** For each applicable target, draft a specific diff/snippet (not a vague idea).

**Step 4 — User decides.** Present each proposal. User approves, rejects, or modifies. No validation loop — the user is the gate.

**Step 5 — Apply accepted proposals + record durably.**
1. Apply the change to the appropriate local file
2. Write a commit message capturing root cause + applied changes + rejected proposals
3. If the change is **generic** (would benefit any Shamt Lite project): append an entry to `CHANGES.md` in the shamt-lite root

**Polish commit message format:**
```
polish({slug}): {brief description of fix}

PR comment / feedback:
{paste or summarize}

Root cause:
{1-3 sentences on why this slipped through}

Applied:
- CODING_STANDARDS.md: new rule "{...}"

Rejected:
- {proposal and reason}

Upstream to master? Yes — CHANGES.md entry added / No — project-specific
```

**"Polish complete"** signal: User tells the agent when polishing is done. No marker file needed — the git log is the persistent record.

---

## Exit Criteria

Story is complete when the user signals "polishing complete" or the PR is merged. All intermediate artifacts (ticket.md, spec.md, implementation_plan.md, review_v1.md) remain in `stories/{slug}/` as a record.

---

## Quick Reference

### 5 Core Patterns

| Pattern | When to use |
|---|---|
| 1. Validation Loops | After creating any significant artifact (spec, plan, review) |
| 2. Severity Classification | Classifying issues during validation |
| 3. Spec Protocol | Starting a story's Spec phase |
| 4. Code Review | Starting a story's Review phase; or reviewing external PRs |
| 5. Implementation Planning | After spec is approved, before Build |

### Validation loop quick steps

```
1. Re-read artifact completely (fresh every round)
2. Find issues across relevant dimensions
3. Classify: CRITICAL / HIGH / MEDIUM / LOW
4. Fix ALL immediately
5. Counter: 0 issues OR 1 LOW fixed → consecutive_clean + 1
          2+ LOW or any MEDIUM/HIGH/CRITICAL → consecutive_clean = 0
6. consecutive_clean = 1 → spawn 1 Haiku sub-agent
7. Sub-agent finds 0 issues → DONE ✅
8. Add footer: ✅ Validated {date} — N rounds, 1 sub-agent confirmed
```

### Severity quick reference

```
CRITICAL → blocks workflow / causes failure
HIGH     → causes confusion or wrong decisions
MEDIUM   → reduces quality noticeably
LOW      → cosmetic only

When uncertain → classify HIGHER
One LOW per round is OK; two LOW = not clean
Sub-agents get NO LOW allowance
```

### Token discipline: model selection

| Activity | Model |
|---|---|
| Intake | Haiku |
| Spec research | Sonnet |
| Spec design dialog | Opus or Sonnet |
| Spec validation | Opus |
| Plan creation + validation | Sonnet |
| Build (mechanical plan, >10 steps) | Haiku (mandatory) |
| Review — git metadata | Haiku |
| Review — issue finding | Opus |
| Polish — apply fix | Sonnet |
| Polish — root cause + upstream proposal | Opus |
| Sub-agent confirmations (all phases) | Haiku (always) |

### Minimum viable artifacts

| Phase | Minimum to proceed |
|---|---|
| Intake | Any non-empty ticket.md |
| Spec | 3-5 lines: problem, chosen approach, files affected |
| Plan | 1-3 steps |
| Build | Code changes pass verification checklist |
| Review | "No issues found." is a valid review |
| Polish | Phase is a no-op if no feedback arrives |
