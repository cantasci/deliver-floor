#!/usr/bin/env bash
# LIVE end-to-end in INTERACTIVE mode — a person at a terminal with Michael, no headless runner, no office floor.
#   setup   fresh HOME → ECC from GitHub → scripts/install.sh → doctor → sandbox repo (as tests/e2e-live.sh)
#   run     the real Claude Code TUI in tmux; the "person" types `/deliver <JOB.md>` and then only reads the screen:
#           first-run / trust / permission dialogs are answered as a person would; when Michael asks the human, the
#           answers come from HUMAN_ANSWERS.json, typed into the chat (a question none matches fails the run); when
#           Michael ends his turn with the job unfinished and nothing running, the person says "continue" (counted).
#   verify  tests/verify-job.sh on the delivered repo + interactive-only checks; screen snapshots in <work>/screens/
#
#   tests/e2e-interactive.sh [work dir]        E2E_JOB=JOB.md (default) | JOB-parallel.md · E2E_MINUTES (60)
#   Costs real tokens (≈ 3–6 USD, 15–30 min).
set -uo pipefail
gq() { grep "$@" >/dev/null; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXN=watchlist-poc; EX="$HERE/examples/$EXN"
JOBF="${E2E_JOB:-JOB.md}"; REQ="$EX/$JOBF"; ORACLE=watchlist.oracle.test.mjs; [[ $JOBF == JOB-parallel.md ]] && ORACLE=parallel.oracle.test.mjs
W="${1:-$(mktemp -d "${TMPDIR:-/tmp}/deliver-ia.XXXXXX")}"; mkdir -p "$W/interactive"; W="$(cd "$W/interactive" && pwd)"
export ISO_HOME="$W/home"; mkdir -p "$ISO_HOME" "$W/screens"
. "$HERE/tests/lib-isolated-claude.sh"
export IS_SANDBOX=1 GIT_AUTHOR_NAME=e2e GIT_AUTHOR_EMAIL=e2e@example.com GIT_COMMITTER_NAME=e2e GIT_COMMITTER_EMAIL=e2e@example.com
REP="$W/report.md"; printf '# Live E2E — interactive (a person at the terminal)\n\nRequest: `examples/%s/%s` · started %s\n' "$EXN" "$JOBF" "$(date -u +%FT%TZ)" > "$REP"
log()  { printf '%s\n' "$*" | tee -a "$REP"; }
step() { printf '\n\033[1;36m━━ %s\033[0m\n' "$*"; printf '\n## %s\n\n' "$*" >> "$REP"; }
FAILED=0
ok()  { printf '  \033[32m✔\033[0m %s\n' "$1"; printf -- '- ✅ %s\n' "$1" >> "$REP"; }
bad() { printf '  \033[31m✘\033[0m %s\n' "$1"; printf -- '- ❌ %s\n' "$1" >> "$REP"; FAILED=1; }

step "1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo"
if ! iso_env claude plugin list 2>/dev/null | gq "ecc@ecc"; then
  iso_env claude plugin marketplace add https://github.com/affaan-m/ECC > "$W/ecc.log" 2>&1
  iso_env claude plugin install ecc@ecc >> "$W/ecc.log" 2>&1
fi
iso_env claude plugin list 2>/dev/null | gq ecc@ecc && ok "ECC plugin installed" || bad "ECC plugin not installed (ecc.log)"
iso_env "$HERE/scripts/install.sh" --user > "$W/install.log" 2>&1 && ok "kit installed (scripts/install.sh --user)" || bad "kit install failed (install.log)"
SB="$W/repo"; rm -rf "$SB"; iso_env "$HERE/scripts/sandbox.sh" "$SB" "$EXN" > /dev/null
iso_env "$HERE/scripts/doctor.sh" "$SB" > "$W/doctor.log" 2>&1 && ok "doctor: $(tail -1 "$W/doctor.log")" || bad "doctor: $(tail -1 "$W/doctor.log")"
# A person who has used Claude Code once has finished its first-run screens; trusting the repo is asked on screen.
cj="$ISO_HOME/.claude.json"; [[ -s $cj ]] || echo '{}' > "$cj"
jq '.hasCompletedOnboarding = true | .theme = (.theme // "dark")' "$cj" > "$cj.tmp" && mv "$cj.tmp" "$cj"
DL="$ISO_HOME/.claude/skills/deliver/bin/dl"

step "2 · the terminal: claude in tmux, the person types /deliver and watches"
T="deliver-ia-$$"; tm() { tmux -L "$T" "$@"; }
# the tmux server starts inside the isolated environment, so the claude it runs sees only that
iso_env TERM=xterm-256color tmux -L "$T" new-session -d -s main -x 200 -y 50 -c "$SB" "claude --dangerously-skip-permissions"
trap 'tm kill-server 2>/dev/null' EXIT
screen() { tm capture-pane -p -t main 2>/dev/null; }
snap() { screen > "$W/screens/$(printf '%04d' $(( $(date +%s) - t0 )))-$1.txt"; }
say() { tm send-keys -t main -l "$1"; sleep 1; tm send-keys -t main Enter; log "    person typed: ${1:0:160}"; }
t0=$(date +%s)
# dialogs before the prompt: trust this folder, accept bypass-permissions mode
for i in $(seq 1 60); do
  s="$(screen)"
  if grep -q "Yes, I accept" <<<"$s"; then tm send-keys -t main Down; sleep 0.5; tm send-keys -t main Enter; log "    dialog: accepted bypass-permissions mode"; sleep 2; continue; fi
  # "❯ No, exit / Yes, I trust this folder": the default is No — one down, then confirm
  if grep -q "Yes, I trust this folder" <<<"$s"; then tm send-keys -t main Down; sleep 0.5; tm send-keys -t main Enter; log "    dialog: trusted the repo folder"; sleep 2; continue; fi
  grep -qE "for shortcuts|bypass permissions on|^│ >|^> " <<<"$s" && break
  sleep 2
done
snap ready
grep -qE "for shortcuts|bypass permissions on" <<<"$(screen)" && ok "Claude Code's prompt is up (interactive session)" || { bad "the prompt did not come up (screens/)"; exit 1; }
say "/deliver $REQ"

idle_since=0 nudges=0 answered=0 last_phase="" last_snap=0 deadline=$(( t0 + ${E2E_MINUTES:-60} * 60 ))
busy() { grep -qE "esc to interrupt|Running…|thinking" <<<"$1"; }
while (( $(date +%s) < deadline )); do
  sleep 10
  s="$(screen)"; now=$(date +%s)
  (( now - last_snap >= 60 )) && { snap run; last_snap=$now; }
  J="$(ls -d "$SB"/.work/JOB-* 2>/dev/null | head -1)"; [[ -n $J ]] || continue
  ph="$(jq -r .phase "$J/job.json" 2>/dev/null)"
  [[ $ph != "$last_phase" ]] && { log "    [$(( now - t0 ))s] phase $ph"; last_phase=$ph; snap "phase-$ph"; }
  [[ $ph == done || $ph == awaiting_pr_merge || $ph == aborted ]] && break
  # Michael asks the human (AskUserQuestion on screen, or a question in chat while the job waits for clarification)
  if [[ $ph == awaiting_clarification ]] && ! busy "$s"; then
    grep -q "Enter to select" <<<"$s" && { tm send-keys -t main Escape; sleep 2; log "    the question form was closed to answer in chat"; }
    msg="" miss=""
    while IFS=$'\t' read -r id q; do
      a="$(node "$HERE/tests/pick-answer.mjs" "$EX/HUMAN_ANSWERS.json" "$q" "$id" 2>/dev/null)"
      if [[ -n $a ]]; then msg+="$id: $a  "; else miss+="$id ($q) "; fi
    done < <(jq -r '(.items // .)[] | select(.status=="open" and .owner != "pm") | [.id, .question] | @tsv' "$J/readiness.json" 2>/dev/null)
    if [[ -n $miss ]]; then bad "no prepared answer — a real person must answer: $miss"; break; fi
    if [[ -n $msg ]]; then say "My answers, in my words — record each with dl clarify: $msg"; answered=$((answered + 1)); idle_since=0; continue; fi
  fi
  # Michael ended his turn with the job unfinished: nothing is running → a person says continue (counted, at most 5)
  if busy "$s"; then idle_since=0
  elif (( idle_since == 0 )); then idle_since=$now
  elif (( now - idle_since > 180 )); then
    running="$(jq '[.cards[] | select(.state=="running")] | length' "$J/board.json" 2>/dev/null)"
    if (( nudges < 5 )) && [[ ${running:-0} == 0 ]]; then
      say "continue the /deliver job"; nudges=$((nudges + 1)); idle_since=0
    fi
  fi
done
snap final
log "wall time: $(( ($(date +%s) - t0) / 60 )) min · the person answered $answered time(s) and said continue $nudges time(s)"

step "3 · interactive-specific checks"
J="$(ls -d "$SB"/.work/JOB-* 2>/dev/null | head -1)"
[[ -n $J ]] && ok "Michael opened the job $(basename "$J") from the typed /deliver" || { bad "no job was created"; exit 1; }
[[ "$(jq -r .phase "$J/job.json")" == done ]] && ok "the job finished in the interactive session" || bad "the job did not finish (phase $(jq -r .phase "$J/job.json"))"
(( nudges <= 2 )) && ok "Michael kept the job moving on his own (person said continue $nudges time(s))" || bad "Michael needed $nudges nudges — he stops while work is waiting"
grep -q $'\tagent\t' "$J/events.log" && ok "the roles ran as Michael's subagents ($(grep -c $'\tagent\t' "$J/events.log") agent reports)" || bad "no subagent ran"
# a clarify recorded in this session came from the person's answers, never from a guess
nclar="$(grep -c $'\tclarify\t' "$J/events.log")"; log "    clarifications recorded: $nclar (answers given: $answered)"
(( nclar == 0 || answered > 0 )) && ok "every recorded human answer was given by the person" || bad "clarifications recorded without the person answering"

step "4 · verify the delivered job"
"$HERE/tests/verify-job.sh" "$SB" "$ORACLE" "$REP" "$ISO_HOME/.claude/skills/deliver" || FAILED=1
printf '\n**%s**\n' "$([[ $FAILED -eq 0 ]] && echo PASSED || echo FAILED)" >> "$REP"
exit $FAILED
