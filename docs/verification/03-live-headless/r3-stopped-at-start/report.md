# Live E2E — scenario `complete`

Request: `examples/watchlist-poc/JOB.md`  ·  started 2026-10-04T08:00:23Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
max_attempts = 1 (one review change blocks a card)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB.md

- ✅ Michael opened the job JOB-20261004-0800-notch-calculator-and-country-rat

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the complete request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-0800-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## X-trim-whitespace
    
    C1 says 'Input is trimmed' but does not define which characters are trimmed from the start and end of a rating. Which whitespace must be stripped?
    
    - (a) All Unicode whitespace and line terminators, as JavaScript String.prototype.trim() does (space, tab, newline, CR, NBSP U+00A0, BOM U+FEFF, U+2000-U+200A …).
    - (b) ASCII whitespace only (space, \t, \n, \r, \f, \v); '\u00A0BBB+' throws RangeError.
    - (c) Spaces (U+0020) only; '\tBBB+' and 'BBB+\n' throw RangeError.
    
    _Why it matters:_ Decides which inputs are accepted vs rejected with RangeError in all three public functions; matters for ratings pasted from web pages/spreadsheets (NBSP) or CSV lines (trailing CRLF).
- ❌ no prepared answer for X-trim-whitespace — a real person must answer: C1 says 'Input is trimmed' but does not define which characters are trimmed from the start and end of a rating. Which whitespace must be stripped?

## 4.2 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the complete request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-0800-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## X-trim-whitespace
    
    C1 says 'Input is trimmed' but does not define which characters are trimmed from the start and end of a rating. Which whitespace must be stripped?
    
    - (a) All Unicode whitespace and line terminators, as JavaScript String.prototype.trim() does (space, tab, newline, CR, NBSP U+00A0, BOM U+FEFF, U+2000-U+200A …).
    - (b) ASCII whitespace only (space, \t, \n, \r, \f, \v); '\u00A0BBB+' throws RangeError.
    - (c) Spaces (U+0020) only; '\tBBB+' and 'BBB+\n' throw RangeError.
    
    _Why it matters:_ Decides which inputs are accepted vs rejected with RangeError in all three public functions; matters for ratings pasted from web pages/spreadsheets (NBSP) or CSV lines (trailing CRLF).
- ❌ no prepared answer for X-trim-whitespace — a real person must answer: C1 says 'Input is trimmed' but does not define which characters are trimmed from the start and end of a rating. Which whitespace must be stripped?

## 4.3 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the complete request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-0800-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## X-trim-whitespace
    
    C1 says 'Input is trimmed' but does not define which characters are trimmed from the start and end of a rating. Which whitespace must be stripped?
    
    - (a) All Unicode whitespace and line terminators, as JavaScript String.prototype.trim() does (space, tab, newline, CR, NBSP U+00A0, BOM U+FEFF, U+2000-U+200A …).
    - (b) ASCII whitespace only (space, \t, \n, \r, \f, \v); '\u00A0BBB+' throws RangeError.
    - (c) Spaces (U+0020) only; '\tBBB+' and 'BBB+\n' throw RangeError.
    
    _Why it matters:_ Decides which inputs are accepted vs rejected with RangeError in all three public functions; matters for ratings pasted from web pages/spreadsheets (NBSP) or CSV lines (trailing CRLF).
- ❌ no prepared answer for X-trim-whitespace — a real person must answer: C1 says 'Input is trimmed' but does not define which characters are trimmed from the start and end of a rating. Which whitespace must be stripped?
wall time: 4 min

## 5 · verify the whole flow on disk

- ❌ job reached done
- ❌ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 3 (implementation details, recorded with rationale)
- ❌ readiness review complete (no open item) with an architecture
readiness: 31 items — 22 decided, 8 n/a · architecture: library: watchlist-domain-lib [javascript+node]
- ❌ readiness frozen at planning and unchanged since
- ❌ no cards on the board
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
- ❌ no QA test files on main
- ✅ role really ran: business-analyst
- ❌ no ecc:architect run in events.log
- ❌ no qa-tester run in events.log
- ❌ no dev agent run
- ❌ no reviewer run
- ✅ no tracker errors
- ❌ kanban view rendered
- ❌ report.md is the template
- ✅ no AI attribution in the delivered history (1 commits)
- ✅ the whole test suite passes on main
- ❌ hidden oracle FAILED (oracle.log)
✖ oracle/watchlist.oracle.test.mjs (64.642914ms)
✖ failing tests:
✖ oracle/watchlist.oracle.test.mjs (64.642914ms)

## R3 · a blocked card is Michael's decision — no question to the human after the start

R3 NOT EXERCISED: no card was blocked in this run (every card passed on its one attempt)

## result

cost: $1.16  ·  artifacts: /tmp/claude-0/e2e-r3/complete
**11 passed, 16 failed**
