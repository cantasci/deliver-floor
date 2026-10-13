# Live E2E — scenario `complete`

Request: `examples/watchlist-poc/JOB.md`  ·  started 2026-10-13T12:47:07Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

✔ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 27 ok, 6 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB.md

- ✅ Michael opened the job JOB-20261013-1448-rating-notch-calculator-and-coun

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the complete request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-1448-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## ARC-style
    
    Which architecture style does this repo have? The draft architecture is not confirmed yet.
    
    - As in the draft (context.draft.md): a library, one component 'repo' at path '.', suite npm test
    - A modular library: one package with areas src/ratings and src/indicators, still one component and one suite
    
    _Why it matters:_ Low. Both options give the same code layout. Recommendation: library.
    
    ## ARC-components
    
    Confirm the component list. The draft lists one library component, 'repo' (javascript, path '.', suite npm test).
    
    - As in the draft: one component 'repo' holding src/ratings, src/indicators and test/
    - Two components, ratings and indicators (not recommended: one package.json, one suite)
    
    _Why it matters:_ Decides card ownership and the QA verify command. Recommendation: the single component.
    
    ## X-trim-whitespace
    
    C1 says the input is 'trimmed' but not which whitespace. Does trimming cover tabs, newlines and non-breaking spaces (String.prototype.trim), or only ASCII spaces? Is internal whitespace such as 'BBB +' rejected?
    
    - String.prototype.trim (all Unicode whitespace at both ends); internal whitespace gives RangeError
    - Only leading and trailing ASCII spaces; everything else gives RangeError
    
    _Why it matters:_ Changes which inputs are accepted vs. throw RangeError, e.g. '\tBBB+\n'. Recommendation: option 1.
- ✅ answered ARC-style — Which architecture style does this repo have? The draft architecture is not confirmed yet.
- ✅ answered ARC-components — Confirm the component list. The draft lists one library component, 'repo' (javascript, pat
- ✅ answered X-trim-whitespace — C1 says the input is 'trimmed' but not which whitespace. Does trimming cover tabs, newline
wall time: 20 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, qa, backend-lead, backend, reviewer, blind
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 3 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 32 items — 23 decided, 9 n/a · architecture: library: repo [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Rating scale and notch calculator (src/ratings/notch.mjs) | repo | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 Indicator 12 country rating change WL (src/indicators/countryRating.mjs) | repo | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
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
- ✅ hidden oracle passes (5 checks, watchlist.oracle.test.mjs)
- ❌ the job took 20.5 min (> 15) — where it went: intake 0.3, readiness 3.4, awaiting_clarification 0.4, planning 6.9, executing 7.5, integrating 0.4, closing 1.6; busiest: business-analyst 6.7 min (timeline.txt)

## B3 · risk-based test design and the NFR gate

- ✅ every AC of the plan has a priority: AC-1 P0, AC-2 P2, AC-3 P0, AC-4 P1, AC-5 P0, AC-6 P0, AC-7 P1, AC-8 P0, AC-9 P1, AC-10 P1, AC-11 P1
- ✅ every card spec has a ## Test design

Test design of T-01:
    ## Test design
    | AC | Priority | Level | Scenarios |
    |---|---|---|---|
    | AC-1 | P0 | unit + integration | deep equal, length, ends, regex, excluded grades |
    | AC-2 | P2 | integration (dev may unit test) | isFrozen, three mutations throw TypeError, scale unchanged |
    | AC-3 | P0 | unit + integration | 9 examples, ±1/±18, Object.is on diagonal, antisymmetry |
    | AC-4 | P1 | integration | case, each trim() whitespace kind, both arguments, both functions |
    | AC-5 | P0 | unit + integration | every invalid value × both positions × both functions; missing args; Symbol/null-proto; message contains previous and X; no mutation |
    | AC-6 | P0 | unit + integration | 5 examples; n=1,2,3,18; exact keys; C2 example by name |
    | AC-7 | P1 | integration | upgrades -1,-2,-3,-18; unchanged plain and normalised; Object.is |
    | AC-10 | P1 | integration | 361 pairs |
    | AC-11 | P1 | integration | typeof; child process stdout/stderr empty; package.json diff empty; source scan |
    
QA verdicts (each must name every AC of its card — dl qa refuses otherwise):
    - T-01: AC-1: AC-1 RATING_SCALE deep-equals the 19 C1 ratings; AC-2: AC-2 frozen, mutations throw TypeError; AC-3: AC-3 nine spec examples; AC-4: AC-4 case and trim whitespace tests; AC-5: AC-5 invalid values RangeError + X-erro
    - T-02: AC-8: countryRating.int.test.mjs spec examples + n=1..18 + C6 contrast; AC-9: countryRating.int.test.mjs Object.is +0 upgrade/unchanged; AC-4: countryRating.int.test.mjs case/whitespace kinds; AC-5: countryRating.int.tes
decided NFR items: NFR-security, NFR-audit
- ✅ the report gives every decided NFR item a result: NFR-security null, NFR-audit null
- ✅ the plan says how each is checked (## Non-functional requirements)

## B4 · the blind review

settings.review.blind: risk
- ✅ T-01 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
- ✅ T-02 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
blind agent runs: 2

## result

cost: $5.10  ·  artifacts: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/live/complete
**34 passed, 1 failed**
