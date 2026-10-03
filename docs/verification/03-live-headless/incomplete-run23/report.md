# Live E2E — scenario `incomplete`

Request: `examples/watchlist-poc/JOB-incomplete.md`  ·  started 2026-10-03T22:24:46Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-incomplete.md

- ✅ Michael opened the job JOB-20261003-2225-rating-notch-calculator-and-coun

## 3 · the gap: Michael must stop and ask — not assume

- ✅ phase awaiting_clarification (stopped before planning)
- ✅ QUESTIONS.md asks about the unspecified sign of notches
- ✅ no card was cut before the answer
- ✅ no code was written before the answer

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261003-2225-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    What is the sign of notchCalculator(previous, current).notches? Clarification C5, which the document skips, presumably defined it. Settled: notchChange is a signed integer (positive = downgrade, negative = upgrade, 0 = unchanged); direction is exactly 'downgrade' | 'upgrade' | 'unchanged'; wl is 0|1|2; the returned object has exactly the keys notches, direction, wl. NOT settled: whether notches is signed like notchChange or an unsigned magnitude with direction carrying the sign. For downgrades both agree (BBB+ -> BB+: 3); for upgrades they differ (BB+ -> BBB+: -3 or 3).
    
    - A: notches is signed and identical to notchChange: downgrade positive, upgrade negative, unchanged 0. BB+ -> BBB+ gives { notches: -3, direction: 'upgrade', wl: 0 }.
    - B: notches is the unsigned magnitude |notchChange| (0..18); the sign lives only in direction. BB+ -> BBB+ gives { notches: 3, direction: 'upgrade', wl: 0 }.
    
    _Why it matters:_ Changes the public contract other POC parts import 'exactly'. Consumers that render or compare notches break if they assume the other convention. Upgrade ACs and test data cannot be written until decided. Downgrade and unchanged cases are identical under A and B.

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261003-2225-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    What is the sign of notchCalculator(previous, current).notches? Clarification C5, which the document skips, presumably defined it. Settled: notchChange is a signed integer (positive = downgrade, negative = upgrade, 0 = unchanged); direction is exactly 'downgrade' | 'upgrade' | 'unchanged'; wl is 0|1|2; the returned object has exactly the keys notches, direction, wl. NOT settled: whether notches is signed like notchChange or an unsigned magnitude with direction carrying the sign. For downgrades both agree (BBB+ -> BB+: 3); for upgrades they differ (BB+ -> BBB+: -3 or 3).
    
    - A: notches is signed and identical to notchChange: downgrade positive, upgrade negative, unchanged 0. BB+ -> BBB+ gives { notches: -3, direction: 'upgrade', wl: 0 }.
    - B: notches is the unsigned magnitude |notchChange| (0..18); the sign lives only in direction. BB+ -> BBB+ gives { notches: 3, direction: 'upgrade', wl: 0 }.
    
    _Why it matters:_ Changes the public contract other POC parts import 'exactly'. Consumers that render or compare notches break if they assume the other convention. Upgrade ACs and test data cannot be written until decided. Downgrade and unchanged cases are identical under A and B.
- ✅ answered CON-interface — What is the sign of notchCalculator(previous, current).notches? Clarification C5, which th
wall time: 17 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 3 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 31 items — 22 decided, 9 n/a · architecture: library: ratings-notch [javascript+node], indicators-country-rating [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Rating scale, notchChange and notchCalculator in src/ratings/notch.mjs (REQ-06-02) | ratings-notch | backend#1 | 2 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 Indicator 12 countryRatingChangeWl in src/indicators/countryRating.mjs (REQ-03-12) | indicators-country-rating | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
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

cost: $4.60  ·  artifacts: /tmp/claude-0/e2e-hi/incomplete
**30 passed, 0 failed**
