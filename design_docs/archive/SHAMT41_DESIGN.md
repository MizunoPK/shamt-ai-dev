# SHAMT-41: Hooks Bundle and Minimal MCP Server (Claude Code)

**Status:** Validated
**Created:** 2026-04-27
**Branch:** `feat/SHAMT-41`
**Validation Log:** [SHAMT41_VALIDATION_LOG.md](./SHAMT41_VALIDATION_LOG.md)
**Depends on:** SHAMT-39 (canonical content), SHAMT-40 (Claude Code wiring with reserved hooks/mcpServers blocks)
**Companion docs:** [`CLAUDE_INTEGRATION_THEORIES.md`](../CLAUDE_INTEGRATION_THEORIES.md), [`FUTURE_ARCHITECTURE_OVERVIEW.md`](../FUTURE_ARCHITECTURE_OVERVIEW.md)

---

## Problem Statement

After SHAMT-40, a Shamt-on-Claude-Code child project has skills, sub-agent personas, and slash commands wired in, but the *enforcement* and *mechanical-operation* layers are still prose. Several rules in CLAUDE.md ("never `--no-verify`", "audit before export", "architect-builder is mandatory in S6", "validation log must be stamped each round") rely on the agent remembering to follow them. Mechanical operations (reserve next SHAMT-N, append a structured validation round) shell out via Bash and require the agent to parse text.

The Claude theorization doc (§2.3, §2.5, §3.5) identifies this as the next leverage step: ship a hooks bundle that turns prose rules into harness enforcement, and ship a minimal MCP server (`next_number()`, `validation_round()`) that gives the agent typed verbs for the most-felt mechanical operations. The doc also identifies the **PreCompact + SessionStart hook pair** as the highest-impact single change: it replaces the GUIDE_ANCHOR / Resume Instructions ritual with harness behavior. This is Claude doc Experiment B's load-bearing hypothesis.

This design doc ships the high-value hook subset, the minimal MCP server, and validates Experiment B.

---

## Goals

1. Author `.shamt/hooks/` script bodies for the high-value enforcement hooks: `--no-verify` blocker, commit-message format, pre-export audit gate, validation-log auto-stamp, S9 zero-bug push gate, architect-builder enforcement.
2. Author the **PreCompact and SessionStart hook pair** as the framework's compaction-survival mechanism, replacing GUIDE_ANCHOR / Resume Instructions for sessions where they fire.
3. Author `.shamt/mcp/` containing a minimal MCP server with two functions: `shamt.next_number()` (atomic SHAMT-N reservation) and `shamt.validation_round()` (append a structured round entry, return updated `consecutive_clean`).
4. Update the Claude Code regen and init flows so hooks register in `.claude/settings.json` and the MCP server registers in `.claude/settings.json`'s `mcpServers` block.
5. Update `validation_loop_master_protocol.md` and S2/S5/S7/S8/S9 stage guides to call the new MCP verbs and acknowledge that hooks now enforce specific rules.
6. Validate Claude doc Experiment B: run a full epic where the agent does not read `GUIDE_ANCHOR.md` or `Resume Instructions` because PreCompact + SessionStart carry the context, *and* a deliberate compaction event mid-epic produces a clean resume.

---

## Detailed Design

### Proposal 1: Hooks bundle with opt-in installation

**Description:** Each hook script lives in `.shamt/hooks/<name>.sh` (with `<name>.ps1` for Windows). The init script (post-SHAMT-40) and the regen script add hook registrations to `.claude/settings.json`'s `hooks` block under `_shamt_managed_blocks`.

The bundle:

