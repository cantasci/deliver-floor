# Live E2E — scenario `incomplete`

Request: `examples/watchlist-poc/JOB-incomplete.md`  ·  started 2026-10-03T22:12:01Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-incomplete.md

- ✅ Michael opened the job JOB-20261003-2212-notch-calculator-and-country-rat

## 3 · the gap: Michael must stop and ask — not assume

- ✅ phase awaiting_clarification (stopped before planning)
- ✅ QUESTIONS.md asks about the unspecified sign of notches
- ✅ no card was cut before the answer
- ✅ no code was written before the answer

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261003-2212-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-priority
    
    If both requirements cannot ship together, which one comes first?
    
    - Both Must: ship together as one slice
    - REQ-06-02 Must, REQ-03-12 Should (it depends on notchChange anyway)
    - REQ-03-12 Must, with only notchChange from notch.mjs; notchCalculator Should
    
    _Why it matters:_ Affects scope only if the job is cut short. The slice is small, so 'both Must' is likely.
    
    ## CON-interface
    
    What does notchCalculator(previous, current).notches contain for an upgrade: the absolute number of notches moved (>= 0, direction carries the sign), or the signed value identical to notchChange?
    
    - Absolute magnitude (>= 0): notchCalculator('BBB','A-') → { notches: 2, direction: 'upgrade', wl: 0 }; notchCalculator('BBB+','BB+') → { notches: 3, direction: 'downgrade', wl: 2 }
    - Signed, equal to notchChange: notchCalculator('BBB','A-') → { notches: -2, direction: 'upgrade', wl: 0 }; downgrade → notches: 3
    
    _Why it matters:_ Public contract imported and rendered by other POC parts (C8). Downgrades and unchanged are identical under both options; every upgrade case differs, so implementation, tests and later screens depend on the answer.
    
    ## CON-errors
    
    For non-string input (null, undefined, 42, {}), should the functions throw RangeError (literal C1: 'anything else') or TypeError?
    
    - RangeError for every invalid input, strings and non-strings alike
    - TypeError for non-string input, RangeError for strings not on the scale
    
    _Why it matters:_ Observable error contract; callers' catch logic and QA error-path tests depend on it. Either way, no value is returned for invalid input.
    
    ## X-missing-C5
    
    What did C5 say? Was it only the notches sign rule, or did it also carry another rule this slice must follow?
    
    - C5 was the notches sign rule only: answering CON-interface is enough
    - C5 was withdrawn on purpose: confirm no other rule is missing
    - C5 held another rule as well: please supply its text
    
    _Why it matters:_ A missing confirmed clarification could change observable behaviour beyond the notches sign.

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261003-2212-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-priority
    
    If both requirements cannot ship together, which one comes first?
    
    - Both Must: ship together as one slice
    - REQ-06-02 Must, REQ-03-12 Should (it depends on notchChange anyway)
    - REQ-03-12 Must, with only notchChange from notch.mjs; notchCalculator Should
    
    _Why it matters:_ Affects scope only if the job is cut short. The slice is small, so 'both Must' is likely.
    
    ## CON-interface
    
    What does notchCalculator(previous, current).notches contain for an upgrade: the absolute number of notches moved (>= 0, direction carries the sign), or the signed value identical to notchChange?
    
    - Absolute magnitude (>= 0): notchCalculator('BBB','A-') → { notches: 2, direction: 'upgrade', wl: 0 }; notchCalculator('BBB+','BB+') → { notches: 3, direction: 'downgrade', wl: 2 }
    - Signed, equal to notchChange: notchCalculator('BBB','A-') → { notches: -2, direction: 'upgrade', wl: 0 }; downgrade → notches: 3
    
    _Why it matters:_ Public contract imported and rendered by other POC parts (C8). Downgrades and unchanged are identical under both options; every upgrade case differs, so implementation, tests and later screens depend on the answer.
    
    ## CON-errors
    
    For non-string input (null, undefined, 42, {}), should the functions throw RangeError (literal C1: 'anything else') or TypeError?
    
    - RangeError for every invalid input, strings and non-strings alike
    - TypeError for non-string input, RangeError for strings not on the scale
    
    _Why it matters:_ Observable error contract; callers' catch logic and QA error-path tests depend on it. Either way, no value is returned for invalid input.
    
    ## X-missing-C5
    
    What did C5 say? Was it only the notches sign rule, or did it also carry another rule this slice must follow?
    
    - C5 was the notches sign rule only: answering CON-interface is enough
    - C5 was withdrawn on purpose: confirm no other rule is missing
    - C5 held another rule as well: please supply its text
    
    _Why it matters:_ A missing confirmed clarification could change observable behaviour beyond the notches sign.
