#!/usr/bin/env bash
# Replay of a whole /deliver job on the 2-task Watchlist POC slice — WITHOUT a model.
# Every step Michael would take is printed with the real dl output, so you can watch the flow live.
# The PM/Lead outputs come from examples/watchlist-poc/reference/, and the "dev agents" copy the reference
# solution into their worktrees. T-01's first attempt deliberately touches a file outside its scope, so you
# also see the gate reject it and the retry. Every card is assigned by Michael, built by the dev role, tested by the
# QA role against its acceptance criteria, reviewed by the Lead reviewer, then merged. merge_mode=local delivers it;
# with a remote the same step opens the PR (human / semi / auto). At the end the hidden oracle judges the result.
#   tests/replay-watchlist.sh [sandbox dir]      (default: a temp dir, removed afterwards)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EX="$HERE/examples/watchlist-poc"
DL="$HERE/kit/skills/deliver/bin/dl"
keep="${1:-}"; SB="${keep:-$(mktemp -d "${TMPDIR:-/tmp}/watchlist-replay.XXXXXX")/repo}"
[[ -n $keep ]] || trap 'rm -rf "$(dirname "$SB")"' EXIT
export DELIVER_HOME="$(dirname "$SB")/.deliver"
export GIT_AUTHOR_NAME=replay GIT_AUTHOR_EMAIL=replay@example.com GIT_COMMITTER_NAME=replay GIT_COMMITTER_EMAIL=replay@example.com
unset DELIVER_JOB DELIVER_REPO HIVE_ROOT DELIVER_HEADLESS

c_step=$'\033[1;36m'; c_who=$'\033[1;33m'; c_off=$'\033[0m'
step() { printf '\n%s━━ %s%s\n' "$c_step" "$*" "$c_off"; }
say()  { printf '%s%s%s %s\n' "$c_who" "$1" "$c_off" "$2"; }
dl()   { printf '  $ dl %s\n' "$*"; "$DL" "$@" 2>&1 | sed 's/^/    /'; return "${PIPESTATUS[0]}"; }
dev()  { # dev <card> <worktree> — the "dev agent": copy the reference solution, run verify, commit, fill handoff
  local card=$1 wt=$2
  cp -R "$EX/reference/$card"/. "$wt"/
  (cd "$wt" && node --test $(jq -r --arg id "$card" '.cards[] | select(.id==$id) | .verify' "$B" | sed 's/^node --test //') >/dev/null)
  git -C "$wt" add -A && git -C "$wt" commit -qm "$card: $(jq -r --arg id "$card" '.cards[] | select(.id==$id) | .title' "$B")"
  sed -e "s/{CARD-ID}/$card/" -e "s/{hash}/$(git -C "$wt" rev-parse --short HEAD)/" "$HERE/kit/skills/deliver/templates/handoff.md" > "$J/handoffs/$card.md"
  say "  $card dev:" "status: done · commit $(git -C "$wt" rev-parse --short HEAD) · verify: passed"
}

qa() { # qa <card> <wt> — the "QA role": writes the integration tests for the card's ACs in qa_scope, runs them, commits
  local card=$1 wt=$2
  say "  qa-tester $card:" "writes integration tests for the spec's ACs in $(jq -r --arg id "$card" '.cards[] | select(.id==$id) | .qa_scope | join(",")' "$B")"
  cp -R "$EX/reference/QA-$card"/. "$wt"/
  (cd "$wt" && node --test --test-reporter=spec $(jq -r --arg id "$card" '.cards[] | select(.id==$id) | .qa_verify' "$B" | sed 's/^node --test //') 2>&1 | grep -E '✔|✖' | head -8 | sed 's/^/      /')
  git -C "$wt" add -A && git -C "$wt" commit -qm "$card QA: integration tests"
}

step "0 · sandbox repo from examples/watchlist-poc/seed"
"$HERE/scripts/sandbox.sh" "$SB" | sed 's/^/    /'
cd "$SB"

step "0 · INTAKE — Michael opens the job and picks the roles"
say "you:" "/deliver $(head -1 "$EX/JOB.md")"
JOB="$("$DL" new "Notch calculator + Ind. 12" "$(cat "$EX/JOB.md")")"; echo "    job: $JOB"
J="$SB/.work/$JOB"; B="$J/board.json"
"$DL" jobset '.stack=["javascript"] | .roles=[
  {"role":"ba","agent":"business-analyst","why":"always"},
  {"role":"backend-lead","agent":"ecc:architect","why":"pure domain modules (ratings, indicators)"},
  {"role":"backend","agent":"backend-dev","why":"backend-lead selected"},
  {"role":"qa","agent":"qa-tester","why":"always: tests every card against its ACs"},
  {"role":"reviewer","agent":"ecc:typescript-reviewer","why":"stack: javascript"}]'
jq -r '.roles[] | "    \(.role) → \(.agent)  (\(.why))"' "$J/job.json"

step "1 · ROLES — the project's role cards are generated (rules + company standards + project facts)"
dl phase readiness
cat "$J/ROLES.md" | sed 's/^/    /'
echo "    --- excerpt of roles/qa.md:"; sed -n '/## Rules/,/## This project/p' "$J/roles/qa.md" | sed 's/^/    /'

