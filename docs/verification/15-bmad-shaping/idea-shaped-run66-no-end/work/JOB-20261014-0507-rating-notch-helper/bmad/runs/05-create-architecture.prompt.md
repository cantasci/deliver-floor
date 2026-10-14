Use the bmad-architecture skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: create
slug: rating-notch-helper
Write your artifacts under .work/JOB-20261014-0507-rating-notch-helper/bmad/out/ (your output folder).
Inputs:
- The request, all of it: .work/JOB-20261014-0507-rating-notch-helper/bmad/inputs/request.md (it names its requirements file; read that too)
- The repo: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/idea-shaped/idea/repo — no code yet
- For your information — what our delivery team needs to know before it can cut tasks (a checklist, not instructions; items that do not apply to this request do not apply): .work/JOB-20261014-0507-rating-notch-helper/bmad/inputs/delivery-checklist.yaml
Artifacts BMad already made for this request (settled — build on them):
- bmad-spec: .work/JOB-20261014-0507-rating-notch-helper/bmad/out/SPEC.md, .work/JOB-20261014-0507-rating-notch-helper/bmad/out/notch-wl-tables.md, .work/JOB-20261014-0507-rating-notch-helper/bmad/out/readiness.md
Decisions already taken on what BMad said (binding):
- B-1 (question, bmad-spec) — BMad said: "Conflict in the POC: REQ-06-02 says BBB+ to BB+ is a 2-notch downgrade giving WL1. On the 19-step scale it is 3 notches (BBB+, BBB, BBB-, BB+), which gives WL2. Which is right, the example or the scale?"
  decided by the business: The scale is right and the POC example is wrong: BBB+ to BB+ is 3 notches, WL2 under the Ind. 11/13 rule. The test uses 3/WL2 and the POC text is flagged for correction. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-2 (question, bmad-spec) — BMad said: "Conflict in the POC: Ind. 12 gives 1 notch WL1 and 2+ notches WL2. Ind. 11 and 13 give 2 notches WL1 and 3+ notches WL2. Does the calculator take an indicator selector, and what is the default?"
  decided by the business: The caller picks the WL rule through a required profile argument ('ind12' or 'ind11-13'); there is no hidden default, and a missing or unknown profile is an error result. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-3 (question, bmad-spec) — BMad said: "Q2: which agency's scale applies to the Other segment, and must Moody's notation (Aaa, Baa1 and so on) be accepted?"
  decided by the business: Only the 19-step S&P/Fitch notation is accepted; Moody's notation is an error result. Choosing the agency for Other stays with Credit Policy (Q2), outside this helper. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-4 (question, bmad-spec) — BMad said: "Are ratings below CCC- (CC, C, D/SD) and outlook or watch suffixes accepted or rejected?"
  decided by the business: Anything outside the 19 listed ratings is an error result: CC, C, D/SD, and suffixes such as '(neg)'. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-5 (question, bmad-spec) — BMad said: "Interface (CON-interface, CON-errors): function names, input normalisation (case, whitespace, '-' variants) and return shape (result object or throw). The readiness file proposes defaults."
  decided by the business: Other parts of the POC import exactly these. src/ratings/notch.mjs: RATING_SCALE (the 19 ratings, best first); notchChange(previous, current) → integer, positive = downgrade, negative = upgrade, 0 = unchanged; notchCalculator(previous, current) → { notches, direction: "downgrade" | "upgrade" | "unchanged", wl }, notches signed like notchChange. src/indicators/countryRating.mjs: countryRatingChangeWl(previous, current) → 0 | 1 | 2, built on notchChange.
- B-6 (question, bmad-spec) — BMad said: "ARC-style, ARC-components, ARC-layer, ARC-stack, ARC-deps: confirm a Node ESM library with no dependencies. The request names no language and CLAUDE.md is the only evidence."
  decided by the business: Plain Node.js ESM (.mjs), no dependencies; tests with node --test next to the code under test/.
- B-7 (question, bmad-spec) — BMad said: "ARC-data, ARC-integration, DEL-deploy: confirm there is no store, no external call and no deployment (import-only). ARC-ui is settled by the request: 'not about screens'."
  decided by the business: C8 stands: 'displayed' is met by the returned { notches, direction, wl }; the POC screens are built later by other parts. No UI, CLI or printed output in this slice.
- B-8 (question, bmad-spec) — BMad said: "PRD-priority: REQ-06-02 is Should and Ind. 12 is Must. Do they ship together, or does Ind. 12 go first?"
  decided by the business: REQ-06-02 comes first (Must); REQ-03-12 follows (Should).
