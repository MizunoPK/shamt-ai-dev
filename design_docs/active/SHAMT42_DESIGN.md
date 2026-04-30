# SHAMT-42: Codex Host Parity — AGENTS.md, Profiles, requirements.toml, PermissionRequest

**Status:** In Progress (implementation complete 2026-04-29; pending implementation validation)
**Created:** 2026-04-27
**Branch:** `feat/SHAMT-42`
**Validation Log:** [SHAMT42_VALIDATION_LOG.md](./SHAMT42_VALIDATION_LOG.md)
**Depends on:** SHAMT-39 (canonical content), SHAMT-41 (hooks + MCP — for porting hook bundle to Codex form)
**Companion docs:** `CODEX_INTEGRATION_THEORIES.md`, `FUTURE_ARCHITECTURE_OVERVIEW.md`

---

## Problem Statement

After SHAMT-39 / SHAMT-40 / SHAMT-41, Shamt-on-Claude-Code is operational with skills, sub-agent personas, slash commands, hooks, and minimal MCP. Codex is a different host with a different (in some places stronger) capability surface — `requirements.toml` for admin-enforced policy, per-stage profiles, a five-level reasoning effort knob, the PermissionRequest hook, declarative sandbox modes per sub-agent — and crucially with **no PreCompact hook** and a `agents.max_depth=1` ceiling that constrains nested sub-agent patterns.

This design doc adds Codex parity: the canonical content from SHAMT-39 lights up on Codex, hooks port to Codex's event set (substituting the missing PreCompact with a custom `compact_prompt` + manual `/compact` discipline + artifact substrate), per-stage profiles get authored, the unique-to-Codex `requirements.toml` enforces master-vs-child rules, and the PermissionRequest hook reduces approval fatigue without abandoning gates.

This validates Codex doc Experiment A: a real S2.P1.I3 spec validation on Codex CLI with measurable token/round behavior comparable to Shamt-on-Claude-Code. Once landed, child projects can pick `--host=claude`, `--host=codex`, or `--host=claude,codex` (dual-host) at init.

---

## Goals

1. Extend `init.sh` / `init.ps1` to support `--host=codex` and `--host=claude,codex` flags. AGENTS.md gets generated alongside or instead of CLAUDE.md.
2. Author `regen-codex-shims.sh` that materializes `.codex/agents/<name>.toml` from canonical `.shamt/agents/<name>.yaml` and writes/updates `.codex/config.toml` with profile imports, MCP registration, and hook registration.
3. Author the per-stage Codex profile fragments (`shamt-s1`..`shamt-s10`) and persona profile fragments (`shamt-validator`, `shamt-builder`, `shamt-architect`) under `.shamt/host/codex/profiles/`.
4. Author `.shamt/host/codex/requirements.toml.template` enforcing the master-vs-child contract: sandbox floor, MCP allowlist, deny-read globs, managed hooks directory.
5. Port the high-value hook bundle from SHAMT-41 to Codex's event set. Use `compact_prompt` override + `/compact` discipline to compensate for the missing PreCompact hook; SessionStart with matcher `resume` covers the resume side.
6. Author the `permission-router.sh` PermissionRequest handler scoping auto-approval by active epic and known-safe tool patterns.
7. Update `ai_services.md` to mark Codex as "full-wiring" alongside Claude Code.
8. Validate Codex doc Experiment A: real S2.P1.I3 validation runs on Codex CLI; measure tokens, rounds, agent prose patterns; compare against Shamt-on-Claude-Code baseline.

---

## Detailed Design

### Proposal 1: Multi-host init flag and AGENTS.md generation

**Description:** `init.sh` / `init.ps1` learn a `--host` flag accepting `claude`, `codex`, or `claude,codex`. Behavior:

- `--host=claude` (default if Claude Code detected): existing SHAMT-40 behavior. Generates `CLAUDE.md` from `RULES_FILE.template.md`.
- `--host=codex`: generates `AGENTS.md` from the same template (content identical; filename differs). Creates `.codex/` tree, runs `regen-codex-shims.sh`, writes `.codex/config.toml` starter, copies `requirements.toml.template` to repo root.
- `--host=claude,codex`: generates both files (CLAUDE.md may be a symlink to AGENTS.md on Unix or a duplicate on Windows). Creates both `.claude/` and `.codex/` trees.

