#!/usr/bin/env bash
# PreToolUse(Bash) — blocks hard-to-reverse commands for every agent.
# This is a guardrail, not a sandbox: also enable branch protection on the remote.
set -uo pipefail
command -v jq >/dev/null || exit 0
cmd="$(jq -r '.tool_input.command // ""')"
deny() { echo "deliver bash-guard: $1" >&2; exit 2; }

if grep -Eq 'git[[:space:]].*push' <<<"$cmd"; then
  grep -Eq -- '(--force|--force-with-lease|[[:space:]]-f([[:space:]]|$)|[[:space:]]\+[[:alnum:]_/.-]+)' <<<"$cmd" \
    && deny "force push is not allowed."
  grep -Eq '(^|[[:space:]:/])(main|master)([[:space:]]|$)' <<<"$cmd" \
    && deny "pushing directly to main/master is not allowed. Push the job/<id> branch and open a PR (after the merge gate)."
fi

grep -Eq 'rm[[:space:]]+-[[:alpha:]]*[rR][[:alpha:]]*[[:space:]]+([^;&|]*[[:space:]])?[^[:space:]]*\.work(/|[[:space:]]|$)' <<<"$cmd" \
  && deny ".work/ must not be deleted — job state lives there. Use 'dl cleanup'."

grep -Eq 'git[[:space:]].*worktree[[:space:]]+remove[^;&|]*_integration' <<<"$cmd" \
  && deny "the integration worktree must not be removed by hand. Use 'dl cleanup --all'."

grep -Eq 'git[[:space:]].*branch[[:space:]]+-[dD][^;&|]*job/' <<<"$cmd" \
  && deny "job/ branches must not be deleted by agents. Delete them yourself after the job is closed."

exit 0
