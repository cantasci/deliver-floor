Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md, .work/JOB-20261014-0631-rating-notch-helper/bmad/out/spec-rating-notch-helper/rating-scale-and-wl.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-15 (question, bmad-spec) — BMad said: "Follow-up from B-1: correct the REQ-06-02 text in the POC document (BBB+ to BB+, 3 notches, WL 2). Who owns the edit?"
  decided by the business: The POC document's owner corrects REQ-06-02 outside this job; this job does not edit it and lists it as a follow-up in the PR (dl followup). (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-16 (question, bmad-spec) — BMad said: "What does 'C8' in B-12 refer to? Confirm it means the displayed-result criterion."
  decided by the business: Confirm: 'C8' means the displayed-result criterion (displayed = the returned { notches, direction, wl }); no UI, CLI or printed output. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).