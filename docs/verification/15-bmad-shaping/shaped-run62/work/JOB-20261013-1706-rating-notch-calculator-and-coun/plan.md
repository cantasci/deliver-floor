# Plan

> Produced by the Business Analyst (MODE PLAN), written to this file by Michael. Keep the headings as they are — the ACs are checked one by one at closing.

## Goal

Credit analysts using the Watchlist POC need two things: the notch change between a previous and a current rating, and the Watchlist level (WL) that change produces. Both come from one shared notch computation, delivered as a pure Node ESM library with no dependencies:
- `src/ratings/notch.mjs` exports `RATING_SCALE`, `notchChange` and `notchCalculator`. It covers the REQ-06-02 notch calculator (CAP-1, CAP-2).
- `src/indicators/countryRating.mjs` exports `countryRatingChangeWl`. It covers REQ-03-12, Indicator 12 country rating change (CAP-3).

Success means two things. First, `npm test` (`node --test`) passes. Second, a downstream module that imports `notchCalculator` and `countryRatingChangeWl` gets the documented values (readiness PRD-goal, SPEC "Success signal").

## Scope

- **CAP-1** (`src/ratings/notch.mjs`):
  - `RATING_SCALE` is a frozen array of the 19 S&P-style steps, best first (AD-2).
  - `notchChange(previous, current)` returns a signed integer: positive for a downgrade, negative for an upgrade, 0 (never -0) when unchanged (AD-1).
  - Rating lookup: the input is trimmed, then must match a scale step exactly, case included. Anything else throws a `RangeError` (AD-4, CON-errors).
- **CAP-2, REQ-06-02** (`src/ratings/notch.mjs`):
  - `notchCalculator(previous, current)` returns `{ notches, direction, wl }`. It is built on `notchChange`.
  - Its WL comes from an unexported, named helper that applies the Ind. 13 thresholds: unchanged, upgrade or a 1-notch downgrade → 0; a 2-notch downgrade → 1; 3 or more → 2 (AD-3).
- **CAP-3, REQ-03-12** (`src/indicators/countryRating.mjs`):
  - `countryRatingChangeWl(previous, current)` returns 0, 1 or 2 under the Ind. 12 rule: 1-notch downgrade → 1; 2 or more → 2; unchanged or upgrade → 0.
  - It is built on `notchChange` (AD-1, AD-3).
- Unit tests use `node:test` and `node:assert/strict` in `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs` (AD-6, TST-strategy).
- Both WL helpers carry a code comment on the intentional 1-notch difference: the calculator gives WL 0, Ind. 12 gives WL 1 (B-36, DEL-docs).
- The PR description lists these follow-ups (DEL-docs, AD Deferred):
  - the consuming form job owns REQ-03-12's "auto-filled value editable";
  - the consuming UI needs a mapping step, because Moody's, CC, C, D, SD and NR all throw;
  - the POC owner should correct the REQ-06-02 example;
  - the reviewer lenses were skipped (B-48).

## Out of scope

(PRD-scope, SPEC Non-goals)
- **Any UI.** This includes REQ-03-12's "auto-filled value editable", which the consuming form job owns. There is no override parameter.
- **Public sources.** Nothing is fetched, scraped or pre-filled from a public source. REQ-03-12's "Pre-filled from public source" belongs to the caller.
- The 12-month lookback (REQ-02-02).
- The Ind. 11 and Ind. 13 WL functions, the agency selector, and final WL aggregation. The calculator only borrows the Ind. 13 thresholds; it does not export them.
- **Other rating notations.** Moody's notation and CC, C, D, SD and NR are not mapped to the scale; they throw `RangeError`.
- **Unpinned non-string inputs.** Only `null`, `undefined`, a number, `{}` and a `Symbol` are pinned. Exotic objects (null-prototype, a throwing `toString`) are out.
- **Infrastructure.** No persistence, audit trail, logging, metrics, config, CI or deployment.
- **The POC document.** `docs/POC_Requirements_v0.2_EN.md` is not edited (X-poc-doc-example).
- **No extra exports** beyond the Contract. No npm dependencies (ARC-deps).

## Acceptance criteria
<!-- Each one must be testable. Cards reference these ids. Each carries its priority: [P0] money, data, security or the core
     flow lost · [P1] the core feature wrong, with a workaround · [P2] secondary behaviour · [P3] cosmetic or rare. -->

The ratings scale used below (index 0 to 18) is AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-.

- AC-1 [P0] (CAP-1, REQ-06-02, REQ-03-12; AD-2). Cost: a wrong or reordered scale silently gives every caller a wrong distance and a wrong WL.
  - **Given** `import { RATING_SCALE } from "./src/ratings/notch.mjs"`
  - **when** it is read
  - **then** `assert.deepStrictEqual(RATING_SCALE, ["AAA","AA+","AA","AA-","A+","A","A-","BBB+","BBB","BBB-","BB+","BB","BB-","B+","B","B-","CCC+","CCC","CCC-"])`, and `RATING_SCALE.length === 19`.
