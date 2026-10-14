Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0507-rating-notch-helper/bmad/out/SPEC.md, .work/JOB-20261014-0507-rating-notch-helper/bmad/out/notch-wl-tables.md, .work/JOB-20261014-0507-rating-notch-helper/bmad/out/readiness.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-28 (question, bmad-architecture) — BMad said: "The Reviewer Gate was only partly run. lint_spine.py passed with 0 findings, but I did not dispatch the parallel subagent lenses (rubric walker, web-verification lens, adversarial two-builder lens). They should be run before downstream use."
  decided by the business: Accept: the lint passed; the independent review lenses run as the review round after shaping (bmad-review), before the architecture binds the job. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-29 (question, bmad-architecture) — BMad said: "Node 18 reached upstream end of life in April 2025 (from my own knowledge, not checked against the web). Should the floor stay at CLAUDE.md's 18+, or be raised to a supported LTS? The decision belongs to the human, and nothing in this design depends on it."
  decided by the business: Keep Node 18+ as in CLAUDE.md (the floor the project already states); no code depends on it, so raising it later changes nothing built. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-30 (assumption, bmad-architecture) — BMad said: "Paradigm is a functional core: a pure-function library in two one-way layers, with src/indicators importing src/ratings and never the reverse. It follows CLAUDE.md and B-5/B-6."
  decided by the business: Accept: functional core, two one-way layers, indicators import ratings only. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-31 (assumption, bmad-architecture) — BMad said: "The WL threshold tables live once, in src/ratings/notch.mjs, in a frozen map keyed by 'ind12' and 'ind11-13'. countryRatingChangeWl reads the ind12 entry through an internal export of notch.mjs that is not part of the public interface bound in B-5, so Ind. 12 cannot drift from the calculator."
  decided by the business: Other parts of the POC import exactly these. src/ratings/notch.mjs: RATING_SCALE (the 19 ratings, best first); notchChange(previous, current) → integer, positive = downgrade, negative = upgrade, 0 = unchanged; notchCalculator(previous, current) → { notches, direction: "downgrade" | "upgrade" | "unchanged", wl }, notches signed like notchChange. src/indicators/countryRating.mjs: countryRatingChangeWl(previous, current) → 0 | 1 | 2, built on notchChange.
- B-32 (assumption, bmad-architecture) — BMad said: "Validation is strict and shared: only strings exactly equal to one of the 19 RATING_SCALE entries are accepted, with no trimming or case folding. This follows B-3 and B-4."
  decided by the business: Accept: strict exact-match validation on the 19 RATING_SCALE strings, no trimming or case folding. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-33 (assumption, bmad-architecture) — BMad said: "A success result from notchCalculator never contains `error`, and an error result never contains `wl`. This shape rule is my inference from B-20."
  decided by the business: Accept: success results never carry error; error results never carry wl. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-34 (assumption, bmad-architecture) — BMad said: "Node.js 18+ is kept as the floor from CLAUDE.md. I did not web-verify it: no technology beyond Node built-ins is named, and the dev machine runs 22.11.0."
  decided by the business: Accept: Node 18+ floor kept, same as B-29. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-35 (assumption, bmad-architecture) — BMad said: "The existing .memlog.md from the spec run was reused and appended to, rather than re-initialised."
  decided by the business: Accept: BMad's working log is reused; it only affects BMad's own notes, not the code. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-36 (assumption, bmad-architecture) — BMad said: "The six architecture decisions (AD-1 to AD-6) are all inferred from the inputs, because no human was available."
  decided by the business: Accept AD-1..AD-6 as written; they are inferred from the spec and CLAUDE.md, and I confirm them with the human now. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-37 (decision, bmad-architecture) — BMad said: "Paradigm: functional core / pure-function library, two layers: ratings (domain primitives) <- indicators (POC rules). indicators may import ratings, never reverse. No I/O anywhere."
  decided by the business: Accept. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-38 (decision, bmad-architecture) — BMad said: "AD-2 single scale source: RATING_SCALE is the only rating->index mapping; every notch/WL computation goes via notchChange."
  decided by the business: Accept. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-39 (decision, bmad-architecture) — BMad said: "AD-3 WL threshold tables live once in notch.mjs (profiles ind12, ind11-13); countryRatingChangeWl reuses ind12, no re-implemented thresholds."
  decided by the business: Accept. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-40 (decision, bmad-architecture) — BMad said: "AD-4 error contract: notchCalculator returns {error}; notchChange & countryRatingChangeWl throw Error naming input. One shared validation; exact match on 19 ratings, no normalisation."
  decided by the business: C1: the 19 S&P/Fitch steps AAA … CCC- only. Input is trimmed and case-insensitive ("bbb+" = "BBB+"); anything else — another notation (Moody's), an outlook suffix, a Unicode minus, unrated, a non-string — is rejected with a RangeError.
- B-41 (decision, bmad-architecture) — BMad said: "AD-5 sign convention: positive=downgrade; WL>0 only for downgrades."
  decided by the business: Accept. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).