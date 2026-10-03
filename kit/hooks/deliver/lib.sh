#!/usr/bin/env bash
# Shared by the /deliver hooks. Source it after reading the hook input into $input.
#
# Jobs are found without relying on the session's cwd: Michael may run in the repo, in a Munder Difflin
# hive folder, or anywhere else. Candidates come from $CLAUDE_PROJECT_DIR/.work/ACTIVE, the hook's cwd,
# and the registry `dl new` writes (~/.deliver/jobs/<id> → repo root). A job is "active" when its repo's
# .work/ACTIVE names it.

DELIVER_REG="${DELIVER_HOME:-$HOME/.deliver}/jobs"
DEV_AGENTS_RE='^(backend-dev|frontend-dev|mobile-dev)$'

hk() { jq -r "$1 // empty" <<<"$input" 2>/dev/null; }

# active_jobs → lines "<job id>\t<repo root>"
active_jobs() {
  local roots=() r f id seen=""
  [[ -n ${CLAUDE_PROJECT_DIR:-} ]] && roots+=("$CLAUDE_PROJECT_DIR")
  r="$(hk .cwd)"; [[ -n $r ]] && roots+=("$(git -C "$r" rev-parse --path-format=absolute --git-common-dir 2>/dev/null | sed 's#/\.git$##')")
  if [[ -d $DELIVER_REG ]]; then for f in "$DELIVER_REG"/*; do [[ -f $f ]] && roots+=("$(cat "$f")"); done; fi
  for r in "${roots[@]}"; do
    [[ -n $r && -f $r/.work/ACTIVE ]] || continue
    id="$(cat "$r/.work/ACTIVE")"
    [[ -f $r/.work/$id/job.json && $seen != *"|$id|"* ]] || continue
    seen+="|$id|"; printf '%s\t%s\n' "$id" "$r"
  done
}

# owns_job <id> → true when this session's transcript mentions the job id (i.e. this session runs the job)
owns_job() {
  local t; t="$(hk .transcript_path)"
  [[ -n $t && -f $t ]] && grep -qF "$1" "$t"
}

# The session is a card worker when it is a subagent, or a top-level session started inside a card worktree
# (Munder Difflin workers run `claude --agent <dev>` with cwd = the card worktree).
in_card_worktree() { [[ "$(hk .cwd)" == */.work/JOB-*/wt/T-* ]]; }
is_agent() { [[ -n "$(hk .agent_id)" ]] || in_card_worktree; }

# owned_job → "<id>\t<root>" of the active job this (orchestrator) session owns, if any
owned_job() {
  local id root
  while IFS=$'\t' read -r id root; do
    owns_job "$id" && { printf '%s\t%s\n' "$id" "$root"; return 0; }
  done < <(active_jobs)
  return 1
}
