=== T-01 ===

# T-01: Implement notchChange function and RATING_SCALE export

## User story

As an indicator (part 11, 12, or 13 of the Watchlist POC), I want a pure function `notchChange(previous, current)` that calculates the signed notch distance between two credit ratings, so that I can determine rating movement and trigger appropriate risk controls.

## Traces to

- REQ-06-02 (Rating notch change)
- Clarifications C1–C4 (from the JOB request)
- Plan ACs: AC-1 through AC-26 and AC-7b

## Acceptance criteria

- **AC-1 (REQ-06-02):** Given previous rating "BBB+" and current rating "BB+", when `notchChange("BBB+", "BB+")` is called, then it returns 3 (downgrade = positive).
- **AC-2 (REQ-06-02):** Given previous rating "BB+" and current rating "BBB+", when `notchChange("BB+", "BBB+")` is called, then it returns -3 (upgrade = negative).
- **AC-3 (REQ-06-02):** Given previous rating "A" and current rating "A", when `notchChange("A", "A")` is called, then it returns 0 (unchanged).
- **AC-4 (REQ-06-02, C1):** Given the rating scale (best to worst: AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-), when `RATING_SCALE` is exported from `src/ratings/notch.mjs`, then it is an array of these 19 ratings in order (index 0 = AAA, index 18 = CCC-).
- **AC-5 (REQ-06-02, C1):** Given previous rating "  AAA  " (with leading/trailing whitespace), when `notchChange("  AAA  ", "CCC-")` is called, then it trims to "AAA" and returns 18 (index 18 - index 0).
- **AC-6 (REQ-06-02, C1):** Given previous rating "aaa" (lowercase), when `notchChange("aaa", "ccc-")` is called, then it normalizes to uppercase and returns 18 (index 18 - index 0).
- **AC-7 (REQ-06-02, C1):** Given mixed-case ratings "bBb+" and "Bb+", when `notchChange("bBb+", "Bb+")` is called, then it case-normalizes both (BBB+ at index 7 and BB+ at index 10) and returns 3 (index 10 - index 7).
- **AC-7b (REQ-06-02, C1):** Given ratings with trim and case "  bbb+ " and " BB+  ", when `notchChange("  bbb+ ", " BB+  ")` is called, then it trims and case-normalizes both (BBB+ at index 7 and BB+ at index 10) and returns 3.
- **AC-8 (REQ-06-02, C3):** Given boundary ratings AAA (best, index 0) and CCC- (worst, index 18), when `notchChange("AAA", "CCC-")` is called, then it returns 18 (maximum downgrade distance).
- **AC-9 (REQ-06-02, C3):** Given boundary ratings CCC- (worst, index 18) and AAA (best, index 0), when `notchChange("CCC-", "AAA")` is called, then it returns -18 (maximum upgrade distance).
- **AC-10 (REQ-06-02, C3):** Given the same rating in both positions for each of the 19 ratings (AAA, AA+, ..., CCC-), when `notchChange(rating, rating)` is called for each, then it returns 0.
- **AC-11 (REQ-06-02, C2):** Given previous rating as an empty string "", when `notchChange("", "A")` is called, then it throws a RangeError.
- **AC-12 (REQ-06-02, C2):** Given previous rating as an unknown string "XYZ", when `notchChange("XYZ", "A")` is called, then it throws a RangeError.
- **AC-13 (REQ-06-02, C2):** Given previous rating as a whitespace-only string "   ", when `notchChange("   ", "A")` is called, then it trims (resulting in empty string) and throws a RangeError.
- **AC-14 (REQ-06-02, C2):** Given previous rating as a non-string number 123, when `notchChange(123, "A")` is called, then it throws a RangeError.
- **AC-15 (REQ-06-02, C2):** Given previous rating as a String object `new String('A')`, when `notchChange(new String('A'), "A")` is called, then it throws a RangeError (String object has typeof 'object', not 'string').
- **AC-16 (REQ-06-02, C2):** Given previous rating as null, when `notchChange(null, "A")` is called, then it throws a RangeError.
- **AC-17 (REQ-06-02, C2):** Given previous rating as undefined, when `notchChange(undefined, "A")` is called, then it throws a RangeError.
- **AC-18 (REQ-06-02, C2):** Given current rating as an empty string "", when `notchChange("A", "")` is called, then it throws a RangeError.
- **AC-19 (REQ-06-02, C2):** Given current rating as an unknown string "XYZ", when `notchChange("A", "XYZ")` is called, then it throws a RangeError.
- **AC-20 (REQ-06-02, C2):** Given current rating as a whitespace-only string "   ", when `notchChange("A", "   ")` is called, then it trims (resulting in empty string) and throws a RangeError.
- **AC-21 (REQ-06-02, C2):** Given current rating as a non-string number 123, when `notchChange("A", 123)` is called, then it throws a RangeError.
- **AC-22 (REQ-06-02, C2):** Given current rating as a String object `new String('B')`, when `notchChange("A", new String('B'))` is called, then it throws a RangeError.
- **AC-23 (REQ-06-02, C2):** Given current rating as null, when `notchChange("A", null)` is called, then it throws a RangeError.
- **AC-24 (REQ-06-02, C2):** Given current rating as undefined, when `notchChange("A", undefined)` is called, then it throws a RangeError.
- **AC-25 (REQ-06-02, C1):** Given all 19 valid ratings as the previous parameter and "A" (index 5) as current, when `notchChange(previous, "A")` is called for each rating, then it returns the correct notch distance per the test data table below (formula: index(current) − index(previous) = 5 − index(previous)).
- **AC-26 (REQ-06-02, C1):** Given "A" (index 5) as the previous parameter and all 19 valid ratings as current, when `notchChange("A", current)` is called for each rating, then it returns the correct notch distance per the test data table below (formula: index(current) − index(previous) = index(current) − 5), which is the negative of the corresponding AC-25 entry.

