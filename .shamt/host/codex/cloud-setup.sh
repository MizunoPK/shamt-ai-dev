#!/usr/bin/env bash
# =============================================================================
# cloud-setup.sh — Shamt MCP + guide cache setup for Codex Cloud containers
# =============================================================================
# Runs once when a Codex Cloud container is first provisioned. Installs the
# Shamt MCP server as an HTTP listener, pre-caches the guide tree, seeds
# AGENTS.md if missing, and verifies requirements.toml is in place.
#
# Codex Cloud calls this script before the agent phase begins. GITHUB_TOKEN
# is available here for dependency fetches; it is removed before the agent
# phase. Service account tokens for MCP auth are written to the container
# environment here.
#
# MCP transport: HTTP-served (not STDIO). Cloud container STDIO MCP behavior
# is constrained; all Shamt MCP calls in cloud tasks use HTTP on port 7400.
# =============================================================================

set -euo pipefail

SHAMT_MCP_PATH="${SHAMT_MCP_PATH:-.shamt/mcp}"
SHAMT_MCP_PORT="${SHAMT_MCP_PORT:-7400}"
SHAMT_MCP_LOG="/tmp/shamt-mcp.log"

echo "[shamt-cloud-setup] Starting Shamt cloud container setup..."
echo "[shamt-cloud-setup] MCP path: $SHAMT_MCP_PATH"
echo "[shamt-cloud-setup] MCP port: $SHAMT_MCP_PORT"

# --- 1. Install Shamt MCP server -----------------------------------------------

echo "[shamt-cloud-setup] Installing Shamt MCP server..."

if [ ! -d "$SHAMT_MCP_PATH" ]; then
    echo "[shamt-cloud-setup] ERROR: $SHAMT_MCP_PATH not found. Is this a Shamt project?" >&2
    exit 1
fi

python3 -m venv "$SHAMT_MCP_PATH/.venv"
# shellcheck disable=SC1091
source "$SHAMT_MCP_PATH/.venv/bin/activate"
pip install --quiet -e "$SHAMT_MCP_PATH"
echo "[shamt-cloud-setup] Shamt MCP server installed"

# --- 2. Start MCP server as HTTP listener ----------------------------------------
#
# Shamt MCP supports both STDIO (for Claude Code) and HTTP (for cloud tasks).
# In cloud context we always use HTTP so the agent can reach the server across
# the container network boundary.

echo "[shamt-cloud-setup] Starting Shamt MCP HTTP server on port $SHAMT_MCP_PORT..."

python3 -m shamt_mcp --http \
    --host 0.0.0.0 \
    --port "$SHAMT_MCP_PORT" \
    > "$SHAMT_MCP_LOG" 2>&1 &
MCP_PID=$!

# Wait for the server to be ready (up to 15s)
_ready=0
for i in $(seq 1 30); do
    if curl -sf "http://localhost:$SHAMT_MCP_PORT/health" > /dev/null 2>&1; then
        _ready=1
        break
    fi
    sleep 0.5
done

if [ "$_ready" -eq 0 ]; then
    echo "[shamt-cloud-setup] ERROR: MCP server did not start within 15s" >&2
    cat "$SHAMT_MCP_LOG" >&2
    exit 1
fi

echo "[shamt-cloud-setup] MCP server running (PID $MCP_PID)"
echo "SHAMT_MCP_PID=$MCP_PID" >> /etc/environment 2>/dev/null || true

# --- 3. Pre-cache guide tree -------------------------------------------------------
#
# Warm the guide tree into the filesystem cache so the agent's first guide read
# doesn't incur cold-storage latency in the cloud container.

echo "[shamt-cloud-setup] Pre-caching guide tree..."
find .shamt/guides -name "*.md" -exec cat {} + > /dev/null
echo "[shamt-cloud-setup] Guide tree cached ($(find .shamt/guides -name "*.md" | wc -l) files)"

# --- 4. Seed AGENTS.md if missing --------------------------------------------------
#
# A cloud task checks out the epic branch. If AGENTS.md is not present (e.g.,
# this is a Codex-only project that hasn't run init yet), seed it from the
# canonical source so the agent has its rules file.

if [ ! -f "AGENTS.md" ]; then
    if [ -f ".shamt/scripts/initialization/RULES_FILE.template.md" ]; then
        cp ".shamt/scripts/initialization/RULES_FILE.template.md" "AGENTS.md"
        echo "[shamt-cloud-setup] Seeded AGENTS.md from template"
    else
        echo "[shamt-cloud-setup] WARNING: AGENTS.md missing and template not found" >&2
    fi
else
    echo "[shamt-cloud-setup] AGENTS.md present"
fi

# --- 5. Verify requirements.toml ---------------------------------------------------

if [ -f "requirements.toml" ]; then
    echo "[shamt-cloud-setup] requirements.toml present"
else
    echo "[shamt-cloud-setup] WARNING: requirements.toml not found — Codex sandbox enforcement may not apply" >&2
fi

# --- 6. Write MCP endpoint to shell environment ------------------------------------
#
# The agent phase reads SHAMT_MCP_HOST from the environment to know where to
# send MCP tool calls. shell_environment_policy controls which vars survive
# into the agent phase; SHAMT_MCP_HOST and SHAMT_CLOUD must be in that list.

export SHAMT_MCP_HOST="http://localhost:$SHAMT_MCP_PORT"
export SHAMT_CLOUD=1
echo "SHAMT_MCP_HOST=http://localhost:$SHAMT_MCP_PORT" >> /etc/environment 2>/dev/null || true
echo "SHAMT_CLOUD=1" >> /etc/environment 2>/dev/null || true

echo "[shamt-cloud-setup] Setup complete."
echo "[shamt-cloud-setup]   MCP endpoint: http://localhost:$SHAMT_MCP_PORT"
echo "[shamt-cloud-setup]   Ready for agent phase."
