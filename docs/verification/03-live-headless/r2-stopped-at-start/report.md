# Live E2E — scenario `incomplete`

Request: `examples/watchlist-poc/JOB-incomplete.md`  ·  started 2026-10-04T08:00:23Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

√ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
- ✅ doctor: result: 25 ok, 5 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-incomplete.md

- ✅ Michael opened the job JOB-20261004-0800-rating-notch-calculator-and-coun

## 3 · the gap: Michael must stop and ask — not assume

- ✅ phase awaiting_clarification (stopped before planning)
- ✅ QUESTIONS.md asks about the unspecified sign of notches
- ✅ no card was cut before the answer
- ✅ no code was written before the answer

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-0800-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    What sign does notchCalculator(previous, current).notches carry for an upgrade? The request fixes the sign only for notchChange ('positive = downgrade, negative = upgrade, 0 = unchanged'). For notchCalculator it says only `{ notches, direction, wl }`. C2 speaks of a '3-notch downgrade', which is a size plus a direction word. The clarification that settled this (C5) is missing. Downgrades (e.g. BBB+→BB+ = 3) and unchanged (0) come out the same either way; only upgrades differ.
    
    - A — signed, same as notchChange: notches = notchChange(previous, current); AA→AAA gives { notches: -1, direction: 'upgrade', wl: 0 }; BBB→BBB+ gives { notches: -1, ... }
    - B — unsigned size, direction carries the sign: notches = |notchChange|; AA→AAA gives { notches: 1, direction: 'upgrade', wl: 0 }
    
    _Why it matters:_ This is a public contract other POC parts import, and the POC screens will show this value as 'notch change' (C8). A shows '-1 upgrade'; B shows '1 upgrade'. Dev unit tests and QA expectations for every upgrade case depend on it. Changing it after other parts integrate breaks them.
    
    ## X-input-whitespace
    
    C1 says input is 'trimmed' but does not say which characters are trimmed. Which leading and trailing characters are removed before matching?
    
    - A — JavaScript String.prototype.trim(): all Unicode whitespace and line terminators (space, tab, \n, \r, NBSP U+00A0, U+2003 …). ' bbb+\n' and '\u00A0BBB+' are accepted.
    - B — ASCII space only (U+0020). '\tBBB+' and '\u00A0BBB+' throw RangeError.
    - C — ASCII whitespace only (space, \t, \n, \r, \f, \v). '\u00A0BBB+' throws RangeError.
    
    _Why it matters:_ Decides whether inputs pasted from a public source or spreadsheet (tabs, NBSP, newlines) are accepted or rejected with a RangeError. Observable behaviour of all three functions; QA test data depends on it. Inner whitespace ('BBB +') is rejected under every option.
    
    ## X-input-nonstring
    
    What happens when an argument is not a string (null, undefined, a number, an object, or a missing argument)? C1 says 'anything else is rejected with a RangeError', but its subject is text input that is trimmed and case-folded. A non-string cannot be trimmed, and JavaScript convention throws TypeError for a wrong type.
    
    - A — RangeError for every invalid input, including null, undefined, 123 and {} (literal reading of C1: one error type for consumers to catch)
    - B — TypeError for non-string input; RangeError only for strings that are not a C1 rating
    - C — String-coerce first (String(x)) and then validate, so null becomes 'null' and throws RangeError
    
    _Why it matters:_ The thrown error type is part of the public contract that callers catch. Consumers that check `instanceof RangeError` would miss a TypeError. Affects the tests of all three functions.

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-0800-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## CON-interface
    
    What sign does notchCalculator(previous, current).notches carry for an upgrade? The request fixes the sign only for notchChange ('positive = downgrade, negative = upgrade, 0 = unchanged'). For notchCalculator it says only `{ notches, direction, wl }`. C2 speaks of a '3-notch downgrade', which is a size plus a direction word. The clarification that settled this (C5) is missing. Downgrades (e.g. BBB+→BB+ = 3) and unchanged (0) come out the same either way; only upgrades differ.
    
    - A — signed, same as notchChange: notches = notchChange(previous, current); AA→AAA gives { notches: -1, direction: 'upgrade', wl: 0 }; BBB→BBB+ gives { notches: -1, ... }
    - B — unsigned size, direction carries the sign: notches = |notchChange|; AA→AAA gives { notches: 1, direction: 'upgrade', wl: 0 }
    
    _Why it matters:_ This is a public contract other POC parts import, and the POC screens will show this value as 'notch change' (C8). A shows '-1 upgrade'; B shows '1 upgrade'. Dev unit tests and QA expectations for every upgrade case depend on it. Changing it after other parts integrate breaks them.
    
    ## X-input-whitespace
    
    C1 says input is 'trimmed' but does not say which characters are trimmed. Which leading and trailing characters are removed before matching?
    
    - A — JavaScript String.prototype.trim(): all Unicode whitespace and line terminators (space, tab, \n, \r, NBSP U+00A0, U+2003 …). ' bbb+\n' and '\u00A0BBB+' are accepted.
    - B — ASCII space only (U+0020). '\tBBB+' and '\u00A0BBB+' throw RangeError.
    - C — ASCII whitespace only (space, \t, \n, \r, \f, \v). '\u00A0BBB+' throws RangeError.
    
    _Why it matters:_ Decides whether inputs pasted from a public source or spreadsheet (tabs, NBSP, newlines) are accepted or rejected with a RangeError. Observable behaviour of all three functions; QA test data depends on it. Inner whitespace ('BBB +') is rejected under every option.
    
    ## X-input-nonstring
    
    What happens when an argument is not a string (null, undefined, a number, an object, or a missing argument)? C1 says 'anything else is rejected with a RangeError', but its subject is text input that is trimmed and case-folded. A non-string cannot be trimmed, and JavaScript convention throws TypeError for a wrong type.
    
    - A — RangeError for every invalid input, including null, undefined, 123 and {} (literal reading of C1: one error type for consumers to catch)
    - B — TypeError for non-string input; RangeError only for strings that are not a C1 rating
    - C — String-coerce first (String(x)) and then validate, so null becomes 'null' and throws RangeError
    
    _Why it matters:_ The thrown error type is part of the public contract that callers catch. Consumers that check `instanceof RangeError` would miss a TypeError. Affects the tests of all three functions.
    (R2) answering CON-interface on purpose with an unrelated answer: C8 stands: 'displayed' is met by the returned { notches, direction, wl }; the POC screens 
