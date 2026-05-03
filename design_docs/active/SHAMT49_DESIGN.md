# SHAMT-49: Project-Tailored Cheat Sheet Generation

**Status:** Validated
**Created:** 2026-05-02
**Branch:** `feat/SHAMT-49`
**Validation Log:** [SHAMT49_VALIDATION_LOG.md](./SHAMT49_VALIDATION_LOG.md)

---

## Problem Statement

The canonical `CHEATSHEET.md` deployed to `.claude/commands/` is generic — it covers every host, every optional feature, and every provider simultaneously. A Claude Code user on a GitHub project with no hooks sees ADO pipeline instructions, Codex profile-switch commands, and hook behavior tables that don't apply to them. The result is noise that buries the sections that actually matter. More concretely: on a freshly initialized project, the commit format shown is `feat/SHAMT-N:` rather than `feat/FF-N:`, so users still have to mentally substitute their own epic tag.

There is currently no generated artifact that tells a user what Shamt looks like *on their specific project* with their specific configuration.

---

## Goals

1. Generate a project-specific `CHEATSHEET.md` at init time (and on every `regen` run) that contains only sections relevant to the project's current configuration
2. Substitute the project's actual epic tag (e.g. `FF`, `KAI`) throughout — in git conventions, hook descriptions, and examples
3. Filter sections by: AI service (Claude Code vs Codex vs both), PR provider (GitHub vs ADO vs both), optional features enabled (hooks, MCP), and repo type (master vs child)
4. Keep the tailored cheat sheet separate from the canonical `/CHEATSHEET` slash command — the slash command remains generic and is always available; the tailored file is the project-specific quick reference
5. Keep the cheat sheet current: regenerated on every `regen-claude-shims.sh` run so it reflects the current feature state, not just init-time state

---

## Detailed Design

### Proposal 1: Phase 5 in regen-claude-shims.sh (Recommended)

**Description:** Add a Phase 5 to `regen-claude-shims.sh` that generates `.shamt/CHEATSHEET.md`. The phase reads all available config sources (`.shamt/config/*.conf`, `.claude/settings.json`), then builds a filtered markdown file. Generation is done via an inline Python3 script (consistent with Phase 2 agent transform and Phase 4 hooks registration).

**Output location:** `.shamt/CHEATSHEET.md` — gitignored, regenerated on every regen run. Placed inside `.shamt/` so it doesn't add a file to the project root.

**Epic tag source:** `init.sh` writes `.shamt/config/epic_tag.conf` (e.g. `FF`) alongside the existing `ai_service.conf` and `repo_type.conf`. The regen script reads it to substitute the real tag throughout the cheat sheet. This requires a one-line addition to `init.sh` and `init.ps1`.

**Sections and filtering rules:**

| Section | Included when |
|---------|--------------|
| Git conventions | Always — substitutes actual epic tag |
| Slash commands | Always — filters out `/shamt-promote` on child repos |
| Validation rules | Always |
| Stage flow (abbreviated) | Always — filters out S11 Export section on master repo |
| Key personas | Always — filters out child-only personas on master, master-only on child |
| Active enforcement hooks | Only when `features.shamt_hooks=true` in `.claude/settings.json` |
| MCP tools | Only when `mcpServers.shamt` present in `.claude/settings.json` |
| Codex-specific tips | Only when `ai_service.conf` contains `codex` |
| Claude Code tips | Only when `ai_service.conf` contains `claude` |
| ADO CI / ADO PR review (ADO MCP) | Only when `pr_provider.conf` contains `ado` — "ADO MCP" refers to Azure DevOps MCP integration for interactive PR review (documented in canonical CHEATSHEET.md) |
| GitHub CI | Only when `pr_provider.conf` contains `github` or is absent |

**Rationale:** Python inline script is the right tool — it needs to read JSON (settings.json) and multiple text files, then produce conditional output. Bash would be fragile for this. Inline in regen keeps everything in one script, matching the existing pattern. The output is short (~60–120 lines depending on enabled features) so maintenance is straightforward.

**Alternatives considered:**

- **Section-marker stripping on the canonical CHEATSHEET.md:** Add `<!-- SECTION: hooks -->` markers to the canonical file and strip non-applicable sections. Rejected: the canonical file is deployed verbatim to `.claude/commands/` — adding markers would pollute the slash command output for all users.
- **Separate template files per section in `.shamt/scripts/regen/cheatsheet/`:** Assembly script concatenates applicable section files. Rejected: adds several new files for what is ultimately string assembly logic; inline Python is simpler and already the established pattern in regen.
- **Generate only at init time, not regen:** Simpler, but means the cheat sheet goes stale if the user later enables hooks or MCP. Rejected.

---