step "1 · READINESS — the BA checks every requirement and decision before anything is planned"
jq '(.items[] | select(.id=="CON-interface")) |= {id, status:"open", owner:"business",
     question:"Is notchCalculator().notches signed like notchChange (upgrade negative) or an absolute count?",
     options:["signed, like notchChange","absolute count + direction"], impact:"changes the contract other POC modules import"}' \
   "$EX/reference/readiness.json" > "$J/readiness.json"
say "  business-analyst:" "27 items + the architecture — 1 open (the request does not say whether notches is signed)"
dl readiness || true
dl next
dl phase planning || true
dl phase awaiting_clarification
say "you:" "signed, like notchChange (downgrade positive, upgrade negative)"
dl clarify CON-interface "signed, like notchChange (downgrade positive, upgrade negative)"
dl readiness
grep -E "CON-interface|PRD-conflicts|ARC-layer|NFR-privacy" "$J/readiness.md" | cut -c1-200 | sed 's/^/    /'
dl phase planning

step "1 · BUSINESS ANALYST (business-analyst) turns the requirements into a traceable plan"
cp "$EX/reference/plan.md" "$J/plan.md"; grep '^- AC-' "$J/plan.md" | sed 's/^/    /'

step "2 · LEAD (ecc:architect) turns the plan into cards"
cp "$EX/reference/board.json" "$B"
step "2 · BUSINESS ANALYST writes a spec per card (user story, Given/When/Then, edge cases, test data)"
cp "$EX/reference/specs/"*.md "$J/specs/"
sed -n '/## Acceptance criteria/,/## Edge cases/p' "$J/specs/T-01.md" | head -6 | sed 's/^/    /'
dl validate
dl board

step "3 · EXECUTE — no human stop before code (plan gate off); the human is next at the PR"
dl phase executing

step "3 · EXECUTE — wave 1"
dl next
say "  bash-guard/dl:" "T-02 must wait for T-01:"; dl wt add T-02 || true
W1="$("$DL" wt add T-01)"; echo "    T-01 worktree: ${W1#$SB/}"
say "  T-01 dev:" "attempt 1 — TDD: unit tests + code, but also 'tidies' README.md (outside its scope)"
cp -R "$EX/reference/T-01"/. "$W1"/; echo "tidied" >> "$W1/README.md"
git -C "$W1" add -A && git -C "$W1" commit -qm "T-01: notch calculator"

step "4 · GATE + REVIEW — T-01"
dl gate T-01 || true
dl next
say "Michael:" "re-dispatch T-01 with the FAIL lines as feedback"
dl wt add T-01 >/dev/null; git -C "$W1" checkout -q "job/$JOB" -- README.md
git -C "$W1" commit -qm "T-01: revert out-of-scope README change"
say "  T-01 dev:" "attempt 2 — reverted README.md, verify passed"
dl gate T-01
dl next
qa T-01 "$W1"
dl qa T-01 pass "AC-1 pass, AC-2 pass (test/integration/ratings)"
say "  ecc:typescript-reviewer:" '{"verdict":"approve","blocking":[],"nits":[]}'
dl review T-01 approve "AC-1, AC-2 covered by tests"
dl integrate T-01

step "3 · EXECUTE — wave 2 (T-02 branches from the job branch, so it sees T-01)"
dl next
W2="$("$DL" wt add T-02)"; echo "    T-02 worktree: ${W2#$SB/}"
dev T-02 "$W2"
dl gate T-02
qa T-02 "$W2"
dl qa T-02 pass "AC-3 pass (test/integration/indicators)"
say "  ecc:typescript-reviewer:" '{"verdict":"approve","blocking":[],"nits":["name the thresholds"]}'
dl review T-02 approve "AC-3 covered"
dl integrate T-02

step "5 · INTEGRATE — full verify on the job branch"
dl next
dl phase integrating
dl verify-all
dl phase closing

step "6 · CLOSE — BA checks every AC against the evidence, writes report.md (also the PR body)"
{ echo "# Delivery report"; echo; echo "| AC | Status | Evidence |"; echo "| --- | --- | --- |"
  echo "| AC-1 | ✅ | QA T-01: notchChange checks; gate log |"; echo "| AC-2 | ✅ | QA T-01: notchCalculator BBB+→BB+ = 3/WL2 |"
  echo "| AC-3 | ✅ | QA T-02: Ind. 12 thresholds |"; } > "$J/report.md"
sed 's/^/    /' "$J/report.md"
dl next

step "7 · SHIP — merge_mode=local (with a remote: human → PR for you · semi → PR + auto-merge on approval · auto → merge on green CI)"
dl ship
git -C "$SB" log --oneline --graph -8 | sed 's/^/    /'
dl cleanup

step "8 · ORACLE — hidden acceptance tests judge the delivered code"
"$HERE/scripts/check-oracle.sh" "$SB" main | sed 's/^/    /'

step "timeline (.work/$JOB/events.log)"
cut -f2- "$J/events.log" | sed 's/^/    /'
printf '\n%s✔ replay finished: the job went intake → done and the oracle passed.%s\n' "$c_step" "$c_off"
