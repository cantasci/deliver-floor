# Live E2E — scenario `incomplete`

Request: `examples/watchlist-poc/JOB-incomplete.md`  ·  started 2026-10-04T13:06:35Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-incomplete.md

- ✅ Michael opened the job JOB-20261004-1306-notch-calculator-and-country-rat

## 3 · the gap: Michael must stop and ask — not assume

- ✅ phase awaiting_clarification (stopped before planning)
- ✅ QUESTIONS.md asks about the unspecified sign of notches
- ✅ no card was cut before the answer
- ✅ no code was written before the answer

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-1306-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    C5 is missing: what is the sign of notchCalculator(previous, current).notches? Signed (and if so is a downgrade positive or negative) or an unsigned magnitude with `direction` carrying the sign?
    
    - A: signed, same convention as notchChange: ('BBB+','BB+') → {notches:3,direction:'downgrade',wl:2}; ('BB+','BBB+') → {notches:-3,direction:'upgrade',wl:0}
    - B: unsigned magnitude: ('BBB+','BB+') → {notches:3,…}; ('BB+','BBB+') → {notches:3,direction:'upgrade',wl:0}
    - C: signed, negative = downgrade: ('BBB+','BB+') → {notches:-3,direction:'downgrade',wl:2}; ('BB+','BBB+') → {notches:3,direction:'upgrade',wl:0}
    
    _Why it matters:_ Public contract that other POC parts import exactly; every consumer and test reading `notches` depends on it. The contract fixes notchChange's sign but not notchCalculator's.

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-1306-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    C5 is missing: what is the sign of notchCalculator(previous, current).notches? Signed (and if so is a downgrade positive or negative) or an unsigned magnitude with `direction` carrying the sign?
    
    - A: signed, same convention as notchChange: ('BBB+','BB+') → {notches:3,direction:'downgrade',wl:2}; ('BB+','BBB+') → {notches:-3,direction:'upgrade',wl:0}
    - B: unsigned magnitude: ('BBB+','BB+') → {notches:3,…}; ('BB+','BBB+') → {notches:3,direction:'upgrade',wl:0}
    - C: signed, negative = downgrade: ('BBB+','BB+') → {notches:-3,direction:'downgrade',wl:2}; ('BB+','BBB+') → {notches:3,direction:'upgrade',wl:0}
    
    _Why it matters:_ Public contract that other POC parts import exactly; every consumer and test reading `notches` depends on it. The contract fixes notchChange's sign but not notchCalculator's.
    (R2) answering CON-interface on purpose with an unrelated answer: C8 stands: 'displayed' is met by the returned { notches, direction, wl }; the POC screens 
- ✅ answered CON-interface — C5 is missing: what is the sign of notchCalculator(previous, current).notches? Signed (and

## 4.2 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-1306-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    C5 is missing: what is the sign of notchCalculator(previous, current).notches? Signed (and if so is a downgrade positive or negative) or an unsigned magnitude with `direction` carrying the sign? (Asked again: the recorded answer did not answer it — The recorded answer is about C8 (what 'displayed' means), not the question asked: the sign convention of notchCalculator(previous, current).notches (options A/B/C).)
    
    - A: signed, same convention as notchChange: ('BBB+','BB+') → {notches:3,direction:'downgrade',wl:2}; ('BB+','BBB+') → {notches:-3,direction:'upgrade',wl:0}
    - B: unsigned magnitude: ('BBB+','BB+') → {notches:3,…}; ('BB+','BBB+') → {notches:3,direction:'upgrade',wl:0}
    - C: signed, negative = downgrade: ('BBB+','BB+') → {notches:-3,direction:'downgrade',wl:2}; ('BB+','BBB+') → {notches:3,direction:'upgrade',wl:0}
    
    _Why it matters:_ Public contract that other POC parts import exactly; every consumer and test reading `notches` depends on it. The contract fixes notchChange's sign but not notchCalculator's.
- ✅ answered CON-interface — C5 is missing: what is the sign of notchCalculator(previous, current).notches? Signed (and
wall time: 22 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 5 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 31 items — 23 decided, 8 n/a · architecture: library: ratings-lib [javascript+node], indicators-lib [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 ratings-lib: RATING_SCALE, notchChange and notchCalculator (REQ-06-02) | ratings-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 indicators-lib: Indicator 12 countryRatingChangeWl (REQ-03-12) | indicators-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
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
- ✅ no AI attribution in the delivered history (7 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (5 checks, watchlist.oracle.test.mjs)

## R2 · Michael does not build on an answer that does not answer its question

- ✅ CON-interface was asked again after the unrelated answer (2 answers recorded)
- ✅ Michael put CON-interface back to the human (dl reopen): CON-interface: The recorded answer is about C8 (what 'displayed' means), not the question asked: the
- ✅ the frozen answer for CON-interface is the right one: notchCalculator(...).notches is signed exactly like notchChange: downgrade posit

## result

cost: $5.54  ·  artifacts: /tmp/claude-0/e2e-r2/incomplete
**34 passed, 0 failed**
