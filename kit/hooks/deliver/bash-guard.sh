#!/usr/bin/env bash
# PreToolUse(Bash) — blocks hard-to-reverse commands, and keeps the flow's state in Michael's hands.
# This is a guardrail, not a sandbox: also enable branch protection on the remote.
set -uo pipefail
input="$(cat)"
command -v jq >/dev/null || exit 0
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cmd="$(hk .tool_input.command)"
[[ -n $cmd ]] || exit 0
deny() { echo "deliver bash-guard: $1" >&2; exit 2; }

# --- git: everyone ---------------------------------------------------------------------------------------------
if grep -Eq '(^|[^[:alnum:]_-])git[[:space:]].*push' <<<"$cmd"; then
  grep -Eq -- '(--force|--force-with-lease|--mirror|--delete|[[:space:]]-f([[:space:]]|$)|[[:space:]]-d([[:space:]]|$)|[[:space:]]\+[[:alnum:]_/.-]+)' <<<"$cmd" \
    && deny "force push / remote delete is not allowed."
  grep -Eq '(^|[[:space:]:/])(main|master)([[:space:]]|$)' <<<"$cmd" \
    && deny "pushing directly to main/master is not allowed. Push the job/<id> branch and open a PR (after the merge gate)."
  is_agent && deny "agents never push. Michael pushes the job branch after the merge gate."
fi

grep -Eq 'rm[[:space:]]+-[[:alpha:]]*[rR][[:alpha:]]*[[:space:]]+([^;&|]*[[:space:]])?[^[:space:]]*\.work(/|[[:space:]]|$)' <<<"$cmd" \
  && deny ".work/ must not be deleted — job state lives there. Use 'dl cleanup'."

grep -Eq 'git[[:space:]].*worktree[[:space:]]+(remove|prune)[^;&|]*(_integration|\.work)' <<<"$cmd" \
  && deny "job worktrees are managed by dl. Use 'dl cleanup'."

grep -Eq 'git[[:space:]].*branch[[:space:]]+(-[[:alpha:]]*[dD]|--delete)[^;&|]*job/' <<<"$cmd" \
  && deny "job/ branches must not be deleted by agents. Delete them yourself after the job is closed."

# --- dl: who may change the flow's state ------------------------------------------------------------------------
dl_re='(^|[;&|[:space:](/"'"'"'])dl[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?'
if grep -Eq "${dl_re}(new|phase|jobset|roles|readiness|clarify|learn|wt|card|gate|qa|review|integrate|verify-all|ship|approve|reject|md-dispatch|cleanup)([[:space:]]|$)" <<<"$cmd"; then
  is_agent && deny "only the orchestrator (Michael) runs state-changing dl commands. Report back in your summary instead."
fi
if grep -Eq "${dl_re}(approve|reject|clarify)([[:space:]]|$)" <<<"$cmd"; then
  [[ ${DELIVER_HEADLESS:-} == 1 ]] && deny "no human is in this session (headless). Write the question down (APPROVAL.md / QUESTIONS.md) and stop; the human answers in a terminal (dl approve | reject | clarify)."
fi
grep -Eq "${dl_re}unfreeze([[:space:]]|$)" <<<"$cmd" \
  && deny "frozen decisions are reopened only by a human, from their own terminal (dl unfreeze \"<reason>\")."
grep -Eq "${dl_re}phase[[:space:]][^;&|]*--force" <<<"$cmd" \
  && deny "'dl phase … --force' bypasses the flow's guards; only a human may run it, from their own terminal."
grep -Eq "${dl_re}card[[:space:]]+[^[:space:]]+[[:space:]]+retry" <<<"$cmd" && [[ ${DELIVER_HEADLESS:-} == 1 ]] \
  && deny "granting a blocked card new attempts is a human decision; in headless mode the human runs it."

exit 0
