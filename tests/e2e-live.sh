#!/usr/bin/env bash
# LIVE end-to-end test — real Claude Code, real ECC plugin, real agents. No mocks, no replay, no hand-holding.
# It does exactly what a user does on a fresh machine, then checks the result from the outside:
#   1. fresh HOME → install ECC from GitHub (/plugin marketplace add + install)   [skipped if already there]
#   2. scripts/install.sh --user → scripts/doctor.sh
#   3. scripts/sandbox.sh → a new git repo from examples/<example>/seed
#   4. scripts/run-headless.sh <repo> "<path to the requirements .md>"  — the ONLY input is the requirements file
#   5. verify: job reached done, every card was assigned + gated + QA-passed + reviewed + merged on the same commit,
#      roles were derived from the request, role cards exist, verify_full passes on main, and the hidden oracle passes.
#
#   tests/e2e-live.sh [work dir] [example]       (needs API access; costs real tokens — a 2-card job ≈ a few dollars)
#   Env: PERMISSION_MODE (default bypassPermissions in this throwaway sandbox), E2E_ROUNDS (default 8)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
W="${1:-$(mktemp -d "${TMPDIR:-/tmp}/deliver-e2e.XXXXXX")}"; EXN="${2:-watchlist-poc}"; EX="$HERE/examples/$EXN"
mkdir -p "$W"; W="$(cd "$W" && pwd)"
export ISO_HOME="$W/home"; mkdir -p "$ISO_HOME"
. "$HERE/tests/lib-isolated-claude.sh"
export PERMISSION_MODE="${PERMISSION_MODE:-bypassPermissions}" IS_SANDBOX=1
export GIT_AUTHOR_NAME=e2e GIT_AUTHOR_EMAIL=e2e@example.com GIT_COMMITTER_NAME=e2e GIT_COMMITTER_EMAIL=e2e@example.com
LOG="$W/e2e.log"; : > "$LOG"
step() { printf '\n\033[1;36m━━ %s\033[0m\n' "$*" | tee -a "$LOG"; }
pass=0 fail=0
ok()  { printf '  \033[32m✔\033[0m %s\n' "$1" | tee -a "$LOG"; pass=$((pass+1)); }
bad() { printf '  \033[31m✘\033[0m %s\n' "$1" | tee -a "$LOG"; fail=$((fail+1)); }

step "1 · ECC plugin (fresh HOME: $ISO_HOME)"
if iso_env claude plugin list 2>/dev/null | grep -q "ecc@ecc"; then echo "  already installed"
else
  iso_env claude plugin marketplace add https://github.com/affaan-m/ECC 2>&1 | tail -1
  iso_env claude plugin install ecc@ecc 2>&1 | tail -1
fi

step "2 · install the kit + doctor"
iso_env "$HERE/scripts/install.sh" --user 2>&1 | tail -3
SB="$W/repo"
step "3 · sandbox repo from examples/$EXN/seed"
rm -rf "$SB"; iso_env "$HERE/scripts/sandbox.sh" "$SB" "$EXN" | tail -2
iso_env "$HERE/scripts/doctor.sh" "$SB" 2>&1 | grep -E "✘|result:" | tee -a "$LOG"

step "4 · run — the only input is the requirements file: $EX/JOB.md"
start=$(date +%s)
iso_env DELIVER_HEADLESS=1 "$HERE/scripts/run-headless.sh" "$SB" "$EX/JOB.md" "${E2E_ROUNDS:-8}" 2>&1 | tee -a "$LOG"
echo "  wall time: $(( ($(date +%s) - start) / 60 )) min" | tee -a "$LOG"

step "5 · verify from the outside"
J="$(ls -d "$SB"/.work/JOB-* 2>/dev/null | head -1)"
if [[ -z $J ]]; then bad "no job was created"; echo "result: $pass passed, $fail failed"; exit 1; fi
JJ="$J/job.json"; B="$J/board.json"
phase="$(jq -r .phase "$JJ")"
[[ $phase == done ]] && ok "job reached done" || bad "job phase is '$phase' (expected done)"
[[ "$(jq -r .shipped "$JJ")" == true ]] && ok "job shipped ($(jq -r .settings.merge_mode "$JJ"))" || bad "job not shipped"
jq -e '[.roles[].role] | (index("ba") and index("qa") and (map(select(startswith("reviewer"))) | length > 0))' "$JJ" >/dev/null \
  && ok "roles: $(jq -r '[.roles[].role] | join(", ")' "$JJ")" || bad "roles incomplete: $(jq -c '[.roles[].role]' "$JJ")"
