# Shamt MCP Server

Provides seven MCP tools used by the Shamt workflow:

- **`shamt.next_number()`** — atomically reserve the next SHAMT-N design-doc number
- **`shamt.validation_round()`** — append a structured round entry to a validation log and return updated `consecutive_clean` state
- **`shamt.audit_run()`** — record a completed guide audit result for the pre-export-audit-gate hook
- **`shamt.epic_status()`** — return a structured snapshot of an epic's stage / phase / blocker state
- **`shamt.metrics_append()`** — emit a Shamt-domain metric to the sidecar log and optionally OTel
- **`shamt.export_pipeline()`** — drive the export pipeline with pre-condition checks
- **`shamt.import_pipeline()`** — drive the import pipeline

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

### `shamt.audit_run(scope, consecutive_clean, exit_criterion_met, issues_by_severity)`

Record a completed guide audit. Writes `.shamt/audit/last_run.json` so `pre-export-audit-gate.sh` can gate exports without re-running the audit.

```json
{"recorded": true, "path": "/repo/.shamt/audit/last_run.json", "exit_criterion_met": true}
```

- `scope` — what was audited (e.g., `".shamt/guides/"`)
- `consecutive_clean` — final value when the audit exited
- `exit_criterion_met` — `true` when 3 consecutive clean rounds were achieved
- `issues_by_severity` — final round counts `{"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0}`

### `shamt.epic_status(epic_id)`

Return a structured snapshot of an epic. `epic_id` may be `"active"` to auto-detect from `EPIC_TRACKER.md`.

```json
{"found": true, "epic_id": "KAI-007", "stage": "S6", "phase": "P2", "step": "...", "blocker": "none", "consecutive_clean": 1}
```

### `shamt.metrics_append(metric_name, value, labels, epic_id?)`

Emit a Shamt-domain metric event to `.shamt/metrics/sidecar.jsonl` and optionally to the OTel endpoint at `SHAMT_OTEL_ENDPOINT`. Labels are validated against a per-metric permit-list; unknown labels are rejected with `accepted: false`.

Permitted metric names: `validation_round`, `audit_round`, `builder_step`, `builder_runs_total`, `confirmer_run`, `shamt_session_active`, `shamt_tokens_saved`, `shamt_tool_calls`.

```json
{"accepted": true, "metric_name": "validation_round", "rejected_labels": []}
```

### `shamt.export_pipeline(epic_id, dry_run?)`

Drive the export pipeline. Checks that `CHANGES.md` exists and the last audit is clean before invoking `export.sh`. `dry_run=true` checks pre-conditions only.

### `shamt.import_pipeline(dry_run?)`

Drive the import pipeline via `import.sh`. `dry_run=true` fetches and diffs without applying changes.

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

# HTTP on port 7400 (for Codex Cloud containers)
python -m shamt_mcp --http
python -m shamt_mcp --http --port 7400 --host 0.0.0.0
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
