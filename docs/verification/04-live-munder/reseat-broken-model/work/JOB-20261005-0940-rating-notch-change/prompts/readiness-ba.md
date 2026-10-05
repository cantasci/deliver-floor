MODE: READINESS
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/roles/ba.md
JOB REQUEST (from /home/user/skills-shop/examples/watchlist-poc/JOB-models-plain.md):
Rating notch change (Watchlist POC — one task)

Source: POC_Requirements_v0.2_EN.md (Corporate Client Credit Monitoring — Watchlist Tool).
This job is a one-requirement slice of that document: the notch change that Indicators 11, 12 and 13 and the notch
calculator (REQ-06-02) are built on. It is small: one card.

## Requirement

| Req ID | Requirement | Acceptance Criteria (summary) |
|---|---|---|
| REQ-06-02 (part) | Given a previous and a current rating, the system computes the notch change between them | BBB+ → BB+ = 3-notch downgrade; BB+ → BBB+ = 3-notch upgrade; A → A = 0 |

## Clarifications for this slice (confirmed by the business unit)

- C1. Rating scale, best to worst (19 steps): AAA, AA+, AA, AA-, A+, A, A-, BBB+, BBB, BBB-, BB+, BB, BB-, B+, B, B-, CCC+, CCC, CCC-.
  A notch is one step on this scale. Input is trimmed with `String.prototype.trim()` and case-insensitive ("bbb+" = "BBB+").
- C2. Every invalid input (an unknown rating, an empty string, a non-string) is rejected with a RangeError. A String object
  such as `new String('A')` is a non-string. No banking-regulation or internal-policy constraint applies to this slice.
- C3. The result is signed: downgrade positive, upgrade negative, unchanged 0.
- C4. No UI, CLI or printed output; other parts of the POC import the function.

## Contract

- `src/ratings/notch.mjs`
  - `RATING_SCALE` — the 19 ratings of C1, best first.
  - `notchChange(previous, current)` → integer (C3).

Plain Node ESM, no dependencies; tests with `node --test` next to the code under `test/`.

REPO: /tmp/claude-0/e2e-fR2/munder/repo   STACK: javascript   ROLES: ba, backend-lead, backend, qa, reviewer (ecc:typescript-reviewer)
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

OUTPUT: write the readiness JSON (the format your role card specifies, including architecture) to /tmp/claude-0/e2e-fR2/munder/repo/.work/JOB-20261005-0940-rating-notch-change/out/readiness-ba.json, then report done.
