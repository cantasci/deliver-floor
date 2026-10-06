#!/usr/bin/env bash
# Writes (or refreshes) the /deliver section of Michael's instruction files in a Munder Difflin hive folder:
# CLAUDE.md (Claude Code), AGENTS.md (Codex, OpenCode, Crush, Copilot, Cursor, …) and GEMINI.md (Gemini CLI / Antigravity).
# Michael's working directory is the hive folder, so whichever CLI runs him reads its file.
#   md-brief.sh <hive dir> [repo …]      (dl floor-open runs it; scripts/md-brief.sh is a wrapper for a copied install)
set -euo pipefail
hive="${1:?usage: md-brief.sh <hive dir> [repo …]}"; shift
mkdir -p "$hive"
skill="${DELIVER_SKILL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"   # the skill this script ships in
# Installed as a plugin (…/plugins/cache/<marketplace>/<plugin>/<version>/skills/deliver): Michael runs the plugin's skill,
# /deliver:deliver, and other CLIs the stable dl in the plugin's data dir — never this version's path, which an update
# leaves behind (a copied kit's /deliver kept Michael on an old version on a user's machine).
cmd="/deliver" dl="$skill/bin/dl" playbook="\`$skill/SKILL.md\`"
if [[ $skill =~ ^(.*)/cache/([^/]+)/([^/]+)/[^/]+/skills/deliver$ ]]; then
  id="$(printf '%s@%s' "${BASH_REMATCH[3]}" "${BASH_REMATCH[2]}" | tr -c 'A-Za-z0-9_\n-' '-')"
  cmd="/${BASH_REMATCH[3]}:deliver" dl="${BASH_REMATCH[1]}/data/$id/bin/dl" playbook="the file \`$dl playbook\` names"
fi
repos=""; for r in "$@"; do repos+="  - \`$(cd "$r" && pwd)\`"$'\n'; done
block="$(cat <<EOF
<!-- deliver:begin — managed by the deliver plugin (md-brief.sh); edit outside these markers -->
## Delivery work runs through /deliver

You are Michael, the PM. For any request to build, change or fix something in a code repository:

1. Run \`$cmd <the request>\` — or \`$cmd <path to a requirements .md>\` when the request is a document.
   Put the target repository in the request as \`REPO: <absolute path>\` when it is not obvious.
   **The request reached you as a message (Slack, webhook, inbox), or you are not Claude Code?** Then \`$cmd\` is not
   something you can invoke yourself: read the playbook
   $playbook and follow it exactly, with \`$dl\` as \`dl\`.
2. Follow the deliver skill to the letter: you pick the roles, assign every card, and never write product code yourself.
   The Business Analyst analyses, devs build with unit tests (TDD), QA writes and runs the integration/e2e tests,
   a Lead reviews, \`dl\` merges. The human takes over at the PR.
3. On this floor every role is a person at a desk, never a subagent (\`dispatch: "munder"\`): after the roles are chosen,
   \`dl md-hire\` seats one person per seat (BA, Leads, every dev seat, QA, reviewers). Every piece of role work is a work
   order to that person: \`dl md-send <role|seat> <task> <prompt file> --agent <ECC or kit agent>\` — you choose the
   instructions and skills for each task. Each person reports \`done <task> <seat>\` in your inbox — read it only with
   \`dl md-inbox\` (never move inbox files yourself); record it with \`dl md-done <seat> "<summary>"\` and continue. At the end, \`dl md-release\`.
   A seat is live only after its "seated" message; \`dl md-seats\` says why one is not (died at startup, API or credit
   error, no "seated" in time). Re-seat it yourself: \`dl md-reseat <seat> "<why>" [--model <model>]\`.
4. You ask the human only when a project or task is given (the readiness questions, on an ASK ME card: \`tasks.json\` →
   \`humanQA\`). After that you decide yourself (\`dl pm-decide\`, or archive a card with its reason); the PR lists your decisions.
5. Status questions: \`$cmd status\`.

Repositories on this floor:
${repos:-  - (none registered — add with scripts/md-brief.sh <hive> <repo>)}
<!-- deliver:end -->
EOF
)"
for f in "$hive/CLAUDE.md" "$hive/AGENTS.md" "$hive/GEMINI.md"; do
  touch "$f"
  if grep -q '<!-- deliver:begin' "$f"; then
    awk -v b="$block" 'BEGIN{p=1} /<!-- deliver:begin/{print b; p=0} p{print} /<!-- deliver:end -->/{p=1}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  else
    [[ -s $f ]] && printf '\n' >> "$f"; printf '%s\n' "$block" >> "$f"
  fi
done
echo "briefed Michael: $hive/{CLAUDE,AGENTS,GEMINI}.md"
