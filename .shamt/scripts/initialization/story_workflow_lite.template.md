# Story Workflow — Shamt Lite

**Purpose:** Six-phase workflow for Agile ticket work (Intake → Spec → Plan → Build → Review → Polish)
**For:** Projects using Shamt Lite for day-to-day ticket execution

**How to use this file:**
- Follow phases in order unless user explicitly skips one
- Each phase has a minimum-viable artifact — even a 1-line bug fix can use this workflow
- Name the story slug explicitly each invocation — no marker files track which story is "active"
- See `SHAMT_LITE.md` for the standalone patterns referenced inside each phase

---

## Workflow Overview

| Phase | Artifact | Gate |
|-------|----------|------|
| 1. Intake | `stories/{slug}/ticket.md` | User confirms slug + content |
| 2. Spec | `stories/{slug}/spec.md` | (2a) User picks design, (2b) User approves validated spec |
| 3. Plan | `stories/{slug}/implementation_plan.md` | User approves validated plan |
| 4. Build | code changes | Verification checklist in plan |
| 5. Review | `stories/{slug}/code_review/review_v1.md` | Review is the artifact |
| 6. Polish | commit messages + CHANGES.md entries | User signals "polishing complete" |

**Advisory context-clear breakpoints:**
- After Gate 2b (spec approved) → suggest `/clear` before Plan phase
- After Gate 3 (plan approved) → suggest `/clear` before Build
- After Build, before Review → optional
- After Review, before Polish → optional (depends on review size)

---

## Phase 1: Intake

**Purpose:** Capture the ticket and establish the story folder.

**Minimum viable artifact:** Whatever the user pasted into ticket.md — no structure required.

**Recommended model:** Haiku (mechanical)

### Steps

**Step 1 — Ask for slug.**

If the user has not named a slug, ask: "What slug should I use for this story?" Do not guess from the ticket content or conversation context.

**Step 2 — Check for collision.**

If `stories/{slug}/` already exists, warn the user and halt. Do not overwrite.

**Step 3 — Create folder and ticket.md.**

```
stories/{slug}/
└── ticket.md    ← paste ticket content here
```

Use `templates/ticket.template.md` as the structure hint. The file is freeform — accept Jira HTML, Slack thread dumps, email text, voice-memo transcripts, anything.

**Step 4 — Confirm.**

Report to user: slug created, path, content summary (1-2 sentences). Ask if they want to proceed to Spec phase.

**Gate:** User confirms slug and ticket content are correct.

---

## Phase 2: Spec

**Purpose:** Research the ticket, align on design, produce a validated spec.

**Minimum viable artifact:** 3-5 lines — problem, chosen approach, files affected.

**Pattern used:** Pattern 3 (Spec Protocol) in `SHAMT_LITE.md`

**Recommended models:** Sonnet for research (Steps 1-3), Opus or Sonnet for design dialog (Step 4), Opus for validation (Step 6)

### The 7-Step Spec Protocol

**Step 1 — Ingest the ticket.**

Read `stories/{slug}/ticket.md`. Treat as unstructured raw text regardless of format. Extract:
- What's being asked (the ask)
- Acceptance criteria (explicit or implied)
- Links, due dates, constraints

Output a **brief in-agent summary** (3-5 bullets). Do NOT write to disk yet.

If `ticket.md` is empty or missing: halt and ask the user to populate it. Do not fabricate ticket content from prior conversation context.

**Step 2 — Targeted research.**

Scope research to what the ticket references — not a broad exploration:
- Grep for referenced file paths, function names, feature names
- Read `ARCHITECTURE.md` and `CODING_STANDARDS.md` if present
- Skim related code files

Document findings in `spec.md` under "Research Findings" (3-10 bullets).

**Step 3 — Draft spec skeleton.**

Create `stories/{slug}/spec.md` using `templates/spec.template.md`. Fill in:
- Ticket Summary (from Step 1)
- Research Findings (from Step 2)
- Problem Statement
- Proposed Design / Architecture — placeholder: "TBD, awaiting user alignment"
- Requirements (functional + non-functional)
- Files Affected (best-effort)
- Out of Scope
- Open Questions

**Step 4 — Architecture/design dialog (Gate 2a).**

Propose **1-3 design options** inline in chat (not in spec.md yet):

- **1 option:** Acceptable when the choice is obvious from research — present it with rationale.
- **2-3 options:** Required when a non-trivial user-facing design fork exists (e.g., server-side vs. client-side, new service vs. extending existing).

For each option: brief description, pros, cons, effort (S/M/L). Recommend one.

When options have open sub-questions, use the 6-category question brainstorm framework (see `reference/question_brainstorm_categories_lite.md`) to surface them. Show categories with questions; omit empty ones.

**Wait for explicit user confirmation before proceeding. Do not fill in the spec's design section without user approval.**

