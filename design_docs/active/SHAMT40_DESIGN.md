# SHAMT-40: Claude Code Host Wiring — Init Extension and Regen Scripts

**Status:** Validated
**Created:** 2026-04-27
**Branch:** `feat/SHAMT-40`
**Validation Log:** [SHAMT40_VALIDATION_LOG.md](./SHAMT40_VALIDATION_LOG.md)
**Depends on:** SHAMT-39 (canonical content must exist before it can be wired)
**Companion docs:** `CLAUDE_INTEGRATION_THEORIES.md`, `FUTURE_ARCHITECTURE_OVERVIEW.md`

---

## Problem Statement

After SHAMT-39 lands, `.shamt/skills/`, `.shamt/agents/`, `.shamt/commands/` exist as canonical content but no host actually loads them — Claude Code reads from `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, and `.claude/settings.json`. Without a wiring layer, the SHAMT-39 content is inert. Children that run `shamt import` see new content arrive in `.shamt/` but no behavior change.

This design doc adds the bridge: an init-script extension that detects "Claude Code" as the host and writes the host-specific shim files, plus a regen script that refreshes those shims after every `shamt import`. After this design lands, a Shamt-on-Claude-Code child project gains skills, sub-agent personas, and slash commands as first-class harness behavior. This validates Claude doc Experiment A — the skills bundle running through a real S2.P1.I3 spec validation.

The Codex equivalent of this work lands separately in SHAMT-42; this doc focuses exclusively on Claude Code so the work can ship and be validated in isolation.

---

## Goals

1. Extend the existing `init.sh` / `init.ps1` scripts so they detect Claude Code as the chosen AI service and execute the additional host-wiring steps without disturbing other AI service paths.
2. Author a `regen-claude-shims.sh` script that materializes `.claude/skills/`, `.claude/agents/`, `.claude/commands/` from canonical `.shamt/` content.
3. Provide a starter `.claude/settings.json` template that wires statusLine and (placeholder) hooks/MCP fields so SHAMT-41 can plug in without rewriting the file.
4. Update `import.sh` (or equivalent) to invoke the regen script automatically after a successful import, ensuring shims stay current.
5. Update `ai_services.md` with a new "wiring tier" column distinguishing rules-file-only services from full-wiring services.
6. Validate Claude doc Experiment A: a real S2.P1.I3 spec validation runs through the wired skill bundle with measurable token / round savings vs. baseline.

---

## Detailed Design

### Proposal 1: Init-script branch by AI service detection

**Description:** `init.sh` already detects/asks about the AI service (Claude Code, Cursor, etc.) and writes the appropriate rules file. Extend the same decision point: when `AI_SERVICE=claude-code`, additionally:

1. Create `.claude/` directory tree (`skills/`, `agents/`, `commands/`).
2. Run `regen-claude-shims.sh` to populate them from `.shamt/`.
3. Copy `.shamt/host/claude/settings.starter.json` to `.claude/settings.json` with placeholders resolved (project path, statusLine script path).
4. Add the project to the user's Claude Code trust list if a config-management primitive supports it; otherwise emit a one-line instruction the user runs.

For all other AI services, current behavior is unchanged — `init.sh` writes the rules file and stops. `ai_services.md` records which service is "full-wiring" (Claude Code today, Codex after SHAMT-42) and which is "rules-file-only" (everything else).

**Rationale:** Keeps the host-aware work scoped to a single decision branch the script already has. Existing AI services (Cursor, generic) are unaffected. The starter `.claude/settings.json` is written once at init; subsequent syncs do not touch it (per the architecture's "user owns settings.json after init" principle).

**Alternatives considered:**
- *Separate `init-claude-code.sh` script invoked after `init.sh`:* Splits the workflow and makes the host-aware step optional, which would let users miss it. Single-script branch keeps the right defaults. Rejected.
- *Always write `.claude/` regardless of detected host:* Pollutes projects that don't use Claude Code. Rejected.

### Proposal 2: `regen-claude-shims.sh` as a deterministic transform

**Description:** A bash script that walks `.shamt/skills/`, `.shamt/agents/`, `.shamt/commands/` and writes Claude Code-shaped equivalents under `.claude/`. Key behaviors:

- **Skills:** Each `.shamt/skills/<name>/SKILL.md` becomes `.claude/skills/<name>/SKILL.md`. The neutral frontmatter `triggers:` is preserved (Claude Code reads it directly). A "managed by Shamt — do not edit" header is prepended.
- **Agents:** Each `.shamt/agents/<name>.yaml` is transformed to `.claude/agents/<name>.md` with frontmatter (`name`, `description`, `tools`, `model`) and a body that's the persona's prompt_template. The `model_tier` translates per the mapping in `.shamt/agents/README.md` (cheap=haiku, balanced=sonnet, reasoning=opus).
- **Commands:** Each `.shamt/commands/<name>.md` becomes `.claude/commands/<name>.md` with the body preserved and a "managed by Shamt" header. `{placeholder}` syntax is unchanged (Claude Code's command argument syntax matches).
- **Master-only filter:** Skills with `master-only: true` frontmatter are skipped on child projects.
- **Idempotence:** Running the script multiple times produces the same output. Existing files in `.claude/skills/`, `.claude/agents/`, `.claude/commands/` that don't have the "managed by Shamt" header are preserved (user may have authored their own).

**Rationale:** A single transform script is simpler than per-shim authoring. Idempotence and the managed-header convention let the script run on every `shamt import` without losing user-authored content.

**Alternatives considered:**
- *Symlinks instead of generated files:* Symlinks break on Windows by default (and SHAMT-40 needs cross-platform support since `init.ps1` exists). Generated files are portable. Rejected.
- *Authoring directly in `.claude/`:* Couples canonical content to Claude Code's format and breaks the dual-host story landing in SHAMT-42. Rejected.
- *Make regen part of `init.sh` only:* Then post-import changes don't propagate. Rejected.

### Proposal 3: Starter `settings.json` with reserved placeholders

**Description:** `.shamt/host/claude/settings.starter.json` contains a Claude Code settings.json with three reserved sections:

```json
{
  "statusLine": {
    "type": "command",
    "command": "${PROJECT}/.shamt/scripts/statusline/shamt-statusline.sh"
  },
  "hooks": {},
  "mcpServers": {},
  "_shamt_managed_blocks": ["statusLine"]
}
```

Init resolves `${PROJECT}` at write time. The empty `hooks: {}` and `mcpServers: {}` blocks are placeholders that SHAMT-41 fills in (and the user can also add their own). The `_shamt_managed_blocks` field tracks which top-level keys Shamt is allowed to update on subsequent operations (statusLine in this design; hooks and mcpServers added in SHAMT-41).

**Rationale:** Reserves space for future Shamt-managed blocks without forcing future work to surgically edit user-owned JSON. The `_shamt_managed_blocks` array makes the contract explicit.

**Alternatives considered:**
- *Write a complete settings.json including hooks now:* Hooks land in SHAMT-41 — separating concerns is cleaner. Rejected.
- *No starter file; user creates settings.json themselves:* Loses the statusLine wiring and forces every user through manual setup. Rejected.

### Recommended approach

All three proposals together: init detects Claude Code, runs regen script, writes starter settings.json with reserved blocks. Import script invokes regen post-import. ai_services.md gets a wiring tier column.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/scripts/initialization/init.sh` | MODIFY | Add Claude Code branch: regen + settings.json writer |
| `.shamt/scripts/initialization/init.ps1` | MODIFY | Same as init.sh, PowerShell port |
| `.shamt/scripts/regen/regen-claude-shims.sh` | CREATE | Transform `.shamt/{skills,agents,commands}/` → `.claude/{skills,agents,commands}/` |
| `.shamt/scripts/regen/regen-claude-shims.ps1` | CREATE | PowerShell port |
| `.shamt/scripts/regen/README.md` | CREATE | Document the transform conventions and managed-header pattern |
| `.shamt/scripts/statusline/shamt-statusline.sh` | CREATE | Renders epic / stage / blocker line; reads .shamt/epics/<active>/AGENT_STATUS.md |
| `.shamt/host/claude/settings.starter.json` | CREATE | Starter `.claude/settings.json` with reserved blocks |
| `.shamt/host/claude/README.md` | CREATE | Document the host-wiring layout |
| `.shamt/scripts/import/import.sh` | MODIFY | Invoke regen after successful import (Claude Code branch) |
| `.shamt/scripts/initialization/ai_services.md` | MODIFY | Add "wiring tier" column; mark Claude Code as "full-wiring" |
| `.shamt/commands/CHEATSHEET.md` | PASSTHROUGH (via regen) | Deployed verbatim (no argument-substitution) to `.claude/commands/CHEATSHEET.md` by `regen-claude-shims.sh`; managed-header prepended. Content is authored in SHAMT-39 and updated in SHAMT-41, 43, 44, 45. |
| `CLAUDE.md` | MODIFY | Document the Claude Code wiring story under a new section |