| Hook | Event | Purpose |
|------|-------|---------|
| `no-verify-blocker.sh` | PreToolUse on Bash | Reject `git commit --no-verify` / `--no-gpg-sign` |
| `commit-format.sh` | PreToolUse on Bash | Enforce `feat/SHAMT-N:` or `fix/SHAMT-N:` commit prefix |
| `pre-export-audit-gate.sh` | UserPromptSubmit + PreToolUse on export script | Refuse export if `.shamt/audit/last_run.json` is stale or shows unfixed issues |
| `validation-log-stamp.sh` | PostToolUse on Edit matching `*VALIDATION_LOG.md` | Append timestamp + model used; harness owns the round counter |
| `architect-builder-enforcer.sh` | PreToolUse on Task during S6 | Reject if subagent_type ≠ shamt-builder |
| `user-testing-gate.sh` | PreToolUse on Bash matching `git push` during S9 | Refuse if user-testing artifact doesn't show "ZERO bugs found" |
| `precompact-snapshot.sh` | **PreCompact** | Dump epic / stage / phase / step / blockers / open validation-loop counters to `.shamt/epics/<active>/RESUME_SNAPSHOT.md` |
| `session-start-resume.sh` | **SessionStart** (matchers: startup, resume) | Read `.shamt/epics/<active>/RESUME_SNAPSHOT.md` if present and inject as agent context |
| `subagent-confirmation-receipt.sh` | SubagentStop | When a confirming sub-agent reports issues, write a `.shamt/epics/<active>/.subagent_confirmation_veto` flag file. The `shamt.validation_round()` MCP tool reads and deletes this flag before incrementing `consecutive_clean`; if the flag is present, it returns the current count unchanged (veto takes effect). |
| `stage-transition-snapshot.sh` | UserPromptSubmit matching "advance to S{N}" / "enter S{N}" / "S{N}.P1" stage-advance phrases | Complement to `precompact-snapshot.sh`. Writes current epic / stage / phase / step / blockers to `RESUME_SNAPSHOT.md` at each explicit stage transition so context is preserved at natural handoff points, not only at auto-compaction. Uses the same `RESUME_SNAPSHOT.md` schema defined for `precompact-snapshot.sh` in Phase 4 (schema must be authored once, shared by both hooks). |

Each hook is opt-in by default — the SHAMT-40 starter `settings.json` had empty `hooks: {}`. SHAMT-41's installer step writes registrations into `.claude/settings.json` and adds `"hooks"` to `_shamt_managed_blocks`.

**Rationale:** Splits the high-value enforcement subset from the long-tail. The PreCompact + SessionStart pair is structurally the highest-leverage change — it replaces a meaningful fraction of GUIDE_ANCHOR / Resume Instructions ritual. Other hooks are validated additive enforcement.

**Alternatives considered:**
- *Ship all proposed hooks at once:* Larger surface to validate and debug. Splitting the high-value subset reduces risk. Rejected (deferred more speculative hooks like EPIC_TRACKER mutation log to SHAMT-44 / SHAMT-45).
- *Hooks as user-pasted snippets only, no installer:* Friction barrier; defeats the "harness enforces" thesis. Rejected.

### Proposal 2: Minimal MCP server in Python

**Description:** `.shamt/mcp/` contains a Python package with two MCP-server-exposed tools:

```python
shamt.next_number() -> {"number": int, "reserved": bool, "reserved_at": str}
shamt.validation_round(
    log_path: str,
    round: int,
    severity_counts: dict[str, int],
    fixed: bool = False,
    exit_threshold: int = 1,
) -> {"round_number": int, "consecutive_clean": int, "should_exit": bool}
```

`next_number()` opens `design_docs/NEXT_NUMBER.txt` with an OS-level lock, reads the current value, increments, writes back, releases the lock. Returns the reserved number atomically.

`validation_round()` parses the log, appends a structured entry, computes `consecutive_clean` from the severity_counts and history, and returns whether the loop should exit. Parameters:
- `fixed`: Set to `true` when the round found exactly 1 LOW issue that was immediately fixed (the "1-LOW-fixed" exception to the clean-round rule). When `fixed=true` and `severity_counts` shows exactly 1 LOW and zero higher-severity issues, the round counts as clean and `consecutive_clean` increments. For all other severity combinations, `fixed` is ignored.
- `exit_threshold`: The `consecutive_clean` value at which `should_exit` returns `true`. Default 1 for validation loops (per `validation_loop_master_protocol.md` primary-clean exit criterion). Pass 3 for guide audits (which require 3 consecutive clean rounds). `should_exit` is computed as `consecutive_clean >= exit_threshold` after processing the current round.

