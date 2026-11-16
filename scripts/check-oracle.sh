#!/usr/bin/env bash
# Runs an example's hidden acceptance tests (oracle) against a delivered branch — independent of the agents' own tests.
#   scripts/check-oracle.sh <sandbox repo> [branch] [example] [oracle file]
#   (branch default: the last job/* branch, else HEAD; oracle default: watchlist.oracle.test.mjs)
# The oracles are not in this repository — an agent that can read the repo could read them. They live in a local directory,
# DELIVER_ORACLE_DIR (default ~/.deliver-bench/oracles), as <example>/<oracle file>; the repo keeps only their sha256
# (examples/<example>/oracles.sha256), so a changed oracle is refused instead of silently judging with other tests.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo="$(cd "${1:?usage: check-oracle.sh <repo> [branch] [example] [oracle file]}" && pwd)"; ex="${3:-watchlist-poc}"; of="${4:-watchlist.oracle.test.mjs}"
od="${DELIVER_ORACLE_DIR:-$HOME/.deliver-bench/oracles}"; src="$od/$ex/$of"
[[ -f $src ]] || { echo "oracle not found: $src — the oracles are kept outside the repo (DELIVER_ORACLE_DIR, default ~/.deliver-bench/oracles/<example>/); ask the maintainer for them" >&2; exit 3; }
want="$(awk -v f="$of" '$2 == f { print $1 }' "$HERE/examples/$ex/oracles.sha256" 2>/dev/null)"
have="$(node -e 'process.stdout.write(require("crypto").createHash("sha256").update(require("fs").readFileSync(process.argv[1])).digest("hex"))' "$src")"
[[ -n $want ]] || { echo "no sha256 for $of in examples/$ex/oracles.sha256" >&2; exit 3; }
[[ $have == "$want" ]] || { echo "oracle $src differs from the one recorded in examples/$ex/oracles.sha256 — not used" >&2; exit 3; }
branch="${2:-$(git -C "$repo" for-each-ref --sort=-committerdate --format='%(refname:short)' 'refs/heads/job/*' | grep -v -- '--T-' | awk 'NR==1')}"
branch="${branch:-HEAD}"
tmp="$(mktemp -d)"; trap 'git -C "$repo" worktree remove --force "$tmp/wt" >/dev/null 2>&1; rm -rf "$tmp"' EXIT
git -C "$repo" worktree add -q --detach "$tmp/wt" "$branch"
mkdir -p "$tmp/wt/oracle" && cp "$src" "$tmp/wt/oracle/"
echo "oracle: $ex/$of against $branch ($(git -C "$repo" rev-parse --short "$branch"))"
(cd "$tmp/wt" && node --test --test-reporter=spec "oracle/$of")
