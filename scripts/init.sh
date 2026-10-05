#!/usr/bin/env bash
# init — one command from a bare machine to a working /deliver setup.
#
#   scripts/init.sh                                   ECC plugin + the kit (user level) + doctor
#   scripts/init.sh --repo <path>                     … and a .deliver.json for that repo (if it has none)
#   scripts/init.sh --munder [--munder-dir <dir>] --hive <dir> [--repo <path>]
#                                                     … and Munder Difflin from source: clone, install, native
#                                                       modules, build, configure (hive, worker spawning, knowledge
#                                                       graph), and teach Michael to run /deliver
#   --munder-repo <url|path>  where Munder Difflin comes from (default: the fork the kit needs — MD_REPO below)
#   --munder-ref <branch|tag> which branch or tag of it (default: that repo's default branch)
#   --project <repo>   install the kit into <repo>/.claude instead of ~/.claude
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

repo="" hive="" munder=0 mddir="${XDG_DATA_HOME:-$HOME/.local/share}/munder-difflin" project="" skip_onb=0 ecc=1
while [[ $# -gt 0 ]]; do
  case $1 in
    --repo) repo="$(cd "${2:?}" && pwd)"; shift 2 ;;
    --hive) hive="$2"; shift 2 ;;
    --munder) munder=1; shift ;;
    --munder-dir) mddir="$2"; shift 2 ;;
    --munder-repo) MD_REPO="$2"; shift 2 ;;
    --munder-ref) MD_REF="$2"; shift 2 ;;
    --project) project="$(cd "${2:?}" && pwd)"; shift 2 ;;
    --skip-onboarding) skip_onb=1; shift ;;
    --no-ecc) ecc=0; shift ;;
    -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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

step "deliver kit"
if [[ -n $project ]]; then "$HERE/scripts/install.sh" --project "$project"; else "$HERE/scripts/install.sh" --user; fi | grep -E "installed|updated|unchanged|backup" || true

if [[ -n $repo && ! -f $repo/.deliver.json ]]; then
  step ".deliver.json for $repo"
  verify="npm test"; [[ -f $repo/package.json ]] || verify=""
  [[ -f $repo/pyproject.toml || -f $repo/requirements.txt ]] && verify="pytest -q"
  [[ -f $repo/go.mod ]] && verify="go test ./..."
  mm=human; git -C "$repo" remote get-url origin >/dev/null 2>&1 || mm=local
  jq -n --arg v "${verify:-echo set verify_full && false}" --arg m "$mm" '{verify_full:$v, worktree_setup:"", merge_mode:$m}' > "$repo/.deliver.json"
  cat "$repo/.deliver.json"; echo "(edit verify_full / worktree_setup to match the repo — docs/03-settings.md)"
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
    jq '.dispatch = "munder"' "$repo/.deliver.json" > "$repo/.deliver.json.tmp" 2>/dev/null && mv "$repo/.deliver.json.tmp" "$repo/.deliver.json" \
      || echo '{"dispatch":"munder"}' > "$repo/.deliver.json"
    echo "$repo/.deliver.json: dispatch=munder (cards run as floor workers)"
  fi
  step "teach Michael /deliver ($hive/CLAUDE.md)"
  "$HERE/scripts/md-brief.sh" "$hive" ${repo:+"$repo"}
  echo "start it: cd $mddir && npm run preview      (Linux root/containers: ELECTRON_DISABLE_SANDBOX=1 … -- --no-sandbox)"
fi

step "doctor"
"$HERE/scripts/doctor.sh" ${repo:+"$repo"} || true
