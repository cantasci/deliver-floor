# Live E2E — interactive (a person at the terminal)

Request: `examples/watchlist-poc/JOB-models-plain.md` · started 2026-10-05T06:19:04Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

- ✅ ECC plugin installed
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · the terminal: claude in tmux, the person types /deliver and watches

    dialog: trusted the repo folder
    dialog: accepted bypass-permissions mode
- ✅ Claude Code's prompt is up (interactive session)
    person typed: /deliver /home/user/skills-shop/examples/watchlist-poc/JOB-models-plain.md — the backend developer works on the haiku model
    [29s] phase readiness
    [219s] phase planning
    [491s] phase executing
    [843s] phase integrating
    [853s] phase closing
    [923s] phase done
wall time: 15 min · the person answered 0 time(s) and said continue 0 time(s)

## 3 · interactive-specific checks

- ✅ Michael opened the job JOB-20261005-0619-rating-notch-change from the typed /deliver
- ✅ the job finished in the interactive session
- ✅ Michael kept the job moving on his own (person said continue 0 time(s))
- ✅ the roles ran as Michael's subagents (30 agent reports)
    clarifications recorded: 0 (answers given: 0)
- ✅ every recorded human answer was given by the person

## 4 · verify the delivered job

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ a role card for every role
- ✅ readiness review complete (no open item) with an architecture
readiness: 29 items — 19 decided (0 by the human, 3 by the PM), 10 n/a
architecture: library: ratings [javascript] → backend/reviewer
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 1 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 ratings: add src/ratings/notch.mjs (RATING_SCALE + notchChange) with TDD unit tests | ratings | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
- ✅ every card (1): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration/e2e tests are on main (1 file(s) in the cards' qa_scope)
- ✅ role really ran: business-analyst
- ✅ role really ran: ecc:architect
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev role
- ✅ role really ran: reviewer(s)
- ✅ no tracker errors
- ✅ kanban view rendered
- ✅ report.md written by the closing check
- ✅ no AI attribution in the delivered history (4 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (3 checks, models.oracle.test.mjs)

## models per role: the person told Michael "the backend developer works on the haiku model"


models seen (assistant messages per session, from the transcripts):
- Michael: claude-sonnet-5-5 ×91
- backend-dev: claude-haiku-4-5-20251001 ×43
- ecc:typescript-reviewer: claude-sonnet-5-5 ×7
- business-analyst: claude-opus-5-5 ×46
- ecc:architect: claude-opus-5-5 ×8
- qa-tester: claude-sonnet-5-5 ×14
- ✅ Michael put it in the job: role backend → model haiku
- ✅ every backend-dev message ran on haiku (claude-haiku-4-5-20251001)
- ✅ Michael ran on a different model (claude-sonnet-5-5)
- ✅ no other role ran on haiku — only the asked role changed

**PASSED**
