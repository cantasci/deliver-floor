# Delivery report

## Summary

Asked: the notch change of REQ-06-02 (Watchlist POC slice, requirements `JOB-models-plain.md`, clarifications C1–C4) — given a previous and a current rating, compute the signed notch change on the 19-step scale.
Delivered: `src/ratings/notch.mjs` exporting `RATING_SCALE` (19 ratings, best first, frozen) and `notchChange(previous, current)` = index(current) − index(previous): downgrade positive, upgrade negative, unchanged 0. Input is trimmed and case-insensitive; every invalid input (unknown, empty/whitespace, non-string incl. `new String('A')`, null/undefined) throws a RangeError. 33 unit tests (dev, TDD) + 27 integration tests (QA); full suite green.

## Acceptance criteria

| AC | Status | Evidence |
|-----|--------|----------|
| AC-1 | met | test `AC-1: given previous rating "BBB+" and current rating "BB+", returns 3` passed; gate verify-all-064350.log line 3; QA integration test test/integration/ratings/notch.int.test.mjs (19781a6) |
| AC-2 | met | test `AC-2: given previous rating "BB+" and current rating "BBB+", returns -3` passed; gate verify-all-064350.log line 9; QA test (19781a6) |
| AC-3 | met | test `AC-3: given previous rating "A" and current rating "A", returns 0` passed; gate verify-all-064350.log line 14; QA test (19781a6) |
| AC-4 | met | test `AC-4: RATING_SCALE is an array of 19 ratings from AAA (index 0) to CCC- (index 18)` passed; gate verify-all-064350.log line 20; QA test (19781a6) |
| AC-5 | met | test `AC-5: given previous rating "  AAA  " with whitespace, trims and returns 18` passed; gate verify-all-064350.log line 26; QA test (19781a6) |
| AC-6 | met | test `AC-6: given previous rating "aaa" in lowercase, normalizes and returns 18` passed; gate verify-all-064350.log line 32; QA test (19781a6) |
| AC-7 | met | test `AC-7: given mixed-case ratings "bBb+" and "Bb+", normalizes both and returns 3` passed; gate verify-all-064350.log line 38; QA test (19781a6) |
| AC-7b | met | test `AC-7b: given ratings with trim and case "  bbb+ " and " BB+  ", returns 3` passed; gate verify-all-064350.log line 44; QA test (19781a6) |
| AC-8 | met | test `AC-8: given boundary ratings AAA to CCC-, returns 18 (maximum downgrade)` passed; gate verify-all-064350.log line 50; QA test (19781a6) |
| AC-9 | met | test `AC-9: given boundary ratings CCC- to AAA, returns -18 (maximum upgrade)` passed; gate verify-all-064350.log line 56; QA test (19781a6) |
| AC-10 | met | test `AC-10: given same rating for both previous and current for each of 19 ratings, returns 0` passed; gate verify-all-064350.log line 62; QA test (19781a6) |
| AC-11 | met | test `AC-11: given previous rating as empty string "", throws RangeError` passed; gate verify-all-064350.log line 68; QA test (19781a6) |
| AC-12 | met | test `AC-12: given previous rating as unknown string "XYZ", throws RangeError` passed; gate verify-all-064350.log line 74; QA test (19781a6) |
| AC-13 | met | test `AC-13: given previous rating as whitespace-only "   ", trims to empty and throws RangeError` passed; gate verify-all-064350.log line 80; QA test (19781a6) |
| AC-14 | met | test `AC-14: given previous rating as non-string number 123, throws RangeError` passed; gate verify-all-064350.log line 86; QA test (19781a6) |
| AC-15 | met | test `AC-15: given previous rating as String object new String("A"), throws RangeError` passed; gate verify-all-064350.log line 92; QA test (19781a6) |
| AC-16 | met | test `AC-16: given previous rating as null, throws RangeError` passed; gate verify-all-064350.log line 98; QA test (19781a6) |
| AC-17 | met | test `AC-17: given previous rating as undefined, throws RangeError` passed; gate verify-all-064350.log line 104; QA test (19781a6) |
| AC-18 | met | test `AC-18: given current rating as empty string "", throws RangeError` passed; gate verify-all-064350.log line 110; QA test (19781a6) |
| AC-19 | met | test `AC-19: given current rating as unknown string "XYZ", throws RangeError` passed; gate verify-all-064350.log line 116; QA test (19781a6) |
| AC-20 | met | test `AC-20: given current rating as whitespace-only "   ", throws RangeError` passed; gate verify-all-064350.log line 122; QA test (19781a6) |
| AC-21 | met | test `AC-21: given current rating as non-string number 123, throws RangeError` passed; gate verify-all-064350.log line 128; QA test (19781a6) |
| AC-22 | met | test `AC-22: given current rating as String object new String("B"), throws RangeError` passed; gate verify-all-064350.log line 134; QA test (19781a6) |
| AC-23 | met | test `AC-23: given current rating as null, throws RangeError` passed; gate verify-all-064350.log line 140; QA test (19781a6) |
| AC-24 | met | test `AC-24: given current rating as undefined, throws RangeError` passed; gate verify-all-064350.log line 146; QA test (19781a6) |
| AC-25 | met | test `AC-25: given all 19 previous ratings against current "A", returns correct notch distances` passed; gate verify-all-064350.log line 152; QA test (19781a6) |
| AC-26 | met | test `AC-26: given previous "A" against all 19 current ratings, returns correct notch distances` passed; gate verify-all-064350.log line 158; QA test (19781a6) |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 Implement notchChange function and RATING_SCALE export | backend (backend-dev, **sonnet**, as the human asked) | 1 | gate PASS · QA pass 27/27 · review approve · merged |

## Blocked / deferred work

None.

## PM decisions

- No security reviewer role: NFR-security is input validation only (RangeError per C2); called in-process, no auth, secrets, personal data or external entry point.
- Readiness quotes split at markdown backticks into verbatim fragments by the PM, component reviewer set to role `reviewer` (no third BA round trip).
- `qa_verify` quoted (`node --test "test/integration/ratings/**/*.test.mjs"`) so Node, not the shell, expands the glob.

## Risks and follow-ups

- Plan v1 had wrong expected values (AC-7, AC-25); caught in PM verification and fixed before cards were cut.
- None open. Indicators 11–13 and the notch calculator can import `notchChange` / `RATING_SCALE`.

## Delivery

- Branch: `job/JOB-20261005-0622-rating-notch-change`
- Merge: local (`merge_mode: local`) into the base branch.

<!-- deliver:pm-decisions -->
## Decisions Michael took after the start

- No security reviewer role on this job — _NFR-security is input validation only (RangeError on invalid ratings, per C2); the function is called in-process by other POC modules, no auth, secrets, personal data or external entry point — the stack reviewer checks the validation_ (2026-10-05T06:29:55Z)
- Corrected readiness quotes myself (split at markdown backticks into '…' fragments) and set the component reviewer to role 'reviewer' — _The BA's wording was verbatim except across backtick-wrapped tokens; a third BA round trip would add nothing to the analysis_ (2026-10-05T06:29:55Z)
