import { test } from "node:test";
import assert from "node:assert/strict";
import { RATING_SCALE, notchChange, notchCalculator } from "../../src/ratings/notch.mjs";

test("scale", () => assert.equal(RATING_SCALE.length, 19));
test("notch change", () => {
  assert.equal(notchChange("BBB+", "BB+"), 3);
  assert.equal(notchChange("bb+ ", "BBB+"), -3);
  assert.throws(() => notchChange("BBB+", "nope"), RangeError);
});
test("calculator", () => {
  assert.deepEqual(notchCalculator("BBB+", "BB+"), { notches: 3, direction: "downgrade", wl: 2 });
  assert.deepEqual(notchCalculator("BBB+", "BBB-"), { notches: 2, direction: "downgrade", wl: 1 });
  assert.deepEqual(notchCalculator("A", "A"), { notches: 0, direction: "unchanged", wl: 0 });
});
