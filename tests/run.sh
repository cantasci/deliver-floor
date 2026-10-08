#!/usr/bin/env bash
# End-to-end test of the deterministic half of /deliver: dl, validate, scope, hooks, install/uninstall.
# No model and no network needed — dev agents are simulated with git commits.
#   tests/run.sh            → exit 0 when everything passes
set -uo pipefail
# grep -q exits on the first match; under pipefail the producer then dies of SIGPIPE and the pipe fails at random. gq reads to EOF.
gq() { grep "$@" >/dev/null; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/deliver-test.XXXXXX")" && pwd -P)"   # resolved: macOS links /var and /tmp into /private
trap 'rm -rf "$TMP" "$HERE/kit/skills/deliver/bin/trackers/zz-test.mjs"' EXIT
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
bedit() { # bedit <board.json> '<jq>' — a fixture edit made outside dl, accepted by "the human" with dl reseal
  local f=$1; jq "$2" "$f" > "$f.t" && mv "$f.t" "$f"; "$DL" reseal "test fixture edit: $2" >/dev/null
}
ready_all() { # ready_all [<id> open] — the BA's readiness review: every applicable item decided (one left open if asked)
  local jd; jd="$(dirname "$(dirname "$(git rev-parse --git-common-dir)")")/.work/$(cat .work/ACTIVE)"
  [[ -d $jd ]] || jd="$PWD/.work/$(cat .work/ACTIVE)"
  # a decision quotes the request words that state it (R1): the fixture quotes the start of its job's request
  local q; q="$(jq -r '.request | gsub("\\s+"; " ") | .[0:24]' "$jd/job.json")"
  node "$HERE/kit/skills/deliver/bin/readiness.mjs" applicable "$jd" | jq --arg o "${1:-}" --arg spec "${SPECIALISTS:-}" --arg q "$q" --argjson arch "${ARCH:-null}" '{items: [.[] | if .id == $o
     then {id, status:"open", owner:"business", question:("Which option for " + .id + "?"), options:["a","b"]}
     elif ($spec != "1" and (.id == "UX-a11y" or .id == "NFR-performance" or .id == "DEL-docs")) then {id, status:"n_a", answer:"not part of this fixture", source:"test fixture"}
     else {id, status:"decided", answer:"test decision", source:"the request", quote:$q} end],
     architecture: ($arch // {style:"library", components:[{id:"app", kind:"library", stack:["generic"], path:".", owner:"backend", reviewer:"reviewer"}]})}' > "$jd/readiness.json"
}
SDIR="$HERE/kit/skills/deliver"

echo "Node 22: node --test <directory> fails (MODULE_NOT_FOUND) — caught before it costs an attempt"
nt() { node "$HERE/kit/skills/deliver/bin/node-test-args.mjs" "$1" >/dev/null; echo $?; }
[[ "$(nt 'node --test test/x/')$(nt 'node --test test/x')$(nt "node --test 'test/**/*.test.mjs'")$(nt 'node --test test/a.test.mjs')$(nt 'npm test && node --test --test-reporter=spec test/int/')$(nt 'node --test')" == 110010 ]] \
  && ok "a directory argument to node --test is found (with or without /, after options); files, globs and none are fine" || bad "node-test-args"

