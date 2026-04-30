#!/usr/bin/env bash
# PreToolUse (Bash) — Enforce feat/SHAMT-N: or fix/SHAMT-N: commit prefix.
# Allows commits that use -m flag with a well-formed message.
# Passes through commits that don't use -m (e.g., -F file, --amend without msg).

set -euo pipefail

input="$(cat)"

# Only intercept commands containing `git commit` with a -m flag
if ! echo "$input" | grep -q 'git commit'; then
    exit 0
fi
if ! echo "$input" | grep -qE -- '-m'; then
    exit 0
fi

# Extract the commit message value following -m
msg="$(echo "$input" | python3 -c "
import sys, json, re
data = sys.stdin.read()
try:
    obj = json.loads(data)
    cmd = obj.get('command', '')
except Exception:
    cmd = data
# Extract value after -m flag (single or double quoted, or heredoc \$(cat <<EOF)
m = re.search(r'-m\s+[\"\'](.*?)[\"\']', cmd, re.DOTALL)
if m:
    print(m.group(1)[:200])
" 2>/dev/null || true)"

if [ -z "$msg" ]; then
    exit 0  # couldn't parse message — allow (agent will catch format errors in review)
fi

# Validate prefix: feat/SHAMT-N: or fix/SHAMT-N: (also allow docs/, chore/, sync:, ci:)
if echo "$msg" | grep -qE '^(feat|fix|docs|chore|sync|ci)/[A-Z]+-[0-9]+:'; then
    exit 0
fi

# Also allow top-level conventional prefixes without a ticket (e.g., "sync: ..." for export commits)
if echo "$msg" | grep -qE '^(sync|docs|chore|ci|test):'; then
    exit 0
fi

echo "SHAMT HOOK BLOCKED: Commit message does not match required prefix." >&2
echo "Expected: feat/SHAMT-N: ... or fix/SHAMT-N: ..." >&2
echo "Got: $msg" >&2
exit 2
