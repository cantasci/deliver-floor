# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Implement the notch change calculation (REQ-06-02, part) that computes the rating change between two credit ratings on the Watchlist POC. The function will enable Indicators 11, 12, 13 and the notch calculator components to determine whether a credit rating has upgraded, downgraded, or remained unchanged. Success is measured by correct calculation of notch differences with the signed convention: downgrade positive, upgrade negative, unchanged zero.

## Scope

- Implement `notchChange(previous, current)` pure function in `src/ratings/notch.mjs`
- Export `RATING_SCALE` constant array containing all 19 valid ratings (AAA through CCC-, ordered best to worst)
- Input validation: trim whitespace, handle case-insensitivity, reject invalid ratings with RangeError
- Return signed integer: positive for downgrade, negative for upgrade, zero for no change
- Unit test coverage with node:test and node:assert/strict
- No dependencies; plain Node 18+ ESM (`.mjs`)

## Out of scope

- User-facing UI, CLI, or printed output (C4)
- Integration with Indicators 11, 12, 13 or other POC modules (only exported for import)
- Database storage or persistence
- External API calls or network integration
- Documentation, changelog, or runbook updates
- Performance tuning or load optimization

## Acceptance criteria

<!-- Each one must be testable. Cards reference these ids. -->

- **AC-1 (REQ-06-02, C1):** `RATING_SCALE` is exported as an array containing all 19 credit ratings in order from best (index 0) to worst (index 18): `['AAA', 'AA+', 'AA', 'AA-', 'A+', 'A', 'A-', 'BBB+', 'BBB', 'BBB-', 'BB+', 'BB', 'BB-', 'B+', 'B', 'B-', 'CCC+', 'CCC', 'CCC-']`. Each rating appears exactly once.

- **AC-2 (REQ-06-02, C2, C3):** Given two valid ratings from `RATING_SCALE`, when `notchChange(previous, current)` is called, then it returns an integer equal to (current index - previous index). Example: `notchChange('BBB+', 'BB+')` returns `3` (BB+ at index 10 minus BBB+ at index 7 = 3).

- **AC-3 (REQ-06-02, C3):** Given a downgrade (worse rating, higher index), when `notchChange(previous, current)` is called, then the result is positive. Example: `notchChange('BBB+', 'BB+')` returns positive `3`.

- **AC-4 (REQ-06-02, C3):** Given an upgrade (better rating, lower index), when `notchChange(previous, current)` is called, then the result is negative. Example: `notchChange('BB+', 'BBB+')` returns negative `-3`.

- **AC-5 (REQ-06-02, C3):** Given the same rating for both parameters, when `notchChange(previous, current)` is called, then the result is `0`. Example: `notchChange('A', 'A')` returns `0`.

- **AC-6 (REQ-06-02, C1):** Given input with leading or trailing whitespace, when `notchChange(previous, current)` is called, then the input is trimmed using `String.prototype.trim()` before processing. Example: `notchChange('  BBB+  ', 'BB+')` returns `3`.

- **AC-7 (REQ-06-02, C1):** Given input with different letter case, when `notchChange(previous, current)` is called, then the input is compared case-insensitively. Example: `notchChange('bbb+', 'bb+')` returns `3` (same as `notchChange('BBB+', 'BB+')`).

- **AC-8 (REQ-06-02, C2):** Given a rating string not in `RATING_SCALE` (after trim and case normalization), when `notchChange(previous, current)` is called, then it throws a `RangeError`. Example: `notchChange('XYZ', 'BBB+')` throws `RangeError`.

- **AC-9 (REQ-06-02, C2):** Given an empty string (even after trim), when `notchChange(previous, current)` is called, then it throws a `RangeError`. Example: `notchChange('', 'BBB+')` throws `RangeError`.

- **AC-10 (REQ-06-02, C2):** Given a non-string primitive (number, boolean, null, undefined, symbol), when `notchChange(previous, current)` is called, then it throws a `RangeError`. Example: `notchChange(123, 'BBB+')` throws `RangeError`; `notchChange(undefined, 'BBB+')` throws `RangeError`.

- **AC-11 (REQ-06-02, C2):** Given a String object (e.g., `new String('A')`), when `notchChange(previous, current)` is called, then it throws a `RangeError` (String objects are non-string). Example: `notchChange(new String('A'), 'BBB+')` throws `RangeError`.

## Risks and assumptions

**Assumptions:**
- Node.js 18+ with support for `node:test` and `node:assert/strict` is available in the test environment.
- `String.prototype.trim()` behavior (removing leading/trailing whitespace per ECMAScript standard) is sufficient for input sanitization.
- No other components depend on this module during development; Indicators 11, 12, 13 will be implemented in subsequent jobs and will import this function.
- The 19-rating scale order is stable and won't change (order is part of the business contract).

**Risks:**
- **Scope creep:** Other POC modules may request additional features (e.g., multi-notch thresholds, category definitions). Mitigation: Changes beyond REQ-06-02 part are out of scope and require a new job.
- **Integration timing:** Indicators 11, 12, 13 depend on this module being correct; integration bugs will surface only when those components are built. Mitigation: Comprehensive unit tests cover all ACs; integration testing is in the indicators' scope.

## Open questions

None. All decisions are covered in the readiness document and the job request (JOB-models-plain.md). No clarifications are needed to proceed with implementation.
