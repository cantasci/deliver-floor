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
# Under the code driver DELIVER_AGENT_ID says which role session ran the subagent.
printf '%s\tagent\t%s %s%s: %s\n' "$(date -u +%FT%TZ)" "$(hk .agent_type)" "$(hk .agent_id)" "${DELIVER_AGENT_ID:+ @$DELIVER_AGENT_ID}" \
  "$(tr -s '[:space:]' ' ' <<<"$msg" | cut -c1-160)" >> "$root/.work/$job/events.log"
# What it spent (tokens from its transcript, priced by settings.prices; card and role from its prompt): dl timeline, the PR's
# cost section and the budget read it. Under the code driver the role session's own result counts it (run.mjs), not this.
at="$(hkp .agent_transcript_path)"
if [[ -z ${DELIVER_AGENT_ID:-} && -n $at && -f $at ]]; then
  u="$(node "$(dirname "${BASH_SOURCE[0]}")/../../skills/deliver/bin/usage.mjs" event "$at" "$root/.work/$job" "$(hk .agent_type)" "$(hk .agent_id)" 2>/dev/null)"
  [[ -n $u ]] && printf '%s\tusage\t%s\n' "$(date -u +%FT%TZ)" "$u" >> "$root/.work/$job/events.log"
fi
exit 0
