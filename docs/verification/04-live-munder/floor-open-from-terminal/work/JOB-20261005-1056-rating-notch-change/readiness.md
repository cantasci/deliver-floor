# Readiness — JOB-20261005-1056-rating-notch-change

27 item(s): 16 decided · 11 not applicable · 0 open

Sources: a requirement / file = from the request or the repo · `human:` = answered by the business · `pm:` = an implementation detail decided by Michael (the PM)

| Item | Status | Decision / reason | Source |
| --- | --- | --- | --- |
| **PRD-goal** What business outcome does this deliver, and how is success measured? | decided | Deliver the notch calculator notchChange(previous, current) that Indicators 11, 12, 13 build on. Success = the three REQ-06-02 examples hold: BBB+ to BB+ = +3, BB+ to BBB+ = -3, A to A = 0, plus the C1-C3 rules. | JOB request, Requirement table (REQ-06-02) |
| **PRD-users** Who uses it (roles/personas), and what may each role see or do? | decided | No end users or roles; the only consumers are other POC modules that import the function. No role-based visibility applies. | JOB request, C4 |
| **PRD-scope** What is explicitly in scope and out of scope for this delivery? | decided | In scope: RATING_SCALE and notchChange in src/ratings/notch.mjs with tests under test/. Out of scope: Indicators 11-13, any UI/CLI/printing, other REQ-06 parts. | JOB request, intro |
| **PRD-acceptance** Does every requirement have testable acceptance criteria with concrete examples? | decided | Yes: REQ-06-02 gives three concrete examples; C1-C3 give scale, normalisation, error and sign rules that can be turned into Given/When/Then with concrete values. | JOB request, Requirement table |
| **PRD-conflicts** Do any requirements, examples or clarifications contradict each other? How is each resolved? | decided | No contradictions found. On the C1 scale BBB+ is index 7 and BB+ index 10, so 3 steps; downgrade = positive (C3) matches the examples; BB+ to BBB+ gives -3; A to A gives 0. | JOB request, C3 vs Requirement table |
| **PRD-priority** What is the priority order (MoSCoW) if not everything can ship together? | n_a | Single card, single requirement: nothing to prioritise or split. | JOB request, intro |
| **CON-interface** Are all public interfaces fully specified — names, inputs, outputs, types, units, signs, ranges, null/empty handling? | decided | src/ratings/notch.mjs exports RATING_SCALE (the 19 ratings, best first) and notchChange(previous, current) returning an integer = index(current) - index(previous). Inputs trimmed with trim() and case-insensitive; result signed per C3. | JOB request, Contract |
| **CON-errors** What happens on invalid input and on failure (error types, codes, messages, fallbacks)? | decided | Any unknown rating, empty string or non-string (String object, null, undefined, number) throws RangeError, for either argument. Whitespace-only input trims to empty and is rejected. | JOB request, C2 |
| **CON-compat** Must existing behaviour, APIs or data stay backward compatible? Is there versioning? | n_a | New module; src/ and test/ contain no files yet, so there is no existing behaviour, API or data to keep compatible; no versioning stated. | JOB request, Contract |
| **ARC-style** Architecture style: monolith, modular monolith, microservices, library? Where does this change live? | decided | Plain library module inside a single-component repo with area folders under src/. The change lives in src/ratings/notch.mjs with tests under test/. | README.md |
| **ARC-components** Every component (service, BFF, app, library, worker, database) with its stack, repo path and owning role — written to readiness.json → architecture. | decided | One component: ratings library, stack javascript (Node ESM), paths src/ratings/ and test/ratings/, owner backend, reviewer reviewer-javascript. See architecture block. | JOB request, Contract |
| **ARC-layer** Which layer owns the logic: BFF/API gateway, core/domain service, shared library, client? | decided | Shared domain library (pure functions) imported by other POC areas; no BFF, gateway or client layer. | CLAUDE.md |
| **ARC-stack** Languages, frameworks and runtime versions — and are new dependencies allowed (licences)? | decided | Plain Node.js 18+ ES modules (.mjs); no new dependencies allowed. | CLAUDE.md |
| **ARC-data** What data is stored, in which store, with which schema and migrations; who owns it? | n_a | No data is stored; pure function over an in-memory constant scale. | CLAUDE.md |
| **ARC-integration** Which external systems are called — protocol, auth, rate limits, timeouts, retries, failure behaviour? | n_a | No external systems are called. | CLAUDE.md |
| **ARC-async** Synchronous or asynchronous (queues, events, jobs)? Ordering and idempotency requirements? | n_a | Synchronous pure function; no queues, events or jobs. | CLAUDE.md |
| **NFR-performance** Latency, throughput, data volume or load targets — or none for this delivery? | n_a | No latency/throughput/volume targets stated; 19-element lookup. | JOB request, Contract |
| **NFR-availability** Availability/resilience expectations, degradation when a dependency is down? | n_a | In-process pure function with no dependencies; nothing can be down. | CLAUDE.md |
| **NFR-security** Authentication, authorisation, input validation, secrets handling — what applies here? | decided | Only input validation applies: strict type check, reject everything that is not a primitive string with RangeError; no auth or secrets. | JOB request, C2 |
| **NFR-privacy** Personal or sensitive data involved (KVKK/GDPR)? Retention, masking, logging rules? | n_a | Only rating codes are handled; no personal data, and nothing is logged or printed. | JOB request, C4 |
| **NFR-audit** Must actions or changes be audited (who, what, when), and for how long? | n_a | Pure calculation with no state change; no audit requirement stated. | JOB request, C4 |
| **NFR-observability** Logging, metrics, tracing and alerting required for this change? | n_a | No logging, metrics or tracing: the function prints nothing. | JOB request, C4 |
| **NFR-compliance** Domain regulations or internal policies that constrain the solution (e.g. banking regulation, model risk)? | decided | None applies to this slice. | JOB request, C2 |
| **TST-strategy** Test expectations: unit (dev, TDD), integration/e2e (QA), coverage, test data, test environments? | decided | Dev writes unit tests with node:test + node:assert/strict in test/ratings/notch.test.mjs (TDD); QA covers integration/AC checks. Test data: the three REQ-06-02 examples, all 19 scale entries, trim/case variants, C2 invalid inputs (unknown, empty, whitespace-only, null, undefined, number, String object). No coverage threshold stated. | CLAUDE.md |
| **DEL-ci** Which checks must pass to merge (lint, typecheck, tests, security scans)? | decided | Full verification is node --test (npm test) green; no lint, typecheck or scan is configured in the repo. | package.json |
| **DEL-deploy** How and where is it deployed or consumed; feature flags; rollback; migration order? | decided | Not deployed; consumed by import from other POC modules. No flags or migrations; rollback = revert the commit. | JOB request, C4 |
| **DEL-docs** Documentation, changelog or runbook updates required? | n_a | No documentation, changelog or runbook update is requested; the Contract names only the module and tests. | JOB request, Contract |

## Architecture (frozen once the job is planned)

Style: library

| Component | Kind | Stack | Path | Owner (dev role) | Reviewer |
| --- | --- | --- | --- | --- | --- |
| ratings-lib | library | javascript, nodejs-esm | `src/ratings/`, `test/ratings/` | backend | reviewer |
