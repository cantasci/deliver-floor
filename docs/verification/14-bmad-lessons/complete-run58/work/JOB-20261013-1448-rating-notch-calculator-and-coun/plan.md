# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

This delivers two requirements of the Watchlist POC as pure Node ESM library functions that other parts of the POC will import:

1. **REQ-06-02, the notch calculator helper.** It takes a previous and a current rating and returns the signed notch change, the direction and the resulting Watchlist level (WL). The WL uses the Indicator 13 thresholds (C2, C3, C6).
2. **REQ-03-12, Indicator 12 (country rating change).** It returns WL 0, 1 or 2 from the notch change between the previous and current country rating (C3).

Success means every acceptance criterion below passes under `node --test`, and the full suite (`npm test` / `node --test`) passes on the job branch (PRD-goal, DEL-ci).

## Scope

- `src/ratings/notch.mjs`, with these named exports (Contract, CON-interface):
  - `RATING_SCALE`: the 19 ratings of C1, best first, frozen (X-scale-immutability).
  - `notchChange(previous, current)`: an integer equal to index(current) − index(previous). Positive is a downgrade, negative an upgrade, 0 is unchanged.
  - `notchCalculator(previous, current)`: returns `{ notches, direction, wl }`.
    - `notches` is signed exactly like `notchChange` (C5).
    - `direction` is one of `"downgrade" | "upgrade" | "unchanged"`.
    - `wl` is 0 for 1 notch or fewer, 1 for 2 notches and 2 for 3 or more notches (C2, C3, C6).
- `src/indicators/countryRating.mjs`, with the named export `countryRatingChangeWl(previous, current)`. It returns 0, 1 or 2: 1-notch downgrade → 1, 2 or more → 2, upgrade or unchanged → 0 (REQ-03-12, C3). It is built on `notchChange` (Contract).
- How input is handled, in all three functions:
  - Values are trimmed with `String.prototype.trim()` semantics and compared case-insensitively (C1, X-trim-whitespace).
  - Anything that is not on the scale throws a `RangeError` (C1, CON-errors).
  - The error message names the argument and the bad value, and `previous` is checked first (X-error-message).
- Unit tests in `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`, using `node:test` and `node:assert/strict` (TST-strategy).
- QA adds contract-level tests over the public imports.

## Out of scope

- Fetching or pre-filling ratings from a public source. The caller passes the ratings in (C4, ARC-integration).
- An override parameter, persistence of the edited value, or an audit trail. "Editable" is met because the caller passes whichever rating the analyst confirmed (C7, ARC-data, NFR-audit).
- Any UI, CLI, printed or logged output. "Displayed" is met by the returned object (C8, ARC-ui, NFR-observability).
- A separate Indicator 13 module, or an Indicator 13 public function. Only its thresholds are reused inside `notchCalculator` (PRD-scope).
- Any other indicator (Ind. 1–11) or requirement of the POC document.
- Ratings outside the C1 scale: `CC`, `C`, `D`, `SD`, `NR`, `WD`, outlooks, watch flags and suffixes such as `(sf)`. These are rejected, not supported (C1).
- New npm dependencies, a data store, an API or middleware, CI, lint or typecheck setup, and docs or changelog (ARC-deps, ARC-layer, DEL-ci, DEL-docs).

## Acceptance criteria

Scale indices used below (from C1, 0 = best): AAA 0, AA+ 1, AA 2, AA- 3, A+ 4, A 5, A- 6, BBB+ 7, BBB 8, BBB- 9, BB+ 10, BB 11, BB- 12, B+ 13, B 14, B- 15, CCC+ 16, CCC 17, CCC- 18.

- **AC-1 [P0] (C1, Contract `RATING_SCALE`).** Cost: a wrong or reordered scale shifts every notch count, so every WL is wrong with no workaround.
  - Given `import { RATING_SCALE } from "src/ratings/notch.mjs"`,
  - when it is read,
  - then it deep-strict-equals `["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"]`: length 19, `RATING_SCALE[0] === "AAA"`, `RATING_SCALE[18] === "CCC-"`, all upper-case with no whitespace.

