// the same edge cases against a delivered repo: node probe.mjs <repo>
const repo = process.argv[2];
const n = await import(`${repo}/src/ratings/notch.mjs`);
const c = await import(`${repo}/src/indicators/countryRating.mjs`);
const show = (f) => { try { const v = f(); return JSON.stringify(v); } catch (e) { return `${e.constructor.name}: ${String(e.message).slice(0, 70)}`; } };
const cases = [
  ["BBB+ → BB+ (the POC's miscounted example)", () => n.notchCalculator("BBB+", "BB+")],
  ["1-notch downgrade, calculator", () => n.notchCalculator("BBB+", "BBB")],
  ["upgrade, calculator", () => n.notchCalculator("BB+", "BBB+")],
  ["Indicator 12, 1 notch", () => c.countryRatingChangeWl("A", "A-")],
  ["lower case ' bbb+ ' → 'bb+'", () => n.notchChange(" bbb+ ", "bb+")],
  ["Unicode minus 'BBB−' (U+2212)", () => n.notchChange("BBB−", "BB+")],
  ["Moody's 'Baa1'", () => n.notchChange("Baa1", "BB+")],
  ["Moody's-looking 'Aaa'", () => n.notchChange("Aaa", "AA")],
  ["outlook suffix 'BBB+ (neg)'", () => n.notchChange("BBB+ (neg)", "BB+")],
  ["below the scale 'CC'", () => n.notchChange("CCC-", "CC")],
  ["null", () => n.notchChange(null, "A")],
  ["String object new String('A')", () => n.notchChange(new String("A"), "A")],
  ["RATING_SCALE frozen?", () => Object.isFrozen(n.RATING_SCALE) + " / " + n.RATING_SCALE.length],
];
for (const [label, f] of cases) console.log(`${label}\t${show(f)}`);
