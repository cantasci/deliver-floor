# Live E2E — scenario `shaped`

Request: `examples/watchlist-poc/JOB-shaped.md`  ·  started 2026-10-13T19:09:17Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

✔ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
upstream.engine = bmad; docs/POC_Requirements_v0.2_EN.md in the repo
- ✅ doctor: result: 27 ok, 6 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-shaped.md

- ✅ Michael opened the job JOB-20261013-2110-rating-notch-calculator-and-coun

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-2110-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-scope
    
    REQ-03-12 also says 'Pre-filled from public source' and 'auto-filled value editable', and REQ-06-02 says the analyst 'selects' ratings and the WL is 'displayed'. The contract only lists pure functions. Are the public-source pre-fill, the editable field and a display part of this delivery?
    
    - (a, BA recommendation) Only the contract: RATING_SCALE, notchChange, notchCalculator, countryRatingChangeWl, pure, with tests; fetching, override flag, display are later jobs; Ind. 13 not implemented
    - (b) (a) plus a fetcher for sovereign ratings (I/O)
    - (c) (a) plus a user-facing calculator (CLI or web page)
    
    _Why it matters:_ (a) 1-2 cards, no I/O; (b)/(c) add integration or UI.
    
    ## PRD-acceptance
    
    Confirm worked examples QA will use verbatim, e.g. countryRatingChangeWl: AAA→AA+ = 1; BBB+→BBB- = 2; BB→BB = 0; BB→BBB = 0.
    
    - (a) Confirm the BA's table once X-example-notches, X-calc-wl-rule, X-upgrade-wl are answered
    - (b) Business supplies examples from the Excel dropdown sheet
    
    _Why it matters:_ Without examples P1 ACs lack concrete values.
    
    ## PRD-conflicts
    
    See X-example-notches, X-calc-wl-rule, X-upgrade-wl.
    
    - Resolve each X- item
    
    _Why it matters:_ Wrong WL on the core output (P1).
    
    ## CON-interface
    
    (1) Is notchCalculator's notches signed or magnitude? (2) range of wl? (3) RATING_SCALE type?
    
    - (a, BA recommendation) notches = magnitude (0 when unchanged), direction carries the sign; wl in 0|1|2; RATING_SCALE a frozen array of strings
    - (b) notches signed, identical to notchChange
    
    _Why it matters:_ Other POC parts import these exactly.
    
    ## CON-errors
    
    What must the functions do with an unknown/invalid rating?
    
    - (a, BA recommendation) Throw TypeError for non-string, RangeError for a string not in RATING_SCALE, naming the value
    - (b) Return null so the caller falls back to manual input
    - (c) Treat NR/WD as no change, throw for garbage
    
    _Why it matters:_ Silent wrong WL vs visible failure.
    
    ## ARC-style
    
    Architecture style of the repo?
    
    - as in the draft: one library component, plain Node ESM under src/<area>/, suite npm test
    - modular monolith with later UI/fetcher components
    
    _Why it matters:_ Where later code goes.
    
    ## ARC-components
    
    Confirm the component list.
    
    - as in the draft: one component repo, library, node, path ., npm test
    - plus UI or fetcher component if chosen elsewhere
    
    _Why it matters:_ Card split.
    
    ## ARC-ui
    
    Is any user interface delivered in this job?
    
    - (a, BA recommendation) None
    - (b) A small CLI
    - (c) A web page
    
    _Why it matters:_ (b)/(c) add a component.
    
    ## ARC-data
    
    Is anything persisted in this delivery?
    
    - (a, BA recommendation) No store — pure functions
    - (b) Persist ratings
    
    _Why it matters:_ (b) adds a data component.
    
    ## ARC-integration
    
    Is any external source called in this delivery?
    
    - (a, BA recommendation) None — fetch is REQ-02-02, a separate job
    - (b) Scrape here
    
    _Why it matters:_ (b) adds I/O and an open policy question.
    
    ## X-example-notches
    
    Which part of the example is right?
    
    - (a) Standard counting: 3-notch downgrade; example count is a typo, WL follows X-calc-wl-rule
    - (b) Count and WL right, ratings a typo (e.g. BBB+ → BBB- = 2 → WL=1)
    - (c) Non-standard notch definition — BA advises against
    
    _Why it matters:_ The only REQ-06-02 example cannot pass as written.
    
    ## X-calc-wl-rule
    
    Which threshold rule gives notchCalculator's wl?
    
    - (a) Ind. 13 rule: 0-1 down → 0; 2 → 1; 3+ → 2
    - (b) Ind. 12 rule: 1 down → 1; 2+ → 2
    - (c) Add an indicator argument (changes contract)
    - (d) Return WL per indicator (changes contract)
    
    _Why it matters:_ Core output (P1).
    
    ## X-upgrade-wl
    
    What WL do unchanged and upgrade give?
    
    - (a, BA recommendation) WL=0 for unchanged and any upgrade
    - (b) Thresholds on absolute count
    
    _Why it matters:_ (b) would watchlist upgraded clients.
    
    ## X-rating-scale
    
    What is in RATING_SCALE?
    
    - (a, BA recommendation) the 19 grades AAA…CCC-; anything else invalid
    - (b) (a) plus CC, C, D
    - (c) plus Moody's codes
    - (d) NR/WD invalid or no change
    
    _Why it matters:_ Valid inputs and bottom-of-scale counts.
    
    ## X-input-format
    
    Are 'bbb+', ' BBB+ ', 'BBB−' accepted?
    
    - (a) Exact match only
    - (b, BA recommendation) Trim and upper-case; ASCII +/- only
    - (c) (b) plus map Unicode minus
    
    _Why it matters:_ QA edge tests.
