#!/usr/bin/env bash
# Creates a fresh git repo from an example's seed, ready for /deliver.
#   scripts/sandbox.sh <dest dir> [example]        (example default: watchlist-poc)
# Then: cd <dest> && claude   →   /deliver $(cat <repo>/examples/<example>/JOB.md)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="${1:?usage: sandbox.sh <dest dir> [example]}"; ex="${2:-watchlist-poc}"
src="$HERE/examples/$ex/seed"
[[ -d $src ]] || { echo "no such example: $ex" >&2; exit 1; }
[[ ! -e $dest || -z "$(ls -A "$dest" 2>/dev/null)" ]] || { echo "$dest exists and is not empty" >&2; exit 1; }
mkdir -p "$dest"; cp -R "$src"/. "$dest"/
cd "$dest"
git init -q -b main
git -c user.name="${GIT_AUTHOR_NAME:-sandbox}" -c user.email="${GIT_AUTHOR_EMAIL:-sandbox@example.com}" add -A
git -c user.name="${GIT_AUTHOR_NAME:-sandbox}" -c user.email="${GIT_AUTHOR_EMAIL:-sandbox@example.com}" commit -qm "seed: $ex"
[[ -n "$(git config user.email)" ]] || git config user.email "sandbox@example.com"
[[ -n "$(git config user.name)" ]] || git config user.name "sandbox"
echo "sandbox ready: $(pwd)"
echo "job request:   $HERE/examples/$ex/JOB.md"
