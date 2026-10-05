#!/usr/bin/env bash
# Writes the /deliver brief into a Munder Difflin hive folder — see kit/skills/deliver/bin/md-brief.sh.
#   scripts/md-brief.sh <hive dir> [repo …]      (DELIVER_SKILL_DIR: the installed skill, default ~/.claude/skills/deliver)
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DELIVER_SKILL_DIR="${DELIVER_SKILL_DIR:-$HOME/.claude/skills/deliver}" exec bash "$HERE/kit/skills/deliver/bin/md-brief.sh" "$@"