`shamt add-host <host>` is a complementary command that adds a new host to an existing project without re-running full init.

**Rationale:** Existing init behavior is preserved as the default. The dual-host configuration is the recommended posture per the Codex doc §8 (Codex for headless / CI, Claude Code for interactive). The `add-host` command supports late adoption without forcing a full re-init.

**Alternatives considered:**
- *Single-host only, force re-init to add second host:* Worse user experience; rejected.
- *Always generate both files regardless:* Pollutes single-host projects. Rejected.

### Proposal 2: regen-codex-shims.sh transform

**Description:** Walk `.shamt/skills/`, `.shamt/agents/`, `.shamt/commands/` and produce Codex-shaped equivalents:

- **Skills:** Until Codex's skills surface stabilizes, ship to `~/.codex/prompts/shamt-<name>.md` (the deprecated-but-functional custom-prompts directory). Each skill's body becomes the prompt content; trigger metadata is informational only since custom prompts are explicit (`/prompts:shamt-<name>`). When the new skills surface lands, this transform updates to write to the canonical Codex skills location.
- **Agents:** Each `.shamt/agents/<name>.yaml` becomes `.codex/agents/<name>.toml`. The `model_tier` translates to a Codex model name per `.shamt/agents/README.md`'s mapping. `sandbox` maps directly to Codex's `sandbox_mode`. `tools_allowed` is preserved.
- **Commands:** Currently follow the same path as skills (`~/.codex/prompts/`). Argument substitution syntax is translated: canonical `{name}` → Codex-style `$NAME` (Codex prompts support both positional `$1` and named `$NAME` substitution).
- **Profiles:** SHAMT-42 introduces stage profiles. Each `.shamt/host/codex/profiles/shamt-<stage>.fragment.toml` is concatenated into `.codex/config.toml` under `[profiles.shamt-<stage>]`. The starter `.codex/config.toml` includes a marker comment block where these fragments land.
- **Hooks:** Each Codex-applicable hook from `.shamt/hooks/<name>.sh` is registered in `.codex/config.toml`'s `[hooks]` section. Codex's hook event set differs from Claude Code's — see Proposal 4 for the mapping.

**Rationale:** Single regen script per host keeps the transform mechanics simple. The multi-target output (per-prompt files in `~/.codex/prompts/`, per-agent files in `.codex/agents/`, single config file `.codex/config.toml`) reflects Codex's actual config layout.

**Alternatives considered:**
- *Use `.codex/skills/` even though it's not yet stable:* Unsafe assumption about future Codex format. Rejected; revisit when skills surface stabilizes.
- *Pure single-file output (one big config.toml):* Per-agent TOML files are clearer for review and per-agent overrides. Rejected.

### Proposal 3: Per-stage profile fragments

**Description:** Author `.shamt/host/codex/profiles/<name>.fragment.toml` for each Shamt stage and key persona:

```toml
[profiles.shamt-s1]
model = "${FRONTIER_MODEL}"
model_reasoning_effort = "high"
sandbox_mode = "read-only"

[profiles.shamt-s2]
model = "${FRONTIER_MODEL}"
model_reasoning_effort = "medium"
sandbox_mode = "workspace-write"

[profiles.shamt-s5]
model = "${FRONTIER_MODEL}"
model_reasoning_effort = "high"
sandbox_mode = "read-only"
[profiles.shamt-s5.mcp_servers]
shamt = { command = "shamt-mcp", args = ["serve"] }

# S6 uses the builder sub-profile name to distinguish it from shamt-builder (persona)
[profiles.shamt-s6-builder]
model = "${DEFAULT_MODEL}"
model_reasoning_effort = "minimal"
sandbox_mode = "workspace-write"

[profiles.shamt-validator]
model = "${FRONTIER_MODEL}"
model_reasoning_effort = "low"
sandbox_mode = "read-only"
approval_policy = "never"
```

`${FRONTIER_MODEL}` and `${DEFAULT_MODEL}` are template placeholders resolved at init time by reading the user's preferred model names (or defaulting to the Codex changelog's current frontier and default). Init prompts the user for these on first run; the values are stored in `.shamt/host/codex/.model_resolution.local.toml` (gitignored) for re-use on regen.

