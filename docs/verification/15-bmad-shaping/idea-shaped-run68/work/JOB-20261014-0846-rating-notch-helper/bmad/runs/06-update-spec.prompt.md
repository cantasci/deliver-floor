Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md, .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/scale-and-wl-mapping.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-32 (question, bmad-spec) — BMad said: "Confirm the function is exported as `notchHelper` (spec) and not `notchCalculator` (B-21 wording), and that `direction` is 'downgrade', 'upgrade' or 'none'."
  decided by the business: notchCalculator(...).notches is signed exactly like notchChange: downgrade positive, upgrade negative (BB → BBB is -3); direction says the same in words.
- B-34 (question, bmad-architecture) — BMad said: "Function name: decision B-32 is worded 'notchCalculator', while the spec and companion say 'notchHelper'. The spine exports both names as one function (AD-8) until a human picks the canonical name."
  decided by the business: Other parts of the POC import exactly these. src/ratings/notch.mjs: RATING_SCALE (the 19 ratings, best first); notchChange(previous, current) → integer, positive = downgrade, negative = upgrade, 0 = unchanged; notchCalculator(previous, current) → { notches, direction: "downgrade" | "upgrade" | "unchanged", wl }, notches signed like notchChange. src/indicators/countryRating.mjs: countryRatingChangeWl(previous, current) → 0 | 1 | 2, built on notchChange.
- B-35 (question, bmad-architecture) — BMad said: "Node floor: CLAUDE.md fixes Node 18+, and a reviewer reported Node 18 as end-of-life. This was not verified against the web. Should the floor rise to 20 or 22, and should package.json get an engines field?"
  decided by the business: Keep the Node floor at CLAUDE.md's 18+ (stated 18.6+ for describe/it); no engines field. Raising it is a project decision outside this job. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-36 (question, bmad-architecture) — BMad said: "The 'direction' values 'downgrade', 'upgrade' and 'none' are still an assumption in the spec. B-21 says only that direction states the sign in words."
  decided by the business: notchCalculator(...).notches is signed exactly like notchChange: downgrade positive, upgrade negative (BB → BBB is -3); direction says the same in words.
