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

# --- everyone: no search of the whole disk ---------------------------------------------------------------------
# Run 53: Michael ran find / for an answer file; it hit the 2-minute Bash timeout. The job's files are named.
if grep -Eq '(^|[^[:alnum:]_-])find([[:space:]]+-[HLP])*[[:space:]]+["'"'"']?/\*?["'"'"']?([[:space:]]|;|\||&|$)' <<<"$cmd"; then
  deny "searching the whole disk is refused — it outlasts the command timeout. The job's files are under <repo>/.work/<job>/ (dl status prints it)."
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
    gdir="$(hkp .cwd)"   # the repo git acts on: `git -C <dir> push …` names it, else the shell's directory
    cdir="$(grep -Eo 'git[[:space:]]+-C[[:space:]]+[^[:space:];&|]+' <<<"$cmd" | awk 'NR==1 {print $3}' | tr -d "\"'")"
    [[ -n $cdir ]] && { [[ $cdir == /* ]] && gdir="$cdir" || gdir="$gdir/$cdir"; }
    own="$(git -C "$gdir" symbolic-ref --short -q HEAD 2>/dev/null || true)"
    [[ $own == job/*--T-* ]] || deny "agents push only their own card branch, from inside its worktree (this directory is not a card worktree)."
    grep -Eq "(^|[[:space:]:])(job/[^[:space:]:]*)" <<<"$cmd" || deny "name the branch explicitly: git push origin $own"
    for ref in $(grep -Eo "job/[^[:space:]:]+" <<<"$cmd"); do
      [[ $ref == "$own" ]] || deny "agents push only their own card branch ($own), not $ref."
    done
  fi
fi

# Card branches change only through the roles that own them (the dev, QA — in their worktree) and dl (gate, integrate).
# Michael never rewrites them by hand: a merge, reset or commit of his in a card or integration worktree makes the next
# gate count it as the dev's, and hides what happened from the record. He records the step with dl and re-dispatches.
# "Not a role" = no subagent id and not a session of the code driver — the main Claude session (Michael, or Claude itself) even when its
# shell has cd'ed into a card worktree.
if [[ -z "$(hk .agent_id)" ]] && ! is_driver_agent && grep -Eq '(^|[^[:alnum:]_-])git[[:space:]]([^;&|]*[[:space:]])?(merge|reset|rebase|commit|cherry-pick|revert|checkout|switch|restore|stash|am|apply|pull|rm|mv|add|tag)([[:space:]]|$)' <<<"$cmd"; then
  wtcwd="$(hkp .cwd)"
  if grep -Eq '\.work/[^[:space:]]*/wt/' <<<"$cmd" || [[ $wtcwd == */.work/JOB-*/wt/* ]]; then
    deny "card and integration worktrees change only through the roles and dl — never by hand. Record what happened (dl qa | dl review | dl card <id> note), then re-dispatch the role that owns the change (dl wt add <card>) or let dl merge (dl integrate)."
  fi
fi

# git stash in a job worktree: the stash list belongs to the whole repo, shared by every worktree — a pop in one card's
# worktree took another card's stash (live job: T-12 and T-64 swapped their uncommitted work). Commit, or ask Michael.
if grep -Eq '(^|[^[:alnum:]_-])git[[:space:]]([^;&|]*[[:space:]])?stash([[:space:]]|$)' <<<"$cmd" \
   && ! grep -Eq 'stash[[:space:]]+(list|show)([[:space:]]|$)' <<<"$cmd" \
   && { grep -Eq '\.work/[^[:space:]]*/wt/' <<<"$cmd" || [[ "$(hkp .cwd)" == */.work/JOB-*/wt/* ]]; }; then
  deny "no git stash in a job worktree: the stash list is shared by every worktree of the repo, and a pop can take another card's work (seen live). Commit your work in progress on your card branch instead."
fi

grep -Eq 'rm[[:space:]]+-[[:alpha:]]*[rR][[:alpha:]]*[[:space:]]+([^;&|]*[[:space:]])?[^[:space:]]*\.work(/|[[:space:]]|$)' <<<"$cmd" \
  && deny ".work/ must not be deleted — job state lives there. Use 'dl cleanup'."

grep -Eq 'git[[:space:]].*worktree[[:space:]]+(remove|prune)[^;&|]*(_integration|\.work)' <<<"$cmd" \
  && deny "job worktrees are managed by dl. Use 'dl cleanup'."

grep -Eq 'git[[:space:]].*branch[[:space:]]+(-[[:alpha:]]*[dD]|--delete)[^;&|]*job/' <<<"$cmd" \
  && deny "job/ branches must not be deleted by agents. Delete them yourself after the job is closed."

# DELIVER_HUMAN_CMD marks the human's own slash commands (/deliver:retry …, run by Claude Code before the model sees them).
grep -q 'DELIVER_HUMAN_CMD' <<<"$cmd" && deny "DELIVER_HUMAN_CMD is set only by the human's /deliver:<command> — ask the human to run it."

# --- dl: who may change the flow's state ------------------------------------------------------------------------
# dl as a word, a path (…/bin/dl) or the variable the playbook uses ("$DL", ${DL})
dl_re='(^|[;&|[:space:](/"'"'"'])(dl|\$\{?DL\}?)"?[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?'
# A BMad session (dl shape run) reports in its answer; the flow's state is not its to touch
if [[ -n ${DELIVER_SHAPING:-} ]]; then
  grep -Eq "${dl_re}[a-z]" <<<"$cmd" && deny "a BMad session does not run dl — end with the JSON your headless contract defines; dl reads it."
  grep -Eq '(^|[^[:alnum:]_-])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?(commit|push|merge|rebase|reset|checkout|switch)([[:space:]]|$)' <<<"$cmd" \
    && deny "a BMad session writes its artifacts only; it does not change the repo's history."
fi
if grep -Eq "${dl_re}(new|quick|phase|jobset|roles|readiness|input|clarify|decide|pm-decide|reopen|learn|followup|knowledge[[:space:]]+promote|wt|card|gate|qa|qa-join|review|integrate|verify-all|stack-test|checkpoint|track|waive|context[[:space:]]+(draft|propose)|ship|approve|reject|cleanup|shape)([[:space:]]|$)" <<<"$cmd"; then
  is_agent && deny "only the orchestrator (Michael) runs state-changing dl commands. Report back in your summary instead."
fi
if grep -Eq "${dl_re}(approve|reject|clarify|input[[:space:]]+defer)([[:space:]]|$)" <<<"$cmd"; then
  [[ ${DELIVER_HEADLESS:-} == 1 ]] && deny "no human is in this session (headless). Write the question down (APPROVAL.md / QUESTIONS.md) and stop; the human answers with /deliver:approve | /deliver:reject | /deliver:answer."
fi
grep -Eq "${dl_re}(unfreeze|reseal|abort|tracker[[:space:]]+switch)([[:space:]]|$)" <<<"$cmd" \
  && deny "frozen decisions, seals, aborting and the tracker are a human's call, with their own slash command (/deliver:unfreeze | /deliver:reseal | /deliver:abort | /deliver:tracker)."
grep -Eq "${dl_re}phase[[:space:]][^;&|]*--force" <<<"$cmd" \
  && deny "'dl phase … --force' bypasses the flow's guards; only a human may run it."
grep -Eq "${dl_re}card[[:space:]]+[^[:space:]]+[[:space:]]+retry" <<<"$cmd" && [[ ${DELIVER_HEADLESS:-} == 1 ]] \
  && deny "granting a blocked card new attempts is a human decision; in headless mode the human runs it."

# --- the flow's state files: written by dl only, once work has started -----------------------------------------
# job.json and board.json are sealed (sha256); a write by any other tool stops the flow until a human reseals. Refuse
# such a write up front, with the command to use instead, so the session corrects itself.
# The shaping ledger (what BMad said and what was decided on it) and BMad's artifacts: dl and BMad only
if grep -Eq 'shaping\.json|/bmad/(out|inputs|runs)/' <<<"$cmd" && grep -Eq '(writeFileSync|>[[:space:]]*[^[:space:]|&;]*(shaping\.json|/bmad/)|sed[[:space:]]+(-[a-zA-Z]*i|--in-place)|tee[[:space:]]|(mv|cp|rm)[[:space:]][^|&;]*(shaping\.json|/bmad/))' <<<"$cmd" && [[ -z ${DELIVER_SHAPING:-} ]]; then
  deny "the shaping ledger and BMad's artifacts are written by dl and by BMad only: dl shape propose | decide | gap, the human's dl clarify."
fi
if grep -Eq '(job|board)\.json' <<<"$cmd" && grep -Eq '(writeFileSync|>[[:space:]]*[^[:space:]|&;]*(job|board)\.json|sed[[:space:]]+(-[a-zA-Z]*i|--in-place)|tee[[:space:]][^|&;]*(job|board)\.json|(mv|cp)[[:space:]][^|&;]*(job|board)\.json[[:space:]]*($|[;&|])|open\([^)]*(job|board)\.json[^)]*["'"'"'][wa])' <<<"$cmd"; then
  if owned="$(owned_job || active_jobs | awk 'NR==1')" && [[ -n $owned ]]; then
    IFS=$'\t' read -r job root <<<"$owned"
    phase="$(jq -r .phase "$root/.work/$job/job.json" 2>/dev/null)"
    grep -Eq '(^|[^[:alnum:]_])job\.json' <<<"$cmd" \
      && deny "job.json is written by dl only (sealed). Use: dl jobset '<jq expr>' (logged) — or ask the human."
    case $phase in intake|shaping|readiness|awaiting_clarification|planning|awaiting_plan_approval) ;;
      *) deny "board.json is written by dl only once work has started (phase $phase; sealed). Change a ready/blocked card with: dl card <id> set <field> <json> \"<reason>\" · add one with: dl card add <card.json> \"<reason>\" · a running card's contract does not change — put extra detail in the dispatch prompt." ;;
    esac
  fi
fi

exit 0