---

## Implementation Plan

### Phase 1: Regen script
- [ ] Author `regen-claude-shims.sh` performing the three transforms (skills, agents, commands).
- [ ] Implement managed-header detection (preserve user files lacking the header).
- [ ] Implement `master-only` skill filter (skip on child projects).
- [ ] Author the PowerShell port for Windows parity.
- [ ] Author `.shamt/scripts/regen/README.md` documenting the transform and managed-header convention.
- [ ] Test regen idempotence: run twice, diff should be empty.

### Phase 2: Status line script
- [ ] Author `shamt-statusline.sh` reading `.shamt/epics/<active>/AGENT_STATUS.md`.
- [ ] Output format: `SHAMT-{N} | S{stage}.P{phase} | round {N} | blocker: {blocker_text or "none"}`.
- [ ] Handle no-active-epic case gracefully (display project name only).

### Phase 3: Starter settings.json + host directory
- [ ] Author `.shamt/host/claude/settings.starter.json` with statusLine, empty hooks, empty mcpServers, _shamt_managed_blocks.
- [ ] Author `.shamt/host/claude/README.md` describing what's in this directory and how it's consumed by init.

### Phase 4: Init script extension
- [ ] Add Claude Code branch to `init.sh`: create `.claude/` tree, run regen, copy starter settings.json with `${PROJECT}` resolved.
- [ ] Handle pre-existing `.claude/settings.json`: detect its presence; if Shamt-managed blocks are absent, merge them in; if a safe merge is not possible, print a clear instruction for the user to merge manually.
- [ ] Mirror the change in `init.ps1`.
- [ ] Print a one-line trust-list reminder if Claude Code config doesn't auto-trust the project.

