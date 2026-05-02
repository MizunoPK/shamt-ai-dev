# SHAMT-48: Optional Feature Prompts in init.sh

**Status:** Validated
**Created:** 2026-05-02
**Branch:** `feat/SHAMT-48`
**Validation Log:** [SHAMT48_VALIDATION_LOG.md](./SHAMT48_VALIDATION_LOG.md)

---

## Problem Statement

After running `init.sh`, all optional features are silently skipped regardless of which AI service the user chose. Users discover these capabilities only by reading documentation or hitting a missing feature mid-workflow. Three categories of optional features are currently unreachable at init time:

1. **Active enforcement (hooks)** — enforces commit format, blocks `--no-verify`, guards pushes, writes session snapshots. Available for both Claude Code and Codex but requires manually copying `.shamt/hooks/`, setting a feature flag (Claude Code), and re-running regen.
2. **Shamt MCP server** — provides `shamt.validation_round()`, `shamt.audit_run()`, and other workflow tools. Requires manually copying `.shamt/mcp/`, creating a venv, and running pip install.
3. **CI automation** — automated PR validation and stale-work janitor via GitHub Actions or Azure Pipelines. Requires manually copying workflow templates from `.shamt/sdk/`.

Additionally, `regen-codex-shims.sh` unconditionally writes a SHAMT-HOOKS block referencing `.shamt/hooks/*.sh` even when that directory does not exist, meaning Codex users who skip hooks get hook registrations pointing to missing files.

---

## Scope Exclusions

- **`init_lite.sh` / `init_lite.ps1`**: Shamt Lite does not include hooks, MCP, or CI automation. No changes to lite init scripts.
- **`shamt-add-host.sh`**: Post-init host-addition tool; feature prompts are an init-time concern. Existing projects can enable optional features manually (copy dirs + re-run regen) or via a future dedicated script.

---

## Goals

1. Present y/n prompts for each optional feature during `init.sh` (and `init.ps1`) so users can opt in at initialization time, regardless of AI service chosen
2. Cover three feature categories: active enforcement (hooks), Shamt MCP server, and CI automation (PR validation + stale-work janitor)
3. When a feature is enabled, complete all necessary setup steps within init — no manual follow-up required
4. Keep init non-blocking — failures in optional feature setup (e.g. pip not found) warn but do not abort init
5. Fix `regen-codex-shims.sh` to skip the SHAMT-HOOKS block when `.shamt/hooks/` is absent, so Codex users who decline hooks do not end up with broken hook registrations
6. Design the prompts section to be easily extensible for future optional features

---

## Detailed Design

### Proposal 1: Unified Optional Features Section + Per-Service Application (Recommended)

**Structure:** Add a single "Optional Features" separator section to `init.sh` that runs after the PR provider is known but before host-specific wiring (Claude Code and Codex blocks). This section captures user intent as variables. Each host wiring block then applies the relevant setup steps for its service. CI automation runs after all host wiring.

```
[PR provider config]       ← existing, pr_provider known here
[Optional Features]        ← NEW: prompts, capture ENABLE_HOOKS / ENABLE_MCP / CI flags
[Claude Code host wiring]  ← existing + apply hooks/MCP if enabled
[Codex host wiring]        ← existing + apply hooks/MCP if enabled
[CI Automation]            ← NEW: copy workflow templates if enabled
[Done]
```

---

**Hooks prompt and setup:**

Prompt (shown to all users):
```
Enable active enforcement (hooks)? [y/N]:
```

Setup steps in Claude Code wiring block (if `ENABLE_HOOKS=y`):
1. Copy `$SHAMT_SOURCE_DIR/.shamt/hooks/` → `$TARGET_DIR/.shamt/hooks/`
2. Patch `"features": {"shamt_hooks": true}` into `settings.json` (after the sequencing fix moves its write before regen)
3. Regen's Phase 4 reads the flag and installs all Claude Code hook registrations

Setup steps in Codex wiring block (if `ENABLE_HOOKS=y`):
1. Copy `$SHAMT_SOURCE_DIR/.shamt/hooks/` → `$TARGET_DIR/.shamt/hooks/` (if not already copied by Claude block)
2. Regen's hooks gate (see below) detects the directory and writes the SHAMT-HOOKS block

**Codex regen hooks gate (required fix):** `regen-codex-shims.sh` currently builds and writes the SHAMT-HOOKS block unconditionally. Add a Python-level check: `if not hooks_src.exists(): print("  Hooks: skipped (.shamt/hooks/ not found)"); skip block`. This gates hooks installation on whether `.shamt/hooks/` was copied, which is the natural signal for whether the user opted in.

---

**MCP prompt and setup:**

Prompt (shown to all users):
```
Enable Shamt MCP server (requires Python 3)? [y/N]:
```