echo "macOS bash 3.2"
expect_ok "dl, hooks and scripts parse and run on bash 3.2 (no case in \$( ), no bare empty arrays, no bash-4 features)" \
  node "$HERE/tests/lint-bash32.mjs" "$HERE/kit/skills/deliver/bin/dl" "$HERE/kit/skills/deliver/bin/md-brief.sh" "$HERE"/kit/hooks/deliver/*.sh "$HERE"/scripts/*.sh

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
{ "dispatch": "subagent", "verify_full": "node --test", "worktree_setup": "mkdir -p \"$ROOT/node_modules\" && ln -s \"$ROOT/node_modules\" node_modules", "merge_mode": "local", "max_parallel": 2, "gates": { "plan": true } }
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
RJ0="$R/.work/$JOB"
out="$("$DL" jobset '.settings.verify_full' 2>&1)"
contains "dl jobset refuses an expression that reads instead of changes (seen live: job.json became the string \"npm test\")" "$out" "dl jobset changes the job, it does not read it"
[[ "$(jq -r 'type' "$RJ0/job.json")" == object ]] && ok "…job.json is left as it was" || bad "job.json clobbered: $(head -c 80 "$RJ0/job.json")"
contains "dl jobset refuses dropping the job's identity too" "$("$DL" jobset 'del(.id)' 2>&1)" "an object that is not this job"
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
# R1: a decision taken from the request must quote the words that state it — an interpretation is an open business item
jq '{items: ([.[] | {id, status:"decided", answer:"x", source:"the request", quote:"Users can cancel orders"}])}' "$TMP/appl.json" > "$RJ/readiness.json"
jq '.items[0].quote = "orders may be cancelled within 24 hours" | .items[1] |= del(.quote) | .items[2].source = "human: ana 2026-10-03" | .items[2] |= del(.quote)' "$RJ/readiness.json" > "$RJ/r.json" && mv "$RJ/r.json" "$RJ/readiness.json"
out="$("$DL" readiness 2>&1)"
contains "a quote that is not in the request is an error (an interpretation, not a decision)" "$out" "quote not found in the request"
contains "a decision from the request without its quote is an error" "$out" "decided from a source needs \`quote\`"
[[ $out != *"$(jq -r '.items[2].id' "$RJ/readiness.json"): decided from a source"* && $out != *"$(jq -r '.items[2].id' "$RJ/readiness.json"): quote"* ]] && ok "an answer from the human needs no quote" || bad "human source asked for a quote"
# The language is never a PM default: ARC-stack is the repo's, the request's or the human's
jq '{items: ([.[] | {id, status:"decided", answer:"x", source:"human: t 2026-10-05"}])} | (.items[] | select(.id=="ARC-stack")) |= {id, status:"decided", answer:"Node.js", source:"pm: michael 2026-10-05 — fastest to write"}' "$TMP/appl.json" > "$RJ/readiness.json"
out="$("$DL" readiness 2>&1)"
contains "a language picked out of habit is refused: the choice must quote what in the request points to it" "$out" "quoting the request words that point to it"
contains "…and name the alternatives it weighed" "$out" "must name the alternatives it weighed"
REQ0="$(jq -r .request "$RJ/job.json")"; QW="$(printf '%s' "$REQ0" | tr -s ' \n' ' ' | cut -d' ' -f1-3)"
jq --arg q "$QW" '(.items[] | select(.id=="ARC-stack")).source = ("pm: michael 2026-10-05 — the request says \"" + $q + "\"; chosen over Python, which the repo would add as a second runtime")' "$RJ/readiness.json" > "$RJ/r.json" && mv "$RJ/r.json" "$RJ/readiness.json"
[[ "$("$DL" readiness 2>&1)" != *"ARC-stack"* ]] && ok "a best-fit choice with the request's words and the alternatives is the team's decision" || bad "ARC-stack: $("$DL" readiness 2>&1 | grep ARC-stack)"
EJ='{"phase":"intake","stack":[],"roles":[{"role":"ba","agent":"business-analyst"},{"role":"qa","agent":"qa-tester"},{"role":"backend-lead","agent":"ecc:architect"},{"role":"backend","agent":"backend-dev"}]}'
contains "a repo without code may start with no stack reviewer (the language is decided at readiness)…" "$(node --input-type=module -e "import {checkJobRoles, loadCatalog} from '$HERE/kit/skills/deliver/bin/roles.mjs'; console.log(JSON.stringify(checkJobRoles($EJ, loadCatalog())))")" '[]'
contains "…but not into planning" "$(node --input-type=module -e "import {checkJobRoles, loadCatalog} from '$HERE/kit/skills/deliver/bin/roles.mjs'; const j=$EJ; j.phase='planning'; console.log(JSON.stringify(checkJobRoles(j, loadCatalog())))")" "no stack reviewer selected"
contains "the stack check is in the playbook: no default language, the best fit for the requirements" "$(cat "$HERE/kit/skills/deliver/SKILL.md")" "never pick one by default"
# Items that shape the product (ask: human) — settled by the request's own words or the human, never a repo convention or the PM
echo 'Pure functions, no I/O.' > "$R/CONV.md"
jq '{items: ([.[] | {id, status:"decided", answer:"x", source:"the request", quote:"Users can cancel orders"}])}
    | (.items[] | select(.id=="ARC-data")) |= {id, status:"n_a", answer:"no store", source:"CONV.md", quote:"Pure functions, no I/O."}
    | (.items[] | select(.id=="ARC-style")) |= (.source = "CONV.md" | .quote = "Pure functions")
    | (.items[] | select(.id=="ARC-ui")) |= {id, status:"open", owner:"pm", question:"Is there a UI?"}
    | (.items[] | select(.id=="ARC-deps")) |= {id, status:"decided", answer:"no new dependencies", source:"CONV.md", quote:"Pure functions"}
    | (.items[] | select(.id=="ARC-stack")) |= (.source = "human: ana 2026-10-05" | del(.quote))' "$TMP/appl.json" > "$RJ/readiness.json"
out="$("$DL" readiness 2>&1)"
contains "a product-shaping item may not be n/a because of a repo convention (seen live: no database, from CLAUDE.md)" "$out" "ARC-data: n_a from words that are not in the request"
contains "…nor be decided from a repo file" "$out" "ARC-style: decided from words that are not in the request"
contains "…nor be left to the PM" "$out" "ARC-ui: open for the PM"
[[ $out != *"ARC-stack:"* && $out != *"ARC-components:"* ]] && ok "…while the human's answer or the request's own words settle it" || bad "product-shaping item refused: $out"
contains "new dependencies are the human's call too: not ruled out by a repo convention" "$out" "ARC-deps: decided from words that are not in the request"
contains "dl decide refuses a product-shaping item even when it is marked pm" "$("$DL" decide ARC-ui "no UI" "x" 2>&1)" "belongs to the business"
printf 'Orders are kept for 90 days.\n' > "$R/RETENTION.md"
jq '{items: ([.[] | {id, status:"decided", answer:"x", source:"the request", quote:"Users can cancel orders"}])} | .items[0].source = "RETENTION.md" | .items[0].quote = "kept for 90   days"' "$TMP/appl.json" > "$RJ/readiness.json"
out="$("$DL" readiness 2>&1)"; [[ $out != *"quote not found"* ]] && ok "a quote from the repo file named in the source counts (whitespace-insensitive)" || bad "repo-file quote: $out"
rm -f "$R/RETENTION.md"
# Brand DNA: a company or project standard settles a product-shaping item where it states it — quoted, from that document
mkdir -p "$R/.deliver/knowledge"; printf -- '---\napplies_to: [ba]\n---\n# Brand\n## Must\n- [BV-type] Text uses only the typeface Inter.\n## Decides\n- Primary colour: Deep Blue #0B3D91\n' > "$R/.deliver/knowledge/brand-visual.md"
jq '{items: ([.[] | {id, status:"decided", answer:"x", source:"the request", quote:"Users can cancel orders"}])}
    | (.items[] | select(.id=="ARC-ui")) |= {id, status:"decided", answer:"a web UI in the brand colours", source:"standard: brand-visual.md", quote:"Primary colour: deep blue   #0B3D91"}
    | (.items[] | select(.id=="ARC-style")) |= {id, status:"decided", answer:"x", source:"standard: brand-visual.md", quote:"Primary colour: Bright Red"}
    | (.items[] | select(.id=="ARC-data")) |= {id, status:"decided", answer:"x", source:"standard: nope.md", quote:"x"}
    | (.items[] | select(.id=="ARC-deps")) |= {id, status:"decided", answer:"x", source:"standard: brand-visual"}' "$TMP/appl.json" > "$RJ/readiness.json"
out="$("$DL" readiness 2>&1)"
[[ $out != *"ARC-ui:"* ]] && ok "a product-shaping item is settled by a standard that states it, quoted (source standard: <file>)" || bad "standard source refused: $(grep ARC-ui <<<"$out")"
contains "…not by words the standard does not hold" "$out" "ARC-style: quote not found in standard 'brand-visual.md'"
contains "…not by a standard the job does not have" "$out" "ARC-data: standard 'nope.md' is not one of this job's standards"
contains "…and not without its words" "$out" "ARC-deps: decided from standard 'brand-visual.md' needs \`quote\`"
rm -f "$R/.deliver/knowledge/brand-visual.md"; rmdir "$R/.deliver/knowledge" 2>/dev/null || true
contains "a missing architecture is an error" "$out" "architecture: architecture is missing"
ready_all CON-interface
out="$("$DL" readiness 2>&1)"; contains "an open item is reported as a question" "$out" "OPEN  CON-interface"
grep -q "## CON-interface" "$RJ/QUESTIONS.md" && ok "QUESTIONS.md lists the open question" || bad "QUESTIONS.md"
expect_fail 1 "planning refused while a question is open" "$DL" phase planning
contains "next asks the human the open question" "$("$DL" next)" "ASK     human: CON-interface"
expect_ok "awaiting_clarification" "$DL" phase awaiting_clarification
contains "agents cannot answer readiness questions" "$(printf '%s' '{"tool_input":{"command":"dl clarify CON-interface x"},"agent_id":"a1","cwd":"/"}' | "$HERE/kit/hooks/deliver/bash-guard.sh" 2>&1; echo "rc=$?")" "rc=2"
contains "headless sessions cannot answer them either" "$(printf '%s' '{"tool_input":{"command":"dl clarify CON-interface x"},"cwd":"/"}' | DELIVER_HEADLESS=1 "$HERE/kit/hooks/deliver/bash-guard.sh" 2>&1; echo "rc=$?")" "rc=2"
expect_fail 1 "the PM cannot decide a business question" "$DL" decide CON-interface "signed" "seems natural"
expect_ok "the human's answer is recorded" "$DL" clarify CON-interface "signed integers; negative = upgrade"
jq -e '.items[] | select(.id=="CON-interface") | .status=="decided" and (.source|startswith("human:")) and (.history|length==1)' "$RJ/readiness.json" >/dev/null \
  && ok "answer stored with source human + history of the question" || bad "clarify record"
grep -q "signed integers" "$RJ/readiness.md" && ok "readiness.md carries the decision" || bad "readiness.md"
# R2: before the freeze an answer that does not answer its question goes back to the human
out="$("$DL" reopen CON-interface "the answer is about the display, not the sign" 2>&1)"; contains "dl reopen puts an answered item back to the human" "$out" "open again"
jq -e '.items[] | select(.id=="CON-interface") | .status=="open" and .owner=="business" and (.question|test("Asked again")) and (.history[-1].rejected|test("display"))' "$RJ/readiness.json" >/dev/null \
  && ok "…same question, asked again, the rejected answer kept in its history" || bad "reopen record: $(jq -c '.items[] | select(.id=="CON-interface")' "$RJ/readiness.json")"
grep -q "CON-interface" "$RJ/QUESTIONS.md" && ok "…and QUESTIONS.md asks it again" || bad "QUESTIONS.md"
DELIVER_APPROVER=ana "$DL" clarify CON-interface "signed like notchChange" >/dev/null
jq '.items += [{id:"X-immutable",status:"open",owner:"pm",question:"Freeze the options array?",options:["freeze","plain"]}]' "$RJ/readiness.json" > "$RJ/r.t" && mv "$RJ/r.t" "$RJ/readiness.json"
contains "next asks the PM to decide an implementation detail" "$("$DL" next)" "DECIDE  (PM) X-immutable"
expect_fail 1 "planning refused while a PM decision is open" "$DL" phase planning
! grep -q "X-immutable" "$RJ/QUESTIONS.md" && ok "PM-owned items are not put to the human" || bad "pm item in QUESTIONS.md"
expect_ok "the PM decides it with a rationale" "$DL" decide X-immutable "freeze with Object.freeze" "no scope or contract impact; protects consumers"
jq -e '.items[] | select(.id=="X-immutable") | .status=="decided" and (.source|startswith("pm: michael"))' "$RJ/readiness.json" >/dev/null && ok "recorded with source pm: michael + rationale" || bad "pm decision record"
contains "agents cannot record PM decisions" "$(printf '%s' '{"tool_input":{"command":"dl decide X a b"},"agent_id":"a1","cwd":"/"}' | "$HERE/kit/hooks/deliver/bash-guard.sh" 2>&1; echo "rc=$?")" "rc=2"
expect_ok "phase planning once nothing is open" "$DL" phase planning
jq -e '.frozen.readiness_sha256 | length == 64' "$R/.work/$JOB/job.json" >/dev/null && ok "planning froze readiness.json (sha256 in job.json)" || bad "freeze"
contains "in planning Michael may still write board.json with a script (the Leads' cards)" \
  "$(printf '%s' "$(jq -n --arg c 'node -e "fs.writeFileSync(d+\"/board.json\", s)"' --arg cwd "$R" '{tool_input:{command:$c},cwd:$cwd}')" | "$HERE/kit/hooks/deliver/bash-guard.sh" 2>&1; echo "rc=$?")" "rc=0"
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
report_ok() { # report_ok <job dir> [title] — the closing check's report: a row with status and evidence for every AC of plan.md
  { echo "# ${2:-Delivery report}"; echo; echo "| AC | Status | Evidence |"; echo "| --- | --- | --- |"
    grep -oE '^- AC-[0-9]+' "$1/plan.md" 2>/dev/null | sed 's/^- //' | sort -u | while read -r a; do echo "| $a | ✅ | test/$a.test.mjs (gate log) |"; done; } > "$1/report.md"
}
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
bedit "$B" '.cards[0].agent="frontend-dev"'
expect_fail 1 "agent outside selected roles rejected" "$DL" validate
bedit "$B" '.cards[0].agent="backend-dev" | .cards[0].acceptance=["AC-9: x"]'
expect_fail 1 "unknown AC reference rejected" "$DL" validate
bedit "$B" '.cards[0].acceptance=["AC-1: add"] | .cards[0].verify="true"'
expect_fail 1 "no-op verify rejected" "$DL" validate
bedit "$B" '.cards[0].verify="node --test test/add/*.test.mjs" | .cards[1].scope=["src/add/**"]'
out="$("$DL" validate 2>&1)"; contains "parallel scope overlap warned" "$out" "WARN  T-01 and T-02"
bedit "$B" '.cards[1].scope=["src/sub/**","test/sub/**"] | .cards[1].scope += ["../x"]'
expect_fail 1 "scope escaping repo rejected" "$DL" validate
bedit "$B" '.cards[1].scope=["src/sub/**","test/sub/**"] | .cards[0].depends_on=["T-03"]'
expect_fail 1 "dependency cycle rejected" "$DL" validate
bedit "$B" '.cards[0].depends_on=[]'

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
bedit "$B" '.cards[2].depends_on=[]'
expect_fail 5 "max_parallel enforced" "$DL" wt add T-03
bedit "$B" '.cards[2].depends_on=["T-01","T-02"]'

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
contains "a blocked card is Michael's to decide — the human is not asked after the start" "$("$DL" next)" "DECIDE  (PM) blocked T-02"
contains "…dropping it needs the reason" "$("$DL" card T-02 state archived 2>&1)" "give the reason"
contains "no questions for the human after the start" "$("$DL" phase awaiting_clarification 2>&1)" "asked only at the start"
expect_ok "Michael records a decision of his own" "$DL" pm-decide "keep T-02 and give it one more round with a negative test" "the reviewer's finding is small and in scope" T-02
contains "…in the event log" "$(tail -1 "$R/.work/$JOB/events.log")" "pm-decision	T-02: keep T-02"
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
contains "a running card's verify command can be fixed (a form Node 22 rejects is refused by the validator)" "$("$DL" card T-03 set qa_verify "node --test test/qa/" "try a directory" 2>&1)" "a directory fails on Node 22+"
QV0="$(jq -r '.cards[] | select(.id=="T-03") | .qa_verify' "$B")"; AT0="$(jq -r '.cards[] | select(.id=="T-03") | .attempts' "$B")"
bedit "$B" '(.cards[] | select(.id=="T-03")).qa_verify = "node --test test/qa/"'
contains "the gate refuses a node --test directory before running it…" "$("$DL" gate T-03 2>&1)" "T-03's qa_verify cannot pass"
[[ "$(jq -r '.cards[] | select(.id=="T-03") | .attempts' "$B")" == "$AT0" && "$(jq -r '.cards[] | select(.id=="T-03") | .gate.result // "none"' "$B")" == none ]] && ok "…without using an attempt or recording a FAIL" || bad "gate pre-check cost an attempt"
expect_ok "…and the fix is one command on the running card" "$DL" card T-03 set qa_verify "$QV0" "back to the file form"
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
printf '# Delivery report\n\n| AC | Status | Evidence |\n| --- | --- | --- |\n| AC-1 | ✅ / ❌ / ⚠️ | test name, gate log, screenshot |\n' > "$R/.work/$JOB/report.md"
out="$("$DL" ship 2>&1)"
contains "ship refuses a report that does not account for every AC of the plan (a missing row)…" "$out" "AC-2 has no row"
contains "…an AC without its status" "$out" "AC-1 has no status"
contains "…or without its evidence" "$out" "AC-1 has no evidence"
report_ok "$R/.work/$JOB" "Delivery report — all ACs met"
expect_fail 1 "done refused before shipping" "$DL" phase done
expect_ok "ship (local) merges into the base" "$DL" ship
contains "the PR body lists every change to a card's tests, with its reason (a weaker check is the human's to see)" "$(cat "$R/.work/$JOB/report.md")" "## Test and contract changes after the start"
contains "…the change itself and why" "$(cat "$R/.work/$JOB/report.md")" '**T-03** `qa_verify`'
contains "…with the reason given" "$(cat "$R/.work/$JOB/report.md")" "_back to the file form_"
contains "the PR body lists Michael's own decisions" "$(cat "$R/.work/$JOB/report.md")" "## Decisions Michael took himself"
contains "…with the reason" "$(cat "$R/.work/$JOB/report.md")" "the reviewer's finding is small and in scope"
[[ -f $R/src/add/add.mjs && -f $R/src/sub/sub.mjs && "$(jq -r .phase "$R/.work/$JOB/job.json")" == done ]] && ok "local merge delivered the cards, phase done" || bad "local ship"
JR="$R/.deliver/jobs/$JOB"
[[ -f $JR/request.md && -f $JR/readiness.json && -f $JR/readiness.md && -f $JR/plan.md && -f $JR/report.md && -f $JR/board.json && -f $JR/events.log ]] \
  && ok "the job's record is in the repo with its code (.deliver/jobs/<job>: request, readiness, plan, report, board, events)" || bad "job record: $(ls "$JR" 2>&1)"
contains "…the record's report is the final PR body (with the contract changes)" "$(cat "$JR/report.md")" "## Test and contract changes after the start"
contains "…the request in the asker's words" "$(cat "$JR/request.md")" "$(jq -r .request "$R/.work/$JOB/job.json" | head -n 1)"
[[ "$(jq -r '[.cards[] | select(.review.verdict == "approve")] | length' "$JR/board.json")" -ge 1 ]] && ok "…the board keeps every card's gate, QA and review verdicts" || bad "record board"
! grep -q "$R/" "$JR/board.json" "$JR/events.log" && ok "…with paths relative to the repo (no machine paths)" || bad "absolute paths in the record"
git -C "$R" log --format=%s main | gq "Record of $JOB\|record of " && ok "…committed by dl in the repo's commit format" || bad "record commit: $(git -C "$R" log --format=%s main | head -5)"

echo "hooks"
H="$HERE/kit/hooks/deliver"
hook() { local h=$1 json=$2; out="$(printf '%s' "$json" | "$H/$h" 2>&1)"; echo "rc=$? $out"; }
TR="$TMP/transcript.jsonl"; echo "{\"x\":\"$JOB\"}" > "$TR"
"$DL" phase executing --force >/dev/null
bedit "$B" '.cards[2].state="ready" | .cards[2].attempts=0'
contains "stop-guard blocks the owner with open cards" "$(hook stop-guard.sh "{\"cwd\":\"$TMP\",\"transcript_path\":\"$TR\"}")" "rc=2"
contains "…but lets a floor seat with the same transcript stop (only Michael is held to the board)" "$(AGENT_ID=worker-seat-x hook stop-guard.sh "{\"cwd\":\"$TMP\",\"transcript_path\":\"$TR\"}")" "rc=0"
contains "stop-guard ignores other sessions" "$(hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"/dev/null\"}")" "rc=0"
contains "stop-guard ignores agent sessions (a subagent id), wherever they are" "$(hook stop-guard.sh "{\"cwd\":\"$R/.work/$JOB/wt/T-03\",\"transcript_path\":\"$TR\",\"agent_id\":\"a1\"}")" "rc=0"
contains "…but Michael with his shell cd'ed into a card worktree is still Michael (held to the board)" "$(hook stop-guard.sh "{\"cwd\":\"$R/.work/$JOB/wt/T-03\",\"transcript_path\":\"$TR\"}")" "rc=2"; rm -f "$R/.work/$JOB/.stop-blocks"
for i in 1 2 3 4 5; do hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\"}" >/dev/null; done
contains "stop-guard gives up after stop_guard_max" "$(hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\"}")" "rc=0"
"$DL" jobset '.settings.dispatch="munder"'; export AGENT_ID=god; rm -f "$R/.work/$JOB/.stop-blocks"   # a floor job: only the app's Michael drives it
bedit "$B" '.cards[2].state="running"'
contains "stop-guard lets Michael wait for floor workers (munder)" "$(hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\"}")" "rc=0"
"$DL" jobset '.settings.dispatch="subagent"'; unset AGENT_ID; rm -f "$R/.work/$JOB/.stop-blocks"
contains "interactive: waiting for background agents is allowed" "$(hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\"}")" "rc=0"
# a card in review whose QA or review agent is already at work (the user's report: three agents running, the guard said "do not stop")
bedit "$B" '.cards[2].state="review"'; rm -f "$R/.work/$JOB/.stop-blocks"
contains "interactive, a card in review and no agent at work: Michael is held (its QA/review is his to start)" "$(hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\"}")" "rc=2"
hook agent-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\",\"tool_input\":{\"subagent_type\":\"qa-tester\",\"run_in_background\":true}}" >/dev/null
contains "…an agent sent to work and not back yet: Michael may wait for it (it reports back on its own)" "$(hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\"}")" "rc=0"
printf '%s\tagent\tqa-tester a1: done\n' "$(date -u +%FT%TZ)" >> "$R/.work/$JOB/events.log"; rm -f "$R/.work/$JOB/.stop-blocks"
contains "…once it is back and the card waits on him, he is held again" "$(hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\"}")" "rc=2"
bedit "$B" '.cards[2].state="running"'; rm -f "$R/.work/$JOB/.stop-blocks"
contains "headless: Michael may not stop while agents run in the foreground flow" "$(DELIVER_HEADLESS=1 hook stop-guard.sh "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\"}")" "rc=2"
contains "agent-guard: headless background dispatch is denied" "$(DELIVER_HEADLESS=1 hook agent-guard.sh '{"tool_input":{"run_in_background":true,"subagent_type":"backend-dev"}}')" "rc=2"
contains "agent-guard: headless foreground dispatch is fine" "$(DELIVER_HEADLESS=1 hook agent-guard.sh '{"tool_input":{"run_in_background":false}}')" "rc=0"
contains "agent-guard: headless dispatch without an explicit false is denied (subagents default to background)" "$(DELIVER_HEADLESS=1 hook agent-guard.sh '{"tool_input":{"subagent_type":"business-analyst"}}')" "rc=2"
contains "agent-guard: headless with background tasks disabled lets any dispatch through (no background mode exists)" "$(DELIVER_HEADLESS=1 CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1 hook agent-guard.sh '{"tool_input":{"run_in_background":"false"}}')" "rc=0"
contains "agent-guard: the string \"false\" counts as foreground" "$(DELIVER_HEADLESS=1 hook agent-guard.sh '{"tool_input":{"run_in_background":"false"}}')" "rc=0"
contains "agent-guard: interactive background dispatch is fine" "$(hook agent-guard.sh '{"tool_input":{"run_in_background":true}}')" "rc=0"
"$DL" jobset '.settings.dispatch="subagent"'

bg() { hook bash-guard.sh "$(jq -n --arg c "$1" --arg cwd "${2:-$R}" --arg a "${3:-}" '{tool_input:{command:$c},cwd:$cwd} + (if $a!="" then {agent_id:$a} else {} end)')"; }
contains "push to main denied" "$(bg 'git push origin main')" "rc=2"
contains "push refspec to main denied" "$(bg 'git push origin job/x:main')" "rc=2"
contains "force push denied" "$(bg 'git push -f origin job/x')" "rc=2"
contains "job branch push allowed for Michael" "$(bg "git -C x push -u origin job/$JOB")" "rc=0"
contains "an agent outside a card worktree cannot push" "$(bg 'git push origin job/x--T-01' "$R" abc123)" "rc=2"
contains "Michael's own dl review is allowed with his shell inside a card worktree (seen live: refused before)" "$(bg 'dl review T-01 changes "x" --by reviewer' "$R/.work/$JOB/wt/T-01")" "rc=0"
contains "rm -rf .work denied" "$(bg 'rm -rf .work')" "rc=2"
W1="$R/.work/$JOB/wt/T-01"
contains "the main session (Michael / Claude itself, subagent mode) cannot reset a card worktree" "$(bg "git -C $W1 reset --hard 30388981")" "rc=2"
contains "…nor merge into one, even with its shell cd'ed inside" "$(bg "git merge job/$JOB" "$W1")" "rc=2"
contains "…nor commit in the integration worktree" "$(bg "cd $R/.work/$JOB/wt/_integration && git commit -qm x")" "rc=2"
PRP="$TMP/pushrepo"; mkdir -p "$PRP" && git -C "$PRP" init -q -b main && git -C "$PRP" commit -q --allow-empty -m i
git -C "$PRP" worktree add -q -b "job/JOB-x--T-01" "$PRP/.work/JOB-x/wt/T-01"
contains "a QA/dev subagent pushes its card branch with git -C <its worktree> (refused before: the shell's directory was used)" "$(bg "git -C $PRP/.work/JOB-x/wt/T-01 push origin job/JOB-x--T-01" "$PRP" abc123)" "rc=0"
contains "…but not another branch from there" "$(bg "git -C $PRP/.work/JOB-x/wt/T-01 push origin job/JOB-x--T-02" "$PRP" abc123)" "rc=2"
contains "…reading is fine (git log / status / diff)" "$(bg "git -C $W1 log --oneline")" "rc=0"
contains "the dev subagent commits in its own worktree" "$(bg "git commit -qm 'feat: x (T-01)'" "$W1" abc123)" "rc=0"
contains "git in the repo outside .work is not affected" "$(bg "git commit -qm x" "$R")" "rc=0"
contains "subagent dl integrate denied" "$(bg 'dl integrate T-01' "$R" abc123)" "rc=2"
contains "subagent dl status allowed" "$(bg 'dl status' "$R" abc123)" "rc=0"
contains "Michael dl gate allowed" "$(bg '/x/bin/dl gate T-01')" "rc=0"
contains "dl phase --force denied" "$(bg 'dl phase executing --force')" "rc=2"
contains "headless self-approval denied" "$(DELIVER_HEADLESS=1 bg 'dl approve plan ok')" "rc=2"
contains "subagent dl qa denied" "$(bg 'dl qa T-01 pass x' "$R" abc123)" "rc=2"
contains "the playbook's \"\$DL\" form is recognised: headless self-answer denied" "$(DELIVER_HEADLESS=1 bg '"$DL" clarify PRD-goal "yes"')" "rc=2"
contains "…and \${DL} with -C too" "$(DELIVER_HEADLESS=1 bg '${DL} -C /x approve plan ok')" "rc=2"
contains "a subagent calling \"\$DL\" gate is denied" "$(bg 'DL=/k/bin/dl; "$DL" gate T-01' "$R" abc123)" "rc=2"
PH="$(jq -r .phase "$R/.work/$(cat "$R/.work/ACTIVE" 2>/dev/null || echo none)/job.json" 2>/dev/null)"
contains "a script writing board.json once work has started is denied (phase ${PH:-?})" \
  "$(bg 'node -e "fs.writeFileSync(d+\"/board.json\", s)"')" "rc=2"
contains "…so is a redirect into job.json" "$(bg 'jq ".phase=\"done\"" a > .work/J/job.json')" "rc=2"
contains "…while reading them stays allowed" "$(bg 'jq .cards .work/J/board.json > /tmp/cards.json')" "rc=0"
out="$(DELIVER_HEADLESS=1 "$DL" reseal "x" 2>&1; echo "rc=$?")"
contains "dl itself refuses a human decision in an unattended session, whatever it is called by" "$out" "rc=8"
contains "interactive approval allowed" "$(bg 'dl approve plan "user said yes"')" "rc=0"
contains "unrelated commands allowed" "$(bg 'npm test -- --watch=false')" "rc=0"

wg() { hook write-guard.sh "$(jq -n --arg f "$1" --arg cwd "${2:-$R}" --arg a "${3:-}" --arg t "${4:-/dev/null}" '{tool_input:{file_path:$f},cwd:$cwd,transcript_path:$t} + (if $a!="" then {agent_id:$a} else {} end)')"; }
contains "dev may write in its card worktree" "$(wg "$R/.work/$JOB/wt/T-03/src/x.ts" "$R" a1)" "rc=0"
contains "dev may write its handoff" "$(wg "$R/.work/$JOB/handoffs/T-03.md" "$R" a1)" "rc=0"
contains "dev may not write the main checkout" "$(wg "$R/src/x.ts" "$R" a1)" "rc=2"
contains "dev may not write board.json" "$(wg "$R/.work/$JOB/board.json" "$R" a1)" "rc=2"
contains "dev may not write the integration worktree" "$(wg "$R/.work/$JOB/wt/_integration/src/x.ts" "$R" a1)" "rc=2"
ln -s "$R" "$TMP/repo-link"   # one repo, two spellings (macOS: /tmp → /private/tmp): the guard compares resolved paths
contains "dev may not write the main checkout through a symlinked path" "$(wg "$TMP/repo-link/src/x.ts" "$R" a1)" "rc=2"
contains "…nor a new file in a new folder there" "$(wg "$TMP/repo-link/src/new/y.ts" "$R" a1)" "rc=2"
contains "…while its card worktree stays writable that way" "$(wg "$TMP/repo-link/.work/$JOB/wt/T-03/src/x.ts" "$R" a1)" "rc=0"
contains "floor worker in its worktree may write there" "$(wg "$R/.work/$JOB/wt/T-03/a.ts" "$R/.work/$JOB/wt/T-03")" "rc=0"
contains "Michael may write plan.md" "$(wg "$R/.work/$JOB/plan.md" "$R" "" "$TR")" "rc=0"
contains "Michael may not write product code" "$(wg "$R/src/x.ts" "$R" "" "$TR")" "rc=2"
contains "other sessions are not restricted" "$(wg "$R/src/x.ts" "$R" "" /dev/null)" "rc=0"
contains "writes outside the repo are ignored" "$(wg "$TMP/elsewhere.txt" "$R" a1)" "rc=0"

out="$(printf '%s' "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\",\"agent_type\":\"backend-dev\",\"agent_id\":\"abcdef1234\",\"last_assistant_message\":\"status: done\\ncommit: 123\"}" | "$H/subagent-log.sh"; tail -1 "$R/.work/$JOB/events.log")"
contains "subagent-log appends the agent's summary, with its full id (what SendMessage needs)" "$out" "backend-dev abcdef1234: status: done commit: 123"
n0="$(wc -l < "$R/.work/$JOB/events.log")"
printf '%s' "{\"cwd\":\"$R\",\"transcript_path\":\"$TR\",\"agent_type\":\"\",\"agent_id\":\"abcdef1234\",\"last_assistant_message\":\"/deliver status\"}" | "$H/subagent-log.sh"
expect_ok "subagent-log skips Claude Code's own helper forks (no agent type)" test "$(wc -l < "$R/.work/$JOB/events.log")" -eq "$n0"

echo "munder difflin dispatch"
export HIVE_ROOT="$TMP/hive"; mkdir -p "$HIVE_ROOT"
"$DL" phase executing --force >/dev/null ; echo "do the card" > "$TMP/p.txt"
expect_ok "md-dispatch writes a spawn request" "$DL" md-dispatch T-03 "$TMP/p.txt"
reqf="$(ls "$HIVE_ROOT"/spawn-requests/*.json | head -1)"
contains "spawn request: card worktree cwd, no extra isolation, dev agent" "$(jq -c '{cwd,isolate,command}' "$reqf")" "\"isolate\":false,\"command\":\"claude --agent backend-dev\""
"$DL" jobset '.settings.munder.claude_command="/opt/bin/claude"'
jq '(.cards[] | select(.id=="T-03")).md_workers = []' "$R/.work/$JOB/board.json" > /dev/null
"$DL" md-dispatch T-03 "$TMP/p.txt" >/dev/null 2>&1 || true
contains "settings.munder.claude_command sets the workers' claude binary" "$(jq -r .command "$(grep -l "/opt/bin/claude" "$HIVE_ROOT"/spawn-requests/*.json | head -1)")" "/opt/bin/claude --agent backend-dev"
"$DL" jobset '.settings.munder.claude_command="claude"'
"$DL" jobset '(.roles[] | select(.role=="backend")) += {provider:"codex", model:"gpt-5-codex"}'
out="$("$DL" phase readiness --force 2>&1; node "$HERE/kit/skills/deliver/bin/roles.mjs" check "$R/.work/$JOB/job.json")"
contains "a non-Claude role needs dispatch munder" "$out" "runs on codex: non-Claude roles run as Munder Difflin floor workers"
"$DL" jobset '.settings.dispatch="munder"'; export AGENT_ID=god; "$DL" phase executing --force >/dev/null
jq '(.cards[] | select(.id=="T-03")).md_workers = []' "$R/.work/$JOB/board.json" > /dev/null
"$DL" md-dispatch T-03 "$TMP/p.txt" >/dev/null 2>&1 || true
reqc="$(grep -l "\"provider\": *\"codex\"" "$HIVE_ROOT"/spawn-requests/*.json | head -1)"
contains "codex worker: provider set, no claude --agent" "$(jq -c '{provider,command,model}' "$reqc")" '"provider":"codex","command":null,"model":"gpt-5-codex"'
jq -r .objective "$reqc" | gq "Your role instructions (backend-dev)" && jq -r .objective "$reqc" | gq "TDD with unit tests" \
  && ok "the agent definition's instructions travel inside the objective for non-Claude CLIs" || bad "agent body not embedded"
jq -r .objective "$reqc" | gq "^---$" && ! jq -r .objective "$reqc" | gq "^tools: " && ok "…without Claude frontmatter" || bad "frontmatter leaked"
"$DL" jobset '(.roles[] | select(.role=="backend")) |= del(.provider, .model) | .settings.dispatch="subagent"'
unset HIVE_ROOT AGENT_ID

echo "munder difflin seats: one person per role seat, work orders, no subagents for Michael"
export HIVE_ROOT="$TMP/hive-seats"; mkdir -p "$HIVE_ROOT"
echo '{"godId":"god","agents":{"god":{"id":"god","isGod":true,"status":"idle"}}}' > "$HIVE_ROOT/registry.json"
"$DL" jobset '.settings.dispatch="munder"' >/dev/null; export AGENT_ID=god
nseat="$(jq '[.roles[] | select(.agent != "artemis") | (.count // 1)] | add' "$R/.work/$JOB/job.json")"
expect_ok "md-hire seats every role seat" "$DL" md-hire
"$DL" roles >/dev/null
[[ ! -e $R/.work/$JOB/munder/hires && ! -e $HIVE_ROOT/research/hires ]] && ok "no hire manifests that would need a click in the app" || bad "hire manifests written"
contains "ROLES.md tells Michael the roles are people he seats" "$(cat "$R/.work/$JOB/ROLES.md")" "dl md-hire"
[[ "$(ls "$HIVE_ROOT"/spawn-requests/seat-*.json | wc -l | tr -d " ")" == "$nseat" ]] && ok "one spawn request per seat ($nseat) — every selected role, count seats each" || bad "seat requests: $(ls "$HIVE_ROOT"/spawn-requests)"
sreq="$(ls "$HIVE_ROOT"/spawn-requests/seat-*-backend-1-h1.json)"
contains "a seat is a plain claude in the repo, no --agent, no isolation" "$(jq -c '{command,cwd,isolate}' "$sreq")" "{\"command\":\"claude\",\"cwd\":\"$R\",\"isolate\":false}"
contains "…its charter: stay for the job, report each task, done only on release" "$(jq -r .objective "$sreq")" 'only when Michael sends you the release message'
[[ "$(jq -r '[.munder.seats[].character] | (length == (unique | length))' "$R/.work/$JOB/job.json")" == true ]] && ok "every person on the floor has a face of their own" || bad "duplicate characters: $(jq -c '.munder.seats' "$R/.work/$JOB/job.json")"
contains "a seat not on the floor yet is pending" "$("$DL" md-seats)" "pending"
expect_ok "md-hire again does not hire twice" "$DL" md-hire
[[ "$(ls "$HIVE_ROOT"/spawn-requests/seat-*.json | wc -l | tr -d " ")" == "$nseat" ]] && ok "…same requests" || bad "hired twice"
# Munder Difflin consumes the requests: workers on the floor (registry), requests archived to .done
mkdir -p "$HIVE_ROOT/spawn-requests/.done"
for f in "$HIVE_ROOT"/spawn-requests/seat-*.json; do w="worker-$(basename "$f" .json)"; mv "$f" "$HIVE_ROOT/spawn-requests/.done/"
  jq --arg w "$w" '.agents[$w] = {id:$w, role:"worker", status:"idle"}' "$HIVE_ROOT/registry.json" > "$TMP/reg" && mv "$TMP/reg" "$HIVE_ROOT/registry.json"; done
contains "on the floor but silent: starting, not live (the registry alone proves nothing)" "$("$DL" md-seats)" "starting"
contains "…and gets no order yet" "$("$DL" md-send backend#1 T-03 "$TMP/p.txt" 2>&1)" "not seated yet"
# a message from the worker in the hive log also counts as "seated" (the router logs every delivery)
w1s="$(jq -r '.munder.seats["ba#1"].worker' "$R/.work/$JOB/job.json")"
jq -cn --arg w "$w1s" '{ts:0, kind:"message", from:$w, to:"god", act:"inform", subject:"hello"}' >> "$HIVE_ROOT/log.jsonl"
grep -qE "^ba#1 +live" <<<"$("$DL" md-seats)" && ok "a worker's first message in the hive log seats it (any subject)" || bad "log seated: $("$DL" md-seats | head -3)"
# each worker says "seated" (its outbox; the router moves it to .sent)
for w in $(jq -r '.munder.seats[].worker' "$R/.work/$JOB/job.json"); do mkdir -p "$HIVE_ROOT/agents/$w/outbox/.sent"
  jq -n --arg w "$w" '{from:$w, to:"god", act:"inform", subject:"seated", body:"ready"}' > "$HIVE_ROOT/agents/$w/outbox/.sent/s1.json"; done
out="$("$DL" md-seats)"; [[ $out != *pending* && $out != *starting* && $out == *live* && $out != *"not seated"* ]] && ok "md-seats: everyone said seated — live" || bad "md-seats: $out"
contains "every seat gets an explicit model — never the app's default (kit default sonnet)" "$(jq -c '[.model]' "$HIVE_ROOT/spawn-requests/.done/$(basename "$sreq")")" '["sonnet"]'
echo "Build T-03 test-first." > "$TMP/order.md"
out="$("$DL" md-seats)"; [[ $out != *pending* && $out != *starting* && $out == *live* && $out != *"not seated"* ]] && ok "md-seats: everyone is at their desk" || bad "md-seats: $out"
out="$("$DL" md-send backend T-03 "$TMP/order.md" 2>&1)"; contains "md-send gives a running card to its role's seat" "$out" "T-03 → backend#1"
ord="$(ls "$HIVE_ROOT"/agents/god/outbox/*.json | head -1)"
contains "the order goes from Michael's outbox to that seat's worker" "$(jq -c '{to:(.to|startswith("worker-seat-")),act}' "$ord")" '{"to":true,"act":"request"}'
body="$(jq -r .body "$ord")"
[[ $body == *"## Your role card"* && $body == *"Role: backend"* && $body == *"## Instructions for this task — backend-dev"* && $body == *"TDD with unit tests"* && $body == *"Build T-03 test-first."* && $body == *"Work in: $R/.work/$JOB/wt/T-03"* ]] \
  && ok "…carrying the role card, the agent's instructions, the task and the card worktree" || bad "order body: ${body:0:400}"
contains "a busy seat takes no second order" "$("$DL" md-send backend#1 T-03 "$TMP/order.md" 2>&1)" "busy with T-03"
contains "the card records which seat worked on it" "$(jq -c '[.cards[] | select(.id=="T-03") | .md_workers[-1] | {role,seat}]' "$R/.work/$JOB/board.json")" '{"role":"backend","seat":"backend#1"}'
expect_ok "md-done records the seat's report" "$DL" md-done backend#1 "T-03 built, 4 unit tests, commit abc123"
contains "…in the event log" "$(tail -1 "$R/.work/$JOB/events.log")" "md-done	T-03 backend#1: T-03 built"
echo "Write the readiness review." > "$TMP/ba.md"
out="$("$DL" md-send ba readiness "$TMP/ba.md" --agent business-analyst 2>&1)"; contains "plan steps go to a seat too (BA: readiness)" "$out" "readiness → ba#1"
bao="$(jq -r .body "$(ls -t "$HIVE_ROOT"/agents/god/outbox/*.json | head -1)")"
contains "…working in the repo" "$bao" "Work in: $R"
contains "…the order names the one answer file (md-done checks it)" "$bao" "Your answer goes to exactly one file: $R/.work/$JOB/out/readiness-ba.md (or $R/.work/$JOB/out/readiness-ba.json"
contains "…and md-send prints it" "$out" "answer: $R/.work/$JOB/out/readiness-ba.md|.json"
[[ $body != *"Your answer goes to exactly one file"* ]] && ok "a dev's order names no answer file (the commits are the work)" || bad "dev order names an answer file"
n0="$(ls "$HIVE_ROOT"/agents/god/outbox/*.json | wc -l)"
out="$("$DL" md-done ba#1 "readiness written" 2>&1)"; rc=$?
[[ $rc != 0 && $out == *"ba#1's done for readiness is not accepted: $R/.work/$JOB/out/readiness-ba.md (or .json) does not exist"* ]] \
  && ok "md-done refuses a done whose answer file is not there (run 53: the write was refused, done was sent)" || bad "md-done without file: rc=$rc $out"
contains "…the seat is told, in the task's conversation" "$(jq -c '{s:.subject, c:.conversation}' "$(ls -t "$HIVE_ROOT"/agents/god/outbox/*.json | head -1)")" "{\"s\":\"readiness — your done is not accepted\",\"c\":\"deliver-$JOB-readiness\"}"
contains "…and keeps the task" "$(jq -r '.munder.seats["ba#1"].task' "$R/.work/$JOB/job.json")" "readiness"
contains "…logged" "$(tail -1 "$R/.work/$JOB/events.log")" "md-done-refused	readiness ba#1"
echo '{"items": [' > "$R/.work/$JOB/out/readiness-ba.json"
contains "an answer that is not valid JSON is refused too" "$("$DL" md-done ba#1 "readiness written" 2>&1)" "readiness-ba.json is not valid JSON"
echo '{"items": []}' > "$R/.work/$JOB/out/readiness-ba.json"
out="$("$DL" md-done ba#1 "readiness written" 2>&1)"; contains "with the file there, md-done records it and prints the file" "$out" "ba#1 is free (readiness done) — answer: $R/.work/$JOB/out/readiness-ba.json"
"$DL" md-send ba readiness "$TMP/ba.md" >/dev/null 2>&1
[[ ! -e $R/.work/$JOB/out/readiness-ba.json && -n "$(ls "$R/.work/$JOB/out/.prev/" | grep '^readiness-ba.json.')" ]] \
  && ok "a new order for the same task moves the earlier answer aside — never taken for the new one" || bad "stale answer: $(ls -a "$R/.work/$JOB/out" "$R/.work/$JOB/out/.prev" 2>&1)"
contains "…so a done without a new answer is refused" "$("$DL" md-done ba#1 "again" 2>&1)" "is not accepted"
echo "# readiness" > "$R/.work/$JOB/out/readiness-ba.md"; "$DL" md-done ba#1 "again" >/dev/null
# A seat reaped by the floor is noticed and re-seated
w1="$(jq -r '.munder.seats["backend#1"].worker' "$R/.work/$JOB/job.json")"
jq --arg w "$w1" '.agents[$w].status = "gone"' "$HIVE_ROOT/registry.json" > "$TMP/reg" && mv "$TMP/reg" "$HIVE_ROOT/registry.json"
contains "a reaped seat shows as not seated" "$("$DL" md-seats)" "not seated: backend#1"
contains "…and sends no order into the void" "$("$DL" md-send backend#1 T-03 "$TMP/order.md" 2>&1)" "no one at the desk"
"$DL" md-hire >/dev/null; contains "md-hire re-seats only that seat, same face" "$(ls "$HIVE_ROOT"/spawn-requests/*.json | xargs -n1 basename)" "backend-1-h2.json"
contains "…logged as a re-seat" "$(grep md-hire "$R/.work/$JOB/events.log" | tail -1)" "re-seated, was gone"
# A seat that fails is seen, with the reason — never called live
seat_w() { jq -r --arg s "$1" '.munder.seats[$s].worker' "$R/.work/$JOB/job.json"; }
on_floor() { local w; w="$(seat_w "$1")"; mv "$HIVE_ROOT/spawn-requests/${w#worker-}.json" "$HIVE_ROOT/spawn-requests/.done/" 2>/dev/null
  jq --arg w "$w" --arg sid "${2:-}" '.agents[$w] = {id:$w, role:"worker", status:"idle"} + (if $sid != "" then {sessionId:$sid} else {} end)' "$HIVE_ROOT/registry.json" > "$TMP/reg" && mv "$TMP/reg" "$HIVE_ROOT/registry.json"; }
on_floor backend#1
mkdir -p "$HIVE_ROOT/crashes"; printf 'agent: x\n--- tail ---\n\033[31mError: Invalid API key · Please run /login\033[0m\n\n' > "$HIVE_ROOT/crashes/c1.log"
jq -nc --arg w "$(seat_w backend#1)" --arg tp "$HIVE_ROOT/crashes/c1.log" '{ts:1, kind:"agent-exit", agentId:$w, exitCode:1, signal:null, abnormal:true, tailPath:$tp}' >> "$HIVE_ROOT/log.jsonl"
out="$("$DL" md-seats)"; contains "a worker that died at startup is failed, not live (hive log agent-exit)" "$out" "FAILED   backend#1: its process died (exit 1)"
contains "…with the last thing it printed" "$out" "last output: Error: Invalid API key · Please run /login"
contains "…and md-seats says how to recover" "$out" "dl md-reseat"
contains "…and md-send names the failure" "$("$DL" md-send backend#1 T-03 "$TMP/order.md" 2>&1)" "backend#1 failed: its process died"
# out of credit: the worker runs, but its last Claude reply is an API error
mkdir -p "$HOME/.claude/projects/p"; QAW="$(seat_w qa#1)"
jq --arg w "$QAW" '.agents[$w].sessionId = "sess-qa"' "$HIVE_ROOT/registry.json" > "$TMP/reg" && mv "$TMP/reg" "$HIVE_ROOT/registry.json"
{ echo '{"type":"assistant","message":{"model":"claude-x","content":[{"type":"text","text":"ok"}]}}'
  echo '{"type":"assistant","isApiErrorMessage":true,"message":{"model":"<synthetic>","content":[{"type":"text","text":"Credit balance is too low"}]}}'; } > "$HOME/.claude/projects/p/sess-qa.jsonl"
contains "a seat whose last reply is an API error (credit) is failed, with the error" "$("$DL" md-seats)" "FAILED   qa#1: its last Claude reply is an API error: Credit balance is too low"
echo '{"type":"assistant","message":{"model":"claude-x","content":[{"type":"text","text":"retried fine"}]}}' >> "$HOME/.claude/projects/p/sess-qa.jsonl"
[[ "$("$DL" md-seats)" != *"FAILED   qa#1"* ]] && ok "…an error it recovered from is not a failure" || bad "recovered seat still failed"
# no "seated" within the timeout
"$DL" jobset '.settings.munder.seat_timeout_minutes = 0' >/dev/null
RW="$(jq -r '.munder.seats | to_entries[] | select(.key | startswith("reviewer")) | .value.worker' "$R/.work/$JOB/job.json" | head -1)"; RS="$(jq -r '.munder.seats | to_entries[] | select(.key | startswith("reviewer")) | .key' "$R/.work/$JOB/job.json" | head -1)"
rm -f "$HIVE_ROOT/agents/$RW/outbox/.sent/s1.json"
contains "a seat silent past munder.seat_timeout_minutes is failed" "$("$DL" md-seats)" "FAILED   $RS: no \"seated\" message"
"$DL" jobset '.settings.munder.seat_timeout_minutes = 5 | .settings.munder.seat_timeout = 0' >/dev/null
contains "…also by the older munder.seat_timeout (seconds)" "$("$DL" md-seats)" "FAILED   $RS: no \"seated\" message"
"$DL" jobset 'del(.settings.munder.seat_timeout)' >/dev/null
mkdir -p "$HIVE_ROOT/agents/$RW/outbox/.sent"; jq -n --arg w "$RW" '{from:$w, subject:"seated"}' > "$HIVE_ROOT/agents/$RW/outbox/.sent/s1.json"
# the app rejects a request
w2="$(seat_w backend#1)"
# re-seat the crashed one on another model: old one withdrawn, a new person hired with that model, a PM decision recorded
out="$("$DL" md-reseat backend#1 "died at startup: invalid API key" --model haiku 2>&1)"
contains "md-reseat hires a new person for the seat" "$out" "backend#1"
nreq="$(ls "$HIVE_ROOT"/spawn-requests/*backend-1-h3.json 2>/dev/null | head -1)"
[[ -n $nreq ]] && contains "…on the model it was given" "$(jq -c '{model}' "$nreq")" '{"model":"haiku"}' || bad "no h3 request: $(ls "$HIVE_ROOT"/spawn-requests)"
contains "…logged with the reason" "$(grep $'\tmd-reseat\t' "$R/.work/$JOB/events.log" | tail -1)" "backend#1 (failed): died at startup: invalid API key → model haiku"
contains "…as Michael's decision for the PR" "$(jq -r '.pm_decisions[-1].what' "$R/.work/$JOB/job.json")" "re-seated backend#1 on haiku"
contains "the new person is starting, not live" "$("$DL" md-seats)" "backend#1"
mv "$nreq" "$HIVE_ROOT/spawn-requests/.failed/" 2>/dev/null || { mkdir -p "$HIVE_ROOT/spawn-requests/.failed"; mv "$nreq" "$HIVE_ROOT/spawn-requests/.failed/"; }
contains "a request the app rejected is failed" "$("$DL" md-seats)" "FAILED   backend#1: the app rejected the spawn request"
contains "md-reseat needs a reason" "$("$DL" md-reseat backend#1 2>&1)" "usage: dl md-reseat"
# a stuck live seat: re-seated, the old person is sent home
n0="$(ls "$HIVE_ROOT"/agents/god/outbox/*.json | wc -l)"; "$DL" md-reseat "$RS" "stuck: no answer for 20 min" >/dev/null
contains "re-seating a live seat sends the old person home" "$(jq -r .subject "$(ls -t "$HIVE_ROOT"/agents/god/outbox/*.json | head -1)")" "release — your seat is re-seated"
[[ "$(jq -r --arg s "$RS" '.munder.seats[$s].worker' "$R/.work/$JOB/job.json")" != "$RW" ]] && ok "…and a new worker takes the seat" || bad "same worker"
# the floor recorded why it could not start the worker (Munder Difflin: registry lastError)
LW="$(seat_w ba#1)"; jq --arg w "$LW" '.agents[$w].lastError = "failed to start: no usage left for its model — \"You are out of usage credits.\""' "$HIVE_ROOT/registry.json" > "$TMP/reg" && mv "$TMP/reg" "$HIVE_ROOT/registry.json"
contains "a worker the floor could not start is failed, with the floor's reason (lastError)" "$("$DL" md-seats)" "FAILED   ba#1: the floor says: failed to start: no usage left for its model"
jq --arg w "$LW" 'del(.agents[$w].lastError)' "$HIVE_ROOT/registry.json" > "$TMP/reg" && mv "$TMP/reg" "$HIVE_ROOT/registry.json"
# more seats than the floor runs at once: said, not left pending without a word
echo '{"workerCap":2,"agents":[]}' > "$HIVE_ROOT/fleet.json"
contains "md-seats notes when the job has more seats than the floor's worker cap" "$("$DL" md-seats 2>&1)" "the floor runs at most 2 workers at once"
rm -f "$HIVE_ROOT/fleet.json"
# Outside the app (no HIVE_ROOT from Munder Difflin) a live Michael on the floor would drive the same job: run it from his seat
"$DL" jobset ".settings.munder.hive_root=\"$HIVE_ROOT\"" >/dev/null
out="$(env -u HIVE_ROOT -u AGENT_ID "$DL" md-seats 2>&1)"; contains "outside the app, the floor's Michael is not raced for his inbox" "$out" "REFUSED — Michael (god) has a seat on the floor"
contains "…the refusal says where to run it" "$out" "\"/deliver resume\" with REPO: $R"
expect_ok "Michael's own seat (AGENT_ID=god) uses the configured hive" env -u HIVE_ROOT AGENT_ID=god "$DL" md-seats
jq '.agents.god.archived = true' "$HIVE_ROOT/registry.json" > "$TMP/reg" && mv "$TMP/reg" "$HIVE_ROOT/registry.json"
expect_ok "…and with no Michael on the floor the configured hive is usable from outside" env -u HIVE_ROOT -u AGENT_ID "$DL" md-seats
jq '.agents.god.archived = false' "$HIVE_ROOT/registry.json" > "$TMP/reg" && mv "$TMP/reg" "$HIVE_ROOT/registry.json"
contains "md-hire does not re-hire a failed seat blindly (same model, same failure)" "$("$DL" md-hire)" "→ dl md-reseat backend#1"
expect_ok "md-hire --reseat <seat> is md-reseat (the other branch's spelling)" "$DL" md-hire --reseat backend#1 "the app rejected the request"
contains "…logged as a re-seat on request" "$(grep $'\tmd-reseat\t' "$R/.work/$JOB/events.log" | tail -1)" "backend#1 (failed): the app rejected the request"
# put everyone back on the floor for what follows
for s in backend#1 "$RS"; do on_floor "$s"; w="$(seat_w "$s")"; mkdir -p "$HIVE_ROOT/agents/$w/outbox/.sent"; jq -n --arg w "$w" '{from:$w, subject:"seated"}' > "$HIVE_ROOT/agents/$w/outbox/.sent/s1.json"; done
rm -f "$HOME/.claude/projects/p/sess-qa.jsonl"
# Michael's inbox: each message shown once, archived exactly; a report archived unread is still found
GI="$HIVE_ROOT/agents/god/inbox"; mkdir -p "$GI"; wq="$(jq -r '.munder.seats["qa#1"].worker' "$R/.work/$JOB/job.json")"
echo "Test T-03." > "$TMP/qa.md"; "$DL" jobset '.settings.dispatch="munder"' >/dev/null
jq --arg w "$wq" '.agents[$w].status = "idle"' "$HIVE_ROOT/registry.json" > "$TMP/reg" && mv "$TMP/reg" "$HIVE_ROOT/registry.json"
"$DL" md-send qa#1 T-03 "$TMP/qa.md" >/dev/null 2>&1 || "$DL" md-send qa#1 plan-check "$TMP/qa.md" >/dev/null
qtask="$(jq -r '.munder.seats["qa#1"].task' "$R/.work/$JOB/job.json")"
jq -n --arg w "$wq" --arg t "$qtask" '{id:"m1", from:$w, act:"inform", subject:("done " + $t + " qa#1"), body:"6/6 integration tests pass", created_at:"2999-01-01T00:00:00.000Z"}' > "$GI/m1.json"
out="$("$DL" md-inbox)"; contains "md-inbox shows a report with the sender as its seat" "$out" "qa#1 · inform · done $qtask qa#1"
[[ ! -e $GI/m1.json && -f $GI/.done/m1.json ]] && ok "…and archives exactly what it showed" || bad "inbox archive"
contains "a report archived without md-done is flagged as unrecorded" "$("$DL" md-inbox)" "UNRECORDED  qa#1 reported \"done $qtask\""
echo "6/6 pass" > "$(jq -r '.munder.seats["qa#1"].out' "$R/.work/$JOB/job.json").md"
"$DL" md-done qa#1 "6/6" >/dev/null; contains "…until it is recorded" "$("$DL" md-inbox)" "(no new messages)"
contains "md-wait with no open task and an empty inbox does not wait" "$("$DL" md-wait 5)" "nothing to wait for"
"$DL" md-send qa#1 plan-check "$TMP/qa.md" >/dev/null 2>&1
( sleep 2; jq -n --arg w "$wq" '{id:"m2", from:$w, act:"inform", subject:"done plan-check qa#1", body:"ok", created_at:"2999-01-01T00:00:01.000Z"}' > "$GI/.m2.tmp" && mv "$GI/.m2.tmp" "$GI/m2.json" ) &
t0=$SECONDS; out="$("$DL" md-wait 30)"; dt=$((SECONDS - t0)); wait
[[ $out == *"done plan-check qa#1"* && $dt -lt 10 ]] && ok "md-wait returns as a message arrives and shows it (${dt}s)" || bad "md-wait: ${dt}s $out"
contains "…a timed-out wait says so" "$("$DL" md-wait 1)" "(waited 1s — run dl md-wait again)"
echo ok > "$(jq -r '.munder.seats["qa#1"].out' "$R/.work/$JOB/job.json").md"; "$DL" md-done qa#1 "ok" >/dev/null
nlive="$("$DL" md-seats | grep -cE '^[^ ]+ +(live|starting) ')"
n0="$(ls "$HIVE_ROOT"/agents/god/outbox/*.json | wc -l)"; "$DL" md-release >/dev/null
[[ $nlive == "$nseat" && $(( $(ls "$HIVE_ROOT"/agents/god/outbox/*.json | wc -l) - n0 )) == "$nlive" ]] && ok "md-release sends every live seat home" || bad "release orders"
n1="$(ls "$HIVE_ROOT"/agents/god/outbox/*.json | wc -l)"; out="$("$DL" md-release)"
[[ $out == "released 0 seat(s)" && "$(ls "$HIVE_ROOT"/agents/god/outbox/*.json | wc -l)" == "$n1" ]] && ok "…once: a second md-release sends nobody home twice (seen live with parallel calls)" || bad "second release: $out"
# Guards: Michael on the floor has no Agent tool; seats are agents (their own lanes, no flow commands)
ag() { hook agent-guard.sh '{"tool_input":{"subagent_type":"backend-dev","run_in_background":true}}'; }
contains "Michael on the floor may not start subagents" "$(AGENT_ID=god ag)" "rc=2"
contains "…the message names md-send" "$(AGENT_ID=god ag)" "md-send"
contains "a seat may use subagents for its own work" "$(AGENT_ID=worker-seat-x ag)" "rc=0"
contains "outside the floor nothing changes" "$(unset AGENT_ID; ag)" "rc=0"
contains "a seat is not mistaken for Michael: it may write in a card worktree" "$(AGENT_ID=worker-seat-x wg "$R/.work/$JOB/wt/T-03/src/a.ts" "$R" "" "$TR")" "rc=0"
contains "…where Michael (god) may not" "$(AGENT_ID=god wg "$R/.work/$JOB/wt/T-03/src/a.ts" "$R" "" "$TR")" "rc=2"
contains "a seat may write its analysis to out/" "$(AGENT_ID=worker-seat-x wg "$R/.work/$JOB/out/readiness.json" "$R" "" "$TR")" "rc=0"
contains "a seat may not write the main checkout, even with the job in its transcript" "$(AGENT_ID=worker-seat-x wg "$R/src/x.ts" "$R" "" "$TR")" "rc=2"
contains "a seat may not write board.json" "$(AGENT_ID=worker-seat-x wg "$R/.work/$JOB/board.json" "$R" "" "$TR")" "rc=2"
contains "Michael may not move his inbox files (md-inbox reads them)" "$(AGENT_ID=god bg 'H=/h; mv $H/agents/god/inbox/*.json $H/agents/god/inbox/.done/')" "rc=2"
contains "…reading them is fine" "$(AGENT_ID=god bg 'cat /h/agents/god/inbox/*.json')" "rc=0"
contains "Michael may not poll his inbox with a loop of his own (md-wait)" "$(AGENT_ID=god bg 'I=/h/agents/god/inbox; for i in $(seq 1 55); do n=$(ls $I | wc -l); [ $n -gt 0 ] && break; sleep 10; done')" "rc=2"
contains "nobody searches the whole disk (run 53: find / ran into the 2-minute timeout)" "$(AGENT_ID=god bg "find / -name 'readiness-ba.json' 2>/dev/null")" "rc=2"
contains "…also spelled find -L /* or find \"/\"" "$(AGENT_ID=worker-seat-x bg 'find -L "/" -name x; find /* -name y')" "rc=2"
contains "…a search of a named directory is fine" "$(AGENT_ID=god bg 'ls /; find /tmp/job/out -name x')" "rc=0"
contains "…and a seat still files its own inbox" "$(AGENT_ID=worker-seat-x bg 'mv inbox/m1.json inbox/.done/')" "rc=0"
contains "a seat may not hand out work orders" "$(AGENT_ID=worker-seat-x bg '"$DL" md-send backend T-03 o.md')" "rc=2"
contains "…nor record decisions" "$(AGENT_ID=worker-seat-x bg '"$DL" pm-decide x y')" "rc=2"
contains "a seat may not run flow commands" "$(AGENT_ID=worker-seat-x bg "\"\$DL\" qa T-03 pass")" "rc=2"
contains "Michael (god) still writes the job's files" "$(AGENT_ID=god wg "$R/.work/$JOB/plan.md" "$R" "" "$TR")" "rc=0"
# A floor job is driven only by the app's Michael: a second Michael in a plain terminal would read the same inbox
contains "outside the app, a floor job's flow is refused" "$(env -u AGENT_ID "$DL" md-inbox 2>&1)" "Hand it to Michael in the app: dl floor-open"
contains "…the refusal says how to switch to subagents by hand" "$(env -u AGENT_ID "$DL" phase executing 2>&1)" '/deliver:mode subagent <why>'
expect_ok "…while the human can still read and answer from any terminal (status, md-seats)" env -u AGENT_ID "$DL" status
expect_ok "…md-seats" env -u AGENT_ID "$DL" md-seats
contains "a seat cannot run the flow through dl either" "$(AGENT_ID=worker-seat-x "$DL" md-hire 2>&1)" "a seat does not run the flow"
contains "switching modes is the human's call (bash-guard)" "$(AGENT_ID=god bg '"$DL" dispatch subagent "x"')" "rc=2"
contains "dl dispatch is refused in an unattended session" "$(DELIVER_HEADLESS=1 "$DL" dispatch subagent "x" 2>&1)" "the human's decision"
NF="$TMP/newfloor"; mkdir -p "$NF" && (cd "$NF" && git init -q -b main && echo x > a && git add -A && git commit -qm i)
contains "Munder Difflin is the default: dl new outside the app is refused" "$(cd "$NF" && env -u AGENT_ID "$DL" new "t" "r" 2>&1)" "dispatch: munder, the default"
expect_ok "…and opened by the app's Michael" bash -c "cd '$NF' && AGENT_ID=god '$DL' new t r"
contains "…as a floor job" "$(jq -r .settings.dispatch "$NF/.work/$(cat "$NF/.work/ACTIVE")/job.json")" "munder"
(cd "$NF" && git rm -q --cached a >/dev/null; rm -rf .work; echo '{"dispatch":"subagent"}' > .deliver.json)
expect_ok "subagents are an explicit choice: \"dispatch\": \"subagent\" in .deliver.json, dl new from any terminal" bash -c "cd '$NF' && env -u AGENT_ID '$DL' new t2 r2"
# /deliver typed in a terminal for a floor repo: dl floor-open opens the app on the repo's floor and hands Michael the job
FO="$TMP/floorrepo"; FH="$TMP/floorhome"; FX="$TMP/fakehome"; mkdir -p "$FO" "$FX" && (cd "$FO" && git init -q -b main && echo x > a && git add -A && git commit -qm i)
jq -n --arg h "$FH" --arg c "touch '$TMP/app-started'" '{munder:{hive_root:$h, app_command:$c}}' > "$FO/.deliver.json"
out="$(cd "$FO" && HOME="$FX" XDG_CONFIG_HOME="$FX/.config" env -u AGENT_ID "$DL" floor-open "examples/JOB.md" 2>&1)"
contains "floor-open: the app is started on the repo's floor" "$out" "Munder Difflin is starting on $FH"
for i in 1 2 3 4 5 6 7 8 9 10; do [[ -f $TMP/app-started ]] && break; sleep 0.3; done
[[ -f $TMP/app-started ]] && ok "…with munder.app_command" || bad "app command not run"
contains "…aimed at that floor (the app's harnessHome) with the repo registered" "$(jq -c '{harnessHome, r:(.registeredRepos|length), s:.orchestratorMaySpawn}' "$FX/.config/munder-difflin/config.json")" "{\"harnessHome\":\"$FH\",\"r\":1,\"s\":true}"
grep -q "deliver:begin" "$FH/CLAUDE.md" && ok "…Michael is taught /deliver there (the brief ships in the plugin)" || bad "no brief in $FH"
msg="$(ls "$FH"/hive/agents/god/inbox/*.json 2>/dev/null | head -1)"
contains "…and the job is in Michael's inbox as the human's request, with the repo" "$(jq -c '{from,to,act,b:.body}' "$msg" 2>/dev/null)" "{\"from\":\"human\",\"to\":\"god\",\"act\":\"request\",\"b\":\"/deliver examples/JOB.md\\nREPO: $FO\"}"
mkdir -p "$FH/hive"; jq -n --argjson t "$(( $(date +%s) * 1000 ))" '{godId:"god", agents:{god:{lastSeen:$t}}}' > "$FH/hive/registry.json"; rm -f "$TMP/app-started"
out="$(cd "$FO" && HOME="$FX" XDG_CONFIG_HOME="$FX/.config" env -u AGENT_ID "$DL" floor-open "again" 2>&1)"
[[ $out == *"is open on $FH"* && ! -f $TMP/app-started ]] && ok "an app already open on that floor is not started twice — the job just goes to Michael" || bad "floor-open with app running: $out"
jq '.harnessHome = "/elsewhere"' "$FX/.config/munder-difflin/config.json" > "$TMP/c" && mv "$TMP/c" "$FX/.config/munder-difflin/config.json"
contains "an app open on another floor is not hijacked" "$(cd "$FO" && HOME="$FX" XDG_CONFIG_HOME="$FX/.config" env -u AGENT_ID "$DL" floor-open "x" 2>&1)" "open on another floor (/elsewhere)"
contains "floor-open names the human's slash commands, not dl (a plugin puts no dl on the user's PATH — seen on a user's machine)" "$out" "/deliver:status · /deliver:board · /deliver:seats"
out="$(cd "$FO" && env -u AGENT_ID "$DL" status 2>&1)"
contains "dl status before Michael started: the request waiting on the floor, not \"no active job\"" "$out" "no job yet — the request went to Michael on the floor $FH"
contains "…and what starts it" "$out" "click Open once"
[[ -f $FO/.work/FLOOR-PENDING && "$(git -C "$FO" status --porcelain)" != *.work* ]] && ok "…its record (.work/FLOOR-PENDING) stays out of git" || bad "floor-open left: $(git -C "$FO" status --porcelain)"
# the first /deliver in a floor repo with no .deliver.json writes it, read from the repo, with the floor it opens
FN="$TMP/floornew"; FX2="$TMP/fakehome2"; FH2="$TMP/floorhome2"; mkdir -p "$FN" "$FX2/.config/munder-difflin" "$FX2/.deliver"
(cd "$FN" && git init -q -b main && echo '{"scripts":{"test":"node --test"}}' > package.json && git add -A && git commit -qm i)
jq -n --arg h "$FH2" '{harnessHome:$h}' > "$FX2/.config/munder-difflin/config.json"
jq -n --arg c "true" '{munder:{app_command:$c}}' > "$FX2/.deliver/config.json"
out="$(cd "$FN" && HOME="$FX2" XDG_CONFIG_HOME="$FX2/.config" DELIVER_HOME="$FX2/.deliver" env -u AGENT_ID "$DL" floor-open "x" 2>&1)"
contains "floor-open in a repo without .deliver.json writes it from the repo" "$out" "verify_full: npm test — package.json scripts test"
contains "…with the floor it opened as munder.hive_root, and no install step for a package.json without dependencies" "$(jq -c '{d:.dispatch,h:.munder.hive_root,s:.worktree_setup}' "$FN/.deliver.json")" "{\"d\":\"munder\",\"h\":\"$FH2\",\"s\":\"\"}"

# The project's config file: the first /deliver writes a complete .deliver.json; its per-role defaults reach the job
PC="$TMP/projcfg"; mkdir -p "$PC" && (cd "$PC" && git init -q -b main && echo '{"scripts":{"test":"node --test"}}' > package.json && git add -A && git commit -qm i)
out="$(cd "$PC" && AGENT_ID=god "$DL" new t r 2>&1)"; contains "the first /deliver in a repo writes its config file" "$out" "created $PC/.deliver.json"
contains "…complete: run mode, verify, merge mode, roles, the floor, with its schema" "$(jq -c '{d:.dispatch,v:.verify_full,m:.merge_mode,r:.roles,mm:.munder.model,s:(."$schema"|endswith("deliver.schema.json"))}' "$PC/.deliver.json")" '{"d":"munder","v":"npm test","m":"local","r":{},"mm":"sonnet","s":true}'
contains "…and says where each value came from" "$out" "verify_full: npm test — package.json scripts test"
# What goes into .deliver.json is what the repo says, never a guess (detect.mjs)
DT="$HERE/kit/skills/deliver/bin/detect.mjs"; DR="$TMP/detect"; mkdir -p "$DR"
det() { node "$DT" "$DR/$1" | jq -c "$2"; }
mkdir -p "$DR/placeholder" && echo '{"scripts":{"test":"echo \"Error: no test specified\" && exit 1"}}' > "$DR/placeholder/package.json"
contains "npm's placeholder test script is not a test suite: verify_full stays empty" "$(det placeholder '{v:.verify_full,e:.evidence.verify_full}')" '{"v":"","e":"package.json has no test script (only npm'"'"'s placeholder) — verify_full left empty"}'
mkdir -p "$DR/pnpm" && echo '{"scripts":{"test":"vitest run","typecheck":"tsc --noEmit"},"devDependencies":{"vitest":"^2"}}' > "$DR/pnpm/package.json" && touch "$DR/pnpm/pnpm-lock.yaml"
contains "the lockfile names the package manager (pnpm), typecheck runs before the tests" "$(det pnpm '{v:.verify_full,s:.worktree_setup}')" '{"v":"pnpm typecheck && pnpm test","s":"pnpm install --frozen-lockfile"}'
mkdir -p "$DR/py" && printf '[project]\nname = "x"\n[dependency-groups]\ndev = ["pytest"]\n' > "$DR/py/pyproject.toml" && touch "$DR/py/uv.lock"
contains "Python with uv: uv run pytest, uv sync in each worktree" "$(det py '{v:.verify_full,s:.worktree_setup,x:.worktree_exclude}')" '{"v":"uv run pytest -q","s":"uv sync","x":[".venv"]}'
mkdir -p "$DR/mono/web" "$DR/mono/api" && echo '{"scripts":{"test":"jest"},"devDependencies":{"jest":"^29"}}' > "$DR/mono/web/package.json" && touch "$DR/mono/web/package-lock.json" && echo 'module x' > "$DR/mono/api/go.mod"
contains "a repo with a project per folder: each one's tests, in its folder" "$(det mono '{v:.verify_full,s:.worktree_setup}')" '{"v":"(cd api && go test ./...) && (cd web && npm test)","s":"(cd web && npm ci)"}'
mkdir -p "$DR/make" && printf 'test:\n\tgo test ./...\n' > "$DR/make/Makefile" && echo 'module x' > "$DR/make/go.mod"
contains "the repo's own Makefile test target wins" "$(det make .verify_full)" '"make test"'
mkdir -p "$DR/empty"
contains "a repo without code: no test command and no language assumed" "$(det empty '{v:.verify_full,s:.worktree_setup}')" '{"v":"","s":""}'
mkdir -p "$DR/cfg/munder-difflin" && jq -n --arg r "$DR/pnpm" '{harnessHome:"/floors/pnpm", registeredRepos:[$r]}' > "$DR/cfg/munder-difflin/config.json"
contains "the floor the repo is registered on becomes its munder.hive_root" "$(XDG_CONFIG_HOME="$DR/cfg" node "$DT" "$DR/pnpm" | jq -c '{h:.hive_root}')" '{"h":"/floors/pnpm"}'
expect_ok "…valid against the shipped schema's keys" node -e 'const s=require(process.argv[1]),c=require(process.argv[2]);for(const k of Object.keys(c)) if(!(k in s.properties)) {console.error("unknown key "+k);process.exit(1)}' "$HERE/kit/skills/deliver/deliver.schema.json" "$PC/.deliver.json"
contains "dl config shows what applies (kit defaults ⊕ .deliver.json)" "$(cd "$PC" && "$DL" config)" "kit defaults ⊕ $PC/.deliver.json"
(cd "$PC" && AGENT_ID=god "$DL" phase aborted >/dev/null 2>&1; AGENT_ID=god "$DL" cleanup --all >/dev/null 2>&1; jq '.roles = {"backend":{"model":"haiku","count":2},"qa":{"model":"sonnet"}}' .deliver.json > x && mv x .deliver.json && AGENT_ID=god "$DL" new t2 r2 >/dev/null 2>&1)
(cd "$PC" && AGENT_ID=god "$DL" jobset '.roles=[{"role":"backend","agent":"backend-dev","why":"x"},{"role":"qa","agent":"qa-tester","why":"y","model":"opus"}]' >/dev/null)
PJ="$PC/.work/$(cat "$PC/.work/ACTIVE")/job.json"
contains "per-role defaults from .deliver.json reach the job's roles — and QA gets one seat per developer seat" "$(jq -c '[.roles[] | {role,model,count}]' "$PJ")" '[{"role":"backend","model":"haiku","count":2},{"role":"qa","model":"opus","count":2}]'
contains "…logged" "$(grep $'\troles-defaults\t' "$(dirname "$PJ")/events.log")" "qa: 2 seats — one per developer seat"
(cd "$PC" && AGENT_ID=god "$DL" jobset '.roles=[{"role":"backend","agent":"backend-dev","why":"x","count":3},{"role":"qa","agent":"qa-tester","why":"y","count":1}]' >/dev/null)
contains "…a QA count somebody gave is kept" "$(jq -c '[.roles[] | select(.role=="qa") | .count]' "$PJ")" '[1]'
(cd "$PC" && AGENT_ID=god "$DL" jobset '.roles=[{"role":"backend","agent":"backend-dev","why":"x","count":1},{"role":"qa","agent":"qa-tester","why":"y"}]' >/dev/null)
contains "…one developer seat: one QA seat" "$(jq -c '[.roles[] | select(.role=="qa") | .count]' "$PJ")" '[null]'
(cd "$PC" && FORCE_COLOR=1 AGENT_ID=god "$DL" jobset '.roles=[{"role":"backend","agent":"backend-dev","why":"x","count":2},{"role":"qa","agent":"qa-tester","why":"y"}]' >/dev/null 2>&1)
contains "…also where the terminal forces colour (the floor's, run 54: node coloured the count and dl could not read it)" "$(jq -c '[.roles[] | select(.role=="qa") | .count]' "$PJ")" '[2]'
# parallel jobsets (Michael's parallel tool calls) must not lose each other's changes — seen live
(cd "$PC" && for k in a b c d e f; do AGENT_ID=god "$DL" jobset ".assumptions += [\"$k\"]" >/dev/null & done; wait)
contains "six jobsets at once: none is lost (they run one at a time)" "$(jq -c '.assumptions | map(select(length == 1)) | sort' "$PJ")" '["a","b","c","d","e","f"]'
contains "…a role that names its own model keeps it (qa: opus from the request, not the default sonnet), logged" "$(grep $'\troles-defaults\t' "$PC/.work/$(cat "$PC/.work/ACTIVE")/events.log")" "backend: model haiku, count 2"
contains "the human switches the job to subagents by hand (dl dispatch)" "$(env -u AGENT_ID "$DL" dispatch subagent "leave the floor for the rest of the tests" 2>&1)" "now runs with dispatch subagent"
contains "…logged with who and why" "$(grep $'\tdispatch\t' "$R/.work/$JOB/events.log" | tail -1)" "subagent — leave the floor"
unset HIVE_ROOT AGENT_ID

echo "plugin install: the kit's agents are namespaced, job files keep plain names"
DELIVER_AGENT_NS=deliver "$DL" roles >/dev/null
out="$(cat "$R/.work/$JOB/ROLES.md")"
contains "ROLES.md names kit agents with the plugin prefix" "$out" '`deliver:backend-dev`'
contains "…and says to call them by those names" "$out" 'runs as the `deliver` plugin'
[[ $out != *deliver:ecc:* ]] && ok "…ECC agents keep their own namespace" || bad "ecc agent re-prefixed"
contains "the role card names the agent to call" "$(cat "$R/.work/$JOB/roles/backend.md")" 'Agent: `deliver:backend-dev`'
contains "job.json keeps the plain name" "$(jq -r '.roles[] | select(.role=="backend") | .agent' "$R/.work/$JOB/job.json")" "backend-dev"
export HIVE_ROOT="$TMP/hive3"; mkdir -p "$HIVE_ROOT"; "$DL" jobset '.settings.dispatch="munder"'; export AGENT_ID=god
DELIVER_AGENT_NS=deliver "$DL" md-dispatch T-03 "$TMP/p.txt" >/dev/null 2>&1 || true
contains "floor workers start the namespaced agent" "$(jq -r .command "$(ls "$HIVE_ROOT"/spawn-requests/*.json | head -1)" 2>&1)" "claude --agent deliver:backend-dev"
"$DL" jobset '.settings.dispatch="subagent"'; unset HIVE_ROOT AGENT_ID
"$DL" roles >/dev/null
out="$(cat "$R/.work/$JOB/ROLES.md")"
[[ $out == *'`backend-dev`'* && $out != *deliver:* ]] && ok "a copied install (no plugin) keeps plain names" || bad "plain names: $out"
# Claude Code may load an installed plugin straight from a local marketplace folder: the kit's manifest + the plugin
# listed in installed_plugins.json is enough.
mkdir -p "$HOME/.claude/plugins"; echo '{"version":2,"plugins":{"deliver@deliver-floor":[{"scope":"user"}]}}' > "$HOME/.claude/plugins/installed_plugins.json"
"$DL" roles >/dev/null; contains "an installed plugin loaded from its source folder is detected" "$(cat "$R/.work/$JOB/ROLES.md")" '`deliver:backend-dev`'
rm -f "$HOME/.claude/plugins/installed_plugins.json"; "$DL" roles >/dev/null
[[ "$(cat "$R/.work/$JOB/ROLES.md")" != *deliver:* ]] && ok "…and not when the plugin is not installed" || bad "namespace without plugin"
HV="$TMP/hive2"; DELIVER_SKILL_DIR=/opt/kit/skills/deliver "$HERE/scripts/md-brief.sh" "$HV" "$R" >/dev/null
[[ -f $HV/CLAUDE.md && -f $HV/AGENTS.md && -f $HV/GEMINI.md ]] && grep -q "/opt/kit/skills/deliver/SKILL.md" "$HV/AGENTS.md" \
  && ok "md-brief briefs Michael for Claude, Codex-style (AGENTS.md) and Gemini CLIs" || bad "md-brief files"

echo "architecture: mixed stacks, frozen decisions, seats, parallel assignment"
AR="$TMP/arch"; mkdir -p "$AR" && cd "$AR" && git init -q -b main && echo '{"dispatch":"subagent","verify_full":"true","merge_mode":"local","max_parallel":4}' > .deliver.json && git add -A && git commit -qm i
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
bedit "$AJ/board.json" '.cards[0].scope=["services/payments/src/**"]'
out="$("$DL" validate 2>&1)"; contains "a card reaching outside its component is rejected" "$out" "outside component orders"
# a component may span several directories (code + unit tests + integration tests); copy the job to try it without
# touching the frozen readiness of this job
VC="$TMP/vcomp"; rm -rf "$VC"; cp -r "$AJ" "$VC"
jq '.architecture.components[0].path = ["services/orders/", "test/unit/orders/", "test/it/orders/"]' "$AJ/readiness.json" > "$VC/readiness.json"
jq '.cards[0].scope = ["services/orders/src/**", "test/unit/orders/**"] | .cards[0].qa_scope = ["test/it/orders/**"]' "$AJ/board.json" > "$VC/board.json"
expect_ok "a component spanning code and test directories accepts cards in all of them" node "$HERE/kit/skills/deliver/bin/validate.mjs" "$VC/board.json"
jq '.cards[0].qa_scope = ["test/e2e/orders/**"]' "$VC/board.json" > "$VC/b2.json" && mv "$VC/b2.json" "$VC/board.json"
out="$(node "$HERE/kit/skills/deliver/bin/validate.mjs" "$VC/board.json" 2>&1)"; contains "…and still rejects a directory it does not list" "$out" "outside component orders"
# …or of single files (live run: the BA listed each component's files; readiness took them, validate must too)
jq '.architecture.components[0].path = ["src/orders/cancel.mjs", "test/orders/cancel.test.mjs"]' "$AJ/readiness.json" > "$VC/readiness.json"
jq '.cards[0].scope = ["src/orders/cancel.mjs"] | .cards[0].qa_scope = ["test/orders/cancel.test.mjs"]' "$AJ/board.json" > "$VC/board.json"
expect_ok "a component listed as single files accepts cards scoped to exactly those files" node "$HERE/kit/skills/deliver/bin/validate.mjs" "$VC/board.json"
jq '.cards[0].scope = ["src/orders/cancel.mjsx"]' "$VC/board.json" > "$VC/b2.json" && mv "$VC/b2.json" "$VC/board.json"
out="$(node "$HERE/kit/skills/deliver/bin/validate.mjs" "$VC/board.json" 2>&1)"; contains "…but not a file that merely starts with one of their names" "$out" "outside component orders"
bedit "$AJ/board.json" '.cards[0].scope=["services/orders/src/**"] | .cards[2].role="backend"'
out="$("$DL" validate 2>&1)"; contains "a backend dev on the database component is rejected" "$out" "owned by role 'database'"
bedit "$AJ/board.json" '.cards[2].role="database"'
cp "$AJ/readiness.json" "$TMP/rd.bak"; jq '.architecture.components[4].stack=["rust"]' "$TMP/rd.bak" > "$AJ/readiness.json"
expect_fail 6 "editing the frozen readiness/architecture is refused" "$DL" validate
contains "agents cannot unfreeze" "$(printf '%s' '{"tool_input":{"command":"dl unfreeze \"x\""},"cwd":"/"}' | "$HERE/kit/hooks/deliver/bash-guard.sh" 2>&1; echo "rc=$?")" "rc=2"
cp "$TMP/rd.bak" "$AJ/readiness.json"
"$DL" phase executing >/dev/null
# two parallel assignments race for the single database seat… and two backend seats work side by side
"$DL" jobset '(.roles[] | select(.role=="database")).count = 1'
bedit "$AJ/board.json" '.cards += [(.cards[2] | .id="T-04" | .title="T-04")]'; cp "$AJ/specs/T-03.md" "$AJ/specs/T-04.md"
( "$DL" wt add T-03 >"$TMP/r3" 2>&1; echo $? >> "$TMP/r3" ) & ( "$DL" wt add T-04 >"$TMP/r4" 2>&1; echo $? >> "$TMP/r4" ) & wait
[[ "$(jq '[.cards[] | select(.role=="database" and .state=="running")] | length' "$AJ/board.json")" == 1 ]] && grep -q "seats are busy" "$TMP/r3" "$TMP/r4" \
  && ok "concurrent assignment: exactly one of two cards gets the single database seat" || bad "race: $(cat "$TMP/r3" "$TMP/r4")"
out="$("$DL" next)"; contains "an idle seat with work says so (backend#1 → T-01)" "$out" "IDLE    backend#1 — free; take T-01"
contains "…and so does the second seat" "$out" "IDLE    backend#2 — free; take T-01"
grep -qE "backend#2 +IDLE +→ assign T-01, T-02" <<<"$("$DL" seats)" && ok "dl seats lists every seat with its next card" || bad "dl seats: $("$DL" seats)"
"$DL" wt add T-01 >/dev/null && "$DL" wt add T-02 >/dev/null
! "$DL" next | gq "IDLE    backend" && ok "no backend seat idle once both work" || bad "idle after assign: $("$DL" next)"
grep -q "backend#1 busy (T-01)" "$AJ/kanban.html" && ok "kanban shows seat utilisation" || bad "kanban seats"
[[ "$(jq -r '[.cards[] | select(.role=="backend") | .seat] | sort | join(",")' "$AJ/board.json")" == "backend#1,backend#2" ]] \
  && ok "two backend devs work in parallel on seats backend#1 and backend#2, each on its own branch" || bad "seats: $(jq -c '[.cards[]|{id,seat,branch}]' "$AJ/board.json")"
[[ "$(git -C "$AR" branch --list '*--T-01' '*--T-02' | wc -l | tr -d " ")" == 2 ]] && ok "…each on its own card branch" || bad "branches"
bedit "$AJ/board.json" '.cards += [(.cards[0] | .id="T-05" | .title="T-05" | .state="ready" | del(.seat))]'; cp "$AJ/specs/T-01.md" "$AJ/specs/T-05.md"
out="$("$DL" wt add T-05 2>&1)"; contains "a third backend card waits: both backend seats are busy" "$out" "all 2 'backend' seats are busy"
jq -e '[.cards[] | select(.id=="T-01") | .assignments[0] | .by=="michael" and .seat=="backend#1"] | all' "$AJ/board.json" >/dev/null && ok "assignment records michael + seat" || bad "assignment record"
"$DL" kanban > "$TMP/kanban.txt"; grep -q "In Progress (3)" "$TMP/kanban.txt" && ok "kanban shows 3 cards in progress" || bad "kanban: $(cat "$TMP/kanban.txt")"
[[ -f $AJ/kanban.html ]] && grep -q "backend#2" "$AJ/kanban.html" && ok "local tracker renders kanban.html with seats" || bad "kanban.html"
"$DL" phase aborted >/dev/null; "$DL" cleanup --all >/dev/null; cd "$R"; unset ARCH

echo "traceability: card changes, jobset limits, seals"
TR2="$TMP/trace"; mkdir -p "$TR2" && cd "$TR2" && git init -q -b main && echo '{"dispatch":"subagent","verify_full":"true","merge_mode":"local"}' > .deliver.json && git add -A && git commit -qm i
"$DL" new "trace" "x" >/dev/null; TJ="$TR2/.work/$(cat .work/ACTIVE)"
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]'
expect_fail 1 "jobset cannot move the phase" "$DL" jobset '.phase="done"'
expect_fail 1 "jobset cannot approve a gate" "$DL" jobset '.gates.plan={"status":"approved"}'
"$DL" phase readiness >/dev/null && ready_all && "$DL" phase planning >/dev/null
expect_fail 1 "jobset cannot clear the frozen hash" "$DL" jobset '.frozen=null'
printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$TJ/specs/T-01.md"
jq -n '{cards:[{id:"T-01",title:"one",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:[],scope:["src/**"],qa_scope:["it/**"],
  verify:"test -d .",qa_verify:"test -d .",acceptance:["AC-1: x"],context:"c",attempts:0,notes:[]}]}' > "$TJ/board.json"
"$DL" phase executing >/dev/null
contains "Michael's direct board edit is denied by the write-guard" "$(printf '%s' "{\"tool_input\":{\"file_path\":\"$TJ/board.json\"},\"cwd\":\"$TR2\",\"transcript_path\":\"$TR\"}" | sed "s#$JOB#$(basename "$TJ")#" > /dev/null; echo "{\"x\":\"$(basename "$TJ")\"}" > "$TMP/tr2.jsonl"; printf '%s' "{\"tool_input\":{\"file_path\":\"$TJ/board.json\"},\"cwd\":\"$TR2\",\"transcript_path\":\"$TMP/tr2.jsonl\"}" | "$HERE/kit/hooks/deliver/write-guard.sh" 2>&1; echo "rc=$?")" "rc=2"
jq '.cards[0].verify="echo ok"' "$TJ/board.json" > "$TJ/b.t" && mv "$TJ/b.t" "$TJ/board.json"
expect_fail 7 "an edit through any other tool breaks the seal: dl stops" "$DL" status
contains "only a human may reseal" "$(printf '%s' '{"tool_input":{"command":"dl reseal \"ok\""},"cwd":"/"}' | "$HERE/kit/hooks/deliver/bash-guard.sh" 2>&1; echo "rc=$?")" "rc=2"
expect_ok "the human reseals after inspecting" "$DL" reseal "verify change inspected"
grep -q $'\treseal\t' "$TJ/events.log" && ok "the reseal is in the event log" || bad "reseal log"
expect_ok "dl card set changes a field with a reason" "$DL" card T-01 set verify "test -f package.json || true" "package.json is optional in this repo"
jq -e '.cards[0].history[-1] | .field=="verify" and .reason=="package.json is optional in this repo" and .by=="michael"' "$TJ/board.json" >/dev/null && ok "card history keeps from/to/reason" || bad "history"
expect_fail 1 "an invalid change is reverted" "$DL" card T-01 set scope '["**"]' "too broad"
[[ "$(jq -c '.cards[0].scope' "$TJ/board.json")" == '["src/**"]' ]] && ok "…and the board is unchanged" || bad "revert"
jq -n '{title:"fix",role:"backend",agent:"backend-dev",component:"app",depends_on:[],scope:["lib/**"],qa_scope:["it2/**"],verify:"test -d .",qa_verify:"test -d .",acceptance:["AC-1: y"],context:"fix"}' > "$TMP/fix.json"
contains "dl card add gives the next id" "$("$DL" card add "$TMP/fix.json" "verify-all found a gap" 2>&1)" "T-02"
jq -n '{title:"bad",role:"backend",agent:"backend-dev",component:"app",depends_on:[],scope:["it/**"],qa_scope:["it3/**"],verify:"test -d .",qa_verify:"test -d .",acceptance:["AC-1: z"],context:"x"}' > "$TMP/bad.json"
out="$("$DL" card add "$TMP/bad.json" "dev edits QA tests" 2>&1)"; contains "a dev card reaching another card's QA tests is rejected" "$out" "QA tests belong to the QA role"
"$DL" phase aborted >/dev/null; "$DL" cleanup --all >/dev/null; cd "$R"

echo "tracker: jira (contract stub of Jira REST v3) — statuses, comments, branch links"
JS="$TMP/jira-state.json"; JSF="$TMP/jira-statuses"; : > "$TMP/jira.port"
STUB_STATUSES_FILE="$JSF" node "$HERE/tests/jira-stub.mjs" "$JS" > "$TMP/jira.port" & JPID=$!
for _ in $(seq 50); do grep -q listening "$TMP/jira.port" && break; sleep 0.1; done
export JIRA_BASE_URL="http://127.0.0.1:$(awk '{print $2}' "$TMP/jira.port")" JIRA_EMAIL=bot@example.com JIRA_API_TOKEN=t0ken
git init -q --bare "$TMP/gh-origin.git"
JR="$TMP/jira-repo"; mkdir -p "$JR" && cd "$JR" && git init -q -b main
git remote add origin https://github.com/acme/demo.git && git config url."$TMP/gh-origin.git".insteadOf https://github.com/acme/demo.git
echo '{"dispatch":"subagent","verify_full":"true","merge_mode":"human","tracker":{"kind":"jira","jira":{"project":"WL"}}}' > .deliver.json && git add -A && git commit -qm i && git push -q origin main
# Before any job: dl tracker check asks the site what the flow will need (read-only)
out="$("$DL" tracker check 2>&1)"; rc=$?
[[ $rc == 0 && $out == *"ok   signed in to $JIRA_BASE_URL as bot@example.com"* && $out == *"status for every column"* && $out == *"link type 'Blocks'"* ]] \
  && ok "dl tracker check: signed in, project, issue types, a status per column, Blocks — before any job" || bad "tracker check: $out"
contains "…a missing credential is named" "$(env -u JIRA_API_TOKEN "$DL" tracker check 2>&1)" "Jira credentials missing: JIRA_EMAIL + JIRA_API_TOKEN, or JIRA_PAT"
contains "…a project the user cannot see fails" "$(jq '.tracker.jira.project = "NOPE"' .deliver.json > x.json && mv x.json .deliver.json && "$DL" tracker check 2>&1; git checkout -q .deliver.json)" "FAIL project NOPE is not visible"
echo "To Do,In Progress,Code Review,Done,Blocked,Won't Do" > "$JSF"
out="$("$DL" tracker check 2>&1)"; rc=$?
[[ $rc == 1 && $out == *"FAIL the Task workflow has no status for: qa → 'QA'"* ]] && ok "…a workflow without a column's status fails, naming it" || bad "tracker check missing status: rc=$rc $out"
rm -f "$JSF"
contains "doctor runs the same check for a Jira repo" "$("$HERE/scripts/doctor.sh" "$JR" 2>&1)" "jira: signed in to $JIRA_BASE_URL as bot@example.com"
contains "…and names missing Jira credentials" "$(env -u JIRA_EMAIL "$HERE/scripts/doctor.sh" "$JR" 2>&1)" "tracker jira: set JIRA_BASE_URL and JIRA_EMAIL + JIRA_API_TOKEN"
"$DL" new "jira flow" "x" >/dev/null; JJ="$JR/.work/$(cat .work/ACTIVE)"
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]'
"$DL" phase readiness >/dev/null && ready_all && "$DL" phase planning >/dev/null
printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$JJ/specs/T-01.md"; cp "$JJ/specs/T-01.md" "$JJ/specs/T-02.md"
jq -n '{cards:[{id:"T-01",title:"one",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:[],scope:["src/**"],qa_scope:["it/**"],
  verify:"test -d src",qa_verify:"test -d it",acceptance:["AC-1: x"],context:"ctx",attempts:0,notes:[]},
  {id:"T-02",title:"two",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:["T-01"],scope:["lib/**"],qa_scope:["it2/**"],
  verify:"test -d lib",qa_verify:"test -d it2",acceptance:["AC-1: y"],context:"ctx2",attempts:0,notes:[]}]}' > "$JJ/board.json"
"$DL" phase executing >/dev/null
jst() { jq -r "$1" "$JS"; }
[[ "$(jst '.issues | length')" == 3 && "$(jst '.issues["WL-2"].fields.parent.key')" == WL-1 && "$(jst '.issues["WL-1"].fields.issuetype.name')" == Epic ]] \
  && ok "executing opens an epic (WL-1) and one issue per card under it" || bad "jira open: $(jst '.issues|keys')"
[[ "$(jst '.links | length')" == 1 ]] && ok "T-02 depends_on T-01 becomes a 'Blocks' issue link" || bad "issue links"
jst '.issues["WL-2"].fields.labels | join(",")' | gq "component-app" && ok "issues carry job, role and component labels" || bad "labels"
W="$("$DL" wt add T-01)"
[[ "$(jq -r '.cards[0].branch' "$JJ/board.json")" == *"--T-01-WL-2" ]] && ok "the card branch carries the issue key (Jira's Development panel links it)" || bad "branch name"
git --git-dir="$TMP/gh-origin.git" rev-parse -q --verify "refs/heads/$(jq -r '.cards[0].branch' "$JJ/board.json")" >/dev/null && ok "dl pushed the card branch" || bad "card branch push"
[[ "$(jst '.issues["WL-2"].status')" == "In Progress" ]] && ok "assignment → In Progress" || bad "status after assign: $(jst '.issues["WL-2"].status')"
jst '.issues["WL-2"].remotelinks[0].object.url' | gq "https://github.com/acme/demo/tree/job/" && ok "the branch is a remote link on the issue" || bad "remotelink"
jst '.issues["WL-2"].fields.description' | gq "Development: branch" && ok "…and in the description" || bad "description branch"
mkdir -p "$W/src" && echo 1 > "$W/src/a" && git -C "$W" add -A && git -C "$W" commit -qm "T-01"
"$DL" gate T-01 >/dev/null; [[ "$(jst '.issues["WL-2"].status')" == QA ]] && ok "gate PASS → QA" || bad "after gate: $(jst '.issues["WL-2"].status')"
mkdir -p "$W/it" && echo 1 > "$W/it/t" && git -C "$W" add -A && git -C "$W" commit -qm "T-01 QA"
"$DL" qa T-01 pass "AC-1 pass" >/dev/null; [[ "$(jst '.issues["WL-2"].status')" == "Code Review" ]] && ok "QA pass → Code Review" || bad "after qa: $(jst '.issues["WL-2"].status')"
"$DL" review T-01 approve "ok" >/dev/null; "$DL" integrate T-01 >/dev/null
[[ "$(jst '.issues["WL-2"].status')" == Done ]] && ok "merge → Done" || bad "after integrate: $(jst '.issues["WL-2"].status')"
jst '.issues["WL-2"].comments | join(" ")' | gq "qa-tester" && jst '.issues["WL-2"].comments | join(" ")' | gq "\[reviewer\] approve" \
  && ok "the roles' results are comments on the issue (gate, QA, review, assignment)" || bad "comments: $(jst '.issues["WL-2"].comments')"
echo "To Do,In Progress,Code Review,Done,Blocked" > "$JSF"   # the Jira admin removed the QA status
W2="$("$DL" wt add T-02)"; mkdir -p "$W2/lib" && echo 1 > "$W2/lib/a" && git -C "$W2" add -A && git -C "$W2" commit -qm "T-02"
out="$("$DL" gate T-02 2>&1)"; contains "a missing workflow status is reported, the gate result stands" "$out" "no transition to 'QA'"
contains "dl status shows the tracker error" "$("$DL" status 2>&1)" "tracker: "
[[ "$(jq -r '.cards[1].gate.result' "$JJ/board.json")" == PASS ]] && ok "board.json (the source of truth) is unaffected by the tracker outage" || bad "gate record"
own2="$(jq -r '.cards[1].branch' "$JJ/board.json")"
pg() { printf '%s' "$(jq -n --arg c "$1" --arg cwd "$W2" '{tool_input:{command:$c},cwd:$cwd,agent_id:"dev1"}')" | "$HERE/kit/hooks/deliver/bash-guard.sh" 2>&1; echo "rc=$?"; }
contains "an agent may push its own card branch" "$(pg "git push origin $own2")" "rc=0"
contains "…but not another card's branch" "$(pg "git push origin $(jq -r '.cards[0].branch' "$JJ/board.json")")" "rc=2"
contains "…nor the job branch" "$(pg "git push origin $(jq -r .branch "$JJ/job.json")")" "rc=2"
contains "…nor main" "$(pg "git push origin main")" "rc=2"
contains "…nor a force push of its own branch" "$(pg "git push -f origin $own2")" "rc=2"
contains "…and must name the branch" "$(pg "git push")" "rc=2"
kill $JPID 2>/dev/null; unset JIRA_BASE_URL JIRA_EMAIL JIRA_API_TOKEN
"$DL" phase aborted --force >/dev/null; "$DL" cleanup --all >/dev/null; cd "$R"

# Asana, Linear, GitHub Projects: the same contract as Jira, each against a stub of its vendor's API (tests/tracker-stubs.mjs)
tracker_contract() { # tracker_contract <kind> <credential var> '<tracker.<kind> settings>' <key in the branch: 1|0>
  local k=$1 cred=$2 cfg=$3 keyed=$4 pid; local TS="$TMP/$k-state.json" TC="$TMP/$k-cols" TP="$TMP/$k.port" TR="$TMP/$k-repo"
  echo "tracker: $k (contract stub) — check, open, columns, dependencies, comments, branch"
  local saved_gh=${GH_TOKEN:-}; unset GH_TOKEN   # a real token of this machine never reaches the stub, nor hides a missing one
  : > "$TP"; rm -f "$TC"; STUB_COLUMNS_FILE="$TC" node "$HERE/tests/tracker-stubs.mjs" "$k" "$TS" > "$TP" & pid=$!
  for _ in $(seq 50); do grep -q listening "$TP" && break; sleep 0.1; done
  local port; port="$(awk '{print $2}' "$TP")"
  export ASANA_BASE_URL="http://127.0.0.1:$port/api/1.0" LINEAR_API_URL="http://127.0.0.1:$port/graphql" GITHUB_API_URL="http://127.0.0.1:$port"
  export "$cred=t0ken-$k"
  mkdir -p "$TR" && cd "$TR" && git init -q -b main
  jq -n --arg k "$k" --argjson c "$cfg" '{dispatch:"subagent",verify_full:"true",merge_mode:"local",tracker:{kind:$k, ($k):$c}}' > .deliver.json && git add -A && git commit -qm i
  local out rc=0; out="$("$DL" tracker check 2>&1)" || rc=$?
  [[ $rc == 0 && $out == *"ok   signed in to "* && $out == *"for every column"* ]] && ok "$k: dl tracker check — signed in, the board, a column for every stage" || bad "$k check: rc=$rc $out"
  contains "$k: …a missing credential is named" "$(env -u "$cred" "$DL" tracker check 2>&1)" "credentials missing: $cred"
  echo "To Do,In Progress,Code Review,Done,Blocked,Won't Do" > "$TC"; rc=0; out="$("$DL" tracker check 2>&1)" || rc=$?
  [[ $rc == 1 && $out == *"qa → 'QA'"* ]] && ok "$k: …a board without a column fails, naming it — nothing is added to your board" || bad "$k missing column: rc=$rc $out"
  rm -f "$TC"
  contains "$k: doctor runs the same check" "$("$HERE/scripts/doctor.sh" "$TR" 2>&1)" "$k: signed in to "
  contains "$k: …and names a missing credential" "$(env -u "$cred" "$HERE/scripts/doctor.sh" "$TR" 2>&1)" "tracker $k: set $cred"
  "$DL" new "$k flow" "x" >/dev/null; local TJ2="$TR/.work/$(cat .work/ACTIVE)"
  "$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]' >/dev/null
  "$DL" phase readiness >/dev/null && ready_all && "$DL" phase planning >/dev/null
  printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$TJ2/specs/T-01.md"; cp "$TJ2/specs/T-01.md" "$TJ2/specs/T-02.md"
  jq -n '{cards:[{id:"T-01",title:"one",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:[],scope:["src/**"],qa_scope:["it/**"],
    verify:"test -d src",qa_verify:"test -d it",acceptance:["AC-1: x"],context:"ctx",attempts:0,notes:[]},
    {id:"T-02",title:"two",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:["T-01"],scope:["lib/**"],qa_scope:["it2/**"],
    verify:"test -d lib",qa_verify:"test -d it2",acceptance:["AC-1: y"],context:"ctx2",attempts:0,notes:[]}]}' > "$TJ2/board.json"
  "$DL" phase executing >/dev/null
  local ts; ts() { jq -r "$1" "$TS"; }
  local i1 i2; i1="$(ts '.items | to_entries[] | select(.value.title | startswith("T-01")) | .key')"; i2="$(ts '.items | to_entries[] | select(.value.title | startswith("T-02")) | .key')"
  [[ "$(ts '.container.title')" == "$k flow" && -n $i1 && -n $i2 && "$(ts ".items[\"$i1\"].parent | tostring")" == "$(ts '.container.id | tostring')" ]] \
    && ok "$k: executing opens the job and one item per card under it, in your existing board" || bad "$k open: $(cat "$TS" | head -c 600)"
  [[ "$(ts ".items[\"$i2\"].blocked_by | map(tostring) | join(\",\")")" == "$(jq -r '.cards[0].tracker | (.number // .id) | tostring' "$TJ2/board.json")" ]] \
    && ok "$k: T-02 depends_on T-01 becomes the tool's own dependency" || bad "$k dependency: $(ts ".items[\"$i2\"].blocked_by")"
  [[ "$(ts ".items[\"$i1\"].column")" == "To Do" ]] && ok "$k: a ready card is in To Do" || bad "$k column at open: $(ts ".items[\"$i1\"].column")"
  local W; W="$("$DL" wt add T-01)"
  if [[ $keyed == 1 ]]; then [[ "$(jq -r '.cards[0].branch' "$TJ2/board.json")" == *"--T-01-$(jq -r '.cards[0].tracker.key' "$TJ2/board.json")" ]] && ok "$k: the card branch carries the issue key" || bad "$k branch: $(jq -r '.cards[0].branch' "$TJ2/board.json")"; fi
  [[ "$(ts ".items[\"$i1\"].column")" == "In Progress" ]] && ok "$k: assignment → In Progress" || bad "$k after assign: $(ts ".items[\"$i1\"].column")"
  ts ".items[\"$i1\"].body" | gq "Development: branch" && ok "$k: the branch is in the description" || bad "$k description"
  mkdir -p "$W/src" && echo 1 > "$W/src/a" && git -C "$W" add -A && git -C "$W" commit -qm "T-01"
  "$DL" gate T-01 >/dev/null; [[ "$(ts ".items[\"$i1\"].column")" == QA ]] && ok "$k: gate PASS → QA" || bad "$k after gate: $(ts ".items[\"$i1\"].column")"
  mkdir -p "$W/it" && echo 1 > "$W/it/t" && git -C "$W" add -A && git -C "$W" commit -qm "T-01 QA"
  "$DL" qa T-01 pass "AC-1 pass" >/dev/null; [[ "$(ts ".items[\"$i1\"].column")" == "Code Review" ]] && ok "$k: QA pass → Code Review" || bad "$k after qa: $(ts ".items[\"$i1\"].column")"
  "$DL" review T-01 approve "ok" >/dev/null; "$DL" integrate T-01 >/dev/null
  [[ "$(ts ".items[\"$i1\"].column")" == Done ]] && ok "$k: merge → Done" || bad "$k after integrate: $(ts ".items[\"$i1\"].column")"
  ts ".items[\"$i1\"].comments | join(\" \")" | gq "qa-tester" && ts ".items[\"$i1\"].comments | join(\" \")" | gq "reviewer\]" \
    && ok "$k: the roles' results are comments (gate, QA, review, assignment)" || bad "$k comments: $(ts ".items[\"$i1\"].comments")"
  echo "To Do,In Progress,Code Review,Done,Blocked" > "$TC"
  local W2; W2="$("$DL" wt add T-02)"; mkdir -p "$W2/lib" && echo 1 > "$W2/lib/a" && git -C "$W2" add -A && git -C "$W2" commit -qm "T-02"
  out="$("$DL" gate T-02 2>&1)"; contains "$k: a column removed mid-job is reported, the gate result stands" "$out" "'QA'"
  [[ "$(jq -r '.cards[1].gate.result' "$TJ2/board.json")" == PASS ]] && ok "$k: …board.json is unaffected" || bad "$k gate record"
  kill $pid 2>/dev/null; unset "$cred" ASANA_BASE_URL LINEAR_API_URL GITHUB_API_URL; [[ -z $saved_gh ]] || export GH_TOKEN=$saved_gh
  "$DL" phase aborted --force >/dev/null; "$DL" cleanup --all >/dev/null; cd "$R"
}
tracker_contract asana ASANA_TOKEN '{"project":"1200"}' 0
tracker_contract linear LINEAR_API_KEY '{"team":"WL"}' 1
tracker_contract github GITHUB_TOKEN '{"repo":"acme/demo","project":7}' 0

echo "tracker switch mid-job (the human's /deliver:tracker): Jira → Linear"
SWS="$TMP/sw"; mkdir -p "$SWS"; saved_gh=${GH_TOKEN:-}; unset GH_TOKEN
node "$HERE/tests/jira-stub.mjs" "$SWS/jira.json" > "$SWS/j.port" & SJP=$!; node "$HERE/tests/tracker-stubs.mjs" linear "$SWS/linear.json" > "$SWS/l.port" & SLP=$!
for _ in $(seq 50); do grep -q listening "$SWS/j.port" && grep -q listening "$SWS/l.port" && break; sleep 0.1; done
export JIRA_BASE_URL="http://127.0.0.1:$(awk '{print $2}' "$SWS/j.port")" JIRA_EMAIL=bot@example.com JIRA_API_TOKEN=t LINEAR_API_URL="http://127.0.0.1:$(awk '{print $2}' "$SWS/l.port")/graphql" LINEAR_API_KEY=k
SWR="$SWS/repo"; mkdir -p "$SWR" && cd "$SWR" && git init -q -b main
echo '{"dispatch":"subagent","verify_full":"true","merge_mode":"local","tracker":{"kind":"jira","jira":{"project":"WL"}}}' > .deliver.json && git add -A && git commit -qm i
"$DL" new "switch" "x" >/dev/null; SWJ="$SWR/.work/$(cat .work/ACTIVE)"
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]' >/dev/null
"$DL" phase readiness >/dev/null && ready_all && "$DL" phase planning >/dev/null
printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$SWJ/specs/T-01.md"; cp "$SWJ/specs/T-01.md" "$SWJ/specs/T-02.md"
jq -n '{cards:[{id:"T-01",title:"one",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:[],scope:["src/**"],qa_scope:["it/**"],
  verify:"test -d src",qa_verify:"test -d it",acceptance:["AC-1: x"],context:"ctx",attempts:0,notes:[]},
  {id:"T-02",title:"two",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:["T-01"],scope:["lib/**"],qa_scope:["it2/**"],
  verify:"test -d lib",qa_verify:"test -d it2",acceptance:["AC-1: y"],context:"ctx2",attempts:0,notes:[]}]}' > "$SWJ/board.json"
"$DL" phase executing >/dev/null; SWW="$("$DL" wt add T-01)"
[[ "$(jq -r '.cards[0].tracker | "\(.kind) \(.key)"' "$SWJ/board.json")" == "jira WL-2" ]] && ok "a card's tracker record says which tool made it" || bad "record: $(jq -c '.cards[0].tracker' "$SWJ/board.json")"
contains "Claude may not switch the tracker (bash-guard)" "$(bg '"$DL" tracker switch linear "x"')" "rc=2"
swl() { printf '%s' "$1" | env -u AGENT_ID bash "$HERE/kit/skills/tracker/run.sh" tracker; }
out="$(swl 'linear the team moved to Linear')"
contains "a tracker not set up in .deliver.json is refused — nothing changes" "$out" "the linear tracker is not ready — nothing was changed"
contains "…naming what is missing" "$out" "settings.tracker.linear.team is not set"
[[ "$(jq -r .settings.tracker.kind "$SWJ/job.json")" == jira ]] && ok "…the job keeps Jira" || bad "kind changed on a refused switch"
jq '.tracker.linear = {"team":"WL"}' .deliver.json > x && mv x .deliver.json
out="$(swl 'linear the team moved to Linear')"
contains "/deliver:tracker switches once the new tracker passes its check" "$out" "the job now uses the linear tracker (was jira)"
[[ "$(jq -r .settings.tracker.kind "$SWJ/job.json")" == linear ]] && ok "…the job's tracker is Linear now" || bad "kind: $(jq -r .settings.tracker.kind "$SWJ/job.json")"
contains "…logged with who and why" "$(grep $'\ttracker-switch\t' "$SWJ/events.log")" "jira → linear by "
SLI="$(jq -r '.items | to_entries[] | select(.value.title | startswith("T-01")) | .key' "$SWS/linear.json")"
[[ "$(jq -r '.container.title' "$SWS/linear.json")" == switch && -n $SLI && "$(jq -r --arg i "$SLI" '.items[$i].parent' "$SWS/linear.json")" == "$(jq -r '.container.id' "$SWS/linear.json")" ]] \
  && ok "Linear gets its own job issue and the cards under it — never Jira's epic key as a parent" || bad "linear after switch: $(head -c 400 "$SWS/linear.json")"
[[ "$(jq -r --arg i "$SLI" '.items[$i].column' "$SWS/linear.json")" == "In Progress" ]] && ok "…each card in its current column (T-01 In Progress)" || bad "column after switch: $(jq -r --arg i "$SLI" '.items[$i].column' "$SWS/linear.json")"
[[ "$(jq -r '.cards[0].tracker_history[0] | "\(.kind) \(.key)"' "$SWJ/board.json")" == "jira WL-2" && "$(jq -r '.tracker_history[0].epic' "$SWJ/job.json")" == WL-1 ]] \
  && ok "…the Jira links stay in the card's and the job's history" || bad "history: $(jq -c '.cards[0].tracker_history' "$SWJ/board.json")"
mkdir -p "$SWW/src" && echo 1 > "$SWW/src/a" && git -C "$SWW" add -A && git -C "$SWW" commit -qm "T-01"
"$DL" gate T-01 >/dev/null
[[ "$(jq -r --arg i "$SLI" '.items[$i].column' "$SWS/linear.json")" == QA && "$(jq -r '.issues["WL-2"].status' "$SWS/jira.json")" == "In Progress" ]] \
  && ok "the flow goes on in Linear (gate → QA); Jira keeps what it had" || bad "after gate: linear $(jq -r --arg i "$SLI" '.items[$i].column' "$SWS/linear.json") jira $(jq -r '.issues["WL-2"].status' "$SWS/jira.json")"
[[ -z "$(grep $'\ttracker-error\t' "$SWJ/events.log")" ]] && ok "…without a tracker error" || bad "tracker errors: $(grep $'\ttracker-error\t' "$SWJ/events.log" | tail -1)"
contains "switching to the tracker it already has is refused" "$(swl 'linear again')" "already uses the linear tracker"
kill $SJP $SLP 2>/dev/null; unset JIRA_BASE_URL JIRA_EMAIL JIRA_API_TOKEN LINEAR_API_URL LINEAR_API_KEY; [[ -z $saved_gh ]] || export GH_TOKEN=$saved_gh
"$DL" phase aborted --force >/dev/null; "$DL" cleanup --all >/dev/null; cd "$R"

echo "ECC specialists: decisions bring their reviewers; every reviewer must approve"
EC="$TMP/ecc"; mkdir -p "$EC" && cd "$EC" && git init -q -b main && echo '{"dispatch":"subagent","verify_full":"true","merge_mode":"local"}' > .deliver.json && git add -A && git commit -qm i
"$DL" new "spec" "x" >/dev/null; EJ="$EC/.work/$(cat .work/ACTIVE)"
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"frontend-lead","agent":"ecc:architect"},{"role":"frontend","agent":"frontend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:react-reviewer"}]'
"$DL" phase readiness >/dev/null
SPECIALISTS=1 ARCH='{"style":"library","components":[{"id":"web","kind":"web","stack":["react"],"path":".","owner":"frontend","reviewer":"reviewer"}]}' ready_all
out="$("$DL" readiness 2>&1)"; contains "an accessibility decision without the a11y role is an error" "$out" "UX-a11y is decided"
contains "…a performance decision likewise" "$out" "role 'performance' must be on the job"
contains "security is suggested, not forced" "$out" "WARN  NFR-security is decided → consider role 'security'"
"$DL" jobset '.roles += [{"role":"a11y","agent":"ecc:a11y-architect"},{"role":"performance","agent":"ecc:performance-optimizer"},{"role":"docs","agent":"ecc:doc-updater"}]'
SPECIALISTS=1 ARCH='{"style":"library","components":[{"id":"web","kind":"web","stack":["react"],"path":".","owner":"frontend","reviewer":"reviewer"}]}' ready_all
expect_ok "with ecc:a11y-architect, ecc:performance-optimizer and ecc:doc-updater on the job the readiness passes" "$DL" readiness
"$DL" phase planning >/dev/null
printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$EJ/specs/T-01.md"
jq -n '{cards:[{id:"T-01",title:"button",role:"frontend",agent:"frontend-dev",component:"web",state:"ready",depends_on:[],scope:["src/**"],qa_scope:["it/**"],
  verify:"test -d src",qa_verify:"test -d it",acceptance:["AC-1: x"],context:"c",attempts:0,notes:[],reviewers:["reviewer","a11y","nobody"]}]}' > "$EJ/board.json"
out="$("$DL" validate 2>&1)"; contains "an unknown reviewer role is rejected" "$out" "reviewer 'nobody' is not a role on this job"
jq '.cards[0].reviewers=["reviewer","a11y"]' "$EJ/board.json" > "$EJ/b.t" && mv "$EJ/b.t" "$EJ/board.json"
"$DL" phase executing >/dev/null; WE="$("$DL" wt add T-01)"
mkdir -p "$WE/src" "$WE/it" && echo 1 > "$WE/src/a" && git -C "$WE" add -A && git -C "$WE" commit -qm "T-01"
"$DL" gate T-01 >/dev/null; echo 1 > "$WE/it/t"; git -C "$WE" add -A; git -C "$WE" commit -qm "T-01 QA"; "$DL" qa T-01 pass "AC-1" >/dev/null
contains "next names both reviewers" "$("$DL" next)" "reviewers: reviewer, a11y"
out="$("$DL" review T-01 approve "react ok" --by reviewer)"; contains "one approval leaves the card pending" "$out" "card: pending, waiting for a11y"
expect_fail 1 "integrate refused while a reviewer is pending" "$DL" integrate T-01
expect_fail 1 "a role that is not the card's reviewer is refused" "$DL" review T-01 approve "x" --by performance
out="$("$DL" review T-01 changes "button has no accessible name" --by a11y)"; contains "a specialist's 'changes' makes the card 'changes'" "$out" "card: changes"
contains "next re-dispatches with the a11y finding" "$("$DL" next)" "REDISPATCH T-01  (review asked for changes"
"$DL" review T-01 approve "label added" --by a11y >/dev/null
contains "both approvals on the same commit → approve" "$(jq -r '.cards[0].review.verdict' "$EJ/board.json")" "approve"
expect_ok "…and the card merges" "$DL" integrate T-01
"$DL" phase aborted --force >/dev/null; "$DL" cleanup --all >/dev/null; cd "$R"; unset ARCH

echo "robustness: dl next at full capacity with many ready cards (was SIGPIPE 141)"
PF="$TMP/pf"; mkdir -p "$PF" && cd "$PF" && git init -q -b main && echo '{"dispatch":"subagent","verify_full":"true","merge_mode":"local","max_parallel":1}' > .deliver.json && git add -A && git commit -qm i
"$DL" new "pf" "x" >/dev/null; PJ="$PF/.work/$(cat .work/ACTIVE)"; "$DL" phase executing --force >/dev/null
node -e 'const c=[...Array(6)].map((_,i)=>({id:"T-0"+(i+1),title:"t",role:"backend",agent:"backend-dev",state:i?"ready":"running",depends_on:[],scope:["s/**"],acceptance:["x"],verify:"true",context:"c",attempts:i?0:1,notes:[]}));require("fs").writeFileSync(process.argv[1],JSON.stringify({cards:c}))' "$PJ/board.json"
"$DL" reseal "fixture" >/dev/null
rc=0; for i in 1 2 3 4 5; do "$DL" next >/dev/null 2>&1 || rc=$?; done
[[ $rc -eq 0 ]] && ok "dl next survives a full board (5 runs)" || bad "dl next rc=$rc"
"$DL" phase aborted >/dev/null; "$DL" cleanup --all >/dev/null; cd "$R"

echo "commit hygiene: no AI attribution, optional role trailer"
CH="$TMP/commits"; mkdir -p "$CH" && cd "$CH" && git init -q -b main && echo '{"dispatch":"subagent","verify_full":"true","merge_mode":"local"}' > .deliver.json && git add -A && git commit -qm i
"$DL" new "commits" "x" >/dev/null; CJ="$CH/.work/$(cat .work/ACTIVE)"
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]'
"$DL" phase readiness >/dev/null && ready_all && "$DL" phase planning >/dev/null
grep -q "no AI attribution" "$CJ/roles/backend.md" && ok "role cards state the commit rule" || bad "commit rule in role card"
printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$CJ/specs/T-01.md"
jq -n '{cards:[{id:"T-01",title:"one",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:[],scope:["src/**"],qa_scope:["it/**"],
  verify:"test -d src",qa_verify:"test -d it",acceptance:["AC-1: x"],context:"c",attempts:0,notes:[]}]}' > "$CJ/board.json"
"$DL" phase executing >/dev/null; WC="$("$DL" wt add T-01)"
mkdir -p "$WC/src" && echo 1 > "$WC/src/a" && git -C "$WC" add -A && git -C "$WC" commit -qm "T-01: one" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
out="$("$DL" gate T-01 2>&1)"; contains "a Claude co-author trailer fails the gate" "$out" "AI attribution in the card's commits"
git -C "$WC" commit -q --amend -m "T-01: one" -m "Generated with [Claude Code](https://claude.com/claude-code)"
out="$("$DL" gate T-01 2>&1)"; contains "a 'Generated with Claude Code' line fails the gate" "$out" "AI attribution"
git -C "$WC" commit -q --amend -m "T-01: one"
expect_ok "a clean history passes" "$DL" gate T-01
"$DL" jobset '.settings.commit.role_in_message=true'
out="$("$DL" gate T-01 2>&1)"; contains "role_in_message on: a commit without 'Role:' fails" "$out" "without a 'Role: <seat>' trailer"
git -C "$WC" commit -q --amend -m "T-01: one" -m "Role: backend#1"
expect_ok "…and passes with the trailer" "$DL" gate T-01
"$DL" jobset '.settings.commit.role_in_message=false'
"$DL" phase aborted >/dev/null; "$DL" cleanup --all >/dev/null; cd "$R"

echo "commit messages follow the repo's convention — the devs', QA's and dl's own merges; its hooks are never skipped"
for k in cl hist plain; do mkdir -p "$TMP/cc-$k" && git -C "$TMP/cc-$k" init -q -b main; done
echo 'export default { extends: ["@commitlint/config-conventional"] };' > "$TMP/cc-cl/commitlint.config.mjs"
for i in 1 2 3 4; do git -C "$TMP/cc-hist" commit -q --allow-empty -m "feat: thing $i"; git -C "$TMP/cc-plain" commit -q --allow-empty -m "Thing $i"; done
contains "detected: commitlint config → Conventional Commits, enforced" "$(node "$HERE/kit/skills/deliver/bin/detect.mjs" --commit "$TMP/cc-cl")" '{"convention":"conventional","source":"commitlint.config.mjs (commitlint)","enforced":true}'
contains "…from the history when no tool enforces it" "$(node "$HERE/kit/skills/deliver/bin/detect.mjs" --commit "$TMP/cc-hist" | jq -r .source)" "the history: 4 of the last 4 commits"
contains "…plain when neither says so" "$(node "$HERE/kit/skills/deliver/bin/detect.mjs" --commit "$TMP/cc-plain" | jq -r .convention)" "plain"
# phases cannot be skipped: no executing straight from readiness (no readiness review, no freeze), no integrating before it
SK="$TMP/skip"; mkdir -p "$SK" && git -C "$SK" init -q -b main && (cd "$SK" && echo '{"dispatch":"subagent","verify_full":"true","merge_mode":"local"}' > .deliver.json && git add -A && git commit -qm i && "$DL" new s x >/dev/null 2>&1 \
  && "$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]' >/dev/null && "$DL" phase readiness >/dev/null)
contains "readiness → executing is refused (the readiness review and its freeze cannot be skipped)" "$(cd "$SK" && "$DL" phase executing 2>&1)" "executing comes after planning"
contains "readiness → integrating is refused" "$(cd "$SK" && "$DL" phase integrating 2>&1)" "integrating comes after executing"
CC="$TMP/cc-cl"; cd "$CC"
# the repo's commit-msg hook (what husky + commitlint do): Conventional Commits only — also for merges
printf '#!/bin/sh\ngrep -qE "^(feat|fix|chore|test|docs|refactor)(\\(.+\\))?: [a-z]" "$1" || { echo "commitlint: subject may not be empty / type must be one of [feat, fix, …]" >&2; exit 1; }\n' > .git/hooks/commit-msg; chmod +x .git/hooks/commit-msg
echo '{"dispatch":"subagent","verify_full":"true","merge_mode":"local"}' > .deliver.json && git add -A && git commit -qm "chore: init"
out="$("$DL" new "Notch change" "x" 2>&1)"; CJ="$CC/.work/$(cat .work/ACTIVE)"
contains "dl new keeps the detected convention with the job" "$(jq -c '{c:.settings.commit.convention,s:.settings.commit.convention_source}' "$CJ/job.json")" '{"c":"conventional","s":"commitlint.config.mjs (commitlint)"}'
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]'
"$DL" phase readiness >/dev/null && ready_all && "$DL" phase planning >/dev/null
contains "role cards give the devs and QA this repo's commit format" "$(cat "$CJ/roles/backend.md")" "this repo uses Conventional Commits (commitlint.config.mjs (commitlint))"
printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$CJ/specs/T-01.md"
jq -n '{cards:[{id:"T-01",title:"Notch change",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:[],scope:["src/**"],qa_scope:["it/**"],
  verify:"test -d src",qa_verify:"test -d it",acceptance:["AC-1: x"],context:"c",attempts:0,notes:[]}]}' > "$CJ/board.json"
"$DL" phase executing >/dev/null; WC="$("$DL" wt add T-01)"
mkdir -p "$WC/src" && echo 1 > "$WC/src/a" && git -C "$WC" add -A && git -C "$WC" -c core.hooksPath=/dev/null commit -qm "T-01: notch change"
out="$("$DL" gate T-01 2>&1)"; contains "the gate refuses a card commit outside the repo's convention (a hook skipped is caught too)" "$out" "commits not in this repo's Conventional Commits format"
git -C "$WC" commit -q --amend -m "feat: notch change (T-01)"
expect_ok "…and passes once it follows it" "$DL" gate T-01
mkdir -p "$WC/it" && echo t > "$WC/it/t" && git -C "$WC" add -A && git -C "$WC" commit -qm "test: integration tests for AC-1 (T-01)"
out="$("$DL" wt add T-01 2>&1)"; contains "QA's commits must be recorded before the card goes anywhere else (dl wt add refuses)" "$out" "has QA commits that are not recorded yet"
"$DL" qa T-01 pass "AC-1 pass" >/dev/null && "$DL" review T-01 approve "ok" >/dev/null
out="$("$DL" integrate T-01 2>&1)"; rc=$?
[[ $rc == 0 && "$(git -C "$CJ/wt/_integration" log -1 --format=%s)" == "chore: merge T-01 - notch change" ]] \
  && ok "dl's own merge commit follows the convention and passes the repo's hook: \"chore: merge T-01 - notch change\"" || bad "integrate under commitlint: rc=$rc $out / $(git -C "$CJ/wt/_integration" log -1 --format=%s)"
"$DL" phase aborted >/dev/null; "$DL" cleanup --all >/dev/null
# a hook that refuses every form dl can write: not a conflict — the hook's words, exit 5, the card untouched
printf '#!/bin/sh\ncase "$(head -1 "$1")" in *TICKET-*) exit 0 ;; esac; echo "commit-msg: every subject needs a TICKET-n reference" >&2; exit 1\n' > .git/hooks/commit-msg
"$DL" new "Second" "x" >/dev/null 2>&1; CJ="$CC/.work/$(cat .work/ACTIVE)"
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]'
"$DL" phase readiness >/dev/null && ready_all && "$DL" phase planning >/dev/null
printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$CJ/specs/T-01.md"
jq -n '{cards:[{id:"T-01",title:"Second",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:[],scope:["src/**"],qa_scope:["it/**"],
  verify:"test -d src",qa_verify:"test -d it",acceptance:["AC-1: x"],context:"c",attempts:0,notes:[]}]}' > "$CJ/board.json"
"$DL" phase executing >/dev/null; WC="$("$DL" wt add T-01)"
mkdir -p "$WC/src" "$WC/it" && echo 2 > "$WC/src/b" && git -C "$WC" add src && git -C "$WC" commit -qm "feat: second TICKET-1 (T-01)"
"$DL" gate T-01 >/dev/null; echo t > "$WC/it/u" && git -C "$WC" add it && git -C "$WC" commit -qm "test: second TICKET-1 (T-01)"
"$DL" qa T-01 pass "AC-1 pass" >/dev/null && "$DL" review T-01 approve "ok" >/dev/null
out="$("$DL" integrate T-01 2>&1)"; rc=$?
[[ $rc == 5 && $out == *"every subject needs a TICKET-n reference"* && $out == *"NOT A CONFLICT"* && $out != *"Re-dispatch the dev"* ]] \
  && ok "a hook refusing every merge message: exit 5, the hook's own words, 'not a conflict' — never 're-dispatch the dev'" || bad "refused merge: rc=$rc $out"
[[ "$(jq -r '.cards[0].state' "$CJ/board.json")" == review && -z "$(git -C "$CJ/wt/_integration" status --porcelain)" ]] && ok "…nothing half-merged, the card still waits in review" || bad "state after refused merge"
"$DL" jobset '.settings.commit.merge_message="chore: merge {card} TICKET-1 — {title}"' >/dev/null
out="$("$DL" integrate T-01 2>&1)"; rc=$?
[[ $rc == 0 && "$(git -C "$CJ/wt/_integration" log -1 --format=%s)" == "chore: merge T-01 TICKET-1 — Second" ]] && ok "…Michael sets commit.merge_message and the merge goes through, the hook still run" || bad "merge_message: rc=$rc $out"
"$DL" phase aborted >/dev/null; "$DL" cleanup --all >/dev/null; cd "$R"

echo "tracker factory: a new tracker is one file in bin/trackers/"
TK="$HERE/kit/skills/deliver/bin/trackers/zz-test.mjs"; mkdir -p "$(dirname "$TK")"
cat > "$TK" <<'JS'
import { Tracker, registerTracker } from "../tracker.mjs";
import { appendFileSync } from "node:fs";
class LogTracker extends Tracker {
  async open() { appendFileSync(process.env.TK_LOG, "open\n"); }
  async sync(c) { appendFileSync(process.env.TK_LOG, `sync ${c ?? "*"}\n`); }
  async note(c, a, t) { appendFileSync(process.env.TK_LOG, `note ${c} ${a}\n`); }
  async branch(c) { appendFileSync(process.env.TK_LOG, `branch ${c}\n`); }
}
registerTracker("testlog", LogTracker);
JS
TKR="$TMP/tk"; mkdir -p "$TKR" && cd "$TKR" && git init -q -b main && echo '{"dispatch":"subagent","verify_full":"true","merge_mode":"local","tracker":{"kind":"nope"}}' > .deliver.json && git add -A && git commit -qm i
out="$("$DL" new "tk" "x" 2>&1)"; contains "an unknown tracker kind is refused at dl new" "$out" "not a known tracker"
contains "…and the message lists the registered ones, including the new file" "$out" "testlog"
echo '{"dispatch":"subagent","verify_full":"true","merge_mode":"local","tracker":{"kind":"testlog"}}' > .deliver.json
export TK_LOG="$TMP/tk.log"; "$DL" new "tk" "x" >/dev/null && TJ2="$TKR/.work/$(cat .work/ACTIVE)"
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]'
"$DL" phase readiness >/dev/null && ready_all && "$DL" phase planning >/dev/null
printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$TJ2/specs/T-01.md"
jq -n '{cards:[{id:"T-01",title:"one",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:[],scope:["src/**"],qa_scope:["it/**"],verify:"test -d .",qa_verify:"test -d .",acceptance:["AC-1: x"],context:"c",attempts:0,notes:[]}]}' > "$TJ2/board.json"
"$DL" phase executing >/dev/null; "$DL" wt add T-01 >/dev/null
grep -q "^open" "$TK_LOG" && grep -q "^sync T-01" "$TK_LOG" && grep -q "^branch T-01" "$TK_LOG" && ok "the new tracker receives open, sync and branch with no other change" || bad "tracker plugin calls: $(cat "$TK_LOG")"
rm -f "$TK"; unset TK_LOG; "$DL" phase aborted >/dev/null; "$DL" cleanup --all >/dev/null; cd "$R"

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
cd "$TMP/kn" && git init -q -b main && echo x > a && echo '{"dispatch":"subagent"}' > .deliver.json && git add -A && git commit -qm i
"$DL" new "know" "x" >/dev/null; KJ="$(cat .work/ACTIVE)"
"$DL" jobset '.stack=["javascript"] | .roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]'
contains "a lesson without what happened is refused (no lessons on assumptions)" "$("$DL" learn qa "Check rounding" --topic rounding 2>&1)" "a lesson needs what happened"
"$DL" learn qa "Check rounding at .5 boundaries — QA missed it in JOB-1" --topic rounding-boundaries --evidence "JOB-1: AC-4 failed in production at 2.5" >/dev/null
"$DL" phase readiness >/dev/null
grep -q "MUST \[api-errors#1\]: Map domain errors" ".work/$KJ/roles/backend.md" && ok "company standard's Must reaches the dev role" || bad "dev standard"
grep -q "MUST \[api-errors#1\]: Map domain errors" ".work/$KJ/roles/qa.md" && bad "standard leaked to a role it does not apply to" || ok "applies_to filters roles"
grep -q "Tests live in test/<area>/" ".work/$KJ/roles/qa.md" && ! grep -q "Every AC has a test named" ".work/$KJ/roles/qa.md" && ok "project standard overrides the company one" || bad "override"
grep -q "Never leak stack traces" ".work/$KJ/roles/reviewer.md" && ok "reviewer gets the review standards" || bad "reviewer standard"
grep -q "Background" ".work/$KJ/roles/backend.md" && bad "whole document pasted" || ok "only Must bullets are copied (rest by reference)"
grep -q "rounding at .5" ".work/$KJ/roles/qa.md" && ok "memory: a learned lesson reaches the next role cards" || bad "lesson"
# Brand DNA: a standards template to fill in; a rule still holding {{…}} is not a rule; each rule has an id
contains "dl knowledge new writes the brand template into the project's knowledge" "$("$DL" knowledge new brand-visual)" "written: $TMP/kn/.deliver/knowledge/brand-visual.md"
contains "…and never overwrites a filled-in one" "$("$DL" knowledge new brand-visual 2>&1)" "exists — edit it"
contains "…an unknown template is named with the ones there are" "$("$DL" knowledge new nope 2>&1)" "templates: brand-visual"
sed -i.bak 's#{{the tokens file, e.g. src/styles/tokens.css}}#src/styles/tokens.css#' .deliver/knowledge/brand-visual.md && rm -f .deliver/knowledge/brand-visual.md.bak
"$DL" phase readiness >/dev/null
grep -q "MUST \[BV-colours\]: Colours come only from the brand tokens in src/styles/tokens.css" ".work/$KJ/roles/reviewer.md" && ok "a filled-in brand rule reaches the reviewer with its id" || bad "BV-colours not in reviewer card"
grep -q "{{" ".work/$KJ/roles/reviewer.md" && bad "a placeholder reached a role card" || ok "rules still holding {{…}} reach no role card…"
contains "…and are named as not filled in" "$(cat ".work/$KJ/roles/reviewer.md")" "(not filled in yet, so not a rule: BV-type, BV-logo, BV-contrast, BV-voice)"
grep -q "BV-colours" ".work/$KJ/roles/backend.md" && bad "brand rule reached a role outside applies_to" || ok "brand rules follow applies_to (not the backend dev)"
contains "the reviewer card says each MUST is answered by id" "$(cat ".work/$KJ/roles/reviewer.md")" "Your review answers every MUST above by its id"
contains "the BA card says a standard settles only what it states" "$(cat ".work/$KJ/roles/ba.md")" 'source `standard: <file>`'
out="$("$DL" knowledge must reviewer)"; contains "dl knowledge must lists the rules a reviewer answers, by id" "$out" "BV-colours"$'\t'
contains "…company ones included" "$out" "api-errors#2"$'\t'"Never leak stack traces."
mkdir -p "$TMP/mphive/agents/god"; HIVE_ROOT="$TMP/mphive" "$DL" learn all "Name QA tests after the AC id" --topic qa-test-names --evidence "review: tests named t1..t9" >/dev/null
grep -q "/deliver lesson for kn .*Name QA tests after the AC id" "$TMP/mphive/agents/god/memory.md" \
  && ok "on the floor a lesson also lands in Michael's memory.md (mined into MemPalace)" || bad "lesson not in god memory"
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
[[ "$(jq length "$TMP/kgroot/idx.json")" == 3 ]] && ok "knowledge graph holds the 3 standards (lessons join once a PR accepted them)" || bad "kg docs: $(cat "$TMP/kgroot/idx.json")"

echo "QA pass runs the whole suite: tests that pass alone can break it together (seen live: two sovereign_support.py helpers)"
QF="$TMP/qafull"; mkdir -p "$QF" && cd "$QF" && git init -q -b main
# verify_full stands in for pytest: two test modules with the same name in one run break it (each set alone passes)
jq -n '{dispatch:"subagent", merge_mode:"local", verify_full:"test -z \"$(find test -name \"*.py\" | sed \"s#.*/##\" | sort | uniq -d)\""}' > .deliver.json
git add -A && git commit -qm i
"$DL" new "QA full" "x" >/dev/null 2>&1; QJ="$QF/.work/$(cat .work/ACTIVE)"
"$DL" jobset '.stack=["python"] | .roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:python-reviewer"}]' >/dev/null
"$DL" phase readiness >/dev/null && ready_all && "$DL" phase planning >/dev/null
printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$QJ/specs/T-01.md"
jq -n '{cards:[{id:"T-01",title:"fetcher",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:[],scope:["src/**","test/unit/**"],qa_scope:["test/it/**"],
  verify:"test -f test/unit/sovereign_support.py",qa_verify:"test -f test/it/sovereign_support.py",acceptance:["AC-1: x"],context:"c",attempts:0,notes:[]}]}' > "$QJ/board.json"
