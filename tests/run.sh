#!/usr/bin/env bash
# End-to-end test of the deterministic half of /deliver: dl, validate, scope, hooks, install/uninstall.
# No model and no network needed — dev agents are simulated with git commits.
#   tests/run.sh            → exit 0 when everything passes
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/deliver-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" DELIVER_HOME="$TMP/home/.deliver"; mkdir -p "$HOME"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
unset DELIVER_HEADLESS DELIVER_JOB DELIVER_REPO HIVE_ROOT CLAUDE_PROJECT_DIR

pass=0 failn=0
ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; pass=$((pass+1)); }
bad()  { printf '  \033[31m✘\033[0m %s\n' "$1"; failn=$((failn+1)); }
expect_ok()   { local d=$1; shift; if out="$("$@" 2>&1)"; then ok "$d"; else bad "$d — $out"; fi; }
expect_fail() { local code=$1 d=$2; shift 2; out="$("$@" 2>&1)"; local rc=$?
  if [[ $rc -ne 0 && ( $code == any || $rc -eq $code ) ]]; then ok "$d"; else bad "$d (rc=$rc, want ${code}) — $out"; fi; }
contains() { [[ $2 == *"$3"* ]] && ok "$1" || bad "$1 — got: $2"; }

DL="$HERE/kit/skills/deliver/bin/dl"
ready_all() { # ready_all [<id> open] — the BA's readiness review: every applicable item decided (one left open if asked)
  local jd; jd="$(dirname "$(dirname "$(git rev-parse --git-common-dir)")")/.work/$(cat .work/ACTIVE)"
  [[ -d $jd ]] || jd="$PWD/.work/$(cat .work/ACTIVE)"
  node "$HERE/kit/skills/deliver/bin/readiness.mjs" applicable "$jd" | jq --arg o "${1:-}" --argjson arch "${ARCH:-null}" '{items: [.[] | if .id == $o
     then {id, status:"open", question:("Which option for " + .id + "?"), options:["a","b"]}
     else {id, status:"decided", answer:"test decision", source:"test fixture"} end],
     architecture: ($arch // {style:"library", components:[{id:"app", kind:"library", stack:["generic"], path:".", owner:"backend", reviewer:"reviewer"}]})}' > "$jd/readiness.json"
}
SDIR="$HERE/kit/skills/deliver"

echo "scope matcher"
m() { printf '%s\n' "$2" | node "$SDIR/bin/scope.mjs" "$1"; }
[[ -z "$(m '["src/a/**"]' src/a/b/c.ts)" ]] && ok "** spans directories" || bad "** spans directories"
[[ -n "$(m '["src/*.ts"]' src/a/b.ts)" ]] && ok "* stays in one segment" || bad "* stays in one segment"
[[ -z "$(m '["src/{a,b}/**"]' src/b/x.ts)" ]] && ok "{a,b} alternatives" || bad "{a,b} alternatives"
[[ -z "$(m '["test/**/*.test.ts"]' test/x.test.ts)" ]] && ok "**/ matches zero directories" || bad "**/ zero dirs"

echo "repo + job"
R="$TMP/repo"; mkdir -p "$R"; cd "$R"
git init -q -b main
cat > package.json <<'EOF'
{ "name": "demo", "private": true, "scripts": { "test": "node --test" } }
EOF
printf 'node_modules/\n' > .gitignore
mkdir -p src test secret
echo 'export const add = (a, b) => a + b;' > src/math.mjs
echo 'top secret' > secret/keep.txt
git add -A && git commit -qm init
cat > .deliver.json <<'EOF'
{ "verify_full": "node --test", "worktree_setup": "mkdir -p \"$ROOT/node_modules\" && ln -s \"$ROOT/node_modules\" node_modules", "merge_mode": "local", "max_parallel": 2, "gates": { "plan": true } }
EOF
git add .deliver.json && git commit -qm cfg

JOB="$("$DL" new "Sipariş iptali" "Users can cancel orders")"
contains "dl new returns id with ascii slug" "$JOB" "-siparis-iptali"
[[ -f $R/.work/$JOB/job.json && -d $R/.work/$JOB/wt/_integration ]] && ok "job dir + integration worktree" || bad "job dir"
[[ "$(cat "$DELIVER_HOME/jobs/$JOB")" == "$R" ]] && ok "job registered for the hooks" || bad "registry"
grep -qx node_modules "$R/.git/info/exclude" && ok "node_modules (no slash) excluded" || bad "exclude"
expect_fail 1 "second dl new refused while a job is active" "$DL" new "other" "x"
expect_ok "dl -C works from outside the repo" bash -c "cd '$TMP' && '$DL' -C '$R' status"

echo "planning guards"
expect_fail 1 "planning refused while roles are incomplete" "$DL" phase planning
"$DL" jobset '.roles=[{"role":"backend","agent":"backend-dev"}]'
out="$("$DL" phase planning 2>&1)"; contains "roles check names the missing always-on roles" "$out" "role 'qa' is always selected"
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst","why":"always"},{"role":"backend-lead","agent":"ecc:architect","why":"api"},
  {"role":"backend","agent":"backend-dev","why":"lead"},{"role":"qa","agent":"qa-tester","why":"always"},
  {"role":"reviewer","agent":"ecc:typescript-reviewer","why":"stack"}]'
expect_fail 1 "planning refused before the readiness review" "$DL" phase planning
expect_ok "phase readiness with valid roles" "$DL" phase readiness
RJ="$R/.work/$JOB"
expect_fail 1 "readiness check fails without readiness.json" "$DL" readiness
node "$HERE/kit/skills/deliver/bin/readiness.mjs" applicable "$RJ" > "$TMP/appl.json"
jq -e 'map(.id) | (index("ARC-style") and index("ARC-layer") and index("NFR-privacy") and index("CON-interface") and (index("MOB-stack")|not))' "$TMP/appl.json" >/dev/null \
  && ok "applicable items follow the roles (backend: ARC-layer; no mobile items)" || bad "applicable: $(jq -c 'map(.id)' "$TMP/appl.json")"
