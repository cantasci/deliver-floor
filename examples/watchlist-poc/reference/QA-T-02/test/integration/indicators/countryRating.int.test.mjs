// QA (integration): REQ-03-12 — Indicator 12 uses the real notch calculator (no second scale).
import { test } from "node:test";
import assert from "node:assert/strict";
import { countryRatingChangeWl } from "../../../src/indicators/countryRating.mjs";
import { RATING_SCALE } from "../../../src/ratings/notch.mjs";

test("AC-3: 1 notch → 1, 2+ → 2, upgrade/unchanged → 0 (every adjacent pair of the scale)", () => {
  for (let i = 0; i + 1 < RATING_SCALE.length; i++) {
    assert.equal(countryRatingChangeWl(RATING_SCALE[i], RATING_SCALE[i + 1]), 1);
    assert.equal(countryRatingChangeWl(RATING_SCALE[i + 1], RATING_SCALE[i]), 0);
  }
  assert.equal(countryRatingChangeWl("BB", "B+"), 2);
  assert.equal(countryRatingChangeWl("AAA", "AAA"), 0);
});
test("AC-3: unknown ratings propagate RangeError", () => assert.throws(() => countryRatingChangeWl("X", "A"), RangeError));