"$DL" phase executing >/dev/null; WQ="$("$DL" wt add T-01)"
mkdir -p "$WQ/src" "$WQ/test/unit" && echo x > "$WQ/src/fetcher.py" && echo 'def h(): return 1' > "$WQ/test/unit/sovereign_support.py" && git -C "$WQ" add -A && git -C "$WQ" commit -qm "T-01: fetcher"
"$DL" gate T-01 >/dev/null 2>&1
mkdir -p "$WQ/test/it" && echo 'def h(): return 2' > "$WQ/test/it/sovereign_support.py" && git -C "$WQ" add -A && git -C "$WQ" commit -qm "T-01 QA: it"
out="$("$DL" qa T-01 pass "AC-1 pass" 2>&1)"
contains "a QA pass is refused when the whole suite fails with the dev's and QA's tests together" "$out" "the whole suite (verify_full) fails on T-01's commit with the dev's and QA's tests together"
contains "…and says what to look for and whose file it is" "$out" "the one in qa_scope is QA's to rename"
[[ "$(jq -r '.cards[0].qa.verdict // "none"' "$QJ/board.json")" == none ]] && ok "…no pass was recorded" || bad "qa recorded: $(jq -c '.cards[0].qa' "$QJ/board.json")"
ls "$QJ"/gates/T-01-qa-*-full.log >/dev/null 2>&1 && ok "…the suite's log is kept beside the QA log" || bad "no full-suite log"
contains "a QA fail is recorded as before (the suite is run for a pass)" "$("$DL" qa T-01 fail "the suite breaks: two sovereign_support.py" 2>&1)" "qa: T-01 fail"
git -C "$WQ" mv test/it/sovereign_support.py test/it/it_support.py && git -C "$WQ" commit -qm "T-01 QA: rename the helper"
sed_qv='(.cards[0].qa_verify) = "test -f test/it/it_support.py"'; bedit "$QJ/board.json" "$sed_qv"
contains "after QA renames its helper the pass goes through" "$("$DL" qa T-01 pass "AC-1 pass" 2>&1)" "qa: T-01 pass"
[[ "$(jq -r '[.cards[0].gate.seconds, .cards[0].qa.seconds, .cards[0].qa.suite_seconds] | map(type) | join(",")' "$QJ/board.json")" == number,number,number ]] \
  && ok "the gate, QA's run and the whole suite each record how long they took" || bad "durations: $(jq -c '.cards[0] | {g: .gate.seconds, q: .qa.seconds, s: .qa.suite_seconds}' "$QJ/board.json")"
