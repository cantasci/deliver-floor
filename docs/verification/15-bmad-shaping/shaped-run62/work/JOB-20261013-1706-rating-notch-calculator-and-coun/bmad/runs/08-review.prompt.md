skill:bmad-review — review these artifacts before our delivery team cuts tasks from them. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].
Report findings in your canonical shape and end with a JSON summary:
{"findings":[{"lens":"…","severity":"critical|high|medium|low","artifact":"…","finding":"…","needs_human":true|false}],"verdict":"ready|ready-with-concerns|not-ready"}
needs_human: true when settling it changes what is built (scope, behaviour, a contract, a risk accepted); false for wording, consistency and test detail.

Artifacts:
- .work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md
- .work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md
Sources they were built from:
- The request, all of it: .work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/inputs/request.md (it names its requirements file; read that too)
- The repo: /private/tmp/claude-502/-Users-cantasci-Desktop-Projects-side-projects-skills-shop/0c0ab0d6-f540-4c24-a870-568f823e7be7/scratchpad/live-shaped2/shaped/repo — no code yet
- For your information — what our delivery team needs to know before it can cut tasks (a checklist, not instructions; items that do not apply to this request do not apply): .work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/inputs/delivery-checklist.yaml
Decisions taken so far (by the business with the PM) — check the artifacts against them too:
- B-1 (question, bmad-spec) — BMad said: "OQ-1: The REQ-06-02 example BBB+ → BB+ is 3 notches on the standard scale (BBB+, BBB, BBB-, BB+), not the 2 the request says. Is the scale different (for example, no BBB-), or is the example wrong? If 3 notches is right, WL would be 2 under the Ind. 13 thresholds. The example test is blocked until this is settled."
  decided by the business: C2 stands: the POC example miscounts. BBB+ → BB+ is 3 notches → calculator WL 2; the 2-notch example is BBB+ → BBB- → WL 1.
- B-2 (question, bmad-spec) — BMad said: "OQ-2: What exactly is RATING_SCALE? Does it include D/SD or CC/C, and does the internal scale in REQ-03-10 (AAA → CCC-) differ from the external one?"
  decided by the business: C1 stands: only the 19-step S&P-style scale in this slice; anything else is rejected with a RangeError.
- B-3 (question, bmad-spec) — BMad said: "OQ-3: Which WL thresholds does the calculator use: Ind. 13, Ind. 12 or Ind. 11? REQ-06-02 gives only the one example."
  decided by the business: Calculator WL uses the Ind. 13 thresholds (2 notches → WL=1, 3+ → WL=2), the only rule that fits the REQ-06-02 example's wording. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-4 (question, bmad-spec) — BMad said: "OQ-4: Should unknown ratings throw (the assumed behaviour) or return null or an error object?"
  decided by the business: Unknown ratings throw an Error naming the value. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-5 (assumption, bmad-spec) — BMad said: "The scale is S&P/Fitch style, best first: AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-, CC, C, D. Moody's notation, NR and SD are not accepted."
  decided by the business: C1 stands: only the 19-step S&P-style scale in this slice; anything else is rejected with a RangeError.
- B-6 (assumption, bmad-spec) — BMad said: "The calculator's WL uses the Ind. 13 thresholds: a downgrade of 0–1 notches gives WL 0, 2 notches gives WL 1, 3+ gives WL 2. Upgrades and unchanged ratings give WL 0. I chose these because the REQ-06-02 example (2 notches → WL=1) fits them."
  decided by the business: Accept: Ind. 13 thresholds, upgrades and unchanged → WL 0. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-7 (assumption, bmad-spec) — BMad said: "countryRatingChangeWl returns 0 for an unchanged rating or an upgrade. Only downgrades count."
  decided by the business: Accept: unchanged or upgrade → WL 0; only downgrades count. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-8 (assumption, bmad-spec) — BMad said: "notchCalculator.notches is the absolute magnitude (>= 0), and direction carries the sign."
  decided by the business: notchCalculator(...).notches is signed exactly like notchChange: downgrade positive, upgrade negative (BB → BBB is -3); direction says the same in words.
- B-9 (assumption, bmad-spec) — BMad said: "Unknown, non-string or empty ratings throw an Error naming the offending value, with no silent fallback. Ratings match exactly (case-sensitive, trimmed)."
  decided by the business: Accept: throw on unknown/empty/non-string; exact case-sensitive match after trim. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-10 (assumption, bmad-spec) — BMad said: "'Auto-filled value editable', scraping, the 12-month lookup and any UI are out of scope, because the slice has no UI or data source."
  decided by the business: The caller passes the rating the analyst confirmed or edited. No override parameter, no persistence, no audit trail in this slice.
