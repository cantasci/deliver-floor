#!/usr/bin/env bash
# Writes (or refreshes) the /deliver section of Michael's CLAUDE.md in a Munder Difflin hive folder.
# Michael is a Claude Code session whose working directory is the hive folder, so this file is in his context.
#   scripts/md-brief.sh <hive dir> [repo …]
set -euo pipefail
hive="${1:?usage: md-brief.sh <hive dir> [repo …]}"; shift
mkdir -p "$hive"; f="$hive/CLAUDE.md"; touch "$f"
repos=""; for r in "$@"; do repos+="  - \`$(cd "$r" && pwd)\`"$'\n'; done
block="$(cat <<EOF
<!-- deliver:begin — managed by skills-shop scripts/md-brief.sh; edit outside these markers -->
## Delivery work runs through /deliver

You are Michael, the PM. For any request to build, change or fix something in a code repository:

1. Run \`/deliver <the request>\` — or \`/deliver <path to a requirements .md>\` when the request is a document.
   Put the target repository in the request as \`REPO: <absolute path>\` when it is not obvious.
2. Follow the deliver skill to the letter: you pick the roles, assign every card, and never write product code yourself.
   The Business Analyst analyses, devs build with unit tests (TDD), QA writes and runs the integration/e2e tests,
   a Lead reviews, \`dl\` merges. The human takes over at the PR.
3. On this floor, cards run as floor workers (\`dispatch: "munder"\`): \`dl wt add\` then \`dl md-dispatch\`. Each worker's
   \`act:"done"\` arrives in your inbox — continue that card with the gate, QA and review.
4. Questions for the human (a blocked card, a scope question) go on an ASK ME card (\`tasks.json\` → \`humanQA\`), short.
5. Status questions: \`/deliver status\`.

Repositories on this floor:
${repos:-  - (none registered — add with scripts/md-brief.sh <hive> <repo>)}
<!-- deliver:end -->
EOF
)"
if grep -q '<!-- deliver:begin' "$f"; then
  awk -v b="$block" 'BEGIN{p=1} /<!-- deliver:begin/{print b; p=0} p{print} /<!-- deliver:end -->/{p=1}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
else
  [[ -s $f ]] && printf '\n' >> "$f"; printf '%s\n' "$block" >> "$f"
fi
echo "briefed Michael: $f"
