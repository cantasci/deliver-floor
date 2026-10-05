// QA (integration): REQ-06-02 through the module's public surface, as other POC parts will import it.
import { test } from "node:test";
import assert from "node:assert/strict";
import * as notch from "../../../src/ratings/notch.mjs";

const cases = [
  ["BBB+", "BB+", { notches: 3, direction: "downgrade", wl: 2 }],
  ["BBB+", "BBB-", { notches: 2, direction: "downgrade", wl: 1 }],
  ["BBB+", "BBB", { notches: 1, direction: "downgrade", wl: 0 }],
  ["BB", "BBB", { notches: -3, direction: "upgrade", wl: 0 }],
  ["AA", "AA", { notches: 0, direction: "unchanged", wl: 0 }],
];
for (const [p, c, want] of cases)
  test(`AC-2: ${p} → ${c} = ${JSON.stringify(want)}`, () => assert.deepEqual(notch.notchCalculator(p, c), want));

test("AC-1: the module exports the contract", () => {
  assert.deepEqual(Object.keys(notch).sort(), ["RATING_SCALE", "notchCalculator", "notchChange"]);
  assert.ok(Object.isFrozen(notch.RATING_SCALE) || notch.RATING_SCALE.length === 19);
});
test("AC-1: trimmed, case-insensitive; unknown → RangeError", () => {
  assert.equal(notch.notchChange(" bbb+ ", "bb+"), 3);
  for (const bad of ["ZZZ", "", undefined, null]) assert.throws(() => notch.notchChange(bad, "A"), RangeError);
});
