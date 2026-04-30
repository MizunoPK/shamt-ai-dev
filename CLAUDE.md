# Shamt Master — Agent Rules

This is the **master Shamt repository**. You are working on the framework itself, not a child project.

Your primary responsibilities here are:
1. **Reviewing child PRs** — reviewing guide/script improvements submitted by child projects via pull request
2. **Master dev workflow** — making guide improvements using the standardized process
3. **AI service registry** — keeping `ai_services.md` up to date with new AI services

---

## Project Structure

```text
shamt-ai-dev/
├── README.md
├── CLAUDE.md                           (this file)
├── design_docs/                        # Design doc lifecycle management
│   ├── active/                         # Design docs being worked on
│   │   └── SHAMT{N}_DESIGN.md
│   ├── incoming/                       # Child project proposals awaiting review
│   ├── archive/                        # Implemented design docs
│   │   └── rejected/                   # Rejected child proposals
│   └── NEXT_NUMBER.txt                 # Next SHAMT-N number
└── .shamt/
    ├── guides/                         (the canonical guide system)
    │   ├── stages/                     # s1–s11 workflow guides
    │   ├── reference/
    │   ├── audit/
    │   ├── code_review/                # code review workflow guides
    │   ├── debugging/                  # debugging and troubleshooting guides
    │   ├── design_doc_validation/      # design doc validation guides
    │   ├── master_dev_workflow/        # guide for improving master guides
    │   ├── missed_requirement/         # missed requirement recovery guides
    │   ├── parallel_work/              # parallel work coordination guides
    │   ├── prompts/                    # prompt templates and reference cards
    │   ├── sync/                       # README, separation rule, export workflow, import workflow
    │   └── templates/                  # templates (design_doc_template.md)
    ├── skills/                         (canonical skill bodies — host-portable, content-only; SHAMT-39)
    │   ├── README.md
    │   └── {skill-name}/SKILL.md       # one subdirectory per skill
    ├── agents/                         (sub-agent persona YAML definitions; SHAMT-39)
    │   ├── README.md
    │   └── {persona}.yaml
    ├── commands/                       (slash command bodies + CHEATSHEET.md; SHAMT-39)
    │   ├── README.md
    │   ├── CHEATSHEET.md               # user-facing quick reference
    │   └── {command}.md
    ├── scripts/
    │   ├── initialization/
    │   │   ├── init.sh / init.ps1                           # Full Shamt initialization
    │   │   ├── init_lite.sh / init_lite.ps1                 # Shamt Lite initialization
    │   │   ├── RULES_FILE.template.md                       # AI rules file template (full)
    │   │   ├── SHAMT_LITE.template.md                       # Standalone lite rules file
    │   │   ├── ARCHITECTURE.template.md                     # Full template
    │   │   ├── CODING_STANDARDS.template.md                 # Full template
    │   │   ├── EPIC_TRACKER.template.md
    │   │   ├── ai_services.md                               # Known AI service registry
    │   │   ├── reference/
    │   │   │   ├── severity_classification_lite.md
    │   │   │   ├── validation_exit_criteria_lite.md
    │   │   │   └── question_brainstorm_categories_lite.md
    │   │   └── templates/
    │   │       ├── discovery_lite.template.md
    │   │       ├── code_review_lite.template.md
    │   │       ├── architecture_lite.template.md
    │   │       └── coding_standards_lite.template.md
    │   ├── export/                     # export script
    │   ├── import/                     # import script
    │   └── storage/                    # store/get .shamt/ across machines
    └── epics/
        ├── EPIC_TRACKER.md             # not actively maintained for master work — see Master Dev Workflow
        ├── requests/
        └── done/
```

---

## Reviewing Child Project PRs

Child projects submit guide and script improvements to master via pull request (not changelog files).

The PR description will reference `.shamt/CHANGES.md` from the child project for context.

