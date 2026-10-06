#!/usr/bin/env bash
# init — one command from a bare machine to a working /deliver setup.
#
#   scripts/init.sh                                   ECC plugin + the deliver plugin (user level) + doctor
#   scripts/init.sh --repo <path>                     … and a .deliver.json for that repo (if it has none)
#   scripts/init.sh --munder [--munder-dir <dir>] --hive <dir> [--repo <path>]
#                                                     … and Munder Difflin from source: clone, install, native
#                                                       modules, build, configure (hive, worker spawning, knowledge
#                                                       graph), and teach Michael to run /deliver
#   --subagent         the repo runs with Claude Code subagents instead of the Munder Difflin floor (the default)
#   --munder-repo <url|path>  where Munder Difflin comes from (default: the fork the kit needs — MD_REPO below)
#   --munder-ref <branch|tag> which branch or tag of it (default: that repo's default branch)
#   --kit-from <url|path>  the marketplace the deliver plugin comes from (default: KIT_MARKET below; a local checkout
#                      for testing a change before it is released)
#   --project <repo>   copy the kit into <repo>/.claude (committed, a version pinned in the repo) instead of the plugin
#   --skip-onboarding  mark Munder Difflin's first-run wizard as done (headless / CI setups)
#   --no-ecc           do not touch the ECC plugin
#
# Idempotent: every step checks first and only does what is missing. Run with bash -x to see every command.
set -euo pipefail
# grep -q exits on the first match; under pipefail the producer then dies of SIGPIPE and the pipe fails at random. gq reads to EOF.
gq() { grep "$@" >/dev/null; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# The fork, not upstream (chaitanyagiri/munder-difflin): /deliver's seats are spawn-queue workers, and only the fork gives
# them a first prompt, cards them on the floor and records why one failed to start — upstream, a seat never starts.
MD_REPO="https://github.com/cantasci/munder-difflin"
MD_REF=""
ECC_MARKET="https://github.com/affaan-m/ECC"
KIT_MARKET="https://github.com/cantasci/deliver-floor"

repo="" hive="" munder=0 subagent=0 mddir="${XDG_DATA_HOME:-$HOME/.local/share}/munder-difflin" project="" skip_onb=0 ecc=1
while [[ $# -gt 0 ]]; do
  case $1 in
    --repo) repo="$(cd "${2:?}" && pwd)"; shift 2 ;;
    --hive) hive="$2"; shift 2 ;;
    --munder) munder=1; shift ;;
    --subagent) subagent=1; shift ;;
    --munder-dir) mddir="$2"; shift 2 ;;
    --munder-repo) MD_REPO="$2"; shift 2 ;;
    --munder-ref) MD_REF="$2"; shift 2 ;;
    --project) project="$(cd "${2:?}" && pwd)"; shift 2 ;;
    --kit-from) KIT_MARKET="$2"; shift 2 ;;
    --skip-onboarding) skip_onb=1; shift ;;
    --no-ecc) ecc=0; shift ;;
    -h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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
[[ $munder == 1 && $subagent == 1 ]] && { echo "init: --munder and --subagent exclude each other" >&2; exit 1; }
if [[ -n $repo && $subagent == 1 ]]; then
  jq '.dispatch = "subagent"' "$repo/.deliver.json" > "$repo/.deliver.json.tmp" && mv "$repo/.deliver.json.tmp" "$repo/.deliver.json"
  echo "$repo/.deliver.json: dispatch=subagent (roles run as Claude Code subagents — chosen by hand)"
elif [[ $munder == 0 ]]; then
  echo "note: Munder Difflin is the default mode — add --munder --hive <dir> to install it, or --subagent --repo <path> to run with Claude Code subagents (docs/07-munder-difflin.md#choosing-the-mode)"
fi

