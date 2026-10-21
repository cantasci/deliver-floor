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
#     models      one task; the request's Staffing says "the backend developer works on haiku" → judged from the transcripts
#     light       a repo with the watchlist slice already delivered (no architecture.md); a small change (JOB-light.md) →
#                 Michael takes the light path (no Lead, ≤ 2 cards), the human confirms the drafted architecture once and
#                 it is committed; then a second small change (JOB-light2.md) settles its architecture from that file (B1, B2)
#     shaped      the watchlist request without its clarifications (JOB-shaped.md), upstream.engine bmad: the BMad Method
#                 shapes it — its own path, the ledger decided with the human (HUMAN_ANSWERS.json by topic; an item no answer
#                 fits takes Michael's proposal, counted), its update and review — frozen, then delivered; the hidden oracle
#                 judges whether the shaped specification was the right one (S1)
#     idea        an idea, not a specification (JOB-idea.md: one paragraph, no requirements table, no contract) — shaped as
#                 above; its human knows the business's answers (HUMAN_ANSWERS-idea.json: scope, contract, C1–C8) (S2)
#   E2E_SHAPING=off      the shaped scenario without shaping: the same request, the readiness review alone (the control run)
#   E2E_FALLBACK=recommended   a readiness question no prepared answer fits takes the BA's (recommended) option — the same
#                        policy as "Michael's proposal accepted" in a shaped run, so the two compare; each is logged
#   Every scenario on 0.16.0 settings also judges the risk-based test design, the NFR gate and the blind review (B3, B4).
#   Each writes <work dir>/<scenario>/report.md (the scenario, step by step) and keeps every artifact.
#   Costs real tokens (a scenario ≈ 3–6 USD, 10–25 min). Env: PERMISSION_MODE (default bypassPermissions), E2E_ROUNDS (8).
#   E2E_MISMATCH=<readiness id>  the human first answers that item with an unrelated answer: Michael must not build on it,
#                                must ask it again (still the start), and deliver after the right answer (R2)
#   E2E_INJECT=regression        fault injection, disclosed in the report: a git post-merge hook breaks the rating scale on the
#                                job branch once, right after the merge that brings it (BBB- and BB+ swapped) — a finding after
#                                the start: Michael opens a fix, the Lead cuts it, the BA specs it, dl fix add (F23)
#   E2E_INJECT=hang              (disclosed) the same hook adds a test that never ends to the job branch after its first merge:
#                                the suite after the merge must be stopped (STALLED) and fixed through a fix card
#   E2E_INJECT=qa-wrong          (disclosed) when QA's tests join a card branch, one wrong assertion is appended to one of them:
#                                the gate fails on QA's own test, QA fixes it, the next gate takes it as QA's (qa_fix)
#   E2E_SUITE_RUNS=card|batch|end, E2E_SUITE_TIMEOUT_MIN=<min>   written to .deliver.json (suite_runs, suite_timeout_min)
#   E2E_MAX_ATTEMPTS=1           one attempt per card: a review change blocks a card; Michael must decide it himself — split
#                                or drop, recorded and listed in the PR — and ask nothing (R3). No blocked card = not exercised
set -uo pipefail
# grep -q exits on the first match; under pipefail the producer then dies of SIGPIPE and the pipe fails at random. gq reads to EOF.
gq() { grep "$@" >/dev/null; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SC="${1:?usage: e2e-live.sh complete|incomplete|parallel|models|light|shaped|idea [work dir]}"
EXN=watchlist-poc; EX="$HERE/examples/$EXN"
case $SC in
  complete)   REQ="$EX/JOB.md";            ORACLE=watchlist.oracle.test.mjs ;;
  incomplete) REQ="$EX/JOB-incomplete.md"; ORACLE=watchlist.oracle.test.mjs ;;
  parallel)   REQ="$EX/JOB-parallel.md";   ORACLE=parallel.oracle.test.mjs ;;
  models)     REQ="$EX/JOB-models.md";     ORACLE=models.oracle.test.mjs ;;
  light)      REQ="$EX/JOB-light.md";      ORACLE=light.oracle.test.mjs ;;
  shaped)     REQ="$EX/JOB-shaped.md";     ORACLE=watchlist.oracle.test.mjs ;;
  idea)       REQ="$EX/JOB-idea.md";       ORACLE=watchlist.oracle.test.mjs ;;
  *) echo "unknown scenario: $SC" >&2; exit 2 ;;