- **AC-2 [P2] (X-scale-immutability).**
  - Given `RATING_SCALE`,
  - when the code checks `Object.isFrozen(RATING_SCALE)` and tries, in ESM strict mode, `RATING_SCALE.push("D")`, `RATING_SCALE[0] = "X"` and `RATING_SCALE.reverse()`,
  - then `Object.isFrozen` returns `true` and each mutation throws `TypeError`.
  - Afterwards the scale is unchanged and `notchChange("AAA","AA+")` still returns `1`.

- **AC-3 [P0] (REQ-06-02, REQ-03-12, Contract `notchChange`, C5).** Cost: a wrong magnitude or sign is the input to both WL rules, so the WL is wrong with no workaround.
  - Given two ratings on the scale,
  - when `notchChange(previous, current)` is called,
  - then it returns the integer index(current) − index(previous). `Number.isInteger(result)` is `true`, and for unchanged inputs `Object.is(result, 0)` is `true` (never `-0`).
  - Examples:
    - `("BBB+","BB+")` → `3`
    - `("BBB+","BBB-")` → `2`
    - `("BBB+","BBB")` → `1`
    - `("BBB","BBB")` → `0`
    - `("BB+","BBB+")` → `-3`
    - `("AAA","CCC-")` → `18`
    - `("CCC-","AAA")` → `-18`
    - `("AAA","AA+")` → `1`
    - `("CCC","CCC-")` → `1`

- **AC-4 [P1] (C1, X-trim-whitespace).** Cost: valid analyst input would be rejected or mis-matched. The workaround is that the caller normalises the input first.
  - Given input that differs from a scale value only in letter case or in leading/trailing whitespace of any kind (space, `\t`, `\n`, `\r`, NBSP ` `),
  - when it is passed to `notchChange`, `notchCalculator` or `countryRatingChangeWl` as either argument,
  - then it is treated as that scale value.
  - Examples:
    - `notchChange("bbb+","BB+")` → `3`
    - `notchChange("  BBB+\t","\nbb+ ")` → `3`
    - `notchChange(" Bbb- ","bbb-")` → `0`
    - `notchCalculator("aaa","ccc-")` → `{ notches: 18, direction: "downgrade", wl: 2 }`
    - `countryRatingChangeWl(" bbb+ ","BBB")` → `1`

- **AC-5 [P0] (C1, CON-errors, NFR-security).** Cost: an unrejected invalid rating (for example `indexOf` returning −1) gives a silent wrong notch count and WL, so the client is misrated.
  - Given an argument that is not on the scale after trim and case-folding,
  - when it is passed as `previous` or as `current` (the other argument valid, for example `"BBB"`) to each of `notchChange`, `notchCalculator` and `countryRatingChangeWl`,
  - then the call throws an error with `instanceof RangeError` true. It is never a `TypeError`, and nothing is returned.
  - Values that must be rejected:
    - `""`, `"   "`, `"\t\n"`
    - `"D"`, `"SD"`, `"NR"`, `"CC"`, `"C"`, `"AAA+"`, `"BBB--"`, `"B B B+"`, `"BBB +"`, `"BBB+ (sf)"`, `"7"`
    - `null`, `undefined`, `7`, `0`, `NaN`, `true`, `{}`
    - `["BBB+"]` and `new String("BBB+")`: these are not primitive strings, see A-1.
  - When both arguments are invalid (`notchChange("X","Y")`), the thrown `RangeError` message names the argument `previous` and the value `X`.
  - Tests assert only the error type; the message text is not contract (X-error-message).

