#!/usr/bin/env bash
# SubagentStop — appends one line to the active job's events.log whenever a role agent finishes.
# Works for plugin agents (ecc:*) too, because the hook lives in settings, not in the agent file.
set -uo pipefail
input="$(cat)"
command -v jq >/dev/null || exit 0
root="${CLAUDE_PROJECT_DIR:-$(jq -r '.cwd // empty' <<<"$input")}"
[[ -n $root && -f $root/.work/ACTIVE ]] || exit 0
job="$(cat "$root/.work/ACTIVE")"
[[ -d $root/.work/$job ]] || exit 0
jq -r --arg t "$(date -u +%FT%TZ)" \
  '[$t, "agent", "\(.agent_type // "?") \(.agent_id // "" | .[0:8]): \((.last_assistant_message // "") | gsub("\\s+"; " ") | .[0:160])"] | @tsv' \
  <<<"$input" >> "$root/.work/$job/events.log"
exit 0
