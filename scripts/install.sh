#!/usr/bin/env bash
# Installs the /deliver kit into Claude Code.
#
#   scripts/install.sh --user                 → ~/.claude            (every project)
#   scripts/install.sh --project <repo path>  → <repo>/.claude       (one project, can be committed)
#   add --dry-run to only print what would happen
#
# Copies: kit/agents/*.md, kit/skills/deliver/, kit/hooks/deliver/
# Merges: kit/settings.hooks.json into <target>/settings.json (backup first, no duplicates)
# Does NOT install ECC — do that inside Claude Code: /plugin install ecc@ecc
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIT="$HERE/kit"
mode="" target="" dry=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --user) mode=user; target="$HOME/.claude"; shift ;;
    --project) mode=project; target="$(cd "${2:?repo path required}" && pwd)/.claude"; shift 2 ;;
    --dry-run) dry=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done
[[ -n $mode ]] || { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
command -v jq >/dev/null || { echo "jq is required: brew install jq" >&2; exit 1; }

run() { if [[ $dry -eq 1 ]]; then echo "DRY: $*"; else "$@"; fi; }
ts="$(date +%Y%m%d-%H%M%S)"

copy() { # copy <src> <dst> — skips if identical, backs up an existing different destination
  local src=$1 dst=$2
  if [[ -e $dst ]]; then
    if diff -rq "$src" "$dst" >/dev/null 2>&1; then echo "unchanged: $dst"; return 0; fi
    run mv "$dst" "$dst.bak.$ts"; echo "backup: $dst.bak.$ts"
  fi
  run mkdir -p "$(dirname "$dst")"
  run cp -R "$src" "$dst"
}

echo "target: $target"
for f in "$KIT"/agents/*.md; do copy "$f" "$target/agents/$(basename "$f")"; done
copy "$KIT/skills/deliver" "$target/skills/deliver"
copy "$KIT/hooks/deliver" "$target/hooks/deliver"
run chmod +x "$target/skills/deliver/bin/dl" "$target/skills/deliver/bin/validate.mjs" "$target"/hooks/deliver/*.sh

# Hook commands: absolute path for --user, $CLAUDE_PROJECT_DIR for --project (portable when committed)
if [[ $mode == user ]]; then hooks_dir="$target/hooks/deliver"; else hooks_dir='"${CLAUDE_PROJECT_DIR}"/.claude/hooks/deliver'; fi
snippet="$(jq --arg d "$hooks_dir" '(.. | objects | select(has("command")) | .command) |= sub("__HOOKS_DIR__"; $d)' "$KIT/settings.hooks.json")"

settings="$target/settings.json"
if [[ -f $settings ]]; then current="$(cat "$settings")"; else current='{}'; fi
# Append our hook entries per event, skipping any whose command is already present.
merged="$(jq --argjson k "$snippet" '
  .hooks = ((.hooks // {}) as $h
    | reduce ($k.hooks | keys[]) as $ev ($h;
        .[$ev] = ((.[$ev] // []) + [ $k.hooks[$ev][]
          | select(.hooks[0].command as $c | ([$h[$ev][]?.hooks[]?.command] | index($c)) | not) ])))
' <<<"$current")"

if [[ $dry -eq 1 ]]; then
  echo "DRY: would write these hooks into $settings:"; jq '.hooks' <<<"$merged"
else
  [[ -f $settings ]] && cp "$settings" "$settings.bak.$ts" && echo "backup: $settings.bak.$ts"
  printf '%s\n' "$merged" > "$settings"
  echo "hooks merged into $settings"
fi

repo_arg=""; [[ $mode == project ]] && repo_arg=" $(dirname "$target")"
cat <<EOF

Done. Next steps:
  1. In Claude Code:   /plugin install ecc@ecc   (if not installed yet), then restart Claude Code
  2. Check everything: $HERE/scripts/doctor.sh$repo_arg
  3. Per repo (optional): add .deliver.json at the repo root to override settings (docs/03-settings.md)
  4. Start a job:      /deliver <what you want built>
EOF