contains "dl timeline shows each card's test runs and how long Michael waited on them" "$("$DL" timeline 2>&1)" "Michael waited on test runs"
echo "baseline: the whole suite runs on the job branch before planning; already red → the human decides, at the start"
BL="$TMP/baseline"; mkdir -p "$BL" && cd "$BL" && git init -q -b main
echo '{"dispatch":"subagent","merge_mode":"local","verify_full":"test -f ok.txt"}' > .deliver.json && git add -A && git commit -qm i
"$DL" new "baseline" "x" >/dev/null 2>&1; BJ="$BL/.work/$(cat .work/ACTIVE)"
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]' >/dev/null
"$DL" phase readiness >/dev/null && ready_all
out="$("$DL" phase planning 2>&1)"
contains "planning is refused while the suite already fails before any card" "$out" "already fails on job/"
contains "…and says it is the human's call, at the start" "$out" "This is the human's call, at the start"
[[ "$(jq -r .phase "$BJ/job.json")" == readiness && "$(jq -r .baseline.result "$BJ/job.json")" == FAIL ]] && ok "…the job stays in readiness, the red baseline recorded" || bad "baseline: $(jq -c '{phase, baseline}' "$BJ/job.json")"
ls "$BJ"/gates/baseline-*.log >/dev/null 2>&1 && ok "…its log kept" || bad "no baseline log"
echo x > ok.txt && git add -A && git commit -qm "fix the base"
out="$("$DL" baseline 2>&1)"
contains "dl baseline runs it again once the base is fixed — the job branch takes the fix (fast-forward, no card yet)" "$out" "baseline: PASS"
[[ "$(git rev-parse "$(jq -r .branch "$BJ/job.json")")" == "$(git rev-parse main)" ]] && ok "…the job branch is at the fixed base" || bad "job branch not fast-forwarded"
expect_ok "…and planning goes ahead" "$DL" phase planning
echo "knowledge: lessons with what happened, into the project (and the shared repo) through the job's PR; a topic seen thrice becomes a standard"
SB="$TMP/shared.git"; git init -q --bare -b main "$SB"; SW="$TMP/shared-w"; git clone -q "$SB" "$SW" 2>/dev/null
mkdir -p "$SW/standards" && printf -- '---\napplies_to: [dev]\n---\n# Observability\n## Must\n- Log with the request id.\n' > "$SW/standards/observability.md"
git -C "$SW" add -A && git -C "$SW" commit -qm "docs: observability standard" && git -C "$SW" push -q origin main
KP="$TMP/kp"; mkdir -p "$KP/.deliver/knowledge" && cd "$KP" && git init -q -b main
jq -n --arg r "$SB" '{dispatch:"subagent", verify_full:"true", merge_mode:"local", knowledge:{repo:$r}}' > .deliver.json
printf '# Lessons — kp\n\n## 2026-09-01 · JOB-A · qa · topic: qa-verify-files\nqa_verify runs files.\n- evidence: gate T-02 FAIL\n\n## 2026-09-10 · JOB-B · lead · topic: qa-verify-files\nverify lists files.\n- evidence: gate T-01 FAIL\n' > .deliver/knowledge/lessons.md
git add -A && git commit -qm i
"$DL" new "Knowledge" "x" >/dev/null 2>&1; KJ2="$KP/.work/$(cat .work/ACTIVE)"
[[ -d $DELIVER_HOME/shared/shared.git/.git || -d $DELIVER_HOME/shared/shared/.git ]] && ok "dl new clones the shared knowledge repo (settings.knowledge.repo)" || bad "no shared clone: $(ls "$DELIVER_HOME/shared" 2>&1)"
"$DL" jobset '.stack=["javascript"] | .roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]' >/dev/null
"$DL" phase readiness >/dev/null && ready_all && "$DL" phase planning >/dev/null
grep -q "MUST \\[observability#1\\]: Log with the request id" "$KJ2/roles/backend.md" && ok "…its standards reach the role cards" || bad "shared standard not in the role card"
grep -q "qa_verify runs files" "$KJ2/roles/qa.md" && ok "accepted project lessons (.deliver/knowledge/lessons.md) reach the role cards" || bad "project lesson not in the role card"
printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$KJ2/specs/T-01.md"
jq -n '{cards:[{id:"T-01",title:"one",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:[],scope:["src/**"],qa_scope:["it/**"],
  verify:"test -f src/ok",qa_verify:"test -d it",acceptance:["AC-1: x"],context:"c",attempts:0,notes:[]}]}' > "$KJ2/board.json"
