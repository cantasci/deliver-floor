#!/usr/bin/env bash
# PreToolUse(Agent|Task) — background agents only where something will still be there to hear back.
# Measured (docs/09-testing.md): under `claude -p` the process exits when Michael ends his turn and background agents die
# with it, losing their work. Headless runs (DELIVER_HEADLESS=1) therefore dispatch in the foreground — several agents per
# message, every actionable stage at once. Interactive sessions may use background agents.
set -uo pipefail
input="$(cat)"
# a BMad session started by dl shape run (shaping) is not Michael: it ends when its skill is done, with its own reviewers
[[ -n ${DELIVER_SHAPING:-} ]] && exit 0
command -v jq >/dev/null || exit 0
# Each agent let through is recorded ("dispatch"), its SubagentStop is logged as "agent" by subagent-log: the stop-guard
# knows who is still at work, and dl timeline measures how long each one worked.
allow() {
  . "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
  if owned="$(owned_job)"; then
    IFS=$'\t' read -r job root <<<"$owned"
    # the job's budget (settings.budget, raised only by the human): reached → nothing more is dispatched; the job stays as it
    # is and goes on once they raise it
    if [[ -z ${DELIVER_AGENT_ID:-} && -z "$(hk .agent_id)" ]]; then   # Michael's own session, not a role agent's
      local u="$(dirname "${BASH_SOURCE[0]}")/../../skills/deliver/bin/usage.mjs" t; t="$(hkp .transcript_path)"
      [[ -n $t && -f $t ]] && node "$u" michael "$t" "$root/.work/$job" 2>/dev/null
      local line rc=0; line="$(node "$u" budget "$root/.work/$job" 2>/dev/null)" || rc=$?
      if [[ $rc -eq 3 ]]; then
        echo "deliver agent-guard: the job's budget is used up — $line. Dispatch nothing more: tell the human what is done and what is left (dl status). Only they raise it: /deliver:budget usd=<n> | minutes=<n> <why>; the job goes on from where it is." >&2
        exit 2
      fi
    fi
    printf '%s\tdispatch\t%s\n' "$(date -u +%FT%TZ)" "$(jq -r '.tool_input.subagent_type // "agent"' <<<"$input")" >> "$root/.work/$job/events.log"
  fi
  exit 0
}
[[ ${DELIVER_HEADLESS:-} == 1 ]] || allow
# With background tasks disabled (scripts/run-headless.sh sets this) the Agent tool has no background mode at all.
[[ ${CLAUDE_CODE_DISABLE_BACKGROUND_TASKS:-} == 1 ]] && allow
# Otherwise current Claude Code runs subagents in the background BY DEFAULT, so headless dispatch must say false explicitly.
[[ "$(jq -r 'if (.tool_input.run_in_background | tostring) == "false" then "fg" else "bg" end' <<<"$input")" == fg ]] && allow
echo "deliver agent-guard: headless run — background agents die when this process exits, and subagents default to the background. Dispatch with run_in_background: false explicitly (several Agent calls in one message still run in parallel)." >&2
exit 2
