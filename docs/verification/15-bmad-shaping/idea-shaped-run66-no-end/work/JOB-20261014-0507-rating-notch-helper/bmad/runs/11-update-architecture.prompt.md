Use the bmad-architecture skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0507-rating-notch-helper/bmad/out/ARCHITECTURE-SPINE.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-57 (question, bmad-spec) — BMad said: "Which WL rule does the profile-less notchCalculator use? ind11-13 is assumed, and ind12 is stricter at 1 and 2 notches. Confirm, and confirm the profile selector is dropped entirely."
  decided by the business: Confirm: notchCalculator(previous, current) has no profile argument and applies the ind11-13 rule (<=1 notch WL0, 2 WL1, 3+ WL2), as REQ-06-02's own example (2 notches -> WL1) matches it; ind12 stays internal to countryRatingChangeWl. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-58 (question, bmad-spec) — BMad said: "Does Moody's 'Aaa' fold to 'AAA' under the case-insensitive rule, or is it rejected? Ruling C1 does not name it, and the spec folds it."
  decided by the business: C1: the 19 S&P/Fitch steps AAA … CCC- only. Input is trimmed and case-insensitive ("bbb+" = "BBB+"); anything else — another notation (Moody's), an outlook suffix, a Unicode minus, unrated, a non-string — is rejected with a RangeError.
- B-60 (question, bmad-architecture) — BMad said: "Which WL rule does the profile-less notchCalculator use: ind11-13 (assumed) or ind12? Is the profile selector dropped entirely?"
  decided by the business: Same as B-57: notchCalculator(previous, current) has no profile argument and applies the ind11-13 rule; ind12 stays internal to countryRatingChangeWl. The profile selector is dropped entirely. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-61 (question, bmad-architecture) — BMad said: "Is 'Aaa' accepted as AAA (case-insensitive fold) or rejected as Moody's notation?"
  decided by the business: C1: the 19 S&P/Fitch steps AAA … CCC- only. Input is trimmed and case-insensitive ("bbb+" = "BBB+"); anything else — another notation (Moody's), an outlook suffix, a Unicode minus, unrated, a non-string — is rejected with a RangeError.

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).