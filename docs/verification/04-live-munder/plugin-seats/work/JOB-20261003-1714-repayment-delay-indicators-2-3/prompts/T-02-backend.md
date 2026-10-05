CARD:
{
 "id": "T-02",
 "title": "Indicator 3 \"Delays in 12 months\": delayCountWl + DELAY_COUNT_OPTIONS (REQ-03-03)",
 "role": "backend",
 "component": "indicators",
 "context": "Why: Watchlist-level (WL, 0-4, higher is worse) mapping for POC indicator 3 \"Delays in 12 months\"; pure function plus exported dropdown option list that later POC screens render. Plain Node 18+ ESM (.mjs), no npm deps, no imports, no I/O, no logging (CLAUDE.md). Tests: node:test + node:assert/strict. TDD: write the unit test first.\nFiles: create src/indicators/delayCount.mjs and test/indicators/delayCount.test.mjs. Touch nothing else; do NOT create src/indicators/index.mjs or any shared helper (the other indicator is built in parallel by another dev; tiny duplicated trim/validate logic is accepted).\nExports (named): DELAY_COUNT_OPTIONS = Object.freeze([\"0\",\"1\",\">1\"]) in exactly this order; function delayCountWl(option) -> number in {0, 1, 2}.\nMapping: \"0\"->0, \"1\"->1, \">1\"->2 (more than one delay in 12 months).\nCounting delays in the last 12 months and choosing the option is the CALLER's job (C6); do not implement it. Numbers such as 1 must be rejected even though they look like option \"1\".\nAlgorithm: (1) if typeof option !== 'string' throw RangeError (BEFORE trimming: String objects, arrays, numbers like 1 must be rejected); (2) t = option.trim() (String.prototype.trim; internal whitespace untouched); (3) exact, case-sensitive match against the option list using an own-property-safe lookup (Map, switch, or Object.hasOwn) - never plain map[option], which would accept 'constructor'/'__proto__'/'toString' (NFR-security); (4) otherwise throw RangeError, never return a default WL. Return plain numbers.\nError message (X-errors-msg): must contain the function name and quote the rejected value for strings, e.g. delayCountWl: invalid option \"2\"; for non-strings describe the type/value safely (e.g. `delayCountWl: invalid option (${typeof option})` or String()-free formatting; must not throw itself for Symbol/object input). Tests assert only instanceof RangeError and message includes 'delayCountWl'.\nInvalid inputs to cover in tests: \"2\", \">2\", \"01\", \"1.0\", \"-1\", \"> 1\", \"\", \"   \", \"one\", \"constructor\", \"__proto__\". Non-strings: 0, 1, 2, undefined, null, true, {}, [\"1\"], and call with no argument.\nAlso test: option list equals expected array and Object.isFrozen is true; every entry of the list maps without throwing to [0,1,2] (map over the list); push on the frozen list throws TypeError (ESM is strict) or leaves it unchanged, and mapping unchanged; whitespace trimming cases \" 1 \" -> 1, \"\\t>1\\n\" -> 2, \" 0\" -> 0.",
 "depends_on": [],
 "scope": [
  "src/indicators/delayCount.mjs",
  "test/indicators/delayCount.test.mjs"
 ],
 "verify": "node --test test/indicators/delayCount.test.mjs",
 "qa_scope": [
  "test/integration/indicators/delayCount.test.mjs"
 ],
 "qa_verify": "node --test test/integration/indicators/delayCount.test.mjs",
 "acceptance": [
  "AC-9: Given the module, when `DELAY_COUNT_OPTIONS` is read, then `deepEqual` to `[\"0\",\"1\",\">1\"]` (this order) and `Object.isFrozen(DELAY_COUNT_OPTIONS) === true`.",
  "AC-10: `delayCountWl(\"0\")` returns `0` (`strictEqual`, a number).",
  "AC-11: `delayCountWl(\"1\")` returns `1`.",
  "AC-12: `delayCountWl(\">1\")` returns `2`.",
  "AC-13: `\" 1 \"` → `1`, `\"\\t>1\\n\"` → `2`, `\" 0\"` → `0`.",
  "AC-14: `\"2\"`, `\">2\"`, `\"01\"`, `\"1.0\"`, `\"-1\"`, `\"> 1\"`, `\"\"`, `\"   \"`, `\"one\"`, `\"constructor\"`, `\"__proto__\"` → `RangeError`.",
  "AC-15: `0`, `1`, `2`, `undefined`, `null`, `true`, `{}`, `[\"1\"]`, and a call with no argument → `RangeError` (numbers rejected even though `1` looks like option `\"1\"`). The `typeof` check happens before trimming.",
  "AC-16: for an invalid input the error is `instanceof RangeError` and its message contains `delayCountWl`; for strings it quotes the value, e.g. `delayCountWl: invalid option \"2\"`. Building the message must not itself throw for Symbol/object input. Tests assert only the type and the function name.",
  "AC-17: mapping every entry of `DELAY_COUNT_OPTIONS` through `delayCountWl` does not throw and gives `[0,1,2]`; `push` on the frozen list throws `TypeError` or leaves it unchanged, and the mapping is unchanged afterwards.",
  "AC-18: the module is plain ESM `.mjs`, has no `import`, no I/O, no logging; `src/indicators/index.mjs` and any shared helper are not created; `node --test test/indicators/delayCount.test.mjs` passes (and the full `node --test` stays green)."
 ],
 "agent": "backend-dev",
 "state": "running",
 "attempts": 1,
 "notes": [],
 "seat": "backend#2",
 "assignments": [
  {
   "attempt": 1,
   "agent": "backend-dev",
   "seat": "backend#2",
   "by": "michael",
   "at": "2026-10-03T17:21:03Z"
  }
 ],
 "worktree": "/tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/wt/T-02",
 "branch": "job/JOB-20261003-1714-repayment-delay-indicators-2-3--T-02"
}
SPEC (what to build, the acceptance criteria and test data — follow it): /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/specs/T-02.md
COMPONENT: indicators — stack javascript (plain Node 18+ ESM, node:test, no deps), path src/indicators/, test/indicators/; load these skills: ecc:backend-patterns, ecc:tdd-workflow
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/roles/backend.md
WORKTREE: /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/wt/T-02   (branch job/JOB-20261003-1714-repayment-delay-indicators-2-3--T-02; base is the job branch job/JOB-20261003-1714-repayment-delay-indicators-2-3)
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT: /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/plan.md — Goal section and the ACs listed in the card.
READINESS (binding): /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/readiness.md
HANDOFF FILE: /tmp/claude-0/e2e-v/munder/repo/.work/JOB-20261003-1714-repayment-delay-indicators-2-3/handoffs/T-02.md — fill it in.
QA TESTS: qa_scope "test/integration/indicators/delayCount.test.mjs" belongs to the QA role — never edit it; after a QA round its tests must pass unchanged.
PREVIOUS FEEDBACK: none
Work test-first (unit tests). When done: run the verify command in the worktree, commit, fill the handoff, and report done.
