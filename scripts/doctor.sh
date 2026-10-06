#!/usr/bin/env bash
# Checks that everything /deliver needs is in place.
#   scripts/doctor.sh              → tools + user-level install (~/.claude)
#   scripts/doctor.sh <repo path>  → also the repo (git, project-level install, .deliver.json)
set -uo pipefail

ok=0 warn=0 bad=0
pass() { printf '  \033[32m✔\033[0m %s\n' "$1"; ok=$((ok+1)); }
note() { printf '  \033[33m!\033[0m %s\n' "$1"; warn=$((warn+1)); }
fail() { printf '  \033[31m✘\033[0m %s\n' "$1"; bad=$((bad+1)); }
have() { command -v "$1" >/dev/null 2>&1; }
vge() { printf '%s\n%s\n' "$2" "$1" | sort -V -C; }   # vge <have> <need> → have >= need

repo="${1:-}"
[[ -z $repo ]] || repo="$(cd "$repo" 2>/dev/null && pwd)" || { echo "no such directory: $1"; exit 1; }

echo "Required tools"
if have claude; then
  v="$(claude --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  if vge "${v:-0}" 2.1.0; then pass "Claude Code $v"; else note "Claude Code ${v:-?} — update (claude update); the kit needs plugin agents, skills with frontmatter and hook agent_type"; fi
else fail "Claude Code (claude) not on PATH"; fi
if have git; then gv="$(git --version | awk '{print $3}')"; vge "$gv" 2.38 && pass "git $gv" || fail "git $gv — need 2.38+ (worktrees, rev-parse --path-format)"; else fail "git"; fi
have jq && pass "jq $(jq --version)" || fail "jq — brew install jq / apt install jq"
if have node; then
  nv="$(node -v | tr -d v)"; [[ ${nv%%.*} -ge 18 ]] && pass "node $nv" || fail "node $nv — need 18+"
else fail "node 18+ — brew install node"; fi

# How Claude Code signs in — Michael and every Claude seat use the same: a login, an API key, a cloud provider, or a gateway
echo "Claude authentication"
senv() { [[ -n ${!1:-} ]] || jq -e --arg k "$1" '.env[$k] // empty' "$HOME/.claude/settings.json" >/dev/null 2>&1; }
if senv CLAUDE_CODE_USE_BEDROCK; then pass "Amazon Bedrock (CLAUDE_CODE_USE_BEDROCK) — AWS credentials from the usual AWS chain"
elif senv CLAUDE_CODE_USE_VERTEX; then pass "Google Vertex AI (CLAUDE_CODE_USE_VERTEX) — gcloud application-default credentials"
elif senv ANTHROPIC_BASE_URL; then pass "an LLM gateway (ANTHROPIC_BASE_URL) — its key in ANTHROPIC_AUTH_TOKEN or ANTHROPIC_API_KEY"
elif senv ANTHROPIC_API_KEY; then pass "Anthropic API key (ANTHROPIC_API_KEY) — billed per token on your Console account"
elif senv CLAUDE_CODE_OAUTH_TOKEN; then pass "a long-lived login token (CLAUDE_CODE_OAUTH_TOKEN, from claude setup-token)"
elif [[ -f $HOME/.claude/.credentials.json ]] || jq -e '.oauthAccount' "$HOME/.claude.json" >/dev/null 2>&1; then pass "Claude login (/login — your Claude subscription)"
elif [[ $(uname) == Darwin ]]; then note "no API key or token set — a /login is kept in the macOS Keychain (not checked here); if claude asks you to log in, run it once"
else note "no sign-in found — run claude once and /login, or set ANTHROPIC_API_KEY (docs/02-setup.md § Claude authentication)"; fi

echo "Optional tools"
have gh && pass "gh (PR creation)" || note "gh not found — needed for merge_mode human/semi/auto (gh auth login)"
have timeout && pass "timeout (gate_timeout for verify commands)" || note "timeout not found — verify commands run without a time limit (brew install coreutils)"
have adb && pass "adb (mobile / ARTEMIS)" || note "adb not found — only for mobile jobs"

