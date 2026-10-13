# Readiness — JOB-20261013-1531-indicator-13-external-rating-cha

13 item(s): 12 decided · 1 not applicable · 0 open

Sources: a requirement / file = from the request or the repo · `human:` = answered by the business · `pm:` = an implementation detail decided by Michael (the PM)

| Item | Status | Decision / reason | Source |
| --- | --- | --- | --- |
| **PRD-goal** What business outcome does this deliver, and how is success measured? | decided | Indicator 13 calculates the Watchlist level from the change between a client's previous and current external rating; success = the function returns the REQ-03-13 WL for every rating pair on the scale. | request: REQ-03-13 |
| **PRD-scope** What is explicitly in scope and out of scope for this delivery? | decided | In scope: new src/indicators/externalRatingChangeWl module externalRating.mjs plus its tests. Out of scope: any change to existing exports (notch.mjs, countryRating.mjs), rating sourcing, combining indicators, other scales, D/SD/NR/WD codes. | request: intro |
| **PRD-acceptance** Does every requirement have testable acceptance criteria with concrete examples? | decided | notchChange(previous,current): 2 → WL1 (BBB+→BBB-); 3+ → WL2 (BBB+→BB+, AAA→CCC-); 1, 0 or upgrade → WL0 (BBB+→BBB, AA→AA, BB→BBB); ' bbb+ '→'bb+' = 2; ('X','A') throws RangeError. | request: REQ-03-13 + Clarifications |
| **PRD-conflicts** Do any requirements, examples or clarifications contradict each other? How is each resolved? | decided | No contradiction: '3+ notches' has no direction, the clarification settles that only downgrades count; upgrades and 1-notch downgrades give WL 0. Not to be confused with Indicator 12 (1→1, 2+→2). | request: Clarifications |
| **CON-interface** Are all public interfaces fully specified — names, inputs, outputs, types, units, signs, ranges, null/empty handling? | decided | src/indicators/externalRating.mjs exports named function externalRatingChangeWl(previous, current) returning the number 0, 1 or 2, built on notchChange (imported from ../ratings/notch.mjs, no second copy of the scale). Argument order: previous, current; positive notchChange = downgrade. | request: Contract |
| **CON-errors** What happens on invalid input and on failure (error types, codes, messages, fallbacks)? | decided | Any rating notchChange rejects throws its RangeError unchanged; no fallback WL. Tests assert the type, not which argument is named. | request: Clarifications |
| **CON-compat** Must existing behaviour, APIs or data stay backward compatible? Is there versioning? | decided | Additive only: RATING_SCALE, notchChange, notchCalculator and countryRatingChangeWl and all existing tests stay unchanged; the new function is not added to notch.mjs. | request: Clarifications |
| **ARC-style** Architecture style: monolith, modular monolith, microservices, library? Where does this change live? | decided | Confirmed: the drafted architecture is right — one plain Node ESM library at the repo root, code under src/, tests under test/, run with node --test. Keep it as the project's architecture. | human: e2e-human 2026-10-13 |
| **ARC-components** Every component (service, BFF, app, library, worker, database) with its stack, repo path and owning role — written to readiness.json → architecture. | decided | Confirmed: the drafted architecture is right — one plain Node ESM library at the repo root, code under src/, tests under test/, run with node --test. Keep it as the project's architecture. | human: e2e-human 2026-10-13 |
| **ARC-stack** Languages, frameworks and runtime versions From the repo's code or the request (quoted). A repo without code and a request that names no language → the best fit for the requirements, never a default: open, owner pm, with the evidence the request gives (the libraries, tools, platforms and data sources it names) and the alternatives — Michael decides it with that evidence quoted. | decided | Node.js 18+, plain ES modules (.mjs), no npm dependencies; node:test and node:assert/strict. | request: Contract |
| **NFR-security** Authentication, authorisation, input validation, secrets handling — what applies here? | decided | Only input validation applies: pure function, no auth, secrets or I/O; input is validated against the closed scale through notchChange. | request: Clarifications |
| **NFR-privacy** Personal or sensitive data involved (KVKK/GDPR)? Retention, masking, logging rules? | n_a | No personal data: the inputs are two rating codes, no I/O or logging. | request: Contract |
| **TST-strategy** Test expectations: unit (dev, TDD), integration/e2e (QA), coverage, test data, test environments? | decided | node:test via npm test, like the existing tests: dev unit tests under test/unit/indicators/, QA integration tests under test/integration/indicators/ (.int.test.mjs) on the real RATING_SCALE. | request: Contract |

## Architecture (frozen once the job is planned)

Style: library

| Component | Kind | Stack | Path | Owner (dev role) | Reviewer | Suite at a QA pass |
| --- | --- | --- | --- | --- | --- | --- |
| repo | library | node | `.` | backend | reviewer | `npm test` |
