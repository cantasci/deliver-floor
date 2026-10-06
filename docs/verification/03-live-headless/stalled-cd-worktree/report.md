# Live E2E — scenario `models`

Request: `examples/watchlist-poc/JOB-models.md`  ·  started 2026-10-05T21:50:46Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ fresh repo: no .deliver.json; ~/.deliver/config.json says dispatch subagent
- ✅ doctor: result: 26 ok, 6 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-models.md

- ✅ Michael opened the job JOB-20261005-2151-rating-notch-change
wall time: 15 min

## 5 · verify the whole flow on disk

- ✅ the first /deliver wrote .deliver.json
.deliver.json: {"dispatch":"subagent","verify_full":"npm test","worktree_setup":"","merge_mode":"local"}
- ✅ …read from the repo: verify_full npm test (package.json scripts.test), no install step (no dependencies), local merge (no remote)
- ✅ …the user's own dispatch carried into it, and into the job
- ✅ …and Michael's session saw where each value came from ("verify_full: npm test — package.json scripts test")
- ❌ job reached done
- ❌ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 3 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 30 items — 20 decided, 10 n/a · architecture: library: ratings-lib [node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 1 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Add src/ratings/notch.mjs (RATING_SCALE + notchChange) with unit tests | ratings-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | - | review |
- ❌ T-01 did not go through assign → dev → gate → QA → review → merge
- ❌ no QA test files on main
- ✅ role really ran: business-analyst
- ✅ role really ran: ecc:architect
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev agent
- ✅ role really ran: a stack reviewer
- ✅ no tracker errors
- ✅ kanban view rendered
- ❌ report.md is the template
- ✅ no AI attribution in the delivered history (1 commits)
- ✅ the whole test suite passes on main
- ❌ hidden oracle FAILED (oracle.log)
✖ oracle/models.oracle.test.mjs (54.158194ms)
✖ failing tests:
✖ oracle/models.oracle.test.mjs (54.158194ms)

## 6 · models per role: the request's Staffing — the backend developer works on haiku


models seen (assistant messages per session, from the transcripts):
- Michael: claude-sonnet-5-5 ×89
- qa-tester: claude-sonnet-5-5 ×18
- business-analyst: claude-opus-5-5 ×31
- ecc:architect: claude-opus-5-5 ×7
- ecc:typescript-reviewer: claude-sonnet-5-5 ×7
- backend-dev: claude-haiku-4-5-20251001 ×58
- ✅ Michael put it in the job: role backend → model haiku
- ✅ every backend-dev message ran on haiku (claude-haiku-4-5-20251001)
- ✅ Michael ran on a different model (claude-sonnet-5-5)
- ✅ no other role ran on haiku — only the asked role changed

## result

cost: $3.49  ·  artifacts: /tmp/claude-0/live/k050/models
**28 passed, 6 failed**
