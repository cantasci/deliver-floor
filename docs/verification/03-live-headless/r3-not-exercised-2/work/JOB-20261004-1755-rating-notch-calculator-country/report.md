# Rating notch calculator + country rating change indicator (Watchlist POC slice)

## Delivered
- `src/ratings/notch.mjs`: `RATING_SCALE` (frozen, 19 steps), `notchChange`, `notchCalculator` (REQ-06-02; WL by Indicator 13 thresholds, C2/C3/C5/C6).
- `src/indicators/countryRating.mjs`: `countryRatingChangeWl` (REQ-03-12), built on `notchChange`.
- Full suite on the job branch: `node --test` → 56 tests, 56 pass, 0 fail (Node v22.22.0).

## Cards
| Card | Title | Attempts | Gate | QA | Review |
|---|---|---|---|---|---|
| T-01 | notch.mjs | 1 | pass | pass (16/16) | approve |
| T-02 | countryRating.mjs | 1 | pass | pass (13/13) | approve |

## Acceptance criteria (BA closing check)
All of AC-1..AC-16 met, each backed by named unit and integration tests and `gates/verify-all-181016.log`.
AC-5 is met against a corrected example: the plan's ('A','BBB+') → 3 notches / WL 2 contradicts the scale; A→BBB+ is 2 notches / WL 1, A→BBB is 3 / WL 2 (see PM decisions).

## PM decisions
- Readiness: `X-trim` decided as `String.prototype.trim()`, from the request's "Input is trimmed" (C1) — no human question asked. `DEL-docs` n_a (request requires no docs). DEL-docs/RATING_SCALE frozen/error message includes rejected input/no numeric coverage threshold decided as PM items.
- AC-5 example corrected (above).
- No `security` role: only input validation applies to a pure library.

## Follow-ups
- Not run on Node 18 (CLAUDE.md says 18+); all runs used Node 22.
- Review nits, not blocking: unit and integration suites overlap; one AC-15 unit test fails if a non-test helper is added under `test/indicators/`; an integration test monkeypatches `process.stdout.write`; magic values (WL thresholds) inline in `notch.mjs`.
- Card branches were not pushed to origin (a hook blocked it; merge mode is local, so not needed).

<!-- deliver:pm-decisions -->
## Decisions Michael took after the start

- **T-01** — Spec AC-5 example ('A','BBB+') is wrong: A→BBB+ is 2 notches (WL 1), A→BBB is 3 (WL 2). The scale (C1) and AC-2/AC-8 govern; dev's test follows the scale; QA is told in its prompt — _The AC-5 example contradicts the frozen scale; the rule-based ACs are authoritative_ (2026-10-04T18:06:58Z)