**Step 5 — Flesh out spec.**

Fill in "Proposed Design / Architecture" with the agreed approach. Refine Requirements, Files Affected, Out of Scope.

**Step 6 — Validation loop (Pattern 1).**

Run Pattern 1 (Validation Loops) on `spec.md` using the **7 spec dimensions**:

1. **Completeness** — All sections filled? Requirements gap-free?
2. **Correctness** — Research accurate? File paths correct?
3. **Consistency** — Design internally consistent? Aligned with ARCHITECTURE.md?
4. **Helpfulness** — Does the spec solve the ticket? Is the design achievable?
5. **Improvements** — Simpler approach available? Over-engineered?
6. **Missing proposals** — Any important design element unaddressed?
7. **Open questions** — Unresolved decision that would block planning?

**Targeted gap-finding each round:** Ask "What code should I have read that I haven't?" and read it. New discoveries may trigger new issues.

**Exit criterion:** Primary clean round + **1 Haiku sub-agent confirmation**.

**Step 7 — User approval (Gate 2b).**

Present the validated spec. User approves or requests changes. On approval, Spec phase is complete.

*Suggest:* "Spec approved. Consider `/clear` before starting the Plan phase to free context."

---

## Phase 3: Plan

**Purpose:** Create a validated, mechanical implementation plan.

**Minimum viable artifact:** 1-3 steps.

**Pattern used:** Pattern 5 (Implementation Planning) in `SHAMT_LITE.md`

**Recommended models:** Sonnet for plan creation, Sonnet for plan validation

### Steps

**Step 1 — Read spec.**

Read `stories/{slug}/spec.md` completely. Confirm all design decisions are resolved before creating the plan.

**Step 2 — Create plan.**

Create `stories/{slug}/implementation_plan.md` using `templates/implementation_plan.template.md`.

Each step must be **mechanical** — no design decisions left for the executor. Use CREATE/EDIT/DELETE/MOVE operations with exact details. See Pattern 5 in `SHAMT_LITE.md` for operation formats.

**Step 3 — Validate plan (Pattern 1, 7 plan dimensions).**

Exit criterion: Primary clean round + **1 Haiku sub-agent confirmation**.

Add validation footer:
```
---
✅ Validated {date} — N rounds, 1 sub-agent confirmed
```

**Step 4 — User approval (Gate 3).**

Present validated plan. User approves or requests changes. On approval, Plan phase is complete.

*Suggest:* "Plan approved. Consider `/clear` before starting the Build phase."

**Builder handoff (optional):** If the plan has >10 mechanical steps, spawn a Haiku builder for execution. See Pattern 5 in `SHAMT_LITE.md` for the handoff template.

---

## Phase 4: Build

**Purpose:** Execute the implementation plan.

**Minimum viable artifact:** Code changes that pass the plan's verification checklist.

**Pattern used:** Pattern 5 (Implementation Planning) — execution section

**Recommended model:** Haiku (mandatory if plan is mechanical and >10 steps)

### Steps

**Step 1 — Execute plan.**

Work through `stories/{slug}/implementation_plan.md` step by step. Follow each step exactly as written. Run verification after steps that require it.

**Using builder handoff:** Spawn Haiku builder using the template in Pattern 5. Monitor for errors — if builder reports a failed verification or unclear step, take over, fix the plan, and re-run.

**Step 2 — Post-execution check.**

Test the feature against spec requirements. Verify no unintended side effects.

**Gate:** None — verification steps in the plan serve as the gate.

---

## Phase 5: Review

**Purpose:** Self-review (or peer review) of the code changes.

**Minimum viable artifact:** `review_v1.md` can be empty or "No issues found." for trivial changes.

**Pattern used:** Pattern 4 (Code Review Process) — story mode

**Recommended models:** Opus for issue finding/classification, Haiku for git metadata

### Story Mode (this phase)

Reviewing code changes for a story you/the agent just built:
- Output: `stories/{slug}/code_review/review_v1.md` only
- No `overview.md` — the story folder already has ticket.md, spec.md, and implementation_plan.md as context
- Focus: "does the code match the spec and plan?"

### Steps

**Step 1 — Gather diff.**

Use read-only git commands to get the diff for the changes made during Build phase. **Never check out another branch.**

```bash
git diff HEAD~N HEAD  # or appropriate range for build changes
git diff --stat HEAD~N HEAD
```

**Step 2 — Write review_v1.md.**

Create `stories/{slug}/code_review/review_v1.md`. Use severity-first grouping (BLOCKING/CONCERN/SUGGESTION/NITPICK), 12 categories (see Pattern 4 in `SHAMT_LITE.md`).

If no issues found: write "No issues found." — do not fabricate findings.

**Re-reviews:** If user requests re-review after changes, create `review_v2.md`, `review_v3.md`. Never overwrite.

**Step 3 — Validate review (Pattern 1, 5 review dimensions).**

