# 06 — Troubleshooting

Start with `/deliver:doctor` (or `scripts/doctor.sh <repo>`), then `/deliver:status`, then `tail -50 .work/<job>/events.log`.

## Setup

| Symptom | Cause | Fix |
| --- | --- | --- |
| `/deliver:deliver` not found | plugin not installed or not loaded (its dependency ECC missing), or Claude Code not restarted | `/plugin install deliver@deliver-floor` (ECC with it), restart, check `/plugin` → Errors |
| Michael runs an old version after an update | a copy of the kit in `~/.claude` shadowed the plugin (before 0.7.0) | start one Claude Code session with the plugin: it deletes the copy; `scripts/init.sh` re-briefs the floor |
| `ecc:architect` unknown agent | ECC marketplace added but plugin not installed | `claude plugin install ecc@ecc`, restart, check `/agents` |
| Dev agent starts without ECC skills | a `skills:` preload did not resolve | the role card names the skills too; the agent loads them with the Skill tool. `/agents` → the dev agent shows what loaded |
| `dl: jq is required` | jq missing | `brew install jq` / `apt install jq` |
| Hooks never fire | entries missing from `settings.json` | `doctor.sh` shows which; re-run `install.sh`; `/hooks` lists the active ones |
| Commits show `Co-Authored-By: Claude` and the gate fails | `attribution` not set (installed with `--keep-attribution`, or a project `settings.json` overrides it) | `scripts/install.sh --user` again, or set `"attribution": {"commit": "", "pr": ""}`; or allow it: `commit.ai_attribution: true` |
| ECC GateGuard blocks Michael writing `.work/…` | `GATEGUARD_EXEMPT_GLOBS` missing from `settings.json → env` | re-run `install.sh` (it merges the env entry) |

## Readiness and planning

