# {{PROJECT_NAME}} — Shamt Lite Rules

**Version:** 2.0
**Updated:** {{DATE}}
**Purpose:** Standalone agent rules — story workflow, validation, spec, code review, and implementation planning

---

## What is Shamt Lite?

Shamt Lite is a lightweight quality framework for AI-assisted development. It provides **5 core patterns** and an opinionated **six-phase story workflow** (Intake → Spec → Plan → Build → Review → Polish) for taking tickets from received to shipped and learned from.

**Use Shamt Lite when:**
- You're working from a ticket (Jira, Linear, Slack, verbal, or any source)
- You want systematic quality patterns without the full Shamt S1-S11 epic framework
- You need validation loops, spec protocols, and structured code review

**Files in this project:**
- `SHAMT_LITE.md` — This file: 5 patterns + token discipline (standalone executable)
- `story_workflow_lite.md` — Full six-phase workflow narrative (read for story work)
- `CHANGES.md` — Upstream-worthy Polish entries accumulate here
- `stories/` — Per-story folders created during story work
- `reference/` — Extended depth for each pattern
- `templates/` — Copy-paste-ready templates

**How to use:** This file is standalone. You can execute all 5 patterns using only the instructions below without reading any supporting files. `story_workflow_lite.md` provides the full narrative for running a story start-to-finish.

---

## Host Wiring (Optional)

`init_lite.sh` (and `init_lite.ps1`) accept an optional `--host=` flag that deploys host-native skills, slash commands, and sub-agent personas — turning the standalone patterns below into one-command invocations.

| Flag | Result |
|---|---|
| (no flag) | **Default.** Writes `shamt-lite/` only. Manual: copy `SHAMT_LITE.md` into your AI service's rules file. |
| `--host=claude` | Adds `<project>/CLAUDE.md` (canonical), and deploys `.claude/{skills,commands,agents}/` for Claude Code. Slash commands available: `/lite-story`, `/lite-spec`, `/lite-plan`, `/lite-review`, `/lite-validate`. |
| `--host=codex` | Adds `<project>/AGENTS.md` (canonical, read by Codex automatically), prompts for `FRONTIER_MODEL` / `DEFAULT_MODEL`, deploys `.agents/skills/`, `.codex/agents/`, and 8 `SHAMT-LITE-PROFILES` blocks in `.codex/config.toml`. Per-phase profiles let you launch sessions as `codex --profile shamt-lite-spec-validate`. |
| `--host=cursor` | Prompts for cheap-tier model (default `inherit`), deploys `.cursor/{skills,commands,rules,agents}/`. 5 attachment-aware `.mdc` rule files load pattern-specific rules only when editing relevant files. No `AGENTS.md` written. |
| `--host=claude,codex` | Both Claude Code + Codex. `AGENTS.md` is canonical; on Unix `CLAUDE.md` is symlinked to it, on Windows it is duplicated. |
| `--host=cursor,codex` | Both Cursor + Codex. Independent deployments; no symlinking. `AGENTS.md` is written for Codex; `.cursor/rules/*.mdc` for Cursor. |
| `--with-mcp` | Reserved (Tier 3, deferred). Currently a no-op. |

Re-running `init_lite.sh` with a different `--host=` flag is **not** idempotent for the rules-file copy (`AGENTS.md` / `CLAUDE.md` are overwritten); the regen scripts (`regen-lite-claude.sh`, `regen-lite-codex.sh`, `regen-lite-cursor.sh`) ARE idempotent and safe to re-run.

**On other hosts** (Copilot, Windsurf, etc.) the standalone Tier 0 mode (no flag) remains the supported path. Claude Code, Codex, and Cursor have full Lite host wiring.

---

## Story Workflow Map

For ticket-based work, follow `story_workflow_lite.md`. Quick reference:

| Phase | Artifact | Gate |
|-------|----------|------|
| 1. Intake | `stories/{slug}/ticket.md` | User confirms slug + content |
| 2. Spec | `stories/{slug}/spec.md` | (2a) Design approved, (2b) Spec approved |
| 3. Plan | `stories/{slug}/implementation_plan.md` | User approves validated plan |
| 4. Build | code changes | Verification checklist in plan |
| 5. Review | `stories/{slug}/code_review/review_v1.md` | Review is the artifact |
| 6. Polish | commit messages + CHANGES.md entries | User signals "complete" |

**Advisory context-clear breakpoints:** After Gate 2b → `/clear` before Plan. After Gate 3 → `/clear` before Build.

---

# Part 1: Core Patterns

## Pattern 1: Validation Loops

**Purpose:** Iterative self-review of work artifacts until quality threshold is met

**Lite exit criterion:** Primary clean round + **1 independent Haiku sub-agent confirmation**. Applies to all Lite validation loops — specs, plans, code reviews, and ad-hoc artifacts.

**When to use:**
- After creating a spec, plan, or code review
- After writing any significant work artifact
- When you need to ensure work meets quality standards

### The 8-Step Validation Process

**Step 1: Read the artifact completely with fresh perspective**

Re-read the entire artifact top-to-bottom every round. Do not rely on memory of prior rounds.

**Step 2: Identify issues across relevant dimensions**

*For Specs (7 dimensions):*
1. Completeness — All sections filled? Requirements gap-free?
2. Correctness — Research accurate? File paths correct?
3. Consistency — Design internally consistent? Aligned with ARCHITECTURE.md?
4. Helpfulness — Does it solve the ticket?
5. Improvements — Simpler approach available?
6. Missing proposals — Any design element left unaddressed?
7. Open questions — Blocking decisions unresolved?

*For Implementation Plans (7 dimensions):*
1. Step Clarity — Every step has a clear action description?
2. Mechanical Executability — All design decisions made, none left to executor?
3. File Coverage — All affected files listed?
4. Operation Specificity — EDIT steps have exact locate/replace strings?
5. Verification Completeness — Steps that need it have verification methods?
6. Dependency Ordering — Steps in correct sequence?
7. Requirements Alignment — Plan covers all spec requirements?

*For Code Reviews (5 dimensions):*
1. Correctness — Issues accurately described?
2. Completeness — All changed files reviewed?
3. Helpfulness — Suggested fixes actionable?
4. Severity Accuracy — Classifications correct?
5. Evidence — File paths and line numbers match the diff?

*For General Artifacts (4 dimensions):*
1. Completeness — All sections filled?
2. Clarity — Easy to understand?
3. Accuracy — Facts and references correct?
4. Actionability — Can someone act on this?

**Step 3: Classify each issue by severity** (see Pattern 2)

Quick questions:
1. "If not fixed, can workflow complete?" → NO = CRITICAL
2. "Will this cause confusion?" → YES = HIGH
3. "Does this reduce quality noticeably?" → YES = MEDIUM
4. Otherwise = LOW

**Step 4: Fix ALL issues immediately**

Fix each issue now. Do not defer or batch.

**Step 5: Update consecutive_clean counter**

- **Clean round** = ZERO issues OR exactly ONE LOW issue (which you fixed)
- **Not clean** = 2+ LOW issues OR any MEDIUM/HIGH/CRITICAL issue
- If clean: `consecutive_clean = consecutive_clean + 1`
- If not clean: `consecutive_clean = 0`

**Step 6: Check exit condition**

- If `consecutive_clean = 0`: return to Step 1
- If `consecutive_clean = 1`: spawn 1 Haiku sub-agent (Step 7)
- If sub-agent confirms zero issues: Validation complete ✅
- If sub-agent finds issues: fix all, reset `consecutive_clean = 0`, return to Step 1

**Step 7: Spawn sub-agent for independent confirmation**

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">{cheap-tier}</parameter>
  <parameter name="description">Sub-agent confirmation</parameter>
  <parameter name="prompt">You are confirming zero issues after primary validation.

