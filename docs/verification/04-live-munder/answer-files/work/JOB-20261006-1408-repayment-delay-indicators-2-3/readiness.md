# Readiness — JOB-20261006-1408-repayment-delay-indicators-2-3

32 item(s): 20 decided · 12 not applicable · 0 open

Sources: a requirement / file = from the request or the repo · `human:` = answered by the business · `pm:` = an implementation detail decided by Michael (the PM)

| Item | Status | Decision / reason | Source |
| --- | --- | --- | --- |
| **PRD-goal** What business outcome does this deliver, and how is success measured? | decided | Provide the mapping of the Indicator 2 (days with delay) and Indicator 3 (delays in 12 months) dropdown options to Watchlist levels (WL). Success = the contract functions return the specified WL for every option and RangeError otherwise, verified by node --test. | request |
| **PRD-users** Who uses it (roles/personas), and what may each role see or do? | n_a | No end users/roles in this slice; consumers are later POC screens/code calling the exported functions. No role-based access applies. | request C4: no UI |
| **PRD-scope** What is explicitly in scope and out of scope for this delivery? | decided | In: REQ-03-02 and REQ-03-03 (option lists + WL mapping functions). Out: Indicator 1 and its collapsing of indicators 2-3, any UI, counting delays. | request |
| **PRD-acceptance** Does every requirement have testable acceptance criteria with concrete examples? | decided | Yes: AC summaries plus C1/C2/C5 give every option's exact WL and the invalid-input rule; BA derives Given/When/Then in PLAN. | request |
| **PRD-conflicts** Do any requirements, examples or clarifications contradict each other? How is each resolved? | decided | Only apparent difference: the POC writes '≤3 days' while C1 fixes the string as '<=3 days'. Resolved by C1 (the clarification confirmed by the business unit wins); no other contradictions found. | request |
| **PRD-priority** What is the priority order (MoSCoW) if not everything can ship together? | decided | Both Must; delivered together on parallel cards | pm: michael 2026-10-06 — The request says the two requirements are independent and staffs one developer per requirement in parallel; no ordering is needed. |
| **CON-interface** Are all public interfaces fully specified — names, inputs, outputs, types, units, signs, ranges, null/empty handling? | decided | daysWithDelay.mjs: DAYS_WITH_DELAY_OPTIONS (5 strings in order: 'no delay','<=3 days','>3 days','>60 days','>90 days') and daysWithDelayWl(option)→0|2|3|4. delayCount.mjs: DELAY_COUNT_OPTIONS ('0','1','>1') and delayCountWl(option)→0|1|2. Mapping: no delay/<=3 days→0, >3→2, >60→3, >90→4; '0'→0, '1'→1, '>1'→2. Input trimmed with String.prototype.trim(), exact case-sensitive match, inner whitespace untouched. | request |
| **CON-errors** What happens on invalid input and on failure (error types, codes, messages, fallbacks)? | decided | Any value not in the list after trim (wrong case, inner-space change, empty string, null/undefined, number, other non-string) throws RangeError. | request |
| **X-errors-msg** Is the RangeError message text part of the contract (and are the functions allowed to expose the offending value in it)? | decided | Message text is not contract: tests assert the RangeError type only; message should name the indicator and the valid options and may include String(value) | pm: michael 2026-10-06 — The request fixes only the error type (C1/C5 'throws a RangeError'); pinning text would over-constrain tests. A descriptive message helps callers; the value is a dropdown label, not sensitive data. |
| **CON-compat** Must existing behaviour, APIs or data stay backward compatible? Is there versioning? | decided | Greenfield: src/ and test/ only contain .gitkeep; nothing to stay compatible with, no versioning. | repo: git ls-files (src/.gitkeep, test/.gitkeep) |
| **ARC-style** Architecture style: monolith, modular monolith, microservices, library? Where does this change live? | decided | Library of pure functions: two modules under src/indicators/ of the existing repo, as named by the request's contract. | request, Contract |
| **ARC-components** Every component (service, BFF, app, library, worker, database) with its stack, repo path and owning role — written to readiness.json → architecture. | decided | One component: indicators-lib (library, node ESM) in src/indicators/ + test/indicators/, owned by backend, reviewed by reviewer-typescript. See architecture. | request, Contract |
| **ARC-ui** Is there a user interface — none, web, desktop or mobile app? Who uses it, and with which stack? | decided | No UI: the dropdown is met by the exported option lists only. | request, C4 |
| **ARC-layer** Which layer owns the logic: BFF/API gateway or other middleware, core/domain service, shared library, client? Is there an API, and for whom? | decided | Shared domain library functions called by later POC screens; no API/BFF/client in this slice. | request, C4 and C6 |
| **ARC-stack** Languages, frameworks and runtime versions From the repo's code or the request (quoted). A repo without code and a request that names no language → the best fit for the requirements, never a default: open, owner pm, with the evidence the request gives (the libraries, tools, platforms and data sources it names) and the alternatives — Michael decides it with that evidence quoted. | decided | Plain Node ESM (.mjs), tests with node --test; Node 18+ per repo. | request, Contract |
| **ARC-deps** May the delivery add new dependencies or libraries (which, under which licences), or must it stay on what the repo already uses? | decided | No new dependencies. | request, Contract |
| **ARC-data** Is there a database or other store? What data is stored, in which store, with which schema and migrations; who owns it? | n_a | No database or store; pure in-memory mapping. | request, C6 + Contract |
| **ARC-integration** Which external systems are called — protocol, auth, rate limits, timeouts, retries, failure behaviour? | n_a | No external systems. | request, C6 + Contract |
| **ARC-async** Synchronous or asynchronous (queues, events, jobs)? Ordering and idempotency requirements? | n_a | Synchronous pure functions; no queues/events. | repo CLAUDE.md |
| **NFR-performance** Latency, throughput, data volume or load targets — or none for this delivery? | n_a | None stated; constant-time lookup of a 3-5 element list. | request |
| **NFR-availability** Availability/resilience expectations, degradation when a dependency is down? | n_a | Not applicable to a pure in-process function. | request |
| **NFR-security** Authentication, authorisation, input validation, secrets handling — what applies here? | n_a | Only input validation applies (strict RangeError on invalid input); no auth/secrets. | request |
| **NFR-privacy** Personal or sensitive data involved (KVKK/GDPR)? Retention, masking, logging rules? | n_a | No personal data handled; functions take only an option string. | request |
| **NFR-audit** Must actions or changes be audited (who, what, when), and for how long? | n_a | No auditing in this slice. | request |
| **NFR-observability** Logging, metrics, tracing and alerting required for this change? | n_a | No logging/metrics; repo rule forbids I/O in src/indicators. | repo CLAUDE.md |
| **NFR-compliance** Domain regulations or internal policies that constrain the solution (e.g. banking regulation, model risk)? | n_a | No regulation stated for this slice. | request |
| **TST-strategy** Test expectations: unit (dev, TDD), integration/e2e (QA), coverage, test data, test environments? | decided | Unit tests by backend devs per requirement, node:test + node:assert/strict, files test/indicators/<name>.test.mjs; QA writes integration/boundary tests (every option, trim variants, case, NBSP, inner double space, non-strings). | repo CLAUDE.md |
| **DEL-ci** Which checks must pass to merge (lint, typecheck, tests, security scans)? | decided | Only `node --test` (npm test); no lint/typecheck configured. | repo package.json / CLAUDE.md |
| **DEL-deploy** How and where is it deployed or consumed; feature flags; rollback; migration order? | decided | Merged into the repo as a library module; no deployment, flags or migrations. | request |
| **DEL-docs** Documentation, changelog or runbook updates required? | n_a | No README/changelog/runbook update: the request asks only for the two modules and their tests (PM decision). | pm: request names no documentation |
| **X-immutable-options** Should the exported *_OPTIONS arrays be frozen/immutable so consumers cannot mutate them? | decided | Export the *_OPTIONS arrays frozen (Object.freeze), exact strings in the request's order | pm: michael 2026-10-06 — C4: later screens render these shared lists; freezing prevents a consumer mutating the list every other module sees, and still satisfies 'the N strings, in order'. |
| **X-ind2-semantics** Options '>3 days', '>60 days', '>90 days' overlap as ranges; the caller picks exactly one. Confirm each option maps only by its own label (no range logic in this slice). | decided | Label-only lookup: each option maps by its exact (trimmed) label; no numeric range logic | pm: michael 2026-10-06 — C6: the caller picks the option; this slice only maps the option to a WL. C2/AC table give each label's WL. |

## Architecture (frozen once the job is planned)

Style: library

| Component | Kind | Stack | Path | Owner (dev role) | Reviewer |
| --- | --- | --- | --- | --- | --- |
| indicators-lib | library | node, esm | `src/indicators/`, `test/indicators/`, `test/integration/indicators/` | backend | reviewer |
