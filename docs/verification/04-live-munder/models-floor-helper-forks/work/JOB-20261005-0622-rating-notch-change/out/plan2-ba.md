# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Implement a notch change calculator that computes the signed number of steps between two credit ratings on the 19-step scale (AAA to CCC-), supporting indicators 11, 12, and 13 in the Watchlist POC.

## Scope

- `notchChange(previous, current)` function: pure calculation from two trimmed, case-insensitive rating strings to a signed integer (downgrade positive, upgrade negative, unchanged 0)
- `RATING_SCALE` export: array of the 19 ratings in order (best to worst)
- Input validation: reject unknown ratings, empty strings, whitespace-only strings, non-strings (including String objects), null, and undefined with RangeError
- Location: `src/ratings/notch.mjs` (ESM module)
- Testing: `node:test` unit tests in `test/ratings/notch.test.mjs`

## Out of scope

- User interface, CLI, or printed output (C4)
- Banking regulation or internal policy constraints (C2)
- Performance optimization beyond O(1) lookup
- Logging, metrics, or observability
- Database or external system integration
- Backward compatibility (new code)

## Acceptance criteria

<!-- Each one must be testable. Cards reference these ids. -->

- **AC-1 (REQ-06-02):** Given previous rating "BBB+" and current rating "BB+", when `notchChange("BBB+", "BB+")` is called, then it returns 3 (downgrade = positive).
- **AC-2 (REQ-06-02):** Given previous rating "BB+" and current rating "BBB+", when `notchChange("BB+", "BBB+")` is called, then it returns -3 (upgrade = negative).
- **AC-3 (REQ-06-02):** Given previous rating "A" and current rating "A", when `notchChange("A", "A")` is called, then it returns 0 (unchanged).
- **AC-4 (REQ-06-02, C1):** Given the rating scale (best to worst: AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-), when `RATING_SCALE` is exported, then it is an array of these 19 ratings in order.
- **AC-5 (REQ-06-02, C1):** Given previous rating "  AAA  " (with leading/trailing whitespace), when `notchChange("  AAA  ", "CCC-")` is called, then it trims to "AAA" and returns 18 (AAA → CCC- = 18 notches down).
- **AC-6 (REQ-06-02, C1):** Given previous rating "aaa" (lowercase), when `notchChange("aaa", "ccc-")` is called, then it normalizes to uppercase and returns 18 (AAA → CCC- = 18 notches down).
- **AC-7 (REQ-06-02, C1):** Given mixed-case ratings "bBb+" and "Bb+", when `notchChange("bBb+", "Bb+")` is called, then it case-normalizes both (BBB+ → BB+) and returns 3 (index 10 - index 7).
- **AC-7b (REQ-06-02, C1):** Given ratings with trim and case "  bbb+ " and " BB+  ", when `notchChange("  bbb+ ", " BB+  ")` is called, then it trims and case-normalizes both (BBB+ → BB+) and returns 3.
- **AC-8 (REQ-06-02, C3):** Given boundary ratings AAA (best, index 0) and CCC- (worst, index 18), when `notchChange("AAA", "CCC-")` is called, then it returns 18 (maximum downgrade distance).
- **AC-9 (REQ-06-02, C3):** Given boundary ratings CCC- (worst, index 18) and AAA (best, index 0), when `notchChange("CCC-", "AAA")` is called, then it returns -18 (maximum upgrade distance).
- **AC-10 (REQ-06-02, C3):** Given the same rating in both positions for each of the 19 ratings (AAA, AA+, ..., CCC-), when `notchChange(rating, rating)` is called for each, then it returns 0.
- **AC-11 (REQ-06-02, C2):** Given previous rating as an empty string "", when `notchChange("", "A")` is called, then it throws a RangeError.
- **AC-12 (REQ-06-02, C2):** Given previous rating as an unknown string "XYZ", when `notchChange("XYZ", "A")` is called, then it throws a RangeError.
- **AC-13 (REQ-06-02, C2):** Given previous rating as a whitespace-only string "   ", when `notchChange("   ", "A")` is called (after trimming, this becomes empty), then it throws a RangeError.
- **AC-14 (REQ-06-02, C2):** Given previous rating as a non-string number 123, when `notchChange(123, "A")` is called, then it throws a RangeError.
- **AC-15 (REQ-06-02, C2):** Given previous rating as a String object `new String('A')`, when `notchChange(new String('A'), "A")` is called, then it throws a RangeError (String object is not a primitive string).
- **AC-16 (REQ-06-02, C2):** Given previous rating as null, when `notchChange(null, "A")` is called, then it throws a RangeError.
- **AC-17 (REQ-06-02, C2):** Given previous rating as undefined, when `notchChange(undefined, "A")` is called, then it throws a RangeError.
- **AC-18 (REQ-06-02, C2):** Given current rating as an empty string "", when `notchChange("A", "")` is called, then it throws a RangeError.
- **AC-19 (REQ-06-02, C2):** Given current rating as an unknown string "XYZ", when `notchChange("A", "XYZ")` is called, then it throws a RangeError.
- **AC-20 (REQ-06-02, C2):** Given current rating as a whitespace-only string "   ", when `notchChange("A", "   ")` is called (after trimming, this becomes empty), then it throws a RangeError.
- **AC-21 (REQ-06-02, C2):** Given current rating as a non-string number 123, when `notchChange("A", 123)` is called, then it throws a RangeError.
- **AC-22 (REQ-06-02, C2):** Given current rating as a String object `new String('B')`, when `notchChange("A", new String('B'))` is called, then it throws a RangeError.
- **AC-23 (REQ-06-02, C2):** Given current rating as null, when `notchChange("A", null)` is called, then it throws a RangeError.
- **AC-24 (REQ-06-02, C2):** Given current rating as undefined, when `notchChange("A", undefined)` is called, then it throws a RangeError.
- **AC-25 (REQ-06-02, C1):** Given all 19 valid ratings for the previous position, when `notchChange(previous, "A")` is called for each, then each returns the correct notch distance per the table below (result = index("A") − index(previous) = 5 − index(previous)):

