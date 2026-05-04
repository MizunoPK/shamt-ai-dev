# Shamt Lite — Cursor Host Directory

This directory stores Cursor-specific Lite host configuration for the master shamt-ai-dev repo.

---

## Files

| File | Status | Description |
|------|--------|-------------|
| `README.md` | Committed | This file |
| `.model_resolution.local.toml.example` | Committed | Template for the per-developer gitignored model resolution file |
| `.model_resolution.local.toml` | **Gitignored** | Per-developer model resolution (written by `init_lite.sh --host=cursor`) |

---

## `.model_resolution.local.toml` Schema

Written by `init_lite.sh --host=cursor` into `<child-project>/shamt-lite/host/cursor/`.  
Gitignored via `<child-project>/shamt-lite/.gitignore`.

```toml
CHEAP_MODEL = "inherit"
```

| Key | Description | Default |
|-----|-------------|---------|
| `CHEAP_MODEL` | Model id used for sub-agent personas and `{cheap-tier}` XML substitution in deployed skills | `inherit` |

**`inherit`** — Cursor uses whatever model is currently active in the session. Avoids breakage when model names are renamed upstream. Recommended unless you want to pin to a specific cheap model.

**Specific model id** (e.g. `claude-haiku-4-5`) — pins sub-agents to that model. Breaks if Cursor renames the model; re-run `init_lite.sh --host=cursor` to update.

---

## No AGENTS.md for `--host=cursor` alone

Unlike `--host=codex` which writes `AGENTS.md` (Codex reads it from the project root automatically), `--host=cursor` does **not** write `AGENTS.md`. Cursor's deployment surface is `.cursor/rules/*.mdc` only.

When `--host=cursor,codex` is used, `AGENTS.md` is written by the Codex flow; Cursor reads its own `.cursor/rules/` files independently.

---

## Updating After Init

To change the cheap-tier model without re-initializing:

1. Edit `<child-project>/shamt-lite/host/cursor/.model_resolution.local.toml`
2. Re-run `regen-lite-cursor.sh` from the child project root

Or re-run `init_lite.sh --host=cursor` (prompts for model again, then runs regen).

---

## Drift Risk

The 5 `.cursor/rules/lite-*.mdc` files in `<child>/.cursor/rules/` are derivatives of `SHAMT_LITE.md`. If `SHAMT_LITE.md` is updated in master, re-run `regen-lite-cursor.sh` in child projects to refresh. A future enhancement (SHAMT-52 R3) may auto-regenerate `.mdc` files from `SHAMT_LITE.md` sections.
