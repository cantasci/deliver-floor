# Readiness — JOB-20261004-1255-rating-notch-calculator-and-coun

31 item(s): 23 decided · 8 not applicable · 0 open

Sources: a requirement / file = from the request or the repo · `human:` = answered by the business · `pm:` = an implementation detail decided by Michael (the PM)

| Item | Status | Decision / reason | Source |
| --- | --- | --- | --- |
| **PRD-goal** What business outcome does this deliver, and how is success measured? | decided | Two pure importable domain functions: a notch calculator (signed notch change, direction, WL per Indicator 13 thresholds, REQ-06-02/C2) and the Indicator 12 country rating change WL (REQ-03-12). Success = contract exists exactly as named and examples hold: BBB+ -> BB+ = 3 notches -> WL 2; BBB+ -> BBB- = 2 notches -> WL 1; Ind. 12: 1 notch -> WL 1, 2+ -> WL 2, upgrade/unchanged -> 0. | JOB.md REQ-06-02, REQ-03-12, C2, Contract |
| **PRD-users** Who uses it (roles/personas), and what may each role see or do? | decided | Credit analyst via POC screens built later (C8); direct consumers are other POC parts importing the contract. No roles/permissions: pure functions. | JOB.md REQ-06-02, C8, Contract |
| **PRD-scope** What is explicitly in scope and out of scope for this delivery? | decided | IN: src/ratings/notch.mjs (RATING_SCALE, notchChange, notchCalculator), src/indicators/countryRating.mjs (countryRatingChangeWl), their tests. OUT: public-source fetch (C4), override/persistence/audit (C7), UI/CLI/printed output (C8), Indicator 13 as own function, every other REQ. | JOB.md intro, C4, C7, C8, Contract |
| **PRD-acceptance** Does every requirement have testable acceptance criteria with concrete examples? | decided | Yes: BBB+ -> BB+ = 3 notches WL 2; BBB+ -> BBB- = 2 notches WL 1 (C2); 1-notch downgrade calculator WL 0 (C6) but Ind. 12 WL 1; upgrade/unchanged WL 0 (C3); notches signed like notchChange (C5); invalid input RangeError (C1). | JOB.md REQ-03-12, C1, C2, C3, C5, C6, C7 |
| **PRD-conflicts** Do any requirements, examples or clarifications contradict each other? How is each resolved? | decided | POC example BBB+ -> BB+ (2 notches, WL 1) is corrected by C2 to 3 notches, WL 2. Calculator uses Ind. 13 thresholds, Ind. 12 uses its own (C6). Pre-fill from public source is out of scope (C4); editable met by contract (C7); displayed met by return value (C8). | JOB.md C2, C4, C6, C7, C8 |
| **PRD-priority** What is the priority order (MoSCoW) if not everything can ship together? | decided | Both Must, ship together. Order: notch.mjs first, then countryRatingChangeWl (built on notchChange). | JOB.md intro, Contract |
| **CON-interface** Are all public interfaces fully specified — names, inputs, outputs, types, units, signs, ranges, null/empty handling? | decided | RATING_SCALE: 19 ratings best first. notchChange(previous,current) = index(current) - index(previous) (positive downgrade, negative upgrade, range -18..18). notchCalculator -> { notches (same sign as notchChange), direction, wl }: downgrade 2 -> 1, 3+ -> 2, 1 -> 0, upgrade/unchanged -> 0. countryRatingChangeWl -> 0|1|2: downgrade 1 -> 1, 2+ -> 2, else 0. Synchronous, string inputs, case-insensitive. | JOB.md Contract, C1, C5 |
| **CON-errors** What happens on invalid input and on failure (error types, codes, messages, fallbacks)? | decided | Anything that is not one of the 19 ratings after trimming and case-folding (including null, undefined, numbers, empty string, unknown ratings) throws RangeError, from all three functions. Must be RangeError, not TypeError. No fallback value. Message text not in contract. | JOB.md C1 |
| **CON-compat** Must existing behaviour, APIs or data stay backward compatible? Is there versioning? | n_a | Nothing exists yet (only .gitkeep files); all modules and exports are new. | repo: src/.gitkeep, test/.gitkeep; package.json |
| **ARC-style** Architecture style: monolith, modular monolith, microservices, library? Where does this change live? | decided | Library: plain Node ES modules in the single watchlist-poc package, in src/ratings/ and src/indicators/, tests under test/. | JOB.md Contract; CLAUDE.md |
| **ARC-components** Every component (service, BFF, app, library, worker, database) with its stack, repo path and owning role — written to readiness.json → architecture. | decided | One component: watchlist-ratings (library, javascript/node; src/ratings/, src/indicators/, test/), owner backend, reviewer reviewer. | JOB.md Contract; CLAUDE.md |
| **ARC-layer** Which layer owns the logic: BFF/API gateway, core/domain service, shared library, client? | decided | Shared domain library of pure functions; screens/indicator engine built later by other parts. | CLAUDE.md; JOB.md C8 |
| **ARC-stack** Languages, frameworks and runtime versions — and are new dependencies allowed (licences)? | decided | JavaScript, Node 18+, ESM (.mjs), no framework, no dependencies. node:test + node:assert/strict. | CLAUDE.md |
| **ARC-data** What data is stored, in which store, with which schema and migrations; who owns it? | n_a | No data stored; C7 excludes persistence and the scale is a constant. | JOB.md C7; CLAUDE.md |
| **ARC-integration** Which external systems are called — protocol, auth, rate limits, timeouts, retries, failure behaviour? | n_a | No external system: public-source fetching is out of scope (C4). | JOB.md C4 |
| **ARC-async** Synchronous or asynchronous (queues, events, jobs)? Ordering and idempotency requirements? | decided | Synchronous; functions return values directly, not Promises. | CLAUDE.md; JOB.md Contract |
| **NFR-performance** Latency, throughput, data volume or load targets — or none for this delivery? | n_a | No performance target in the request; lookup in a 19-item constant. | JOB.md (no performance requirement); CLAUDE.md |
| **NFR-availability** Availability/resilience expectations, degradation when a dependency is down? | n_a | In-process library without I/O or dependencies. | JOB.md C4; CLAUDE.md |
| **NFR-security** Authentication, authorisation, input validation, secrets handling — what applies here? | decided | No auth or secrets; input validation per C1 is the only concern: unknown input throws RangeError. | JOB.md C1 |
| **NFR-privacy** Personal or sensitive data involved (KVKK/GDPR)? Retention, masking, logging rules? | n_a | Only rating symbols are processed; nothing stored or logged. | JOB.md C1, C7, C8 |
| **NFR-audit** Must actions or changes be audited (who, what, when), and for how long? | decided | No audit in this slice. | JOB.md C7 |
| **NFR-observability** Logging, metrics, tracing and alerting required for this change? | decided | None: no logging, metrics or printed output. | JOB.md C8 |
| **NFR-compliance** Domain regulations or internal policies that constrain the solution (e.g. banking regulation, model risk)? | n_a | POC; no regulation named; business rules confirmed in C1-C8. | README.md; JOB.md Clarifications |
| **TST-strategy** Test expectations: unit (dev, TDD), integration/e2e (QA), coverage, test data, test environments? | decided | Dev unit tests in test/ratings/notch.test.mjs and test/indicators/countryRating.test.mjs; QA integration tests under test/integration/**. Data from C1-C6 plus edges (AAA/CCC- ends, 18-notch move, invalid/non-string input). | CLAUDE.md |
| **DEL-ci** Which checks must pass to merge (lint, typecheck, tests, security scans)? | decided | `node --test` full suite must pass; no lint tooling, no dependencies. | .deliver.json |
| **DEL-deploy** How and where is it deployed or consumed; feature flags; rollback; migration order? | decided | Nothing deployed; consumed by import; rollback = revert merge. | JOB.md Contract |
| **DEL-docs** Documentation, changelog or runbook updates required? | n_a | No docs requested; JOB.md contract describes the interface, README describes layout. | JOB.md Contract; README.md |
| **X-trim** C1 says input is trimmed but not which characters are stripped. Which whitespace must be removed from both ends before matching? | decided | Trimmed means String.prototype.trim(): leading and trailing whitespace of any kind (spaces, tabs, newlines, Unicode spaces such as NBSP) is removed; whitespace inside the value is not changed. | human: e2e-human 2026-10-04 |
| **X-scale-immutability** Should the exported RATING_SCALE be frozen? | decided | Frozen array (Object.freeze) | pm: michael 2026-10-04 — Prevents importers from corrupting the scale notchChange relies on; no contract change |
| **X-error-message** Should the RangeError message name the argument and the offending value? | decided | Message names the argument and offending value; tests assert RangeError type only | pm: michael 2026-10-04 — Better diagnosability, not part of the contract |
| **X-coverage** Is there a numeric coverage target? | decided | No numeric target; every AC and edge case has a test | pm: michael 2026-10-04 — POC; request sets no coverage number |

## Architecture (frozen once the job is planned)

Style: library

| Component | Kind | Stack | Path | Owner (dev role) | Reviewer |
| --- | --- | --- | --- | --- | --- |
| watchlist-ratings | library | javascript, node | `src/ratings/`, `src/indicators/`, `test/` | backend | reviewer |
