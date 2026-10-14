Use the bmad-architecture skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0846-rating-notch-helper/bmad/out/architecture-rating-notch-helper/ARCHITECTURE-SPINE.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-84 (question, bmad-spec) — BMad said: "B-79 says an injected scale needs 'canonical entries' without defining them. I read it as trimmed upper-case strings, the form rankOf compares against, and recorded that as an assumption. Please confirm it against rankOf."
  decided by the business: Accept BMad's reading: canonical entries of an injected scale are trimmed upper-case strings (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-85 (question, bmad-spec) — BMad said: "Follow-up for Credit Policy (B-69, same as B-1): confirm that BBB+ to BB+ is 3 notches, WL 2, and correct the POC. It stays out of the passing tests."
  decided by the business: Build with 3 notches / WL 2 for BBB+ → BB+ as the spec states; the POC correction is a follow-up for Credit Policy, listed in the PR, nothing blocks delivery (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-86 (question, bmad-spec) — BMad said: "Follow-up for Credit Policy (earlier B-6/B-23): confirm WL 0 at exactly 1 notch for Ind. 11 and 13."
  decided by the business: Build with WL 0 at exactly 1 notch for Ind. 11 and 13 as the spec assumes; the table is the one place to change; confirmation is a PR follow-up (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-87 (question, bmad-spec) — BMad said: "Follow-up for whoever supplies the ratings (B-70, same as B-3): Q2, the country rating source for the Other segment (Fitch, S&P or most conservative)."
  decided by the business: Out of scope for this library; record Q2 as a follow-up for whoever supplies the ratings (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-92 (question, bmad-architecture) — BMad said: "The SPEC and the companion may still say non-object options throws INVALID_INPUT, name the validation order, mention .gitkeep or a README note, or cite 'A4'. Confirm that the artifacts those decisions belong to are updated, so they don't diverge from the spine."
  decided by the business: Accept: the SPEC and companion already agree with the spine (non-object options -> UNKNOWN_INDICATOR; no .gitkeep or README change); no artifact change needed. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).