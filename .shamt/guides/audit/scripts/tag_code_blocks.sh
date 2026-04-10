#!/bin/bash
# Tag untagged code blocks with appropriate language identifiers

set -euo pipefail

GUIDES_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$GUIDES_DIR"

echo "Tagging untagged code blocks..."
echo

# Count before
BEFORE=$(grep -rc '^```$' . --include="*.md" | grep -v ':0$' | cut -d: -f2 | awk '{sum+=$1} END {print sum}' || echo "0")
echo "Untagged blocks before: ${BEFORE:-0}"
echo

# Use Python for correct state-tracking (awk mishandles already-tagged blocks)
find . -name "*.md" -type f | while read -r file; do
    python3 - "$file" << 'PYEOF'
import sys

filepath = sys.argv[1]
with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

in_block = False       # Are we tracking an untagged block (collecting content)?
tagged_block = False   # Are we inside an already-tagged block (not collecting)?
buffer = []            # Buffered lines for untagged block
output = []
changed = False

def determine_tag(content_lines):
    """Determine language tag from code block content."""
    content = '\n'.join(content_lines)
    # Check each line individually for heuristics
    for line in content_lines:
        stripped = line.strip()
        if stripped.startswith(('$ ', 'cd ', 'ls ', 'grep ', 'git ', 'bash', 'echo ',
                                 'cat ', 'mkdir', 'rm ', 'mv ', 'cp ', 'chmod', '# !')):
            return 'bash'
    for line in content_lines:
        stripped = line.strip()
        if stripped.startswith(('## ', '# ', '**', '- [', '> ')):
            return 'markdown'
        if stripped.startswith(('{', '}')):
            return 'json'
        if any(c in stripped for c in ('├', '│', '└', '┌', '─', '═', '║')):
            return 'text'
    return 'text'

for line in lines:
    stripped = line.rstrip('\n\r')
    eol = '\r\n' if line.endswith('\r\n') else '\n' if line.endswith('\n') else ''

    is_bare_fence = (stripped == '```')
    is_tagged_fence = (stripped.startswith('```') and len(stripped) > 3 and stripped[3].isalpha())

    if is_bare_fence:
        if not in_block and not tagged_block:
            # Bare fence while not in any block = untagged opening, start collecting
            in_block = True
            buffer = []
        elif in_block:
            # Bare fence while collecting = closing of untagged block
            in_block = False
            tag = determine_tag(buffer)
            # Print tagged opening
            output.append('```' + tag + eol)
            # Print collected content
            for buf_line in buffer:
                output.append(buf_line)
            # Print bare closing
            output.append('```' + eol)
            buffer = []
            changed = True
            continue
        elif tagged_block:
            # Bare fence while inside tagged block = closing of tagged block
            tagged_block = False
            output.append(line)
        else:
            output.append(line)
        continue

    elif is_tagged_fence:
        if not in_block and not tagged_block:
            # Tagged fence while not in any block = already-tagged opening
            tagged_block = True
            output.append(line)
        elif tagged_block:
            # Tagged fence while inside tagged block = shouldn't happen (treat as closing)
            tagged_block = False
            output.append('```' + eol)
            changed = True
        elif in_block:
            # Tagged fence while collecting = shouldn't happen; flush buffer as text
            in_block = False
            tag = determine_tag(buffer)
            output.append('```' + tag + eol)
            for buf_line in buffer:
                output.append(buf_line)
            output.append('```' + eol)
            buffer = []
            # Now open this tagged block
            tagged_block = True
            output.append(line)
            changed = True
        continue

    else:
        # Regular line
        if in_block:
            buffer.append(line)
        else:
            output.append(line)

if changed:
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(output)
    print(f'✓ Tagged blocks in: {filepath}')
PYEOF
done

echo
echo "Tagging complete!"
echo

# Count after
AFTER=$(grep -rc '^```$' . --include="*.md" | grep -v ':0$' | cut -d: -f2 | awk '{sum+=$1} END {print sum}' || echo "0")
echo "Untagged blocks after: ${AFTER:-0}"
echo "Tagged: $((${BEFORE:-0} - ${AFTER:-0})) blocks"
