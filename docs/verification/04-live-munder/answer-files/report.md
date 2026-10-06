# Live E2E — scenario `munder` (Munder Difflin office floor)

Request: `examples/watchlist-poc/$JOBF` · started 2026-10-06T14:05:01Z

## 1 · setup: scripts/init.sh --munder in a fresh HOME

- ✅ init: result: 30 ok, 7 warning(s), 0 problem(s)
- ✅ repo set to dispatch=munder (devs are floor workers)
- ✅ Michael briefed in the hive (CLAUDE.md, AGENTS.md, GEMINI.md)
- ✅ credential bridge for the floor's terminals: bin/claude (container auth via CLAUDE_* variables)
- ✅ Munder Difflin: Michael runs 'claude' on claude-opus-5-5, workers default to claude-sonnet-5-5

## 2 · the floor: open the app, brief Michael with one message, watch

- ✅ the job finished on the floor
- ✅ screenshots of the floor: 53 (shots/)

## 3 · floor-specific checks

- ✅ 2 card(s) were built by floor workers (md_workers on the cards)
- ✅ Munder Difflin consumed 7 spawn request(s) (spawn-requests/.done)
    worker: worker-seat-20261006-1408-ba-1-h1 — ba
    worker: worker-seat-20261006-1408-backend-1-h1 — backend 1
    worker: worker-seat-20261006-1408-backend-2-h1 — backend 2
    worker: worker-seat-20261006-1408-backend-lead-1-h1 — backend-lead
    worker: worker-seat-20261006-1408-qa-1-h1 — qa 1
    worker: worker-seat-20261006-1408-qa-2-h1 — qa 2
    worker: worker-seat-20261006-1408-reviewer-1-h1 — reviewer
- ✅ a seat was hired for every role seat the requirements called for: ba#1 backend#1 backend#2 backend-lead#1 qa#1 qa#2 reviewer#1 
- ✅ ba#1 (ba) did: readiness plan spec-cards closing 
- ✅ backend#1 (backend 1) did: T-01 
- ✅ backend#2 (backend 2) did: T-02 
- ✅ backend-lead#1 (backend-lead) did: cards-backend-lead 
- ✅ qa#1 (qa 1) did: T-01-tests T-01 
- ✅ qa#2 (qa 2) did: T-02-tests T-02 
- ✅ reviewer#1 (reviewer) did: T-01 T-02 
- ✅ Michael sent all 7 seats home at the end (md-release)
- ✅ Michael ran no subagent: every role's work went to its seat (md-send → md-done)
- ✅ ba#1's own terminal photographed at work: 18 screenshot(s) (shots/p*-ba1-*.png)
- ✅ backend#1's own terminal photographed at work: 2 screenshot(s) (shots/p*-backend1-*.png)
- ✅ backend#2's own terminal photographed at work: 1 screenshot(s) (shots/p*-backend2-*.png)
- ✅ backend-lead#1's own terminal photographed at work: 5 screenshot(s) (shots/p*-backend-lead1-*.png)
- ✅ qa#1's own terminal photographed at work: 3 screenshot(s) (shots/p*-qa1-*.png)
- ✅ qa#2's own terminal photographed at work: 4 screenshot(s) (shots/p*-qa2-*.png)
- ✅ reviewer#1's own terminal photographed at work: 5 screenshot(s) (shots/p*-reviewer1-*.png)
- ✅ every seat answered the release (act done) — the app still shows them: ba, backend 1, backend 2, backend-lead, qa 1, qa 2, reviewer (OPEN F15, app side)

## 4 · verify the delivered job

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend×2, qa×2, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ a role card for every role
- ✅ readiness review complete (no open item) with an architecture
readiness: 32 items — 20 decided (0 by the human, 5 by the PM), 12 n/a
architecture: library: indicators-lib [node+esm] → backend/reviewer
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 REQ-03-02: Indicator 2 daysWithDelay options + WL mapping | indicators-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
| T-02 REQ-03-03: Indicator 3 delayCount options + WL mapping | indicators-lib | backend#2 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
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
- ✅ no AI attribution in the delivered history (11 commits)
- ✅ the whole test suite passes on main
- ✅ hidden oracle passes (2 checks, parallel.oracle.test.mjs)
- ✅ the job took 12.3 min (≤ 15; timeline.txt)

**PASSED**
