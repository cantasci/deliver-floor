# Live E2E — scenario `incomplete`

Request: `examples/watchlist-poc/JOB-incomplete.md`  ·  started 2026-10-04T17:31:34Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-incomplete.md

- ✅ Michael opened the job JOB-20261004-1732-notch-calculator-and-country-rat

## 3 · the gap: Michael must stop and ask — not assume

- ✅ phase awaiting_clarification (stopped before planning)
- ✅ QUESTIONS.md asks about the unspecified sign of notches
- ✅ no card was cut before the answer
- ✅ no code was written before the answer

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-1732-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    What is the sign and meaning of notchCalculator(previous, current).notches? The contract defines notchChange (positive = downgrade) but nothing defines `notches` (clarification C5 was removed). Deciding case: notchCalculator('BBB', 'A'), a 3-notch upgrade, returns notches = ?
    
    - A: signed, same as notchChange. 'BBB+'→'BB+' gives { notches: 3, direction: 'downgrade', wl: 2 }; 'BBB'→'A' gives { notches: -3, direction: 'upgrade', wl: 0 }
    - B: always the size of the change (>= 0); direction carries the sign. 'BBB'→'A' gives { notches: 3, direction: 'upgrade', wl: 0 }
    - C: another convention (e.g. positive = upgrade), stated by the business with one downgrade and one upgrade example
    
    _Why it matters:_ Public contract imported by other POC parts and rendered by the analyst screen (C8). Only upgrades differ between A and B (-3 vs 3). Specs and tests cannot be written until answered; changing later breaks importers.
    
    ## X-input-trim
    
    C1 says 'Input is trimmed' but not which characters. Which leading and trailing characters must be removed before a rating is matched?
    
    - A: all JavaScript whitespace and line terminators, as String.prototype.trim does (space, tab, CR, LF, NBSP U+00A0, other Unicode spaces, BOM). ' BBB+\t' and '\u00A0BBB+' are accepted
    - B: ASCII whitespace only (space, tab, CR, LF, FF, VT). '\u00A0BBB+' throws RangeError
    - C: the ASCII space U+0020 only. 'BBB+\t' throws RangeError
    
    _Why it matters:_ Decides which inputs return a value and which throw RangeError in all three functions; QA test data depends on it. 'BBB +' throws under every option.

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-1732-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    What is the sign and meaning of notchCalculator(previous, current).notches? The contract defines notchChange (positive = downgrade) but nothing defines `notches` (clarification C5 was removed). Deciding case: notchCalculator('BBB', 'A'), a 3-notch upgrade, returns notches = ?
    
    - A: signed, same as notchChange. 'BBB+'→'BB+' gives { notches: 3, direction: 'downgrade', wl: 2 }; 'BBB'→'A' gives { notches: -3, direction: 'upgrade', wl: 0 }
    - B: always the size of the change (>= 0); direction carries the sign. 'BBB'→'A' gives { notches: 3, direction: 'upgrade', wl: 0 }
    - C: another convention (e.g. positive = upgrade), stated by the business with one downgrade and one upgrade example
    
    _Why it matters:_ Public contract imported by other POC parts and rendered by the analyst screen (C8). Only upgrades differ between A and B (-3 vs 3). Specs and tests cannot be written until answered; changing later breaks importers.
    
    ## X-input-trim
    
    C1 says 'Input is trimmed' but not which characters. Which leading and trailing characters must be removed before a rating is matched?
    
    - A: all JavaScript whitespace and line terminators, as String.prototype.trim does (space, tab, CR, LF, NBSP U+00A0, other Unicode spaces, BOM). ' BBB+\t' and '\u00A0BBB+' are accepted
    - B: ASCII whitespace only (space, tab, CR, LF, FF, VT). '\u00A0BBB+' throws RangeError
    - C: the ASCII space U+0020 only. 'BBB+\t' throws RangeError
    
    _Why it matters:_ Decides which inputs return a value and which throw RangeError in all three functions; QA test data depends on it. 'BBB +' throws under every option.
    (R2) answering CON-interface on purpose with an unrelated answer: C8 stands: 'displayed' is met by the returned { notches, direction, wl }; the POC screens 
- ✅ answered CON-interface — What is the sign and meaning of notchCalculator(previous, current).notches? The contract d
- ✅ answered X-input-trim — C1 says 'Input is trimmed' but not which characters. Which leading and trailing characters

## 4.2 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-1732-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    What is the sign and meaning of notchCalculator(previous, current).notches? The contract defines notchChange (positive = downgrade) but nothing defines `notches` (clarification C5 was removed). Deciding case: notchCalculator('BBB', 'A'), a 3-notch upgrade, returns notches = ? (Asked again: the recorded answer did not answer it — The answer is about C8 (no UI/CLI output) and does not say what notches means: signed like notchChange, or always the size of the change? Deciding case notchCalculator('BBB','A') -> notches = ?)
    
    - A: signed, same as notchChange. 'BBB+'→'BB+' gives { notches: 3, direction: 'downgrade', wl: 2 }; 'BBB'→'A' gives { notches: -3, direction: 'upgrade', wl: 0 }
    - B: always the size of the change (>= 0); direction carries the sign. 'BBB'→'A' gives { notches: 3, direction: 'upgrade', wl: 0 }
    - C: another convention (e.g. positive = upgrade), stated by the business with one downgrade and one upgrade example
    
    _Why it matters:_ Public contract imported by other POC parts and rendered by the analyst screen (C8). Only upgrades differ between A and B (-3 vs 3). Specs and tests cannot be written until answered; changing later breaks importers.
- ✅ answered CON-interface — What is the sign and meaning of notchCalculator(previous, current).notches? The contract d
wall time: 21 min

## 5 · verify the whole flow on disk

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer, docs
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 3 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 30 items — 22 decided, 8 n/a · architecture: library: watchlist-domain-lib [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Rating scale, notchChange and notchCalculator in src/ratings/notch.mjs (with unit tests and JSDoc) | watchlist-domain-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
| T-02 Indicator 12 countryRatingChangeWl in src/indicators/countryRating.mjs, built on notchChange (with unit tests and JSDoc) | watchlist-domain-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | merged |
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
- ✅ no AI attribution in the delivered history (7 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (5 checks, watchlist.oracle.test.mjs)

## R2 · Michael does not build on an answer that does not answer its question

- ✅ CON-interface was asked again after the unrelated answer (2 answers recorded)
- ✅ Michael put CON-interface back to the human (dl reopen): CON-interface: The answer is about C8 (no UI/CLI output) and does not say what notches means: signed
- ✅ the frozen answer for CON-interface is the right one: notchCalculator(...).notches is signed exactly like notchChange: downgrade posit

## result

cost: $5.37  ·  artifacts: /tmp/claude-0/e2e-r2b/incomplete
**35 passed, 0 failed**
