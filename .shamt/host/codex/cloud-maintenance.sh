#!/usr/bin/env bash
# =============================================================================
# cloud-maintenance.sh — Shamt container refresh on cached-container resume
# =============================================================================
# Codex Cloud may resume a previously-provisioned container (cached for up to
# 12 hours) rather than running setup.sh again. This script refreshes deps
# that may have changed since the container was first provisioned.
#
# Codex Cloud calls this script when resuming a cached container.
# =============================================================================

set -euo pipefail

SHAMT_MCP_PATH="${SHAMT_MCP_PATH:-.shamt/mcp}"
SHAMT_MCP_PORT="${SHAMT_MCP_PORT:-7400}"

echo "[shamt-cloud-maintenance] Refreshing cached container..."

# --- 1. Re-install Shamt MCP if venv is stale ------------------------------------

if [ -d "$SHAMT_MCP_PATH/.venv" ]; then
    # shellcheck disable=SC1091
    source "$SHAMT_MCP_PATH/.venv/bin/activate"
    pip install --quiet -e "$SHAMT_MCP_PATH"
    echo "[shamt-cloud-maintenance] MCP package refreshed"
else
    echo "[shamt-cloud-maintenance] MCP venv not found — running full setup" >&2
    bash "$(dirname "$0")/cloud-setup.sh"
    exit 0
fi

# --- 2. Restart MCP HTTP server if not running ------------------------------------

if ! curl -sf "http://localhost:$SHAMT_MCP_PORT/health" > /dev/null 2>&1; then
    echo "[shamt-cloud-maintenance] MCP server not running — restarting..."
    python3 -m shamt.server.http \
        --host 0.0.0.0 \
        --port "$SHAMT_MCP_PORT" \
        --project-root "$(pwd)" \
        > /tmp/shamt-mcp.log 2>&1 &

    for i in $(seq 1 30); do
        if curl -sf "http://localhost:$SHAMT_MCP_PORT/health" > /dev/null 2>&1; then
            echo "[shamt-cloud-maintenance] MCP server restarted"
            break
        fi
        sleep 0.5
    done
else
    echo "[shamt-cloud-maintenance] MCP server already running"
fi

# --- 3. Pull latest guide tree changes -------------------------------------------
#
# If the container was cached while an epic branch was in progress, the guide
# tree may have been updated on main since. A fast-forward pull keeps the
# guides current without risking the epic branch state.

if git remote get-url origin > /dev/null 2>&1; then
    git fetch origin main --quiet 2>/dev/null || true
    echo "[shamt-cloud-maintenance] Guide tree fetch complete"
fi

echo "[shamt-cloud-maintenance] Container refresh complete."
