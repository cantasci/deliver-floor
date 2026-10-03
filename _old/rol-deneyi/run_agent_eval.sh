#!/usr/bin/env bash
# Experiment B: tools ON, fresh git worktree of /tmp/traccar-mut (branch r3-base) per run.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
RUNS="${RUNS:-3}"; MODEL="${MODEL:-}"; TAG="${MODEL:-default}"
REPO="${REPO:-/tmp/traccar-r3}"; BASE_BRANCH="${BASE_BRANCH:-master}"   # single-commit snapshot: no history to mine
OUT_ROOT="${OUT_ROOT:-$HERE/out-r3-agent}"; OUT="$OUT_ROOT/$TAG"; mkdir -p "$OUT"
CONDS="${CONDS:-agent_no_role agent_role_v2}"
MAX_TURNS="${MAX_TURNS:-80}"
export CHECKS="${CHECKS:-$HERE/checks.json}"
TASK="$(cat "$HERE/task_agent.md")"
ROLE="$(cat "$HERE/role_rules_v2.md"; echo; cat "$HERE/role_examples_v2.md")"
MODEL_ARGS=(); [ -n "$MODEL" ] && MODEL_ARGS=(--model "$MODEL")
ALLOWED=("Read" "Glob" "Grep" "Write" "Edit" "Bash(ls *)" "Bash(grep *)" "Bash(rg *)" "Bash(find *)" "Bash(cat *)" "Bash(head *)" "Bash(tail *)" "Bash(wc *)" "Bash(sed -n *)")
DISALLOWED=("Bash(git *)" "Bash(rm *)" "Bash(curl *)" "Bash(wget *)")

run_one() {  # cond n
    local cond="$1" n="$2" base="$OUT/${cond}_${n}"
    local sys_args=()
    case "$cond" in
        agent_no_role) sys_args=() ;;
        agent_role_v2) sys_args=(--append-system-prompt "$ROLE") ;;
        *) echo "unknown cond $cond" >&2; return 1 ;;
    esac
    local wt; wt="$(mktemp -d)"; rmdir "$wt"
    local br="r3-$TAG-$cond-$n-$RANDOM"
    git -C "$REPO" worktree add -q -b "$br" "$wt" "$BASE_BRANCH" || { echo "worktree failed" >&2; return 1; }
    local t0; t0=$(date +%s)
    ( cd "$wt" && claude -p \
        --output-format stream-json --verbose \
        --permission-mode acceptEdits --permission-prompts none \
        --tools "Read,Glob,Grep,Write,Edit,Bash" \
        --allowedTools "${ALLOWED[@]}" --disallowedTools "${DISALLOWED[@]}" \
        --strict-mcp-config --setting-sources "" \
        --max-turns "$MAX_TURNS" \
        ${MODEL_ARGS[@]+"${MODEL_ARGS[@]}"} \
        ${sys_args[@]+"${sys_args[@]}"} \
        -- "$TASK" < /dev/null ) > "$base.stream.jsonl" 2> "$base.err"
    local t1; t1=$(date +%s)
    ( cd "$wt" && git status --short ) > "$base.gitstatus" 2>/dev/null
    python3 "$HERE/agent_metrics.py" "$wt" "$base.stream.jsonl" --wall $((t1 - t0)) --json "$base.json" --md "$base.md" | tee -a "$OUT/summary.txt"
    git -C "$REPO" worktree remove --force "$wt" && git -C "$REPO" branch -D -q "$br"
    echo "$TAG,$cond,$n,$(python3 -c "import json;d=json.load(open('$base.json'));print(d['score']['score'], d['metrics']['tokens_total'], d['metrics']['tool_calls'], d['metrics']['wall_seconds'], d['metrics']['files_read_distinct'], sep=',')")" >> "$OUT/scores.csv"
}
echo "model=$TAG runs=$RUNS conds=[$CONDS] out=$OUT" >&2
for cond in $CONDS; do for n in $(seq 1 "$RUNS"); do echo "== $cond #$n" >&2; run_one "$cond" "$n"; done; done
echo "done -> $OUT/scores.csv" >&2