"$DL" phase executing >/dev/null; WK="$("$DL" wt add T-01)"
mkdir -p "$WK/src" && echo 1 > "$WK/src/a" && git -C "$WK" add -A && git -C "$WK" commit -qm "T-01: one"
"$DL" gate T-01 >/dev/null 2>&1; echo 1 > "$WK/src/ok" && git -C "$WK" add -A && git -C "$WK" commit -qm "T-01: ok"
"$DL" wt add T-01 >/dev/null; "$DL" gate T-01 >/dev/null
mkdir -p "$WK/it" && echo t > "$WK/it/t" && git -C "$WK" add -A && git -C "$WK" commit -qm "T-01 QA: it"
"$DL" qa T-01 pass "AC-1 pass" >/dev/null
# Brand DNA review: the reviewer answers every Must rule that applies (here the company's api-errors), one by one
out="$("$DL" review T-01 approve ok 2>&1)"; contains "an approval without the standards answers is refused" "$out" "api-errors#1 (api-errors.md) has no answer"
out="$("$DL" review T-01 approve ok --standards '{"api-errors#1":"ok","api-errors#2":"violated: the 500 handler returns err.stack"}' 2>&1)"
contains "an approval that violates a Must rule is refused" "$out" "api-errors#2 (api-errors.md) is violated"
contains "n_a needs its reason" "$("$DL" review T-01 approve ok --standards '{"api-errors#1":"ok","api-errors#2":"n_a"}' 2>&1)" "api-errors#2: n_a needs its reason"
contains "an id that is not a rule of this reviewer is refused" "$("$DL" review T-01 approve ok --standards '{"api-errors#1":"ok","api-errors#2":"ok","BV-nope":"ok"}' 2>&1)" "BV-nope is not a Must rule this reviewer answers to"
[[ "$(jq -r '.cards[0].reviews // [] | length' "$KJ2/board.json")" == 0 ]] && ok "…none of the refused reviews was recorded" || bad "refused review recorded"
"$DL" review T-01 approve ok --standards '{"api-errors#1":"ok","api-errors#2":"n_a: no HTTP handler in this change"}' >/dev/null \
  && [[ "$(jq -c '.cards[0].reviews[-1].standards' "$KJ2/board.json")" == '{"api-errors#1":"ok","api-errors#2":"n_a: no HTTP handler in this change"}' && "$(jq -r '.cards[0].review.verdict' "$KJ2/board.json")" == approve ]] \
  && ok "an approval answering every rule is recorded with the answers" || bad "standards review: $(jq -c '.cards[0].reviews' "$KJ2/board.json")"