- B-9 (assumption, bmad-spec) — BMad said: "Rating scale is the 19-step S&P/Fitch scale AAA to CCC-, taken from the POC's Ind. 10 dropdown (AAA to CCC-)."
  decided by the business: Accept: 19-step scale AAA to CCC-. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-10 (assumption, bmad-spec) — BMad said: "Any caller other than Ind. 12 uses the Ind. 11/13 thresholds. One notch under that rule gives WL0, because the POC states no WL for it."
  decided by the business: Accept: under the Ind. 11/13 rule 1 notch gives WL0. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-11 (assumption, bmad-spec) — BMad said: "A downgrade is a positive notch count. Only downgrades give WL above 0; upgrades and no change give WL0."
  decided by the business: Accept: a downgrade is positive; upgrade and no change give WL0. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-12 (assumption, bmad-spec) — BMad said: "The helper only does the calculation. Fetching ratings and their 12-month history is out of scope."
  decided by the business: Only REQ-06-02 (the notch calculator helper) and REQ-03-12 (Indicator 12, country rating change). Fetching ratings from a public source, screens, persistence and every other indicator are out of scope; REQ-03-13 matters only for the thresholds of the calculator's WL (C2).
- B-13 (assumption, bmad-spec) — BMad said: "Node 18+ ESM with no dependencies, placed in src/ratings and src/indicators, comes from CLAUDE.md, not from the request."
  decided by the business: Plain Node.js ESM (.mjs), no dependencies; tests with node --test next to the code under test/.
- B-14 (assumption, bmad-spec) — BMad said: "Invalid, missing or unknown ratings return an error result, never a guessed number. This lets callers fall back to manual entry (REQ-02-08)."
  decided by the business: Accept: invalid, missing or unknown ratings give an error result, never a guessed number. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-15 (assumption, bmad-spec) — BMad said: "I used the out folder directly as the spec folder, as you instructed. The skill's default would be specs/spec-rating-notch-helper/."
  decided by the business: Accept: bookkeeping only, no effect on what is built. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-16 (decision, bmad-spec) — BMad said: "CAP-1 notch count between two ratings on an ordered scale; downgrade positive, upgrade/same <=0 (REQ-02-02, REQ-06-02)"
  decided by the business: Accept CAP-1 as written. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-17 (decision, bmad-spec) — BMad said: "CAP-2 map notch change to WL per indicator profile; Ind.12 profile 1->WL1, 2+->WL2 (REQ-03-12); Ind.11/13 profile 2->WL1, 3+->WL2 (REQ-03-11/13)"
  decided by the business: Accept CAP-2 as written: Ind. 12 1→WL1, 2+→WL2; Ind. 11/13 2→WL1, 3+→WL2. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-18 (decision, bmad-spec) — BMad said: "CAP-3 country rating change indicator: current + 12-months-prior rating in, notch change + WL out; fetching the ratings is NOT in scope (scrape = REQ-02-02 other half)"
  decided by the business: Only REQ-06-02 (the notch calculator helper) and REQ-03-12 (Indicator 12, country rating change). Fetching ratings from a public source, screens, persistence and every other indicator are out of scope; REQ-03-13 matters only for the thresholds of the calculator's WL (C2).
- B-19 (decision, bmad-spec) — BMad said: "CAP-4 invalid/unknown/missing rating returns explicit error result, never a guessed number (no source states behaviour; analyst must be able to override per A3)"
  decided by the business: Accept CAP-4: explicit error result for missing, unknown or off-scale ratings. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-20 (question, bmad-spec) — BMad said: "The error-result shape is unspecified for `notchChange` (returns an integer) and `countryRatingChangeWl` (returns 0, 1 or 2). I assumed `notchCalculator` returns `{ error }` and the other two throw `Error`. Please confirm."
  decided by the business: notchCalculator returns { error: <message naming the offending input> }; notchChange and countryRatingChangeWl, whose return types the human fixed as an integer and 0|1|2, throw an Error naming the offending input. No number is ever guessed. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-21 (question, bmad-spec) — BMad said: "Please confirm `profile` as the third argument of `notchCalculator`."
  decided by the business: Confirm: notchCalculator(previous, current, profile), profile required, since B-2 makes the profile required and has no default. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-22 (question, bmad-spec) — BMad said: "Someone needs to own the correction to the POC text for REQ-06-02. It says BBB+ → BB+ is a 2-notch downgrade giving WL1."
  decided by the business: The PM records the POC text correction as a follow-up in the PR (REQ-06-02 example: BBB+ to BB+ is 3 notches, WL2); this delivery does not edit the POC document. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")

This step was chosen by bmad-help, which said: {"skill":"bmad-architecture","intent":"create","why":"The spec says what to build. The architecture records the few decisions that keep the parts consistent: where the helper lives (a pure function in src/ratings, per CLAUDE.md), its public interface and error contract, the rating-scale data shape, and how the country rating change indicator relates to the notch calculator. It also covers how the fetch from the public source (Wikipedia and similar) is separated from the pure calculation, if the fetch is in scope. It must record the stack (Node 18+ ESM, no dependencies) as a quoted repo constraint, and note that the repo has no code yet. Run it after the spec and with the spec as input, so decisions trace to requirements.","inputs":["SPEC.md and its supporting files from bmad-spec","CLAUDE.md","docs/POC_Requirements_v0.2_EN.md (section 3A, Ind. 12; section 7 constraints C2, A4)",".work/JOB-20261014-0507-rating-notch-helper/bmad/inputs/delivery-checklist.yaml"]}

End with the JSON your headless contract defines (status, the artifact paths, assumptions[], open_questions[]).