MODE: READINESS
ROLE CARD (your rules — read first): /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/roles/ba.md
JOB REQUEST: read the requirements file /home/user/skills-shop/examples/watchlist-poc/JOB-models-plain.md (whole content is the request). Team instruction: the backend developer works on the sonnet model.
REPO: /tmp/claude-0/e2e-mC2/munder/repo   STACK: javascript (plain Node 18+ ESM, no deps, node --test)   ROLES: ba, backend-lead, backend (sonnet), qa, reviewer (ecc:typescript-reviewer)
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

Answer every item with a real source (quote the request section, e.g. "C2", or the repo file) or n_a with a reason. Include the architecture (one component: ratings module, path src/ratings + test/, owner backend).
WRITE YOUR ANSWER (the readiness JSON only) TO: /tmp/claude-0/e2e-mC2/munder/repo/.work/JOB-20261005-0700-rating-notch-change/out/readiness-ba.json — then report done.
