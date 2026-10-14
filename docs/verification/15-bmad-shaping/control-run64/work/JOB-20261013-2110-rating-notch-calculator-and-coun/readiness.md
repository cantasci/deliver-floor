# Readiness — JOB-20261013-2110-rating-notch-calculator-and-coun

35 item(s): 28 decided · 7 not applicable · 0 open

Sources: a requirement / file = from the request or the repo · `human:` = answered by the business · `pm:` = an implementation detail decided by Michael (the PM)

| Item | Status | Decision / reason | Source |
| --- | --- | --- | --- |
| **PRD-goal** What business outcome does this deliver, and how is success measured? | decided | Replace the analyst's manual, subjective reading of rating changes with a deterministic notch count and WL: Ind. 12 gets its WL from the notch change, and a notch calculator helper gives notch change + resultant WL for any previous/current rating pair. Success = the REQ-06-02 and REQ-03-12 acceptance criteria pass under node --test. | docs/POC_Requirements_v0.2_EN.md §1 Problem Statement |
| **PRD-users** Who uses it (roles/personas), and what may each role see or do? | decided | The credit analyst (single user, no roles or authentication in the POC) uses the calculator; other POC modules are the programmatic consumers of the contract. | request: REQ-06-02 |
| **PRD-scope** What is explicitly in scope and out of scope for this delivery? | decided | The caller passes the rating the analyst confirmed or edited. No override parameter, no persistence, no audit trail in this slice. | human: e2e-human 2026-10-13 |
| **PRD-acceptance** Does every requirement have testable acceptance criteria with concrete examples? | decided | (a) Confirm the BA's table once X-example-notches, X-calc-wl-rule, X-upgrade-wl are answered | human: e2e-human 2026-10-13 |
| **PRD-conflicts** Do any requirements, examples or clarifications contradict each other? How is each resolved? | decided | Resolve each X- item | human: e2e-human 2026-10-13 |
| **PRD-priority** What is the priority order (MoSCoW) if not everything can ship together? | decided | REQ-03-12 is Must, REQ-06-02 is Should. Build shared notchChange first. | docs/POC_Requirements_v0.2_EN.md §5 |
| **CON-interface** Are all public interfaces fully specified — names, inputs, outputs, types, units, signs, ranges, null/empty handling? | decided | notchCalculator(...).notches is signed exactly like notchChange: downgrade positive, upgrade negative (BB → BBB is -3); direction says the same in words. | human: e2e-human 2026-10-13 |
| **CON-errors** What happens on invalid input and on failure (error types, codes, messages, fallbacks)? | decided | RangeError for every invalid input, strings and non-strings alike (null, undefined, 42, {} included). | human: e2e-human 2026-10-13 |
| **CON-compat** Must existing behaviour, APIs or data stay backward compatible? Is there versioning? | decided | Nothing to stay compatible with; new exports are the contract. | request: Contract |
| **ARC-style** Architecture style: monolith, modular monolith, microservices, library? Where does this change live? | decided | Confirmed: the drafted architecture is right — one plain Node ESM library at the repo root, code under src/, tests under test/, run with node --test. Keep it as the project's architecture. | human: e2e-human 2026-10-13 |
| **ARC-components** Every component (service, BFF, app, library, worker, database) with its stack, repo path and owning role — written to readiness.json → architecture. | decided | Confirmed: the drafted architecture is right — one plain Node ESM library at the repo root, code under src/, tests under test/, run with node --test. Keep it as the project's architecture. | human: e2e-human 2026-10-13 |
| **ARC-ui** Is there a user interface — none, web, desktop or mobile app? Who uses it, and with which stack? | decided | (a, BA recommendation) None | human: e2e-human 2026-10-13 |
| **ARC-layer** Which layer owns the logic: BFF/API gateway or other middleware, core/domain service, shared library, client? Is there an API, and for whom? | decided | Shared domain library modules consumed by in-process import; no API. | request: Contract |
| **ARC-stack** Languages, frameworks and runtime versions From the repo's code or the request (quoted). A repo without code and a request that names no language → the best fit for the requirements, never a default: open, owner pm, with the evidence the request gives (the libraries, tools, platforms and data sources it names) and the alternatives — Michael decides it with that evidence quoted. | decided | Plain Node.js ESM (.mjs), Node 18+ per CLAUDE.md, no dependencies, node:test. | request: Contract |
| **ARC-deps** May the delivery add new dependencies or libraries (which, under which licences), or must it stay on what the repo already uses? | decided | No new dependencies. | request: Contract |
| **ARC-data** Is there a database or other store? What data is stored, in which store, with which schema and migrations; who owns it? | decided | (a, BA recommendation) No store — pure functions | human: e2e-human 2026-10-13 |
| **ARC-integration** Which external systems are called — protocol, auth, rate limits, timeouts, retries, failure behaviour? | decided | (a, BA recommendation) None — fetch is REQ-02-02, a separate job | human: e2e-human 2026-10-13 |
| **ARC-async** Synchronous or asynchronous (queues, events, jobs)? Ordering and idempotency requirements? | n_a | Synchronous pure functions. | CLAUDE.md |
| **NFR-performance** Latency, throughput, data volume or load targets — or none for this delivery? | n_a | In-memory lookups on a ~19-entry scale. | CLAUDE.md |
| **NFR-availability** Availability/resilience expectations, degradation when a dependency is down? | n_a | A library, no dependency can be down. | CLAUDE.md |
| **NFR-security** Authentication, authorisation, input validation, secrets handling — what applies here? | decided | No authentication (single-user POC); no secrets. Input validation per CON-errors. | docs/POC_Requirements_v0.2_EN.md §7 A1 |
| **NFR-privacy** Personal or sensitive data involved (KVKK/GDPR)? Retention, masking, logging rules? | n_a | Inputs are public rating codes only. | request: Contract |
| **NFR-audit** Must actions or changes be audited (who, what, when), and for how long? | n_a | Pure functions record nothing; override audit is outside this slice. | request |
| **NFR-observability** Logging, metrics, tracing and alerting required for this change? | n_a | No logging in pure functions. | CLAUDE.md |
| **NFR-compliance** Domain regulations or internal policies that constrain the solution (e.g. banking regulation, model risk)? | decided | WL rules must mirror the Excel dropdown sheet exactly; ambiguities go to business. | docs/POC_Requirements_v0.2_EN.md §7 A4 |
| **TST-strategy** Test expectations: unit (dev, TDD), integration/e2e (QA), coverage, test data, test environments? | decided | node:test + assert/strict; unit tests by dev in test/ratings and test/indicators; QA integration tests with the confirmed example table. | CLAUDE.md |
| **DEL-ci** Which checks must pass to merge (lint, typecheck, tests, security scans)? | decided | node --test must pass; no lint or scanners. | .deliver.json |
| **DEL-deploy** How and where is it deployed or consumed; feature flags; rollback; migration order? | decided | Not deployed; consumed by in-repo import. | request: Contract |
| **DEL-docs** Documentation, changelog or runbook updates required? | n_a | The request asks for no documentation or changelog; the contract is in the request itself. | request: Contract |
| **X-example-notches** Which part of the example is right? | decided | (a) Standard counting: 3-notch downgrade; example count is a typo, WL follows X-calc-wl-rule | human: e2e-human 2026-10-13 |
| **X-calc-wl-rule** Which threshold rule gives notchCalculator's wl? | decided | (a) Ind. 13 rule: 0-1 down → 0; 2 → 1; 3+ → 2 | human: e2e-human 2026-10-13 |
| **X-upgrade-wl** What WL do unchanged and upgrade give? | decided | (a, BA recommendation) WL=0 for unchanged and any upgrade | human: e2e-human 2026-10-13 |
| **X-rating-scale** What is in RATING_SCALE? | decided | (a, BA recommendation) the 19 grades AAA…CCC-; anything else invalid | human: e2e-human 2026-10-13 |
| **X-input-format** Are 'bbb+', ' BBB+ ', 'BBB−' accepted? | decided | (a) Exact match only | human: e2e-human 2026-10-13 |
| **X-ind13-scope**  | decided | Ind. 13 is not built; quoted only as related context. | request |

## Architecture (frozen once the job is planned)

Style: library

| Component | Kind | Stack | Path | Owner (dev role) | Reviewer | Suite at a QA pass |
| --- | --- | --- | --- | --- | --- | --- |
| watchlist-poc | library | javascript, node | `src/ratings/`, `src/indicators/`, `test/ratings/`, `test/indicators/` | backend | reviewer | `npm test` |
