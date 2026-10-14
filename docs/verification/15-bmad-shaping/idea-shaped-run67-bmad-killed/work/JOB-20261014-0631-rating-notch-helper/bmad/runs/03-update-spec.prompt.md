Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md, .work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/rating-scale-and-wl.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-1 (question, bmad-spec) — BMad said: "REQ-06-02 says BBB+ to BB+ is 2 notches and WL 1. On the standard scale it is 3 notches (BBB, BBB-, BB+), which gives WL 2 under either rule set. Is the example wrong, or is a different scale used?"
  decided by the business: Trust the scale: BBB+ to BB+ is 3 notches, WL 2. Treat the REQ-06-02 example (2 notches, WL 1) as a documentation slip; record a follow-up so the POC text is corrected. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-2 (question, bmad-spec) — BMad said: "Ind. 12 (1 notch = WL 1, 2+ = WL 2) conflicts with REQ-06-02 and Ind. 11/13 (2 notches = WL 1, 3+ = WL 2). Should the helper take an indicator kind, or apply a single rule set? If a single one, which?"
  decided by the business: Take the indicator kind as an explicit input (country | internal | external), each with its own thresholds as the POC states them. No single rule set. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-3 (question, bmad-spec) — BMad said: "Is the Excel dropdown sheet (A4) available? It is not in the repo. It would settle the scale, the two questions above, and the WL for a 1-notch downgrade on Ind. 11/13."
  decided by the business: A 1-notch downgrade gives calculator WL 0 (Indicator 13 starts at 2 notches); Indicator 12 stays 1 notch → WL 1.
- B-4 (question, bmad-spec) — BMad said: "How should NR, WR, SD, D and outlook or watch changes be treated? The spec currently treats them as errors."
  decided by the business: Accept BMad's reading: NR, WR, SD, D and unknown symbols return an explicit error; outlook/watch changes are not rating symbols and are out of scope. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-5 (question, bmad-spec) — BMad said: "Q2: for the Other segment, does the country rating need agency awareness (S&P, Moody's, Fitch or most conservative), or are rating symbols enough?"
  decided by the business: Rating symbols are enough; no agency awareness in this helper. Agency choice stays with the Ind. 13 form and segment logic (non-goal). (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-6 (assumption, bmad-spec) — BMad said: "One 21-notch scale (AAA to C) is shared by S&P and Fitch, and Moody's symbols map onto the same positions."
  decided by the business: Accept: one 21-notch scale, Moody's symbols mapped to the same positions. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-7 (assumption, bmad-spec) — BMad said: "No change, an upgrade, or a downgrade below the first threshold gives WL 0. The POC states only the thresholds, so a 1-notch downgrade is assumed to give WL 0 for Ind. 11 and 13."
  decided by the business: A 1-notch downgrade gives calculator WL 0 (Indicator 13 starts at 2 notches); Indicator 12 stays 1 notch → WL 1.
- B-8 (assumption, bmad-spec) — BMad said: "Notch change is signed so that a downgrade is positive and an upgrade is negative, which matches WL where higher is worse."
  decided by the business: notchCalculator(...).notches is signed exactly like notchChange: downgrade positive, upgrade negative (BB → BBB is -3); direction says the same in words.
- B-9 (assumption, bmad-spec) — BMad said: "The indicator kind (country, internal or external) is an explicit input, because the WL thresholds differ between Ind. 12 and Ind. 11/13."
  decided by the business: Accept: the kind is an explicit input. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-10 (assumption, bmad-spec) — BMad said: "The code goes in src/ratings (scale and notch difference) and src/indicators (WL rules) as pure functions, following CLAUDE.md."
  decided by the business: Accept: pure functions, scale and notch difference in src/ratings, WL rules in src/indicators (matches CLAUDE.md). (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-11 (assumption, bmad-spec) — BMad said: "I ran in express mode (the request is short, and the POC document supplies the rest). The spec is logic only, with no screens or fetching."
  decided by the business: Accept: logic only, no screens or fetching; the request says it is not about screens. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-12 (decision, bmad-spec) — BMad said: "Non-goals: screens/UI, web fetching/scraping of ratings (REQ-02-02 fetch part), Ind. 11/13 form fields, segment/agency selection (Q2), overall WL aggregation"
  decided by the business: C8 stands: 'displayed' is met by the returned { notches, direction, wl }; the POC screens are built later by other parts. No UI, CLI or printed output in this slice.
- B-13 (decision, bmad-spec) — BMad said: "Helper takes explicit indicator parameter (country|internal|external) because thresholds differ; REQ-06-02 has none"
  decided by the business: Accept: explicit kind parameter. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-14 (decision, bmad-spec) — BMad said: "Companion rating-scale-and-wl.md holds scale table, WL tables, worked examples, I/O shapes"
  decided by the business: Accept: the companion file holds the scale, WL tables, examples and shapes. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).