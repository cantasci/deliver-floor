# Live E2E — scenario `complete`

Request: `examples/watchlist-poc/JOB.md`  ·  started 2026-10-04T17:31:53Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
max_attempts = 1 (one review change blocks a card)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB.md

- ✅ Michael opened the job JOB-20261004-1732-rating-notch-calculator-and-coun

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the complete request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-1732-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## X-input-whitespace
    
    C1 says the input is 'trimmed' but not which whitespace. Which characters are removed before a rating is matched?
    
    - A: JavaScript String.prototype.trim(): all Unicode whitespace and line terminators at both ends (space, tab, CR/LF, NBSP, BOM …).
    - B: ASCII whitespace only (space, tab, CR, LF, VT, FF); NBSP or other Unicode spaces give a RangeError.
    - C: Plain space only; tabs, newlines and NBSP give a RangeError.
    
    _Why it matters:_ Changes observable behaviour for inputs such as '\tBBB+\n' or '\u00A0BBB+'. QA cannot write the trimming criterion until answered. Internal whitespace ('BBB +') is rejected under every option.
- ✅ answered X-input-whitespace — C1 says the input is 'trimmed' but not which whitespace. Which characters are removed befo
wall time: 17 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 2 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 32 items — 22 decided, 10 n/a · architecture: library: ratings-lib [javascript]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Rating scale, notchChange and notchCalculator (REQ-06-02) | ratings-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 Indicator 12 country rating change WL (REQ-03-12) | ratings-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
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

R3 NOT EXERCISED: no card was blocked in this run (every card passed on its one attempt)

## result

cost: $4.43  ·  artifacts: /tmp/claude-0/e2e-r3b/complete
**26 passed, 0 failed**
