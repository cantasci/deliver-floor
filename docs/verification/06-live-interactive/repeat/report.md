# Live E2E — interactive (a person at the terminal)

Request: `examples/watchlist-poc/JOB.md` · started 2026-10-04T07:13:21Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

- ✅ ECC plugin installed
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · the terminal: claude in tmux, the person types /deliver and watches

    dialog: trusted the repo folder
    dialog: accepted bypass-permissions mode
- ✅ Claude Code's prompt is up (interactive session)
    person typed: /deliver /home/user/skills-shop/examples/watchlist-poc/JOB.md
    [29s] phase intake
    [39s] phase readiness
    [260s] phase planning
    [752s] phase executing
    [1924s] phase closing
    [2014s] phase done
wall time: 33 min · the person answered 0 time(s) and said continue 0 time(s)

## 3 · interactive-specific checks

- ✅ Michael opened the job JOB-20261004-0713-notch-calculator-and-country-rat from the typed /deliver
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
readiness: 31 items — 22 decided (0 by the human, 4 by the PM), 9 n/a
architecture: library: ratings-notch [javascript+node-esm] → backend/reviewer, indicators-country-rating [javascript+node-esm] → backend/reviewer
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Rating scale, notchChange and notchCalculator in src/ratings/notch.mjs | ratings-notch | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
| T-02 Indicator 12 countryRatingChangeWl in src/indicators/countryRating.mjs | indicators-country-rating | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
- ✅ every card (2): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration/e2e tests are on main (2 file(s) in the cards' qa_scope)
- ✅ role really ran: business-analyst
- ✅ role really ran: ecc:architect
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev role
- ✅ role really ran: reviewer(s)
- ✅ no tracker errors
- ✅ kanban view rendered
- ✅ report.md written by the closing check
- ✅ no AI attribution in the delivered history (7 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (5 checks, watchlist.oracle.test.mjs)

**PASSED**
