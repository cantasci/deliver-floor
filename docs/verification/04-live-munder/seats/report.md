# Live E2E — scenario `munder` (Munder Difflin office floor)

Request: `examples/watchlist-poc/$JOBF` · started 2026-10-03T15:04:28Z

## 1 · setup: scripts/init.sh --munder in a fresh HOME

- ✅ init: result: 25 ok, 6 warning(s), 0 problem(s)
- ✅ repo set to dispatch=munder (devs are floor workers)
- ✅ Michael briefed in the hive (CLAUDE.md, AGENTS.md, GEMINI.md)
- ✅ credential bridge for the floor's terminals: bin/claude (container auth via CLAUDE_* variables)
- ✅ Munder Difflin: Michael runs 'claude' on claude-opus-5-5, workers default to claude-sonnet-5-5

## 2 · the floor: open the app, brief Michael with one message, watch

- ✅ the job finished on the floor
- ✅ screenshots of the floor: 29 (shots/)

## 3 · floor-specific checks

- ✅ 4 card(s) were built by floor workers (md_workers on the cards)
- ✅ Munder Difflin consumed 6 spawn request(s) (spawn-requests/.done)
    worker: worker-seat-20261003-1505-ba-1-h1 — ba
    worker: worker-seat-20261003-1505-backend-lead-1-h1 — backend-lead
    worker: worker-seat-20261003-1505-backend-1-h1 — backend 1
    worker: worker-seat-20261003-1505-backend-2-h1 — backend 2
    worker: worker-seat-20261003-1505-qa-1-h1 — qa
    worker: worker-seat-20261003-1505-reviewer-1-h1 — reviewer
- ✅ a seat was hired for every role seat the requirements called for: ba#1 backend#1 backend#2 backend-lead#1 qa#1 reviewer#1 
- ✅ ba#1 (ba) did: readiness plan spec-all closing 
- ✅ backend#1 (backend 1) did: T-01 T-03 T-01 T-04 
- ✅ backend#2 (backend 2) did: T-02 
- ✅ backend-lead#1 (backend-lead) did: cards-backend-lead 
- ✅ qa#1 (qa) did: T-02 T-01 T-03 T-01 T-04 
- ✅ reviewer#1 (reviewer) did: T-02 T-01 T-03 T-01 T-04 
- ✅ Michael ran no subagent: every role's work went to its seat (md-send → md-done)

## 4 · verify the delivered job

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend×2, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ a role card for every role
- ✅ readiness review complete (no open item) with an architecture
readiness: 30 items — 17 decided (0 by the human, 2 by the PM), 13 n/a
architecture: library: indicators-lib [javascript+node-esm] → backend/reviewer
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 4 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Indicator 2: days with delay options and WL mapping (REQ-03-02) | indicators-lib | backend#1 | 2 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
| T-02 Indicator 3: delays in 12 months options and WL mapping (REQ-03-03) | indicators-lib | backend#2 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
| T-03 Ind.3 delayCountWl: RangeError (not TypeError) for BigInt/circular input (C5) | indicators-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
| T-04 Merged-branch AC-10 check: QA tests assert per-card files without pinning the whole diff | indicators-lib | backend#1 | 2 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
- ✅ every card (4): assigned by Michael → dev → gate PASS → QA pass → review approve (same commit) → merged
- ✅ QA's integration/e2e tests are on main (5 file(s) in the cards' qa_scope)
- ✅ role really ran: business-analyst
- ✅ role really ran: ecc:architect
- ✅ role really ran: qa-tester
- ✅ role really ran: a dev role
- ✅ role really ran: reviewer(s)
- ✅ no tracker errors
- ✅ kanban view rendered
- ✅ report.md written by the closing check
- ✅ no AI attribution in the delivered history (16 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (2 checks, parallel.oracle.test.mjs)

**PASSED**
