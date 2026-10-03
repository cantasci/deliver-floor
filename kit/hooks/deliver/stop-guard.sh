#!/usr/bin/env bash
# Stop hook — while a job is executing/integrating, Michael cannot stop before the board is finished.
# Only affects the session that owns the job (the one whose transcript mentions the job id); other Claude
# sessions, dev workers in card worktrees and Munder Difflin workers are left alone.
# dispatch=munder: devs run as floor workers and wake Michael through his inbox, so waiting is allowed
# while the only open cards are running.
# Loop protection: lets the stop through after job.settings.stop_guard_max blocks.
# Any progress (dl phase/card/wt/gate/review/integrate/approve) resets the counter.
set -uo pipefail
input="$(cat)"
command -v jq >/dev/null || exit 0
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

in_card_worktree && exit 0
owned="$(owned_job)" || exit 0
IFS=$'\t' read -r job root <<<"$owned"
jf="$root/.work/$job/job.json"; bf="$root/.work/$job/board.json"
[[ -f $bf ]] || exit 0

phase="$(jq -r .phase "$jf")"
case $phase in executing|integrating) ;; *) exit 0 ;; esac

open="$(jq '[.cards[] | select(.state | IN("ready","running","review"))] | length' "$bf")"
[[ $open -gt 0 ]] || exit 0

if [[ "$(jq -r '.settings.dispatch // "subagent"' "$jf")" == munder ]]; then
  actionable="$(jq '[.cards[] | select(.state=="review" or .state=="ready")] | length' "$bf")"
  [[ $actionable -eq 0 ]] && exit 0   # only floor workers running: wait for their done messages
fi

counter="$root/.work/$job/.stop-blocks"
n=$(( $(cat "$counter" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$counter"
max="$(jq -r '.settings.stop_guard_max // 5' "$jf")"
if (( n > max )); then
  echo "deliver stop-guard: blocked $max times, letting you stop. Make sure job.json and the board reflect the real state." >&2
  exit 0
fi

cat >&2 <<EOF
Board not finished: job $job has $open open card(s) (phase: $phase). Do not stop.
- Run 'dl next' and do what it says (DISPATCH → agents, GATE/REVIEW/INTEGRATE → per card).
- If a human is genuinely needed: 'dl card <id> state blocked' + 'dl card <id> note "<reason>"',
  then ask the user about the blocked cards.
EOF
exit 2