esac
export PICK_REQUEST="$(basename "$REQ")"   # answers that belong to one request (`requests`) reach only its scenario
ANSWERS="$EX/HUMAN_ANSWERS.json"; [[ $SC == idea ]] && ANSWERS="$EX/HUMAN_ANSWERS-idea.json"   # what the scenario's human knows
SHAPED_SC=0; [[ $SC == shaped || $SC == idea ]] && SHAPED_SC=1
W="${2:-$(mktemp -d "${TMPDIR:-/tmp}/deliver-e2e.XXXXXX")}"; mkdir -p "$W/$SC"; W="$(cd "$W/$SC" && pwd)"
export ISO_HOME="$W/home"; mkdir -p "$ISO_HOME"
. "$HERE/tests/lib-isolated-claude.sh"
export PERMISSION_MODE="${PERMISSION_MODE:-bypassPermissions}" IS_SANDBOX=1
# Claude Code does not hand its token to the commands it runs: the BMad sessions dl shape run starts get it from a file
if [[ -n ${CLAUDE_CODE_OAUTH_TOKEN:-} && -z ${DELIVER_CLAUDE_TOKEN_FILE:-} ]]; then
  DELIVER_CLAUDE_TOKEN_FILE="$(mktemp "${TMPDIR:-/tmp}/deliver-e2e-token.XXXXXX")"; chmod 600 "$DELIVER_CLAUDE_TOKEN_FILE"
  printf '%s' "$CLAUDE_CODE_OAUTH_TOKEN" > "$DELIVER_CLAUDE_TOKEN_FILE"; export DELIVER_CLAUDE_TOKEN_FILE
  trap 'rm -f "$DELIVER_CLAUDE_TOKEN_FILE"' EXIT
fi
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
SB="$W/repo"; rm -rf "$SB"
if [[ -n ${E2E_FRESH_REPO:-} ]]; then
  # a repo with no .deliver.json: the first /deliver must write it from the repo; subagents come from the user's own config
  iso_env "$HERE/scripts/sandbox.sh" "$SB" "$EXN" > /dev/null
  git -C "$SB" rm -q .deliver.json && git -C "$SB" commit -qm "no .deliver.json: the first /deliver writes it"   # the seed ships one
  mkdir -p "$ISO_HOME/.deliver" && echo '{"dispatch":"subagent"}' > "$ISO_HOME/.deliver/config.json"
  [[ ! -f $SB/.deliver.json ]] && ok "fresh repo: no .deliver.json; ~/.deliver/config.json says dispatch subagent" || bad "sandbox wrote a .deliver.json"
else iso_env "$HERE/scripts/sandbox.sh" --subagent "$SB" "$EXN" > /dev/null; fi
if [[ $SHAPED_SC == 1 ]]; then   # shaping on; the POC document the request names is in the repo
  mkdir -p "$SB/docs" && cp "$EX/POC_Requirements_v0.2_EN.md" "$SB/docs/"
  [[ ${E2E_SHAPING:-on} == off ]] || { jq '.upstream = {engine: "bmad", review_rounds: 2}' "$SB/.deliver.json" > "$SB/.deliver.json.t" && mv "$SB/.deliver.json.t" "$SB/.deliver.json"; }
  git -C "$SB" add -A && git -C "$SB" commit -qm "shaping with the BMad Method; the POC document" && log "upstream.engine = bmad; docs/POC_Requirements_v0.2_EN.md in the repo"
fi
if [[ $SC == light ]]; then   # an existing codebase: the slice JOB.md delivers, with its unit and QA tests
  for d in T-01 T-02 QA-T-01 QA-T-02; do cp -R "$EX/reference/$d/." "$SB/"; done
  git -C "$SB" add -A && git -C "$SB" commit -qm "watchlist: notch calculator and Indicator 12 (REQ-06-02, REQ-03-12)"
  (cd "$SB" && node --test >/dev/null 2>&1) && ok "existing code in the repo: $(git -C "$SB" ls-files src test | grep -c .) files, its tests pass, no architecture.md" || bad "the seeded code's tests fail"
fi
if [[ -n ${E2E_MAX_ATTEMPTS:-} ]]; then
  jq --argjson n "$E2E_MAX_ATTEMPTS" '.max_attempts = $n' "$SB/.deliver.json" > "$SB/.deliver.json.t" && mv "$SB/.deliver.json.t" "$SB/.deliver.json"
  git -C "$SB" commit -qam "deliver: max_attempts $E2E_MAX_ATTEMPTS" && log "max_attempts = $E2E_MAX_ATTEMPTS (one review change blocks a card)"
fi
if [[ -n ${E2E_INJECT:-} ]]; then   # fault injection, disclosed in report.md: a post-merge hook that fires once and deletes itself
  case $E2E_INJECT in
    regression) on='job/*--*) exit 0 ;; job/*) ;;'; act='f=src/ratings/notch.mjs; [ -f "$f" ] || exit 0
perl -0pi -e '"'"'s/(["\x27])BBB-(["\x27])(\s*,\s*)(["\x27])BB\+(["\x27])/$4BB+$5$3$1BBB-$2/'"'"' "$f"
git diff --quiet -- "$f" && exit 0
rm -f "$0"; git commit -q -am "refactor: tidy the rating scale"' ;;
    hang) on='job/*--*) exit 0 ;; job/*) ;;'; act='mkdir -p test; printf '"'"'import { test } from "node:test";\ntest("rating scale stays loaded", async () => { await new Promise(() => setInterval(() => {}, 1000)); });\n'"'"' > test/zz-scale-loaded.test.mjs
rm -f "$0"; git add test/zz-scale-loaded.test.mjs && git commit -q -m "test: the rating scale stays loaded"' ;;
    qa-wrong) on='job/*--*) ;;'; act='git log -1 --format=%s | grep -q "QA tests" || exit 0
