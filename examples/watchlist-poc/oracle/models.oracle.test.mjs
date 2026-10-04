// Oracle — acceptance tests for the one-task slice in JOB-models.md / JOB-models-plain.md. NOT given to the agents:
// scripts/check-oracle.sh runs them against the delivered job branch.
import { test } from "node:test";
import assert from "node:assert/strict";
import { RATING_SCALE, notchChange } from "../src/ratings/notch.mjs";

test("C1: the rating scale has 19 steps, AAA best, CCC- worst", () => {
  assert.equal(RATING_SCALE.length, 19);
  assert.equal(RATING_SCALE[0], "AAA");
  assert.equal(RATING_SCALE[7], "BBB+");
  assert.equal(RATING_SCALE.at(-1), "CCC-");
});

test("C3: downgrade positive, upgrade negative, unchanged zero", () => {
  assert.equal(notchChange("BBB+", "BB+"), 3);
  assert.equal(notchChange("BB+", "BBB+"), -3);
  assert.equal(notchChange("A", "A"), 0);
  assert.equal(notchChange("AAA", "CCC-"), 18);
});

test("C1/C2: trimmed, case-insensitive; every invalid input throws RangeError", () => {
  assert.equal(notchChange(" bbb+ ", "BB+"), 3);
  assert.throws(() => notchChange("BBB+", "ZZZ"), RangeError);
  assert.throws(() => notchChange("", "A"), RangeError);
  assert.throws(() => notchChange(5, "A"), RangeError);
});
