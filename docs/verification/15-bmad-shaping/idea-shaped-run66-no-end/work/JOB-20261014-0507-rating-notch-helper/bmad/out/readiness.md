# Readiness answers (delivery-checklist.yaml)

Status: **decided** (source quoted), **default** (spec proceeds, human may change), **open** (needs human), **n/a**.

| Item | Status | Answer / source |
|---|---|---|
| PRD-goal | decided | Replace manual notch counting; callable by other POC parts ("Other parts of the POC will use it"). Success signal in SPEC. |
| PRD-users | n/a | Library, no roles (A1; "not about screens"). |
| PRD-scope | decided | In: CAP-1..4. Out: Non-goals in SPEC. Request: "the notch calculator and the country rating change indicator". |
| PRD-acceptance | decided | Examples in `notch-wl-tables.md`; BBB+→BB+ is 3 notches, WL2 (B-1). |
| PRD-conflicts | decided | Both resolved: scale beats the POC example (B-1); `notchCalculator` takes no profile (B-44/B-48, supersedes B-2/B-21); it applies `ind11-13` (confirmed, B-57/B-60); `ind12` stays inside `countryRatingChangeWl`. POC text correction is a PM follow-up in the PR; this delivery does not edit the POC document (B-22). |
| PRD-priority | decided | REQ-06-02 first (Must); REQ-03-12 follows (Should) (B-8). |
| CON-interface | decided | `src/ratings/notch.mjs`: `RATING_SCALE`, `notchChange(previous, current)`, `notchCalculator(previous, current)` → `{notches, direction, wl}`. `src/indicators/countryRating.mjs`: `countryRatingChangeWl(previous, current)` → 0\|1\|2. Names and shapes per B-5; no profile argument (B-44/B-48). Input is the 19 ratings, trimmed and case-insensitive (B-40, B-43/B-49, supersedes B-3/B-4 strictness). `notchCalculator` applies `ind11-13` (B-57/B-60); profile selector dropped entirely; input per C1 (B-58/B-61). |
| CON-errors | decided | Never a guessed value, for missing/non-string/unknown rating (CAP-4) (no profile input). `notchCalculator` returns `{ error: <message naming the offending input> }`; `notchChange` (integer) and `countryRatingChangeWl` (0\|1\|2) throw a `RangeError` naming the offending input (B-20, B-40, B-42, B-50). Success results never carry `error`; error results never carry `wl` (B-33). `Aaa` folds to `AAA`: C1 does not name it, open. |
| CON-compat | n/a | No existing code or API (repo has no code). |
| ARC-style | decided | Library, plain Node.js ESM (B-6). |
| ARC-components | decided | `src/ratings/notch.mjs`, `src/indicators/countryRating.mjs`; tests under `test/` (B-5, B-6). |
| ARC-ui | decided | None — request: "this is not about screens". |
| ARC-layer | decided | Import-only shared library, no API (B-7). |
| ARC-stack | decided | Plain Node.js ESM (`.mjs`), tests with `node --test` (B-6, B-13); Node 18+ floor accepted (B-52). |
| ARC-deps | decided | None (B-6). |
| ARC-data | decided | No store (B-7). |
| ARC-integration | decided | No external call; rating fetching out of scope (B-7, B-12). |
| NFR-performance | n/a | Pure in-memory arithmetic. |
| NFR-security | n/a | No auth or secrets; input validation per CAP-4. |
| NFR-privacy | n/a | No personal data. |
| NFR-audit | n/a | Caller's concern (EPIC-05/07). |
| NFR-compliance | default | A4: mirror Excel scoring exactly; no interpretation. |
| TST-strategy | decided | Unit tests with `node:test` + `node:assert/strict` in `test/ratings/` and `test/indicators/`; full scale pairs and every WL boundary (CLAUDE.md). No integration/e2e. |
| DEL-ci | default | `npm test` (`node --test`) must pass. |
| DEL-deploy | decided | Import-only, no deployment (B-7). |
| DEL-docs | default | Short note in README on the helper API. |
