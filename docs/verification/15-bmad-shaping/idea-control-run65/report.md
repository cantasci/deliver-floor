# Live E2E — scenario `idea`

Request: `examples/watchlist-poc/JOB-idea.md`  ·  started 2026-10-14T03:05:48Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

✔ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
upstream.engine = bmad; docs/POC_Requirements_v0.2_EN.md in the repo
- ✅ doctor: result: 27 ok, 6 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-idea.md

- ✅ Michael opened the job JOB-20261014-0507-rating-notch-helper

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the idea request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261014-0507-rating-notch-helper
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-scope
    
    What does 'the notch calculator and the country rating change indicator' include? (1) Does it include the Ind. 12 data fetch (REQ-02-02, a scrape of Wikipedia or countryeconomy)? (2) The request also says 'a client's ... rating'. Client ratings are Ind. 11 (internal) and Ind. 13 (external), and those use a different WL mapping. Are their WL mappings in scope? (3) Is Ind. 10 (current internal rating → WL) in scope?
    
    - A: notch calculator plus the Ind. 12 notch change and WL only. Both ratings are passed in by the caller and nothing is fetched (recommended; fits 'not about screens' and CLAUDE.md pure functions)
    - B: A plus the Ind. 11 and Ind. 13 WL mappings (REQ-03-11, REQ-03-13)
    - C: A or B plus the Ind. 12 fetch from a public source (REQ-02-02, 3A)
    - D: any of the above plus Ind. 10 (REQ-03-10)
    
    _Why it matters:_ B adds two WL rules and their tests. C adds an integration component, network I/O and Q2. D adds a rule that has a gap (see PRD-conflicts C4). Screens are out in every option.
    
    ## PRD-acceptance
    
    The POC gives concrete values only for Ind. 12 downgrades, plus one REQ-06-02 example that contradicts them. There are no examples for no change, upgrades, Moody's symbols, the bottom of the scale or invalid input. Can business supply the Excel dropdown sheet (A4) or confirm a list of examples?
    
    - Business supplies the Excel dropdown sheet, which A4 says the scoring mirrors
    - The BA derives examples from the standard scale and REQ-03-12, and business confirms the list
    
    _Why it matters:_ Without confirmed examples the ACs rest on our interpretation, and A4 forbids that.
    
    ## PRD-conflicts
    
    C1: The REQ-06-02 example counts BBB+ → BB+ as 2 notches. On the S&P/Fitch scale (BBB+, BBB, BBB-, BB+) it is 3. C2: Under Ind. 12 (REQ-03-12), 2 notches gives WL=2 and so does 3. Only the Ind. 11/13 mapping (REQ-03-11/13: 2 → WL=1, 3+ → WL=2) gives the example's WL=1, and then only if the move is 2 notches. A 3-notch move gives WL=2 under every mapping, so the example fits no rule in the document. C3: Ind. 12 starts WL=1 at 1 notch; Ind. 11/13 start it at 2 notches. REQ-06-02 does not say which mapping the calculator's 'resultant WL' uses. C4 (only if Ind. 10 is in scope): REQ-03-10 maps B → WL=1, CCC+ and below → WL=2, B+ and above → WL=0. B- gets no WL.
    
    - (a) Count on the standard scale and correct the example to 'BBB+ → BB+ = 3 notches → WL=2' (BA recommendation)
    - (b) Keep the example's WL=1 and change the pair to BBB+ → BBB- (2 notches → WL=1 under the Ind. 11/13 mapping)
    - (c) Let the Excel dropdown sheet (A4) decide
    
    _Why it matters:_ Changes the expected output of the only worked example and the WL thresholds the helper returns. Under C4, B- has no defined WL.
    
    ## CON-interface
    
    Several parts of the public contract are not stated. (1) The input format of a rating: symbol strings such as 'BBB+' or 'Baa1', case sensitivity, whitespace. (2) Whether the caller passes the scale or agency. (3) The sign of the notch change. (4) The output shape (for example {notches, direction, wl}). (5) Which indicator's WL mapping the result uses (see X-calc-mapping). Function and module names are a PM matter.
    
    - Notch change as a signed integer, downgrade = positive (matches 'higher is worse' for WL), plus wl 0..4
    - Notch change as a signed integer, downgrade = negative (the market convention), plus wl
    - An unsigned count plus a direction field ('downgrade'|'upgrade'|'none'), plus wl
    
    _Why it matters:_ Every consumer in the POC depends on the sign and the output shape. Changing them later breaks callers.
    
    ## CON-errors
    
    What should happen for an unknown symbol ('BBB*', '', null, undefined)? For ratings from different scales (Fitch 'BBB+' compared with Moody's 'Baa1')? For NR or WD (withdrawn)? For default symbols (D, SD, RD)? For an internal rating outside AAA..CCC-? REQ-02-08 covers only the form's fallback when a fetch fails.
    
    - Throw a RangeError or TypeError whose message names the bad input; the caller falls back to manual input as in REQ-02-08 (recommended)
    - Return null or an {error} result instead of throwing
    - Cross-scale pairs: reject, or map through the Moody's ⇔ S&P/Fitch equivalence
    
    _Why it matters:_ Defines the error contract that every consumer relies on, and whether pairs that mix agencies are valid.
    
    ## ARC-style
    
    Which architecture style, and where does the helper live?
    
    - As in the draft (.work/JOB-20261014-0507-rating-notch-helper/context.draft.md): a single library component in this repo, run with npm test
    - A module inside a future POC app or service
    
    _Why it matters:_ Decides the component list, the paths and the verify command for every card.
    
    ## ARC-components
    
    Confirm the component list. The draft lists one component, 'repo' (library, javascript, path '.', npm test). CLAUDE.md names the areas src/ratings and src/indicators.
    
    - As in the draft: one library. Rating scales and notch counting go in src/ratings/, the Ind. 12 WL (and Ind. 11/13 if PRD-scope is B) in src/indicators/, tests in test/ratings/ and test/indicators/
    - Everything in src/ratings/ only
    - A further fetch component, if PRD-scope C is chosen (it cannot live in src/ratings or src/indicators, because CLAUDE.md forbids I/O there)
    
    _Why it matters:_ Card paths, scopes and ownership.
    
    ## ARC-layer
    
    Which layer owns the logic? Is there an API?
    
    - An in-process ESM library that other POC modules import, with no HTTP API (recommended)
    - An HTTP or other API in front of it
    
    _Why it matters:_ An API adds a server, a contract and NFRs. It is settled together with ARC-style.
    
    ## ARC-deps
    
    The request is silent. May the delivery add dependencies?
    
    - None, per the repo rule in CLAUDE.md 'No npm dependencies; do not add any.' (recommended; the helper needs none)
    - Allow a library such as a rating-scale package
    
    _Why it matters:_ Only matters if someone wants a library. The repo rule forbids it.
    
    ## ARC-data
    
    The request is silent. Is any rating history stored?
    
    - No store. Both ratings are passed in by the caller (recommended; the POC puts history out of scope)
    - Store past ratings
    
    _Why it matters:_ A store adds a schema, migrations and a new component.
    
    ## ARC-integration
    
    Is the Ind. 12 country-rating fetch (a scrape of Wikipedia or countryeconomy.com) part of this delivery? If yes: which agency for 'Other' (X-agency-other), what timeout and failure behaviour?
    
    - None; ratings are inputs (recommended, PRD-scope A or B)
    - A scraper component: no API key, falls back to manual input on failure (REQ-02-08), finishes within 30 s (REQ-02-01)
    
    _Why it matters:_ Adds network I/O, a new component, flaky-source handling and Q2.
    
    ## DEL-deploy
    
    How is the helper delivered and consumed (deployment shape, rollback)?
    
    - Nothing is deployed: other POC parts import it from this repo (the repo convention; POC C1 says no production without a business review) (recommended)
    - Published as a package or service
    
    _Why it matters:_ Delivery shape only.
    
    ## X-scales
    
    Which rating scales, and in what notch order? The POC names an internal scale 'AAA → CCC-' (REQ-03-10), an agency selector S&P / Moody's / Fitch (REQ-03-13), and Fitch for the Germany and Turkey country ratings. It never lists the scales.
    
    - S&P/Fitch AAA, AA+ … CCC-, CC, C, D (22 steps); Moody's Aaa, Aa1 … Caa3, Ca, C (21 steps); internal AAA … CCC- (19 steps). Notches are counted within one scale (recommended)
    - S&P/Fitch symbols only; Moody's mapped by the standard equivalence
    - Whatever the Excel sheet defines
    
    _Why it matters:_ Decides every notch count, especially at the bottom of the scale (CCC- → CC/C/D, Ca/C) and the REQ-06-02 example.
    
    ## X-modifiers
    
    Do outlook (positive/stable/negative) or watch status (CreditWatch / Rating Watch / review) count toward the notch change or the WL? How are NR, WD, SD and RD handled?
    
    - Ignore them; only the symbol counts, and NR/WD are invalid input (recommended)
    - A negative outlook or watch adds to the WL
    - Accept the modifiers in the input and strip them
    
    _Why it matters:_ Changes the WL for a stable symbol with a negative outlook, and the input format.
    
    ## X-direction
    
    What WL do no change and upgrades get? REQ-03-12 says '1 notch → WL=1' without saying downgrade. REQ-03-11 puts 'same/upgrade' in one option.
    
    - No change and upgrades of any size give WL=0; only downgrades count (recommended, consistent with REQ-03-11)
    - Upgrades count by absolute notches
    
    _Why it matters:_ The WL for every upgrade.
    
    ## X-calc-mapping
    
    Which WL mapping does the notch calculator's 'resultant WL' (REQ-06-02) use?
    
    - The caller names the indicator (11, 12 or 13) and gets that indicator's mapping
    - Always Ind. 12 (1 → WL=1, 2+ → WL=2)
    - Always the Ind. 11/13 mapping (2 → WL=1, 3+ → WL=2), which fits the example's WL=1
    
    _Why it matters:_ The same move gives a different WL: a 1-notch downgrade is WL=1 under Ind. 12 and WL=0 under Ind. 11/13.
    
    ## X-agency-other
    
    For the 'Other' segment, which agency is the reference country rating (POC Q2)? This only matters if the helper picks or fetches the rating (PRD-scope C). Otherwise the caller supplies it.
    
    - Fitch
    - S&P
    - The most conservative of the three
    - Not this delivery's concern; the caller passes the ratings (recommended with PRD-scope A or B)
    
    _Why it matters:_ Fetch logic and which rating is fed in.
- ✅ answered PRD-scope — What does 'the notch calculator and the country rating change indicator' include? (1) Does
- ✅ answered PRD-acceptance — The POC gives concrete values only for Ind. 12 downgrades, plus one REQ-06-02 example that
    no prepared answer fits PRD-conflicts — took the BA's recommended option: (a) Count on the standard scale and correct the example to 'BBB+ → BB+ = 3 notches → WL=2' (BA recom
- ✅ answered PRD-conflicts — C1: The REQ-06-02 example counts BBB+ → BB+ as 2 notches. On the S&P/Fitch scale (BBB+, BB
- ✅ answered CON-interface — Several parts of the public contract are not stated. (1) The input format of a rating: sym
- ✅ answered CON-errors — What should happen for an unknown symbol ('BBB*', '', null, undefined)? For ratings from d
- ✅ answered ARC-style — Which architecture style, and where does the helper live?
- ✅ answered ARC-components — Confirm the component list. The draft lists one component, 'repo' (library, javascript, pa
    no prepared answer fits ARC-layer — took the BA's recommended option: An in-process ESM library that other POC modules import, with no HTTP API (recommended)
- ✅ answered ARC-layer — Which layer owns the logic? Is there an API?
    no prepared answer fits ARC-deps — took the BA's recommended option: None, per the repo rule in CLAUDE.md 'No npm dependencies; do not add any.' (recommended; the helper
- ✅ answered ARC-deps — The request is silent. May the delivery add dependencies?
    no prepared answer fits ARC-data — took the BA's recommended option: No store. Both ratings are passed in by the caller (recommended; the POC puts history out of scope)
- ✅ answered ARC-data — The request is silent. Is any rating history stored?
    no prepared answer fits ARC-integration — took the BA's recommended option: None; ratings are inputs (recommended, PRD-scope A or B)
- ✅ answered ARC-integration — Is the Ind. 12 country-rating fetch (a scrape of Wikipedia or countryeconomy.com) part of 
    no prepared answer fits DEL-deploy — took the BA's recommended option: Nothing is deployed: other POC parts import it from this repo (the repo convention; POC C1 says no p
- ✅ answered DEL-deploy — How is the helper delivered and consumed (deployment shape, rollback)?
- ✅ answered X-scales — Which rating scales, and in what notch order? The POC names an internal scale 'AAA → CCC-'
    no prepared answer fits X-modifiers — took the BA's recommended option: Ignore them; only the symbol counts, and NR/WD are invalid input (recommended)
- ✅ answered X-modifiers — Do outlook (positive/stable/negative) or watch status (CreditWatch / Rating Watch / review
    no prepared answer fits X-direction — took the BA's recommended option: No change and upgrades of any size give WL=0; only downgrades count (recommended, consistent with RE
- ✅ answered X-direction — What WL do no change and upgrades get? REQ-03-12 says '1 notch → WL=1' without saying down
    no prepared answer fits X-calc-mapping — took the BA's recommended option: The caller names the indicator (11, 12 or 13) and gets that indicator's mapping
- ✅ answered X-calc-mapping — Which WL mapping does the notch calculator's 'resultant WL' (REQ-06-02) use?
    no prepared answer fits X-agency-other — took the BA's recommended option: Not this delivery's concern; the caller passes the ratings (recommended with PRD-scope A or B)
- ✅ answered X-agency-other — For the 'Other' segment, which agency is the reference country rating (POC Q2)? This only 
wall time: 87 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer, blind
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 2 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 35 items — 29 decided, 6 n/a · architecture: library: watchlist-core [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 notch.mjs: RATING_SCALE, notchChange, notchCalculator | watchlist-core | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 countryRating.mjs: countryRatingChangeWl (Ind. 12) | watchlist-core | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
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
✖ C1: input is trimmed and case-insensitive; unknown ratings throw RangeError (0.059292ms)
✖ REQ-06-02 + C2: calculator reports notches, direction and WL (Indicator 13 thresholds) (0.894333ms)
  AssertionError [ERR_ASSERTION]: Expected values to be strictly deep-equal:
  + actual - expected
    actual: { notches: 2, direction: 'downgrade', wl: 2 },
    expected: { notches: 2, direction: 'downgrade', wl: 1 },
✖ failing tests:
✖ C1: input is trimmed and case-insensitive; unknown ratings throw RangeError (0.059292ms)
✖ REQ-06-02 + C2: calculator reports notches, direction and WL (Indicator 13 thresholds) (0.894333ms)
  AssertionError [ERR_ASSERTION]: Expected values to be strictly deep-equal:
  + actual - expected
    actual: { notches: 2, direction: 'downgrade', wl: 2 },
- ❌ the job took 87 min (> 45) — where it went: intake 0.4, readiness 5.5, readiness 0.1, awaiting_clarification 0.6, planning 8.5, executing 69.9, integrating 0.3, closing 1.6; busiest: business-analyst 8.4 min (timeline.txt)

## B3 · risk-based test design and the NFR gate

- ✅ every AC of the plan has a priority: AC-1 P1, AC-2 P0, AC-3 P0, AC-4 P0, AC-5 P0, AC-6 P1, AC-7 P1, AC-8 P1, AC-9 P2, AC-10 P3
- ✅ every card spec has a ## Test design

Test design of T-01:
    ## Test design
    
    | AC | priority | level | scenarios |
    |---|---|---|---|
    | AC-1 | P1 | integration (QA), plus a unit smoke test (dev) | QA imports from `src/ratings/notch.mjs` and checks the exact 19-element list against a list it types out itself, the length, `[0]`/`[18]`, `typeof` of the two functions, `Object.isFrozen`, and that `push("CC")` throws `TypeError` while `"CC"` is still rejected afterwards |
    | AC-2 | P0 | unit (dev) + integration (QA) | the main path: all 7 table downgrades, each with `Number.isInteger`. Boundaries: smallest (1), largest (18 = `AAA`→`CCC-`), first and last scale entries as either argument, the IG/HY crossing. Error path: AC-4's table. QA adds all 171 downgrade pairs `c > p` equal to `idx(c)-idx(p)` on its own typed list |
    | AC-3 | P0 | unit (dev) + integration (QA) | the main path: upgrades -1, -3, -18. Boundaries: `-1` and `-18`; `Object.is(r, 0)` for 3 equal pairs and for all 19 diagonal pairs. Antisymmetry over all 361 pairs. Error path: AC-4's table |
    | AC-4 | P0 | unit (dev) + integration (QA) | every invalid value in both positions for `notchChange` and `notchCalculator` (default indicator, and indicator 11), asserted with `assert.throws(fn, RangeError)` plus a check that the error is not a `TypeError`. Missing arguments (4 calls). Prototype names. Symbol and null-prototype objects (the message must not crash). Scale-mutation attempt followed by `"CC"` still rejected |
    | AC-6 | P1 | integration (QA) | the 4 plan examples with `deepStrictEqual`; exact key set; `direction` for -1/0/1; Ind. 12 thresholds at -1, 0, 1, 2, 18 |
    | AC-7 | P1 | integration (QA) | the 5 plan examples; Ind. 11 and 13 thresholds at -1, 0, 1, 2, 3, 18 for both indicators; `12`, `undefined` and omitted give the same result over all 361 pairs; the 7 invalid indicators throw `RangeError` with a downgrade pair and with the no-change pair |
    | AC-9 | P2 | integration (QA) | not-a-Promise check and repeat-call equality on a few pairs; `RATING_SCALE` unchanged after the suite; the source text of `notch.mjs` has no `import`, `import(`, `require(`, `eval(` or `new Function`; `package.json` has no `dependencies` |
    | AC-10 | P3 | unit (dev) / review | a dev unit test reads `src/ratings/notch.mjs` and asserts a `/** … */` block before each export containing `@param` (functions), `@returns` (functions) and `@throws {RangeError}` (functions). The reviewer confirms that the content is accurate, including the `RATING_SCALE` block |
    
QA verdicts (each must name every AC of its card — dl qa refuses otherwise):
    - T-01: AC-1: qa-notch tests 'AC-1'..'AC-3' [spec AC-1] (scale, frozen, exports); AC-2: 'AC-4' downgrade tests; AC-3: 'AC-5','AC-6','AC-7' upgrade/zero/antisymmetry; AC-4: 'AC-8','AC-9','AC-10' invalid/missing inputs; AC-6: 'AC-
    - T-02: AC-1: 'AC-1: countryRatingChangeWl is exported' test; AC-2: 'AC-5: 1-notch downgrade returns the number 1'; AC-3: 'AC-5: downgrade of 2 or more notches returns 2'; AC-4: 'AC-5: no change or any upgrade returns 0'; AC-5: 
decided NFR items: NFR-security, NFR-compliance
- ✅ the report gives every decided NFR item a result: NFR-security PASS, NFR-compliance CONCERNS
- ✅ the plan says how each is checked (## Non-functional requirements)
waived: NFR-compliance — Code mirrors the recorded rules; the business-unit review (C1/A4) is a human step outside this job and is listed as a follow-up before production use

## B4 · the blind review

settings.review.blind: risk
- ✅ T-01 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
- ✅ T-02 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
blind agent runs: 2

## result

cost: $6.54  ·  artifacts: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/idea-control/idea
**47 passed, 2 failed**