if [[ $munder -eq 1 ]]; then
  [[ -n $hive ]] || { echo "init: --munder needs --hive <dir> (Michael's folder on the floor)" >&2; exit 1; }
  mkdir -p "$hive"; hive="$(cd "$hive" && pwd)"
  step "Munder Difflin source → $mddir"
  if [[ -d $mddir/.git ]]; then
    # An init-managed checkout: point it at MD_REPO (an older init cloned upstream) and move it to MD_REF, detached — a
    # local branch is never rewritten. npm install rewrites package-lock.json, so that file alone is not a local edit.
    cur="$(git -C "$mddir" remote get-url origin 2>/dev/null || true)"
    if [[ $cur != "$MD_REPO" ]]; then
      echo "origin: ${cur:-none} → $MD_REPO"
      git -C "$mddir" remote set-url origin "$MD_REPO" 2>/dev/null || git -C "$mddir" remote add origin "$MD_REPO"
    fi
    if [[ -n "$(git -C "$mddir" status --porcelain --untracked-files=no -- . ':!package-lock.json')" ]]; then
      echo "(local edits in $mddir — using the checkout as is)"
    elif git -C "$mddir" fetch -q --depth 1 origin "${MD_REF:-HEAD}"; then
      git -C "$mddir" checkout -q -- package-lock.json 2>/dev/null || true
      git -C "$mddir" checkout -q --detach FETCH_HEAD
    else
      echo "(could not fetch ${MD_REF:-the default branch} of $MD_REPO — using the checkout as is)"
    fi
  else git clone -q --depth 1 ${MD_REF:+--branch "$MD_REF"} "$MD_REPO" "$mddir"; fi
  cd "$mddir"
  echo "Munder Difflin: $MD_REPO${MD_REF:+ @ $MD_REF} → $(git rev-parse --short HEAD)"
  # Dependencies follow the committed lockfile: a new source with a new lockfile gets a fresh npm install.
  lock="$(git rev-parse -q --verify HEAD:package-lock.json 2>/dev/null || echo none)"
  if [[ ! -d node_modules/electron/dist || "$(cat .init-lock 2>/dev/null)" != "$lock" ]]; then
    # postinstall rebuilds native modules against Electron; it needs electron headers, which some networks block.
    npm install --no-audit --no-fund > "$mddir/.init-install.log" 2>&1 || echo "npm install reported an error (often only the native rebuild) — repairing below"
    echo "$lock" > .init-lock
  fi
  ev="$(jq -r .version node_modules/electron/package.json)"
  step "native modules for Electron $ev"
  if ! node -e "process.exit(require('fs').existsSync('node_modules/node-pty/build/Release/pty.node')?0:1)"; then
    # node-pty is N-API: building it against the local Node headers yields a binary Electron can load.
    (cd node_modules/node-pty && npx --yes node-gyp rebuild --nodedir="$(dirname "$(dirname "$(command -v node)")")" >/dev/null 2>&1) \
      || (cd node_modules/node-pty && npx --yes node-gyp rebuild >/dev/null)
  fi
  echo "node-pty: ok"
  # better-sqlite3 is not N-API: take the official Electron prebuild (GitHub release).
  (cd node_modules/better-sqlite3 && npx --yes prebuild-install --runtime electron --target "$ev" >/dev/null 2>&1) \
    || npx --yes @electron/rebuild -f -w better-sqlite3 >/dev/null
  echo "better-sqlite3: ok"
  node tools/ensure-pty-perms.cjs >/dev/null 2>&1 || true
  step "build"
  # A build belongs to one commit (out/.built-from): new source after a fetch is built again, not run from a stale out/.
  head="$(git rev-parse HEAD)"
  if [[ -f out/main/index.js && "$(cat out/.built-from 2>/dev/null)" == "$head" ]]; then echo "already built from $(git rev-parse --short HEAD)"
  else npm run build > "$mddir/.init-build.log" 2>&1; echo "$head" > out/.built-from; echo "built from $(git rev-parse --short HEAD)"; fi
  step "configure Munder Difflin"
  case "$(uname)" in Darwin) ud="$HOME/Library/Application Support/munder-difflin" ;; *) ud="${XDG_CONFIG_HOME:-$HOME/.config}/munder-difflin" ;; esac
  mkdir -p "$ud"; cfg="$ud/config.json"; [[ -f $cfg ]] || echo '{}' > "$cfg"
  jq --arg h "$hive" --arg r "${repo:-}" --argjson skip "$skip_onb" '
      .harnessHome = $h
    | .recentHives = ([$h] + ((.recentHives // []) - [$h]))
    | .registeredRepos = (((.registeredRepos // []) + (if $r != "" then [$r] else [] end)) | unique)
    | .orchestratorMaySpawn = true
    # /deliver seats a person per role for the whole job: they wait between tasks (QA for the devs, …), so the floor must not
    # reap them after 20 idle minutes, and a job with 6–10 seats must not queue behind the default limit of 4 workers.
    | .workerIdleTimeoutMinutes = ([.workerIdleTimeoutMinutes // 0, 480] | max)
    | .maxConcurrentWorkers = ([.maxConcurrentWorkers // 0, 12] | max)
    | .knowledgeGraph = ((.knowledgeGraph // {}) + {enabled: true})
    | (if $skip == 1 then .onboardingComplete = true | .audience = (.audience // "technical") else . end)' \
    "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
  echo "config: $cfg"; jq -c '{harnessHome, registeredRepos, orchestratorMaySpawn, workerIdleTimeoutMinutes, maxConcurrentWorkers, knowledgeGraph, onboardingComplete}' "$cfg"
  if [[ -n $repo ]]; then
    jq --arg h "$hive" '.dispatch = "munder" | .munder.hive_root = $h' "$repo/.deliver.json" > "$repo/.deliver.json.tmp" 2>/dev/null && mv "$repo/.deliver.json.tmp" "$repo/.deliver.json" \
      || jq -n --arg h "$hive" '{dispatch: "munder", munder: {hive_root: $h}}' > "$repo/.deliver.json"
    echo "$repo/.deliver.json: dispatch=munder, munder.hive_root=$hive (this repo's floor)"
  fi
  step "teach Michael /deliver ($hive/CLAUDE.md)"
  bash "$skill/bin/md-brief.sh" "$hive" ${repo:+"$repo"}
  echo "start it: cd $mddir && npm run preview      (Linux root/containers: ELECTRON_DISABLE_SANDBOX=1 npm run preview -- --noSandbox)"
fi

step "doctor"
"$HERE/scripts/doctor.sh" ${repo:+"$repo"} || true
