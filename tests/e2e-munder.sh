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
#   Needs: xvfb-run, Playwright (node), network to GitHub/npm. Costs real tokens.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
W="${1:-$(mktemp -d "${TMPDIR:-/tmp}/deliver-md.XXXXXX")}"; mkdir -p "$W/munder"; W="$(cd "$W/munder" && pwd)"
MD="${2:-$W/munder-difflin}"
EX="$HERE/examples/watchlist-poc"
export ISO_HOME="$W/home"; mkdir -p "$ISO_HOME"
. "$HERE/tests/lib-isolated-claude.sh"
export GIT_AUTHOR_NAME=e2e GIT_AUTHOR_EMAIL=e2e@example.com GIT_COMMITTER_NAME=e2e GIT_COMMITTER_EMAIL=e2e@example.com IS_SANDBOX=1
REP="$W/report.md"; printf '# Live E2E — scenario `munder` (Munder Difflin office floor)\n\nRequest: `examples/watchlist-poc/JOB.md` · started %s\n' "$(date -u +%FT%TZ)" > "$REP"
step() { printf '\n\033[1;36m━━ %s\033[0m\n' "$*"; printf '\n## %s\n\n' "$*" >> "$REP"; }
ok()  { printf '  \033[32m✔\033[0m %s\n' "$1"; printf -- '- ✅ %s\n' "$1" >> "$REP"; }
bad() { printf '  \033[31m✘\033[0m %s\n' "$1"; printf -- '- ❌ %s\n' "$1" >> "$REP"; FAILED=1; }
FAILED=0

step "1 · setup: scripts/init.sh --munder in a fresh HOME"
SB="$W/repo"; rm -rf "$SB"; iso_env "$HERE/scripts/sandbox.sh" "$SB" watchlist-poc > /dev/null
iso_env bash "$HERE/scripts/init.sh" --munder --munder-dir "$MD" --hive "$W/hive" --repo "$SB" --skip-onboarding > "$W/init.log" 2>&1 \
  && ok "init: $(grep -E '^result:' "$W/init.log" | tail -1)" || { bad "init failed (init.log)"; tail -20 "$W/init.log"; exit 1; }
jq -e '.dispatch == "munder"' "$SB/.deliver.json" >/dev/null && ok "repo set to dispatch=munder (devs are floor workers)" || bad "dispatch not munder"
grep -q "deliver:begin" "$W/hive/CLAUDE.md" && ok "Michael briefed in the hive (CLAUDE.md, AGENTS.md, GEMINI.md)" || bad "no brief"
git -C "$SB" add .deliver.json && git -C "$SB" commit -qm "deliver: dispatch on the floor" || true

step "2 · the floor: open the app, brief Michael with one message, watch"
iso_env NODE_PATH="${NODE_PATH:-/usr/local/lib/node_modules_global}" xvfb-run -a node "$HERE/tests/md-drive.cjs" "$MD" "$ISO_HOME" "$W/shots" "$SB" \
  "/deliver $EX/JOB.md" "${E2E_MINUTES:-75}" 2>&1 | grep -v -E 'bus\.cc|viz_main|dbus|Fontconfig' | tee "$W/drive.log" | sed 's/^/    /'
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

step "4 · verify the delivered job"
"$HERE/tests/verify-job.sh" "$SB" watchlist.oracle.test.mjs "$REP" "$ISO_HOME/.claude/skills/deliver" || FAILED=1
printf '\n**%s**\n' "$([[ $FAILED -eq 0 ]] && echo PASSED || echo FAILED)" >> "$REP"
exit $FAILED
