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
  [[ $found -eq 1 ]] && fail "the kit is installed twice (plugin AND copied into .claude/) — skill and hooks load twice: scripts/install.sh --user --uninstall, then scripts/install.sh --user --plugin"
  found=1
fi
[[ $found -eq 1 ]] || fail "deliver kit not installed → /plugin install deliver@deliver-floor + scripts/install.sh --user --plugin, or scripts/install.sh --user (or --project <repo>)"
have dl && pass "dl on PATH ($(command -v dl))" || note "dl not on PATH — only for you in a terminal: ln -sf ~/.claude/skills/deliver/bin/dl ~/.local/bin/dl"

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
  [[ -f $repo/.work/ACTIVE ]] && note "active job: $(cat "$repo/.work/ACTIVE")"
fi

echo
echo "result: $ok ok, $warn warning(s), $bad problem(s)"
[[ $bad -eq 0 ]]