**Recommended approach:** Proposal 1.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/scripts/regen/regen-claude-shims.sh` | MODIFY | Add Phase 5: read config, generate `.shamt/CHEATSHEET.md` |
| `.shamt/scripts/regen/regen-codex-shims.sh` | MODIFY | Add Phase 5 (parity): generate `.shamt/CHEATSHEET.md` for Codex-only projects. For dual-host (`claude_codex`) both regen scripts run and produce identical output from the same config files, so the second write is harmless. |
| `.shamt/.gitignore` | CREATE | Written by regen Phase 5; contains `CHEATSHEET.md` to gitignore the generated file in projects that track `.shamt/` |
| `.shamt/scripts/initialization/init.sh` | MODIFY | Write `epic_tag.conf` to `.shamt/config/` after collecting epic tag from user |
| `.shamt/scripts/initialization/init.ps1` | MODIFY | Parity: write `epic_tag.conf` |

---

## Implementation Plan

### Phase 1: Write epic_tag.conf during init

`regen-claude-shims.sh` needs the epic tag to substitute into the cheat sheet. The epic tag is collected interactively during init but currently only written to `init_config.md`.

- [ ] In `init.sh`, after the epic tag is collected into `$EPIC_TAG`, add: `echo "$EPIC_TAG" > "$SHAMT_DIR/config/epic_tag.conf"`
- [ ] In `init.ps1`, after the epic tag is collected, add the equivalent: `Set-Content "$ShamtDir\config\epic_tag.conf" $EpicTag`
- [ ] Verify the conf file is written alongside `ai_service.conf` and `repo_type.conf`

### Phase 2: Add Phase 5 to regen-claude-shims.sh

- [ ] Add a `Phase 5: Tailored cheat sheet` section after Phase 4 in the regen script
- [ ] Read config sources: `epic_tag.conf` (default `SHAMT-N` if absent — the cheat sheet is still generated and remains useful with the placeholder tag on projects initialized before SHAMT-49) and the three pre-existing conf files written by `init.sh` — `ai_service.conf`, `repo_type.conf`, and `pr_provider.conf` (default `github` if absent) — plus `.claude/settings.json`
- [ ] Generate `.shamt/CHEATSHEET.md` using an inline Python3 heredoc that applies the filtering rules in the table above
- [ ] Include a generated header: `<!-- Generated by Shamt regen — do not edit. Run regen-claude-shims.sh (or regen-codex-shims.sh) to update. -->`
- [ ] Write `.shamt/.gitignore` containing `CHEATSHEET.md` unconditionally — git respects nested `.gitignore` files regardless of whether the parent `.shamt/` directory is already excluded at the repo level (if it is, the nested file is a harmless no-op; if `.shamt/` is tracked, the nested file ensures `CHEATSHEET.md` is excluded without touching the repo-level `.gitignore`)
- [ ] Print status line: `Cheat sheet: generated (.shamt/CHEATSHEET.md)`
- [ ] If `settings.json` is missing or malformed, fall back gracefully (treat all optional features as disabled) and print a warning line: `⚠  settings.json missing or malformed — optional features disabled in cheat sheet`

### Phase 3: Parity in regen-codex-shims.sh (minimal)

The Codex regen script doesn't write `settings.json`, but it has access to the same config files. For Codex-only projects, the cheat sheet should still be generated. `regen-codex-shims.sh` does not run for `claude_code` projects, so adding Phase 5 there is safe and will not affect Claude Code projects.

- [ ] Add Phase 5 to `regen-codex-shims.sh` by copying the Phase 2 inline Python3 script verbatim, then wrapping the `json.load(settings_json)` call in a try/except that catches `FileNotFoundError` and `json.JSONDecodeError` — both cases default `hooks_enabled` and `mcp_enabled` to `False` (Codex-only projects have no `.claude/settings.json`, so `FileNotFoundError` is the normal path, not an error condition) — no other changes needed

### Phase 4: Verify end-to-end

- [ ] Run regen on a Claude Code + GitHub + hooks + MCP project; confirm `.shamt/CHEATSHEET.md` contains hooks table, MCP tools, GitHub CI section, and the real epic tag throughout
- [ ] Run regen on a fresh project with no optional features; confirm ADO, Codex, hooks, and MCP sections are absent
- [ ] Manually disable hooks (set `features.shamt_hooks=false`), re-run regen; confirm hooks section disappears
- [ ] Confirm the canonical `.claude/commands/CHEATSHEET.md` is unchanged (generic)

---

## Validation Strategy

- Run design doc validation loop (7 dimensions) to primary clean round (≤1 LOW-severity issue) + 2 independent Haiku sub-agent confirmations
- After implementation, run implementation validation (5 dimensions) to the same exit criterion
- Manual verification per Phase 4 steps constitutes the testing approach

---

## Open Questions

None — all resolved.

1. **Codex dual-host** ✓ — For `ai_service=claude_codex`, both Claude Code and Codex sections are included (filter on *contains* `claude` / *contains* `codex`). Confirmed correct.

2. **MCP detection fallback** ✓ — Treat MCP as disabled when `settings.json` is absent (Codex-only projects). Confirmed correct.

---

## Risks & Mitigation

| Risk | Mitigation |
|------|-----------|
| `settings.json` is malformed JSON (user edited it) | Wrap `json.load()` in try/except; treat all optional features as disabled on parse failure; print a warning line |
| `epic_tag.conf` missing on projects initialized before SHAMT-49 | Default to the string `SHAMT-N` as the tag placeholder; cheat sheet is still useful, just not substituted |
| Phase 5 inline Python heredoc grows unwieldy as more sections are added | The cheat sheet content is intentionally shorter than the canonical CHEATSHEET.md (~100 lines max); if it grows past ~200 lines of Python string, extract to a separate helper script |
| Regen running on master repo generates a cheat sheet with master-only sections | Already handled by the `repo_type.conf` filter; master gets `/shamt-promote`, child does not |
| Shamt Lite projects (`init_lite.sh`) have no `epic_tag.conf` | `init_lite.sh` does not collect an epic tag; the fallback (default to `SHAMT-N`) applies; the cheat sheet is still generated but tag substitution is inactive |
| SHAMT-48 also modifies `init.sh` and `init.ps1` (reorders settings.json/regen + adds feature prompts in the Claude Code wiring section) | Changes are orthogonal — different sections of the script, no conflict. Implement in either order or as separate PRs; no coordination needed beyond awareness. |

---

## Change History

| Date | Change |
|------|--------|
| 2026-05-02 | Initial draft created |
