# Example job (snapshot mid-execution)

A real-looking `.work/<job>/` from a TypeScript/React shop app, caught at 12:32 while the job is in `executing`.

| File | What to look at |
| --- | --- |
| [`job.json`](JOB-20261001-1430-order-cancellation/job.json) | roles with reasons, the approved plan gate, the settings snapshot |
| [`plan.md`](JOB-20261001-1430-order-cancellation/plan.md) | testable ACs; scope and out-of-scope |
| [`board.json`](JOB-20261001-1430-order-cancellation/board.json) | 4 cards: T-01/T-02 merged, T-03 running, T-04 in review. T-02 needed 2 attempts |
| [`handoffs/T-02.md`](JOB-20261001-1430-order-cancellation/handoffs/T-02.md) | a dev handoff + both review verdicts |
| [`events.log`](JOB-20261001-1430-order-cancellation/events.log) | the whole timeline, including every agent run |

Dependency graph of this board:

```text
T-01 (service) ──► T-02 (endpoint) ──► T-03 (UI)
        └────────► T-04 (email)
```

T-02 and T-04 ran in parallel: both depend only on T-01, and their scopes don't overlap. T-03 had to wait for T-02's API contract.

Board as `dl status` prints it:

```text
ID    STATE    ROLE      AGENT         TRIES  DEPENDS  TITLE
T-01  merged   backend   backend-dev   1      -        Order status transition: cancel() in the order service
T-02  merged   backend   backend-dev   2      T-01     Cancel endpoint: POST /api/orders/:id/cancel
T-03  running  frontend  frontend-dev  1      T-02     Cancel button + confirm dialog on the order page
T-04  review   backend   backend-dev   1      T-01     Enqueue cancellation email

summary: merged=2  review=1  running=1
```

Next steps Michael would take: gate + review T-04, then wait for T-03. After that comes Phase 5: `verify-all` and `ecc:e2e-runner` on the order page.
