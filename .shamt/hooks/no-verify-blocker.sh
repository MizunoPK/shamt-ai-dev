#!/usr/bin/env bash
# PreToolUse (Bash) — Reject git commit --no-verify or --no-gpg-sign.
# Claude Code passes the tool input JSON on stdin.
# Exit 2 to block; exit 0 to allow.

set -euo pipefail

input="$(cat)"

if echo "$input" | grep -qE -- '--no-verify|--no-gpg-sign'; then
    echo "SHAMT HOOK BLOCKED: --no-verify and --no-gpg-sign are forbidden." >&2
    echo "Fix the underlying hook issue instead of bypassing it." >&2
    exit 2
fi

exit 0
