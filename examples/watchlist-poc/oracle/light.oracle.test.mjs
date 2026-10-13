// Oracle — acceptance tests for JOB-light.md (Indicator 13 on top of the delivered watchlist slice). Not given to the agents.
import { test } from "node:test";
import assert from "node:assert/strict";
import { externalRatingChangeWl } from "../src/indicators/externalRating.mjs";
import { notchChange } from "../src/ratings/notch.mjs";
import { countryRatingChangeWl } from "../src/indicators/countryRating.mjs";

test("REQ-03-13: 2 notch downgrade → WL 1, 3+ → WL 2", () => {
  assert.equal(externalRatingChangeWl("BBB+", "BBB-"), 1);
  assert.equal(externalRatingChangeWl("BBB+", "BB+"), 2);
  assert.equal(externalRatingChangeWl("AAA", "CCC-"), 2);
});

test("1-notch downgrade, upgrade and unchanged → WL 0", () => {
  assert.equal(externalRatingChangeWl("A", "A-"), 0);
  assert.equal(externalRatingChangeWl("BB+", "BBB+"), 0);
  assert.equal(externalRatingChangeWl("A", "A"), 0);
});

test("ratings read like notchChange: trimmed, case-insensitive, else RangeError", () => {
  assert.equal(externalRatingChangeWl(" bbb+ ", "bb+"), 2);
  assert.throws(() => externalRatingChangeWl("BBB+", "ZZZ"), RangeError);
});

test("the existing exports are unchanged", () => {
  assert.equal(notchChange("BBB+", "BB+"), 3);
  assert.equal(countryRatingChangeWl("A", "A-"), 1);
});
