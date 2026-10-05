#!/usr/bin/env bash
# Creates a fresh git repo from an example's seed, ready for /deliver.
#   scripts/sandbox.sh [--subagent] <dest dir> [example]        (example default: watchlist-poc)
# Munder Difflin is the default: give /deliver to Michael in the app (scripts/init.sh --munder --repo <dest>).
# --subagent: the sandbox runs with Claude Code subagents instead ("dispatch": "subagent") — then: cd <dest> && claude
#   → /deliver <repo>/examples/<example>/JOB.md
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sub=0; [[ ${1:-} == --subagent ]] && { sub=1; shift; }
dest="${1:?usage: sandbox.sh [--subagent] <dest dir> [example]}"; ex="${2:-watchlist-poc}"
src="$HERE/examples/$ex/seed"
[[ -d $src ]] || { echo "no such example: $ex" >&2; exit 1; }
[[ ! -e $dest || -z "$(ls -A "$dest" 2>/dev/null)" ]] || { echo "$dest exists and is not empty" >&2; exit 1; }
mkdir -p "$dest"; cp -R "$src"/. "$dest"/
cd "$dest"
git init -q -b main
if [[ $sub == 1 ]]; then jq '.dispatch = "subagent"' .deliver.json > .deliver.json.t 2>/dev/null && mv .deliver.json.t .deliver.json || echo '{"dispatch":"subagent"}' > .deliver.json; fi
git -c user.name="${GIT_AUTHOR_NAME:-sandbox}" -c user.email="${GIT_AUTHOR_EMAIL:-sandbox@example.com}" add -A
git -c user.name="${GIT_AUTHOR_NAME:-sandbox}" -c user.email="${GIT_AUTHOR_EMAIL:-sandbox@example.com}" commit -qm "seed: $ex"
[[ -n "$(git config user.email)" ]] || git config user.email "sandbox@example.com"
[[ -n "$(git config user.name)" ]] || git config user.name "sandbox"
echo "sandbox ready: $(pwd)"
echo "job request:   $HERE/examples/$ex/JOB.md"
if [[ $sub == 1 ]]; then echo "mode:          Claude Code subagents (dispatch: subagent) — cd $(pwd) && claude, then /deliver <job request>"
else echo "mode:          Munder Difflin floor (the default) — scripts/init.sh --munder --repo $(pwd), then give /deliver to Michael in the app"; fi