Before incrementing `consecutive_clean`, the tool checks for the `.shamt/epics/<active>/.subagent_confirmation_veto` flag file written by `subagent-confirmation-receipt.sh`; if present, the counter is not incremented and the flag is deleted. The agent writes its prose analysis separately; the MCP call is bookkeeping only.

The server uses the standard MCP Python SDK and exposes itself over stdio. SHAMT-40's regen reserved the empty `mcpServers: {}` block; SHAMT-41's regen (Phase 5) populates the `mcpServers.shamt` entry in `.claude/settings.json`.

**Rationale:** Python is portable, the MCP Python SDK is mature, and these two functions are the friction points the Claude doc identified as worth carving out first. Other tools (`audit_run`, `epic_status`, `metrics.append`, `export`, `import`) are deferred to SHAMT-44 where they pair naturally with cross-cutting workflows.

**Alternatives considered:**
- *Rust or Node implementation:* Equally viable; Python chosen for ecosystem familiarity and MCP SDK maturity. No strong technical preference.
- *Skip MCP, keep bash:* Loses the typed-result benefit and prevents hooks from cleanly observing structured tool calls. Rejected.
- *Ship more tools now:* Premature; the Claude doc explicitly recommends carving out just these two first.

### Proposal 3: Update validation guides to reference the MCP verbs

**Description:** `validation_loop_master_protocol.md` is updated to say "call `shamt.validation_round()` to log each round; the harness owns the counter and exit determination." S2, S5, S7, S8, and S9 stage guides are updated similarly (all stages that run validation loops with `consecutive_clean` tracking). The prose protocol still describes the dimensions and severity classification — only the bookkeeping moves to MCP.

`GUIDE_ANCHOR.md` and Resume Instructions guides note that on Claude Code with PreCompact + SessionStart enabled, the manual snapshot ritual is partially superseded; they remain authoritative when hooks are not installed.

**Rationale:** Guides should reflect the reality on the current codebase. Without this update, agents have both prose ("write a round entry") and MCP verbs ("call validation_round") and may use them inconsistently.

### Recommended approach