- B-11 (decision, bmad-spec) — BMad said: "Non-goals: UI, scraping/public source, editable auto-fill, 12-month lookup, Ind.11/13 functions, agency selector, final WL aggregation"
  decided by the business: The caller passes the rating the analyst confirmed or edited. No override parameter, no persistence, no audit trail in this slice.
- B-12 (question, bmad-spec) — BMad said: "OQ-5: The POC document's REQ-06-02 example still says BBB+ → BB+ is 2 notches. Should the POC document be corrected to match decision B-1 (3 notches, WL 2)?"
  decided by the business: Yes: BBB+ to BB+ is 3 notches (WL 2), as decided in B-1. Treat the POC document's 2-notch REQ-06-02 example as an error that B-1 supersedes; the delivery follows B-1 and its tests use 3 notches. The document itself is the owner's to correct; the PR lists this as a follow-up. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-16 (question, bmad-architecture) — BMad said: "When the Ind. 13 WL function is built later, should it reuse the calculator's threshold mapping? That would mean exporting the helper. This is deferred to that job and does not block this slice."
  decided by the business: Defer: the later Ind. 13 job decides reuse and any export; nothing exported now. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-17 (assumption, bmad-architecture) — BMad said: "The paradigm is a pure-function library in two layers, ratings core and indicators on top, with no UI, store or service. The request and CLAUDE.md state this."
  decided by the business: Accept: pure-function library, two layers, no UI/store/service. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-18 (assumption, bmad-architecture) — BMad said: "The calculator's threshold helper (Ind. 13 rule) lives unexported in src/ratings/notch.mjs. The Ind. 12 rule lives in src/indicators/countryRating.mjs. Exports stay exactly as in the request's Contract."
  decided by the business: Accept: threshold helper unexported in notch.mjs; Ind. 12 rule in countryRating.mjs; exports as in the request's Contract. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-19 (assumption, bmad-architecture) — BMad said: "RATING_SCALE is a frozen array of the 19 steps AAA to CCC-, matching the SPEC. Only notchChange does the rating lookup and throws, and the other functions let the RangeError propagate unchanged."
  decided by the business: Accept: frozen 19-step RATING_SCALE; only notchChange throws, others propagate the RangeError. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-20 (assumption, bmad-architecture) — BMad said: "The two test files are test/ratings/notch.test.mjs and test/indicators/countryRating.test.mjs. The file names are my choice; the folders come from the SPEC."
  decided by the business: Accept the file names BMad chose. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-21 (assumption, bmad-architecture) — BMad said: "The spec-validation reviewer subagents were not run, because this slice is small. Only the deterministic lint_spine.py check ran, with 0 findings."
  decided by the business: Accept: the deterministic spine check ran clean; the slice is small. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-22 (decision, bmad-architecture) — BMad said: "AD-1 notchChange is the single source of truth for rank and distance; notchCalculator and countryRatingChangeWl both call it; only notch.mjs indexes RATING_SCALE"
  decided by the business: Accept AD-1: notchChange is the single source of truth for distance. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-23 (decision, bmad-architecture) — BMad said: "AD-2 RATING_SCALE is a frozen 19-step array, best first; position is rank; no second scale (B-2, B-5)"
  decided by the business: Accept AD-2: one frozen 19-step scale, best first. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-24 (decision, bmad-architecture) — BMad said: "AD-3 WL threshold mappings are named pure functions, never inline: calculator uses Ind.13 (0-1 ->0, 2 ->1, 3+ ->2); Ind.12 uses 1 ->1, 2+ ->2; upgrades and unchanged -> 0 (B-3, B-6, B-7)"
  decided by the business: Accept AD-3: separate named pure WL functions (calculator Ind. 13; Ind. 12 in countryRating). (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-25 (decision, bmad-architecture) — BMad said: "AD-4 invalid rating throws RangeError naming the value, raised only inside notchChange's rating lookup; callers do not catch or translate (B-4, B-9)"
  decided by the business: Accept AD-4: RangeError naming the value, only from notchChange. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-26 (decision, bmad-architecture) — BMad said: "AD-5 purity and direction: src/ratings and src/indicators do no I/O and use no deps; indicators may import ratings, never the reverse"
  decided by the business: Accept AD-5: no I/O, no deps; indicators import ratings, never the reverse. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-27 (decision, bmad-architecture) — BMad said: "AD-6 tests under test/ratings and test/indicators with node:test; REQ-06-02 example uses 3 notches (B-1, B-12)"
  decided by the business: Accept AD-6: node:test layout; REQ-06-02 example is 3 notches (BBB+ → BB+, WL 2). (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
