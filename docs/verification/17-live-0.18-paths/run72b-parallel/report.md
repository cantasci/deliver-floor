# Live E2E — scenario `parallel`

Request: `examples/watchlist-poc/JOB-parallel.md`  ·  started 2026-10-21T13:26:07Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
fault injection (E2E_INJECT=hang): a post-merge hook in the sandbox, once — see injected.log
suite_runs batch · suite_timeout_min 1
- ✅ doctor: result: 30 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-parallel.md

- ✅ Michael opened the job JOB-20261021-1326-indicators-2-and-3-repayment-del

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the parallel request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261021-1326-indicators-2-and-3-repayment-del
    
    Answer each question in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## ARC-style
    
    What is the project's architecture style? The request fixes this slice's module paths (src/indicators/*.mjs) but not what the repository is as a whole. The draft leaves the style open.
    
    - As in the draft: one component 'repo', kind library, plain Node ESM, path '.', suite 'npm test'. Areas such as src/indicators and src/ratings are folders inside it (recommended)
    - Modular monolith: each src/<area> is its own module with a boundary
    - Something else the team names
    
    _Why it matters:_ No effect on this slice's code (the Contract fixes the files). It fixes the project standard (architecture.md) later jobs quote.
    
    ## ARC-components
    
    Is the component list right? The draft lists one component: 'repo', library, javascript, path '.', suite 'npm test'. This slice adds src/indicators/daysWithDelay.mjs and delayCount.mjs with tests under test/indicators/.
    
    - As in the draft: one library component at '.', suite 'npm test' (= node --test) (recommended)
    - One component per area (e.g. 'indicators' at src/indicators/ + test/indicators/), each with its own suite command
    - Something else the team names
    
    _Why it matters:_ Decides card component tags, reviewer routing and whether QA runs the full or an area suite. The two cards build the same either way.
    
    ## X-string-object
    
    Does a String wrapper object such as new String('>1') count as a string (trimmed and mapped) or as a non-string (RangeError)? C5 does not define 'string'.
    
    - Only primitive strings (typeof === 'string'); a String object throws RangeError (recommended)
    - String objects are accepted and mapped like their primitive value
    
    _Why it matters:_ Rare input only; decides one QA edge test per function.
- ✅ answered ARC-style — What is the project's architecture style? The request fixes this slice's module paths (src
- ✅ answered ARC-components — Is the component list right? The draft lists one component: 'repo', library, javascript, p
- ✅ answered X-string-object — Does a String wrapper object such as new String('>1') count as a string (trimmed and mappe
wall time: 33 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend×2, qa×2, reviewer, blind
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 3 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 34 items — 21 decided, 13 n/a · architecture: library: repo [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 3 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 REQ-03-02 Indicator 2 Days with delay: DAYS_WITH_DELAY_OPTIONS + daysWithDelayWl | repo | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 REQ-03-03 Indicator 3 Delays in 12 months: DELAY_COUNT_OPTIONS + delayCountWl | repo | backend#2 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-03 Remove the never-ending test/zz-scale-loaded.test.mjs so `node --test` finishes | repo | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
- ✅ every card (3): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration tests are on main (3 file(s) in the cards' qa_scope)
- ✅ role really ran: business-analyst
- ✅ role really ran: ecc:architect
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev agent
- ✅ role really ran: a stack reviewer
- ✅ no tracker errors
- ✅ kanban view rendered
- ✅ report.md written by the closing check
- ✅ no AI attribution in the delivered history (17 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (2 checks, parallel.oracle.test.mjs)
- ❌ the job took 33.2 min (> 15) — where it went: intake 0.5, readiness 5, awaiting_clarification 0.6, planning 7, executing 16.1, integrating 0.5, closing 3.5; busiest: business-analyst 8.2 min (timeline.txt)

## 6 · parallel seats

- ✅ the backend role has 2+ seats
seats used: backend#1, backend#2
- ✅ a second seat was used
- ✅ two cards were assigned before the first merge (they ran in parallel)

## B3 · risk-based test design and the NFR gate

- ✅ every AC of the plan has a priority: AC-1 P1, AC-2 P2, AC-3 P3, AC-4 P2, AC-5 P1, AC-6 P1, AC-7 P1, AC-8 P2, AC-9 P3, AC-10 P2, AC-11 P1, AC-12 P1, AC-13 P3, AC-14 P3
- ✅ every card spec has a ## Test design

Test design of T-01:
    ## Test design
    | AC | Priority | Level | Scenarios |
    | --- | --- | --- | --- |
    | AC-1 | P1 | Unit (dev, `test/indicators/daysWithDelay.test.mjs`) and integration (QA, `test/integration/daysWithDelay/`, public exports only) | Each of the 5 options gives its WL with `strictEqual`. Iterate over `DAYS_WITH_DELAY_OPTIONS`: each maps without throwing, result in `{0, 2, 3, 4}`; the results contain neither `1` nor anything above `4`. |
    | AC-2 | P2 | Integration (QA); dev unit test as well | `deepStrictEqual` against the 5 strings; length 5; element 1 is not `"≤3 days"`. |
    | AC-3 | P3 | Unit (dev) | `isFrozen`, `push` throws `TypeError`, list unchanged, `">120 days"` throws `RangeError`. |
    | AC-4 | P2 | Integration (QA); dev unit test as well | The 6 trimmed inputs of the test data, including NBSP. |
    | AC-5 | P1 | Unit (dev) and integration (QA) | Every boundary and error path: case; inner whitespace; Unicode `"≤3 days"`; off-list; zero-width space; empty and whitespace-only; inherited names. Each checked with `assert.throws(fn, RangeError)` and not a `TypeError`. |
    | AC-6 | P1 | Unit (dev) and integration (QA) | All 11 non-string inputs, including the no-argument call, the `String` object and the `Symbol`. Each a `RangeError`, not a `TypeError` from building the message. |
    | AC-13 | P3 | Unit (dev) and review | Message of `">3 Days"` matches `/daysWithDelay/` (optional); `Symbol` input throws a `RangeError`. Review checks all 5 options are in the message. |
    | AC-14 | P3 | Unit (dev) and review | Three calls with `">60 days"` each return `3`. Review checks no imports and no top-level side effects. |
    
    **QA note: `qa_verify` must name a file.** On Node v22, `node --test <directory>/` fails with `MODULE_NOT_FOUND`. QA names its file `test/integration/daysWithDelay/daysWithDelay.integration.test.mjs` (the `.test.mjs` suffix lets `npm test` find it); `qa_verify` is `node --test test/integration/daysWithDelay/daysWithDelay.integration.test.mjs`.
    
QA verdicts (each must name every AC of its card — dl qa refuses otherwise):
    - T-01: AC-1 pass: 'AC-1: each option maps to its WL'; AC-2 pass: 'AC-2: DAYS_WITH_DELAY_OPTIONS deep-equals the 5 strings in order'; AC-3 pass: 'AC-3: DAYS_WITH_DELAY_OPTIONS is frozen'; AC-4 pass: 'AC-4' trim tests; AC-5 pass:
    - T-02: AC-7 pass: 'AC-7' mapping tests; AC-8 pass: 'AC-8' deepStrictEqual options; AC-9 pass: 'AC-9' frozen/push tests; AC-10 pass: 'AC-10: " 0 " is trimmed and maps to 0'; AC-11 pass: 'AC-11' RangeError tests; AC-12 pass: 'AC-
    - T-03: AC-1: suiteFinishes test asserts file absent; AC-2: dev verify diff; AC-3: dev verify indicators; AC-4: dev commit; AC-5: AC-5: test/zz-scale-loaded.test.mjs does not exist (the suite can finish); AC-6: same test fails f
decided NFR items: NFR-security
- ✅ the report gives every decided NFR item a result: NFR-security PASS
- ✅ the plan says how each is checked (## Non-functional requirements)

## B4 · the blind review

settings.review.blind: risk
- ✅ T-01 (top P1): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
- ✅ T-02 (top P1): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
T-03 (top -): no blind review needed
blind agent runs: 3

## 0.18 · inputs only when the work needs them

- ✅ DEL-inputs: no input asked for by default (a .env file is never needed unless the work reads it)
- ✅ …and the human was not asked for a .env file or a key
verify-all: 1 call(s), 1 run(s) of the suite — PASS;

## fault injected (hang, disclosed): what the team did with it

injection: injected (hang) at d20f517d138c7c14937ca2a775498296a07ac1c3 on job/JOB-20261021-1326-indicators-2-and-3-repayment-del, after: Merge T-01: REQ-03-02 Indicator 2 Days with delay: DAYS_WITH_DELAY_OPTIONS + daysWithDelayWl
    2026-10-21T13:42:54Z	gate	T-01 PASS
    2026-10-21T13:42:56Z	gate	T-02 PASS
    2026-10-21T13:43:34Z	qa	T-01 pass (qa_verify PASS) — AC-1 pass: 'AC-1: each option maps to its WL'; AC-2 pass: 'AC-2: DAYS_WITH_DELAY_OPTIONS deep-equals the 5 strings in order'; AC-3 pass: 'AC-3: DAYS_WITH_DELAY_OPTIONS is frozen'; AC-4 pass: 'AC-4' trim te
    2026-10-21T13:43:36Z	qa	T-02 pass (qa_verify PASS) — AC-7 pass: 'AC-7' mapping tests; AC-8 pass: 'AC-8' deepStrictEqual options; AC-9 pass: 'AC-9' frozen/push tests; AC-10 pass: 'AC-10: " 0 " is trimmed and maps to 0'; AC-11 pass: 'AC-11' RangeError tests; A
    2026-10-21T13:44:31Z	integrate	T-01 merged
    2026-10-21T13:45:35Z	merge-check	T-01 STALLED (repo suite)
    2026-10-21T13:45:38Z	integrate	T-02 merged
    2026-10-21T13:50:29Z	fix-open	F-1 (merge-check): test/zz-scale-loaded.test.mjs (commit d20f517 'test: the rating scale stays loaded', on the job branch outside any card, after the baseline) never ends: its async test awaits a promise that never resolves and ho
    2026-10-21T13:53:41Z	fix-add	F-1 → T-03
    2026-10-21T13:54:44Z	gate	T-03 PASS
    2026-10-21T13:54:47Z	qa	T-03 pass (qa_verify PASS) — AC-1: suiteFinishes test asserts file absent; AC-2: dev verify diff; AC-3: dev verify indicators; AC-4: dev commit; AC-5: AC-5: test/zz-scale-loaded.test.mjs does not exist (the suite can finish); AC-6: sa
    2026-10-21T13:55:24Z	integrate	T-03 merged
    2026-10-21T13:55:25Z	merge-check	T-03 PASS (repo suite)
    2026-10-21T13:55:58Z	verify-all	PASS
- ✅ Michael opened a fix (dl fix open)
fixes: [{"id":"F-1","from":"merge-check","state":"added","cards":["T-03"],"finding":"test/zz-scale-loaded.test.mjs (commit d20f517 'test: the rating scale stays loaded', on the job branch outside any card,"}]
- ✅ …and added it from the Lead's cards with the BA's specs (dl fix add)
- ✅ fix card(s) on the board: T-03
- ✅ T-03: the Lead's card (out/fix-…/cards.json) and the BA's spec (specs/T-03.md)
- ✅ the Lead was asked in MODE: FIX (transcripts: 5)
- ✅ the BA was asked for card specs (transcripts: 8)
- ✅ the hung suite was stopped by dl (STALLED), not waited for
- ✅ …and the hanging test is gone from main
suite_runs batch: no two cards of one component were ready to merge at the same moment — not exercised in this run

## result

cost: $6.18  ·  artifacts: <work>
**47 passed, 1 failed**
