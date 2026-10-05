# Rating notch change (REQ-06-02, part)

Delivers `src/ratings/notch.mjs`: `RATING_SCALE` (frozen, 19 ratings, best first) and `notchChange(previous, current)` (signed integer, downgrade positive; trimmed, case-insensitive; every invalid input throws `RangeError`). Pure ESM, no imports, no dependencies. `npm test`: 27/27 pass (13 dev unit tests, 14 QA integration tests) on Node 22.22 and 20.20.

## Roles and cards
Roles: business-analyst, backend-lead (ecc:architect), backend-dev (haiku, as the job asked), qa-tester, reviewer (ecc:typescript-reviewer).

| Card | Result |
|---|---|
| T-01 | archived. Passed QA and had one blocking review item (AC-13 child process used a static `import` under `node -e`, which fails on Node 18, and printed to stdout), fixed on attempt 2. Then the gate refused it, because QA re-committed its test file after the dev's fix and `dl` compares against the commit recorded at the round-1 QA. Attempts were used up. |
| T-02 | merged. Replaces T-01: brings over T-01's two dev commits by cherry-pick, escapes the remaining raw non-ASCII characters in the dev test file, with a fresh QA round and review (approve). 1 attempt. |

## Acceptance criteria (BA closing check)
| AC | Status | Evidence |
|---|---|---|
| AC-1 frozen 19-entry scale, exact order, mutation throws TypeError | met | dev "AC-1"; QA "AC-1" x3 (outside import, literal, tampering) |
| AC-2 BBB+ → BB+ = 3 | met | dev AC-2; QA spec test-data table |
| AC-3 BB+ → BBB+ = -3 | met | dev AC-3; QA table |
| AC-4 A → A = +0 (not -0), all ratings | met | dev AC-4; QA matrix, diagonal `Object.is` |
| AC-5 adjacent steps ±1 across letter groups | met | dev AC-5; QA AC-5 |
| AC-6 AAA ↔ CCC- = ±18 | met | dev AC-6; QA table |
| AC-7 all 361 pairs = j − i, integer, antisymmetric | met | dev AC-7; QA oracle matrix (4 spellings) + 6859-triple additivity |
| AC-8 case-insensitive | met | dev AC-8; QA matrix |
| AC-9 `trim()` incl. U+00A0, U+FEFF | met | dev AC-9; QA trim/lookalike test |
| AC-10 unknown rating → RangeError | met | dev AC-10; QA every-invalid-value test |
| AC-11 empty / whitespace-only → RangeError | met | dev AC-11; QA |
| AC-12 non-string → RangeError, never TypeError | met | dev AC-12; QA synchronous RangeError test |
| AC-13 pure, silent, no imports, no dependencies | met | dev AC-13; QA silent child process, one-liner, package.json, source check |
| AC-14 `npm test` exit 0, test per AC | met | gates/verify-all-191210.log: 27/27 |

## Decisions by the PM (no human was asked after the start)
- DEL-docs: JSDoc only, no README/changelog (marked n_a, so no `docs` role). X-scale-shape: frozen array. X-error-message: descriptive RangeError, type-only contract. X-coverage: no numeric target.
- Skipped the optional `security` role: no auth, secrets or personal data; input validation is covered by the AC-10..AC-12 tests.
- Replaced blocked T-01 with T-02 (above) instead of a third attempt.

## Follow-ups
1. Node 18 was never run (only 20 and 22 exist in the sandbox); compatibility is by code reading. Run the suite on Node 18.
2. `test/ratings/notch.qa.test.mjs` asserts `node_modules/` does not exist; it fails in a checkout where `npm install` was run. Assert "no dependencies in package.json, no lockfile" instead.
3. QA builds invalid values with `(0, eval)`; a literal array is simpler. Dev AC-7/AC-13 checks are weaker than QA's (Promise check, `require(`); QA covers them.
4. Tooling: the gate should accept a QA re-commit after the dev's fix (or `dl qa` should be recordable before the gate) so a QA round 2 does not use up the card's attempts.
5. Next: the rest of REQ-06-02 (notch calculator) and Ind. 11-13 can import from `src/ratings/notch.mjs`.

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

- **T-01** — Accept raw non-ASCII characters (U+00A0/U+FEFF/U+2212/Cyrillic A) left in the dev's unit-test file instead of a third attempt — _review nit only; tests pass and the QA file uses escapes; attempts are used up_ (2026-10-05T19:08:36Z)
- **T-01** — T-01 is not delivered (archived) — _replaced by T-02 (same work, brought over by cherry-pick); T-01 could not pass the gate after QA's round-2 re-commit with attempts used_ (2026-10-05T19:09:17Z)
