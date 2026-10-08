#!/usr/bin/env bash
# suite-run.sh — the whole suite (verify_full) on one card commit, in the background, started by `dl qa <card> pass`:
# Michael goes on (review, other cards) while it runs; `dl integrate` merges only on its PASS for that same commit.
# It runs in a checkout of its own (a detached worktree at that commit, set up with worktree_setup, removed afterwards),
# never in the card's worktree: a dev sent back to fix the card works there meanwhile.
#   suite-run.sh <repo root> <checkout path> <commit> <setup command> <command> <base path> <slot dir> <slots> <run id>
#                <timeout s> <git lock dir>
# Writes <base>.log (the output), <base>.result (JSON, written last: a missing result is never a pass).
# Runs at most <slots> suites at once on this machine (default 1): two suites sharing a database, a port or a temp dir
# could break each other, or pass by accident. DELIVER_RUN_ID is unique per run, for a project that isolates by it.
set -u
root=$1 co=$2 commit=$3 setup=$4 cmd=$5 base=$6 slotdir=$7 slots=$8 runid=$9 tmo=${10} gitlock=${11}
child="" slot="" start=""
git_l() { # git under dl's git lock (a worktree add/remove racing dl's own git calls could fail)
  local n=0 rc=0
  until mkdir "$gitlock" 2>/dev/null; do
    if [[ -n "$(find "$gitlock" -maxdepth 0 -mmin +2 2>/dev/null)" ]]; then rmdir "$gitlock" 2>/dev/null; continue; fi
    sleep 0.2; n=$((n + 1)); [[ $n -lt 600 ]] || break
  done
  git "$@" || rc=$?; rmdir "$gitlock" 2>/dev/null; return $rc
}
cleanup() { [[ -d $co ]] && git_l -C "$root" worktree remove --force "$co" >/dev/null 2>&1; [[ -n $slot ]] && rm -rf "$slot"; slot=""; }
finish() { # finish <result> <exit> <note>
  local end; end=$(date +%s)
  cleanup
  printf '{"result":"%s","exit":%s,"seconds":%s,"head":"%s","note":"%s","at":"%s"}\n' "$1" "$2" "$(( end - ${start:-$end} ))" "$commit" "$3" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$base.result.tmp" && mv "$base.result.tmp" "$base.result"
  exit 0
}
stop() { [[ -n $child ]] && { pkill -TERM -P "$child" 2>/dev/null; kill -TERM "$child" 2>/dev/null; }; finish STOPPED 143 "stopped (a newer commit of the card, or the job ended)"; }
trap stop TERM INT
mkdir -p "$slotdir"
waited=0
while [[ -z $slot ]]; do
  i=1
  while [[ $i -le $slots ]]; do
    if mkdir "$slotdir/$i" 2>/dev/null; then slot="$slotdir/$i"; echo $$ > "$slot/pid"; break; fi
    p="$(cat "$slotdir/$i/pid" 2>/dev/null)"   # a slot whose runner is gone is free
    if [[ -n $p ]] && ! kill -0 "$p" 2>/dev/null; then rm -rf "$slotdir/$i"; continue; fi
    i=$((i + 1))
  done
  [[ -n $slot ]] && break
  [[ $waited -eq 0 ]] && echo "# waiting for a free suite slot ($slots at once: suite_parallel)" >> "$base.log"
  sleep 2; waited=$((waited + 2))
done
start=$(date +%s)
rm -rf "$co"
if ! git_l -C "$root" worktree add -q --detach "$co" "$commit" >> "$base.log" 2>&1; then finish FAIL 1 "could not check out ${commit:0:12}"; fi
if [[ -n $setup ]]; then
  echo "# worktree_setup: $setup" >> "$base.log"
  ( cd "$co" && ROOT="$root" bash -c "$setup" ) >> "$base.log" 2>&1 || echo "# worktree_setup failed (the suite runs anyway)" >> "$base.log"
fi
echo "# whole suite (verify_full) on ${commit:0:12}, dev + QA tests together: $cmd" >> "$base.log"
runner=(bash -c "$cmd"); command -v timeout >/dev/null && runner=(timeout "$tmo" bash -c "$cmd")
( cd "$co" && DELIVER_RUN_ID="$runid" exec "${runner[@]}" ) >> "$base.log" 2>&1 &
child=$!
wait "$child"; rc=$?; child=""
if [[ -n "$(git -C "$co" status --porcelain --untracked-files=no 2>/dev/null)" ]]; then
  { echo "verify_full changed tracked files:"; git -C "$co" status --porcelain --untracked-files=no; } >> "$base.log"
  finish FAIL "$rc" "the suite changed tracked files"
fi
[[ $rc -eq 0 ]] && finish PASS 0 "" || finish FAIL "$rc" "exit $rc"
