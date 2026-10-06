#!/usr/bin/env bash
# LIVE end-to-end scenario on the Munder Difflin office floor — the real Electron app, driven like a user with Playwright.
#   1. fresh HOME → scripts/init.sh --munder (ECC from GitHub, the kit, Munder Difflin source → build → config, Michael's brief)
#   2. sandbox repo (dispatch: munder — every dev card runs as a floor worker)
#   3. the app starts under a virtual display; the hive is opened; Michael (the god agent) is briefed with ONE message:
#      /deliver <requirements .md>
#   4. the driver watches the job and screenshots the floor every minute until the job is done
#   5. tests/verify-job.sh judges the result + floor-specific checks (workers spawned, md_workers on cards)
#
#   tests/e2e-munder.sh [work dir] [munder-difflin checkout]   (default: a fresh clone into the work dir)
#   E2E_JOB=JOB-parallel.md → two backend seats: several floor workers at their desks at the same time
#   E2E_MODEL=<model>     the floor default for every seat (.deliver.json munder.model; default claude-sonnet-5-5)
#   E2E_SAY="<text>"      added to Michael's /deliver message (e.g. which model a role works on)
#   E2E_SEAT_MODEL=<role>:<seat name regex>:<m>   judge from the transcripts: that seat on <m>, every other seat on
#                         E2E_MODEL, Michael on neither
#   E2E_EXPECT_RESEAT=1  the floor default model is broken on purpose (E2E_MODEL=claude-nonexistent-0, like an app default
#                         with no credit): every seat must be seen as failed and re-seated by Michael on a working model,
#                         as his own decision (no question to the human), listed in the PR — and the job still delivered
#   Needs: xvfb-run, Playwright (node), network to GitHub/npm. Costs real tokens.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
W="${1:-$(mktemp -d "${TMPDIR:-/tmp}/deliver-md.XXXXXX")}"; mkdir -p "$W/munder"; W="$(cd "$W/munder" && pwd)"
MD="${2:-$W/munder-difflin}"
EX="$HERE/examples/watchlist-poc"
JOBF="${E2E_JOB:-JOB.md}"; ORACLE=watchlist.oracle.test.mjs; [[ $JOBF == JOB-parallel.md ]] && ORACLE=parallel.oracle.test.mjs; [[ $JOBF == JOB-models* ]] && ORACLE=models.oracle.test.mjs
export ISO_HOME="$W/home"; mkdir -p "$ISO_HOME"
. "$HERE/tests/lib-isolated-claude.sh"
export GIT_AUTHOR_NAME=e2e GIT_AUTHOR_EMAIL=e2e@example.com GIT_COMMITTER_NAME=e2e GIT_COMMITTER_EMAIL=e2e@example.com IS_SANDBOX=1
REP="$W/report.md"; printf '# Live E2E — scenario `munder` (Munder Difflin office floor)\n\nRequest: `examples/watchlist-poc/$JOBF` · started %s\n' "$(date -u +%FT%TZ)" > "$REP"
log()  { printf '%s\n' "$*" | tee -a "$REP"; }
step() { printf '\n\033[1;36m━━ %s\033[0m\n' "$*"; printf '\n## %s\n\n' "$*" >> "$REP"; }
ok()  { printf '  \033[32m✔\033[0m %s\n' "$1"; printf -- '- ✅ %s\n' "$1" >> "$REP"; }
bad() { printf '  \033[31m✘\033[0m %s\n' "$1"; printf -- '- ❌ %s\n' "$1" >> "$REP"; FAILED=1; }
FAILED=0

step "1 · setup: scripts/init.sh --munder in a fresh HOME"
SB="$W/repo"; rm -rf "$SB"; iso_env "$HERE/scripts/sandbox.sh" "$SB" watchlist-poc > /dev/null
# The kit from this checkout's marketplace — the plugin a user installs, with this branch's changes (a local marketplace
# loads the plugin in place). E2E_COPIED_KIT=1 first puts an old-style copy into ~/.claude, as a user upgrading has it.
if [[ ${E2E_COPIED_KIT:-0} == 1 ]]; then
  iso_env bash "$HERE/scripts/install.sh" --user > "$W/copied-kit.log" 2>&1 && ok "an old-style copy of the kit in ~/.claude (as a user upgrading has it)" || bad "copied kit (copied-kit.log)"
fi
iso_env bash "$HERE/scripts/init.sh" --munder --munder-dir "$MD" --hive "$W/hive" --repo "$SB" --skip-onboarding --kit-from "$HERE" > "$W/init.log" 2>&1 \
  && ok "init: $(grep -E '^result:' "$W/init.log" | tail -1)" || { bad "init failed (init.log)"; tail -20 "$W/init.log"; exit 1; }
