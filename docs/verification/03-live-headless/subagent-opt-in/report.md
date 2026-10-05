# Live E2E — scenario `complete`

Request: `examples/watchlist-poc/JOB.md`  ·  started 2026-10-05T09:18:58Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 26 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB.md

- ✅ Michael opened the job JOB-20261005-0919-rating-notch-calculator-and-coun

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the complete request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261005-0919-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## X-input-trim
    
    C1 says the input is 'trimmed' but does not say which characters are removed. Which leading and trailing characters must be stripped before a rating is matched? Are look-alike characters (Unicode minus U+2212 or en dash in 'BBB−', fullwidth letters) normalised or rejected?
    
    - A: JavaScript String.prototype.trim(): all Unicode whitespace and line terminators (incl. NBSP U+00A0); look-alikes rejected
    - B: ASCII whitespace only (space, \t, \n, \r, \v, \f); NBSP and other Unicode spaces rejected; look-alikes rejected
    - C: spaces only (U+0020); everything else rejected
    - D: A plus look-alike normalisation (U+2212 or en dash -> '-', fullwidth -> ASCII)
    
    _Why it matters:_ Changes observable behaviour: ('BBB+\u00A0','BBB+') returns 0 under A or D but throws RangeError under B or C; 'BBB−' (U+2212) accepted only under D. Tests and QA data cannot be fixed until answered.
- ✅ answered X-input-trim — C1 says the input is 'trimmed' but does not say which characters are removed. Which leadin
wall time: 18 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 5 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 35 items — 25 decided, 10 n/a · architecture: library: ratings-indicators-lib [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Rating scale, notchChange and notchCalculator (src/ratings/notch.mjs) | ratings-indicators-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 Indicator 12 country rating change WL (src/indicators/countryRating.mjs) | ratings-indicators-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
- ✅ every card (2): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration tests are on main (4 file(s) in the cards' qa_scope)
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
- ✅ hidden oracle passes (5 checks, watchlist.oracle.test.mjs)

## result

cost: $4.58  ·  artifacts: /tmp/claude-0/e2e-hS/complete
**26 passed, 0 failed**
