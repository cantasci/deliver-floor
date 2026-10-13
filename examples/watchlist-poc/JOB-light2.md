Investment grade check — a small addition to the existing rating code

The rating scale lives in `src/ratings/notch.mjs`. Add one function to that file; nothing that exists changes.

## Requirement

- `isInvestmentGrade(rating)` → `true` for AAA down to BBB- (the first 10 steps of `RATING_SCALE`), `false` for BB+ down
  to CCC-.
- The rating is read exactly as `notchChange` reads it (trimmed, case-insensitive); anything else is rejected with the
  same RangeError.
- The existing exports and their behaviour stay as they are.

Plain Node ESM, no dependencies; tests with `node --test` under `test/`, like the existing ones.
