skill:bmad-review — review these artifacts before our delivery team cuts tasks from them. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].
Report findings in your canonical shape and end with a JSON summary:
{"findings":[{"lens":"…","severity":"critical|high|medium|low","artifact":"…","finding":"…","needs_human":true|false}],"verdict":"ready|ready-with-concerns|not-ready"}
needs_human: true when settling it changes what is built (scope, behaviour, a contract, a risk accepted); false for wording, consistency and test detail.

Artifacts:
- .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md
- .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/scale-and-wl-mapping.md
- .work/JOB-20261014-0846-rating-notch-helper/bmad/out/architecture-rating-notch-helper/ARCHITECTURE-SPINE.md
Sources they were built from:
- The request, all of it: .work/JOB-20261014-0846-rating-notch-helper/bmad/inputs/request.md (it names its requirements file; read that too)
- The repo: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/idea-shaped/idea/repo — no code yet
- For your information — what our delivery team needs to know before it can cut tasks (a checklist, not instructions; items that do not apply to this request do not apply): .work/JOB-20261014-0846-rating-notch-helper/bmad/inputs/delivery-checklist.yaml
Decisions taken so far (by the business with the PM) — check the artifacts against them too:
- B-1 (question, bmad-spec) — BMad said: "Conflict in REQ-06-02: BBB+ to BB+ is stated as 2 notches, WL 1. On the standard scale it is 3 notches, WL 2. Is the example wrong, or does the business scale lack a grade?"
  decided by the business: The POC example is wrong: compute BBB+ to BB+ on the standard scale (3 notches, WL 2); keep it out of the passing tests and record it as a follow-up for Credit Policy. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-2 (question, bmad-spec) — BMad said: "Conflict in the WL rules: Ind. 12 gives WL 2 at 2 notches, while Ind. 11 and 13 give WL 1. Does the helper take the indicator from the caller (assumed), or always use one profile?"
  decided by the business: The caller names the indicator (11, 12 or 13); the helper has no default profile. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-3 (question, bmad-spec) — BMad said: "Q2 from the POC: for the Other segment, is the country rating from Fitch, S&P or the most conservative of the three? This does not block the helper, but whoever supplies the ratings needs the answer."
  decided by the business: Out of scope for this helper because ratings come in as input; record Q2 as a follow-up for whoever supplies the ratings. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-4 (question, bmad-spec) — BMad said: "Is scraping sovereign ratings (REQ-02-02) part of this delivery or a later one? Assumed later."
  decided by the business: Only REQ-06-02 (the notch calculator helper) and REQ-03-12 (Indicator 12, country rating change). Fetching ratings from a public source, screens, persistence and every other indicator are out of scope; REQ-03-13 matters only for the thresholds of the calculator's WL (C2).
- B-5 (question, bmad-spec) — BMad said: "Should the scale include Moody's notation? Do CC, C and D count for sovereigns?"
  decided by the business: C1 stands: only the 19-step S&P-style scale in this slice; anything else is rejected with a RangeError.
