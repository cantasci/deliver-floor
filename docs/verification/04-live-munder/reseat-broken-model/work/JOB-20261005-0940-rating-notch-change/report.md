# Delivery report

## Summary

The request asked for the notch change from REQ-06-02 (part): a signed count of steps between a previous and a current rating on the 19-step scale. This is the base that Indicators 11–13 and the notch calculator build on. Delivered: `src/ratings/notch.mjs` exports a frozen `RATING_SCALE` and `notchChange(previous, current)`. Downgrades are positive, upgrades negative, and equal ratings return +0. Input is trimmed and case-insensitive, and every invalid input throws a `RangeError`. It is plain Node ESM with no dependencies and no I/O; 7 unit tests and 13 QA integration tests are included.

## Acceptance criteria

| AC | Status | Evidence |
|---|---|---|
| AC-1 scale: 19 entries in order, frozen | ✅ met | `RATING_SCALE = Object.freeze([...])` in notch.mjs; direct check `Object.isFrozen` true, length 19; unit test in `test/ratings/notch.test.mjs`; QA `notch.int.test.mjs` AC-1; verify-all-095115.log |
| AC-2 BBB+→BB+ = 3, AAA→CCC- = 18 | ✅ met | direct check `notchChange('BBB+','BB+')` = 3; unit + QA AC-2 (T-01-qa-a1-095020.log) |
| AC-3 BB+→BBB+ = -3, CCC-→AAA = -18 | ✅ met | direct check = -3; unit + QA AC-3 |
| AC-4 equal = +0 | ✅ met | `indexCurrent - indexPrevious` (no negation); direct check `Object.is(notchChange('A','A'),0)` true; unit + QA AC-4 |
| AC-5 adjacent pairs ±1 | ✅ met | unit + QA AC-5 (all pairs from literal array); verify-all log |
| AC-6 trim only; 'BB B+' throws | ✅ met | direct check `' BBB+ '`,`'\tBB+\n'` = 3; `'BB B+'` → RangeError; unit + QA AC-6 |
| AC-7 case-insensitive | ✅ met | direct check `'bbb+','Bb+'` = 3; QA AC-7 |
| AC-8 empty / whitespace-only → RangeError | ✅ met | unit "empty and unknown strings throw RangeError"; QA AC-8 |
| AC-9 unknown ratings → RangeError | ✅ met | same unit test; QA AC-9 |
| AC-10 non-strings (incl. String object, no args) → RangeError | ✅ met | `typeof value !== 'string'` throws RangeError; direct check `new String('A')` and `notchChange()` → RangeError; unit "non-strings throw RangeError, never TypeError"; QA AC-10 |
| AC-11 invalid in either position | ✅ met | both args validated before the subtraction; direct check `('XYZ',5)` → RangeError; QA AC-11 |
| AC-12 no I/O/output, no deps, tests pass | ✅ met | notch.mjs has no imports or console calls; `package.json` unchanged in `git diff main job/...`; QA AC-12 via child process, empty stdout/stderr; verify-all log: 20 pass / 0 fail |
| AC-13 error tests assert type only | ✅ met | QA test "AC-13 ..." (notch.int.test.mjs:102); error tests use `assert.throws(fn, RangeError)`; the message text is not asserted |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 notchChange + frozen RATING_SCALE | backend (backend#1) | 1 | gate PASS, QA pass 13/13 (qa#1), review approve (reviewer#1, ecc:typescript-reviewer), merged |

## Blocked / deferred work

None.

## Risks and follow-ups

1. The reviewer's 3 non-blocking nits are optional polish: JSDoc on the exports and per-case assertion messages in tests.
2. The AC-13 QA check is a source-text scan and only a weak guard. Tighten it or drop it later.
3. The next slices (Indicators 11–13, the rest of REQ-06-02) import `notchChange` / `RATING_SCALE` from `src/ratings/notch.mjs`.
4. The README was not updated (PM decision DEL-docs: not required).

## PM decisions

- DEL-docs n/a: no README or changelog for a one-module POC slice.
- X-error-message: tests assert only `RangeError`, not the message text.
- X-scale-immutability: `RATING_SCALE` is exported frozen.
- No security specialist role: the function is pure, and input validation is covered by C2, the reviewer and QA.
- All seats were re-seated on `claude-sonnet-5-5`: the configured `munder.model` (`claude-nonexistent-0`) does not exist.

## Delivery

- Branch: `job/JOB-20261005-0940-rating-notch-change`
- PR / merge: local merge into the base branch (merge_mode `local`)

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

- re-seated ba#1 on claude-sonnet-5-5 — _API error: model claude-nonexistent-0 does not exist (munder.model in .deliver.json)_ (2026-10-05T09:41:51Z)
- re-seated backend-lead#1 on claude-sonnet-5-5 — _API error: model claude-nonexistent-0 does not exist (munder.model in .deliver.json)_ (2026-10-05T09:41:52Z)
- re-seated backend#1 on claude-sonnet-5-5 — _API error: model claude-nonexistent-0 does not exist (munder.model in .deliver.json)_ (2026-10-05T09:41:53Z)
- re-seated qa#1 on claude-sonnet-5-5 — _API error: model claude-nonexistent-0 does not exist (munder.model in .deliver.json)_ (2026-10-05T09:41:55Z)
- re-seated reviewer#1 on claude-sonnet-5-5 — _API error: model claude-nonexistent-0 does not exist (munder.model in .deliver.json)_ (2026-10-05T09:41:57Z)
- No security specialist role — _NFR-security covers only input validation of a pure, I/O-free function (C2 RangeError); the stack reviewer and QA check it._ (2026-10-05T09:44:35Z)
