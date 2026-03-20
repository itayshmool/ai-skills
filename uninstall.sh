#!/usr/bin/env bash
# uninstall.sh — Remove symlinks from ~/.claude/skills/ that point into this repo

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${SCRIPT_DIR}/claude"
SKILLS_DIR="${HOME}/.claude/skills"

removed=0

if [[ ! -d "$SKILLS_DIR" ]]; then
    echo "No skills directory at ${SKILLS_DIR}. Nothing to do."
    exit 0
fi

for entry in "$SKILLS_DIR"/*/; do
    link="${entry%/}"
    [[ -L "$link" ]] || continue

    link_target="$(readlink "$link")"
    if [[ "$link_target" == "${CLAUDE_DIR}"* ]]; then
        rm "$link"
        echo "  [REMOVED] $(basename "$link")"
        ((removed++))
    fi
done

echo ""
echo "Done: ${removed} symlinks removed."