Review steps:
1. Read the PR diff — assess whether changes are truly generic (applicable to all Shamt projects)
2. If project-specific content has leaked into shared files: request changes
3. If generic: approve and merge
4. After merging, run the full guide audit on the entire `.shamt/guides/` tree — do not let changes propagate to other child projects on their next import until the audit passes
5. Commit any audit fixes before the merge is considered complete

**Proposal docs:** Child PRs may include proposal files (named `{project}-{epic}-SHAMT-UPDATE-PROPOSAL.md`) that were exported to `design_docs/incoming/`. These are always acceptable — no generic/specific evaluation needed since they are explicitly project-originated proposals for guide changes, not shared guide files themselves. Review for obvious errors but do not apply the separation rule to them. See "Child Proposal Handling" section for the promotion/rejection process.

**Full workflow guides:** `.shamt/guides/sync/export_workflow.md` (child side) and `.shamt/guides/sync/import_workflow.md` (post-import validation)

---

## Canonical Content Layer (SHAMT-39)

Three directories under `.shamt/` hold host-portable canonical content. These are **content-only** — no host-specific wiring. Regen scripts (SHAMT-40 for Claude Code, SHAMT-42 for Codex) deploy the content to host-specific locations at init/regen time.

**`.shamt/skills/`** — Skill bodies encoding Shamt protocols (validation loop, architect-builder, spec protocol, code review, guide audit, discovery, import/export, master reviewer, lite story). Each skill lives in its own subdirectory as `SKILL.md`. Each SKILL.md is self-contained and includes `source_guides:` frontmatter listing every guide file it was distilled from.

**`.shamt/agents/`** — Sub-agent persona YAML definitions (`shamt-validator`, `shamt-builder`, `shamt-architect`, `shamt-guide-auditor`, `shamt-spec-aligner`, `shamt-code-reviewer`, `shamt-discovery-researcher`). Each file declares model_tier (cheap/balanced/reasoning), reasoning_effort, sandbox, tools_allowed, and prompt_template with `{placeholder}` syntax.

**`.shamt/commands/`** — Slash command bodies (`shamt-start-epic`, `shamt-validate`, `shamt-audit`, `shamt-export`, `shamt-import`, `shamt-status`, `shamt-resume`, `shamt-promote`) plus `CHEATSHEET.md`. Regen scripts copy command bodies verbatim to `.claude/commands/` (Claude Code) and `~/.codex/prompts/` (Codex).

**Child projects on prior versions** ignore these directories until they re-init or run regen — the directories are additive and backward-compatible.

**Master-applicable skills:** `shamt-validation-loop`, `shamt-guide-audit`, `shamt-code-review`, `shamt-master-reviewer`  
**Master-applicable personas:** `shamt-validator`, `shamt-builder`, `shamt-architect`, `shamt-guide-auditor`, `shamt-code-reviewer`  
**Child-only personas:** `shamt-spec-aligner`, `shamt-discovery-researcher`

Host wiring is deployed by SHAMT-40 (Claude Code) and SHAMT-42 (Codex).

---

## Claude Code Host Wiring (SHAMT-40)

`init.sh` detects Claude Code (`AI_SERVICE=claude_code`) and runs additional wiring steps:

1. Creates `.claude/skills/`, `.claude/agents/`, `.claude/commands/`
2. Runs `regen-claude-shims.sh` to populate them from canonical `.shamt/` content
3. Writes `.claude/settings.json` from `.shamt/host/claude/settings.starter.json` (with `${PROJECT}` resolved)
4. Writes `.shamt/config/ai_service.conf` (value: `claude_code`) and `.shamt/config/repo_type.conf` (value: `master` or `child`)

**`regen-claude-shims.sh`** — deterministic transform script at `.shamt/scripts/regen/`:
- Skills: copies `SKILL.md` verbatim with a managed header; skips `master-only: true` skills on child projects
- Agents: transforms YAML → Claude Code agent markdown; maps model tiers (cheap→Haiku, balanced→Sonnet, reasoning→Opus)
- Commands: copies markdown verbatim with a managed header; `{placeholder}` notation is documentation-style
- Idempotent: user-authored files (no managed header) are preserved; safe to run on every import
- Run automatically by `import.sh` when `ai_service.conf` is `claude_code`

