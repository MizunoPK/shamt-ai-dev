# SHAMT-51: Shamt Lite Host Wiring for Codex and Cursor

**Status:** Validated
**Created:** 2026-05-03
**Validated:** 2026-05-03 — 10 rounds + 3 sub-agent attempts (final pair both confirmed zero issues)
**Branch:** `feat/SHAMT-51`
**Validation Log:** [SHAMT51_VALIDATION_LOG.md](./SHAMT51_VALIDATION_LOG.md)
**Type:** Research / Design Proposal

---

## TL;DR

Shamt Lite is rules-file-only today. Cursor 3.x and Codex CLI both now support skills (`SKILL.md`), slash commands, project-local sub-agents, hooks, and MCP — feature parity with Claude Code for the surfaces Lite cares about. Codex Skills (launched Dec 2025) supersedes the SHAMT-42 interim that wrote to `~/.codex/prompts/`.

This doc proposes an opt-in `init_lite.sh --host=codex|cursor` flag that deploys a single canonical content layer (skills, slash commands, sub-agents) to each host, plus per-phase Codex profiles that mechanically realize the Token Discipline table, plus a Cursor `.mdc` rules split for attachment-aware context. Hooks and MCP are deferred (Tier 3 — users wanting them have effectively outgrown Lite). Default no-flag behavior is preserved exactly.

**Document scope:** SHAMT-51 (this doc) is a research-driven **design proposal covering both Codex and Cursor**. Open Question 1 asks whether **implementation** should be split into two PRs (SHAMT-51 = Codex impl, SHAMT-52 = Cursor impl) or kept as a single PR. The design content itself stays unified here either way — both Codex and Cursor proposals are evaluated together because their canonical content layer is shared.

**Important non-obvious property — Lite is opt-out of master sync.** Lite projects do NOT participate in the import/export cycle that full-Shamt projects use. When `SHAMT_LITE.md` or any Lite skill is updated upstream, child Lite projects only pick up the change by re-running `init_lite.sh`. This is intentional (Lite trades freshness for simplicity); see OQ 9 for `AGENTS.md` propagation specifics.

---

## Tier Definitions

The proposal is tiered to control complexity:

