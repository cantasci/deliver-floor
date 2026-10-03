// Oracle — acceptance tests for the 2-requirement slice in JOB.md. They are NOT given to the agents:
// scripts/check-oracle.sh runs them against the delivered job branch, so they judge the result independently.
import { test } from "node:test";
import assert from "node:assert/strict";
import { RATING_SCALE, notchChange, notchCalculator } from "../src/ratings/notch.mjs";
import { countryRatingChangeWl } from "../src/indicators/countryRating.mjs";

test("C1: the rating scale has 19 steps, AAA best, CCC- worst", () => {
  assert.equal(RATING_SCALE.length, 19);
  assert.equal(RATING_SCALE[0], "AAA");
  assert.equal(RATING_SCALE[7], "BBB+");
  assert.equal(RATING_SCALE.at(-1), "CCC-");
});

test("notchChange: downgrade positive, upgrade negative, unchanged zero", () => {
  assert.equal(notchChange("BBB+", "BB+"), 3);
  assert.equal(notchChange("BBB+", "BBB-"), 2);
  assert.equal(notchChange("BB+", "BBB+"), -3);
  assert.equal(notchChange("A", "A"), 0);
  assert.equal(notchChange("AAA", "CCC-"), 18);
});

test("C1: input is trimmed and case-insensitive; unknown ratings throw RangeError", () => {
  assert.equal(notchChange(" bbb+ ", "BB+"), 3);
  assert.throws(() => notchChange("BBB+", "ZZZ"), RangeError);
  assert.throws(() => notchChange("", "A"), RangeError);
});

test("REQ-06-02 + C2: calculator reports notches, direction and WL (Indicator 13 thresholds)", () => {
  assert.deepEqual(notchCalculator("BBB+", "BB+"), { notches: 3, direction: "downgrade", wl: 2 });
  assert.deepEqual(notchCalculator("BBB+", "BBB-"), { notches: 2, direction: "downgrade", wl: 1 });
  assert.deepEqual(notchCalculator("BBB+", "BBB"), { notches: 1, direction: "downgrade", wl: 0 });
  assert.deepEqual(notchCalculator("BB", "BBB"), { notches: -3, direction: "upgrade", wl: 0 });
  assert.deepEqual(notchCalculator("AA", "AA"), { notches: 0, direction: "unchanged", wl: 0 });
});

test("REQ-03-12: country rating change — 1 notch → WL1, 2+ → WL2, upgrade/unchanged → WL0", () => {
  assert.equal(countryRatingChangeWl("BB", "BB-"), 1);
  assert.equal(countryRatingChangeWl("BB", "B+"), 2);
  assert.equal(countryRatingChangeWl("BBB", "B"), 2);
  assert.equal(countryRatingChangeWl("BB-", "BB"), 0);
  assert.equal(countryRatingChangeWl("AAA", "AAA"), 0);
  assert.throws(() => countryRatingChangeWl("X", "AAA"), RangeError);
});