f="$(git diff --name-only HEAD^1 HEAD | grep -E "\.test\.mjs$" | head -1)"; [ -n "$f" ] || exit 0
printf '"'"'\n;(await import("node:test")).test("notch of an unchanged rating", async () => (await import("node:assert/strict")).default.equal((await import("%s")).notchChange("BBB", "BBB"), 1));\n'"'"' "$(dirname "$f" | awk -F/ '"'"'{ for (i = 1; i <= NF; i++) printf "../" }'"'"')src/ratings/notch.mjs" >> "$f"
rm -f "$0"; git commit -q -am "test: unchanged rating"' ;;
    *) echo "unknown E2E_INJECT: $E2E_INJECT" >&2; exit 2 ;;
  esac
  { printf '#!/bin/sh\n# e2e fault injection (%s), disclosed in report.md — fires once, then deletes itself\n' "$E2E_INJECT"
    printf 'case "$(git symbolic-ref --short HEAD 2>/dev/null)" in %s *) exit 0 ;; esac\n' "$on"
    printf '%s\n' "$act"
    printf 'echo "injected (%s) at $(git rev-parse HEAD) on $(git symbolic-ref --short HEAD), after: $(git log -1 --format=%%s HEAD^)" >> "%s"\n' "$E2E_INJECT" "$W/injected.log"
  } > "$SB/.git/hooks/post-merge"
  chmod +x "$SB/.git/hooks/post-merge"; log "fault injection (E2E_INJECT=$E2E_INJECT): a post-merge hook in the sandbox, once — see injected.log"
fi
if [[ -n ${E2E_SUITE_RUNS:-}${E2E_SUITE_TIMEOUT_MIN:-} ]]; then
  jq --arg r "${E2E_SUITE_RUNS:-}" --arg t "${E2E_SUITE_TIMEOUT_MIN:-}" '(if $r != "" then .suite_runs = $r else . end) | (if $t != "" then .suite_timeout_min = ($t | tonumber) else . end)' "$SB/.deliver.json" > "$SB/.deliver.json.t" && mv "$SB/.deliver.json.t" "$SB/.deliver.json"
  git -C "$SB" commit -qam "deliver: suite_runs ${E2E_SUITE_RUNS:-card}${E2E_SUITE_TIMEOUT_MIN:+, suite_timeout_min $E2E_SUITE_TIMEOUT_MIN}" && log "suite_runs ${E2E_SUITE_RUNS:-card}${E2E_SUITE_TIMEOUT_MIN:+ · suite_timeout_min $E2E_SUITE_TIMEOUT_MIN}"
fi
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
human_rounds() { local J=$1 JJ=$1/job.json round
for round in $(seq 1 "${E2E_HUMAN_ROUNDS:-$([[ $SHAPED_SC == 1 ]] && echo 12 || echo 3)}"); do
  [[ "$(jq -r .phase "$JJ")" == awaiting_clarification ]] || break
  step "4.$round · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes"
  [[ $SC != incomplete ]] && log "note: the $SC request still raised question(s) — recorded below; answering them is the human's job"
  log "Open questions (QUESTIONS.md):"; sed 's/^/    /' "$J/QUESTIONS.md" >> "$REP"
  # Shaping: what BMad decided, assumed, asked or found, each with Michael's proposal. The prepared human answers what a
  # prepared answer fits; the rest takes Michael's proposal — counted, since a real person would read each one.
  if [[ -f $J/shaping.json ]] && jq -e '[.ledger[] | select(.status=="open" and .needs_human)] | length > 0' "$J/shaping.json" >/dev/null; then
    while IFS=$'\t' read -r id q; do
      ans="$(node "$HERE/tests/pick-answer.mjs" "$ANSWERS" "$q" 2>/dev/null)"
      if [[ -n $ans ]]; then iso_env DELIVER_APPROVER=e2e-human "$DL" -C "$SB" clarify "$id" "$ans" > /dev/null && ok "answered $id from HUMAN_ANSWERS — $(cut -c1-90 <<<"$q")"; fi
    done < <(jq -r '.ledger[] | select(.status=="open" and .needs_human) | [.id, .text] | @tsv' "$J/shaping.json")
    n="$(jq '[.ledger[] | select(.status=="open" and .needs_human)] | length' "$J/shaping.json")"
    if [[ $n -gt 0 ]]; then
      iso_env DELIVER_APPROVER=e2e-human "$DL" -C "$SB" clarify proposals "e2e: no prepared answer fits — Michael's proposal accepted" > /dev/null \
        && log "accepted Michael's proposal for $n item(s) no prepared answer fits: $(jq -r '[.ledger[] | select(.decision.text // "" | test("no prepared answer fits")) | .id] | join(", ")' "$J/shaping.json")" \
        || bad "could not accept Michael's proposals"
    fi
    run_rounds | sed 's/^/    /'; continue
  fi
  while IFS=$'\t' read -r id q; do
    ans="$(node "$HERE/tests/pick-answer.mjs" "$ANSWERS" "$q" "$id" 2>/dev/null)"
    if [[ $id == "${E2E_MISMATCH:-}" && ! -f $W/.mismatched ]]; then   # R2: the first answer is about something else
      ans="$(jq -r '.[] | select(.topic | startswith("what '"'"'displayed'"'"' means")) | .answer' "$ANSWERS")"; touch "$W/.mismatched"
      log "    (R2) answering $id on purpose with an unrelated answer: ${ans:0:90}"
    fi
    # E2E_FALLBACK=recommended — the same policy as the shaped run's "Michael's proposal accepted": no prepared answer fits →
    # the option the BA marked (recommended), else its first option; counted, since a real person would read each one
    if [[ -z $ans && ${E2E_FALLBACK:-} == recommended ]]; then
      ans="$(jq -r --arg id "$id" '(.items // .)[] | select(.id == $id) | (.options // []) as $o | (([$o[] | select(test("recommended"; "i"))][0]) // $o[0] // "")' "$J/readiness.json")"
      [[ -n $ans ]] && { echo "$id" >> "$W/.fallback"; log "    no prepared answer fits $id — took the BA's recommended option: ${ans:0:100}"; }
    fi
    if [[ -n $ans ]]; then iso_env DELIVER_APPROVER=e2e-human "$DL" -C "$SB" clarify "$id" "$ans" > /dev/null && ok "answered $id — $(cut -c1-90 <<<"$q")"
    else bad "no prepared answer for $id — a real person must answer: $q"; fi
  done < <(jq -r '(.items // .)[] | select(.status=="open" and .owner != "pm") | [.id, .question] | @tsv' "$J/readiness.json")
  run_rounds | sed 's/^/    /'
done
}
human_rounds "$J"
log "wall time: $(( ($(date +%s) - start) / 60 )) min"

