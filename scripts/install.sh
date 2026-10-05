#!/usr/bin/env bash
# Installs the /deliver kit into Claude Code.
#
#   scripts/install.sh --user                 → ~/.claude            (every project)
#   scripts/install.sh --project <repo path>  → <repo>/.claude       (one project, can be committed)
#   add --dry-run to only print what would happen, --uninstall to remove the kit again
#   --plugin: the kit itself comes from the plugin (/plugin install deliver@deliver-floor); only merge the settings a
#   plugin cannot set (env, attribution) into <target>/settings.json — no files are copied, no hooks are added
#   --keep-attribution: keep Claude Code's "Co-Authored-By"/"Generated with" lines in commits and PRs
#   (by default the kit sets attribution.commit/pr to "" so delivered history carries no AI attribution)
#
# Copies: kit/agents/*.md, kit/skills/deliver/, kit/hooks/deliver/
# Merges: kit/settings.hooks.json into <target>/settings.json (backup first, no duplicates, existing env kept)
# Backups go to <target>/.deliver-backups/<timestamp>/ — never next to the originals, where Claude Code
# would load a backed-up skill or agent as a second copy.
# Does NOT install ECC — do that inside Claude Code: /plugin install ecc@ecc
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIT="$HERE/kit"
mode="" target="" dry=0 uninstall=0 keep_attr=0 plugin=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --user) mode=user; target="$HOME/.claude"; shift ;;
    --project) mode=project; target="$(cd "${2:?repo path required}" && pwd)/.claude"; shift 2 ;;
    --dry-run) dry=1; shift ;;
    --uninstall) uninstall=1; shift ;;
    --keep-attribution) keep_attr=1; shift ;;
    --plugin) plugin=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done
