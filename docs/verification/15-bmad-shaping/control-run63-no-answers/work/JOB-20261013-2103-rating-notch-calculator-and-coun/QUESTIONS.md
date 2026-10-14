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
