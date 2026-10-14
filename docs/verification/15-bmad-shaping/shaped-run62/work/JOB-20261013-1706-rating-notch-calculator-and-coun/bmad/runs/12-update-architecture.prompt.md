Use the bmad-architecture skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-38 (question, bmad-architecture) — BMad said: "Should the reviewer-gate lens subagents be run on the updated spine before downstream use? Headless normally requires them, and this run skipped them."
  decided by the business: No: do not run the reviewer-gate lens subagents on the spine. Only the deterministic lint check ran (0 findings), and the independent bmad-review round that follows shaping reviews the updated spine anyway. Nothing built changes. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).