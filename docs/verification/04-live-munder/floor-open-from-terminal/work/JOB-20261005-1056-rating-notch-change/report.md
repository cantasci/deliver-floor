# Delivery report

## Summary
Asked: the REQ-06-02 slice — compute the signed notch change between two ratings on the 19-step scale (JOB-models-plain.md, C1–C4).
Delivered: `src/ratings/notch.mjs` exporting a frozen `RATING_SCALE` (AAA … CCC-) and `notchChange(previous, current)` (downgrade positive, upgrade negative, 0 unchanged; trim + case-insensitive; every invalid input → RangeError). Plain Node ESM, no dependencies, no I/O.
Tests: 11 unit tests (dev, TDD) in `test/ratings/notch.test.mjs` and 13 integration tests (QA) in `test/ratings/integration/notch.int.test.mjs`; full `node --test` 24/24 on the job branch.

## Acceptance criteria
| AC | Status | Evidence |
|---|---|---|
| AC-1 RATING_SCALE: 19 ratings, order, frozen | met | Test "AC-1: RATING_SCALE is the 19 ratings in order and frozen" (QA `test/ratings/integration/notch.int.test.mjs`) and the AC-1 test in `test/ratings/notch.test.mjs`; source inspected; out/T-02-qa.json pass |
| AC-2 BBB+ → BB+ = 3 | met | Test "AC-2: BBB+ → BB+ is 3"; gates/verify-all-111824.log |
| AC-3 BB+ → BBB+ = -3 | met | Test "AC-3: BB+ → BBB+ is -3"; verify-all log |
| AC-4 A → A = 0, not -0 | met | Test "AC-4: A → A is 0 and not -0" (`Object.is`); verify-all log |
| AC-5 signed integer, antisymmetry, examples | met | Test "AC-5: examples and antisymmetry"; out/T-02-qa.json |
| AC-6 all 361 pairs | met | Test "AC-6: all 361 pairs equal index(c)-index(p) and are integers" |
| AC-7 trim | met | Test "AC-7: surrounding whitespace is trimmed" |
| AC-8 case-insensitive | met | Test "AC-8: case-insensitive" |
| AC-9 unknown ratings → RangeError | met | Test "AC-9: unknown rating strings throw RangeError in either position" |
| AC-10 empty / whitespace-only → RangeError | met | Test "AC-10: empty and whitespace-only strings throw RangeError" |
| AC-11 non-strings (incl. Symbol, String object, no args) → RangeError | met | Test "AC-11: non-strings throw RangeError (never TypeError) in either position"; source shows typeof check first |
| AC-12 valid+invalid / both invalid throw | met | Test "AC-12 valid+invalid and both invalid" (verify-all log, ok 23); QA test of the same area passes |
| AC-13 no I/O, exact exports, no deps | met | Test "AC-13 no output, exact exports" (ok 24) and QA check incl. package.json unchanged vs main; own diff of package.json empty |
| AC-14 `node --test` exits 0 | met | gates/verify-all-111824.log: tests 24, pass 24, fail 0; own re-run identical; QA 13/13 integration pass; review verdict approve, no blocking findings (out/T-02-reviewer.json) |

## Cards
| Card | State | Tries | Gate | QA | Review |
|---|---|---|---|---|---|
| T-01 | archived | 2 | PASS (a1) | tests passed, verdict not recordable | — |
| T-02 | merged | 1 | PASS | pass (13/13) | approve (0 blocking) |

## Blocked / deferred work
- T-01 archived and replaced by T-02 (same contract). Its qa_verify `node --test test/ratings/integration/` exits 1 on Node 22 (directory argument → MODULE_NOT_FOUND), so QA's passing verdict could not be recorded; fixing it used the last attempt. T-02 reuses the same code (dev cherry-pick) and the same QA tests (QA cherry-pick) with qa_verify `node --test test/ratings/integration/*.mjs`.

## Risks and follow-ups
- Reviewer nits (non-blocking): unused helper `bad` and an empty `catch {}` in the unit tests; QA AC-6 uses `|| 0`, which would mask -0 (the unit test asserts non -0 directly); optional JSDoc on the exports.
- PM decisions are listed by dl below.

## Delivery
Merge mode `local`: `job/JOB-20261005-1056-rating-notch-change` merged into `main` in the main checkout (no remote configured).

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

- No security reviewer role — _Pure in-process function over a constant scale; NFR-security is only strict input validation (C2), covered by unit/QA tests and the JS reviewer._ (2026-10-05T10:59:35Z)
- Component reviewer = job role 'reviewer' (ecc:typescript-reviewer) — _BA named 'reviewer-javascript', not a role on this job._ (2026-10-05T10:59:35Z)
- RATING_SCALE is exported frozen (Object.freeze) — _Shared constant imported by other POC modules; freezing prevents accidental mutation of the scale every indicator depends on. Plan left it as a PM detail._ (2026-10-05T11:00:52Z)
- **T-01** — T-01 qa_verify changed to 'node --test test/ratings/integration/*.mjs' — _Lead's directory form exits 1 on Node 22 (MODULE_NOT_FOUND); no code change, gate re-run on the same commits_ (2026-10-05T11:05:56Z)
- **T-01** — T-01 is not delivered (archived) — _Replaced by T-02 (same contract, fixed qa_verify); T-01 attempts were spent on a qa_verify defect, not on the product_ (2026-10-05T11:15:59Z)