jq '{items: ([.[] | {id, status:"decided", answer:"x", source:"y"}] | .[0].source = null | del(.[1]))}' "$TMP/appl.json" > "$RJ/readiness.json"
out="$("$DL" readiness 2>&1)"; contains "a missing item and a decision without source are errors" "$out" "is not answered"
contains "…both reported" "$out" "decided needs an answer and its source"
contains "a missing architecture is an error" "$out" "architecture: architecture is missing"
ready_all CON-interface
out="$("$DL" readiness 2>&1)"; contains "an open item is reported as a question" "$out" "OPEN  CON-interface"
grep -q "## CON-interface" "$RJ/QUESTIONS.md" && ok "QUESTIONS.md lists the open question" || bad "QUESTIONS.md"
expect_fail 1 "planning refused while a question is open" "$DL" phase planning
contains "next asks the human the open question" "$("$DL" next)" "ASK     human: CON-interface"
expect_ok "awaiting_clarification" "$DL" phase awaiting_clarification
contains "agents cannot answer readiness questions" "$(printf '%s' '{"tool_input":{"command":"dl clarify CON-interface x"},"agent_id":"a1","cwd":"/"}' | "$HERE/kit/hooks/deliver/bash-guard.sh" 2>&1; echo "rc=$?")" "rc=2"
contains "headless sessions cannot answer them either" "$(printf '%s' '{"tool_input":{"command":"dl clarify CON-interface x"},"cwd":"/"}' | DELIVER_HEADLESS=1 "$HERE/kit/hooks/deliver/bash-guard.sh" 2>&1; echo "rc=$?")" "rc=2"
expect_ok "the human's answer is recorded" "$DL" clarify CON-interface "signed integers; negative = upgrade"
jq -e '.items[] | select(.id=="CON-interface") | .status=="decided" and (.source|startswith("human:")) and (.history|length==1)' "$RJ/readiness.json" >/dev/null \
  && ok "answer stored with source human + history of the question" || bad "clarify record"
grep -q "signed integers" "$RJ/readiness.md" && ok "readiness.md carries the decision" || bad "readiness.md"
expect_ok "phase planning once nothing is open" "$DL" phase planning
jq -e '.frozen.readiness_sha256 | length == 64' "$R/.work/$JOB/job.json" >/dev/null && ok "planning froze readiness.json (sha256 in job.json)" || bad "freeze"
[[ -f $R/.work/$JOB/roles/backend.md && -f $R/.work/$JOB/roles/qa.md && -f $R/.work/$JOB/ROLES.md ]] && ok "role cards generated on planning" || bad "role cards"
grep -q "TDD" "$R/.work/$JOB/roles/backend.md" && grep -q "integration and/or end-to-end tests" "$R/.work/$JOB/roles/qa.md" \
  && grep -q "node --test" "$R/.work/$JOB/roles/backend.md" && ok "role cards carry kind rules + project facts" || bad "role card content"