| Symptom | Cause | Fix |
| --- | --- | --- |
| Job stops in `awaiting_clarification` | open business items — the request does not say | answer each (`QUESTIONS.md`): `/deliver:answer <id> <answer>`, then `/deliver:deliver resume`. Write it into the requirements next time |
| `dl clarify` denied in Michael's session | bash-guard: answers are the human's (unattended run) | `/deliver:answer <id> <answer>` (or answer Michael's question in the chat) |
| `dl: REFUSED — readiness.json … changed after it was frozen at planning` | someone edited the decisions after planning | a real change: `/deliver:unfreeze <reason>` (human), edit, `dl readiness`, `dl phase planning` again. Not intended: restore the file |
| `dl: REFUSED — job.json / board.json was modified outside dl` | a hand edit broke the seal | `/deliver:reseal <reason>` (human) if the edit is intended |
| `dl readiness` ERROR: component owner/reviewer not on the job | architecture names a role the job lacks | `dl jobset '.roles += [{…}]'`, `dl phase readiness` (regenerates role cards), `dl readiness` |
| `dl validate` ERROR: outside component / not the owner | a card's scope leaves its component's path, or the wrong role | fix the card (`dl card T-xx set scope …` / `set role …`) |

## During a job

| Symptom | Cause | Fix |
| --- | --- | --- |
| Every gate fails at `verify` with "command not found" / missing modules | fresh worktree has no deps | set `worktree_setup` in `.deliver.json` ([02 § 4.1](02-setup.md#41-deliverjson--how-this-repo-is-verified-and-delivered)); for the running job `dl jobset '.settings.worktree_setup="…"'` and run it once in each `wt/*` |
| `FAIL out-of-scope file` | the dev touched a file outside `scope` | legit: `dl card T-xx set scope '[…]' "<reason>"` on a ready/blocked card; otherwise the retry fixes it |
| `dl qa` refused: changes outside `qa_scope` | QA edited product code or unit tests | QA reverts; product bugs go back to the dev as failing tests |
| `CONFLICT` on integrate (exit 3) | two cards edited the same area | the dev merges the job branch in its worktree (Michael does this); next time add `depends_on` or split scopes (validate warns) |
| `dl: REFUSED — all N '<role>' seats are busy` | more ready cards than seats | expected: the next free seat takes it. More parallelism: `count` on the role |
| `IDLE <seat> — waiting: …` | the seat's cards depend on unmerged cards | nothing to do; it starts when the dependency merges |
| Michael stopped mid-board | context/turns ran out, or `stop_guard_max` reached | `/deliver:deliver resume` — everything is in files |
| A card stuck in `running` after a restart | its agent died with the session | `/deliver:deliver resume` re-dispatches into the same worktree (`dl wt add --resume`) |
| Headless: agents vanish, cards stay `running` | background agents in `claude -p` die with the process | use `scripts/run-headless.sh` (disables background tasks); agent-guard refuses background agents when `DELIVER_HEADLESS=1` |
| Same card failing again and again | card too big or `verify` wrong | it blocks after `max_attempts`; split it (`dl card add`), fix `verify`, `dl card T-xx retry` |
| `git push` denied | bash-guard: main/master, force, or not the agent's own card branch | push the card branch from its worktree; force push is never allowed |
| `tracker-error` in `/deliver:status` | Jira unreachable / workflow lacks a status | the flow continues; fix the cause, `dl tracker sync` ([10](10-trackers.md)) |

## Munder Difflin

| Symptom | Cause | Fix |
| --- | --- | --- |
| Michael's terminal shows Claude Code's first-run screens ("Select login method", theme) and your message went into them | Claude Code was never started interactively in this HOME (fresh user, CI) | run `claude` once in a normal terminal, or set `"hasCompletedOnboarding": true` in `~/.claude.json`; restart the floor. If you authenticate through a `CLAUDE_*` variable other than `CLAUDE_CODE_OAUTH_TOKEN`, see [07 § 5](07-munder-difflin.md#5-authentication-and-first-run) — Munder Difflin strips those |
| Electron fails to start: `pty.node` / `better_sqlite3.node` | native modules not built for Electron | `scripts/init.sh --munder …` rebuilds them (node-pty from local headers, better-sqlite3 from the Electron prebuild) |
| `dl md-hire` / `md-send` / `md-dispatch`: HIVE_ROOT is not set | run outside Munder Difflin | run from Michael's floor terminal, or set `settings.munder.hive_root` |
| `agent-guard: on the Munder Difflin floor every role works at its own seat` | Michael tried the Agent tool on a floor job | send the work to the role's seat: `dl md-send <role> <task> <prompt>`; `dl md-seats` shows who sits where |
| `dl md-send`: "no one at the desk" / `md-seats`: `not seated` | the seat was released or reaped (idle longer than `workerIdleTimeoutMinutes`) | `dl md-hire` seats a replacement; `scripts/init.sh --munder` sets the idle timeout to 480 minutes |
| seats stay `pending` | more seats than `maxConcurrentWorkers`, or `orchestratorMaySpawn` is off | Settings → Autonomy & Budgets; `scripts/init.sh --munder` sets both |
| A floor worker never starts | `orchestratorMaySpawn` off, or the provider CLI is missing | `scripts/init.sh --munder` sets it; Munder Difflin offers to install the CLI |

## Manual control (you can always take over)

```bash
dl status                          # where are we
dl kanban                          # the board as columns, seats busy/idle
dl card T-04 note "use the v2 API" # guidance Michael passes to the dev
dl card T-04 retry                 # you, at a terminal: give a blocked card new attempts (Michael never asks for it)
dl pm-decide "<what>" "<why>"      # Michael: a decision after the start, listed in the PR
cd "$(dl wt add T-04)"             # work on a card yourself (commit in the worktree), then:
dl gate T-04 && dl qa T-04 pass "…" && dl review T-04 approve "…" && dl integrate T-04
dl phase aborted && dl cleanup --all       # give up on the job (branches stay)
git branch -D job/JOB-… job/JOB-…--T-01   # delete branches yourself when done
```
