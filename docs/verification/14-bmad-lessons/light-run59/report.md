# Live E2E — scenario `light`

Request: `examples/watchlist-poc/JOB-light.md`  ·  started 2026-10-13T12:47:07Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

✔ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ existing code in the repo: 8 files, its tests pass, no architecture.md
- ✅ doctor: result: 27 ok, 6 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-light.md

- ✅ Michael opened the job JOB-20261013-1448-indicator-13-external-rating

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the light request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-1448-indicator-13-external-rating
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## ARC-style
    
    What is the project's architecture style, so it can be confirmed in architecture.md?
    
    - library: one component of pure functions (src/ratings, src/indicators), no runtime entry point
    - monolith: one deployable application that will grow these modules
    
    _Why it matters:_ None on this change's code; only what the project standard records for later jobs.
    
    ## ARC-components
    
    Confirm the component list: one component 'repo' (library, Node.js 18+ ESM, path '.', suite npm test)?
    
    - As drafted: one component, whole repo, suite npm test
    - Two library components: ratings (src/ratings) and indicators (src/indicators)
    
    _Why it matters:_ None on this change's code; how components and verify commands are recorded for this and later jobs.
- ✅ answered ARC-style — What is the project's architecture style, so it can be confirmed in architecture.md?
- ✅ answered ARC-components — Confirm the component list: one component 'repo' (library, Node.js 18+ ESM, path '.', suit
wall time: 9 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, qa, backend, reviewer, blind
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
- ✅ readiness review complete (no open item) with an architecture
readiness: 14 items — 12 decided, 2 n/a · architecture: library: watchlist-poc [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 1 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Indicator 13: externalRatingChangeWl(previous, current) on notchChange | watchlist-poc | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
- ✅ every card (1): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration tests are on main (1 file(s) in the cards' qa_scope)
- ✅ role really ran: business-analyst
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev agent
- ✅ role really ran: a stack reviewer
- ✅ no tracker errors
- ✅ kanban view rendered
- ✅ report.md written by the closing check
- ✅ no AI attribution in the delivered history (7 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (4 checks, light.oracle.test.mjs)
- ✅ the job took 8.9 min (≤ 15; timeline.txt)

## B3 · risk-based test design and the NFR gate

- ✅ every AC of the plan has a priority: AC-1 P0, AC-2 P0, AC-3 P1, AC-4 P1, AC-5 P0, AC-6 P1
- ✅ every card spec has a ## Test design

Test design of T-01:
    ## Test design
    | AC | Priority | Level | Scenarios |
    | --- | --- | --- | --- |
    | AC-1 | P0 | unit (dev) and integration (QA) | +2 → 1 (BBB+→BBB-, A→BBB+). Boundaries +1 → 0 and +3 → 2. Integration: every pair in `RATING_SCALE` with `notchChange === 2` gives `1`. |
    | AC-2 | P0 | unit (dev) and integration (QA) | +3, +4, +18 → 2. Integration: every pair with `notchChange >= 3` gives `2`; result is a number (`strictEqual`). |
    | AC-3 | P1 | integration (QA) | +1, 0, −1, −3, −18 → 0; swapped argument order. Integration: every pair with `notchChange <= 1` gives `0`. |
    | AC-4 | P1 | integration (QA) | `" bbb+ "`→`"bb+"` → 2; `"bbb+"`→`"Bbb-"` → 1; `"\tA\n"`→`"a"` → 0; inner space throws. |
    | AC-5 | P0 | unit (dev) and integration (QA) | Error paths in both positions: `"nope"`, `"D"`, `"CC"`, `"NR"`, `"Baa1"`, `""`, `"   "`, `null`, `undefined`. Each throws `RangeError` whose message equals `notchChange`'s for the same input. |
    | AC-6 | P1 | integration (QA) | Full `node --test` green; only new files added; `notchCalculator("BBB+", "BB+")` deep-equals `{ notches: 3, direction: "downgrade", wl: 2 }`; `countryRatingChangeWl("BBB", "BBB-")` still returns `1`. |
    
QA verdicts (each must name every AC of its card — dl qa refuses otherwise):
    - T-01: AC-1: AC-1: BBB+ → BBB- (+2 notches) returns exactly the number 1; AC-2: AC-2: downgrades of 3, 4 and 18 notches return 2; AC-3: AC-3: 1-notch downgrade, no change and upgrades return 0 (spec data); AC-4: AC-4: whitespac
decided NFR items: none
NOT EXERCISED: no NFR item was decided in this job (all n/a)

## B4 · the blind review

settings.review.blind: risk
- ✅ T-01 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
blind agent runs: 1

## B1 · the light path

- ✅ Michael took the light path, with the request's words
his reason: the light path: a small change to existing code ("This change adds one function next to them and changes nothing that exists.") — one new function next to existing code, no new dependency/data/integration/UI
- ✅ …and stayed on it (no dl track full)
readiness: 14 items (the full path asks 29 for this repo)
- ✅ no Lead role
- ✅ at most 2 cards

## B2 · the project's architecture, confirmed once and committed

context events: drafted from the repo: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540- 
ARC answers: ARC-style: decided (human: e2e-human 2026-10-13); ARC-components: decided (human: e2e-human 2026-10-13)
- ❌ architecture.md is on main
- ❌ …and dl context check passes on it
- ❌ the PR body says so (## Project architecture)

## B2 · a second small change settles its architecture from the file (JOB-light2.md)

- ❌ no second job was created

## result

cost: $2.36  ·  artifacts: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/live/light
**35 passed, 4 failed**