**Rationale:** Profiles are Codex's killer feature for per-stage configuration. Hardcoding model names in fragments ages out within a release cycle; templated placeholders + a small resolver script keeps the fragments stable.

### Proposal 4: Hook event mapping for Codex

**Description:** Codex's hook events differ from Claude Code's. Mapping for the SHAMT-41 bundle:

| Shamt hook | Claude Code event | Codex event |
|---|---|---|
| `--no-verify` blocker | PreToolUse on Bash | PreToolUse on shell tool |
| `commit-format.sh` | PreToolUse on Bash | PreToolUse on shell tool |
| `pre-export-audit-gate.sh` | UserPromptSubmit / PreToolUse | UserPromptSubmit / PreToolUse |
| `validation-log-stamp.sh` | PostToolUse on Edit | PostToolUse on edit tool |
| `architect-builder-enforcer.sh` | PreToolUse on Task | PreToolUse on agent-spawn tool (with regex on tool name; persona check via stdin parsing per Codex matcher constraint) |
| `user-testing-gate.sh` | PreToolUse on Bash | PreToolUse on shell tool |
| `precompact-snapshot.sh` | **PreCompact** | **No equivalent.** Use custom `compact_prompt` to instruct summarizer to preserve epic state; user invokes `/compact` discipline at stage transitions; artifact substrate as durable fallback |
| `session-start-resume.sh` | SessionStart | SessionStart (matchers `startup`, `resume`) — direct port |
| `subagent-confirmation-receipt.sh` | SubagentStop | **No equivalent SubagentStop event** — use Stop hook with stdin-parsing to detect sub-agent vs. parent context |
| `stage-transition-snapshot.sh` | UserPromptSubmit matching "advance to S{N}" / stage-advance phrases | Direct port — Codex also fires UserPromptSubmit; handler reads RESUME_SNAPSHOT.md schema from Phase 4 of SHAMT-41 and writes identically to the Codex project's active epic path |

The PreCompact gap is the most painful. The mitigation triplet (custom `compact_prompt`, `/compact` discipline at stage transitions, artifact substrate via `RESUME_SNAPSHOT.md` from SHAMT-41) is the same as the Codex doc §2.4 prescribed. SessionStart-on-resume reads the snapshot back identically.

The SubagentStop gap is smaller — the Stop hook can read sub-agent context from stdin per Codex's hook protocol.

**Rationale:** Best-effort port. The Codex doc explicitly identifies these gaps and their mitigations; we adopt the prescribed approach.

### Proposal 5: requirements.toml as master-vs-child contract

**Description:** `.shamt/host/codex/requirements.toml.template` ships master's enforcement floor:

```toml
[sandbox]
allowed_modes = ["read-only", "workspace-write"]   # never danger-full-access

[mcp]
allowed_servers = ["shamt", "git"]                  # named allowlist

[hooks]
managed_dir = ".shamt/hooks/"                       # admin-pinned hook source

[denied_reads]
globs = [".env", "**/secrets.*", "**/.aws/credentials"]

[approval]
floor = "on-request"                                # never "never" for stages touching git push or external services
```

Init copies this template to the repo root as `requirements.toml` with a managed-by-Shamt header. The template is master-synced; child projects don't edit it directly. Local overrides go in a separate `requirements.local.toml` (gitignored) if Codex supports such a layered file; otherwise overrides require modifying the master template (which audit will flag).

**Rationale:** This is the unique value Codex offers — admin-enforced policy that the user can't trivially bypass. Shipping conservative rules first (sandbox floor, MCP allowlist, secret-glob deny, approval floor) catches the common-case violations without restricting development velocity.

### Proposal 6: PermissionRequest handler — scoped auto-approval

**Description:** `.shamt/hooks/permission-router.sh` is a Codex-only hook responding to PermissionRequest events. Logic:

```
if tool_name == "edit" and target inside .shamt/epics/<active>/feature folder:
    return {"decision": "approve", "reason": "in-scope edit"}
if tool_name == "shell" and command starts with "git commit":
    return {"decision": "ask_user", "reason": "commit needs human review"}
if tool_name == "shell" and command starts with "git push":
    return {"decision": "ask_user", "reason": "push needs human review"}
default:
    return {"decision": "ask_user"}
```

