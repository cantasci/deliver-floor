#!/usr/bin/env bash
# The human's slash commands (/deliver:status, /deliver:answer …). Claude Code runs this before the model sees the command
# (the skill's `!` block), with what the human typed after the command on stdin — never parsed by a shell, so quotes, $ or
# backticks in an answer stay exactly as typed. The model cannot run these skills (disable-model-invocation).
#   slash.sh <command>   < what the human typed
set -uo pipefail
DL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dl"
cmd=${1:?usage: slash.sh <command>}
args="$(cat)"
args="${args#"${args%%[![:space:]]*}"}"; args="${args%"${args##*[![:space:]]}"}"   # trim
first=${args%%[[:space:]]*}; rest=${args#"$first"}; rest="${rest#"${rest%%[![:space:]]*}"}"
need() { [[ -n $1 ]] || { echo "usage: /deliver:$cmd $2"; exit 0; }; }
# Always exit 0 with dl's own words: Claude Code drops the whole output of a command that fails, so a refusal would vanish.
run() { local out rc=0; out="$(bash "$DL" "$@" 2>&1)" || rc=$?; printf '%s\n' "$out"; [[ $rc -eq 0 ]] || echo "(dl did not do it — exit $rc)"; exit 0; }
export DELIVER_HUMAN_CMD=1 DELIVER_APPROVER="${DELIVER_APPROVER:-${USER:-human}}"
case $cmd in
  status)   run status ;;
  board)    run kanban ;;
  seats)    run md-seats ;;
  timeline) run timeline ;;
  answer)   need "$rest" "<question id> <your answer>"; run clarify "$first" "$rest" ;;
  approve)  run approve plan "${args:-approved}" ;;
  reject)   need "$args" "<what to change in the plan>"; run reject plan "$args" ;;
  mode)     need "$rest" "munder|subagent <why>"; run dispatch "$first" "$rest" ;;
  retry)    need "$first" "<card id, e.g. T-03>"; run card "$first" retry ;;
  reseal)   need "$args" "<what was changed outside dl and why it is accepted>"; run reseal "$args" ;;
  unfreeze) need "$args" "<why the frozen decisions must change>"; run unfreeze "$args" ;;
  abort)    need "$args" "<why the job stops>"; run abort "$args" ;;
  new)      # what /deliver:new tells Claude: is a job in the way of a new one?
            if out="$(bash "$DL" status 2>/dev/null)" && [[ $out == job:* ]]; then
              echo "ACTIVE JOB — a new job cannot start while this one is active:"; printf '%s\n' "$out" | sed -n '1,4p'
            else echo "NO ACTIVE JOB"; fi ;;
  doctor)   bash "$DL" version 2>&1
            if cfg="$(bash "$DL" config 2>&1)"; then
              printf '%s\n' "$cfg" | sed -n 1p
              printf '%s\n' "$cfg" | sed 1d | jq -r '"dispatch: \(.dispatch) · merge_mode: \(.merge_mode) · verify_full: \(.verify_full // "" | if . == "" then "(none)" else . end)\(if (.munder.hive_root // "") != "" then " · floor: " + .munder.hive_root else "" end)"' 2>/dev/null
            else printf '%s\n' "$cfg"; fi
            node "$(dirname "$DL")/../../../hooks/deliver/setup.mjs" --report 2>&1; exit 0 ;;
  *)        echo "unknown command: $cmd"; exit 0 ;;
esac
