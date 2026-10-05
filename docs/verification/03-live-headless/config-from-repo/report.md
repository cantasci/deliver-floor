# Live E2E — scenario `models`

Request: `examples/watchlist-poc/JOB-models.md`  ·  started 2026-10-05T18:49:31Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ fresh repo: no .deliver.json; ~/.deliver/config.json says dispatch subagent
- ✅ doctor: result: 25 ok, 6 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-models.md

- ✅ Michael opened the job JOB-20261005-1849-rating-notch-change
wall time: 23 min

## 5 · verify the whole flow on disk

- ✅ the first /deliver wrote .deliver.json
.deliver.json: {"dispatch":"subagent","verify_full":"npm test","worktree_setup":"","merge_mode":"local"}
- ✅ …read from the repo: verify_full npm test (package.json scripts.test), no install step (no dependencies), local merge (no remote)
- ✅ …the user's own dispatch carried into it, and into the job
- ✅ …and Michael's session saw where each value came from ("verify_full: npm test — package.json scripts test")
- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 4 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 30 items — 21 decided, 9 n/a · architecture: library: ratings-lib [node+esm]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 1 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 ratings-lib: RATING_SCALE + notchChange(previous, current) in src/ratings/notch.mjs with unit tests | ratings-lib | backend#1 | 2 | FAIL | pass (qa_verify PASS) | changes | archived |
| T-02 ratings-lib: land the reviewed T-01 work (RATING_SCALE + notchChange) and finish its test nits | ratings-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
- ✅ every card (1): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration tests are on main (1 file(s) in the cards' qa_scope)
- ✅ role really ran: business-analyst
- ✅ role really ran: ecc:architect
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev agent
- ✅ role really ran: a stack reviewer
- ✅ no tracker errors
- ✅ kanban view rendered
- ✅ report.md written by the closing check
- ✅ no AI attribution in the delivered history (7 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (3 checks, models.oracle.test.mjs)

## 6 · models per role: the request's Staffing — the backend developer works on haiku


models seen (assistant messages per session, from the transcripts):
- Michael: claude-sonnet-5-5 ×145
- business-analyst: claude-opus-5-5 ×47
- ecc:architect: claude-opus-5-5 ×15
- unknown: claude-opus-5-5 ×28
- ecc:typescript-reviewer: claude-sonnet-5-5 ×12
- backend-dev: claude-haiku-4-5-20251001 ×248
- qa-tester: claude-sonnet-5-5 ×40
- ✅ Michael put it in the job: role backend → model haiku
- ✅ every backend-dev message ran on haiku (claude-haiku-4-5-20251001)
- ✅ Michael ran on a different model (claude-sonnet-5-5)
- ✅ no other role ran on haiku — only the asked role changed

## result

cost: $5.00  ·  artifacts: /tmp/claude-0/live/fresh/models
**34 passed, 0 failed**
