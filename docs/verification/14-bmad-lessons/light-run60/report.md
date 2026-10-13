# Live E2E — scenario `light`

Request: `examples/watchlist-poc/JOB-light.md`  ·  started 2026-10-13T13:30:21Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

✔ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ existing code in the repo: 8 files, its tests pass, no architecture.md
- ✅ doctor: result: 27 ok, 6 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-light.md

- ✅ Michael opened the job JOB-20261013-1531-indicator-13-external-rating-cha

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the light request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-1531-indicator-13-external-rating-cha
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## ARC-style
    
    What is the architecture style of the repo? The draft leaves it unfilled.
    
    - As in the draft: a single-component library of pure functions (src/ratings, src/indicators), no runtime or service
    - Modular monolith with area modules
    - Something else the team names
    
    _Why it matters:_ This change does not depend on the answer; it is recorded as the project architecture for later jobs.
    
    ## ARC-components
    
    Confirm the component list: the draft has one component, 'repo', a JavaScript library at '.', suite 'npm test'.
    
    - As in the draft: one component, repo, library, node, path '.', owner backend
    - Split into area components (ratings, indicators)
    
    _Why it matters:_ This change touches only src/indicators and test/; the answer shapes future job splits.
- ✅ answered ARC-style — What is the architecture style of the repo? The draft leaves it unfilled.
- ✅ answered ARC-components — Confirm the component list: the draft has one component, 'repo', a JavaScript library at '
wall time: 10 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend, qa, reviewer, blind
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
- ✅ readiness review complete (no open item) with an architecture
readiness: 13 items — 12 decided, 1 n/a · architecture: library: repo [node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 1 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Indicator 13: externalRatingChangeWl(previous, current) on notchChange | repo | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
- ✅ every card (1): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration tests are on main (1 file(s) in the cards' qa_scope)
- ✅ role really ran: business-analyst
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev agent
- ✅ role really ran: a stack reviewer
- ✅ no tracker errors
- ✅ kanban view rendered
- ✅ report.md written by the closing check
- ✅ no AI attribution in the delivered history (8 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (4 checks, light.oracle.test.mjs)
- ✅ the job took 10.4 min (≤ 15; timeline.txt)

## B3 · risk-based test design and the NFR gate

- ✅ every AC of the plan has a priority: AC-1 P1, AC-2 P1, AC-3 P1, AC-4 P2, AC-5 P1, AC-6 P1, AC-7 P2
- ✅ every card spec has a ## Test design

Test design of T-01:
    ## Test design
    | AC | Priority | Level | Scenarios |
    |---|---|---|---|
    | AC-1 | P1 | unit (dev, TDD) + integration (QA) | Dev: `("BBB+","BBB-")` → 1. QA: every 2-notch pair on the real `RATING_SCALE` (17 pairs) → 1, including the top `("AAA","AA")` and the bottom `("CCC+","CCC-")`; the boundary with 1 notch `("BBB+","BBB")` → 0 and with 3 notches `("BBB+","BB+")` → 2. |
    | AC-2 | P1 | unit (dev) + integration (QA) | Dev: `("BBB+","BB+")` → 2. QA: all 361 pairs against `d>=3?2:d===2?1:0` (136 give 2), the 3-notch boundary at the bottom `("B-","CCC-")` → 2, and the maximum `("AAA","CCC-")` → 2. |
    | AC-3 | P1 | unit (dev) + integration (QA) | Dev: `("BBB+","BBB")` → 0, `("AA","AA")` → 0, `("BB","BBB")` → 0. QA: every adjacent 1-notch downgrade (18) → 0, every unchanged pair (19) → 0, every upgrade (171) → 0, including `("BBB-","BBB+")` and `("CCC-","AAA")`; total WL 0 = 208. |
    | AC-4 | P2 | integration (QA), dev unit optional | `(" bbb+ ","bb+")` → 2, `("bbb+","Bbb-")` → 1, `("aa","AA")` → 0. |
    | AC-5 | P1 | unit (dev) + integration (QA) | Dev: `("X","A")` throws `RangeError`. QA: `assert.throws(..., RangeError)` for `("A","X")`, `("","A")`, `("   ","A")`, `(null,"A")`, `(undefined,"BBB")`, `("BBB")`, `("BBB","D")`, `("NR","BBB")`, `("Baa1","BBB")`, `("A +","A")`, `(5,"A")`; type only, not the message. |
    | AC-6 | P1 | integration (QA, full suite) + review | `npm test` is green with the existing tests unchanged; `git diff --name-only main...HEAD` lists only the three new files. |
    | AC-7 | P2 | integration (QA) + review | QA: the named import works, `typeof externalRatingChangeWl === "function"`, every result in the 361-pair loop has `typeof === "number"` and is in {0,1,2}. Review: the only import is `notchChange` from `../ratings/notch.mjs`, there are no rating literals or scale copy, and no I/O or logging (NFR-security, NFR-privacy). |
    
QA verdicts (each must name every AC of its card — dl qa refuses otherwise):
    - T-01: AC-1: all 17 two-notch pairs → 1; AC-2: all 136 pairs ≥3 notches → 2; AC-3: 208 pairs → 0 (18 one-notch, 19 unchanged, 171 upgrades); AC-4: normalisation tests (' bbb+ ','bb+'); AC-5: RangeError tests for invalid inputs;
decided NFR items: NFR-security
- ✅ the report gives every decided NFR item a result: NFR-security null
- ✅ the plan says how each is checked (## Non-functional requirements)

## B4 · the blind review

settings.review.blind: risk
- ✅ T-01 (top P1): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
blind agent runs: 1

## B1 · the light path

- ✅ Michael took the light path, with the request's words
his reason: the light path: a small change to existing code ("This change adds one function next to them and changes nothing that exists.") — one new function next to existing code, one card, no new dependency/data/integration/UI
- ✅ …and stayed on it (no dl track full)
readiness: 13 items (the full path asks 29 for this repo)
- ✅ no Lead role
- ✅ at most 2 cards

## B2 · the project's architecture, confirmed once and committed

context events: drafted from the repo: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540- proposed for .deliver/knowledge/architecture.md: architecture: 1 component(s) — repo (.) 
ARC answers: ARC-style: decided (human: e2e-human 2026-10-13); ARC-components: decided (human: e2e-human 2026-10-13)
- ✅ architecture.md is on main
- ✅ …and dl context check passes on it
- ✅ the PR body says so (## Project architecture)

## B2 · a second small change settles its architecture from the file (JOB-light2.md)


## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the light request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-1542-investment-grade-check
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-conflicts
    
    The request says 'nothing that exists changes' and that the existing exports stay as they are, but also asks to add an export to src/ratings/notch.mjs. The existing QA test 'AC-1: the module exports the contract' (test/integration/ratings/notch.int.test.mjs) requires the export list to be exactly [RATING_SCALE, notchCalculator, notchChange], so adding isInvestmentGrade makes it fail. May that one assertion be updated to include isInvestmentGrade?
    
    - (a) Recommended: update only that assertion to [RATING_SCALE, isInvestmentGrade, notchCalculator, notchChange]; every other existing test stays as it is.
    - (b) Leave the existing test untouched and put isInvestmentGrade in a new module (contradicts 'Add one function to that file').
    - (c) Weaken the assertion to 'contains at least these exports' (a later extra export would no longer be caught).
- ❌ no prepared answer for PRD-conflicts — a real person must answer: The request says 'nothing that exists changes' and that the existing exports stay as they are, but also asks to add an export to src/ratings/notch.mjs. The existing QA test 'AC-1: the module exports the contract' (test/integration/ratings/notch.int.test.mjs) requires the export list to be exactly [RATING_SCALE, notchCalculator, notchChange], so adding isInvestmentGrade makes it fail. May that one assertion be updated to include isInvestmentGrade?

## 4.2 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the light request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-1542-investment-grade-check
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-conflicts
    
    The request says 'nothing that exists changes' and that the existing exports stay as they are, but also asks to add an export to src/ratings/notch.mjs. The existing QA test 'AC-1: the module exports the contract' (test/integration/ratings/notch.int.test.mjs) requires the export list to be exactly [RATING_SCALE, notchCalculator, notchChange], so adding isInvestmentGrade makes it fail. May that one assertion be updated to include isInvestmentGrade?
    
    - (a) Recommended: update only that assertion to [RATING_SCALE, isInvestmentGrade, notchCalculator, notchChange]; every other existing test stays as it is.
    - (b) Leave the existing test untouched and put isInvestmentGrade in a new module (contradicts 'Add one function to that file').
    - (c) Weaken the assertion to 'contains at least these exports' (a later extra export would no longer be caught).
- ❌ no prepared answer for PRD-conflicts — a real person must answer: The request says 'nothing that exists changes' and that the existing exports stay as they are, but also asks to add an export to src/ratings/notch.mjs. The existing QA test 'AC-1: the module exports the contract' (test/integration/ratings/notch.int.test.mjs) requires the export list to be exactly [RATING_SCALE, notchCalculator, notchChange], so adding isInvestmentGrade makes it fail. May that one assertion be updated to include isInvestmentGrade?

## 4.3 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the light request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-1542-investment-grade-check
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-conflicts
    
    The request says 'nothing that exists changes' and that the existing exports stay as they are, but also asks to add an export to src/ratings/notch.mjs. The existing QA test 'AC-1: the module exports the contract' (test/integration/ratings/notch.int.test.mjs) requires the export list to be exactly [RATING_SCALE, notchCalculator, notchChange], so adding isInvestmentGrade makes it fail. May that one assertion be updated to include isInvestmentGrade?
    
    - (a) Recommended: update only that assertion to [RATING_SCALE, isInvestmentGrade, notchCalculator, notchChange]; every other existing test stays as it is.
    - (b) Leave the existing test untouched and put isInvestmentGrade in a new module (contradicts 'Add one function to that file').
    - (c) Weaken the assertion to 'contains at least these exports' (a later extra export would no longer be caught).
- ❌ no prepared answer for PRD-conflicts — a real person must answer: The request says 'nothing that exists changes' and that the existing exports stay as they are, but also asks to add an export to src/ratings/notch.mjs. The existing QA test 'AC-1: the module exports the contract' (test/integration/ratings/notch.int.test.mjs) requires the export list to be exactly [RATING_SCALE, notchCalculator, notchChange], so adding isInvestmentGrade makes it fail. May that one assertion be updated to include isInvestmentGrade?
- ❌ the second job reached done
- ✅ …on the light path
- ✅ the human was not asked about the architecture again
- ✅ its components are the file's (["repo"])
- ❌ hidden oracle of the second change FAILED (oracle2.log)
- ✅ …and the first change still passes its oracle

## result

cost: $3.47  ·  artifacts: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/live3/light
**44 passed, 5 failed**
