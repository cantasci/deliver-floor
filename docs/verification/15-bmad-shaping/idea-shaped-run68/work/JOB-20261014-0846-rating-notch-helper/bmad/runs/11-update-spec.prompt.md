Use the bmad-spec skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/SPEC.md, .work/JOB-20261014-0846-rating-notch-helper/bmad/out/spec-rating-notch-helper/scale-and-wl-mapping.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-68 (question, bmad-spec) — BMad said: "Assumed, not in B-62: the optional `scale` moves into `options.scale`, and a missing or non-object `options` throws `UNKNOWN_INDICATOR`. Confirm."
  decided by the business: Accept: options is { indicator, scale? }; a missing or non-object options throws UNKNOWN_INDICATOR. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-69 (question, bmad-spec) — BMad said: "Follow-up for Credit Policy: the POC example BBB+ → BB+ is 3 notches, WL 2. Confirm it and correct the POC."
  decided by the business: Same as the answered B-1: BBB+ to BB+ is 3 notches, WL 2; keep it out of the passing tests and list it as a follow-up for Credit Policy. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-70 (question, bmad-spec) — BMad said: "Follow-up for whoever supplies the ratings: Q2, the country rating source for the Other segment (Fitch, S&P or most conservative)."
  decided by the business: Same as the answered B-3: Q2 is out of scope here; list it as a follow-up for whoever supplies the ratings. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-77 (finding) — BMad said: "Non-object options throws INVALID_INPUT in AD-6 but UNKNOWN_INDICATOR in the spec and companion (B-68 decided UNKNOWN_INDICATOR); null/array handling unstated."
  decided by the PM: A missing, null, array or any non-object options throws UNKNOWN_INDICATOR; AD-6 is corrected to match the spec and B-68
- B-78 (finding) — BMad said: "Stated validation order (previous, current, indicator, scale) conflicts with rankOf validating the scale while ranking previous; error code for multi-fault input is ambiguous."
  decided by the PM: Validation of all arguments precedes any result; with several faults the reported code is not contractual and tests cover single-fault inputs only; AD-7 drops the claimed order
- B-79 (finding) — BMad said: "Unclear whether an injected scale may contain grades outside the 19 (e.g. CC) and whether a non-frozen array is accepted; the 19-step rule vs injectable scale needs one clarifying sentence."
  decided by the PM: An injected scale is accepted when rankOf's rules hold (array, non-empty, no duplicates, canonical entries); grades beyond the 19 are allowed, a frozen array is not required and the scale is never mutated; the 19-step rule applies to the default RATING_SCALE only
- B-80 (finding) — BMad said: "Naive grep test for Date, fs, process, console gives false positives; specify word-boundary or identifier-level patterns."
  decided by the PM: The purity test matches whole identifiers (word-boundary regex, comments and strings excluded) for Date, Math.random, process, fs, console
- B-81 (finding) — BMad said: "Dangling reference 'A4' in the WL-values constraint; cite REQ-03-11/12/13 instead."
  decided by the PM: The WL-values constraint cites REQ-03-11/12/13, not 'A4'
- B-82 (finding) — BMad said: "Mentions removing .gitkeep placeholders that do not exist, and a README usage note that the spec does not scope."
  decided by the PM: No .gitkeep removal and no README change in this job; both are outside the spec's scope
- B-83 (finding) — BMad said: "Sources omit docs/POC_Requirements_v0.2_EN.md, from which the REQ numbers and examples derive."
  decided by the PM: docs/POC_Requirements_v0.2_EN.md is added to the sources as the origin of the REQ numbers and examples

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).