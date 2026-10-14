Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md, .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/scale-and-wl-mapping.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-58 (question, bmad-spec) — BMad said: "Confirm that `notchCalculator(previous, current)` returns `wl` for Ind. 12, and that the object-style `notchHelper` and `countryRatingChange` returning `{notches, direction, wl}` are dropped."
  decided by the business: Confirmed: the drafted architecture is right — one plain Node ESM library at the repo root, code under src/, tests under test/, run with node --test. Keep it as the project's architecture.
- B-62 (question, bmad-architecture) — BMad said: "Which indicator does notchCalculator(previous, current) use for wl? AD-5 and B-55 allow no default indicator, but the decided signature has no indicator argument. The spine assumes Ind. 12 through options.indicator. A human should confirm or fix this."
  decided by the business: No default indicator, as the human decided in B-2: notchCalculator takes options.indicator (11, 12 or 13) as required, and a missing or other value throws UNKNOWN_INDICATOR. The Ind. 12 default is dropped. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).