- ✅ answered CON-interface — What sign does notchCalculator(previous, current).notches carry for an upgrade? The reques
- ❌ no prepared answer for X-input-whitespace — a real person must answer: C1 says input is 'trimmed' but does not say which characters are trimmed. Which leading and trailing characters are removed before matching?
- ✅ answered X-input-nonstring — What happens when an argument is not a string (null, undefined, a number, an object, or a 

## 4.2 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-0800-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## X-input-whitespace
    
    C1 says input is 'trimmed' but does not say which characters are trimmed. Which leading and trailing characters are removed before matching?
    
    - A — JavaScript String.prototype.trim(): all Unicode whitespace and line terminators (space, tab, \n, \r, NBSP U+00A0, U+2003 …). ' bbb+\n' and '\u00A0BBB+' are accepted.
    - B — ASCII space only (U+0020). '\tBBB+' and '\u00A0BBB+' throw RangeError.
    - C — ASCII whitespace only (space, \t, \n, \r, \f, \v). '\u00A0BBB+' throws RangeError.
    
    _Why it matters:_ Decides whether inputs pasted from a public source or spreadsheet (tabs, NBSP, newlines) are accepted or rejected with a RangeError. Observable behaviour of all three functions; QA test data depends on it. Inner whitespace ('BBB +') is rejected under every option.
- ❌ no prepared answer for X-input-whitespace — a real person must answer: C1 says input is 'trimmed' but does not say which characters are trimmed. Which leading and trailing characters are removed before matching?

## 4.3 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261004-0800-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## X-input-whitespace
    
    C1 says input is 'trimmed' but does not say which characters are trimmed. Which leading and trailing characters are removed before matching?
    
    - A — JavaScript String.prototype.trim(): all Unicode whitespace and line terminators (space, tab, \n, \r, NBSP U+00A0, U+2003 …). ' bbb+\n' and '\u00A0BBB+' are accepted.
    - B — ASCII space only (U+0020). '\tBBB+' and '\u00A0BBB+' throw RangeError.
    - C — ASCII whitespace only (space, \t, \n, \r, \f, \v). '\u00A0BBB+' throws RangeError.
    
    _Why it matters:_ Decides whether inputs pasted from a public source or spreadsheet (tabs, NBSP, newlines) are accepted or rejected with a RangeError. Observable behaviour of all three functions; QA test data depends on it. Inner whitespace ('BBB +') is rejected under every option.
- ❌ no prepared answer for X-input-whitespace — a real person must answer: C1 says input is 'trimmed' but does not say which characters are trimmed. Which leading and trailing characters are removed before matching?
wall time: 5 min

## 5 · verify the whole flow on disk

- ❌ job reached done
- ❌ job shipped (local)
roles: ba, qa, backend-lead, backend, reviewer, docs
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 3 (implementation details, recorded with rationale)
- ❌ readiness review complete (no open item) with an architecture
readiness: 36 items — 26 decided, 9 n/a · architecture: library: ratings-notch [javascript+node], indicators-country-rating [javascript+node]
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
✖ oracle/watchlist.oracle.test.mjs (62.415795ms)
✖ failing tests:
✖ oracle/watchlist.oracle.test.mjs (62.415795ms)

## R2 · Michael does not build on an answer that does not answer its question

- ❌ CON-interface was not asked again (1 answer(s) recorded)
- ❌ the unrelated answer was frozen: C8 stands: 'displayed' is met by the returned { notches, direction, wl }; the PO

## result

cost: $1.27  ·  artifacts: /tmp/claude-0/e2e-r2/incomplete
**17 passed, 18 failed**
