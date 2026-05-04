# SHAMT-52: Shamt Lite Host Wiring for Cursor

**Status:** Ready for implementation (validated + all OQs resolved 2026-05-04)
**Created:** 2026-05-03
**Branch:** `feat/SHAMT-52`
**Validation Log:** [SHAMT52_VALIDATION_LOG.md](./SHAMT52_VALIDATION_LOG.md)
**Type:** Design Proposal
**Depends on:** [SHAMT-51 v2](./SHAMT51_DESIGN_v2.md) — canonical Lite content layer + `init_lite.sh --host=` flag + Proposal 8 host-agnostic XML must be in place before this doc's implementation can land.

---

## TL;DR

Cursor 3.x has full feature parity with Claude Code and Codex for the surfaces Shamt Lite cares about (`SKILL.md`, `.cursor/commands/`, `.cursor/agents/`, `.cursor/rules/*.mdc`, `.cursor/hooks.json`, `.cursor/mcp.json`). Today master has zero Cursor wiring — it's rules-file-only on the AI service registry.

This doc adds Lite host wiring for Cursor: a `regen-lite-cursor.sh` script, 5 attachment-aware `.cursor/rules/*.mdc` files, plus `--host=cursor` handling in `init_lite.sh`. Cursor sub-agent model selection is a hybrid prompt with `inherit` default (per SHAMT-51 OQ 3 resolution). `AGENTS.md` is NOT written for `--host=cursor` alone (per SHAMT-51 OQ 4 resolution); only `.cursor/rules/*.mdc` is deployed.

Hooks and MCP are deferred (Tier 3, same as SHAMT-51). The Cursor SDK and `/multitask` background agents are out of scope for Lite.

---

## Problem Statement

Cursor 3.x supports the full set of agent-extension surfaces (skills, slash commands, sub-agents, attachment-aware rules, hooks, MCP). Shamt Lite users on Cursor today get NONE of this — only the `SHAMT_LITE.md` rules file copied manually into `.cursor/rules/index.mdc` or `.cursorrules`. Validator and builder sub-agent handoff requires hand-writing Task spawns. Slash commands don't exist. Pattern-specific rules load all the time, regardless of context.

SHAMT-51 establishes the canonical Lite content layer (skills, commands, sub-agent personas) and the `init_lite.sh --host=` infrastructure. SHAMT-52 plugs Cursor into that infrastructure as a third deployment target alongside Claude Code and Codex.

**Concrete trigger:** A child project on Cursor + Lite cannot invoke `/lite-validate`, `/lite-spec`, `/lite-plan`, `/lite-review`, or `/lite-story`. The validator and builder sub-agent personas (`shamt-lite-validator`, `shamt-lite-builder`) defined in SHAMT-51 don't exist on the Cursor side. The 5 patterns in `SHAMT_LITE.md` are loaded into every Cursor chat regardless of which file the user is editing.

**Impact of not solving:** Lite-on-Cursor remains the worst-supported tier. SHAMT-51 brings Codex and Claude to feature parity; without SHAMT-52, Cursor lags behind.

---

## Goals

1. Deploy SHAMT-51's canonical Lite content (skills, slash commands, sub-agent personas) to Cursor's project-local directories.
2. Provide a Cursor `.cursor/rules/*.mdc` split that loads pattern-specific guidance only when editing pattern-specific files.
3. Implement Cursor's hybrid sub-agent model prompt (per SHAMT-51 OQ 3): `init_lite.sh --host=cursor` prompts for a cheap-tier model id with `inherit` as the default.
4. Update the AI service registry (`ai_services.md`) to mark Cursor as "full-wiring (Lite)".
5. Preserve SHAMT-51's "Lite is opt-out of master sync" property — re-running `init_lite.sh --host=cursor` is the upstream-update mechanism.

---

## Detailed Design

### Proposal 1: `regen-lite-cursor.sh` deployment script

