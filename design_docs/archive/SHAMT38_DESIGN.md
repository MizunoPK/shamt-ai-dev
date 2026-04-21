# SHAMT-38: Shamt Lite Story Workflow, Polishing Phase, and Token Discipline

**Status:** In Progress
**Created:** 2026-04-20
**Branch:** `feat/SHAMT-38`
**Validation Log:** [SHAMT38_VALIDATION_LOG.md](./SHAMT38_VALIDATION_LOG.md)

---

## Problem Statement

Shamt Lite today is a toolbox of six loose patterns (validation loops, severity classification, discovery protocol, code review, question brainstorming, implementation planning). Real-world use in a workplace Agile setting — tickets too small to warrant a full S1-S11 epic — has surfaced three concrete gaps:

1. **No workflow, only patterns.** Users receive a ticket (from Jira, Linear, Slack, a verbal ask, wherever) and there is no opinionated path from "ticket received" to "change shipped and learned from." Each pattern is applicable in isolation, but users must assemble the workflow themselves every time, which is both cognitive overhead and a source of skipped steps.

2. **Discovery Protocol is too generic for ticketed work.** The current Discovery pattern is a general exploration tool for vague requests. In ticketed work, the request is already (loosely) defined in a ticket — what's needed is **targeted research + a design/architecture dialog + a validated spec**, mirroring the S2 spec phase in full Shamt, not generic exploration.

3. **No feedback loop from review comments back into the rules.** When a reviewer points out an issue, the user fixes the code and moves on. The shared standards (`CODE_STANDARDS.md`, `ARCHITECTURE.md`, `SHAMT_LITE.md` itself) are not updated, so the same class of issue resurfaces on the next ticket. The rules never learn from their own failures.

On top of these, Shamt Lite is nominally "lightweight" but has no explicit token-minimization discipline. Current SHAMT_LITE.md is ~1,500 lines of inline examples and duplicated content. The full Shamt system has a token-optimization doctrine (SHAMT-27, model selection); Lite has nothing equivalent, which is contrary to its stated purpose.

The impact of NOT solving these: Lite gets used inconsistently, drifts toward full Shamt in weight without the benefits, and never learns from real usage. Users either abandon it (too heavy for what it claims to be) or bypass parts of it (no workflow to keep them honest).

---

## Goals

1. Define an **opinionated six-phase story workflow** (Intake → Spec → Plan → Build → Review → Polish) that every story follows by default, sized so even trivial tickets can go through it without ceremony.
2. Introduce a **`stories/{slug}/` folder convention** for per-story artifacts: ticket.md, spec.md, implementation_plan.md, code_review/. (Polish phase uses commit messages + `CHANGES.md`, not a per-story log file.)
3. Replace the current Discovery Protocol with a **Spec Protocol** that mirrors S2: targeted research → design/architecture dialog → flesh out spec → validation loop.
4. Add a **Polishing Phase** that applies reviewer feedback AND performs root-cause analysis to propose upstream changes to `SHAMT_LITE.md`, `CODE_STANDARDS.md`, `ARCHITECTURE.md`, and templates.
5. Introduce a **local `CHANGES.md`** in shamt_lite that accumulates upstream-worthy Polish entries, formatted so the user can manually copy to master Shamt's `design_docs/incoming/` if desired.
6. Bake **token discipline as a first-class concern** throughout Lite: explicit per-phase model recommendations, context-clear breakpoints, single sub-agent confirmation (down from 2), and aggressive cuts to existing content.
7. **Split `SHAMT_LITE.md`**: keep a lean core file with workflow map + patterns + pointers; move the full workflow narrative into a new `story_workflow_lite.md`.
8. **Cut dead token weight** in existing Lite practices (verbose validation summaries, boilerplate checklists, mandatory option-counts, duplicated reference content) — independent of new workflow capability, simply because they don't earn their cost.
9. Ship without regressing the standalone-executable promise for the patterns themselves.

---

## Non-Goals

- Does **not** add a path to automatically sync Polish-phase proposals back to master Shamt. The user copies `CHANGES.md` entries manually into master's `incoming/` folder if they deem them worth sharing.
- Does **not** add a cleanup/archive mechanism for `stories/`. Stories accumulate; cleanup is the user's responsibility and not worth token spend.
- Does **not** attempt to validate that a freeform `ticket.md` matches any schema. It is assumed to be raw copy-paste from any source.
- Does **not** change the full Shamt S1-S11 workflow, master validation criteria, or any non-Lite guides. Every change in this design is scoped to Shamt Lite files under `.shamt/scripts/initialization/` (plus master `CLAUDE.md`/`README.md` updates that describe Lite). Full Shamt retains its existing validation patterns (two sub-agents, full validation summaries, etc.) unchanged.

---

## Detailed Design

### Proposal 1 (P1): File Architecture — Split SHAMT_LITE.md

**Description:** Decompose the current monolithic `SHAMT_LITE.template.md` into a lean core file plus a dedicated workflow file, keeping the "standalone executable" promise for patterns.

**New file layout (shipped via init_lite):**

```
shamt_lite/
├── SHAMT_LITE.md                    # Lean core: workflow map, 5 patterns, pointers
├── story_workflow_lite.md           # Full narrative for the six-phase workflow
├── CHANGES.md                       # Accumulating Polish-phase upstream candidates
├── stories/                         # Per-story work folders
├── reference/
│   ├── severity_classification_lite.md
│   ├── validation_exit_criteria_lite.md
│   └── question_brainstorm_categories_lite.md   # Now a spec sub-component reference
├── templates/
│   ├── ticket.template.md           # NEW — minimal structure hint, freeform
│   ├── spec.template.md             # NEW — replaces discovery template
│   ├── implementation_plan_lite.template.md     # Existing, minor updates
│   ├── code_review_lite.template.md             # Existing, updated for story mode
│   ├── architecture_lite.template.md
│   └── coding_standards_lite.template.md
```

**`SHAMT_LITE.md` (new structure):**
- Part 0: What Shamt Lite Is + Workflow Map (1-screen overview of the six phases + pointer to story_workflow_lite.md)
- Part 1: Core Patterns — **5 patterns** (drops Discovery, promotes Implementation Planning, demotes Question Brainstorming into spec reference)
  - Pattern 1: Validation Loops (simplified exit criterion — see P10)
  - Pattern 2: Severity Classification
  - Pattern 3: Spec Protocol (replaces Discovery — see P4)
  - Pattern 4: Code Review Process (story-mode and formal-mode variants — see P5)
  - Pattern 5: Implementation Planning
