#!/usr/bin/env bash
# PreToolUse(Agent|Task) — background agents only where something will still be there to hear back.
# Measured (docs/09-testing.md): under `claude -p` the process exits when Michael ends his turn and background agents die
# with it, losing their work. Headless runs (DELIVER_HEADLESS=1) therefore dispatch in the foreground — several agents per
# message, every actionable stage at once. Interactive sessions and Munder Difflin may use background agents.
set -uo pipefail
input="$(cat)"
command -v jq >/dev/null || exit 0
[[ ${DELIVER_HEADLESS:-} == 1 ]] || exit 0
# With background tasks disabled (scripts/run-headless.sh sets this) the Agent tool has no background mode at all.
[[ ${CLAUDE_CODE_DISABLE_BACKGROUND_TASKS:-} == 1 ]] && exit 0
# Otherwise current Claude Code runs subagents in the background BY DEFAULT, so headless dispatch must say false explicitly.
[[ "$(jq -r 'if (.tool_input.run_in_background | tostring) == "false" then "fg" else "bg" end' <<<"$input")" == fg ]] && exit 0
echo "deliver agent-guard: headless run — background agents die when this process exits, and subagents default to the background. Dispatch with run_in_background: false explicitly (several Agent calls in one message still run in parallel)." >&2
exit 2
