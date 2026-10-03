#!/usr/bin/env bash
# Stop hook — while a job is executing, Michael cannot stop before the board is finished.
# Only affects the session that owns the job (the one whose transcript mentions the job id);
# other Claude sessions working in the same repo are left alone.
# Loop protection: lets the stop through after job.settings.stop_guard_max blocks.
# Any progress (dl phase/card/wt/integrate/approve) resets the counter.
set -uo pipefail
input="$(cat)"
command -v jq >/dev/null || exit 0

root="${CLAUDE_PROJECT_DIR:-$(jq -r '.cwd // empty' <<<"$input")}"
[[ -n $root ]] || exit 0
work="$root/.work"
[[ -f $work/ACTIVE ]] || exit 0
job="$(cat "$work/ACTIVE")"
jf="$work/$job/job.json"; bf="$work/$job/board.json"
[[ -f $jf && -f $bf ]] || exit 0

transcript="$(jq -r '.transcript_path // empty' <<<"$input")"
if [[ -n $transcript && -f $transcript ]]; then
  grep -q "$job" "$transcript" || exit 0   # this session does not own the job
fi

phase="$(jq -r .phase "$jf")"
case $phase in executing|integrating) ;; *) exit 0 ;; esac

open="$(jq '[.cards[] | select(.state | IN("merged","archived","blocked") | not)] | length' "$bf")"
[[ $open -gt 0 ]] || exit 0

counter="$work/$job/.stop-blocks"
n=$(( $(cat "$counter" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$counter"
max="$(jq -r '.settings.stop_guard_max // 5' "$jf")"
if (( n > max )); then
  echo "deliver stop-guard: blocked $max times, letting you stop. Make sure job.json and the board reflect the real state." >&2
  exit 0
fi

cat >&2 <<EOF
Board not finished: job $job has $open open card(s) (phase: $phase). Do not stop.
- Run 'dl status' and take the next step (ready card → dispatch, card in review → gate/review).
- If a human is genuinely needed: 'dl card <id> state blocked' + 'dl card <id> note "<reason>"',
  or move to a waiting phase such as 'dl phase awaiting_merge_approval' and ask the user.
EOF
exit 2
