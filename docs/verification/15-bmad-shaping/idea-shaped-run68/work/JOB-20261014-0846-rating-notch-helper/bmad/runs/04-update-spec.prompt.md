Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md, .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/scale-and-wl-mapping.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-19 (question, bmad-spec) — BMad said: "Confirm CC, C and D are out for this slice, given the 22-grade default accepted in B-12 and the 19-step rule in C1."
  decided by the business: CC, C and D are out for this slice: only the 19-step scale is valid and they are rejected as UNKNOWN_RATING. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-20 (question, bmad-spec) — BMad said: "Confirm RatingError extending RangeError satisfies both the RangeError rule and the three error codes."
  decided by the business: Accept: RatingError extends RangeError, so both the RangeError rule and the three error codes hold. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-21 (question, bmad-spec) — BMad said: "Confirm the direction values 'downgrade', 'upgrade' and 'none'; B-18 names the field but not its values."
  decided by the business: notchCalculator(...).notches is signed exactly like notchChange: downgrade positive, upgrade negative (BB → BBB is -3); direction says the same in words.
- B-22 (question, bmad-spec) — BMad said: "Follow-up for Credit Policy: confirm BBB+ to BB+ is 3 notches, WL 2, and correct the POC REQ-06-02 example."
  decided by the business: Record as a follow-up for Credit Policy to confirm BBB+ to BB+ is 3 notches, WL 2, and correct the POC; keep it out of the passing tests. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-23 (question, bmad-spec) — BMad said: "Follow-up for Credit Policy: confirm WL 0 at 1 notch for Ind. 11 and 13."
  decided by the business: Record as a follow-up for Credit Policy to confirm WL 0 at 1 notch for Ind. 11 and 13; the table is the one place to change. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-24 (question, bmad-spec) — BMad said: "Follow-up for whoever supplies the ratings: Q2, the country rating source for the Other segment (Fitch, S&P or the most conservative)."
  decided by the business: Record as a follow-up for whoever supplies the ratings; out of scope for this helper. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).