- **AC-6 [P0] (REQ-06-02, C2, C6, C5).** Cost: wrong downgrade thresholds put a client on the wrong WL and to the wrong desk, the core credit-risk flow.
  - Given a downgrade,
  - when `notchCalculator(previous, current)` is called,
  - then it returns an object with exactly the keys `notches`, `direction` and `wl`, where:
    - `notches === notchChange(previous, current)`
    - `direction === "downgrade"`
    - `wl` is `0` for 1 notch, `1` for 2 notches and `2` for 3 or more.
  - Examples:
    - `("BBB+","BB+")` → `{ notches: 3, direction: "downgrade", wl: 2 }`. This is the corrected POC example, not 2 notches/WL 1 (C2).
    - `("BBB+","BBB-")` → `{ notches: 2, direction: "downgrade", wl: 1 }`
    - `("BBB+","BBB")` → `{ notches: 1, direction: "downgrade", wl: 0 }` (C6)
    - `("AAA","CCC-")` → `{ notches: 18, direction: "downgrade", wl: 2 }`. WL is capped at 2.
    - `("A","BBB+")` → `{ notches: 2, direction: "downgrade", wl: 1 }`

- **AC-7 [P1] (REQ-06-02, C3, C5).** Cost: a false WL on an upgrade or an unchanged rating flags a healthy client. The workaround is that the analyst sees `direction`.
  - Given an upgrade or an unchanged rating,
  - when `notchCalculator(previous, current)` is called,
  - then:
    - for an upgrade it returns `{ notches: <negative integer>, direction: "upgrade", wl: 0 }`
    - for an unchanged rating it returns `{ notches: 0, direction: "unchanged", wl: 0 }`, with `Object.is(notches, 0)`.
  - Examples:
    - `("BB+","BBB+")` → `{ notches: -3, direction: "upgrade", wl: 0 }`
    - `("BBB-","BBB+")` → `{ notches: -2, direction: "upgrade", wl: 0 }`
    - `("CCC-","AAA")` → `{ notches: -18, direction: "upgrade", wl: 0 }`
    - `("BBB","BBB")` → `{ notches: 0, direction: "unchanged", wl: 0 }`
    - `(" bbb ","BBB")` → `{ notches: 0, direction: "unchanged", wl: 0 }`

- **AC-8 [P0] (REQ-03-12, C6, Contract `countryRatingChangeWl`).** Cost: wrong Indicator 12 thresholds misrate country risk for every client in that country, with no workaround.
  - Given a country rating downgrade,
  - when `countryRatingChangeWl(previous, current)` is called,
  - then it returns `1` for exactly 1 notch and `2` for 2 or more notches, as a primitive number.
  - Examples:
    - `("BBB+","BBB")` → `1`. Here the calculator gives WL 0 for the same pair (C6).
    - `("CCC","CCC-")` → `1`
    - `("BBB+","BBB-")` → `2`
    - `("BBB+","BB+")` → `2`
    - `("AAA","CCC-")` → `2`

- **AC-9 [P1] (REQ-03-12, C3).** Cost: a false Indicator 12 WL on an improving or stable country. The workaround is that the analyst edits the inputs.
  - Given a country rating upgrade or an unchanged country rating,
  - when `countryRatingChangeWl(previous, current)` is called,
  - then it returns `0`.
  - Examples:
    - `("BBB","BBB+")` → `0`
    - `("BB+","BBB+")` → `0`
    - `("CCC-","AAA")` → `0`
    - `("BBB","BBB")` → `0`
    - `("aa"," AA ")` → `0`

- **AC-10 [P1] (C5, C2, C3, REQ-03-12, Contract "built on `notchChange`").** Cost: a pair outside the hand-picked examples gets an inconsistent WL. Few pairs are hit.
  - Given all 361 ordered pairs `(p, c)` of `RATING_SCALE`,
  - when each function is called,
  - then for `n = notchChange(p, c)`:
    - `notchCalculator(p, c)` deep-strict-equals `{ notches: n, direction: n > 0 ? "downgrade" : n < 0 ? "upgrade" : "unchanged", wl: n >= 3 ? 2 : n === 2 ? 1 : 0 }`
    - `countryRatingChangeWl(p, c) === (n >= 2 ? 2 : n === 1 ? 1 : 0)`
    - `notchChange(c, p) === -n`, and the diagonal gives `0`.
  - Review confirms that `src/indicators/countryRating.mjs` imports `notchChange` from `../ratings/notch.mjs` and holds no copy of the scale.

