#!/usr/bin/env bash
# Installs the /deliver kit into Claude Code.
#
#   scripts/install.sh --user                 → ~/.claude            (every project)
#   scripts/install.sh --project <repo path>  → <repo>/.claude       (one project, can be committed)
#   add --dry-run to only print what would happen, --uninstall to remove the kit again
#
# Copies: kit/agents/*.md, kit/skills/deliver/, kit/hooks/deliver/
# Merges: kit/settings.hooks.json into <target>/settings.json (backup first, no duplicates, existing env kept)
# Backups go to <target>/.deliver-backups/<timestamp>/ — never next to the originals, where Claude Code
# would load a backed-up skill or agent as a second copy.
# Does NOT install ECC — do that inside Claude Code: /plugin install ecc@ecc
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIT="$HERE/kit"
mode="" target="" dry=0 uninstall=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --user) mode=user; target="$HOME/.claude"; shift ;;
    --project) mode=project; target="$(cd "${2:?repo path required}" && pwd)/.claude"; shift 2 ;;
    --dry-run) dry=1; shift ;;
    --uninstall) uninstall=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done
[[ -n $mode ]] || { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
command -v jq >/dev/null || { echo "jq is required: brew install jq / apt install jq" >&2; exit 1; }

run() { if [[ $dry -eq 1 ]]; then echo "DRY: $*"; else "$@"; fi; }
ts="$(date +%Y%m%d-%H%M%S)"
backup_dir="$target/.deliver-backups/$ts"

backup() { # backup <path> — moves it under .deliver-backups, keeping its relative path
  local p=$1 rel=${1#"$target"/}
  run mkdir -p "$(dirname "$backup_dir/$rel")"
  run mv "$p" "$backup_dir/$rel"; echo "backup: $backup_dir/$rel"
}

copy() { # copy <src> <dst> — skips if identical, backs up an existing different destination
  local src=$1 dst=$2
  if [[ -e $dst ]]; then
    if diff -rq "$src" "$dst" >/dev/null 2>&1; then echo "unchanged: $dst"; return 0; fi
    backup "$dst"
  fi
  run mkdir -p "$(dirname "$dst")"
  run cp -R "$src" "$dst"; echo "installed: $dst"
}

# Hook commands: absolute path for --user, $CLAUDE_PROJECT_DIR for --project (portable when committed)
if [[ $mode == user ]]; then hooks_dir="$target/hooks/deliver"; else hooks_dir='"${CLAUDE_PROJECT_DIR}"/.claude/hooks/deliver'; fi
snippet="$(jq --arg d "$hooks_dir" '(.. | objects | select(has("command")) | .command) |= sub("__HOOKS_DIR__"; $d)' "$KIT/settings.hooks.json")"
settings="$target/settings.json"
if [[ -f $settings ]]; then current="$(cat "$settings")"; else current='{}'; fi
jq -e . >/dev/null 2>&1 <<<"$current" || { echo "$settings is not valid JSON — fix it first" >&2; exit 1; }

write_settings() { # write_settings <json>
  if [[ $dry -eq 1 ]]; then echo "DRY: would write $settings:"; jq '{env, hooks}' <<<"$1"; return; fi
  if [[ -f $settings ]]; then mkdir -p "$backup_dir"; cp "$settings" "$backup_dir/settings.json"; echo "backup: $backup_dir/settings.json"; fi
  mkdir -p "$target"; printf '%s\n' "$1" > "$settings"; echo "updated: $settings"
}

echo "target: $target"

if [[ $uninstall -eq 1 ]]; then
  for f in "$KIT"/agents/*.md; do [[ -e $target/agents/$(basename "$f") ]] && backup "$target/agents/$(basename "$f")"; done
  [[ -e $target/skills/deliver ]] && backup "$target/skills/deliver"
  [[ -e $target/hooks/deliver ]] && backup "$target/hooks/deliver"
  # Remove every hook entry whose command points into hooks/deliver/, and our env keys if unchanged.
  cleaned="$(jq --argjson k "$snippet" '
    (if .hooks then .hooks |= (with_entries(.value |= map(select(([.hooks[]?.command] | any(test("hooks/deliver/"))) | not)))
                               | with_entries(select(.value | length > 0))) else . end)
    | (if .env then .env |= with_entries(select(. as $e | ($k.env[$e.key] // null) != $e.value)) else . end)
    | (if .env == {} then del(.env) else . end) | (if .hooks == {} then del(.hooks) else . end)' <<<"$current")"
  write_settings "$cleaned"
  echo "Uninstalled. Backups: $backup_dir   (ECC is untouched: /plugin uninstall ecc@ecc if you want it gone)"
  exit 0
fi

for f in "$KIT"/agents/*.md; do copy "$f" "$target/agents/$(basename "$f")"; done
copy "$KIT/skills/deliver" "$target/skills/deliver"
copy "$KIT/hooks/deliver" "$target/hooks/deliver"
run chmod +x "$target/skills/deliver/bin/dl" "$target/skills/deliver/bin/"*.mjs "$target"/hooks/deliver/*.sh

# Append our hook entries per event, skipping any whose command is already present; add env keys only if unset.
merged="$(jq --argjson k "$snippet" '
  .env = (($k.env // {}) + (.env // {}))
  | .hooks = ((.hooks // {}) as $h
    | reduce ($k.hooks | keys[]) as $ev ($h;
        .[$ev] = ((.[$ev] // []) + [ $k.hooks[$ev][]
          | select(.hooks[0].command as $c | ([$h[$ev][]?.hooks[]?.command] | index($c)) | not) ])))
' <<<"$current")"
if [[ "$(jq -S . <<<"$merged")" == "$(jq -S . <<<"$current")" ]]; then echo "unchanged: $settings"; else write_settings "$merged"; fi

repo_arg=""; [[ $mode == project ]] && repo_arg=" $(dirname "$target")"
cat <<EOF

Done. Next steps:
  1. In Claude Code:   /plugin marketplace add https://github.com/affaan-m/ECC
                       /plugin install ecc@ecc        (if not installed yet), then restart Claude Code
  2. dl on your PATH:  ln -sf "$target/skills/deliver/bin/dl" ~/.local/bin/dl     (or an alias)
  3. Check everything: $HERE/scripts/doctor.sh$repo_arg
  4. Per repo:         add .deliver.json at the repo root (verify_full, worktree_setup — docs/03-settings.md)
  5. Start a job:      /deliver <what you want built>
EOF