Reduces approval fatigue without abandoning gates. The script is read-only on the project's own active-epic state; it doesn't make decisions based on external state.

**Rationale:** Codex's PermissionRequest hook is unique to that host and meaningfully reduces friction. Conservative defaults (in-scope edits auto-approve, commits and pushes always escalate) preserve the human checkpoints that matter.

### Recommended approach

All six proposals together. SHAMT-42 is large but cohesive — porting the SHAMT-39/40/41 stack to Codex requires all of these to land at once for the validation experiment to be meaningful.

---

## Files Affected

| File | Status | Notes |
|------|--------|-------|
| `.shamt/scripts/initialization/init.sh` | MODIFY | Add `--host` flag; Codex branch; dual-host support |
| `.shamt/scripts/initialization/init.ps1` | MODIFY | Mirror |
| `.shamt/scripts/regen/regen-codex-shims.sh` | CREATE | Transform `.shamt/{skills,agents,commands,hooks}/` → Codex shapes |
| `.shamt/scripts/regen/regen-codex-shims.ps1` | CREATE | Mirror |
| `.shamt/scripts/initialization/shamt-add-host.sh` | CREATE | Adds a new host to an existing project |
| `.shamt/scripts/initialization/shamt-add-host.ps1` | CREATE | Mirror (Windows) |
| `.shamt/host/codex/config.starter.toml` | CREATE | Starter `.codex/config.toml` with marker blocks for profile imports |
| `.shamt/host/codex/requirements.toml.template` | CREATE | Master enforcement floor |
| `.shamt/host/codex/profiles/shamt-s1.fragment.toml` | CREATE | Per-stage profile |
| `.shamt/host/codex/profiles/shamt-s2.fragment.toml` | CREATE | |
| `.shamt/host/codex/profiles/shamt-s3.fragment.toml` | CREATE | |
| `.shamt/host/codex/profiles/shamt-s4.fragment.toml` | CREATE | |
| `.shamt/host/codex/profiles/shamt-s5.fragment.toml` | CREATE | Includes MCP server registration |
| `.shamt/host/codex/profiles/shamt-s6-builder.fragment.toml` | CREATE | Builder-specific |
| `.shamt/host/codex/profiles/shamt-s7.fragment.toml` | CREATE | |
| `.shamt/host/codex/profiles/shamt-s8.fragment.toml` | CREATE | |
| `.shamt/host/codex/profiles/shamt-s9.fragment.toml` | CREATE | |
| `.shamt/host/codex/profiles/shamt-s10.fragment.toml` | CREATE | |
| `.shamt/host/codex/profiles/shamt-validator.fragment.toml` | CREATE | Validator persona profile |
| `.shamt/host/codex/profiles/shamt-builder.fragment.toml` | CREATE | Builder persona profile |
| `.shamt/host/codex/profiles/shamt-architect.fragment.toml` | CREATE | Architect persona profile |
| `.shamt/host/codex/README.md` | CREATE | Layout, model resolution, how fragments combine |
| `.shamt/hooks/permission-router.sh` | CREATE | Codex-only PermissionRequest handler |
| `.shamt/hooks/permission-router.ps1` | CREATE | Mirror (Windows) |
| `.shamt/hooks/codex-compact-prompt.txt` | CREATE | Custom compact_prompt content preserving Shamt state |
| `.shamt/hooks/README.md` | MODIFY | Add Codex event mapping table |
| `.shamt/scripts/initialization/ai_services.md` | MODIFY | Mark Codex "full-wiring" |
| `.shamt/scripts/initialization/RULES_FILE.template.md` | MODIFY | Note that this same content generates either CLAUDE.md or AGENTS.md based on host |
| `.shamt/scripts/import/import.sh` | MODIFY | Invoke regen-codex-shims.sh on Codex projects |
| `.shamt/scripts/import/import.ps1` | MODIFY | Mirror — invoke regen-codex-shims.ps1 on Codex projects |
| `.gitignore` | MODIFY | Add `.shamt/host/codex/.model_resolution.local.toml` (gitignored local config) |
| `.shamt/commands/CHEATSHEET.md` | PASSTHROUGH (via regen) | Deployed verbatim to `~/.codex/prompts/CHEATSHEET.md` (same interim location as other commands). Argument-substitution syntax translated (`{name}` → `$NAME`) but reference content requires no substitution. Content is authored in SHAMT-39 and updated in SHAMT-41, 43, 44, 45. |
| `CLAUDE.md` | MODIFY | New section "Codex Host Parity (SHAMT-42)" — also covers dual-host story |