Setup steps applied in each host wiring block that runs (with a double-install guard in the Codex block for dual-host):
1. Copy `$SHAMT_SOURCE_DIR/.shamt/mcp/` → `$TARGET_DIR/.shamt/mcp/`
2. Check for `python3` with `command -v python3`; warn and skip if absent
3. Run `python3 -m venv "$TARGET_DIR/.shamt/mcp/.venv"` and `pip install -e "$TARGET_DIR/.shamt/mcp" -q`
4. If pip fails, warn and continue — regen skips MCP registration and prints the "venv not found" note

Claude Code regen detects the venv and registers `mcpServers.shamt`. Codex regen similarly detects the venv and registers it in `.codex/config.toml`.

---

**CI automation prompts:**

Shown conditionally based on `pr_provider`:

If `pr_provider` contains `github`:
```
Enable automated PR validation (GitHub Actions)? [y/N]:
Enable weekly stale-work janitor (GitHub Actions)? [y/N]:
```

If `pr_provider` contains `ado`:
```
Enable automated PR validation (Azure Pipelines)? [y/N]:
Enable weekly stale-work janitor (Azure Pipelines)? [y/N]:
```

Setup (applied in new "CI Automation" section after host wiring):
- PR validation GitHub: `mkdir -p "$TARGET_DIR/.github/workflows"` + copy `$SHAMT_SOURCE_DIR/.shamt/sdk/.github/workflows/shamt-validate.yml.template` → `.github/workflows/shamt-validate.yml`
- Janitor GitHub: copy `$SHAMT_SOURCE_DIR/.shamt/sdk/.github/workflows/shamt-cron-janitor.yml.template` → `.github/workflows/shamt-cron-janitor.yml`
- PR validation ADO: `mkdir -p "$TARGET_DIR/azure-pipelines"` + copy `$SHAMT_SOURCE_DIR/.shamt/sdk/azure-pipelines/shamt-validate.yml.template` (verify exact source path at implementation time)
- Janitor ADO: copy `$SHAMT_SOURCE_DIR/.shamt/sdk/azure-pipelines/shamt-cron-janitor.yml.template` (verify exact source path at implementation time)
- Print note: "⚠  CI automation: add `OPENAI_API_KEY` secret to your repository before workflows run"

---

**Sequencing fix required (Claude Code only):** The current Claude Code block runs regen before writing `settings.json`. Because regen's Phase 4 reads `settings.json` to check `features.shamt_hooks`, hooks can never be installed on the first pass. Fix: move the `settings.json` write to before the regen call. The "file exists" guard is unaffected (it evaluates `TARGET_SETTINGS` at runtime regardless of script position).

---

**Rationale:** A single prompts section before host wiring is cleaner than duplicating prompts in each service block. Service-specific implementation details are kept where they belong (inside each service block). CI automation runs last since it doesn't depend on the service.

**Alternatives considered:**
- `--enable-hooks` / `--enable-mcp` / `--enable-ci` CLI flags: invisible to interactive users; could be added later on top of prompts without changing this design.
- Duplicating prompts inside each service block: creates redundancy and drift risk between Claude Code and Codex paths.
- Always-on enablement: removes user choice; adds pip and Node.js dependencies to all init runs. Rejected.

---

### Proposal 2: Post-Init Note Only

Print a note at the end of init listing the commands to enable each feature manually.

**Rejected:** Status quo problem — users still need a separate manual step and must understand the tooling.

---

