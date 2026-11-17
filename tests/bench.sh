#!/usr/bin/env bash
# The bench: the same request three ways, judged by the same hidden oracle, cost and time measured the same way.
#   tests/bench.sh <scenario> <full|quick|plain>   one run → <bench dir>/<arm>/<scenario>/result.json
#   tests/bench.sh all                              every scenario × arm not yet done — three lanes, one per arm, at once
#   tests/bench.sh table                            the table so far (markdown)
#   bench dir: DELIVER_BENCH_DIR (default ~/.deliver-bench/runs) · restrict: BENCH_SCENARIOS="complete light" BENCH_ARMS=quick
#
# Arms — each gets the request file from a directory of its own (never examples/, where a reference solution lies):
#   full   /deliver as a user runs it — Michael picks the path; tests/e2e-live.sh with its prepared human answers
#   quick  /deliver:quick forced: one developer, one reviewer, no planning
# The kit arms install the kit as users do: the plugin (from this checkout), with ECC.
#   plain  Claude Code with no plugin: one session; if it stopped to ask, one more with the prepared answers and "go ahead"
# The plan for what each result means is written before the first run: docs/13-bench.md.
#
# Live: it costs real money (a full run ~$3–6). Stops before a run once BENCH_MAX_USD (default 90) is spent.
# Needs: credentials an isolated HOME can use — CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY, or a token from
# `claude setup-token` in DELIVER_BENCH_TOKEN_FILE (default ~/.deliver-bench/token); the oracles in DELIVER_ORACLE_DIR.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BD="${DELIVER_BENCH_DIR:-$HOME/.deliver-bench/runs}"
SCENARIOS="${BENCH_SCENARIOS:-complete light models parallel incomplete shaped idea}"   # the costly shaped ones last
ARMS="${BENCH_ARMS:-full quick plain}"
EXN=watchlist-poc; EX="$HERE/examples/$EXN"
KITV="$(jq -r .version "$HERE/kit/.claude-plugin/plugin.json")+$(git -C "$HERE" rev-parse --short HEAD)"
B="node $HERE/tests/bench.mjs"

scenario() {   # → REQ (file name), ORACLE, ANSWERS
  case $1 in
    complete)   REQ=JOB.md;            ORACLE=watchlist.oracle.test.mjs ;;
    incomplete) REQ=JOB-incomplete.md; ORACLE=watchlist.oracle.test.mjs ;;
    parallel)   REQ=JOB-parallel.md;   ORACLE=parallel.oracle.test.mjs ;;
    models)     REQ=JOB-models.md;     ORACLE=models.oracle.test.mjs ;;
    light)      REQ=JOB-light.md;      ORACLE=light.oracle.test.mjs ;;
    shaped)     REQ=JOB-shaped.md;     ORACLE=watchlist.oracle.test.mjs ;;
    idea)       REQ=JOB-idea.md;       ORACLE=watchlist.oracle.test.mjs ;;
    *) return 1 ;;
  esac
  ANSWERS="$EX/HUMAN_ANSWERS.json"; [[ $1 == idea ]] && ANSWERS="$EX/HUMAN_ANSWERS-idea.json"
  export PICK_REQUEST=$REQ
}
auth() {
  [[ -n ${CLAUDE_CODE_OAUTH_TOKEN:-}${ANTHROPIC_API_KEY:-} ]] && return 0
  local tf="${DELIVER_BENCH_TOKEN_FILE:-$HOME/.deliver-bench/token}"
  [[ -r $tf ]] || { echo "bench: no credentials an isolated HOME can use — run \`claude setup-token\` in a terminal, save the token in $tf (chmod 600); or set CLAUDE_CODE_OAUTH_TOKEN / ANTHROPIC_API_KEY" >&2; exit 2; }
  CLAUDE_CODE_OAUTH_TOKEN="$(tr -d '[:space:]' < "$tf")"; export CLAUDE_CODE_OAUTH_TOKEN
}
over_budget() { awk -v s="$($B spent "$BD")" -v m="${BENCH_MAX_USD:-90}" 'BEGIN { exit !(s >= m) }'; }

