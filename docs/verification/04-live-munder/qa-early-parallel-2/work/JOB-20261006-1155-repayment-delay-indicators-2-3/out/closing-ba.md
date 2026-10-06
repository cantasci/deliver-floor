## Closing check: Repayment delay indicators 2-3

Checked on the job branch `job/JOB-20261006-1155-repayment-delay-indicators-2-3` at `5659d1e` (both cards merged). My own re-run in that worktree: `node --test` → 37 tests, 37 pass, 0 fail. Direct probes confirmed the behaviour listed below.

Evidence key: **gate** = `gates/T-01-a1-120734.log` (PASS, 14 checks) and `gates/T-02-a1-120736.log` (PASS); **QA** = `gates/T-01-qa-a1-120839.log` (11/11) and `gates/T-02-qa-a1-120929.log` (PASS); **verify-all** = `gates/verify-all-121005.log` (37 pass, 0 fail); **review** = reviewer approve on both cards, 0 blocking.

| AC | Status | Evidence |
| --- | --- | --- |
| AC-1 (REQ-03-02): `DAYS_WITH_DELAY_OPTIONS` = the 5 strings in order, frozen | met | `src/indicators/daysWithDelay.mjs` line 2 (`Object.freeze([...])`); my probe: `Object.isFrozen` is true; QA log (T-01), AC-1 pass; verify-all |
| AC-2 (REQ-03-02): each option → WL (no delay 0, <=3 days 0, >3 days 2, >60 days 3, >90 days 4) | met | `WL_BY_OPTION` Map in the module; QA log (T-01), AC-2 pass; gate T-01 |
| AC-3 (REQ-03-02): trimmed input gives the same WL | met | my probe: NBSP-padded `">90 days"` → 4; QA log (T-01), AC-3 pass. Reviewer nit: the unit test at line 48 holds a raw NBSP, to be written as ` ` |
| AC-4 (REQ-03-02): invalid string → `RangeError`, message contains `JSON.stringify(input)` | met | my probes: `"constructor"`, `"≤3 days"`, `">3  days"` all throw with the quoted value in the message; QA log (T-01), AC-4 pass |
| AC-5 (REQ-03-02): non-string → `RangeError`, message contains `typeof` | met | my probes: `null` and `new String(">3 days")` throw with "object" in the message; QA log (T-01), AC-5 pass |
| AC-6 (REQ-03-03): `DELAY_COUNT_OPTIONS` = `["0","1",">1"]`, frozen | met | `src/indicators/delayCount.mjs` line 2; my probe: `Object.isFrozen` is true; QA log (T-02), AC-6 pass |
| AC-7 (REQ-03-03): each option → WL (0 → 0, 1 → 1, >1 → 2) | met | `WL_BY_OPTION` Map in the module; QA log (T-02), AC-7 pass; gate T-02 |
| AC-8 (REQ-03-03): trimmed input gives the same WL | met | my probe: NBSP-padded `">1"` → 2; QA log (T-02), AC-8 pass. The T-02 unit tests have no NBSP case (reviewer nit); the QA integration tests cover it |
| AC-9 (REQ-03-03): invalid string → `RangeError`, message contains `JSON.stringify(input)` | met | my probes: `"2"` and `"toString"` throw with the quoted value; QA log (T-02), AC-9 pass |
| AC-10 (REQ-03-03): non-string → `RangeError`, message contains `typeof`; numbers throw | met | my probe: the number `1` throws with "number" in the message; QA log (T-02), AC-10 pass |
| AC-11 (both modules): plain ESM, no imports or I/O, no dependency, no cross-import, `node --test` exits 0 | met | the two source files contain no `import`, `console` or file access (read directly); `package.json` has no dependencies key; verify-all 37 pass, 0 fail; QA logs AC-11 pass on both cards |
| AC-12 (both modules): stateless; a throwing call leaves the option list unchanged | met | QA logs AC-12 pass (T-01); T-02 QA pass; the Map is module-private and the option arrays are frozen; verify-all |
| Error message rule (X-error-message): names the indicator, rejected value and allowed options | met | my probes show `Indicator 2 (days with delay): invalid option "≤3 days"; expected one of: …` and the Indicator 3 equivalent; QA logs, error-message pass |
| Out of scope respected (C3, C4, C6: no Indicator 1, no UI, no day counting) | met | `git diff main HEAD --stat` in the job worktree lists exactly 6 files: 2 modules, 2 unit tests, 2 integration tests; no other file touched |

Open questions in the plan: none; nothing was left unresolved.

## Follow-ups

1. **Not yet on `main`.** Both cards are merged into the job branch (`5659d1e`), but `main` is still at `0622a60` with no `src/indicators` files. The job branch must be integrated into `main` by god; that is the only outstanding delivery step.
2. **Commit-message prefixes are inconsistent.** T-01's dev commit is `b62ff8e B1: …` (the card text said `B1:`), while T-02's is `1cb3eb5 T-02: …`. The role card requires `<CARD-ID>:`, so T-01's prefix deviates. Cosmetic; reword only if the gate or history cleanliness matters.
3. **T-01 reviewer nit:** replace the raw NBSP at line 48 of `test/indicators/daysWithDelay.test.mjs` with a ` ` escape, so the character stays visible in editors and diffs.
4. **T-02 reviewer nits:** `delayCountWl` builds the message text eagerly on every call (`shown`), including on success, and its unit tests have no NBSP case (QA covers it). No behaviour impact; optional tidy-up.
5. **Caller risk (A4, not a defect):** the nested options `">3 days"`, `">60 days"` and `">90 days"` rely on the later POC screens picking the right option. When Indicator 1 and the screens are built, they should derive the option from the number of days and the delay count (C6).
