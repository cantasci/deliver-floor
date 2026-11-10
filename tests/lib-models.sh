# Sourced by the live e2e scripts (they define ok/bad/log). Judges which model each role REALLY ran on, from Claude Code's
# own session transcripts (tests/check-models.mjs) — not from what Michael wrote down.
#
#   models_subagents <projects dir> <job.json> <role> <agent type> <model word>
#       subagent mode: the role's model is in job.json, every message of that agent type ran on it, Michael did not,
#       and no other agent type ran on it (only the asked role changed)
_models_dump() { log ""; log "models seen (assistant messages per session, from the transcripts):"; jq -r '"- Michael: \(.michael | to_entries | map("\(.key) ×\(.value)") | join(", "))", (.roles | to_entries[] | "- \(.key): \(.value | to_entries | map("\(.key) ×\(.value)") | join(", "))")' <<<"$1" | tee -a "$REP"; }

models_subagents() {
  local proj=$1 jj=$2 role=$3 at=$4 m=$5 M
  M="$(node "$HERE/tests/check-models.mjs" subagents "$proj")"; echo "$M" > "$W/models.json"; _models_dump "$M"
  jq -e --arg r "$role" --arg m "$m" '[.roles[] | select(.role==$r) | .model // ""] | first // "" | test($m)' "$jj" >/dev/null \
    && ok "Michael put it in the job: role $role → model $(jq -r --arg r "$role" '[.roles[] | select(.role==$r) | .model] | first' "$jj")" \
    || bad "job.json: role $role has model '$(jq -r --arg r "$role" '[.roles[] | select(.role==$r) | .model // ""] | first // ""' "$jj")', expected $m"
  jq -e --arg a "$at" --arg m "$m" '[.roles | to_entries[] | select(.key | test("(^|:)" + $a + "$"))] | length > 0 and all(.value | keys | all(test($m)))' <<<"$M" >/dev/null \
    && ok "every $at message ran on $m ($(jq -r --arg a "$at" '[.roles | to_entries[] | select(.key | test("(^|:)" + $a + "$")) | .value | keys[]] | unique | join(", ")' <<<"$M"))" \
    || bad "$at did not run (only) on $m: $(jq -c --arg a "$at" '[.roles | to_entries[] | select(.key | test("(^|:)" + $a + "$"))]' <<<"$M")"
  jq -e --arg m "$m" '(.michael | length > 0) and (.michael | keys | all(test($m) | not))' <<<"$M" >/dev/null \
    && ok "Michael ran on a different model ($(jq -r '.michael | keys | join(", ")' <<<"$M"))" || bad "Michael's model: $(jq -c .michael <<<"$M")"
  jq -e --arg a "$at" --arg m "$m" '[.roles | to_entries[] | select(.key | test("(^|:)" + $a + "$") | not) | .value | keys[] | select(test($m))] | length == 0' <<<"$M" >/dev/null \
    && ok "no other role ran on $m — only the asked role changed" || bad "other roles also ran on $m"
}
