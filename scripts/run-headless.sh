#!/usr/bin/env bash
# Unattended mode: keeps running "/deliver resume" headless until the job is done
# or waits at a human gate. Start the job first (interactive /deliver, or the first run below).
#
#   scripts/run-headless.sh <repo path> ["<job description>"]   [max rounds, default 10]
#
# Approvals: when it stops at a gate, run in the repo:  dl approve plan   (or merge)
# then start this script again.
set -euo pipefail
repo="$(cd "${1:?repo path required}" && pwd)"; request="${2:-}"; rounds="${3:-10}"
cd "$repo"

# auto: classifier-based approvals (no prompts). If your plan lacks auto mode, use
# PERMISSION_MODE=acceptEdits and pre-allow Bash commands in .claude/settings.json (docs/03-settings.md).
mode="${PERMISSION_MODE:-auto}"
mkdir -p .work/runs

run() {
  local prompt=$1 log=".work/runs/$(date +%Y%m%d-%H%M%S).jsonl"
  echo "▶ claude -p \"$prompt\"   (log: $log)"
  claude -p "$prompt" --permission-mode "$mode" --output-format stream-json --verbose > "$log" || true
  jq -r 'select(.type=="result") | "  result: \(.subtype)  turns=\(.num_turns)  cost=$\(.total_cost_usd // 0)"' "$log" 2>/dev/null | tail -1
}

if [[ -n $request && ! -f .work/ACTIVE ]]; then run "/deliver $request"; fi

for ((i = 1; i <= rounds; i++)); do
  [[ -f .work/ACTIVE ]] || { echo "no active job."; exit 0; }
  job="$(cat .work/ACTIVE)"; phase="$(jq -r .phase ".work/$job/job.json")"
  case $phase in
    awaiting_plan_approval|awaiting_merge_approval)
      gate=${phase#awaiting_}; gate=${gate%_approval}
      if [[ "$(jq -r ".gates.$gate.status // empty" ".work/$job/job.json")" == "" ]]; then
        echo "⏸  waiting for a human: $phase. Read .work/$job/APPROVAL.md, then: dl approve $gate | dl reject $gate \"<note>\""
        exit 0
      fi ;;
    done|aborted) echo "✔ job $job: $phase"; exit 0 ;;
  esac
  echo "round $i — $job ($phase)"
  run "/deliver resume"
done
echo "stopped after $rounds rounds — check: dl status"
