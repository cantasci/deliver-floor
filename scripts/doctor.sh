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

repo="${1:-}"

echo "Required tools"
if have claude; then
  v="$(claude --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  IFS=. read -r ma mi pa <<<"$v"
  if (( ma > 2 || (ma == 2 && mi >= 1 && pa >= 200) )); then pass "Claude Code $v"; else note "Claude Code $v — update recommended (claude update); kit was written against 2.1.28x"; fi
else fail "Claude Code (claude) not on PATH"; fi
have git && pass "git $(git --version | awk '{print $3}')" || fail "git"
have jq && pass "jq $(jq --version)" || fail "jq — brew install jq"
if have node; then
  nv="$(node -v | tr -d v)"; [[ ${nv%%.*} -ge 18 ]] && pass "node $nv" || fail "node $nv — need 18+"
else fail "node 18+ — brew install node"; fi

echo "Optional tools"
have gh && pass "gh (PR creation)" || note "gh not found — needed only for merge_strategy=pr (brew install gh && gh auth login)"
have tmux && pass "tmux (agent-team split panes)" || note "tmux not found — only for agent-teams split-pane mode"
have adb && pass "adb (mobile / ARTEMIS)" || note "adb not found — only for mobile jobs"

echo "ECC plugin"
if jq -e '.plugins | keys[] | select(startswith("ecc@"))' "$HOME/.claude/plugins/installed_plugins.json" >/dev/null 2>&1 \
   || ls -d "$HOME"/.claude/plugins/cache/ecc* >/dev/null 2>&1; then
  pass "ecc installed"
else
  if [[ -d $HOME/.claude/plugins/marketplaces/ecc ]]; then
    fail "ECC marketplace is added but the plugin is NOT installed → in Claude Code: /plugin install ecc@ecc, then restart"
  else
    fail "ECC not found → in Claude Code: /plugin marketplace add https://github.com/affaan-m/ECC  then  /plugin install ecc@ecc"
  fi
fi

check_install() { # check_install <claude dir> <label>
  local d=$1 label=$2 a
  [[ -f $d/skills/deliver/SKILL.md ]] || return 1
  pass "$label: deliver skill"
  for a in backend-dev frontend-dev mobile-dev; do
    [[ -f $d/agents/$a.md ]] && pass "$label: agent $a" || note "$label: agent $a missing"
  done
  [[ -x $d/skills/deliver/bin/dl ]] && pass "$label: dl executable" || fail "$label: dl not executable (chmod +x)"
  local s=$d/settings.json
  for h in stop-guard bash-guard subagent-log; do
    grep -q "$h.sh" "$s" 2>/dev/null && pass "$label: hook $h" || fail "$label: hook $h not in $s (re-run install.sh)"
  done
  return 0
}

echo "Kit install"
found=0
check_install "$HOME/.claude" "user" && found=1
if [[ -n $repo ]]; then check_install "$repo/.claude" "project" && found=1; fi
[[ $found -eq 1 ]] || fail "deliver kit not installed → scripts/install.sh --user (or --project <repo>)"

if [[ -n $repo ]]; then
  echo "Repo: $repo"
  if git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    pass "git repository"
    b="$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null)" && pass "on branch $b" || note "detached HEAD — set base_branch in .deliver.json"
    [[ -z "$(git -C "$repo" status --porcelain --untracked-files=no)" ]] && pass "working tree clean" || note "uncommitted changes in the main checkout — jobs branch from the last commit, not from these"
    git -C "$repo" remote get-url origin >/dev/null 2>&1 && pass "remote origin" || note "no remote 'origin' — use merge_strategy=local"
  else
    fail "not a git repository"
  fi
  if [[ -f $repo/.deliver.json ]]; then
    jq -e . "$repo/.deliver.json" >/dev/null 2>&1 && pass ".deliver.json valid: $(jq -c '{verify_full,worktree_setup,merge_strategy}' "$repo/.deliver.json")" || fail ".deliver.json is not valid JSON"
  else
    note "no .deliver.json — defaults apply (verify_full: npm test, no worktree_setup). See docs/03-settings.md"
  fi
  [[ -f $repo/.work/ACTIVE ]] && note "active job: $(cat "$repo/.work/ACTIVE")"
fi

echo
echo "result: $ok ok, $warn warning(s), $bad problem(s)"
[[ $bad -eq 0 ]]