export PERMISSION_MODE=bypassPermissions IS_SANDBOX=1
export GIT_AUTHOR_NAME=bench GIT_AUTHOR_EMAIL=bench@example.com GIT_COMMITTER_NAME=bench GIT_COMMITTER_EMAIL=bench@example.com
. "$HERE/tests/lib-isolated-claude.sh"

# the repo every arm starts from: the seed, plus what the scenario needs (the POC document; for light, the code it builds on)
sandbox() {
  local sc=$1
  iso_env "$HERE/scripts/sandbox.sh" "$SB" "$EXN" > /dev/null || return 1
  case $sc in
    shaped|idea) mkdir -p "$SB/docs" && cp "$EX/POC_Requirements_v0.2_EN.md" "$SB/docs/" ;;
    light) local d; for d in T-01 T-02 QA-T-01 QA-T-02; do cp -R "$EX/reference/$d/." "$SB/"; done ;;
  esac
  git -C "$SB" add -A && git -C "$SB" commit -qm "bench: $sc" > /dev/null 2>&1
  return 0
}
with_kit() {   # what the full arm has (tests/e2e-live.sh): ECC, and the kit as the plugin users get, from this checkout
  { iso_env claude plugin marketplace add https://github.com/affaan-m/ECC && iso_env claude plugin install ecc@ecc
    iso_env claude plugin marketplace add "$HERE" && iso_env claude plugin install deliver@deliver-floor && iso_env "$HERE/scripts/install.sh" --user --plugin; } > "$W/install.log" 2>&1
  KS="$(ls -d "$ISO_HOME"/.claude/plugins/cache/deliver-floor/deliver/*/skills/deliver 2>/dev/null | tail -1)"; [[ -n $KS ]]
}
# the prepared human: open readiness items answered from the scenario's answers, as tests/e2e-live.sh does
answer_open() {
  local J=$1 id q ans n=0
  [[ -f $J/readiness.json ]] || return 1
  while IFS=$'\t' read -r id q; do
    ans="$(node "$HERE/tests/pick-answer.mjs" "$ANSWERS" "$q" "$id" 2>/dev/null)" || continue
    iso_env DELIVER_APPROVER=bench-human "$KS/bin/dl" -C "$SB" clarify "$id" "$ans" > /dev/null && n=$((n + 1))
  done < <(jq -r '(.items // .)[] | select(.status=="open" and .owner != "pm") | [.id, .question] | @tsv' "$J/readiness.json")
  [[ $n -gt 0 ]]
}