- Part 2: Token Discipline Doctrine (model recommendations per phase, context-clear breakpoints, cost notes — see P8)
- Part 3: Reference pointers
- Part 4: Template pointers

**Rationale:** Honors the standalone promise at the pattern level (an agent handed a bare pattern can still execute it) while getting the story-workflow narrative out of the core file. Lets the workflow grow without bloating the file every user reads.

**Alternatives considered:**
- Keep everything in `SHAMT_LITE.md` — rejected: violates token discipline goal; file would grow past 2,000 lines.
- Full split per pattern (one file per pattern) — rejected: destroys the "one file to read" property that makes Lite approachable.

---

### Proposal 2 (P2): Stories Folder Convention

**Description:** Introduce `shamt_lite/stories/` as the canonical per-ticket workspace. When the user receives a ticket, they (or the agent at the user's direction) create a subfolder:

```
shamt_lite/stories/{slug}/
├── ticket.md                     # Freeform — user pastes anything relevant
├── spec.md                       # Created in Spec phase
├── implementation_plan.md        # Created in Plan phase
├── code_review/
│   └── review_v1.md              # Created in Review phase (no overview.md)
```

**No per-story polish log.** The Polish phase uses commit messages (for root-cause reasoning and applied fixes) and `shamt_lite/CHANGES.md` (for upstream-worthy proposals) as its durable records. See P6.

**Slug convention:** Free-form. Examples: `PROJ-1234-csv-export`, `fix-login-timeout`, `2026-04-20-dashboard-bug`. The agent does not enforce a format; it uses whatever the user provides.

**Naming collisions:** If the user creates a story folder that already exists, the agent warns and halts — does not overwrite. This is explicit in the Intake phase instructions.

**Active-story convention:** The agent does NOT track which story is "active" via marker files, most-recent-modified heuristics, or session state. The user **names the slug explicitly** every time they invoke the agent on story work — e.g., "begin Spec phase for `PROJ-1234-csv-export`" or "polish the `fix-login-timeout` story." Rationale: marker files go stale across sessions, heuristics guess wrong when multiple stories are in flight, and explicit naming costs the user ~5 tokens per invocation while removing an entire class of "wrong story modified" failure mode. If the user invokes a story-phase action without naming a slug, the agent asks rather than guessing.

**Rationale:** Co-locates all artifacts for a story in one place. Easy for the user to send a reviewer the folder; easy for the agent in the Polish phase to see the full arc of the story (ticket → spec → plan → review → polish).

**Alternatives considered:**
- Flat structure (`specs/`, `plans/`, `reviews/` top-level, linked by filename) — rejected: harder to navigate, Polish phase harder to run because artifacts are scattered.
- Per-story branch in git with no folder — rejected: divorces artifacts from the git history of the code change itself.

---

### Proposal 3 (P3): The Six-Phase Story Workflow

**Description:** Define an opinionated workflow that every story follows by default. Phases are lightweight — each has a "minimum viable artifact" size so trivial tickets can pass through without ceremony.

| # | Phase | Artifact | Gate |
|---|---|---|---|
| 1 | **Intake** | `stories/{slug}/ticket.md` | User confirms slug and ticket content captured |
| 2 | **Spec** | `spec.md` | (a) User approves architecture/design proposal, then (b) user approves validated spec |
| 3 | **Plan** | `implementation_plan.md` | User approves validated plan |
| 4 | **Build** | code changes | (none — verification checklist in the plan) |
| 5 | **Review** | `code_review/review_v1.md` | (none — review is the artifact) |
| 6 | **Polish** | commit messages + `CHANGES.md` entries (no per-story log file) | User signals "polishing complete" in chat |

**Minimum viable artifacts (1-line bug fix path):**
- `ticket.md`: whatever the user pasted
- `spec.md`: 3-5 lines — problem, chosen approach, files affected
- `implementation_plan.md`: 1-3 steps
- `review_v1.md`: can be empty or "no issues found"
- Polish phase: if nothing to polish, phase is a no-op (no log file to create either way)

**Default-mandatory, user-overridable:** The agent always follows the workflow unless the user explicitly instructs otherwise (e.g., "skip the spec, just do it"). The agent should not proactively decide to skip phases.

**Context-clear breakpoints (recommended):** After Gate 2b (spec approved), the agent should suggest `/clear` before starting the Plan phase. After Gate 3 (plan approved), suggest `/clear` before Build. Between Review and Polish is optional. These are advisory, not mandatory.

**Rationale:** The six phases mirror the most valuable parts of S1-S11 (S2 spec, S5 plan, S6 build, S7/S9 review) plus a new Polish phase tailored to small-ticket reality (PR comments come in, you fix them, you ideally learn from them). Minimum-viable artifact sizing prevents the workflow from becoming overhead for trivial work.

**Alternatives considered:**
- Four phases (collapse Intake into Spec, Plan into Build) — rejected: Intake-as-distinct-phase captures the "paste the ticket" moment cleanly; Plan-as-distinct-phase preserves the architect/builder boundary for larger Lite work.
- Decision tree to skip phases automatically — rejected per user direction #2: always follow unless told otherwise.

---

### Proposal 4 (P4): Spec Protocol (Replaces Discovery Protocol)

**Description:** Define a new pattern — the Spec Protocol — that replaces the current Discovery Protocol entirely. Mirrors S2 in full Shamt: targeted research, design dialog, flesh-out, validation loop.

**The 7-step Spec Protocol:**

**Step 1 — Ingest the ticket.** Read `ticket.md`. Treat it as unstructured raw text (could be Jira HTML, a pasted email, Slack thread, voice-memo transcript). Extract structured understanding: what's being asked, acceptance criteria (explicit or implied), links, due dates, any constraints. Output a **brief in-agent summary** (3-5 bullets, do NOT write it to disk yet).

**Minimum input requirement:** Any non-empty content is sufficient — there is no schema. If `ticket.md` is empty or missing, the agent halts and asks the user to populate it. The agent does NOT attempt to fabricate ticket content from prior conversation context.

**Step 2 — Targeted research.** Unlike Discovery's broad exploration, Spec research is scoped by the ticket. Grep for referenced file paths, function names, feature names. Read `ARCHITECTURE.md` and `CODING_STANDARDS.md` if present. Skim related code. Document findings in spec.md under "Research Findings" (3-10 bullets).

**Step 3 — Draft spec skeleton.** Create `spec.md` with these sections:
- Ticket Summary (from Step 1)
- Research Findings (from Step 2)
- Problem Statement
- Proposed Design / Architecture — *placeholder: "TBD, awaiting user alignment"*
- Requirements (functional + non-functional)
- Files Affected (best-effort list)
- Out of Scope
- Open Questions

**Step 4 — Architecture/design dialog (GATE 2a).** Propose 1-3 design/architecture options to the user inline in chat (not in spec.md yet). Each option: brief description, pros, cons, effort (S/M/L). Recommend one. **Wait for the user to pick an option or propose a variant.** Do not proceed without explicit user confirmation.

**Step 5 — Flesh out spec.** Fill in the "Proposed Design / Architecture" section with the agreed approach. Refine Requirements, Files Affected, Out of Scope.

**Step 6 — Validation loop.** Run validation (Pattern 1) on spec.md using **these 7 dimensions** (S2-style):
1. Completeness
2. Correctness
3. Consistency
4. Helpfulness
5. Improvements
6. Missing proposals
7. Open questions

**Critical addition vs. current Discovery validation:** Each validation round also performs **targeted gap-finding research** — the agent asks itself "what code should I have read by now that I haven't?" and reads it. New discoveries may trigger new issues.

Exit criterion: primary clean round + **1 sub-agent confirmation** (see P10).

**Step 7 — User approval (GATE 2b).** Present validated spec. User approves or requests changes. On approval, the Spec phase is complete.

**Question brainstorming:** The 6-category framework (currently Pattern 5 in the pre-SHAMT-38 structure) is **demoted from a top-level pattern** to a reference callout used inside Spec Step 4 when proposing design options or inside Step 6 when checking the "Open questions" dimension. The reference file `reference/question_brainstorm_categories_lite.md` remains, but is linked from Spec Protocol rather than from a top-level pattern listing.

**Rationale:** Ticketed work starts with *some* concrete input (the ticket). The old Discovery Protocol treats every request as a blank-slate exploration, which wastes tokens. Spec Protocol assumes a ticket exists and optimizes for "research + design dialog + validated spec" — the actual workplace shape.

**Alternatives considered:**
- Keep both Discovery and Spec — rejected: confuses users, adds weight, Discovery has no clear use case if you're always working from a ticket.
- Skip the architecture dialog gate (2a) — rejected: the dialog is where most misalignment gets caught cheaply, before the validation loop expends tokens on a spec the user would have rewritten.

---

### Proposal 5 (P5): Code Review Process — Story Mode

**Description:** Extend the existing Code Review pattern to support two modes:

**Formal mode (external PR/branch review):** Reviewing someone else's branch/PR. Produces `.shamt/code_reviews/<branch>/` with `overview.md` + `review_v1.md`. The `overview.md` in the existing Shamt Lite (pre-SHAMT-38) has four sections (ELI5, What, Why, How); P11-D removes ELI5, leaving three: What Does This Branch Do, Why Was It Built, How Does It Work.

**Story mode (NEW):** Reviewing the code changes for a story the agent/user just built. Produces `stories/{slug}/code_review/review_v1.md` **only** — no `overview.md`. Rationale: the story folder already has `ticket.md`, `spec.md`, and `implementation_plan.md`, which collectively provide better context than an overview.md would.

**Mode selection:** Determined by context. If invoked during the Review phase of an active story, use story mode. If invoked via "review branch X" or similar, use formal mode.

**Same review format in both modes:** severity-first grouping (BLOCKING/CONCERN/SUGGESTION/NITPICK), 12 categories, validation loop on review.md.

**Re-review versioning:** In both modes, subsequent reviews create `review_v2.md`, `review_v3.md`. Never overwrite.

**Rationale:** Story mode drops redundant overview generation (token savings). Formal mode keeps overview for external reviewers who don't have the story folder.

**Alternatives considered:**
- Always skip overview.md — rejected: formal reviews of external branches genuinely need it.
- Make overview optional per-invocation flag — rejected: mode selection from context is simpler and less error-prone.

---

### Proposal 6 (P6): The Polishing Phase

**Description:** A new phase — Polishing — that runs after Review. It is the learning loop: every reviewer comment becomes both a fix and a potential standard-improvement proposal.

**Trigger:** User pastes a PR comment, points out an issue verbally, or identifies something they want changed. Each trigger is a **polish cycle**.

**Per polish cycle, the agent executes 5 steps:**

**Step 1 — Apply the fix.** Make the code change requested. No ceremony.

**Step 2 — Root-cause analysis.** The agent asks:
- Why did this issue make it past Spec, Plan, and Build?
- Was it a missing question in the Spec Protocol?
- A missing validation dimension?
- A gap in `CODE_STANDARDS.md`?
- An architectural principle not documented in `ARCHITECTURE.md`?
- An unclear step or example in `SHAMT_LITE.md` itself?
- Or genuinely a one-off that wouldn't be caught by any standard?

**Target selection guidance (when multiple targets apply):** Draft proposals for all applicable targets — the user decides which to accept in Step 4. The following maps common issue types to the right proposal target:
- Code style, naming, or pattern issue → `CODE_STANDARDS.md`
- Architectural decision or structural principle → `ARCHITECTURE.md`
- Something a spec question would have caught → Spec Protocol dimensions or Question Brainstorm categories; if a structural section is missing from the spec template → spec.template.md
- Something a review dimension would have caught → Code review categories in `SHAMT_LITE.md`
- Framework behavior the agent got wrong → `SHAMT_LITE.md` pattern wording or example
- One-off with no generalizable lesson → commit message only, no upstream proposal

**Spec loopback:** If root-cause analysis reveals that the spec was fundamentally wrong — not just incomplete in a patchable way, but the chosen design/architecture was the wrong approach — the agent recommends formally re-entering the Spec phase (Gate 2a/2b). The user decides whether to accept that loopback. This is distinct from small gaps, which are handled in place via Polish's upstream proposals.

**Step 3 — Propose upstream changes.** For each applicable target, draft a specific change:
- **Spec template** (`spec.template.md`) — new required section, new prompt
- **SHAMT_LITE.md patterns** — new validation dimension, new example, stricter gate wording
- **Question brainstorm categories** — new category or example
- **Code review categories** — new category
- **`CODE_STANDARDS.md`** — new rule, new example, anti-pattern
- **`ARCHITECTURE.md`** — new decision record, new principle

Each proposal is drafted as a specific diff/snippet, not a vague idea. If multiple targets apply, draft a proposal for each — the user gates them independently in Step 4.

**Step 4 — User decides.** The agent presents the proposals. The user approves, rejects, or modifies each one. No validation loop — the user is the gate.

**Step 5 — Apply accepted proposals + record durably via commit + CHANGES.md.** For each accepted proposal:
1. Apply the change to the appropriate local file (`SHAMT_LITE.md`, `CODE_STANDARDS.md`, etc.).
2. Write a **commit message** capturing root cause + applied changes + rejected proposals. This is the durable per-story record (replaces the previously-proposed `polishing_log.md`).
3. If the change is judged **generic** (would benefit other projects, not specific to this codebase), also append an entry to `shamt_lite/CHANGES.md` (see P7).

**"Polish complete" signal:** The user tells the agent when polishing is done (typical trigger: PR is merged or the user has no more feedback). No durable marker file — the chat message ends the phase; the git log is the persistent record.

**Recommended commit message format for Polish commits:**

```
polish({slug}): {brief description of fix}

PR comment / feedback:
{paste or summarize}

Root cause:
{1-3 sentences on why this slipped through Spec/Plan/Build/Review}

Applied:
- CODE_STANDARDS.md: new rule "auth middleware must validate token expiry"
- SHAMT_LITE.md §Pattern 3: added dimension "security boundary review"

Rejected:
- Project-specific rule about X — too narrow

Upstream to master? Yes — CHANGES.md entry added / No — project-specific
```

**Why commit messages, not a log file:**
- Applied changes are already in `git diff` + affected files — a log duplicates them
- Root cause fits naturally in commit body
- Rejected proposals rarely need to persist beyond the session
- One fewer artifact to maintain, read, and validate
- Walk-away recovery: if user returns mid-polish next day, `git log` + the PR comment string provides enough context

**Rationale:** Most real-world learning happens in review feedback. Without a structured capture step, the learning is lost. Polish phase institutionalizes the capture and the local-propagation of improvements — *and does so using git's existing durable record rather than inventing a new file format.*

**Alternatives considered:**
- Per-story `polishing_log.md` file — rejected: redundant with git commits + CHANGES.md; pure token cost for no added durability.
- Make upstream proposals optional/on-demand — rejected: people won't do it if not prompted; the default must be "always consider."
- Run a validation loop on root-cause analysis — rejected per user direction #7: the user is already in the loop via approval.
- Auto-apply proposals without user approval — rejected: destroys trust, risks polluting local standards with AI-generated noise.

---

### Proposal 7 (P7): Local `CHANGES.md` for Upstream-Worthy Proposals

**Description:** Introduce `shamt_lite/CHANGES.md` as a running log of Polish-phase entries that are **generic** (applicable to any Shamt Lite project, not tied to this codebase's specifics). The user can manually copy entries to master Shamt's `design_docs/incoming/` if they want to share upstream.

**Entry format:**

```markdown
## {Date} — {Short title}

**Story:** {slug}
**Target file(s):** {which shamt_lite file(s) were updated}

**Change applied locally:**

{Full diff/snippet of the change made to the local file.}

**Rationale:** {Why this would benefit other projects. What issue it prevents.}

**Generic (not project-specific):** {Why this isn't tied to this codebase's specific domain.}
```

**Copy-to-master procedure (documented in CHANGES.md header):**
1. User identifies entries worth sharing.
2. User creates a file `{project}-{story-slug}-SHAMT-UPDATE-PROPOSAL.md` copying the entry content.
3. User drops it in master's `design_docs/incoming/` (via PR, as per master child-proposal handling).

**Rationale:** Preserves the learning-loop from Polish while respecting user direction #4 (no automatic sync, local only + optional manual share). The format is already compatible with master's existing `incoming/` review process.

**No CHANGES.md for non-generic entries:** Project-specific entries live only in the story's commit messages (`git log`) — not promoted to CHANGES.md. The agent makes the genericness judgment during Polish Step 5 and flags it for user confirmation before writing to CHANGES.md.

**Alternatives considered:**
- Auto-export via script to a staging location — rejected per user direction #4: manual copy is fine, automation is overkill.
- Log everything to CHANGES.md (generic and specific) — rejected: pollutes the upstream candidate pool, makes manual curation harder.

---

### Proposal 8 (P8): Token Discipline Doctrine

**Description:** Introduce an explicit **Token Discipline** section (Part 2 of the new `SHAMT_LITE.md`) as a first-class concern, not an afterthought.

**Components:**

**8a. Per-phase model recommendations:**

| Phase / Activity | Recommended Model | Rationale |
|---|---|---|
| Intake (ticket capture) | Haiku | Mechanical; no reasoning needed |
| Spec Step 2 (research) | Sonnet | Code reading, structural |
| Spec Step 4 (design dialog) | Opus or Sonnet | Design judgment |
| Spec Step 6 (validation loop) | Opus | Multi-dimensional reasoning |
| Plan creation | Sonnet | Structured, pattern-following |
| Plan validation | Sonnet | 7-dimension check, lighter than spec |
| **Builder (Build phase)** | **Haiku (mandatory if plan is mechanical)** | Execution at Haiku rates instead of planning-model rates |
| Review (issue finding) | Opus | Classification + judgment |
| Review (git metadata fetch) | Haiku | Mechanical |
| Polish Step 1 (apply fix) | Sonnet | Code editing |
| Polish Step 2 (root cause) | Opus | Causal reasoning |
| Polish Step 3 (propose upstream) | Opus | Cross-doc reasoning |
| **Sub-agent confirmations (any phase)** | **Haiku (always)** | Mechanical re-check |

**8b. Context-clear breakpoints (advisory):**
- After Gate 2b (spec approved), before Plan phase
- After Gate 3 (plan approved), before Build
- Between Build and Review (optional)
- Between Review and Polish (optional, depending on review size)

**8c. Inline "cost notes":** Small callouts at key decision points, e.g.:
> 💡 *Cost note: if plan has >20 mechanical steps and you stay in this context, you're burning Opus/Sonnet tokens on file operations. Spawn a Haiku builder (see Pattern 5 — implementation planning section) — builder execution is materially cheaper than self-execution.*

**8d. Pattern-level token notes:** Each of the 5 patterns gets a one-line **qualitative** "token cost profile" — e.g. "Validation loop: cost scales with rounds × artifact size; one sub-agent confirmation per loop." No numeric token estimates and no model-pricing references — both go stale fast as the model lineup and pricing change. Where helpful, use relative comparisons ("Builder handoff is materially cheaper than self-execution for plans with many mechanical steps") instead of percentages.

**Rationale:** Without explicit doctrine, token discipline is wishful thinking. Codifying model choices and context-clear breakpoints makes the expectation concrete and auditable.

**Alternatives considered:**
- Keep model selection implicit / up to agent discretion — rejected: current Lite is bloat-prone precisely because token cost isn't foregrounded.
- Make all recommendations mandatory — rejected: some activities are context-dependent (e.g. if spec is trivial, Opus is overkill even for validation); "recommended with guidance" is the right default.

---

### Proposal 9 (P9): Cuts to Current SHAMT_LITE.md

**Description:** To make room for the new workflow content without growing the file, aggressively cut existing content.

**Specific cuts:**

| Current content | Disposition | Savings (est.) |
|---|---|---|
| Pattern 3 (Discovery Protocol) — entire pattern | **Delete** (replaced by Spec Protocol in P4) | ~150 lines |
| Pattern 5 (Question Brainstorming) as top-level pattern | **Demote** — move to a brief reference inside Spec Protocol; keep reference file | ~190 lines from main |
| Verbose in-pattern examples (CSV-export example in discovery, full code review example output, implementation plan example with 4 steps) | **Trim** — keep short illustrative snippets only; move full examples to reference files | ~300 lines |
| Duplicated "Cheat Sheets" section at end | **Consolidate** — one compact cheat sheet, not six | ~80 lines |
| Validation loop example (full round-by-round walkthrough) | **Trim** — keep summary only; move walkthrough to `reference/validation_exit_criteria_lite.md` | ~40 lines |
| "How to Use This File" 3-tier structure intro | **Collapse** into a short "how to read" paragraph | ~20 lines |

**Net effect:** Main SHAMT_LITE.md drops from ~1,540 lines to ~600-700 lines before new content is added. After adding workflow map (P3), token doctrine section (P8), updated Spec Protocol pointer (P4), updated Code Review story-mode note (P5), and Polish pattern pointer (P6), the file lands around ~900-1,000 lines — a net reduction of 30-40% while adding significant new capability.

**Rationale:** Token discipline goal requires cutting existing bloat, not just sizing new content conservatively. Moving examples to reference files preserves access while keeping the file a user would read front-to-back short.

**Alternatives considered:**
- Leave existing content, only add new — rejected: violates token goal, makes file unreadable.
- More aggressive cuts (drop Pattern 2 severity classification to reference) — rejected: severity is referenced inline in every validation round; needs to stay in main.

---

### Proposal 10 (P10): Lite Validation Exit Criterion — Single Sub-Agent

**Description:** Change Lite's validation loop exit criterion from "primary clean round + 2 independent sub-agent confirmations" to "primary clean round + **1** sub-agent confirmation."

**Scope:** Applies to **every** Lite validation loop invocation, whether inside the story workflow (spec, plan, review) or invoked ad-hoc outside any story (e.g., user says "validate this file"). The criterion travels with Lite, not with the workflow context. Does **not** apply to full Shamt or to master-repo design docs (artifacts in `design_docs/`) — only to per-project Lite invocations. Full Shamt retains its 2-sub-agent criterion.

**Behavior change:**
- When `consecutive_clean = 1`, spawn **1** Haiku sub-agent (not 2).
- If the sub-agent finds 0 issues → validation complete.
- If the sub-agent finds issues → fix, reset `consecutive_clean = 0`, restart primary rounds.

**Rationale:** Lite is explicitly the lightweight variant. The second sub-agent provides diminishing marginal assurance (if one Haiku agent with fresh eyes finds nothing, a second one finding something is rare) at a direct 50% increase in sub-agent token spend. Aligns with the Token Discipline doctrine.

**Alternatives considered:**
- Keep 2 sub-agents — rejected per user direction #3.
- Drop sub-agent confirmation entirely — rejected: the fresh-eyes check is the main value of the loop; removing it turns validation into unchecked self-review.

---

### Proposal 11 (P11): Existing-Practice Token Cuts

**Description:** Independent of the new workflow content (P1-P10), the current Lite has several practices that cost tokens without earning their cost. This proposal cuts or trims them. **All cuts are scoped to Shamt Lite files only** — full Shamt's equivalent practices (which operate at a different scale and risk level) are untouched.

**Cuts:**

**P11-A. Verbose validation summary blocks → single-line footer.**

Current Lite Pattern 1 Step 8 mandates a multi-line block on every validated artifact:

```
## Validation Summary
**Rounds completed:** N
**Exit criteria:** Primary clean round + sub-agent confirmation
**Sub-agent A:** 0 issues ✅
**Sub-agent B:** 0 issues ✅
**Issues found and resolved during validation:** N
```

Replace with a single-line footer:

```
---
✅ Validated {date} — {N} rounds, 1 sub-agent confirmed
```

Preserves provenance and exit-criteria acknowledgment; drops ~80% of tokens.

**Applies to:** spec.md, implementation_plan.md, review.md (story + formal modes), overview.md (formal mode).

---

**P11-B. Drop pre-execution and post-execution checklists in implementation plans.**

Current `implementation_plan_lite.template.md` has two generic boilerplate checklists:

- Pre-execution: "Requirements documented / Files identified / Dependencies understood / Backup current / Plan validated"
- Post-execution: "All steps executed / Verifications passed / No side effects / Tests pass / Feature works"

These are redundant with per-step Verifications (already present in every step) and with the validation loop itself (which already confirms the plan is complete). Drop both.

---

**P11-C. Per-step "Verification:" becomes optional, not mandatory.**

Current format requires a Verification line on every CREATE/EDIT/DELETE/MOVE step. For trivial edits ("change `cnt` to `count` in line 42"), verification is self-evident and adds noise.

New rule: **Verification is required when step success depends on tooling or runtime behavior; optional for pure text/content edits.** Captured as an examples list rather than a strict rule, because the boundary is fuzzy in practice.

**Verification REQUIRED — examples:**
- Step creates or modifies code that must compile (TypeScript, Java, Rust, etc.)
- Step adds or modifies a test (`npm test` / `pytest` / etc. must pass)
- Step adds a linter-affecting change (rule must be picked up)
- Step adds a new API endpoint (must respond to a request)
- Step adds a config value consumed at runtime (must be loaded successfully)
- Step modifies a database schema or migration

**Verification OPTIONAL — examples:**
- Pure text replacements (typo fixes, wording changes)
- Markdown / docs / comment edits with no code impact
- Renaming a private variable consistently in a single file
- Reordering imports for style
- Deleting an obsolete file that has no remaining references

**When in doubt:** include the verification — it's cheaper than discovering breakage later.

---

**P11-D. Drop "ELI5 — What Changed?" from formal code review `overview.md`.**

Current overview.md has four sections: ELI5, What Does This Branch Do, Why Was It Built, How Does It Work. ELI5 is the most token-heavy and most overlaps with "What Does This Branch Do" — it's essentially "the same content but in simpler words."

Drop ELI5. Keep: What, Why, How. This applies to formal-mode overview.md only (story mode already has no overview.md per P5).

---

**P11-E. Drop "one-line justification for empty categories" in question brainstorming.**

Current `reference/question_brainstorm_categories_lite.md` forces the agent to either list questions OR write a justification like "None identified — approach is clear from request" for each of the 6 categories. This produces 6 mandatory lines even when 2 are substantive.

New rule: show categories with questions; omit empty ones. The brainstorming still happens mentally — the agent considers all 6 categories, but only writes output for the ones that produced questions. The red-flag check ("zero questions across all categories is suspicious") is retained as a check, not a per-category output requirement.

---

**P11-F. Allow 1 option in Spec architecture dialog when the choice is obvious.**

Current Discovery Protocol Step 5 mandates "Design 2-3 solution options" with Pros/Cons/Effort/Fit for each. When the right answer is obvious from research, generating 2-3 options is performative — the agent invents filler alternatives just to satisfy the count.

New rule in Spec Protocol Step 4: present 1-3 options. Require ≥2 only when the user-facing design fork is non-trivial (e.g. "server-side vs client-side CSV generation"). When it's a single clear answer, present 1 with rationale.

---

**P11-G. Compress verbose "Key Rules" summaries at the end of each pattern.**

Current SHAMT_LITE.md patterns each end with a "Key Rules" section that restates what the pattern body already said in bullet form. Drop these — the pattern text is canonical; restating it costs tokens and drifts out of sync.

**Exception:** Pattern 2 (severity classification) has a "Quick Classification Decision Tree" that is genuinely faster to scan than the body — keep that one but call it what it is.

---

**P11-H. De-duplicate between SHAMT_LITE.md and `reference/*.md`.**

Current state: `reference/severity_classification_lite.md` (272 lines), `reference/validation_exit_criteria_lite.md` (261 lines), and `reference/question_brainstorm_categories_lite.md` (194 lines) duplicate most of their content with SHAMT_LITE.md's corresponding patterns. A user reading both reads the same material twice.

New rule: main file is **canonical for the minimum needed to execute the pattern**; reference file holds **only additional depth** (borderline cases, common mistakes, edge-case examples). Each reference file opens with "This file extends Pattern N in SHAMT_LITE.md; read that first."

**Critical update triggered by P10:** `validation_exit_criteria_lite.md` currently prescribes "two independent sub-agents" — must be updated to the single-sub-agent Lite criterion as part of this cut.

---

**P11-I. Reference files stay (not deleted); pure trimming only.**

Considered deleting `reference/*.md` entirely and keeping only what's in SHAMT_LITE.md + `story_workflow_lite.md`. Rejected: the reference files contain genuinely useful depth (decision trees, borderline cases, common mistakes) that would bloat the main file if inlined. Keep all three reference files; trim per P11-H.

---

**Net effect of P11:**

| Cut | Files touched | Estimated tokens saved per invocation |
|---|---|---|
| P11-A | All validated artifacts | 80-90% of validation summary footprint |
| P11-B | implementation_plan_lite.template.md | 10-15 boilerplate items dropped |
| P11-C | implementation_plan_lite.template.md | ~1 line per trivial step |
| P11-D | code_review_lite.template.md (formal mode only) | 2-4 sentences per formal review |
| P11-E | question_brainstorm_categories_lite.md + Spec Protocol | 4-6 lines per spec on average |
| P11-F | Spec Protocol | 20-40 lines per spec when choice is obvious |
| P11-G | SHAMT_LITE.md (all patterns) | ~30 lines total |
| P11-H | SHAMT_LITE.md + 3 reference files | 200-400 lines of duplicated content |

**Rationale:** Token discipline means cutting dead weight, not just sizing new content conservatively. These cuts each fail the test "does this earn its cost?" Most are minor individually; together they make a material difference, and none degrade the quality of the work being produced.

**Alternatives considered:**
- Keep everything as-is, offset only via P9 cuts — rejected: P9 pays for new content (workflow map + token doctrine); P11 is independent cleanup that should happen regardless.
- More aggressive cuts (delete reference files, drop 12 review categories, merge severity into validation) — rejected: each of those either deletes genuinely useful depth (reference files) or destroys a load-bearing structure (categories, severity).

---

## Files Affected

| File | Status | Notes |
|---|---|---|
| `.shamt/scripts/initialization/SHAMT_LITE.template.md` | MODIFY | Rewrite per P1 + P9 + P11-A + P11-G: lean core with workflow map, 5 patterns (dropping Discovery, demoting Question Brainstorming), token doctrine, single-line validation footer, trimmed "Key Rules" sections, pointers |
| `.shamt/scripts/initialization/story_workflow_lite.template.md` | CREATE | New — full narrative of six-phase workflow (P3), including phase-by-phase instructions, gates, model recommendations |
| `.shamt/scripts/initialization/CHANGES.template.md` | CREATE | New — template for local CHANGES.md with header explaining copy-to-master procedure (P7) |
| `.shamt/scripts/initialization/templates/ticket.template.md` | CREATE | New — minimal structure hint, explicitly freeform (P2) |
| `.shamt/scripts/initialization/templates/spec.template.md` | CREATE | New — replaces discovery template; S2-style sections (P4); P11-F note "1-3 options, ≥2 only when non-trivial fork"; P11-A single-line validation footer |
| `.shamt/scripts/initialization/templates/discovery_lite.template.md` | DELETE | Replaced by `spec.template.md` (P4) |
| `.shamt/scripts/initialization/templates/implementation_plan_lite.template.md` | MODIFY | Story-folder context + Haiku builder emphasis (P8); drop pre/post-execution checklists (P11-B); optional Verification field (P11-C); P11-A single-line validation footer |
| `.shamt/scripts/initialization/templates/code_review_lite.template.md` | MODIFY | Add story-mode variant: no overview.md, path `stories/{slug}/code_review/` (P5); drop ELI5 section from formal-mode overview.md (P11-D); P11-A single-line validation footer |
| `.shamt/scripts/initialization/reference/validation_exit_criteria_lite.md` | MODIFY | Update to single sub-agent criterion (P10); extend-not-duplicate main file (P11-H); receive trimmed examples moved from main (P9) |
| `.shamt/scripts/initialization/reference/severity_classification_lite.md` | MODIFY | Extend-not-duplicate main file (P11-H); receive borderline-case examples moved from main (P9) |
| `.shamt/scripts/initialization/reference/question_brainstorm_categories_lite.md` | MODIFY | Reframe as Spec-phase reference (P4); drop "justify empty categories" mandate (P11-E); extend-not-duplicate (P11-H) |
| `.shamt/scripts/initialization/init_lite.sh` | MODIFY | Create `stories/` folder, copy new templates, copy `story_workflow_lite.md`, copy `CHANGES.md` |
| `.shamt/scripts/initialization/init_lite.ps1` | MODIFY | Same changes as `init_lite.sh` for PowerShell |
| `CLAUDE.md` (master root) | MODIFY | Update "Shamt Lite" section to reflect new file layout, new workflow, `CHANGES.md` convention |
| `README.md` (master root) | MODIFY | Update Shamt Lite mentions to reflect new structure if any |

**Total:** 4 CREATE, 10 MODIFY, 1 DELETE. (Down from 5 CREATE after dropping `polishing_log.template.md`.)

---

## Implementation Plan

### Phase 1: Skeleton, Templates, and Init Script Updates
Produce the new files empty/skeletal, update init_lite scripts, and verify init_lite copies them correctly.
- [ ] Create `story_workflow_lite.template.md` with section headers only
- [ ] Create `CHANGES.template.md` with header + empty entry
- [ ] Create `ticket.template.md` and `spec.template.md` (minimal)
- [ ] Update `init_lite.sh` and `init_lite.ps1` to create `stories/` folder and copy new files (P2)
- [ ] Smoke test: run `init_lite.sh` against a scratch directory, verify structure

### Phase 2: Write Story Workflow Narrative
Flesh out `story_workflow_lite.template.md` per P3-P8.
- [ ] Intake phase section with freeform ticket.md note
- [ ] Spec phase section with 7-step Spec Protocol (P4), including architecture dialog (Gate 2a) and validation loop (Gate 2b, using single-sub-agent criterion per P10); include P11-F note on 1-3 options
- [ ] Plan phase section (reference Pattern 5 in SHAMT_LITE.md)
- [ ] Build phase section with mandatory Haiku builder guidance (P8)
- [ ] Review phase section with story-mode pointer (P5)
- [ ] Polish phase section with 5-step polish cycle (P6) using commit messages + CHANGES.md (no polishing_log.md), CHANGES.md writeout rules (P7)
- [ ] Inline per-phase model recommendations from the P8 table into each phase section of story_workflow_lite.md
- [ ] Context-clear breakpoint recommendations (P8)

### Phase 3: Rewrite SHAMT_LITE.md
Execute P1 (file structure), P9 (content cuts), P10 (single sub-agent in Pattern 1), and all P11 cuts that affect SHAMT_LITE.md's pattern descriptions and structure (see task checklist; P11-B/C/D are documented in pattern text here — their template-level changes are in Phase 4): lean core file.
- [ ] Part 0: Workflow map (1-screen, pointer to story_workflow_lite.md)
- [ ] Part 1: 5 core patterns
  - [ ] Pattern 1 (Validation) — update for single sub-agent criterion (P10); replace multi-line validation summary with single-line footer (P11-A); trim example
  - [ ] Pattern 2 (Severity) — trim verbose examples, move to reference (P11-H)
  - [ ] Pattern 3 (Spec Protocol) — NEW, replaces Discovery; include 1-3 option rule (P11-F; also written into story_workflow_lite.md in Phase 2)
  - [ ] Pattern 4 (Code Review) — note formal vs story mode (P5); drop ELI5 from formal overview.md (P11-D)
  - [ ] Pattern 5 (Implementation Planning) — Haiku builder emphasis; drop pre/post-execution checklists (P11-B); optional Verification field (P11-C)
- [ ] Part 2: Token Discipline Doctrine (P8)
- [ ] Part 3: Reference pointers (updated)
- [ ] Part 4: Template pointers (updated)
- [ ] Drop verbose "Key Rules" summaries at end of each pattern, except Pattern 2's decision tree (P11-G)
- [ ] Consolidated quick reference / cheat sheet (P9)

### Phase 4: Update Reference and Existing Templates
- [ ] Update `validation_exit_criteria_lite.md`: single sub-agent (P10); add "extends Pattern 1" header, strip duplicated content (P11-H); receive trimmed examples from main
- [ ] Update `severity_classification_lite.md`: add "extends Pattern 2" header, strip duplicated content (P11-H); receive borderline-case examples from main
- [ ] Update `question_brainstorm_categories_lite.md`: reframe as Spec-phase reference (P4); drop empty-category justification rule (P11-E); add "extends Spec Protocol" header, strip duplication (P11-H)
- [ ] Update `implementation_plan_lite.template.md`: story-folder context; drop pre/post-execution checklists (P11-B); make Verification optional (P11-C); single-line validation footer (P11-A)
- [ ] Update `code_review_lite.template.md`: story-mode variant (P5); drop ELI5 from formal overview.md (P11-D); single-line validation footer (P11-A)
- [ ] Delete `discovery_lite.template.md`

### Phase 5: Update Master Documentation
- [ ] Update `CLAUDE.md` "Shamt Lite" section (new file layout, new workflow, CHANGES.md)
- [ ] Update root `README.md` Shamt Lite mentions if applicable

### Phase 6: End-to-End Dry Run
- [ ] Run `init_lite.sh` into a scratch directory
- [ ] Fabricate a tiny ticket.md
- [ ] Walk through all six phases step-by-step (simulating how an agent would follow the workflow file), verifying each phase instruction is complete and unambiguous
- [ ] Fabricate one PR comment and walk through Polish phase: commit-message writeout + CHANGES.md entry
- [ ] Verify Polish Step 2 root-cause path can recommend re-entering Spec (loopback scenario, P6 Step 2)
- [ ] Spot-check a validated artifact has a single-line footer, not a multi-line block (P11-A)
- [ ] Verify final scratch directory looks like what we'd want a user to have

### Phase 7: Design Doc Validation Loop
- [ ] Run 7-dimension validation on this design doc (see Validation Strategy)

### Phase 8: Implementation Validation Loop
- [ ] After all implementation phases complete, run 5-dimension implementation validation
- [ ] Run full guide audit on `.shamt/guides/` (3 consecutive clean rounds)
- [ ] Archive design doc + validation log to `design_docs/archive/`

---

## Validation Strategy

**Design doc validation:** Run the 7-dimension validation loop per `.shamt/guides/design_doc_validation/` on this document. Exit: primary clean round + 2 independent sub-agent confirmations. Use the master validation criterion (2 sub-agents) — this design doc is a master-repo artifact (permanent design_docs/ archive entry that governs all future Lite deployments), not a per-project Lite artifact (which is what P10's single-sub-agent scope covers), so P10 does not apply here.

**Implementation validation:** After Phase 6 (dry run) but before Phase 8 archive, run 5-dimension implementation validation:
1. **Completeness** — Every proposal (P1-P11) implemented?
2. **Correctness** — Does the implementation match what was proposed?
3. **Files Affected Accuracy** — Files in the table match reality?
4. **No Regressions** — Full-mode code review still works? Init scripts still produce valid output?
5. **Documentation Sync** — `CLAUDE.md` reflects new layout?

**Gate: Phase 6 (dry run) is a mandatory prerequisite before Phase 8 (implementation validation) can begin.** Phase 6 (fabricated story walkthrough) must succeed before proceeding to Phase 8 (implementation validation, which also includes archival). If the workflow reads awkwardly or a step is missing, it must be fixed and the dry run re-run. The dry run is not optional.

**Full guide audit:** After implementation validation passes, run the full `.shamt/guides/` audit (3 consecutive clean rounds) to ensure master guides weren't inadvertently affected. This design primarily touches `.shamt/scripts/initialization/`, but `CLAUDE.md` and master docs are in scope.

---

## Open Questions

*(All major design questions have been resolved in the design conversation preceding this doc; captured here for the record.)*

| Question | Resolution | Source |
|---|---|---|
| SHAMT_LITE.md monolith vs split? | Split: lean core + `story_workflow_lite.md` + pointers | User direction #1 |
| Workflow mandatory or opt-in? | Mandatory by default; follow unless user explicitly says otherwise | User direction #2 |
| Sub-agent count for Lite validation? | 1 (down from 2) | User direction #3 |
| Polish upstream scope? | Local-only + `CHANGES.md` user can manually copy to master | User direction #4 |
| Ticket.md format? | Freeform, no schema, no assumptions | User direction #5 |
| Story cleanup? | Not handled — user's responsibility | User direction #6 |
| Validation loop in Polish? | No loop; user is the gate | User direction #7 |
| Should `polishing_log.md` be auto-created? | Dissolved — no `polishing_log.md`; Polish uses commit messages + `CHANGES.md` | Design iteration, user-approved |
| Minimum `ticket.md` content before Spec proceeds? | Any non-empty content — Spec Step 1 handles arbitrary text; agent halts only on empty file | Design iteration, user-approved lean |
| Single sub-agent criterion outside stories (ad-hoc invocation)? | Yes — it's Lite's criterion regardless of context | Design iteration, user-approved lean |
| Numeric token estimates in Token Discipline section? | Qualitative only — numbers go stale with model/pricing changes | Design iteration, user-approved lean |
| Precise rule for "obvious" Verification (P11-C)? | Required when success depends on tooling (compile, test, lint, runtime); optional for pure text/content edits. Documented via examples list, not strict rule | Design iteration, user-approved lean |
| Active-story convention — how does agent know which story is active? | User names the slug explicitly each invocation; no marker file, no most-recent heuristic | Design iteration, user-approved lean |
| Polish → Spec loopback path? | Polish Step 2 may recommend re-entering Spec; user gates the loopback | Design iteration, user-approved lean |

**No remaining open items.** All design decisions are resolved. Validation loop may still surface new questions during review — those will be logged in the validation log and folded back into the design as needed.

---

## Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Workflow feels heavy for 1-line bug fixes | Medium | Medium | Minimum-viable-artifact sizing baked into P3; 3-5 line spec is explicitly OK |
| Polish phase proposals degrade CODE_STANDARDS.md with AI-generated noise over time | Medium | High | User approval gate in Polish Step 4 is explicit and required; no auto-apply |
| Users don't know when to use formal vs story mode for code review | Low | Low | Mode selection is context-driven (inside a story = story mode); documented clearly in Pattern 4 |
| Single sub-agent confirmation misses issues that 2 would have caught | Medium | Low | Acceptable tradeoff per user direction #3; validation loop still catches most issues in primary rounds |
| `stories/` folder grows unbounded | High | Low | Documented as accepted per user direction #6; user cleans up at their discretion |
| CHANGES.md entries are lossy when users forget to copy to master | High | Low | Doc explicitly calls out that propagation is manual; master doesn't depend on any particular sync cadence |
| Existing Lite users hit breaking changes (e.g. discovery_lite.template.md deleted) | High | Medium | Mitigation is inherent: Lite files are re-deployed via `init_lite` and users who run the script get the new layout; we document the breaking change in CLAUDE.md Shamt Lite section |
| Cuts (P9) remove content users relied on | Low | Medium | Cuts are "move to reference" not "delete"; all content remains accessible one file deeper |
| Master `CLAUDE.md` section grows unwieldy documenting Lite structure | Low | Low | Keep master's Lite section as a summary + pointer to `story_workflow_lite.md` for the canonical description |
| Token Discipline model recommendations go stale as model lineup changes | Medium | Low | Use generic tiers (Haiku/Sonnet/Opus) without version numbers; references point to `model_selection.md` for current names |

---

## Change History

| Date | Change |
|---|---|
| 2026-04-20 | Initial draft created (pre-validation) |
| 2026-04-20 | Removed `polishing_log.md` entirely; Polish now uses commit messages + `CHANGES.md` (redundancy was pure token cost). Added Proposal 11 (Existing-Practice Token Cuts): single-line validation footer, drop impl-plan checklists, optional Verification field, drop ELI5 from formal overview.md, drop empty-category justifications, allow 1-option spec dialogs when obvious, trim "Key Rules", de-duplicate main/reference. Added Goal 8. Clarified Non-Goals: all changes are Lite-only; full Shamt is untouched. Updated Files Affected (5→4 CREATE). Dissolved Q-OPEN-1; added Q-OPEN-5/6/7. |
| 2026-04-20 | Resolved all remaining open questions (Q-OPEN-2 through Q-OPEN-7): ticket.md minimum is non-empty; single sub-agent applies everywhere in Lite regardless of context; token discipline is qualitative only; Verification rule documented via tooling-dependent examples list; active-story convention is explicit slug naming by user; Polish Step 2 includes Spec loopback path gated by user. No open questions remain. |
| 2026-04-20 | Validation complete (13 primary rounds + 13 sub-agent rounds). Status → Validated. |