**Artifact:** {artifact_path_or_description}
**Dimensions:** {list the dimensions from Step 2 for this artifact type}
**Task:** Re-read the entire artifact. Report ANY issue found (even LOW severity).
If zero issues found, state "CONFIRMED: Zero issues found."

{Relevant context about the artifact}
  </parameter>
</invoke>
```

> **`{cheap-tier}` resolves per host:** `haiku-4-5` on Claude Code; your configured `${DEFAULT_MODEL}` on Codex; `inherit` (or a configured cheap-model alias) on Cursor. If `init_lite.sh --host=...` was used at init time, the per-host wiring substitutes the correct value for you; otherwise replace the placeholder manually.

**Step 8: Add validation footer**

When validation is complete, append a single-line footer to the artifact:

```
---
✅ Validated {date} — N rounds, 1 sub-agent confirmed
```

---

## Pattern 2: Severity Classification

**Purpose:** Consistent issue categorization for validation and code review

### The 4 Levels

**CRITICAL** — Blocks workflow, causes failures, or creates serious risks
- Workflow cannot complete if not fixed
- Security vulnerability or data-loss risk
- Broken reference or file path blocking execution
- Missing required section in template

**HIGH** — Causes confusion, significantly reduces quality, or risks problems
- Agent or user will likely be confused or misled
- Important information missing or incorrect
- Inconsistency creating ambiguity
- Misleading or unclear instructions

**MEDIUM** — Reduces quality or usability in noticeable ways
- Makes artifact harder to use
- Suboptimal structure or organization
- Minor factual errors that don't mislead
- Missing helpful context

**LOW** — Minor cosmetic issues, trivial improvements
- Typos, grammar, formatting
- Trivial wording improvements
- Style inconsistencies

### Quick Classification Decision Tree

```
Start: Is there an issue?
│
├─ NO → Continue reading
│
└─ YES →
    ├─ Q1: "If not fixed, can workflow complete?" → NO = CRITICAL
    │
    ├─ Q2: "Will this cause agent or user confusion?" → YES = HIGH
    │
    ├─ Q3: "Does this reduce quality or usability noticeably?" → YES = MEDIUM
    │
    └─ Otherwise = LOW