**Description:** New script at `.shamt/scripts/regen/regen-lite-cursor.sh` (and `.ps1` for Windows). Behavior:

1. Read all `shamt-lite-*` skills from `.shamt/skills/` and copy verbatim to `<TARGET>/.cursor/skills/<name>/SKILL.md`.
2. Copy `.shamt/scripts/initialization/lite/commands/*.md` → `<TARGET>/.cursor/commands/`.
3. Copy `.shamt/scripts/initialization/lite/rules-cursor/*.mdc` → `<TARGET>/.cursor/rules/`.
4. Transform `.shamt/scripts/initialization/lite/agents/*.yaml` → `<TARGET>/.cursor/agents/<name>.md` (YAML frontmatter + body). Map `model_tier: cheap` to whatever the user provided during init (default `inherit`); read from `.shamt/host/cursor/.model_resolution.local.toml` (gitignored, written by init).
5. Skip hooks (Tier 3 — deferred).
6. Skip MCP (Tier 3 — deferred).
7. Idempotent: re-running overwrites existing deployed files; user-authored files NOT named `shamt-lite-*` or `lite-*` are untouched.

**Rationale:** Symmetric to SHAMT-51's `regen-lite-claude.sh` and `regen-lite-codex.sh`. Per-host script pattern keeps each host's deployment isolated and individually maintainable.

**Alternatives considered:**
- *(A) Extend an existing regen script* (e.g., have `regen-lite-claude.sh` also deploy to Cursor). Mixes concerns; rejected for the same reason as SHAMT-51 Phase 2.

### Proposal 2: Cursor `.cursor/rules/*.mdc` 5-file split

**Description:** Instead of dumping the entire ~600-line `SHAMT_LITE.md` into a single rule file, split into 5 attachment-aware `.mdc` files at `<TARGET>/.cursor/rules/`:

| File | Type | Content (drawn from `SHAMT_LITE.md`) | Trigger |
|---|---|---|---|
| `lite-core.mdc` | `alwaysApply: true` | Compact 5-pattern overview + Token Discipline summary (~150 lines) | Always loaded |
| `lite-spec.mdc` | `globs: stories/**/spec.md, **/ticket*.md` | Pattern 3 (Spec Protocol) full text | Auto-attached when editing spec or ticket files |
| `lite-plan.mdc` | `globs: stories/**/implementation_plan.md` | Pattern 5 (Implementation Planning) full text | Auto-attached when editing plan files |
| `lite-review.mdc` | `globs: stories/**/code_review/**, .shamt/code_reviews/**` | Pattern 4 (Code Review) full text | Auto-attached when editing review files |
| `lite-validation.mdc` | `alwaysApply: true` | Pattern 1 (Validation Loops) + Pattern 2 (Severity) — short reference | Always (validation invoked in many contexts) |

**Rationale:** Cursor's documented soft cap is 500 lines per rule. Splitting also improves agent context-relevance: when the user is editing a spec, only spec rules attach; when planning, only plan rules. Estimated reduction in default loaded context: ~70% (back-of-envelope, based on `lite-core.mdc` ≈ 150 lines + `lite-validation.mdc` ≈ 80 lines vs. full SHAMT_LITE.md ≈ 600 lines; verify during impl).

**Source of truth:** `SHAMT_LITE.md` is canonical. The `.mdc` files are derivatives — pattern-specific sections extracted with reformat. R3 below tracks the drift risk.

**No `AGENTS.md` for `--host=cursor` alone** (per SHAMT-51 OQ 4 resolution). Cursor's deployment is `.mdc`-only. When `--host=cursor,codex` is combined, `AGENTS.md` is written by the Codex flow, but Cursor doesn't depend on it.

**Alternatives considered:**
- *(A) Single `SHAMT_LITE.mdc` with `alwaysApply: true`.* Exceeds the 500-line soft cap; loads entire pattern catalog into every chat. Rejected.
- *(B) Use `AGENTS.md` for the always-on portion, `.mdc` for the auto-attached parts.* Resolved no by SHAMT-51 OQ 4 — `--host=cursor` alone uses `.mdc` only.