Exit criterion: Primary clean round + 1 Haiku sub-agent.

Add validation footer:
```
---
✅ Validated {date} — N rounds, 1 sub-agent confirmed
```

**Gate:** None — the review is the artifact. User reads it and decides what to act on.

---

## Phase 6: Polish

**Purpose:** Apply reviewer feedback AND capture generalizable lessons in local standards.

**Minimum viable artifact:** If no feedback arrives, this phase is a no-op.

**Recommended models:** Sonnet for fix application, Opus for root-cause analysis and upstream proposals

### Trigger

User pastes a PR comment, verbal feedback, or points out an issue. Each trigger is one **polish cycle**. Multiple cycles per story are normal.

### Per Polish Cycle: 5 Steps

**Step 1 — Apply the fix.**

Make the code change. No ceremony.

**Step 2 — Root-cause analysis.**

Ask:
- Why did this slip through Spec, Plan, Build, and Review?
- Missing question in Spec Step 4 or 6?
- Gap in `CODE_STANDARDS.md`?
- Architectural principle not in `ARCHITECTURE.md`?
- Something a review dimension would have caught?
- Or a one-off — genuinely not preventable by any standard?

**Target selection guide:**

| Issue type | Proposal target |
|---|---|
| Code style, naming, or pattern | `CODE_STANDARDS.md` |
| Architectural decision or structural principle | `ARCHITECTURE.md` |
| Something a spec question would have caught | Spec Protocol Step 4/6 or `templates/spec.template.md` |
| Something a review dimension would have caught | Code review categories in `SHAMT_LITE.md` |
| Framework behavior agent got wrong | `SHAMT_LITE.md` pattern wording or example |
| One-off with no generalizable lesson | commit message only, no upstream proposal |

**Spec loopback:** If the root cause reveals the chosen design/architecture was fundamentally wrong (not just incomplete in a patchable way), recommend formally re-entering the Spec phase at Gate 2a. The user gates this decision. This is distinct from small gaps, which are handled in place via Polish's upstream proposals.

**Step 3 — Propose upstream changes.**

For each applicable target, draft a specific diff/snippet — not a vague idea. If multiple targets apply, draft a proposal for each:
- `CODE_STANDARDS.md` — new rule, anti-pattern, example
- `ARCHITECTURE.md` — new decision record or principle
- `SHAMT_LITE.md` patterns — new validation dimension, new example
- `templates/spec.template.md` — new required section or prompt

**Step 4 — User decides.**

Present each proposal. User approves, rejects, or modifies each one. No validation loop — the user is the gate.

**Step 5 — Apply accepted proposals + record durably.**

For each accepted proposal:
1. Apply the change to the appropriate local file.
2. Write a commit message capturing root cause + applied changes + rejected proposals.
3. If the change is **generic** (would benefit any Shamt Lite project, not just this codebase), also append an entry to `CHANGES.md` in the shamt-lite root.

### Polish Commit Message Format

```
polish({slug}): {brief description of fix}

PR comment / feedback:
{paste or summarize}

Root cause:
{1-3 sentences on why this slipped through Spec/Plan/Build/Review}

Applied:
- CODE_STANDARDS.md: new rule "{...}"
- SHAMT_LITE.md §Pattern 3: added dimension "{...}"

Rejected:
- {proposal and reason why not accepted, if any}

Upstream to master? Yes — CHANGES.md entry added / No — project-specific
```

**"Polish complete" signal:** User tells the agent when polishing is done (typically: PR merged, or no more feedback). No marker file needed — the git log is the persistent record.

---

## Minimum Viable Artifacts

| Phase | Minimum to proceed |
|---|---|
| Intake | Any non-empty ticket.md |
| Spec | 3-5 lines: problem, chosen approach, files affected |
| Plan | 1-3 steps |
| Build | Code changes pass verification checklist |
| Review | "No issues found." is a valid review |
| Polish | Phase is a no-op if no feedback arrives |

---

## Stories Folder Convention

```
stories/
└── {slug}/
    ├── ticket.md                   # Paste raw ticket content
    ├── spec.md                     # Created in Spec phase
    ├── implementation_plan.md      # Created in Plan phase
    └── code_review/
        └── review_v1.md            # Created in Review phase
```

**Slug convention:** Free-form. Examples: `PROJ-1234-csv-export`, `fix-login-timeout`, `2026-04-20-dashboard-bug`.

**Active-story convention:** Name the slug explicitly each time you invoke the agent on story work. If you invoke a story-phase action without naming a slug, the agent will ask rather than guessing.

**Collision check:** If `stories/{slug}/` already exists, the agent warns and halts. Does not overwrite.

**Cleanup:** Stories accumulate; cleanup is the user's responsibility.

---

*Shamt Lite Story Workflow — six phases, minimum ceremony, maximum learning*
