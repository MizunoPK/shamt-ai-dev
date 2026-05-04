---
name: shamt-lite-spec
description: >
  Run the Shamt Lite Spec Protocol for ticketed work — ingest the ticket, run targeted
  research, draft a spec skeleton, dialog through 1-3 design options with the user,
  flesh out the spec, and validate it via the Lite validation loop. Outputs
  stories/{slug}/spec.md ready for implementation planning.
triggers:
  - "spec this ticket"
  - "run the spec protocol"
  - "shamt lite spec"
  - "create a spec for"
source_guides:
  - scripts/initialization/SHAMT_LITE.template.md
  - scripts/initialization/story_workflow_lite.template.md
  - scripts/initialization/templates/spec.template.md
  - scripts/initialization/reference/question_brainstorm_categories_lite.md
master-only: false
---

## Overview

Encodes Pattern 3 (Spec Protocol) from `SHAMT_LITE.md`. Use when starting a story's Spec phase or any time you need to define and validate an approach before planning.

**Output:** `stories/{slug}/spec.md`, validated and approved by user.

**Two gates:**
- **Gate 2a:** Design dialog approval (chat-only at this point; spec.md design section not yet written)
- **Gate 2b:** Validated-spec approval

---

## When This Skill Triggers

- Starting a story's Spec phase (after Phase 1 Intake completes)
- User says "spec this ticket", "run the spec protocol", or names a ticket to spec
- Any time a non-trivial approach needs definition + validation before planning

---

## Inputs Required

- **Slug** — story slug (e.g., `add-export-button`). Story folder must already exist with a populated `ticket.md`.
- **Ticket content** — at `stories/{slug}/ticket.md`

If `stories/{slug}/ticket.md` is empty or missing: halt and ask the user to populate it. Do not fabricate from conversation context.

---

## Protocol — The 7-Step Spec Protocol

### Step 1 — Ingest the ticket

Read `stories/{slug}/ticket.md`. Extract:
- What's being asked
- Acceptance criteria (explicit or implied)
- Links, due dates, constraints

Output a **3-5 bullet in-agent summary**. Do NOT write to disk yet.

If empty/missing: halt, ask user to populate `ticket.md`.

### Step 2 — Targeted research

Scope research to what the ticket references — not a broad exploration:
- Grep for referenced file paths, function names, feature names
- Read `ARCHITECTURE.md` and `CODING_STANDARDS.md` if present
- Skim related code

Document findings under "Research Findings" in `spec.md` (3-10 bullets).

**Suggested model:** Sonnet (code reading is structural, not deep reasoning).

### Step 3 — Draft spec skeleton

Create `stories/{slug}/spec.md` (use `templates/spec.template.md` as a starting point) with these sections:
- Ticket Summary (from Step 1)
- Research Findings (from Step 2)
- Problem Statement
- Proposed Design / Architecture — placeholder: "TBD, awaiting user alignment"
- Requirements (functional + non-functional)
- Files Affected (best-effort)
- Out of Scope
- Open Questions

### Step 4 — Architecture/design dialog (Gate 2a)

Propose **1-3 design options** inline in chat (not in spec.md yet):

- **1 option:** Acceptable when the choice is obvious from research.
- **2-3 options:** Required when a non-trivial user-facing design fork exists.

For each option: brief description, pros, cons, effort (S/M/L). Recommend one.

When options have open sub-questions, work through the 6-category question brainstorm framework. See `reference/question_brainstorm_categories_lite.md` for examples; show categories with questions and omit empty ones:

| Category | Example questions |
|---|---|
| Functional requirements | What must X do exactly? |
| User workflow / edge cases | What if only some records need this? |
| Implementation approach | Server-side vs. client-side? |
| Constraints | Perf targets, auth requirements? |
| Scope boundaries | Does this include Y? |
| Success criteria | How will the user verify it works? |

**Wait for explicit user confirmation before proceeding.** Do not fill in the spec's design section without user approval.

**Suggested model:** Opus or Sonnet (design judgment).

### Step 5 — Flesh out spec

Fill in "Proposed Design / Architecture" with the agreed approach. Refine Requirements, Files Affected, Out of Scope.

### Step 6 — Validation loop (7 spec dimensions)

Invoke the `shamt-lite-validate` skill with `artifact = stories/{slug}/spec.md`, `type = spec`. Exit: primary clean round + 1 Haiku sub-agent confirmation.

**Targeted gap-finding each round:** Ask "What code should I have read that I haven't?" and read it. New discoveries may surface new issues.

**Suggested model:** Opus (multi-dimensional reasoning).

### Step 7 — User approval (Gate 2b)

Present the validated spec to the user. User approves or requests changes.

Suggest: "Spec approved. Consider `/clear` before starting the Plan phase."

---

## Exit Criteria

- `stories/{slug}/spec.md` exists with all 8 sections filled
- Validation footer appended (`✅ Validated {date} — N rounds, 1 sub-agent confirmed`)
- User has explicitly approved (Gate 2b)

---

## Common Mistakes

- **Skipping Step 4 (design dialog).** Filling in the design without user input is the most common failure mode. Always pause for explicit approval.
- **Broad research instead of targeted.** Pattern 3 is targeted — scope to what the ticket references.
- **Fabricating ticket content from conversation.** If `ticket.md` is empty, halt and ask. Don't reconstruct from memory.
- **Skipping the validation loop.** The validation loop is what makes the spec mechanically reusable in Pattern 5. Don't skip it.