jq -e '.dispatch == "munder"' "$SB/.deliver.json" >/dev/null && ok "repo set to dispatch=munder (devs are floor workers)" || bad "dispatch not munder"
grep -q "deliver:begin" "$W/hive/CLAUDE.md" && ok "Michael briefed in the hive (CLAUDE.md, AGENTS.md, GEMINI.md)" || bad "no brief"
# Munder Difflin strips CLAUDE_* variables from every terminal it opens. A user who logged in with `claude` does not care;
# a CI/cloud container that authenticates through CLAUDE_* variables does. Then a two-line bridge puts them back and runs the
# real claude — configured where a user would: MD's defaultCommand (Michael) and settings.munder.claude_command (workers).
CL="claude"
if [[ -n ${CLAUDE_SESSION_INGRESS_TOKEN_FILE:-}${CLAUDE_CODE_OAUTH_TOKEN:-} && -z ${ANTHROPIC_API_KEY:-} ]]; then
  mkdir -p "$W/bin"; CL="$W/bin/claude"  # named claude: Munder Difflin infers the provider from the binary name
  { echo '#!/usr/bin/env bash'
    for v in CLAUDE_SESSION_INGRESS_TOKEN_FILE CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_BASE_URL; do
      [[ -n ${!v:-} ]] && printf 'export %s=%q\n' "$v" "${!v}"; done
    printf 'exec %q "$@"\n' "$(command -v claude)"; } > "$CL"; chmod +x "$CL"
  ok "credential bridge for the floor's terminals: bin/claude (container auth via CLAUDE_* variables)"
fi
cfg="$ISO_HOME/.config/munder-difflin/config.json"
jq --arg c "$CL" --arg gm "${E2E_GOD_MODEL:-claude-opus-5-5}" --arg dm "${E2E_MODEL:-claude-sonnet-5-5}" \
  '.defaultCommand = $c | .godModel = $gm | .defaultModel = $dm | .autoMode = true' "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
ok "Munder Difflin: Michael runs '$(basename "$CL")' on ${E2E_GOD_MODEL:-claude-opus-5-5}, workers default to ${E2E_MODEL:-claude-sonnet-5-5}"
jq --arg c "$CL" --arg m "${E2E_MODEL:-claude-sonnet-5-5}" '.munder = ((.munder // {}) + {claude_command: $c, model: $m})' "$SB/.deliver.json" > "$SB/.deliver.json.tmp" \
  && mv "$SB/.deliver.json.tmp" "$SB/.deliver.json"
# A fresh HOME has never seen Claude Code's first-run screens; a user clicks through them once — so does the test.
cj="$ISO_HOME/.claude.json"; [[ -s $cj ]] || echo '{}' > "$cj"
jq '.hasCompletedOnboarding = true' "$cj" > "$cj.tmp" && mv "$cj.tmp" "$cj"
git -C "$SB" add .deliver.json && git -C "$SB" commit -qm "deliver: dispatch on the floor" || true
# One copy of the kit: the plugin. Nothing of it in ~/.claude, Michael told to run the plugin's skill by the stable dl.
SKD="$(jq -r '.plugins["deliver@deliver-floor"] | if type == "array" then .[0] else . end | .installPath // empty' "$ISO_HOME/.claude/plugins/installed_plugins.json" 2>/dev/null)/skills/deliver"
[[ -x $SKD/bin/dl ]] && ok "the kit is the plugin deliver@deliver-floor: $SKD" || bad "plugin not installed: $SKD"
left="$(ls -d "$ISO_HOME"/.claude/skills/deliver "$ISO_HOME"/.claude/hooks/deliver 2>/dev/null; jq -r '[.hooks // {} | .[][] | .hooks[]?.command | select(test("hooks/deliver[/\"]"))] | .[]' "$ISO_HOME/.claude/settings.json" 2>/dev/null)"
[[ -z $left ]] && ok "no copy of the kit in ~/.claude (skill, hooks, hook entries)" || bad "a copy of the kit is left: $left"
grep -q '`/deliver:deliver <the request>`' "$W/hive/CLAUDE.md" && ! grep -q "$SKD" "$W/hive/CLAUDE.md" && grep -q 'plugins/data/deliver-deliver-floor/bin/dl' "$W/hive/CLAUDE.md" \
  && ok "Michael's brief: /deliver:deliver and the stable dl — no version path" || bad "Michael's brief ($W/hive/CLAUDE.md)"
