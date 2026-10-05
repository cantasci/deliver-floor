# Closing check — JOB-20261005-0940-rating-notch-change

Checked on branch `job/JOB-20261005-0940-rating-notch-change` (card T-01: gate PASS, QA pass 13/13, review approve). I also re-ran `node --test` on an export of that branch: 20 tests, 20 pass, 0 fail, and spot-checked the code directly (values below).

| AC | Status | Evidence |
|---|---|---|
| AC-1 scale: 19 entries in order, frozen | met | `RATING_SCALE = Object.freeze([...])` in notch.mjs; direct check `Object.isFrozen` true, length 19; unit test in `test/ratings/notch.test.mjs`; QA `notch.int.test.mjs` AC-1; verify-all-095115.log |
| AC-2 BBB+→BB+ = 3, AAA→CCC- = 18 | met | direct check `notchChange('BBB+','BB+')` = 3; unit + QA AC-2 (T-01-qa-a1-095020.log) |
| AC-3 BB+→BBB+ = -3, CCC-→AAA = -18 | met | direct check = -3; unit + QA AC-3 |
| AC-4 equal = +0 | met | `indexCurrent - indexPrevious` (no negation); direct check `Object.is(notchChange('A','A'),0)` true; unit + QA AC-4 |
| AC-5 adjacent pairs ±1 | met | unit + QA AC-5 (all pairs from literal array); verify-all log |
| AC-6 trim only; 'BB B+' throws | met | direct check `' BBB+ '`,`'\tBB+\n'` = 3; `'BB B+'` → RangeError; unit + QA AC-6 |
| AC-7 case-insensitive | met | direct check `'bbb+','Bb+'` = 3; QA AC-7 |
| AC-8 empty / whitespace-only → RangeError | met | unit "empty and unknown strings throw RangeError"; QA AC-8 |
| AC-9 unknown ratings → RangeError | met | same unit test; QA AC-9 |
| AC-10 non-strings (incl. String object, no args) → RangeError | met | `typeof value !== 'string'` throws RangeError; direct check `new String('A')` and `notchChange()` → RangeError; unit "non-strings throw RangeError, never TypeError"; QA AC-10 |
| AC-11 invalid in either position | met | both args validated before the subtraction; direct check `('XYZ',5)` → RangeError; QA AC-11 |
| AC-12 no I/O/output, no deps, tests pass | met | notch.mjs has no imports or console calls; `package.json` unchanged in `git diff main job/...`; QA AC-12 via child process, empty stdout/stderr; verify-all log: 20 pass / 0 fail |
| AC-13 error tests assert type only | met | QA test "AC-13 ..." (notch.int.test.mjs:102); error tests use `assert.throws(fn, RangeError)`; the message text is not asserted |

Overall: all 13 ACs met; nothing partial or not met. Scope respected: the branch adds only `src/ratings/notch.mjs`, `test/ratings/notch.test.mjs` and `test/ratings/integration/notch.int.test.mjs`.

## Follow-ups
1. Reviewer's 3 non-blocking nits (JSDoc on the exports, assertion messages in tests): optional polish, no AC impact.
2. AC-13's QA check is a source-text scan for the words message/match/regex; it is a weak guard. Consider dropping it or tightening it later.
3. Next slices: Indicators 11–13 and the rest of REQ-06-02 should import `notchChange` and `RATING_SCALE` from `src/ratings/notch.mjs` (out of scope here).
4. Non-blocking: `README.md` was not updated (decided not required, DEL-docs).