**`shamt-statusline.sh`** — status bar renderer at `.shamt/scripts/statusline/`:
- Reads `EPIC_TRACKER.md` → finds active epic → reads its `AGENT_STATUS.md`
- Emits: `EPIC-N | S{stage}.P{phase} | round {N} | blocker: {text or "none"}`
- Falls back to `Shamt | no active epic` when no epic is in progress

---

## Codex Host Parity (SHAMT-42)

`init.sh` detects Codex (`AI_SERVICE=codex` or `claude_codex`) and runs additional wiring steps:

1. Creates `.codex/agents/`
2. Prompts for `FRONTIER_MODEL` and `DEFAULT_MODEL`; writes `.shamt/host/codex/.model_resolution.local.toml` (gitignored)
3. Writes `.codex/config.toml` from `.shamt/host/codex/config.starter.toml`
4. Copies `.shamt/host/codex/requirements.toml.template` to project root as `requirements.toml`
5. Runs `regen-codex-shims.sh` to populate skills/agents/commands/profiles/hooks

**`--host` flag:** `init.sh --host=codex` skips the AI service menu. `--host=claude,codex` sets up both hosts (dual-host): `AGENTS.md` is the canonical rules file; `CLAUDE.md` is a symlink on Unix or a duplicate on Windows.

**`regen-codex-shims.sh`** — deterministic transform script at `.shamt/scripts/regen/`:
- Skills: deploys to `~/.codex/prompts/shamt-<name>.md` (interim; see `.shamt/host/codex/README.md` for migration path)
- Agents: transforms YAML → TOML (`.codex/agents/<name>.toml`); maps model tiers (cheap→DEFAULT, balanced/reasoning→FRONTIER)
- Commands: deploys to `~/.codex/prompts/`; translates `{placeholder}` → `$PLACEHOLDER` (Codex prompt syntax)
- Profiles: concatenates `.shamt/host/codex/profiles/*.fragment.toml` into `.codex/config.toml` SHAMT-PROFILES block; substitutes `${FRONTIER_MODEL}` / `${DEFAULT_MODEL}` from `.model_resolution.local.toml`
- Hooks: writes SHAMT-HOOKS block in `.codex/config.toml` (see hook event mapping in `.shamt/hooks/README.md`)
- Run automatically by `import.sh` when `ai_service.conf` is `codex` or `claude_codex`

**Stage transitions as session boundaries:** Codex profiles are loaded at session start; switching profiles mid-session requires relaunching Codex with `--profile shamt-s<N>`. Stage transitions in the Shamt workflow are therefore natural session boundaries on Codex.

**`shamt-add-host.sh <host>`** — adds Codex or Claude Code wiring to an existing project without re-running full init.

**`requirements.toml`** — admin enforcement floor written to the project root: sandbox mode ceiling (`workspace-write`), MCP allowlist, hook source pin, secret-glob deny, approval floor.

**`permission-router.sh`** — Codex-only `hooks.permission_request` handler: auto-approves in-scope edits within the active epic folder; always escalates commits and pushes to the user; passes unknown tools through to Codex default.

**Profile fragments** — `.shamt/host/codex/profiles/*.fragment.toml` — one per Shamt stage (s1–s10) and key personas (validator, builder, architect, s6-builder). Model, reasoning effort, and sandbox mode calibrated per stage. See `.shamt/host/codex/README.md` for the full layout.

---

## Hooks and MCP Server (SHAMT-41)

**Hooks bundle** — 10 enforcement hook scripts in `.shamt/hooks/`. Activated by setting `features.shamt_hooks=true` in `.claude/settings.json`; regen installs registrations into `settings.json`'s `hooks` block.

