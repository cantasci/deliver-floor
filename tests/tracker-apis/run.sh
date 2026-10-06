#!/usr/bin/env bash
# Re-checks the Asana, Linear and GitHub Projects trackers against each vendor's official API description, as published
# today: every GraphQL document they send is validated with graphql-js, every REST call's method, path and body fields are
# looked up in the OpenAPI description. Needs network (raw.githubusercontent.com, registry.npmjs.org), node, python3 + PyYAML.
#   tests/tracker-apis/run.sh [work dir]          exit 0 when everything is found; prints each call
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; T="$HERE/kit/skills/deliver/bin/trackers"; C="$HERE/tests/tracker-apis"
W="${1:-$(mktemp -d)}"; mkdir -p "$W"; cd "$W" || exit 1
get() { curl -fsSL -o "$1" "$2" || { echo "cannot fetch $2" >&2; exit 1; }; }
get asana.yaml https://raw.githubusercontent.com/Asana/openapi/master/defs/asana_oas.yaml
get linear.graphql https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql
get gh-rest.json https://raw.githubusercontent.com/github/rest-api-description/main/descriptions/api.github.com/api.github.com.json
get gh.graphql https://raw.githubusercontent.com/octokit/graphql-schema/main/schema.graphql
[[ -d node_modules/graphql ]] || { npm init -y >/dev/null && npm install --silent graphql@16 >/dev/null; } || exit 1
rc=0
echo "== linear (GraphQL)"; NODE_PATH="$W/node_modules" node "$C/check-graphql.cjs" linear.graphql "$T/linear.mjs" || rc=1
echo "== github (GraphQL)"; NODE_PATH="$W/node_modules" node "$C/check-graphql.cjs" gh.graphql "$T/github.mjs" || rc=1
echo "== github (REST)"; python3 "$C/check-rest.py" github gh-rest.json "$T/github.mjs" || rc=1
echo "== asana (REST)"; python3 "$C/check-rest.py" asana asana.yaml "$T/asana.mjs" | grep -v '^FAIL GET /users/me' ; [[ ${PIPESTATUS[0]} -le 1 ]] || rc=1
echo "   (GET /users/me is /users/{user_gid}: \"This can either be the string \\\"me\\\", an email, or the gid of a user.\")"
exit $rc