- **AC-11 [P1] (Contract, C7, C8, ARC-deps, CLAUDE.md).** Cost: other POC parts that import the contract break at import time. The workaround is to fix the path or name before they integrate.
  - Given the repository on the job branch with Node 18+,
  - when `import { RATING_SCALE, notchChange, notchCalculator } from "./src/ratings/notch.mjs"` and `import { countryRatingChangeWl } from "./src/indicators/countryRating.mjs"` are run,
  - then:
    - all four named exports resolve, with `typeof` `"object"`, `"function"`, `"function"`, `"function"`
    - calling any function writes nothing to stdout or stderr and does not mutate its arguments
    - `package.json` has no `dependencies` or `devDependencies` added
    - `src/ratings` and `src/indicators` import no `node:fs`, `node:net`, `node:http` or other I/O module
    - `node --test` passes.

## Non-functional requirements

- **NFR-security: input validation only, with strict scale membership.** All three public functions accept only a primitive string that, after `trim()` and upper-casing, equals one of the 19 `RATING_SCALE` values. Every other value throws `RangeError` and is never coerced or partly matched. There is no authentication, authorisation or secrets handling, because none applies. Checked by:
  - a test: AC-5, covering every listed invalid value, each argument position and each function
  - a test: AC-4, for the values that must be accepted
  - a review: no `eval`, no `String(x)` coercion before the type check, and no `indexOf` result used without a −1 check.
- **NFR-audit: no audit trail in this slice (C7).** The target is that the modules record nothing: no logging, no persistence and no audit or event emission. The edited-value audit belongs to a later part of the POC. Checked by:
  - a review of `src/ratings/notch.mjs` and `src/indicators/countryRating.mjs`: no `console.*`, no file, network or storage access, and no module-level mutable state
  - a test: AC-11, no stdout/stderr output.
- The readiness items NFR-performance, NFR-availability, NFR-privacy, NFR-observability and NFR-compliance are n_a, so they set no target. Because of NFR-compliance, the WL criteria are rated P0/P1.

## Risks and assumptions

- **R-1: the POC example miscount (C2).** The POC document says BBB+ → BB+ is 2 notches and WL 1; the binding answer is 3 notches and WL 2. Someone who checks the code against the POC text may "fix" it back. The tests and the review must use the C2 values, and AC-6 names this example explicitly.
- **R-2: the two WL rules differ at 1 notch (C6).** The calculator gives 0 and Indicator 12 gives 1. A shared threshold helper, or a copy-paste between the modules, would break one of the two. AC-6, AC-8 and AC-10 pin both rules on the same pair (`BBB+` → `BBB`).
- **R-3: signed zero.** `index(current) − index(previous)` cannot produce `-0`, but an implementation using `Math.sign`, negation or `-(a-b)` could. Under `assert.deepStrictEqual`, `-0` differs from `0`, so AC-3 and AC-7 require `Object.is(n, 0)`.
- **R-4: the scale has no default grades.** `CC`, `C`, `D` and `SD` are not on the C1 scale and are rejected. A country or issuer that defaults cannot be expressed in this slice. This is accepted as written in C1, and is a likely follow-up for the business.
- **A-1 (assumption): non-string values are rejected.** "Anything else is rejected" (C1, CON-errors) is read as: only primitive strings are candidates. Values whose string form is on the scale, such as `["BBB+"]` or `new String("BBB+")`, throw `RangeError` and are not coerced. This changes no business outcome, because callers pass strings.
- **A-2 (assumption): trimming follows `String.prototype.trim()` exactly (X-trim-whitespace).** Zero-width characters such as `​` are not whitespace under `trim()`, so input like `"​BBB"` is rejected.
- **A-3 (assumption): the error message is a diagnostic, not contract (X-error-message).** Only `instanceof RangeError` is asserted. The rule that `previous` is checked first is checked by one test on the message, which only needs to contain "previous".
- **A-4 (assumption): the `direction` literals and the key set `{ notches, direction, wl }` are a public contract.** Downstream screens (C8) depend on them, so no extra keys are added.

## Open questions

None. Every point that changes scope is settled by C1–C8 and readiness.md, which has 0 open items. R-4 (support for default grades) is noted for a later slice; it does not change this one.