cat > "$R/.work/$JOB/plan.md" <<'EOF'
# Plan
## Goal
x
## Acceptance criteria
- AC-1: add works
- AC-2: sub works
EOF
expect_fail 1 "empty board is invalid" "$DL" validate
expect_fail 1 "executing refused without approval" "$DL" phase executing
card() { # card <id> <deps json> <scope json> <verify> <ac> — QA tests go to test/integration/<id>/
  jq -n --arg id "$1" --argjson d "$2" --argjson s "$3" --arg v "$4" --arg ac "$5" \
    '{id:$id,title:("card "+$id),role:"backend",agent:"backend-dev",state:"ready",depends_on:$d,scope:$s,
      acceptance:[$ac],verify:$v,context:"ctx",attempts:0,notes:[],component:"app",
      qa_scope:["test/integration/\($id)/**"],qa_verify:"node --test test/integration/\($id)/*.test.mjs"}'
}
qa_tests() { # qa_tests <worktree> <card> [fail] — the "QA role": commit an integration test in qa_scope
  mkdir -p "$1/test/integration/$2"
  if [[ ${3:-} == fail ]]; then printf 'import {test} from "node:test"; import assert from "node:assert"; test("AC: integration", () => assert.equal(1, 2));\n' > "$1/test/integration/$2/int.test.mjs"
  else printf 'import {test} from "node:test"; test("AC: integration", () => {});\n' > "$1/test/integration/$2/int.test.mjs"; fi
  git -C "$1" add -A && git -C "$1" commit -qm "$2 QA: integration tests"
}
B="$R/.work/$JOB/board.json"
jq -n --argjson a "$(card T-01 '[]' '["src/add/**","test/add/**"]' 'node --test test/add/*.test.mjs' 'AC-1: add')" \
      --argjson b "$(card T-02 '[]' '["src/sub/**","test/sub/**"]' 'node --test test/sub/*.test.mjs' 'AC-2: sub')" \
      --argjson c "$(card T-03 '["T-01","T-02"]' '["src/index.mjs","test/index.test.mjs"]' 'node --test test/index.test.mjs' 'AC-1 AC-2 index')" \
      '{cards:[$a,$b,$c]}' > "$B"
expect_fail 1 "cards without BA specs are rejected" "$DL" validate
spec() { printf '# %s\n## Acceptance criteria\n1. Given x, when y, then z\n' "$1" > "$R/.work/$JOB/specs/$1.md"; }
spec T-01; spec T-02; echo "# T-03 no criteria" > "$R/.work/$JOB/specs/T-03.md"
expect_fail 1 "a spec without Given/When/Then is rejected" "$DL" validate
spec T-03
expect_ok "valid board passes" "$DL" validate
jq '.cards[0].agent="frontend-dev"' "$B" > "$B.t" && mv "$B.t" "$B"
expect_fail 1 "agent outside selected roles rejected" "$DL" validate
jq '.cards[0].agent="backend-dev" | .cards[0].acceptance=["AC-9: x"]' "$B" > "$B.t" && mv "$B.t" "$B"
expect_fail 1 "unknown AC reference rejected" "$DL" validate
jq '.cards[0].acceptance=["AC-1: add"] | .cards[0].verify="true"' "$B" > "$B.t" && mv "$B.t" "$B"
expect_fail 1 "no-op verify rejected" "$DL" validate
jq '.cards[0].verify="node --test test/add/*.test.mjs" | .cards[1].scope=["src/add/**"]' "$B" > "$B.t" && mv "$B.t" "$B"
out="$("$DL" validate 2>&1)"; contains "parallel scope overlap warned" "$out" "WARN  T-01 and T-02"
jq '.cards[1].scope=["src/sub/**","test/sub/**"] | .cards[1].scope += ["../x"]' "$B" > "$B.t" && mv "$B.t" "$B"
expect_fail 1 "scope escaping repo rejected" "$DL" validate
jq '.cards[1].scope=["src/sub/**","test/sub/**"] | .cards[0].depends_on=["T-03"]' "$B" > "$B.t" && mv "$B.t" "$B"
expect_fail 1 "dependency cycle rejected" "$DL" validate
jq '.cards[0].depends_on=[]' "$B" > "$B.t" && mv "$B.t" "$B"

expect_fail 1 "approve refused outside the waiting phase" "$DL" approve plan
expect_ok "awaiting_plan_approval" "$DL" phase awaiting_plan_approval
contains "next asks the human" "$("$DL" next)" "ASK     human: plan approval"
expect_fail 1 "reject needs a note" "$DL" reject plan
"$DL" reject plan "split T-03" >/dev/null
contains "next shows the revision" "$("$DL" next)" "REVISE"
expect_fail 1 "executing refused after rejection" "$DL" phase executing
"$DL" phase awaiting_plan_approval >/dev/null
[[ "$(jq -r .gates.plan "$R/.work/$JOB/job.json")" == null ]] && ok "re-entering the gate clears the old answer" || bad "gate reset"
"$DL" approve plan "ok" >/dev/null
expect_ok "executing after approval" "$DL" phase executing

echo "execution guards"
contains "next dispatches independent cards" "$("$DL" next)" "DISPATCH T-01 T-02"
expect_fail 1 "card with unmerged deps refused" "$DL" wt add T-03
expect_fail 1 "card state merged refused" "$DL" card T-01 state merged
expect_fail 1 "card state running refused" "$DL" card T-01 state running
W1="$("$DL" wt add T-01)"; W2="$("$DL" wt add T-02)"
[[ -L $W1/node_modules ]] && ok "worktree_setup ran (node_modules symlink)" || bad "worktree_setup"
jq '.cards[2].depends_on=[]' "$B" > "$B.t" && mv "$B.t" "$B"
expect_fail 5 "max_parallel enforced" "$DL" wt add T-03
jq '.cards[2].depends_on=["T-01","T-02"]' "$B" > "$B.t" && mv "$B.t" "$B"

# --- simulated dev T-01: good work
mkdir -p "$W1/src/add" "$W1/test/add"
echo 'export const add = (a, b) => a + b;' > "$W1/src/add/add.mjs"
printf 'import {test} from "node:test"; import assert from "node:assert"; import {add} from "../../src/add/add.mjs";\ntest("add", () => assert.equal(add(1,2), 3));\n' > "$W1/test/add/add.test.mjs"
git -C "$W1" add -A && git -C "$W1" commit -qm "T-01: add"
[[ -z "$(git -C "$W1" ls-files node_modules)" ]] && ok "git add -A does not commit the node_modules symlink" || bad "symlink committed"
expect_fail 1 "integrate refused before gate" "$DL" integrate T-01
expect_ok "gate T-01 passes" "$DL" gate T-01
[[ "$(jq -r '.cards[0].state' "$B")" == review ]] && ok "gate moves running → review" || bad "state after gate"
expect_fail 1 "integrate refused before review" "$DL" integrate T-01
contains "next asks for QA after the gate" "$("$DL" next)" "QA      T-01"
expect_fail 1 "review refused before QA" "$DL" review T-01 approve "lgtm"
expect_fail 1 "qa needs a summary" "$DL" qa T-01 pass
expect_fail 1 "QA without integration tests is refused" "$DL" qa T-01 pass "x"
echo 'export const hacked = 1;' >> "$W1/src/add/add.mjs"; git -C "$W1" commit -qam "QA touches code"
expect_fail 1 "QA that changes product code is refused" "$DL" qa T-01 pass "x"
git -C "$W1" reset -q --hard HEAD~1
# QA writes an integration test for an AC the dev missed (addChecked) → it fails
mkdir -p "$W1/test/integration/T-01"
printf 'import {test} from "node:test"; import assert from "node:assert"; import * as m from "../../../src/add/add.mjs";\ntest("AC-1: addChecked rejects non-numbers", () => { assert.equal(typeof m.addChecked, "function"); assert.throws(() => m.addChecked("a", 1), TypeError); });\n' > "$W1/test/integration/T-01/int.test.mjs"
git -C "$W1" add -A && git -C "$W1" commit -qm "T-01 QA: integration tests"
expect_fail 1 "QA 'pass' with failing QA tests is refused (dl runs qa_verify)" "$DL" qa T-01 pass "AC-1 pass"
"$DL" qa T-01 fail "AC-1: addChecked missing" >/dev/null
contains "QA failure re-dispatches the dev" "$("$DL" next)" "REDISPATCH T-01  (QA failed"
"$DL" wt add T-01 >/dev/null
echo '// weakened' >> "$W1/test/integration/T-01/int.test.mjs"; git -C "$W1" commit -qam "dev edits the QA test"
out="$("$DL" gate T-01 2>&1)"; contains "gate fails when the dev edits a QA test" "$out" "the dev changed a QA test"
git -C "$W1" reset -q --hard HEAD~1
git -C "$W1" rm -q test/integration/T-01/int.test.mjs; git -C "$W1" commit -qm "dev deletes the QA test"
out="$("$DL" gate T-01 2>&1)"; contains "gate fails when the dev deletes a QA test" "$out" "the dev changed a QA test"
git -C "$W1" reset -q --hard HEAD~1
printf 'export const add = (a, b) => a + b;\n' > "$W1/src/add/add.mjs"; git -C "$W1" commit -qam "T-01: no real fix"
out="$("$DL" gate T-01 2>&1)"; contains "gate runs the QA tests after a QA round" "$out" "FAIL  verify failed: QA tests"
printf 'export const add = (a, b) => a + b;\nexport const addChecked = (a, b) => { if (typeof a !== "number" || typeof b !== "number") throw new TypeError("numbers only"); return a + b; };\n' > "$W1/src/add/add.mjs"
git -C "$W1" commit -qam "T-01: addChecked"
expect_ok "gate passes once the dev's fix satisfies the QA tests" "$DL" gate T-01
expect_ok "QA pass recorded (qa_verify green)" "$DL" qa T-01 pass "AC-1 pass: test/integration/T-01 green"
contains "next asks for the review after QA" "$("$DL" next)" "REVIEW  T-01"
"$DL" review T-01 approve "lgtm" >/dev/null
expect_ok "integrate T-01" "$DL" integrate T-01

# --- simulated dev T-02: moves a file out of scope via rename, then fixes it
git -C "$W2" mv secret/keep.txt src/sub/keep.txt 2>/dev/null || { mkdir -p "$W2/src/sub"; git -C "$W2" mv secret/keep.txt src/sub/keep.txt; }
mkdir -p "$W2/test/sub"
printf 'import {test} from "node:test"; test("sub", () => {});\n' > "$W2/test/sub/sub.test.mjs"
git -C "$W2" add -A && git -C "$W2" commit -qm "T-02: sub"
out="$("$DL" gate T-02 2>&1)"; contains "rename out of scope is caught" "$out" "out-of-scope file: secret/keep.txt"
contains "next re-dispatches a failed gate" "$("$DL" next)" "REDISPATCH T-02"
expect_fail 1 "review refused on a failed gate" "$DL" review T-02 approve "x"
"$DL" wt add T-02 >/dev/null
git -C "$W2" mv src/sub/keep.txt secret/keep.txt && echo 'export const sub = (a, b) => a - b;' > "$W2/src/sub/sub.mjs"
echo junk > "$W2/untracked.txt"
out="$("$DL" gate T-02 2>&1)"; contains "untracked file fails the gate" "$out" "uncommitted or untracked"
rm "$W2/untracked.txt"; git -C "$W2" add -A && git -C "$W2" commit -qm "T-02: fix"
expect_ok "gate T-02 passes on attempt 2" "$DL" gate T-02
qa_tests "$W2" T-02; "$DL" qa T-02 pass "AC-2 pass" >/dev/null
"$DL" review T-02 changes "needs a negative test" >/dev/null
contains "last attempt with changes → BLOCK" "$("$DL" next)" "BLOCK   T-02"
expect_fail 4 "max_attempts enforced" "$DL" wt add T-02
"$DL" card T-02 state blocked >/dev/null; "$DL" card T-02 note "reviewer wants negative test" >/dev/null
contains "blocked card asks the human" "$("$DL" next)" "ASK     human about blocked T-02"
"$DL" card T-02 retry >/dev/null
"$DL" wt add T-02 >/dev/null
printf 'import {test} from "node:test"; test("sub", () => {}); test("neg", () => {});\n' > "$W2/test/sub/sub.test.mjs"
git -C "$W2" commit -qam "T-02: negative test"
"$DL" gate T-02 >/dev/null && "$DL" qa T-02 pass "AC-2 pass (re-run)" >/dev/null && "$DL" review T-02 approve "ok" >/dev/null
expect_ok "integrate T-02 after human retry" "$DL" integrate T-02

# --- T-03 conflicts with a file changed on the job branch after it was branched
W3="$("$DL" wt add T-03)"
echo 'export * from "./add/add.mjs";' > "$W3/src/index.mjs"
printf 'import {test} from "node:test"; test("index", () => {});\n' > "$W3/test/index.test.mjs"
git -C "$W3" add -A && git -C "$W3" commit -qm "T-03: index"
IWT="$R/.work/$JOB/wt/_integration"
echo 'export const v = 1;' > "$IWT/src/index.mjs"; git -C "$IWT" add -A; git -C "$IWT" commit -qm "hotfix on job branch"
"$DL" gate T-03 >/dev/null && qa_tests "$W3" T-03 && "$DL" qa T-03 pass "ok" >/dev/null && "$DL" review T-03 approve "ok" >/dev/null
expect_fail 3 "merge conflict → exit 3" "$DL" integrate T-03
[[ -z "$(git -C "$IWT" status --porcelain)" ]] && ok "conflicted merge aborted cleanly" || bad "IWT dirty after conflict"
"$DL" wt add T-03 >/dev/null
git -C "$W3" merge -q "job/$JOB" 2>/dev/null; echo 'export * from "./add/add.mjs"; export const v = 1;' > "$W3/src/index.mjs"
git -C "$W3" add -A && git -C "$W3" commit -qm "T-03: resolve"
expect_fail 1 "integrate refused: QA/review were for the old commit" "$DL" integrate T-03
"$DL" gate T-03 >/dev/null && "$DL" qa T-03 pass "ok" >/dev/null && "$DL" review T-03 approve "ok" >/dev/null
expect_ok "integrate T-03 after resolving" "$DL" integrate T-03

echo "integration + delivery (merge_mode=local)"
contains "next moves to integrating" "$("$DL" next)" "PHASE   dl phase integrating"
expect_ok "phase integrating" "$DL" phase integrating
expect_fail 1 "closing refused before verify-all" "$DL" phase closing
expect_ok "verify-all passes" "$DL" verify-all
expect_ok "closing" "$DL" phase closing
expect_fail 1 "approve merge no longer exists" "$DL" approve merge
expect_fail 1 "ship refused while report.md is the template" "$DL" ship
contains "next asks for the report" "$("$DL" next)" "REPORT"
echo "# Delivery report — all ACs met" > "$R/.work/$JOB/report.md"
expect_fail 1 "done refused before shipping" "$DL" phase done
expect_ok "ship (local) merges into the base" "$DL" ship
[[ -f $R/src/add/add.mjs && -f $R/src/sub/sub.mjs && "$(jq -r .phase "$R/.work/$JOB/job.json")" == done ]] && ok "local merge delivered the cards, phase done" || bad "local ship"

echo "hooks"
H="$HERE/kit/hooks/deliver"
hook() { local h=$1 json=$2; out="$(printf '%s' "$json" | "$H/$h" 2>&1)"; echo "rc=$? $out"; }
TR="$TMP/transcript.jsonl"; echo "{\"x\":\"$JOB\"}" > "$TR"
"$DL" jobset '.phase="executing"'
jq '.cards[2].state="ready" | .cards[2].attempts=0' "$B" > "$B.t" && mv "$B.t" "$B"
contains "stop-guard blocks the owner with open cards" "$(hook stop-guard.sh "{\"cwd\":\"$TMP\",\"transcript_path\":\"$TR\"}")" "rc=2"
contains "stop-guard ignores other sessions" "$(hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"/dev/null\"}")" "rc=0"
contains "stop-guard ignores card worktree sessions" "$(hook stop-guard.sh "{\"cwd\":\"$R/.work/$JOB/wt/T-03\",\"transcript_path\":\"$TR\"}")" "rc=0"
for i in 1 2 3 4 5; do hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\"}" >/dev/null; done
contains "stop-guard gives up after stop_guard_max" "$(hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\"}")" "rc=0"
"$DL" jobset '.settings.dispatch="munder"'; rm -f "$R/.work/$JOB/.stop-blocks"
jq '.cards[2].state="running"' "$B" > "$B.t" && mv "$B.t" "$B"
contains "stop-guard lets Michael wait for floor workers (munder)" "$(hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\"}")" "rc=0"
"$DL" jobset '.settings.dispatch="subagent"'

bg() { hook bash-guard.sh "$(jq -n --arg c "$1" --arg cwd "${2:-$R}" --arg a "${3:-}" '{tool_input:{command:$c},cwd:$cwd} + (if $a!="" then {agent_id:$a} else {} end)')"; }
contains "push to main denied" "$(bg 'git push origin main')" "rc=2"
contains "push refspec to main denied" "$(bg 'git push origin job/x:main')" "rc=2"
contains "force push denied" "$(bg 'git push -f origin job/x')" "rc=2"
contains "job branch push allowed for Michael" "$(bg "git -C x push -u origin job/$JOB")" "rc=0"
contains "agent push denied" "$(bg 'git push origin job/x--T-01' "$R/.work/$JOB/wt/T-01")" "rc=2"
contains "rm -rf .work denied" "$(bg 'rm -rf .work')" "rc=2"
contains "subagent dl integrate denied" "$(bg 'dl integrate T-01' "$R" abc123)" "rc=2"
contains "subagent dl status allowed" "$(bg 'dl status' "$R" abc123)" "rc=0"
contains "Michael dl gate allowed" "$(bg '/x/bin/dl gate T-01')" "rc=0"
contains "dl phase --force denied" "$(bg 'dl phase executing --force')" "rc=2"
contains "headless self-approval denied" "$(DELIVER_HEADLESS=1 bg 'dl approve plan ok')" "rc=2"
contains "subagent dl qa denied" "$(bg 'dl qa T-01 pass x' "$R" abc123)" "rc=2"
contains "interactive approval allowed" "$(bg 'dl approve plan "user said yes"')" "rc=0"
contains "unrelated commands allowed" "$(bg 'npm test -- --watch=false')" "rc=0"

wg() { hook write-guard.sh "$(jq -n --arg f "$1" --arg cwd "${2:-$R}" --arg a "${3:-}" --arg t "${4:-/dev/null}" '{tool_input:{file_path:$f},cwd:$cwd,transcript_path:$t} + (if $a!="" then {agent_id:$a} else {} end)')"; }
contains "dev may write in its card worktree" "$(wg "$R/.work/$JOB/wt/T-03/src/x.ts" "$R" a1)" "rc=0"
contains "dev may write its handoff" "$(wg "$R/.work/$JOB/handoffs/T-03.md" "$R" a1)" "rc=0"
contains "dev may not write the main checkout" "$(wg "$R/src/x.ts" "$R" a1)" "rc=2"
contains "dev may not write board.json" "$(wg "$R/.work/$JOB/board.json" "$R" a1)" "rc=2"
contains "dev may not write the integration worktree" "$(wg "$R/.work/$JOB/wt/_integration/src/x.ts" "$R" a1)" "rc=2"
contains "floor worker in its worktree may write there" "$(wg "$R/.work/$JOB/wt/T-03/a.ts" "$R/.work/$JOB/wt/T-03")" "rc=0"
contains "Michael may write plan.md" "$(wg "$R/.work/$JOB/plan.md" "$R" "" "$TR")" "rc=0"
contains "Michael may not write product code" "$(wg "$R/src/x.ts" "$R" "" "$TR")" "rc=2"
contains "other sessions are not restricted" "$(wg "$R/src/x.ts" "$R" "" /dev/null)" "rc=0"
contains "writes outside the repo are ignored" "$(wg "$TMP/elsewhere.txt" "$R" a1)" "rc=0"

out="$(printf '%s' "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\",\"agent_type\":\"backend-dev\",\"agent_id\":\"abcdef1234\",\"last_assistant_message\":\"status: done\\ncommit: 123\"}" | "$H/subagent-log.sh"; tail -1 "$R/.work/$JOB/events.log")"
contains "subagent-log appends the agent's summary" "$out" "backend-dev abcdef12: status: done commit: 123"

echo "munder difflin dispatch"
export HIVE_ROOT="$TMP/hive"; mkdir -p "$HIVE_ROOT"
"$DL" jobset '.phase="executing"' ; echo "do the card" > "$TMP/p.txt"
expect_ok "md-dispatch writes a spawn request" "$DL" md-dispatch T-03 "$TMP/p.txt"
reqf="$(ls "$HIVE_ROOT"/spawn-requests/*.json | head -1)"
contains "spawn request: card worktree cwd, no extra isolation, dev agent" "$(jq -c '{cwd,isolate,command}' "$reqf")" "\"isolate\":false,\"command\":\"claude --agent backend-dev\""
unset HIVE_ROOT

echo "architecture: mixed stacks, frozen decisions, seats, parallel assignment"
AR="$TMP/arch"; mkdir -p "$AR" && cd "$AR" && git init -q -b main && echo '{"verify_full":"true","merge_mode":"local","max_parallel":4}' > .deliver.json && git add -A && git commit -qm i
"$DL" new "micro" "x" >/dev/null; AJ="$AR/.work/$(cat .work/ACTIVE)"
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend-lead","agent":"ecc:architect"},
  {"role":"backend","agent":"backend-dev","count":2},{"role":"database","agent":"database-dev"},{"role":"qa","agent":"qa-tester"},
  {"role":"reviewer-java","agent":"ecc:java-reviewer"},{"role":"reviewer-go","agent":"ecc:go-reviewer"},{"role":"reviewer-db","agent":"ecc:database-reviewer"}]'
"$DL" phase readiness >/dev/null
svc() { jq -n --arg id "$1" --arg st "$2" --arg rv "$3" '{id:$id,kind:"service",stack:($st|split(",")),path:("services/"+$id+"/"),owner:"backend",reviewer:$rv}'; }
ARCH="$(jq -n --argjson a "$(svc orders java,spring-boot reviewer-java)" --argjson b "$(svc payments java,spring-boot reviewer-java)" \
  --argjson c "$(svc catalog java,spring-boot reviewer-java)" --argjson d "$(svc users java,spring-boot reviewer-java)" --argjson e "$(svc pricing go reviewer-go)" \
  '{style:"microservices",components:[$a,$b,$c,$d,$e,{id:"db",kind:"db",stack:["postgres"],path:"db/",owner:"database",reviewer:"reviewer-db"}]}')"
ARCH="$(jq '.components[4].reviewer="reviewer-java"' <<<"$ARCH")" ready_all
out="$("$DL" readiness 2>&1)"; contains "a Go service reviewed by the Java reviewer is rejected" "$out" "component 'pricing': reviewer reviewer-java (ecc:java-reviewer) does not match its stack"
ARCH="$(jq '.components[5].owner="qa"' <<<"$ARCH")" ready_all
out="$("$DL" readiness 2>&1)"; contains "a component owned by a non-dev role is rejected" "$out" "owner 'qa' must be a dev role"
ARCH="$ARCH" ready_all; expect_ok "4 Spring Boot + 1 Go service + a separately owned DB: valid" "$DL" readiness
grep -q "| pricing | service | go |" "$AJ/readiness.md" && ok "readiness.md shows the architecture table" || bad "arch table"
"$DL" phase readiness >/dev/null   # regenerate role cards with the architecture
grep -q "ecc:golang-patterns" "$AJ/roles/backend.md" && grep -q "ecc:springboot-patterns" "$AJ/roles/backend.md" && ok "backend role card names Spring Boot and Go skills per component" || bad "stack skills"
grep -q "postgres-patterns" "$AJ/roles/database.md" && ! grep -q "springboot" "$AJ/roles/database.md" && ok "database role card lists only the db component" || bad "db card"
grep -q "pricing" "$AJ/roles/reviewer-go.md" && ! grep -q "orders" "$AJ/roles/reviewer-go.md" && ok "the Go reviewer's card lists only the Go service" || bad "reviewer-go card"
"$DL" phase planning >/dev/null
acard() { jq -n --arg id "$1" --arg comp "$2" --arg role "$3" --arg p "$4" '{id:$id,title:$id,role:$role,agent:(if $role=="database" then "database-dev" else "backend-dev" end),component:$comp,state:"ready",depends_on:[],
  scope:[$p+"src/**"],qa_scope:[$p+"it/**"],verify:"true",qa_verify:"true",acceptance:["AC-1: x"],context:"c",attempts:0,notes:[]}' | sed 's/"verify": "true"/"verify": "test -d ."/;s/"qa_verify": "true"/"qa_verify": "test -d ."/'; }
for c in T-01 T-02 T-03; do printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$AJ/specs/$c.md"; done
jq -n --argjson a "$(acard T-01 orders backend services/orders/)" --argjson b "$(acard T-02 pricing backend services/pricing/)" --argjson c "$(acard T-03 db database db/)" '{cards:[$a,$b,$c]}' > "$AJ/board.json"
expect_ok "cards on three components validate" "$DL" validate
jq '.cards[0].scope=["services/payments/src/**"]' "$AJ/board.json" > "$AJ/b.t" && mv "$AJ/b.t" "$AJ/board.json"
out="$("$DL" validate 2>&1)"; contains "a card reaching outside its component is rejected" "$out" "outside component orders"
jq '.cards[0].scope=["services/orders/src/**"] | .cards[2].role="backend"' "$AJ/board.json" > "$AJ/b.t" && mv "$AJ/b.t" "$AJ/board.json"
out="$("$DL" validate 2>&1)"; contains "a backend dev on the database component is rejected" "$out" "owned by role 'database'"
jq '.cards[2].role="database"' "$AJ/board.json" > "$AJ/b.t" && mv "$AJ/b.t" "$AJ/board.json"
cp "$AJ/readiness.json" "$TMP/rd.bak"; jq '.architecture.components[4].stack=["rust"]' "$TMP/rd.bak" > "$AJ/readiness.json"
expect_fail 6 "editing the frozen readiness/architecture is refused" "$DL" validate
contains "agents cannot unfreeze" "$(printf '%s' '{"tool_input":{"command":"dl unfreeze \"x\""},"cwd":"/"}' | "$HERE/kit/hooks/deliver/bash-guard.sh" 2>&1; echo "rc=$?")" "rc=2"
cp "$TMP/rd.bak" "$AJ/readiness.json"
"$DL" phase executing >/dev/null
# two parallel assignments race for the single database seat… and two backend seats work side by side
"$DL" jobset '(.roles[] | select(.role=="database")).count = 1'
jq '.cards += [(.cards[2] | .id="T-04" | .title="T-04")]' "$AJ/board.json" > "$AJ/b.t" && mv "$AJ/b.t" "$AJ/board.json"; cp "$AJ/specs/T-03.md" "$AJ/specs/T-04.md"
( "$DL" wt add T-03 >"$TMP/r3" 2>&1; echo $? >> "$TMP/r3" ) & ( "$DL" wt add T-04 >"$TMP/r4" 2>&1; echo $? >> "$TMP/r4" ) & wait
[[ "$(jq '[.cards[] | select(.role=="database" and .state=="running")] | length' "$AJ/board.json")" == 1 ]] && grep -q "seats are busy" "$TMP/r3" "$TMP/r4" \
  && ok "concurrent assignment: exactly one of two cards gets the single database seat" || bad "race: $(cat "$TMP/r3" "$TMP/r4")"
"$DL" wt add T-01 >/dev/null && "$DL" wt add T-02 >/dev/null
[[ "$(jq -r '[.cards[] | select(.role=="backend") | .seat] | sort | join(",")' "$AJ/board.json")" == "backend#1,backend#2" ]] \
  && ok "two backend devs work in parallel on seats backend#1 and backend#2, each on its own branch" || bad "seats: $(jq -c '[.cards[]|{id,seat,branch}]' "$AJ/board.json")"
[[ "$(git -C "$AR" branch --list '*--T-01' '*--T-02' | wc -l)" == 2 ]] && ok "…each on its own card branch" || bad "branches"
jq '.cards += [(.cards[0] | .id="T-05" | .title="T-05" | .state="ready" | del(.seat))]' "$AJ/board.json" > "$AJ/b.t" && mv "$AJ/b.t" "$AJ/board.json"; cp "$AJ/specs/T-01.md" "$AJ/specs/T-05.md"
out="$("$DL" wt add T-05 2>&1)"; contains "a third backend card waits: both backend seats are busy" "$out" "all 2 'backend' seats are busy"
jq -e '[.cards[] | select(.id=="T-01") | .assignments[0] | .by=="michael" and .seat=="backend#1"] | all' "$AJ/board.json" >/dev/null && ok "assignment records michael + seat" || bad "assignment record"
"$DL" kanban > "$TMP/kanban.txt"; grep -q "In Progress (3)" "$TMP/kanban.txt" && ok "kanban shows 3 cards in progress" || bad "kanban: $(cat "$TMP/kanban.txt")"
[[ -f $AJ/kanban.html ]] && grep -q "backend#2" "$AJ/kanban.html" && ok "local tracker renders kanban.html with seats" || bad "kanban.html"
"$DL" phase aborted >/dev/null; "$DL" cleanup --all >/dev/null; cd "$R"; unset ARCH

echo "knowledge: standards, memory, Munder Difflin knowledge graph"
K="$HOME/.deliver/knowledge"; mkdir -p "$K" "$TMP/kn/.deliver/knowledge"
cat > "$K/api-errors.md" <<'MD'
---
title: API error handling
applies_to: [dev, review]
stack: [javascript]
---
# API error handling
## Must
- Map domain errors to HTTP codes in one place.
- Never leak stack traces.
## Background
Long text that is referenced, not copied.
MD
cat > "$K/testing.md" <<'MD'
---
applies_to: [qa]
---
# Testing standard
## Must
- Every AC has a test named after it.
MD
cat > "$TMP/kn/.deliver/knowledge/testing.md" <<'MD'
---
applies_to: [qa, dev]
---
# Testing standard (project override)
## Must
- Tests live in test/<area>/.
MD
cd "$TMP/kn" && git init -q -b main && echo x > a && git add -A && git commit -qm i
"$DL" new "know" "x" >/dev/null; KJ="$(cat .work/ACTIVE)"
"$DL" jobset '.stack=["javascript"] | .roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]'
"$DL" learn qa "Check rounding at .5 boundaries — QA missed it in JOB-1" >/dev/null
"$DL" phase readiness >/dev/null
grep -q "MUST: Map domain errors" ".work/$KJ/roles/backend.md" && ok "company standard's Must reaches the dev role" || bad "dev standard"
grep -q "MUST: Map domain errors" ".work/$KJ/roles/qa.md" && bad "standard leaked to a role it does not apply to" || ok "applies_to filters roles"
grep -q "Tests live in test/<area>/" ".work/$KJ/roles/qa.md" && ! grep -q "Every AC has a test named" ".work/$KJ/roles/qa.md" && ok "project standard overrides the company one" || bad "override"
grep -q "Never leak stack traces" ".work/$KJ/roles/reviewer.md" && ok "reviewer gets the review standards" || bad "reviewer standard"
grep -q "Background" ".work/$KJ/roles/backend.md" && bad "whole document pasted" || ok "only Must bullets are copied (rest by reference)"
grep -q "rounding at .5" ".work/$KJ/roles/qa.md" && ok "memory: a learned lesson reaches the next role cards" || bad "lesson"
mkdir -p "$TMP/res"; cat > "$TMP/res/kg-core.cjs" <<'JS'
const fs=require('fs'),p=require('path');
const f=r=>p.join(r,'idx.json'), rd=r=>{try{return JSON.parse(fs.readFileSync(f(r)))}catch{return[]}};
module.exports={list:r=>rd(r), removeDoc:(r,id)=>{fs.writeFileSync(f(r),JSON.stringify(rd(r).filter(m=>m.id!==id)));return true},
 ingest:(r,i)=>{const a=rd(r);a.push({id:String(a.length+Math.random()),source:i.source,title:i.title});fs.mkdirSync(r,{recursive:true});fs.writeFileSync(f(r),JSON.stringify(a));return{docId:'x'}}};
JS
touch "$TMP/res/kg.cjs"
KG_CLI="$TMP/res/kg.cjs" KG_ROOT="$TMP/kgroot" "$DL" knowledge sync-md >/dev/null
out="$(KG_CLI="$TMP/res/kg.cjs" KG_ROOT="$TMP/kgroot" "$DL" knowledge sync-md)"
contains "sync-md re-ingests without duplicates" "$out" "3 document(s) ingested (3 older version(s) replaced)"
[[ "$(jq length "$TMP/kgroot/idx.json")" == 3 ]] && ok "knowledge graph holds 3 docs (2 standards + lessons)" || bad "kg docs: $(cat "$TMP/kgroot/idx.json")"
"$DL" phase aborted >/dev/null; "$DL" cleanup --all >/dev/null; cd "$R"

echo "merge modes: human / semi / auto (fake gh, bare origin)"
FAKEGH="$TMP/gh"; GHLOG="$TMP/gh.log"
cat > "$FAKEGH" <<'GH'
#!/usr/bin/env bash
echo "$*" >> "$GHLOG"
case "$1 $2" in
  "pr create") echo "https://github.com/acme/demo/pull/7" ;;
  "pr merge") exit 0 ;;
  "pr checks") [[ -f $GHSTATE.fail ]] && { echo "ci  fail"; exit 1; }; echo "ci  pass" ;;
  "pr view") cat "$GHSTATE" 2>/dev/null || echo "OPEN REVIEW_REQUIRED BLOCKED" ;;
esac
GH
chmod +x "$FAKEGH"; export DELIVER_GH="$FAKEGH" GHLOG GHSTATE="$TMP/ghstate"
shipjob() { # shipjob <mode> → a repo with one merged card, in phase closing with a report
  local mode=$1 r="$TMP/ship-$1"
  git init -q --bare "$TMP/origin-$mode.git"
  mkdir -p "$r" && cd "$r" && git init -q -b main && git remote add origin "$TMP/origin-$mode.git"
  echo '{}' > package.json; mkdir -p test; printf 'import {test} from "node:test"; test("x",()=>{});\n' > test/x.test.mjs
  printf '{"verify_full":"node --test","merge_mode":"%s"}\n' "$mode" > .deliver.json
  git add -A && git commit -qm init
  "$DL" new "ship $mode" "x" >/dev/null
  "$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]'
  "$DL" phase readiness >/dev/null && ready_all && "$DL" phase planning >/dev/null
  local j; j="$(cat .work/ACTIVE)"
  jq -n '{cards:[{id:"T-01",title:"one",role:"backend",agent:"backend-dev",state:"ready",depends_on:[],scope:["src/**"],acceptance:["AC-1: x"],verify:"node --test",context:"c",attempts:0,notes:[],component:"app",qa_scope:["test/integration/T-01/**"],qa_verify:"node --test test/integration/T-01/*.test.mjs"}]}' > ".work/$j/board.json"
  printf '## Acceptance criteria\nGiven a, when b, then c\n' > ".work/$j/specs/T-01.md"
  "$DL" phase executing >/dev/null; local w; w="$("$DL" wt add T-01)"
  mkdir -p "$w/src" && echo 1 > "$w/src/a.txt" && git -C "$w" add -A && git -C "$w" commit -qm "T-01"
  "$DL" gate T-01 >/dev/null && qa_tests "$w" T-01 && "$DL" qa T-01 pass "ok" >/dev/null && "$DL" review T-01 approve ok >/dev/null && "$DL" integrate T-01 >/dev/null
  "$DL" phase integrating >/dev/null && "$DL" verify-all >/dev/null && "$DL" phase closing >/dev/null
  echo "# report" > ".work/$j/report.md"
}
shipjob human; : > "$GHLOG"
out="$("$DL" ship 2>&1)"; contains "human: PR opened, waits for the human" "$out" "waiting for the human"
git --git-dir="$TMP/origin-human.git" rev-parse -q --verify "refs/heads/$(jq -r .branch .work/*/job.json)" >/dev/null && ok "human: job branch pushed" || bad "push"
grep -q "pr create --base main" "$GHLOG" && ! grep -q "pr merge" "$GHLOG" && ok "human: PR created, never merged by Michael" || bad "human gh calls: $(cat "$GHLOG")"
contains "human: phase awaiting_pr_merge" "$(jq -r .phase .work/*/job.json)" "awaiting_pr_merge"
contains "human: stop-guard lets Michael hand over" "$(hook stop-guard.sh "{\"cwd\":\"$PWD\",\"transcript_path\":\"/dev/null\"}")" "rc=0"
contains "human: dl pr shows an open PR" "$("$DL" pr)" "OPEN:"
echo "MERGED APPROVED CLEAN" > "$GHSTATE"; contains "human: dl pr sees the merge → done" "$("$DL" pr)" "MERGED"; rm -f "$GHSTATE"
contains "phase done" "$(jq -r .phase .work/*/job.json)" "done"
shipjob semi; : > "$GHLOG"
out="$("$DL" ship 2>&1)"; contains "semi: auto-merge armed" "$out" "auto-merge armed"
grep -q "pr merge https://github.com/acme/demo/pull/7 --auto --merge" "$GHLOG" && ok "semi: gh pr merge --auto" || bad "semi gh: $(cat "$GHLOG")"
contains "semi: still waits for the human approval" "$(jq -r .phase .work/*/job.json)" "awaiting_pr_merge"
shipjob auto; : > "$GHLOG"; touch "$GHSTATE.fail"
expect_fail 1 "auto: red CI → not merged" "$DL" ship
! grep -q "pr merge" "$GHLOG" && ok "auto: no merge on red CI" || bad "auto merged on red"
rm -f "$GHSTATE.fail"; : > "$GHLOG"
out="$("$DL" ship 2>&1)"; contains "auto: merged on green" "$out" "merged automatically"
! grep -q "pr create" "$GHLOG" && ok "auto: re-ship reuses the existing PR" || bad "auto created a second PR"
contains "auto: phase done" "$(jq -r .phase .work/*/job.json)" "done"
unset DELIVER_GH; cd "$R"

