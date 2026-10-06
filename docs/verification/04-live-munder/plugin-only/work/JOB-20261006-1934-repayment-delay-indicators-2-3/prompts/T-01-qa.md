MODE: QA-RUN — run your tests on the dev's commit; change a test only where it contradicts the spec; record the verdict per AC. No product code.
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/roles/qa.md
CARD:
{
 "id": "T-01",
 "title": "Indicator 2 Days with delay: DAYS_WITH_DELAY_OPTIONS + daysWithDelayWl (REQ-03-02)",
 "role": "backend",
 "component": "indicators-lib",
 "context": "WHY: EPIC-03 Indicator 2 (Days with delay) maps a dropdown option string to a Watchlist level (WL 0-4, higher is worse). This is a pure-function library module; the option list is the single source the screens (built elsewhere) render. FILES: create src/indicators/daysWithDelay.mjs and test/indicators/daysWithDelay.test.mjs only. Plain Node 18+ ESM (.mjs), node:test + node:assert/strict, NO dependencies, NO I/O, must not import or require src/indicators/delayCount.mjs or any other module (independent of the sibling card B2). CONTRACT: `export const DAYS_WITH_DELAY_OPTIONS = Object.freeze([\"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"])` (exactly these 5 strings, this order, frozen array). `export function daysWithDelayWl(option)` returns 0|2|3|4: \"no delay\"->0, \"<=3 days\"->0, \">3 days\"->2, \">60 days\"->3, \">90 days\"->4. Each option maps to exactly one WL; no range arithmetic (caller picks the single most specific option). INPUT HANDLING: if typeof option !== 'string' throw RangeError (undefined, null, numbers, booleans, objects, arrays, `new String(...)` wrapper objects, and a call with no argument); otherwise option.trim() (String.prototype.trim, any surrounding whitespace) then exact, case-sensitive match against the 5 options; anything else (\"\", \"   \", \">3 Days\", \"No delay\", \"<= 3 days\", \">3  days\" with two inner spaces, \"≤3 days\" (the POC table's ≤ char is NOT valid, only <=), \">30 days\", \"60 days\", \"unknown\") throws RangeError. Error type is the only contract: message text is free (tests assert only RangeError, e.g. assert.throws(fn, RangeError)); include the offending value in the message for debuggability. A zero-width space U+200B is not trimmed by trim() and therefore throws; do not special-case it. Functions must be pure and must not mutate the options array. WORKFLOW: TDD (write failing tests first, then implement). Tests must cover: the options array deep-equal + Object.isFrozen; every WL mapping; every trimming example (\"  >60 days  \"->3, \"\\t>90 days\\n\"->4, \" no delay \"->0, \"\\n<=3 days \\r\\n\"->0); all invalid-string and non-string examples above; iterating DAYS_WITH_DELAY_OPTIONS through daysWithDelayWl never throws and yields [0,0,2,3,4]; purity (same input same output, options array unchanged after calls). Commit message format: `<CARD-ID>: <what changed>`, no AI attribution lines.",
 "depends_on": [],
 "scope": [
  "src/indicators/daysWithDelay.mjs",
  "test/indicators/daysWithDelay.test.mjs"
 ],
 "verify": "node --test test/indicators/daysWithDelay.test.mjs",
 "qa_scope": [
  "test/indicators/integration/daysWithDelay/**"
 ],
 "qa_verify": "node --test test/indicators/integration/daysWithDelay/*.test.mjs",
 "acceptance": [
  "AC-1: Given `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is imported, then it deep-equals `[\"no delay\", \"<=3 days\", \">3 days\", \">60 days\", \">90 days\"]` and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`.",
  "AC-2: Given the option, when `daysWithDelayWl(\"no delay\")` and `daysWithDelayWl(\"<=3 days\")` are called, then both return `0`.",
  "AC-3: `daysWithDelayWl(\">3 days\")` returns `2`.",
  "AC-4: `daysWithDelayWl(\">60 days\")` returns `3`.",
  "AC-5: `daysWithDelayWl(\">90 days\")` returns `4`.",
  "AC-6: Given surrounding whitespace, when called, then `String.prototype.trim()` is applied first: `\"  >60 days  \"` → 3, `\"\\t>90 days\\n\"` → 4, `\" no delay \"` → 0, `\"\\n<=3 days \\r\\n\"` → 0, `\" no delay \"` → 0.",
  "AC-7: Given a string that is not exactly one of the 5 options after trim, when called, then it throws `RangeError`: `\"\"`, `\"   \"`, `\">3 Days\"`, `\"No delay\"`, `\"<= 3 days\"`, `\">3  days\"`, `\"≤3 days\"`, `\">30 days\"`, `\"60 days\"`, `\"unknown\"`.",
  "AC-8: Given a non-string (`undefined`, `null`, `3`, `true`, `{}`, `[\">3 days\"]`, `new String(\">3 days\")`, or no argument), when called, then it throws `RangeError`.",
  "AC-9: Given every entry of `DAYS_WITH_DELAY_OPTIONS`, when mapped through `daysWithDelayWl`, then nothing throws and the result is `[0, 0, 2, 3, 4]`.",
  "AC-18 (this module): the file is plain ESM `.mjs`, has no dependency and no I/O; the function is pure (same input → same output) and does not mutate the options array; `node --test test/indicators/daysWithDelay.test.mjs` passes.",
  "AC-19 (this module): `daysWithDelay.mjs` does not import or require `delayCount.mjs` (or any other module)."
 ],
 "agent": "backend-dev",
 "reviewers": [
  "reviewer"
 ],
 "state": "review",
 "attempts": 1,
 "notes": [],
 "seat": "backend#1",
 "assignments": [
  {
   "attempt": 1,
   "agent": "backend-dev",
   "seat": "backend#1",
   "by": "michael",
   "at": "2026-10-06T19:40:04Z"
  }
 ],
 "worktree": "/tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/wt/T-01",
 "branch": "job/JOB-20261006-1934-repayment-delay-indicators-2-3--T-01",
 "md_workers": [
  {
   "role": "backend",
   "seat": "backend#1",
   "worker": "worker-seat-20261006-1934-backend-1-h1",
   "at": "2026-10-06T19:40:18Z"
  }
 ],
 "gate": {
  "result": "PASS",
  "head": "8d7707c85b428e7c680e38b7ba3597b2c2927d02",
  "attempt": 1,
  "log": "/tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/gates/T-01-a1-194049.log",
  "at": "2026-10-06T19:40:49Z"
 },
 "comments": [
  {
   "at": "2026-10-06T19:40:49.716Z",
   "author": "gate",
   "text": "PASS — 14 checks ok, 0 failed (T-01-a1-194049.log)"
  }
 ],
 "qa_join": {
  "head": "1f305014951725aa5666eda07763a6cec3ff0d06",
  "qa_branch": "0bd2166ce359e6f3386a4877df84c8bfdaf646a7",
  "at": "2026-10-06T19:41:19Z"
 }
}
SPEC: /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/specs/T-01.md
WORKTREE: /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/wt/T-01   QA_SCOPE (write only here): test/indicators/integration/daysWithDelay/**   QA_VERIFY: node --test test/indicators/integration/daysWithDelay/*.test.mjs
DEV'S COMMIT (what the gate passed — test this): 8d7707c85b428e7c680e38b7ba3597b2c2927d02   (your tests were merged on top of it by dl qa-join)
PLAN ACs referenced by the card:
- AC-1 (REQ-03-02, C1, C4, X-options-immutable): Given module `src/indicators/daysWithDelay.mjs`, when `DAYS_WITH_DELAY_OPTIONS` is imported, then it is an array deep-equal to `["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]` (5 strings, this order) and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`.
- AC-2 (REQ-03-02, C2): Given a valid option, when `daysWithDelayWl("no delay")` or `daysWithDelayWl("<=3 days")` is called, then it returns `0` for both.
- AC-3 (REQ-03-02): Given `">3 days"`, when `daysWithDelayWl(">3 days")` is called, then it returns `2`.
- AC-4 (REQ-03-02): Given `">60 days"`, when `daysWithDelayWl(">60 days")` is called, then it returns `3`.
- AC-5 (REQ-03-02): Given `">90 days"`, when `daysWithDelayWl(">90 days")` is called, then it returns `4`.
- AC-6 (REQ-03-02, C1, C5): Given an option with surrounding whitespace of any kind, when called, then it is trimmed with `String.prototype.trim()` and maps as without the whitespace. Examples: `daysWithDelayWl("  >60 days  ")` → 3; `daysWithDelayWl("\t>90 days\n")` → 4; `daysWithDelayWl(" no delay ")` → 0; `daysWithDelayWl("\n<=3 days \r\n")` → 0.
- AC-7 (REQ-03-02, C1, C5): Given a string that is not exactly one of the 5 options after trim, when called, then it throws `RangeError`. Examples: `""`, `"   "`, `">3 Days"`, `"No delay"`, `"<= 3 days"`, `">3  days"` (two inner spaces), `"≤3 days"` (the POC table's ≤ character; only `<=` is valid), `">30 days"`, `"60 days"`, `"unknown"`.
- AC-8 (REQ-03-02, C5): Given a non-string input, when called, then it throws `RangeError`. Examples: `undefined`, `null`, `3`, `true`, `{}`, `[">3 days"]`, `new String(">3 days")`; also a call with no argument.
- AC-9 (REQ-03-02, C1, C2): Given every entry of `DAYS_WITH_DELAY_OPTIONS`, when passed to `daysWithDelayWl`, then none throws and the results, in order, are `[0, 0, 2, 3, 4]`.
- AC-18 (REQ-03-02, REQ-03-03, C4, CLAUDE.md): Given the two modules, when imported, then each is plain Node ESM (`.mjs`), uses no dependency and performs no I/O; both functions are pure (same input → same output, no mutation of the option arrays); `node --test` passes with the tests of both requirements.
- AC-19 (REQ-03-02, REQ-03-03): Given the two modules, when either is imported, then it does not import or require the other module (independence of the two requirements).
Commit any test change in this repo's commit format (your role card, "Commits"), leave the worktree clean, return the JSON your agent definition specifies (verdict per AC).
