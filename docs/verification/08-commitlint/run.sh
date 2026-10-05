#!/usr/bin/env bash
# dl against a repo with REAL commitlint (@commitlint/config-conventional) behind a husky-style commit-msg hook
set -uo pipefail
HERE=/home/user/skills-shop; DL="$HERE/kit/skills/deliver/bin/dl"
T="$(mktemp -d)"; export HOME="$T/home" DELIVER_HOME="$T/home/.deliver" AGENT_ID=god; mkdir -p "$HOME"
R="$T/repo"; mkdir -p "$R" && cd "$R" && git init -q -b main
git config user.email dev@example.com; git config user.name dev
cp -R /tmp/claude-0/cl/node_modules . ; cp /tmp/claude-0/cl/package.json .
echo 'export default { extends: ["@commitlint/config-conventional"] };' > commitlint.config.mjs
printf 'node_modules\n' > .gitignore
printf '#!/bin/sh\nnpx --no -- commitlint --edit "$1"\n' > .git/hooks/commit-msg; chmod +x .git/hooks/commit-msg
git add -A && git commit -qm "chore: init with commitlint" && echo "repo commit with the hook: $(git log -1 --format=%s)"
git commit -q --allow-empty -m "Bad message" 2>/dev/null && echo "UNEXPECTED: hook let a bad message through" || echo "the hook refuses a non-conventional message (as in the user's repo)"
jq -n --arg r "$R" '{dispatch:"subagent", verify_full:"true", merge_mode:"local", worktree_setup:("ln -s " + $r + "/node_modules node_modules")}' > .deliver.json
git add -A && git commit -qm "chore: add deliver settings"
"$DL" new "Model orchestration generation endpoint" "x" 2>&1 | tail -1; J="$R/.work/$(cat .work/ACTIVE)"
echo "convention kept with the job: $(jq -c '.settings.commit | {convention, convention_source}' "$J/job.json")"
"$DL" jobset '.roles=[{"role":"ba","agent":"business-analyst"},{"role":"backend","agent":"backend-dev"},{"role":"qa","agent":"qa-tester"},{"role":"reviewer","agent":"ecc:code-reviewer"}]' >/dev/null
"$DL" phase readiness >/dev/null
jq '(.items // .) |= map(.status = (if .status=="open" then "n_a" else .status end) | .answer = (.answer // "n/a"))' "$J/readiness.json" > x && mv x "$J/readiness.json" 2>/dev/null
"$DL" phase planning >/dev/null 2>&1 || { echo "planning refused (readiness):"; "$DL" phase planning 2>&1 | tail -3; }
printf '## Acceptance criteria\nGiven a, when b, then c\n' > "$J/specs/T-01.md"
jq -n '{cards:[{id:"T-01",title:"Model orchestration generation endpoint",role:"backend",agent:"backend-dev",component:"app",state:"ready",depends_on:[],scope:["src/**"],qa_scope:["it/**"],
  verify:"test -d src",qa_verify:"test -d it",acceptance:["AC-1: x"],context:"c",attempts:0,notes:[]}]}' > "$J/board.json"
"$DL" phase executing >/dev/null; WC="$("$DL" wt add T-01)"
grep -o 'this repo uses Conventional Commits[^—]*' "$J/roles/backend.md" | head -1
mkdir -p "$WC/src" && echo 1 > "$WC/src/a" && git -C "$WC" add src && git -C "$WC" commit -qm "feat: model orchestration generation endpoint (T-01)" && echo "dev commit through the real hook: ok"
"$DL" gate T-01 | head -1; grep -E "commit messages" "$J"/gates/T-01-a1-*.log
mkdir -p "$WC/it" && echo t > "$WC/it/t" && git -C "$WC" add it && git -C "$WC" commit -qm "test: integration tests for AC-1 (T-01)" && echo "QA commit through the real hook: ok"
"$DL" qa T-01 pass "AC-1 pass" >/dev/null && "$DL" review T-01 approve ok >/dev/null
"$DL" integrate T-01; echo "integrate exit $?; merge commit: $(git -C "$J/wt/_integration" log -1 --format=%s)"
"$DL" phase integrating >/dev/null; "$DL" verify-all >/dev/null; "$DL" phase closing >/dev/null
echo "# report" > "$J/report.md"
"$DL" ship 2>&1 | tail -1; echo "main: $(git log -1 --format=%s)"
grep $'\tmerge-refused\t' "$J/events.log" || echo "no message was refused on the way"
