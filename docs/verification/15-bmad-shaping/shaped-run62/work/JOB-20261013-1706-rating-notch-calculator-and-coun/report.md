# Delivery report

## Summary

Credit analysts needed the notch change between two ratings and the Watchlist level (WL) it produces. Delivered as a pure Node ESM library with no dependencies: `src/ratings/notch.mjs` (`RATING_SCALE`, `notchChange`, `notchCalculator`, REQ-06-02) and `src/indicators/countryRating.mjs` (`countryRatingChangeWl`, Ind. 12 / REQ-03-12), built on one shared notch computation. Invalid ratings throw `RangeError`; nothing falls back to a value. `npm test` passes (161 tests, 0 failed). REQ-03-12 is delivered only for the notch auto-calculation and WL; public-source pre-fill and the editable value belong to other jobs.

**Intentional difference for consumers:** a 1-notch downgrade gives WL 0 in `notchCalculator` (Ind. 13 thresholds) and WL 1 in `countryRatingChangeWl` (Ind. 12). At 2 notches it is WL 1 vs WL 2. The POC text's example (BBB+ → BB+ = 2 notches / WL 1) is wrong on the 19-step scale: it is 3 notches / WL 2.

## Acceptance criteria

| AC | Status | Evidence |
| ---- | ------------ | ------------------------------------- |
| AC-1 | ✅ | Unit `RATING_SCALE (AC-1, AC-2)`; QA `qa-ratings: AC-1` (#77–79, #105) in gates/verify-all-213159.log |
| AC-2 | ✅ | Unit `RATING_SCALE (AC-1, AC-2)`; QA #80 |
| AC-3 | ✅ | Unit `notchChange (AC-3, AC-4, AC-7)`; QA #81–85 (361 pairs, adjacent pairs, pinned values) |
| AC-4 | ✅ | Unit `notchChange`; QA #86 (19 self-pairs return +0) |
| AC-5 | ✅ | Unit `notchChange invalid input (AC-5, AC-6)`; QA #87–89; blind review approve |
| AC-6 | ✅ | QA #90–93 (messages, Symbol, previous checked first) |
| AC-7 | ✅ | Unit trim case `" BBB+ "`; QA #94 |
| AC-8 | ✅ | Unit `notchCalculator (AC-8, AC-9, AC-10)`; QA #95–96, #106 |
| AC-9 | ✅ | QA #97–98 (all 361 pairs and threshold pairs) |
| AC-10 | ✅ | QA #99; unit suite |
| AC-11 | ✅ | Unit `AC-11 Ind. 12 rule`; QA #2–9 (7 pinned rows, 361 pairs, boundaries) |
| AC-12 | ✅ | Unit `AC-12 differs from the calculator`; QA #10–13, #56–57; "INTENTIONAL" comments in `calculatorWl` and `ind12Wl` |
| AC-13 | ✅ | QA #14–52, #100–103, #107; unit suites in both files |
| AC-14 | ✅ | QA #53–55, #58, #104, #120; unit `module exports` suites |
| AC-15 | ✅ | QA #59–75, #108–121 (import direction, no scale copy, purity, no deps); reviewer AD-1 / AD-5 ok |
| AC-16 | ✅ | gates/verify-all-213159.log: 161 pass, 0 fail; reproduced at closing, exit 0 |
| AC-17 | ✅ | This report is the PR body; it lists the four follow-ups and the 1-notch WL difference below |

## Non-functional requirements

| Requirement | Result | Evidence |
| ----------- | ------ | -------- |
| NFR-security | PASS | AC-5, AC-6, AC-13 tests (QA #14–52, #87–93, #100–103); `rankOf` is the only validation point; reviewer AD-4 ok |
| NFR-audit | PASS | No persistence, writes or module state in either module (QA #65–72, #110–117); reviewer AD-5 ok |
| NFR-observability | PASS | No `console`, `process` or env reads (QA #68, #71, #113, #116) |
| NFR-compliance | PASS | Closing review of both sources: only AD-1..AD-5 rules implemented; both cards approved by reviewer and blind review with nits only |

## Cards

| Card | Role | Attempts | Result |
| ---- | ---- | -------- | ------ |
| T-01 | backend | 1 | merged |
| T-02 | backend | 1 | merged |

## Blocked / deferred work

None.

## Risks and follow-ups

1. The consuming form job owns REQ-03-12 "auto-filled value editable" (and "Pre-filled from public source").
2. The consuming UI needs a mapping step, because Moody's, CC, C, D, SD and NR throw `RangeError`.
3. The POC owner should correct the REQ-06-02 example (`docs/POC_Requirements_v0.2_EN.md` line 195) to BBB+ → BB+ = 3 notches / WL 2. The document was not edited.
4. The reviewer lenses of BMad were skipped (B-48); the job's own review and blind review ran.
5. The QA AC-8 grep in `test/ratings/qa/qa-ratings-purity.test.mjs` is line-based and should be narrowed to calculator assertions; it also flags correct Ind. 12 assertions for BBB+/BB+.
6. Exotic inputs (null-prototype object, throwing `toString`) are not pinned; out of scope by the plan.

## Delivery

- Branch: `job/JOB-20261013-1706-rating-notch-calculator-and-coun`
- PR / merge: local merge into `main` (`merge: local`)

<!-- deliver:shaping -->
## Shaped with the BMad Method 6.12.2

BMad chose its own path, wrote the specification headless, applied the decisions taken on what it said and reviewed its own work: 15 runs, 11 min, $3.54. Nothing it decided was binding until the decisions below.

**Path:** bmad-spec → bmad-architecture · skipped: bmad-prd, bmad-product-brief, bmad-prfaq, bmad-brainstorming, bmad-forge-idea, bmad-deep-recon, bmad-ux, bmad-project-context, bmad-advanced-elicitation, bmad-party-mode, bmad-create-epics-and-stories, bmad-sprint-planning, bmad-build, bmad-build-auto, bmad-code-review, bmad-qa-generate-e2e-tests, bmad-walkthrough, bmad-retrospective, bmad-correct-course, bmad-customize

**Artifacts:** `.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/SPEC.md`, `.work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md`

**Its reviews:** round 1 — ready-with-concerns, 10 finding(s) · round 2 — ready-with-concerns, 9 finding(s)

| Id | From | BMad said | Decision | By |
| --- | --- | --- | --- | --- |
| B-1 | question · bmad-spec | OQ-1: The REQ-06-02 example BBB+ → BB+ is 3 notches on the standard scale (BBB+, BBB, BBB-, BB+), not the 2 the request says. Is the scale different (for example, no BBB-), or is the example wrong? If 3 notches is right, | C2 stands: the POC example miscounts. BBB+ → BB+ is 3 notches → calculator WL 2; the 2-notch example is BBB+ → BBB- → WL 1. | the human |
| B-2 | question · bmad-spec | OQ-2: What exactly is RATING_SCALE? Does it include D/SD or CC/C, and does the internal scale in REQ-03-10 (AAA → CCC-) differ from the external one? | C1 stands: only the 19-step S&P-style scale in this slice; anything else is rejected with a RangeError. | the human |
| B-3 | question · bmad-spec | OQ-3: Which WL thresholds does the calculator use: Ind. 13, Ind. 12 or Ind. 11? REQ-06-02 gives only the one example. | Calculator WL uses the Ind. 13 thresholds (2 notches → WL=1, 3+ → WL=2), the only rule that fits the REQ-06-02 example's wording. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-4 | question · bmad-spec | OQ-4: Should unknown ratings throw (the assumed behaviour) or return null or an error object? | Unknown ratings throw an Error naming the value. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-5 | assumption · bmad-spec | The scale is S&P/Fitch style, best first: AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-, CC, C, D. Moody's notation, NR and SD are not accepted. | C1 stands: only the 19-step S&P-style scale in this slice; anything else is rejected with a RangeError. | the human |
| B-6 | assumption · bmad-spec | The calculator's WL uses the Ind. 13 thresholds: a downgrade of 0–1 notches gives WL 0, 2 notches gives WL 1, 3+ gives WL 2. Upgrades and unchanged ratings give WL 0. I chose these because the REQ-06-02 example (2 notche | Accept: Ind. 13 thresholds, upgrades and unchanged → WL 0. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-7 | assumption · bmad-spec | countryRatingChangeWl returns 0 for an unchanged rating or an upgrade. Only downgrades count. | Accept: unchanged or upgrade → WL 0; only downgrades count. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-8 | assumption · bmad-spec | notchCalculator.notches is the absolute magnitude (>= 0), and direction carries the sign. | notchCalculator(...).notches is signed exactly like notchChange: downgrade positive, upgrade negative (BB → BBB is -3); direction says the same in words. | the human |
| B-9 | assumption · bmad-spec | Unknown, non-string or empty ratings throw an Error naming the offending value, with no silent fallback. Ratings match exactly (case-sensitive, trimmed). | Accept: throw on unknown/empty/non-string; exact case-sensitive match after trim. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-10 | assumption · bmad-spec | 'Auto-filled value editable', scraping, the 12-month lookup and any UI are out of scope, because the slice has no UI or data source. | The caller passes the rating the analyst confirmed or edited. No override parameter, no persistence, no audit trail in this slice. | the human |
| B-11 | decision · bmad-spec | Non-goals: UI, scraping/public source, editable auto-fill, 12-month lookup, Ind.11/13 functions, agency selector, final WL aggregation | The caller passes the rating the analyst confirmed or edited. No override parameter, no persistence, no audit trail in this slice. | the human |
| B-12 | question · bmad-spec | OQ-5: The POC document's REQ-06-02 example still says BBB+ → BB+ is 2 notches. Should the POC document be corrected to match decision B-1 (3 notches, WL 2)? | Yes: BBB+ to BB+ is 3 notches (WL 2), as decided in B-1. Treat the POC document's 2-notch REQ-06-02 example as an error that B-1 supersedes; the delivery follows B-1 and its tests use 3 notches. The document itself is th | the human |
| B-16 | question · bmad-architecture | When the Ind. 13 WL function is built later, should it reuse the calculator's threshold mapping? That would mean exporting the helper. This is deferred to that job and does not block this slice. | Defer: the later Ind. 13 job decides reuse and any export; nothing exported now. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-17 | assumption · bmad-architecture | The paradigm is a pure-function library in two layers, ratings core and indicators on top, with no UI, store or service. The request and CLAUDE.md state this. | Accept: pure-function library, two layers, no UI/store/service. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-18 | assumption · bmad-architecture | The calculator's threshold helper (Ind. 13 rule) lives unexported in src/ratings/notch.mjs. The Ind. 12 rule lives in src/indicators/countryRating.mjs. Exports stay exactly as in the request's Contract. | Accept: threshold helper unexported in notch.mjs; Ind. 12 rule in countryRating.mjs; exports as in the request's Contract. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-19 | assumption · bmad-architecture | RATING_SCALE is a frozen array of the 19 steps AAA to CCC-, matching the SPEC. Only notchChange does the rating lookup and throws, and the other functions let the RangeError propagate unchanged. | Accept: frozen 19-step RATING_SCALE; only notchChange throws, others propagate the RangeError. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-20 | assumption · bmad-architecture | The two test files are test/ratings/notch.test.mjs and test/indicators/countryRating.test.mjs. The file names are my choice; the folders come from the SPEC. | Accept the file names BMad chose. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-21 | assumption · bmad-architecture | The spec-validation reviewer subagents were not run, because this slice is small. Only the deterministic lint_spine.py check ran, with 0 findings. | Accept: the deterministic spine check ran clean; the slice is small. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-22 | decision · bmad-architecture | AD-1 notchChange is the single source of truth for rank and distance; notchCalculator and countryRatingChangeWl both call it; only notch.mjs indexes RATING_SCALE | Accept AD-1: notchChange is the single source of truth for distance. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-23 | decision · bmad-architecture | AD-2 RATING_SCALE is a frozen 19-step array, best first; position is rank; no second scale (B-2, B-5) | Accept AD-2: one frozen 19-step scale, best first. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-24 | decision · bmad-architecture | AD-3 WL threshold mappings are named pure functions, never inline: calculator uses Ind.13 (0-1 ->0, 2 ->1, 3+ ->2); Ind.12 uses 1 ->1, 2+ ->2; upgrades and unchanged -> 0 (B-3, B-6, B-7) | Accept AD-3: separate named pure WL functions (calculator Ind. 13; Ind. 12 in countryRating). (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-25 | decision · bmad-architecture | AD-4 invalid rating throws RangeError naming the value, raised only inside notchChange's rating lookup; callers do not catch or translate (B-4, B-9) | Accept AD-4: RangeError naming the value, only from notchChange. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-26 | decision · bmad-architecture | AD-5 purity and direction: src/ratings and src/indicators do no I/O and use no deps; indicators may import ratings, never the reverse | Accept AD-5: no I/O, no deps; indicators import ratings, never the reverse. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-27 | decision · bmad-architecture | AD-6 tests under test/ratings and test/indicators with node:test; REQ-06-02 example uses 3 notches (B-1, B-12) | Accept AD-6: node:test layout; REQ-06-02 example is 3 notches (BBB+ → BB+, WL 2). (accepted: "e2e: no prepared answer fits — Michael's proposal accepted") | the human |
| B-28 | finding | RangeError message format underspecified: rendering of non-string values, original vs trimmed value, and which argument is named when both are invalid. | The RangeError message names the offending value exactly as passed (String(value) for non-strings, the original untrimmed text for strings); when both arguments are invalid, the previous argument is validated first and n | Michael |
| B-29 | finding | Trim behaviour has no pinned test cases (padded accepted, wrong case rejected, whitespace-only rejected). | Add pinned trim tests: ' BBB+ ' accepted, 'bbb+' rejected, '   ' and '' rejected. | Michael |
| B-30 | finding | No extreme-distance case (AAA to CCC-, 18 notches) to show the WL stays capped at 2. | Add an extreme-distance test: AAA to CCC- is 18 notches, calculator WL 2 and Ind. 12 WL 2. | Michael |
| B-31 | finding | Frontmatter sources omit the requirements file and the POC document, and Assumptions points to a .memlog.md that is not among the artifacts. | Documentation-only: sources and the .memlog.md pointer are traceability metadata; not delivered code. No change to what is built. | Michael |
| B-32 | finding | Success signal sentence has a misplaced parenthetical about the corrected examples. | Wording only: the tests use 3 notches for BBB+ → BB+, never the POC document's 2; the parenthetical is cosmetic. | Michael |
| B-33 | finding | The [ADOPTED] marker on some ADs is undefined for the delivery team. | [ADOPTED] marks an architecture decision taken over from the project's settled rules; the delivery team treats every AD as binding regardless of the marker. | Michael |
| B-34 | finding | PRD-priority (Must/Should), DEL-docs and DEL-ci are not explicitly answered. | PRD priority is Must for both requirements (they are the job's whole scope); DEL-docs: no docs beyond code and tests; DEL-ci: none, tests run via npm test. Recorded as PM decisions in readiness. | Michael |
| B-35 | finding | The REQ-03-12 'auto-filled value editable' criterion has no named downstream owner or follow-up entry. | Follow-up recorded for the PR: the consuming form job owns 'auto-filled value editable' (REQ-03-12). | Michael |
| B-36 | finding | 1-notch downgrade gives WL 0 from the calculator but WL 1 from Ind. 12; intentional under B-3/B-24, but undocumented as such for consumers. | Intentional: the calculator (Ind. 13 thresholds) gives WL 0 for a 1-notch downgrade, Ind. 12 gives WL 1. Documented in code comments of both helpers and in the PR for consumers. | Michael |
| B-37 | finding | Moody's-only sovereign ratings will throw; the consuming UI job needs a mapping step. Settled by B-2/B-5, so a follow-up note only. | Follow-up note for the consuming UI job: Moody's-only sovereign ratings throw RangeError and need a mapping step before calling. | Michael |
| B-38 | question · bmad-architecture | Should the reviewer-gate lens subagents be run on the updated spine before downstream use? Headless normally requires them, and this run skipped them. | No: do not run the reviewer-gate lens subagents on the spine. Only the deterministic lint check ran (0 findings), and the independent bmad-review round that follows shaping reviews the updated spine anyway. Nothing built | the human |
| B-40 | finding | B-34 sets PRD priority Must for both requirements, but the POC marks REQ-06-02 as Should and REQ-03-12 as Must. Neither artifact states a priority. Correct B-34 or record the override knowingly. | Correct B-34: record the POC's own priorities, REQ-06-02 Should and REQ-03-12 Must, in readiness. Both are delivered in this job; priority changes no code or tests. (accepted: "e2e: no prepared answer fits — Michael's pr | the human |
| B-41 | finding | The delivery's BBB+ → BB+ = 3 notches / WL 2 differs from the POC's REQ-06-02 text (2 notches / WL 1). This is resolved by B-1 and B-12, but a verifier working from the POC will see a mismatch. Keep the PR follow-up to c | Keep the PR follow-up asking the owner to correct the POC's REQ-06-02 example to 3 notches / WL 2. | Michael |
| B-42 | finding | The follow-up notes cover only Moody's-only sovereign ratings. Sovereigns rated CC, C, D or SD also throw RangeError and cannot be scored. Extend the PR follow-up note to name them. | Extend the PR follow-up: sovereign ratings CC, C, D, SD (and NR) also throw RangeError, not only Moody's-only ratings. | Michael |
| B-43 | finding | String(value) can throw TypeError for null-prototype objects or a throwing toString. Pin the invalid-input tests to null, undefined, number, {} and Symbol, and declare exotic objects out of scope. | Invalid-input tests pin null, undefined, number, {} and Symbol; exotic objects (null-prototype, throwing toString) are out of scope. | Michael |
| B-44 | finding | The spec does not pin an unchanged rating (notches 0, wl 0, +0 not -0), a 1-notch upgrade, the frozen RATING_SCALE, or the calculator WL for a 2-notch downgrade beyond BBB+ → BBB-. | Add tests for: unchanged rating (notches 0, wl 0, +0 not -0), a 1-notch upgrade, frozen RATING_SCALE, and calculator WL for a 2-notch downgrade. | Michael |
| B-45 | finding | 'Downgrade of 0–1 notches → 0' is awkward. Reword to 'unchanged, upgrade or 1-notch downgrade → 0'. | Reword the calculator rule to 'unchanged, upgrade or 1-notch downgrade → 0'. | Michael |
| B-46 | finding | [ADOPTED] is defined as taken over from the project's settled rules. AD-2, AD-3 and AD-4 come from business decisions, not CLAUDE.md, and AD-5 comes from CLAUDE.md but is not marked. This is cosmetic under B-33. | Cosmetic: the [ADOPTED] marker is documentation only; every AD is binding either way. | Michael |
| B-47 | finding | Sources omit the requirements file and the POC document, and the .memlog.md pointer is not among the artifacts, although the SPEC calls itself the complete contract. B-31 accepts this as documentation only. | Documentation only: the request and the POC document stay referenced by the job record; code and tests follow the SPEC. | Michael |
| B-48 | finding | status: final overstates validation. Only the deterministic lint ran, and the reviewer-gate lenses were skipped (B-21, B-38). | Accepted: status final means the lint passed; the reviewer lenses were skipped (B-21, B-38), and the PR says so. | Michael |

**What BMad changed against its own earlier decisions:**

- {"change":"B-2 / B-5","prior":"The scale had 22 steps, AAA through D, with CC, C and D included.","now":"The scale has 19 steps, AAA through CCC-. CC, C, D, SD, NR and Moody's notation are rejected."}
- {"change":"B-8","prior":"`notchCalculator.notches` was an absolute magnitude (>= 0), with `direction` carrying the sign.","now":"`notches` is signed like `notchChange`: downgrade positive, upgrade negative (BB → BBB is -3). `direction` says the same in words."}
- {"change":"B-2 / B-9","prior":"Bad ratings threw a generic `Error` naming the value.","now":"Bad ratings throw a `RangeError` naming the value. This is a subclass of `Error`, so it narrows the earlier decision rather than contradicting it."}
- B-38 departs from the bmad-architecture headless contract (references/headless.md), which requires every finalize_reviewers lens to run as a parallel subagent. The business decision overrides it for this spine. The independent bmad-review round after shaping covers the review instead.
- B-40 corrects B-34: the priority is no longer Must for both. REQ-06-02 is Should and REQ-03-12 is Must. B-34's text was only in readiness, not in SPEC, so no SPEC text had to change.
- B-42 extends B-37, which named only Moody's-only ratings. B-37 is now broader, not contradicted.
- B-43 narrows B-28, which said the message uses String(value) for non-strings. B-28 now holds for the pinned types only, because exotic objects can make String(value) throw.
- B-45 rewords B-6/AD-3 (calculator thresholds). The mapping is the same, so there is no behavioural conflict.
- B-45 rewords the AD-3 calculator rule from '<=1 -> 0' to 'unchanged, upgrade or 1-notch downgrade -> 0'. The mapping is the same, so this is a refinement of B-6 with no change in meaning.
- B-43 narrows how AD-4 (B-28) uses String(value) for non-string inputs: tests pin null, undefined, number, {} and Symbol, and exotic objects are out of scope. It adds to B-28 and does not reverse it.
- B-42 extends the B-37 PR follow-up beyond Moody's-only ratings to sovereign CC, C, D, SD and NR.
- B-40 supersedes B-34's 'Must for both' priority. This concerns readiness only, so the spine is unchanged.

<!-- deliver:pm-decisions -->
## Decisions Michael took himself

Taken without asking you (you are asked only at the start); each with its reason.

None: every decision was taken with the human before planning.

<!-- deliver:contract-changes -->
## Test and contract changes after the start

What was checked changed here, each with its reason — a weaker check is a weaker delivery.

- job settings: `settings: .settings.verify_full="npm test"` (2026-10-13T19:08:31Z)

<!-- deliver:followups -->
## Follow-ups (found during the job, outside its scope)

- **T-02** — The consuming form job owns REQ-03-12 'auto-filled value editable' and public-source pre-fill
- **T-01** — The consuming UI needs a mapping step: Moody's, CC, C, D, SD and NR throw RangeError
- **T-01** — POC owner should correct REQ-06-02 example (POC doc line 195) to BBB+ -> BB+ = 3 notches / WL 2
- **T-02** — Narrow the line-based AC-8 grep in test/ratings/qa/qa-ratings-purity.test.mjs; it flags correct Ind. 12 assertions
- **T-01** — Exotic inputs (null-prototype, throwing toString) are not pinned; out of scope by plan