## Edge cases

- **Type checking:** Both `previous` and `current` must be primitive strings (typeof x === 'string'). Reject any non-string type including numbers, String objects, null, undefined, and booleans with RangeError.
- **Trim behavior:** Whitespace-only strings ("   ", "\t\n") trim to empty string, which is invalid and throws RangeError.
- **Case normalization:** Input strings are normalized with `.toUpperCase()` before validation. Mixed-case inputs like "bBb+" or "aaa" are normalized to "BBB+" or "AAA".
- **Unknown ratings:** Any string not in RATING_SCALE after trim and case normalization (e.g., "XYZ", "B++", "AAA ") throws RangeError.
- **Scale boundaries:** Index 0 (AAA, best) to Index 18 (CCC-, worst). Functions correctly at both extremes (AAA→CCC- = +18, CCC-→AAA = -18).
- **Unchanged values:** notchChange(rating, rating) returns 0 for all 19 ratings without error.
- **Error messages:** RangeError messages are not specified; any descriptive text is acceptable (e.g., "Invalid rating: 'XYZ'", "Rating must be a string").

## Test data

### Rating Scale and Indices

| Index | Rating |
|-------|--------|
| 0     | AAA    |
| 1     | AA+    |
| 2     | AA     |
| 3     | AA-    |
| 4     | A+     |
| 5     | A      |
| 6     | A-     |
| 7     | BBB+   |
| 8     | BBB    |
| 9     | BBB-   |
| 10    | BB+    |
| 11    | BB     |
| 12    | BB-    |
| 13    | B+     |
| 14    | B      |
| 15    | B-     |
| 16    | CCC+   |
| 17    | CCC    |
| 18    | CCC-   |

### AC-25 Test Table: notchChange(previous, "A") for all previous ratings

(Expected result = index("A") − index(previous) = 5 − index(previous))

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

### AC-26 Test Table: notchChange("A", current) for all current ratings

(Expected result = index(current) − index("A") = index(current) − 5)

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

### Core Functionality Test Examples

| previous | current | expected result | test name             |
|----------|---------|-----------------|------------------------|
| BBB+     | BB+     | 3               | AC-1: downgrade       |
| BB+      | BBB+    | -3              | AC-2: upgrade         |
| A        | A       | 0               | AC-3: unchanged       |
| AAA      | CCC-    | 18              | AC-8: max downgrade   |
| CCC-     | AAA     | -18             | AC-9: max upgrade     |

### Input Normalization Test Examples

| previous      | current | expected result | description |
|---------------|---------|-----------------|-------------|
| "  AAA  "     | "CCC-"  | 18              | AC-5: trim previous |
| "aaa"         | "ccc-"  | 18              | AC-6: lowercase to uppercase |
| "bBb+"        | "Bb+"   | 3               | AC-7: mixed case |
| "  bbb+ "     | " BB+  "| 3               | AC-7b: trim and case |

### Invalid Input Test Examples

| previous | current | expected behavior | test names |
|----------|---------|-------------------|------------|
| ""       | "A"     | throws RangeError | AC-11 |
| "XYZ"    | "A"     | throws RangeError | AC-12 |
| "   "    | "A"     | throws RangeError | AC-13 |
| 123      | "A"     | throws RangeError | AC-14 |
| new String('A') | "A" | throws RangeError | AC-15 |
| null     | "A"     | throws RangeError | AC-16 |
| undefined | "A"    | throws RangeError | AC-17 |
| "A"      | ""      | throws RangeError | AC-18 |
| "A"      | "XYZ"   | throws RangeError | AC-19 |
| "A"      | "   "   | throws RangeError | AC-20 |
| "A"      | 123     | throws RangeError | AC-21 |
| "A"      | new String('B') | throws RangeError | AC-22 |
| "A"      | null    | throws RangeError | AC-23 |
| "A"      | undefined | throws RangeError | AC-24 |

## Out of scope for this card

- User interface, CLI, or printed output (C4)
- Banking regulation or internal policy constraints (C2)
- Performance optimization beyond O(1) lookup
- Logging, metrics, or observability
- Database or external system integration
- Backward compatibility (new code)
- Changes to existing indicators or other parts of the POC
- Documentation or changelog updates (JSDoc comments are dev conventions, not required)
