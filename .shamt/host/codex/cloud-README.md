# Shamt Codex Cloud — Setup and Usage

This directory contains the cloud environment template and setup scripts for running Shamt workflows on Codex Cloud.

---

## Overview

Codex Cloud spawns disposable containers from the `codex-universal` base image. The Shamt cloud setup:

1. Installs the Shamt MCP server as an **HTTP listener** (port 7400)
2. Pre-caches the guide tree
3. Seeds `AGENTS.md` if missing
4. Verifies `requirements.toml` is in place

---

## Files

| File | Purpose |
|------|---------|
| `cloud-environment.template.json` | Environment manifest template — copy to project root, rename per Codex Cloud docs |
| `cloud-setup.sh` | First-provision setup; installs MCP, warms guide cache, seeds AGENTS.md |
| `cloud-maintenance.sh` | Resume-from-cache refresh; restarts MCP if needed, pulls guide updates |

---

## Cloud Environment Setup

### Step 1 — Verify the manifest filename

Codex Cloud's manifest filename may vary by release. At implementation time, check:
```
https://platform.openai.com/docs/codex/cloud
```
Rename `cloud-environment.template.json` to match the expected filename (e.g., `codex-environment.json`, `.codex/environment.json`, etc.).

### Step 2 — Copy the manifest to your project root

```bash
cp .shamt/host/codex/cloud-environment.template.json <manifest-filename>
```

### Step 3 — Set `EPIC_BRANCH`

Before launching a cloud task, set `EPIC_BRANCH` in your environment or in the manifest to the active epic branch name (e.g., `feat/KAI-007`). The container checks out this branch.

### Step 4 — Register as a Codex Cloud project

Follow the Codex Cloud docs to register your project and link the manifest.

---

## MCP Transport: HTTP vs. STDIO

Codex CLI uses the Shamt MCP server via **STDIO** (the default). Codex Cloud uses **HTTP** because container STDIO MCP behavior is constrained.

The `cloud-setup.sh` script starts `shamt.server.http` on `http://localhost:7400`. The cloud task agent reads `SHAMT_MCP_HOST` from the environment to locate the endpoint.

If you need a non-default port, set `SHAMT_MCP_PORT` in the manifest's `environment_variables` block.

---

## Secrets Handling

`GITHUB_TOKEN` is listed in `secrets_setup_only` — it is available during `cloud-setup.sh` but is removed before the agent phase begins. This prevents the agent from making unintended GitHub API calls.

Service account tokens needed for long-running MCP auth are written to the container environment during setup via `/etc/environment`. These survive into the agent phase.

To inject additional secrets into the agent phase, add them to the manifest's `environment_variables` block (for non-sensitive values) or use Codex Cloud's secrets management (for sensitive values).

---

## Network Policy

The manifest sets `"network_policy": "limited"`. This allows:
- Outbound HTTPS to GitHub, npm, PyPI, and Codex API endpoints
- The local MCP HTTP server (localhost:7400)

The container cannot receive inbound connections from outside the cloud environment.

---

## Container Lifecycle and Recovery

Codex Cloud containers are cached for up to 12 hours. On resume, `cloud-maintenance.sh` runs instead of `cloud-setup.sh`. It:
- Re-installs the Shamt MCP package (picks up any guide or script updates)
- Restarts the MCP HTTP server if it exited
- Fetches guide updates from `origin/main`

**Corrupted-cache recovery:** If the cached container state is corrupted (broken venv, stale guide tree, wrong branch), discard the container. On the next launch, Codex Cloud runs `cloud-setup.sh` fresh and the container rebuilds cleanly.

---

## requirements.toml in Cloud Context

`requirements.toml` at the project root enforces Shamt's sandbox floor. In a cloud task:
- `[sandbox] allowed_modes` prevents `danger-full-access` escalation — the cloud task cannot exceed `workspace-write`
- `[approval] floor = "on-request"` means git push and external service calls require approval

The `cloud-setup.sh` script warns if `requirements.toml` is missing. If Codex Cloud does not apply `requirements.toml` enforcement in container contexts, add an explicit check in `cloud-setup.sh` and fail the setup if the file is absent.

---

## Cloud MCP Deferral

Cloud-specific MCP auth configuration (service account token management, HTTP MCP endpoint registration in `.codex/config.toml` for cloud sessions) is covered in this README. The base MCP server implementation lives in `.shamt/mcp/` and is documented there.