---

## Implementation Plan

### Phase 1: Init flag and AGENTS.md generation
- [ ] Extend init.sh/init.ps1 with `--host` flag accepting claude / codex / claude,codex.
- [ ] Codex branch generates AGENTS.md from RULES_FILE.template.md.
- [ ] Dual-host generates both (symlink CLAUDE.md → AGENTS.md on Unix, duplicate on Windows).
- [ ] Author `shamt-add-host.sh` and `shamt-add-host.ps1` for adding hosts post-init.

### Phase 2: regen-codex-shims.sh
- [ ] Author the transform: skills → `~/.codex/prompts/`, agents → `.codex/agents/`, commands → prompts.
- [ ] Implement profile-fragment concatenation into `.codex/config.toml` under marker blocks.
- [ ] Implement model resolution: read `.shamt/host/codex/.model_resolution.local.toml`; prompt user on first run if missing.
- [ ] Idempotence check.

### Phase 3: Profile fragments + starter config
- [ ] Author 10 stage profile fragments (s1–s10) with model_tier / reasoning_effort / sandbox_mode declared.
- [ ] Author validator, builder, and architect persona profile fragments.
- [ ] Author `.shamt/host/codex/config.starter.toml` with marker blocks for profile imports, MCP registration, hook registration, OTel placeholder.

### Phase 4: requirements.toml.template
- [ ] Author the template with conservative defaults (sandbox floor, MCP allowlist, deny-read globs, approval floor).
- [ ] Init copies to repo root with managed-by-Shamt header.
- [ ] Document the override pattern in `.shamt/host/codex/README.md`.

### Phase 5: Hook port + Codex-specific additions
- [ ] Verify each SHAMT-41 hook works under Codex's regex-on-tool-name matcher; adjust where the matcher is less expressive (architect-builder-enforcer needs stdin parsing for persona check).
- [ ] Author `permission-router.sh` and `.ps1`.
- [ ] Author `codex-compact-prompt.txt` instructing summarizer to preserve epic state during `/compact`.
- [ ] Update `.shamt/hooks/README.md` with event mapping table.

### Phase 6: AI services registry
- [ ] Update `ai_services.md` "wiring_tier" column to include Codex as "full-wiring".

### Phase 7: Guides update
- [ ] RULES_FILE.template.md note about both filenames.
- [ ] CLAUDE.md section on Codex host parity and dual-host story.

### Phase 8: Import script extension
- [ ] Extend `import.sh`: add Codex detection branch (check `ai_service.conf` for `codex`); invoke `regen-codex-shims.sh` analogously to the existing Claude Code branch.
- [ ] Extend `import.ps1`: mirror the above for Windows.
- [ ] Update `.gitignore`: add `.shamt/host/codex/.model_resolution.local.toml`.
- [ ] After Codex-targeted regen, also reload `.codex/config.toml` if Codex CLI requires explicit config-reload (verify per Codex docs).

### Phase 9: Validation — Codex doc Experiment A
- [ ] On a test child project, run `init --host=codex`.
- [ ] Verify `.codex/agents/`, `.codex/config.toml`, `requirements.toml` populate correctly.
- [ ] Run S2.P1.I3 spec validation using the `/prompts:shamt-validation-loop` invocation and `shamt-validator` Codex sub-agent.
- [ ] Compare token usage, rounds-to-exit, agent prose against Shamt-on-Claude-Code baseline.
- [ ] Pass criterion: comparable token usage (within ±15% of Claude Code baseline), comparable rounds-to-exit, agent prose around bookkeeping similarly reduced.

### Phase 10: Implementation validation
- [ ] Run implementation validation loop (5 dimensions).
- [ ] Run full guide audit (3 clean rounds).

---

## Validation Strategy

