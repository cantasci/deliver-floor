# Live E2E — scenario `complete`

Request: `examples/watchlist-poc/JOB.md`  ·  started 2026-10-20T06:47:13Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
fault injection (E2E_INJECT=regression): a post-merge hook swaps BBB- and BB+ on the job branch once
- ✅ doctor: result: 30 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB.md

- ✅ Michael opened the job JOB-20261020-0647-notch-calculator-and-country-rat

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the complete request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261020-0647-notch-calculator-and-country-rat
    
    Answer each question in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## ARC-style
    
    The architecture draft is not confirmed and its Style is still a placeholder. Which style should it record?
    
    - Library, one component (as in the draft): matches the Contract's plain ES modules that other POC parts import.
    - Modular monolith: the POC is one Node app with modules in src/<area>/; this job adds the ratings and indicators modules.
    
    _Why it matters:_ Same code either way; only fixes architecture.md, the project standard later POC jobs are planned against.
    
    ## ARC-components
    
    Confirm the component list: one component 'repo' (library, node, path '.', suite 'npm test'), or src/ratings and src/indicators as separate library components?
    
    - One component 'repo', kind library, path '.', suite 'npm test' (as in the draft).
    - Two library components: 'ratings' (src/ratings/, test/ratings/) and 'indicators' (src/indicators/, test/indicators/, depends on ratings), each verified with 'node --test test/<area>/'.
    
    _Why it matters:_ Changes how cards are cut and which verify command each card runs. Delivered code is the same.
    
    ## X-trim
    
    C1 says input is trimmed but not which whitespace. What must be stripped from the start and end of a rating? (Whitespace inside, e.g. 'BBB +', is always rejected.)
    
    - JavaScript String.prototype.trim(): all Unicode whitespace and line terminators (incl. NBSP U+00A0, U+FEFF). Recommended.
    - ASCII whitespace only (space, \t, \n, \r, \v, \f); NBSP throws RangeError.
    - Spaces only; tabs and newlines throw RangeError.
    
    _Why it matters:_ Decides whether values pasted with tabs, newlines or NBSP give a WL or throw. Tests pin this exactly.
