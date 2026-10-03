import { test } from "node:test";
import assert from "node:assert/strict";
import { countryRatingChangeWl } from "../../../src/indicators/countryRating.mjs";

test("Ind. 12 thresholds", () => {
  assert.equal(countryRatingChangeWl("BB", "BB-"), 1);
  assert.equal(countryRatingChangeWl("BB", "B+"), 2);
  assert.equal(countryRatingChangeWl("BB-", "BB"), 0);
});
