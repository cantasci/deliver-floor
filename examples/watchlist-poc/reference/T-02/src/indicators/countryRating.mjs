// Indicator 12 — country rating change (REQ-03-12): 1 notch → WL1, 2+ → WL2, upgrade/unchanged → WL0.
import { notchChange } from "../ratings/notch.mjs";

export function countryRatingChangeWl(previous, current) {
  const notches = notchChange(previous, current);
  return notches >= 2 ? 2 : notches === 1 ? 1 : 0;
}