- ❌ no prepared answer for PRD-priority — a real person must answer: If both requirements cannot ship together, which one comes first?
- ✅ answered CON-interface — What does notchCalculator(previous, current).notches contain for an upgrade: the absolute 
- ❌ no prepared answer for CON-errors — a real person must answer: For non-string input (null, undefined, 42, {}), should the functions throw RangeError (literal C1: 'anything else') or TypeError?
- ✅ answered X-missing-C5 — What did C5 say? Was it only the notches sign rule, or did it also carry another rule this

## 4.2 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261003-2212-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-priority
    
    If both requirements cannot ship together, which one comes first?
    
    - Both Must: ship together as one slice
    - REQ-06-02 Must, REQ-03-12 Should (it depends on notchChange anyway)
    - REQ-03-12 Must, with only notchChange from notch.mjs; notchCalculator Should
    
    _Why it matters:_ Affects scope only if the job is cut short. The slice is small, so 'both Must' is likely.
    
    ## CON-errors
    
    For non-string input (null, undefined, 42, {}), should the functions throw RangeError (literal C1: 'anything else') or TypeError?
    
    - RangeError for every invalid input, strings and non-strings alike
    - TypeError for non-string input, RangeError for strings not on the scale
    
    _Why it matters:_ Observable error contract; callers' catch logic and QA error-path tests depend on it. Either way, no value is returned for invalid input.
- ❌ no prepared answer for PRD-priority — a real person must answer: If both requirements cannot ship together, which one comes first?
- ❌ no prepared answer for CON-errors — a real person must answer: For non-string input (null, undefined, 42, {}), should the functions throw RangeError (literal C1: 'anything else') or TypeError?

## 4.3 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261003-2212-notch-calculator-and-country-rat
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-priority
    
    If both requirements cannot ship together, which one comes first?
    
    - Both Must: ship together as one slice
    - REQ-06-02 Must, REQ-03-12 Should (it depends on notchChange anyway)
    - REQ-03-12 Must, with only notchChange from notch.mjs; notchCalculator Should
    
    _Why it matters:_ Affects scope only if the job is cut short. The slice is small, so 'both Must' is likely.
    
    ## CON-errors
    
    For non-string input (null, undefined, 42, {}), should the functions throw RangeError (literal C1: 'anything else') or TypeError?
    
    - RangeError for every invalid input, strings and non-strings alike
    - TypeError for non-string input, RangeError for strings not on the scale
    
    _Why it matters:_ Observable error contract; callers' catch logic and QA error-path tests depend on it. Either way, no value is returned for invalid input.
- ❌ no prepared answer for PRD-priority — a real person must answer: If both requirements cannot ship together, which one comes first?
- ❌ no prepared answer for CON-errors — a real person must answer: For non-string input (null, undefined, 42, {}), should the functions throw RangeError (literal C1: 'anything else') or TypeError?
wall time: 4 min

## 5 · verify the whole flow on disk

- ❌ job reached done
- ❌ job shipped (local)
roles: ba, backend-lead, backend, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 4 (implementation details, recorded with rationale)
- ❌ readiness review complete (no open item) with an architecture
readiness: 33 items — 21 decided, 10 n/a · architecture: library: ratings-lib [javascript+node-esm], indicators-lib [javascript+node-esm]
- ❌ readiness frozen at planning and unchanged since
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
✖ oracle/watchlist.oracle.test.mjs (76.665002ms)
✖ failing tests:
✖ oracle/watchlist.oracle.test.mjs (76.665002ms)

## result

cost: $0.98  ·  artifacts: /tmp/claude-0/e2e-hi/incomplete
**17 passed, 19 failed**