echo "ECC plugin"
ipj="$HOME/.claude/plugins/installed_plugins.json"
if jq -e '.plugins | keys[] | select(startswith("ecc@"))' "$ipj" >/dev/null 2>&1 \
   || ls -d "$HOME"/.claude/plugins/cache/ecc* >/dev/null 2>&1; then
  ecc_dir="$(ls -d "$HOME"/.claude/plugins/cache/ecc/*/* 2>/dev/null | tail -1)"
  pass "ecc installed${ecc_dir:+ ($ecc_dir)}"
  if [[ -n $ecc_dir ]]; then
    miss=""
    for a in planner architect code-reviewer typescript-reviewer security-reviewer e2e-runner; do [[ -f $ecc_dir/agents/$a.md ]] || miss+=" $a"; done
    [[ -z $miss ]] && pass "ecc agents present (planner, architect, reviewers, e2e-runner)" || fail "ecc agents missing:$miss — update ECC (/plugin update ecc@ecc)"
    miss=""
    for s in tdd-workflow backend-patterns frontend-patterns; do [[ -d $ecc_dir/skills/$s ]] || miss+=" $s"; done
    [[ -z $miss ]] && pass "ecc skills present (tdd-workflow, backend-patterns, frontend-patterns)" || note "ecc skills missing:$miss — dev agents load them on demand"
  fi
  prof="${ECC_HOOK_PROFILE:-standard}"
  note "ECC hook profile: $prof. GateGuard (standard/strict) asks for facts before the first edit of each file; the kit exempts .work/ bookkeeping (GATEGUARD_EXEMPT_GLOBS). Set ECC_GATEGUARD=off if agents loop on it"
else
  if [[ -d $HOME/.claude/plugins/marketplaces/ecc ]]; then
    fail "ECC marketplace is added but the plugin is NOT installed → in Claude Code: /plugin install ecc@ecc, then restart"
  else
    fail "ECC not found → in Claude Code: /plugin marketplace add https://github.com/affaan-m/ECC  then  /plugin install ecc@ecc"
  fi
fi
[[ -f $HOME/.claude/agents/planner.md && -f $HOME/.claude/agents/architect.md ]] \
  && note "ECC agents also found in ~/.claude/agents (ECC's own install.sh?) — use ONE install path, or agents/hooks load twice"

check_install() { # check_install <claude dir> <label>
  local d=$1 label=$2 a h s
  [[ -f $d/skills/deliver/SKILL.md ]] || return 1
  pass "$label: deliver skill"
  for a in backend-dev frontend-dev mobile-dev; do
    [[ -f $d/agents/$a.md ]] && pass "$label: agent $a" || note "$label: agent $a missing"
  done
  [[ -x $d/skills/deliver/bin/dl ]] && pass "$label: dl executable" || fail "$label: dl not executable (chmod +x)"
  s=$d/settings.json
  for h in stop-guard bash-guard write-guard agent-guard subagent-log; do
    grep -qE "run\.mjs[\\\"]* $h|$h\.sh" "$s" 2>/dev/null && pass "$label: hook $h" || fail "$label: hook $h not in $s (re-run install.sh)"
  done
  for h in "$d"/skills/deliver*.bak* "$d"/skills/deliver.bak*; do
    [[ -e $h ]] && fail "$label: stale backup $h is loaded as a second skill — delete it (newer install.sh backs up to .deliver-backups/)"
  done
  return 0
}