out="$("$DL" learn qa "qa_verify and verify run test files, never a bare directory" --topic qa-verify-files --card T-01 2>&1)"
contains "dl learn --card attaches what happened (the card's gate FAIL from the event log)" "$(jq -r '.[0].evidence | join(" | ")' "$KJ2/lessons.json")" "gate: T-01 FAIL"
contains "…and a topic seen in three jobs asks for a standard" "$out" "PROMOTE: topic 'qa-verify-files' was learned in 3 jobs"
contains "a standard grows only out of recorded lessons" "$("$DL" knowledge promote nothing-learned "x" 2>&1)" "no lesson on topic 'nothing-learned'"
"$DL" knowledge promote qa-verify-files "verify and qa_verify run test files, never a bare directory" --applies-to qa,lead >/dev/null
"$DL" learn all "Name integration tests after the AC" --topic qa-test-names --evidence "review T-01: tests named t1..t9" --scope shared >/dev/null
"$DL" learn all "The stop-guard held Michael while three agents worked" --topic stop-guard-wait --evidence "stop hook fired 4 times with T-04 QA running" --scope kit >/dev/null
"$DL" followup "suite_v2._balanced accepts an empty industry_keys map" --card T-01 --evidence "T-05 QA report" >/dev/null
"$DL" integrate T-01 >/dev/null && "$DL" phase integrating >/dev/null && "$DL" verify-all >/dev/null && "$DL" phase closing >/dev/null
report_ok "$KJ2" Report
out="$("$DL" ship 2>&1)"; contains "ship goes through after the lessons commit (verify-all ran on the code; only .deliver/knowledge changed since)" "$out" "SHIPPED"
contains "the project's lessons file on main carries the lesson with its evidence" "$(cat .deliver/knowledge/lessons.md)" "topic: qa-verify-files"$'\n'"qa_verify and verify run test files, never a bare directory"$'\n'"- evidence: "
contains "…and the new standard, its rule under ## Must" "$(cat .deliver/knowledge/qa-verify-files.md 2>&1)" "## Must"$'\n'"- verify and qa_verify run test files, never a bare directory"
contains "…committed in the repo's commit format" "$(git log --format=%s -n 5)" "Lessons learned in JOB-"
! grep -q "stop-guard" .deliver/knowledge/lessons.md && ok "kit lessons do not become project rules" || bad "kit lesson in project lessons"
R2="$(cat "$KJ2/report.md")"
[[ $R2 == *"## Lessons learned"* && $R2 == *"## Feedback for the deliver kit"* && $R2 == *"The stop-guard held Michael"* && $R2 == *"### New standards"* && $R2 == *"## Follow-ups (found during the job, outside its scope)"* && $R2 == *"suite_v2._balanced"* ]] \
  && ok "the PR body lists the lessons, the new standard, the kit feedback and the follow-ups" || bad "report: $R2"