```

**Borderline cases:** Classify higher, not lower — it's better to fix a MEDIUM that might be LOW than to miss a HIGH classified as MEDIUM.

### The "One LOW Issue" Rule

A round with exactly one LOW-severity issue (which you fix) still counts as clean. Two or more LOW issues = not clean.

**Sub-agent exception:** Sub-agents do NOT get the 1 LOW allowance. ANY issue found by a sub-agent (even LOW) resets `consecutive_clean = 0`.

---

## Pattern 3: Spec Protocol

**Purpose:** Targeted research + design dialog + validated spec for ticketed work

**When to use:**
- Starting a story's Spec phase
- Any time you need to define and validate an approach before planning

### The 7-Step Spec Protocol

**Step 1 — Ingest the ticket**

Read `stories/{slug}/ticket.md` (or the provided ticket content). Extract:
- What's being asked
- Acceptance criteria (explicit or implied)
- Links, due dates, constraints

Output a **3-5 bullet in-agent summary**. Do NOT write to disk yet.

If ticket content is empty or missing: halt and ask the user to provide it. Do not fabricate from conversation context.

**Step 2 — Targeted research**

Scope research to what the ticket references — not a broad exploration:
- Grep for referenced file paths, function names, feature names
- Read `ARCHITECTURE.md` and `CODING_STANDARDS.md` if present
- Skim related code

Document findings under "Research Findings" in spec.md (3-10 bullets).

**Step 3 — Draft spec skeleton**

Create `stories/{slug}/spec.md` (or use `templates/spec.template.md`) with these sections:
- Ticket Summary (from Step 1)
- Research Findings (from Step 2)
- Problem Statement
- Proposed Design / Architecture — placeholder: "TBD, awaiting user alignment"
- Requirements (functional + non-functional)
- Files Affected (best-effort)
- Out of Scope
- Open Questions

**Step 4 — Architecture/design dialog (Gate 2a)**

Propose **1-3 design options** inline in chat (not in spec.md yet):

- **1 option:** Acceptable when the choice is obvious from research.
- **2-3 options:** Required when a non-trivial user-facing design fork exists.

For each option: brief description, pros, cons, effort (S/M/L). Recommend one.

When options have open sub-questions, work through the 6-category question brainstorm framework (see `reference/question_brainstorm_categories_lite.md`). Show categories with questions; omit empty ones.

**Wait for explicit user confirmation before proceeding.**

**Step 5 — Flesh out spec**

Fill in "Proposed Design / Architecture" with the agreed approach. Refine Requirements, Files Affected, Out of Scope.

**Step 6 — Validation loop**

Run Pattern 1 on spec.md using the 7 spec dimensions. Exit: primary clean round + 1 Haiku sub-agent.

**Targeted gap-finding each round:** Ask "What code should I have read that I haven't?" and read it. New discoveries may trigger new issues.

**Step 7 — User approval (Gate 2b)**

Present validated spec. User approves or requests changes.

---

## Pattern 4: Code Review Process

**Purpose:** Structured review of branches/PRs with validated, copy-paste-ready feedback

**Two modes — determined by context:**

**Story mode:** Reviewing code you/the agent just built for an active story. Output: `stories/{slug}/code_review/review_v1.md` only (no overview.md — the story folder provides context). See `story_workflow_lite.md` Phase 5.

**Formal mode:** Reviewing someone else's branch or PR. Output: `.shamt/code_reviews/<branch>/overview.md` + `review_v1.md`.

### Formal Mode — 7 Steps

**Step 1: Fetch branch metadata (read-only)**

**NEVER check out the branch.** Use read-only commands only:

```bash
git fetch origin <branch-name>
git merge-base origin/main origin/<branch-name>
git log origin/main..origin/<branch-name> --oneline
git diff --stat origin/main...origin/<branch-name>
git diff origin/main...origin/<branch-name>
```

If branch cannot be fetched, halt immediately and report to user.

**Step 2: Create review directory**

`.shamt/code_reviews/<sanitized-branch>/` (e.g., `feat/add-export` → `feat-add-export`)

**Step 3: Write overview.md (formal mode only)**

Three sections:

**What Does This Branch Do?** — Purpose, outcomes, what the system does differently after merge.

**Why Was It Built?** — Intent from commit messages and PR description. If unclear: "inferred from commit messages / code structure."

**How Does It Work?** — Technical walkthrough: files changed, key logic, component interactions. Organize by area when multiple subsystems touched.

**Step 4: Validate overview.md**

Run Pattern 1 (4 general dimensions). Exit: primary clean + 1 Haiku sub-agent.

Add validation footer:
```
---
✅ Validated {date} — N rounds, 1 sub-agent confirmed
```

**Step 5: Write review.md (both modes)**

Findings grouped by severity, then by category. Omit severity sections with no findings.

**4 Severity Levels:** BLOCKING / CONCERN / SUGGESTION / NITPICK

**12 Review Categories:**
1. Correctness  2. Security  3. Performance  4. Maintainability  5. Testing
6. Edge Cases  7. Naming  8. Documentation  9. Error Handling  10. Concurrency
11. Dependencies  12. Architecture

**Format each finding:**

```markdown
#### [SEVERITY] — <Category Name>

**File:** `path/to/file.ext`, line N

<Description: what's wrong and what the consequence is.>

