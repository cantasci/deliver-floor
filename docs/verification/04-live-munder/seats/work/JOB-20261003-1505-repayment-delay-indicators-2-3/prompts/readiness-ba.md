MODE: READINESS
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/roles/ba.md
JOB REQUEST (file: /home/user/skills-shop/examples/watchlist-poc/JOB-parallel.md):
Repayment delay indicators 2 and 3 (Watchlist POC slice, parallel)

Source: POC_Requirements_v0.2_EN.md (Corporate Client Credit Monitoring — Watchlist Tool), EPIC-03.
Build only these two requirements. They are independent of each other.

Staffing: two backend developers work in parallel, one per requirement.

## Requirements (verbatim from the POC)

| Req ID | Requirement | Acceptance Criteria (summary) |
|---|---|---|
| REQ-03-02 | Indicator 2 (Days with delay): Dropdown → no delay / ≤3 days / >3 days / >60 days / >90 days | >3 days → WL=2; >60 days → WL=3; >90 days → WL=4 |
| REQ-03-03 | Indicator 3 (Delays in 12 months): Dropdown → 0 / 1 / >1 | 1 → WL=1; >1 → WL=2 |

## Clarifications for this slice (confirmed by the business unit)

- C1. Dropdown values are exactly these strings: Indicator 2: "no delay", "<=3 days", ">3 days", ">60 days", ">90 days";
  Indicator 3: "0", "1", ">1". Input is trimmed; any other value throws a RangeError.
- C2. "no delay" and "<=3 days" → WL 0; Indicator 3 "0" → WL 0.
- C3. Indicator 1 (repayment delay yes/no) and its collapsing of indicators 2–3 are OUT of scope here.
- C4. "Dropdown" is met by the exported option lists (`*_OPTIONS`) that the POC screens, built later by other parts, render.
  No UI in this slice.
- C5. Matching is exact and case-sensitive after trimming (">3 days" yes, ">3 Days" no → RangeError); a non-string input is a RangeError too.
- C6. The caller counts the delays in the last 12 months and picks the option; this slice only maps the option to a WL.

## Contract

- `src/indicators/daysWithDelay.mjs` → `export const DAYS_WITH_DELAY_OPTIONS` (the 5 strings, in order) and `export function daysWithDelayWl(option)` → 0 | 2 | 3 | 4
- `src/indicators/delayCount.mjs` → `export const DELAY_COUNT_OPTIONS` (the 3 strings, in order) and `export function delayCountWl(option)` → 0 | 1 | 2

Plain Node ESM, no dependencies; tests with `node --test`.
REPO: /tmp/claude-0/e2e-seats/munder/repo   STACK: javascript (plain Node ESM, node --test)   ROLES: ba, backend-lead, backend x2, qa, reviewer (ecc:typescript-reviewer)
READINESS ITEMS (answer every one):
[
  {
    "id": "PRD-goal",
    "area": "always",
    "q": "What business outcome does this deliver, and how is success measured?"
  },
  {
    "id": "PRD-users",
    "area": "always",
    "q": "Who uses it (roles/personas), and what may each role see or do?"
  },
  {
    "id": "PRD-scope",
    "area": "always",
    "q": "What is explicitly in scope and out of scope for this delivery?"
  },
  {
    "id": "PRD-acceptance",
    "area": "always",
    "q": "Does every requirement have testable acceptance criteria with concrete examples?"
  },
  {
    "id": "PRD-conflicts",
    "area": "always",
    "q": "Do any requirements, examples or clarifications contradict each other? How is each resolved?"
  },
  {
    "id": "PRD-priority",
    "area": "always",
    "q": "What is the priority order (MoSCoW) if not everything can ship together?"
  },
  {
    "id": "CON-interface",
    "area": "always",
    "q": "Are all public interfaces fully specified — names, inputs, outputs, types, units, signs, ranges, null/empty handling?"
  },
  {
    "id": "CON-errors",
    "area": "always",
    "q": "What happens on invalid input and on failure (error types, codes, messages, fallbacks)?"
  },
  {
    "id": "CON-compat",
    "area": "always",
    "q": "Must existing behaviour, APIs or data stay backward compatible? Is there versioning?"
  },
  {
    "id": "ARC-style",
    "area": "always",
    "q": "Architecture style: monolith, modular monolith, microservices, library? Where does this change live?"
  },
  {
    "id": "ARC-components",
    "area": "always",
    "q": "Every component (service, BFF, app, library, worker, database) with its stack, repo path and owning role — written to readiness.json → architecture."
  },
  {
    "id": "ARC-layer",
    "area": "backend",
    "q": "Which layer owns the logic: BFF/API gateway, core/domain service, shared library, client?"
  },
  {
    "id": "ARC-stack",
    "area": "always",
    "q": "Languages, frameworks and runtime versions — and are new dependencies allowed (licences)?"
  },
  {
    "id": "ARC-data",
    "area": "data",
    "q": "What data is stored, in which store, with which schema and migrations; who owns it?"
  },
  {
    "id": "ARC-integration",
    "area": "integration",
    "q": "Which external systems are called — protocol, auth, rate limits, timeouts, retries, failure behaviour?"
  },
  {
    "id": "ARC-async",
    "area": "backend",
    "q": "Synchronous or asynchronous (queues, events, jobs)? Ordering and idempotency requirements?"
  },
  {
    "id": "NFR-performance",
    "area": "always",
    "q": "Latency, throughput, data volume or load targets — or none for this delivery?"
  },
  {
    "id": "NFR-availability",
    "area": "backend",
    "q": "Availability/resilience expectations, degradation when a dependency is down?"
  },
  {
    "id": "NFR-security",
    "area": "always",
    "q": "Authentication, authorisation, input validation, secrets handling — what applies here?"
  },
  {
    "id": "NFR-privacy",
    "area": "always",
    "q": "Personal or sensitive data involved (KVKK/GDPR)? Retention, masking, logging rules?"
  },
  {
    "id": "NFR-audit",
    "area": "always",
    "q": "Must actions or changes be audited (who, what, when), and for how long?"
  },
  {
    "id": "NFR-observability",
    "area": "backend",
    "q": "Logging, metrics, tracing and alerting required for this change?"
  },
  {
    "id": "NFR-compliance",
    "area": "always",
    "q": "Domain regulations or internal policies that constrain the solution (e.g. banking regulation, model risk)?"
  },
  {
    "id": "TST-strategy",
    "area": "always",
    "q": "Test expectations: unit (dev, TDD), integration/e2e (QA), coverage, test data, test environments?"
  },
  {
    "id": "DEL-ci",
    "area": "always",
    "q": "Which checks must pass to merge (lint, typecheck, tests, security scans)?"
  },
  {
    "id": "DEL-deploy",
    "area": "always",
    "q": "How and where is it deployed or consumed; feature flags; rollback; migration order?"
  },
  {
    "id": "DEL-docs",
    "area": "always",
    "q": "Documentation, changelog or runbook updates required?"
  }
]

WRITE your answer (the readiness JSON only) to: /tmp/claude-0/e2e-seats/munder/repo/.work/JOB-20261003-1505-repayment-delay-indicators-2-3/out/readiness-ba.json
Then report "done readiness <your seat>" to Michael.
