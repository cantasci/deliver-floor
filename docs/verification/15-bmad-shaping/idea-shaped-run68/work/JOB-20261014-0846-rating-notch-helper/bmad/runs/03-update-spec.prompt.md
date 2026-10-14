Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md, .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/scale-and-wl-mapping.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-1 (question, bmad-spec) — BMad said: "Conflict in REQ-06-02: BBB+ to BB+ is stated as 2 notches, WL 1. On the standard scale it is 3 notches, WL 2. Is the example wrong, or does the business scale lack a grade?"
  decided by the business: The POC example is wrong: compute BBB+ to BB+ on the standard scale (3 notches, WL 2); keep it out of the passing tests and record it as a follow-up for Credit Policy. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-2 (question, bmad-spec) — BMad said: "Conflict in the WL rules: Ind. 12 gives WL 2 at 2 notches, while Ind. 11 and 13 give WL 1. Does the helper take the indicator from the caller (assumed), or always use one profile?"
  decided by the business: The caller names the indicator (11, 12 or 13); the helper has no default profile. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-3 (question, bmad-spec) — BMad said: "Q2 from the POC: for the Other segment, is the country rating from Fitch, S&P or the most conservative of the three? This does not block the helper, but whoever supplies the ratings needs the answer."
  decided by the business: Out of scope for this helper because ratings come in as input; record Q2 as a follow-up for whoever supplies the ratings. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-4 (question, bmad-spec) — BMad said: "Is scraping sovereign ratings (REQ-02-02) part of this delivery or a later one? Assumed later."
  decided by the business: Only REQ-06-02 (the notch calculator helper) and REQ-03-12 (Indicator 12, country rating change). Fetching ratings from a public source, screens, persistence and every other indicator are out of scope; REQ-03-13 matters only for the thresholds of the calculator's WL (C2).
- B-5 (question, bmad-spec) — BMad said: "Should the scale include Moody's notation? Do CC, C and D count for sovereigns?"
  decided by the business: C1 stands: only the 19-step S&P-style scale in this slice; anything else is rejected with a RangeError.
- B-6 (question, bmad-spec) — BMad said: "Confirm with Credit Policy that Ind. 11 at 1 notch gives WL 0."
  decided by the business: Ship WL 0 at 1 notch for Ind. 11 as an assumption, kept in one table so Credit Policy can change it in one place; follow-up to confirm. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-7 (question, bmad-spec) — BMad said: "Confirm this is a library only, with no CLI or API."
  decided by the business: Library only: no CLI, no API, imported from src/. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-8 (assumption, bmad-spec) — BMad said: "Positive notch change means downgrade. An upgrade or no change gives WL 0."
  decided by the business: Accept: a positive notch change is a downgrade, and an upgrade or no change gives WL 0. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-9 (assumption, bmad-spec) — BMad said: "The library sits in src/ratings/ (scale, notch, WL mapping) and src/indicators/ (Ind. 12), as CLAUDE.md names those folders."
  decided by the business: Accept: ratings and WL mapping in src/ratings/, the Ind. 12 evaluator in src/indicators/. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-10 (assumption, bmad-spec) — BMad said: "Errors are thrown as RatingError with a code of UNKNOWN_RATING, INVALID_INPUT or UNKNOWN_INDICATOR. The repo has no convention yet."
  decided by the business: Accept RatingError with codes UNKNOWN_RATING, INVALID_INPUT and UNKNOWN_INDICATOR. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-11 (assumption, bmad-spec) — BMad said: "Input is trimmed and case-insensitive, and a Unicode minus counts as '-'. Outlooks, NR/WR and Moody's notation are rejected."
  decided by the business: C1: the 19 S&P/Fitch steps AAA … CCC- only. Input is trimmed and case-insensitive ("bbb+" = "BBB+"); anything else — another notation (Moody's), an outlook suffix, a Unicode minus, unrated, a non-string — is rejected with a RangeError.
- B-12 (assumption, bmad-spec) — BMad said: "The default scale is S&P/Fitch AAA to D (22 grades). The internal scale (AAA to CCC-) is its first 19 grades."
  decided by the business: Accept the 22-grade S&P/Fitch default scale, passed as data, with the internal scale as its first 19 grades. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-13 (assumption, bmad-spec) — BMad said: "Ind. 11 and Ind. 13 give WL 0 at exactly 1 notch. The POC lists that option but gives no WL."
  decided by the business: Accept WL 0 at exactly 1 notch for Ind. 11 and 13, as in B-6. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-14 (assumption, bmad-spec) — BMad said: "The caller names the indicator (11, 12 or 13) for the WL, and there is no default."
  decided by the business: Accept: the caller names the indicator, with no default. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-15 (assumption, bmad-spec) — BMad said: "The caller supplies the rating from 12 months ago, so there is no date logic."
  decided by the business: Accept: the caller supplies the rating from 12 months ago, so there is no date logic. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-16 (assumption, bmad-spec) — BMad said: "Scraping or fetching ratings is out of scope, because CLAUDE.md forbids I/O in src/ratings and src/indicators. The helper takes ratings as input and has no UI."
  decided by the business: Only REQ-06-02 (the notch calculator helper) and REQ-03-12 (Indicator 12, country rating change). Fetching ratings from a public source, screens, persistence and every other indicator are out of scope; REQ-03-13 matters only for the thresholds of the calculator's WL (C2).
- B-17 (decision, bmad-spec) — BMad said: "Fetch/scrape of sovereign ratings (REQ-02-02 fetch half) out of scope: needs I/O, source and Q2 undecided; helper consumes ratings passed in"
  decided by the business: Only REQ-06-02 (the notch calculator helper) and REQ-03-12 (Indicator 12, country rating change). Fetching ratings from a public source, screens, persistence and every other indicator are out of scope; REQ-03-13 matters only for the thresholds of the calculator's WL (C2).
- B-18 (decision, bmad-spec) — BMad said: "No screens/UI (REQ-06-02 screen, REQ-03-14 row display belong to other epics)"
  decided by the business: C8 stands: 'displayed' is met by the returned { notches, direction, wl }; the POC screens are built later by other parts. No UI, CLI or printed output in this slice.

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).