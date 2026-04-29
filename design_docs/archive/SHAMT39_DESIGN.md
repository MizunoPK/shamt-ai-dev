# SHAMT-39: Canonical Content Foundation — Skills, Sub-Agent Personas, Slash Commands

**Status:** Implemented
**Created:** 2026-04-27
**Branch:** `feat/SHAMT-39`
**Validation Log:** [SHAMT39_VALIDATION_LOG.md](./SHAMT39_VALIDATION_LOG.md)
**Companion docs:** [`CLAUDE_INTEGRATION_THEORIES.md`](../CLAUDE_INTEGRATION_THEORIES.md), [`CODEX_INTEGRATION_THEORIES.md`](../CODEX_INTEGRATION_THEORIES.md), [`FUTURE_ARCHITECTURE_OVERVIEW.md`](../FUTURE_ARCHITECTURE_OVERVIEW.md)

---

## Problem Statement

Shamt's framework knowledge today lives in `.shamt/guides/` as reference documentation that an agent must remember to read. Validation protocols, the architect-builder pattern, spec resolution rules, code-review dimensions, audit dimensions, and discovery Q&A flows are all encoded as prose the agent re-discovers each session. There is no host-aware substrate that an AI host (Claude Code, Codex) can auto-load, no per-persona agent definitions with declared model and tool restrictions, and no slash-command surface for user-invocable Shamt operations.

The Claude and Codex theorization docs both identify three highest-leverage content layers that should exist as host-portable canonical artifacts in the master repo:

1. **Skills** — auto-loadable behavior packs encoding Shamt's protocols (validation loop, architect-builder, spec protocol, code review, guide audit, discovery, import/export).
2. **Sub-agent personas** — neutral definitions of `shamt-validator`, `shamt-builder`, `shamt-architect`, `shamt-guide-auditor`, `shamt-spec-aligner`, `shamt-code-reviewer`, `shamt-discovery-researcher` with declared model, sandbox/tool restriction, and prompt template.
3. **Slash command bodies** — `shamt-start-epic`, `shamt-validate`, `shamt-audit`, `shamt-export`, `shamt-import`, `shamt-status`, `shamt-resume`, `shamt-promote`.

Without this foundation, the host-wiring work in SHAMT-40 / SHAMT-42 has nothing to wire. This design doc establishes the canonical content layer that all subsequent host-specific work consumes.

---

## Goals

1. Author all skill content as host-portable markdown under `.shamt/skills/<name>/SKILL.md` so a single source serves both Claude Code and Codex (when its skills surface stabilizes).
2. Author all sub-agent personas as neutral YAML definitions under `.shamt/agents/<name>.yaml` with model, sandbox/tool restriction, reasoning effort, and developer instructions declared.
3. Author slash command bodies as markdown under `.shamt/commands/<name>.md` with argument substitution patterns documented.
4. Update `CLAUDE.md` (master) to reference the new directories so they're discoverable.
5. Ensure all content is content-only (no host wiring) so this design doc is purely additive and child projects on prior states are unaffected until they re-init.

---

## Detailed Design

### Proposal 1: Author content from existing reference guides

**Description:** The Shamt guide tree (`.shamt/guides/`) already contains the protocols this design doc seeks to encode. The skill bodies, agent prompts, and command bodies are essentially distillations of existing content into trigger-anchored or persona-anchored form.

For each artifact, the source guide becomes the authority and the new file is a focused excerpt:

- `shamt-validation-loop` skill body ← `validation_loop_master_protocol.md`
- `shamt-architect-builder` skill body ← `architect_builder_pattern.md` + `implementation_plan_format.md`
- `shamt-spec-protocol` skill body ← `validation_loop_spec_refinement.md` + `critical_workflow_rules.md` (the ONE-question-at-a-time rule)
- `shamt-code-review` skill body ← `code_review/` directory contents
- `shamt-guide-audit` skill body ← `audit/` directory + `severity_classification_universal.md`
- `shamt-discovery` skill body ← S1.P3 stage guide + `validation_loop_discovery.md`
- `shamt-import` / `shamt-export` skill bodies ← `sync/import_workflow.md` / `sync/export_workflow.md`
- `shamt-master-reviewer` skill body ← CLAUDE.md "Reviewing Child Project PRs" section (master-only)
- `shamt-lite-story` skill body ← `SHAMT_LITE.template.md` + `story_workflow_lite.template.md`