Ship all three: hooks bundle (opt-in installation through Shamt-managed `hooks` block), minimal MCP server (`next_number` + `validation_round`), guide updates so the protocol references the new verbs.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/hooks/no-verify-blocker.sh` (+ .ps1) | CREATE | PreToolUse on Bash |
| `.shamt/hooks/commit-format.sh` (+ .ps1) | CREATE | PreToolUse on Bash |
| `.shamt/hooks/pre-export-audit-gate.sh` (+ .ps1) | CREATE | UserPromptSubmit + PreToolUse |
| `.shamt/hooks/validation-log-stamp.sh` (+ .ps1) | CREATE | PostToolUse on Edit |
| `.shamt/hooks/architect-builder-enforcer.sh` (+ .ps1) | CREATE | PreToolUse on Task |
| `.shamt/hooks/user-testing-gate.sh` (+ .ps1) | CREATE | PreToolUse on Bash (S9 only) |
| `.shamt/hooks/precompact-snapshot.sh` (+ .ps1) | CREATE | PreCompact |
| `.shamt/hooks/session-start-resume.sh` (+ .ps1) | CREATE | SessionStart |
| `.shamt/hooks/subagent-confirmation-receipt.sh` (+ .ps1) | CREATE | SubagentStop |
| `.shamt/hooks/stage-transition-snapshot.sh` (+ .ps1) | CREATE | UserPromptSubmit on stage-advance |
| `.shamt/hooks/README.md` | CREATE | Document each hook's purpose, event, and registration shape |
| `.shamt/mcp/pyproject.toml` | CREATE | Python package metadata |
| `.shamt/mcp/src/shamt_mcp/__init__.py` | CREATE | Server entry point |
| `.shamt/mcp/src/shamt_mcp/next_number.py` | CREATE | Atomic SHAMT-N reservation |
| `.shamt/mcp/src/shamt_mcp/validation_round.py` | CREATE | Structured round-log append |
| `.shamt/mcp/README.md` | CREATE | Install, run, register |
| `.shamt/audit/last_run.json` (schema only) | CREATE | Schema documented in pre-export-audit-gate.sh; format defined |
| `.shamt/guides/audit/*.md` (relevant files) | MODIFY | Phase 2: update audit workflow guides to write `last_run.json` on audit completion; specific file list determined in Phase 2 |
| `.shamt/scripts/regen/regen-claude-shims.sh` | MODIFY | Install hooks block into `.claude/settings.json`; install mcpServers.shamt |
| `.shamt/scripts/regen/regen-claude-shims.ps1` | MODIFY | Mirror |
| `.shamt/scripts/initialization/init.sh` | MODIFY | After SHAMT-40 wiring, install hooks + MCP if `features.shamt_hooks=true` is set in settings.json (see Open Question 1) |
| `.shamt/scripts/initialization/init.ps1` | MODIFY | Mirror |
| `.shamt/scripts/import/import.sh` | MODIFY | Add `hooks/` to the import scope (analogous to how skills/agents/commands were added in SHAMT-40); ensures existing child projects receive hook scripts on `shamt import` |
| `.shamt/scripts/import/import.ps1` | MODIFY | Mirror |
| `.shamt/skills/shamt-validation-loop/SKILL.md` | MODIFY | Reference `shamt.validation_round()` MCP verb alongside prose round-entry procedure (for hosts without MCP). Maintain `source_guides:` frontmatter. |
| `.shamt/guides/reference/validation_loop_master_protocol.md` | MODIFY | Reference `shamt.validation_round()` MCP verb; source guide for `shamt-validation-loop/SKILL.md` — skill body updated in same phase (Phase 6) |
| `.shamt/guides/stages/s2/*.md` | MODIFY | Reference MCP verbs where validation rounds happen (spec validation loop in S2.P1) |
| `.shamt/guides/stages/s5/*.md` | MODIFY | Same |
| `.shamt/guides/stages/s7/*.md` | MODIFY | Same |
| `.shamt/guides/stages/s8/*.md` | MODIFY | Same (S8 alignment validation loop tracks consecutive_clean explicitly) |
| `.shamt/guides/stages/s9/*.md` | MODIFY | Same |
| `.shamt/guides/sync/import_workflow.md` | MODIFY | Note that GUIDE_ANCHOR rituals are partially superseded by PreCompact / SessionStart hooks |
| `.shamt/commands/CHEATSHEET.md` | MODIFY | Add "Active Enforcement" section listing each hook, the event that fires it, and what it blocks or requires. Users need to know which operations are now harness-enforced rather than prose-convention. |
| `CLAUDE.md` | MODIFY | New section "Hooks and MCP Server (SHAMT-41)" |
| `.shamt/guides/master_dev_workflow/master_dev_workflow.md` | MODIFY | Add hook and MCP tool references at Steps 4, 5, and design-doc workflow steps |

---

## Implementation Plan

### Phase 1: MCP server skeleton
- [ ] Create `.shamt/mcp/` Python package with `pyproject.toml`.
- [ ] Implement `next_number()` with file-locking.
- [ ] Implement `validation_round()` parsing existing log format and computing `consecutive_clean`.
- [ ] Add unit tests covering atomic reservation under simulated concurrent access and `consecutive_clean` arithmetic edge cases.
- [ ] Document install, run, and configuration in `.shamt/mcp/README.md`. **Installation strategy decision:** Default to repo-local venv (per Open Question 2 recommendation); document the alternative paths (system pip-install, packaged binary) but specify repo-local venv as the default and what the registered command in settings.json should invoke (`python -m shamt_mcp` from within the venv).

### Phase 2: Audit-state contract
- [ ] Define `.shamt/audit/last_run.json` schema (timestamp, scope, severity counts, unfixed issue list).
- [ ] Update audit workflow guides to write this file when an audit completes.
- [ ] This contract is consumed by `pre-export-audit-gate.sh`.

### Phase 3: Hook scripts
- [ ] Author each `.sh` and `.ps1` hook script per the table. **Note:** `stage-transition-snapshot.sh` shares the `RESUME_SNAPSHOT.md` schema defined in Phase 4; author it alongside `precompact-snapshot.sh` in Phase 4 rather than before the schema exists. All other hooks in the table can be authored in Phase 3.
- [ ] Each script reads stdin (event details from harness) and writes stdout / sets exit code per Claude Code hook protocol.
- [ ] Test each script's deny-path: feed it an out-of-spec input and verify rejection. Feed it a legitimate input and verify pass-through.
- [ ] Document each in `.shamt/hooks/README.md`.

### Phase 4: PreCompact + SessionStart pair (special attention)
- [ ] Define `.shamt/epics/<active>/RESUME_SNAPSHOT.md` schema (current SHAMT-N, stage, phase, step, blockers, open validation rounds, last 3 file edits).
- [ ] `precompact-snapshot.sh` writes this file with current state.
- [ ] `session-start-resume.sh` reads it (if present) and outputs an agent context block via stdout.
- [ ] Test: run an agent, force compaction, verify resume snapshot writes; start new session, verify the snapshot is read back into context.

### Phase 5: Regen and init updates
- [ ] Update `regen-claude-shims.sh` to install the `hooks` block into `.claude/settings.json` and the `mcpServers.shamt` entry.
- [ ] Add hooks key to `_shamt_managed_blocks`.
- [ ] Update init script: after SHAMT-40 wiring, run the same install step.
- [ ] Update `import.sh` (and `import.ps1`) to add `hooks/` to the import scope so that existing child projects receive hook scripts when running `shamt import`.

### Phase 6: Guide updates
- [ ] Update `CHEATSHEET.md` with an "Active Enforcement" section listing each hook, its trigger event, and what it blocks or requires (e.g., "commit-format.sh — rejects commits not matching `feat/SHAMT-N:` or `fix/SHAMT-N:` prefix").
- [ ] Modify `validation_loop_master_protocol.md` to reference `shamt.validation_round()`.
- [ ] Update `shamt-validation-loop/SKILL.md` to reference `shamt.validation_round()` MCP verb alongside the prose round-entry procedure (for hosts without MCP). Maintain `source_guides:` frontmatter.
- [ ] Modify S2/S5/S7/S8/S9 stage guides similarly (S2.P1 spec validation loop, S5/S7/S9 implementation and QC validation loops, S8 alignment validation loop).
- [ ] Modify `import_workflow.md` to note PreCompact / SessionStart partial supersession.
- [ ] Add CLAUDE.md section "Hooks and MCP Server (SHAMT-41)".

### Phase 6.5: Master repo hook + MCP activation
- [ ] Wire master-applicable hooks (10 of 12) into master's `.claude/settings.json` via regen. Excluded hooks: `pre-export-audit-gate.sh` (master doesn't export), `user-testing-gate.sh` (S9-only child workflow). Note: SHAMT-41 creates 10 hooks; SHAMT-44 adds 2 more (`validation-stall-detector`, `pre-push-tripwire`), bringing the total to 12. At SHAMT-41 implementation time, 8 of 10 SHAMT-41 hooks are master-applicable; the remaining 2 master-applicable hooks arrive with SHAMT-44.
- [ ] Register MCP tools in master's config: `shamt.next_number()`, `shamt.validation_round()` (implemented in this design doc, active immediately). Note: `shamt.audit_run()`, `shamt.epic_status()`, `shamt.metrics.append()` are implemented in SHAMT-44; they will be registered in master's config when SHAMT-44's regen updates land.
- [ ] Update `master_dev_workflow.md` to reference hooks and MCP tools at relevant steps:
  - Step 4 (Guide Audit): note that `shamt.audit_run()` will be available after SHAMT-44
  - Step 5 (Commit): note that `commit-format` hook enforces commit discipline now; `pre-push-tripwire` hook will be available after SHAMT-44
  - Larger Changes section, sub-step "Reserve N": use `shamt.next_number()` MCP tool
  - Larger Changes section, sub-step "Validate design doc": `shamt.validation_round()` tracks rounds; `validation-log-stamp` hook auto-stamps
  - Session Management: `precompact-snapshot` and `session-start-resume` hooks auto-manage context across compactions
- [ ] Test on master repo: create a test branch, make a commit with wrong format, verify `commit-format` hook rejects it.

### Phase 7: Validation — Claude doc Experiment B
- [ ] On a test child project (post-SHAMT-40), install hooks + MCP via the new flow.
- [ ] Run a full S1–S10 epic execution, monitoring whether the agent reads `GUIDE_ANCHOR.md` or any Resume Instructions guides.
- [ ] Force a compaction event mid-epic (manual `/compact` or wait for auto-compaction); verify the resume snapshot is written and read back cleanly.
- [ ] Pass criterion: at least one full epic completes without GUIDE_ANCHOR reads, AND a deliberate compaction-mid-epic produces a clean resume.

### Phase 8: Implementation validation
- [ ] Run implementation validation loop (5 dimensions).
- [ ] Run full guide audit (3 clean rounds).

---

## Validation Strategy

- **Primary:** Design doc validation loop on this doc.
- **Implementation:** Verify each file in "Files Affected" matches spec.
- **Empirical (Experiment B):** Full epic completes without GUIDE_ANCHOR reads + clean compaction-mid-epic resume.
- **Hook deny-path testing:** Each hook tested for both legitimate-pass and false-positive-reject scenarios.
- **MCP atomicity:** `next_number()` tested under simulated concurrent access (two processes calling simultaneously).
- **Success criteria:**
  1. All hooks installed and firing on the right events.
  2. MCP server registers and responds to both functions.
  3. Experiment B passes: full epic without GUIDE_ANCHOR reads, clean compaction resume.
  4. Existing children without SHAMT-41 continue to work via prose-only protocol.

---

## Open Questions

1. **Hook opt-in granularity:** Should the user opt in per-hook or all-or-nothing? **Recommendation:** All-or-nothing initially via a single `features.shamt_hooks=true` flag in settings.json; per-hook opt-out via the array later if friction is felt.
2. **MCP server installation path:** Where does the MCP server actually run from — system pip-install, repo-local venv, or a packaged binary? **Recommendation:** Document multiple paths in `.shamt/mcp/README.md`; default to repo-local venv invoked via the registered command in settings.json.
3. **PreCompact snapshot scope:** What goes into RESUME_SNAPSHOT.md? Current proposal lists SHAMT-N, stage, phase, step, blockers, validation rounds, recent edits. Need to confirm via Experiment B that this is sufficient. **Recommendation:** Start minimal; expand if Experiment B reveals gaps.
4. **MCP server HTTP variant for Codex Cloud:** SHAMT-41 designs the MCP server for STDIO operation (repo-local venv). Codex Cloud containers constrain STDIO MCP — the `cloud-setup.sh` in SHAMT-43 installs the server as an HTTP-served process instead. SHAMT-41 does not need to ship the HTTP variant; SHAMT-43 owns the Cloud deployment pattern. However, implementers should note that the server code should be structured so the HTTP transport can be added without architectural surgery. **Recommendation:** Add a `--http` flag to the server CLI in Phase 1 (even if Phase 1 only uses `--stdio`); SHAMT-43 Phase 1 activates the HTTP entrypoint in the cloud setup script.

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| A hook bug rejects legitimate operations and blocks the user | Each hook has a deny-path test (Phase 3); ship as opt-in via flag; provide easy disable instructions |
| MCP server crashes mid-validation | Skill body falls back to prose log entry; harness retries on next call (per overview §7b failure modes) |
| PreCompact / SessionStart don't carry enough state | Resume snapshot schema is iterative; first version may miss edge cases that Experiment B reveals |
| `next_number()` race condition still exists despite locking | OS-level file lock (fcntl on Unix, msvcrt.locking on Windows) is the standard solution; document the locking behavior |
| Guide updates create temporary inconsistency for children pre-SHAMT-41 | Updated guides include conditional language ("if MCP is registered, call X; otherwise write the log entry directly") |
| Experiment B fails | Hypothesis under test is that PreCompact + SessionStart is sufficient. If not, the framework's compaction protocols are doing more work than they appear; investigate before retrying |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-27 | Initial draft created |
| 2026-04-27 | Validated — specified flag-file protocol for subagent-confirmation-receipt↔validation_round interaction; added audit workflow guides to Files Affected |
| 2026-04-27 | Added stage-transition-snapshot hook to bundle (10th hook); added HTTP-served MCP note for Codex Cloud to Open Questions |
| 2026-04-27 | Fixed feature flag naming conflict: Files Affected init.sh row now references `features.shamt_hooks=true` consistent with Open Question 1 |
| 2026-04-27 | Added CHEATSHEET.md MODIFY entry to Files Affected; Phase 6 step to add "Active Enforcement" section listing hooks and their enforcement rules |
| 2026-04-28 | SHAMT-47 fold-in: Added Phase 6.5 (master repo hook + MCP activation); added `master_dev_workflow.md` to Files Affected; master gets 10 of 12 hooks and MCP tool registration |
| 2026-04-28 | Validation fix: Hook count corrected to 10 of 12 (SHAMT-41 creates 10 hooks, SHAMT-44 adds 2 more; 2 excluded for master); MCP tool registration timing clarified (SHAMT-44 tools registered when SHAMT-44 lands); workflow references now use "Larger Changes section" sub-step names instead of ambiguous "Branch + Design Doc" |
| 2026-04-28 | Validation fix (sub-agent round): clarified Phase 1 step 4 to explicitly name the installation strategy decision (repo-local venv default per Open Question 2) |
| 2026-04-28 | Validation fix (sub-agent round 2): (1) companion docs in frontmatter changed to markdown hyperlinks; (2) `validation_round()` signature extended with `exit_threshold` parameter; `fixed` and `should_exit` semantics fully documented in Proposal 2 |
| 2026-04-29 | Drift/coverage sync: Added `shamt-validation-loop/SKILL.md` MODIFY to Files Affected — Phase 6 modifies `validation_loop_master_protocol.md` (source guide), so the skill body must be updated in the same phase to reference the MCP verb. Updated guide MODIFY row Notes to link source guide → skill. Added Phase 6 step for skill update. |
| 2026-04-29 | Validation fixes: (1) Fixed `false` → `False` in `validation_round()` Python signature (correctness); (2) Added Phase 3 note that `stage-transition-snapshot.sh` must be authored alongside `precompact-snapshot.sh` in Phase 4 due to shared RESUME_SNAPSHOT.md schema; (3) Added `.shamt/guides/stages/s2/*.md` MODIFY to Files Affected and updated Phase 6 step to include S2 alongside S5/S7/S9 (spec validation loop also uses `shamt.validation_round()`). |
| 2026-04-29 | Validation fixes (round 2): (1) Phase 6.5 Step 5 bullet now notes `pre-push-tripwire` will be available after SHAMT-44 (consistent with audit_run forward reference pattern); (2) Added `.shamt/guides/stages/s8/*.md` MODIFY to Files Affected and Phase 6 step (S8 alignment validation loop tracks consecutive_clean explicitly). |
| 2026-04-29 | Re-validation fix (post SHAMT-40 merge): Added `import.sh` and `import.ps1` to Files Affected as MODIFY — `.shamt/hooks/` is a new top-level directory not in the prior import scope; without syncing it, child projects would have hooks registered in settings.json but no hook scripts. Added Phase 5 step to update import scripts. |
