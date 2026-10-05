// Rating notch calculator — REQ-06-02 (JOB.md C1–C3).
export const RATING_SCALE = Object.freeze([
  "AAA", "AA+", "AA", "AA-", "A+", "A", "A-",
  "BBB+", "BBB", "BBB-", "BB+", "BB", "BB-",
  "B+", "B", "B-", "CCC+", "CCC", "CCC-",
]);

const indexOf = (rating) => {
  const i = RATING_SCALE.indexOf(String(rating ?? "").trim().toUpperCase());
  if (i === -1) throw new RangeError(`unknown rating: ${JSON.stringify(rating)}`);
  return i;
};

/** Positive = downgrade, negative = upgrade, 0 = unchanged. */
export const notchChange = (previous, current) => indexOf(current) - indexOf(previous);

/** WL under the Indicator 13 thresholds: 2 notches → 1, 3+ → 2. */
export function notchCalculator(previous, current) {
  const notches = notchChange(previous, current);
  const direction = notches > 0 ? "downgrade" : notches < 0 ? "upgrade" : "unchanged";
  const wl = notches >= 3 ? 2 : notches === 2 ? 1 : 0;
  return { notches, direction, wl };
}
