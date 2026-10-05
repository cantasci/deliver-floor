# /deliver from a plain terminal opens the floor (run 45, 2026-10-05)

1. A floor repo (`.deliver.json`: `munder.hive_root` = a new floor folder, `munder.app_command` = start the app); the app was
   closed and aimed at no floor.
2. In the repo, a plain terminal: `claude -p "/deliver examples/watchlist-poc/JOB-models-plain.md"` — its answer:
   [terminal-claude-output.txt](terminal-claude-output.txt): it did not run the job, ran `dl floor-open`, and told the person
   to click Open once.
3. `dl floor-open` aimed the app at the floor, wrote Michael's brief there, started the app and put the request in his inbox.
4. The app opened on its floor picker ([00-picker](shots/00-picker.png)); the stand-in for the person clicked Open
   (`tests/md-open-click.cjs`) — the one click the app needs.
5. Michael read the job from his inbox and ran it on the floor: 5 seats hired, readiness → planning → executing →
   integrating → closing → **done** in 25 min; every role's work went to its seat (10 work orders, no subagent);
   **hidden oracle passed**. He replaced a card whose QA verify command was broken on Node 22, and listed it with his other
   decisions in the PR.

Seen on the floor: cards of a previous run's workers ([01-floor](shots/01-floor.png)). The test reused that run's app HOME,
and Munder Difflin restores the agents it had when it quit — they idle and do no work for this job. A user reopening the app
after a job sees the same; `dl md-release` at the end of a job sends seats home, the app keeps their cards until closed.
