// Oracle — acceptance tests for JOB-light2.md (isInvestmentGrade). Not given to the agents.
import { test } from "node:test";
import assert from "node:assert/strict";
import { isInvestmentGrade, notchChange, RATING_SCALE } from "../src/ratings/notch.mjs";

test("AAA … BBB- are investment grade, BB+ … CCC- are not", () => {
  for (const r of RATING_SCALE.slice(0, 10)) assert.equal(isInvestmentGrade(r), true, r);
  for (const r of RATING_SCALE.slice(10)) assert.equal(isInvestmentGrade(r), false, r);
});

test("read like notchChange: trimmed, case-insensitive, else RangeError", () => {
  assert.equal(isInvestmentGrade(" bbb- "), true);
  assert.equal(isInvestmentGrade("bb+"), false);
  assert.throws(() => isInvestmentGrade("ZZZ"), RangeError);
});

test("the existing exports are unchanged", () => {
  assert.equal(RATING_SCALE.length, 19);
  assert.equal(notchChange("BBB+", "BB+"), 3);
});