- B-6 (question, bmad-spec) — BMad said: "Confirm with Credit Policy that Ind. 11 at 1 notch gives WL 0."
  decided by the business: Ship WL 0 at 1 notch for Ind. 11 as an assumption, kept in one table so Credit Policy can change it in one place; follow-up to confirm. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-7 (question, bmad-spec) — BMad said: "Confirm this is a library only, with no CLI or API."
  decided by the business: Library only: no CLI, no API, imported from src/. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-8 (assumption, bmad-spec) — BMad said: "Positive notch change means downgrade. An upgrade or no change gives WL 0."
  decided by the business: Accept: a positive notch change is a downgrade, and an upgrade or no change gives WL 0. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-9 (assumption, bmad-spec) — BMad said: "The library sits in src/ratings/ (scale, notch, WL mapping) and src/indicators/ (Ind. 12), as CLAUDE.md names those folders."
  decided by the business: Accept: ratings and WL mapping in src/ratings/, the Ind. 12 evaluator in src/indicators/. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-10 (assumption, bmad-spec) — BMad said: "Errors are thrown as RatingError with a code of UNKNOWN_RATING, INVALID_INPUT or UNKNOWN_INDICATOR. The repo has no convention yet."
  decided by the business: Accept RatingError with codes UNKNOWN_RATING, INVALID_INPUT and UNKNOWN_INDICATOR. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-11 (assumption, bmad-spec) — BMad said: "Input is trimmed and case-insensitive, and a Unicode minus counts as '-'. Outlooks, NR/WR and Moody's notation are rejected."
  decided by the business: C1: the 19 S&P/Fitch steps AAA … CCC- only. Input is trimmed and case-insensitive ("bbb+" = "BBB+"); anything else — another notation (Moody's), an outlook suffix, a Unicode minus, unrated, a non-string — is rejected with a RangeError.
- B-12 (assumption, bmad-spec) — BMad said: "The default scale is S&P/Fitch AAA to D (22 grades). The internal scale (AAA to CCC-) is its first 19 grades."
  decided by the business: Accept the 22-grade S&P/Fitch default scale, passed as data, with the internal scale as its first 19 grades. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-13 (assumption, bmad-spec) — BMad said: "Ind. 11 and Ind. 13 give WL 0 at exactly 1 notch. The POC lists that option but gives no WL."
  decided by the business: Accept WL 0 at exactly 1 notch for Ind. 11 and 13, as in B-6. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-14 (assumption, bmad-spec) — BMad said: "The caller names the indicator (11, 12 or 13) for the WL, and there is no default."
  decided by the business: Accept: the caller names the indicator, with no default. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-15 (assumption, bmad-spec) — BMad said: "The caller supplies the rating from 12 months ago, so there is no date logic."
  decided by the business: Accept: the caller supplies the rating from 12 months ago, so there is no date logic. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-16 (assumption, bmad-spec) — BMad said: "Scraping or fetching ratings is out of scope, because CLAUDE.md forbids I/O in src/ratings and src/indicators. The helper takes ratings as input and has no UI."
  decided by the business: Only REQ-06-02 (the notch calculator helper) and REQ-03-12 (Indicator 12, country rating change). Fetching ratings from a public source, screens, persistence and every other indicator are out of scope; REQ-03-13 matters only for the thresholds of the calculator's WL (C2).
- B-17 (decision, bmad-spec) — BMad said: "Fetch/scrape of sovereign ratings (REQ-02-02 fetch half) out of scope: needs I/O, source and Q2 undecided; helper consumes ratings passed in"
  decided by the business: Only REQ-06-02 (the notch calculator helper) and REQ-03-12 (Indicator 12, country rating change). Fetching ratings from a public source, screens, persistence and every other indicator are out of scope; REQ-03-13 matters only for the thresholds of the calculator's WL (C2).
- B-18 (decision, bmad-spec) — BMad said: "No screens/UI (REQ-06-02 screen, REQ-03-14 row display belong to other epics)"
  decided by the business: C8 stands: 'displayed' is met by the returned { notches, direction, wl }; the POC screens are built later by other parts. No UI, CLI or printed output in this slice.
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
- B-58 (question, bmad-spec) — BMad said: "Confirm that `notchCalculator(previous, current)` returns `wl` for Ind. 12, and that the object-style `notchHelper` and `countryRatingChange` returning `{notches, direction, wl}` are dropped."
  decided by the business: Confirmed: the drafted architecture is right — one plain Node ESM library at the repo root, code under src/, tests under test/, run with node --test. Keep it as the project's architecture.
- B-62 (question, bmad-architecture) — BMad said: "Which indicator does notchCalculator(previous, current) use for wl? AD-5 and B-55 allow no default indicator, but the decided signature has no indicator argument. The spine assumes Ind. 12 through options.indicator. A human should confirm or fix this."
  decided by the business: No default indicator, as the human decided in B-2: notchCalculator takes options.indicator (11, 12 or 13) as required, and a missing or other value throws UNKNOWN_INDICATOR. The Ind. 12 default is dropped. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-68 (question, bmad-spec) — BMad said: "Assumed, not in B-62: the optional `scale` moves into `options.scale`, and a missing or non-object `options` throws `UNKNOWN_INDICATOR`. Confirm."
  decided by the business: Accept: options is { indicator, scale? }; a missing or non-object options throws UNKNOWN_INDICATOR. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-69 (question, bmad-spec) — BMad said: "Follow-up for Credit Policy: the POC example BBB+ → BB+ is 3 notches, WL 2. Confirm it and correct the POC."
  decided by the business: Same as the answered B-1: BBB+ to BB+ is 3 notches, WL 2; keep it out of the passing tests and list it as a follow-up for Credit Policy. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-70 (question, bmad-spec) — BMad said: "Follow-up for whoever supplies the ratings: Q2, the country rating source for the Other segment (Fitch, S&P or most conservative)."
  decided by the business: Same as the answered B-3: Q2 is out of scope here; list it as a follow-up for whoever supplies the ratings. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