step "2 · the floor: open the app, brief Michael with one message, watch"
iso_env NODE_PATH="${NODE_PATH:-/usr/local/lib/node_modules_global}" xvfb-run -a node "$HERE/tests/md-drive.cjs" "$MD" "$ISO_HOME" "$W/shots" "$SB" \
  "/deliver:deliver $EX/$JOBF${E2E_SAY:+ — $E2E_SAY}" "${E2E_MINUTES:-75}" "$EX/HUMAN_ANSWERS.json" "$SKD/bin/dl" 2>&1 | grep --line-buffered -v -E 'bus\.cc|viz_main|dbus|Fontconfig' | tee "$W/drive.log" | sed 's/^/    /'
[[ ${PIPESTATUS[0]} -eq 0 ]] && ok "the job finished on the floor" || bad "the job did not finish on the floor (drive.log)"
ok "screenshots of the floor: $(ls "$W/shots" 2>/dev/null | wc -l) (shots/)"

step "3 · floor-specific checks"
J="$(ls -d "$SB"/.work/JOB-* 2>/dev/null | sort | tail -1)"
if [[ -n $J ]]; then
  n="$(jq '[.cards[] | select((.md_workers // []) | length > 0)] | length' "$J/board.json")"
  [[ $n -ge 1 ]] && ok "$n card(s) were built by floor workers (md_workers on the cards)" || bad "no card ran as a floor worker"
  d="$(ls "$W/hive/hive/spawn-requests/.done" 2>/dev/null | wc -l)"
  [[ $d -ge 1 ]] && ok "Munder Difflin consumed $d spawn request(s) (spawn-requests/.done)" || bad "no spawn request was consumed"
  jq -r '.agents | to_entries[] | select(.key | startswith("worker-")) | "    worker: \(.key) — \(.value.name // "")"' "$W/hive/hive/registry.json" 2>/dev/null | tee -a "$REP"
fi
# Every role the requirements called for is a person at a desk who did that role's work — Michael ran no subagent.
if [[ -n $J ]]; then
  seats="$(jq -r '.munder.seats // {} | keys[]' "$J/job.json")"
  want="$(jq -r '.roles[] | select(.agent != "artemis") | . as $r | range(1; (($r.count // 1) + 1)) | "\($r.role)#\(.)"' "$J/job.json" | sort)"
  [[ -n $seats && "$(sort <<<"$seats")" == "$want" ]] && ok "a seat was hired for every role seat the requirements called for: $(tr '\n' ' ' <<<"$want")" \
    || bad "seats hired ($(tr '\n' ' ' <<<"$seats")) ≠ seats needed ($(tr '\n' ' ' <<<"$want"))"
  for s in $want; do
    w="$(jq -r --arg s "$s" '.munder.seats[$s].worker' "$J/job.json")"
    on="$(jq -r --arg w "$w" '.agents[$w] // empty | .name' "$W/hive/hive/registry.json" 2>/dev/null)"
    tasks="$(grep -P "\tmd-done\t\S+ $s:" "$J/events.log" | cut -f3 | cut -d' ' -f1 | tr '\n' ' ')"
    [[ -n $tasks ]] && ok "$s (${on:-$w}) did: $tasks" || bad "$s never reported a finished task"
  done
  nrel="$(grep -cP '\tmd-release\t' "$J/events.log")"; nwant="$(wc -w <<<"$want")"
  [[ $nrel -ge $nwant ]] && ok "Michael sent all $nwant seats home at the end (md-release)" || bad "md-release for $nrel of $nwant seats"
  nsub="$(grep -P '\tagent\t' "$J/events.log" | grep -vc ' @worker-')"
  if [[ $nsub -gt 0 ]]; then
    bad "Michael ran $nsub subagent(s) on the floor: $(grep -P '\tagent\t' "$J/events.log" | grep -v ' @worker-' | head -3 | cut -f3 | cut -c1-60 | tr '\n' ';')"
  else ok "Michael ran no subagent: every role's work went to its seat (md-send → md-done)"; fi
  # Proof of who did the work: the driver selected each seat on the floor and photographed its own terminal.
  for s in $want; do
    n="$(ls "$W/shots" 2>/dev/null | grep -c -- "-${s/\#/}-")"
    [[ $n -ge 1 ]] && ok "$s's own terminal photographed at work: $n screenshot(s) (shots/p*-${s/\#/}-*.png)" || bad "no screenshot of $s at work"
  done
  # Everyone went home: Michael's release reached every seat and the floor archived them before the app closed.
  left="$(jq -r --argjson ws "$(jq -c '[.munder.seats[].worker]' "$J/job.json")" '[.agents | to_entries[] | select(.key as $k | $ws | index($k)) | select((.value.archived != true) and (.value.status != "gone")) | .value.name] | join(", ")' "$W/hive/hive/registry.json" 2>/dev/null)"
  if [[ -z $left ]]; then ok "every seat left the floor after the release"
  else
    nodone="$(jq -r --argjson ws "$(jq -c '[.munder.seats[].worker]' "$J/job.json")" -s '[.[] | select(.kind=="message" and .to=="god" and .act=="done") | .from] as $d | [$ws[] | select(. as $w | $d | index($w) | not)] | join(", ")' "$W/hive/hive/log.jsonl" 2>/dev/null)"
    [[ -z $nodone ]] && ok "every seat answered the release (act done) — the app still shows them: $left (OPEN F15, app side)" || bad "seats that never answered the release: $nodone"
  fi
  grep -q '`deliver:backend-dev`' "$J/ROLES.md" && ok "plugin: ROLES.md names the kit's agents deliver:<agent>" || bad "plugin: ROLES.md without the deliver: prefix"
  mt="$(ls -S "$ISO_HOME"/.claude/projects/*hive*/*.jsonl 2>/dev/null | head -1)"
  base="$(grep -o 'Base directory for this skill: [^"\\]*/skills/deliver' "$mt" 2>/dev/null | head -1 | sed 's/^Base directory for this skill: //')"
  [[ -n $base && $base != "$ISO_HOME/.claude/skills/"* ]] && ok "Michael ran the plugin's /deliver:deliver: $base" || bad "Michael's /deliver was not the plugin's (${base:-no skill run in $mt})"
