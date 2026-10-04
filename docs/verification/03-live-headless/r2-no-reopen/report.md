# Live E2E — scenario `incomplete`

Request: `examples/watchlist-poc/JOB-incomplete.md`  ·  started 2026-10-04T12:55:09Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-incomplete.md

- ✅ Michael opened the job JOB-20261004-1255-notch-calculator-and-country-rat

## 3 · the gap: Michael must stop and ask — not assume

- ✅ phase awaiting_clarification (stopped before planning)
- ✅ QUESTIONS.md asks about the unspecified sign of notches
- ✅ no card was cut before the answer
- ✅ no code was written before the answer

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-1255-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    What is the sign of notchCalculator(previous, current).notches for an upgrade? The clarification that defined it (C5) was removed from the request. notchChange is specified (positive = downgrade, negative = upgrade, 0 = unchanged), but notchCalculator's `notches` is not. Example: notchCalculator("BB+", "BBB+") returns { notches: ?, direction: "upgrade", wl: 0 }.
    
    - A) Signed, same convention as notchChange: notches = notchChange(previous, current). BB+ -> BBB+ gives notches -3; BBB+ -> BB+ gives 3; unchanged gives 0. Range -18..+18.
    - B) Magnitude only: notches = |notchChange(previous, current)| and `direction` carries the sign. BB+ -> BBB+ gives notches 3, direction 'upgrade'. Range 0..18.
    
    _Why it matters:_ Public contract that later POC screens render. Downgrades and unchanged are the same under both options; only upgrades differ (-3 vs 3). Upgrade acceptance tests cannot be written until this is answered.
    
    ## X-input-trim
    
    C1 says the input 'is trimmed' but does not say which characters trimming removes. Which leading and trailing characters are stripped before a rating is matched? And is whitespace inside a rating (e.g. 'BBB +') rejected?
    
    - A) JavaScript String.prototype.trim(): strips every ECMAScript whitespace and line terminator at both ends, including tab, CR/LF, NBSP U+00A0, BOM U+FEFF and U+2000-U+200A. ' BBB+\u00A0' is accepted.
    - B) ASCII whitespace only (space, \t, \n, \r, \f, \v) at both ends. 'BBB+\u00A0' gives RangeError.
    - C) The space character only. 'BBB+\n' gives RangeError.
    
    _Why it matters:_ Changes which inputs are accepted and which throw RangeError. In every option inner whitespace ('BBB +') is rejected with RangeError.

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-1255-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    What is the sign of notchCalculator(previous, current).notches for an upgrade? The clarification that defined it (C5) was removed from the request. notchChange is specified (positive = downgrade, negative = upgrade, 0 = unchanged), but notchCalculator's `notches` is not. Example: notchCalculator("BB+", "BBB+") returns { notches: ?, direction: "upgrade", wl: 0 }.
    
    - A) Signed, same convention as notchChange: notches = notchChange(previous, current). BB+ -> BBB+ gives notches -3; BBB+ -> BB+ gives 3; unchanged gives 0. Range -18..+18.
    - B) Magnitude only: notches = |notchChange(previous, current)| and `direction` carries the sign. BB+ -> BBB+ gives notches 3, direction 'upgrade'. Range 0..18.
    
    _Why it matters:_ Public contract that later POC screens render. Downgrades and unchanged are the same under both options; only upgrades differ (-3 vs 3). Upgrade acceptance tests cannot be written until this is answered.
    
    ## X-input-trim
    
    C1 says the input 'is trimmed' but does not say which characters trimming removes. Which leading and trailing characters are stripped before a rating is matched? And is whitespace inside a rating (e.g. 'BBB +') rejected?
    
    - A) JavaScript String.prototype.trim(): strips every ECMAScript whitespace and line terminator at both ends, including tab, CR/LF, NBSP U+00A0, BOM U+FEFF and U+2000-U+200A. ' BBB+\u00A0' is accepted.
    - B) ASCII whitespace only (space, \t, \n, \r, \f, \v) at both ends. 'BBB+\u00A0' gives RangeError.
    - C) The space character only. 'BBB+\n' gives RangeError.
    
    _Why it matters:_ Changes which inputs are accepted and which throw RangeError. In every option inner whitespace ('BBB +') is rejected with RangeError.
    (R2) answering CON-interface on purpose with an unrelated answer: C8 stands: 'displayed' is met by the returned { notches, direction, wl }; the POC screens 
- ✅ answered CON-interface — What is the sign of notchCalculator(previous, current).notches for an upgrade? The clarifi
- ✅ answered X-input-trim — C1 says the input 'is trimmed' but does not say which characters trimming removes. Which l

## 4.2 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):

## 4.3 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
wall time: 7 min

## 5 · verify the whole flow on disk

- ❌ job reached done
- ❌ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer, docs
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 4 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 33 items — 26 decided, 7 n/a · architecture: library: ratings-lib [javascript+node], indicators-lib [javascript+node]
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
- ✅ no AI attribution in the delivered history (0 commits)
- ✅ the whole test suite passes on main
- ❌ hidden oracle FAILED (oracle.log)
✖ oracle/watchlist.oracle.test.mjs (71.656995ms)
✖ failing tests:
✖ oracle/watchlist.oracle.test.mjs (71.656995ms)

## R2 · Michael does not build on an answer that does not answer its question

- ❌ CON-interface was not asked again (1 answer(s) recorded)
- ❌ the unrelated answer was frozen: C8 stands: 'displayed' is met by the returned { notches, direction, wl }; the PO

## result

cost: $1.85  ·  artifacts: /tmp/claude-0/e2e-r2/incomplete
**18 passed, 14 failed**