### Proposal 3: `init_lite.sh --host=cursor` extension

**Description:** Extend `init_lite.sh` (and `.ps1`) to handle `--host=cursor`:

1. Prompt: *"Cursor cheap-tier model id (for sub-agent personas; press Enter to use `inherit`):"* — read into `CURSOR_CHEAP_MODEL` (default `inherit`).
2. Write `.shamt/host/cursor/.model_resolution.local.toml` (gitignored) with the resolved value: `CHEAP_MODEL = "<value>"`.
3. Call `regen-lite-cursor.sh` to deploy skills, commands, agents, and `.mdc` rules.
4. Print confirmation including: *"Cursor sub-agents will use `<value>`. To change later, edit `.cursor/agents/shamt-lite-*.md` or re-run `init_lite.sh --host=cursor`."*

**Rationale:** Mirrors the model-resolution pattern from SHAMT-42 (Codex's `.model_resolution.local.toml`). Per-developer file means each teammate can have their own preferred Cursor model without git collisions.

**No symlink behavior.** Unlike `--host=claude,codex` which symlinks `CLAUDE.md` → `AGENTS.md` on Unix, Cursor's deployment is `.cursor/rules/*.mdc` and shares no file with other hosts. Combinations like `--host=cursor,codex` write `AGENTS.md` (for Codex's sake) AND `.cursor/rules/*.mdc` (for Cursor) — independently, no symlinking.

**Alternatives considered:**
- *(A) No model prompt, always default to `inherit`.* Was OQ 3 Option A; rejected during OQ 3 resolution.

### Proposal 4: AI service registry update

**Description:** Update `.shamt/scripts/initialization/ai_services.md` Cursor entry from "rules-file-only" to "full-wiring (Lite)". Note that full-Shamt-on-Cursor remains rules-file-only (out of scope for SHAMT-52; tracked as a future follow-up).

**Rationale:** The registry is the canonical source of truth for "what setup does each host get?" Once SHAMT-52 lands, Cursor users on Lite have the same one-command experience as Claude/Codex.

---

## Files Affected

**Legend:**
- `CREATE` / `MODIFY` apply to **master-stored** files (this repo).
- `DEPLOYED` files are written into the **child project tree** by `init_lite.sh` or regen scripts.

| File | Status | Notes |
|---|---|---|
| `.shamt/scripts/regen/regen-lite-cursor.sh` | CREATE | Cursor regen script (Bash) |
| `.shamt/scripts/regen/regen-lite-cursor.ps1` | CREATE | Cursor regen script (Windows) |
| `.shamt/scripts/initialization/lite/rules-cursor/lite-core.mdc` | CREATE | Always-on core rule (~150 lines) |
| `.shamt/scripts/initialization/lite/rules-cursor/lite-spec.mdc` | CREATE | Auto-attached on spec files |
| `.shamt/scripts/initialization/lite/rules-cursor/lite-plan.mdc` | CREATE | Auto-attached on plan files |
| `.shamt/scripts/initialization/lite/rules-cursor/lite-review.mdc` | CREATE | Auto-attached on review files |
| `.shamt/scripts/initialization/lite/rules-cursor/lite-validation.mdc` | CREATE | Always-on Pattern 1+2 reference |
| `.shamt/scripts/initialization/init_lite.sh` | MODIFY | Add `--host=cursor` handling, model prompt, regen call |
| `.shamt/scripts/initialization/init_lite.ps1` | MODIFY | Same on Windows |
| `.shamt/scripts/initialization/ai_services.md` | MODIFY | Cursor entry → "full-wiring (Lite)"; full-Shamt-on-Cursor remains rules-file-only |
| `.shamt/host/cursor/README.md` | CREATE | New host directory; document `.model_resolution.local.toml` schema and the no-AGENTS.md decision |
| `.shamt/host/cursor/.model_resolution.local.toml.example` | CREATE | Example model resolution file (gitignored real version written at init) |
| (deployed) `<project>/.cursor/skills/shamt-lite-*/SKILL.md` (×5) | DEPLOYED | By `regen-lite-cursor.sh` |
| (deployed) `<project>/.cursor/commands/lite-*.md` (×5) | DEPLOYED | By `regen-lite-cursor.sh` |
| (deployed) `<project>/.cursor/agents/shamt-lite-*.md` (×2) | DEPLOYED | By `regen-lite-cursor.sh` (validator + builder) |
| (deployed) `<project>/.cursor/rules/lite-*.mdc` (×5) | DEPLOYED | By `regen-lite-cursor.sh` |