**Suggested fix:** <Concrete direction.>
```

**Step 6: Validate review.md**

Run Pattern 1 (5 review dimensions). Exit: primary clean + 1 Haiku sub-agent.

Add validation footer:
```
---
✅ Validated {date} — N rounds, 1 sub-agent confirmed
```

**Step 7: Re-review versioning**

On re-review, create `review_v2.md`, `review_v3.md`, etc. Never overwrite.

---

## Pattern 5: Implementation Planning

**Purpose:** Create mechanical, step-by-step plans that separate planning from execution

**When to use:**
- After spec is approved, before Build
- Any non-trivial feature or change involving multiple file operations
- When implementation will be delegated to a builder agent

**Key benefit:** Catch design issues early; optionally delegate execution to Haiku (material token savings on mechanical steps).

### The 5-Step Process

**Step 1: Read spec completely**

Read `stories/{slug}/spec.md` (or feature brief). Confirm all design decisions are resolved before creating the plan.

**Step 2: Create mechanical implementation plan**

Write a step-by-step plan. Each step must be **mechanical** — no design decisions left for the executor.

**Plan format:**

```markdown
# Implementation Plan

**Created:** [Date]
**Feature/Task:** [Brief description]
**Related:** stories/{slug}/spec.md

---

## Implementation Steps

### Step N: [Clear action description]
**Operation:** CREATE | EDIT | DELETE | MOVE
**File:** `path/to/file.ext`
**Details:**
- [Operation-specific details]

**Verification:** [How to verify — required when success depends on tooling]

---

## Notes

[Optional: gotchas, constraints, reminders]
```

**Operation formats:**

- **CREATE:** Specify file purpose and initial content (or reference template)
- **EDIT:** Exact locate string (5-10 lines context) + exact replacement string
- **DELETE:** File/section to delete + justification
- **MOVE:** Source → destination + reason

**Verification guidance:**

*Required when success depends on tooling:*
- Step compiles code, runs tests, or invokes linter
- Step adds a new API endpoint or config value loaded at runtime
- Step modifies a database schema or migration

*Optional (omit if self-evident):*
- Pure text replacements (typo fixes, wording changes)
- Markdown / docs / comment edits with no code impact
- Reordering imports for style

**Step 3: Validate plan**

Run Pattern 1 (7 plan dimensions). Exit: primary clean round + 1 Haiku sub-agent.

Add validation footer:
```
---
✅ Validated {date} — N rounds, 1 sub-agent confirmed
```

**Step 4: Execute (or hand off to builder)**

**Option A — Execute yourself:** Work through steps sequentially. Run verification after each step that requires it.

**Option B — cheap-tier builder handoff (recommended for >10 mechanical steps):**

```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">{cheap-tier}</parameter>
  <parameter name="description">Execute implementation plan</parameter>
  <parameter name="prompt">You are a builder executing a validated implementation plan.

**Plan:** stories/{slug}/implementation_plan.md

**Critical rules:**
1. Follow steps exactly as written — make ZERO design decisions
2. Execute sequentially (Step 1, then 2, then 3...)
3. Run verification after each step that specifies one
4. If verification fails: STOP and report to architect
5. If any step is unclear: STOP and report to architect

**Report:**
- Success: "All steps completed."
- Error: "Step N failed: [describe what failed]"
- Unclear: "Step N is ambiguous: [describe ambiguity]"
  </parameter>
