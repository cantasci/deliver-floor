# Readiness — JOB-20261003-1505-repayment-delay-indicators-2-3

30 item(s): 17 decided · 13 not applicable · 0 open

Sources: a requirement / file = from the request or the repo · `human:` = answered by the business · `pm:` = an implementation detail decided by Michael (the PM)

| Item | Status | Decision / reason | Source |
| --- | --- | --- | --- |
| **PRD-goal** What business outcome does this deliver, and how is success measured? | decided | Provide the WL mapping for Indicator 2 (days with delay) and Indicator 3 (delays in 12 months) as pure functions plus exported option lists. Success: the mappings in REQ-03-02/03 hold for every option, invalid input throws RangeError, node --test is green. | JOB request, REQ-03-02, REQ-03-03, C1-C2 |
| **PRD-users** Who uses it (roles/personas), and what may each role see or do? | n_a | No end users or roles in this slice; the consumers are later POC screens/rating code calling the functions. No UI, no access control. | JOB request C3, C4 |
| **PRD-scope** What is explicitly in scope and out of scope for this delivery? | decided | In: src/indicators/daysWithDelay.mjs and delayCount.mjs with option lists and WL functions, plus their tests. Out: Indicator 1 and its collapsing of 2-3, UI, counting delays (caller does), aggregation to overall WL. | JOB request C3, C4, C6, Contract |
| **PRD-acceptance** Does every requirement have testable acceptance criteria with concrete examples? | decided | Yes. Option→WL: Ind.2 'no delay'→0, '<=3 days'→0, '>3 days'→2, '>60 days'→3, '>90 days'→4; Ind.3 '0'→0, '1'→1, '>1'→2. Invalid: ' >3 days ' trimmed OK; '>3 Days', '', 'foo', null, 5 → RangeError. | REQ-03-02, REQ-03-03, C1, C2, C5 |
| **PRD-conflicts** Do any requirements, examples or clarifications contradict each other? How is each resolved? | decided | Two surface differences, both resolved by the request: (1) POC writes '≤3 days', clarification C1 fixes the ASCII string '<=3 days'; (2) REQ-03-02 acceptance summary lists WL only for >3/>60/>90, C2 supplies 0 for 'no delay' and '<=3 days'. Options '>3 days'/'>60 days'/'>90 days' overlap numerically but are discrete exact-match labels, so no conflict. | C1, C2, REQ-03-02 |
| **PRD-priority** What is the priority order (MoSCoW) if not everything can ship together? | decided | Both requirements are equal priority (Must) and independent; they ship together, either can merge first. | JOB request ('independent of each other') |
| **CON-interface** Are all public interfaces fully specified — names, inputs, outputs, types, units, signs, ranges, null/empty handling? | decided | daysWithDelay.mjs: export const DAYS_WITH_DELAY_OPTIONS (5 strings in order: 'no delay','<=3 days','>3 days','>60 days','>90 days'); export function daysWithDelayWl(option) → 0|2|3|4. delayCount.mjs: export const DELAY_COUNT_OPTIONS ('0','1','>1'); export function delayCountWl(option) → 0|1|2. Input: string, trimmed, exact case-sensitive match. | Contract, C1, C5 |
| **CON-errors** What happens on invalid input and on failure (error types, codes, messages, fallbacks)? | decided | Any value not in the list after trimming, and any non-string (null, undefined, number, object), throws RangeError. Message text is not specified. | C1, C5 |
| **CON-compat** Must existing behaviour, APIs or data stay backward compatible? Is there versioning? | n_a | New files only; repo src/ is empty, nothing to keep compatible. No versioning. | repo: src/ and test/ empty |
| **ARC-style** Architecture style: monolith, modular monolith, microservices, library? Where does this change live? | decided | Library: pure functions in a single-package plain Node ESM repo, under src/indicators. | CLAUDE.md, Contract |
| **ARC-components** Every component (service, BFF, app, library, worker, database) with its stack, repo path and owning role — written to readiness.json → architecture. | decided | One component, see architecture. | CLAUDE.md, Contract |
| **ARC-layer** Which layer owns the logic: BFF/API gateway, core/domain service, shared library, client? | decided | Shared domain library layer (src/indicators), no I/O. | CLAUDE.md: 'Pure functions, no I/O in src/ratings and src/indicators' |
| **ARC-stack** Languages, frameworks and runtime versions — and are new dependencies allowed (licences)? | decided | Plain Node.js 18+ ES modules (.mjs), node:test + node:assert/strict; no new dependencies allowed. | CLAUDE.md, JOB request |
| **ARC-data** What data is stored, in which store, with which schema and migrations; who owns it? | n_a | No data stored. | pure functions, CLAUDE.md |
| **ARC-integration** Which external systems are called — protocol, auth, rate limits, timeouts, retries, failure behaviour? | n_a | No external systems. | pure functions, CLAUDE.md |
| **ARC-async** Synchronous or asynchronous (queues, events, jobs)? Ordering and idempotency requirements? | n_a | Synchronous pure functions. | Contract signatures |
| **NFR-performance** Latency, throughput, data volume or load targets — or none for this delivery? | n_a | No targets; constant-time lookup. | JOB request is silent; trivial mapping |
| **NFR-availability** Availability/resilience expectations, degradation when a dependency is down? | n_a | In-process library, no dependencies. | CLAUDE.md |
| **NFR-security** Authentication, authorisation, input validation, secrets handling — what applies here? | decided | Only input validation applies: strict type and value check, RangeError on anything unexpected; no secrets, auth. | C1, C5 |
| **NFR-privacy** Personal or sensitive data involved (KVKK/GDPR)? Retention, masking, logging rules? | n_a | Inputs are dropdown labels, no personal data; no logging. | Contract |
| **NFR-audit** Must actions or changes be audited (who, what, when), and for how long? | n_a | No auditing in this slice. | JOB request scope |
| **NFR-observability** Logging, metrics, tracing and alerting required for this change? | n_a | None; pure functions, no I/O. | CLAUDE.md |
| **NFR-compliance** Domain regulations or internal policies that constrain the solution (e.g. banking regulation, model risk)? | n_a | No regulation constrains this slice beyond the WL values stated in the POC. | JOB request |
| **TST-strategy** Test expectations: unit (dev, TDD), integration/e2e (QA), coverage, test data, test environments? | decided | Unit tests by the devs (TDD) in test/indicators/<name>.test.mjs with node:test; QA verifies each AC end to end via the public exports. Test data: every option, trimmed variants, wrong case, empty string, unknown string, non-strings. Full run: node --test. | CLAUDE.md, JOB request |
| **DEL-ci** Which checks must pass to merge (lint, typecheck, tests, security scans)? | decided | node --test must pass; no lint/typecheck configured in package.json. | package.json, role card |
| **DEL-deploy** How and where is it deployed or consumed; feature flags; rollback; migration order? | n_a | Library consumed by later parts via import; no deploy, flags or migrations. Rollback = revert commit. | JOB request C4 |
| **DEL-docs** Documentation, changelog or runbook updates required? | n_a | No docs required beyond JSDoc-level comments matching surrounding code; no changelog exists. | repo files: CLAUDE.md, README.md only |
| **X-immutable-options** Should the exported *_OPTIONS arrays be frozen (Object.freeze) so consumers cannot mutate them? | decided | Frozen: export Object.freeze([...]) arrays; tests assert Object.isFrozen and exact order | pm: michael 2026-10-03 — Shared option lists are rendered by later POC screens; freezing prevents one consumer mutating another's dropdown at zero cost |
| **X-error-message** Exact RangeError message text. | decided | RangeError message includes the offending value (JSON.stringify/String) and the allowed list; tests assert only instanceof RangeError | pm: michael 2026-10-03 — Diagnosable for the later screen developers; tests stay robust by not pinning text |
| **X-trim-scope**  | decided | 'Trimmed' means String.prototype.trim (leading/trailing whitespace); inner whitespace is not normalised, so '>3  days' is a RangeError. | C1, C5 (exact match after trimming) |

## Architecture (frozen once the job is planned)

Style: library

| Component | Kind | Stack | Path | Owner (dev role) | Reviewer |
| --- | --- | --- | --- | --- | --- |
| indicators-lib | library | javascript, node-esm | `src/indicators/`, `test/indicators/` | backend | reviewer |
