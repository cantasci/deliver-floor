# Live E2E — scenario `complete`

Request: `examples/watchlist-poc/JOB.md`  ·  started 2026-10-21T13:16:45Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
fault injection (E2E_INJECT=regression): a post-merge hook in the sandbox, once — see injected.log
suite_runs end
- ✅ doctor: result: 30 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB.md

- ✅ Michael opened the job JOB-20261021-1317-rating-notch-calculator-and-coun

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the complete request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261021-1317-rating-notch-calculator-and-coun
    
    Answer each question in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## ARC-style
    
    What is the project's architecture style, and where does this change live? The draft (context.draft.md) leaves Style unfilled; the request only says other POC parts will import the modules.
    
    - Library, one component (as the draft). Fits the request's contract.
    - Modular monolith: one Node package whose areas (src/ratings, src/indicators, later screens) are modules
    - Monolith with no module boundaries
    
    _Why it matters:_ Confirmed once and becomes the project standard (architecture.md). Does not change this slice's functions.
    
    ## ARC-components
    
    Which components does the project have? The draft lists one library component 'repo' (path '.', suite 'npm test'). One component, or two (ratings: src/ratings + test/ratings; indicators: src/indicators + test/indicators, depending on ratings)?
    
    - One library component (draft): path '.', suite 'npm test'
    - Two library components: ratings and indicators, each with its own suite
    
    _Why it matters:_ Card scopes and per-component QA verify commands.
    
    ## X-trim
    
    C1 says input is 'trimmed' but not which whitespace. Everything String.prototype.trim() removes (incl. NBSP, newline), or ASCII space/tab only? Inner whitespace ('BBB +') is rejected either way.
    
    - String.prototype.trim(): ' bbb+\t', 'BBB+\n', '\u00A0BBB+' are accepted
    - ASCII space and tab only: newline and NBSP throw RangeError
    
    _Why it matters:_ Whether such inputs return a result or throw RangeError in a contract other POC parts import; pasted public-source values (NBSP, newline) are the realistic case.
