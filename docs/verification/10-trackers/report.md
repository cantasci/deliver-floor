# Asana, Linear, GitHub Projects — checked against the vendors' official API descriptions

Run 2026-10-06 with graphql-js 16 (`validate()`) and the descriptions as fetched that day:

- `asana.yaml` — sha256 `7c4c198fda7627c2…`, 3215280 bytes
- `linear.graphql` — sha256 `cc4263f66d6e79f1…`, 1335039 bytes
- `gh-rest.json` — sha256 `3c608117f6d5a69c…`, 13014796 bytes
- `gh.graphql` — sha256 `3c62d0526d133cee…`, 1223842 bytes

Sources: `raw.githubusercontent.com/Asana/openapi/master/defs/asana_oas.yaml`, `…/linear/linear/master/packages/sdk/src/schema.graphql` (endpoint and auth header form: `…/packages/sdk/src/client.ts`), `…/github/rest-api-description/main/descriptions/api.github.com/api.github.com.json`, `…/octokit/graphql-schema/main/schema.graphql`.

## GraphQL: every document the tracker sends, validated against the schema

```
== linear.mjs
ok   query($key: String!) { teams(filter: {key: {eq: $key}}) { nodes { id key name states { nodes { id name } } } }
ok   mutation($input: IssueCreateInput!) { issueCreate(input: $input) { success issue { id identifier url } } }
ok   mutation($input: IssueRelationCreateInput!) { issueRelationCreate(input: $input) { success } }
ok   mutation($id: String!, $input: IssueUpdateInput!) { issueUpdate(id: $id, input: $input) { success } }
ok   mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success } }
ok   mutation($issueId: String!, $url: String!, $title: String) { attachmentLinkURL(issueId: $issueId, url: $url, t
ok   query { viewer { name email } }
rc=0
== github.mjs
ok   query($o: String!, $n: Int!) { organization(login: $o) { projectV2(number: $n) { id url title fields(first: 50
ok   query($o: String!, $n: Int!) { user(login: $o) { projectV2(number: $n) { id url title fields(first: 50) { node
ok   mutation($p: ID!, $c: ID!) { addProjectV2ItemById(input: {projectId: $p, contentId: $c}) { item { id } } }
ok   mutation($p: ID!, $i: ID!, $f: ID!, $o: String!) { updateProjectV2ItemFieldValue(input: {projectId: $p, itemId
rc=0
== the checker catches a mistake: 'identifer' for 'identifier'
FAIL mutation($input: IssueCreateInput!) { issueCreate(input: $input) { success issue { id identifer url } } }
      Cannot query field "identifer" on type "Issue". Did you mean "identifier"?
```

## REST: every call's method, path and body fields found in the OpenAPI description

```
== asana.mjs
ok   GET /projects/{project_gid}/sections
ok   POST /tasks/{task_gid}/addDependencies body ['dependencies'] 
ok   POST /sections/{section_gid}/addTask body ['task'] 
ok   POST /tasks/{task_gid}/stories body ['text'] 
ok   PUT /tasks/{task_gid} body ['notes'] 
ok   GET /projects/{project_gid}
ok   POST /tasks body ['name', 'projects'] 
ok   POST /tasks body ['name'] 
FAIL GET /users/me — no such path+method
rc=1 — GET /users/me is /users/{user_gid}, whose description reads: A string identifying a user. This can either be the string "me", an email, or the gid of a user.
== github.mjs
ok   POST /repos/{owner}/{repo}/issues body ['title', 'body'] 
ok   POST /repos/{owner}/{repo}/issues body ['title'] 
ok   POST /repos/{owner}/{repo}/issues/{issue_number}/sub_issues body ['sub_issue_id'] 
ok   POST /repos/{owner}/{repo}/issues/{issue_number}/dependencies/blocked_by body ['issue_id'] 
ok   POST /repos/{owner}/{repo}/issues/{issue_number}/comments body ['body'] 
ok   PATCH /repos/{owner}/{repo}/issues/{issue_number} body ['body'] 
ok   GET /repos/{owner}/{repo}
ok   GET /user
rc=0
```

The body-field check reads the first object literal of each call; fields built from templates (notes, parent, labels) were checked by hand against the same descriptions: Asana `POST /tasks` accepts name, notes, parent, projects; GitHub `POST /repos/{owner}/{repo}/issues` accepts title, body, labels.

## The whole flow against a stub of each API

`tests/run.sh` → `tracker_contract` for asana (16 checks), linear (17), github (16): check (sign-in, board, a column per stage; a missing credential named; a missing column refused), open (job + a card under it per card, in the existing board), the dependency, To Do → In Progress → QA → Code Review → Done through the real `dl wt add / gate / qa / review / integrate`, the roles' comments, the branch in the description (Linear: the identifier in the branch name), and a column removed mid-job reported without touching board.json.

Not done: a run against a real Asana, Linear or GitHub Projects account — none is available here ([OPEN O2](../../OPEN.md)).
