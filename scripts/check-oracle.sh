#!/usr/bin/env bash
# Runs an example's hidden acceptance tests (oracle) against a delivered branch — independent of the agents' own tests.
#   scripts/check-oracle.sh <sandbox repo> [branch] [example] [oracle file]
#   (branch default: the last job/* branch, else HEAD; oracle default: watchlist.oracle.test.mjs)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo="$(cd "${1:?usage: check-oracle.sh <repo> [branch] [example] [oracle file]}" && pwd)"; ex="${3:-watchlist-poc}"; of="${4:-watchlist.oracle.test.mjs}"
branch="${2:-$(git -C "$repo" for-each-ref --sort=-committerdate --format='%(refname:short)' 'refs/heads/job/*' | grep -v -- '--T-' | head -1)}"
branch="${branch:-HEAD}"
tmp="$(mktemp -d)"; trap 'git -C "$repo" worktree remove --force "$tmp/wt" >/dev/null 2>&1; rm -rf "$tmp"' EXIT
git -C "$repo" worktree add -q --detach "$tmp/wt" "$branch"
mkdir -p "$tmp/wt/oracle" && cp "$HERE/examples/$ex/oracle/$of" "$tmp/wt/oracle/"
echo "oracle: $ex/$of against $branch ($(git -C "$repo" rev-parse --short "$branch"))"
(cd "$tmp/wt" && node --test --test-reporter=spec "oracle/$of")
