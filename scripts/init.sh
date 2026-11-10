#!/usr/bin/env bash
# init — one command from a bare machine to a working /deliver setup.
#
#   scripts/init.sh                                   ECC plugin + the deliver plugin (user level) + doctor
#   scripts/init.sh --repo <path>                     … and a .deliver.json for that repo (if it has none)
#   --kit-from <url|path>  the marketplace the deliver plugin comes from (default: KIT_MARKET below; a local checkout
#                      for testing a change before it is released)
#   --project <repo>   copy the kit into <repo>/.claude (committed, a version pinned in the repo) instead of the plugin
#   --no-ecc           do not touch the ECC plugin
#
# Idempotent: every step checks first and only does what is missing. Run with bash -x to see every command.
set -euo pipefail
# grep -q exits on the first match; under pipefail the producer then dies of SIGPIPE and the pipe fails at random. gq reads to EOF.
gq() { grep "$@" >/dev/null; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ECC_MARKET="https://github.com/affaan-m/ECC"
KIT_MARKET="https://github.com/cantasci/deliver-floor"

repo="" project="" ecc=1
while [[ $# -gt 0 ]]; do
  case $1 in
    --repo) repo="$(cd "${2:?}" && pwd)"; shift 2 ;;
    --project) project="$(cd "${2:?}" && pwd)"; shift 2 ;;
    --kit-from) KIT_MARKET="$2"; shift 2 ;;
    --no-ecc) ecc=0; shift ;;
    --subagent) shift ;;   # accepted for older callers: subagents are the only mode
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done
step() { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
need() { command -v "$1" >/dev/null || { echo "init: '$1' is required — $2" >&2; exit 1; }; }

step "tools"
need git "install git"; need jq "brew install jq / apt install jq"; need node "Node 18+ (brew install node)"; need claude "Claude Code: https://claude.com/claude-code"
echo "claude $(claude --version | awk 'NR==1') · node $(node -v) · git $(git --version | awk '{print $3}')"

if [[ $ecc -eq 1 ]]; then
  step "ECC plugin"
  if claude plugin list 2>/dev/null | gq "ecc@ecc"; then echo "ecc@ecc already installed"
  else
    claude plugin marketplace list 2>/dev/null | gq -i "ecc" || claude plugin marketplace add "$ECC_MARKET"
    claude plugin install ecc@ecc
  fi
fi

# The kit is the plugin — one copy, updated by Claude Code. Never also copied into ~/.claude: that copy shadows the plugin's
# /deliver and kept Michael on an old version however often the plugin updated (seen on a user's machine).
step "deliver plugin"
skill=""
if [[ -n $project ]]; then
  "$HERE/scripts/install.sh" --project "$project" | grep -E "installed|updated|unchanged|backup" || true
  skill="$project/.claude/skills/deliver"
else
  claude plugin marketplace list 2>/dev/null | gq "deliver-floor" || claude plugin marketplace add "$KIT_MARKET"
  if claude plugin list 2>/dev/null | gq "deliver@deliver-floor"; then claude plugin update deliver@deliver-floor || true
  else claude plugin install deliver@deliver-floor; fi
  root="$(jq -r '.plugins["deliver@deliver-floor"] | if type == "array" then .[0] else . end | .installPath // empty' \
    "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json" 2>/dev/null || true)"
  [[ -n $root && -d $root ]] || { echo "init: the deliver plugin did not install (claude plugin list)" >&2; exit 1; }
  echo "deliver plugin: $root"
  node "$root/hooks/deliver/copied-kit.mjs" "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" "$root"   # a copy from an older init goes
  "$HERE/scripts/install.sh" --user --plugin | grep -E "updated|unchanged|backup" || true   # env and attribution only
  skill="$root/skills/deliver"
  # the stable dl Michael's brief names (the plugin's first session writes it too)
  data="$(cd "$root/../../../.." && pwd)/data/deliver-deliver-floor"; mkdir -p "$data/bin"
  printf '#!/usr/bin/env bash\n# Written by the deliver plugin at every session start: runs the plugin version that session loaded.\nexec bash "%s" "$@"\n' "$skill/bin/dl" > "$data/bin/dl"
  chmod +x "$data/bin/dl"
fi

if [[ -n $repo && ! -f $repo/.deliver.json ]]; then
  step ".deliver.json for $repo"
  (cd "$repo" && "$HERE/kit/skills/deliver/bin/dl" config --init)   # read from the repo: test script, lockfile, remote
  echo "(every key: docs/03-settings.md)"
fi
step "doctor"
"$HERE/scripts/doctor.sh" ${repo:+"$repo"} || true
