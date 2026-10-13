# Plan

> Produced by the Business Analyst (MODE LIGHT), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal
Add one pure function, `isInvestmentGrade(rating)`, to `src/ratings/notch.mjs`. It says whether a rating on the existing 19-step `RATING_SCALE` is investment grade (AAA down to BBB-) or not (BB+ down to CCC-). It reads the rating exactly as `notchChange` does and rejects anything else with the same `RangeError`. Nothing that exists changes behaviour.

## Scope
- A new named export `isInvestmentGrade(rating)` in `src/ratings/notch.mjs`: one argument, strict boolean.
- Input is read through the module's private `indexOf` helper (trimmed, case-insensitive).
- Invalid input throws the same `RangeError`, message `unknown rating: ${JSON.stringify(rating)}`.
- Dev unit tests in a new file `test/unit/ratings/investmentGrade.test.mjs`.
- QA integration tests in a new file `test/integration/ratings/investmentGrade.int.test.mjs`.
- One change to an existing test: the export-list assertion in `test/integration/ratings/notch.int.test.mjs` becomes `["RATING_SCALE", "isInvestmentGrade", "notchCalculator", "notchChange"]` (readiness PRD-conflicts (a)).

## Out of scope
- Any change to `RATING_SCALE`, `notchChange`, `notchCalculator` or the private `indexOf`.
- `src/indicators/*`; wiring the check into any indicator or WL calculation.
- Codes not on the scale (D, SD, NR, WD), other scales: rejected with RangeError, never classified.
- Any existing test other than the one export-list assertion.
- New npm dependencies.

## Acceptance criteria
- AC-1 [P1]: `isInvestmentGrade` returns `true` for AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB- (indices 0–9) and `false` for BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC- (indices 10–18); all 19 covered, result strictly boolean.
- AC-2 [P1]: boundary — `isInvestmentGrade("BBB-") === true` and `isInvestmentGrade("BB+") === false` (also BBB true, BB false).
- AC-3 [P2]: padded / other-case input is read as `notchChange` reads it: `" bbb- "` → true, `"bb+"` → false, `"\tAaA\n"` → true, `"ccc-"` → false.
- AC-4 [P1]: input that does not normalise to a scale entry throws `RangeError` with message `unknown rating: <JSON.stringify(input)>` and never returns a value: `"ZZZ"`, `""`, `"   "`, `null`, `undefined`, `"D"`, `"NR"`, `"BBB -"`, `5`; same message as `notchChange(x, "A")`.
- AC-5 [P1]: existing behaviour unchanged — `Object.keys(notch).sort()` equals `["RATING_SCALE","isInvestmentGrade","notchCalculator","notchChange"]`; `RATING_SCALE` has 19 frozen entries; `notchChange("BBB+","BB+") === 3`; `notchCalculator("BBB+","BBB-")` equals `{notches:2,direction:"downgrade",wl:1}`; whole suite green with only the export-list assertion edited.

## Non-functional requirements
- NFR-security: input validation only. Input is accepted only if it normalises to one entry of the closed 19-entry `RATING_SCALE`; anything else throws `RangeError`, never a `false` fallback. Pure function: no I/O, logging or secrets. Checked by the invalid-input tests of AC-4 (unit and integration) and by review that `notch.mjs` gains no I/O.
- NFR-privacy: not applicable (readiness) — the input is a rating code.

## Risks and assumptions
- "Read exactly as notchChange" means reusing the private `indexOf`, so its quirks carry over (e.g. `String()` coercion: `["AAA"]` is accepted). Accepted as parity, not asserted.
- "First 10 steps" means indices 0–9 of the current `RATING_SCALE`; tests list all 19 by name, so a reorder is caught.
- The export-list assertion fails until QA updates it; the dev's `verify` does not run it.

## Open questions
None.
