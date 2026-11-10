# 11 — Several projects at once

Status: **analysis from the code, not yet verified live.** Nothing on this page has been run with two projects at the same
time. The open points in § 2 are tracked in [OPEN.md](OPEN.md#multiple-projects-at-once).

## 1. Two projects at the same time — what works

- **Jobs are per repository.** Each repo has its own `.work/ACTIVE`, `job.json`, board, branches, worktrees and role
  seats. The job registry (`~/.deliver/jobs/`) and the hooks' `active_jobs` list every active job.
- **One Michael per project.** Start a Claude Code session in each repo and give it its job; each session is that job's
  Michael and dispatches its own agents.
- **The playbook** asks before starting a second job *in the same repo*; a job in another repo is independent.

## 2. What is still open

| # | Gap | Where | Effect today | Fix |
| --- | --- | --- | --- | --- |
| M5 | **stop-guard looks at one job.** `owned_job` returns the first active job the session's transcript mentions | `owned_job` in `kit/hooks/deliver/lib.sh`, used by `stop-guard.sh` | a session that runs jobs in two repos (`dl -C <repo> …`) may stop while the *other* job has work waiting | stop-guard checks every active job the session owns |
| M6 | **No live test with two projects.** | `tests/e2e-live.sh` | none of the above is proven | a live test that runs two jobs in two repos at the same time and checks: separate boards, branches and seats, both delivered |

Until M5 and M6 are done, run each project's job in its own Claude Code session, started in that repo.
