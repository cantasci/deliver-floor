# Live E2E — scenario `complete`

Request: `examples/watchlist-poc/JOB.md`  ·  started 2026-10-04T12:55:09Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
max_attempts = 1 (one review change blocks a card)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB.md

- ✅ Michael opened the job JOB-20261004-1255-rating-notch-calculator-and-coun

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the complete request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-1255-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## X-trim
    
    C1 says input is trimmed but not which characters are stripped. Which whitespace must be removed from both ends before matching?
    
    - A: JavaScript String.prototype.trim() — all Unicode whitespace incl. NBSP, tabs, newlines
    - B: ASCII whitespace only (space, \t, \n, \r, \f, \v); NBSP etc. -> RangeError
    - C: plain spaces only; tabs/newlines/NBSP -> RangeError
    
    _Why it matters:_ Which inputs are accepted vs RangeError, e.g. 'BBB+\u00a0' accepted under A only.
- ✅ answered X-trim — C1 says input is trimmed but not which characters are stripped. Which whitespace must be r
wall time: 19 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 3 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 31 items — 23 decided, 8 n/a · architecture: library: watchlist-ratings [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Notch calculator module: RATING_SCALE, notchChange, notchCalculator (REQ-06-02) | watchlist-ratings | backend#1 | 1 | FAIL | - (qa_verify -) | - | archived |
| T-02 Indicator 12 country rating change WL: countryRatingChangeWl (REQ-03-12) | watchlist-ratings | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-03 Notch calculator module (re-run of T-01 with portable verify) | watchlist-ratings | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
- ✅ every card (2): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration tests are on main (2 file(s) in the cards' qa_scope)
- ✅ role really ran: business-analyst
- ✅ role really ran: ecc:architect
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev agent
- ✅ role really ran: a stack reviewer
- ✅ no tracker errors
- ✅ kanban view rendered
- ✅ report.md written by the closing check
- ✅ no AI attribution in the delivered history (8 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (5 checks, watchlist.oracle.test.mjs)

## R3 · a blocked card is Michael's decision — no question to the human after the start

blocked card(s): T-01 
- ✅ no question to the human after planning (no clarify, no APPROVAL.md)
- ✅ T-01 was decided by Michael: now archived
- ✅ …with a recorded decision: T-01: T-01 is not delivered (archived) — replaced by T-03: verify command fixed; T-01's work is reused
- ✅ the PR body lists his decisions
note: a dropped card leaves its requirement undelivered — the oracle result above shows the effect

## result

cost: $5.02  ·  artifacts: /tmp/claude-0/e2e-r3/complete
**30 passed, 0 failed**
