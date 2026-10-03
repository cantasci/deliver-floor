#!/usr/bin/env bash
# LIVE end-to-end scenarios — real Claude Code, real ECC plugin, real agents. No mocks, no replay, no hand-holding.
# Each scenario does what a user does on a fresh machine and then judges the result from the outside, step by step:
#   setup   fresh HOME → ECC from GitHub (/plugin marketplace add + install) → scripts/install.sh → doctor → sandbox repo
#   run     scripts/run-headless.sh <repo> <requirements .md>   — the ONLY input is the requirements file
#   verify  every step of the flow is checked on disk (job, readiness, roles, cards, QA tests, commits) + a hidden oracle
#
#   tests/e2e-live.sh <scenario> [work dir]
#     complete    a complete requirements slice (JOB.md) → delivered, oracle passes
#     incomplete  a slice with a gap (JOB-incomplete.md) → Michael must STOP with the question; the human answers each
#                 question from HUMAN_ANSWERS.json (matched by topic, recorded with dl clarify); the run resumes →
#                 delivered, oracle passes. A question no prepared answer matches fails the scenario: a real person must answer.
#     parallel    two independent requirements, "two backend developers in parallel" → two seats work at the same time
#   Each writes <work dir>/<scenario>/report.md (the scenario, step by step) and keeps every artifact.
#   Costs real tokens (a scenario ≈ 3–6 USD, 10–25 min). Env: PERMISSION_MODE (default bypassPermissions), E2E_ROUNDS (8).
set -uo pipefail
# grep -q exits on the first match; under pipefail the producer then dies of SIGPIPE and the pipe fails at random. gq reads to EOF.
gq() { grep "$@" >/dev/null; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SC="${1:?usage: e2e-live.sh complete|incomplete|parallel [work dir]}"
EXN=watchlist-poc; EX="$HERE/examples/$EXN"
case $SC in
  complete)   REQ="$EX/JOB.md";            ORACLE=watchlist.oracle.test.mjs ;;
  incomplete) REQ="$EX/JOB-incomplete.md"; ORACLE=watchlist.oracle.test.mjs ;;
  parallel)   REQ="$EX/JOB-parallel.md";   ORACLE=parallel.oracle.test.mjs ;;
  *) echo "unknown scenario: $SC" >&2; exit 2 ;;
