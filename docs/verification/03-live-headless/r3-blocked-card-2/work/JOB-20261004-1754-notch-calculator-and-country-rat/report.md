# Notch calculator and country rating — delivery report

Watchlist POC slice: REQ-06-02 (notch calculator) and REQ-03-12 (Indicator 12, country rating change).

## Delivered
- `src/ratings/notch.mjs` — `RATING_SCALE` (frozen, 19 steps), `notchChange`, `notchCalculator` (Indicator 13 thresholds).
- `src/indicators/countryRating.mjs` — `countryRatingChangeWl` (1 notch → 1, 2+ → 2, upgrades/unchanged → 0), built on `notchChange`.
- Full suite on the job branch: 68 tests, 68 pass, 0 fail (`node --test`, Node v22.22.0).

## Acceptance criteria
All 12 ACs met (BA closing check; evidence: QA tests `test/integration/**`, unit tests, verify-all log `gates/verify-all-181211.log`).

| AC | Status |
|---|---|
| AC-1 frozen 19-rating scale | met |
| AC-2 notchChange values | met |
| AC-3 calculator downgrades (BBB+→BB+ = 3 notches, WL 2 per C2) | met |
| AC-4 upgrades/unchanged → WL 0 | met |
| AC-5 all 361 pairs consistent | met |
| AC-6 Indicator 12 downgrade values; differs from calculator at 1 notch (C6) | met |
| AC-7 Indicator 12 upgrades/unchanged → 0; all 361 pairs | met |
| AC-8 trim + case-insensitive | met |
| AC-9 invalid input → RangeError | met |
| AC-10 error message names argument, echoes value | met |
| AC-11 pure, silent, no I/O | met |
| AC-12 suite green, contract paths, no dependencies | met |

## Cards
| Card | Result | Attempts |
|---|---|---|
| T-01 notch.mjs | archived — stuck after QA (qa_verify directory form fails on Node 22), replaced by T-03 | 1 |
| T-03 notch.mjs (carry-over of T-01's dev commit + hardening against throwing Proxy input) | merged | 1 |
| T-02 countryRating.mjs | merged | 1 |

## PM decisions
- Readiness: `X-input-trim` was raised by the BA as a business question; I treated it as an implementation detail (the request says "trimmed" → `String.prototype.trim()`) and decided it as PM. Please confirm at review. `DEL-docs` recorded as n/a (no docs deliverable); `X-error-message`, `X-scale-immutability` decided by PM.
- T-01 replaced by T-03 (see Cards); logged with `dl pm-decide`.

## Follow-ups
1. Node 18 floor never run (all runs on Node 22).
2. SD/RD/NR and other out-of-scale ratings throw RangeError; a later slice must decide how to score them.
3. Indicator 13 is not exposed as an indicator; add `externalRatingChangeWl` on top of `notchCalculator` later.
4. Reviewer nits (long error messages, a git-dependent QA test) not acted on.
5. Cards should use `node --test <dir>/*.test.mjs` for qa_verify.

<!-- deliver:pm-decisions -->
## Decisions Michael took after the start

- **T-01** — T-01 is not delivered (archived) — _Replaced by T-03: stuck with no attempts left after QA; its finished dev commit 5ee1e93 is carried into T-03_ (2026-10-04T18:08:09Z)
- **T-03** — T-01 replaced by T-03 (same contract; qa_verify changed to glob form) — _T-01 reached QA but qa_verify (directory arg) fails on Node 22; I moved it out of review to fix it, leaving no attempts (max_attempts 1). Re-planned inside the frozen decisions._ (2026-10-04T18:08:14Z)
