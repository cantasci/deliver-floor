# Live E2E — scenario `munder` (Munder Difflin office floor)

Request: `examples/watchlist-poc/$JOBF` · started 2026-10-03T10:40:46Z

## 1 · setup: scripts/init.sh --munder in a fresh HOME

- ✅ init: result: 24 ok, 6 warning(s), 0 problem(s)
- ✅ repo set to dispatch=munder (devs are floor workers)
- ✅ Michael briefed in the hive (CLAUDE.md, AGENTS.md, GEMINI.md)
- ✅ credential bridge for the floor's terminals: bin/claude (container auth via CLAUDE_* variables)
- ✅ Munder Difflin: Michael runs 'claude' on claude-opus-5-5, workers default to claude-sonnet-5-5

## 2 · the floor: open the app, brief Michael with one message, watch

- ✅ the job finished on the floor
- ✅ screenshots of the floor: 19 (shots/)

## 3 · floor-specific checks

- ✅ 2 card(s) were built by floor workers (md_workers on the cards)
- ✅ Munder Difflin consumed 2 spawn request(s) (spawn-requests/.done)
    worker: worker-dl-20261003-1042-T-01-backend-a1 — T-01 backend
    worker: worker-dl-20261003-1042-T-02-backend-a1 — T-02 backend

## 4 · verify the delivered job

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, qa, backend-lead, backend×2, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ a role card for every role
- ✅ readiness review complete (no open item) with an architecture
readiness: 34 items — 23 decided (0 by the human, 6 by the PM), 11 n/a
architecture: library: indicators-lib [javascript+node-esm] → backend/reviewer
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 REQ-03-02 Indicator 2 'Days with delay': DAYS_WITH_DELAY_OPTIONS + daysWithDelayWl | indicators-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
| T-02 REQ-03-03 Indicator 3 'Delays in 12 months': DELAY_COUNT_OPTIONS + delayCountWl | indicators-lib | backend#2 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
- ✅ every card (2): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration/e2e tests are on main (2 file(s) in the cards' qa_scope)
- ✅ role really ran: business-analyst
- ✅ role really ran: ecc:architect
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev role
- ✅ role really ran: reviewer(s)
- ✅ no tracker errors
- ✅ kanban view rendered
- ✅ report.md written by the closing check
- ✅ no AI attribution in the delivered history (8 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (2 checks, parallel.oracle.test.mjs)

**PASSED**