step "5 · verify the whole flow on disk"
if [[ -n ${E2E_FRESH_REPO:-} ]]; then
  chk "the first /deliver wrote .deliver.json" test -f "$SB/.deliver.json"
  log ".deliver.json: $(jq -c '{dispatch,verify_full,worktree_setup,merge_mode}' "$SB/.deliver.json" 2>/dev/null)"
  chk "…read from the repo: verify_full npm test (package.json scripts.test), no install step (no dependencies), local merge (no remote)" \
    jq -e '.verify_full == "npm test" and .worktree_setup == "" and .merge_mode == "local"' "$SB/.deliver.json"
  chk "…the user's own dispatch carried into it, and into the job" bash -c "jq -e '.dispatch == \"subagent\"' '$SB/.deliver.json' && jq -e '.settings.verify_full == \"npm test\" and .settings.dispatch == \"subagent\"' '$JJ'"
  ev="$(cat "$SB"/.work/runs/*.jsonl 2>/dev/null | grep -o 'verify_full: npm test — package.json scripts test' | head -1)"
  [[ -n $ev ]] && ok "…and Michael's session saw where each value came from (\"$ev\")" || bad "the evidence lines are not in the session transcript"
fi
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
for a in business-analyst $([[ $SC == light ]] || echo ecc:architect) qa-tester; do grep -q $'\tagent\t'"$a" "$J/events.log" && ok "role really ran: $a" || bad "no $a run in events.log"; done
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
# Time: a job must not get slower unnoticed — its own time from the event log (setup and the harness excluded), against
# E2E_MAX_MIN (default 15, the floor's two-seat request took 10–17 min on 0.6.0); dl timeline says where the time went.
TL="$(node "$HERE/kit/skills/deliver/bin/timeline.mjs" "$J" --json 2>/dev/null)"
if [[ -n $TL ]]; then
  node "$HERE/kit/skills/deliver/bin/timeline.mjs" "$J" > "$W/timeline.txt" 2>/dev/null
  jm="$(jq -r .total_min <<<"$TL")"; max="${E2E_MAX_MIN:-$([[ $SHAPED_SC == 1 ]] && echo 45 || echo 15)}"
  awk -v a="$jm" -v b="$max" 'BEGIN { exit !(a <= b) }' && ok "the job took $jm min (≤ $max; timeline.txt)" \
    || { bad "the job took $jm min (> $max) — where it went: $(jq -r '[.phases[] | "\(.phase) \(.min)"] | join(", ")' <<<"$TL"); busiest: $(jq -r '.seats[0] | "\(.who) \(.busy_min) min"' <<<"$TL") (timeline.txt)"; }
fi

if [[ $SC == parallel ]]; then
  step "6 · parallel seats"
  chk "the backend role has 2+ seats" jq -e '[.roles[] | select(.role=="backend") | .count // 1] | max >= 2' "$JJ"
  seats="$(jq -r '[.cards[] | .assignments[]?.seat] | unique | join(", ")' "$B")"; log "seats used: $seats"
  [[ $seats == *"#2"* ]] && ok "a second seat was used" || bad "only one seat used ($seats)"
  first_merge="$(grep -n $'\tintegrate\t' "$J/events.log" | head -1 | cut -d: -f1)"
  assigns_before="$(head -n "${first_merge:-0}" "$J/events.log" | grep -c $'\tassign\t')"
  [[ ${assigns_before:-0} -ge 2 ]] && ok "two cards were assigned before the first merge (they ran in parallel)" || bad "cards ran one after another"
fi
if [[ $SC == models ]]; then
  step "6 · models per role: the request's Staffing — the backend developer works on haiku"
  . "$HERE/tests/lib-models.sh"
  models_subagents "$ISO_HOME/.claude/projects" "$JJ" backend backend-dev haiku
