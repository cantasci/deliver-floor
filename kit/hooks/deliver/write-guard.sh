#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit|NotebookEdit) — isolation, enforced.
# While a job is active in a repo:
#   - agents (subagents, and the role sessions of the code driver) may write inside that repo only in a
#     card worktree (.work/<job>/wt/T-*), the handoffs folder or out/ — never in the main checkout, the integration
#     worktree, or the job's state files;
#   - the orchestrator (the session that owns the job) writes only the job's files under .work/<job>/ —
#     product code is written by dev agents.
# Writes outside the repo (e.g. /tmp) are not this hook's business.
set -uo pipefail
input="$(cat)"
command -v jq >/dev/null || exit 0
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
f="$(hkp .tool_input.file_path)"; [[ -n $f ]] || f="$(hkp .tool_input.notebook_path)"
[[ -n $f ]] || exit 0
[[ $f == /* ]] || f="$(hkp .cwd)/$f"
f="$(canon_path "$f")"
deny() { echo "deliver write-guard: $1" >&2; exit 2; }
# A BMad session (dl shape run, DELIVER_SHAPING=<job>) writes its artifacts in its output folder and its own scripts' state —
# nothing else: not the product, not the job's state, not the ledger it reports to.
if [[ -n ${DELIVER_SHAPING:-} ]]; then
  case $f in */.work/"$DELIVER_SHAPING"/bmad/out/*|*/_bmad/*) exit 0 ;; esac
  deny "a BMad session writes only in its output folder (.work/$DELIVER_SHAPING/bmad/out/) — not $f."
fi

while IFS=$'\t' read -r job root; do
  root="$(canon_path "$root")"
  [[ $f == "$root"/* ]] || continue
  jd="$root/.work/$job"
  if is_agent; then
    case $f in
      "$jd"/wt/_integration/*) deny "nothing is written in the integration worktree; work in your card worktree." ;;
      "$jd"/wt/T-*/*|"$jd"/handoffs/*|"$jd"/out/*) exit 0 ;;
      "$jd"/*) deny "the job's state files (board, plan, job.json) are Michael's. Write only in your worktree, your handoff or .work/<job>/out/." ;;
      *) deny "you may only write inside your card worktree ($jd/wt/<card>/…) and your handoff file — not in the main checkout ($f)." ;;
    esac
  elif owns_job "$job"; then
    phase="$(jq -r .phase "$jd/job.json" 2>/dev/null)"
    case $f in
      "$jd"/wt/*) deny "Michael does not write product code. Dispatch (or re-dispatch) the card to its dev agent." ;;
      "$jd"/job.json) deny "job.json changes only through dl (dl jobset for stack/roles/assumptions/settings) — every change is logged." ;;
      "$jd"/events.log|"$jd"/gates/*) deny "the event log and gate logs are written by dl and the hooks only." ;;
      "$jd"/readiness.json)
        [[ -n "$(jq -r '.frozen.readiness_sha256 // empty' "$jd/job.json" 2>/dev/null)" ]] \
          && deny "readiness.json is frozen (decisions + architecture). Only the human can reopen it: /deliver:unfreeze <reason>."
        exit 0 ;;
      "$jd"/board.json)
        case $phase in intake|shaping|readiness|awaiting_clarification|planning|awaiting_plan_approval) exit 0 ;; esac
        deny "board.json is written by dl once work has started: dl card <id> set <field> <value> \"<reason>\" or dl card add <card.json> \"<reason>\"." ;;
      "$jd"/shaping.json|"$jd"/bmad/*) deny "the shaping ledger and BMad's artifacts are written by dl and by BMad only: dl shape propose | decide | gap, the human's dl clarify." ;;
      "$jd"/*) exit 0 ;;
      "$root"/.work/*) exit 0 ;;
      *) deny "Michael does not write product code while a job runs ($f). Add or re-dispatch a card instead." ;;
    esac
  fi
done < <(active_jobs)
exit 0
