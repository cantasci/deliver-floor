# 11 — Several projects at once, and removing people from the floor

Status: **analysis from the code, not yet verified live.** Nothing on this page has been run with two projects at the same
time. The fixes in § 3 are open; they are tracked in [OPEN.md](OPEN.md#multiple-projects-on-one-floor).

## 1. Removing agents from the floor

Three ways, all available today:

| How | What happens | Verified |
| --- | --- | --- |
| **End of job** — Michael runs `dl md-release` | every seat gets a release order, answers `act:"done"`, Munder Difflin closes its terminal and archives it | live, run 18 ([HISTORY](verification/HISTORY.md)): all 6 seats left the floor |
| **By hand in the app** | select the person → the red ✕ in the Command Center; or the **workers** tab → stop | Munder Difflin feature, not exercised by our tests |
| **Idle** | a seat with no output for `workerIdleTimeoutMinutes` (`init.sh --munder` sets 480) is reaped; `dl md-seats` then shows it as `not seated`, `dl md-hire` seats a replacement with the same face | reaping is Munder Difflin's; the re-seat is covered by `tests/run.sh` |

An archived person does not come back after an app restart.

## 2. Two projects at the same time — what works

- **One app, one Michael, one hive.** Munder Difflin allows one running instance per user
  (`app.requestSingleInstanceLock()` in `src/main/index.ts`), so two projects share the floor and Michael. That is by
  design: Michael runs each job with `dl -C <repo> …`.
- **Jobs are per repository.** Each repo has its own `.work/ACTIVE`, `job.json`, board, branches and seats
  (`job.munder.seats`). The job registry (`~/.deliver/jobs/`) and the hooks' `active_jobs` already list every active job.
- **Seats belong to one job.** `dl md-hire` seats people for that job only; worker ids carry the job id
  (`worker-seat-<job>-<seat>-h<n>`), so an order never reaches the other project's person.
- **The playbook** asks before starting a second job *in the same repo*; a job in another repo is independent.

## 3. What has to be fixed before it is safe

| # | Gap | Where | Effect today | Fix |
| --- | --- | --- | --- | --- |
| M1 | **Michael's inbox is shared.** `dl md-inbox -C <repo A>` shows and archives *every* message in `agents/god/inbox`, including reports from project B's seats | `cmd_md_inbox` in `kit/skills/deliver/bin/dl` | B's report is shown under A (sender as a raw worker id) and archived; B's `md-inbox` later flags it `UNRECORDED`, so it is not lost — but it is confusing and relies on the backstop | `md-inbox` takes only messages from its own job's seats (and messages from nobody's seat), leaves the rest in the inbox |
| M2 | **Seat names collide.** Both projects' seats are called `ba`, `backend 1`, … | `cmd_md_hire` (`name="$role $n"`) | two people named `ba` on the floor and in the agent strip; routing is unaffected (worker ids differ), people are not | name = `<project> · <role>[ n]`, e.g. `watchlist · ba`; the floor driver selects by that name |
| M3 | **Faces repeat across projects.** A job never reuses a face, but two jobs pick from the same cast independently | `cmd_md_hire` (`used` is per job) | two "Pam"s on the floor | pick faces not used by any live seat in the hive (`registry.json`), not just this job |
| M4 | **Worker limit.** `maxConcurrentWorkers` ≥ 12 fits one or two 6-seat teams; a third team, or bigger teams, queue | `scripts/init.sh`, `scripts/doctor.sh` | extra seats stay `pending` until someone leaves | `md-hire` warns when the hive's live seats + this job's seats exceed the limit; doctor states the rule (sum of all seats of concurrent jobs) |
| M5 | **stop-guard looks at one job.** `owned_job` returns the first active job Michael's transcript mentions | `owned_job` in `kit/hooks/deliver/lib.sh`, used by `stop-guard.sh` | Michael may stop while the *other* job has work waiting | stop-guard checks every active job Michael owns |
| M6 | **No live test with two projects.** | `tests/e2e-munder.sh` | none of the above is proven | a floor test that starts two jobs in two repos on one floor and checks: separate seats and names, no inbox crossover, both delivered, all seats released |

Until M1–M6 are done and the two-project test passes, run one project per floor at a time.
