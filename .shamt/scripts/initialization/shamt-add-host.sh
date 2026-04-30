#!/usr/bin/env bash
# =============================================================================
# shamt-add-host.sh — Add a host to an existing Shamt project
# =============================================================================
# Adds Codex or Claude Code host wiring to a project already initialized with
# the other host. Does not re-run full init (project details already in place).
#
# Usage:
#   bash /path/to/shamt-ai-dev/.shamt/scripts/initialization/shamt-add-host.sh <host>
#
# Arguments:
#   host — "claude" or "codex" (required)
#
# Run from the project root.
# =============================================================================

set -e

SHAMT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TARGET_DIR="$(pwd)"
SHAMT_DIR="$TARGET_DIR/.shamt"

HOST="${1:-}"

echo ""
echo "============================================================"
echo "  Shamt — Add Host"
echo "============================================================"
echo "  Project: $TARGET_DIR"
echo "  Host:    $HOST"
echo "============================================================"
echo ""

# --- Validate ------------------------------------------------------------------

if [ ! -d "$SHAMT_DIR" ]; then
    echo "  Error: .shamt/ not found. Run init.sh first."
    exit 1
fi

if [ -z "$HOST" ]; then
    echo "  Usage: bash shamt-add-host.sh <host>"
    echo "  Hosts:  claude  |  codex"
    exit 1
fi

case "$HOST" in
    claude|codex) ;;
    *)
        echo "  Error: unknown host '$HOST'. Valid values: claude, codex"
        exit 1
        ;;
esac

# --- Claude Code host wiring --------------------------------------------------

if [ "$HOST" = "claude" ]; then
    echo "  Adding Claude Code host wiring..."
    echo ""

    mkdir -p "$TARGET_DIR/.claude/skills"
    mkdir -p "$TARGET_DIR/.claude/agents"
    mkdir -p "$TARGET_DIR/.claude/commands"
    echo "  ✓ .claude/ directory structure created"

    REGEN_SCRIPT="$SHAMT_SOURCE_DIR/.shamt/scripts/regen/regen-claude-shims.sh"
    if [ -f "$REGEN_SCRIPT" ]; then
        bash "$REGEN_SCRIPT"
        echo "  ✓ Claude Code shims generated"
    else
        echo "  ⚠  regen-claude-shims.sh not found — run it manually"
    fi

    STARTER_SETTINGS="$SHAMT_SOURCE_DIR/.shamt/host/claude/settings.starter.json"
    TARGET_SETTINGS="$TARGET_DIR/.claude/settings.json"
    if [ -f "$TARGET_SETTINGS" ]; then
        echo "  ✓ .claude/settings.json already exists — skipping"
    elif [ -f "$STARTER_SETTINGS" ]; then
        sed "s|\${PROJECT}|$TARGET_DIR|g" "$STARTER_SETTINGS" > "$TARGET_SETTINGS"
        echo "  ✓ .claude/settings.json written"
    else
        echo "  ⚠  settings.starter.json not found — skipping"
    fi

    # Update ai_service.conf if not already set
    AI_SERVICE_CONF="$SHAMT_DIR/config/ai_service.conf"
    if [ ! -f "$AI_SERVICE_CONF" ] || [ "$(cat "$AI_SERVICE_CONF")" != "claude_code" ]; then
        mkdir -p "$SHAMT_DIR/config"
        echo "claude_code" > "$AI_SERVICE_CONF"
        echo "  ✓ ai_service.conf updated to claude_code"
    fi

    echo ""
    echo "  ⚠  Trust reminder: ensure this project is trusted in Claude Code."
fi

# --- Codex host wiring --------------------------------------------------------

if [ "$HOST" = "codex" ]; then
    echo "  Adding Codex host wiring..."
    echo ""

    mkdir -p "$TARGET_DIR/.codex/agents"
    echo "  ✓ .codex/ directory structure created"

    # Model resolution: prompt if missing
    MODEL_RESOLUTION="$SHAMT_DIR/host/codex/.model_resolution.local.toml"
    mkdir -p "$SHAMT_DIR/host/codex"
    if [ ! -f "$MODEL_RESOLUTION" ]; then
        echo "  Codex model names (from Codex changelog — press Enter to accept defaults):"
        read -rp "    Frontier model [o3]: " _frontier
        _frontier="${_frontier:-o3}"
        read -rp "    Default model  [o4-mini]: " _default
        _default="${_default:-o4-mini}"
        printf 'FRONTIER_MODEL = "%s"\nDEFAULT_MODEL = "%s"\n' "$_frontier" "$_default" > "$MODEL_RESOLUTION"
        echo "  ✓ .model_resolution.local.toml written"
    else
        echo "  ✓ .model_resolution.local.toml already exists"
    fi

    # Write starter config.toml
    STARTER_CONFIG="$SHAMT_SOURCE_DIR/.shamt/host/codex/config.starter.toml"
    TARGET_CONFIG="$TARGET_DIR/.codex/config.toml"
    if [ -f "$TARGET_CONFIG" ]; then
        echo "  ✓ .codex/config.toml already exists — skipping initial write"
    elif [ -f "$STARTER_CONFIG" ]; then
        cp "$STARTER_CONFIG" "$TARGET_CONFIG"
        echo "  ✓ .codex/config.toml written from starter"
    else
        echo "  ⚠  config.starter.toml not found — skipping"
    fi

    # Copy requirements.toml.template to project root
    REQUIREMENTS_TPL="$SHAMT_SOURCE_DIR/.shamt/host/codex/requirements.toml.template"
    TARGET_REQUIREMENTS="$TARGET_DIR/requirements.toml"
    if [ -f "$TARGET_REQUIREMENTS" ]; then
        echo "  ✓ requirements.toml already exists — skipping"
    elif [ -f "$REQUIREMENTS_TPL" ]; then
        cp "$REQUIREMENTS_TPL" "$TARGET_REQUIREMENTS"
        echo "  ✓ requirements.toml written"
    else
        echo "  ⚠  requirements.toml.template not found — skipping"
    fi

    # Run regen to populate .codex/ from canonical content
    REGEN_SCRIPT="$SHAMT_SOURCE_DIR/.shamt/scripts/regen/regen-codex-shims.sh"
    if [ -f "$REGEN_SCRIPT" ]; then
        bash "$REGEN_SCRIPT"
        echo "  ✓ Codex shims generated"
    else
        echo "  ⚠  regen-codex-shims.sh not found — run it manually"
    fi

    # Update ai_service.conf — use claude_codex if Claude Code was already registered
    AI_SERVICE_CONF="$SHAMT_DIR/config/ai_service.conf"
    mkdir -p "$SHAMT_DIR/config"
    _existing=""
    [ -f "$AI_SERVICE_CONF" ] && _existing="$(tr -d '[:space:]' < "$AI_SERVICE_CONF")"
    if [ "$_existing" = "claude_code" ]; then
        echo "claude_codex" > "$AI_SERVICE_CONF"
        echo "  ✓ ai_service.conf updated to claude_codex (dual-host)"
    else
        echo "codex" > "$AI_SERVICE_CONF"
        echo "  ✓ ai_service.conf updated to codex"
    fi
fi

echo ""
echo "============================================================"
echo "  Host '$HOST' wiring complete."
echo "============================================================"
echo ""
