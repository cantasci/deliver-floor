#!/usr/bin/env bash
# Judges a delivered /deliver job from the outside — the same checks for every live scenario.
#   tests/verify-job.sh <repo> <oracle file> <report.md> <kit skill dir>
# Appends ✅/❌ lines to the report, prints them, exits non-zero when anything failed.
set -uo pipefail
# grep -q exits on the first match; under pipefail the producer then dies of SIGPIPE and the pipe fails at random. gq reads to EOF.
gq() { grep "$@" >/dev/null; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SB="$1" ORACLE="$2" REP="$3" SKILL="$4"
pass=0 fail=0
ok()  { printf '  \033[32m✔\033[0m %s\n' "$1"; printf -- '- ✅ %s\n' "$1" >> "$REP"; pass=$((pass+1)); }
bad() { printf '  \033[31m✘\033[0m %s\n' "$1"; printf -- '- ❌ %s\n' "$1" >> "$REP"; fail=$((fail+1)); }
log() { printf '%s\n' "$*" | tee -a "$REP"; }
chk() { local d=$1; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
J="$(ls -d "$SB"/.work/JOB-* 2>/dev/null | sort | tail -1)"
[[ -n $J ]] || { bad "no job was created"; exit 1; }
JJ="$J/job.json"; B="$J/board.json"
chk "job reached done" test "$(jq -r .phase "$JJ")" == done
chk "job shipped ($(jq -r .settings.merge_mode "$JJ"))" test "$(jq -r .shipped "$JJ")" == true
log "roles: $(jq -r '[.roles[] | .role + (if .count then "×\(.count)" else "" end) + (if .provider then "@\(.provider)" else "" end)] | join(", ")' "$JJ")"
chk "roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason" jq -e '([.roles[].role] | (index("ba") and index("qa") and any(.[]; startswith("reviewer")))) and ([.roles[] | select((.why // "") == "")] | length == 0)' "$JJ"
miss=""; for r in $(jq -r '.roles[] | select(.agent != "artemis") | .role' "$JJ"); do [[ -f $J/roles/$r.md ]] || miss+=" $r"; done
[[ -z $miss ]] && ok "a role card for every role" || bad "role cards missing:$miss"
chk "readiness review complete (no open item) with an architecture" jq -e '((.items // .) | all(.status != "open")) and (.architecture.components | length > 0)' "$J/readiness.json"
log "readiness: $(jq -r '(.items // .) | "\(length) items — \(map(select(.status=="decided"))|length) decided (\(map(select((.source//"")|startswith("human:")))|length) by the human, \(map(select((.source//"")|startswith("pm:")))|length) by the PM), \(map(select(.status=="n_a"))|length) n/a"' "$J/readiness.json")"
log "architecture: $(jq -r '.architecture | "\(.style): " + ([.components[] | "\(.id) [\(.stack|join("+"))] → \(.owner)/\(.reviewer)"] | join(", "))' "$J/readiness.json")"
h="$(node -e 'process.stdout.write(require("crypto").createHash("sha256").update(require("fs").readFileSync(process.argv[1])).digest("hex"))' "$J/readiness.json")"
[[ $h == "$(jq -r .frozen.readiness_sha256 "$JJ")" ]] && ok "readiness frozen at planning and unchanged since" || bad "readiness changed after the freeze"
ncards="$(jq '[.cards[] | select(.state != "archived")] | length' "$B")"
[[ $ncards -ge 1 ]] && ok "the Leads cut $ncards card(s)" || bad "no cards on the board"
miss=""; for c in $(jq -r '.cards[] | select(.state != "archived") | .id' "$B"); do [[ -f $J/specs/$c.md ]] || miss+=" $c"; done
[[ $ncards -ge 1 && -z $miss ]] && ok "a BA spec for every card" || bad "BA specs missing:$miss"
log ""; log "| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |"; log "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"
jq -r '.cards[] | "| \(.id) \(.title) | \(.component // "-") | \(.seat // "-") | \(.attempts) | \(.gate.result // "-") | \(.qa.verdict // "-") (qa_verify \(.qa.qa_verify // "-")) | \(.review.verdict // "-") | \((.reviewers // ["reviewer"]) | join(", ")) | \(.state) |"' "$B" | tee -a "$REP"
chain=$(( ncards >= 1 ? 1 : 0 ))
for c in $(jq -r '.cards[] | select(.state != "archived") | .id' "$B"); do
  q() { jq -r --arg id "$c" ".cards[] | select(.id==\$id) | $1" "$B"; }
  [[ "$(q .state)" == merged && "$(q '.assignments[0].by')" == michael && "$(q .gate.result)" == PASS && "$(q .qa.verdict)" == pass \
     && "$(q .qa.gate_head)" == "$(q .gate.head)" && "$(q .review.verdict)" == approve && "$(q .review.head)" == "$(q .qa.head)" ]] || { chain=0; bad "$c did not go through assign → dev → gate → QA → review → merge"; }
done
[[ $chain -eq 1 ]] && ok "every card ($ncards): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged"
qa_files=0
for c in $(jq -r '.cards[] | select(.state=="merged") | .id' "$B"); do
  total="$(git -C "$SB" ls-files | wc -l)"
  out="$(git -C "$SB" ls-files | node "$SKILL/bin/scope.mjs" "$(jq -c --arg id "$c" '.cards[] | select(.id==$id) | .qa_scope' "$B")" | wc -l)"
  qa_files=$((qa_files + total - out))
done
[[ $qa_files -gt 0 ]] && ok "QA's integration/e2e tests are on main ($qa_files file(s) in the cards' qa_scope)" || bad "no QA test files on main"
for a in business-analyst ecc:architect qa-tester; do grep -qE $'\tagent\t'"(deliver:)?$a" "$J/events.log" || gq "md-dispatch.*$a" "$J/events.log" && ok "role really ran: $a" || bad "no $a run in events.log"; done
grep -qE $'\tagent\t(deliver:)?(backend|frontend|mobile|database)-dev|md-dispatch\tT-[0-9]+ (backend|frontend|mobile|database)' "$J/events.log" && ok "role really ran: a dev role" || bad "no dev run"
grep -qE $'\tagent\tecc:[a-z-]*reviewer|\treview\t' "$J/events.log" && ok "role really ran: reviewer(s)" || bad "no reviewer run"
! grep -q $'\ttracker-error\t' "$J/events.log" && ok "no tracker errors" || bad "tracker errors in events.log"
chk "kanban view rendered" test -f "$J/kanban.html"
! cmp -s "$J/report.md" "$SKILL/templates/report.md" && ok "report.md written by the closing check" || bad "report.md is the template"
base="$(git -C "$SB" rev-list --max-parents=0 HEAD | tail -1)"
if git -C "$SB" log --format='%an <%ae>%n%B' "$base..main" | gq -iE 'co-authored-by:.*(claude|anthropic)|generated with \[?claude|noreply@anthropic'; then bad "AI attribution found in the delivered history"
else ok "no AI attribution in the delivered history ($(git -C "$SB" rev-list --count "$base..main") commits)"; fi
(cd "$SB" && node --test >/dev/null 2>&1) && ok "the whole test suite passes on main" || bad "tests fail on main"
d="$(dirname "$REP")"
if "$HERE/scripts/check-oracle.sh" "$SB" main watchlist-poc "$ORACLE" > "$d/oracle.log" 2>&1; then ok "hidden oracle passes ($(grep -c '✔' "$d/oracle.log") checks, $ORACLE)"
else bad "hidden oracle FAILED (oracle.log)"; grep -E '✖|AssertionError|expected|actual' "$d/oracle.log" | head -12 | tee -a "$REP"; fi
for f in events.log readiness.md board.json plan.md; do cp "$J/$f" "$d/$f" 2>/dev/null; done; cp "$J/report.md" "$d/job-report.md" 2>/dev/null
echo "VERIFY $pass $fail"
[[ $fail -eq 0 ]]