- ✅ answered PRD-scope — REQ-03-12 also says 'Pre-filled from public source' and 'auto-filled value editable', and 
    no prepared answer fits PRD-acceptance — took the BA's recommended option: (a) Confirm the BA's table once X-example-notches, X-calc-wl-rule, X-upgrade-wl are answered
- ✅ answered PRD-acceptance — Confirm worked examples QA will use verbatim, e.g. countryRatingChangeWl: AAA→AA+ = 1; BBB
    no prepared answer fits PRD-conflicts — took the BA's recommended option: Resolve each X- item
- ✅ answered PRD-conflicts — See X-example-notches, X-calc-wl-rule, X-upgrade-wl.
- ✅ answered CON-interface — (1) Is notchCalculator's notches signed or magnitude? (2) range of wl? (3) RATING_SCALE ty
- ✅ answered CON-errors — What must the functions do with an unknown/invalid rating?
- ✅ answered ARC-style — Architecture style of the repo?
- ✅ answered ARC-components — Confirm the component list.
    no prepared answer fits ARC-ui — took the BA's recommended option: (a, BA recommendation) None
- ✅ answered ARC-ui — Is any user interface delivered in this job?
    no prepared answer fits ARC-data — took the BA's recommended option: (a, BA recommendation) No store — pure functions
- ✅ answered ARC-data — Is anything persisted in this delivery?
    no prepared answer fits ARC-integration — took the BA's recommended option: (a, BA recommendation) None — fetch is REQ-02-02, a separate job
- ✅ answered ARC-integration — Is any external source called in this delivery?
    no prepared answer fits X-example-notches — took the BA's recommended option: (a) Standard counting: 3-notch downgrade; example count is a typo, WL follows X-calc-wl-rule
- ✅ answered X-example-notches — Which part of the example is right?
    no prepared answer fits X-calc-wl-rule — took the BA's recommended option: (a) Ind. 13 rule: 0-1 down → 0; 2 → 1; 3+ → 2