- AC-2 [P2] (CAP-1; AD-2, CON-interface).
  - **Given** `RATING_SCALE`
  - **when** a caller tries to mutate it in strict ESM code
  - **then** `Object.isFrozen(RATING_SCALE) === true`, and `RATING_SCALE.push("CC")`, `RATING_SCALE[0] = "X"` and `RATING_SCALE.length = 0` each throw `TypeError`. Afterwards the array is unchanged (still deep-equal to AC-1).
- AC-3 [P0] (CAP-1, REQ-06-02, REQ-03-12; AD-1). Cost: a wrong sign or distance silently flips a downgrade into an upgrade, and every WL built on it under-scores the client.
  - **Given** two valid ratings
  - **when** `notchChange(previous, current)` is called
  - **then** it returns `RATING_SCALE.indexOf(current) - RATING_SCALE.indexOf(previous)`, as an integer.
  - Every one of the 18 adjacent pairs `i → i+1` returns `1`, and each reverse pair returns `-1`.
  - Pinned values:
    - `notchChange("BBB+","BB+") === 3`
    - `notchChange("BBB+","BBB-") === 2`
    - `notchChange("AA","A+") === 2`
    - `notchChange("BB","BBB") === -3`
    - `notchChange("A-","A") === -1`
    - `notchChange("AAA","CCC-") === 18`
    - `notchChange("CCC-","AAA") === -18`
- AC-4 [P2] (CAP-1; CON-interface "never -0").
  - **Given** the same rating twice
  - **when** `notchChange(r, r)` is called for each of the 19 steps (e.g. `notchChange("BBB","BBB")`)
  - **then** it returns 0, and `Object.is(result, 0) === true` (+0, not -0).
