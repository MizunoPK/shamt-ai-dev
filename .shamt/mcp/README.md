# Shamt MCP Server

Provides two MCP tools used by the Shamt workflow:

- **`shamt.next_number()`** — atomically reserve the next SHAMT-N design-doc number
- **`shamt.validation_round()`** — append a structured round entry to a validation log and return updated `consecutive_clean` state

## Tools

### `shamt.next_number()`

Reads `design_docs/NEXT_NUMBER.txt`, increments it under an OS-level exclusive lock, and returns the reserved number.

```json
{
  "number": 42,
  "reserved": true,
  "reserved_at": "2026-04-29T12:00:00+00:00"
}
```

Use the returned `number` as your SHAMT-N. The file is already incremented; do not increment again manually.

### `shamt.validation_round(log_path, round, severity_counts, fixed, exit_threshold)`

Append a structured round entry and track `consecutive_clean`.

```json
{
  "round_number": 2,
  "consecutive_clean": 2,
  "should_exit": false
}
```

Parameters:
- `log_path` — path to `*_VALIDATION_LOG.md` (absolute or repo-relative)
- `round` — 1-based round number
- `severity_counts` — `{"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 1}`
- `fixed` (optional, default `false`) — `true` when exactly 1 LOW was found and immediately fixed (counts as clean per the 1-LOW-fixed exception)
- `exit_threshold` (optional, default `1`) — `consecutive_clean` value at which `should_exit` returns `true`; use `1` for standard validation loops, `3` for guide audits

## Installation (default: repo-local venv)

The default installation method is a repo-local Python venv. This is what the registered command in `.claude/settings.json` invokes.

```bash
# From repo root
python -m venv .shamt/mcp/.venv
source .shamt/mcp/.venv/bin/activate   # Windows: .shamt\mcp\.venv\Scripts\activate
pip install -e ".shamt/mcp[dev]"
```

The registered command in `.claude/settings.json` will point to:
```
/path/to/repo/.shamt/mcp/.venv/bin/python -m shamt_mcp
```
(resolved to an absolute path by regen at install time)

### Alternative: system pip-install

```bash
pip install -e .shamt/mcp
```

Not recommended for team environments (version conflicts). Use for personal setups where a project venv would be redundant.

### Alternative: packaged binary

Not yet shipped. Future SHAMT release may publish a binary via PyPI for projects that don't want a Python toolchain.

## Running the server manually

```bash
# stdio (default — used by Claude Code)
python -m shamt_mcp

# HTTP (not yet implemented — activates in SHAMT-43 for Codex Cloud)
python -m shamt_mcp --http
```

## Testing

```bash
cd .shamt/mcp
pip install -e ".[dev]"
pytest
```

## Registration in `.claude/settings.json`

Populated automatically by `regen-claude-shims.sh` (SHAMT-41). The `mcpServers.shamt` entry will use the absolute path to the venv Python.

Manual registration example:
```json
{
  "mcpServers": {
    "shamt": {
      "command": "/path/to/repo/.shamt/mcp/.venv/bin/python",
      "args": ["-m", "shamt_mcp"],
      "env": {}
    }
  }
}
```
