# Readiness — JOB-20261005-0619-rating-notch-change

29 item(s): 19 decided · 10 not applicable · 0 open

Sources: a requirement / file = from the request or the repo · `human:` = answered by the business · `pm:` = an implementation detail decided by Michael (the PM)

| Item | Status | Decision / reason | Source |
| --- | --- | --- | --- |
| **PRD-goal** What business outcome does this deliver, and how is success measured? | decided | Deliver the reusable notch-change function that Ind. 11, 12, 13 and the notch calculator (REQ-06-02) build on. Success = the REQ-06-02 examples (BBB+ to BB+ = 3, BB+ to BBB+ = -3, A to A = 0) pass under `node --test`. | request intro; REQ-06-02 (part) |
| **PRD-users** Who uses it (roles/personas), and what may each role see or do? | decided | No human users or roles. The only consumers are other POC modules that import the function. No access control. | request C4 |
| **PRD-scope** What is explicitly in scope and out of scope for this delivery? | decided | In: src/ratings/notch.mjs exporting RATING_SCALE and notchChange(previous, current), plus its tests. Out: the rest of REQ-06-02 and Ind. 11-13, any UI/CLI/printed output, persistence. | request intro, C4, Contract |
| **PRD-acceptance** Does every requirement have testable acceptance criteria with concrete examples? | decided | Yes. REQ-06-02 examples plus C1-C3: notchChange('BBB+','BB+') = 3; ('BB+','BBB+') = -3; ('A','A') = 0; ' bbb+ ' equals 'BBB+'; unknown rating, '', non-string or new String('A') throws RangeError. | request REQ-06-02, C1, C2, C3 |
| **PRD-conflicts** Do any requirements, examples or clarifications contradict each other? How is each resolved? | decided | No contradiction. The examples match C1+C3 (BBB+ index 7, BB+ index 10, so +3). C3 turns the N-notch wording into a signed integer. C2 says non-strings raise RangeError. CLAUDE.md puts tests at test/ratings/notch.test.mjs. | request C1, C2, C3; CLAUDE.md |
| **PRD-priority** What is the priority order (MoSCoW) if not everything can ship together? | n_a | One requirement and one card, nothing to prioritise. | request intro |
| **CON-interface** Are all public interfaces fully specified — names, inputs, outputs, types, units, signs, ranges, null/empty handling? | decided | Module src/ratings/notch.mjs with named ESM exports. RATING_SCALE = the 19 C1 ratings, best first. notchChange(previous, current) returns the integer index(current) - index(previous) (range -18..18; downgrade +, upgrade -, unchanged 0). Inputs trimmed with String.prototype.trim(), matched case-insensitively. | request Contract, C1, C3 |
| **CON-errors** What happens on invalid input and on failure (error types, codes, messages, fallbacks)? | decided | Any invalid argument throws RangeError, no fallback value: unknown rating, whitespace-only, '', undefined, null, number, missing argument, String object. | request C2 |
| **CON-compat** Must existing behaviour, APIs or data stay backward compatible? Is there versioning? | n_a | New module; the repo has no src/ratings code yet (only .gitkeep files), so nothing to stay compatible with and no versioning. | repo: git ls-files at 3fca1aa |
| **ARC-style** Architecture style: monolith, modular monolith, microservices, library? Where does this change live? | decided | Library: a pure-function module inside the POC codebase that other parts import. | request C4, Contract; CLAUDE.md |
| **ARC-components** Every component (service, BFF, app, library, worker, database) with its stack, repo path and owning role — written to readiness.json → architecture. | decided | One component: library 'ratings' (javascript, Node 18+ ESM) at src/ratings/ + test/ratings/, owner backend, reviewer reviewer. | request Contract; CLAUDE.md |
| **ARC-layer** Which layer owns the logic: BFF/API gateway, core/domain service, shared library, client? | decided | Shared domain library (src/ratings): pure, no I/O, imported by other POC modules. | CLAUDE.md; request C4 |
| **ARC-stack** Languages, frameworks and runtime versions — and are new dependencies allowed (licences)? | decided | Plain Node.js 18+ ES modules (.mjs). No npm dependencies. Tests use node:test + node:assert/strict. | CLAUDE.md; request Contract |
| **ARC-data** What data is stored, in which store, with which schema and migrations; who owns it? | n_a | No stored data; pure function, the scale is a code constant. | CLAUDE.md |
| **ARC-integration** Which external systems are called — protocol, auth, rate limits, timeouts, retries, failure behaviour? | n_a | No external systems; runs in-process. | CLAUDE.md; request C4 |
| **ARC-async** Synchronous or asynchronous (queues, events, jobs)? Ordering and idempotency requirements? | decided | Synchronous: notchChange returns the integer directly. Idempotent because pure. | request Contract; CLAUDE.md |
| **NFR-performance** Latency, throughput, data volume or load targets — or none for this delivery? | n_a | No targets; lookup over a fixed 19-entry scale, no I/O. | request C1; CLAUDE.md |
| **NFR-availability** Availability/resilience expectations, degradation when a dependency is down? | n_a | Imported library, not a running service. | request C4 |
| **NFR-security** Authentication, authorisation, input validation, secrets handling — what applies here? | decided | No auth or secrets (library, no I/O). Only control is input validation: primitive strings only, checked against RATING_SCALE, else RangeError. | request C2 |
| **NFR-privacy** Personal or sensitive data involved (KVKK/GDPR)? Retention, masking, logging rules? | n_a | Inputs are public rating codes only; no personal data, no logging. | request C1, C4 |
| **NFR-audit** Must actions or changes be audited (who, what, when), and for how long? | n_a | Pure function, no state changes. | CLAUDE.md |
| **NFR-observability** Logging, metrics, tracing and alerting required for this change? | n_a | No logging or metrics; prints nothing. | request C4 |
| **NFR-compliance** Domain regulations or internal policies that constrain the solution (e.g. banking regulation, model risk)? | decided | No regulatory or internal-policy constraint applies to this slice. | request C2 |
| **TST-strategy** Test expectations: unit (dev, TDD), integration/e2e (QA), coverage, test data, test environments? | decided | Backend writes unit tests first (TDD) in test/ratings/notch.test.mjs with node:test + node:assert/strict. QA re-runs them and checks C1-C3 edges: all 19 ratings, extremes AAA->CCC- = 18 and CCC-->AAA = -18, trimming and case, every C2 invalid kind. No coverage percentage, no test environments. | CLAUDE.md; request Contract |
| **DEL-ci** Which checks must pass to merge (lint, typecheck, tests, security scans)? | decided | `node --test` (= npm test) must pass. No lint, typecheck or security scan configured. | package.json |
| **DEL-deploy** How and where is it deployed or consumed; feature flags; rollback; migration order? | decided | Not deployed; other modules import src/ratings/notch.mjs. No flags or migrations; rollback = revert the merge. | request C4 |
| **DEL-docs** Documentation, changelog or runbook updates required? | n_a | No separate documentation deliverable (no README, changelog or runbook); the contract is in the request and the tests | pm: michael 2026-10-05 — one-function slice; the request Contract and the tests document the behaviour |
| **X-scale-shape** Is RATING_SCALE a plain Array or a frozen Array of the 19 upper-case strings? | decided | Frozen Array of the 19 upper-case strings | pm: michael 2026-10-05 — Consumers cannot silently break notchChange; C1 fixes order and content either way |
| **X-error-message** What should the RangeError message say, and which argument is checked first? | decided | RangeError message names the argument and the bad value; previous is checked first | pm: michael 2026-10-05 — Better diagnostics; tests assert only the error type per C2 |

## Architecture (frozen once the job is planned)

Style: library

| Component | Kind | Stack | Path | Owner (dev role) | Reviewer |
| --- | --- | --- | --- | --- | --- |
| ratings | library | javascript | `src/ratings/`, `test/ratings/` | backend | reviewer |