---

## Implementation Plan

### Phase 0: Prerequisite check

- [ ] Confirm SHAMT-51 has landed (canonical Lite content layer + `init_lite.sh --host=` flag exist; `regen-lite-claude.sh` and `regen-lite-codex.sh` are in place; Lite skills authored in `.shamt/skills/`).
- [ ] **Spot-check Cursor 3.x paths and frontmatter** (per OQ 3 resolution — bounded scope, not a full re-research pass). Targeted WebFetch on Cursor docs to verify these specific items haven't changed since SHAMT-51's research date (2026-05-03):
  - Path constants: `.cursor/rules/`, `.cursor/skills/`, `.cursor/agents/`, `.cursor/commands/`
  - SKILL.md frontmatter keys: `paths:`, `disable-model-invocation:`, model-invocation defaults
  - `.mdc` rule frontmatter keys: `alwaysApply:`, `globs:`
  - Escalate to a full re-research pass only if any of the above looks different from the SHAMT-51 notes.

### Phase 1: Author the 5 `.mdc` rule files

- [ ] Write `lite-core.mdc` — compact 5-pattern overview + Token Discipline summary
- [ ] Write `lite-spec.mdc` — Pattern 3 (Spec Protocol) full text with `globs:` frontmatter
- [ ] Write `lite-plan.mdc` — Pattern 5 (Implementation Planning) full text
- [ ] Write `lite-review.mdc` — Pattern 4 (Code Review) full text
- [ ] Write `lite-validation.mdc` — Pattern 1 + Pattern 2 short reference, `alwaysApply: true`
- [ ] Verify each file is under Cursor's 500-line soft cap

### Phase 2: Implement `regen-lite-cursor.sh` and `.ps1`

- [ ] Bash version: skills + commands + rules + agents transformations
- [ ] Windows variant
- [ ] Idempotency check (re-running overwrites Shamt-managed files; non-Shamt-named files in `.cursor/` are untouched)
- [ ] Read `CHEAP_MODEL` from `.shamt/host/cursor/.model_resolution.local.toml`; substitute into agent files
- [ ] **Skill frontmatter injection (per OQ 1 + OQ 2 resolutions).** When deploying canonical SKILL.md files to `.cursor/skills/<name>/SKILL.md`, the regen script must inject Cursor-specific frontmatter:
  - `lite-spec` → `paths: stories/**/spec.md, **/ticket*.md`
  - `lite-plan` → `paths: stories/**/implementation_plan.md`
  - `lite-review` → `paths: stories/**/code_review.md`
  - `lite-validation` and `lite-token-discipline` → no `paths:` (always discoverable)
  - All five skills: do NOT inject `disable-model-invocation` (model-invokable by default; OQ 2).
- [ ] Append a managed header to all deployed `.mdc` files (e.g., `<!-- MANAGED by regen-lite-cursor.sh — do not hand-edit; run regen-lite-cursor.sh to refresh -->`). Mirrors the managed-header pattern used by `regen-claude-shims.sh` and `regen-codex-shims.sh`.
- [ ] Author `.shamt/host/cursor/.model_resolution.local.toml.example` showing both common values: `CHEAP_MODEL = "inherit"` (default) and `CHEAP_MODEL = "claude-haiku-4-5"` (example specific id). The committed example file is the template for the gitignored real file written at init time.

