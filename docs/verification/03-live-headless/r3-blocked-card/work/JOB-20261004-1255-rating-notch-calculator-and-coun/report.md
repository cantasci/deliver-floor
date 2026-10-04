# Rating notch calculator and country indicator

Delivers REQ-06-02 (notch calculator) and REQ-03-12 (Indicator 12, country rating change) as pure ES modules:
`src/ratings/notch.mjs` (`RATING_SCALE`, `notchChange`, `notchCalculator`) and `src/indicators/countryRating.mjs` (`countryRatingChangeWl`).
BBB+ → BB+ is 3 notches / WL 2 (C2 corrects the POC text).

## Acceptance criteria
All 14 ACs met (AC-1 … AC-14). Evidence: full suite on the job branch, 165/165 passing (`gates/verify-all-131326.log`);
T-03 QA 23/23, T-02 QA 66/66; both cards approved by the reviewer with nits only.

## Cards
| Card | Result | Attempts |
|---|---|---|
| T-01 | archived: its verify command (`node --test test/ratings/`, directory form) fails on Node 22; replaced by T-03 | 1 |
| T-03 | merged (re-run of T-01, reuses its commit; file-form verify) | 1 |
| T-02 | merged | 1 |

## PM decisions
- Replaced T-01 with T-03 and switched to file-form verify commands: max_attempts is 1 and the failure was a contract defect, not the dev's work.

## Follow-ups
- T-03's commit message still reads "T-01: …" (an amend was blocked by a hook); cosmetic.
- Reviewer test nits (duplicated assertions, 16-entry invalid list in a unit test); no AC affected.

<!-- deliver:pm-decisions -->
## Decisions Michael took after the start

- **T-01** — T-01 is not delivered (archived) — _replaced by T-03: verify command fixed; T-01's work is reused_ (2026-10-04T13:08:39Z)
- **T-01** — Replace T-01 with T-03 and use file-form verify commands — _directory-form 'node --test dir/' fails on Node 22 (MODULE_NOT_FOUND); max_attempts=1 leaves no retry; T-01's work is reused via cherry-pick_ (2026-10-04T13:08:41Z)