run_full() {
  rm -rf "$W"; mkdir -p "$BD/full"
  "$HERE/tests/e2e-live.sh" "$SC" "$BD/full" > "$BD/full/$SC.console.txt" 2>&1
  SB="$W/repo"; J="$(ls -d "$SB"/.work/JOB-* 2>/dev/null | head -1)"
  SECS="$(sed -n 's/^wall time: .*(\([0-9]*\) s)$/\1/p' "$W/report.md" | tail -1)"
  NOTE="harness: $(grep -c '^- ✅' "$W/report.md") checks pass, $(grep -c '^- ❌' "$W/report.md") fail (full/$SC/report.md)"
  COST_PATHS="$SB/.work/runs ${J:+$J/bmad/runs}"
  # light: e2e-live goes on with a second change (JOB-light2.md) once this request is judged — its sessions are not this run's
  local cut f; cut="$(sed -n 's/.*JOB-light2\.md"[[:space:]]*(log: \([^)]*\)).*/\1/p' "$W/run.log" 2>/dev/null | head -1)"
  if [[ -n $cut ]]; then
    COST_PATHS="${J:+$J/bmad/runs}"
    for f in "$SB"/.work/runs/*.jsonl; do [[ "$(basename "$f")" < "$(basename "$cut")" ]] && COST_PATHS="$COST_PATHS $f"; done
    NOTE="$NOTE; the second change (JOB-light2.md) left out of time and cost"
  fi
}
run_quick() {
  rm -rf "$W"; mkdir -p "$W/input" "$ISO_HOME"; cp "$EX/$REQ" "$W/input/"
  SB="$W/repo"; sandbox "$SC" && with_kit || { NOTE="setup failed"; return 1; }
  mkdir -p "$SB/.work/runs"; local t0 r; t0=$(date +%s)
  (cd "$SB" && iso_env DELIVER_HEADLESS=1 CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1 claude -p "/deliver:quick Implement the request in $W/input/$REQ" \
     --permission-mode "$PERMISSION_MODE" --output-format stream-json --verbose > ".work/runs/$(date +%Y%m%d-%H%M%S)-quick.jsonl" 2> "$W/quick.err")
  for r in 1 2 3; do
    iso_env DELIVER_HEADLESS=1 "$HERE/scripts/run-headless.sh" "$SB" "" "${BENCH_ROUNDS:-8}" >> "$W/run.log" 2>&1
    J="$(ls -d "$SB"/.work/JOB-* 2>/dev/null | head -1)"
    [[ -n $J && "$(jq -r .phase "$J/job.json")" == awaiting_clarification ]] && answer_open "$J" || break
  done
  SECS=$(( $(date +%s) - t0 )); COST_PATHS="$SB/.work/runs"
}
run_plain() {
  rm -rf "$W"; mkdir -p "$W/input" "$ISO_HOME"; cp "$EX/$REQ" "$W/input/"
  SB="$W/repo"; sandbox "$SC" || { NOTE="setup failed"; return 1; }
  git -C "$SB" rm -q .deliver.json && git -C "$SB" commit -qm "bench: plain Claude Code, no kit"
  local t0 base ans answers="" line; t0=$(date +%s); base="$(git -C "$SB" rev-parse HEAD)"
  (cd "$SB" && iso_env claude -p "Implement the request in $W/input/$REQ in this repository. Work on the main branch: write the code and its tests, run the tests, and commit your work." \
     --permission-mode "$PERMISSION_MODE" --output-format json > "$W/plain-1.json" 2> "$W/plain.err")
  if [[ -z "$(git -C "$SB" status --porcelain)" && "$(git -C "$SB" rev-parse HEAD)" == "$base" ]]; then   # it stopped to ask
    while IFS= read -r line; do
      ans="$(node "$HERE/tests/pick-answer.mjs" "$ANSWERS" "$line" 2>/dev/null)" && answers="$answers $ans"
    done < <(jq -r '.result // ""' "$W/plain-1.json" | grep '?')
    (cd "$SB" && iso_env claude -p "${answers:+Answers:$answers }Nobody can answer more right now. Go ahead: decide anything still unclear yourself, note it, implement the request and commit." \
       --continue --permission-mode "$PERMISSION_MODE" --output-format json > "$W/plain-2.json" 2>> "$W/plain.err")
    NOTE="stopped to ask; ${answers:+given the prepared answers and }told to go ahead"
  fi
  SECS=$(( $(date +%s) - t0 ))
  if [[ -n "$(git -C "$SB" status --porcelain)" ]]; then   # what a person would commit
    git -C "$SB" add -A && git -C "$SB" commit -qm "bench: work left uncommitted"; NOTE="${NOTE:+$NOTE; }left work uncommitted (committed by the bench)"
  fi
  COST_PATHS="$W/plain-1.json $W/plain-2.json"
}

one() {
  SC=$1 ARM=$2; scenario "$SC" || { echo "unknown scenario: $SC" >&2; return 2; }
  [[ " full quick plain " == *" $ARM "* ]] || { echo "unknown arm: $ARM" >&2; return 2; }
  [[ -f ${DELIVER_ORACLE_DIR:-$HOME/.deliver-bench/oracles}/$EXN/$ORACLE ]] || { echo "bench: the oracle $EXN/$ORACLE is not in DELIVER_ORACLE_DIR — see scripts/check-oracle.sh" >&2; return 2; }
  W="$BD/$ARM/$SC"; export ISO_HOME="$W/home"
  SB="" J="" SECS=0 NOTE="" COST_PATHS="" KS="$HERE/kit/skills/deliver"
  echo "▶ $SC · $ARM ($(date +%T))"
  "run_$ARM"
  local branch=main; [[ $ARM == plain ]] && branch=HEAD
  if [[ -n $SB && -d $SB/.git ]] && [[ $ARM != full || ! -f $W/oracle.log ]]; then
    "$HERE/scripts/check-oracle.sh" "$SB" "$branch" "$EXN" "$ORACLE" > "$W/oracle.log" 2>&1
  fi
  J="${J:-$(ls -d "$SB"/.work/JOB-* 2>/dev/null | head -1)}"
  local cost infra; cost="$($B cost $COST_PATHS)"
  infra="$(jq -r '.errors[]' <<<"$cost" | grep -iE "limit|credits|overloaded|api error|rate" | head -1)"
  if [[ -n $infra ]]; then
    printf '%s\n' "$infra" > "$W/infra.txt"; rm -f "$W/result.json"
    echo "⏸  $SC · $ARM: not a result — the run was stopped from outside: $infra"; return 9
  fi
  [[ $ARM != plain && -z $J ]] && NOTE="${NOTE:+$NOTE; }no job was opened"
  local kc=""; [[ -n $J ]] && kc="$(node "$HERE/kit/skills/deliver/bin/usage.mjs" spend "$J" --json 2>/dev/null | jq -c '.total.usd // null' 2>/dev/null)"
  # shellcheck disable=SC2086
  jq -n --arg sc "$SC" --arg arm "$ARM" --arg kit "$KITV" --arg at "$(date -u +%FT%TZ)" --argjson secs "${SECS:-0}" \
    --argjson oracle "$($B oracle "$W/oracle.log")" --argjson cost "$cost" \
    --argjson kitcost "${kc:-null}" \
    --arg track "$( [[ -n $J ]] && jq -r '.track // "full"' "$J/job.json")" --arg phase "$( [[ -n $J ]] && jq -r .phase "$J/job.json")" --arg note "$NOTE" \
    '{scenario: $sc, arm: $arm, kit: $kit, at: $at, oracle: $oracle, seconds: $secs, usd: $cost.usd, sessions: $cost.sessions,
      models: $cost.models, usd_kit: $kitcost, track: (if $track == "" then null else $track end),
      phase: (if $phase == "" then null else $phase end), note: (if $note == "" then null else $note end)}' > "$W/result.json"
  echo "✔ $SC · $ARM: $(jq -r '"oracle \(.oracle.result) (\(.oracle.pass)/\(.oracle.pass + .oracle.fail)) · \(.seconds / 60 | floor) min · $\(.usd)\(if .track then " · track \(.track), \(.phase)" else "" end)"' "$W/result.json")"
}
lane() {
  local arm=$1 sc
  for sc in $SCENARIOS; do
    [[ -f $BD/$arm/$sc/result.json ]] && continue
    if over_budget; then echo "⏸  $arm: the bench has spent \$$($B spent "$BD") (BENCH_MAX_USD ${BENCH_MAX_USD:-90}) — stopping"; return; fi
    one "$sc" "$arm" || { [[ $? == 9 ]] && { echo "⏸  $arm: stopping — a limit or an API error; run tests/bench.sh all again when it is lifted"; return; }; }
  done
}

mkdir -p "$BD"
case ${1:-} in
  table) $B table "$BD" ;;
  all)
    auth
    for arm in $ARMS; do lane "$arm" > "$BD/lane-$arm.log" 2>&1 & done
    echo "bench: lanes ${ARMS// /, } running — progress in $BD/lane-*.log"; wait
    $B table "$BD" | tee "$BD/TABLE.md" ;;
  ''|-h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
  *) auth; one "$1" "${2:?usage: bench.sh <scenario> <full|quick|plain>}" ;;
esac
