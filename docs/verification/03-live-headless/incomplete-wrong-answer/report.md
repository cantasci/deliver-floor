# Live E2E — scenario `incomplete`

Request: `examples/watchlist-poc/JOB-incomplete.md`  ·  started 2026-10-03T22:02:22Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-incomplete.md

- ✅ Michael opened the job JOB-20261003-2202-rating-notch-calculator-and-coun

## 3 · the gap: Michael must stop and ask — not assume

- ✅ phase awaiting_clarification (stopped before planning)
- ✅ QUESTIONS.md asks about the unspecified sign of notches
- ✅ no card was cut before the answer
- ✅ no code was written before the answer

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261003-2202-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    For an upgrade, what is notchCalculator(previous, current).notches: signed like notchChange (A- -> A+ gives -2) or an absolute count with the sign carried only by `direction` (A- -> A+ gives 2)? Downgrades (BBB+ -> BB+ = 3) and unchanged (0) are the same under both.
    
    - A: signed, identical to notchChange (positive = downgrade, negative = upgrade); `direction` is redundant but explicit. Example: notchCalculator('A-','A+') -> { notches: -2, direction: 'upgrade', wl: 0 }
    - B: absolute magnitude (always >= 0); the sign is only in `direction`. This matches the REQ-06-02 wording '2 notch downgrade' (count + direction). Example: notchCalculator('A-','A+') -> { notches: 2, direction: 'upgrade', wl: 0 }
    
    _Why it matters:_ Public contract that other POC parts import and render ('Displayed', C8). Choosing wrong changes the observable value for every upgrade and breaks consumers or their tests. The upgrade acceptance criteria and test data for REQ-06-02 cannot be written until this is answered.

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261003-2202-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    For an upgrade, what is notchCalculator(previous, current).notches: signed like notchChange (A- -> A+ gives -2) or an absolute count with the sign carried only by `direction` (A- -> A+ gives 2)? Downgrades (BBB+ -> BB+ = 3) and unchanged (0) are the same under both.
    
    - A: signed, identical to notchChange (positive = downgrade, negative = upgrade); `direction` is redundant but explicit. Example: notchCalculator('A-','A+') -> { notches: -2, direction: 'upgrade', wl: 0 }
    - B: absolute magnitude (always >= 0); the sign is only in `direction`. This matches the REQ-06-02 wording '2 notch downgrade' (count + direction). Example: notchCalculator('A-','A+') -> { notches: 2, direction: 'upgrade', wl: 0 }
    
    _Why it matters:_ Public contract that other POC parts import and render ('Displayed', C8). Choosing wrong changes the observable value for every upgrade and breaks consumers or their tests. The upgrade acceptance criteria and test data for REQ-06-02 cannot be written until this is answered.
- ✅ answered CON-interface — For an upgrade, what is notchCalculator(previous, current).notches: signed like notchChang
wall time: 5 min

## 5 · verify the whole flow on disk

- ❌ job reached done
- ❌ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 2 (implementation details, recorded with rationale)
- ✅ readiness review complete (no open item) with an architecture
readiness: 33 items — 22 decided, 11 n/a · architecture: library: watchlist-domain-lib [javascript+node]
- ✅ readiness frozen at planning and unchanged since
- ❌ no cards on the board
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | State |
| --- | --- | --- | --- | --- | --- | --- | --- |
- ❌ no QA test files on main
- ✅ role really ran: business-analyst
- ❌ no ecc:architect run in events.log
- ❌ no qa-tester run in events.log
- ❌ no dev agent run
- ❌ no reviewer run
- ✅ no tracker errors
- ❌ kanban view rendered
- ❌ report.md is the template
- ✅ no AI attribution in the delivered history (0 commits)
- ✅ the whole test suite passes on main
- ❌ hidden oracle FAILED (oracle.log)
✖ oracle/watchlist.oracle.test.mjs (63.765289ms)
✖ failing tests:
✖ oracle/watchlist.oracle.test.mjs (63.765289ms)

## result

cost: $1.44  ·  artifacts: /tmp/claude-0/e2e-hi/incomplete
**18 passed, 11 failed**
