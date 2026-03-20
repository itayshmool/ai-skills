#!/usr/bin/env bash
# install.sh — Symlink skills from this repo into ~/.claude/skills/
#
# Usage:
#   ./install.sh           # Install (warns on conflicts)
#   ./install.sh --force   # Backup existing dirs and replace with symlinks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${SCRIPT_DIR}/claude"
SKILLS_DIR="${HOME}/.claude/skills"
FORCE=false

if [[ "${1:-}" == "--force" ]]; then
    FORCE=true
fi

mkdir -p "$SKILLS_DIR"

installed=0
skipped=0
backed_up=0
BACKUP_DIR=""

for category_dir in "$CLAUDE_DIR"/*/; do
    [[ -d "$category_dir" ]] || continue

    for skill_dir in "$category_dir"*/; do
        [[ -d "$skill_dir" ]] || continue

        skill_name="$(basename "$skill_dir")"
        target="${SKILLS_DIR}/${skill_name}"
        source="$(cd "$skill_dir" && pwd)"

        # Already linked correctly
        if [[ -L "$target" ]]; then
            existing="$(readlink "$target")"
            if [[ "$existing" == "$source" ]]; then
                ((installed++))
                continue
            else
                echo "  [RELINK] ${skill_name}"
                rm "$target"
            fi
        fi

        # Real directory exists
        if [[ -d "$target" && ! -L "$target" ]]; then
            if [[ "$FORCE" == true ]]; then
                if [[ -z "$BACKUP_DIR" ]]; then
                    BACKUP_DIR="${HOME}/.claude/skills-backup-$(date +%Y%m%d-%H%M%S)"
                    mkdir -p "$BACKUP_DIR"
                fi
                mv "$target" "${BACKUP_DIR}/${skill_name}"
                echo "  [BACKUP] ${skill_name}"
                ((backed_up++))
            else
                echo "  [SKIP]   ${skill_name} — real directory exists (use --force)"
                ((skipped++))
                continue
            fi
        fi

        # Non-directory file exists
        if [[ -e "$target" ]]; then
            echo "  [SKIP]   ${skill_name} — file exists at target"
            ((skipped++))
            continue
        fi

        ln -s "$source" "$target"
        echo "  [LINK]   ${skill_name}"
        ((installed++))
    done
done

echo ""
echo "Done: ${installed} linked, ${skipped} skipped, ${backed_up} backed up."
[[ $skipped -gt 0 ]] && echo "Run with --force to replace skipped directories."
[[ -n "$BACKUP_DIR" ]] && echo "Backups at: ${BACKUP_DIR}"