### Phase 5: Import script extension
- [ ] Add post-import hook in `import.sh`: if Claude Code is the detected host, run regen script.
- [ ] Mirror in PowerShell.

### Phase 6: AI services registry update
- [ ] Add "wiring_tier" column to `ai_services.md`. Values: "rules-file-only" or "full-wiring".
- [ ] Mark Claude Code as "full-wiring".
- [ ] All other entries remain "rules-file-only" until SHAMT-42 lands.

### Phase 7: CLAUDE.md update
- [ ] Add section "Claude Code Host Wiring (SHAMT-40)" describing the init flow, regen script, settings.json reserved blocks.
- [ ] Note that Codex equivalent lands in SHAMT-42.

### Phase 8: Validation — Claude doc Experiment A
- [ ] On a test child project, run init with Claude Code selected.
- [ ] Verify `.claude/skills/`, `.claude/agents/`, `.claude/commands/` populate correctly.
- [ ] Run a real S2.P1.I3 spec validation using the `shamt-validation-loop` skill and `shamt-validator` sub-agent.
- [ ] Measure: tokens used, rounds-to-exit, qualitative agent prose around bookkeeping.
- [ ] Compare against pre-SHAMT-40 baseline (validation done via prose-only protocol).
- [ ] Pass criterion: ≥30% token reduction on validation phase, fewer-or-equal rounds, visible drop in agent's bookkeeping prose.

### Phase 9: Implementation validation
- [ ] Run implementation validation loop (5 dimensions) on this design doc.
- [ ] Run full guide audit on `.shamt/guides/` (3 clean rounds).

---

## Validation Strategy

- **Primary validation:** Design doc validation loop on this doc.
- **Implementation validation:** Verify all files in "Files Affected" were created/modified per spec.
- **Empirical validation (Experiment A):** Run a real S2.P1.I3 spec validation on a test child project; measure token / round savings vs. baseline.
- **Regression check:** Existing children that don't pick Claude Code should be unaffected. Test by running init with `AI_SERVICE=cursor` and verifying `.claude/` is not created.
- **Idempotence:** Run regen twice, verify empty diff.
- **Success criteria:**
  1. Running init in a fresh repo with Claude Code selected produces a working `.claude/` setup with shims and settings.json.
  2. Running `shamt import` with new content in master triggers regen automatically.
  3. The shamt-statusline.sh script renders correctly when an active epic exists.
  4. Experiment A passes: ≥30% token reduction, fewer-or-equal rounds.

---

## Open Questions

1. **Trust list automation:** Can the init script add a project to Claude Code's trust list programmatically, or does the user have to do it? **Recommendation:** Try to do it programmatically; if Claude Code's config schema doesn't support write-from-script, print a clear instruction.
2. **Cross-platform line endings in regen output:** Windows users may see CRLF in generated `.claude/skills/` files. Decide whether regen normalizes to LF (recommended) or follows host platform conventions.
3. **`_shamt_managed_blocks` semantics:** Should subsequent design docs (SHAMT-41) update this field, or is the user expected to edit it manually when they accept new Shamt-managed sections? **Recommendation:** SHAMT-41's hook-installer step updates the array via JSON merge; document the convention in `.shamt/host/claude/README.md`.

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Regen script overwrites user-authored skills | Managed-header check; user files without the header are preserved |
| Init detects host wrongly | Confirm with user via prompt before writing `.claude/`; allow override |
| Symlink confusion on Windows | Generated files (not symlinks); regen is the sync mechanism |
| `.claude/settings.json` already exists at init time | Detect; either merge (if our blocks not present) or print "manual setup needed" |
| Trust list registration silently fails | Init prints a verification step; user runs it once to confirm |
| Experiment A fails | The hypothesis is that skills + sub-agents save tokens; if not, the issue is the validation-loop protocol itself, not the wiring. Diagnostic plan: run with prose-protocol-in-context vs. skill-in-context, isolate the variable |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-27 | Initial draft created |
| 2026-04-27 | Validated — added explicit Phase 4 step for pre-existing settings.json handling |
| 2026-04-27 | Added CHEATSHEET.md passthrough entry to Files Affected; regen deploys it verbatim to `.claude/commands/CHEATSHEET.md` alongside all other command files |