| Hook | Event | Purpose |
|------|-------|---------|
| `no-verify-blocker.sh` | PreToolUse (Bash) | Block `--no-verify` / `--no-gpg-sign` |
| `commit-format.sh` | PreToolUse (Bash) | Enforce `feat/SHAMT-N:` or `fix/SHAMT-N:` prefix |
| `pre-export-audit-gate.sh` | UserPromptSubmit + PreToolUse | Block export if audit is stale or failed (child-only) |
| `validation-log-stamp.sh` | PostToolUse (Edit) | Append timestamp to validation logs |
| `architect-builder-enforcer.sh` | PreToolUse (Task) | S6: reject non-`shamt-builder` Task spawns |
| `user-testing-gate.sh` | PreToolUse (Bash) | S9: block push without user-testing confirmation (child-only) |
| `precompact-snapshot.sh` | PreCompact | Write `RESUME_SNAPSHOT.md` before compaction |
| `session-start-resume.sh` | SessionStart | Inject `RESUME_SNAPSHOT.md` as context on start |
| `subagent-confirmation-receipt.sh` | SubagentStop | Write veto flag if confirming sub-agent reports issues |
| `stage-transition-snapshot.sh` | UserPromptSubmit | Write `RESUME_SNAPSHOT.md` at stage-advance phrases |