- ✅ answered X-calc-wl-rule — Which threshold rule gives notchCalculator's wl?
    no prepared answer fits X-upgrade-wl — took the BA's recommended option: (a, BA recommendation) WL=0 for unchanged and any upgrade
- ✅ answered X-upgrade-wl — What WL do unchanged and upgrade give?
    no prepared answer fits X-rating-scale — took the BA's recommended option: (a, BA recommendation) the 19 grades AAA…CCC-; anything else invalid
- ✅ answered X-rating-scale — What is in RATING_SCALE?
    no prepared answer fits X-input-format — took the BA's recommended option: (a) Exact match only
- ✅ answered X-input-format — Are 'bbb+', ' BBB+ ', 'BBB−' accepted?
wall time: 261 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, qa, backend-lead, backend, reviewer, blind
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 2 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 35 items — 28 decided, 7 n/a · architecture: library: watchlist-poc [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Rating scale, notchChange and notchCalculator (src/ratings/notch.mjs) | watchlist-poc | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 Indicator 12 country rating change WL (src/indicators/countryRating.mjs) | watchlist-poc | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
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
- ❌ hidden oracle FAILED (oracle.log)
✖ C1: input is trimmed and case-insensitive; unknown ratings throw RangeError (0.059208ms)
✖ failing tests:
✖ C1: input is trimmed and case-insensitive; unknown ratings throw RangeError (0.059208ms)
- ❌ the job took 261.6 min (> 45) — where it went: intake 0.3, readiness 6.1, awaiting_clarification 0.8, planning 8.2, executing 5.5, integrating 0.6, closing 240.2; busiest: business-analyst 10.6 min (timeline.txt)

## B3 · risk-based test design and the NFR gate

- ✅ every AC of the plan has a priority: AC-1 P0, AC-2 P0, AC-3 P0, AC-4 P0, AC-5 P1, AC-6 P1, AC-7 P1, AC-8 P1, AC-9 P0, AC-10 P0, AC-11 P0, AC-12 P1
- ✅ every card spec has a ## Test design

Test design of T-01:
    ## Test design
    Levels:
    - **unit:** the dev's `test/ratings/notch.test.mjs`, run by `node --test test/ratings/notch.test.mjs`.
    - **integration:** QA's `test/ratings/notch.integration.test.mjs`, run by `node --test test/ratings/notch.integration.test.mjs`. It imports the module through its public path the way T-02 does. It is table-driven from the plan's example table, cross-checks the functions against each other, and must also pass under the full `node --test`.
    
    | AC | priority | level | scenarios |
    | --- | --- | --- | --- |
    | AC-1 | P0 | unit | `deepStrictEqual` against the 19-item array; `Set` size 19; `[0]` "AAA", `[18]` "CCC-"; every element `typeof "string"`; no element contains U+2212 |
    | AC-1 | P0 | integration | the imported `RATING_SCALE` drives every 361-pair loop below; the `indexOf` of each table code matches its position (AAA=0, BBB+=7, BBB=8, BBB-=9, BB+=10, CCC-=18) |
    | AC-2 | P0 | unit | the 5 downgrade rows; end-of-scale pairs ("AAA","AA+") → 1 and ("CCC","CCC-") → 1; letter-group pairs ("A-","BBB+"), ("BBB-","BB+"), ("B-","CCC+") → 1; ("AAA","CCC-") → 18 is the maximum; `Number.isInteger` |
    | AC-2 | P0 | integration | the table's downgrade rows; a 361-pair loop asserting `notchChange(p,c) === RATING_SCALE.indexOf(c) - RATING_SCALE.indexOf(p)` and `Number.isInteger`; the counts 18 / 17 / 136 for =1 / =2 / >=3 |
    | AC-3 | P0 | unit | the 5 rows; `Object.is(notchChange("A","A"), 0)` (not `-0`); ("AA+","AAA") → -1; ("CCC-","AAA") → -18 is the minimum |
    | AC-3 | P0 | integration | the table's unchanged and upgrade rows; in the 361-pair loop, `notchChange(p,c) === -notchChange(c,p)` for p≠c, and `Object.is(…, 0)` when p===c (19 pairs); 171 negative results |
    | AC-4 | P0 | unit | each of the 15 INVALID values as `previous` and as `current` (30 asserts, `assert.throws(fn, RangeError)`); `notchChange("BBB")`; `notchChange()`; `notchChange(null, null)`; the extra list (String object, `["BBB"]`, "toString", "constructor", "__proto__", "length", 0, NaN, true, 10n, `Symbol("BBB")`, `Object.create(null)`) in both positions, each still a `RangeError`, never a `TypeError` |
    | AC-4 | P0 | integration | the INVALID list in both positions against a valid partner from each part of the scale ("AAA", "BBB", "CCC-"); the missing-argument calls; confirm nothing is returned (the throw happens before any value) |
    | AC-5 | P1 | unit | the 4 rows with `deepStrictEqual`; the wl thresholds 1→0, 2→1, 3→2 with ("BBB","BBB-"), ("BBB","BB+") / ("AA","A+"), ("BBB+","BB+") / ("BBB","BB") |
    | AC-5 | P1 | integration | the table's downgrade rows with `deepStrictEqual`, including ("BBB+","BB+") → `{3,"downgrade",2}` (X-example-notches) |
    | AC-6 | P1 | unit | the 4 rows with `deepStrictEqual`; ("CCC-","CCC-") unchanged; `Object.is(r.notches, 0)` for unchanged |
    | AC-6 | P1 | integration | the table's unchanged and upgrade rows with `deepStrictEqual` |
    | AC-7 | P1 | unit | a 361-pair loop: exact keys, `notches === notchChange`, the direction rule, the wl rule; independence (changing a result does not affect the next call) |
    | AC-7 | P1 | integration | a 361-pair loop checking each result against a separate implementation of the rule written in the test; counts wl 0/1/2 = 208/17/136 and direction downgrade/upgrade/unchanged = 171/171/19 |
    | AC-8 | P1 | unit | the 15 INVALID values in both positions; `notchCalculator()` and `notchCalculator("BBB")`; `Symbol("BBB")` and `Object.create(null)` give `RangeError` |
    | AC-8 | P1 | integration | the INVALID list in both positions against "AAA", "BBB" and "CCC-" |
    
    NFR checks for review (not tests):
    - **NFR-security:** no `String()` / `trim` / `toUpperCase` / default fallback on the input.
    - **Purity (CLAUDE.md):** no `node:fs`, `fetch`, `console`, module-level mutable state or imports.
    - **NFR-compliance:** blind review of the wl rule against REQ-03-13, X-calc-wl-rule and X-upgrade-wl.
    
QA verdicts (each must name every AC of its card — dl qa refuses otherwise):
    - T-01: AC-1: RATING_SCALE deep-strict-equals the 19 grades; AC-2: 361-pair loop + downgrade rows; AC-3: unchanged is +0 for all 19 grades; AC-4: notchChange(v, partner) throws RangeError; AC-5: BBB+ -> BB+ is 3 notches WL 2; AC
    - T-02: AC-9: example-row tests in countryRating.integration.test.mjs (AC-9 examples, threshold test); AC-10: 361-pair loop with counts 190/18/153; AC-11: INVALID values in both positions + no-arg call throw RangeError; AC-12: e
decided NFR items: NFR-security, NFR-compliance
- ✅ the report gives every decided NFR item a result: NFR-security PASS, NFR-compliance PASS
- ✅ the plan says how each is checked (## Non-functional requirements)

## B4 · the blind review

settings.review.blind: risk
- ✅ T-01 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
- ✅ T-02 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
blind agent runs: 2

## result

cost: $6.21  ·  artifacts: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/live-control/shaped
**45 passed, 2 failed**