| previous | index | expected result |
|----------|-------|-----------------|
| AAA      | 0     | 5               |
| AA+      | 1     | 4               |
| AA       | 2     | 3               |
| AA-      | 3     | 2               |
| A+       | 4     | 1               |
| A        | 5     | 0               |
| A-       | 6     | -1              |
| BBB+     | 7     | -2              |
| BBB      | 8     | -3              |
| BBB-     | 9     | -4              |
| BB+      | 10    | -5              |
| BB       | 11    | -6              |
| BB-      | 12    | -7              |
| B+       | 13    | -8              |
| B        | 14    | -9              |
| B-       | 15    | -10             |
| CCC+     | 16    | -11             |
| CCC      | 17    | -12             |
| CCC-     | 18    | -13             |

- **AC-26 (REQ-06-02, C1):** Given all 19 valid ratings for the current position, when `notchChange("A", current)` is called for each, then each returns the correct notch distance per the table below (result = index(current) − index("A") = index(current) − 5), which is the negative of the corresponding AC-25 entry:

| current  | index | expected result |
|----------|-------|-----------------|
| AAA      | 0     | -5              |
| AA+      | 1     | -4              |
| AA       | 2     | -3              |
| AA-      | 3     | -2              |
| A+       | 4     | -1              |
| A        | 5     | 0               |
| A-       | 6     | 1               |
| BBB+     | 7     | 2               |
| BBB      | 8     | 3               |
| BBB-     | 9     | 4               |
| BB+      | 10    | 5               |
| BB       | 11    | 6               |
| BB-      | 12    | 7               |
| B+       | 13    | 8               |
| B        | 14    | 9               |
| B-       | 15    | 10              |
| CCC+     | 16    | 11              |
| CCC      | 17    | 12              |
| CCC-     | 18    | 13              |

## Risks and assumptions

- **Assumption: Synchronous lookup.** The function uses simple array indexing (indexOf or similar) for O(1) lookup. No async operations or external calls.
- **Assumption: Input trimming and case normalization.** Trim is applied with `String.prototype.trim()`, case normalization with `.toUpperCase()` per C1.
- **Risk (low): Boundary confusion.** Downgrade (lower rating = higher index) is positive; upgrade (higher rating = lower index) is negative. Implementation must ensure correct sign.
- **Assumption: Error type.** All invalid inputs raise RangeError (per C2). Error message text is not specified and may be any string.

## Open questions

<!-- Questions whose answers would change the scope. Asked to the human at plan approval. -->

(None. Readiness phase resolved all scope-affecting questions. Clarifications C1–C4 are complete and consistent.)