fi
if [[ -n ${E2E_MISMATCH:-} ]]; then
  step "R2 · Michael does not build on an answer that does not answer its question"
  n="$(grep -cP "\tclarify\t$E2E_MISMATCH:" "$J/events.log")"
  [[ $n -ge 2 ]] && ok "$E2E_MISMATCH was asked again after the unrelated answer ($n answers recorded)" || bad "$E2E_MISMATCH was not asked again ($n answer(s) recorded)"
  grep -qP "\treopen\t$E2E_MISMATCH:" "$J/events.log" && ok "Michael put $E2E_MISMATCH back to the human (dl reopen): $(grep -P "\treopen\t$E2E_MISMATCH:" "$J/events.log" | head -1 | cut -f3 | cut -c1-100)" \
    || bad "Michael did not reopen $E2E_MISMATCH"
  fin="$(jq -r --arg id "$E2E_MISMATCH" '(.items // .)[] | select(.id==$id) | .answer // ""' "$J/readiness.json")"
  if grep -qP "\tfreeze\t" "$J/events.log"; then
    [[ $fin != *"displayed"* ]] && ok "the frozen answer for $E2E_MISMATCH is the right one: ${fin:0:80}" || bad "the unrelated answer was frozen: ${fin:0:80}"
  else bad "readiness was never frozen — the job did not get past the start"; fi
fi
if [[ -n ${E2E_MAX_ATTEMPTS:-} ]]; then
  step "R3 · a blocked card is Michael's decision — no question to the human after the start"
  blocked="$(grep -oP "\tstate\t\KT-[0-9]+(?==blocked)" "$J/events.log" | sort -u | tr '\n' ' ')"
  if [[ -z $blocked ]]; then log "R3 NOT EXERCISED: no card was blocked in this run (every card passed on its one attempt)"
  else
    log "blocked card(s): $blocked"
    pl="$(grep -nP "\tphase\tplanning" "$J/events.log" | head -1 | cut -d: -f1)"
    late="$(tail -n +"${pl:-1}" "$J/events.log" | grep -cP "\tphase\tawaiting_clarification|\tclarify\t")"
    [[ $late -eq 0 && ! -f $J/APPROVAL.md ]] && ok "no question to the human after planning (no clarify, no APPROVAL.md)" || bad "the human was asked after the start ($late event(s), APPROVAL.md: $([[ -f $J/APPROVAL.md ]] && echo yes || echo no))"
    for c in $blocked; do
      st="$(jq -r --arg c "$c" '.cards[] | select(.id==$c) | .state' "$B")"
      dec="$(grep -P "\tpm-decision\t$c:" "$J/events.log" | head -1 | cut -f3)"
      [[ ( $st == archived || $st == merged ) ]] && ok "$c was decided by Michael: now $st" || bad "$c is still $st"
      [[ $st == merged || -n $dec ]] && ok "…with a recorded decision: ${dec:0:110}" || bad "$c archived without a recorded decision"
    done
    grep -q "## Decisions Michael took himself" "$J/report.md" && [[ "$(sed -n '/deliver:pm-decisions/,$p' "$J/report.md" | grep -c '^- ')" -ge 1 ]] \
      && ok "the PR body lists his decisions" || bad "the PR body does not list the decisions"
    log "note: a dropped card leaves its requirement undelivered — the oracle result above shows the effect"
  fi
fi
# B3, B4 — 0.16.0: risk-based test design, the NFR gate, the blind review (a job on older settings has none of them)
if [[ "$(jq -r '.settings.test_design.risk // false' "$JJ")" == true ]]; then
  step "B3 · risk-based test design and the NFR gate"
  RISK="$ISO_HOME/.claude/skills/deliver/bin/risk.mjs"
  if pri="$(node "$RISK" plan "$J" 2>&1)"; then ok "every AC of the plan has a priority: $(jq -r 'map("\(.ac) \(.priority)") | join(", ")' <<<"$pri")"
  else bad "plan priorities: $pri"; fi
  chk "every card spec has a ## Test design" bash -c "for c in \$(jq -r '.cards[] | select(.state != \"archived\") | .id' '$B'); do grep -q '^## Test design' '$J/specs/'\$c.md || exit 1; done"
  log ""; log "Test design of $(jq -r '[.cards[] | select(.state != "archived")][0].id' "$B"):"
  sed -n '/^## Test design/,/^## /p' "$J/specs/$(jq -r '[.cards[] | select(.state != "archived")][0].id' "$B").md" | sed '$d' | sed 's/^/    /' >> "$REP"
  log "QA verdicts (each must name every AC of its card — dl qa refuses otherwise):"
  jq -r '.cards[] | select(.state=="merged") | "    - \(.id): \(.qa.summary // "-" | .[0:220])"' "$B" >> "$REP"
  nfr="$(node "$RISK" nfr "$J" 2>/dev/null)"; log "decided NFR items: $(jq -r 'map(.id) | join(", ") | if . == "" then "none" else . end' <<<"$nfr")"
  if [[ "$(jq length <<<"$nfr")" -gt 0 ]]; then
    if rows="$(node "$RISK" report "$J" 2>&1)"; then ok "the report gives every decided NFR item a result: $(jq -r 'map("\(.id) \(.status)") | join(", ")' <<<"$rows" 2>/dev/null || echo "$rows")"
    else bad "NFR rows in the report: $rows"; fi
    grep -q '^## Non-functional requirements' "$J/plan.md" && ok "the plan says how each is checked (## Non-functional requirements)" || bad "the plan has no ## Non-functional requirements"
    [[ "$(jq '(.waivers // []) | length' "$JJ")" -gt 0 ]] && log "waived: $(jq -r '[.waivers[] | "\(.id) — \(.why)"] | join("; ")' "$JJ")"
  else log "NOT EXERCISED: no NFR item was decided in this job (all n/a)"; fi
  step "B4 · the blind review"
  mode="$(jq -r '.settings.review.blind // "off"' "$JJ")"; log "settings.review.blind: $mode"
  for c in $(jq -r '.cards[] | select(.state=="merged") | .id' "$B"); do
    top="$(node "$RISK" card "$J" "$c" 2>/dev/null | jq -r '.top // "-"')"
    needs=no; [[ $mode == all || ( $mode == risk && ( $top == P0 || $top == P1 ) ) ]] && needs=yes
    br="$(jq -c --arg c "$c" '[.cards[] | select(.id==$c) | .reviews[]? | select(.by=="blind")]' "$B")"
    n="$(jq length <<<"$br")"
    if [[ $needs == yes ]]; then
      [[ $n -ge 1 ]] && ok "$c (top $top): reviewed blind $n time(s) — findings $(jq '[.[].triage[]?] | length' <<<"$br"): intended $(jq '[.[].triage[]? | select(.decision=="intended")] | length' <<<"$br"), defect $(jq '[.[].triage[]? | select(.decision=="defect")] | length' <<<"$br")" \
        || bad "$c (top $top) needed a blind review and has none"
      jq -r '.[].triage[]? | "    - [\(.decision)] \(.finding | .[0:140])" + (if .quote then " — quote: \(.quote | .[0:80])" else "" end)' <<<"$br" >> "$REP"
    else log "$c (top $top): no blind review needed"; fi
  done
  grep -q $'\tagent\tecc:code-reviewer' "$J/events.log" && log "blind agent runs: $(grep -c $'\tagent\tecc:code-reviewer' "$J/events.log")"
