Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-1 (question, bmad-spec) — BMad said: "OQ-1: The REQ-06-02 example BBB+ → BB+ is 3 notches on the standard scale (BBB+, BBB, BBB-, BB+), not the 2 the request says. Is the scale different (for example, no BBB-), or is the example wrong? If 3 notches is right, WL would be 2 under the Ind. 13 thresholds. The example test is blocked until this is settled."
  decided by the business: C2 stands: the POC example miscounts. BBB+ → BB+ is 3 notches → calculator WL 2; the 2-notch example is BBB+ → BBB- → WL 1.
- B-2 (question, bmad-spec) — BMad said: "OQ-2: What exactly is RATING_SCALE? Does it include D/SD or CC/C, and does the internal scale in REQ-03-10 (AAA → CCC-) differ from the external one?"
  decided by the business: C1 stands: only the 19-step S&P-style scale in this slice; anything else is rejected with a RangeError.
- B-3 (question, bmad-spec) — BMad said: "OQ-3: Which WL thresholds does the calculator use: Ind. 13, Ind. 12 or Ind. 11? REQ-06-02 gives only the one example."
  decided by the business: Calculator WL uses the Ind. 13 thresholds (2 notches → WL=1, 3+ → WL=2), the only rule that fits the REQ-06-02 example's wording. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-4 (question, bmad-spec) — BMad said: "OQ-4: Should unknown ratings throw (the assumed behaviour) or return null or an error object?"
  decided by the business: Unknown ratings throw an Error naming the value. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-5 (assumption, bmad-spec) — BMad said: "The scale is S&P/Fitch style, best first: AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-, CC, C, D. Moody's notation, NR and SD are not accepted."
  decided by the business: C1 stands: only the 19-step S&P-style scale in this slice; anything else is rejected with a RangeError.
- B-6 (assumption, bmad-spec) — BMad said: "The calculator's WL uses the Ind. 13 thresholds: a downgrade of 0–1 notches gives WL 0, 2 notches gives WL 1, 3+ gives WL 2. Upgrades and unchanged ratings give WL 0. I chose these because the REQ-06-02 example (2 notches → WL=1) fits them."
  decided by the business: Accept: Ind. 13 thresholds, upgrades and unchanged → WL 0. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-7 (assumption, bmad-spec) — BMad said: "countryRatingChangeWl returns 0 for an unchanged rating or an upgrade. Only downgrades count."
  decided by the business: Accept: unchanged or upgrade → WL 0; only downgrades count. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-8 (assumption, bmad-spec) — BMad said: "notchCalculator.notches is the absolute magnitude (>= 0), and direction carries the sign."
  decided by the business: notchCalculator(...).notches is signed exactly like notchChange: downgrade positive, upgrade negative (BB → BBB is -3); direction says the same in words.
- B-9 (assumption, bmad-spec) — BMad said: "Unknown, non-string or empty ratings throw an Error naming the offending value, with no silent fallback. Ratings match exactly (case-sensitive, trimmed)."
  decided by the business: Accept: throw on unknown/empty/non-string; exact case-sensitive match after trim. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-10 (assumption, bmad-spec) — BMad said: "'Auto-filled value editable', scraping, the 12-month lookup and any UI are out of scope, because the slice has no UI or data source."
  decided by the business: The caller passes the rating the analyst confirmed or edited. No override parameter, no persistence, no audit trail in this slice.
- B-11 (decision, bmad-spec) — BMad said: "Non-goals: UI, scraping/public source, editable auto-fill, 12-month lookup, Ind.11/13 functions, agency selector, final WL aggregation"
  decided by the business: The caller passes the rating the analyst confirmed or edited. No override parameter, no persistence, no audit trail in this slice.

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).