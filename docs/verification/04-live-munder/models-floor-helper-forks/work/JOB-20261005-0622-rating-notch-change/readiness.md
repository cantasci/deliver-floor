# Readiness — JOB-20261005-0622-rating-notch-change

27 item(s): 22 decided · 5 not applicable · 0 open

Sources: a requirement / file = from the request or the repo · `human:` = answered by the business · `pm:` = an implementation detail decided by Michael (the PM)

| Item | Status | Decision / reason | Source |
| --- | --- | --- | --- |
| **PRD-goal** What business outcome does this deliver, and how is success measured? | decided | Deliver the notch change calculator (REQ-06-02) that indicators 11, 12, and 13 depend on. Success is measured by correct computation of notch changes between rating pairs per the 19-step scale. | JOB-models-plain.md: Requirement section, Clarifications C1 |
| **PRD-users** Who uses it (roles/personas), and what may each role see or do? | decided | Internal API consumers (other functions/indicators within the POC). No end users; no UI, CLI, or printed output. | JOB-models-plain.md: Clarification C4 |
| **PRD-scope** What is explicitly in scope and out of scope for this delivery? | decided | In scope: notchChange(previous, current) function per REQ-06-02 and clarifications C1–C4. Out of scope: UI, CLI, printed output, banking regulation/policy constraints. | JOB-models-plain.md: Clarifications C2, C4 |
| **PRD-acceptance** Does every requirement have testable acceptance criteria with concrete examples? | decided | Yes. Requirement has testable acceptance criteria with concrete examples: BBB+ → BB+ = 3-notch downgrade; BB+ → BBB+ = 3-notch upgrade; A → A = 0. Clarifications C1–C4 provide complete specifications for input handling, error behavior, and output signing. | JOB-models-plain.md: Requirement section, Clarifications C1–C4 |
| **PRD-conflicts** Do any requirements, examples or clarifications contradict each other? How is each resolved? | n_a | No explicit conflict statement in the request; requirement, clarifications, and examples are internally consistent. | JOB-models-plain.md: Requirement, Clarifications, Contract |
| **PRD-priority** What is the priority order (MoSCoW) if not everything can ship together? | decided | Single requirement (REQ-06-02 part), single card. Must = implement notchChange function per spec. No prioritization needed; this slice is atomic. | JOB-models-plain.md: Opening |
| **CON-interface** Are all public interfaces fully specified — names, inputs, outputs, types, units, signs, ranges, null/empty handling? | decided | Fully specified. Function: notchChange(previous, current) → integer (signed). Inputs: string (rating). Output: notch change (downgrade positive, upgrade negative, unchanged 0). Rating scale: 19 steps best to worst (AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-). Input processing: trimmed and case-insensitive. | JOB-models-plain.md: Clarifications C1, C3; Contract |
| **CON-errors** What happens on invalid input and on failure (error types, codes, messages, fallbacks)? | decided | Invalid input rejected with RangeError. Invalid cases: unknown rating, empty string, non-string values (including String objects). Error type: RangeError. No fallback or recovery; rejection is the behavior. | JOB-models-plain.md: Clarification C2 |
| **CON-compat** Must existing behaviour, APIs or data stay backward compatible? Is there versioning? | decided | N/A. This is new code (one-card addition). No existing APIs or data modified. No backward compatibility concern. | JOB-models-plain.md: Opening |
| **ARC-style** Architecture style: monolith, modular monolith, microservices, library? Where does this change live? | decided | Library. Single JavaScript module (ESM) exporting a pure calculation function. No BFF, microservices, or separate deployment. Imported by other functions in the POC. | JOB-models-plain.md: Contract |
| **ARC-components** Every component (service, BFF, app, library, worker, database) with its stack, repo path and owning role — written to readiness.json → architecture. | n_a | Single library component; component role and stack are determined by the job's architecture (library, not a complex system needing component breakdown). | JOB-models-plain.md: Contract; CLAUDE.md |
| **ARC-layer** Which layer owns the logic: BFF/API gateway, core/domain service, shared library, client? | decided | Core/domain layer. Pure calculation function (no I/O, no side effects). | CLAUDE.md: Project conventions |
| **ARC-stack** Languages, frameworks and runtime versions — and are new dependencies allowed (licences)? | decided | Language: JavaScript (Node.js 18+ ESM, .mjs files). Test framework: node:test (built-in). Assert: node:assert/strict (built-in). No external dependencies. | CLAUDE.md; JOB-models-plain.md: Contract |
| **ARC-data** What data is stored, in which store, with which schema and migrations; who owns it? | decided | N/A. Pure function; no data storage, no database, no state. | CLAUDE.md |
| **ARC-integration** Which external systems are called — protocol, auth, rate limits, timeouts, retries, failure behaviour? | decided | N/A. No external systems called. Pure calculation function. | CLAUDE.md |
| **ARC-async** Synchronous or asynchronous (queues, events, jobs)? Ordering and idempotency requirements? | decided | Synchronous. Pure function; no queues, events, or async I/O. Idempotent by definition. | CLAUDE.md |
| **NFR-performance** Latency, throughput, data volume or load targets — or none for this delivery? | n_a | No performance targets stated in this slice. Pure in-memory lookup; not a bottleneck for the POC. | JOB-models-plain.md |
| **NFR-availability** Availability/resilience expectations, degradation when a dependency is down? | decided | N/A. No external dependencies; no failure modes except invalid input (which raises RangeError as specified). | CLAUDE.md |
| **NFR-security** Authentication, authorisation, input validation, secrets handling — what applies here? | decided | Input validation: trim and case-normalize ratings; reject unknown ratings, empty strings, and non-strings with RangeError. No authentication, secrets, or sensitive data. | JOB-models-plain.md: Clarifications C1, C2 |
| **NFR-privacy** Personal or sensitive data involved (KVKK/GDPR)? Retention, masking, logging rules? | n_a | No personal or sensitive data. Pure calculation on rating codes. | JOB-models-plain.md: Clarification C4 |
| **NFR-audit** Must actions or changes be audited (who, what, when), and for how long? | decided | N/A. Pure function; no state changes or side effects to audit. | CLAUDE.md |
| **NFR-observability** Logging, metrics, tracing and alerting required for this change? | decided | N/A. Pure function; no logging, metrics, or tracing required. Function is deterministic and testable. | CLAUDE.md |
| **NFR-compliance** Domain regulations or internal policies that constrain the solution (e.g. banking regulation, model risk)? | decided | N/A. Explicitly excluded by requirement. No banking regulation or internal policy applies to this slice. | JOB-models-plain.md: Clarification C2 |
| **TST-strategy** Test expectations: unit (dev, TDD), integration/e2e (QA), coverage, test data, test environments? | decided | Unit tests with node:test framework. Dev-driven TDD (developers write tests). Test file: test/ratings/notch.test.mjs. Coverage should include: all 19 ratings as both previous and current, boundaries (AAA, CCC-), invalid inputs (empty string, non-string, unknown rating), unchanged case (A → A). | CLAUDE.md; README.md |
| **DEL-ci** Which checks must pass to merge (lint, typecheck, tests, security scans)? | decided | Passing tests via npm test (= node --test). No lint, typecheck, or security scans specified for this POC. | README.md; CLAUDE.md |
| **DEL-deploy** How and where is it deployed or consumed; feature flags; rollback; migration order? | decided | No deployment/rollout. Library function imported by other POC code. Single card, single requirement; integrated into the codebase when tests pass. | JOB-models-plain.md: Clarification C4 |
| **DEL-docs** Documentation, changelog or runbook updates required? | n_a | No documentation deliverable required. Function is imported internally; JSDoc is a dev convention, not a docs card. | JOB-models-plain.md: Contract section |

## Architecture (frozen once the job is planned)

Style: library

| Component | Kind | Stack | Path | Owner (dev role) | Reviewer |
| --- | --- | --- | --- | --- | --- |
| notch-change | library | javascript, node-18+, esm | `src/ratings/`, `test/ratings/`, `test/integration/ratings/` | backend | reviewer |