contains "after ship a lesson is refused, with why (seen live: one learned after ship reached no PR)" "$("$DL" learn ba "late" --topic late --evidence "x" 2>&1)" "the job is shipped"
contains "…a follow-up too" "$("$DL" followup "late" 2>&1)" "the job is shipped"
contains "shared lessons go to their own branch in the shared repo (a PR there)" "$(git -C "$SB" show "deliver/$(basename "$KJ2"):lessons.md" 2>&1)" "- project: kp"
"$DL" cleanup --all >/dev/null 2>&1
"$DL" new "Next" "x" >/dev/null 2>&1; KJ3="$KP/.work/$(cat .work/ACTIVE)"
"$DL" jobset '.stack=["javascript"] | .roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]' >/dev/null
"$DL" phase readiness >/dev/null
grep -q "MUST \\[qa-verify-files#1\\]: verify and qa_verify run test files" "$KJ3/roles/qa.md" && ok "the next job's QA card carries the new standard as a MUST rule" || bad "promoted standard not in the next role card"
"$DL" phase aborted >/dev/null; "$DL" cleanup --all >/dev/null 2>&1; cd "$R"
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
  printf '{"dispatch":"subagent","verify_full":"node --test","merge_mode":"%s"}\n' "$mode" > .deliver.json
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
  report_ok ".work/$j" report
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

echo "hooks on every platform: node launcher + SessionStart setup (the plugin's postinstall)"
contains "the node launcher runs a bash guard with its stdin and exit code (Windows: via Git Bash)" "$(printf '%s' '{"tool_input":{"command":"dl clarify CON-interface x"},"agent_id":"a1","cwd":"/"}' | node "$HERE/kit/hooks/deliver/run.mjs" bash-guard 2>&1; echo "rc=$?")" "rc=2"
contains "…an unknown hook name is a no-op, never a block" "$(echo '{}' | node "$HERE/kit/hooks/deliver/run.mjs" nope 2>&1; echo "rc=$?")" "rc=0"
SH="$TMP/setuphome"; SP="$TMP/setupproj"; mkdir -p "$SH" "$SP" && (cd "$SP" && git init -q -b main && echo '{"dispatch":"subagent"}' > .deliver.json)
su() { echo "{\"cwd\":\"$SP\"}" | CLAUDE_CONFIG_DIR="$SH" CLAUDE_PLUGIN_ROOT="$HERE/kit" CLAUDE_PLUGIN_DATA="$SH/data" CLAUDE_PROJECT_DIR="$SP" node "$HERE/kit/hooks/deliver/setup.mjs"; }
out="$(su)"; jq -e . >/dev/null <<<"$out" && ok "setup speaks JSON to Claude Code (systemMessage + additionalContext)" || bad "setup output: $out"
contains "first session after install: the env a plugin cannot set goes into ~/.claude/settings.json" "$(jq -r .env.GATEGUARD_EXEMPT_GLOBS "$SH/settings.json")" ".work/"
contains "…GateGuard lets the seats write their answer files (run 53: every out/ file was refused once)" "$(jq -r .env.GATEGUARD_EXEMPT_GLOBS "$SH/settings.json")" ".work/*/out/**"
contains "…and the user is told to restart once" "$(jq -r .systemMessage <<<"$out")" "restart Claude Code once"
contains "a /deliver repo gets no AI attribution — in that repo only (.claude/settings.local.json)" "$(jq -c .attribution "$SP/.claude/settings.local.json")" '{"commit":"","pr":""}'
[[ ! -e $SH/settings.json || "$(jq -r '.attribution // "none"' "$SH/settings.json")" == none ]] && ok "…never in the user's global settings" || bad "global attribution changed"
contains "missing prerequisites are named with the fix (ECC here)" "$(jq -r .systemMessage <<<"$out")" "ECC plugin is not installed"
out2="$(su)"; [[ "$(jq -r .systemMessage <<<"$out2")" != *"first-run setup"* && "$(jq -r .systemMessage <<<"$out2")" != *"settings.local.json"* ]] && ok "the setup runs once per version; later sessions only check" || bad "setup repeated: $out2"
mkdir -p "$SH/plugins"; echo '{"plugins":{"ecc@ecc":[{}],"deliver@deliver-floor":[{}]}}' > "$SH/plugins/installed_plugins.json"
[[ -z "$(su)" ]] && ok "all well: the setup prints nothing" || bad "setup output when all is well: $(su)"
(cd "$SP" && echo '{}' > .deliver.json); out3="$(su)"
if compgen -G "$HOME/.config/munder-difflin/config.json" >/dev/null; then ok "(Munder Difflin installed here — floor check skipped)"
else contains "a floor repo (the default) without the app: told how to install it or choose subagents" "$(jq -r .systemMessage <<<"$out3")" "Munder Difflin floor (the default) but the app is not set up"; fi
OLD="$TMP/oldhome"; mkdir -p "$OLD/.claude"; echo '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"/x/.claude/hooks/deliver/stop-guard.sh"}]}]}}' > "$OLD/.claude/settings.json"
HOME="$OLD" "$HERE/scripts/install.sh" --user >/dev/null 2>&1
contains "upgrading a copied install replaces the old .sh hook entries (no double guards)" "$(jq -c '[.hooks.Stop[].hooks[].command]' "$OLD/.claude/settings.json")" "[\"node \\\"$OLD/.claude/hooks/deliver\\\"/run.mjs stop-guard\"]"

echo "QA in parallel with the dev: QA writes the tests from the spec while the dev builds; they join after the gate"
QE="$TMP/qaearly"; mkdir -p "$QE" && cd "$QE" && git init -q -b main && echo '{"dispatch":"subagent","verify_full":"true","merge_mode":"local"}' > .deliver.json && git add -A && git commit -qm i
"$DL" new "qa early" "x" >/dev/null 2>&1; QJ="$QE/.work/$(cat .work/ACTIVE)"
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]' >/dev/null
"$DL" phase readiness >/dev/null && ready_all && "$DL" phase planning >/dev/null
printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$QJ/specs/T-01.md"
jq -n '{cards:[{id:"T-01",title:"one",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:[],scope:["src/**"],qa_scope:["it/**"],
  verify:"test -f src/a",qa_verify:"test -f it/t && test -f src/a",acceptance:["AC-1: x"],context:"c",attempts:0,notes:[]}]}' > "$QJ/board.json"
"$DL" phase executing >/dev/null; WQ="$("$DL" wt add T-01)"
contains "dl next asks for QA to start the moment the card is assigned (QA-WRITE)" "$("$DL" next)" "QA-WRITE T-01"
QW="$("$DL" wt qa T-01)"; [[ -d $QW && "$(git -C "$QW" symbolic-ref --short HEAD)" == *"--T-01-qa" ]] && ok "dl wt qa: QA's own worktree and branch, from the job branch" || bad "qa worktree: $QW"
[[ "$("$DL" next)" != *"QA-WRITE T-01"* ]] && ok "…asked once" || bad "QA-WRITE repeated"
mkdir -p "$QW/it" "$QW/src" && echo t > "$QW/it/t" && git -C "$QW" add it && git -C "$QW" commit -qm "T-01 QA: tests from the spec"
mkdir -p "$WQ/src" && echo a > "$WQ/src/a" && git -C "$WQ" add src && git -C "$WQ" commit -qm "T-01: a"
contains "QA's tests join only after the gate" "$("$DL" qa-join T-01 2>&1)" "T-01 is running"
"$DL" gate T-01 >/dev/null
contains "after the gate dl next says QA-JOIN" "$("$DL" next)" "QA-JOIN dl qa-join T-01"
echo x > "$QW/src/b" && git -C "$QW" add src && git -C "$QW" commit -qm "T-01 QA: oops"
contains "QA's branch may change only qa_scope" "$("$DL" qa-join T-01 2>&1)" "changed files outside qa_scope: src/b"
git -C "$QW" reset -q --hard HEAD~1
out="$("$DL" qa-join T-01 2>&1)"; contains "dl qa-join merges QA's tests into the card branch" "$out" "QA tests joined T-01"
[[ -f $WQ/it/t && ! -d $QW ]] && ok "…the tests are in the card worktree, QA's worktree is gone" || bad "after join: $(ls "$WQ")"
contains "…QA's commits must be recorded before the card goes back to the dev" "$("$DL" wt add T-01 2>&1)" "has QA commits that are not recorded yet"
expect_ok "the gate after the join counts QA's tests as QA's, not the dev's" "$DL" gate T-01
"$DL" qa T-01 pass "AC-1 pass" >/dev/null && "$DL" review T-01 approve ok >/dev/null
expect_ok "…and the card merges as before" "$DL" integrate T-01
"$DL" phase aborted >/dev/null; "$DL" cleanup --all >/dev/null 2>&1; cd "$R"

echo "dl timeline: where a job's time went, from the event log only"
TLJ="$TMP/tl"; mkdir -p "$TLJ"; printf '%s\n' \
  $'2026-10-06T10:00:00Z\tphase\treadiness' $'2026-10-06T10:00:00Z\tmd-send\treadiness ba#1 (business-analyst) → w1' \
  $'2026-10-06T10:02:00Z\tmd-done\treadiness ba#1: ok' $'2026-10-06T10:03:00Z\tphase\texecuting' \
  $'2026-10-06T10:03:00Z\tassign\tT-01 → backend-dev attempt=1' $'2026-10-06T10:03:00Z\tdispatch\tbackend-dev' \
  $'2026-10-06T10:05:00Z\tagent\tbackend-dev a1: done' $'2026-10-06T10:05:00Z\tgate\tT-01 PASS' $'2026-10-06T10:06:00Z\tqa\tT-01 pass' \
  $'2026-10-06T10:07:00Z\treview\tT-01 reviewer approve' $'2026-10-06T10:07:00Z\tintegrate\tT-01 merged' $'2026-10-06T10:10:00Z\tphase\tclosing' > "$TLJ/events.log"
TJ="$(node "$HERE/kit/skills/deliver/bin/timeline.mjs" "$TLJ" --json)"
contains "timeline: each seat's and agent's busy time and share of the job (floor and subagents alike)" "$(jq -c '[.seats[] | [.who, .busy_min, .share]]' <<<"$TJ")" '[["ba#1",2,20],["backend-dev",2,20]]'
contains "…the stretches nobody worked" "$(jq -c '{t:.total_min, n:.nobody_working_min}' <<<"$TJ")" '{"t":10,"n":6}'
contains "…and each card, assigned → merged" "$(jq -c '.cards[0]' <<<"$TJ")" '{"id":"T-01","dev":"2.0","gate_to_qa":"1.0","qa_to_review":"1.0","review_to_merge":"0.0","total":"4.0"}'

echo "releases: a change to the plugin raises its version and says what changed"
V="$(jq -r .version "$HERE/kit/.claude-plugin/plugin.json")"
grep -q "^## $V\b" "$HERE/CHANGELOG.md" && ok "CHANGELOG.md has an entry for the plugin's version ($V)" || bad "CHANGELOG.md has no '## $V' entry"
if BASE="$(git -C "$HERE" merge-base HEAD origin/main 2>/dev/null)"; then
  if git -C "$HERE" diff --quiet "$BASE" -- kit; then ok "kit/ unchanged since origin/main — no new version needed"
  else
    BV="$(git -C "$HERE" show "$BASE:kit/.claude-plugin/plugin.json" 2>/dev/null | jq -r .version)"
    [[ $V != "$BV" && "$(printf '%s\n%s\n' "$BV" "$V" | sort -V | tail -1)" == "$V" ]] \
      && ok "kit/ changed since origin/main and the version went up ($BV → $V): users get it" \
      || bad "kit/ changed since origin/main but the plugin version is still $V — raise it in kit/.claude-plugin/plugin.json and add a CHANGELOG.md entry, or installed users never get the change"
  fi
else ok "(no origin/main here — version check skipped)"; fi
UD="$TMP/updatedata"; mkdir -p "$UD" && echo x > "$UD/setup-0.3.0.done"
out="$(echo '{}' | CLAUDE_CONFIG_DIR="$TMP/updhome" CLAUDE_PLUGIN_ROOT="$HERE/kit" CLAUDE_PLUGIN_DATA="$UD" CLAUDE_PROJECT_DIR="$TMP" node "$HERE/kit/hooks/deliver/setup.mjs")"
contains "the first session after an update says the new version and where the changes are" "$(jq -r .systemMessage <<<"$out")" "updated to $V (was 0.3.0) — what changed: https://github.com/cantasci/deliver-floor/blob/main/CHANGELOG.md"
out="$(echo '{}' | CLAUDE_CONFIG_DIR="$TMP/updhome" CLAUDE_PLUGIN_ROOT="$HERE/kit" CLAUDE_PLUGIN_DATA="$UD" CLAUDE_PROJECT_DIR="$TMP" node "$HERE/kit/hooks/deliver/setup.mjs")"
[[ $out != *"updated to"* ]] && ok "…once" || bad "update notice repeated: $out"

echo "Windows"
grep -q '^\* text=auto eol=lf' "$HERE/.gitattributes" && ok ".gitattributes keeps LF in every checkout (a CRLF .sh breaks bash on Windows)" || bad ".gitattributes"
crlf="$(cd "$HERE" && git ls-files kit scripts tests | grep -E '\.(sh|mjs|cjs|json|md)$|/bin/dl$' | xargs grep -lI $'\r' 2>/dev/null | head -3)"
[[ -z $crlf ]] && ok "no CRLF in any script or config" || bad "CRLF in: $crlf"
contains "Git Bash is found on Windows: CLAUDE_CODE_GIT_BASH_PATH, next to git.exe, the install folders — or reported missing" "$(node --input-type=module -e '
import { findBash } from "'"$HERE"'/kit/hooks/deliver/bash-path.mjs";
const ex = (p) => ["G:/Git/bin/bash.exe","C:/PF/Git/bin/bash.exe"].includes(p.replace(/\\/g,"/")), f = (p) => (p ?? "null").replace(/\\/g,"/");
console.log([findBash({}, "linux"), f(findBash({CLAUDE_CODE_GIT_BASH_PATH:"G:/Git/bin/bash.exe"}, "win32", ex, () => "")),
  f(findBash({}, "win32", ex, () => "C:/PF/Git/cmd/git.exe\r\n")), f(findBash({ProgramFiles:"C:/PF"}, "win32", ex, () => { throw 1; })),
  f(findBash({}, "win32", () => false, () => ""))].join(" "))')" "bash G:/Git/bin/bash.exe C:/PF/Git/bin/bash.exe C:/PF/Git/bin/bash.exe null"
lp() { bash -c '. "$1/kit/hooks/deliver/lib.sh"; np "$2"' _ "$HERE" "$1"; }
[[ "$(lp 'C:\Users\a b\repo')" == "/c/Users/a b/repo" && "$(lp 'C:/x/y')" == "/c/x/y" && "$(lp /home/u)" == "/home/u" ]] \
  && ok "hooks compare Windows paths (C:\\… from Claude Code) with Git Bash paths (/c/… from dl)" || bad "np: $(lp 'C:\Users\a b\repo')"
WG="$(jq -n --arg f 'C:\x\.work\JOB-1\board.json' '{tool_input:{file_path:$f},cwd:"C:\\x"}')"
contains "write-guard reads a Windows file path as absolute (not glued to the cwd)" "$(bash -c '. "$1/kit/hooks/deliver/lib.sh"; input=$2; hkp .tool_input.file_path' _ "$HERE" "$WG")" "/c/x/.work/JOB-1/board.json"

echo "plugin packaging"
claude_ok=0; command -v claude >/dev/null && claude_ok=1
jq -e '.name=="deliver"' "$HERE/kit/.claude-plugin/plugin.json" >/dev/null && ok "plugin manifest names the plugin deliver" || bad "plugin.json"
jq -e '.plugins[] | select(.name=="deliver" and .source=="./kit")' "$HERE/.claude-plugin/marketplace.json" >/dev/null && ok "the repo is a marketplace offering ./kit" || bad "marketplace.json"
gen="$(jq -S '{hooks: ((.hooks | (.. | objects | select(has("command")) | .command) |= sub("__HOOKS_DIR__"; "\"${CLAUDE_PLUGIN_ROOT}/hooks/deliver\"")))}' "$HERE/kit/settings.hooks.json")"
[[ "$gen" == "$(jq -S . "$HERE/kit/hooks/hooks.json")" ]] && ok "plugin hooks.json matches settings.hooks.json" \
  || bad "kit/hooks/hooks.json is stale — regenerate it from kit/settings.hooks.json (docs/02-setup.md)"
