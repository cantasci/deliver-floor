// Oracle for JOB-parallel.md (REQ-03-02, REQ-03-03) — run by scripts/check-oracle.sh, never shown to the agents.
import { test } from "node:test";
import assert from "node:assert/strict";
import { DAYS_WITH_DELAY_OPTIONS, daysWithDelayWl } from "../src/indicators/daysWithDelay.mjs";
import { DELAY_COUNT_OPTIONS, delayCountWl } from "../src/indicators/delayCount.mjs";

test("REQ-03-02: options and WL", () => {
  assert.deepEqual([...DAYS_WITH_DELAY_OPTIONS], ["no delay", "<=3 days", ">3 days", ">60 days", ">90 days"]);
  assert.deepEqual(DAYS_WITH_DELAY_OPTIONS.map(daysWithDelayWl), [0, 0, 2, 3, 4]);
  assert.equal(daysWithDelayWl("  >90 days "), 4);
  assert.throws(() => daysWithDelayWl("91 days"), RangeError);
});
test("REQ-03-03: options and WL", () => {
  assert.deepEqual([...DELAY_COUNT_OPTIONS], ["0", "1", ">1"]);
  assert.deepEqual(DELAY_COUNT_OPTIONS.map(delayCountWl), [0, 1, 2]);
  assert.throws(() => delayCountWl("2"), RangeError);
});