echo "install / uninstall"
INST="$HERE/scripts/install.sh"
expect_ok "install --user" "$INST" --user
expect_ok "install is idempotent" "$INST" --user
[[ "$(jq '[.hooks[][] .hooks[] | select(.command|test("hooks/deliver"))] | length' "$HOME/.claude/settings.json")" == 4 ]] && ok "4 hooks, no duplicates" || bad "hook count"
[[ -f $HOME/.claude/agents/qa-tester.md ]] && ok "qa-tester agent installed" || bad "qa-tester missing"
[[ "$(jq -r .env.GATEGUARD_EXEMPT_GLOBS "$HOME/.claude/settings.json")" == .work/* ]] && ok "GateGuard exemption set" || bad "env"
echo "# local edit" >> "$HOME/.claude/skills/deliver/SKILL.md"
"$INST" --user >/dev/null
ls -d "$HOME"/.claude/skills/* | grep -qv '/deliver$' && bad "backup left inside skills/" || ok "backups stay out of skills/"
ls "$HOME"/.claude/.deliver-backups/*/skills/deliver/SKILL.md >/dev/null 2>&1 && ok "changed skill backed up" || bad "backup missing"
jq '.hooks.Stop += [{"hooks":[{"type":"command","command":"/usr/bin/true"}]}] | .env.MINE="1"' "$HOME/.claude/settings.json" > "$TMP/s" && mv "$TMP/s" "$HOME/.claude/settings.json"
expect_ok "uninstall" "$INST" --user --uninstall
[[ ! -e $HOME/.claude/skills/deliver && "$(jq -c '[.hooks.Stop[].hooks[].command]' "$HOME/.claude/settings.json")" == '["/usr/bin/true"]' && "$(jq -r .env.MINE "$HOME/.claude/settings.json")" == 1 ]] \
  && ok "uninstall keeps foreign hooks and env" || bad "uninstall: $(cat "$HOME/.claude/settings.json")"
"$INST" --user >/dev/null
out="$("$HERE/scripts/doctor.sh" "$R" 2>&1)"
contains "doctor sees the install and the repo" "$out" "user: hook write-guard"

echo
echo "result: $pass passed, $failn failed"
[[ $failn -eq 0 ]]
