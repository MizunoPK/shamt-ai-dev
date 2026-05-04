# SHAMT-51 v2: Shamt Lite Foundation + Codex + Claude Bridge

**Status:** Ready for implementation (validated; v2 — replaces v1 unified scope; no OQs after v1's resolutions)
**Created:** 2026-05-03 (v2 derived from v1 after OQ resolutions)
**Branch:** `feat/SHAMT-51`
**Validation Log:** [SHAMT51v2_VALIDATION_LOG.md](./SHAMT51v2_VALIDATION_LOG.md)
**v1 reference:** [SHAMT51_DESIGN.md](./SHAMT51_DESIGN.md) (validated unified design covering Codex + Cursor; preserved for context. v2 shrinks scope per OQ 1's split decision.)
**Type:** Design Proposal
**Companion docs:** [SHAMT-52](./SHAMT52_DESIGN.md) (Cursor support), [SHAMT-53](./SHAMT53_DESIGN.md) (full-Shamt Codex skills migration).

---

## TL;DR

This is the **shrunken-scope** design doc for the Shamt Lite host wiring effort. After OQ resolution on the unified v1 design (SHAMT51_DESIGN.md), implementation was split into three docs:

- **SHAMT-51 v2** (this doc): foundation (canonical Lite content layer + `init_lite.sh --host=` flag + Proposal 8 host-agnostic XML) + **Codex Tier 1+2** + **Claude bridge**.
- **SHAMT-52:** Cursor support (Tier 1+2).
- **SHAMT-53:** full-Shamt `regen-codex-shims.sh` migration (separate cross-cutting follow-up surfaced during v1 research).

Everything Cursor-specific from v1 has been moved to SHAMT-52. Default no-flag behavior of `init_lite.sh` is preserved exactly. Hooks and MCP remain Tier 3 (deferred). The Lite-is-opt-out-of-master-sync property is preserved.

---

## Tier Definitions

The proposal is tiered to control complexity:

| Tier | Surfaces | Status in this doc |
|---|---|---|
| **Tier 0** | Standalone `SHAMT_LITE.md` only (today's `init_lite.sh` no-flag behavior) | Preserved unchanged |
| **Tier 1** | Skills + slash commands + sub-agents (Claude + Codex; Cursor in SHAMT-52) | Proposed |
| **Tier 2** | Codex per-phase profiles (Cursor `.mdc` rules split in SHAMT-52) | Proposed |
| **Tier 3** | Hooks + MCP server + observability | Deferred — out of scope |

Tier 0 is the default. Tier 1 is the minimum useful host-wired deployment for Lite. Tier 2 layers token-discipline mechanization. Tier 3 is full-Shamt territory.

---

## Problem Statement

Shamt Lite today is a rules-file-only deployment: `init_lite.sh` writes `shamt-lite/SHAMT_LITE.md` plus reference and template files, and the user manually copies `SHAMT_LITE.md` into whatever rules file convention their AI service uses. No skills, no slash commands, no sub-agents, no per-phase model profiles, no hooks. Every model selection in the Token Discipline table is advisory prose, not infrastructure.

Full Shamt has solved host wiring for Claude Code (SHAMT-40) and Codex (SHAMT-42), but those designs are sized for the S1–S11 epic workflow — too heavy for Lite.

**Concrete trigger (for v2 scope):** A child project using Codex + Lite cannot invoke the validation loop, spec protocol, or builder handoff via slash command, cannot delegate validator confirmations to a cheap-model sub-agent without writing the Task spawn by hand, and gets no per-phase model selection. The Token Discipline doctrine that promises 40–60% savings is, in practice, only as effective as the user's willingness to manually switch models.

**Who is affected:** Lite users on Codex (this doc) + Cursor (SHAMT-52) who would benefit from the same one-command quality patterns Claude users get.

**Impact of not solving:** Lite continues to be the "manual" tier. Token-discipline savings remain advisory. Sub-agent handoff requires hand-writing Task spawns from inline XML examples.

---

## Goals

1. Give Shamt Lite users on **Codex** the same one-command, model-aware experience that Claude users get from full Shamt — without dragging Lite into full-Shamt complexity (no MCP, no hooks bundle, no OTel, no cloud).
2. Establish a single canonical content layer for Lite skills, slash commands, and sub-agents that deploys to **all three hosts** (Claude, Codex, Cursor) with minimal per-host transformation. SHAMT-52 will plug Cursor into this same layer.
3. Make per-phase model selection (the Token Discipline table) actually mechanical on Codex via per-phase profiles, not advisory prose.
4. Author each Lite skill, slash command, and sub-agent persona once and deploy via per-host regen scripts. v2 scope deploys to Claude + Codex paths: skills → `.claude/skills/` / `.agents/skills/`; slash commands → `.claude/commands/` (Codex's project-shareable slash surface IS Skills); sub-agents → `.claude/agents/` / `.codex/agents/`. (SHAMT-52 plugs Cursor into the same authored content via `.cursor/{skills,commands,agents,rules}/`.)
5. Keep the standalone `SHAMT_LITE.md` rules file unchanged in **patterns and protocols** — host wiring is additive sugar. The `SHAMT_LITE.md` edits proposed here are content-only and additive: (a) Goal 7's host-agnostic XML (corrects a pre-existing portability bug), (b) Phase 4's `--host=` flag documentation, and (c) Phase 4's "Migration to full Shamt" section. None of these change the 5 patterns or token-discipline doctrine.
6. Preserve the option to "stay manual": running `init_lite.sh` with no host flag must produce today's output exactly.
7. Make the standalone `SHAMT_LITE.md` host-agnostic — replace the Claude-specific `model="haiku"` XML with a model-tier abstraction so non-Claude users without host wiring still get correct guidance.
8. Document the migration path for Lite users who outgrow Lite and want full Shamt.

---

## Background: Current State of Hosts (May 2026)

This research informs both v2 (Codex/Claude) and SHAMT-52 (Cursor). The key finding — all three hosts support `SKILL.md` — is what makes a single canonical content layer feasible.

### Claude Code (already wired by SHAMT-40 in full Shamt)

| Surface | Path | Notes |
|---|---|---|
| Rules | `CLAUDE.md` (project root) | Always loaded |
| Skills | `.claude/skills/<name>/SKILL.md` | Model-discovered |
| Commands | `.claude/commands/<name>.md` | `/name` invocation |
| Sub-agents | `.claude/agents/<name>.md` | YAML frontmatter, `model` field |
| Hooks | `.claude/settings.json` `hooks` block | (not used by Lite — Tier 3) |
| MCP | `.claude/settings.json` `mcpServers` block | (not used by Lite — Tier 3) |

### Codex CLI (wired by SHAMT-42 in full Shamt; this doc adds Lite)

| Surface | Path | Notes |
|---|---|---|
| Rules | `AGENTS.md` (project root) | More-specific overrides supported via nested `AGENTS.md` |
| Skills | `.agents/skills/<name>/SKILL.md` (project), `~/.agents/skills/` (user), `/etc/codex/skills` (admin) | Same SKILL.md convention as Claude. Implicit + explicit (`/skills`, `$skill-name`). Repo-shareable. **Codex Skills launched December 2025.** |
| Sub-agents | `.codex/agents/<name>.toml` (project) | Wired by SHAMT-42 |
| Custom prompts | `~/.codex/prompts/*.md` | User-only, NOT project-shareable. SHAMT-42 used this as an interim. SHAMT-53 migrates full-Shamt off this path; Lite never uses it. |
| Profiles | `.codex/config.toml` `[profiles.X]` blocks | Wired by SHAMT-42; per-stage |
| Hooks | `.codex/config.toml` SHAMT-HOOKS block | (not used by Lite — Tier 3) |
| MCP | `~/.codex/config.toml` or `.codex/config.toml` | (not used by Lite — Tier 3) |

**SHAMT-53 cross-reference:** SHAMT-53 separately handles the full-Shamt migration of `regen-codex-shims.sh` from `~/.codex/prompts/` to `.agents/skills/`. SHAMT-51 v2 only writes Lite content; it doesn't touch full-Shamt's regen.

### Cursor 3.x (wired by SHAMT-52 — see that doc)

Capability map for Cursor is in SHAMT-52's Background section. Summary: Cursor 3.x has full feature parity with Claude/Codex for the surfaces Lite cares about (`.cursor/rules/*.mdc`, `.cursor/skills/`, `.cursor/agents/`, `.cursor/commands/`, `.cursor/hooks.json`, `.cursor/mcp.json`).

### Cross-host convergence

The single most important finding from research: **all three hosts now support `SKILL.md` with near-identical conventions.** A canonical SKILL.md authored once can deploy verbatim to:
- `.claude/skills/<name>/SKILL.md`
- `.agents/skills/<name>/SKILL.md` (Codex)
- `.cursor/skills/<name>/SKILL.md` (Cursor — SHAMT-52)

This convergence is what makes the canonical content layer architecturally sound. v2 establishes that layer and wires Claude + Codex; SHAMT-52 plugs Cursor in.

---

## Detailed Design

### Proposal 1: Canonical Lite content layer

**Description:** Mirror the SHAMT-39 canonical content pattern for Lite. Skills reuse `.shamt/skills/` (filtered by `shamt-lite-` name prefix); slash commands, sub-agent personas, and Codex profile fragments live under a new `.shamt/scripts/initialization/lite/` subtree. (Cursor-specific `.mdc` rule sources will be added by SHAMT-52 under `.shamt/scripts/initialization/lite/rules-cursor/`.)

**Final structure (SHAMT-51 v2 scope only):**

```
.shamt/skills/                                  (existing — extended with Lite skills)
├── shamt-lite-story/SKILL.md                   (existing — orchestrator)
├── shamt-lite-validate/SKILL.md                (NEW — Pattern 1)
├── shamt-lite-spec/SKILL.md                    (NEW — Pattern 3)
├── shamt-lite-plan/SKILL.md                    (NEW — Pattern 5)
├── shamt-lite-review/SKILL.md                  (NEW — Pattern 4)
└── ...                                          (other full-Shamt skills unchanged)

.shamt/scripts/initialization/lite/             (NEW subtree, v2 scope)
├── commands/
│   ├── lite-story.md
│   ├── lite-validate.md
│   ├── lite-spec.md
│   ├── lite-plan.md
│   └── lite-review.md
├── agents/
│   ├── shamt-lite-validator.yaml
│   └── shamt-lite-builder.yaml
└── profiles-codex/
    ├── shamt-lite-intake.fragment.toml
    ├── shamt-lite-spec-research.fragment.toml
    ├── shamt-lite-spec-design.fragment.toml
    ├── shamt-lite-spec-validate.fragment.toml
    ├── shamt-lite-plan.fragment.toml
    ├── shamt-lite-build.fragment.toml
    ├── shamt-lite-review.fragment.toml
    └── shamt-lite-validator.fragment.toml

(SHAMT-52 will add: .shamt/scripts/initialization/lite/rules-cursor/*.mdc)
```

**Skill family relationship:** `shamt-lite-story` is the *orchestrator* skill — runs the full six-phase workflow end-to-end and delegates to the four pattern-specific skills (`shamt-lite-spec`, `shamt-lite-plan`, `shamt-lite-review`, `shamt-lite-validate`) at phase boundaries. Pattern-specific skills can also be invoked standalone. All five carry `master-only: false` (per OQ 5 resolution).

**Rationale:** Single source of truth. Skills already canonically live in `.shamt/skills/` (SHAMT-39); reusing avoids duplicating the layer (per OQ 2 resolution).

**Alternatives considered:**
- *(A) Co-locate all Lite content under `.shamt/scripts/initialization/lite/` (skills too).* Rejected by OQ 2 — would duplicate canonical layer.
- *(B) Heredoc inside `init_lite.sh`.* Unmaintainable; rejected.

### Proposal 2: Per-host regen scripts (v2 scope: Claude + Codex)

**Description:** Two new regen scripts modeled on `regen-claude-shims.sh` and `regen-codex-shims.sh`. SHAMT-52 will add a third (`regen-lite-cursor.sh`).

```
.shamt/scripts/regen/
├── regen-claude-shims.sh / .ps1        (existing — unchanged for full Shamt)
├── regen-codex-shims.sh / .ps1         (existing — SHAMT-53 will modify separately)
├── regen-lite-claude.sh / .ps1         (NEW — see Phase 2)
├── regen-lite-codex.sh / .ps1          (NEW — see Phase 3)
└── (regen-lite-cursor.sh / .ps1)       (deferred to SHAMT-52)
```

**`regen-lite-claude.sh` behavior:**
1. Read all `shamt-lite-*` skills from `.shamt/skills/` and copy to `<TARGET>/.claude/skills/<name>/SKILL.md`. Substitute `<parameter name="model">{cheap-tier}</parameter>` → `<parameter name="model">haiku</parameter>` so deployed XML examples are concrete; the explanatory footnote (which references `{cheap-tier}` as inline code) is preserved.
2. Copy `.shamt/scripts/initialization/lite/commands/*.md` → `<TARGET>/.claude/commands/`.
3. Transform `.shamt/scripts/initialization/lite/agents/*.yaml` → `<TARGET>/.claude/agents/<name>.md` (YAML frontmatter + body, with `model_tier: cheap` mapped to `model: haiku-4-5`).
4. Skip hooks, skip MCP (Tier 3).
5. Idempotent: managed-block markers preserve user-authored sections.

**`regen-lite-codex.sh` behavior:**
1. Read all `shamt-lite-*` skills from `.shamt/skills/` and copy to `<TARGET>/.agents/skills/<name>/SKILL.md` (Codex's native skills surface, NOT `~/.codex/prompts/`).
2. Transform `.shamt/scripts/initialization/lite/agents/*.yaml` → `<TARGET>/.codex/agents/<name>.toml`.
3. Insert `.shamt/scripts/initialization/lite/profiles-codex/*.fragment.toml` into `<TARGET>/.codex/config.toml` SHAMT-PROFILES block. Substitute `${FRONTIER_MODEL}` / `${DEFAULT_MODEL}` from `.shamt/host/codex/.model_resolution.local.toml`.
4. Skip hooks (Tier 3).
5. Skip MCP (Tier 3).
6. Filter by `shamt-lite-*` name prefix (NEW filtering behavior — distinct from full-Shamt regen which filters by `master-only`).
7. Idempotent.

**Rationale:** Two separate scripts (vs. one combined) match the existing per-host pattern.

**Alternatives considered:**
- *(A) Single combined `regen-lite.sh`.* Breaks per-host pattern; rejected.

### Proposal 3: Native Codex Skills (project-shareable, not `~/.codex/prompts/`)

**Description:** Lite uses `.agents/skills/` exclusively for its slash-command surface on Codex. Skills are repo-shareable (commits with the project), supporting both implicit (model-discovered) and explicit (`/skills` or `$shamt-lite-validate`) invocation. Custom prompts at `~/.codex/prompts/` are user-only and were the SHAMT-42 interim — Lite skips them entirely.

**Rationale:** Project-shareability is the core requirement for Lite — when a developer commits Lite host wiring to git, teammates get the slash commands automatically on `git pull`. `~/.codex/prompts/` is per-user.

**Alternatives considered:**
- *(A) Continue with `~/.codex/prompts/` interim.* Per-user; rejected for Lite.
- *(B) Both — write to skills AND prompts.* Duplication; rejected.

### Proposal 4: Codex per-phase profiles for Lite

**Description:** 8 profile fragments in `.shamt/scripts/initialization/lite/profiles-codex/`. Each maps a phase of the Lite story workflow (or a sub-agent persona) to a model tier and reasoning effort, mirroring the Token Discipline table verbatim.

| Profile | Model tier | Reasoning | Sandbox | Maps to |
|---|---|---|---|---|
| `shamt-lite-intake` | `${DEFAULT_MODEL}` | minimal | workspace-write | Story workflow Phase 1 — mechanical capture |
| `shamt-lite-spec-research` | `${DEFAULT_MODEL}` | low | read-only | Story workflow Phase 2 / Pattern 3 Step 2 — code reading |
| `shamt-lite-spec-design` | `${FRONTIER_MODEL}` | medium | workspace-write | Story workflow Phase 2 / Pattern 3 Step 4 — design dialog |
| `shamt-lite-spec-validate` | `${FRONTIER_MODEL}` | high | read-only | Story workflow Phase 2 / Pattern 3 Step 6 — multi-dim validation |
| `shamt-lite-plan` | `${DEFAULT_MODEL}` | low | workspace-write | Story workflow Phase 3 — plan creation |
| `shamt-lite-build` | `${DEFAULT_MODEL}` | minimal | workspace-write | Story workflow Phase 4 — mechanical execution (cheap-tier model when delegating to builder) |
| `shamt-lite-review` | `${FRONTIER_MODEL}` | medium | read-only | Story workflow Phase 5 — issue finding + classification |
| `shamt-lite-validator` | `${DEFAULT_MODEL}` | low | read-only | Sub-agent confirmations (any phase) |

*Phase numbers refer to the six-phase story workflow (Intake → Spec → Plan → Build → Review → Polish). "Pattern 3 Step N" refers to the seven-step Spec Protocol within the Spec phase.*

**`${FRONTIER_MODEL}` and `${DEFAULT_MODEL}`** are resolved from `.shamt/host/codex/.model_resolution.local.toml` (existing SHAMT-42 mechanism — gitignored, per-developer).

**Rationale:** Codex profiles are loaded at session start. Stage transitions in the Lite workflow are natural session boundaries. The Token Discipline table becomes mechanical: `codex --profile shamt-lite-spec-validate` opens a session pre-tuned for Spec Step 6.

**Alternatives considered:**
- *(A) Skip profiles, keep prose recommendations.* Defeats the goal; rejected.
- *(B) One profile per pattern (5 instead of 8).* Spec phase has three distinct model needs; rejected.

### Proposal 5: Sub-agent personas for Lite

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

**Tier mapping (v2 scope: Claude + Codex):**
- Claude Code: `cheap` → `haiku-4-5`
- Codex: `cheap` → `${DEFAULT_MODEL}` (resolved from `.model_resolution.local.toml`)
- Cursor: handled in SHAMT-52 (per OQ 3 resolution: hybrid prompt, default `inherit`)

**Rationale:** These two personas encode the inline XML in `SHAMT_LITE.md` (Pattern 1 Step 7 + Pattern 5 Step 4 Option B) into actual host artifacts. Once deployed, the user invokes via natural language ("Spawn the shamt-lite-builder") instead of constructing XML.

**Alternatives considered:**
- *(A) Keep XML inline, no personas.* Every spawn requires manual XML; rejected.

### Proposal 6: `init_lite.sh --host=` flag (v2 scope: claude, codex)

**Description:** Extend `init_lite.sh` and `init_lite.ps1` with `--host=` flag handling.

```
init_lite.sh [project-name] [--host=claude|codex|...] [--with-mcp]
```

**Behavior matrix (v2 — Cursor combinations land in SHAMT-52):**

| Flag | Result |
|---|---|
| (no flag) | Today's behavior exactly: writes `shamt-lite/` files only (Tier 0) |
| `--host=claude` | Adds `CLAUDE.md` (copy of `SHAMT_LITE.md`), runs `regen-lite-claude.sh` |
| `--host=codex` | Adds `AGENTS.md` (copy of `SHAMT_LITE.md`), prompts for FRONTIER/DEFAULT models, writes `.shamt/host/codex/.model_resolution.local.toml`, runs `regen-lite-codex.sh` |
| `--host=claude,codex` | Both run; `AGENTS.md` is canonical, on Unix `CLAUDE.md` is symlinked to `AGENTS.md`, on Windows it's a duplicate file |
| `--with-mcp` | Tier 3 — deferred. Reserved flag. |

**`AGENTS.md` propagation (per OQ 9 resolution):** One-shot copy at init. Re-running `init_lite.sh --host=codex` overwrites `AGENTS.md`. The regen script's output should note this overwrite behavior.

**`AGENTS.md` content:** A copy of `SHAMT_LITE.md` (instantiated with `{{PROJECT_NAME}}` / `{{DATE}}`). Codex reads `AGENTS.md` from project root automatically.

**Rationale:** The `--host=` flag mirrors SHAMT-42's pattern (`init.sh --host=claude,codex`) so users moving between Lite and full Shamt see consistent ergonomics. Default no-flag behavior is preserved exactly.

**Alternatives considered:**
- *(A) Always write all hosts.* Bloats project tree; rejected.
- *(B) Add `shamt-add-host-lite.sh`.* Symmetric to SHAMT-42's `shamt-add-host.sh`; recommended as a follow-up but not required for v2.

### Proposal 7 (DEFERRED — Tier 3): Hooks and MCP for Lite

Same as v1's Proposal 8. Per OQ 6 + OQ 7 resolutions: defer entirely. Migration path: users who need MCP/hooks move to full Shamt.

### Proposal 8: Make standalone `SHAMT_LITE.md` host-agnostic

**Description:** Replace Claude-specific `model="haiku"` XML in `SHAMT_LITE.md` Pattern 1 Step 7 and Pattern 5 Step 4 with a tier abstraction.

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

**Rationale:** The standalone `SHAMT_LITE.md` is what users get when they don't run `--host=`. It must be host-agnostic to serve all three hosts as a fallback.

**Scope:** Content edit to `SHAMT_LITE.template.md`. Phase 1 deliverable.

---

## Cross-cutting follow-ups (out of scope; tracked separately)

1. **SHAMT-52 — Cursor support.** Cursor wiring lives in its own design doc. Depends on this v2's foundation (canonical content layer + `init_lite.sh --host=` flag).
2. **SHAMT-53 — Full-Shamt Codex skills migration.** `regen-codex-shims.sh` migration from `~/.codex/prompts/` to `.agents/skills/`. Separate doc; cross-impact on every existing full-Shamt-on-Codex child project.
3. **AI service registry update for Cursor.** Handled in SHAMT-52 (Cursor entry → "full-wiring (Lite)").

---

## Files Affected

**Legend:**
- `CREATE` / `MODIFY` apply to **master-stored** files (this repo).
- `DEPLOYED` files are written into the **child project tree** by `init_lite.sh` or regen scripts.

| File | Status | Notes |
|---|---|---|
| `.shamt/skills/shamt-lite-validate/SKILL.md` | CREATE | Pattern 1 skill body |
| `.shamt/skills/shamt-lite-spec/SKILL.md` | CREATE | Pattern 3 skill body |
| `.shamt/skills/shamt-lite-plan/SKILL.md` | CREATE | Pattern 5 skill body |
| `.shamt/skills/shamt-lite-review/SKILL.md` | CREATE | Pattern 4 skill body |
| `.shamt/skills/shamt-lite-story/SKILL.md` | MODIFY | Already exists; receives Proposal-8-equivalent edits (`<parameter name="model">haiku</parameter>` → `{cheap-tier}`) for consistency with the new sibling skills. Without this edit the orchestrator skill would diverge from the four new pattern-specific skills, creating a D-DRIFT inconsistency. |
| `.shamt/scripts/initialization/lite/commands/lite-story.md` | CREATE | Slash command |
| `.shamt/scripts/initialization/lite/commands/lite-validate.md` | CREATE | Slash command |
| `.shamt/scripts/initialization/lite/commands/lite-spec.md` | CREATE | Slash command |
| `.shamt/scripts/initialization/lite/commands/lite-plan.md` | CREATE | Slash command |
| `.shamt/scripts/initialization/lite/commands/lite-review.md` | CREATE | Slash command |
| `.shamt/scripts/initialization/lite/agents/shamt-lite-validator.yaml` | CREATE | Validator persona |
| `.shamt/scripts/initialization/lite/agents/shamt-lite-builder.yaml` | CREATE | Builder persona |
| `.shamt/scripts/initialization/lite/profiles-codex/shamt-lite-*.fragment.toml` (×8) | CREATE | Per-phase profiles |
| `.shamt/scripts/regen/regen-lite-claude.sh` | CREATE | Claude regen for Lite |
| `.shamt/scripts/regen/regen-lite-claude.ps1` | CREATE | Windows variant |
| `.shamt/scripts/regen/regen-lite-codex.sh` | CREATE | Codex regen for Lite |
| `.shamt/scripts/regen/regen-lite-codex.ps1` | CREATE | Windows variant |
| `.shamt/scripts/initialization/init_lite.sh` | MODIFY | Add `--host=claude,codex` flag handling |
| `.shamt/scripts/initialization/init_lite.ps1` | MODIFY | Same on Windows |
| `.shamt/scripts/initialization/SHAMT_LITE.template.md` | MODIFY | Proposal 8: tier-abstract the inline XML examples; add "Migration to full Shamt" section pointer; document `--host=` |
| `CLAUDE.md` (root) | MODIFY | Extend the existing "Shamt Lite" section with the v2-scope host-wiring deployment matrix |
| (deployed) `<project>/CLAUDE.md` | DEPLOYED | Written by `init_lite.sh --host=claude` |
| (deployed) `<project>/AGENTS.md` | DEPLOYED | Written by `init_lite.sh --host=codex` |
| (deployed) `<project>/.claude/skills/shamt-lite-*/SKILL.md` | DEPLOYED | By `regen-lite-claude.sh` |
| (deployed) `<project>/.claude/commands/lite-*.md` | DEPLOYED | By `regen-lite-claude.sh` |
| (deployed) `<project>/.claude/agents/shamt-lite-*.md` | DEPLOYED | By `regen-lite-claude.sh` |
| (deployed) `<project>/.agents/skills/shamt-lite-*/SKILL.md` | DEPLOYED | By `regen-lite-codex.sh` |
| (deployed) `<project>/.codex/agents/shamt-lite-*.toml` | DEPLOYED | By `regen-lite-codex.sh` |
| (deployed) `<project>/.codex/config.toml` | DEPLOYED | Profile fragments inserted into SHAMT-PROFILES managed block |

(Cursor-deployed entries handled in SHAMT-52.)

---

## Implementation Plan

### Phase 1: Canonical content authoring (foundation for v2 + SHAMT-52)

- [ ] Author `.shamt/skills/shamt-lite-validate/SKILL.md` (Pattern 1)
- [ ] Author `.shamt/skills/shamt-lite-spec/SKILL.md` (Pattern 3)
- [ ] Author `.shamt/skills/shamt-lite-plan/SKILL.md` (Pattern 5)
- [ ] Author `.shamt/skills/shamt-lite-review/SKILL.md` (Pattern 4 — both modes)
- [ ] Author 5 slash command bodies in `.shamt/scripts/initialization/lite/commands/`
- [ ] Author 2 sub-agent YAMLs in `.shamt/scripts/initialization/lite/agents/`
- [ ] Apply Proposal 8: tier-abstract the inline XML examples in `SHAMT_LITE.template.md`
- [ ] Quick targeted audit of new SKILL.md files: D-DRIFT and D-COVERAGE against `SHAMT_LITE.md`. (Fast pre-check, not a substitute for the Phase 4 full-tree audit.)

### Phase 2: Claude Code (`regen-lite-claude.sh` — new)

**Two project types, two regen flows (no redundancy in either case):**
- *Lite-only projects:* `regen-lite-claude.sh` runs alone. Copies skills, commands, and agents to `.claude/{skills,commands,agents}/`. Full-Shamt's `regen-claude-shims.sh` is not present.
- *Full-Shamt projects:* `regen-claude-shims.sh` runs alone. It already scans `.shamt/skills/` (which now includes the new `shamt-lite-*` skills as collateral), so Lite skills are picked up incidentally. Lite-specific commands and agents (in `.shamt/scripts/initialization/lite/`) are NOT picked up — full-Shamt projects don't need them.
- *Edge case — both regen scripts run in the same project:* skills overwrite idempotently; no collision.

- [ ] Implement `regen-lite-claude.sh` and `.ps1`. Writes skills (filtered by `shamt-lite-*` prefix), commands, and agents to `.claude/{skills,commands,agents}/`. Map `model_tier: cheap` → `model: haiku-4-5`.
- [ ] Modify `init_lite.sh` to handle `--host=claude` (write `CLAUDE.md`, call `regen-lite-claude.sh`).
- [ ] Modify `init_lite.ps1` similarly.
- [ ] Test: dry-run init on a fresh directory.

### Phase 3: Codex Tier 1 + 2

- [ ] Author 8 Codex profile fragments
- [ ] Implement `regen-lite-codex.sh` (skills → `.agents/skills/`, agents → `.codex/agents/`, profiles → `.codex/config.toml`). Filter by `shamt-lite-*` name prefix.
- [ ] Implement `regen-lite-codex.ps1`
- [ ] Modify `init_lite.sh` for `--host=codex` (prompt for models, write `.model_resolution.local.toml`, write `AGENTS.md`, call regen)
- [ ] Modify `init_lite.ps1` similarly
- [ ] Test: dry-run init on a fresh directory

### Phase 4: Documentation and registry updates

- [ ] Update `SHAMT_LITE.template.md` with `--host=` documentation and **Migration to full Shamt** section. Skeleton: "When to migrate (you need MCP `validation_round()`/`next_number()`, hooks like commit-format/no-verify-blocker, or the S1–S11 epic workflow); how to migrate (run full-Shamt `init.sh` in the project root alongside the existing Lite tree — your `stories/` and `CHANGES.md` are unaffected; the resulting `.shamt/` adds full-Shamt content; you can remove `shamt-lite/` after confirming everything works); what's preserved (story artifacts, validation history) vs. what's added (epic tracker, design docs, MCP tools, hooks)."
- [ ] Update root `CLAUDE.md` Shamt Lite section.
- [ ] Run guide audit on the entire `.shamt/guides/` tree (3 consecutive clean rounds, per CLAUDE.md "Critical Rules").

### Phase 5: Implementation validation and PR

- [ ] Run implementation validation loop (5 dimensions).
- [ ] Open `feat/SHAMT-51` PR.
- [ ] After PR merge: archive design doc to `design_docs/archive/` (move both v1 and v2 to archive, with v2 cited as the as-implemented version).

---

## Validation Strategy

**Primary validation (this design doc):** 7-dimension validation loop. Exit: primary clean round + 2 independent Haiku sub-agent confirmations.

**Implementation validation:** 5-dimension validation loop. Same exit criterion.

**Testing approach:**
- Run each new regen script on a fresh empty directory; verify all expected files appear with correct content.
- For `init_lite.sh --host=claude` and `--host=codex`: run end-to-end on a fresh test directory; verify the resulting tree matches the expected layout.
- For Codex profiles: launch a Codex session with `--profile shamt-lite-spec-validate` and verify model and reasoning effort are applied.
- For sub-agent personas: invoke the validator from a Lite story validation step and verify it spawns with the expected model.
- **Cross-host smoke test:** Run the same simple story (Phase 1 → 6) on Claude AND Codex; verify the same artifacts are produced. *(Cursor coverage of this smoke test is in SHAMT-52.)*

**Success criteria:**
- All v2-scope deliverables exist on disk and are exercised by at least one end-to-end test.
- A child project can run `init_lite.sh --host=claude,codex` and immediately invoke `/lite-spec`, `/lite-plan`, `/lite-review`, `/lite-validate` from both hosts.
- The Token Discipline table in `SHAMT_LITE.md` is mechanically realized via Codex profiles.
- The standalone `SHAMT_LITE.md` continues to work as a host-agnostic fallback (with Proposal 8's edits).

---

## Open Questions

(All v1 OQs were resolved before v2 was authored. v2 inherits the resolutions; no new open questions for v2 scope.)

For reference, the resolutions that shaped v2:
- **OQ 1:** Split SHAMT-51 work into two design docs — SHAMT-51 v2 (this doc, foundation + Codex + Claude) and SHAMT-52 (Cursor).
- **OQ 2:** Skills live in `.shamt/skills/` filtered by `shamt-lite-` prefix.
- **OQ 5:** All five Lite skills carry `master-only: false`.
- **OQ 6:** MCP for Lite — defer (Tier 3).
- **OQ 7:** Hooks for Lite — defer (Tier 3).
- **OQ 8:** Full-Shamt SHAMT-42 follow-up split into its own design doc, SHAMT-53 (separate cross-cutting concern, not part of the OQ 1 split).
- **OQ 9:** `AGENTS.md` propagation — one-shot copy at init.

OQs 3 and 4 were Cursor-specific and live in SHAMT-52.

---

## Risks & Mitigation

**R1: Codex Skills surface changes.** Codex Skills launched December 2025 and is GA. Risk is low.
- *Mitigation:* Pin to documented schema; treat undocumented frontmatter fields as forward-incompatible.

**R2: Token Discipline profiles drift from Token Discipline table.** If `SHAMT_LITE.md`'s table is updated independently of the profile fragments, they will diverge.
- *Mitigation:* Add a comment in `SHAMT_LITE.md`'s Token Discipline section pointing to `lite/profiles-codex/` and noting both must be updated together.

**R3: `init_lite.sh` complexity creep.** Adding `--host=`, model prompting, and regen calls grows the script substantially.
- *Mitigation:* Mirror `init.sh`'s structure (full-Shamt). Each host is a discrete block.

**R4: User runs `--host=codex` but doesn't have Codex installed.** Init succeeds but `.codex/config.toml` is meaningless.
- *Mitigation:* Document as a no-op-if-unused; the file is harmless. Same risk in full-Shamt SHAMT-42; same mitigation.

**R5: SHAMT-52 prerequisite concerns.** SHAMT-52 (Cursor) depends on v2's foundation (canonical content layer + `init_lite.sh --host=` flag). If v2 lands in a state that doesn't fully establish the foundation, SHAMT-52 implementation gets blocked.
- *Mitigation:* Phase 1 of v2 must complete cleanly. SHAMT-52's Phase 0 includes a prerequisite check that confirms v2 is in place.

**R6: SHAMT-53 cross-impact.** SHAMT-53 changes full-Shamt's `regen-codex-shims.sh` to write to `.agents/skills/`. v2's `regen-lite-codex.sh` also writes to `.agents/skills/`. The two scripts coexist and both write to the same directory using different name prefixes (`shamt-lite-*` vs other `shamt-*`).
- *Mitigation:* Both scripts use prefix-based naming. No collision risk. Document the coexistence in `.shamt/host/codex/README.md` (SHAMT-53 deliverable).

---

## Change History

| Date | Change |
|---|---|
| 2026-05-03 | v1 (unified Codex+Cursor) drafted and validated. |
| 2026-05-03 | v2 created post OQ resolution: scope shrunk to foundation + Codex + Claude bridge. Cursor moved to SHAMT-52; full-Shamt Codex migration moved to SHAMT-53. |
| 2026-05-04 | Implementation pass: Files Affected table updated — `shamt-lite-story/SKILL.md` reclassified UNCHANGED → MODIFY (Proposal-8-equivalent consistency edit). Regen scripts (`regen-lite-claude.sh/.ps1`, `regen-lite-codex.sh/.ps1`) extended to substitute `{cheap-tier}` inside `<parameter name="model">...</parameter>` XML at deploy time (Claude → `haiku`; Codex → resolved `${DEFAULT_MODEL}`); the explanatory footnote is preserved. |
