Use the bmad-architecture skill. headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].

intent: update
Artifacts to update: .work/JOB-20261013-1706-rating-notch-calculator-and-coun/bmad/out/ARCHITECTURE-SPINE.md
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
- B-40 (finding) — BMad said: "B-34 sets PRD priority Must for both requirements, but the POC marks REQ-06-02 as Should and REQ-03-12 as Must. Neither artifact states a priority. Correct B-34 or record the override knowingly."
  decided by the business: Correct B-34: record the POC's own priorities, REQ-06-02 Should and REQ-03-12 Must, in readiness. Both are delivered in this job; priority changes no code or tests. (accepted: "e2e: no prepared answer fits — Michael's proposal accepted")
- B-41 (finding) — BMad said: "The delivery's BBB+ → BB+ = 3 notches / WL 2 differs from the POC's REQ-06-02 text (2 notches / WL 1). This is resolved by B-1 and B-12, but a verifier working from the POC will see a mismatch. Keep the PR follow-up to correct the POC."
  decided by the PM: Keep the PR follow-up asking the owner to correct the POC's REQ-06-02 example to 3 notches / WL 2.
- B-42 (finding) — BMad said: "The follow-up notes cover only Moody's-only sovereign ratings. Sovereigns rated CC, C, D or SD also throw RangeError and cannot be scored. Extend the PR follow-up note to name them."
  decided by the PM: Extend the PR follow-up: sovereign ratings CC, C, D, SD (and NR) also throw RangeError, not only Moody's-only ratings.
- B-43 (finding) — BMad said: "String(value) can throw TypeError for null-prototype objects or a throwing toString. Pin the invalid-input tests to null, undefined, number, {} and Symbol, and declare exotic objects out of scope."
  decided by the PM: Invalid-input tests pin null, undefined, number, {} and Symbol; exotic objects (null-prototype, throwing toString) are out of scope.
- B-44 (finding) — BMad said: "The spec does not pin an unchanged rating (notches 0, wl 0, +0 not -0), a 1-notch upgrade, the frozen RATING_SCALE, or the calculator WL for a 2-notch downgrade beyond BBB+ → BBB-."
  decided by the PM: Add tests for: unchanged rating (notches 0, wl 0, +0 not -0), a 1-notch upgrade, frozen RATING_SCALE, and calculator WL for a 2-notch downgrade.
- B-45 (finding) — BMad said: "'Downgrade of 0–1 notches → 0' is awkward. Reword to 'unchanged, upgrade or 1-notch downgrade → 0'."
  decided by the PM: Reword the calculator rule to 'unchanged, upgrade or 1-notch downgrade → 0'.
- B-46 (finding) — BMad said: "[ADOPTED] is defined as taken over from the project's settled rules. AD-2, AD-3 and AD-4 come from business decisions, not CLAUDE.md, and AD-5 comes from CLAUDE.md but is not marked. This is cosmetic under B-33."
  decided by the PM: Cosmetic: the [ADOPTED] marker is documentation only; every AD is binding either way.
- B-47 (finding) — BMad said: "Sources omit the requirements file and the POC document, and the .memlog.md pointer is not among the artifacts, although the SPEC calls itself the complete contract. B-31 accepts this as documentation only."
  decided by the PM: Documentation only: the request and the POC document stay referenced by the job record; code and tests follow the SPEC.
- B-48 (finding) — BMad said: "status: final overstates validation. Only the deterministic lint ran, and the reviewer-gate lenses were skipped (B-21, B-38)."
  decided by the PM: Accepted: status final means the lint passed; the reviewer lenses were skipped (B-21, B-38), and the PR says so.

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).