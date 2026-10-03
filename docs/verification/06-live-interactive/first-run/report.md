# Live E2E — interactive (a person at the terminal)

Request: `examples/watchlist-poc/JOB.md` · started 2026-10-03T22:05:43Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

- ✅ ECC plugin installed
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · the terminal: claude in tmux, the person types /deliver and watches

    dialog: trusted the repo folder
    dialog: accepted bypass-permissions mode
- ✅ Claude Code's prompt is up (interactive session)
    person typed: /deliver /home/user/skills-shop/examples/watchlist-poc/JOB.md
    [18s] phase intake
    [28s] phase readiness
    [218s] phase awaiting_clarification
    the question form was closed to answer in chat
    person typed: My answers, in my words — record each with dl clarify: NFR-compliance: C2/C6 stand: the calculator uses the Indicator 13 thresholds (2 notches → WL 1, 3+ �
    [231s] phase planning
    [552s] phase executing
    [1715s] phase closing
    [1795s] phase done
wall time: 29 min · the person answered 1 time(s) and said continue 0 time(s)

## 3 · interactive-specific checks

- ✅ Michael opened the job JOB-20261003-2206-notch-calculator-and-country-rat from the typed /deliver
- ✅ the job finished in the interactive session
- ✅ Michael kept the job moving on his own (person said continue 0 time(s))
- ✅ the roles ran as Michael's subagents (25 agent reports)
    clarifications recorded: 1 (answers given: 1)
- ✅ every recorded human answer was given by the person

## 4 · verify the delivered job

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ a role card for every role
- ✅ readiness review complete (no open item) with an architecture
readiness: 33 items — 27 decided (1 by the human, 0 by the PM), 6 n/a
architecture: library: watchlist-ratings-lib [javascript+node] → backend/reviewer
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Ratings module: RATING_SCALE, notchChange, notchCalculator (REQ-06-02) | watchlist-ratings-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
| T-02 Indicator 12: countryRatingChangeWl built on notchChange (REQ-03-12) | watchlist-ratings-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
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