- ✅ answered ARC-style — The architecture draft is not confirmed and its Style is still a placeholder. Which style 
- ✅ answered ARC-components — Confirm the component list: one component 'repo' (library, node, path '.', suite 'npm test
- ✅ answered X-trim — C1 says input is trimmed but not which whitespace. What must be stripped from the start an
wall time: 37 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer, blind
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 2 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 33 items — 23 decided, 10 n/a · architecture: library: repo [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 3 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Rating scale, notchChange and notchCalculator (REQ-06-02) in src/ratings/notch.mjs | repo | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 Indicator 12 country rating change WL (REQ-03-12) in src/indicators/countryRating.mjs | repo | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-03 Fix F-1: restore C1 RATING_SCALE order (BBB- before BB+) in src/ratings/notch.mjs on the job branch | repo | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
- ✅ every card (3): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration tests are on main (5 file(s) in the cards' qa_scope)
- ✅ role really ran: business-analyst
- ✅ role really ran: ecc:architect
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev agent
- ✅ role really ran: a stack reviewer
- ✅ no tracker errors
- ✅ kanban view rendered
- ✅ report.md written by the closing check
- ✅ no AI attribution in the delivered history (15 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (5 checks, watchlist.oracle.test.mjs)
- ❌ the job took 36.9 min (> 15) — where it went: intake 0.3, readiness 5.5, awaiting_clarification 0.6, planning 8.1, executing 19.3, integrating 0.9, closing 2.2; busiest: business-analyst 11 min (timeline.txt)

## B3 · risk-based test design and the NFR gate

- ✅ every AC of the plan has a priority: AC-1 P0, AC-2 P2, AC-3 P0, AC-4 P1, AC-5 P1, AC-6 P0, AC-7 P0, AC-8 P1, AC-9 P0, AC-10 P0, AC-11 P1, AC-12 P1, AC-13 P2
- ✅ every card spec has a ## Test design

Test design of T-01:
    ## Test design
    | AC | Priority | Level | Scenarios |
    | --- | --- | --- | --- |
    | AC-1 | P0 | unit (dev, `test/ratings/notch.test.mjs`) + integration (QA, `test/integration/ratings/`) | deepStrictEqual of the full list; length 19; first and last entry; no U+2212; QA imports through the Contract path |
    | AC-2 | P2 | integration (QA); unit as well | isFrozen; push throws TypeError; index assignment throws TypeError; scale and `notchChange("AAA","AA+")` unchanged afterwards |
    | AC-3 | P0 | unit + integration | the 7-row table; ±1, ±18 and 0 at both scale ends; `Object.is(…,0)` for all 19 `r→r`; invalid input is covered by AC-5 rows |
    | AC-4 | P1 | unit + integration | lower case, mixed case, spaces, tab/newline, NBSP in both positions, for `notchChange` and `notchCalculator` |
    | AC-5 | P1 | unit + integration | the full invalid table × 2 positions × 2 functions; one bad / the other good; both bad names `previous`; message contains value and argument name; no coercion (`["BBB+"]`, `new String`, toString object); Symbol/null never TypeError |
    | AC-6 | P0 | unit + integration | the 6-row downgrade table with the C2 note; boundaries 1/2/3 notches in the middle and at both ends (AAA→AA, AAA→AA-, CCC+→CCC-, CCC→CCC-); max 18 |
    | AC-7 | P0 | unit + integration | -1, -2 (Math.abs trap), -3, -18 → wl 0; unchanged `{0,"unchanged",0}` with Object.is |
    | AC-8 | P1 | unit + integration | 361-pair loop with key set, invariants and the distribution counts; new plain object per call |
    | AC-12 | P1 | unit + integration | namespace exports and `typeof`; `.length === 2`; a third argument is ignored; stdout/stderr write count 0 (restored in `finally`) |
    
QA verdicts (each must name every AC of its card — dl qa refuses otherwise):
    - T-01: AC-1: AC-1 RATING_SCALE test; AC-2: AC-2 frozen test; AC-3: AC-3 notchChange tests (table, 361 pairs, no -0); AC-4: AC-4 trim/case tests; AC-5: AC-5 invalid-input tests; AC-6: AC-6 downgrade table; AC-7: AC-7 upgrade/unc
    - T-02: AC-9: AC-9 downgrade/boundary/number tests; AC-10: upgrade, negative counts, Object.is r->r tests; AC-11: contrast, 361-pair 190/18/153, source review tests; AC-4: case/whitespace tests; AC-5: invalid table and notchChan
    - T-03: AC-1: notch-f1 'AC-1 (F-1): scale order at the BBB-/BB+ boundary' + blob check; AC-2: both suites 20/27 pass, 0 fail; AC-3: notch-f1 'AC-3 (F-1): every adjacent step...'; AC-6: notch-f1 'AC-6 (F-1): downgrade rows across
decided NFR items: NFR-security, NFR-compliance
- ✅ the report gives every decided NFR item a result: NFR-security PASS, NFR-compliance PASS
- ✅ the plan says how each is checked (## Non-functional requirements)

## B4 · the blind review

settings.review.blind: risk
- ✅ T-01 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
- ✅ T-02 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
- ✅ T-03 (top P0): reviewed blind 1 time(s) — findings 0: intended 0, defect 0
blind agent runs: 3

## 0.18 · inputs only when the work needs them

- ✅ DEL-inputs: no input asked for by default (a .env file is never needed unless the work reads it)
- ✅ …and the human was not asked for a .env file or a key

## F23 · a finding after the start goes through the Lead and the BA (fault injected, disclosed)

injection: injected at 50dcb5e2dfc29f635f1ec97858e642e1a5062d19 on job/JOB-20261020-0647-notch-calculator-and-country-rat, after Merge T-01: Rating scale, notchChange and notchCalculator (REQ-06-02) in src/ratings/notch.mjs
- ✅ Michael opened a fix (dl fix open)
fixes: [{"id":"F-1","from":"merge-check","state":"added","cards":["T-03"],"finding":"After 'dl integrate T-01' the job branch head is 50dcb5e 'refactor: tidy the rating scale' (author e2e, 07:06:44), a mer"}]
- ✅ …and added it from the Lead's cards with the BA's specs (dl fix add)
- ✅ fix card(s) on the board: T-03
- ✅ T-03: the Lead's card (out/fix-…/cards.json) and the BA's spec (specs/T-03.md)
- ✅ the Lead was asked in MODE: FIX (transcripts: 5)
- ✅ the BA was asked for card specs (transcripts: 8)
    2026-10-20T07:06:45Z	merge-check	T-01 FAIL (repo suite)
    2026-10-20T07:07:22Z	fix-open	F-1 (merge-check): After 'dl integrate T-01' the job branch head is 50dcb5e 'refactor: tidy the rating scale' (author e2e, 07:06:44), a merge commit that changes src/ratings/notch.mjs: RATING_SCALE entries 'BBB-' and 'BB+' are swapped (BBB-,BB+ -> BB+,BBB-). The card branch (8a1309d, QA 455aef7) had the correct C1 scale and passed gate and QA. On the job branch the merged-suite log gates/T-01-merged-070645.log fails AC-1, AC-2, AC-3, AC-4, AC-6, AC-7 (QA integration tests). No hook in .git/hooks or core.hooksPath explains it; source of that commit unknown. Fix: restore the C1 scale order in src/ratings/notch.mjs on the job branch.
    2026-10-20T07:11:41Z	fix-add	F-1 → T-03
    2026-10-20T07:16:25Z	merge-check	T-03 PASS (repo suite)
    2026-10-20T07:21:35Z	merge-check	T-02 PASS (repo suite)
    2026-10-20T07:21:42Z	verify-all	PASS
    2026-10-20T07:22:31Z	verify-all	PASS

## result

cost: $7.73  ·  artifacts: <work>
**43 passed, 1 failed**
