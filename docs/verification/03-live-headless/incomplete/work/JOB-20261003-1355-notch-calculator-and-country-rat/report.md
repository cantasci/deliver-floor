# Delivery report

## Summary

The request was a two-requirement slice of the Watchlist POC: a rating notch calculator (REQ-06-02) and the country rating change indicator (REQ-03-12). Delivered as pure ESM modules: `src/ratings/notch.mjs` (`RATING_SCALE`, `notchChange`, `notchCalculator`) and `src/indicators/countryRating.mjs` (`countryRatingChangeWl`). The sign of `notchCalculator().notches` was the one open item; the human decided it: signed like `notchChange` (downgrade positive, upgrade negative). All 14 ACs are met; the full suite passes (225 tests, 0 failures).

## Acceptance criteria

| AC | Status | Evidence |
| --- | --- | --- |
| AC-1 RATING_SCALE, frozen | ✅ | unit + QA `AC-1`; verify-all log |
| AC-2 notchChange values, no -0 | ✅ | unit + QA `AC-2` |
| AC-3 trim / case-insensitive | ✅ | unit + QA `AC-3` (notch and indicator) |
| AC-4 RangeError on invalid input | ✅ | unit + QA `AC-4` (12 values × 2 positions × 3 functions) |
| AC-5 downgrade ≥2 notches (BBB+→BB+ = 3 → WL 2) | ✅ | unit + QA `AC-5` |
| AC-6 1-notch downgrade → calculator WL 0 | ✅ | unit + QA `AC-6` |
| AC-7 upgrades: negative notches, WL 0 | ✅ | unit + QA `AC-7` |
| AC-8 unchanged → WL 0 | ✅ | unit + QA `AC-8` |
| AC-9 all 361 pairs | ✅ | unit + QA `AC-9` |
| AC-10 Ind. 12 downgrade WL | ✅ | unit + QA `AC-10` |
| AC-11 Ind. 12 upgrade/unchanged → 0, 361 pairs | ✅ | unit + QA `AC-11` |
| AC-12 Ind. 12 vs calculator thresholds differ on purpose | ✅ | unit + QA `AC-12` |
| AC-13 built on notchChange, arity 2, pure, silent | ✅ | unit + QA `AC-13` (child process output check) |
| AC-14 `node --test` green, no dependencies | ✅ | `gates/verify-all-141114.log`: 225 pass, 0 fail |

## Cards

| Card | Role | Attempts | Result |
| --- | --- | --- | --- |
| T-01 notch.mjs | backend | 1 | gate, QA (87 tests), review approved; merged |
| T-02 countryRating.mjs | backend | 1 | gate, QA (53 tests), review approved; merged |

## Blocked / deferred work

None.

## Risks and follow-ups

- Reviewer nits not acted on: rename `normalizeRating` (returns an index); comment the try/catch in message formatting; use word boundaries in the purity regexes (they also match comments); the stdout-stub test is global.
- QA's AC-14 test runs a nested `node --test` and parses TAP output; it depends on the TAP format and inherited env, and may break on another Node version.
- Only run on Node v22.22.0; CLAUDE.md says Node 18+.
- Strict 19-step scale: a downgrade into CC, C or D throws RangeError instead of returning WL 2. Intended for this slice (C1); later consumers must handle it.
- Card branches were not pushed (no remote; merge mode is local).

## Delivery

- Branch: `job/JOB-20261003-1355-notch-calculator-and-country-rat`
- PR / merge: local merge into `main` (merge_mode: local)
