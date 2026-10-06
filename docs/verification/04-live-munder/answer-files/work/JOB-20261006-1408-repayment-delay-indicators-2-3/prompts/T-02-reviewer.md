Role: backend Lead reviewer (node stack). Review only; do not modify files.
ROLE CARD (your rules — read first): /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/roles/reviewer.md
CARD:
{
  "title": "REQ-03-03: Indicator 3 delayCount options + WL mapping",
  "role": "backend",
  "component": "indicators-lib",
  "context": "Why: later Watchlist POC screens need the Indicator 3 (delays in the last 12 months) dropdown option list and the mapping from the picked option to a Watchlist level (WL 0-4, higher is worse). Pure domain logic, plain Node 18+ ESM (.mjs), no npm dependencies, no I/O, no state, imports nothing (not even the sibling daysWithDelay.mjs - the two modules must stay independent; do NOT create a shared helper, duplicate the small trim/validate logic instead). Tests: node:test + node:assert/strict. Files (create both, src/ and test/ only hold .gitkeep today): src/indicators/delayCount.mjs and test/indicators/delayCount.test.mjs. Do TDD (tests first). CONTRACT (exact names): `export const DELAY_COUNT_OPTIONS` = Object.freeze([\"0\", \"1\", \">1\"]) in exactly this order; `export function delayCountWl(option)` returns the plain number 0|1|2: \"0\"->0, \"1\"->1, \">1\"->2. The caller counts the delays and picks the option; this slice only maps the label (no counting, no numeric parsing - the option is a string label, never parse it as a number). INPUT RULE / DECISIONS: (1) check `typeof option !== \"string\"` FIRST and throw RangeError, before calling .trim() (otherwise null/undefined would throw TypeError); the number 1 is NOT accepted as \"1\", String objects are non-strings -> RangeError; no coercion; calling with no argument -> RangeError. (2) then `option.trim()` (String.prototype.trim: strips any leading/trailing whitespace incl. tab, newline, NBSP U+00A0); then exact, case-sensitive match; inner whitespace is never changed or collapsed. (3) membership/lookup must be own-membership only (e.g. DELAY_COUNT_OPTIONS.includes(trimmed) with a switch/Map, or Object.hasOwn on a null-prototype/frozen table) - NOT a plain-object lookup like table[trimmed], so \"constructor\", \"__proto__\", \"toString\" throw RangeError instead of returning a value. (4) every invalid input throws `RangeError` and only that type; message text is not contract (tests must assert the type only, e.g. assert.throws(() => f(x), RangeError)); the message should still name the indicator and the valid options and may include String(value). Tests to write (unit, dev): options list exact + order + Object.isFrozen; each valid option -> WL; trim cases \" 1 \"->1, \"\\t>1\\n\"->2, \" 0\"->0, NBSP-padded; RangeError for \"\", \"  \", \"2\", \"-1\", \"01\", \"1.0\", \"> 1\", \">  1\" (inner whitespace), \"one\", \"constructor\", \"__proto__\"; RangeError for the number 1, 0, undefined, null, [], new String(\"1\"), and a call with no argument. Do not touch any file outside scope (in particular nothing of the daysWithDelay card). Commit message format: `<CARD-ID>: <what changed>`, no AI attribution.",
  "depends_on": [],
  "scope": [
    "src/indicators/delayCount.mjs",
    "test/indicators/delayCount.test.mjs"
  ],
  "verify": "node --test test/indicators/delayCount.test.mjs",
  "qa_scope": [
    "test/integration/indicators/delayCount.integration.test.mjs"
  ],
  "qa_verify": "node --test test/integration/indicators/delayCount.integration.test.mjs",
  "acceptance": [
    "1. (AC-6) Given the module, when `DELAY_COUNT_OPTIONS` is read, then it deep-equals `[\"0\", \"1\", \">1\"]` in this order and `Object.isFrozen(DELAY_COUNT_OPTIONS)` is `true`.",
    "2. (AC-7) Given a valid option, when `delayCountWl(option)` is called, then it returns the plain number: `\"0\"`→0, `\"1\"`→1, `\">1\"`→2. The option is a string label, never parsed as a number.",
    "3. (AC-8) Given surrounding whitespace, when called, then it is trimmed first: `\" 1 \"`→1, `\"\\t>1\\n\"`→2, `\" 0\"`→0, `\" >1 \"`→2, `\">1 \"`→2.",
    "4. (AC-9) Given an invalid string, when called, then it throws `RangeError`: `\"\"`, `\"  \"`, `\"2\"`, `\"-1\"`, `\"01\"`, `\"1.0\"`, `\"> 1\"`, `\">  1\"`, `\"one\"`, `\"constructor\"`, `\"__proto__\"`, `\"toString\"`.",
    "5. (AC-10) Given a non-string, when called, then it throws `RangeError` (not `TypeError`; no coercion): the number `1`, `0`, `undefined`, `null`, `[]`, `new String(\"1\")`, and a call with no argument.",
    "6. (AC-11) Every invalid input throws an `instanceof RangeError`; tests assert only the type, never the message.",
    "7. (AC-12) The module is plain ESM `.mjs`, pure (no I/O, no state), imports nothing (not `daysWithDelay.mjs`), no shared helper; `node --test` passes."
  ],
  "id": "T-02",
  "agent": "backend-dev",
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
      "at": "2026-10-06T14:15:56Z"
    }
  ],
  "worktree": "/tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/wt/T-02",
  "branch": "job/JOB-20261006-1408-repayment-delay-indicators-2-3--T-02",
  "md_workers": [
    {
      "role": "backend",
      "seat": "backend#2",
      "worker": "worker-seat-20261006-1408-backend-2-h1",
      "at": "2026-10-06T14:16:19Z"
    },
    {
      "role": "qa",
      "seat": "qa#2",
      "worker": "worker-seat-20261006-1408-qa-2-h1",
      "at": "2026-10-06T14:17:32Z"
    }
  ],
  "gate": {
    "result": "PASS",
    "head": "fa90fa21d7a16d80f00a4419b691d026cacf3d08",
    "attempt": 1,
    "log": "/tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/gates/T-02-a1-141659.log",
    "at": "2026-10-06T14:17:00Z"
  },
  "comments": [
    {
      "at": "2026-10-06T14:17:01.760Z",
      "author": "gate",
      "text": "PASS — 12 checks ok, 0 failed (T-02-a1-141659.log)"
    },
    {
      "at": "2026-10-06T14:18:16.346Z",
      "author": "qa-tester",
      "text": "pass (qa_verify PASS): AC-6 pass; AC-7 pass; AC-8 pass; AC-9 pass; AC-10 pass; AC-11 pass; AC-12 pass (11/11 integration tests)"
    }
  ],
  "qa_join": {
    "head": "609eaad8400a40bf34f50330ad5823893509ab1b",
    "qa_branch": "c924bdfc89cd23d8a5ee7e8033db5e8f183df12d",
    "at": "2026-10-06T14:17:21Z"
  },
  "qa": {
    "verdict": "pass",
    "head": "609eaad8400a40bf34f50330ad5823893509ab1b",
    "gate_head": "fa90fa21d7a16d80f00a4419b691d026cacf3d08",
    "qa_verify": "PASS",
    "log": "/tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/gates/T-02-qa-a1-141815.log",
    "summary": "AC-6 pass; AC-7 pass; AC-8 pass; AC-9 pass; AC-10 pass; AC-11 pass; AC-12 pass (11/11 integration tests)",
    "at": "2026-10-06T14:18:15Z"
  },
  "qas": [
    {
      "verdict": "pass",
      "head": "609eaad8400a40bf34f50330ad5823893509ab1b",
      "qa_verify": "PASS",
      "summary": "AC-6 pass; AC-7 pass; AC-8 pass; AC-9 pass; AC-10 pass; AC-11 pass; AC-12 pass (11/11 integration tests)",
      "at": "2026-10-06T14:18:15Z"
    }
  ]
}
SPEC: /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/specs/T-02.md
CHANGE: run `git -C /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/wt/T-02 diff job/JOB-20261006-1408-repayment-delay-indicators-2-3...HEAD` (and `--stat`).
QA RESULT: /tmp/claude-0/live/floor-par3/munder/repo/.work/JOB-20261006-1408-repayment-delay-indicators-2-3/out/T-02-qa.json
Check: acceptance criteria met, correctness bugs, security, test quality, scope.
OUTPUT — only JSON: {"verdict":"approve|changes","blocking":[{"file":"…","line":0,"issue":"…","fix":"…"}],"nits":["…"]}
Use "changes" only when there is at least one blocking item.
