# 06 — Troubleshooting

Start with `scripts/doctor.sh <repo>`, then `dl status`, then `tail -50 .work/<job>/events.log`.

## Setup

| Symptom | Cause | Fix |
| --- | --- | --- |
| `/deliver` not found | skill not installed, or Claude Code not restarted | `scripts/install.sh --user`, restart, check `/skills` |
| `ecc:planner` unknown agent | ECC marketplace added but plugin not installed | `/plugin install ecc@ecc`, restart, check `/agents` |
| Dev agent starts without ECC skills | the `skills:` preload name didn't resolve | check `/agents` → the dev agent; the body tells the agent to load them with the Skill tool anyway; if needed remove the `ecc:` prefix or the list |
| `dl: jq is required` | jq missing | `brew install jq` |
| Hooks never fire | entries missing from `settings.json`, or settings not reloaded | `doctor.sh` shows which; re-run `install.sh`; `/hooks` lists the active ones |

## During a job

| Symptom | Cause | Fix |
| --- | --- | --- |
| Every gate fails at `verify` with "command not found" / missing modules | fresh worktree has no deps | set `worktree_setup` in `.deliver.json` ([02-setup § 4](02-setup.md#4-configure-each-repo-deliverjson)); for the running job: `dl jobset '.settings.worktree_setup="…"'` and run it once in each `wt/*` |
| `FAIL out-of-scope file` | the dev touched a file outside `scope` | if the change is legit, widen the card's scope in `board.json` and gate again; otherwise let the retry fix it |
| `CONFLICT` on integrate | two cards edited the same area | dev merges the job branch in its worktree (Michael does this automatically); next time add `depends_on` or split scopes (validate warns about overlaps) |
| Michael keeps going after you said stop | Stop hook in `executing` | it gives up after `stop_guard_max`; or `dl phase awaiting_merge_approval` / mark cards `blocked` |
| Michael stopped mid-board | ran out of context or turns, or `stop_guard_max` reached | `/deliver resume` — everything is in files |
| A card is stuck in `running` after a restart | its agent died with the session | `/deliver resume` re-dispatches into the same worktree |
| Same card failing again and again | card is too big or `verify` is wrong | `dl card T-xx state blocked`, split it into two cards, fix `verify` |
| Tokens/cost too high | too many roles, big cards, high retries | see recipes in [03-settings](03-settings.md#recipes) |
| `git push` denied | `bash-guard`: main/master or force | push the `job/<id>` branch; force push is never allowed |
| Mobile card stuck "device busy" | ARTEMIS runs one task per device | `max_parallel: 1` for mobile jobs, or connect a second device and tell Michael which serial each card uses |

## Manual control (you can always take over)

```bash
dl status                          # where are we
dl card T-04 state ready           # put a blocked card back in the queue
dl card T-04 note "use the v2 API" # leave guidance Michael will pass to the dev
cd "$(dl wt add T-04)"             # work on a card yourself (commit in the worktree), then:
dl gate T-04 && dl integrate T-04
dl phase aborted && dl cleanup --all       # give up on the job (branches stay)
git branch -D job/JOB-… job/JOB-…--T-01   # delete branches yourself when done
```
