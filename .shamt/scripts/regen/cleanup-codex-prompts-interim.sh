#!/usr/bin/env bash
# =============================================================================
# cleanup-codex-prompts-interim.sh — Remove stale Shamt skill prompts from
# ~/.codex/prompts/ after migrating to .agents/skills/<name>/SKILL.md
# =============================================================================
# Run this once after upgrading to SHAMT-53 (Codex Skills GA migration).
# For each shamt-*.md in ~/.codex/prompts/, checks whether the corresponding
# .agents/skills/ entry exists and removes it if so. Warns for any that cannot
# be matched.
#
# Usage:
#   bash .shamt/scripts/regen/cleanup-codex-prompts-interim.sh
#
# Safe to re-run: already-removed files are silently ignored.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CODEX_PROMPTS_DIR="$HOME/.codex/prompts"
AGENTS_SKILLS_DIR="$PROJECT_ROOT/.agents/skills"

removed=0
warned=0

echo ""
echo "============================================================"
echo "  Shamt: Cleanup interim Codex skill prompts"
echo "============================================================"
echo "  Scanning: $CODEX_PROMPTS_DIR/shamt-*.md"
echo "  Checking against: $AGENTS_SKILLS_DIR/"
echo "============================================================"
echo ""

if [ ! -d "$CODEX_PROMPTS_DIR" ]; then
    echo "  ~/.codex/prompts/ not found — nothing to clean up."
    echo ""
    exit 0
fi

while IFS= read -r -d '' prompt_file; do
    filename="$(basename "$prompt_file")"
    # Strip leading "shamt-" and trailing ".md" → skill directory name
    # e.g. shamt-shamt-validator.md → shamt-validator
    # The interim files were written as shamt-${skill_name}.md where skill_name
    # was already the full directory name (e.g. shamt-validator), so the file
    # was named shamt-shamt-validator.md. Handle both patterns.
    skill_name="${filename%.md}"        # strip .md
    skill_name="${skill_name#shamt-}"   # strip leading "shamt-"

    agents_skill="$AGENTS_SKILLS_DIR/${skill_name}/SKILL.md"

    if [ -f "$agents_skill" ]; then
        rm "$prompt_file"
        echo "  Removed: $prompt_file"
        removed=$((removed + 1))
    else
        echo "  WARN: $prompt_file — no matching .agents/skills/${skill_name}/SKILL.md found; left in place"
        warned=$((warned + 1))
    fi
done < <(find "$CODEX_PROMPTS_DIR" -maxdepth 1 -name "shamt-*.md" -print0 2>/dev/null | sort -z)

echo ""
echo "  Removed: $removed  |  Warnings: $warned"
echo ""

if [ "$warned" -gt 0 ]; then
    echo "  Check warnings above. Run regen-codex-shims.sh first to populate"
    echo "  .agents/skills/, then re-run this script."
    echo ""
fi