- AC-5 [P0] (CAP-1, REQ-06-02, REQ-03-12; CON-errors, AD-4, NFR-security). Cost: an unscorable rating that yields a number instead of an error silently produces a wrong WL.
  - **Given** an invalid rating in either position, the other being `"BBB"`
  - **when** `notchChange` is called
  - **then** it throws an instance of `RangeError` and returns nothing. This applies to each of:
    - **Strings:** `"CC"`, `"C"`, `"D"`, `"SD"`, `"NR"`, `"Baa1"` (Moody's), `"XYZ"`, `"bbb+"` (wrong case), `""`, `"   "`
    - **Non-strings:** `null`, `undefined`, `42`, `{}`, `Symbol("x")`
  - Example: `assert.throws(() => notchChange("NR","BBB"), RangeError)` and `assert.throws(() => notchChange("BBB", null), RangeError)`.
- AC-6 [P2] (CAP-1; CON-errors, AD-4).
  - **Given** an invalid rating
  - **when** `notchChange` throws
  - **then** the `RangeError` message contains the value as it was passed. Pinned messages:

    | Input | Message contains |
    |---|---|
    | `" cc "` | `" cc "` (untrimmed) |
    | `"Baa1"` | `"Baa1"` |
    | `null` | `"null"` |
    | `undefined` | `"undefined"` |
    | `42` | `"42"` |
    | `{}` | `"[object Object]"` |
    | `Symbol("x")` | `"Symbol(x)"` (no `TypeError` while building the message) |

  - When both are invalid, `previous` is checked first: `notchChange("XX1","XX2")` has a message that contains `"XX1"` and does not contain `"XX2"`.
  - Tests check the type and the contained value, not the full wording.
- AC-7 [P2] (CAP-1; CON-errors, AD-6 trim cases).
  - **Given** a valid rating with surrounding spaces
  - **when** `notchChange(" BBB+ ", "BB+")` is called
  - **then** it returns `3`, and `notchChange("BBB", " BBB ")` returns +0.
  - Rejected cases (`"bbb+"`, `"   "`, `""`) are covered by AC-5.
- AC-8 [P1] (CAP-2, REQ-06-02; B-1, B-12, X-poc-doc-example). Cost: the analyst is shown a wrong notch count or WL; the workaround is counting notches by hand, since the helper is a Should.
  - **Given** a previous and a current rating
  - **when** `notchCalculator(previous, current)` is called
  - **then** the result deep-strictly equals exactly these values (exactly three keys):

    | Call | Result |
    |---|---|
    | `("BBB+","BB+")` | `{ notches: 3, direction: "downgrade", wl: 2 }` (corrected REQ-06-02 example, not the POC text's 2 / WL 1) |
    | `("BBB+","BBB-")` | `{ notches: 2, direction: "downgrade", wl: 1 }` |
    | `("AA","A+")` | `{ notches: 2, direction: "downgrade", wl: 1 }` |
    | `("A","A-")` | `{ notches: 1, direction: "downgrade", wl: 0 }` |
    | `("A-","A")` | `{ notches: -1, direction: "upgrade", wl: 0 }` |
    | `("BB","BBB")` | `{ notches: -3, direction: "upgrade", wl: 0 }` |
    | `("AAA","CCC-")` | `{ notches: 18, direction: "downgrade", wl: 2 }` (WL capped at 2) |

  - No test asserts 2 notches for BBB+ → BB+.
- AC-9 [P1] (CAP-2, REQ-06-02; AD-1, AD-3). Cost: the calculator disagrees with `notchChange` or misapplies the thresholds on some pair; few pairs are hit, and recounting by hand is the workaround.
  - **Given** all 361 ordered pairs `(p, c)` of `RATING_SCALE`
  - **when** `notchCalculator(p, c)` is called
  - **then** for every pair:
    - `result.notches === notchChange(p, c)`;
    - `direction` is `"downgrade"` when notches > 0, `"upgrade"` when notches < 0, and `"unchanged"` when notches is 0;
    - `wl` is `0` when notches ≤ 1, `1` when notches is 2, and `2` when notches ≥ 3.
- AC-10 [P2] (CAP-2, REQ-06-02; CON-interface).
  - **Given** the same rating twice
  - **when** `notchCalculator("BBB","BBB")` is called
  - **then** it deep-strictly equals `{ notches: 0, direction: "unchanged", wl: 0 }`, and `Object.is(result.notches, 0) === true`.
- AC-11 [P0] (CAP-3, REQ-03-12; AD-3). Cost: Ind. 12 is a Must indicator; a wrong threshold silently under-scores a client's country risk WL, with no workaround in the flow.
  - **Given** a previous and a current country rating
  - **when** `countryRatingChangeWl(previous, current)` is called
  - **then** it returns:

    | Call | Change | WL |
    |---|---|---|
    | `("BBB","BBB-")` | 1-notch downgrade | `1` |
    | `("BBB","BB+")` | 2 notches | `2` |
    | `("BBB","BB")` | 3 notches | `2` |
    | `("AAA","CCC-")` | 18 notches | `2` |
    | `("BBB","BBB")` | unchanged | `0` |
    | `("BBB-","BBB")` | 1-notch upgrade | `0` |
    | `("BB","BBB")` | 3-notch upgrade | `0` |

  - Across all 361 pairs the result is `notchChange ≤ 0 → 0`, `=== 1 → 1`, `≥ 2 → 2`, and is always one of `0`, `1`, `2` (number, strict equal).
- AC-12 [P1] (CAP-2, CAP-3, REQ-06-02, REQ-03-12; B-36, PRD-conflicts (2)). Cost: a consumer who treats the two WLs as interchangeable gets the 1-notch case wrong; the documented difference is the workaround.
  - **Given** the same 1-notch downgrade `("A","A-")`
  - **when** both functions are called
  - **then** `notchCalculator("A","A-").wl === 0` and `countryRatingChangeWl("A","A-") === 1`.
  - Both WL helpers' source carries a code comment saying the difference is intentional (checked by review).
- AC-13 [P0] (CAP-2, CAP-3, REQ-06-02, REQ-03-12; AD-4). Cost: a swallowed error or a fallback returns WL 0 for an unscorable rating, silently hiding a downgrade.
  - **Given** an invalid rating
  - **when** `notchCalculator` or `countryRatingChangeWl` is called
  - **then** the `RangeError` from `notchChange` propagates unchanged; neither function returns null, 0 or an error object. Pinned cases:

    | Call | Message contains |
    |---|---|
    | `notchCalculator("CC","BBB")` | `"CC"` |
    | `notchCalculator("BBB","")` | (type only) |
    | `countryRatingChangeWl("BBB", null)` | `"null"` |
    | `countryRatingChangeWl("Aa2","AA")` | `"Aa2"` |
    | `countryRatingChangeWl("XX1","XX2")` | `"XX1"`, not `"XX2"` |

- AC-14 [P1] (CAP-1, CAP-2, CAP-3, REQ-06-02, REQ-03-12; CON-interface, AD-5). Cost: other POC parts import these names, so a missing or renamed export breaks them. The failure is loud and the fix is quick.
  - **Given** `import * as n from "./src/ratings/notch.mjs"` and `import * as c from "./src/indicators/countryRating.mjs"`
  - **when** their keys are listed
  - **then** `Object.keys(n).sort()` deep-equals `["RATING_SCALE","notchCalculator","notchChange"]` and `Object.keys(c)` deep-equals `["countryRatingChangeWl"]`. There is no `default` export, and `typeof` each function is `"function"`.
- AC-15 [P2] (CAP-1, CAP-2, CAP-3; AD-1, AD-3, AD-5, ARC-deps).
  - **Given** the delivered source
  - **when** it is reviewed and searched with grep
  - **then**:
    - `src/indicators/countryRating.mjs` imports `notchChange` from `../ratings/notch.mjs` and holds no copy of the scale or of a rating string list;
    - `src/ratings/` imports nothing from `src/indicators/`;
    - `notchCalculator` gets its distance from `notchChange`;
    - each WL rule is a separate named function (the Ind. 13 helper unexported, in `notch.mjs`);
    - neither module imports `node:fs`, `node:net`, `node:http` or `node:process`, nor uses `console`, `Date` or `Math.random`;
    - `package.json` has no `dependencies` or `devDependencies`.
- AC-16 [P1] (CAP-1, CAP-2, CAP-3, REQ-06-02, REQ-03-12; TST-strategy, DEL-ci, AD-6). Cost: without a passing suite the job gate cannot prove any of the above.
  - **Given** a clean checkout of the job branch
  - **when** `npm test` runs from the repo root
  - **then** it exits 0 and the run includes `test/ratings/notch.test.mjs` and `test/indicators/countryRating.test.mjs`, which together contain the pinned cases of AC-1 to AC-13.
- AC-17 [P3] (REQ-06-02, REQ-03-12; DEL-docs, X-poc-doc-example, B-48).
  - **Given** the PR for this job
  - **when** its description is read
  - **then** it lists four follow-ups:
    1. the consuming form job owns REQ-03-12 "auto-filled value editable";
    2. the consuming UI needs a mapping step (Moody's, CC, C, D, SD and NR throw `RangeError`);
    3. the POC owner should correct the REQ-06-02 example to BBB+ → BB+ = 3 notches / WL 2;
    4. the reviewer lenses were skipped.
  - It also states the intentional 1-notch WL difference for consumers.

## Non-functional requirements
<!-- Every decided NFR-* readiness item: its target and how it is checked (a test, a measurement, a review). -->

- **NFR-security:** Input validation is the only part that applies; there is no authentication, authorisation or secrets. Every rating that is not an exact (trimmed, case-sensitive) scale step, or is not a string, throws a `RangeError` naming the value. No path falls back to a value. Checked by the invalid-input tests (AC-5, AC-6, AC-13), and by review confirming that the lookup in `notchChange` is the only validation point and builds its message with `String(value)`.
- **NFR-audit:** No audit trail in this slice (B-10). Checked by review: no persistence, no write and no record of calls in either module (AC-15).
- **NFR-observability:** No logging, metrics, tracing or config. Checked by review and grep: no `console`, no logger, no env or config reads in `src/ratings` or `src/indicators` (AC-15).
- **NFR-compliance:** No banking-regulation or internal-policy constraint beyond the job's clarifications (human, 2026-10-13). Checked by review at closing: nothing to measure; the reviewer confirms that no rule outside the readiness decisions was added.

## Risks and assumptions

- **The POC document contradicts the delivery.** `docs/POC_Requirements_v0.2_EN.md` line 195 says BBB+ → BB+ = 2 notches → WL 1, but on the 19-step scale it is 3 notches → WL 2. We follow B-1 and B-12 (3 notches, WL 2). QA and closing must check against this plan, not the POC text (X-poc-doc-example). The document stays unedited until the owner corrects it.
- **The two WL rules differ on purpose.** For a 1-notch downgrade, `notchCalculator` gives WL 0 (Ind. 13 thresholds) and `countryRatingChangeWl` gives WL 1 (Ind. 12). This is intentional (B-36). The risk is that a consumer confuses the two; it is mitigated by code comments, AC-12 and the PR note.
- **REQ-03-12 is only partly delivered.** Here: the notch auto-calculation and the WL. Elsewhere: "Pre-filled from public source" and "auto-filled value editable" belong to other jobs. At closing, REQ-03-12 is "met" only for the parts in scope.
- **Trimming is wider than the tests.** We assume trimming means JavaScript `String.prototype.trim()` (readiness CON-errors names `trim()`). That also strips tabs, newlines and other Unicode whitespace, but only `" BBB+ "` is pinned. Other whitespace is accepted as a side effect and not tested.
- **The calculator's WL tops out at 2.** WL 3 and 4 never come from this slice; they belong to final aggregation, which is out of scope.
- **Priority:** REQ-03-12 is a Must and REQ-06-02 a Should; both ship in this job. B-40 supersedes B-34.
- **Review cover:** the BMad reviewer lenses were skipped; only the deterministic lint ran (B-21, B-38, B-48). The job's own review and blind review cover the P0 and P1 criteria.

## Open questions

None. Readiness has 0 open items, and the SPEC resolves its earlier open question OQ-5 (B-12).