fi

if [[ -n ${E2E_SEAT_MODEL:-} && -n $J ]]; then
  step "models per role: floor default ${E2E_MODEL:-claude-sonnet-5-5}; Michael was told \"${E2E_SAY:-}\""
  . "$HERE/tests/lib-models.sh"; IFS=: read -r mr ms mm <<<"$E2E_SEAT_MODEL"
  dm="${E2E_MODEL:-claude-sonnet-5-5}"; dm="$(sed -E 's/^claude-//; s/-[0-9].*$//' <<<"$dm")"
  models_floor "$W/hive/hive/registry.json" "$ISO_HOME/.claude/projects" "$J/job.json" "$dm" "$mr" "$ms" "$mm"
fi

if [[ ${E2E_EXPECT_RESEAT:-0} == 1 && -n $J ]]; then
  step "seats that fail: seen, re-seated by Michael on a working model, reported in the PR"
  bad_m="${E2E_MODEL:-}"; nseats="$(jq '[.munder.seats // {} | keys[]] | length' "$J/job.json")"
  nres="$(grep -cP '\tmd-reseat\t' "$J/events.log")"
  log "re-seats: $nres for $nseats seat(s)"; grep -P '\tmd-reseat\t' "$J/events.log" | cut -f3 | head -12 | sed 's/^/    /' | tee -a "$REP" >/dev/null
  [[ $nres -ge $nseats ]] && ok "every seat that started on the broken model was re-seated ($nres re-seats, $nseats seats)" || bad "only $nres re-seat(s) for $nseats seats"
  jq -e --arg b "$bad_m" '[.munder.seats[] | .model // ""] | all(. != "" and . != $b)' "$J/job.json" >/dev/null \
    && ok "…each on a model Michael chose: $(jq -r '[.munder.seats[] | .model] | unique | join(", ")' "$J/job.json")" || bad "seat models: $(jq -c '[.munder.seats[] | .model]' "$J/job.json")"
  jq -e '[.pm_decisions[]? | select(.what | startswith("re-seated"))] | length > 0' "$J/job.json" >/dev/null && ok "…recorded as Michael's own decisions" || bad "no re-seat decision recorded"
  grep -q "re-seated" "$J/report.md" && ok "…and listed in the PR body" || bad "the PR body does not list the re-seats"
  first_plan="$(grep -n $'\tphase\tplanning' "$J/events.log" | head -1 | cut -d: -f1)"
  [[ -z $first_plan || -z "$(tail -n +"$first_plan" "$J/events.log" | grep -P '\tclarify\t')" ]] && ok "no question to the human about it" || bad "a question after planning"
  . "$HERE/tests/lib-models.sh"
  M="$(node "$HERE/tests/check-models.mjs" floor "$W/hive/hive/registry.json" "$ISO_HOME/.claude/projects")"; echo "$M" > "$W/models.json"; _models_dump "$M"
  jq -e '[.roles[] | keys[] | select(. != "<synthetic>")] | length > 0' <<<"$M" >/dev/null && ok "the re-seated people really worked (Claude replies from a real model)" || bad "no real model replies from the seats"
fi

step "4 · verify the delivered job"
"$HERE/tests/verify-job.sh" "$SB" "$ORACLE" "$REP" "$SKD" || FAILED=1
printf '\n**%s**\n' "$([[ $FAILED -eq 0 ]] && echo PASSED || echo FAILED)" >> "$REP"
exit $FAILED