fi

if [[ $SHAPED_SC == 1 && ${E2E_SHAPING:-on} != off ]]; then
  step "S1 · shaped with the BMad Method"
  SHJ="$J/shaping.json"
  chk "the job was shaped (shaping.json)" test -f "$SHJ"
  log "BMad's path (bmad-help): $(jq -r '[.plan.sequence[]?.skill] | join(" → ")' "$SHJ") · skipped: $(jq -r '[.plan.skipped[]?.skill] | join(", ")' "$SHJ")"
  log "runs: $(jq -r '[.runs[] | "\(.name) \(.status) \(.seconds)s $\(.cost // 0 | . * 100 | round / 100)"] | join(" · ")' "$SHJ")"
  log "shaping: $(jq '.runs | length' "$SHJ") runs, $(jq '[.runs[].seconds] | add / 60 | floor' "$SHJ") min, \$$(jq '[.runs[].cost // 0] | add * 100 | round / 100' "$SHJ")"
  log "ledger: $(jq -r '.ledger | group_by(.kind) | map("\(.[0].kind) \(length)") | join(", ")' "$SHJ") · decided by the human $(jq '[.ledger[] | select(.decision.by // "" | startswith("human"))] | length' "$SHJ"), by Michael $(jq '[.ledger[] | select(.decision.by == "pm")] | length' "$SHJ"), Michael's proposal accepted without a prepared answer $(jq '[.ledger[] | select(.decision.text // "" | test("no prepared answer fits"))] | length' "$SHJ")"
  chk "every ledger item decided (or noted)" jq -e 'all(.ledger[]; .status != "open")' "$SHJ"
  log "BMad's reviews: $(jq -r '[.reviews[] | "round \(.round): \(.verdict) (\(.findings))"] | join(" · ")' "$SHJ")"
  chk "BMad reviewed its own work at least once" jq -e '.reviews | length >= 1' "$SHJ"
  chk "frozen with readiness at planning (frozen.shaping_sha256)" jq -e '.frozen.shaping_sha256' "$JJ"
  nb="$(jq '[(.items // .)[] | select((.source // "") | test("^\\s*(bmad|shape):"))] | length' "$J/readiness.json")"
  [[ $nb -gt 0 ]] && ok "the readiness review settled $nb item(s) from BMad's words (bmad: / shape:)" || bad "no readiness item quotes BMad's artifacts or the ledger"
  ids="$(node "$ISO_HOME/.claude/skills/deliver/bin/bmad.mjs" ids "$J" 2>/dev/null | jq -r 'join(", ")')"; log "traced ids: ${ids:-none} (dl validate refuses a plan that leaves one out)"
  [[ -f $J/standards/bmad-architecture.md ]] && log "AD rules for the reviewers: $(grep -c '^- \[AD-' "$J/standards/bmad-architecture.md")" || log "no architecture spine: no AD rules"
  chk "the PR body says how it was shaped" grep -q '## Shaped with the BMad Method' "$J/report.md"
  chk "the record keeps BMad's inputs and artifacts on main" bash -c "git -C '$SB' ls-tree -r --name-only main | grep -q '^.deliver/jobs/.*/bmad/shaping.json'"
  chk "BMad's install stayed outside git" bash -c "! git -C '$SB' ls-tree -r --name-only main | grep -qE '^(_bmad/|\.claude/skills/bmad-)'"
  cp "$SHJ" "$W/shaping.json" 2>/dev/null; cp -R "$J/bmad" "$W/bmad" 2>/dev/null
fi
if [[ $SC == light ]]; then
  step "B1 · the light path"
  chk "Michael took the light path, with the request's words" jq -e '.tracks[0].to == "light" and any(.pm_decisions[]; .what | test("light path"))' "$JJ"
  log "his reason: $(jq -r '[.pm_decisions[] | select(.what | test("light path"))][0] | "\(.what) — \(.why // "")" | .[0:240]' "$JJ")"
  chk "…and stayed on it (no dl track full)" jq -e '.track == "light"' "$JJ"
  log "readiness: $(jq '(.items // .) | length' "$J/readiness.json") items (the full path asks $(jq -n --slurpfile j "$JJ" '$j[0] | .track = "full"' > "$W/full-job.json" && mkdir -p "$W/fulljob" && cp "$W/full-job.json" "$W/fulljob/job.json" && node "$ISO_HOME/.claude/skills/deliver/bin/readiness.mjs" applicable "$W/fulljob" | jq length) for this repo)"
  chk "no Lead role" jq -e '[.roles[].role] | all(test("lead") | not)' "$JJ"
  chk "at most $(jq -r '.settings.light.max_cards' "$JJ") cards" bash -c "[[ \$(jq '[.cards[] | select(.state != \"archived\")] | length' '$B') -le \$(jq -r .settings.light.max_cards '$JJ') ]]"
  step "B2 · the project's architecture, confirmed once and committed"
  grep -q $'\tcontext\t' "$J/events.log" && log "context events: $(grep $'\tcontext\t' "$J/events.log" | cut -f3 | cut -c1-120 | tr '\n' ' ')"
  log "ARC answers: $(jq -r '[(.items // .)[] | select(.id=="ARC-style" or .id=="ARC-components") | "\(.id): \(.status) (\(.source // "-"))"] | join("; ")' "$J/readiness.json")"
  chk "architecture.md is on main" git -C "$SB" cat-file -e main:.deliver/knowledge/architecture.md
  git -C "$SB" show main:.deliver/knowledge/architecture.md > "$W/architecture.md" 2>/dev/null
  chk "…and dl context check passes on it" iso_env node "$ISO_HOME/.claude/skills/deliver/bin/context.mjs" check "$SB"
  chk "the PR body says so (## Project architecture)" grep -q '## Project architecture' "$J/report.md"

  step "B2 · a second small change settles its architecture from the file (JOB-light2.md)"
  git -C "$SB" checkout -q main 2>/dev/null
  run_rounds "$EX/JOB-light2.md" | sed 's/^/    /'
  J2="$(ls -td "$SB"/.work/JOB-* | grep -v "^$J\$" | head -1)"
  if [[ -n $J2 && $J2 != "$J" ]]; then
    human_rounds "$J2"
    JJ2="$J2/job.json"
    chk "the second job reached done" test "$(jq -r .phase "$JJ2")" == done
    chk "…on the light path" jq -e '.track == "light"' "$JJ2"
    ! grep -qP "\tclarify\tARC-(style|components):" "$J2/events.log" && ok "the human was not asked about the architecture again" || bad "the human was asked about the architecture again"
    fid="$(node "$ISO_HOME/.claude/skills/deliver/bin/context.mjs" components "$SB" 2>/dev/null | jq -c '[.[].id] | sort')"
    rid="$(jq -c '[.architecture.components[].id] | sort' "$J2/readiness.json")"
    [[ -n $fid && $(jq -n --argjson f "$fid" --argjson r "$rid" '$r - $f | length') == 0 ]] && ok "its components are the file's ($rid)" || bad "components $rid, the file has $fid"
    if "$HERE/scripts/check-oracle.sh" "$SB" main "$EXN" light2.oracle.test.mjs > "$W/oracle2.log" 2>&1; then ok "hidden oracle of the second change passes ($(grep -c '✔' "$W/oracle2.log") checks)"
    else bad "hidden oracle of the second change FAILED (oracle2.log)"; fi
    "$HERE/scripts/check-oracle.sh" "$SB" main "$EXN" light.oracle.test.mjs > /dev/null 2>&1 && ok "…and the first change still passes its oracle" || bad "the second change broke the first"
    cp "$J2/readiness.md" "$W/readiness2.md" 2>/dev/null; cp "$J2/report.md" "$W/job-report2.md" 2>/dev/null; cp "$J2/events.log" "$W/events2.log" 2>/dev/null
  else bad "no second job was created"; fi
fi
step "0.18 · inputs only when the work needs them"
chk "DEL-inputs: no input asked for by default (a .env file is never needed unless the work reads it)" jq -e '(.items // .) | map(select(.id=="DEL-inputs")) | .[0].status == "n_a" or ((.[0].inputs // []) | length == 0)' "$J/readiness.json"
! grep -qiE '\.env|api key' "$J/QUESTIONS.md" 2>/dev/null && ok "…and the human was not asked for a .env file or a key" || bad "the human was asked for an input: $(grep -iE '\.env|api key' "$J/QUESTIONS.md" | head -2)"
vac="$(grep -c $'\tverify-all\t' "$J/events.log")"; vrun="$(grep $'\tverify-all\t' "$J/events.log" | grep -vc 'kept:')"
log "verify-all: $vac call(s), $vrun run(s) of the suite — $(grep $'\tverify-all\t' "$J/events.log" | cut -f3 | tr '\n' ';')"
if [[ -n ${E2E_INJECT:-} ]]; then
  step "fault injected ($E2E_INJECT, disclosed): what the team did with it"
  if gq '^injected' "$W/injected.log" 2>/dev/null; then log "injection: $(cat "$W/injected.log")"; else bad "the injection did not happen"; fi
  grep -E $'\t(fix-open|fix-add|merge-check|verify-all|qa-fix|gate|qa|integrate|settings)\t' "$J/events.log" | cut -c1-260 | sed 's/^/    /' >> "$REP"
  if gq '^injected' "$W/injected.log" 2>/dev/null && [[ $E2E_INJECT != qa-wrong ]]; then
    chk "Michael opened a fix (dl fix open)" gq $'\tfix-open\t' "$J/events.log"
    log "fixes: $(jq -c '[.fixes[]? | {id, from, state, cards, finding: .finding[0:120]}]' "$JJ")"
    chk "…and added it from the Lead's cards with the BA's specs (dl fix add)" gq $'\tfix-add\t' "$J/events.log"
    fc="$(jq -r '[.cards[] | select(.fix) | .id] | join(" ")' "$B")"
    [[ -n $fc ]] && ok "fix card(s) on the board: $fc" || bad "no card names a fix"
    for c in $fc; do
      [[ -f $J/specs/$c.md && -f "$J/out/fix-$(jq -r --arg id "$c" '.cards[] | select(.id==$id) | .fix' "$B")/cards.json" ]] && ok "$c: the Lead's card (out/fix-…/cards.json) and the BA's spec (specs/$c.md)" || bad "$c: no Lead card file or no spec"
    done
    lead="$(cat "$SB"/.work/runs/*.jsonl 2>/dev/null | grep -c 'MODE: FIX')"; ba="$(cat "$SB"/.work/runs/*.jsonl 2>/dev/null | grep -c 'MODE: CARD SPECS')"
    [[ $lead -gt 0 ]] && ok "the Lead was asked in MODE: FIX (transcripts: $lead)" || bad "no MODE: FIX prompt in the transcripts"
    [[ $ba -gt 0 ]] && ok "the BA was asked for card specs (transcripts: $ba)" || bad "no MODE: CARD SPECS prompt in the transcripts"
  fi
  case $E2E_INJECT in
    hang)
      chk "the hung suite was stopped by dl (STALLED), not waited for" bash -c "grep -E \$'\t(merge-check|qa|gate|verify-all)\t' '$J/events.log' | grep -q STALLED || grep -l 'STALLED' '$J'/gates/*.log >/dev/null"
      chk "…and the hanging test is gone from main" bash -c "! git -C '$SB' cat-file -e main:test/zz-scale-loaded.test.mjs 2>/dev/null || ! git -C '$SB' show main:test/zz-scale-loaded.test.mjs | grep -q setInterval" ;;
    qa-wrong)
      chk "QA's own wrong test failed the gate" gq $'\tgate\tT-[0-9]* FAIL' "$J/events.log"
      chk "…QA fixed it and the next gate took it as QA's (qa_fix), no new dev attempt" bash -c "grep -q \$'\tqa-fix\t' '$J/events.log' && jq -e '[.cards[] | select(.qa_fix)] | length > 0' '$B'"
      log "qa_fix: $(jq -c '[.cards[] | select(.qa_fix) | {id, qa_fix, attempts}]' "$B")" ;;
  esac
  if [[ ${E2E_SUITE_RUNS:-} == end ]]; then
    chk "suite_runs end: no suite after a merge" bash -c "! grep -q \$'\tmerge-check\t' '$J/events.log'"
    [[ $E2E_INJECT == regression ]] && chk "verify-all named the card the failures point to (LIKELY T-…)" bash -c "cat '$SB'/.work/runs/*.jsonl | grep -q 'LIKELY  T-'"
  fi
fi
if [[ ${E2E_SUITE_RUNS:-} == batch ]]; then
  if gq 'DEFERRED' "$J/events.log"; then ok "suite_runs batch: a merge waited for its partner — $(grep DEFERRED "$J/events.log" | cut -f3 | head -2 | tr '\n' ';')"
  else log "suite_runs batch: no two cards of one component were ready to merge at the same moment — not exercised in this run"; fi
fi
cost="$(cat "$SB"/.work/runs/*.jsonl 2>/dev/null | jq -s '[.[] | select(.type=="result") | .total_cost_usd // 0] | add // 0')"
step "result"
log "cost: \$$(printf '%.2f' "$cost")  ·  artifacts: $W"
log "**$pass passed, $fail failed**"
cp "$J/events.log" "$W/events.log" 2>/dev/null; cp "$J/readiness.md" "$W/readiness.md" 2>/dev/null; cp "$J/report.md" "$W/job-report.md" 2>/dev/null
cp "$J/board.json" "$W/board.json" 2>/dev/null; cp "$J/plan.md" "$W/plan.md" 2>/dev/null
[[ $fail -eq 0 ]]
