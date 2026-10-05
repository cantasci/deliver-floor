#!/usr/bin/env bash
# SubagentStop — appends one line to the active job's events.log whenever a role agent finishes.
# Works for plugin agents (ecc:*) too, because the hook lives in settings, not in the agent file.
set -uo pipefail
input="$(cat)"
command -v jq >/dev/null || exit 0
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
owned="$(owned_job)" || owned="$(active_jobs | awk 'NR==1')"
[[ -n $owned ]] || exit 0
IFS=$'\t' read -r job root <<<"$owned"

# No agent type = one of Claude Code's own helper forks (status line, prompt suggestion, tool summaries — seen live in
# 2.1.x on every session, with lines like "/deliver status"), never a role's work: not a role run, not logged.
[[ -n "$(hk .agent_type)" ]] || exit 0

msg="$(hk .last_assistant_message)"
if [[ -z $msg ]]; then # older Claude Code: read the agent's own transcript
  at="$(hkp .agent_transcript_path)"
  [[ -n $at && -f $at ]] && msg="$(jq -rs '[.[] | select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text] | last // ""' "$at" 2>/dev/null)"
fi
# On the Munder Difflin floor AGENT_ID says whose session ran the subagent (@god = Michael, @worker-… = a seat).
printf '%s\tagent\t%s %s%s: %s\n' "$(date -u +%FT%TZ)" "$(hk .agent_type)" "$(hk .agent_id | cut -c1-8)" "${AGENT_ID:+ @$AGENT_ID}" \
  "$(tr -s '[:space:]' ' ' <<<"$msg" | cut -c1-160)" >> "$root/.work/$job/events.log"
exit 0
