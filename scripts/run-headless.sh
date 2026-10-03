#!/usr/bin/env bash
# Unattended mode: keeps running "/deliver resume" headless until the job is done
# or waits at a human gate. Start the job first (interactive /deliver, or the first run below).
#
#   scripts/run-headless.sh <repo path> ["<job description>"] [max rounds, default 10]
#
# Approvals: when it stops at a gate, run in the repo:  dl approve plan   (or merge, or dl reject … "<note>")
# then start this script again. DELIVER_HEADLESS=1 makes the hooks refuse any approval from the model itself.
set -euo pipefail
repo="$(cd "${1:?repo path required}" && pwd)"; request="${2:-}"; rounds="${3:-10}"
cd "$repo"
command -v claude >/dev/null || { echo "claude CLI not found" >&2; exit 1; }

# auto: classifier-based approvals (no prompts). If your plan lacks auto mode, use
# PERMISSION_MODE=acceptEdits and pre-allow Bash commands in .claude/settings.json (docs/02-setup.md § 5).
mode="${PERMISSION_MODE:-auto}"
export DELIVER_HEADLESS=1
export CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1   # agents must finish inside the -p process (they default to background)
mkdir -p .work/runs

run() {
  local prompt=$1 log; log=".work/runs/$(date +%Y%m%d-%H%M%S).jsonl"
  echo "▶ claude -p \"$prompt\"   (log: $log)"
  claude -p "$prompt" --permission-mode "$mode" --output-format stream-json --verbose > "$log" || true
  jq -r 'select(.type=="result") | "  result: \(.subtype)  turns=\(.num_turns)  cost=$\(.total_cost_usd // 0)"' "$log" 2>/dev/null | tail -1
}

if [[ -n $request && ! -f .work/ACTIVE ]]; then run "/deliver $request"; fi

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
  run "/deliver resume"
done
echo "stopped after $rounds rounds — check: dl status"