for f in "$HERE"/kit/hooks/deliver/*.sh "$HERE/kit/skills/deliver/bin/dl"; do [[ -x $f ]] || bad "not executable in the plugin: $f"; done
if [[ $claude_ok -eq 1 ]]; then
  out="$(claude plugin validate "$HERE/kit" 2>&1; claude plugin validate "$HERE" 2>&1)"
  [[ $out == *"Validation passed"* && $out != *"Found "*warning* && $out != *rror* ]] && ok "claude plugin validate: plugin and marketplace pass without warnings" || bad "plugin validate: $out"
fi
PH="$TMP/phome"; mkdir -p "$PH"; INST_P="$HERE/scripts/install.sh"
HOME="$PH" expect_ok "install --plugin (settings only)" "$INST_P" --user --plugin
[[ ! -e $PH/.claude/skills/deliver && ! -e $PH/.claude/agents/qa-tester.md && "$(jq '.hooks // {} | length' "$PH/.claude/settings.json")" == 0 ]] \
  && ok "…copies no files and adds no hooks (the plugin brings them)" || bad "install --plugin copied files or hooks"
[[ "$(jq -r .env.GATEGUARD_EXEMPT_GLOBS "$PH/.claude/settings.json")" == .work/* && "$(jq -c .attribution "$PH/.claude/settings.json")" == '{"commit":"","pr":""}' ]] \
  && ok "…but sets what a plugin cannot: env and attribution" || bad "install --plugin settings: $(cat "$PH/.claude/settings.json")"
HOME="$PH" expect_ok "uninstall --plugin" "$INST_P" --user --plugin --uninstall
[[ "$(jq -c 'del(.x)' "$PH/.claude/settings.json")" == '{}' ]] && ok "…removes them again" || bad "uninstall --plugin left: $(cat "$PH/.claude/settings.json")"

echo "one copy of the kit: the plugin — a copy in ~/.claude is deleted"
CK="$TMP/ckhome"; mkdir -p "$CK"; HOME="$CK" "$INST_P" --user >/dev/null 2>&1
mkdir -p "$CK/.claude/agents"; printf -- '---\nname: my-agent\ndescription: mine\n---\n' > "$CK/.claude/agents/my-agent.md"
printf -- '---\nname: database-dev\ndescription: my own database agent, not the kit'"'"'s\n---\n' > "$CK/.claude/agents/database-dev.md"
jq '.hooks.PreToolUse += [{"matcher":"Bash","hooks":[{"type":"command","command":"my-own-hook.sh"}]}]' "$CK/.claude/settings.json" > "$TMP/s" && mv "$TMP/s" "$CK/.claude/settings.json"
mkdir -p "$CK/.claude/plugins"; echo '{"plugins":{"deliver@deliver-floor":[{"installPath":"x"}]}}' > "$CK/.claude/plugins/installed_plugins.json"
out="$(echo '{}' | CLAUDE_CONFIG_DIR="$CK/.claude" CLAUDE_PLUGIN_ROOT="$HERE/kit" CLAUDE_PLUGIN_DATA="$CK/pdata" CLAUDE_PROJECT_DIR="$TMP" node "$HERE/kit/hooks/deliver/setup.mjs")"
[[ ! -e $CK/.claude/skills/deliver && ! -e $CK/.claude/hooks/deliver && ! -e $CK/.claude/agents/qa-tester.md ]] \
  && ok "the plugin's session deletes the copied kit: skill, hooks, the kit's agents" || bad "copy left: $(ls "$CK/.claude/skills" "$CK/.claude/hooks" "$CK/.claude/agents")"
[[ -f $CK/.claude/agents/my-agent.md && -f $CK/.claude/agents/database-dev.md ]] && ok "…never the user's own agents, even one named like a kit agent" || bad "user agents deleted"
[[ "$(jq -c '[.hooks // {} | .[][] | .hooks[].command]' "$CK/.claude/settings.json")" == '["my-own-hook.sh"]' ]] \
  && ok "…removes the copy's hook entries from settings.json, keeps the user's" || bad "settings hooks: $(jq -c .hooks "$CK/.claude/settings.json")"
ls "$CK"/.claude/settings.json.deliver-backup-* >/dev/null 2>&1 && ok "…with a backup of settings.json" || bad "no settings backup"
contains "…and says so once" "$(jq -r .systemMessage <<<"$out")" "the plugin is the only copy of the kit now"
contains "the stable dl in the plugin's data dir runs this version's dl" "$(cat "$CK/pdata/bin/dl")" "exec bash \"$HERE/kit/skills/deliver/bin/dl\" \"\$@\""
[[ -x $CK/pdata/bin/dl ]] && contains "…and works" "$("$CK/pdata/bin/dl" playbook)" "$HERE/kit/skills/deliver/SKILL.md" || bad "launcher not executable"
out="$(echo '{}' | CLAUDE_CONFIG_DIR="$CK/.claude" CLAUDE_PLUGIN_ROOT="$HERE/kit" CLAUDE_PLUGIN_DATA="$CK/pdata" CLAUDE_PROJECT_DIR="$TMP" node "$HERE/kit/hooks/deliver/setup.mjs")"
[[ $out != *"only copy"* ]] && ok "…a second session finds nothing to remove" || bad "repeated: $out"
NP="$TMP/noplug"; mkdir -p "$NP"; HOME="$NP" "$INST_P" --user >/dev/null 2>&1
echo '{}' | CLAUDE_CONFIG_DIR="$NP/.claude" CLAUDE_PLUGIN_DATA="$NP/pdata" CLAUDE_PROJECT_DIR="$TMP" node "$NP/.claude/hooks/deliver/setup.mjs" >/dev/null
[[ -e $NP/.claude/skills/deliver ]] && ok "a copied kit without the plugin is the user's choice: left alone" || bad "copied-only kit deleted"
expect_ok "the plugin's bin/dl (on Claude Code's PATH) runs this version's dl" "$HERE/kit/bin/dl" help
contains "dl version names the plugin version" "$("$HERE/kit/bin/dl" version)" "deliver $V"
MB="$TMP/mbplug/plugins/cache/deliver-floor/deliver/9.9.9/skills"; mkdir -p "$MB" && cp -R "$HERE/kit/skills/deliver" "$MB/"
bash "$MB/deliver/bin/md-brief.sh" "$TMP/mbhive" >/dev/null
out="$(cat "$TMP/mbhive/CLAUDE.md")"
[[ $out == *'`/deliver:deliver <the request>`'* && $out == *"$TMP/mbplug/plugins/data/deliver-deliver-floor/bin/dl"* && $out != *9.9.9* ]] \
  && ok "Michael's brief with the plugin: /deliver:deliver and the stable dl — no version path an update leaves behind" || bad "plugin brief: $(grep -n 'deliver' "$TMP/mbhive/CLAUDE.md" | head -5)"
bash "$HERE/kit/skills/deliver/bin/md-brief.sh" "$TMP/mbhive2" >/dev/null
grep -q '`/deliver <the request>`' "$TMP/mbhive2/CLAUDE.md" && ok "…a copied kit's brief keeps /deliver and its own paths" || bad "copied brief"

echo "the human's slash commands (/deliver:<name>): no dl in a terminal"
for d in "$HERE"/kit/skills/*/; do
  n="$(basename "$d")"; [[ $n == deliver ]] && continue; f="$d/SKILL.md"
  grep -q '^disable-model-invocation: true$' "$f" && grep -qF 'allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/run.sh":*)' "$f" && grep -qF "bash \"\${CLAUDE_SKILL_DIR}/run.sh\" $n <<'DELIVER_TYPED_7Q2'" "$f" && [[ -x $d/run.sh ]] \
    || bad "/deliver:$n: needs disable-model-invocation, its run.sh and the permission rule that matches its command"
done; ok "every /deliver:<name> is the human's only (disable-model-invocation), runs its own run.sh with the rule that lets it run"
SR="$TMP/slashrepo"; mkdir -p "$SR" && (cd "$SR" && git init -q -b main && echo x > a && git add -A && git commit -qm i && echo '{"dispatch":"subagent"}' > .deliver.json)
sl() { (cd "$SR" && printf '%s' "$2" | env -u AGENT_ID bash "$HERE/kit/skills/$1/run.sh" "$1"); }
contains "/deliver:status with no job: dl's words and that nothing was done — never an empty answer (a failed command shows nothing)" "$(sl status '')" "no active job — start one with /deliver:new <request>"
(cd "$SR" && sl status '' >/dev/null; echo $? > "$TMP/slrc"); [[ "$(cat "$TMP/slrc")" == 0 ]] && ok "…exit 0 even when dl refuses (Claude Code drops a failed command's output)" || bad "slash exit code"
contains "/deliver:new with no job active" "$(sl new 'build it')" "NO ACTIVE JOB"
(cd "$SR" && env -u AGENT_ID "$DL" new t "r" >/dev/null 2>&1)
contains "/deliver:new with a job active says which" "$(sl new 'build it')" "ACTIVE JOB — a new job cannot start while this one is active"
TXT='because "the floor" is $HOME `id` it'"'"'s fine'
sl mode "munder $TXT" >/dev/null
contains "what the human types reaches dl exactly — quotes, \$, backticks (never a shell's parsing)" "$(grep $'\tdispatch\t' "$SR/.work/$(cat "$SR/.work/ACTIVE")/events.log" | tail -1)" "munder — $TXT"
contains "a command without what it needs says how to use it" "$(sl answer 'X-1')" "usage: /deliver:answer <question id> <your answer>"
SJ="$(cat "$SR/.work/ACTIVE")"; out="$(sl abort 'trying it')"
contains "/deliver:abort stops the job" "$out" "job $SJ aborted (trying it)"
[[ "$(jq -r .phase "$SR/.work/$SJ/job.json")" == aborted && ! -f $SR/.work/ACTIVE ]] && ok "…aborted, nothing active: a new job can start" || bad "abort: $(jq -r .phase "$SR/.work/$SJ/job.json")"
contains "…logged with who and why" "$(grep $'\tabort\t' "$SR/.work/$SJ/events.log")" "trying it"
expect_ok "…and the next job starts" bash -c "cd '$SR' && env -u AGENT_ID '$DL' new t2 r2"
contains "Claude may not abort for the human (bash-guard)" "$(bg '"$DL" abort "x"')" "rc=2"
contains "…nor pose as the human's slash command" "$(bg 'DELIVER_HUMAN_CMD=1 "$DL" card T-01 retry')" "rc=2"

echo "a stopped agent is continued, not replaced: dl agents reads Claude Code's own subagent transcripts"
AC="$TMP/agconf"; AJ="$SR/.work/$(cat "$SR/.work/ACTIVE")"; AJN="$(basename "$AJ")"
mkag() { # mkag <session> <agent id> <type> <prompt> <ts> [api error text]
  local d="$AC/projects/-p/$1/subagents"; mkdir -p "$d"
  jq -nc --arg a "$2" --arg s "$1" --arg p "$4" --arg t "$5" '{type:"user",agentId:$a,sessionId:$s,isSidechain:true,timestamp:$t,message:{role:"user",content:$p}}' > "$d/agent-$2.jsonl"
  if [[ -n ${6:-} ]]; then jq -nc --arg t "$5" --arg e "$6" '{type:"assistant",timestamp:$t,isApiErrorMessage:true,message:{content:[{type:"text",text:$e}]}}' >> "$d/agent-$2.jsonl"
  else jq -nc --arg t "$5" '{type:"assistant",timestamp:$t,message:{content:[{type:"text",text:"working"}]}}' >> "$d/agent-$2.jsonl"; fi
  jq -nc --arg ty "$3" '{agentType:$ty, description:"x"}' > "$d/agent-$2.meta.json"
}
mkag s1 aaa1 backend-dev "CARD: {\"id\":\"T-01\"} WORKTREE: $AJ/wt/T-01" 2026-10-07T09:00:00Z
mkag s1 aaa2 backend-dev "CARD: {\"id\":\"T-01\"} WORKTREE: $AJ/wt/T-01" 2026-10-07T09:30:00Z "Claude AI usage limit reached|1791370800"
mkag s1 bbb1 qa-tester "Role: QA/Test for card T-02. ROLE CARD: $AJ/roles/qa.md" 2026-10-07T09:10:00Z
mkag s2 ccc1 backend-dev "CARD: T-01 WORKTREE: /elsewhere/.work/JOB-other/wt/T-01" 2026-10-07T10:00:00Z
mkag s1 ddd1 business-analyst "MODE: PLAN ROLE CARD: $AJ/roles/ba.md" 2026-10-07T08:00:00Z
out="$(cd "$SR" && CLAUDE_CONFIG_DIR="$AC" env -u AGENT_ID "$DL" agents 2>&1)"
contains "dl agents finds the agent of each card from Claude Code's transcripts (jobs started before this, too)" "$out" "aaa2"
[[ $out != *aaa1* && $out != *ccc1* ]] && ok "…the newest one of each role on the card, never another job's" || bad "agents: $out"
contains "…with its session" "$out" "s1"
contains "…and an agent that ended on an API error (a usage limit) is shown as such" "$out" "API ERROR: Claude AI usage limit reached"
contains "…QA's agent on its card" "$out" "bbb1"
contains "dl agents T-01 narrows to one card" "$(cd "$SR" && CLAUDE_CONFIG_DIR="$AC" env -u AGENT_ID "$DL" agents T-02 2>&1 | grep -c bbb1)" "1"
contains "dl agents --all lists the plan steps' agents too" "$(cd "$SR" && CLAUDE_CONFIG_DIR="$AC" env -u AGENT_ID "$DL" agents --all 2>&1)" "ddd1"
contains "no transcript: said so" "$(cd "$SR" && CLAUDE_CONFIG_DIR="$TMP/none" env -u AGENT_ID "$DL" agents 2>&1)" "no subagent of this job found"
grep -q 'SendMessage' "$HERE/kit/skills/deliver/SKILL.md" && grep -q 'A usage limit or an API error is not the card' "$HERE/kit/skills/deliver/SKILL.md" \
  && ok "the playbook continues a stopped agent with SendMessage before a new one, and a limit is not the card's failure" || bad "playbook resume rule"

echo "live tests: the prepared human picks the answer that fits best"
PA="$HERE/tests/pick-answer.mjs"; HA="$HERE/examples/watchlist-poc/HUMAN_ANSWERS.json"
q='For an upgrade, what is notchCalculator(previous, current).notches: signed like notchChange (A- -> A+ gives -2) or an absolute count with the sign carried only by `direction`? Downgrades (BBB+ -> BB+ = 3) are the same under both.'
contains "a sign question quoting the downgrade example gets the sign answer, not the miscount one (seen live)" "$(node "$PA" "$HA" "$q")" "signed exactly like notchChange"
echo '[{"topic":"a","match":"alpha|beta","answer":"A"},{"topic":"b","match":"beta|gamma","answer":"B"}]' > "$TMP/ha.json"
node "$PA" "$TMP/ha.json" "beta only" >/dev/null 2>&1; [[ $? == 2 ]] && ok "two answers fitting equally is no answer (a person must decide)" || bad "tie answered"
node "$PA" "$HA" "What colour is the logo?" >/dev/null 2>&1; [[ $? == 2 ]] && ok "a question no answer fits is left to a person" || bad "unmatched answered"
q='Is any banking regulation or internal policy (e.g. model-risk validation of the WL thresholds, four-eyes sign-off) a constraint on this slice beyond C1-C8?'
node "$PA" "$HA" "$q" >/dev/null 2>&1; [[ $? == 2 ]] && ok "one shared word is no answer: the compliance question is not answered with the thresholds answer (seen live)" || bad "compliance question got: $(node "$PA" "$HA" "$q")"
contains "a readiness item id names its answer" "$(node "$PA" "$HA" "Which comes first?" PRD-priority)" "REQ-06-02 comes first"

echo "install / uninstall"
INST="$HERE/scripts/install.sh"
expect_ok "install --user" "$INST" --user
expect_ok "install is idempotent" "$INST" --user
[[ "$(jq '[.hooks[][] .hooks[] | select(.command|test("hooks/deliver"))] | length' "$HOME/.claude/settings.json")" == 6 ]] && ok "6 hooks (5 guards + the SessionStart setup), no duplicates" || bad "hook count"
[[ -f $HOME/.claude/agents/qa-tester.md ]] && ok "qa-tester agent installed" || bad "qa-tester missing"
[[ "$(jq -r .env.GATEGUARD_EXEMPT_GLOBS "$HOME/.claude/settings.json")" == .work/* ]] && ok "GateGuard exemption set" || bad "env"
[[ "$(jq -c .attribution "$HOME/.claude/settings.json")" == '{"commit":"","pr":""}' ]] && ok "Claude Code commit/PR attribution switched off" || bad "attribution"
echo "# local edit" >> "$HOME/.claude/skills/deliver/SKILL.md"
"$INST" --user >/dev/null
ls -d "$HOME"/.claude/skills/* | gq -v '/deliver$' && bad "backup left inside skills/" || ok "backups stay out of skills/"
ls "$HOME"/.claude/.deliver-backups/*/skills/deliver/SKILL.md >/dev/null 2>&1 && ok "changed skill backed up" || bad "backup missing"
jq '.hooks.Stop += [{"hooks":[{"type":"command","command":"/usr/bin/true"}]}] | .env.MINE="1"' "$HOME/.claude/settings.json" > "$TMP/s" && mv "$TMP/s" "$HOME/.claude/settings.json"
expect_ok "uninstall" "$INST" --user --uninstall
[[ ! -e $HOME/.claude/skills/deliver && "$(jq -c '[.hooks.Stop[].hooks[].command]' "$HOME/.claude/settings.json")" == '["/usr/bin/true"]' && "$(jq -r .env.MINE "$HOME/.claude/settings.json")" == 1 ]] \
  && ok "uninstall keeps foreign hooks and env" || bad "uninstall: $(cat "$HOME/.claude/settings.json")"
"$INST" --user >/dev/null
# A reinstall keeps what the user changed in the installed config.json: it moves into $DELIVER_HOME/config.json
IC="$HOME/.claude/skills/deliver/config.json"
jq '.dispatch = "subagent" | .munder.model = "opus"' "$IC" > "$IC.t" && mv "$IC.t" "$IC"
out="$("$INST" --user 2>&1)"
[[ $out != *"cannot"* ]] && ok "a reinstall in the same second as the last one backs up beside the old backup" || bad "reinstall: $out"
contains "a reinstall keeps the user's changes to the installed config" "$out" "kept your settings: $DELIVER_HOME/config.json"
[[ "$(jq -c . "$DELIVER_HOME/config.json")" == '{"dispatch":"subagent","munder":{"model":"opus"}}' ]] \
  && ok "…in \$DELIVER_HOME/config.json, only what they changed" || bad "user config: $(cat "$DELIVER_HOME/config.json")"
cmp -s "$IC" "$SDIR/config.json" && ok "…and the installed config is the shipped defaults again" || bad "installed config not reset: $(diff "$IC" "$SDIR/config.json" | head -5)"
out="$("$INST" --user 2>&1)"; [[ $out == *"unchanged: $HOME/.claude/skills/deliver"* && $out != *"kept your settings"* ]] \
  && ok "an untouched reinstall moves nothing" || bad "untouched reinstall: $out"
sleep 1; jq '.munder.model = "haiku"' "$IC" > "$IC.t" && mv "$IC.t" "$IC"   # edited again later, in the installed copy
"$INST" --user >/dev/null 2>&1
[[ "$(jq -c . "$DELIVER_HOME/config.json")" == '{"dispatch":"subagent","munder":{"model":"haiku"}}' ]] \
  && ok "…the newer edit wins: a later change in the installed copy updates the user file, the rest stays" || bad "newer edit lost: $(cat "$DELIVER_HOME/config.json")"
cmp -s "$IC" "$SDIR/config.json" && ok "…and several reinstalls within one second each still reset the installed config" || bad "installed config not reset (2)"
sleep 1; jq '.munder.model = "opus"' "$DELIVER_HOME/config.json" > "$DELIVER_HOME/c.t" && mv "$DELIVER_HOME/c.t" "$DELIVER_HOME/config.json"
"$INST" --user >/dev/null 2>&1
[[ "$(jq -r .munder.model "$DELIVER_HOME/config.json")" == opus ]] && ok "…and an edit of the user file itself is never undone by a reinstall" || bad "user file edit undone: $(cat "$DELIVER_HOME/config.json")"
# dl reads the user's settings over the shipped defaults, and a repo's .deliver.json over both
for u in u1 u2; do mkdir -p "$TMP/$u" && git -C "$TMP/$u" init -q -b main && git -C "$TMP/$u" commit -q --allow-empty -m i; done
echo '{"dispatch":"munder"}' > "$TMP/u2/.deliver.json"
for u in u1 u2; do (cd "$TMP/$u" && AGENT_ID=god "$HOME/.claude/skills/deliver/bin/dl" new "u" "x" >/dev/null 2>&1); done
contains "dl new takes the user's settings (\$DELIVER_HOME/config.json)" "$(jq -c '{d:.settings.dispatch,m:.settings.munder.model}' "$TMP"/u1/.work/JOB-*/job.json)" '{"d":"subagent","m":"opus"}'
contains "…and a repo's .deliver.json over them" "$(jq -c '{d:.settings.dispatch,m:.settings.munder.model}' "$TMP"/u2/.work/JOB-*/job.json)" '{"d":"munder","m":"opus"}'
out="$("$HERE/scripts/doctor.sh" "$R" 2>&1)"
contains "doctor sees the install and the repo" "$out" "✔"$'\033[0m'" user: hook write-guard"
[[ $out != *"hook "*" not in "* ]] && ok "…every installed hook found (none reported missing)" || bad "doctor misses hooks: $(grep 'not in' <<<"$out")"
mkdir -p "$HOME/.config/munder-difflin"; echo '{}' > "$HOME/.claude.json"
# Roles on other vendors' CLIs and how Claude signs in
VR="$TMP/vendor"; mkdir -p "$VR" && git -C "$VR" init -q -b main
echo '{"dispatch":"subagent","roles":{"backend":{"provider":"codex","model":"gpt-5-codex"}}}' > "$VR/.deliver.json"
contains "doctor: a role on another vendor's CLI needs the floor" "$("$HERE/scripts/doctor.sh" "$VR" 2>&1)" "role backend runs on codex — other CLIs run only on the Munder Difflin floor"
echo '{"dispatch":"munder","roles":{"backend":{"provider":"codex","model":"gpt-5-codex"}}}' > "$VR/.deliver.json"
contains "…and its CLI on PATH" "$(PATH="/usr/bin:/bin:$(dirname "$(command -v node)")" "$HERE/scripts/doctor.sh" "$VR" 2>&1)" "role backend runs on codex but 'codex' is not on PATH"
mkdir -p "$TMP/fakebin" && printf '#!/bin/sh\nexit 0\n' > "$TMP/fakebin/codex" && chmod +x "$TMP/fakebin/codex"
contains "…found when installed" "$(PATH="$TMP/fakebin:$PATH" "$HERE/scripts/doctor.sh" "$VR" 2>&1)" "role backend runs on codex ($TMP/fakebin/codex)"
na() { env -u ANTHROPIC_BASE_URL -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN -u CLAUDE_CODE_OAUTH_TOKEN -u CLAUDE_CODE_USE_BEDROCK -u CLAUDE_CODE_USE_VERTEX "$@"; }
contains "doctor names how Claude signs in: an API key" "$(na ANTHROPIC_API_KEY=x "$HERE/scripts/doctor.sh" 2>&1)" "Anthropic API key (ANTHROPIC_API_KEY)"
contains "…a gateway (another vendor's models behind ANTHROPIC_BASE_URL)" "$(na ANTHROPIC_BASE_URL=http://gw ANTHROPIC_API_KEY=x "$HERE/scripts/doctor.sh" 2>&1)" "an LLM gateway (ANTHROPIC_BASE_URL)"
contains "…Bedrock" "$(na CLAUDE_CODE_USE_BEDROCK=1 "$HERE/scripts/doctor.sh" 2>&1)" "Amazon Bedrock"
contains "doctor finds Munder Difflin and warns about Claude Code's unfinished first run" "$("$HERE/scripts/doctor.sh" 2>&1)" "first run is not completed"
echo '{"hasCompletedOnboarding":true}' > "$HOME/.claude.json"
contains "…and is satisfied once it is done" "$("$HERE/scripts/doctor.sh" 2>&1)" "first run completed"
echo '{"orchestratorMaySpawn":true}' > "$HOME/.config/munder-difflin/config.json"
out="$("$HERE/scripts/doctor.sh" 2>&1)"
contains "doctor: seats would be reaped after 20 idle minutes" "$out" "workerIdleTimeoutMinutes is 20"
contains "doctor: a team would queue behind 4 workers" "$out" "maxConcurrentWorkers is 4"
echo '{"orchestratorMaySpawn":true,"workerIdleTimeoutMinutes":480,"maxConcurrentWorkers":12}' > "$HOME/.config/munder-difflin/config.json"
out="$("$HERE/scripts/doctor.sh" 2>&1)"
[[ $out == *"seats are not sent home"* && $out == *"room for a whole team"* && $out == *"Michael may seat people"* ]] && ok "doctor: satisfied with the settings init writes" || bad "doctor seats: $out"
# Which Munder Difflin init installed: upstream's build has no floor fixes (seats never start) — the build tells
MD="$TMP/md"; git init -q "$MD"; git -C "$MD" remote add origin https://example.test/upstream/munder-difflin
mkdir -p "$MD/out/main"; echo 'console.log("upstream")' > "$MD/out/main/index.js"; git -C "$MD" add -A; git -C "$MD" commit -qm md
out="$(MUNDER_DIR="$MD" "$HERE/scripts/doctor.sh" 2>&1)"
contains "doctor names where init's Munder Difflin comes from" "$out" "init's Munder Difflin: https://example.test/upstream/munder-difflin @"
contains "…flags a build without the floor fixes (seats would never start)" "$out" "built without the floor fixes"
contains "…and a build that is not from the checked-out commit" "$out" "build is not from the checked-out commit"
echo 'const firstPrompt = "Your task was sent to your hive inbox by god. Read your inbox now";' > "$MD/out/main/index.js"
git -C "$MD" rev-parse HEAD > "$MD/out/.built-from"
out="$(MUNDER_DIR="$MD" "$HERE/scripts/doctor.sh" 2>&1)"
[[ $out == *"built with the floor fixes"* && $out != *"not from the checked-out commit"* && $out != *"built without"* ]] \
  && ok "doctor: satisfied with the fork's build of the checked-out commit" || bad "doctor munder source: $out"

echo
echo "result: $pass passed, $failn failed"
[[ $failn -eq 0 ]]