- B-37 (question, bmad-architecture) — BMad said: "Credit Policy follow-up: confirm BBB+ to BB+ is 3 notches, WL 2, and correct the POC REQ-06-02 example (B-1, B-22). Do not include it in the passing tests."
  decided by the business: Record as a follow-up for Credit Policy (BBB+ to BB+); not a passing test. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-38 (question, bmad-architecture) — BMad said: "Credit Policy follow-up: confirm WL 0 at 1 notch for Ind. 11 and 13 (B-6, B-23)."
  decided by the business: Keep WL 0 at 1 notch for Ind. 11 and 13 as an assumption; follow-up for Credit Policy. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-39 (question, bmad-architecture) — BMad said: "Follow-up for whoever supplies the ratings: Q2, the country rating source for the Other segment (B-3, B-24)."
  decided by the business: Record as a follow-up (Q2 country rating source); out of scope, nothing built. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-40 (assumption, bmad-architecture) — BMad said: "Paradigm is a functional core: a pure-function library with no UI, CLI, API, database or I/O. src/ratings holds errors, scale, watchlist and notch; src/indicators holds countryRatingChange, and may import from src/ratings but not the reverse."
  decided by the business: Accept the functional-core library paradigm. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-41 (assumption, bmad-architecture) — BMad said: "notchHelper and notchChange are positional or object as the companion lists them. countryRatingChange takes only previous, current and scale and fixes the indicator at 12."
  decided by the business: Accept: notchHelper/countryRatingChange take objects, notchChange positional; Ind. fixed at 12. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-42 (assumption, bmad-architecture) — BMad said: "The scale is a frozen array of grades, and the rank is the 0-based index. Only an undefined scale selects the default; any other value is validated. Duplicate, empty or non-canonical scale entries throw INVALID_INPUT."
  decided by the business: Accept frozen-array scale, rank = 0-based index, validation of non-undefined scale. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-43 (assumption, bmad-architecture) — BMad said: "Validation order is previous, current, indicator, scale. A non-integer notches value, a non-object argument and a whitespace-only rating throw INVALID_INPUT."
  decided by the business: Accept validation order previous, current, indicator, scale. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-44 (assumption, bmad-architecture) — BMad said: "One frozen WL table keyed by 11, 12 and 13 is the only place that holds thresholds. Ind. 11 and 13 give WL 0 at 1 notch, as already decided (B-6, B-13)."
  decided by the business: Accept the single frozen WL table. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-45 (assumption, bmad-architecture) — BMad said: "RatingError.message is built by a hand-written safe formatter, because src/ may not import node:util."
  decided by the business: Accept the hand-written safe message formatter. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-46 (assumption, bmad-architecture) — BMad said: "src/ has no node: imports and no memoization. A test greps src/ for Date, Math.random, process, fs and console."
  decided by the business: Accept: no node: imports in src, no memoization, guarded by a grep test. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-47 (assumption, bmad-architecture) — BMad said: "Test helpers and fixtures live outside test/, because Node runs every .mjs file there. Test layout: test/ratings/*.test.mjs and test/indicators/countryRatingChange.test.mjs."
  decided by the business: Accept helpers/fixtures outside test/ and the stated test layout. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-48 (assumption, bmad-architecture) — BMad said: "There is no deployment, environment, migration or rollback. Consumption is by import, and npm test is the only gate because the repo has no CI config."
  decided by the business: Accept: no deployment; npm test is the only gate. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-49 (assumption, bmad-architecture) — BMad said: "Build order is errors, scale, watchlist, notch, then countryRatingChange, each with its test file."
  decided by the business: Accept the build order. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-50 (assumption, bmad-architecture) — BMad said: "The Node floor is stated as 18.6+, because describe/it need 18.6. CLAUDE.md says 18+."
  decided by the business: Accept 18.6+ (consistent with CLAUDE.md 18+ in practice). (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-51 (assumption, bmad-architecture) — BMad said: "Reviewer results come from two subagent lenses, an adversarial lens and a rubric plus reality-check lens, plus lint_spine.py, which reported 0 findings. The clear fixes are applied."
  decided by the business: Informational (how BMad reviewed); nothing built. Accept. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-52 (assumption, bmad-architecture) — BMad said: "No third-party technology is named. The only web-style check, that node --test discovers test/**/*.mjs, came from a reviewer's knowledge and was not run on Node 18."
  decided by the business: Plain Node.js ESM (.mjs), no dependencies; tests with node --test next to the code under test/.
- B-53 (decision, bmad-architecture) — BMad said: "Paradigm: functional core, pure-function library; no UI/API/DB/CLI (B-7,B-16). Layers: src/ratings (scale, notch, WL table, errors) <- src/indicators (Ind.12)"
  decided by the business: C8 stands: 'displayed' is met by the returned { notches, direction, wl }; the POC screens are built later by other parts. No UI, CLI or printed output in this slice.
- B-54 (decision, bmad-architecture) — BMad said: "Scale is data passed in; default 19-step scale frozen (B-11,B-12,B-19)"
  decided by the business: Accept scale as injected data, default 19-step frozen. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-55 (decision, bmad-architecture) — BMad said: "WL table is one frozen data table keyed by indicator 11/12/13; no default indicator (B-2,B-6,B-14)"
  decided by the business: Accept one WL table, no default indicator. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-56 (decision, bmad-architecture) — BMad said: "RatingError extends RangeError with code UNKNOWN_RATING|INVALID_INPUT|UNKNOWN_INDICATOR and value (B-10,B-20)"
  decided by the business: Accept RatingError extends RangeError with the three codes. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-57 (decision, bmad-architecture) — BMad said: "Signed notches: downgrade positive; direction downgrade|upgrade|none (B-8,B-21)"
  decided by the business: notchCalculator(...).notches is signed exactly like notchChange: downgrade positive, upgrade negative (BB → BBB is -3); direction says the same in words.

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).