**Master-applicable hooks (8 of 10):** all except `pre-export-audit-gate.sh` (master doesn't export) and `user-testing-gate.sh` (S9 child-only).

**MCP server** — Python package at `.shamt/mcp/`. Install via repo-local venv:
```bash
python -m venv .shamt/mcp/.venv && source .shamt/mcp/.venv/bin/activate
pip install -e .shamt/mcp
```

Two tools:
- `shamt.next_number()` — atomic SHAMT-N reservation (reads/increments `design_docs/NEXT_NUMBER.txt` under OS-level lock)
- `shamt.validation_round(log_path, round, severity_counts, fixed, exit_threshold)` — appends structured round entry and returns updated `consecutive_clean` + `should_exit`. Pass `exit_threshold=1` for validation loops, `exit_threshold=3` for guide audits.

Regen registers the MCP server in `mcpServers.shamt` when the venv is found.

**Session continuity:** `precompact-snapshot.sh` + `session-start-resume.sh` replace the GUIDE_ANCHOR / Resume Instructions ritual for sessions where both hooks fire. The manual ritual remains authoritative when hooks are not installed.

---

## Master Dev Workflow

For improving the guides directly:

**Guide:** `.shamt/guides/master_dev_workflow/`

Master work does **not** follow the S1-S11 epic workflow and does **not** use EPIC_TRACKER.md. The operating model:

- **Small changes:** Lightweight workflow — read, fix, audit, commit directly to a branch, open PR
- **Large changes:** Create a design doc in `design_docs/active/` (version-controlled), validate it, implement, then archive to `design_docs/archive/`
- **SHAMT-N numbers:** Sequence markers for change sets, not epic identifiers. Reserved via `design_docs/NEXT_NUMBER.txt`
- **No stage gates:** Master work proceeds at judgment, not through S1-S11 phase transitions

**Available skills and personas:** Master-applicable skills (`shamt-validation-loop`, `shamt-guide-audit`, `shamt-code-review`, `shamt-master-reviewer`) and personas (`shamt-validator`, `shamt-builder`, `shamt-architect`, `shamt-guide-auditor`, `shamt-code-reviewer`) are available for master dev work. Claude Code host wiring is live (SHAMT-40); Codex wiring is live (SHAMT-42).

See "Design Doc Lifecycle" below for the full design doc process.

---

## Design Doc Lifecycle

**When to create a design doc:**
- Large changes requiring planning (multi-guide, cross-cutting, architectural)
- Changes affecting multiple system behaviors
- When user requests "create a design doc"
- Judgment call — lightweight workflow works for simple fixes

**How to create a design doc:**

1. **Reserve SHAMT-N number:** Read `design_docs/NEXT_NUMBER.txt` (e.g., contains "27"), use that number, increment the file to "28", commit
2. **Create from template:** Use `.shamt/guides/templates/design_doc_template.md` to create `design_docs/active/SHAMT{N}_DESIGN.md`
3. **Write design:** Capture problem statement, goals, proposals, implementation plan, validation strategy
4. **Validate:** Run 7-dimension validation loop (see Design Doc Validation section below)
5. **Implement:** Execute implementation plan on `feat/SHAMT-N` branch. After implementing, run a D-COVERAGE pass: verify that (a) guide changes have corresponding skill body updates where warranted — if a modified source guide now diverges from its SKILL.md, update the skill body in the same commit; and (b) skill body changes have corresponding guide updates — if a skill introduces protocol content not present in any source guide, add the missing content to the appropriate guide. The D-DRIFT and D-COVERAGE audit dimensions will catch gaps that slip through, but catching them during implementation is cheaper.
6. **Validate implementation:** Run implementation validation loop (see Implementation Validation section below)
7. **Archive:** Move `SHAMT{N}_DESIGN.md` and validation log to `design_docs/archive/` when complete

**Lifecycle states:**
- **Draft** (`active/`) — Being written, not yet validated
- **Validated** (`active/`) — Passed 7-dimension validation, ready for implementation
- **In Progress** (`active/`) — Implementation underway on branch
- **Implemented** (`archive/`) — Implementation complete, branch merged

**Validation log:** Create `SHAMT{N}_VALIDATION_LOG.md` alongside design doc when starting validation. Moves to archive with design doc.

---

## Design Doc Validation

When asked to validate a design doc, run a validation loop following `.shamt/guides/design_doc_validation/validation_workflow.md`.

**The 7 dimensions:**

1. **Completeness** — Are all necessary aspects covered? Is the problem fully stated? Are all affected files identified? Are edge cases and failure modes addressed?
2. **Correctness** — Are factual claims accurate? Do proposed changes actually work the way described? Are references to existing guides/files accurate?
3. **Consistency** — Is the design internally consistent? Does it conflict with existing guide conventions or other SHAMT decisions?
4. **Helpfulness** — Do the proposals actually solve the stated problem? Is the benefit worth the complexity added?
5. **Improvements** — Are there simpler or better ways to achieve the same goal?
6. **Missing proposals** — Is anything important left out of scope that should be addressed here?
7. **Open questions** — Are there unresolved decisions that need to be surfaced before implementation?

**Exit criterion:** Primary clean round (all 7 dimensions pass with ≤1 LOW-severity issue) + 2 independent sub-agents both confirming zero issues. Same pattern as workflow validation loops: `consecutive_clean = 1`, then spawn 2 parallel sub-agents.

A round is clean if it has ZERO issues OR exactly ONE LOW-severity issue (fixed). Multiple LOW-severity issues OR any MEDIUM/HIGH/CRITICAL severity issue resets `consecutive_clean` to 0. See `reference/severity_classification_universal.md` for severity definitions.

**Detailed workflow:** See `.shamt/guides/design_doc_validation/` for complete validation process, validation log template, and guidance.

---

## Implementation Validation

After implementing a design doc (Phases 1-4 complete), run an implementation validation loop to verify the design was fully and correctly implemented.

**The 5 dimensions:**

1. **Completeness** — Was every proposal implemented? Walk through all proposals and verify corresponding changes exist.
2. **Correctness** — Does the implementation match what was proposed? Check folder structures, file contents, script changes.
3. **Files Affected Accuracy** — Were all files in the "Files Affected" table actually created/modified/moved as specified?
4. **No Regressions** — Did the implementation break anything that was working before?
5. **Documentation Sync** — Do CLAUDE.md, master_dev_workflow.md, and other guides accurately reflect the new system?

**Exit criterion:** Same as design doc validation — primary clean round (≤1 LOW-severity issue) + 2 independent sub-agent confirmations.

**After implementation validation passes:** Run a full guide audit on the entire `.shamt/guides/` tree (not just files affected by the design doc) to ensure the repo is in a healthy state. The audit must achieve 3 consecutive clean rounds.

---

## Child Proposal Handling

Child projects can export design proposals to master via the export script. Proposals land in `design_docs/incoming/`.

**Review process:**
1. Read the proposal file in `incoming/`
2. Assess whether it warrants a full design doc or can be handled as a direct guide update
3. **If promoting to design doc:** Reserve SHAMT-N, create design doc in `active/` incorporating the proposal, delete or archive the original proposal
4. **If rejecting:** Move to `archive/rejected/` with a rejection note at the top of the file explaining why
5. **If implementing directly:** Make the guide changes, reference the proposal in commit message, archive the proposal

**Naming convention:** Child proposals use `{project}-{epic}-SHAMT-UPDATE-PROPOSAL.md` format for traceability.

---

## Code Review Workflow

The code review framework is used in three contexts:

1. **Formal code reviews** (external PRs, teammate branches)
2. **S7.P3** (Feature PR Review - part of S1-S11 epic workflow)
3. **S9.P4** (Epic PR Review - part of S1-S11 epic workflow)

**Trigger phrases:** "review branch", "do a code review of", "review the changes on", "re-review"

**Guide:** `.shamt/guides/code_review/` (README → code_review_workflow.md)

**Formal reviews:** Produces `.shamt/code_reviews/<sanitized-branch>/` with a validated `overview.md` (ELI5 + What/Why/How) and a versioned `review_vN.md` with copy-paste-ready PR comments.

**S7/S9 reviews:** Fresh sub-agent code review pattern (integrated into S7.P3 and S9.P4 guides). Skips overview.md creation, adds Dimension 13 (Implementation Fidelity), validates implementation matches plans and specs. See `code_review/s7_s9_code_review_variant.md`.

**Key rules:**
- Never checks out the branch — read-only git commands only
- On re-review: creates `review_v2.md`, `review_v3.md`, etc. — never overwrites previous versions
- If branch cannot be fetched: halt and report to user immediately

---

## Updating the AI Service Registry

When a new AI service is discovered (reported by a child project or user):

1. Research the service's rules file convention
2. Add an entry to `.shamt/scripts/initialization/ai_services.md`
3. Update the init scripts if the service needs special handling
4. Commit the change with a descriptive message

---

## Shamt Lite

**What it is:** A standalone lightweight version of Shamt that provides a six-phase story workflow (Intake → Spec → Plan → Build → Review → Polish) plus 5 core quality patterns, without the full S1-S11 epic framework.

**Target users:** Developers who want systematic quality patterns and a ticket-to-shipped workflow but don't need epic tracking or the full Shamt workflow.

**Master repo storage:** All Shamt Lite files are stored in `.shamt/scripts/initialization/`:
- `SHAMT_LITE.template.md` — Lean core: 5 patterns + token discipline (standalone executable)
- `story_workflow_lite.template.md` — Full narrative of the six-phase story workflow
- `CHANGES.template.md` — Template for per-project CHANGES.md (Polish-phase upstream candidates)
- `init_lite.sh` / `init_lite.ps1` — Initialization scripts
- `reference/` — 3 reference files (severity, validation, question brainstorming / spec categories)
- `templates/` — 6 templates (ticket, spec, code review, implementation plan, architecture, coding standards)

**Deployed layout (after `init_lite` runs):**
```
shamt-lite/
├── SHAMT_LITE.md                    # 5 patterns + token discipline
├── story_workflow_lite.md           # Six-phase story workflow narrative
├── CHANGES.md                       # Polish-phase upstream candidates accumulate here
├── stories/                         # Per-story work folders (stories/{slug}/ticket.md, spec.md, etc.)
├── reference/
│   ├── severity_classification_lite.md
│   ├── validation_exit_criteria_lite.md
│   └── question_brainstorm_categories_lite.md
└── templates/
    ├── ticket.template.md
    ├── spec.template.md
    ├── code_review.template.md
    ├── implementation_plan.template.md
    ├── architecture.template.md
    └── coding_standards.template.md
```

**Key principle:** `SHAMT_LITE.md` is standalone and executable. An agent can run all 5 patterns using only that file. `story_workflow_lite.md` adds the full story workflow narrative for ticket-based work.

**Lite vs. full Shamt validation:** Lite validation loops use **1 sub-agent** confirmation (not 2). This applies to all Lite artifacts (specs, plans, reviews). Full Shamt retains 2 sub-agents. Lite `CHANGES.md` entries are proposals; master does not depend on any sync cadence.

**When to update Shamt Lite:**
- When validation loop mechanics change in the canonical guides
- When severity classification rules are refined
- When spec protocol, code review, or implementation planning patterns improve
- Never copy epic-specific content into lite files

**Maintenance rule:** Shamt Lite files are NOT synced via import/export. They are maintained directly in the master repo and versioned independently.

---

## Architecture & Coding Standards Maintenance

Child projects maintain ARCHITECTURE.md and CODING_STANDARDS.md through the S1-S11 workflow:

- **S1.P3 Discovery:** Review existing docs, check for undocumented additions (Step 3b)
- **S7.P3 Final Review:** Complete Documentation Impact Assessment (Step 1b)
- **S10 Final Changes & Merge:** Final Architecture/Standards Review (Step 1e)

**Audit:** D23 (Architecture/Standards Currency) validates document freshness and accuracy during audits. Threshold: 60 days.

**Master role:** When reviewing child PRs that update these templates, verify metadata sections (Last Updated, Update History, Update Triggers, How to Update) are present.

---

## Git Conventions

- **Branch format:** `feat/SHAMT-{N}` or `fix/SHAMT-{N}`
- **Commit format:** `feat/SHAMT-{N}: {message}` or `fix/SHAMT-{N}: {message}`
- **Default branch:** `main`
- **No AI attribution** in commit messages

---

## Critical Rules

- Zero autonomous conflict resolution — always escalate to user when uncertain
- Run guide audit after every set of guide changes
- Never approve child PRs that contain project-specific content in shared guide files
- When any change affects system behavior (new sync scripts, new guides, new audit scope, new workflow steps): review and update the three master-only files that are not propagated via import — `CLAUDE.md`, root `README.md`, and `scripts/initialization/RULES_FILE.template.md`
- Guide audits require 3 CONSECUTIVE clean rounds (where each round has ≤1 LOW-severity issue) to exit (track `consecutive_clean >= 3`). Workflow validation loops (S7.P2, S9.P2, etc.) exit on **primary clean round + independent sub-agent confirmation** (`consecutive_clean = 1`, then spawn 2 parallel sub-agents both confirming zero issues). A round is clean if it has ZERO issues OR exactly ONE LOW-severity issue (fixed). Multiple LOW-severity issues OR any MEDIUM/HIGH/CRITICAL severity issue resets `consecutive_clean` to 0. Track `consecutive_clean` explicitly and state it at the end of every round. See `reference/severity_classification_universal.md` for severity definitions.

---

## Model Selection for Token Optimization (SHAMT-27)

**Purpose:** MANDATORY token optimization through strategic model delegation (30-50% savings)

**CRITICAL:** Model selection is not optional. When workflow guides specify delegation patterns (e.g., "Spawn Haiku → File operations"), you MUST use the Task tool with the specified model parameter.

**Note:** As of SHAMT-29, model selection is mandatory at all execution points. See workflow guides for inline Task tool examples.

**Quick Reference:**
- **Haiku** (cheap, fast): File operations, git operations, grep/glob searches, tests, sub-agent confirmations
- **Sonnet** (balanced): Code reading, structural analysis, medium-complexity tasks
- **Opus** (deep reasoning): Validation, root cause analysis, design decisions, complex multi-dimensional checks

**Key Workflows:**
- **Guide Audit:** 40-50% savings (Haiku for pre-checks/counting, Sonnet for structural, Opus for content)
- **Validation Loops:** 30-45% savings (Haiku for mechanical, Sonnet for code reading, Opus for validation)
- **Code Review:** 30-40% savings (Haiku for git ops, Sonnet for ELI5, Opus for issue classification)
- **Sub-Agent Confirmations:** 70-80% savings (always use Haiku - focused verification, not deep reasoning)

**Complete Guide:** See `.shamt/guides/reference/model_selection.md` for decision framework, task catalog, Task tool examples, and common mistakes.

**When to Use:** Spawn sub-agents with the `model` parameter in the Task tool when delegation will save tokens without degrading quality. Always delegate sub-agent confirmations to Haiku.

**When NOT to Use:** Parallel work coordination (use Sonnet for consistency), tasks requiring existing context (avoid context switching overhead).

---

## Architect-Builder Implementation Pattern (SHAMT-30)

**Purpose:** Two-stage implementation pattern that separates planning (architect) from execution (builder) for 60-70% token savings on implementation execution.

**Pattern Overview:**

**S5 Phase 1-2 - Architect (Sonnet/Opus):**
- Reads codebase and spec
- Creates mechanical, step-by-step implementation plan (Phase 1)
- Validates plan using 9-dimension validation loop (Phase 2)
- User approves validated plan (Gate 5)

**S6 - Handoff and Execution:**
- S6 Architect receives validated plan from S5
- Creates handoff package
- Spawns Haiku builder agent

**S6 Builder (Haiku):**
- Executes plan mechanically, reports completion or errors

**Separation:** Planning (S5) uses expensive model, execution (S6) uses cheap model

**Usage:**

**MANDATORY** for S1-S11 epic workflow:
- S6 implementation execution MUST use architect-builder pattern (no exceptions)
- No traditional implementation option (architect executing own plan)
- Rationale: S1-S11 workflow is exclusively for non-trivial changes

**OPTIONAL** for master dev workflow and ad-hoc work:
- Use when: >10 file operations, >100K tokens with traditional approach, complex dependencies, unfamiliar codebase
- Skip when: 1-5 file changes, exploratory work, rapid iteration, prototypes
- See decision tree in `reference/architect_builder_pattern.md`

**Key Files:**
- `reference/architect_builder_pattern.md` - Complete pattern documentation (when to use, mechanics, error recovery)
- `reference/implementation_plan_format.md` - Mechanical plan specification (CREATE/EDIT/DELETE/MOVE operations, 9 validation dimensions)
- `templates/implementation_plan_template.md` - Mechanical plan template (copy-paste starting point)
- `templates/implementation_plan_validation_log_template.md` - Validation log template

**Workflow:**
1. **S5 Phase 1:** Architect creates mechanical implementation plan (step-by-step file operations with exact details)
2. **S5 Phase 2:** Architect validates plan (9-dimension validation loop: step clarity, mechanical executability, file coverage, operation specificity, verification completeness, error handling, dependency ordering, checklist completeness, spec alignment)
3. **Gate 5:** User approves validated plan
4. **S6:** Architect receives validated plan from S5, creates handoff package (builder instructions, error handling protocol)
5. **S6:** Architect spawns Haiku builder (Task tool with `model="haiku"`)
6. **S6:** Builder executes plan sequentially (no design decisions, reports errors immediately)
7. **S6:** Architect monitors execution (handles success/errors, diagnoses, fixes plan if needed)

**Token Savings:** 60-70% on implementation execution (Haiku builder vs. Sonnet/Opus architect)

**Integration Points:**
- S2: Added Dimension 10 (Design Completeness) to spec validation - ensures specs contain complete architectural/design detail (prerequisite for mechanical planning)
- S5: Creates and validates mechanical implementation plans using 9-dimension validation loop (Step Clarity, Mechanical Executability, File Coverage, Operation Specificity, Verification Completeness, Error Handling, Dependency Ordering, Checklist Completeness, Spec Alignment)
- S6: Receives validated mechanical plan from S5, creates handoff package, spawns Haiku builder for execution
- Master dev: Optional integration at Step 3.5 with decision criteria
