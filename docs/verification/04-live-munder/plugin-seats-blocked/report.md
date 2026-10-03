# Live E2E — scenario `munder` (Munder Difflin office floor)

Request: `examples/watchlist-poc/$JOBF` · started 2026-10-03T16:40:01Z

## 1 · setup: scripts/init.sh --munder in a fresh HOME

- ✅ init: result: 28 ok, 6 warning(s), 0 problem(s)
- ✅ repo set to dispatch=munder (devs are floor workers)
- ✅ Michael briefed in the hive (CLAUDE.md, AGENTS.md, GEMINI.md)
- ✅ credential bridge for the floor's terminals: bin/claude (container auth via CLAUDE_* variables)
- ✅ Munder Difflin: Michael runs 'claude' on claude-opus-5-5, workers default to claude-sonnet-5-5
- ✅ the kit runs as the plugin deliver@skills-shop (copied kit removed): /tmp/claude-0/e2e-v/munder/home/.claude/plugins/cache/skills-shop/deliver/0.2.0/skills/deliver
- ✅ Michael's brief points at the plugin's playbook
- ✅ doctor sees the plugin install: result: 28 ok, 4 warning(s), 0 problem(s)

## 2 · the floor: open the app, brief Michael with one message, watch

- ❌ the job did not finish on the floor (drive.log)
- ✅ screenshots of the floor: 60 (shots/)

## 3 · floor-specific checks

- ❌ no card ran as a floor worker
- ✅ Munder Difflin consumed 6 spawn request(s) (spawn-requests/.done)
    worker: worker-seat-20261003-1641-ba-1-h1 — ba
    worker: worker-seat-20261003-1641-backend-1-h1 — backend 1
    worker: worker-seat-20261003-1641-backend-2-h1 — backend 2
    worker: worker-seat-20261003-1641-backend-lead-1-h1 — backend-lead
    worker: worker-seat-20261003-1641-qa-1-h1 — qa
    worker: worker-seat-20261003-1641-reviewer-1-h1 — reviewer
- ✅ a seat was hired for every role seat the requirements called for: ba#1 backend#1 backend#2 backend-lead#1 qa#1 reviewer#1 
- ✅ ba#1 (ba) did: readiness plan specs 
- ❌ backend#1 never reported a finished task
- ❌ backend#2 never reported a finished task
- ✅ backend-lead#1 (backend-lead) did: cards-backend-lead cards-backend-lead 
- ❌ qa#1 never reported a finished task
- ❌ reviewer#1 never reported a finished task
- ❌ md-release for 0 of 6 seats
- ✅ Michael ran no subagent: every role's work went to its seat (md-send → md-done)
- ✅ ba#1's own terminal photographed at work: 21 screenshot(s) (shots/p*-ba1-*.png)
- ❌ no screenshot of backend#1 at work
- ❌ no screenshot of backend#2 at work
- ✅ backend-lead#1's own terminal photographed at work: 10 screenshot(s) (shots/p*-backend-lead1-*.png)
- ❌ no screenshot of qa#1 at work
- ❌ no screenshot of reviewer#1 at work
- ❌ still on the floor after the run: ba, backend 1, backend 2, backend-lead, qa, reviewer
- ❌ plugin: ROLES.md without the deliver: prefix

## 4 · verify the delivered job

- ❌ job reached done
- ❌ job shipped (local)
roles: ba, backend-lead, backend×2, qa, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ a role card for every role
- ✅ readiness review complete (no open item) with an architecture
readiness: 30 items — 17 decided (0 by the human, 2 by the PM), 13 n/a
architecture: library: indicators-days-with-delay [javascript+nodejs-esm] → backend/reviewer, indicators-delay-count [javascript+nodejs-esm] → backend/reviewer
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 REQ-03-02 Indicator 2 'Days with delay': option list + daysWithDelayWl | indicators-days-with-delay | - | 0 | - | - (qa_verify -) | - | reviewer | ready |
| T-02 REQ-03-03 Indicator 3 'Delays in 12 months': option list + delayCountWl | indicators-delay-count | - | 0 | - | - (qa_verify -) | - | reviewer | ready |
- ❌ T-01 did not go through assign → dev → gate → QA → review → merge
- ❌ T-02 did not go through assign → dev → gate → QA → review → merge
- ❌ no QA test files on main
- ✅ role really ran: business-analyst
- ✅ role really ran: ecc:architect
- ❌ no qa-tester run in events.log
- ❌ no dev run
- ❌ no reviewer run
- ✅ no tracker errors
- ❌ kanban view rendered
- ❌ report.md is the template
- ✅ no AI attribution in the delivered history (1 commits)
- ✅ the whole test suite passes on main
- ❌ hidden oracle FAILED (oracle.log)
✖ oracle/parallel.oracle.test.mjs (73.717018ms)
✖ failing tests:
✖ oracle/parallel.oracle.test.mjs (73.717018ms)

**FAILED**
