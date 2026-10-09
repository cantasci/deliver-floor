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

# Michael waits with dl md-wait, never a loop of his own: run 53 polled with 10-second sleeps and a hand-written wait.sh.
if [[ ${AGENT_ID:-} == god ]] && grep -q 'god/inbox' <<<"$cmd" && grep -Eq '(^|[^[:alnum:]_-])(sleep|watch|inotifywait)([[:space:]]|$)' <<<"$cmd"; then
  deny "wait for your inbox with \"\$DL\" md-wait — it returns within a second of a message and shows it (md-inbox)."
fi

# --- everyone: no search of the whole disk ---------------------------------------------------------------------
# Run 53: Michael ran find / for a seat's answer file; it hit the 2-minute Bash timeout. The job's files are named.
if grep -Eq '(^|[^[:alnum:]_-])find([[:space:]]+-[HLP])*[[:space:]]+["'"'"']?/\*?["'"'"']?([[:space:]]|;|\||&|$)' <<<"$cmd"; then
  deny "searching the whole disk is refused — it outlasts the command timeout. The job's files are under <repo>/.work/<job>/ (dl status prints it); a seat's answer is the file its work order named, and dl md-done prints it."
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
# "Not a role" = no subagent id and not a floor seat — the main Claude session (Michael, or Claude itself) even when its
# shell has cd'ed into a card worktree.
if [[ -z "$(hk .agent_id)" ]] && ! is_floor_seat && grep -Eq '(^|[^[:alnum:]_-])git[[:space:]]([^;&|]*[[:space:]])?(merge|reset|rebase|commit|cherry-pick|revert|checkout|switch|restore|stash|am|apply|pull|rm|mv|add|tag)([[:space:]]|$)' <<<"$cmd"; then
  wtcwd="$(hkp .cwd)"
  if grep -Eq '\.work/[^[:space:]]*/wt/' <<<"$cmd" || [[ $wtcwd == */.work/JOB-*/wt/* ]]; then
    deny "card and integration worktrees change only through the roles and dl — never by hand. Record what happened (dl qa | dl review | dl card <id> note), then re-dispatch the role that owns the change (dl wt add <card>) or let dl merge (dl integrate)."
  fi
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
if grep -Eq "${dl_re}(new|phase|jobset|roles|readiness|clarify|decide|pm-decide|reopen|learn|followup|knowledge[[:space:]]+promote|wt|card|gate|qa|qa-join|review|integrate|verify-all|stack-test|ship|approve|reject|md-dispatch|md-hire|md-reseat|md-send|md-done|md-release|md-inbox|md-wait|cleanup)([[:space:]]|$)" <<<"$cmd"; then
  is_agent && deny "only the orchestrator (Michael) runs state-changing dl commands. Report back in your summary instead."
fi
if grep -Eq "${dl_re}(approve|reject|clarify)([[:space:]]|$)" <<<"$cmd"; then
  [[ ${DELIVER_HEADLESS:-} == 1 ]] && deny "no human is in this session (headless). Write the question down (APPROVAL.md / QUESTIONS.md) and stop; the human answers with /deliver:approve | /deliver:reject | /deliver:answer."
fi
grep -Eq "${dl_re}(unfreeze|reseal|dispatch|abort|tracker[[:space:]]+switch)([[:space:]]|$)" <<<"$cmd" \
  && deny "frozen decisions, seals, the dispatch mode and the tracker are a human's call, with their own slash command (/deliver:unfreeze | /deliver:reseal | /deliver:mode | /deliver:abort | /deliver:tracker)."
grep -Eq "${dl_re}phase[[:space:]][^;&|]*--force" <<<"$cmd" \
  && deny "'dl phase … --force' bypasses the flow's guards; only a human may run it."
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
