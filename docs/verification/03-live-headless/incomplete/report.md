# Live E2E — scenario `incomplete`

Request: `examples/watchlist-poc/JOB-incomplete.md`  ·  started 2026-10-03T13:55:32Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-incomplete.md

- ✅ Michael opened the job JOB-20261003-1355-notch-calculator-and-country-rat

## 3 · the gap: Michael must stop and ask — not assume

- ✅ phase awaiting_clarification (stopped before planning)
- ✅ QUESTIONS.md asks about the unspecified sign of notches
- ✅ no card was cut before the answer
- ✅ no code was written before the answer

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261003-1355-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    What sign does notchCalculator(previous, current).notches carry for an upgrade? The two readings: it is the signed 'notch change' (REQ-06-02 wording, same as notchChange), or it is a magnitude, with the separate `direction` field carrying the sign.
    
    - A. Signed, identical to notchChange(previous, current): BBB+ -> BB+ gives { notches: 3, direction: 'downgrade', wl: 2 }; BBB- -> BBB+ gives { notches: -2, direction: 'upgrade', wl: 0 }; unchanged gives notches 0.
    - B. Unsigned magnitude (always >= 0), direction carries the sign: BBB+ -> BB+ gives { notches: 3, direction: 'downgrade', wl: 2 }; BBB- -> BBB+ gives { notches: 2, direction: 'upgrade', wl: 0 }; unchanged gives notches 0.
    
    _Why it matters:_ This is a public contract that other POC parts import and render ('N-notch upgrade'). With A, renderers must take the absolute value, and notches duplicates notchChange. With B, callers who need the signed value call notchChange, and notches matches the request's own phrasing ('3-notch downgrade'). Downgrades, unchanged, wl and direction are the same under both options. Only the upgrade value of notches changes, plus every AC and test that asserts it. Choosing wrong breaks consumers or forces a contract change later.

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261003-1355-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    What sign does notchCalculator(previous, current).notches carry for an upgrade? The two readings: it is the signed 'notch change' (REQ-06-02 wording, same as notchChange), or it is a magnitude, with the separate `direction` field carrying the sign.
    
    - A. Signed, identical to notchChange(previous, current): BBB+ -> BB+ gives { notches: 3, direction: 'downgrade', wl: 2 }; BBB- -> BBB+ gives { notches: -2, direction: 'upgrade', wl: 0 }; unchanged gives notches 0.
    - B. Unsigned magnitude (always >= 0), direction carries the sign: BBB+ -> BB+ gives { notches: 3, direction: 'downgrade', wl: 2 }; BBB- -> BBB+ gives { notches: 2, direction: 'upgrade', wl: 0 }; unchanged gives notches 0.
    
    _Why it matters:_ This is a public contract that other POC parts import and render ('N-notch upgrade'). With A, renderers must take the absolute value, and notches duplicates notchChange. With B, callers who need the signed value call notchChange, and notches matches the request's own phrasing ('3-notch downgrade'). Downgrades, unchanged, wl and direction are the same under both options. Only the upgrade value of notches changes, plus every AC and test that asserts it. Choosing wrong breaks consumers or forces a contract change later.
- ✅ answered CON-interface — What sign does notchCalculator(previous, current).notches carry for an upgrade? The two re
wall time: 17 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, qa, backend-lead, backend, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 2 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 29 items — 20 decided, 9 n/a · architecture: library: watchlist-domain-lib [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Notch calculator helper: RATING_SCALE, notchChange, notchCalculator (src/ratings/notch.mjs) with unit tests | watchlist-domain-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 Indicator 12 country rating change WL: countryRatingChangeWl (src/indicators/countryRating.mjs) with unit tests | watchlist-domain-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
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

## result

cost: $4.67  ·  artifacts: /tmp/claude-0/e2e/incomplete
**30 passed, 0 failed**
