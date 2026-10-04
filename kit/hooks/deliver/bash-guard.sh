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

# --- Munder Difflin: Michael reads his inbox through dl md-inbox ----------------------------------------------------
# A glob move of agents/god/inbox files once filed a seat's report that had arrived seconds earlier, unread (run 15).
if [[ ${AGENT_ID:-} == god ]] && grep -q 'god/inbox' <<<"$cmd" && grep -Eq '(^|[^[:alnum:]_-])(mv|rm|find[^|;]*-delete)([[:space:]]|$)' <<<"$cmd"; then
  deny "read your inbox with \"\$DL\" md-inbox — it shows each message once and archives exactly those. Moving inbox files yourself can file a report unread."
fi

# --- git: everyone ---------------------------------------------------------------------------------------------
if grep -Eq '(^|[^[:alnum:]_-])git[[:space:]].*push' <<<"$cmd"; then
  grep -Eq -- '(--force|--force-with-lease|--mirror|--delete|[[:space:]]-f([[:space:]]|$)|[[:space:]]-d([[:space:]]|$)|[[:space:]]\+[[:alnum:]_/.-]+)' <<<"$cmd" \
    && deny "force push / remote delete is not allowed."
  grep -Eq '(^|[[:space:]:/])(main|master)([[:space:]]|$)' <<<"$cmd" \
    && deny "pushing directly to main/master is not allowed. Push the job/<id> branch and open a PR (after the merge gate)."
  # Agents may push only their own card branch (job/<JOB>--T-xx…), from inside its worktree; never main, never the job
  # branch, never another card's branch. Michael (dl) pushes card branches and the job branch.
  if is_agent; then
    own="$(git -C "$(hk .cwd)" symbolic-ref --short -q HEAD 2>/dev/null || true)"
    [[ $own == job/*--T-* ]] || deny "agents push only their own card branch, from inside its worktree (this directory is not a card worktree)."
    grep -Eq "(^|[[:space:]:])(job/[^[:space:]:]*)" <<<"$cmd" || deny "name the branch explicitly: git push origin $own"
    for ref in $(grep -Eo "job/[^[:space:]:]+" <<<"$cmd"); do
      [[ $ref == "$own" ]] || deny "agents push only their own card branch ($own), not $ref."
    done
  fi
fi

grep -Eq 'rm[[:space:]]+-[[:alpha:]]*[rR][[:alpha:]]*[[:space:]]+([^;&|]*[[:space:]])?[^[:space:]]*\.work(/|[[:space:]]|$)' <<<"$cmd" \
  && deny ".work/ must not be deleted — job state lives there. Use 'dl cleanup'."

grep -Eq 'git[[:space:]].*worktree[[:space:]]+(remove|prune)[^;&|]*(_integration|\.work)' <<<"$cmd" \
  && deny "job worktrees are managed by dl. Use 'dl cleanup'."

grep -Eq 'git[[:space:]].*branch[[:space:]]+(-[[:alpha:]]*[dD]|--delete)[^;&|]*job/' <<<"$cmd" \
  && deny "job/ branches must not be deleted by agents. Delete them yourself after the job is closed."

# --- dl: who may change the flow's state ------------------------------------------------------------------------
# dl as a word, a path (…/bin/dl) or the variable the playbook uses ("$DL", ${DL})
dl_re='(^|[;&|[:space:](/"'"'"'])(dl|\$\{?DL\}?)"?[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?'
if grep -Eq "${dl_re}(new|phase|jobset|roles|readiness|clarify|decide|pm-decide|reopen|learn|wt|card|gate|qa|review|integrate|verify-all|ship|approve|reject|md-dispatch|md-hire|md-send|md-done|md-release|md-inbox|cleanup)([[:space:]]|$)" <<<"$cmd"; then
  is_agent && deny "only the orchestrator (Michael) runs state-changing dl commands. Report back in your summary instead."
fi
if grep -Eq "${dl_re}(approve|reject|clarify)([[:space:]]|$)" <<<"$cmd"; then
  [[ ${DELIVER_HEADLESS:-} == 1 ]] && deny "no human is in this session (headless). Write the question down (APPROVAL.md / QUESTIONS.md) and stop; the human answers in a terminal (dl approve | reject | clarify)."
fi
grep -Eq "${dl_re}(unfreeze|reseal)([[:space:]]|$)" <<<"$cmd" \
  && deny "frozen decisions and seals are a human's call, from their own terminal (dl unfreeze | dl reseal \"<reason>\")."
grep -Eq "${dl_re}phase[[:space:]][^;&|]*--force" <<<"$cmd" \
  && deny "'dl phase … --force' bypasses the flow's guards; only a human may run it, from their own terminal."
grep -Eq "${dl_re}card[[:space:]]+[^[:space:]]+[[:space:]]+retry" <<<"$cmd" && [[ ${DELIVER_HEADLESS:-} == 1 ]] \
  && deny "granting a blocked card new attempts is a human decision; in headless mode the human runs it."

# --- the flow's state files: written by dl only, once work has started -----------------------------------------
# job.json and board.json are sealed (sha256); a write by any other tool stops the flow until a human reseals. Refuse
# such a write up front, with the command to use instead, so the session corrects itself.
if grep -Eq '(job|board)\.json' <<<"$cmd" && grep -Eq '(writeFileSync|>[[:space:]]*[^[:space:]|&;]*(job|board)\.json|sed[[:space:]]+(-[a-zA-Z]*i|--in-place)|tee[[:space:]][^|&;]*(job|board)\.json|(mv|cp)[[:space:]][^|&;]*(job|board)\.json[[:space:]]*($|[;&|])|open\([^)]*(job|board)\.json[^)]*["'"'"'][wa])' <<<"$cmd"; then
  if owned="$(owned_job || active_jobs | awk 'NR==1')" && [[ -n $owned ]]; then
    IFS=$'\t' read -r job root <<<"$owned"
    phase="$(jq -r .phase "$root/.work/$job/job.json" 2>/dev/null)"
    grep -Eq '(^|[^[:alnum:]_])job\.json' <<<"$cmd" \
      && deny "job.json is written by dl only (sealed). Use: dl jobset '<jq expr>' (logged) — or ask the human."
    case $phase in intake|readiness|awaiting_clarification|planning|awaiting_plan_approval) ;;
      *) deny "board.json is written by dl only once work has started (phase $phase; sealed). Change a ready/blocked card with: dl card <id> set <field> <json> \"<reason>\" · add one with: dl card add <card.json> \"<reason>\" · a running card's contract does not change — put extra detail in the dispatch prompt." ;;
    esac
  fi
fi

exit 0
