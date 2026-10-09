#!/usr/bin/env bash
# Unattended mode: keeps running "/deliver resume" headless until the job is done
# or waits at a human gate. Start the job first (interactive /deliver, or the first run below).
#
#   scripts/run-headless.sh <repo path> ["<job description>"] [max rounds, default 40]
#
# When it stops for the human (open business questions → QUESTIONS.md, a blocked card or the optional plan gate →
# APPROVAL.md), answer in the repo:  dl clarify <id> "<answer>"  ·  dl card T-xx retry  ·  dl approve plan | dl reject plan "<note>"
# then start this script again. DELIVER_HEADLESS=1 makes the hooks refuse any answer or approval from the model itself.
# Each round is a fresh session: Michael ends his at every phase change and after every wave of cards (dl checkpoint), so
# his context stays small. A usage limit does not stop it: the round's last message names the reset ("resets 2:30pm (Europe/Berlin)"), the script waits
# until a minute past it and goes on (at most LIMIT_WAITS times, default 30). Out of credits it stops — that is the human's call.
set -euo pipefail
repo="$(cd "${1:?repo path required}" && pwd)"; request="${2:-}"; rounds="${3:-40}"
cd "$repo"
command -v claude >/dev/null || { echo "claude CLI not found" >&2; exit 1; }
# Unattended runs use Claude Code subagents; a floor job (Munder Difflin, the default) is run by the app's Michael.
# the layered settings: .deliver.json over the user's own config over the kit default (munder)
d="$(jq -r '.dispatch // empty' .deliver.json 2>/dev/null || true)"
[[ -n $d ]] || d="$(jq -r '.dispatch // empty' "${DELIVER_HOME:-$HOME/.deliver}/config.json" 2>/dev/null || true)"
[[ $d == subagent ]] || { echo "run-headless: this repo runs on the Munder Difflin floor (dispatch: ${d:-munder, the default}). Unattended runs need \"dispatch\": \"subagent\" in .deliver.json — see docs/07-munder-difflin.md#choosing-the-mode" >&2; exit 1; }

# auto: classifier-based approvals (no prompts). If your plan lacks auto mode, use
# PERMISSION_MODE=acceptEdits and pre-allow Bash commands in .claude/settings.json (docs/02-setup.md § 4.5).
mode="${PERMISSION_MODE:-auto}"
export DELIVER_HEADLESS=1
export CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1   # agents must finish inside the -p process (they default to background)
mkdir -p .work/runs
KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../kit/skills/deliver" && pwd)"
"$KIT/bin/dl" awake $$ >/dev/null 2>&1 && export DELIVER_AWAKE=1   # awake for the whole unattended run (dl keep_awake)
waits=0; max_waits="${LIMIT_WAITS:-30}"

run() {
  local prompt=$1 log; log=".work/runs/$(date +%Y%m%d-%H%M%S).jsonl"
  echo "▶ claude -p \"$prompt\"   (log: $log)"
  claude -p "$prompt" --permission-mode "$mode" --output-format stream-json --verbose > "$log" || true
  LAST_LOG=$log
  jq -r 'select(.type=="result") | "  result: \(.subtype)  turns=\(.num_turns)  cost=$\(.total_cost_usd // 0)"' "$log" 2>/dev/null | tail -1
}

# A usage limit is waited out, not handed to the human (live job: 36.6 of 65.7 hours were limit waits, many of them long past
# the reset because nobody saw it). wait_for_limit <round log> → 0: waited, run the round again · 1: no limit in the round
wait_for_limit() {
  local txt at secs rc=0
  txt="$(jq -rs '([.[] | select(.type=="assistant")] | last | .message.content // [] | if type=="array" then map(.text // "") | join(" ") else . end),
                 ([.[] | select(.type=="result")] | last | .result // "")' "$1" 2>/dev/null \
         | grep -oE "(([[:alpha:]']+ )?hit your .*limit.*|out of (usage )?credits.*)" | tail -1 || true)"
  [[ -n $txt ]] || return 1
  at="$(printf '%s' "$txt" | node "$KIT/bin/limit-reset.mjs")" || rc=$?
  if [[ $rc -eq 2 ]]; then echo "⏸  out of usage credits — add credits or switch the model, then run this script again"; exit 3; fi
  [[ $rc -eq 0 && -n $at ]] || return 1
  (( waits < max_waits )) || { echo "⏸  a usage limit again after $waits waits — stopping (LIMIT_WAITS=$max_waits)"; exit 3; }
  waits=$((waits + 1)); secs=$(( at - $(date +%s) + 60 )); (( secs > 0 )) || secs=60
  echo "⏸  usage limit: ${txt} — waiting $(( (secs + 59) / 60 )) min, then the job goes on (wait $waits of $max_waits)"
  sleep "$secs"
  return 0
}

# The plugin's skill is /deliver:deliver; only a copy of the kit (this repo's .claude, or ~/.claude without the plugin) is /deliver.
DCMD=/deliver:deliver; [[ -f .claude/skills/deliver/SKILL.md || -f ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/deliver/SKILL.md ]] && DCMD=/deliver
if [[ -n $request && ! -f .work/ACTIVE ]]; then
  run "$DCMD $request"
  while [[ ! -f .work/ACTIVE ]] && wait_for_limit "$LAST_LOG"; do run "$DCMD $request"; done
fi

last=""
for ((i = 1; i <= rounds; i++)); do
  [[ -f .work/ACTIVE ]] || { echo "no active job."; exit 0; }
  job="$(cat .work/ACTIVE)"; jf=".work/$job/job.json"; phase="$(jq -r .phase "$jf")"
  case $phase in
    awaiting_plan_approval|awaiting_merge_approval)
      gate=${phase#awaiting_}; gate=${gate%_approval}
      if [[ "$(jq -r ".settings.gates.$gate" "$jf")" != false && -z "$(jq -r ".gates.$gate.status // empty" "$jf")" ]]; then
        echo "⏸  waiting for a human: $phase. Read .work/$job/APPROVAL.md, then: dl approve $gate | dl reject $gate \"<note>\""
        exit 0
      fi ;;
    awaiting_clarification)
      if [[ -s .work/$job/QUESTIONS.md ]] && grep -q '^## ' ".work/$job/QUESTIONS.md"; then
        echo "⏸  the requirements have open questions: .work/$job/QUESTIONS.md — answer each with: dl clarify <id> \"<answer>\""
        exit 0
      fi ;;
    awaiting_pr_merge) echo "⏸  the PR is with the human: $(jq -r '.pr.url // "?"' "$jf") — then: dl pr"; exit 0 ;;
    done|aborted) echo "✔ job $job: $phase"; exit 0 ;;
  esac
  state="$phase $(wc -l < ".work/$job/events.log" 2>/dev/null)"   # events.log grows on every dl step
  if [[ $state == "$last" ]]; then echo "⚠ no progress in the last round ($phase) — stopping. Check: dl status; tail .work/$job/events.log"; exit 1; fi
  last=$state
  echo "round $i — $job ($phase)"
  run "$DCMD resume"
  if wait_for_limit "$LAST_LOG"; then last=""; i=$((i - 1)); fi   # a limit is neither a round nor "no progress"
done
echo "stopped after $rounds rounds — check: dl status"
