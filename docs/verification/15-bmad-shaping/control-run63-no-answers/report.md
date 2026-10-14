# Live E2E — scenario `shaped`

Request: `examples/watchlist-poc/JOB-shaped.md`  ·  started 2026-10-13T15:16:25Z

## 1 · setup: fresh HOME, ECC from GitHub, the kit, doctor, sandbox repo

✔ Successfully added marketplace: ecc (declared in user settings)
2 userConfig options not yet set — run /plugin configure ecc@ecc in Claude Code, or pass --config KEY=VALUE.
- ✅ ECC plugin installed (Version: 2.2.3)
- ✅ kit installed (scripts/install.sh --user)
upstream.engine = bmad; docs/POC_Requirements_v0.2_EN.md in the repo
- ✅ doctor: result: 27 ok, 6 warning(s), 0 problem(s)

## 2 · run: the only input is examples/watchlist-poc/JOB-shaped.md

- ✅ Michael opened the job JOB-20261013-2103-rating-notch-calculator-and-coun

## 4.1 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-2103-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-scope
    
    Which parts of REQ-03-12 and REQ-06-02 are in this delivery? The request says 'Build only these two requirements' and gives a contract of pure functions only. But REQ-03-12 also says 'Pre-filled from public source' and 'auto-filled value editable', which means a fetch (REQ-02-02) and an override (REQ-02-09). REQ-06-02 also says 'analyst selects … WL=1 displayed', which means a screen.
    
    - (recommended) Only the four contract exports (RATING_SCALE, notchChange, notchCalculator, countryRatingChangeWl) as pure functions. Out of scope: fetch/pre-fill, editing/override flagging, any UI.
    - Also fetch the current and 12-month-ago sovereign rating (REQ-02-02).
    - Also a notch-calculator screen or CLI for REQ-06-02.
    
    _Why it matters:_ Option 1 is one small library. Options 2 and 3 add integration, UI, error-fallback and override work.
    
    ## PRD-acceptance
    
    The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
    
    - (recommended) Business confirms X-scale, X-example, X-wl-rule and X-upgrade. The BA then derives the cases, e.g. AA → AA- = 1 → country WL 1; BBB+ → BBB- = 2 → country WL 2; BB → BBB = -2 upgrade → WL 0; A → A = 0 → WL 0.
    - Business supplies reference cases from the original Excel dropdown sheet (A4).
    
    _Why it matters:_ Without confirmed pairs, the tests would encode a guess about the scale and the example.
    
    ## PRD-conflicts
    
    Conflicts: (1) REQ-06-02's example counts BBB+ → BB+ as 2 notches, but the standard S&P/Fitch scale gives 3. (2) The example's '2 notch downgrade → WL=1' fits REQ-03-13 (2 → WL1, 3+ → WL2) but not REQ-03-12 (1 → WL1, 2+ → WL2). (3) With the standard count of 3, every rule gives WL=2, never the example's WL=1.
    
    - See X-example and X-wl-rule.
    
    _Why it matters:_ Decides the notch count and WL for the reference example. POC A4 forbids interpretation changes.
    
    ## CON-interface
    
    Not given: the contents and notation of RATING_SCALE (X-scale); whether notchCalculator.notches is signed or absolute (X-notches-sign); which thresholds notchCalculator.wl uses (X-wl-rule); the WL for upgrades (X-upgrade); input normalisation (X-input-normalisation).
    
    - Settle the X-* items. Freezing RATING_SCALE is an implementation detail Michael decides.
    
    _Why it matters:_ These shape the public contract other POC parts import.
    
    ## CON-errors
    
    What must notchChange, notchCalculator and countryRatingChangeWl do when a rating is not on RATING_SCALE (e.g. 'XYZ'), is empty, or is not a string (null, undefined, 3)?
    
    - (recommended) Throw a RangeError (unknown rating) or TypeError (not a string) whose message names the offending value.
    - Return null (and wl null).
    - Return NaN.
    
    _Why it matters:_ Silently returning 0 or WL 0 would hide a bad rating and under-report risk.
    
    ## ARC-style
    
    Confirm the architecture style. The request places the code in two modules of the one package but never names a style.
    
    - As in the draft: one library component, path '.', suite npm test.
    - Modular monolith: areas src/ratings and src/indicators as separate modules.
    
    _Why it matters:_ Low for this slice.
    
    ## ARC-components
    
    Confirm the components. The draft lists one library 'repo' (javascript, path '.', suite npm test).
    
    - As in the draft: one library component.
    - Two library components (ratings, indicators) in one package.
    
    _Why it matters:_ Card scoping and the reviewer only.
    
    ## ARC-ui
    
    REQ-06-02 says 'analyst selects previous rating and current rating' and 'WL=1 displayed', but the contract has functions only. Is a UI part of this delivery?
    
    - (recommended) None. Library only.
    - A small CLI (node script).
    - A web page.
    
    _Why it matters:_ A UI adds a component, a stack choice and e2e tests.
    
    ## ARC-data
    
    Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
    
    - (recommended) None. Pure functions only; callers pass both ratings in.
    - A store for historical sovereign ratings.
    
    _Why it matters:_ A store adds a component, a schema and I/O tests.
    
    ## ARC-integration
    
    REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
    
    - (recommended) None. The fetch belongs to a later slice; this job receives ratings as arguments.
    - Scrape the current and 12-month-prior sovereign rating now.
    
    _Why it matters:_ An integration adds I/O outside the pure modules and failure handling.
    
    ## X-scale
    
    Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
    
    - (recommended) S&P/Fitch long-term scale AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC- (19 entries).
    - The same, extended with CC, C, D (and RD/SD).
    - Also accept Moody's notation mapped onto the same positions.
    
    _Why it matters:_ Fixes every notch count and whether a default is valid input.
    
    ## X-example
    
    REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
    
    - (a) The scale is standard and the example is wrong: BBB+ → BB+ = 3 notches; WL follows X-wl-rule.
    - (b) The example meant a 2-notch pair, e.g. BBB+ → BBB-, giving WL=1 under REQ-03-13 thresholds.
    - (c) Notches count only the ratings strictly between the two. Not recommended: AA → AA- would be 0.
    
    _Why it matters:_ The only concrete example; becomes a P0/P1 test case.
    
    ## X-wl-rule
    
    notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
    
    - (a) REQ-03-13 thresholds (2 → 1, 3+ → 2, 0–1 → 0); fits the example.
    - (b) REQ-03-12 thresholds (1 → 1, 2+ → 2).
    - (c) Add an indicator argument; changes the stated contract.
    
    _Why it matters:_ Different WL for 1- and 2-notch downgrades.
    
    ## X-upgrade
    
    What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
    
    - (recommended) Upgrade or no change → WL 0. Only downgrades score.
    - Use the absolute notch count.
    
    _Why it matters:_ Option 2 would raise a WL when the country improves.
    
    ## X-notches-sign
    
    In notchCalculator's { notches, direction, wl }, is `notches` signed (BB → BBB gives -3) or absolute (3)?
    
    - (recommended) Absolute value; the sign is carried by direction.
    - Signed, equal to notchChange.
    
    _Why it matters:_ A public field other POC parts read.
    
    ## X-input-normalisation
    
    Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?
    
    - (recommended) Exact match on RATING_SCALE strings only; anything else is invalid.
    - Trim and upper-case before matching.
    - Also strip outlook suffixes and map U+2212 to '-'.
    
    _Why it matters:_ Decides which values are accepted.
