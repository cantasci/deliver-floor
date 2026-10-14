Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md, .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/scale-and-wl-mapping.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-110 (question, bmad-spec) — BMad said: "B-106: Node 18-20 do not expand globs in `node --test`. The exact script form (quoted glob or shell expansion) is left to the implementer; the requirement is that exactly the test/**/*.test.mjs files run."
  decided by the business: Plain Node.js ESM (.mjs), no dependencies; tests with node --test next to the code under test/.
- B-111 (question, bmad-spec) — BMad said: "B-100: the artifacts already said countryRating.test.mjs. The name countryRatingChange.test.mjs that BMad attributed to B-47 is not in any artifact, so I made no rename. Confirm B-47 is not stated that way elsewhere (for example in the architecture doc)."
  decided by the business: Confirmed: the drafted architecture is right — one plain Node ESM library at the repo root, code under src/, tests under test/, run with node --test. Keep it as the project's architecture.
- B-112 (question, bmad-spec) — BMad said: "Credit Policy: confirm the exact 19 default steps, inferred from AAA -> CCC- in REQ-03-10 (B-107)."
  decided by the business: Accept the 19-step default scale AAA..CCC- as the working assumption; Credit Policy confirmation is a follow-up listed in the PR, not a blocker. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-113 (question, bmad-spec) — BMad said: "Credit Policy: confirm the POC example BBB+ -> BB+ (3 notches, WL 2) and WL 0 at exactly 1 notch for Ind. 11 and 13 (unchanged)."
  decided by the business: Accept: follow the standard scale (BBB+ -> BB+ = 3 notches, WL 2) and keep the POC example out of passing tests; Credit Policy confirms as a follow-up. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-114 (question, bmad-spec) — BMad said: "Whoever supplies the ratings: Q2, the agency for the Other segment's country rating (unchanged)."
  decided by the business: Accept: out of scope (no source selection per segment); Q2 recorded as a follow-up for whoever supplies the ratings. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-120 (question, bmad-architecture) — BMad said: "B-106: package.json still has "test": "node --test". The spine now states the scoped script (test/**/*.test.mjs), but the package.json edit belongs to the build and was not made here. Who changes it?"
  decided by the business: Plain Node.js ESM (.mjs), no dependencies; tests with node --test next to the code under test/.
- B-121 (question, bmad-architecture) — BMad said: "B-100: the SPEC and companion (not in this update's scope) may still use another test file name. They should be checked and changed to countryRating.test.mjs."
  decided by the business: Have BMad align the SPEC and companion to the test file name countryRating.test.mjs in its next update. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-122 (question, bmad-architecture) — BMad said: "B-97, B-102, B-107: the companion's example and table and the SPEC should carry the BBB+ -> BBB- example, the new test rows and the 19-step note. They were not touched because only the spine was in scope."
  decided by the business: Have BMad carry the BBB+ -> BBB- example, the new test rows and the 19-step note into the SPEC and companion in its next update. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).