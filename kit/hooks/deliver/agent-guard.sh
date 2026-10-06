#!/usr/bin/env bash
# PreToolUse(Agent|Task) — background agents only where something will still be there to hear back.
# Measured (docs/09-testing.md): under `claude -p` the process exits when Michael ends his turn and background agents die
# with it, losing their work. Headless runs (DELIVER_HEADLESS=1) therefore dispatch in the foreground — several agents per
# message, every actionable stage at once. Interactive sessions may use background agents. On the Munder Difflin floor
# Michael uses no subagents at all: every role has a seat (dl md-hire / md-send).
set -uo pipefail
input="$(cat)"
command -v jq >/dev/null || exit 0
# On the Munder Difflin floor every role has a seat of its own: Michael (AGENT_ID=god) hands work to people, not subagents.
if [[ ${AGENT_ID:-} == god ]]; then
  . "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
  while IFS=$'\t' read -r job root; do
    [[ "$(jq -r '.settings.dispatch // empty' "$root/.work/$job/job.json" 2>/dev/null)" == munder ]] || continue
    echo "deliver agent-guard: on the Munder Difflin floor every role works at its own seat — no subagents. Send the work to the role's seat: \"\$DL\" md-send <seat|role> <task> <prompt-file> (dl md-seats shows who sits where; dl md-hire seats missing people)." >&2
    exit 2
  done < <(active_jobs)
fi
# Each agent let through is recorded ("dispatch"), its SubagentStop is logged as "agent" by subagent-log: the stop-guard
# knows who is still at work, and dl timeline measures how long each one worked.
allow() {
  . "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
  if owned="$(owned_job)"; then
    IFS=$'\t' read -r job root <<<"$owned"
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
