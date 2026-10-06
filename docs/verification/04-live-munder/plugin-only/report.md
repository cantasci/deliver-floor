# Live E2E — scenario `munder` (Munder Difflin office floor)

Request: `examples/watchlist-poc/$JOBF` · started 2026-10-06T19:31:53Z

## 1 · setup: scripts/init.sh --munder in a fresh HOME

- ✅ an old-style copy of the kit in ~/.claude (as a user upgrading has it)
- ✅ init: result: 29 ok, 7 warning(s), 0 problem(s)
- ✅ repo set to dispatch=munder (devs are floor workers)
- ✅ Michael briefed in the hive (CLAUDE.md, AGENTS.md, GEMINI.md)
- ✅ credential bridge for the floor's terminals: bin/claude (container auth via CLAUDE_* variables)
- ✅ Munder Difflin: Michael runs 'claude' on claude-opus-5-5, workers default to claude-sonnet-5-5
- ✅ the kit is the plugin deliver@deliver-floor: /tmp/claude-0/live/floor-plug/munder/home/.claude/plugins/cache/deliver-floor/deliver/0.7.0/skills/deliver
- ✅ no copy of the kit in ~/.claude (skill, hooks, hook entries)
- ✅ Michael's brief: /deliver:deliver and the stable dl — no version path

## 2 · the floor: open the app, brief Michael with one message, watch

- ✅ the job finished on the floor
- ✅ screenshots of the floor: 68 (shots/)

## 3 · floor-specific checks

- ✅ 2 card(s) were built by floor workers (md_workers on the cards)
- ✅ Munder Difflin consumed 7 spawn request(s) (spawn-requests/.done)
    worker: worker-seat-20261006-1934-ba-1-h1 — ba
    worker: worker-seat-20261006-1934-backend-1-h1 — backend 1
    worker: worker-seat-20261006-1934-backend-lead-1-h1 — backend-lead
    worker: worker-seat-20261006-1934-backend-2-h1 — backend 2
    worker: worker-seat-20261006-1934-qa-1-h1 — qa 1
    worker: worker-seat-20261006-1934-qa-2-h1 — qa 2
    worker: worker-seat-20261006-1934-reviewer-1-h1 — reviewer
- ✅ a seat was hired for every role seat the requirements called for: ba#1 backend#1 backend#2 backend-lead#1 qa#1 qa#2 reviewer#1 
- ✅ ba#1 (ba) did: readiness plan spec-cards closing 
- ✅ backend#1 (backend 1) did: T-01 
- ✅ backend#2 (backend 2) did: T-02 
- ✅ backend-lead#1 (backend-lead) did: cards-backend-lead 
- ✅ qa#1 (qa 1) did: T-01-tests T-02 
- ✅ qa#2 (qa 2) did: T-02-tests T-01 
- ✅ reviewer#1 (reviewer) did: T-01 T-02 
- ✅ Michael sent all 7 seats home at the end (md-release)
- ✅ Michael ran no subagent: every role's work went to its seat (md-send → md-done)
- ✅ ba#1's own terminal photographed at work: 20 screenshot(s) (shots/p*-ba1-*.png)
- ✅ backend#1's own terminal photographed at work: 2 screenshot(s) (shots/p*-backend1-*.png)
- ✅ backend#2's own terminal photographed at work: 3 screenshot(s) (shots/p*-backend2-*.png)
- ✅ backend-lead#1's own terminal photographed at work: 4 screenshot(s) (shots/p*-backend-lead1-*.png)
- ✅ qa#1's own terminal photographed at work: 10 screenshot(s) (shots/p*-qa1-*.png)
- ✅ qa#2's own terminal photographed at work: 9 screenshot(s) (shots/p*-qa2-*.png)
- ✅ reviewer#1's own terminal photographed at work: 5 screenshot(s) (shots/p*-reviewer1-*.png)
- ✅ every seat answered the release (act done) — the app still shows them: ba, backend 1, backend-lead, backend 2, qa 1, qa 2, reviewer (OPEN F15, app side)
- ✅ plugin: ROLES.md names the kit's agents deliver:<agent>
- ✅ Michael ran the plugin's /deliver:deliver: /home/user/skills-shop/kit/skills/deliver

## 4 · verify the delivered job

- ✅ job reached done
- ✅ job shipped (local)
roles: ba, backend-lead, backend×2, qa×2, reviewer
- ✅ roles chosen from the request: ba, qa, a dev role, a reviewer — each with a reason
- ✅ a role card for every role
- ✅ readiness review complete (no open item) with an architecture
readiness: 31 items — 18 decided (0 by the human, 2 by the PM), 13 n/a
architecture: library: indicators-lib [node] → backend/reviewer
- ✅ readiness frozen at planning and unchanged since
- ✅ the Leads cut 2 card(s)
- ✅ a BA spec for every card

| Card | Component | Seat | Attempts | Gate | QA | Review | Reviewers | State |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T-01 Indicator 2 Days with delay: DAYS_WITH_DELAY_OPTIONS + daysWithDelayWl (REQ-03-02) | indicators-lib | backend#1 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
| T-02 Indicator 3 Delays in 12 months: DELAY_COUNT_OPTIONS + delayCountWl (REQ-03-03) | indicators-lib | backend#2 | 1 | PASS | pass (qa_verify PASS) | approve | reviewer | merged |
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
- ✅ the job took 11.8 min (≤ 15; timeline.txt)

**PASSED**