jq -e '[.roles[] | select(.why == null or .why == "")] | length == 0' "$JJ" >/dev/null && ok "every role has a reason" || bad "a role has no reason"
for r in $(jq -r '.roles[] | select(.agent != "artemis") | .role' "$JJ"); do [[ -f $J/roles/$r.md ]] || bad "role card missing: $r"; done
[[ -f $J/ROLES.md ]] && ok "role cards generated ($(ls "$J/roles" | wc -l))" || bad "ROLES.md missing"
n="$(jq '.cards | length' "$B")"; [[ $n -ge 1 ]] && ok "board has $n card(s)" || bad "empty board"
jq -r '.cards[] | select(.state != "archived") | .id' "$B" | while read -r c; do
  q() { jq -r --arg id "$c" ".cards[] | select(.id==\$id) | $1" "$B"; }
  st="$(q .state)"; h="$(q .gate.head)"
  [[ $st == merged ]] || { echo "  ✘ $c state $st" | tee -a "$LOG"; continue; }
  [[ "$(q '.assignments | length')" -ge 1 && "$(q '.assignments[0].by')" == michael ]] || echo "  ✘ $c not assigned by michael" | tee -a "$LOG"
  [[ "$(q .gate.result)" == PASS && "$(q .qa.verdict)" == pass && "$(q .qa.head)" == "$h" && "$(q .review.verdict)" == approve && "$(q .review.head)" == "$h" ]] \
    && echo "  ✔ $c: assigned → $(q .agent) · gate PASS · QA pass · review approve · merged  (attempts $(q .attempts))" | tee -a "$LOG" \
    || echo "  ✘ $c: gate/QA/review records incomplete" | tee -a "$LOG"
done
grep -q "✘ T-" "$LOG" && bad "some cards did not go through the full chain" || ok "every card: assigned → dev → gate → QA → review → merged"
grep -q $'\tagent\tqa-tester' "$J/events.log" && ok "the QA role really ran (events.log)" || bad "no qa-tester run in events.log"
grep -qE $'\tagent\t(backend|frontend|mobile)-dev' "$J/events.log" && ok "dev roles really ran (events.log)" || bad "no dev agent run in events.log"
grep -qE $'\tagent\tbusiness-analyst' "$J/events.log" && ok "Business Analyst really ran" || bad "no business-analyst run"
for c in $(jq -r '.cards[].id' "$B"); do [[ -f $J/specs/$c.md ]] || bad "no BA spec for $c"; done
ls "$J"/specs/*.md >/dev/null 2>&1 && ok "BA specs: $(ls "$J/specs" | tr '\n' ' ')" || bad "no BA specs"
grep -qE $'\tagent\tecc:architect' "$J/events.log" && ok "Lead (ecc:architect) really ran" || bad "no ecc:architect run"
! cmp -s "$J/report.md" "$HERE/kit/skills/deliver/templates/report.md" && ok "report.md written" || bad "report.md is the template"
(cd "$SB" && node --test >/dev/null 2>&1) && ok "full test suite passes on main" || bad "tests fail on main"
if "$HERE/scripts/check-oracle.sh" "$SB" main "$EXN" > "$W/oracle.log" 2>&1; then ok "hidden oracle passes on main ($(grep -c '✔' "$W/oracle.log") checks)"
else bad "hidden oracle FAILED — see $W/oracle.log"; tail -30 "$W/oracle.log"; fi
cost="$(cat "$SB"/.work/runs/*.jsonl 2>/dev/null | jq -s '[.[] | select(.type=="result") | .total_cost_usd // 0] | add // 0')"
echo "  cost: \$$cost   artifacts: $W" | tee -a "$LOG"
echo; echo "result: $pass passed, $fail failed" | tee -a "$LOG"
[[ $fail -eq 0 ]]
