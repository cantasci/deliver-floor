# Live E2E — scenario `complete`

Request: `examples/watchlist-poc/JOB.md`  ·  started 2026-10-21T13:17:05Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
fault injection (E2E_INJECT=qa-wrong): a post-merge hook in the sandbox, once — see injected.log
- ✅ doctor: result: 30 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB.md

- ✅ Michael opened the job JOB-20261021-1317-rating-notch-calculator-and-coun
wall time: 25 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer, blind
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 3 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 33 items — 21 decided, 12 n/a · architecture: library: rating-indicators [node+javascript-esm]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Rating scale, notchChange and notchCalculator (src/ratings/notch.mjs) | rating-indicators | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 Indicator 12 country rating change WL (src/indicators/countryRating.mjs) | rating-indicators | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
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
- ✅ no AI attribution in the delivered history (12 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (5 checks, watchlist.oracle.test.mjs)
- ❌ the job took 24.8 min (> 15) — where it went: intake 0.3, readiness 4.4, readiness 0, planning 7.7, executing 9.5, integrating 0.1, closing 2.7; busiest: business-analyst 8.8 min (timeline.txt)

## B3 · risk-based test design and the NFR gate

- ✅ every AC of the plan has a priority: AC-1 P1, AC-2 P3, AC-3 P0, AC-4 P0, AC-5 P1, AC-6 P0, AC-7 P1, AC-8 P1, AC-9 P0, AC-10 P3, AC-11 P1, AC-12 P2
- ✅ every card spec has a ## Test design

Test design of T-01:
    ## Test design
    Dev unit tests go in `test/ratings/notch.test.mjs`. QA integration tests go in `test/integration/ratings/notch.integration.test.mjs` and import from `../../../src/ratings/notch.mjs`, the contract path. Neither may use a helper `.mjs` under `test/`.
    
    | AC | priority | level | scenarios |
    |---|---|---|---|
    | AC-1 | P1 | dev unit + QA integration | deep-equal of the full scale; length 19; index 0 `"AAA"` and index 18 `"CCC-"` |
    | AC-2 | P3 | dev unit | test "RATING_SCALE is frozen": `Object.isFrozen`; `push("D")` and `[0] = "X"` throw `TypeError`; length and `[0]` unchanged afterwards |
    | AC-3 | P0 | dev unit + QA integration | every row of table A, with `Number.isInteger`; both signs; both scale ends (18 / −18); unchanged at both ends; letter boundary (`A-`→`BBB`); `+0` not `-0` for equal ratings |
    | AC-4 | P0 | dev unit + QA integration | every row of table B with `deepStrictEqual`; WL boundaries 1→0, 2→1, 3→2; maximum 18→2; `Object.keys(r).sort()` deep-equals `["direction","notches","wl"]` |
    | AC-5 | P1 | QA integration (dev unit through TDD) | every row of table C; key edges: −1, −18, 0 at the top end; `r.notches === notchChange(p, c)` for every row of B and C |
    | AC-8 | P1 | QA integration (dev unit through TDD) | every row of table D; key edges: case only in `previous`, case only in `current`, `\t`/`\n`/`\r`/` ` padding, both functions |
    | AC-9 | P0 | dev unit + QA integration | every table E value × both positions × both functions → `RangeError`; one-argument calls; dev extras: zero arguments, boxed String, Symbol, null-prototype object |
    | AC-10 | P3 | dev unit (type only) + review | test "invalid argument throws RangeError naming the argument": the table F calls throw `RangeError`; review reads the message (argument name, value, previous first) |
    | AC-11 | P1 | QA integration | import the three names by the contract path; `typeof` is `"function"`; `.length === 2` on both; extra-argument call unchanged |
    | AC-12 | P2 | QA integration + review | result is not a Promise; two calls deep-equal; mutating a returned object does not change the next result; review: no imports, no I/O, no console output |
    
QA verdicts (each must name every AC of its card — dl qa refuses otherwise):
    - T-01: AC-1: AC-1: deep-equals the 19-step scale, best first; AC-2 unit: RATING_SCALE is frozen (AC-2); AC-3: AC-3: sign is index(current) - index(previous) for every pair of the scale; AC-4: AC-4: WL boundaries 1 -> 0, 2 -> 1,
    - T-02: AC-6: AC-6 downgrade rows + C6 contrast tests; AC-7: upgrade/unchanged rows test; AC-8: table B normalisation tests; AC-9: table C x both positions RangeError tests; AC-10: table D RangeError message test; AC-11: export 
decided NFR items: NFR-security
- ✅ the report gives every decided NFR item a result: NFR-security PASS
- ✅ the plan says how each is checked (## Non-functional requirements)

## B4 · the blind review

settings.review.blind: risk
- ✅ T-01 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
- ✅ T-02 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
blind agent runs: 2

## 0.18 · inputs only when the work needs them

- ✅ DEL-inputs: no input asked for by default (a .env file is never needed unless the work reads it)
- ✅ …and the human was not asked for a .env file or a key
verify-all: 1 call(s), 1 run(s) of the suite — PASS;

## fault injected (qa-wrong, disclosed): what the team did with it

injection: injected (qa-wrong) at 01b059aa487cad531c9a1c7f1ff879e525713dcb on job/JOB-20261021-1317-rating-notch-calculator-and-coun--T-01, after: Merge T-01: QA tests
    2026-10-21T13:33:35Z	gate	T-01 PASS
    2026-10-21T13:34:47Z	qa	T-01 pass (qa_verify PASS) — AC-1: AC-1: deep-equals the 19-step scale, best first; AC-2 unit: RATING_SCALE is frozen (AC-2); AC-3: AC-3: sign is index(current) - index(previous) for every pair of the scale; AC-4: AC-4: WL boundaries 
    2026-10-21T13:35:36Z	integrate	T-01 merged
    2026-10-21T13:35:37Z	merge-check	T-01 PASS (rating-indicators suite)
    2026-10-21T13:37:19Z	gate	T-02 PASS
    2026-10-21T13:38:49Z	qa	T-02 pass (qa_verify PASS) — AC-6: AC-6 downgrade rows + C6 contrast tests; AC-7: upgrade/unchanged rows test; AC-8: table B normalisation tests; AC-9: table C x both positions RangeError tests; AC-10: table D RangeError message test;
    2026-10-21T13:39:23Z	integrate	T-02 merged
    2026-10-21T13:39:23Z	merge-check	T-02 PASS (rating-indicators suite)
    2026-10-21T13:39:54Z	verify-all	PASS
- ❌ QA's own wrong test failed the gate
- ❌ …QA fixed it and the next gate took it as QA's (qa_fix), no new dev attempt
qa_fix: []

## result

cost: $5.52  ·  artifacts: <work>
**33 passed, 3 failed**