</invoke>
```

> **`{cheap-tier}` resolves per host:** `haiku-4-5` on Claude Code; your configured `${DEFAULT_MODEL}` on Codex; `inherit` (or a configured cheap-model alias) on Cursor. See the Pattern 1 Step 7 footnote for details.

**When to use builder handoff:** Plan has >10 steps + execution is truly mechanical (no design decisions needed during execution).

**Step 5: Verify completeness**

Test the feature against spec requirements. Verify no unintended side effects. Confirm verifications passed.

If builder reports errors: diagnose the issue, fix the plan, re-run or take over.

---

# Part 2: Token Discipline

## Token Discipline Doctrine

Shamt Lite is the lightweight variant — token cost is a first-class concern.

### Per-Phase Model Recommendations

| Phase / Activity | Model | Rationale |
|---|---|---|
| Intake | Haiku | Mechanical |
| Spec research (Step 2) | Sonnet | Code reading, structural |
| Spec design dialog (Step 4) | Opus or Sonnet | Design judgment |
| Spec validation (Step 6) | Opus | Multi-dimensional reasoning |
| Plan creation | Sonnet | Structured, pattern-following |
| Plan validation | Sonnet | 7-dimension check |
| **Build — mechanical plan** | **Haiku (mandatory if mechanical)** | Execution at Haiku rates |
| Review — issue finding | Opus | Classification + judgment |
| Review — git metadata | Haiku | Mechanical |
| Polish — apply fix | Sonnet | Code editing |
| Polish — root cause | Opus | Causal reasoning |
| Polish — propose upstream | Opus | Cross-doc reasoning |
| **Sub-agent confirmations** | **Haiku (always)** | Mechanical re-check |

### Context-Clear Breakpoints (Advisory)

- After Gate 2b (spec approved) → `/clear` before Plan
- After Gate 3 (plan approved) → `/clear` before Build
- After Build, before Review → optional
- After Review, before Polish → optional (depends on review size)

### Cost Notes

> 💡 **Builder savings:** If your plan has >10 mechanical steps and you're on Opus or Sonnet, spawning a Haiku builder for execution is materially cheaper. The architect stays in the loop for errors; Haiku handles the file operations.

> 💡 **Sub-agent model:** Always use Haiku for sub-agent confirmations. They're performing a mechanical re-check, not a reasoning task.

> 💡 **Context size:** The `consecutive_clean` counter terminates as soon as quality is reached. Long validation loops usually mean the artifact needs more fundamental work, not more rounds.

### Pattern Token Cost Profiles

- **Validation Loop:** Cost scales with rounds × artifact size. Exit as soon as quality is reached.
- **Spec Protocol:** Heaviest pattern — research, design dialog, multi-dimensional validation. Worth the cost: Opus catches design errors before plan execution.
- **Code Review:** Moderate. Haiku for git metadata, Opus for classification.
- **Implementation Planning:** Light — Sonnet for planning and validation, Haiku for building.
- **Builder Handoff:** Material savings vs. self-execution for plans with many mechanical steps.

---

# Part 3: Reference Files

Extended depth for each pattern. Read Part 1 first — reference files add depth, not replacement content.

## reference/validation_exit_criteria_lite.md

Extends Pattern 1. Counter logic examples, sub-agent exception rules, common mistakes, validation dimensions quick reference.

## reference/severity_classification_lite.md

Extends Pattern 2. Detailed examples per level, borderline case protocol, edge cases, "err higher" rule in depth.

## reference/question_brainstorm_categories_lite.md

Extends Pattern 3 (Spec Protocol). The 6-category framework (Functional Requirements, User Workflow/Edge Cases, Implementation Approach, Constraints, Scope Boundaries, Success Criteria) used during Spec Step 4 when proposing design options. Show categories with questions; omit empty ones.

---

# Part 4: Templates

## templates/ticket.template.md

Freeform ticket capture. Paste any format — Jira HTML, Slack thread, email, voice memo transcript. No structure required.

## templates/spec.template.md

Spec document. Sections: Ticket Summary, Research Findings, Problem Statement, Proposed Design/Architecture, Requirements, Files Affected, Out of Scope, Open Questions, validation footer.

## templates/implementation_plan.template.md

Implementation plan. Mechanical step format with CREATE/EDIT/DELETE/MOVE operations, optional Verification, Notes.

## templates/code_review.template.md

Code review. Formal-mode overview.md (What/Why/How) + review.md (severity grouping, 12 categories, validation footer). See Pattern 4 for story-mode variant.

## templates/architecture.template.md

Architecture documentation. Tech stack, project structure, core modules, data flow, key design decisions, integration points.

## templates/coding_standards.template.md

Coding standards. Code style, file organization, documentation conventions, error handling, testing, security, performance patterns.

---

## Quick Reference

### When to use which pattern

| Situation | Use |
|-----------|-----|
| Starting a story | story_workflow_lite.md |
| Need to spec a ticket | Pattern 3: Spec Protocol |
| Just wrote a spec, plan, or review | Pattern 1: Validation Loops |
| Unsure if issue is HIGH vs MEDIUM | Pattern 2: Severity Classification |
| About to implement after spec | Pattern 5: Implementation Planning |
| Review a branch or PR | Pattern 4: Code Review (formal mode) |
| In story Review phase | Pattern 4: Code Review (story mode) |

### Validation loop quick steps

```
1. Read artifact completely (fresh every round)
2. Find issues across dimensions
3. Classify: CRITICAL / HIGH / MEDIUM / LOW
4. Fix ALL immediately
5. Update counter:
   0 issues OR 1 LOW fixed → consecutive_clean + 1
   Otherwise             → consecutive_clean = 0
