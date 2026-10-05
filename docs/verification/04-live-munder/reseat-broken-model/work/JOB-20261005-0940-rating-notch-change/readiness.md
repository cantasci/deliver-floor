# Readiness — JOB-20261005-0940-rating-notch-change

30 item(s): 18 decided · 12 not applicable · 0 open

Sources: a requirement / file = from the request or the repo · `human:` = answered by the business · `pm:` = an implementation detail decided by Michael (the PM)

| Item | Status | Decision / reason | Source |
| --- | --- | --- | --- |
| **PRD-goal** What business outcome does this deliver, and how is success measured? | decided | Provide the notch calculator used by Indicators 11, 12, 13: signed number of scale steps between a previous and a current rating. Success = the three AC examples hold (BBB+→BB+ = 3, BB+→BBB+ = -3, A→A = 0) plus the clarified edge cases. | JOB request, Requirement table REQ-06-02 (part) |
| **PRD-users** Who uses it (roles/personas), and what may each role see or do? | n_a | No human user or role: a pure function imported by other POC parts, no UI/CLI. | JOB request, C4 |
| **PRD-scope** What is explicitly in scope and out of scope for this delivery? | decided | In scope: src/ratings/notch.mjs exporting RATING_SCALE and notchChange, with tests under test/. Out of scope: Indicators 11–13 themselves, UI/CLI/output, the rest of REQ-06-02 and the POC. | JOB request, intro and Contract |
| **PRD-acceptance** Does every requirement have testable acceptance criteria with concrete examples? | decided | Three concrete examples in the requirement, plus C1–C3 give edge rules (trim, case, invalid inputs, sign). Cards will add concrete tables. | JOB request, Requirement table |
| **PRD-conflicts** Do any requirements, examples or clarifications contradict each other? How is each resolved? | decided | No contradiction found. Checked: BBB+(index 7) to BB+(index 10) is 3 steps on the C1 scale; sign C3 (downgrade positive) gives +3, upgrade -3, matching the examples. Note the examples say 'downgrade'/'upgrade' without numbers, so the signed values +3/-3 follow from C3 (current index minus previous index). | JOB request, C1 and C3 |
| **PRD-priority** What is the priority order (MoSCoW) if not everything can ship together? | n_a | Single card, single requirement; nothing to prioritise. | JOB request, intro |
| **CON-interface** Are all public interfaces fully specified — names, inputs, outputs, types, units, signs, ranges, null/empty handling? | decided | src/ratings/notch.mjs exports RATING_SCALE (19 ratings, best first) and notchChange(previous, current) returning an integer, positive on downgrade. Inputs are trimmed with trim() and matched case-insensitively. Both args are validated. | JOB request, Contract and C1/C3 |
| **CON-errors** What happens on invalid input and on failure (error types, codes, messages, fallbacks)? | decided | Any invalid input (unknown rating, empty string, whitespace-only after trim, non-string incl. String object, null/undefined/number) throws RangeError, for either argument. Error message text is not specified (see X-error-message). | JOB request, C2 |
| **CON-compat** Must existing behaviour, APIs or data stay backward compatible? Is there versioning? | n_a | Greenfield: src/ and test/ contain only .gitkeep, so nothing exists to stay compatible with and no versioning applies. | repo: git ls-files shows src/.gitkeep and test/.gitkeep only |
| **ARC-style** Architecture style: monolith, modular monolith, microservices, library? Where does this change live? | decided | Single-component library (plain Node ESM module) in a monolith POC repo; the change lives in src/ratings/notch.mjs. | JOB request, Contract and C4 |
| **ARC-components** Every component (service, BFF, app, library, worker, database) with its stack, repo path and owning role — written to readiness.json → architecture. | decided | One component, 'ratings-lib': library, stack javascript/node ESM, paths src/ratings/ and test/ratings/ (see architecture), owner backend, reviewer reviewer-javascript (ecc:typescript-reviewer). | JOB request, Contract and ROLES line |
| **ARC-layer** Which layer owns the logic: BFF/API gateway, core/domain service, shared library, client? | decided | Shared library / pure domain function; no BFF, service or client. | CLAUDE.md |
| **ARC-data** What data is stored, in which store, with which schema and migrations; who owns it? | n_a | No data stored; the scale is an in-code constant. | JOB request, Contract |
| **ARC-integration** Which external systems are called — protocol, auth, rate limits, timeouts, retries, failure behaviour? | n_a | No external systems called. | CLAUDE.md |
| **ARC-async** Synchronous or asynchronous (queues, events, jobs)? Ordering and idempotency requirements? | decided | Synchronous pure function; no queues, ordering or idempotency concerns (it is trivially idempotent). | CLAUDE.md |
| **ARC-stack** Languages, frameworks and runtime versions — and are new dependencies allowed (licences)? | decided | Plain Node.js 18+ ES modules (.mjs), no dependencies; adding any is not allowed. | CLAUDE.md |
| **NFR-performance** Latency, throughput, data volume or load targets — or none for this delivery? | n_a | No latency/throughput target is stated for a 19-element lookup. | JOB request (no performance requirement present) |
| **NFR-availability** Availability/resilience expectations, degradation when a dependency is down? | n_a | In-process pure function; no dependency that can be down. | CLAUDE.md |
| **NFR-security** Authentication, authorisation, input validation, secrets handling — what applies here? | decided | Only input validation applies: strict type check (typeof === 'string') and RangeError on anything not on the scale. No auth or secrets. | JOB request, C2 |
| **NFR-privacy** Personal or sensitive data involved (KVKK/GDPR)? Retention, masking, logging rules? | n_a | Only public rating labels; no personal data, nothing logged or retained. | JOB request, C4 |
| **NFR-audit** Must actions or changes be audited (who, what, when), and for how long? | n_a | Pure calculation, no actions or changes to audit. | JOB request, C4 |
| **NFR-observability** Logging, metrics, tracing and alerting required for this change? | n_a | No logging or metrics; the function does no I/O. | CLAUDE.md |
| **NFR-compliance** Domain regulations or internal policies that constrain the solution (e.g. banking regulation, model risk)? | n_a | The business unit confirmed that no regulatory or policy constraint applies to this slice. | JOB request, C2 |
| **TST-strategy** Test expectations: unit (dev, TDD), integration/e2e (QA), coverage, test data, test environments? | decided | Unit tests with node:test + node:assert/strict, in test/ratings/notch.test.mjs, run by `node --test` / `npm test`. Dev writes them TDD; QA adds the AC-level checks. No coverage threshold stated. | CLAUDE.md and JOB request |
| **DEL-ci** Which checks must pass to merge (lint, typecheck, tests, security scans)? | decided | Only `node --test` (npm test). No lint, typecheck or scan is configured (package.json has only the test script). | package.json |
| **DEL-deploy** How and where is it deployed or consumed; feature flags; rollback; migration order? | decided | Consumed by import from other POC modules; no deployment, flags or migrations. Rollback = revert the commit. | JOB request, C4 |
| **DEL-docs** Documentation, changelog or runbook updates required? | n_a | No documentation, README or changelog update is required for this slice; the module header comment is enough. | pm: one-module POC slice imported by other POC parts (C4); the request asks for code + tests only |
| **X-error-message** C2 fixes the error type (RangeError) but not the message text. Must tests assert a message? | decided | Tests assert only the error type (RangeError). The message names the offending argument (previous/current) and value, but its exact text is not part of the contract. | pm: michael 2026-10-05 — C2 fixes only the type; pinning the text would make tests brittle without any business rule behind them. |
| **X-scale-immutability** Should RATING_SCALE be frozen (Object.freeze) so that consumers cannot mutate it? The contract only says it is the 19 ratings, best first. | decided | RATING_SCALE is exported frozen (Object.freeze), and a test checks it is frozen and has the 19 C1 ratings in order. | pm: michael 2026-10-05 — The scale is shared reference data for Indicators 11-13; freezing stops a consumer from silently corrupting every other caller, and it costs nothing. |
| **X-nonstring-and-zero**  | decided | Result for equal ratings must be +0, not -0 (tests using assert.strictEqual would fail on -0). Both arguments are validated, so an invalid previous or current throws even when the other is valid. null/undefined/number/object are non-strings and throw RangeError (not TypeError). | JOB request, C2 and C3 |

## Architecture (frozen once the job is planned)

Style: library

| Component | Kind | Stack | Path | Owner (dev role) | Reviewer |
| --- | --- | --- | --- | --- | --- |
| ratings-lib | library | javascript, node-esm | `src/ratings/`, `test/ratings/` | backend | reviewer |
