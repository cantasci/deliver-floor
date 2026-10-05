Role: Backend Lead reviewer (stack: javascript / Node ESM). Review only; do not modify files.
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/roles/reviewer.md
CARD:
{
 "id": "T-01",
 "title": "Indicator 2 \"Days with delay\": daysWithDelayWl + DAYS_WITH_DELAY_OPTIONS (REQ-03-02)",
 "role": "backend",
 "component": "indicators",
 "context": "Why: Watchlist-level (WL, 0-4, higher is worse) mapping for POC indicator 2 \"Days with delay\"; pure function plus exported dropdown option list that later POC screens render. Plain Node 18+ ESM (.mjs), no npm deps, no imports, no I/O, no logging (CLAUDE.md). Tests: node:test + node:assert/strict. TDD: write the unit test first.\nFiles: create src/indicators/daysWithDelay.mjs and test/indicators/daysWithDelay.test.mjs. Touch nothing else; do NOT create src/indicators/index.mjs or any shared helper (the other indicator is built in parallel by another dev; tiny duplicated trim/validate logic is accepted).\nExports (named): DAYS_WITH_DELAY_OPTIONS = Object.freeze([\"no delay\",\"<=3 days\",\">3 days\",\">60 days\",\">90 days\"]) in exactly this order; function daysWithDelayWl(option) -> number in {0, 2, 3, 4}.\nMapping: \"no delay\"->0, \"<=3 days\"->0, \">3 days\"->2, \">60 days\"->3, \">90 days\"->4. Mapping is by option STRING, never by number (labels overlap numerically). WL 1 is intentionally never produced..\nThe requirement table writes unicode \"≤3 days\" but the business-confirmed contract is ASCII \"<=3 days\"; \"≤3 days\" must throw RangeError.\nAlgorithm: (1) if typeof option !== 'string' throw RangeError (BEFORE trimming: String objects, arrays, numbers like 1 must be rejected); (2) t = option.trim() (String.prototype.trim; internal whitespace untouched); (3) exact, case-sensitive match against the option list using an own-property-safe lookup (Map, switch, or Object.hasOwn) - never plain map[option], which would accept 'constructor'/'__proto__'/'toString' (NFR-security); (4) otherwise throw RangeError, never return a default WL. Return plain numbers.\nError message (X-errors-msg): must contain the function name and quote the rejected value for strings, e.g. daysWithDelayWl: invalid option \">3 Days\"; for non-strings describe the type/value safely (e.g. `daysWithDelayWl: invalid option (${typeof option})` or String()-free formatting; must not throw itself for Symbol/object input). Tests assert only instanceof RangeError and message includes 'daysWithDelayWl'.\nInvalid inputs to cover in tests: \">3 Days\", \"NO DELAY\", \"≤3 days\", \"<= 3 days\", \">30 days\", \"\", \"   \", \"constructor\", \"__proto__\", \"toString\", \">3  days\" (internal double space). Non-strings: undefined, null, 3, 0, true, {}, [], [\">3 days\"], new String(\">3 days\"), and call with no argument.\nAlso test: option list equals expected array and Object.isFrozen is true; every entry of the list maps without throwing to [0,0,2,3,4] (map over the list); push on the frozen list throws TypeError (ESM is strict) or leaves it unchanged, and mapping unchanged; whitespace trimming cases \"  >3 days \" -> 2, \"\\t>90 days\\n\" -> 4, \" no delay\" -> 0.",
 "depends_on": [],
 "scope": [
  "src/indicators/daysWithDelay.mjs",
  "test/indicators/daysWithDelay.test.mjs"
 ],
 "verify": "node --test test/indicators/daysWithDelay.test.mjs",
 "qa_scope": [
  "test/integration/indicators/daysWithDelay.test.mjs"
 ],
 "qa_verify": "node --test test/integration/indicators/daysWithDelay.test.mjs",
 "acceptance": [
  "AC-1: Given the module, when `DAYS_WITH_DELAY_OPTIONS` is read, then `deepEqual` to `[\"no delay\",\"<=3 days\",\">3 days\",\">60 days\",\">90 days\"]` (this order) and `Object.isFrozen(DAYS_WITH_DELAY_OPTIONS) === true`.",
  "AC-2: Given `\"no delay\"` or `\"<=3 days\"`, when `daysWithDelayWl(option)` is called, then it returns `0` (`strictEqual`, a number).",
  "AC-3: `daysWithDelayWl(\">3 days\")` returns `2`.",
  "AC-4: `daysWithDelayWl(\">60 days\")` returns `3`.",
  "AC-5: `daysWithDelayWl(\">90 days\")` returns `4`.",
  "AC-6: `\"  >3 days \"` → `2`, `\"\\t>90 days\\n\"` → `4`, `\" no delay\"` → `0` (`String.prototype.trim`); `\">3  days\"` (internal double space) → `RangeError`.",
  "AC-7: `\">3 Days\"`, `\"NO DELAY\"`, `\"≤3 days\"`, `\"<= 3 days\"`, `\">30 days\"`, `\"\"`, `\"   \"`, `\"constructor\"`, `\"__proto__\"`, `\"toString\"` → `RangeError`; no default WL is ever returned.",
  "AC-8: `undefined`, `null`, `3`, `0`, `true`, `{}`, `[]`, `[\">3 days\"]`, `new String(\">3 days\")`, and a call with no argument → `RangeError`. The `typeof` check happens before trimming.",
  "AC-16: for an invalid input the error is `instanceof RangeError` and its message contains `daysWithDelayWl`; for strings it quotes the value, e.g. `daysWithDelayWl: invalid option \">3 Days\"`. Building the message must not itself throw for Symbol/object input (non-strings: describe via `typeof`). Tests assert only the type and the function name.",
  "AC-17: mapping every entry of `DAYS_WITH_DELAY_OPTIONS` through `daysWithDelayWl` does not throw and gives `[0,0,2,3,4]`; `push` on the frozen list throws `TypeError` (ESM is strict) or leaves it unchanged, and the mapping is unchanged afterwards.",
  "AC-18: the module is plain ESM `.mjs`, has no `import`, no I/O, no logging; `src/indicators/index.mjs` and any shared helper are not created; `node --test test/indicators/daysWithDelay.test.mjs` passes (and the full `node --test` stays green)."
 ],
 "agent": "backend-dev",
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
   "at": "2026-10-03T17:21:01Z"
  }
 ],
 "worktree": "/tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/wt/T-01",
 "branch": "job/JOB-20261003-1714-repayment-delay-indicators-2-3--T-01",
 "md_workers": [
  {
   "role": "backend",
   "seat": "backend#1",
   "worker": "worker-seat-20261003-1714-backend-1-h1",
   "at": "2026-10-03T17:21:08Z"
  },
  {
   "role": "qa",
   "seat": "qa#1",
   "worker": "worker-seat-20261003-1714-qa-1-h1",
   "at": "2026-10-03T17:22:02Z"
  }
 ],
 "gate": {
  "result": "PASS",
  "head": "eb9c87b8fb14a626c24442a8a36c30257695433b",
  "attempt": 1,
  "log": "/tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/gates/T-01-a1-172150.log",
  "at": "2026-10-03T17:21:50Z"
 },
 "comments": [
  {
   "at": "2026-10-03T17:21:51.448Z",
   "author": "gate",
   "text": "PASS — 14 checks ok, 0 failed (T-01-a1-172150.log)"
  },
  {
   "at": "2026-10-03T17:23:06.736Z",
   "author": "qa-tester",
   "text": "pass (qa_verify PASS): AC-1..8, AC-16, AC-17, AC-18 pass (12 integration tests, test/integration/indicators/daysWithDelay.test.mjs)"
  }
 ],
 "qa": {
  "verdict": "pass",
  "head": "b6c7bcc256dab834c658932f854988c8b4efd851",
  "gate_head": "eb9c87b8fb14a626c24442a8a36c30257695433b",
  "qa_verify": "PASS",
  "log": "/tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/gates/T-01-qa-a1-172306.log",
  "summary": "AC-1..8, AC-16, AC-17, AC-18 pass (12 integration tests, test/integration/indicators/daysWithDelay.test.mjs)",
  "at": "2026-10-03T17:23:06Z"
 },
 "qas": [
  {
   "verdict": "pass",
   "head": "b6c7bcc256dab834c658932f854988c8b4efd851",
   "qa_verify": "PASS",
   "summary": "AC-1..8, AC-16, AC-17, AC-18 pass (12 integration tests, test/integration/indicators/daysWithDelay.test.mjs)",
   "at": "2026-10-03T17:23:06Z"
  }
 ]
}
SPEC: /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/specs/T-01.md   READINESS (binding): /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/readiness.md
CHANGE: run `git -C /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/wt/T-01 diff job/JOB-20261003-1714-repayment-delay-indicators-2-3...HEAD` (and `--stat`).
QA RESULT: /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/out/qa-T-01.json
Check: acceptance criteria met, correctness bugs (incl. prototype-key lookups, typeof before trim, frozen options, error message), security, test quality, scope.
OUTPUT — only JSON, written to /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/out/review-T-01.json (verify with ls -l), then report done:
{"verdict":"approve|changes","blocking":[{"file":"…","line":0,"issue":"…","fix":"…"}],"nits":["…"]}
Use "changes" only when there is at least one blocking item.
