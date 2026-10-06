MODE: QA-RUN — run your tests on the dev's commit; change a test only where it contradicts the spec; record the verdict per AC. No product code.
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/roles/qa.md
CARD:
{
 "id": "T-02",
 "title": "Indicator 3 Delays in 12 months: DELAY_COUNT_OPTIONS + delayCountWl (REQ-03-03)",
 "role": "backend",
 "component": "indicators-lib",
 "context": "WHY: EPIC-03 Indicator 3 (Delays in 12 months) maps a dropdown option string to a Watchlist level (WL 0-4, higher is worse). Pure-function library module; the option list is the single source the screens (built elsewhere) render. The caller counts the delays and picks the option string; this module does NOT count or derive anything (a number input is an error). FILES: create src/indicators/delayCount.mjs and test/indicators/delayCount.test.mjs only. Plain Node 18+ ESM (.mjs), node:test + node:assert/strict, NO dependencies, NO I/O, must not import or require src/indicators/daysWithDelay.mjs or any other module (independent of the sibling card B1). CONTRACT: `export const DELAY_COUNT_OPTIONS = Object.freeze([\"0\", \"1\", \">1\"])` (exactly these 3 strings, this order, frozen array). `export function delayCountWl(option)` returns 0|1|2: \"0\"->0, \"1\"->1, \">1\"->2. INPUT HANDLING: if typeof option !== 'string' throw RangeError (the numbers 0 and 1, undefined, null, false, {}, [\"1\"], and a call with no argument); otherwise option.trim() (String.prototype.trim, any surrounding whitespace) then exact match against the 3 options; anything else (\"\", \"  \", \"2\", \"-1\", \"01\", \"1.0\", \"> 1\", \">  1\", \">=1\", \"one\", \">2\") throws RangeError. Note \">1 \" is valid (trims to \">1\"). Error type is the only contract: message text is free (tests assert only RangeError, e.g. assert.throws(fn, RangeError)); include the offending value in the message for debuggability. Functions must be pure and must not mutate the options array. WORKFLOW: TDD (write failing tests first, then implement). Tests must cover: the options array deep-equal + Object.isFrozen; each WL mapping; trimming examples (\" 1 \"->1, \"\\t>1\\n\"->2, \" 0 \"->0, \">1 \"->2); all invalid-string and non-string examples above; iterating DELAY_COUNT_OPTIONS through delayCountWl never throws and yields [0,1,2]; purity (same input same output, options array unchanged after calls). Commit message format: `<CARD-ID>: <what changed>`, no AI attribution lines.",
 "depends_on": [],
 "scope": [
  "src/indicators/delayCount.mjs",
  "test/indicators/delayCount.test.mjs"
 ],
 "verify": "node --test test/indicators/delayCount.test.mjs",
 "qa_scope": [
  "test/indicators/integration/delayCount/**"
 ],
 "qa_verify": "node --test test/indicators/integration/delayCount/*.test.mjs",
 "acceptance": [
  "AC-10: Given `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is imported, then it deep-equals `[\"0\", \"1\", \">1\"]` and `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`.",
  "AC-11: `delayCountWl(\"0\")` returns `0`.",
  "AC-12: `delayCountWl(\"1\")` returns `1`.",
  "AC-13: `delayCountWl(\">1\")` returns `2`.",
  "AC-14: Given surrounding whitespace, when called, then `trim()` is applied first: `\" 1 \"` → 1, `\"\\t>1\\n\"` → 2, `\" 0 \"` → 0, `\">1 \"` → 2, `\" 0 \"` → 0.",
  "AC-15: Given a string that is not exactly `\"0\"`, `\"1\"` or `\">1\"` after trim, when called, then it throws `RangeError`: `\"\"`, `\"  \"`, `\"2\"`, `\"-1\"`, `\"01\"`, `\"1.0\"`, `\"> 1\"`, `\">  1\"`, `\">=1\"`, `\"one\"`, `\">2\"`. (`\">1 \"` is valid.)",
  "AC-16: Given a non-string (the numbers `0` and `1`, `undefined`, `null`, `false`, `{}`, `[\"1\"]`, or no argument), when called, then it throws `RangeError`.",
  "AC-17: Given every entry of `DELAY_COUNT_OPTIONS`, when mapped through `delayCountWl`, then nothing throws and the result is `[0, 1, 2]`.",
  "AC-18 (this module): the file is plain ESM `.mjs`, has no dependency and no I/O; the function is pure and does not mutate the options array; `node --test test/indicators/delayCount.test.mjs` passes.",
  "AC-19 (this module): `delayCount.mjs` does not import or require `daysWithDelay.mjs` (or any other module)."
 ],
 "agent": "backend-dev",
 "reviewers": [
  "reviewer"
 ],
 "state": "review",
 "attempts": 1,
 "notes": [],
 "seat": "backend#2",
 "assignments": [
  {
   "attempt": 1,
   "agent": "backend-dev",
   "seat": "backend#2",
   "by": "michael",
   "at": "2026-10-06T19:40:05Z"
  }
 ],
 "worktree": "/tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/wt/T-02",
 "branch": "job/JOB-20261006-1934-repayment-delay-indicators-2-3--T-02",
 "md_workers": [
  {
   "role": "backend",
   "seat": "backend#2",
   "worker": "worker-seat-20261006-1934-backend-2-h1",
   "at": "2026-10-06T19:40:19Z"
  }
 ],
 "gate": {
  "result": "PASS",
  "head": "e1f3c16068b220811ba46bf22ca8ce9992441e1e",
  "attempt": 1,
  "log": "/tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/gates/T-02-a1-194057.log",
  "at": "2026-10-06T19:40:57Z"
 },
 "comments": [
  {
   "at": "2026-10-06T19:40:58.302Z",
   "author": "gate",
   "text": "PASS — 14 checks ok, 0 failed (T-02-a1-194057.log)"
  }
 ],
 "qa_join": {
  "head": "d8d1ed1cabf4f85ad49e51d46fbc44f95daa3254",
  "qa_branch": "2621d4e6c683d8068d4030db111dcbad8d06252f",
  "at": "2026-10-06T19:41:07Z"
 }
}
SPEC: /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/specs/T-02.md
WORKTREE: /tmp/claude-0/live/floor-plug/munder/repo/.work/JOB-20261006-1934-repayment-delay-indicators-2-3/wt/T-02   QA_SCOPE (write only here): test/indicators/integration/delayCount/**   QA_VERIFY: node --test test/indicators/integration/delayCount/*.test.mjs
DEV'S COMMIT (what the gate passed — test this): e1f3c16068b220811ba46bf22ca8ce9992441e1e   (your tests were merged on top of it by dl qa-join)
PLAN ACs referenced by the card:
- AC-10 (REQ-03-03, C1, C4, X-options-immutable): Given module `src/indicators/delayCount.mjs`, when `DELAY_COUNT_OPTIONS` is imported, then it is an array deep-equal to `["0", "1", ">1"]` (3 strings, this order) and `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`.
- AC-11 (REQ-03-03, C2): Given `"0"`, when `delayCountWl("0")` is called, then it returns `0`.
- AC-12 (REQ-03-03): Given `"1"`, when `delayCountWl("1")` is called, then it returns `1`.
- AC-13 (REQ-03-03): Given `">1"`, when `delayCountWl(">1")` is called, then it returns `2`.
- AC-14 (REQ-03-03, C1, C5): Given an option with surrounding whitespace of any kind, when called, then it is trimmed and maps as without it. Examples: `delayCountWl(" 1 ")` → 1; `delayCountWl("\t>1\n")` → 2; `delayCountWl(" 0 ")` → 0.
- AC-15 (REQ-03-03, C1, C5): Given a string that is not exactly `"0"`, `"1"` or `">1"` after trim, when called, then it throws `RangeError`. Examples: `""`, `"  "`, `"2"`, `"-1"`, `"01"`, `"1.0"`, `"> 1"`, `">  1"`, `">=1"`, `"one"`, `">2"`. (`">1 "` is valid: it trims to `">1"`.)
- AC-16 (REQ-03-03, C5): Given a non-string input, when called, then it throws `RangeError`. Examples: the number `0`, the number `1`, `undefined`, `null`, `false`, `{}`, `["1"]`; also a call with no argument. (A caller passing the count as a number gets an error; it must pass the option string, C6.)
- AC-17 (REQ-03-03, C1, C2): Given every entry of `DELAY_COUNT_OPTIONS`, when passed to `delayCountWl`, then none throws and the results, in order, are `[0, 1, 2]`.
- AC-18 (REQ-03-02, REQ-03-03, C4, CLAUDE.md): Given the two modules, when imported, then each is plain Node ESM (`.mjs`), uses no dependency and performs no I/O; both functions are pure (same input → same output, no mutation of the option arrays); `node --test` passes with the tests of both requirements.
- AC-19 (REQ-03-02, REQ-03-03): Given the two modules, when either is imported, then it does not import or require the other module (independence of the two requirements).
Commit any test change in this repo's commit format (your role card, "Commits"), leave the worktree clean, return the JSON your agent definition specifies (verdict per AC).