- **Primary:** Design doc validation loop on this doc.
- **Implementation:** Each file in "Files Affected" matches spec.
- **Empirical (Experiment A):** Real S2.P1.I3 validation on Codex CLI within ±15% of Claude Code baseline on tokens.
- **Profile correctness:** Each profile fragment loads cleanly; switching profiles via `codex --profile shamt-s5` produces the expected sandbox mode and reasoning effort.
- **requirements.toml enforcement test:** Attempt `sandbox_mode = "danger-full-access"` from user-side config; verify Codex rejects per requirements.toml.
- **PermissionRequest router:** Test in-scope edit auto-approves, out-of-scope edit escalates, git commit always escalates.
- **PreCompact gap mitigation:** Manually `/compact` mid-session; verify `compact_prompt` preserves epic state in summary; verify SessionStart-on-resume reads RESUME_SNAPSHOT.md if hooks installed.
- **Success criteria:**
  1. Single-host (Codex) and dual-host (Claude+Codex) init flows work.
  2. All profile fragments load and produce expected behavior.
  3. requirements.toml enforces the floor.
  4. Experiment A passes.
  5. Existing children unaffected (Cursor/etc. still work via rules-file-only path).

---

## Open Questions

1. **Codex skills surface stabilization:** When (or if) Codex's new skills surface lands, regen target changes from `~/.codex/prompts/` to wherever Codex parses skills from. Need to monitor changelog and update regen accordingly. **Recommendation:** Document the migration path in `.shamt/host/codex/README.md`; mark current target as "interim".
2. **Profile re-application mid-session:** Codex profiles are loaded at session start; switching mid-session may require relaunch. The Codex doc §2.6 acknowledges this. **Recommendation:** Stage transitions are session boundaries; relaunch is acceptable. Document in `CLAUDE.md`.
3. **Cloud-side MCP behavior:** SHAMT-43 covers Cloud; this doc focuses on CLI. **Recommendation:** Defer Cloud MCP to SHAMT-43; document in `.shamt/host/codex/README.md` that CLI-side MCP works per design but Cloud may differ.
4. **Codex changelog drift:** Model names, hook event additions, etc. may change between this doc's authoring and implementation. **Recommendation:** Init script's model-resolution prompt re-fetches user-preferred names; hook registrations are tested on installation rather than assumed.

---

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Codex docs drift after design doc authoring | Init resolves model names per user prompt; regen verifies hook registration syntax against current Codex; document in README that re-verification is needed before implementation |
| `agents.max_depth=1` constrains the validation-loop pattern | Validator confirmers don't fan out further (depth 2 from root is exactly what's needed); document the constraint and the flatten-or-raise option in `.shamt/host/codex/README.md` |
| `requirements.toml` rules block legitimate user work | Conservative defaults; provide override path via `requirements.local.toml` if Codex supports layering, otherwise document the master-template-edit + audit-flag pattern |
| Codex Cloud MCP friction | Out of scope; SHAMT-43 |
| PreCompact gap mitigation insufficient | Triplet (compact_prompt + /compact discipline + artifact substrate) is best-effort; if Experiment A reveals losses, escalate to Codex feature request |
| PermissionRequest handler auto-approves too broadly | Conservative defaults (in-scope edits only auto-approve; commits/pushes always escalate); test deny-path before shipping |
| Dual-host CLAUDE.md / AGENTS.md drift | Symlink on Unix where possible; on Windows duplicate with a header noting "kept in sync; edit AGENTS.md as the canonical filename"; init script re-syncs on every run |

---

## Change History

| Date | Change |
|------|--------|
| 2026-04-27 | Initial draft created |
| 2026-04-27 | Validated — added shamt-builder.fragment.toml to Files Affected; updated Goal 3 to name builder + architect persona profiles |
| 2026-04-27 | Added CHEATSHEET.md passthrough entry to Files Affected; regen deploys it verbatim to `~/.codex/prompts/CHEATSHEET.md` alongside other commands |
| 2026-04-29 | Re-validated after SHAMT-41 merge — added import.ps1 (MODIFY) and .gitignore (MODIFY) to Files Affected; expanded Phase 8 with explicit import script steps |
| 2026-04-29 | Round 2 fixes — updated Proposal 3 code example to use `shamt-s6-builder` (with comment explaining distinction from builder persona); updated Phase 3 step 2 to include builder persona profile |
| 2026-04-29 | Round 3 fix — added shamt-add-host.ps1 (CREATE, Windows mirror) to Files Affected and Phase 1 |