6. If consecutive_clean = 1 → spawn 1 Haiku sub-agent
7. Sub-agent finds 0 issues → DONE ✅
8. Add single-line footer: ✅ Validated {date} — N rounds, 1 sub-agent confirmed
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

---

## Migration to Full Shamt

Shamt Lite is the lightweight tier. Full Shamt adds: the S1–S11 epic workflow, the MCP server (`shamt.validation_round()`, `shamt.next_number()`, etc.), hook enforcement (commit-format, no-verify-blocker, pre-push-tripwire, etc.), per-stage Codex profiles, observability dashboards, and child-import sync. If you outgrow the 5 patterns and need any of those, migrate.

**When to migrate**

- You need atomic SHAMT-N reservation across machines (`shamt.next_number()`)
- You want hook-enforced git conventions (commit format, `--no-verify` blocker, push tripwire)
- You're running multi-feature epics that need cross-feature coordination (S1–S11)
- You want OTel observability or Grafana dashboards
- You want to sync guide improvements upstream via `import.sh` / `export.sh`

**How to migrate**

1. Run full-Shamt `init.sh` in the **same project root** that has your `shamt-lite/` tree. The two trees coexist:
   - `shamt-lite/` keeps your `stories/`, `CHANGES.md`, and pattern artifacts.
   - `.shamt/` adds full-Shamt content: epics, design docs, host wiring, MCP venv, hooks, etc.
2. Pick `--host=` flags that match what you used in Lite (so the Lite + full regen scripts deploy to the same `.claude/` / `.codex/` paths and skill prefixes don't collide — Lite uses `shamt-lite-*`; full uses `shamt-*`).
3. Validate that everything still works: invoke a Lite slash command (`/lite-validate`) and a full Shamt one (e.g. `/shamt-validate`).
4. (Optional) Once you're comfortable on full Shamt and no longer reaching for the standalone patterns, you can remove `shamt-lite/`. Story artifacts in `shamt-lite/stories/` can be moved into `.shamt/epics/{epic}/features/{feature}/stories/` if you want them under the full-Shamt tree.

**What's preserved**

- Every story artifact in `shamt-lite/stories/`
- Validation history (footers stay attached to artifacts)
- `CHANGES.md` entries
- Architecture and coding standards docs (the templates are compatible)

**What's added by full Shamt**

- `.shamt/epics/EPIC_TRACKER.md` and per-epic folders
- `design_docs/` lifecycle (active / archive)
- MCP server + 7 tools
- Hook bundle (12 enforcement hooks)
- Per-stage Codex profiles (separate from Lite's per-phase profiles)
- Multi-host master review pipeline
- Import / export sync with the master repo

**Reverse direction (full Shamt → Lite)**: not a supported path. Full-Shamt projects use the canonical `.shamt/` content layer; downgrading would require dropping epic tracking and the MCP / hook surface. Stay on full Shamt.

---

*Shamt Lite v2.0 — Standalone rules for story workflow, validation, spec, code review, and implementation planning*