### Phase 3: Extend `init_lite.sh` for `--host=cursor`

- [ ] Add `--host=cursor` recognition in flag parser (in both `.sh` and `.ps1`)
- [ ] Prompt user for cheap-tier model id; default `inherit`
- [ ] Write `.shamt/host/cursor/.model_resolution.local.toml`
- [ ] Add `.shamt/host/cursor/.model_resolution.local.toml` to `.shamt/.gitignore` (mirrors the existing entry for the Codex resolution file)
- [ ] Call `regen-lite-cursor.sh`
- [ ] Print confirmation message with edit-later guidance

### Phase 4: Documentation

- [ ] Update `ai_services.md` Cursor entry
- [ ] Author `.shamt/host/cursor/README.md` documenting the host directory layout, `.model_resolution.local.toml` schema, and the no-AGENTS.md decision
- [ ] Update root `CLAUDE.md` Shamt Lite section with `--host=cursor` mention
- [ ] Update `SHAMT_LITE.template.md` `--host=` documentation (if SHAMT-51's update added Cursor-specific text, verify it's accurate; otherwise add)

### Phase 5: Validation

- [ ] Run guide audit on the entire `.shamt/guides/` tree (3 consecutive clean rounds, per CLAUDE.md "Critical Rules" — not just files affected by SHAMT-52)
- [ ] Run implementation validation loop (5 dimensions)
- [ ] Cross-host smoke test: same simple story works on Claude, Codex, Cursor (the test that was deferred from SHAMT-51's split-mode)

### Phase 6: PR

- [ ] Open `feat/SHAMT-52` PR
- [ ] After merge: archive SHAMT52_DESIGN.md to `design_docs/archive/`

---

## Validation Strategy

**Primary validation (this design doc):** 7-dimension validation loop. Exit: primary clean round + 2 independent Haiku sub-agent confirmations.

**Implementation validation (after code is complete):** 5-dimension validation loop. Same exit criterion.

**Testing approach:**
- Run `regen-lite-cursor.sh` on a fresh empty directory; verify all `.cursor/{skills,commands,agents,rules}/` paths populate.
- Open a `stories/test-slug/spec.md` file in Cursor; verify `lite-spec.mdc` auto-attaches (per `globs:` rule) but `lite-plan.mdc` does NOT.
- Open a `stories/test-slug/implementation_plan.md`; verify `lite-plan.mdc` attaches and `lite-spec.mdc` does not.
- Invoke `/lite-validate` from Cursor's slash menu; verify the validator skill loads.
- Spawn the validator sub-agent; verify it runs with the configured cheap-tier model (or `inherit` if user skipped the prompt).
- Cross-host smoke test (with SHAMT-51 already landed): run a simple story end-to-end on Cursor and verify outputs match Claude/Codex.

**Success criteria:**
- A child project running `init_lite.sh --host=cursor` gets the full Lite slash command surface in Cursor immediately after init.
- Default loaded context drops by ~70% relative to `SHAMT_LITE.md` always-loaded baseline (verify with token count).
- Sub-agent personas spawn with the user's chosen cheap-tier model (or `inherit`).
- The standalone `SHAMT_LITE.md` still works as a fallback for users who don't run `--host=cursor`.

---

## Open Questions

(All resolved 2026-05-04.)

1. **Cursor `paths:` frontmatter on skills.** Cursor's SKILL.md frontmatter optionally accepts `paths:` to scope a skill to specific files. Should `lite-spec`, `lite-plan`, `lite-review` skills also carry `paths:` frontmatter (mirroring the `.mdc` globs)?
   - **Resolved (2026-05-04): Yes, add `paths:`.** `lite-spec/SKILL.md` gets `paths: stories/**/spec.md, **/ticket*.md`; `lite-plan/SKILL.md` gets `paths: stories/**/implementation_plan.md`; `lite-review/SKILL.md` gets `paths: stories/**/code_review.md`. Mirrors the `.mdc` globs and makes skill discovery targeted. Implementation: encode the path lists in Phase 2 when SKILL.md frontmatter is updated for Cursor parity.

2. **Cursor `disable-model-invocation` for Lite skills.** Cursor's frontmatter supports `disable-model-invocation: true` to require explicit `/skill-name` invocation only (no automatic discovery). For Lite, do we want skills to be model-invokable (the agent decides when to use them) or only explicit?
   - **Resolved (2026-05-04): Model-invokable.** Omit `disable-model-invocation` (or set `false`) on all Lite Cursor skills. Lite users benefit from automatic skill suggestion. Implementation: Phase 2 SKILL.md frontmatter does not include the field.

3. **Re-research depth for Phase 0.** Cursor 3.x is still moving fast. Should Phase 0's re-research be a full WebFetch pass (15+ min, like the SHAMT-51 research) or a quick spot-check on the path schemas?
   - **Resolved (2026-05-04): Spot-check first.** Phase 0 does a targeted WebFetch on path schemas (`.cursor/skills/`, `.cursor/commands/`, `.cursor/rules/*.mdc`, frontmatter keys). Escalate to full re-research only if anything diverges from the SHAMT-51 research notes. Implementation: Phase 0 checklist explicitly bounds the spot-check scope.

---

## Risks & Mitigation

**R1: Cursor path/schema breaking change between SHAMT-51 research and SHAMT-52 implementation.** Cursor 3.0 → 3.2 happened in one month (April 2026). A 4.0 could rename paths.
- *Mitigation:* Phase 0 re-research is mandatory. Regen scripts isolate path constants; any rename is a one-line fix.

**R2: `.mdc` content drift from `SHAMT_LITE.md`.** `SHAMT_LITE.md` is canonical; the 5 `.mdc` files are extracted derivatives. Updates to `SHAMT_LITE.md` require parallel updates to the relevant `.mdc` files.
- *Mitigation:* Add a guide-audit dimension (or a comment in `SHAMT_LITE.md`) noting that pattern-specific sections are mirrored in `.shamt/scripts/initialization/lite/rules-cursor/`. R3 tracks this longer-term.

**R3: Optional `.mdc` regeneration script.** A future enhancement could auto-regenerate the `.mdc` files from `SHAMT_LITE.md` sections (extract Pattern N → write `lite-pattern-N.mdc`). Out of scope for SHAMT-52 v1; flagged as a future follow-up.
- *Mitigation:* Manual sync for v1. Audit dimension catches drift.

**R4: Cursor sub-agent invocation differs from Claude/Codex.** Cursor sub-agents are invoked via `/<name>` or natural language. The `SHAMT_LITE.md` standalone document references "spawn the validator" generically.
- *Mitigation:* Skill bodies use natural-language invocation ("Use the shamt-lite-validator to confirm ..."), which works on all three hosts.

**R5: User runs `--host=cursor` without Cursor installed.** Init succeeds; deployed `.cursor/` files are inert until the user opens the project in Cursor.
- *Mitigation:* Document as harmless. Same as SHAMT-51 R7 mitigation pattern.

**R6: Cursor cheap-tier model id changes upstream.** If Cursor renames `claude-haiku-4-5` to something else, deployed agent files break.
- *Mitigation:* `inherit` default avoids this entirely. Users who set a specific model id accept the breakage risk; re-running `init_lite.sh --host=cursor` lets them update.

---

## Change History

| Date | Change |
|---|---|
| 2026-05-03 | Initial draft. Extracted from SHAMT-51 OQ resolutions (split into separate design docs). |
| 2026-05-04 | OQ 1–3 resolved. Phase 0 spot-check scope bounded; Phase 2 path-list and model-invocation frontmatter rules added. |
