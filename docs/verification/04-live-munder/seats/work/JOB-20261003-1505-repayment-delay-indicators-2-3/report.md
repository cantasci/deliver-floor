# Delivery report

## Summary
Asked: REQ-03-02 (Indicator 2, days with delay) and REQ-03-03 (Indicator 3, delays in 12 months) of the Watchlist POC, EPIC-03, built in parallel by two backend developers.
Delivered: `src/indicators/daysWithDelay.mjs` (`DAYS_WITH_DELAY_OPTIONS`, `daysWithDelayWl`) and `src/indicators/delayCount.mjs` (`DELAY_COUNT_OPTIONS`, `delayCountWl`), with frozen option lists, trim + exact case-sensitive matching and `RangeError` for every invalid or non-string input (C1–C6).
Plain Node ESM, no dependencies; `node --test` 34/34 on the merged branch. All 10 acceptance criteria met.

## Roles
- Business Analyst (ba#1): readiness, plan, card specs, closing check
- Backend Lead (backend-lead#1, ecc:architect): cards
- Backend devs (backend#1, backend#2, backend-dev): parallel cards, unit tests first
- QA (qa#1, qa-tester): integration tests per card
- Reviewer (reviewer#1, ecc:typescript-reviewer)

## Cards
| Card | What | Attempts | Result |
|---|---|---|---|
| T-01 | Ind.2 daysWithDelay (REQ-03-02) — backend#1 | 2 (review: C5 BigInt/circular → TypeError) | merged |
| T-02 | Ind.3 delayCount (REQ-03-03) — backend#2 | 1 | merged |
| T-03 | C5 fix for T-02: RangeError for BigInt/circular/Symbol — backend#1 | 1 | merged |
| T-04 | Merged-branch AC-10: job-level check + per-card QA AC-10 relaxed — backend#1 + qa#1 | 2 (PM qa_verify fix) | merged |

## Acceptance check (BA)
| AC | Status | Evidence |
|---|---|---|
| AC-1 (REQ-03-02) options list, order, frozen | met | `DAYS_WITH_DELAY_OPTIONS` is a frozen array of the 5 ASCII strings in order (`src/indicators/daysWithDelay.mjs`); `test/indicators/daysWithDelay.test.mjs`, `test/indicators/integration/daysWithDelay.integration.test.mjs`; `gates/T-01-a2-151457.log`, `T-01-qa-a2-152516.log` |
| AC-2 (REQ-03-02) option → WL | met | Direct call: no delay 0, <=3 days 0, >3 days 2, >60 days 3, >90 days 4; same unit and QA tests |
| AC-3 (REQ-03-02) trimming | met | `"  >60 days "`→3, `"\t>90 days\n"`→4 (direct call + tests) |
| AC-4 (REQ-03-02) invalid → RangeError | met | RangeError for `>3 Days`, `≤3 days`, `>3  days`, `constructor`, `__proto__`, `""`, null, 3, {}, ["no delay"], 10n (direct call); QA round 2 added BigInt/Symbol/circular (`T-01-qa-a2-152516.log`) |
| AC-5 (REQ-03-03) options list, order, frozen | met | `DELAY_COUNT_OPTIONS` frozen `["0","1",">1"]`; `test/indicators/delayCount.test.mjs`, `delayCount.integration.test.mjs`; `gates/T-02-a1-151040.log`, `T-02-qa-a1-151158.log` |
| AC-6 (REQ-03-03) option → WL | met | `"0"`→0, `"1"`→1, `">1"`→2 (direct call + tests) |
| AC-7 (REQ-03-03) trimming | met | `" 1 "`→1 (direct call); `\t>1\n`, ` 0` in unit tests |
| AC-8 (REQ-03-03) invalid → RangeError | met | RangeError for `2`, `01`, `> 1`, numbers 0 and 1, `[]`, `10n`, `constructor`, null (direct call). The BigInt/circular case (C5) was fixed in T-03: `test/indicators/integration/delayCount.c5.integration.test.mjs`, `gates/T-03-a1-151417.log`, `T-03-qa-a1-152432.log` |
| AC-9 (both) valid options never throw, WL in range, pure, arrays unchanged | met | Each option returns 0/2/3/4 and 0/1/2 on direct call; purity and non-mutation covered in the unit tests (frozen arrays cannot be mutated) |
| AC-10 (both) `node --test` green, no extra files, no dependencies | met | `gates/verify-all-153032.log` 34/34; diff vs main touches only `src/indicators/` and `test/indicators/` (8 files), `package.json` unchanged and has no dependencies (`test/indicators/job.test.mjs`); T-04 fixed the merged-branch check |

All 10 ACs met. Plan scope respected: no Indicator 1, no UI, no counting logic.

## Follow-ups
1. AC-10 literally lists four files; the job also added QA integration tests and `test/indicators/job.test.mjs` under `test/indicators/` (within the component path). Treat as accepted extension of AC-10, not a defect.
2. `describe()` and the `WL_BY_OPTION` lookup are duplicated in both modules (intentional for independent parallel cards). Consider extracting a shared helper in a later slice.
3. Process: T-03 (BigInt/circular → RangeError) and T-04 (`qa_verify` passed a directory, fails on Node 22) were late fixes. Plan AC-4/AC-8 could name BigInt/Symbol/circular inputs up front; future contracts should give `qa_verify` explicit files.
4. Later slices: Indicator 1 (collapsing indicators 2-3) and the UI that renders the `*_OPTIONS` lists remain to be built.
