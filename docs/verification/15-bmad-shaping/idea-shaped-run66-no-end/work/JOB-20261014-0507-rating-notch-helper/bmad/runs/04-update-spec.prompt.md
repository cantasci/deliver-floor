Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0507-rating-notch-helper/bmad/out/SPEC.md, .work/JOB-20261014-0507-rating-notch-helper/bmad/out/notch-wl-tables.md, .work/JOB-20261014-0507-rating-notch-helper/bmad/out/readiness.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-20 (question, bmad-spec) — BMad said: "The error-result shape is unspecified for `notchChange` (returns an integer) and `countryRatingChangeWl` (returns 0, 1 or 2). I assumed `notchCalculator` returns `{ error }` and the other two throw `Error`. Please confirm."
  decided by the business: notchCalculator returns { error: <message naming the offending input> }; notchChange and countryRatingChangeWl, whose return types the human fixed as an integer and 0|1|2, throw an Error naming the offending input. No number is ever guessed. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-21 (question, bmad-spec) — BMad said: "Please confirm `profile` as the third argument of `notchCalculator`."
  decided by the business: Confirm: notchCalculator(previous, current, profile), profile required, since B-2 makes the profile required and has no default. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-22 (question, bmad-spec) — BMad said: "Someone needs to own the correction to the POC text for REQ-06-02. It says BBB+ → BB+ is a 2-notch downgrade giving WL1."
  decided by the business: The PM records the POC text correction as a follow-up in the PR (REQ-06-02 example: BBB+ to BB+ is 3 notches, WL2); this delivery does not edit the POC document. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).