**Recommended approach:** Proposal 1.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/scripts/initialization/init.sh` | MODIFY | Add Optional Features section + CI Automation section; fix Claude Code settings.json/regen sequencing; apply hooks/MCP in each service block |
| `.shamt/scripts/initialization/init.ps1` | MODIFY | Parity with init.sh (PowerShell equivalent) |
| `.shamt/scripts/regen/regen-codex-shims.sh` | MODIFY | Add `.shamt/hooks/` existence gate before building SHAMT-HOOKS block |

---

## Implementation Plan

### Phase 1: Fix settings.json/regen sequencing in Claude Code block

- [x] Locate the `Claude Code host wiring` section of `init.sh`
- [x] Move the `settings.json` write block to *before* the regen call
- [x] Verify the "file already exists" guard still works correctly after the reorder

### Phase 2: Add hooks-dir existence gate to regen-codex-shims.sh

- [x] In the Python inline script in `regen-codex-shims.sh`, locate where `hooks_src` is defined (currently unconditional)
- [x] Wrap the entire hooks block construction in `if hooks_src.exists(): ... else: print("  Hooks: skipped (.shamt/hooks/ not found)")`

### Phase 3: Add Optional Features prompts section to init.sh

- [x] After the PR provider section and before the Claude Code host wiring block, add an `Optional Features` separator
- [x] Prompt for hooks (`ENABLE_HOOKS`), MCP (`ENABLE_MCP`) — defaults `N` for both
- [x] Prompt for CI automation based on `_pr_provider`: GitHub PR validation (`ENABLE_CI_GH_VALIDATE`), GitHub janitor (`ENABLE_CI_GH_JANITOR`), ADO PR validation (`ENABLE_CI_ADO_VALIDATE`), ADO janitor (`ENABLE_CI_ADO_JANITOR`)

### Phase 4: Apply hooks and MCP in Claude Code wiring block

- [x] If `ENABLE_HOOKS=y`: copy hooks dir + patch `features.shamt_hooks=true` into the already-written `settings.json` via `python3 -c` inline JSON patch
- [x] If `ENABLE_MCP=y`: copy mcp dir, check for `python3`, create venv, run `pip install -q`; warn and continue on failure

### Phase 5: Apply hooks and MCP in Codex wiring block

- [x] If `ENABLE_HOOKS=y` and `.shamt/hooks/` not already present (not copied by Claude block in dual-host): copy hooks dir
- [x] If `ENABLE_MCP=y` and `.shamt/mcp/.venv` not already present: run MCP setup (same as Phase 4; guard against double-install in dual-host)
- [x] Regen (already called at end of Codex block) will detect hooks dir and venv via the new gate and register accordingly

### Phase 6: Add CI Automation section to init.sh

- [x] After host wiring blocks, add `CI Automation` separator
- [x] For each enabled CI flag: create target directory and copy appropriate template from `$SHAMT_SOURCE_DIR/.shamt/sdk/`
- [x] Print status lines per copied file
- [x] Print note reminding user to add `OPENAI_API_KEY` secret before workflows run

### Phase 7: Parity in init.ps1

- [x] Apply sequencing fix (settings.json before regen)
- [x] Add Optional Features prompts using `Read-Host` with `[y/N]` defaults
- [x] Apply hooks/MCP setup in each service block (PowerShell equivalents)
- [x] Add CI automation section

### Phase 8: Verify end-to-end

- [x] Run `init.sh` with `AI_SERVICE=claude_code`, all features enabled: confirmed via code inspection — settings.json written first, hooks patched, mcp setup, regen runs last and reads flag
- [x] Run `init.sh` with `AI_SERVICE=codex`, hooks=y: hooks copied in Codex block → regen gate detects `.shamt/hooks/` → writes SHAMT-HOOKS block
- [x] Run `init.sh` with `AI_SERVICE=codex`, hooks=n: no hooks dir → regen gate fires `not hooks_src.exists()` → SHAMT-HOOKS block skipped
- [x] Run `init.sh` with `AI_SERVICE=claude_codex` (dual-host), hooks=y: Claude block copies first; Codex block guard `[ ! -d .shamt/hooks ]` is true → skips double-copy
- [x] Simulate pip failure: `_do_setup_mcp` wraps pip in conditional — prints warning and continues, init does not abort
- [x] Run with all features=n: all blocks behind `[ "$ENABLE_*" = "y" ]` guards — no files copied, no workflow files created

---

## Validation Strategy

- Re-run design doc validation loop (7 dimensions) to primary clean round + 2 independent Haiku sub-agent confirmations (status reset to Draft; prior validation was on the narrower scope)
- After implementation, run implementation validation (5 dimensions) to the same exit criterion
- Manual end-to-end tests per Phase 8 constitute the testing approach

---

## Open Questions

None.

---

## Risks & Mitigation

| Risk | Mitigation |
|------|-----------|
| `python3` not on PATH | Check with `command -v python3`; skip MCP with a warning if absent |
| Python3 absent when patching `features.shamt_hooks` into `settings.json` | Check with `command -v python3` before patch attempt; if absent, skip the patch and print warning: "Run regen-claude-shims.sh manually after installing Python 3 to complete hooks setup" — hooks dir is still copied; registrations will complete when regen runs post-install |
| pip install takes >10s | Acceptable; user opted in and sees progress from pip |
| Hooks dir copy brings in Codex-only files (`permission-router.sh`, `codex-compact-prompt.txt`) | Inert on Claude Code; regen only registers Claude Code–relevant hooks. Inert on Codex too (permission-router.sh is already Codex-only and will simply be registered). |
| Dual-host (`claude_codex`): both wiring blocks try to copy hooks dir | Phase 5 guards against double-copy with `if [ ! -d "$TARGET_DIR/.shamt/hooks" ]` |
| Dual-host: MCP venv installed twice | Phase 5 guards against double-install with `if [ ! -d "$TARGET_DIR/.shamt/mcp/.venv" ]` |
| CI workflow templates require `OPENAI_API_KEY` secret not set at init time | Print a clear reminder note; workflows won't run until the secret is added — no breakage |
| Sequencing fix breaks the "file already exists" settings.json guard | The guard evaluates `TARGET_SETTINGS` at runtime; moving the block earlier produces identical branching behavior |
| SHAMT-49 also modifies `init.sh` and `init.ps1` (adds `epic_tag.conf` write in the project details section) | Changes are orthogonal — different sections of the script, no conflict. Implement in either order; no coordination needed beyond awareness. |

---

## Change History

| Date | Change |
|------|--------|
| 2026-05-02 | Initial draft created (Claude Code only, hooks + MCP) |
| 2026-05-02 | Revised: expanded to all AI services, added CI automation, added Codex regen hooks gate |
| 2026-05-02 | Validated: 4-round validation loop, primary clean round + 2 Haiku sub-agent confirmations |