Sub-agent personas (`shamt-validator`, `shamt-builder`, etc.) draw from `model_selection.md`'s mandatory-delegation table for their model and reasoning-effort defaults.

Slash command bodies are short — they describe the user-facing intent and may invoke a skill or a script; full procedural content stays in the skill.

**Rationale:** Authoring from existing guides preserves the framework's accumulated knowledge and avoids redundancy. Skills and persona files become host-specific *surfaces* over the same authoritative protocol content. Future updates to a protocol require updating the source guide and the skill body together.

**Alternatives considered:**
- *Author skills from scratch:* Risks divergence between guide content and skill content, creates maintenance burden, throws away validated protocol prose. Rejected.
- *Make skills point at guides via cross-reference only:* Skills can't ship bare cross-references because the host loader doesn't recursively follow them. Skills need self-contained bodies. Rejected.

### Proposal 2: Define a neutral YAML format for sub-agent personas

**Description:** Sub-agent personas live in `.shamt/agents/<name>.yaml` with this shape:

```yaml
name: shamt-validator
description: Independent confirmation of validation rounds
model_tier: cheap        # cheap | balanced | reasoning  → mapped to host model at regen
reasoning_effort: low    # minimal | low | medium | high | xhigh
sandbox: read-only       # read-only | workspace-write
tools_allowed: [Read, Grep, Glob]
prompt_template: |
  You are an independent validation confirmer for a Shamt validation loop.
  Read the artifact at {artifact_path} and check the {dimension_count} dimensions.
  Report findings only — do not fix anything.
  ...
```

The `model_tier` is host-neutral (cheap/balanced/reasoning); the regen scripts in SHAMT-40 / SHAMT-42 translate to the host's actual model name (Haiku/Sonnet/Opus on Claude Code; current Codex model lineup on Codex). This keeps the canonical persona file stable across host changes.

**Rationale:** YAML is widely supported, supports the multi-line `prompt_template` cleanly, and is host-neutral. Translation to `.claude/agents/<name>.md` (markdown with frontmatter) and `.codex/agents/<name>.toml` (TOML) is a deterministic transform a regen script can perform.

**Alternatives considered:**
- *Author directly in Claude Code's markdown format:* Couples canonical content to Claude Code's format. Codex translation becomes a YAML-to-TOML conversion plus markdown-to-prompt extraction — more brittle than a single neutral source. Rejected.
- *Author in TOML:* Same problem inverted; Claude Code's markdown form is harder to derive from TOML cleanly. Rejected.

### Recommended approach

