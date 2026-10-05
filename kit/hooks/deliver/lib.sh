#!/usr/bin/env bash
# Shared by the /deliver hooks. Source it after reading the hook input into $input.
#
# Jobs are found without relying on the session's cwd: Michael may run in the repo, in a Munder Difflin
# hive folder, or anywhere else. Candidates come from $CLAUDE_PROJECT_DIR/.work/ACTIVE, the hook's cwd,
# and the registry `dl new` writes (~/.deliver/jobs/<id> → repo root). A job is "active" when its repo's
# .work/ACTIVE names it.

DELIVER_REG="${DELIVER_HOME:-$HOME/.deliver}/jobs"

hk() { jq -r "$1 // empty" <<<"$input" 2>/dev/null; }
# Windows (Git Bash): Claude Code hands hooks "C:\\Users\\x\\repo", while dl stores roots as Git Bash sees them ("/c/Users/x/repo").
# np turns either form into the latter, so every path comparison below compares like with like. A no-op elsewhere.
np() { local p=${1//\\//}; if [[ $p =~ ^([A-Za-z]):(/.*)?$ ]]; then p="/$(printf '%s' "${BASH_REMATCH[1]}" | tr 'A-Z' 'a-z')${BASH_REMATCH[2]}"; fi; printf '%s' "$p"; }
hkp() { np "$(hk "$1")"; }   # a path field of the hook input, normalised
# canon_path <path> → symlinks resolved in its longest existing directory prefix. macOS links /tmp and /var into /private,
# so one file has two spellings; dl's roots come from git (resolved), a tool call's path may not (fix/floor-robustness).
canon_path() {
  local p=$1 rest=""
  while [[ ! -d $p ]]; do rest="/${p##*/}$rest"; p="${p%/*}"; [[ -n $p ]] || p=/; done
  local base; base="$(cd -P "$p" 2>/dev/null && pwd -P)" || base=$p
  [[ $base == / ]] && base=""
  printf '%s%s\n' "$base" "$rest"
}

# active_jobs → lines "<job id>\t<repo root>"
active_jobs() {
  local roots=() r f id seen=""
  [[ -n ${CLAUDE_PROJECT_DIR:-} ]] && roots+=("$(np "$CLAUDE_PROJECT_DIR")")
  r="$(hkp .cwd)"; [[ -n $r ]] && roots+=("$(np "$(git -C "$r" rev-parse --path-format=absolute --git-common-dir 2>/dev/null | sed 's#/\.git$##')")")
  if [[ -d $DELIVER_REG ]]; then for f in "$DELIVER_REG"/*; do [[ -f $f ]] && roots+=("$(np "$(cat "$f")")"); done; fi
  for r in ${roots[@]+"${roots[@]}"}; do   # bash 3.2 + set -u: an empty array is "unbound"
    [[ -n $r && -f $r/.work/ACTIVE ]] || continue
    id="$(cat "$r/.work/ACTIVE")"
    [[ -f $r/.work/$id/job.json && $seen != *"|$id|"* ]] || continue
    seen+="|$id|"; printf '%s\t%s\n' "$id" "$r"
  done
}

# owns_job <id> → true when this session's transcript mentions the job id (i.e. this session runs the job)
owns_job() {
  local t; t="$(hkp .transcript_path)"
  [[ -n $t && -f $t ]] && grep -qF "$1" "$t"
}

# The session is a card worker when it is a subagent, or a top-level session started inside a card worktree
# (Munder Difflin workers run `claude --agent <dev>` with cwd = the card worktree).
in_card_worktree() { [[ "$(hkp .cwd)" == */.work/JOB-*/wt/T-* ]]; }
# Munder Difflin sets AGENT_ID in every terminal on the floor; Michael's is "god". Every other id is a seat or a worker.
is_floor_seat() { [[ -n ${AGENT_ID:-} && $AGENT_ID != god ]]; }
is_agent() { [[ -n "$(hk .agent_id)" ]] || in_card_worktree || is_floor_seat; }

# owned_job → "<id>\t<root>" of the active job this (orchestrator) session owns, if any
owned_job() {
  local id root
  while IFS=$'\t' read -r id root; do
    owns_job "$id" && { printf '%s\t%s\n' "$id" "$root"; return 0; }
  done < <(active_jobs)
  return 1
}