[[ -n $mode ]] || { sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
command -v jq >/dev/null || { echo "jq is required: brew install jq / apt install jq" >&2; exit 1; }

run() { if [[ $dry -eq 1 ]]; then echo "DRY: $*"; else "$@"; fi; }
ts="$(date +%Y%m%d-%H%M%S)"
backup_dir="$target/.deliver-backups/$ts"

backup() { # backup <path> — moves it under .deliver-backups, keeping its relative path
  local p=$1 rel=${1#"$target"/}
  local dst="$backup_dir/$rel" n=1
  while [[ -e $dst ]]; do n=$((n + 1)); dst="$backup_dir/$rel.$n"; done   # two installs in one second: never mv into an old backup
  run mkdir -p "$(dirname "$dst")"
  run mv "$p" "$dst"; echo "backup: $dst"
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
# Hooks run through node (run.mjs finds bash — Git Bash on Windows — for the .sh guards); the dir is quoted for spaces.
if [[ $mode == user ]]; then hooks_dir="\"$target/hooks/deliver\""; else hooks_dir='"${CLAUDE_PROJECT_DIR}/.claude/hooks/deliver"'; fi
snippet="$(jq --arg d "$hooks_dir" --argjson keep "$keep_attr" '(.. | objects | select(has("command")) | .command) |= sub("__HOOKS_DIR__"; $d)
  | if $keep == 1 then del(.attribution) else . end' "$KIT/settings.hooks.json")"
# The plugin brings its own hooks (kit/hooks/hooks.json); settings.json only gets env and attribution.
[[ $plugin -eq 1 ]] && snippet="$(jq 'del(.hooks)' <<<"$snippet")"
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
  [[ $plugin -eq 1 ]] || for f in "$KIT"/agents/*.md; do [[ -e $target/agents/$(basename "$f") ]] && backup "$target/agents/$(basename "$f")"; done
  [[ $plugin -eq 0 && -e $target/skills/deliver ]] && backup "$target/skills/deliver"
  [[ $plugin -eq 0 && -e $target/hooks/deliver ]] && backup "$target/hooks/deliver"
  # Remove every hook entry whose command points into hooks/deliver/, and our env keys if unchanged.
  cleaned="$(jq --argjson k "$snippet" '
    (if .hooks then .hooks |= (with_entries(.value |= map(select(([.hooks[]?.command] | any(test("hooks/deliver[/\"]"))) | not)))
                               | with_entries(select(.value | length > 0))) else . end)
    | (if .env then .env |= with_entries(select(. as $e | ($k.env[$e.key] // null) != $e.value)) else . end)
    | (if .attribution == $k.attribution then del(.attribution) else . end)
    | (if .env == {} then del(.env) else . end) | (if .hooks == {} then del(.hooks) else . end)' <<<"$current")"
  write_settings "$cleaned"
  echo "Uninstalled. Backups: $backup_dir   (ECC is untouched: /plugin uninstall ecc@ecc if you want it gone)"
  exit 0
fi

# The installed config.json holds the shipped defaults and copy() replaces it. What the user changed there moves into their
# own file first ($DELIVER_HOME/config.json — dl reads it over the defaults; plugin updates never touch it), so a reinstall
# keeps it. "Changed" = differs from the defaults installed last time (recorded below), not from today's defaults.
user_cfg="${DELIVER_HOME:-$HOME/.deliver}/config.json"; defaults_rec="${DELIVER_HOME:-$HOME/.deliver}/config.installed-defaults.json"
keep_user_settings() {
  local old="$target/skills/deliver/config.json" base="$KIT/skills/deliver/config.json" diff
  [[ -f $old ]] || return 0
  [[ -f $defaults_rec ]] && base="$defaults_rec"
  diff="$(jq -n --slurpfile o "$old" --slurpfile n "$base" '
    def d(o; n): reduce (o | keys[]) as $k ({};
      if (n | has($k) | not) then .[$k] = o[$k]
      elif o[$k] == n[$k] then .
      elif (o[$k] | type) == "object" and (n[$k] | type) == "object" then (d(o[$k]; n[$k])) as $v | if $v == {} then . else .[$k] = $v end
      else .[$k] = o[$k] end);
    d($o[0]; $n[0])')" || return 0
  [[ $diff != "{}" ]] || return 0
  if [[ $dry -eq 1 ]]; then echo "DRY: would keep your settings in $user_cfg: $(jq -c . <<<"$diff")"; return 0; fi
  mkdir -p "$(dirname "$user_cfg")"
  if [[ -f $user_cfg ]]; then jq -s '.[0] * .[1]' <(printf '%s' "$diff") "$user_cfg" > "$user_cfg.tmp"   # the user file wins
  else jq . <<<"$diff" > "$user_cfg.tmp"; fi
  mv "$user_cfg.tmp" "$user_cfg"; echo "kept your settings: $user_cfg $(jq -c . <<<"$diff")"
}

if [[ $plugin -eq 0 ]]; then
  for f in "$KIT"/agents/*.md; do copy "$f" "$target/agents/$(basename "$f")"; done
  keep_user_settings
  copy "$KIT/skills/deliver" "$target/skills/deliver"
  [[ $dry -eq 1 ]] || { mkdir -p "$(dirname "$defaults_rec")"; cp "$KIT/skills/deliver/config.json" "$defaults_rec"; }
  copy "$KIT/hooks/deliver" "$target/hooks/deliver"
  run chmod +x "$target/skills/deliver/bin/dl" "$target/skills/deliver/bin/"*.mjs "$target"/hooks/deliver/*.sh
fi

# Append our hook entries per event, skipping any whose command is already present; add env keys only if unset.
merged="$(jq --argjson k "$snippet" '
  (if ($k.attribution != null and .attribution == null and .includeCoAuthoredBy == null) then .attribution = $k.attribution else . end)
  | .env = (($k.env // {}) + ((.env // {}) | with_entries(select(
      # keep the user'"'"'s own values; replace values an older kit version wrote (they mention .work/)
      (($k.env[.key] // null) == null) or ((.value | tostring | test("\\.work/")) | not)))))
  # entries an older kit version wrote (…/hooks/deliver/<name>.sh) are replaced, never kept beside the new ones
  | .hooks = ((.hooks // {}) | with_entries(.value |= map(select(([.hooks[]?.command // ""] | any(test("hooks/deliver/[a-z-]+\\.sh"))) | not))))
  | .hooks = ((.hooks // {}) as $h
    | reduce (($k.hooks // {}) | keys[]) as $ev ($h;
        .[$ev] = ((.[$ev] // []) + [ $k.hooks[$ev][]
          | select(.hooks[0].command as $c | ([$h[$ev][]?.hooks[]?.command] | index($c)) | not) ])))
' <<<"$current")"
if [[ "$(jq -S . <<<"$merged")" == "$(jq -S . <<<"$current")" ]]; then echo "unchanged: $settings"; else write_settings "$merged"; fi

if [[ $plugin -eq 1 ]]; then
  cat <<EOF

Done (settings only — the plugin brings the skill, agents and hooks). Next steps:
  1. In Claude Code:   /plugin marketplace add https://github.com/cantasci/deliver-floor
                       /plugin install deliver@deliver-floor
                       /plugin marketplace add https://github.com/affaan-m/ECC
                       /plugin install ecc@ecc        (if not installed yet), then restart Claude Code
  2. Start a job:      /deliver <what you want built>   (or /deliver:deliver; agents are called deliver:<name> — ROLES.md lists them)
EOF
  exit 0
fi
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