Both proposals together: existing guides as authoritative content sources, new `.shamt/skills/`, `.shamt/agents/`, `.shamt/commands/` directories as the canonical host-portable layer, neutral YAML for personas, and `CLAUDE.md` updated to reference the new directories.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/skills/shamt-validation-loop/SKILL.md` | CREATE | Skill body distilled from validation_loop_master_protocol.md |
| `.shamt/skills/shamt-architect-builder/SKILL.md` | CREATE | From architect_builder_pattern.md + implementation_plan_format.md |
| `.shamt/skills/shamt-spec-protocol/SKILL.md` | CREATE | From spec refinement + critical workflow rules |
| `.shamt/skills/shamt-code-review/SKILL.md` | CREATE | From code_review/ guides |
| `.shamt/skills/shamt-guide-audit/SKILL.md` | CREATE | From audit/ guides + severity classification; audit scope covers all of `.shamt/guides/` (walk all subdirectories including any added by later SHAMTs). Command bodies (`.shamt/commands/`) are out of guide-audit scope — kept accurate by implementation-plan update steps. Skill bodies are checked by two dedicated dimensions within the audit: **(D-DRIFT)** for each SKILL.md, read its `source_guides:` frontmatter and compare key protocol steps against each referenced guide file — flag divergences (MEDIUM for minor prose drift, HIGH for missing or contradicted steps); **(D-COVERAGE)** walk `.shamt/guides/` and flag guide files with no corresponding skill body as LOW-severity candidates — agent proposes whether a new skill is warranted; also flag skills whose source guides don't cover the skill's protocol steps (reverse gap). |
| `.shamt/skills/shamt-discovery/SKILL.md` | CREATE | From S1.P3 guide + discovery validation loop |
| `.shamt/skills/shamt-import/SKILL.md` | CREATE | From sync/import_workflow.md |
| `.shamt/skills/shamt-export/SKILL.md` | CREATE | From sync/export_workflow.md |
| `.shamt/skills/shamt-master-reviewer/SKILL.md` | CREATE | Master-only; from CLAUDE.md child-PR-review section |
| `.shamt/skills/shamt-lite-story/SKILL.md` | CREATE | From Shamt Lite templates |
| `.shamt/agents/shamt-validator.yaml` | CREATE | Cheap-tier, read-only, low reasoning |
| `.shamt/agents/shamt-builder.yaml` | CREATE | Cheap-tier, workspace-write, minimal reasoning |
| `.shamt/agents/shamt-architect.yaml` | CREATE | Reasoning-tier, read-only, high reasoning |
| `.shamt/agents/shamt-guide-auditor.yaml` | CREATE | Mixed-tier (per-dimension), read-only |
| `.shamt/agents/shamt-spec-aligner.yaml` | CREATE | Balanced-tier, read-only |
| `.shamt/agents/shamt-code-reviewer.yaml` | CREATE | Balanced/reasoning split, read-only |
| `.shamt/agents/shamt-discovery-researcher.yaml` | CREATE | Balanced-tier, read-only + web access |
| `.shamt/commands/shamt-start-epic.md` | CREATE | User-invocable epic-start workflow |
| `.shamt/commands/shamt-validate.md` | CREATE | Invoke shamt-validation-loop skill on argued artifact |
| `.shamt/commands/shamt-audit.md` | CREATE | Run guide audit (full or scoped) |
| `.shamt/commands/shamt-export.md` | CREATE | Trigger export workflow |
| `.shamt/commands/shamt-import.md` | CREATE | Trigger import workflow |
| `.shamt/commands/shamt-status.md` | CREATE | Print current epic / stage / blocker |
| `.shamt/commands/shamt-resume.md` | CREATE | Re-hydrate context after compaction / new session |
| `.shamt/commands/shamt-promote.md` | CREATE | Master-only: promote incoming proposal to design doc |
| `.shamt/commands/CHEATSHEET.md` | CREATE | User-facing quick reference: all slash commands with one-line descriptions, S1–S11 stage flow table, sub-agent persona summary. Foundation file that grows with each subsequent SHAMT-N. Not covered by the guide audit (lives in `commands/`, not `guides/`); kept accurate by explicit update steps in SHAMT-41/43/44/45 implementation plans. |
| `CLAUDE.md` | MODIFY | Add section describing the three new directories and their roles; add master-applicable skill/persona note to Master Dev Workflow section |
| `.shamt/skills/README.md` | CREATE | Index + authoring conventions; must document: (1) `source_guides:` frontmatter requirement for every SKILL.md, (2) bidirectional coverage expectation — every skill should correspond to guide content, and major guide sections should have corresponding skills |
| `.shamt/agents/README.md` | CREATE | Persona format spec + tier-to-model mapping |
| `.shamt/commands/README.md` | CREATE | Command body format + argument-substitution conventions |

---

## Implementation Plan

### Phase 1: Directory scaffolding and conventions
- [ ] Create `.shamt/skills/`, `.shamt/agents/`, `.shamt/commands/` directories.
- [ ] Author the three README.md files documenting authoring conventions, persona YAML schema, and command-body format.
- [ ] Decide on the model_tier → model mapping (cheap = Haiku/cheap-Codex, balanced = Sonnet/default-Codex, reasoning = Opus/frontier-Codex). Document in `.shamt/agents/README.md`.

### Phase 2: Author skill content
- [ ] Distill each skill body from the corresponding source guide(s). Each SKILL.md should be self-contained: protocol body + frontmatter (name, description, triggers, source_guides). Use neutral `triggers:` as a YAML list in the frontmatter — not Claude Code-specific syntax; regen scripts translate to host-specific trigger format at deployment time. Add a `source_guides:` YAML list naming every guide file the skill body was distilled from (relative paths from `.shamt/`); this field is the input to the D-DRIFT audit dimension in `shamt-guide-audit`.
- [ ] Cross-link from the skill body back to the source guide for deeper reference.
- [ ] For each skill, include a "When this skill triggers" section so authors of future host shims know the trigger semantics.

### Phase 3: Author sub-agent persona YAML files
- [ ] One YAML per persona (7 total).
- [ ] Each persona declares model_tier, reasoning_effort, sandbox, tools_allowed, prompt_template.
- [ ] Prompt templates use `{placeholder}` syntax for arguments; document the placeholder convention in `.shamt/agents/README.md`.

### Phase 4: Author slash command bodies
- [ ] One markdown file per command (8 total).
- [ ] Each command body describes: purpose, what it invokes (skill name or script path), argument shape, expected output.
- [ ] Use `{name}` placeholder syntax for arguments in command bodies. Regen scripts translate to host syntax if needed (e.g., `$ARGUMENTS` for Codex custom-prompts).
- [ ] Commands that wrap skills (e.g., `shamt-validate` wraps `shamt-validation-loop`) state the wrap relationship explicitly.
- [ ] Author `CHEATSHEET.md` with: (a) a command table listing all 8 commands with one-line descriptions, (b) the S1–S11 stage flow with key artifact per stage, (c) sub-agent persona quick reference (name, model tier, use case). This file is the foundation that subsequent SHAMT-N designs (41, 43, 44, 45) extend with enforcement rules, CI automation, composite workflows, and status line enhancements respectively. Regen scripts copy it verbatim (no argument substitution needed) to `.claude/commands/CHEATSHEET.md` and `~/.codex/prompts/CHEATSHEET.md`.

### Phase 5: Update CLAUDE.md
- [ ] Add a new section "Canonical Content Layer (SHAMT-39)" describing `.shamt/skills/`, `.shamt/agents/`, `.shamt/commands/`.
- [ ] Note that this is content-only — host wiring lands in SHAMT-40 (Claude Code) and SHAMT-42 (Codex).
- [ ] Note that child projects on prior versions ignore the new directories until they re-init or run regen.
- [ ] In the "Master Dev Workflow" section of CLAUDE.md, add a note that master-applicable skills (`shamt-validation-loop`, `shamt-guide-audit`, `shamt-code-review`, `shamt-master-reviewer`) and agent personas (`shamt-validator`, `shamt-builder`, `shamt-architect`, `shamt-guide-auditor`, `shamt-code-reviewer`) are available for master dev work once host wiring (SHAMT-40/42) is deployed.
- [ ] In the "Design Doc Lifecycle" section of CLAUDE.md, add a coverage-gap check to the Implementation step: when implementing a design doc that modifies guides or skill bodies, run a D-COVERAGE pass — verify that (a) guide changes have corresponding skill body updates where warranted and (b) skill body changes have corresponding guide updates. If content exists only in one area and warrants being in both, create the missing counterpart as part of the same implementation. The D-DRIFT and D-COVERAGE audit dimensions catch gaps that slip through during implementation.

### Phase 5.5: Master repo agent persona subset
- [ ] Document which agent personas are master-applicable vs. child-only in `.shamt/agents/README.md`.
- [ ] Master-applicable personas (5): `shamt-validator`, `shamt-builder`, `shamt-architect`, `shamt-guide-auditor`, `shamt-code-reviewer`.
- [ ] Master-only skill (not a persona): `shamt-master-reviewer` — this is a skill file, not an agent persona YAML.
- [ ] Child-only personas (2): `shamt-spec-aligner`, `shamt-discovery-researcher`.
- [ ] Add a "Master Applicability" column or section to the persona index so regen scripts can filter correctly.

### Phase 6: Post-Implementation Validation
- [ ] Run implementation validation loop (5 dimensions) to confirm all files in "Files Affected" were created correctly.
- [ ] Run full guide audit on `.shamt/guides/` to confirm no regression in existing content.

**Note:** Design doc validation (7 dimensions) is completed before Phase 1 begins, not during implementation.

---

## Validation Strategy

- **Primary validation:** Design doc validation loop on this doc (7 dimensions, primary clean + 2 sub-agents).
- **Implementation validation:** After Phase 5.5, run implementation validation loop (5 dimensions). Verify each file in "Files Affected" was created with the expected structure.
- **CHEATSHEET.md review:** Confirm all 8 commands are listed and each description matches the command body authored in Phase 4; confirm S1–S11 table and persona summary are present.
- **Content quality check:** Each skill body must be self-contained — an agent reading only the SKILL.md should be able to execute the protocol without reading the source guide. Verify this empirically by spawning a clean-context agent on each skill and asking it to walk through the protocol.
- **Persona format check:** Each persona YAML must validate against the schema in `.shamt/agents/README.md`. Use a schema validator (yamale, jsonschema-yaml) in Phase 6 sanity check.
- **Success criteria:**
  1. All 30 files listed in "Files Affected" exist with the correct content.
  2. CLAUDE.md references the new directories.
  3. Guide audit clean (3 consecutive rounds).
  4. A clean-context agent given a SKILL.md can successfully execute the protocol.

---

## Decisions

1. **Skill trigger format:** Use neutral `triggers:` as a YAML list in canonical SKILL.md frontmatter. Regen scripts (SHAMT-40 for Claude Code, SHAMT-42 for Codex) translate to host-specific trigger format at deployment time.

2. **`shamt-master-reviewer` skill location:** Keep in `.shamt/skills/` with a `master-only: true` frontmatter flag. `shamt import` syncs the file to children (it lives in their `.shamt/skills/` and gets updates on every import); regen skips wiring it to `.claude/skills/` on child projects. The "skip" is in wiring only — children always receive the latest skill content.

3. **Argument substitution syntax:** Use `{name}` placeholder syntax in all canonical content (command bodies and persona prompt templates). Regen scripts translate to host syntax if needed (e.g., `$ARGUMENTS` for Codex custom-prompts).

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Skill bodies drift from source guides over time | **D-DRIFT** dimension in `shamt-guide-audit`: reads each SKILL.md's `source_guides:` frontmatter, compares key protocol steps against the referenced guide files, and flags divergences (MEDIUM for minor prose drift; HIGH for missing or contradicted protocol steps). **D-COVERAGE** dimension: walks `.shamt/guides/` and flags guide files with no corresponding skill as LOW-severity candidates; also flags skills whose source guides don't cover stated protocol steps (reverse gap). Both dimensions run as part of every guide audit pass. |
| Persona YAML schema becomes a bottleneck for new personas | Schema is YAML-not-JSON-Schema-strict — additive fields don't break old files; document this in README |
| `model_tier` mapping changes when model lineups evolve | Mapping is in `.shamt/agents/README.md` and is the single source of truth — update there and re-run regen scripts |
| Child projects with stale `.shamt/skills/` content miss updates | Sync flow already handles `.shamt/` updates; child runs `shamt import` then regen (handled in SHAMT-40 / SHAMT-42) |
| Skill bodies bloat — agent loads too much content per session | Skills are loaded on trigger match, not all at once; bloat is bounded by per-skill body size. Set a soft target of <500 lines per SKILL.md |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-27 | Initial draft created |
| 2026-04-27 | Validated — corrected file count 27→29 in Validation Strategy; clarified Phase 6 ordering |
| 2026-04-27 | Added `.shamt/commands/CHEATSHEET.md` (CREATE) to Files Affected; added Phase 4 authoring step and Validation Strategy check; CHEATSHEET.md is the user-facing quick reference that grows across SHAMT-41 through SHAMT-45 |
| 2026-04-27 | Added audit scope note to shamt-guide-audit SKILL.md row: scope covers all of `.shamt/guides/` (all subdirs); `.shamt/commands/` is explicitly out of guide-audit scope (`.shamt/skills/` was also noted out-of-scope at this date; superseded by 2026-04-29 D-DRIFT/D-COVERAGE additions which actively inspect skill bodies). Added out-of-audit-scope note to CHEATSHEET.md row: accuracy maintained by implementation-plan update steps, not the guide audit. |
| 2026-04-28 | SHAMT-47 fold-in: Added Phase 5.5 (master repo agent persona subset); extended Phase 5 CLAUDE.md update to include master-applicable skill/persona note in Master Dev Workflow section |
| 2026-04-28 | Validation fix: Phase 5.5 persona count corrected from 6 to 5; `shamt-master-reviewer` is a skill, not a persona |
| 2026-04-28 | Validation fix (sub-agent round): added hyperlinks to companion docs in frontmatter (relative paths from `active/` to `design_docs/`) |
| 2026-04-28 | Validation fix (sub-agent round 2): Validation Strategy "After Phase 5" corrected to "After Phase 5.5" to match actual implementation plan sequencing (Phase 5.5 added in SHAMT-47 fold-in) |
| 2026-04-29 | Resolved all 3 open questions: (1) trigger format → neutral YAML list, regen translates; (2) master-reviewer location → .shamt/skills/ with master-only flag, wiring skipped on children, sync unaffected; (3) argument syntax → {name}, regen translates. Section renamed Decisions. Phase 2 and Phase 4 updated to reflect decisions. |
| 2026-04-29 | Drift/coverage sync: Phase 2 updated to require `source_guides:` frontmatter on every SKILL.md; shamt-guide-audit Files Affected row replaced with concrete D-DRIFT + D-COVERAGE dimension specs; Risks row made concrete; Skills README Notes updated with bidirectional coverage expectation; Phase 5 CLAUDE.md step extended with coverage-gap check for Design Doc Lifecycle. |