- ✅ answered ARC-style — What is the project's architecture style, and where does this change live? The draft (cont
- ✅ answered ARC-components — Which components does the project have? The draft lists one library component 'repo' (path
- ✅ answered X-trim — C1 says input is 'trimmed' but not which whitespace. Everything String.prototype.trim() re
wall time: 37 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend, qa, reviewer, blind
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 2 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 17 items — 14 decided, 3 n/a · architecture: library: repo [node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 3 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Rating scale, notchChange and notchCalculator (src/ratings/notch.mjs) | repo | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 Indicator 12 country rating change WL (src/indicators/countryRating.mjs) | repo | backend#1 | 2 | FAIL | fail (qa_verify PASS) | - | archived |
| T-03 Restore the C1 order of RATING_SCALE (BBB- before BB+) in src/ratings/notch.mjs and pin it with a literal regression test | repo | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-04 Re-deliver Indicator 12: countryRatingChangeWl in src/indicators/countryRating.mjs (from T-02 branch work) | repo | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
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
- ✅ hidden oracle passes (5 checks, watchlist.oracle.test.mjs)
- ❌ the job took 36.8 min (> 15) — where it went: intake 0.4, readiness 1, readiness 3.8, awaiting_clarification 0.7, planning 4.7, executing 24.3, integrating 0.8, closing 1; busiest: business-analyst 7.3 min (timeline.txt)

## B3 · risk-based test design and the NFR gate

- ✅ every AC of the plan has a priority: AC-1 P0, AC-2 P0, AC-3 P0, AC-4 P1, AC-5 P0, AC-6 P1, AC-7 P1, AC-8 P0, AC-9 P3
- ✅ every card spec has a ## Test design

Test design of T-01:
    ## Test design
    | AC | Priority | Level | Scenarios |
    | --- | --- | --- | --- |
    | AC-1 | P0 | unit (dev) + integration (QA) | exact contents and order; length 19; frozen; push and index assignment throw TypeError and leave the scale unchanged |
    | AC-2 | P0 | unit (dev) + integration (QA) | positive (3, 1 at both ends), negative (-3, -18), zero with `Object.is(…, 0)`, maximum ±18, integer type |
    | AC-3 | P0 | unit (dev) + integration (QA) | each downgrade boundary 1/2/3 notches gives wl 0/1/2; 18 notches gives wl 2; C2's corrected BBB+ → BB+; full 19×19 sweep checks wl against the rule |
    | AC-4 | P1 | integration (QA), plus dev unit tests | upgrade -1, -3, -18 give wl 0; unchanged gives `{0,"unchanged",0}`; exact key set; notches === notchChange for every pair |
    | AC-7 | P1 | integration (QA), plus dev unit tests | lower case, mixed case, leading/trailing space, tab, newline, NBSP, in both positions, for both functions |
    | AC-8 | P0 | unit (dev) + integration (QA) | every invalid string and every non-string of criteria 13–14 in both positions for both functions; missing arguments; `assert.throws(fn, RangeError)`, with explicit cases for Symbol, Object.create(null) and 10n (never TypeError) |
    
    QA file: `test/integration/ratings/notch.contract.test.mjs`. It imports only the public exports. It does not import dev test helpers.
    
QA verdicts (each must name every AC of its card — dl qa refuses otherwise):
    - T-01: AC-1: AC-1 RATING_SCALE deep-equals the 19 ratings best first, length 19, frozen; AC-2: AC-2 full 19x19 sweep returns index(current) - index(previous); AC-3: AC-3 BBB+ -> BB+ is a 3-notch downgrade with WL 2; AC-4: AC-4 
    - T-03: AC-1: AC-1 RATING_SCALE deep-equals the 19 literal ratings, best first; AC-2: AC-2 notchChange(L[i], L[j]) === j - i for all 19x19 pairs; AC-3: AC-3 BBB+ -> BB+ is 3 notches, wl 2
    - T-04: AC-5: A->A- =1, A->BBB+ =2, A->BBB =2, AAA->CCC- =2 and 19x19 sweep (contract tests); AC-6: A-->A, CCC-->AAA, BB->BB =0 (contract tests); AC-7: ' a ','a-' =1, ' bbb\n','BB+' =2, 'aaa','ccc-' =2, NBSP/tab case (contract t
decided NFR items: NFR-security
- ✅ the report gives every decided NFR item a result: NFR-security PASS
- ✅ the plan says how each is checked (## Non-functional requirements)

## B4 · the blind review

settings.review.blind: risk
- ✅ T-01 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
- ✅ T-03 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
- ✅ T-04 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
blind agent runs: 3

## 0.18 · inputs only when the work needs them

- ✅ DEL-inputs: no input asked for by default (a .env file is never needed unless the work reads it)
- ✅ …and the human was not asked for a .env file or a key
verify-all: 2 call(s), 1 run(s) of the suite — PASS;PASS (kept: ran on 88d372b9eb9c, nothing changed since);

## fault injected (regression, disclosed): what the team did with it

injection: injected (regression) at 84e2366f3de0a5c56ef4ad7fa09aa51f4c6c2cae on job/JOB-20261021-1317-rating-notch-calculator-and-coun, after: Merge T-01: Rating scale, notchChange and notchCalculator (src/ratings/notch.mjs)
    2026-10-21T13:31:07Z	gate	T-01 PASS
    2026-10-21T13:31:22Z	qa	T-01 pass (qa_verify PASS) — AC-1: AC-1 RATING_SCALE deep-equals the 19 ratings best first, length 19, frozen; AC-2: AC-2 full 19x19 sweep returns index(current) - index(previous); AC-3: AC-3 BBB+ -> BB+ is a 3-notch downgrade with WL
    2026-10-21T13:32:16Z	integrate	T-01 merged
    2026-10-21T13:36:01Z	fix-open	F-1 (review): src/ratings/notch.mjs RATING_SCALE has BBB- and BB+ swapped (order ...BBB+,BBB,BB+,BBB-,BB...) since commit 84e2366 'refactor: tidy the rating scale' (a merge commit on the job branch, not made through dl). Violates 
    2026-10-21T13:38:53Z	fix-add	F-1 → T-03
    2026-10-21T13:39:00Z	gate	T-02 PASS
    2026-10-21T13:40:35Z	gate	T-03 PASS
    2026-10-21T13:40:53Z	qa	T-03 pass (qa_verify PASS) — AC-1: AC-1 RATING_SCALE deep-equals the 19 literal ratings, best first; AC-2: AC-2 notchChange(L[i], L[j]) === j - i for all 19x19 pairs; AC-3: AC-3 BBB+ -> BB+ is 3 notches, wl 2
    2026-10-21T13:41:36Z	integrate	T-03 merged
    2026-10-21T13:42:10Z	qa	T-02 fail (qa_verify PASS) — AC-7 fail: dev unit test and QA test expect (' bbb\n','BB+')=1, true only on the swapped scale of 84e2366; C1 order (restored by T-03) gives 2; spec corrected
    2026-10-21T13:44:26Z	gate	T-02 FAIL
    2026-10-21T13:46:06Z	fix-open	F-2 (blocked): T-02 (Indicator 12, src/indicators/countryRating.mjs) is blocked with attempts used up (2/2) though its work is complete: dev code 9dedde5 (unit 52/52) and QA's corrected contract test 08a655d (QA_VERIFY 75/75) sit 
    2026-10-21T13:48:58Z	fix-add	F-2 → T-04
    2026-10-21T13:51:37Z	gate	T-04 PASS
    2026-10-21T13:51:46Z	qa	T-04 pass (qa_verify PASS) — AC-5: A->A- =1, A->BBB+ =2, A->BBB =2, AAA->CCC- =2 and 19x19 sweep (contract tests); AC-6: A-->A, CCC-->AAA, BB->BB =0 (contract tests); AC-7: ' a ','a-' =1, ' bbb\n','BB+' =2, 'aaa','ccc-' =2, NBSP/tab c
    2026-10-21T13:52:24Z	integrate	T-04 merged
    2026-10-21T13:52:32Z	verify-all	PASS
    2026-10-21T13:53:15Z	verify-all	PASS (kept: ran on 88d372b9eb9c, nothing changed since)
- ✅ Michael opened a fix (dl fix open)
fixes: [{"id":"F-1","from":"review","state":"added","cards":["T-03"],"finding":"src/ratings/notch.mjs RATING_SCALE has BBB- and BB+ swapped (order ...BBB+,BBB,BB+,BBB-,BB...) since commit 84e2366 'ref"},{"id":"F-2","from":"blocked","state":"added","cards":["T-04"],"finding":"T-02 (Indicator 12, src/indicators/countryRating.mjs) is blocked with attempts used up (2/2) though its work is complete"}]
- ✅ …and added it from the Lead's cards with the BA's specs (dl fix add)
- ✅ fix card(s) on the board: T-03 T-04
- ✅ T-03: the Lead's card (out/fix-…/cards.json) and the BA's spec (specs/T-03.md)
- ✅ T-04: the Lead's card (out/fix-…/cards.json) and the BA's spec (specs/T-04.md)
- ✅ the Lead was asked in MODE: FIX (transcripts: 10)
- ✅ the BA was asked for card specs (transcripts: 8)
- ✅ suite_runs end: no suite after a merge
- ❌ verify-all named the card the failures point to (LIKELY T-…)

## result

cost: $7.51  ·  artifacts: <work>
**45 passed, 2 failed**
