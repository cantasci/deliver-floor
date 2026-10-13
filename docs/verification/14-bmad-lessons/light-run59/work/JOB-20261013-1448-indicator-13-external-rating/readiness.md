# Readiness — JOB-20261013-1448-indicator-13-external-rating

14 item(s): 12 decided · 2 not applicable · 0 open

Sources: a requirement / file = from the request or the repo · `human:` = answered by the business · `pm:` = an implementation detail decided by Michael (the PM)

| Item | Status | Decision / reason | Source |
| --- | --- | --- | --- |
| **PRD-goal** What business outcome does this deliver, and how is success measured? | decided | Indicator 13 calculates the client's WL from the notch change between previous and current external rating: 2-notch downgrade → WL 1, 3+ notches → WL 2; everything else WL 0. | request, ## Requirement, REQ-03-13 |
| **PRD-scope** What is explicitly in scope and out of scope for this delivery? | decided | In scope: src/indicators/externalRating.mjs exporting externalRatingChangeWl(previous, current), plus tests. Out of scope: any change to existing code, fetching/storing ratings, combining indicators, UI/API, new dependencies. | request, intro |
| **PRD-acceptance** Does every requirement have testable acceptance criteria with concrete examples? | decided | BBB+→BBB- (+2) gives 1; BBB+→BB+ (+3) gives 2; AAA→CCC- gives 2; BBB→BBB- (+1) gives 0; BB+→BBB+ (upgrade) gives 0; A→A gives 0; ' bbb+ '→'bb+' gives 2; BBB+→'nope' throws RangeError. | request, REQ-03-13 and ## Clarifications |
| **PRD-conflicts** Do any requirements, examples or clarifications contradict each other? How is each resolved? | decided | No contradictions: the clarification settles direction (an upgrade of any size gives WL 0). Indicator 13 thresholds (2→1, 3+→2) differ from Indicator 12's by design. | request, ## Clarifications |
| **CON-interface** Are all public interfaces fully specified — names, inputs, outputs, types, units, signs, ranges, null/empty handling? | decided | Named export externalRatingChangeWl(previous, current) in src/indicators/externalRating.mjs → 0|1|2. Ratings read as notchChange reads them; notchChange(previous,current) > 0 is a downgrade; ≥3 → 2, ===2 → 1, else 0. Pure, no I/O. | request, ## Contract |
| **CON-errors** What happens on invalid input and on failure (error types, codes, messages, fallbacks)? | decided | Anything off the scale (after trim/uppercase), including null/undefined/'' , throws the RangeError notchChange throws; no catching, no fallback. | request, ## Clarifications |
| **CON-compat** Must existing behaviour, APIs or data stay backward compatible? Is there versioning? | decided | Existing exports (RATING_SCALE, notchChange, notchCalculator, countryRatingChangeWl) and behaviour unchanged; existing tests stay green. | request, ## Clarifications |
| **ARC-style** Architecture style: monolith, modular monolith, microservices, library? Where does this change live? | decided | Confirmed: the drafted architecture is right — one plain Node ESM library at the repo root, code under src/, tests under test/, run with node --test. Keep it as the project's architecture. | human: e2e-human 2026-10-13 |
| **ARC-components** Every component (service, BFF, app, library, worker, database) with its stack, repo path and owning role — written to readiness.json → architecture. | decided | Confirmed: the drafted architecture is right — one plain Node ESM library at the repo root, code under src/, tests under test/, run with node --test. Keep it as the project's architecture. | human: e2e-human 2026-10-13 |
| **ARC-stack** Languages, frameworks and runtime versions From the repo's code or the request (quoted). A repo without code and a request that names no language → the best fit for the requirements, never a default: open, owner pm, with the evidence the request gives (the libraries, tools, platforms and data sources it names) and the alternatives — Michael decides it with that evidence quoted. | decided | Plain Node.js 18+ ES modules (.mjs), no npm dependencies; node:test with node:assert/strict, run with node --test. | request, last line; repo CLAUDE.md |
| **NFR-security** Authentication, authorisation, input validation, secrets handling — what applies here? | n_a | Pure function over two rating strings: no auth, secrets or I/O. Input validation is covered by CON-errors. | repo CLAUDE.md |
| **NFR-privacy** Personal or sensitive data involved (KVKK/GDPR)? Retention, masking, logging rules? | n_a | No personal data: inputs are two rating codes; nothing is stored or logged. | repo CLAUDE.md |
| **TST-strategy** Test expectations: unit (dev, TDD), integration/e2e (QA), coverage, test data, test environments? | decided | Dev unit tests (TDD) in test/unit/indicators/externalRating.test.mjs; QA integration tests in test/integration/indicators/externalRating.int.test.mjs using the real notchChange/RATING_SCALE, covering notches -18,-1,0,+1,+2,+3,+18, trim/case, and RangeError cases. Full suite: node --test. | request, last line |
| **X-rating-scale**  | decided | Only the 19 grades of RATING_SCALE count; CC/C/D/SD, NR/WD and Moody's notation are rejected with RangeError. Risk to list in the plan: a client downgraded to D throws instead of getting WL 2. | request, ## Clarifications |

## Architecture (frozen once the job is planned)

Style: library

| Component | Kind | Stack | Path | Owner (dev role) | Reviewer | Suite at a QA pass |
| --- | --- | --- | --- | --- | --- | --- |
| watchlist-poc | library | javascript, node | `.` | backend | reviewer | `node --test` |
