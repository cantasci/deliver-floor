#!/usr/bin/env bash
# Runs the role experiment: 3 conditions x RUNS repeats via `claude -p`.
# Isolation: each call runs from an empty mktemp dir with ALL tools disabled
# (--tools "" ; --strict-mcp-config ; --setting-sources "" so no user/project
# hooks, CLAUDE.md or MCP servers leak in).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
RUNS="${RUNS:-3}"
MODEL="${MODEL:-}"
MAX_RETRY="${MAX_RETRY:-5}"
TAG="${MODEL:-default}"
OUT_ROOT="${OUT_ROOT:-$HERE/out}"
OUT="$OUT_ROOT/$TAG"
mkdir -p "$OUT"
TASK_FILE="${TASK_FILE:-$HERE/task.md}"
RULES_FILE="${RULES_FILE:-$HERE/role_rules.md}"
EXAMPLE_FILE="${EXAMPLE_FILE:-$HERE/role_example.md}"
export CHECKS="${CHECKS:-$HERE/checks.json}"       # read by scorer.py
CONDS="${CONDS:-no_role rules rules_example}"

# The CLI still presents itself as an agent; with --tools "" the model tends to
# emit fake tool-call text and stop. Identical no-tool preamble in ALL conditions.
NO_TOOLS_PREFIX="Hiçbir aracı kullanma, sadece cevap ver. Do not use or call any tools; answer directly and completely in this single message."
TASK="$NO_TOOLS_PREFIX

$(cat "$TASK_FILE")"
RULES="$(cat "$RULES_FILE")"
EXAMPLE="$(cat "$EXAMPLE_FILE")"
RULES_EX="$(cat "$RULES_FILE"; echo; cat "$EXAMPLE_FILE")"

MODEL_ARGS=()
[ -n "$MODEL" ] && MODEL_ARGS=(--model "$MODEL")

run_one() {  # cond n
    local cond="$1" n="$2" attempt=0 ok=0
    local base="$OUT/${cond}_${n}"
    local sys_args=()
    case "$cond" in
        no_role)                          sys_args=() ;;
        rules|rules_v2|rules_v2_nomiss)   sys_args=(--append-system-prompt "$RULES") ;;
        example_only|examples_v2)         sys_args=(--append-system-prompt "$EXAMPLE") ;;
        rules_example|rules_examples_v2)  sys_args=(--append-system-prompt "$RULES_EX") ;;
        *) echo "unknown condition $cond" >&2; return 1 ;;
    esac
    while [ $attempt -lt "$MAX_RETRY" ]; do
        attempt=$((attempt+1))
        local tmp; tmp="$(mktemp -d)"
        ( cd "$tmp" && claude -p \
            --tools "" \
            --strict-mcp-config \
            --setting-sources "" \
            --permission-prompts none \
            --output-format text \
            ${MODEL_ARGS[@]+"${MODEL_ARGS[@]}"} \
            ${sys_args[@]+"${sys_args[@]}"} \
            -- "$TASK" ) > "$base.md" 2> "$base.err"
        rmdir "$tmp" 2>/dev/null || rm -r "$tmp"
        python3 "$HERE/scorer.py" "$base.md" --json-out "$base.json" > /dev/null
        if python3 -c "import json,sys; sys.exit(1 if json.load(open('$base.json')).get('incomplete') else 0)"; then
            ok=1; break
        fi
        echo "  [$cond #$n] incomplete output, retry $attempt/$MAX_RETRY" >&2
        cp "$base.md" "$base.incomplete$attempt.md"
    done
    local sc; sc="$(python3 -c "import json;d=json.load(open('$base.json'));print(d['score'])")"
    echo "$TAG,$cond,$n,$sc,$([ $ok = 1 ] && echo complete || echo INCOMPLETE)" | tee -a "$OUT/scores.csv"
}

touch "$OUT/scores.csv"   # append; do not truncate when chaining condition sets
echo "model=$TAG runs=$RUNS out=$OUT conds=[$CONDS] task=$TASK_FILE checks=$CHECKS" >&2
for cond in $CONDS; do
    for n in $(seq 1 "$RUNS"); do
        run_one "$cond" "$n"
    done
done
echo "done -> $OUT/scores.csv" >&2