echo "Kit install"
found=0
check_install "$HOME/.claude" "user" && found=1
if [[ -n $repo ]]; then check_install "$repo/.claude" "project" && found=1; fi
# As a plugin (/plugin install deliver@deliver-floor): skill, agents and hooks come from the plugin; settings.json only
# carries what a plugin cannot set (scripts/install.sh --plugin).
pdir="$(jq -r '[.plugins | to_entries[] | select(.key | startswith("deliver@")) | .value[].installPath] | last // empty' "$ipj" 2>/dev/null)"
if [[ -n $pdir && -d $pdir ]]; then
  pass "plugin: deliver ($pdir)"
  [[ -x $pdir/skills/deliver/bin/dl ]] && pass "plugin: dl executable" || fail "plugin: dl not executable — reinstall the plugin"
  for h in stop-guard bash-guard write-guard agent-guard subagent-log; do
    grep -qE "run\.mjs[\\\"]* $h" "$pdir/hooks/hooks.json" 2>/dev/null && pass "plugin: hook $h" || fail "plugin: hook $h missing from hooks/hooks.json — update the plugin"
  done
  [[ "$(jq -r '.env.GATEGUARD_EXEMPT_GLOBS // empty' "$HOME/.claude/settings.json" 2>/dev/null)" == .work/* ]] \
    && pass "plugin: settings carry the GateGuard exemption" || note "plugin: the GateGuard exemption is not in ~/.claude/settings.json yet — the plugin's first session writes it (restart once), or scripts/install.sh --user --plugin"
  [[ $found -eq 1 ]] && fail "a copy of the kit beside the plugin (copied into .claude/) — its /deliver shadows the plugin's: one Claude Code session with the plugin deletes a copy in ~/.claude; a repo's own copy goes with scripts/install.sh --project <repo> --uninstall"
  [[ -x $pdir/../../../../data/deliver-deliver-floor/bin/dl ]] && pass "plugin: the stable dl for Michael's brief ($(cd "$pdir/../../../../data/deliver-deliver-floor/bin" && pwd)/dl)" \
    || note "plugin: the stable dl is written by the plugin's first session (start Claude Code once)"
  found=1
fi
[[ $found -eq 1 ]] || fail "deliver kit not installed → /plugin install deliver@deliver-floor (or scripts/init.sh)"
note "your commands are /deliver:<command> in Claude Code (/deliver:status, /deliver:answer …) — no dl needed in a terminal"

echo "Munder Difflin (the default run mode)"
if [[ -n ${HIVE_ROOT:-} ]]; then
  pass "running inside Munder Difflin (HIVE_ROOT=$HIVE_ROOT)"
  [[ -d $HIVE_ROOT/spawn-requests ]] && pass "spawn-requests/ exists (dispatch=munder possible once Settings → Autonomy allows worker spawning)" \
    || note "no spawn-requests/ yet — dispatch=munder needs worker spawning enabled in Settings → Autonomy & Budgets"
elif compgen -G "$HOME/Library/Application Support/*[Mm]under*" >/dev/null || compgen -G "${XDG_CONFIG_HOME:-$HOME/.config}/*[Mm]under*" >/dev/null; then
  pass "Munder Difflin app data found (run doctor from an agent terminal on the floor to check the hive)"
  # Michael's terminal on the floor is an interactive claude: in a HOME that never finished Claude Code's first run it
  # opens on the first-run screens and swallows the first message (docs/07 § 5).
  jq -e '.hasCompletedOnboarding == true' "$HOME/.claude.json" >/dev/null 2>&1 \
    && pass "Claude Code first run completed (Michael's terminal on the floor opens ready)" \
    || note "Claude Code's first run is not completed in this HOME — run 'claude' once before opening the floor (docs/07-munder-difflin.md § 5)"
  # /deliver seats a person per role for the whole job (dl md-hire): Michael must be allowed to seat people, seats wait
  # between tasks and must not be reaped after the default 20 idle minutes, and a job's 6–10 seats must not queue behind 4.
  mcfg="$(ls -d "$HOME/Library/Application Support/munder-difflin/config.json" "${XDG_CONFIG_HOME:-$HOME/.config}/munder-difflin/config.json" 2>/dev/null | head -1)"
  if [[ -n $mcfg ]]; then
    jq -e '.orchestratorMaySpawn == true' "$mcfg" >/dev/null 2>&1 && pass "Michael may seat people (orchestratorMaySpawn)" \
      || fail "orchestratorMaySpawn is off — Michael cannot seat anyone: Settings → Autonomy & Budgets, or scripts/init.sh --munder"
    v="$(jq -r '.workerIdleTimeoutMinutes // 20' "$mcfg")"
    (( v >= 480 )) && pass "seats are not sent home while they wait (workerIdleTimeoutMinutes $v)" \
      || fail "workerIdleTimeoutMinutes is $v — seats waiting between tasks get reaped: set ≥ 480 in $mcfg (scripts/init.sh --munder does)"
    v="$(jq -r '.maxConcurrentWorkers // 4' "$mcfg")"
    (( v >= 12 )) && pass "room for a whole team (maxConcurrentWorkers $v)" \
      || fail "maxConcurrentWorkers is $v — a job's seats queue behind it: set ≥ 12 in $mcfg (scripts/init.sh --munder does)"
  fi
else
  md_missing=1
  note "Munder Difflin not detected — it is the default run mode: scripts/init.sh --munder --hive <dir>, or choose Claude Code subagents by hand (\"dispatch\": \"subagent\" in .deliver.json — docs/07-munder-difflin.md#choosing-the-mode)"
fi
# Which Munder Difflin: /deliver's seats need the fork's floor fixes (a spawn-queue worker gets a first prompt and appears on
# the floor). Upstream lacks them and its seats never start. The fix leaves a fingerprint in the build: the first prompt.
md_fixed() { grep -q 'Your task was sent to your hive inbox' "$1/out/main/index.js" 2>/dev/null; }
mddir="${MUNDER_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/munder-difflin}"
if [[ -d $mddir/.git ]]; then
  mdhead="$(git -C "$mddir" rev-parse HEAD 2>/dev/null)"
  pass "init's Munder Difflin: $(git -C "$mddir" remote get-url origin 2>/dev/null) @ ${mdhead:0:7} ($mddir)"
  if [[ ! -f $mddir/out/main/index.js ]]; then fail "…not built — scripts/init.sh --munder --hive <hive>"
  elif md_fixed "$mddir"; then pass "…built with the floor fixes (seats get a first prompt and appear on the floor)"
  else fail "…built without the floor fixes: /deliver seats never start — scripts/init.sh --munder --hive <hive> installs the fork"; fi
  [[ "$(cat "$mddir/out/.built-from" 2>/dev/null)" == "$mdhead" ]] \
    || note "…its build is not from the checked-out commit — rebuild: cd $mddir && npm run build (or scripts/init.sh --munder)"
fi
# The running app can come from another checkout than init's: judge the one that runs (preview runs <checkout>/out).
while IFS= read -r d; do
  [[ -n $d ]] || continue
  if md_fixed "$d"; then pass "running Munder Difflin from $d — with the floor fixes"
  else fail "running Munder Difflin from $d — without the floor fixes (/deliver seats never start): quit it, start $mddir"; fi
done < <(ps -axo command= 2>/dev/null | sed -n -E 's#^(/.*)/node_modules/electron/dist/(Electron\.app/Contents/MacOS/Electron|electron) \.$#\1#p' | sort -u)

if [[ -n $repo ]]; then
  echo "Repo: $repo"
  if git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    pass "git repository"
    b="$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null)" && pass "on branch $b" || note "detached HEAD — set base_branch in .deliver.json"
    git -C "$repo" rev-parse -q --verify HEAD >/dev/null && pass "has commits" || fail "no commits yet — make an initial commit first"
    [[ -z "$(git -C "$repo" status --porcelain --untracked-files=no)" ]] && pass "working tree clean" || note "uncommitted changes in the main checkout — jobs branch from the last commit, not from these"
    git -C "$repo" remote get-url origin >/dev/null 2>&1 && pass "remote origin" || note "no remote 'origin' — use merge_mode local"
    if [[ -n "$(git -C "$repo" config user.email)" ]]; then pass "git identity set"; else fail "git user.email not set — dev agents cannot commit"; fi
  else
    fail "not a git repository"
  fi
  if [[ -f $repo/.deliver.json ]]; then
    if jq -e . "$repo/.deliver.json" >/dev/null 2>&1; then
      pass ".deliver.json valid: $(jq -c '{verify_full,worktree_setup,merge_mode,dispatch}' "$repo/.deliver.json")"
      mm="$(jq -r '.merge_mode // (if .merge_strategy == "local" then "local" else "human" end)' "$repo/.deliver.json")"
      case $mm in human|semi|auto|local) ;; *) fail "merge_mode '$mm' — use human | semi | auto | local" ;; esac
      if [[ $mm != local ]] && ! git -C "$repo" remote get-url origin >/dev/null 2>&1; then fail "merge_mode=$mm opens a PR but there is no remote — set \"merge_mode\": \"local\""; fi
      if [[ $mm != local ]] && ! have gh; then fail "merge_mode=$mm needs the GitHub CLI (gh auth login)"; fi
    else fail ".deliver.json is not valid JSON"; fi
  else
    note "no .deliver.json yet — the first /deliver (or dl config --init) writes one from what the repo says (test script, lockfile, remote). See docs/03-settings.md"
  fi
  disp="$(jq -r '.dispatch // empty' "$repo/.deliver.json" 2>/dev/null || true)"
  [[ -n $disp ]] || disp="$(jq -r '.dispatch // empty' "${DELIVER_HOME:-$HOME/.deliver}/config.json" 2>/dev/null || true)"   # the user's own config
  if [[ ${disp:-munder} == munder ]]; then
    pass "run mode: Munder Difflin floor (${disp:+chosen}${disp:-the default}) — give /deliver to Michael in the app"
    [[ ${md_missing:-0} == 1 ]] && fail "this repo runs on the Munder Difflin floor but the app is not installed — scripts/init.sh --munder --hive <dir> --repo $repo, or \"dispatch\": \"subagent\" in .deliver.json"
    [[ "$(jq -r '.munder.model // empty' "$repo/.deliver.json" 2>/dev/null)" == "" ]] && note "seats run on the kit's default model (munder.model: sonnet) — set munder.model to choose another; never the app's default"
  else
    pass "run mode: Claude Code subagents (dispatch: $disp, chosen in .deliver.json or ${DELIVER_HOME:-$HOME/.deliver}/config.json)"
  fi
  # what applies in this repo: kit defaults ⊕ the user's config ⊕ .deliver.json (as dl reads it)
  KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/kit/skills/deliver"
  eff="$(cat "$KIT/config.json")"
  for f in "${DELIVER_HOME:-$HOME/.deliver}/config.json" "$repo/.deliver.json"; do
    [[ -f $f ]] && eff="$(jq -s '.[0] * .[1]' <(printf '%s' "$eff") "$f" 2>/dev/null || printf '%s' "$eff")"
  done
  # Roles on other vendors' CLIs (Codex, Gemini, …) run only as seats on the floor; each CLI signs in its own way
  while IFS=$'\t' read -r role prov; do
    [[ -n $role ]] || continue
    [[ "$(jq -r '.dispatch' <<<"$eff")" == munder ]] || { fail "role $role runs on $prov — other CLIs run only on the Munder Difflin floor (dispatch munder)"; continue; }
    case $prov in codex) bin=codex ;; gemini) bin=gemini ;; qwen) bin=qwen ;; opencode) bin=opencode ;; crush) bin=crush ;; copilot) bin=copilot ;; cursor) bin=cursor-agent ;; *) bin="" ;; esac
    if [[ -z $bin ]]; then note "role $role runs on $prov — make sure its CLI is installed and signed in on this machine (Munder Difflin starts it)"
    elif have "$bin"; then pass "role $role runs on $prov ($(command -v "$bin")) — signed in with its own login or key (not checked)"
    else fail "role $role runs on $prov but '$bin' is not on PATH — install and sign in to it, or drop the provider"; fi
  done < <(jq -r '(.roles // {}) | to_entries[] | select((.value.provider // "claude") != "claude") | [.key, .value.provider] | @tsv' <<<"$eff")
  tk="$(jq -r '.tracker.kind // "local"' <<<"$eff")"; need=""
  case $tk in
    jira)   [[ -z ${JIRA_BASE_URL:-} ]] || [[ -z ${JIRA_PAT:-} && ( -z ${JIRA_EMAIL:-} || -z ${JIRA_API_TOKEN:-} ) ]] && need="JIRA_BASE_URL and JIRA_EMAIL + JIRA_API_TOKEN (Cloud) or JIRA_PAT (Data Center)" ;;
    asana)  [[ -n ${ASANA_TOKEN:-} ]] || need="ASANA_TOKEN (a personal access token)" ;;
    linear) [[ -n ${LINEAR_API_KEY:-} ]] || need="LINEAR_API_KEY" ;;
    github) [[ -n ${GITHUB_TOKEN:-}${GH_TOKEN:-} ]] || need="GITHUB_TOKEN (or GH_TOKEN) with access to the repo's issues and the project" ;;
  esac
  if [[ $tk != local ]]; then
    if [[ -n $need ]]; then fail "tracker $tk: set $need — docs/10-trackers.md#$tk"
    else
      tf="$(mktemp)"; printf '%s' "$eff" > "$tf"
      while IFS= read -r l; do case $l in "ok   "*) pass "$tk: ${l#ok   }" ;; *) fail "$tk: ${l#FAIL }" ;; esac; done < <(node "$KIT/bin/tracker-cli.mjs" check "$tf" 2>&1)
      rm -f "$tf"
    fi
  fi
  [[ -f $repo/.work/ACTIVE ]] && note "active job: $(cat "$repo/.work/ACTIVE")"
fi

echo
echo "result: $ok ok, $warn warning(s), $bad problem(s)"
[[ $bad -eq 0 ]]
