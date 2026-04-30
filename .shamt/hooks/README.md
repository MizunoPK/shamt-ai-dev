# Shamt Hooks Bundle

Ten enforcement hook scripts for Claude Code's hook system. Each script reads the tool event JSON from stdin and exits 0 (allow) or 2 (block).

These hooks are registered in `.claude/settings.json` by `regen-claude-shims.sh` when `features.shamt_hooks=true` is set. They are propagated to child projects via `import.sh`.

---

## Hook Reference

| Script | Event | Purpose |
|--------|-------|---------|
| `no-verify-blocker.sh` | PreToolUse (Bash) | Reject `--no-verify` and `--no-gpg-sign` git flags |
| `commit-format.sh` | PreToolUse (Bash) | Enforce `feat/SHAMT-N:` or `fix/SHAMT-N:` commit prefix |
| `pre-export-audit-gate.sh` | UserPromptSubmit + PreToolUse (export) | Block export if audit is stale (>7 days) or failed |
| `validation-log-stamp.sh` | PostToolUse (Edit on `*VALIDATION_LOG.md`) | Append timestamp after each validation log edit |
| `architect-builder-enforcer.sh` | PreToolUse (Task) | In S6, reject Task spawns that don't use `shamt-builder` |
| `user-testing-gate.sh` | PreToolUse (Bash on `git push`) | In S9, block push unless user-testing artifact shows ZERO bugs |
| `precompact-snapshot.sh` | PreCompact | Write RESUME_SNAPSHOT.md before auto-compaction |
| `session-start-resume.sh` | SessionStart | Inject RESUME_SNAPSHOT.md as agent context on session start |
| `subagent-confirmation-receipt.sh` | SubagentStop | If confirming sub-agent reports issues, write veto flag |
| `stage-transition-snapshot.sh` | UserPromptSubmit (stage-advance phrases) | Write RESUME_SNAPSHOT.md at each explicit stage transition |

---

## Codex Event Mapping

Codex's hook event set differs from Claude Code's. SHAMT-42 maps the bundle:

| Shamt hook | Claude Code event | Codex event |
|---|---|---|
| `no-verify-blocker.sh` | PreToolUse (Bash) | `hooks.pre_tool_use.shell` |
| `commit-format.sh` | PreToolUse (Bash) | `hooks.pre_tool_use.shell` |
| `pre-export-audit-gate.sh` | UserPromptSubmit / PreToolUse | `hooks.user_prompt_submit` / `hooks.pre_tool_use.shell` |
| `validation-log-stamp.sh` | PostToolUse (Edit) | `hooks.post_tool_use.edit` |
| `architect-builder-enforcer.sh` | PreToolUse (Task) | `hooks.pre_tool_use.agent_spawn` |
| `user-testing-gate.sh` | PreToolUse (Bash) | `hooks.pre_tool_use.shell` |
| `precompact-snapshot.sh` | PreCompact | **No equivalent** — use `codex-compact-prompt.txt` + `/compact` discipline |
| `session-start-resume.sh` | SessionStart | `hooks.session_start` (direct port) |
| `subagent-confirmation-receipt.sh` | SubagentStop | `hooks.stop` (Stop hook with stdin-parsing for sub-agent context) |
| `stage-transition-snapshot.sh` | UserPromptSubmit | `hooks.user_prompt_submit` (direct port) |
| `permission-router.sh` | *(Codex-only)* | `hooks.permission_request` |

**PreCompact gap:** Codex has no PreCompact hook. Mitigation triplet: (1) `codex-compact-prompt.txt` registered as custom compact_prompt; (2) advance to a stage boundary before `/compact` so `stage-transition-snapshot.sh` writes `RESUME_SNAPSHOT.md`; (3) `session-start-resume.sh` reads the snapshot on resume. See `.shamt/host/codex/README.md` for details.

**`permission-router.sh`** is Codex-only (no Claude Code equivalent). Registered only in `.codex/config.toml`.

Codex hook registrations are managed by `regen-codex-shims.sh` in `.codex/config.toml`'s `SHAMT-HOOKS` block.

---

## Registration Shape

Each hook registration in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {"type": "command", "command": "/path/to/.shamt/hooks/no-verify-blocker.sh"},
          {"type": "command", "command": "/path/to/.shamt/hooks/commit-format.sh"},
          {"type": "command", "command": "/path/to/.shamt/hooks/user-testing-gate.sh"},
          {"type": "command", "command": "/path/to/.shamt/hooks/pre-export-audit-gate.sh"}
        ]
      },
      {
        "matcher": "Task",
        "hooks": [
          {"type": "command", "command": "/path/to/.shamt/hooks/architect-builder-enforcer.sh"}
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {"type": "command", "command": "/path/to/.shamt/hooks/validation-log-stamp.sh"}
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {"type": "command", "command": "/path/to/.shamt/hooks/pre-export-audit-gate.sh"},
          {"type": "command", "command": "/path/to/.shamt/hooks/stage-transition-snapshot.sh"}
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {"type": "command", "command": "/path/to/.shamt/hooks/precompact-snapshot.sh"}
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {"type": "command", "command": "/path/to/.shamt/hooks/session-start-resume.sh"}
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          {"type": "command", "command": "/path/to/.shamt/hooks/subagent-confirmation-receipt.sh"}
        ]
      }
    ]
  }
}
```

Paths are resolved to absolute project-root-relative paths by `regen-claude-shims.sh` at install time.

---

## Master-Applicable Subset

Master repo activates 8 of 10 hooks. Excluded:

| Hook | Reason excluded from master |
|------|----------------------------|
| `pre-export-audit-gate.sh` | Master doesn't export — export is a child-only operation |
| `user-testing-gate.sh` | S9-only child workflow — master doesn't follow S1-S11 stages |

---

## RESUME_SNAPSHOT.md Schema

Written by both `precompact-snapshot.sh` and `stage-transition-snapshot.sh`. Location: `.shamt/epics/<active-epic>/RESUME_SNAPSHOT.md`.

Fields:
- `Epic` — active epic tag (e.g., `KAI-007`)
- `Stage` — current S-number (e.g., `S5`)
- `Phase` — current P-number (e.g., `P2`)
- `Step` — current step description from AGENT_STATUS.md
- `Blocker` — current blocker text or `none`
- `consecutive_clean` — current validation loop counter from AGENT_STATUS.md
- Recent file edits — last 3 modified files from git log

The snapshot is intentionally minimal. If `AGENT_STATUS.md` has more current information, the agent should prefer it.

---

## Deny-Path Testing

Each hook should be tested for both the block path and the pass-through path:

```bash
# no-verify-blocker: deny path
echo '{"command": "git commit --no-verify -m test"}' | bash .shamt/hooks/no-verify-blocker.sh
# exit 2 expected

# no-verify-blocker: allow path
echo '{"command": "git commit -m feat/SHAMT-1: test"}' | bash .shamt/hooks/no-verify-blocker.sh
# exit 0 expected

# commit-format: deny path
echo '{"command": "git commit -m \"bad message\""}' | bash .shamt/hooks/commit-format.sh
# exit 2 expected

# commit-format: allow path
echo '{"command": "git commit -m \"feat/SHAMT-41: add hooks\""}' | bash .shamt/hooks/commit-format.sh
# exit 0 expected
```
