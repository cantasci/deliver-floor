# Live E2E — scenario `shaped`

Request: `examples/watchlist-poc/JOB-shaped.md`  ·  started 2026-10-13T15:05:02Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

✔ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
upstream.engine = bmad; docs/POC_Requirements_v0.2_EN.md in the repo
- ✅ doctor: result: 30 ok, 6 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-shaped.md

- ✅ Michael opened the job JOB-20261013-1706-rating-notch-calculator-and-coun

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Decisions before the work can start — JOB-20261013-1706-rating-notch-calculator-and-coun
    
    BMad shaped this request. Below is what it decided, assumed, asked or found; nothing it wrote binds until you decide.
    Michael's proposal stands on BMad's own words (quoted). Answer each in a terminal — `dl clarify <id> "<your decision>"` —
    or accept all of Michael's proposals at once: `dl clarify proposals "<your words>"`.
    
    ## B-1 — question (bmad-spec)
    
    OQ-1: The REQ-06-02 example BBB+ → BB+ is 3 notches on the standard scale (BBB+, BBB, BBB-, BB+), not the 2 the request says. Is the scale different (for example, no BBB-), or is the example wrong? If 3 notches is right, WL would be 2 under the Ind. 13 thresholds. The example test is blocked until this is settled.
    
    - **Michael proposes:** Keep the standard scale including BBB-; treat the POC example as a typo: BBB+ → BB+ is 3 notches, WL=2 (Ind. 13 thresholds). Tests assert 3 notches / WL=2 and the 2-notch → WL=1 rule is tested with another pair (e.g. BBB+ → BBB-).
      _BMad's words:_ "BBB+ → BB+ is 3 notches on the standard scale" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md)
    
    ## B-2 — question (bmad-spec)
    
    OQ-2: What exactly is RATING_SCALE? Does it include D/SD or CC/C, and does the internal scale in REQ-03-10 (AAA → CCC-) differ from the external one?
    
    - **Michael proposes:** RATING_SCALE is the 22-step S&P/Fitch list in B-5 (AAA … CCC-, CC, C, D); one scale for internal and external use. REQ-03-10's AAA → CCC- is a subset of it.
      _BMad's words:_ "The scale is S&P/Fitch style, best first" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md)
    
    ## B-3 — question (bmad-spec)
    
    OQ-3: Which WL thresholds does the calculator use: Ind. 13, Ind. 12 or Ind. 11? REQ-06-02 gives only the one example.
    
    - **Michael proposes:** Calculator WL uses the Ind. 13 thresholds (2 notches → WL=1, 3+ → WL=2), the only rule that fits the REQ-06-02 example's wording.
      _BMad's words:_ "Calculator WL uses the Ind. 13 thresholds" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md)
    
    ## B-4 — question (bmad-spec)
    
    OQ-4: Should unknown ratings throw (the assumed behaviour) or return null or an error object?
    
    - **Michael proposes:** Unknown ratings throw an Error naming the value.
      _BMad's words:_ "Unknown, non-string or empty ratings throw an `Error` naming the offending value" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md)
    
    ## B-5 — assumption (bmad-spec)
    
    The scale is S&P/Fitch style, best first: AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-, CC, C, D. Moody's notation, NR and SD are not accepted.
    
    - **Michael proposes:** Accept the scale as written (Moody's notation, NR and SD not accepted).
      _BMad's words:_ "Moody's notation, NR and SD are not accepted." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md)
    
    ## B-6 — assumption (bmad-spec)
    
    The calculator's WL uses the Ind. 13 thresholds: a downgrade of 0–1 notches gives WL 0, 2 notches gives WL 1, 3+ gives WL 2. Upgrades and unchanged ratings give WL 0. I chose these because the REQ-06-02 example (2 notches → WL=1) fits them.
    
    - **Michael proposes:** Accept: Ind. 13 thresholds, upgrades and unchanged → WL 0.
      _BMad's words:_ "Upgrades and unchanged → 0." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md)
    
    ## B-7 — assumption (bmad-spec)
    
    countryRatingChangeWl returns 0 for an unchanged rating or an upgrade. Only downgrades count.
    
    - **Michael proposes:** Accept: unchanged or upgrade → WL 0; only downgrades count.
      _BMad's words:_ "unchanged or upgrade → 0 (Assumption)" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md)
    
    ## B-8 — assumption (bmad-spec)
    
    notchCalculator.notches is the absolute magnitude (>= 0), and direction carries the sign.
    
    - **Michael proposes:** Accept: notches is the absolute magnitude, direction carries the sign.
      _BMad's words:_ "`direction` carries the sign." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md)
    
    ## B-9 — assumption (bmad-spec)
    
    Unknown, non-string or empty ratings throw an Error naming the offending value, with no silent fallback. Ratings match exactly (case-sensitive, trimmed).
    
    - **Michael proposes:** Accept: throw on unknown/empty/non-string; exact case-sensitive match after trim.
      _BMad's words:_ "Ratings match exactly (case-sensitive, trimmed)." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md)
    
    ## B-10 — assumption (bmad-spec)
    
    'Auto-filled value editable', scraping, the 12-month lookup and any UI are out of scope, because the slice has no UI or data source.
    
    - **Michael proposes:** Accept: editable auto-fill, scraping, 12-month lookup and UI are out of scope.
      _BMad's words:_ "Any UI, including "auto-filled value editable"" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md)
    
    ## B-11 — decision (bmad-spec)
    
    Non-goals: UI, scraping/public source, editable auto-fill, 12-month lookup, Ind.11/13 functions, agency selector, final WL aggregation
    
    - **Michael proposes:** Accept the non-goals as written.
      _BMad's words:_ "Indicator 11 and 13 WL functions, agency selector, final WL aggregation." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md)
    
- ✅ answered B-1 from HUMAN_ANSWERS — OQ-1: The REQ-06-02 example BBB+ → BB+ is 3 notches on the standard scale (BBB+, BBB, BBB-
- ✅ answered B-2 from HUMAN_ANSWERS — OQ-2: What exactly is RATING_SCALE? Does it include D/SD or CC/C, and does the internal sc
- ✅ answered B-5 from HUMAN_ANSWERS — The scale is S&P/Fitch style, best first: AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, B
- ✅ answered B-8 from HUMAN_ANSWERS — notchCalculator.notches is the absolute magnitude (>= 0), and direction carries the sign.
- ✅ answered B-10 from HUMAN_ANSWERS — 'Auto-filled value editable', scraping, the 12-month lookup and any UI are out of scope, b
- ✅ answered B-11 from HUMAN_ANSWERS — Non-goals: UI, scraping/public source, editable auto-fill, 12-month lookup, Ind.11/13 func
accepted Michael's proposal for 5 item(s) no prepared answer fits: B-3, B-4, B-6, B-7, B-9

## 4.2 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Decisions before the work can start — JOB-20261013-1706-rating-notch-calculator-and-coun
    
    BMad shaped this request. Below is what it decided, assumed, asked or found; nothing it wrote binds until you decide.
    Michael's proposal stands on BMad's own words (quoted). Answer each in a terminal — `dl clarify <id> "<your decision>"` —
    or accept all of Michael's proposals at once: `dl clarify proposals "<your words>"`.
    
    ## B-12 — question (bmad-spec)
    
    OQ-5: The POC document's REQ-06-02 example still says BBB+ → BB+ is 2 notches. Should the POC document be corrected to match decision B-1 (3 notches, WL 2)?
    
    - **Michael proposes:** Yes: BBB+ to BB+ is 3 notches (WL 2), as decided in B-1. Treat the POC document's 2-notch REQ-06-02 example as an error that B-1 supersedes; the delivery follows B-1 and its tests use 3 notches. The document itself is the owner's to correct; the PR lists this as a follow-up.
      _BMad's words:_ "it is 3 notches (WL 2)" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md)
    
accepted Michael's proposal for 1 item(s) no prepared answer fits: B-3, B-4, B-6, B-7, B-9, B-12

## 4.3 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Decisions before the work can start — JOB-20261013-1706-rating-notch-calculator-and-coun
    
    BMad shaped this request. Below is what it decided, assumed, asked or found; nothing it wrote binds until you decide.
    Michael's proposal stands on BMad's own words (quoted). Answer each in a terminal — `dl clarify <id> "<your decision>"` —
    or accept all of Michael's proposals at once: `dl clarify proposals "<your words>"`.
    
    ## B-16 — question (bmad-architecture)
    
    When the Ind. 13 WL function is built later, should it reuse the calculator's threshold mapping? That would mean exporting the helper. This is deferred to that job and does not block this slice.
    
    - **Michael proposes:** Defer: the later Ind. 13 job decides reuse and any export; nothing exported now.
      _BMad's words:_ "Whether the Ind. 13 function reuses the calculator mapping is decided then, and that decision may need to export the helper." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md)
    
    ## B-17 — assumption (bmad-architecture)
    
    The paradigm is a pure-function library in two layers, ratings core and indicators on top, with no UI, store or service. The request and CLAUDE.md state this.
    
    - **Michael proposes:** Accept: pure-function library, two layers, no UI/store/service.
      _BMad's words:_ "A dependency-free library of pure functions in Node 18+ ESM." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md)
    
    ## B-18 — assumption (bmad-architecture)
    
    The calculator's threshold helper (Ind. 13 rule) lives unexported in src/ratings/notch.mjs. The Ind. 12 rule lives in src/indicators/countryRating.mjs. Exports stay exactly as in the request's Contract.
    
    - **Michael proposes:** Accept: threshold helper unexported in notch.mjs; Ind. 12 rule in countryRating.mjs; exports as in the request's Contract.
      _BMad's words:_ "The calculator rule lives in `notch.mjs` and is not exported" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md)
    
    ## B-19 — assumption (bmad-architecture)
    
    RATING_SCALE is a frozen array of the 19 steps AAA to CCC-, matching the SPEC. Only notchChange does the rating lookup and throws, and the other functions let the RangeError propagate unchanged.
    
    - **Michael proposes:** Accept: frozen 19-step RATING_SCALE; only notchChange throws, others propagate the RangeError.
      _BMad's words:_ "`notchCalculator` and `countryRatingChangeWl` let it propagate unchanged." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md)
    
    ## B-20 — assumption (bmad-architecture)
    
    The two test files are test/ratings/notch.test.mjs and test/indicators/countryRating.test.mjs. The file names are my choice; the folders come from the SPEC.
    
    - **Michael proposes:** Accept the file names BMad chose.
      _BMad's words:_ "test/ratings/notch.test.mjs" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md)
    
    ## B-21 — assumption (bmad-architecture)
    
    The spec-validation reviewer subagents were not run, because this slice is small. Only the deterministic lint_spine.py check ran, with 0 findings.
    
    - **Michael proposes:** Accept: the deterministic spine check ran clean; the slice is small.
      _BMad's words:_ "status: final" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md)
    
    ## B-22 — decision (bmad-architecture)
    
    AD-1 notchChange is the single source of truth for rank and distance; notchCalculator and countryRatingChangeWl both call it; only notch.mjs indexes RATING_SCALE
    
    - **Michael proposes:** Accept AD-1: notchChange is the single source of truth for distance.
      _BMad's words:_ "Only `notch.mjs` looks up a rating's position." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md)
    
    ## B-23 — decision (bmad-architecture)
    
    AD-2 RATING_SCALE is a frozen 19-step array, best first; position is rank; no second scale (B-2, B-5)
    
    - **Michael proposes:** Accept AD-2: one frozen 19-step scale, best first.
      _BMad's words:_ "Array position is rank." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md)
    
    ## B-24 — decision (bmad-architecture)
    
    AD-3 WL threshold mappings are named pure functions, never inline: calculator uses Ind.13 (0-1 ->0, 2 ->1, 3+ ->2); Ind.12 uses 1 ->1, 2+ ->2; upgrades and unchanged -> 0 (B-3, B-6, B-7)
    
    - **Michael proposes:** Accept AD-3: separate named pure WL functions (calculator Ind. 13; Ind. 12 in countryRating).
      _BMad's words:_ "`countryRatingChangeWl` uses the Ind. 12 rule (1 → 1, ≥2 → 2)." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md)
    
    ## B-25 — decision (bmad-architecture)
    
    AD-4 invalid rating throws RangeError naming the value, raised only inside notchChange's rating lookup; callers do not catch or translate (B-4, B-9)
    
    - **Michael proposes:** Accept AD-4: RangeError naming the value, only from notchChange.
      _BMad's words:_ "throws `RangeError` whose message names the offending value." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md)
    
    ## B-26 — decision (bmad-architecture)
    
    AD-5 purity and direction: src/ratings and src/indicators do no I/O and use no deps; indicators may import ratings, never the reverse
    
    - **Michael proposes:** Accept AD-5: no I/O, no deps; indicators import ratings, never the reverse.
      _BMad's words:_ "`src/ratings` never imports `src/indicators`." (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md)
    
    ## B-27 — decision (bmad-architecture)
    
    AD-6 tests under test/ratings and test/indicators with node:test; REQ-06-02 example uses 3 notches (B-1, B-12)
    
    - **Michael proposes:** Accept AD-6: node:test layout; REQ-06-02 example is 3 notches (BBB+ → BB+, WL 2).
      _BMad's words:_ "The REQ-06-02 example is BBB+ → BB+ = 3 notches, WL 2" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md)
    
accepted Michael's proposal for 12 item(s) no prepared answer fits: B-3, B-4, B-6, B-7, B-9, B-12, B-16, B-17, B-18, B-19, B-20, B-21, B-22, B-23, B-24, B-25, B-26, B-27

## 4.4 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Decisions before the work can start — JOB-20261013-1706-rating-notch-calculator-and-coun
    
    BMad shaped this request. Below is what it decided, assumed, asked or found; nothing it wrote binds until you decide.
    Michael's proposal stands on BMad's own words (quoted). Answer each in a terminal — `dl clarify <id> "<your decision>"` —
    or accept all of Michael's proposals at once: `dl clarify proposals "<your words>"`.
    
    ## B-38 — question (bmad-architecture)
    
    Should the reviewer-gate lens subagents be run on the updated spine before downstream use? Headless normally requires them, and this run skipped them.
    
    - **Michael proposes:** No: do not run the reviewer-gate lens subagents on the spine. Only the deterministic lint check ran (0 findings), and the independent bmad-review round that follows shaping reviews the updated spine anyway. Nothing built changes.
      _BMad's words:_ "B-28..B-37 applied to ARCHITECTURE-SPINE; no conflict with prior decisions (B-28 refines B-9/AD-4); reviewer subagents not dispatched, lint only" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/.memlog.md)
    
accepted Michael's proposal for 1 item(s) no prepared answer fits: B-3, B-4, B-6, B-7, B-9, B-12, B-16, B-17, B-18, B-19, B-20, B-21, B-22, B-23, B-24, B-25, B-26, B-27, B-38

## 4.5 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Decisions before the work can start — JOB-20261013-1706-rating-notch-calculator-and-coun
    
    BMad shaped this request. Below is what it decided, assumed, asked or found; nothing it wrote binds until you decide.
    Michael's proposal stands on BMad's own words (quoted). Answer each in a terminal — `dl clarify <id> "<your decision>"` —
    or accept all of Michael's proposals at once: `dl clarify proposals "<your words>"`.
    
    ## B-40 — finding, medium
    
    B-34 sets PRD priority Must for both requirements, but the POC marks REQ-06-02 as Should and REQ-03-12 as Must. Neither artifact states a priority. Correct B-34 or record the override knowingly.
    
    - **Michael proposes:** Correct B-34: record the POC's own priorities, REQ-06-02 Should and REQ-03-12 Must, in readiness. Both are delivered in this job; priority changes no code or tests.
      _BMad's words:_ "PRD priority Must for both reqs" (.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/.memlog.md)
    
accepted Michael's proposal for 1 item(s) no prepared answer fits: B-3, B-4, B-6, B-7, B-9, B-12, B-16, B-17, B-18, B-19, B-20, B-21, B-22, B-23, B-24, B-25, B-26, B-27, B-38, B-40

## 4.6 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-1706-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## NFR-compliance
    
    Not in BMad's artifacts. Does any banking regulation or internal policy (for example model risk, or sign-off of the WL scoring rules) constrain this POC slice?
    
    - None for the POC: the WL thresholds are the POC's business rules (B-1, B-3) and need no extra check
    - A named policy applies: a business or model-risk sign-off of the Ind. 12 and calculator thresholds before use
    
    _Why it matters:_ Option 1 changes nothing. Option 2 adds a sign-off step and a documented rule source to the plan's NFRs and to closing.
- ✅ answered NFR-compliance — Not in BMad's artifacts. Does any banking regulation or internal policy (for example model
wall time: 507 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer, blind
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
- ✅ readiness review complete (no open item) with an architecture
readiness: 30 items — 21 decided, 9 n/a · architecture: library: ratings [node], indicators [node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Ratings core: RATING_SCALE, notchChange and notchCalculator (REQ-06-02) with unit tests | ratings | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 Indicator 12: countryRatingChangeWl (REQ-03-12) on top of notchChange, with unit tests | indicators | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
- ✅ every card (2): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration tests are on main (4 file(s) in the cards' qa_scope)
- ✅ role really ran: business-analyst
- ✅ role really ran: ecc:architect
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev agent
- ✅ role really ran: a stack reviewer
- ✅ no tracker errors
- ✅ kanban view rendered
- ✅ report.md written by the closing check
- ✅ no AI attribution in the delivered history (11 commits)
- ✅ the whole test suite passes on main
- ❌ hidden oracle FAILED (oracle.log)
✖ C1: input is trimmed and case-insensitive; unknown ratings throw RangeError (0.0585ms)
✖ failing tests:
✖ C1: input is trimmed and case-insensitive; unknown ratings throw RangeError (0.0585ms)
- ❌ the job took 507.2 min (> 45) — where it went: intake 0.1, shaping 2.2, awaiting_clarification 0.3, shaping 1.1, awaiting_clarification 0.3, shaping 2.3, awaiting_clarification 0.3, shaping 230.9, awaiting_clarification 0.3, shaping 2.5, awaiting_clarification 0.3, shaping 1.9, readiness 4.5, awaiting_clarification 0.4, planning 9.7, executing 8.8, integrating 0.1, closing 241.2; busiest: business-analyst 248.5 min (timeline.txt)

## B3 · risk-based test design and the NFR gate

- ✅ every AC of the plan has a priority: AC-1 P0, AC-2 P2, AC-3 P0, AC-4 P2, AC-5 P0, AC-6 P2, AC-7 P2, AC-8 P1, AC-9 P1, AC-10 P2, AC-11 P0, AC-12 P1, AC-13 P0, AC-14 P1, AC-15 P2, AC-16 P1, AC-17 P3
- ✅ every card spec has a ## Test design

Test design of T-01:
    ## Test design
    Unit tests are written by the dev in `test/ratings/notch.test.mjs` (import `../../src/ratings/notch.mjs`). Give it one top-level `describe` named after the module (e.g. `"ratings/notch"`) so QA can spot the file in the `npm test` output.
    
    QA integration tests go in `test/ratings/qa/` (files `qa-*.test.mjs`, e.g. `qa-ratings-consumer.test.mjs` and `qa-ratings-purity.test.mjs`). Every QA test name starts with `qa-ratings:` so it is unique in the repo.
    - QA imports the module the way a consumer does, through its public path (`../../../src/ratings/notch.mjs`, static and `await import(...)`).
    - QA reads source files with `node:fs` (allowed in tests only). Before grepping, it strips `/* */` and `//` comments.
    - A QA test must never spawn `npm test`, because that would run itself recursively.
    
    | AC | Priority | Level | Scenarios |
    |---|---|---|---|
    | AC-1 | P0 | unit (dev) | Deep-equal to the 19 steps; length 19; boundaries `RATING_SCALE[0]==="AAA"`, `[18]==="CCC-"`, `indexOf("BBB+")===7`, `indexOf("BB+")===10`. |
    | AC-1 | P0 | integration (QA) | Consumer import (static and dynamic yield the same frozen instance) deep-equals the list. The scale literal exists exactly once in `src/` (grep for `"CCC-"` finds it only in `notch.mjs`). |
    | AC-2 | P2 | integration (QA) | `Object.isFrozen`; `push("CC")`, `[0]="X"` and `length=0` each throw TypeError; afterwards still deep-equal, and `notchChange("AAA","CCC-")` is still 18. |
    | AC-3 | P0 | unit (dev) | 18 adjacent pairs = 1 and reverses = -1; the 7 pinned values; extremes ±18; `Number.isInteger` on the results. |
    | AC-3 | P0 | integration (QA) | All 361 pairs equal `indexOf(c)-indexOf(p)`. Antisymmetry `notchChange(a,b) === -notchChange(b,a)` for a ≠ b. Additivity `notchChange(a,b)+notchChange(b,c) === notchChange(a,c)` on all triples or a sampled set. Pinned values again: BBB+→BB+ = 3, never 2. |
    | AC-4 | P2 | integration (QA) | All 19 self-pairs: `Object.is(r, 0)`. |
    | AC-5 | P0 | unit (dev) | All 15 invalid values × 2 positions → `assert.throws(..., RangeError)`. |
    | AC-5 | P0 | integration (QA) | All 30 calls again through the consumer import, each checked as `instanceof RangeError`, with no return value. Boundary extras from the rule: `"AAA+"`, `"BBB +"`, `" bbb+ "`, `"Aaa"` throw. |
    | AC-6 | P2 | integration (QA) | The 7 message rows (contains, not equals); Symbol gives a RangeError, not a TypeError; `("XX1","XX2")` names XX1 only; `("BBB","XYZ")` names XYZ. |
    | AC-7 | P2 | integration (QA) | `(" BBB+ ","BB+") === 3`; `("BBB"," BBB ")` is +0. |
    | AC-8 | P1 | integration (QA) | All 7 table rows `deepStrictEqual` with `Object.keys(r).length === 3`. Key edges: the corrected example (3/WL 2), 1-notch → WL 0, 2-notch → WL 1, the cap at 18 → WL 2, upgrade → WL 0. Review: a grep of `test/` for `BBB+` shows no expectation of 2 notches or WL 1 for BBB+ → BB+. |
    | AC-9 | P1 | integration (QA) | 361-pair loop applying the three rules. Key edges: the threshold pairs at notches -1, 0, 1, 2 and 3 (e.g. `("A","A-")`, `("A","BBB+")`, `("A","BBB")`). |
    | AC-10 | P2 | integration (QA) | `("BBB","BBB")` deep-equal, and `Object.is(notches, 0)`. |
    | AC-13 (calc) | P0 | unit (dev) | `("CC","BBB")` gives RangeError ⊇ "CC"; `("BBB","")` gives RangeError. |
    | AC-13 (calc) | P0 | integration (QA) | For every one of the 15 invalid values in both positions, `notchCalculator` throws an error whose constructor is `RangeError` and whose message `===` the message `notchChange` throws for the same arguments. No call returns. Grep: no `try`/`catch` in `notchCalculator.toString()`. |
    | AC-14 (notch) | P1 | unit (dev) | Namespace keys sorted equal the 3 names; no `default`; `typeof` checks. |
    | AC-14 (notch) | P1 | integration (QA) | `await import()` of the public path: the same 3 keys, `"default" in n` is false, both functions have `typeof` `"function"`. |
    | AC-15 (ratings) | P2 | integration (QA, grep/purity) | On the comment-stripped source of every file in `src/ratings/`, assert no match for each of: `indicators/`, `from ['"](node:)?(fs\|net\|http\|process)['"]`, `require\(`, `import\(`, `\bconsole\b`, `\bDate\b`, `Math\.random`, `\bprocess\b`, module-scope `let`/`var`. `notchCalculator.toString()` contains `notchChange(` and neither `indexOf` nor `RATING_SCALE`. `notch.mjs` declares at least one named function that is not an export, and the raw (comment-kept) source contains `/intentional/i`. `JSON.parse(package.json)` has no or empty `dependencies` and `devDependencies`. Review confirms the Ind. 13 helper and its B-36 comment. |
    
QA verdicts (each must name every AC of its card — dl qa refuses otherwise):
    - T-01: AC-1: qa-ratings: AC-1 deep-equals 19 steps; AC-2: qa-ratings: AC-2 frozen and mutations throw TypeError; AC-3: qa-ratings: AC-3 361 pairs; AC-4: qa-ratings: AC-4 all 19 self-pairs return +0; AC-5: qa-ratings: AC-5 inval
    - T-02: AC-1: qa-ratings: AC-1 deep-equals 19 steps (T-01 QA, merged; pinned in test/ratings/notch.test.mjs, named by AC-16); AC-11: qa-indicators: AC-11 pinned rows and 361-pair loop; AC-12: qa-indicators: AC-12 A/A- calculator
decided NFR items: NFR-security, NFR-audit, NFR-observability, NFR-compliance
- ✅ the report gives every decided NFR item a result: NFR-security PASS, NFR-audit PASS, NFR-observability PASS, NFR-compliance PASS
- ✅ the plan says how each is checked (## Non-functional requirements)

## B4 · the blind review

settings.review.blind: risk
- ✅ T-01 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
- ✅ T-02 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
blind agent runs: 2

## S1 · shaped with the BMad Method

- ✅ the job was shaped (shaping.json)
BMad's path (bmad-help): bmad-spec → bmad-architecture · skipped: bmad-prd, bmad-product-brief, bmad-prfaq, bmad-brainstorming, bmad-forge-idea, bmad-deep-recon, bmad-ux, bmad-project-context, bmad-advanced-elicitation, bmad-party-mode, bmad-create-epics-and-stories, bmad-sprint-planning, bmad-build, bmad-build-auto, bmad-code-review, bmad-qa-generate-e2e-tests, bmad-walkthrough, bmad-retrospective, bmad-correct-course, bmad-customize
runs: 01-help complete 41s $0.19 · 02-create-spec complete 51s $0.26 · 03-update-spec complete 45s $0.25 · 04-update-spec complete 28s $0.2 · 05-create-architecture complete 76s $0.29 · 06-update-spec complete 34s $0.22 · 07-update-architecture complete 20s $0.19 · 08-review complete 61s $0.26 · 09-update-spec complete 65s $0.29 · 10-update-architecture partial 57s $0.26 · 11-update-spec complete 20s $0.18 · 12-update-architecture complete 21s $0.16 · 13-review complete 69s $0.3 · 14-update-spec complete 46s $0.26 · 15-update-architecture complete 36s $0.23
shaping: 15 runs, 11 min, $3.54
ledger: assumption 11, conflict 12, decision 7, finding 19, question 7 · decided by the human 26, by Michael 18, Michael's proposal accepted without a prepared answer 20
- ✅ every ledger item decided (or noted)
BMad's reviews: round 1: ready-with-concerns (10) · round 2: ready-with-concerns (9)
- ✅ BMad reviewed its own work at least once
- ✅ frozen with readiness at planning (frozen.shaping_sha256)
- ✅ the readiness review settled 26 item(s) from BMad's words (bmad: / shape:)
traced ids: CAP-1, CAP-2, CAP-3 (dl validate refuses a plan that leaves one out)
AD rules for the reviewers: 6
- ✅ the PR body says how it was shaped
- ✅ the record keeps BMad's inputs and artifacts on main
- ✅ BMad's install stayed outside git

## result

cost: $8.06  ·  artifacts: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/live-shaped2/shaped
**45 passed, 2 failed**
