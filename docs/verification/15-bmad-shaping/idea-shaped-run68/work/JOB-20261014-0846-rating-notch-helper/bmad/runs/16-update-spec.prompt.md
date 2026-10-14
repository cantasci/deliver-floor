Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md, .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/scale-and-wl-mapping.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-97 (finding) — BMad said: "Passing example ' BBB+ ' -> BB+ (Ind. 11) is the BBB+ -> BB+ pair that B-1 keeps out of passing tests; use a different pair."
  decided by the PM: Replace the passing example with BBB+ -> BBB- (2 notches, Ind. 11 WL 1); BBB+ -> BB+ stays out of passing tests.
- B-98 (finding) — BMad said: "B-12 (22-grade default) is contradicted by B-54/B-19/B-11 (19-step default); artifacts follow the 19-step default but B-12 is never withdrawn."
  decided by the business: Withdraw B-12: the default scale is the 19-step AAA…CCC-; CC, C, D are rejected unless a scale is injected. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-99 (finding) — BMad said: "B-34 told other POC parts to import notchCalculator(previous, current); B-62/B-68 require options.indicator, so two-arg calls throw UNKNOWN_INDICATOR. Consumers must be told."
  decided by the business: Tell the other POC parts: call notchCalculator(previous, current, {indicator}); two-arg calls throw UNKNOWN_INDICATOR. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-100 (finding) — BMad said: "Test file name countryRating.test.mjs differs from B-47's countryRatingChange.test.mjs; pick one name."
  decided by the PM: Use countryRating.test.mjs everywhere, matching the source file countryRating.mjs.
- B-101 (finding) — BMad said: "AD-6 says result objects are frozen; spec and companion do not state it."
  decided by the PM: State in the spec that notchCalculator results are frozen plain objects, as AD-6 says.
- B-102 (finding) — BMad said: "Missing test rows: non-integer notches, indicator as string '12', bad entries in an injected scale, injected scale with CC, Ind. 11 at n >= 3."
  decided by the PM: Add test rows: non-integer notches, indicator as string '12', bad entries in an injected scale, injected scale with CC, Ind. 11 at n >= 3.
- B-103 (finding) — BMad said: "Purity and layering tests are underspecified: regex comment/string stripping is fragile and property names can false-positive."
  decided by the PM: Purity/layering tests check import specifiers by parsing import lines and fail on I/O module imports; no regex stripping of comments or strings.
- B-104 (finding) — BMad said: "Helpers and fixtures are said to live outside test/ but no directory is named."
  decided by the PM: Test helpers and fixtures live in test/helpers/ (not matched by *.test.mjs).
- B-105 (finding) — BMad said: "Delivery-checklist items NFR-performance, PRD-priority, PRD-users, NFR-privacy, NFR-audit, NFR-observability and NFR-compliance are not answered, even with 'none'."
  decided by the PM: Answer the remaining checklist items as 'none / not applicable' with a one-line reason: pure in-memory library, no data, no users, no I/O.
- B-106 (finding) — BMad said: "Bare node --test at the repo root may also run tests under .work/.../wt/_integration/test; scope the npm test script."
  decided by the PM: Scope npm test to test/**/*.test.mjs so worktree copies under .work/ are not run.
- B-107 (finding) — BMad said: "The exact 19 steps are inferred from 'AAA -> CCC-' in REQ-03-10; note it for Credit Policy confirmation."
  decided by the PM: Note in follow-ups that the exact 19 steps are inferred from AAA -> CCC- in REQ-03-10; Credit Policy to confirm.
- B-108 (finding) — BMad said: "Layer dependency line implies watchlist depends on scale; it only needs errors."
  decided by the PM: Fix the layer line: watchlist imports only errors; notch imports scale and watchlist.
- B-109 (finding) — BMad said: "Exports wlFromNotches and RatingError go beyond B-34's list; state that they are importable."
  decided by the PM: State that wlFromNotches and RatingError are importable public names.

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).