esac
W="${2:-$(mktemp -d "${TMPDIR:-/tmp}/deliver-e2e.XXXXXX")}"; mkdir -p "$W/$SC"; W="$(cd "$W/$SC" && pwd)"
export ISO_HOME="$W/home"; mkdir -p "$ISO_HOME"
. "$HERE/tests/lib-isolated-claude.sh"
export PERMISSION_MODE="${PERMISSION_MODE:-bypassPermissions}" IS_SANDBOX=1
export GIT_AUTHOR_NAME=e2e GIT_AUTHOR_EMAIL=e2e@example.com GIT_COMMITTER_NAME=e2e GIT_COMMITTER_EMAIL=e2e@example.com
REP="$W/report.md"; : > "$REP"
log()  { printf '%s\n' "$*" | tee -a "$REP"; }
step() { printf '\n\033[1;36m━━ %s\033[0m\n' "$*"; printf '\n## %s\n\n' "$*" >> "$REP"; }
pass=0 fail=0
ok()  { printf '  \033[32m✔\033[0m %s\n' "$1"; printf -- '- ✅ %s\n' "$1" >> "$REP"; pass=$((pass+1)); }
bad() { printf '  \033[31m✘\033[0m %s\n' "$1"; printf -- '- ❌ %s\n' "$1" >> "$REP"; fail=$((fail+1)); }
chk() { local d=$1; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
printf '# Live E2E — scenario `%s`\n\nRequest: `%s`  ·  started %s\n' "$SC" "${REQ#$HERE/}" "$(date -u +%FT%TZ)" > "$REP"

step "1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo"
if iso_env claude plugin list 2>/dev/null | gq "ecc@ecc"; then log "ECC already installed in this HOME"
else
  iso_env claude plugin marketplace add https://github.com/affaan-m/ECC 2>&1 | tail -1 | tee -a "$REP"
  iso_env claude plugin install ecc@ecc 2>&1 | tail -1 | tee -a "$REP"
fi
iso_env claude plugin list 2>/dev/null | gq ecc@ecc && ok "ECC plugin installed ($(iso_env claude plugin list 2>/dev/null | grep -A1 ecc@ecc | grep -o 'Version: [0-9.]*'))" || bad "ECC plugin not installed"
iso_env "$HERE/scripts/install.sh" --user > "$W/install.log" 2>&1 && ok "kit installed (scripts/install.sh --user)" || bad "kit install failed (install.log)"
SB="$W/repo"; rm -rf "$SB"; iso_env "$HERE/scripts/sandbox.sh" "$SB" "$EXN" > /dev/null
iso_env "$HERE/scripts/doctor.sh" "$SB" > "$W/doctor.log" 2>&1 && ok "doctor: $(tail -1 "$W/doctor.log")" || bad "doctor: $(tail -1 "$W/doctor.log")"
DL="$ISO_HOME/.claude/skills/deliver/bin/dl"
dlx() { iso_env "$DL" -C "$SB" "$@"; }
run_rounds() { iso_env DELIVER_HEADLESS=1 "$HERE/scripts/run-headless.sh" "$SB" "${1:-}" "${E2E_ROUNDS:-8}" 2>&1 | tee -a "$W/run.log"; }

step "2 · run: the only input is ${REQ#$HERE/}"
start=$(date +%s)
run_rounds "$REQ" | sed 's/^/    /'
J="$(ls -d "$SB"/.work/JOB-* 2>/dev/null | head -1)"
[[ -n $J ]] && ok "Michael opened the job $(basename "$J")" || { bad "no job was created"; log "result: $pass passed, $fail failed"; exit 1; }
JJ="$J/job.json"; B="$J/board.json"

if [[ $SC == incomplete ]]; then
  step "3 · the gap: Michael must stop and ask — not assume"
  [[ "$(jq -r .phase "$JJ")" == awaiting_clarification ]] && ok "phase awaiting_clarification (stopped before planning)" || bad "phase is $(jq -r .phase "$JJ"), expected awaiting_clarification"
  grep -qiE "sign|negative|upgrade|absolute" "$J/QUESTIONS.md" 2>/dev/null && ok "QUESTIONS.md asks about the unspecified sign of notches" || bad "QUESTIONS.md does not ask about the sign: $(head -c 400 "$J/QUESTIONS.md" 2>/dev/null)"
  [[ "$(jq '.cards | length' "$B")" == 0 ]] && ok "no card was cut before the answer" || bad "cards exist before the answer"
  [[ -z "$(git -C "$SB" ls-files src | grep -v gitkeep)" && ! -d $J/wt/T-01 ]] && ok "no code was written before the answer" || bad "code was written before the answer"
  log ""; log "Open questions (QUESTIONS.md):"; sed 's/^/    /' "$J/QUESTIONS.md" >> "$REP"
fi
# The human: whenever Michael stops with questions (in any scenario), each one is answered from HUMAN_ANSWERS.json —
# matched by topic, recorded with dl clarify as a person in a terminal would — and the run resumes. A question no
# prepared answer matches fails the scenario: a real person would have to answer it.
for round in 1 2 3; do
  [[ "$(jq -r .phase "$JJ")" == awaiting_clarification ]] || break
  step "4.$round · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes"
  [[ $SC != incomplete ]] && log "note: the $SC request still raised question(s) — recorded below; answering them is the human's job"
  log "Open questions (QUESTIONS.md):"; sed 's/^/    /' "$J/QUESTIONS.md" >> "$REP"
  while IFS=$'\t' read -r id q; do
    ans="$(node "$HERE/tests/pick-answer.mjs" "$EX/HUMAN_ANSWERS.json" "$q" "$id" 2>/dev/null)"
    if [[ -n $ans ]]; then iso_env DELIVER_APPROVER=e2e-human "$DL" -C "$SB" clarify "$id" "$ans" > /dev/null && ok "answered $id — $(cut -c1-90 <<<"$q")"
    else bad "no prepared answer for $id — a real person must answer: $q"; fi
  done < <(jq -r '(.items // .)[] | select(.status=="open" and .owner != "pm") | [.id, .question] | @tsv' "$J/readiness.json")
  run_rounds | sed 's/^/    /'
done
log "wall time: $(( ($(date +%s) - start) / 60 )) min"

step "5 · verify the whole flow on disk"
chk "job reached done" test "$(jq -r .phase "$JJ")" == done
chk "job shipped ($(jq -r .settings.merge_mode "$JJ"))" test "$(jq -r .shipped "$JJ")" == true
log "roles: $(jq -r '[.roles[] | .role + (if .count then "×\(.count)" else "" end)] | join(", ")' "$JJ")"
chk "roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason" jq -e '([.roles[].role] | (index("ba") and index("qa") and any(.[]; startswith("reviewer")))) and ([.roles[] | select((.why // "") == "")] | length == 0)' "$JJ"
for r in $(jq -r '.roles[] | select(.agent != "artemis") | .role' "$JJ"); do [[ -f $J/roles/$r.md ]] || bad "role card missing: $r"; done
chk "role cards generated for every role" test -f "$J/ROLES.md"
grep -q $'\tdecide\t' "$J/events.log" && log "PM decisions: $(grep -c $'\tdecide\t' "$J/events.log") (implementation details, recorded with rationale)"
chk "readiness review complete (no open item) with an architecture" jq -e '((.items // .) | all(.status != "open")) and (.architecture.components | length > 0)' "$J/readiness.json"
log "readiness: $(jq -r '(.items // .) | "\(length) items — \(map(select(.status=="decided"))|length) decided, \(map(select(.status=="n_a"))|length) n/a"' "$J/readiness.json") · architecture: $(jq -r '.architecture | "\(.style): " + ([.components[] | "\(.id) [\(.stack|join("+"))]"] | join(", "))' "$J/readiness.json")"
chk "readiness frozen at planning and unchanged since" bash -c "[[ \"\$(node -e 'process.stdout.write(require(\"crypto\").createHash(\"sha256\").update(require(\"fs\").readFileSync(process.argv[1])).digest(\"hex\"))' '$J/readiness.json')\" == \"\$(jq -r .frozen.readiness_sha256 '$JJ')\" ]]"
ncards="$(jq '[.cards[] | select(.state != "archived")] | length' "$B")"
[[ $ncards -ge 1 ]] && ok "the Leads cut $ncards card(s)" || bad "no cards on the board"
chk "a BA spec for every card" bash -c "for c in \$(jq -r '.cards[] | select(.state != \"archived\") | .id' '$B'); do test -f '$J/specs/'\$c.md || exit 1; done"
log ""; log "| Card | Component | Seat | Attempts | Gate | QA | Review | State |"; log "| --- | --- | --- | --- | --- | --- | --- | --- |"
jq -r '.cards[] | "| \(.id) \(.title) | \(.component // "-") | \(.seat // "-") | \(.attempts) | \(.gate.result // "-") | \(.qa.verdict // "-") (qa_verify \(.qa.qa_verify // "-")) | \(.review.verdict // "-") | \(.state) |"' "$B" | tee -a "$REP"
all_chain=$(( ncards >= 1 ? 1 : 0 ))
for c in $(jq -r '.cards[] | select(.state != "archived") | .id' "$B"); do
  q() { jq -r --arg id "$c" ".cards[] | select(.id==\$id) | $1" "$B"; }
  [[ "$(q .state)" == merged && "$(q '.assignments[0].by')" == michael && "$(q .gate.result)" == PASS && "$(q .qa.verdict)" == pass \
     && "$(q .qa.gate_head)" == "$(q .gate.head)" && "$(q .review.verdict)" == approve && "$(q .review.head)" == "$(q .qa.head)" ]] || { all_chain=0; bad "$c did not go through assign → dev → gate → QA → review → merge"; }
done
[[ $all_chain -eq 1 ]] && ok "every card ($ncards): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged"
qa_files=0
for c in $(jq -r '.cards[] | select(.state=="merged") | .id' "$B"); do
  n="$(git -C "$SB" ls-files | node "$ISO_HOME/.claude/skills/deliver/bin/scope.mjs" "$(jq -c --arg id "$c" '.cards[] | select(.id==$id) | .qa_scope' "$B")" | wc -l)"
  total="$(git -C "$SB" ls-files | wc -l)"; [[ $((total - n)) -gt 0 ]] && qa_files=$((qa_files + total - n))
done
[[ $qa_files -gt 0 ]] && ok "QA's integration tests are on main ($qa_files file(s) in the cards' qa_scope)" || bad "no QA test files on main"
for a in business-analyst ecc:architect qa-tester; do grep -q $'\tagent\t'"$a" "$J/events.log" && ok "role really ran: $a" || bad "no $a run in events.log"; done
grep -qE $'\tagent\t(backend|frontend|mobile|database)-dev' "$J/events.log" && ok "role really ran: a dev agent" || bad "no dev agent run"
grep -qE $'\tagent\tecc:[a-z-]*reviewer' "$J/events.log" && ok "role really ran: a stack reviewer" || bad "no reviewer run"
! grep -q $'\ttracker-error\t' "$J/events.log" && ok "no tracker errors" || bad "tracker errors in events.log"
chk "kanban view rendered" test -f "$J/kanban.html"
! cmp -s "$J/report.md" "$ISO_HOME/.claude/skills/deliver/templates/report.md" && ok "report.md written by the closing check" || bad "report.md is the template"
base="$(git -C "$SB" rev-list --max-parents=0 HEAD | tail -1)"
if git -C "$SB" log --format='%an <%ae>%n%B' "$base..main" | gq -iE 'co-authored-by:.*(claude|anthropic)|generated with \[?claude|noreply@anthropic'; then bad "AI attribution found in the delivered history"
else ok "no AI attribution in the delivered history ($(git -C "$SB" rev-list --count "$base..main") commits)"; fi
(cd "$SB" && node --test >/dev/null 2>&1) && ok "the whole test suite passes on main" || bad "tests fail on main"
if "$HERE/scripts/check-oracle.sh" "$SB" main "$EXN" "$ORACLE" > "$W/oracle.log" 2>&1; then ok "hidden oracle passes ($(grep -c '✔' "$W/oracle.log") checks, $ORACLE)"
else bad "hidden oracle FAILED (oracle.log)"; grep -E '✖|AssertionError|expected|actual' "$W/oracle.log" | head -12 | tee -a "$REP"; fi
if [[ $SC == parallel ]]; then
  step "6 · parallel seats"
  chk "the backend role has 2+ seats" jq -e '[.roles[] | select(.role=="backend") | .count // 1] | max >= 2' "$JJ"
  seats="$(jq -r '[.cards[] | .assignments[]?.seat] | unique | join(", ")' "$B")"; log "seats used: $seats"
  [[ $seats == *"#2"* ]] && ok "a second seat was used" || bad "only one seat used ($seats)"
  first_merge="$(grep -n $'\tintegrate\t' "$J/events.log" | head -1 | cut -d: -f1)"
  assigns_before="$(head -n "${first_merge:-0}" "$J/events.log" | grep -c $'\tassign\t')"
  [[ ${assigns_before:-0} -ge 2 ]] && ok "two cards were assigned before the first merge (they ran in parallel)" || bad "cards ran one after another"
fi
cost="$(cat "$SB"/.work/runs/*.jsonl 2>/dev/null | jq -s '[.[] | select(.type=="result") | .total_cost_usd // 0] | add // 0')"
step "result"
log "cost: \$$(printf '%.2f' "$cost")  ·  artifacts: $W"
log "**$pass passed, $fail failed**"
cp "$J/events.log" "$W/events.log" 2>/dev/null; cp "$J/readiness.md" "$W/readiness.md" 2>/dev/null; cp "$J/report.md" "$W/job-report.md" 2>/dev/null
cp "$J/board.json" "$W/board.json" 2>/dev/null; cp "$J/plan.md" "$W/plan.md" 2>/dev/null
[[ $fail -eq 0 ]]