| Tier | Surfaces | Status in this doc |
|---|---|---|
| **Tier 0** | Standalone `SHAMT_LITE.md` only (today's `init_lite.sh` no-flag behavior) | Preserved unchanged |
| **Tier 1** | Skills + slash commands + sub-agents (per host) | Proposed |
| **Tier 2** | Codex per-phase profiles + Cursor `.mdc` rules split | Proposed |
| **Tier 3** | Hooks + MCP server + observability | Deferred — out of scope |

Tier 0 is the default — running `init_lite.sh` with no `--host=` flag produces today's output exactly. Tier 1 is the minimum useful host-wired deployment. Tier 2 layers on token-discipline mechanization. Tier 3 is full-Shamt territory and not added to Lite by design.

---

## Problem Statement

Shamt Lite today is a rules-file-only deployment: `init_lite.sh` writes `shamt-lite/SHAMT_LITE.md` plus reference and template files, and the user manually copies `SHAMT_LITE.md` into whatever rules file convention their AI service uses (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.cursor/rules/index.mdc`, etc.). No skills, no slash commands, no sub-agents, no per-phase model profiles, no hooks. Every model selection in the Token Discipline table is advisory prose, not infrastructure.

Full Shamt has solved host wiring for Claude Code (SHAMT-40) and Codex (SHAMT-42), but those designs are sized for the S1–S11 epic workflow. They include hooks bundles, an MCP server, OTel observability, cloud workflows, master-reviewer pipelines, and per-stage profiles — far more than Lite needs.

**Concrete trigger:** A child project using Codex + Cursor (the developer has two preferred hosts) and Shamt Lite cannot invoke the validation loop, spec protocol, or builder handoff via slash command, cannot delegate validator confirmations to a cheap-model sub-agent without writing the Task spawn by hand, and gets no per-phase model selection. The Token Discipline doctrine that promises 40–60% savings is, in practice, only as effective as the user's willingness to manually switch models.

Cursor 3.x in particular has matured significantly since Shamt Lite was written: it now supports `SKILL.md`, custom slash commands at `.cursor/commands/`, project-local sub-agents at `.cursor/agents/`, hooks at `.cursor/hooks.json`, and MCP at `.cursor/mcp.json` — feature parity with Claude Code and Codex for the surfaces Lite cares about. Lite leaves all of this on the floor.

**Who is affected:** any Lite user on Codex or Cursor who would benefit from the same one-command quality patterns that full Shamt + Claude Code users get.

**Impact of not solving:** Lite continues to be the "manual" tier even when the user's host is fully capable of slash-command-driven workflows. Token-discipline savings remain advisory. Validator and builder sub-agent handoff requires hand-writing Task spawns from the inline XML examples in `SHAMT_LITE.md`.

---

## Goals

1. Give Shamt Lite users on Codex and Cursor the same kind of one-command, model-aware experience that Claude Code users get from full Shamt — without dragging Lite into full-Shamt complexity (no MCP server requirement, no hooks bundle, no OTel, no cloud).
2. Establish a single canonical content layer for Lite skills, slash commands, and sub-agents that deploys to all three hosts (Claude Code, Codex, Cursor) with minimal per-host transformation.
3. Make per-phase model selection (the Token Discipline table) actually mechanical on Codex via per-phase profiles, not advisory prose.
4. Author each Lite skill, slash command, and sub-agent persona once and deploy to all three hosts via per-host regen scripts. Note: the host-target paths differ — skills go to `.claude/skills/` / `.agents/skills/` / `.cursor/skills/`; slash commands go to `.claude/commands/` and `.cursor/commands/` (Codex's project-shareable slash surface IS Skills, so Codex receives no separate commands directory); sub-agents go to `.claude/agents/` / `.codex/agents/` / `.cursor/agents/`.
5. Provide a Cursor `.cursor/rules/*.mdc` split that loads pattern-specific guidance only when editing pattern-specific files (smaller default context).
6. Keep the standalone `SHAMT_LITE.md` rules file unchanged in **patterns and protocols** — host wiring is additive sugar, never a replacement. The only `SHAMT_LITE.md` edit proposed here is Goal 8 (host-agnostic XML examples), which corrects a pre-existing portability bug, not a content addition.
7. Preserve the option to "stay manual": running `init_lite.sh` with no host flag must produce today's output exactly. Host wiring is opt-in via `--host=`.
8. Make the standalone `SHAMT_LITE.md` host-agnostic in its examples — replace the Claude-specific `model="haiku"` XML with a model-tier abstraction so non-Claude users without host wiring still get correct guidance.
9. Document the migration path for Lite users who outgrow Lite and want full Shamt.

---

## Background: Current State of Hosts (May 2026)

This research established the following capability map. All three hosts now support a roughly equivalent set of surfaces, with naming and path differences.

### Claude Code (already wired by SHAMT-40 in full Shamt)

| Surface | Path | Notes |
|---|---|---|
| Rules | `CLAUDE.md` (project root) | Always loaded |
| Skills | `.claude/skills/<name>/SKILL.md` | Model-discovered |
| Commands | `.claude/commands/<name>.md` | `/name` invocation |
| Sub-agents | `.claude/agents/<name>.md` | YAML frontmatter, `model` field |
| Hooks | `.claude/settings.json` `hooks` block | PreToolUse, PostToolUse, etc. |
| MCP | `.claude/settings.json` `mcpServers` block | |

### Codex CLI (already wired by SHAMT-42 in full Shamt; see updates below)

| Surface | Path | Notes |
|---|---|---|
| Rules | `AGENTS.md` (project root + nested) | More-specific overrides; multiple AGENTS.md supported |
| Skills | `.agents/skills/<name>/SKILL.md` (repo) or `~/.agents/skills/` (user) or `/etc/codex/skills` (admin) | Same SKILL.md convention as Claude. Implicit + explicit (`/skills`, `$skill-name`). Repo-shareable. **Launched December 2025** — **post-dates SHAMT-42**. |
| Sub-agents | `.codex/agents/<name>.toml` (project) | Wired by SHAMT-42 |
| Custom prompts | `~/.codex/prompts/*.md` | User-only, **not** project-shareable; `/prompts:name` |
| Profiles | `.codex/config.toml` `[profiles.X]` blocks | Wired by SHAMT-42; per-stage |
| Hooks | `.codex/config.toml` SHAMT-HOOKS block | Wired by SHAMT-42 |
| MCP | `~/.codex/config.toml` or `.codex/config.toml` | STDIO or HTTP |

**SHAMT-42 implication:** SHAMT-42 deployed Shamt skills to `~/.codex/prompts/` as an "interim, deprecated-but-functional" surface, noting (in `.shamt/host/codex/README.md`) that "when Codex's new skills surface stabilizes, the regen target will move." That has now happened — Codex Skills launched in December 2025. SHAMT-51 should update both Lite and full-Shamt regen-codex paths to write to `.agents/skills/` instead. (Full-Shamt impact noted under "Cross-cutting follow-ups.")

### Cursor 3.x (no master support today; rules-file-only on the AI service registry)

Capability map below reflects Cursor docs as of May 2026 (Cursor 3.2 released April 2026; subagents/skills introduced in 2.4; hooks introduced in 1.7 / October 2025).

| Surface | Path | Notes |
|---|---|---|
| Rules | `.cursor/rules/<name>.mdc` (project), user-level (Cursor settings, no specific filesystem path documented), team rules (Enterprise dashboard) | 4 types: `alwaysApply: true`, `globs:` (auto-attached), description-driven (agent-requested), manual `@`-mention. Soft cap: keep under 500 lines. Also accepts `AGENTS.md` |
| Skills | `.cursor/skills/<name>/SKILL.md` (project), `~/.cursor/skills/` (user) | Same SKILL.md convention. Frontmatter: `name`, `description`, optional `paths`, `license`, `compatibility`, `metadata`, `disable-model-invocation`. Auto-discovered. Slash invocation supported |
| Commands | `.cursor/commands/<name>.md` | Project-local; slash menu |
| Sub-agents | `.cursor/agents/<name>.md` (project), `~/.cursor/agents/` (user) | Frontmatter: `name`, `description`, `model` (`inherit` or specific id), `readonly`, `is_background`. Tools inherited. Nested launches supported (Cursor 2.5+) |
| Hooks | `.cursor/hooks.json` | beforeShellExecution, beforeMCPExecution, beforeReadFile, afterFileEdit, stop (Cursor 1.7+) |
| MCP | `.cursor/mcp.json` | JSON config |
| Modes | runtime selector | Ask, Manual, Agent, Custom |
| Background agents | `/multitask` (Cursor 3.2+) | Async parallel sub-agents on isolated branches |
| SDK | `@cursor/sdk` | TypeScript, beta — programmatic agents, sandboxed VMs, hooks (out of scope for Lite) |

### Cross-host convergence

The single most important finding from this research: **all three hosts now support `SKILL.md` with near-identical conventions.** A canonical SKILL.md authored once can deploy verbatim to:

- `.claude/skills/<name>/SKILL.md` (already the case in SHAMT-39)
- `.agents/skills/<name>/SKILL.md` (Codex)
- `.cursor/skills/<name>/SKILL.md` (Cursor)

Frontmatter differences are minor (Cursor adds `paths`, `disable-model-invocation`; Codex's optional `agents/openai.yaml` adds invocation policies). The body is shared text.

Sub-agent definitions are less convergent — Claude uses YAML frontmatter in markdown, Codex uses TOML, Cursor uses YAML frontmatter in markdown. A canonical YAML source can be transformed to Codex TOML (the SHAMT-42 regen already does this) and copied with light frontmatter remapping for Cursor.

Slash commands are essentially identical across all three hosts: a directory of markdown files invoked via `/`. Claude (`.claude/commands/`) and Cursor (`.cursor/commands/`) have project-scoped commands directories. Codex has two slash surfaces: `~/.codex/prompts/` (user-scoped, not repo-shareable, the SHAMT-42 interim) and `.agents/skills/` (project-scoped, repo-shareable — Codex's project slash invocation IS Skills, so Lite uses this path).

---

## Detailed Design

### Proposal 1: Canonical Lite content layer

**Description:** Mirror the SHAMT-39 canonical content pattern for Lite. Skills reuse the existing `.shamt/skills/` directory (filtered by `shamt-lite-` name prefix); slash commands, sub-agent personas, Cursor `.mdc` rule sources, and Codex profile fragments live under a new `.shamt/scripts/initialization/lite/` subtree.

**Final structure:**

```
.shamt/skills/                                  (existing — extended with Lite skills)
├── shamt-lite-story/SKILL.md                   (existing — Pattern orchestration / 6-phase workflow)
├── shamt-lite-validate/SKILL.md                (NEW — Pattern 1)
├── shamt-lite-spec/SKILL.md                    (NEW — Pattern 3)
├── shamt-lite-plan/SKILL.md                    (NEW — Pattern 5)
├── shamt-lite-review/SKILL.md                  (NEW — Pattern 4)
└── ...                                          (other full-Shamt skills unchanged)

.shamt/scripts/initialization/lite/             (NEW subtree)
├── commands/
│   ├── lite-story.md
│   ├── lite-validate.md
│   ├── lite-spec.md
│   ├── lite-plan.md
│   └── lite-review.md
├── agents/
│   ├── shamt-lite-validator.yaml
│   └── shamt-lite-builder.yaml
├── rules-cursor/
│   ├── lite-core.mdc
│   ├── lite-spec.mdc
│   ├── lite-plan.mdc
│   ├── lite-review.mdc
│   └── lite-validation.mdc
└── profiles-codex/
    ├── shamt-lite-intake.fragment.toml
    ├── shamt-lite-spec-research.fragment.toml
    ├── shamt-lite-spec-design.fragment.toml
    ├── shamt-lite-spec-validate.fragment.toml
    ├── shamt-lite-plan.fragment.toml
    ├── shamt-lite-build.fragment.toml
    ├── shamt-lite-review.fragment.toml
    └── shamt-lite-validator.fragment.toml
```

**Skill family relationship:** `shamt-lite-story` is the *orchestrator* skill — it runs the full six-phase workflow end-to-end and delegates to the four pattern-specific skills (`shamt-lite-spec`, `shamt-lite-plan`, `shamt-lite-review`, `shamt-lite-validate`) at the appropriate phase boundaries. The pattern-specific skills can also be invoked standalone (e.g., `/lite-validate <file>` for ad-hoc validation outside of a story). All five skills carry `master-only: false` frontmatter and are child-applicable.

**Rationale:** Single source of truth. Skills already canonically live in `.shamt/skills/` (SHAMT-39); reusing that location avoids duplicating the layer. Lite-specific content (commands, sub-agent personas, host-specific transformations) lives in a dedicated `lite/` subtree to keep it organized and discoverable.

**Alternatives considered:**
- *(A) Co-locate all Lite content (including skills) under `.shamt/scripts/initialization/lite/`* — separates Lite cleanly from full Shamt, but duplicates the canonical skills layer. Rejected.
- *(B) Author Lite content directly inside `init_lite.sh` (heredoc strings)* — simplest deployment model but unmaintainable and not per-host transformable. Rejected.

### Proposal 2: Per-host regen scripts for Lite

**Description:** Three new regen scripts modeled on `regen-claude-shims.sh` and `regen-codex-shims.sh`. One per host:

```
.shamt/scripts/regen/
├── regen-claude-shims.sh / .ps1        (existing — unchanged for full Shamt)
├── regen-codex-shims.sh / .ps1         (existing — see "Cross-cutting follow-ups")
├── regen-lite-claude.sh / .ps1         (NEW — see Phase 2)
├── regen-lite-codex.sh / .ps1          (NEW — see Phase 3)
└── regen-lite-cursor.sh / .ps1         (NEW — see Phase 4)
```

**`regen-lite-claude.sh` behavior:**
1. Read all `shamt-lite-*` skills from `.shamt/skills/` and copy to `<TARGET>/.claude/skills/<name>/SKILL.md`.
2. Copy `.shamt/scripts/initialization/lite/commands/*.md` → `<TARGET>/.claude/commands/`.
3. Transform `.shamt/scripts/initialization/lite/agents/*.yaml` → `<TARGET>/.claude/agents/<name>.md` (YAML frontmatter + body, with `model_tier: cheap` mapped to `model: haiku-4-5`).
4. Skip hooks, skip MCP (Tier 3).
5. Idempotent: managed-block markers preserve user-authored sections.

**`regen-lite-codex.sh` behavior:**
1. Read all `shamt-lite-*` skills from `.shamt/skills/` and copy to `<TARGET>/.agents/skills/<name>/SKILL.md` (using Codex's native skills surface, not `~/.codex/prompts/`).
2. Transform `.shamt/scripts/initialization/lite/agents/*.yaml` → `<TARGET>/.codex/agents/<name>.toml`.
3. Insert `.shamt/scripts/initialization/lite/profiles-codex/*.fragment.toml` into `<TARGET>/.codex/config.toml` SHAMT-PROFILES block. Substitute `${FRONTIER_MODEL}` / `${DEFAULT_MODEL}` from `.shamt/host/codex/.model_resolution.local.toml`.
4. Skip hooks (Tier 3 — deferred for Lite).
5. Skip MCP (Tier 3 — deferred for Lite).
6. Idempotent: managed-block markers preserve user-authored sections.

**`regen-lite-cursor.sh` behavior:**
1. Read all `shamt-lite-*` skills from `.shamt/skills/` and copy to `<TARGET>/.cursor/skills/<name>/SKILL.md`.
2. Copy `.shamt/scripts/initialization/lite/commands/*.md` → `<TARGET>/.cursor/commands/`.
3. Copy `.shamt/scripts/initialization/lite/rules-cursor/*.mdc` → `<TARGET>/.cursor/rules/`.
4. Transform `.shamt/scripts/initialization/lite/agents/*.yaml` → `<TARGET>/.cursor/agents/<name>.md` (YAML frontmatter + body).
5. Skip hooks, skip MCP (Tier 3).

**Rationale:** Three separate scripts (one per host, vs. one combined) match the existing per-host pattern and let users add hosts independently. `init_lite.sh --host=claude,codex,cursor` would call all three.

**Alternatives considered:**
- *(A) Single combined `regen-lite.sh`* — symmetric to full Shamt's per-host scripts, so this would break consistency. Rejected.

### Proposal 3: Native Codex Skills replace `~/.codex/prompts/` (Lite scope)

**Description:** Lite uses `.agents/skills/` exclusively for its slash-command surface on Codex. Skills are repo-shareable (commits with the project), supporting both implicit (model-discovered) and explicit (`/skills` or `$shamt-lite-validate`) invocation. Custom prompts at `~/.codex/prompts/` are user-only and were the SHAMT-42 interim. They are skipped for Lite.

**Rationale:** Project-shareability is the core requirement for Lite — when a developer commits Lite host wiring to git, their teammates should get the slash commands automatically on `git pull`. `~/.codex/prompts/` is per-user and would require each teammate to run a setup command separately.

**Alternatives considered:**
- *(A) Continue with `~/.codex/prompts/` interim* — works today, but per-user. Rejected for Lite.
- *(B) Both — write to skills AND prompts* — duplication with no benefit. Rejected.

### Proposal 4: Cursor `.cursor/rules/*.mdc` split

**Description:** Instead of dumping the entire ~600-line `SHAMT_LITE.md` into a single rule file, split into 5 attachment-aware `.mdc` files:

| File | Type | Content | Trigger |
|---|---|---|---|
| `lite-core.mdc` | `alwaysApply: true` | Compact 5-pattern overview + token discipline summary (~150 lines) | Always |
| `lite-spec.mdc` | `globs: stories/**/spec.md, **/ticket*.md` | Pattern 3 (Spec Protocol) full text | Auto-attached when editing spec or ticket files |
| `lite-plan.mdc` | `globs: stories/**/implementation_plan.md` | Pattern 5 (Implementation Planning) full text | Auto-attached when editing plan files |
| `lite-review.mdc` | `globs: stories/**/code_review/**, .shamt/code_reviews/**` | Pattern 4 (Code Review) full text | Auto-attached when editing review files |
| `lite-validation.mdc` | `alwaysApply: true` | Pattern 1 (Validation Loops) + Pattern 2 (Severity) — short reference | Always (validation is invoked in many contexts) |

**Rationale:** Cursor's documented soft cap is 500 lines per rule. Splitting also improves agent context-relevance: when the user is on the spec phase, Cursor loads spec rules; when planning, plan rules. Estimated reduction in default loaded context: ~70% (back-of-envelope, based on `lite-core.mdc` ≈ 150 lines + `lite-validation.mdc` ≈ 80 lines vs. full SHAMT_LITE.md ≈ 600 lines; verify during impl).

**The `SHAMT_LITE.md` standalone document is retained** for users who want the single-file canonical reference and for the master-doc layer. The `.mdc` files are derivatives, not replacements.

**Alternatives considered:**
- *(A) Single `SHAMT_LITE.mdc` with `alwaysApply: true`* — exceeds the 500-line soft cap; loads entire pattern catalog into every chat. Rejected.
- *(B) Use AGENTS.md instead of `.cursor/rules/`* — Cursor accepts AGENTS.md, but doing so loses attachment-aware loading. Rejected for Cursor; a duplicate AGENTS.md is still produced for Codex (see Proposal 7).

### Proposal 5: Codex per-phase profiles for Lite

**Description:** 8 profile fragments in `.shamt/scripts/initialization/lite/profiles-codex/`. Each maps a phase of the Lite story workflow (or a sub-agent persona) to a model tier and reasoning effort, mirroring the Token Discipline table verbatim.

| Profile | Model tier | Reasoning | Sandbox | Maps to |
|---|---|---|---|---|
| `shamt-lite-intake` | `${DEFAULT_MODEL}` | minimal | workspace-write | Story workflow Phase 1 — mechanical capture |
| `shamt-lite-spec-research` | `${DEFAULT_MODEL}` | low | read-only | Story workflow Phase 2 / Pattern 3 Step 2 — code reading |
| `shamt-lite-spec-design` | `${FRONTIER_MODEL}` | medium | workspace-write | Story workflow Phase 2 / Pattern 3 Step 4 — design dialog |
| `shamt-lite-spec-validate` | `${FRONTIER_MODEL}` | high | read-only | Story workflow Phase 2 / Pattern 3 Step 6 — multi-dim validation |
| `shamt-lite-plan` | `${DEFAULT_MODEL}` | low | workspace-write | Story workflow Phase 3 — pattern-following plan creation |
| `shamt-lite-build` | `${DEFAULT_MODEL}` | minimal | workspace-write | Story workflow Phase 4 — mechanical execution (cheap-tier model when delegating to builder) |
| `shamt-lite-review` | `${FRONTIER_MODEL}` | medium | read-only | Story workflow Phase 5 — issue finding + classification |
| `shamt-lite-validator` | `${DEFAULT_MODEL}` | low | read-only | Sub-agent confirmations (any phase) |

*Phase numbers refer to the six-phase story workflow (Intake → Spec → Plan → Build → Review → Polish). "Pattern 3 Step N" refers to the seven-step Spec Protocol within the Spec phase.*

**`${FRONTIER_MODEL}` and `${DEFAULT_MODEL}`** are resolved from `.shamt/host/codex/.model_resolution.local.toml` (existing SHAMT-42 mechanism — gitignored, per-developer).

**Rationale:** Codex profiles are loaded at session start. Stage transitions in the Lite workflow are natural session boundaries, exactly as in full Shamt. The Token Discipline table becomes mechanical: `codex --profile shamt-lite-spec-validate` opens a session pre-tuned for Step 6 of the spec protocol.

**Alternatives considered:**
- *(A) Skip profiles, document per-phase model choice in prose* — equivalent to today's status quo; defeats the point. Rejected.
- *(B) One profile per pattern (5 instead of 8)* — coarser granularity, but spec phase has three distinct model needs (research / design / validate). Rejected; 8 profiles match the table.

### Proposal 6: Sub-agent personas for Lite

**Description:** Two YAML personas at `.shamt/scripts/initialization/lite/agents/`:

```yaml
# shamt-lite-validator.yaml
name: shamt-lite-validator
description: |
  Independent confirmer for the Pattern 1 validation loop sub-agent step.
  Re-reads the artifact and reports any issues found, even LOW severity.
model_tier: cheap
reasoning_effort: low
sandbox: read-only
tools_allowed: [Read, Grep, Glob]
prompt_template: |
  You are confirming zero issues after primary validation.

  Artifact: {artifact_path}
  Dimensions: {dimensions}

  Re-read the entire artifact. Report ANY issue found (even LOW severity).
  If zero issues found, state "CONFIRMED: Zero issues found."
```

```yaml
# shamt-lite-builder.yaml
name: shamt-lite-builder
description: |
  Mechanical executor of validated Pattern 5 implementation plans.
  Makes ZERO design decisions. Stops on ambiguity or verification failure.
model_tier: cheap
reasoning_effort: minimal
sandbox: workspace-write
tools_allowed: [Read, Write, Edit, Bash]
prompt_template: |
  You are a builder executing a validated implementation plan.

  Plan: {plan_path}

  Critical rules:
  1. Follow steps exactly as written — make ZERO design decisions
  2. Execute sequentially
  3. Run verification after each step that specifies one
  4. STOP and report on verification failure or unclear steps

  Report success/error/unclear with specifics.
```

**Rationale:** These two personas encode the two sub-agent spawn patterns from `SHAMT_LITE.md` (the inline XML in Pattern 1 Step 7 and Pattern 5 Step 4 Option B) into actual host artifacts. Once deployed, the user invokes "use the validator" or "spawn the builder" naturally instead of pasting XML.

**Tier mapping:**
- Claude Code: `cheap` → `haiku-4-5`
- Codex: `cheap` → `${DEFAULT_MODEL}` (resolved from `.model_resolution.local.toml`)
- Cursor: `cheap` → defaults to `inherit` unless the user has configured a cheap-tier model alias in Cursor settings (see Open Question 3)

**Alternatives considered:**
- *(A) No sub-agent personas, keep XML in SHAMT_LITE.md* — works but every spawn requires manual XML construction. Rejected.

### Proposal 7: `init_lite.sh --host=` flag and AGENTS.md generation

**Description:** Extend `init_lite.sh` and `init_lite.ps1` with:

```
init_lite.sh [project-name] [--host=claude|codex|cursor|... (comma-separated)] [--with-mcp]
```

**Behavior matrix:**

| Flag | Result |
|---|---|
| (no flag) | Today's behavior exactly: writes `shamt-lite/` files only |
| `--host=claude` | Adds `CLAUDE.md` (copy of `SHAMT_LITE.md`), runs `regen-lite-claude.sh` |
| `--host=codex` | Adds `AGENTS.md` (copy of `SHAMT_LITE.md`), prompts for FRONTIER/DEFAULT models, writes `.shamt/host/codex/.model_resolution.local.toml`, runs `regen-lite-codex.sh` |
| `--host=cursor` | Adds `.cursor/rules/lite-core.mdc` etc., runs `regen-lite-cursor.sh` |
| `--host=codex,cursor` | Both `--host=codex` and `--host=cursor` actions run |
| `--host=claude,codex` | Both run; `AGENTS.md` is canonical, on Unix `CLAUDE.md` is symlinked to `AGENTS.md`, on Windows it's a duplicate file (mirrors SHAMT-42 dual-host) |
| `--host=claude,codex,cursor` | All three; same dual-host rules apply |
| `--with-mcp` | Tier 3 — deferred. Reserved flag. |

**`AGENTS.md` content:** A copy of `SHAMT_LITE.md` (instantiated with `{{PROJECT_NAME}}` / `{{DATE}}`). Codex reads `AGENTS.md` from project root automatically.

**Rationale:** The `--host=` flag mirrors SHAMT-42's pattern (`init.sh --host=claude,codex`) so users moving between Lite and full Shamt see consistent ergonomics. The default no-flag behavior is preserved exactly to avoid breaking existing Lite users.

**Alternatives considered:**
- *(A) Always write all hosts* — bloats the project tree and may conflict with user preferences. Rejected.
- *(B) Add `shamt-add-host-lite.sh`* — symmetric to SHAMT-42's `shamt-add-host.sh`. Recommended as a follow-up but not required for Tier 1.

### Proposal 8 (DEFERRED — Tier 3): Hooks and MCP for Lite

**Description:** Lite users who later want hook enforcement (e.g., commit format) or the validation-round MCP tool can opt in via Tier 3. Out of scope for this design doc. Documented as a future-work pointer in `master_dev_workflow/` and in the migration-to-full-Shamt section of `SHAMT_LITE.md`.

**Rationale:** Hooks and MCP add real setup burden (script auth, venv, regen wiring) that runs counter to the Lite ethos. A Lite user who wants those capabilities has effectively outgrown Lite — the right move is to migrate to full Shamt.

### Proposal 9: Make standalone `SHAMT_LITE.md` host-agnostic

**Description:** The current `SHAMT_LITE.md` Pattern 1 Step 7 and Pattern 5 Step 4 contain inline XML examples that hard-code `<parameter name="model">haiku</parameter>` (Claude-specific). When a user copies `SHAMT_LITE.md` into `AGENTS.md` (Codex) or a Cursor rule file *without* host wiring, that XML is misleading — Codex and Cursor do not have a model called `haiku`.

**Two options:**

- *(A) Tier-abstract everything in standalone:* Replace `model="haiku"` with `model="<cheap-tier>"` and add a one-line note: "On Claude Code use `haiku-4-5`; on Codex use `${DEFAULT_MODEL}` (or your configured cheap-tier model); on Cursor use `inherit` or a configured cheap model alias." Keep the XML structure but parameterize the model field.

- *(B) Host-specific variants:* Maintain three example blocks (Claude, Codex, Cursor) inline. More verbose but explicit.

**Recommendation:** Option A. Adds ~3 lines per example, preserves single-document portability. Users with host wiring never read those XML examples (the personas handle invocation); users without host wiring need the abstraction anyway.

**Concrete edit example (Pattern 1 Step 7):**

Current:
```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">haiku</parameter>
  ...
```

Proposed:
```xml
<invoke name="Task">
  <parameter name="subagent_type">general-purpose</parameter>
  <parameter name="model">{cheap-tier}</parameter>
  ...
```

Followed by a footnote: *"Replace `{cheap-tier}` with: `haiku-4-5` on Claude Code; your configured `${DEFAULT_MODEL}` on Codex; `inherit` (or a configured cheap-model alias) on Cursor."*

**Scope:** This is a content edit to `SHAMT_LITE.template.md`, not new infrastructure. Listed as a Phase 1 deliverable.

**Alternatives considered:**
- *(C) Leave as-is and rely on host wiring to mask the issue* — fails for the no-host-flag standalone deployment, which is the explicit Goal 7. Rejected.

---

## Cross-cutting follow-ups (out of scope but identified)

1. **SHAMT-42 update:** `regen-codex-shims.sh` should migrate from `~/.codex/prompts/` to `.agents/skills/` for full Shamt as well, now that Codex Skills (December 2025) are stable. Track as a separate design doc; cite in Lite docs.
2. **Cursor full-Shamt support:** Master has no Cursor wiring at all today. Lite-on-Cursor is net-new. A separate design doc should propose Cursor wiring for full Shamt, drafted after Lite-on-Cursor lands and lessons are learned.
3. **AI service registry update:** `ai_services.md` Cursor entry should reflect "full-wiring" tier (for Lite at least) once SHAMT-51 implements.

---

## Files Affected

**Legend:**
- `CREATE` / `MODIFY` / `DELETE` apply to **master-stored** files (this repo).
- `DEPLOYED` files are written into the **child project tree** by `init_lite.sh` or regen scripts at run time. They are not stored in the master repo.

| File | Status | Notes |
|---|---|---|
| `.shamt/skills/shamt-lite-validate/SKILL.md` | CREATE | Pattern 1 skill body |
| `.shamt/skills/shamt-lite-spec/SKILL.md` | CREATE | Pattern 3 skill body |
| `.shamt/skills/shamt-lite-plan/SKILL.md` | CREATE | Pattern 5 skill body |
| `.shamt/skills/shamt-lite-review/SKILL.md` | CREATE | Pattern 4 skill body |
| `.shamt/skills/shamt-lite-story/SKILL.md` | UNCHANGED | Already exists |
| `.shamt/scripts/initialization/lite/commands/lite-story.md` | CREATE | Slash command |
| `.shamt/scripts/initialization/lite/commands/lite-validate.md` | CREATE | Slash command |
| `.shamt/scripts/initialization/lite/commands/lite-spec.md` | CREATE | Slash command |
| `.shamt/scripts/initialization/lite/commands/lite-plan.md` | CREATE | Slash command |
| `.shamt/scripts/initialization/lite/commands/lite-review.md` | CREATE | Slash command |
| `.shamt/scripts/initialization/lite/agents/shamt-lite-validator.yaml` | CREATE | Validator persona |
| `.shamt/scripts/initialization/lite/agents/shamt-lite-builder.yaml` | CREATE | Builder persona |
| `.shamt/scripts/initialization/lite/rules-cursor/lite-core.mdc` | CREATE | Always-on Cursor rule |
| `.shamt/scripts/initialization/lite/rules-cursor/lite-spec.mdc` | CREATE | Auto-attached on spec files |
| `.shamt/scripts/initialization/lite/rules-cursor/lite-plan.mdc` | CREATE | Auto-attached on plan files |
| `.shamt/scripts/initialization/lite/rules-cursor/lite-review.mdc` | CREATE | Auto-attached on review files |
| `.shamt/scripts/initialization/lite/rules-cursor/lite-validation.mdc` | CREATE | Always-on Pattern 1+2 reference |
| `.shamt/scripts/initialization/lite/profiles-codex/shamt-lite-*.fragment.toml` (×8) | CREATE | Per-phase profiles |
| `.shamt/scripts/regen/regen-lite-claude.sh` | CREATE | Claude regen for Lite |
| `.shamt/scripts/regen/regen-lite-claude.ps1` | CREATE | Windows variant |
| `.shamt/scripts/regen/regen-lite-codex.sh` | CREATE | Codex regen for Lite |
| `.shamt/scripts/regen/regen-lite-codex.ps1` | CREATE | Windows variant |
| `.shamt/scripts/regen/regen-lite-cursor.sh` | CREATE | Cursor regen for Lite |
| `.shamt/scripts/regen/regen-lite-cursor.ps1` | CREATE | Windows variant |
| `.shamt/scripts/initialization/init_lite.sh` | MODIFY | Add `--host=` flag handling |
| `.shamt/scripts/initialization/init_lite.ps1` | MODIFY | Add `--host=` flag handling |
| `.shamt/scripts/initialization/SHAMT_LITE.template.md` | MODIFY | Proposal 9: tier-abstract the inline XML examples (Pattern 1 Step 7, Pattern 5 Step 4); add "Migration to full Shamt" section pointer; document `--host=` |
| `.shamt/scripts/initialization/ai_services.md` | MODIFY | Update Cursor entry to "full-wiring (Lite)" |
| `CLAUDE.md` (root) | MODIFY | Extend the existing "Shamt Lite" section with the Lite host-wiring deployment matrix |
| (deployed) `<project>/CLAUDE.md` | DEPLOYED | Written by `init_lite.sh --host=claude`; copy of `SHAMT_LITE.md` with template vars resolved |
| (deployed) `<project>/AGENTS.md` | DEPLOYED | Written by `init_lite.sh --host=codex`; copy of `SHAMT_LITE.md` with template vars resolved |
| (deployed) `<project>/.claude/skills/shamt-lite-*/SKILL.md` | DEPLOYED | By `regen-lite-claude.sh` |
| (deployed) `<project>/.claude/commands/lite-*.md` | DEPLOYED | By `regen-lite-claude.sh` |
| (deployed) `<project>/.claude/agents/shamt-lite-*.md` | DEPLOYED | By `regen-lite-claude.sh` |
| (deployed) `<project>/.agents/skills/shamt-lite-*/SKILL.md` | DEPLOYED | By `regen-lite-codex.sh` |
| (deployed) `<project>/.codex/agents/shamt-lite-*.toml` | DEPLOYED | By `regen-lite-codex.sh` |
| (deployed) `<project>/.codex/config.toml` | DEPLOYED | Profile fragments inserted into SHAMT-PROFILES managed block |
| (deployed) `<project>/.cursor/skills/shamt-lite-*/SKILL.md` | DEPLOYED | By `regen-lite-cursor.sh` |
| (deployed) `<project>/.cursor/agents/shamt-lite-*.md` | DEPLOYED | By `regen-lite-cursor.sh` |
| (deployed) `<project>/.cursor/commands/lite-*.md` | DEPLOYED | By `regen-lite-cursor.sh` |
| (deployed) `<project>/.cursor/rules/lite-*.mdc` | DEPLOYED | By `regen-lite-cursor.sh` |

---

## Implementation Plan

This design doc is unified (covers Codex + Cursor in a single SHAMT-51 design). **Implementation** may be split across two PRs if the user wishes (Open Question 1):

- *Single-PR mode (default):* All phases below run under `feat/SHAMT-51`.
- *Split-PR mode:* Phases 1–3, 5, 6 land under `feat/SHAMT-51` (Codex + cross-host content); Phase 4 lands under `feat/SHAMT-52` (Cursor) as a follow-up. Rationale: Cursor wiring is net-new for master and warrants its own validation pass; Codex wiring is conceptually a shrink of SHAMT-42.

The phase ordering is identical in both modes.

### Phase 1: Canonical content authoring (Tier 1 prerequisites)

- [ ] Author `.shamt/skills/shamt-lite-validate/SKILL.md` (Pattern 1)
- [ ] Author `.shamt/skills/shamt-lite-spec/SKILL.md` (Pattern 3)
- [ ] Author `.shamt/skills/shamt-lite-plan/SKILL.md` (Pattern 5)
- [ ] Author `.shamt/skills/shamt-lite-review/SKILL.md` (Pattern 4 — both modes)
- [ ] Author 5 slash command bodies in `.shamt/scripts/initialization/lite/commands/`
- [ ] Author 2 sub-agent YAMLs in `.shamt/scripts/initialization/lite/agents/`
- [ ] Apply Proposal 9: tier-abstract the inline XML examples in `SHAMT_LITE.template.md` (Pattern 1 Step 7, Pattern 5 Step 4)
- [ ] Quick targeted audit of new SKILL.md files: D-DRIFT and D-COVERAGE against `SHAMT_LITE.md`. (This is a fast pre-check, not a substitute for the full-tree audit in Phase 5.)

### Phase 2: Claude Code (`regen-lite-claude.sh` — new)

**Important:** Initial assumption was that Claude needs no new wiring because skills sit under `.shamt/skills/` (already scanned by `regen-claude-shims.sh`). That's only partly true — skills are auto-picked-up, but slash commands (`.shamt/scripts/initialization/lite/commands/`) and sub-agents (`.shamt/scripts/initialization/lite/agents/`) live in a **new** location that the existing `regen-claude-shims.sh` does not scan. Two options:

- *(A) Extend existing `regen-claude-shims.sh`* to also read the Lite subtree. Mixes Lite content into a full-Shamt regen path; cross-impact risk.
- *(B) Add a new `regen-lite-claude.sh`* symmetric to `regen-lite-codex.sh` / `regen-lite-cursor.sh`. Cleaner separation; consistent with the per-host-script pattern already chosen in Proposal 2.

**Recommendation:** (B). This makes Phase 2 a real implementation phase, not a verification step.

**Two project types, two regen flows (no redundancy in either case):**
- *Lite-only projects:* `regen-lite-claude.sh` runs alone. It copies skills, commands, and agents to `.claude/{skills,commands,agents}/`. Full-Shamt's `regen-claude-shims.sh` is not present in these projects.
- *Full-Shamt projects:* `regen-claude-shims.sh` runs alone. It already scans `.shamt/skills/` (which now includes the new `shamt-lite-*` skills as collateral), so Lite skills are picked up incidentally. Lite-specific commands and agents (in `.shamt/scripts/initialization/lite/`) are NOT picked up — full-Shamt projects don't need them.
- *Edge case — both regen scripts run in the same project:* skills overwrite idempotently; no collision.

- [ ] Implement `.shamt/scripts/regen/regen-lite-claude.sh` and `.ps1`. The script writes three things: skills from `.shamt/skills/` (filtered by `shamt-lite-*` prefix) → `<TARGET>/.claude/skills/`; commands from `.shamt/scripts/initialization/lite/commands/*.md` → `<TARGET>/.claude/commands/`; agents transformed from `.shamt/scripts/initialization/lite/agents/*.yaml` → `<TARGET>/.claude/agents/<name>.md` (YAML frontmatter + body, with `model_tier: cheap` mapped to `model: haiku-4-5`). Skills copying is included for self-contained Lite-only deployment, even though full-Shamt projects would get them via the existing regen — this keeps `regen-lite-claude.sh` standalone and the Lite-only case correct.
- [ ] Modify `init_lite.sh` to handle `--host=claude` (write `CLAUDE.md` from `SHAMT_LITE.md`, call `regen-lite-claude.sh`).
- [ ] Modify `init_lite.ps1` similarly.
- [ ] Test: dry-run init on a fresh directory; verify all `.claude/{skills,commands,agents}/` paths populate.

### Phase 3: Codex Tier 1 + 2

- [ ] Author 8 Codex profile fragments
- [ ] Implement `regen-lite-codex.sh` (skills → `.agents/skills/`, agents → `.codex/agents/`, profiles → `.codex/config.toml`). Filter by `shamt-lite-*` name prefix (NEW filtering behavior — distinct from full-Shamt regen which filters by `master-only`).
- [ ] Implement `regen-lite-codex.ps1`
- [ ] Modify `init_lite.sh` to handle `--host=codex` (prompt for models, write `.model_resolution.local.toml`, write `AGENTS.md`, call regen)
- [ ] Modify `init_lite.ps1` similarly
- [ ] Test: dry-run init on a fresh directory; verify all paths and content

### Phase 4: Cursor Tier 1 + 2 (DEFER to SHAMT-52 if implementation split)

- [ ] Author 5 `.mdc` files for `.cursor/rules/`
- [ ] Implement `regen-lite-cursor.sh`
- [ ] Implement `regen-lite-cursor.ps1`
- [ ] Modify `init_lite.sh` for `--host=cursor`
- [ ] Modify `init_lite.ps1` similarly
- [ ] Test on a Cursor 3.x session

### Phase 5: Documentation and registry updates

- [ ] Update `SHAMT_LITE.template.md` with `--host=` documentation and "Migration to full Shamt" section. **Migration section content (skeleton):** "When to migrate (you need MCP `validation_round()`/`next_number()`, hooks like commit-format/no-verify-blocker, or the S1–S11 epic workflow); how to migrate (run full-Shamt `init.sh` in the project root alongside the existing Lite tree — your `stories/` and `CHANGES.md` are unaffected; the resulting `.shamt/` adds full-Shamt content; you can remove `shamt-lite/` after confirming everything works); what's preserved (story artifacts, validation history) vs. what's added (epic tracker, design docs, MCP tools, hooks)."
- [ ] Update `ai_services.md` Cursor entry
- [ ] Update root `CLAUDE.md` Shamt Lite section
- [ ] Run guide audit on the entire `.shamt/guides/` tree (per CLAUDE.md "Critical Rules": 3 consecutive clean rounds — not just files affected by SHAMT-51)

### Phase 6: Implementation validation and PR

- [ ] Run implementation validation loop (5 dimensions)
- [ ] Open implementation PR for SHAMT-51 (and SHAMT-52 if split)
- [ ] After PR merge: archive design doc to `design_docs/archive/`

---

## Validation Strategy

**Primary validation (this design doc):** 7-dimension validation loop. Exit: primary clean round + 2 independent Haiku sub-agent confirmations.

**Implementation validation (after code is complete):** 5-dimension validation loop. Exit: primary clean round + 2 independent Haiku sub-agent confirmations.

**Testing approach:**
- For each new regen script: run on a fresh empty directory; verify all expected files appear with correct content.
- For `init_lite.sh --host=codex` and `--host=cursor`: run end-to-end on a fresh test directory; verify the resulting tree matches the expected layout.
- For Codex profiles: launch a Codex session with `--profile shamt-lite-spec-validate` and verify model and reasoning effort are applied.
- For Cursor rules attachment: open a `stories/test-slug/spec.md` file in Cursor and verify `lite-spec.mdc` is auto-attached but `lite-plan.mdc` is not.
- For sub-agent personas: invoke the validator from a Lite story validation step and verify it spawns with the expected model.
- **Cross-host smoke test:** Run the same simple story (Phase 1 → 6) on all three hosts and verify the same artifacts are produced. This validates the canonical content layer's cross-host portability. *If implementation is split (SHAMT-52 follow-up): SHAMT-51's smoke test covers Claude + Codex; SHAMT-52 adds Cursor.*

**Success criteria:**
- All Tier 1 + Tier 2 deliverables exist on disk and are exercised by at least one end-to-end test.
- A child project can run `init_lite.sh --host=codex,cursor` and immediately invoke `/lite-spec`, `/lite-plan`, `/lite-review`, `/lite-validate` from both hosts.
- The Token Discipline table in `SHAMT_LITE.md` is mechanically realized via Codex profiles (no manual model switching required).
- The standalone `SHAMT_LITE.md` continues to work as a host-agnostic fallback.

---

## Open Questions

1. ~~**Split implementation into two PRs (SHAMT-51 Codex/Claude, SHAMT-52 Cursor) or keep as a single PR?**~~ **Resolved 2026-05-03:** Split into **two design docs**, not just two PRs. SHAMT-51 (this doc) becomes foundation + Codex + Claude bridge. SHAMT-52 will be a separate design doc covering Cursor support (Phase 4 + Cursor-specific portions of Proposals 1, 2, 4, 6, 7). When SHAMT-51 implementation lands, SHAMT-52 is drafted as a new design doc with its own validation loop. *Action item: when implementing, the Cursor-specific content in this doc is reference material for SHAMT-52; SHAMT-51's actual scope shrinks to non-Cursor work.*
2. ~~**Confirm Proposal 1's skills-location choice.**~~ **Resolved 2026-05-03:** Confirmed Option A — Lite skills live in `.shamt/skills/` (filtered by `shamt-lite-` prefix), reusing the SHAMT-39 canonical layer. Lite-only content (commands, agents, rules-cursor, profiles-codex) lives under `.shamt/scripts/initialization/lite/`.
3. ~~**Cursor `cheap`-tier model mapping.**~~ **Resolved 2026-05-03:** Hybrid (Option C) — `init_lite.sh --host=cursor` prompts for a Cursor cheap-tier model id with default `inherit`. Whatever the user provides (or `inherit` if skipped) is written into `.cursor/agents/shamt-lite-*.md`. Init output prints a one-line note: "Sub-agents will use `<value>`. To change later, edit `.cursor/agents/shamt-lite-*.md`." This will be a SHAMT-52 deliverable.
4. ~~**Cursor: `AGENTS.md` vs `.cursor/rules/*.mdc` split.**~~ **Resolved 2026-05-03:** Option A — `.cursor/rules/*.mdc` only. `init_lite.sh --host=cursor` (alone) does NOT write `AGENTS.md`; it only deploys the 5 `.mdc` files. When `--host=cursor,codex` is combined, `AGENTS.md` is still written (Codex's primary surface), but Cursor's deployment doesn't depend on it. SHAMT-52 deliverable.
5. ~~**Should `shamt-lite-story` skill stay master-applicable?**~~ **Resolved 2026-05-03:** Confirmed Option A — all five Lite skills (`shamt-lite-story` + four new siblings) carry `master-only: false`. Available to both master and child projects. No regen-script filtering needed.
6. ~~**MCP server for Lite (Tier 3).**~~ **Resolved 2026-05-03:** Defer (Option A). Lite stays manual on counter tracking. The `--with-mcp` flag remains reserved in Proposal 7 for possible future revisit if usage data shows demand. Migration path is documented in the "Migration to full Shamt" section of `SHAMT_LITE.md` (Phase 5 deliverable).
7. ~~**Hooks for Lite (Tier 3).**~~ **Resolved 2026-05-03:** Defer (Option A). Same rationale as OQ 6 — hook-deployment plumbing across three host formats is expensive; benefit is small. Migration path covers users who need hook enforcement.
8. ~~**Cross-cutting SHAMT-42 follow-up.**~~ **Resolved 2026-05-03:** Split into a separate design doc (Option A). SHAMT-51 stays Lite-scoped. The full-Shamt `regen-codex-shims.sh` migration from `~/.codex/prompts/` to `.agents/skills/` will be its own SHAMT-N (likely SHAMT-53 after SHAMT-52 Cursor; exact number reserved at draft time). Reason for separate doc: the migration changes deployment behavior for every existing full-Shamt-on-Codex child project, and that blast radius warrants its own validation pass.
9. ~~**`AGENTS.md` propagation strategy on Codex.**~~ **Resolved 2026-05-03:** Option A — one-shot copy at init. `init_lite.sh --host=codex` writes `AGENTS.md` as a copy of `SHAMT_LITE.md` and never touches it again. To pick up upstream updates, the user re-runs `init_lite.sh --host=codex` (which overwrites the deployed `AGENTS.md`). Document this overwrite behavior in the regen script's output. Consistent with the Lite ethos and the TL;DR's "Lite is opt-out of master sync" property.

---

## Risks & Mitigation

**R1: Cursor breaking change between research date and implementation.** Cursor 3.x is moving fast (3.0 released April 2026, 3.2 released April 24 2026). The `.cursor/rules/`, `.cursor/skills/`, `.cursor/agents/` paths are stable per docs as of May 2026, but a future major version could rename them.
- *Mitigation:* Implementation phase repeats the WebFetch research as Step 0. Regen scripts are isolated — a path rename is a one-line fix.

**R2: Codex Skills surface changes.** Codex Skills launched December 2025 and is GA. Risk is low.
- *Mitigation:* Pin to documented schema; treat undocumented frontmatter fields as forward-incompatible.

**R3: Token Discipline profiles drift from Token Discipline table.** If `SHAMT_LITE.md`'s table is updated independently of the profile fragments, they will diverge.
- *Mitigation:* Add a guide-audit dimension or comment in `SHAMT_LITE.md`'s Token Discipline section pointing to `lite/profiles-codex/` and noting both must be updated together.

**R4: `init_lite.sh` complexity creep.** Adding `--host=`, model prompting, and regen calls grows the script substantially.
- *Mitigation:* Mirror `init.sh`'s structure (full-Shamt). The full init.sh is already complex but legible because each host is a discrete block. Use the same pattern.

**R5: Cursor sub-agent invocation differs from Claude/Codex.** Cursor sub-agents are invoked via `/<name>` (e.g., `/verifier confirm the auth flow`) or natural language. The "spawn the builder" instruction in `SHAMT_LITE.md` Pattern 5 may need to be updated to reference the slash form.
- *Mitigation:* Skill bodies reference invocation via natural language (`"Spawn the shamt-lite-builder"`) which works on all three hosts. Slash forms are documented but optional.

**R6: Standalone `SHAMT_LITE.md` and `.cursor/rules/*.mdc` content drift.** Both contain the 5 patterns; if one is updated and the other isn't, they diverge.
- *Mitigation:* The `.mdc` files are derived from the same source sections in `SHAMT_LITE.md`. Document as a "single source of truth" rule: `SHAMT_LITE.md` is canonical; `.mdc` files are extracted via guide-audit checked references. Optional: add a script that regenerates `.mdc` files from `SHAMT_LITE.md` sections.

**R7: User runs `--host=codex` but doesn't have Codex installed.** Init succeeds but `.codex/config.toml` is meaningless.
- *Mitigation:* Document as a no-op-if-unused; the file is harmless. Same risk exists in full-Shamt SHAMT-42; same mitigation.

---

## Change History

| Date | Change |
|---|---|
| 2026-05-03 | Initial draft created (research-driven from chat proposal). Research conducted on Cursor 3.x and Codex CLI capabilities (May 2026). |
| 2026-05-03 | Validation loop completed — 10 primary rounds + 3 sub-agent attempts. Substantive iterations: TL;DR + Tier 0 added; Goals split into "patterns unchanged" (G6) + "host-agnostic XML" (G8); Proposal 9 added; Phase 2 expanded to a real `regen-lite-claude.sh` step; Files Affected table got master/deployed legend; OQ 9 added on AGENTS.md propagation; auto-sync-opt-out callout added prominently in TL;DR. Final state: Status = Validated. |