- ✅ answered PRD-scope — Which parts of REQ-03-12 and REQ-06-02 are in this delivery? The request says 'Build only 
- ❌ no prepared answer for PRD-acceptance — a real person must answer: The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
- ✅ answered PRD-conflicts — Conflicts: (1) REQ-06-02's example counts BBB+ → BB+ as 2 notches, but the standard S&P/Fi
- ✅ answered CON-interface — Not given: the contents and notation of RATING_SCALE (X-scale); whether notchCalculator.no
- ✅ answered CON-errors — What must notchChange, notchCalculator and countryRatingChangeWl do when a rating is not o
- ✅ answered ARC-style — Confirm the architecture style. The request places the code in two modules of the one pack
- ✅ answered ARC-components — Confirm the components. The draft lists one library 'repo' (javascript, path '.', suite np
- ✅ answered ARC-ui — REQ-06-02 says 'analyst selects previous rating and current rating' and 'WL=1 displayed', 
- ❌ no prepared answer for ARC-data — a real person must answer: Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
- ❌ no prepared answer for ARC-integration — a real person must answer: REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
- ❌ no prepared answer for X-scale — a real person must answer: Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
- ❌ no prepared answer for X-example — a real person must answer: REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
- ❌ no prepared answer for X-wl-rule — a real person must answer: notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
- ❌ no prepared answer for X-upgrade — a real person must answer: What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
- ✅ answered X-notches-sign — In notchCalculator's { notches, direction, wl }, is `notches` signed (BB → BBB gives -3) o
- ❌ no prepared answer for X-input-normalisation — a real person must answer: Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?

## 4.2 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-2103-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-acceptance
    
    The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
    
    - (recommended) Business confirms X-scale, X-example, X-wl-rule and X-upgrade. The BA then derives the cases, e.g. AA → AA- = 1 → country WL 1; BBB+ → BBB- = 2 → country WL 2; BB → BBB = -2 upgrade → WL 0; A → A = 0 → WL 0.
    - Business supplies reference cases from the original Excel dropdown sheet (A4).
    
    _Why it matters:_ Without confirmed pairs, the tests would encode a guess about the scale and the example.
    
    ## ARC-data
    
    Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
    
    - (recommended) None. Pure functions only; callers pass both ratings in.
    - A store for historical sovereign ratings.
    
    _Why it matters:_ A store adds a component, a schema and I/O tests.
    
    ## ARC-integration
    
    REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
    
    - (recommended) None. The fetch belongs to a later slice; this job receives ratings as arguments.
    - Scrape the current and 12-month-prior sovereign rating now.
    
    _Why it matters:_ An integration adds I/O outside the pure modules and failure handling.
    
    ## X-scale
    
    Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
    
    - (recommended) S&P/Fitch long-term scale AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC- (19 entries).
    - The same, extended with CC, C, D (and RD/SD).
    - Also accept Moody's notation mapped onto the same positions.
    
    _Why it matters:_ Fixes every notch count and whether a default is valid input.
    
    ## X-example
    
    REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
    
    - (a) The scale is standard and the example is wrong: BBB+ → BB+ = 3 notches; WL follows X-wl-rule.
    - (b) The example meant a 2-notch pair, e.g. BBB+ → BBB-, giving WL=1 under REQ-03-13 thresholds.
    - (c) Notches count only the ratings strictly between the two. Not recommended: AA → AA- would be 0.
    
    _Why it matters:_ The only concrete example; becomes a P0/P1 test case.
    
    ## X-wl-rule
    
    notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
    
    - (a) REQ-03-13 thresholds (2 → 1, 3+ → 2, 0–1 → 0); fits the example.
    - (b) REQ-03-12 thresholds (1 → 1, 2+ → 2).
    - (c) Add an indicator argument; changes the stated contract.
    
    _Why it matters:_ Different WL for 1- and 2-notch downgrades.
    
    ## X-upgrade
    
    What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
    
    - (recommended) Upgrade or no change → WL 0. Only downgrades score.
    - Use the absolute notch count.
    
    _Why it matters:_ Option 2 would raise a WL when the country improves.
    
    ## X-input-normalisation
    
    Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?
    
    - (recommended) Exact match on RATING_SCALE strings only; anything else is invalid.
    - Trim and upper-case before matching.
    - Also strip outlook suffixes and map U+2212 to '-'.
    
    _Why it matters:_ Decides which values are accepted.
- ❌ no prepared answer for PRD-acceptance — a real person must answer: The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
- ❌ no prepared answer for ARC-data — a real person must answer: Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
- ❌ no prepared answer for ARC-integration — a real person must answer: REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
- ❌ no prepared answer for X-scale — a real person must answer: Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
- ❌ no prepared answer for X-example — a real person must answer: REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
- ❌ no prepared answer for X-wl-rule — a real person must answer: notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
- ❌ no prepared answer for X-upgrade — a real person must answer: What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
- ❌ no prepared answer for X-input-normalisation — a real person must answer: Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?

## 4.3 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-2103-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-acceptance
    
    The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
    
    - (recommended) Business confirms X-scale, X-example, X-wl-rule and X-upgrade. The BA then derives the cases, e.g. AA → AA- = 1 → country WL 1; BBB+ → BBB- = 2 → country WL 2; BB → BBB = -2 upgrade → WL 0; A → A = 0 → WL 0.
    - Business supplies reference cases from the original Excel dropdown sheet (A4).
    
    _Why it matters:_ Without confirmed pairs, the tests would encode a guess about the scale and the example.
    
    ## ARC-data
    
    Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
    
    - (recommended) None. Pure functions only; callers pass both ratings in.
    - A store for historical sovereign ratings.
    
    _Why it matters:_ A store adds a component, a schema and I/O tests.
    
    ## ARC-integration
    
    REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
    
    - (recommended) None. The fetch belongs to a later slice; this job receives ratings as arguments.
    - Scrape the current and 12-month-prior sovereign rating now.
    
    _Why it matters:_ An integration adds I/O outside the pure modules and failure handling.
    
    ## X-scale
    
    Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
    
    - (recommended) S&P/Fitch long-term scale AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC- (19 entries).
    - The same, extended with CC, C, D (and RD/SD).
    - Also accept Moody's notation mapped onto the same positions.
    
    _Why it matters:_ Fixes every notch count and whether a default is valid input.
    
    ## X-example
    
    REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
    
    - (a) The scale is standard and the example is wrong: BBB+ → BB+ = 3 notches; WL follows X-wl-rule.
    - (b) The example meant a 2-notch pair, e.g. BBB+ → BBB-, giving WL=1 under REQ-03-13 thresholds.
    - (c) Notches count only the ratings strictly between the two. Not recommended: AA → AA- would be 0.
    
    _Why it matters:_ The only concrete example; becomes a P0/P1 test case.
    
    ## X-wl-rule
    
    notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
    
    - (a) REQ-03-13 thresholds (2 → 1, 3+ → 2, 0–1 → 0); fits the example.
    - (b) REQ-03-12 thresholds (1 → 1, 2+ → 2).
    - (c) Add an indicator argument; changes the stated contract.
    
    _Why it matters:_ Different WL for 1- and 2-notch downgrades.
    
    ## X-upgrade
    
    What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
    
    - (recommended) Upgrade or no change → WL 0. Only downgrades score.
    - Use the absolute notch count.
    
    _Why it matters:_ Option 2 would raise a WL when the country improves.
    
    ## X-input-normalisation
    
    Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?
    
    - (recommended) Exact match on RATING_SCALE strings only; anything else is invalid.
    - Trim and upper-case before matching.
    - Also strip outlook suffixes and map U+2212 to '-'.
    
    _Why it matters:_ Decides which values are accepted.
- ❌ no prepared answer for PRD-acceptance — a real person must answer: The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
- ❌ no prepared answer for ARC-data — a real person must answer: Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
- ❌ no prepared answer for ARC-integration — a real person must answer: REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
- ❌ no prepared answer for X-scale — a real person must answer: Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
- ❌ no prepared answer for X-example — a real person must answer: REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
- ❌ no prepared answer for X-wl-rule — a real person must answer: notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
- ❌ no prepared answer for X-upgrade — a real person must answer: What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
- ❌ no prepared answer for X-input-normalisation — a real person must answer: Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?

## 4.4 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-2103-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-acceptance
    
    The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
    
    - (recommended) Business confirms X-scale, X-example, X-wl-rule and X-upgrade. The BA then derives the cases, e.g. AA → AA- = 1 → country WL 1; BBB+ → BBB- = 2 → country WL 2; BB → BBB = -2 upgrade → WL 0; A → A = 0 → WL 0.
    - Business supplies reference cases from the original Excel dropdown sheet (A4).
    
    _Why it matters:_ Without confirmed pairs, the tests would encode a guess about the scale and the example.
    
    ## ARC-data
    
    Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
    
    - (recommended) None. Pure functions only; callers pass both ratings in.
    - A store for historical sovereign ratings.
    
    _Why it matters:_ A store adds a component, a schema and I/O tests.
    
    ## ARC-integration
    
    REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
    
    - (recommended) None. The fetch belongs to a later slice; this job receives ratings as arguments.
    - Scrape the current and 12-month-prior sovereign rating now.
    
    _Why it matters:_ An integration adds I/O outside the pure modules and failure handling.
    
    ## X-scale
    
    Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
    
    - (recommended) S&P/Fitch long-term scale AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC- (19 entries).
    - The same, extended with CC, C, D (and RD/SD).
    - Also accept Moody's notation mapped onto the same positions.
    
    _Why it matters:_ Fixes every notch count and whether a default is valid input.
    
    ## X-example
    
    REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
    
    - (a) The scale is standard and the example is wrong: BBB+ → BB+ = 3 notches; WL follows X-wl-rule.
    - (b) The example meant a 2-notch pair, e.g. BBB+ → BBB-, giving WL=1 under REQ-03-13 thresholds.
    - (c) Notches count only the ratings strictly between the two. Not recommended: AA → AA- would be 0.
    
    _Why it matters:_ The only concrete example; becomes a P0/P1 test case.
    
    ## X-wl-rule
    
    notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
    
    - (a) REQ-03-13 thresholds (2 → 1, 3+ → 2, 0–1 → 0); fits the example.
    - (b) REQ-03-12 thresholds (1 → 1, 2+ → 2).
    - (c) Add an indicator argument; changes the stated contract.
    
    _Why it matters:_ Different WL for 1- and 2-notch downgrades.
    
    ## X-upgrade
    
    What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
    
    - (recommended) Upgrade or no change → WL 0. Only downgrades score.
    - Use the absolute notch count.
    
    _Why it matters:_ Option 2 would raise a WL when the country improves.
    
    ## X-input-normalisation
    
    Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?
    
    - (recommended) Exact match on RATING_SCALE strings only; anything else is invalid.
    - Trim and upper-case before matching.
    - Also strip outlook suffixes and map U+2212 to '-'.
    
    _Why it matters:_ Decides which values are accepted.
- ❌ no prepared answer for PRD-acceptance — a real person must answer: The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
- ❌ no prepared answer for ARC-data — a real person must answer: Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
- ❌ no prepared answer for ARC-integration — a real person must answer: REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
- ❌ no prepared answer for X-scale — a real person must answer: Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
- ❌ no prepared answer for X-example — a real person must answer: REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
- ❌ no prepared answer for X-wl-rule — a real person must answer: notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
- ❌ no prepared answer for X-upgrade — a real person must answer: What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
- ❌ no prepared answer for X-input-normalisation — a real person must answer: Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?

## 4.5 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-2103-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-acceptance
    
    The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
    
    - (recommended) Business confirms X-scale, X-example, X-wl-rule and X-upgrade. The BA then derives the cases, e.g. AA → AA- = 1 → country WL 1; BBB+ → BBB- = 2 → country WL 2; BB → BBB = -2 upgrade → WL 0; A → A = 0 → WL 0.
    - Business supplies reference cases from the original Excel dropdown sheet (A4).
    
    _Why it matters:_ Without confirmed pairs, the tests would encode a guess about the scale and the example.
    
    ## ARC-data
    
    Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
    
    - (recommended) None. Pure functions only; callers pass both ratings in.
    - A store for historical sovereign ratings.
    
    _Why it matters:_ A store adds a component, a schema and I/O tests.
    
    ## ARC-integration
    
    REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
    
    - (recommended) None. The fetch belongs to a later slice; this job receives ratings as arguments.
    - Scrape the current and 12-month-prior sovereign rating now.
    
    _Why it matters:_ An integration adds I/O outside the pure modules and failure handling.
    
    ## X-scale
    
    Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
    
    - (recommended) S&P/Fitch long-term scale AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC- (19 entries).
    - The same, extended with CC, C, D (and RD/SD).
    - Also accept Moody's notation mapped onto the same positions.
    
    _Why it matters:_ Fixes every notch count and whether a default is valid input.
    
    ## X-example
    
    REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
    
    - (a) The scale is standard and the example is wrong: BBB+ → BB+ = 3 notches; WL follows X-wl-rule.
    - (b) The example meant a 2-notch pair, e.g. BBB+ → BBB-, giving WL=1 under REQ-03-13 thresholds.
    - (c) Notches count only the ratings strictly between the two. Not recommended: AA → AA- would be 0.
    
    _Why it matters:_ The only concrete example; becomes a P0/P1 test case.
    
    ## X-wl-rule
    
    notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
    
    - (a) REQ-03-13 thresholds (2 → 1, 3+ → 2, 0–1 → 0); fits the example.
    - (b) REQ-03-12 thresholds (1 → 1, 2+ → 2).
    - (c) Add an indicator argument; changes the stated contract.
    
    _Why it matters:_ Different WL for 1- and 2-notch downgrades.
    
    ## X-upgrade
    
    What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
    
    - (recommended) Upgrade or no change → WL 0. Only downgrades score.
    - Use the absolute notch count.
    
    _Why it matters:_ Option 2 would raise a WL when the country improves.
    
    ## X-input-normalisation
    
    Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?
    
    - (recommended) Exact match on RATING_SCALE strings only; anything else is invalid.
    - Trim and upper-case before matching.
    - Also strip outlook suffixes and map U+2212 to '-'.
    
    _Why it matters:_ Decides which values are accepted.
- ❌ no prepared answer for PRD-acceptance — a real person must answer: The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
- ❌ no prepared answer for ARC-data — a real person must answer: Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
- ❌ no prepared answer for ARC-integration — a real person must answer: REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
- ❌ no prepared answer for X-scale — a real person must answer: Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
- ❌ no prepared answer for X-example — a real person must answer: REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
- ❌ no prepared answer for X-wl-rule — a real person must answer: notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
- ❌ no prepared answer for X-upgrade — a real person must answer: What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
- ❌ no prepared answer for X-input-normalisation — a real person must answer: Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?

## 4.6 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-2103-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-acceptance
    
    The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
    
    - (recommended) Business confirms X-scale, X-example, X-wl-rule and X-upgrade. The BA then derives the cases, e.g. AA → AA- = 1 → country WL 1; BBB+ → BBB- = 2 → country WL 2; BB → BBB = -2 upgrade → WL 0; A → A = 0 → WL 0.
    - Business supplies reference cases from the original Excel dropdown sheet (A4).
    
    _Why it matters:_ Without confirmed pairs, the tests would encode a guess about the scale and the example.
    
    ## ARC-data
    
    Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
    
    - (recommended) None. Pure functions only; callers pass both ratings in.
    - A store for historical sovereign ratings.
    
    _Why it matters:_ A store adds a component, a schema and I/O tests.
    
    ## ARC-integration
    
    REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
    
    - (recommended) None. The fetch belongs to a later slice; this job receives ratings as arguments.
    - Scrape the current and 12-month-prior sovereign rating now.
    
    _Why it matters:_ An integration adds I/O outside the pure modules and failure handling.
    
    ## X-scale
    
    Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
    
    - (recommended) S&P/Fitch long-term scale AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC- (19 entries).
    - The same, extended with CC, C, D (and RD/SD).
    - Also accept Moody's notation mapped onto the same positions.
    
    _Why it matters:_ Fixes every notch count and whether a default is valid input.
    
    ## X-example
    
    REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
    
    - (a) The scale is standard and the example is wrong: BBB+ → BB+ = 3 notches; WL follows X-wl-rule.
    - (b) The example meant a 2-notch pair, e.g. BBB+ → BBB-, giving WL=1 under REQ-03-13 thresholds.
    - (c) Notches count only the ratings strictly between the two. Not recommended: AA → AA- would be 0.
    
    _Why it matters:_ The only concrete example; becomes a P0/P1 test case.
    
    ## X-wl-rule
    
    notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
    
    - (a) REQ-03-13 thresholds (2 → 1, 3+ → 2, 0–1 → 0); fits the example.
    - (b) REQ-03-12 thresholds (1 → 1, 2+ → 2).
    - (c) Add an indicator argument; changes the stated contract.
    
    _Why it matters:_ Different WL for 1- and 2-notch downgrades.
    
    ## X-upgrade
    
    What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
    
    - (recommended) Upgrade or no change → WL 0. Only downgrades score.
    - Use the absolute notch count.
    
    _Why it matters:_ Option 2 would raise a WL when the country improves.
    
    ## X-input-normalisation
    
    Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?
    
    - (recommended) Exact match on RATING_SCALE strings only; anything else is invalid.
    - Trim and upper-case before matching.
    - Also strip outlook suffixes and map U+2212 to '-'.
    
    _Why it matters:_ Decides which values are accepted.
- ❌ no prepared answer for PRD-acceptance — a real person must answer: The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
- ❌ no prepared answer for ARC-data — a real person must answer: Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
- ❌ no prepared answer for ARC-integration — a real person must answer: REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
- ❌ no prepared answer for X-scale — a real person must answer: Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
- ❌ no prepared answer for X-example — a real person must answer: REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
- ❌ no prepared answer for X-wl-rule — a real person must answer: notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
- ❌ no prepared answer for X-upgrade — a real person must answer: What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
- ❌ no prepared answer for X-input-normalisation — a real person must answer: Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?

## 4.7 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-2103-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-acceptance
    
    The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
    
    - (recommended) Business confirms X-scale, X-example, X-wl-rule and X-upgrade. The BA then derives the cases, e.g. AA → AA- = 1 → country WL 1; BBB+ → BBB- = 2 → country WL 2; BB → BBB = -2 upgrade → WL 0; A → A = 0 → WL 0.
    - Business supplies reference cases from the original Excel dropdown sheet (A4).
    
    _Why it matters:_ Without confirmed pairs, the tests would encode a guess about the scale and the example.
    
    ## ARC-data
    
    Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
    
    - (recommended) None. Pure functions only; callers pass both ratings in.
    - A store for historical sovereign ratings.
    
    _Why it matters:_ A store adds a component, a schema and I/O tests.
    
    ## ARC-integration
    
    REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
    
    - (recommended) None. The fetch belongs to a later slice; this job receives ratings as arguments.
    - Scrape the current and 12-month-prior sovereign rating now.
    
    _Why it matters:_ An integration adds I/O outside the pure modules and failure handling.
    
    ## X-scale
    
    Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
    
    - (recommended) S&P/Fitch long-term scale AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC- (19 entries).
    - The same, extended with CC, C, D (and RD/SD).
    - Also accept Moody's notation mapped onto the same positions.
    
    _Why it matters:_ Fixes every notch count and whether a default is valid input.
    
    ## X-example
    
    REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
    
    - (a) The scale is standard and the example is wrong: BBB+ → BB+ = 3 notches; WL follows X-wl-rule.
    - (b) The example meant a 2-notch pair, e.g. BBB+ → BBB-, giving WL=1 under REQ-03-13 thresholds.
    - (c) Notches count only the ratings strictly between the two. Not recommended: AA → AA- would be 0.
    
    _Why it matters:_ The only concrete example; becomes a P0/P1 test case.
    
    ## X-wl-rule
    
    notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
    
    - (a) REQ-03-13 thresholds (2 → 1, 3+ → 2, 0–1 → 0); fits the example.
    - (b) REQ-03-12 thresholds (1 → 1, 2+ → 2).
    - (c) Add an indicator argument; changes the stated contract.
    
    _Why it matters:_ Different WL for 1- and 2-notch downgrades.
    
    ## X-upgrade
    
    What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
    
    - (recommended) Upgrade or no change → WL 0. Only downgrades score.
    - Use the absolute notch count.
    
    _Why it matters:_ Option 2 would raise a WL when the country improves.
    
    ## X-input-normalisation
    
    Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?
    
    - (recommended) Exact match on RATING_SCALE strings only; anything else is invalid.
    - Trim and upper-case before matching.
    - Also strip outlook suffixes and map U+2212 to '-'.
    
    _Why it matters:_ Decides which values are accepted.
- ❌ no prepared answer for PRD-acceptance — a real person must answer: The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
- ❌ no prepared answer for ARC-data — a real person must answer: Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
- ❌ no prepared answer for ARC-integration — a real person must answer: REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
- ❌ no prepared answer for X-scale — a real person must answer: Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
- ❌ no prepared answer for X-example — a real person must answer: REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
- ❌ no prepared answer for X-wl-rule — a real person must answer: notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
- ❌ no prepared answer for X-upgrade — a real person must answer: What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
- ❌ no prepared answer for X-input-normalisation — a real person must answer: Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?

## 4.8 · Michael asked — the human answers each question (HUMAN_ANSWERS.json, recorded with dl clarify), the run resumes

note: the shaped request still raised question(s) — recorded below; answering them is the human's job
Open questions (QUESTIONS.md):
    # Questions before the work can start — JOB-20261013-2103-rating-notch-calculator-and-coun
    
    Answer each one in a terminal (or tell Michael):  dl clarify <id> "<answer>"
    
    ## PRD-acceptance
    
    The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
    
    - (recommended) Business confirms X-scale, X-example, X-wl-rule and X-upgrade. The BA then derives the cases, e.g. AA → AA- = 1 → country WL 1; BBB+ → BBB- = 2 → country WL 2; BB → BBB = -2 upgrade → WL 0; A → A = 0 → WL 0.
    - Business supplies reference cases from the original Excel dropdown sheet (A4).
    
    _Why it matters:_ Without confirmed pairs, the tests would encode a guess about the scale and the example.
    
    ## ARC-data
    
    Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
    
    - (recommended) None. Pure functions only; callers pass both ratings in.
    - A store for historical sovereign ratings.
    
    _Why it matters:_ A store adds a component, a schema and I/O tests.
    
    ## ARC-integration
    
    REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
    
    - (recommended) None. The fetch belongs to a later slice; this job receives ratings as arguments.
    - Scrape the current and 12-month-prior sovereign rating now.
    
    _Why it matters:_ An integration adds I/O outside the pure modules and failure handling.
    
    ## X-scale
    
    Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
    
    - (recommended) S&P/Fitch long-term scale AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC- (19 entries).
    - The same, extended with CC, C, D (and RD/SD).
    - Also accept Moody's notation mapped onto the same positions.
    
    _Why it matters:_ Fixes every notch count and whether a default is valid input.
    
    ## X-example
    
    REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
    
    - (a) The scale is standard and the example is wrong: BBB+ → BB+ = 3 notches; WL follows X-wl-rule.
    - (b) The example meant a 2-notch pair, e.g. BBB+ → BBB-, giving WL=1 under REQ-03-13 thresholds.
    - (c) Notches count only the ratings strictly between the two. Not recommended: AA → AA- would be 0.
    
    _Why it matters:_ The only concrete example; becomes a P0/P1 test case.
    
    ## X-wl-rule
    
    notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
    
    - (a) REQ-03-13 thresholds (2 → 1, 3+ → 2, 0–1 → 0); fits the example.
    - (b) REQ-03-12 thresholds (1 → 1, 2+ → 2).
    - (c) Add an indicator argument; changes the stated contract.
    
    _Why it matters:_ Different WL for 1- and 2-notch downgrades.
    
    ## X-upgrade
    
    What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
    
    - (recommended) Upgrade or no change → WL 0. Only downgrades score.
    - Use the absolute notch count.
    
    _Why it matters:_ Option 2 would raise a WL when the country improves.
    
    ## X-input-normalisation
    
    Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?
    
    - (recommended) Exact match on RATING_SCALE strings only; anything else is invalid.
    - Trim and upper-case before matching.
    - Also strip outlook suffixes and map U+2212 to '-'.
    
    _Why it matters:_ Decides which values are accepted.
- ❌ no prepared answer for PRD-acceptance — a real person must answer: The acceptance criteria give WL thresholds but no rating pairs for REQ-03-12. The one concrete example (REQ-06-02: BBB+ → BB+) contradicts the usual scale (see X-example). Which concrete rating pairs and expected outputs are the reference cases?
- ❌ no prepared answer for ARC-data — a real person must answer: Is anything stored, e.g. the 12-month-prior country rating or the analyst's edited value?
- ❌ no prepared answer for ARC-integration — a real person must answer: REQ-03-12 says 'Pre-filled from public source'. Is any external call part of this delivery?
- ❌ no prepared answer for X-scale — a real person must answer: Which ratings does RATING_SCALE contain, in which notation? Neither the request nor the POC doc defines it. The only hint is the Ind. 10 dropdown 'AAA → CCC-'.
- ❌ no prepared answer for X-example — a real person must answer: REQ-06-02's example 'BBB+ → BB+ = 2 notch downgrade → WL=1' does not match the standard scale: BBB+ → BBB → BBB- → BB+ is 3 notches, WL=2 under both rules. Which part is right?
- ❌ no prepared answer for X-wl-rule — a real person must answer: notchCalculator takes no indicator argument. Which thresholds produce its wl? REQ-03-12: 1 → WL1, 2+ → WL2. REQ-03-13: 2 → WL1, 3+ → WL2.
- ❌ no prepared answer for X-upgrade — a real person must answer: What WL do countryRatingChangeWl and notchCalculator give for an upgrade (BB → BBB) and for no change (A → A)?
- ❌ no prepared answer for X-input-normalisation — a real person must answer: Are inputs matched exactly or normalised (lower case, spaces, Unicode minus, outlook suffix)?
wall time: 231 min

## 5 · verify the whole flow on disk

- ❌ job reached done
- ❌ job shipped (local)
roles: ba, backend-lead, backend, qa×2, reviewer, blind, docs
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ role cards generated for every role
PM decisions: 1 (implementation details, recorded with rationale)
- ❌ readiness review complete (no open item) with an architecture
readiness: 35 items — 22 decided, 5 n/a · architecture: library: watchlist-poc [javascript+node]
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
- ✅ no AI attribution in the delivered history (1 commits)
- ✅ the whole test suite passes on main
- ❌ hidden oracle FAILED (oracle.log)
✖ oracle/watchlist.oracle.test.mjs (45.056542ms)
✖ failing tests:
✖ oracle/watchlist.oracle.test.mjs (45.056542ms)
- ✅ the job took 5.3 min (≤ 45; timeline.txt)

## B3 · risk-based test design and the NFR gate

- ✅ every AC of the plan has a priority: AC-1 P1
- ✅ every card spec has a ## Test design

Test design of null:
QA verdicts (each must name every AC of its card — dl qa refuses otherwise):
decided NFR items: NFR-security, NFR-compliance
- ❌ NFR rows in the report: NFR-security (decided: "No authentication, authorisation or secrets (single user). T") has no row in report.md's Non-functional requirements table
NFR-compliance (decided: "WL thresholds must match the original Excel dropdown sheet e") has no row in report.md's Non-functional requirements table
- ✅ the plan says how each is checked (## Non-functional requirements)

## B4 · the blind review

settings.review.blind: risk

## result

cost: $1.40  ·  artifacts: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/live-control/shaped
**23 passed, 78 failed**
