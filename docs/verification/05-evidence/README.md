# Evidence behind design decisions

## Background agents die with `claude -p` → headless runs dispatch in the foreground

Measured on Claude Code 2.1.x: a `claude -p` session started two background agents — A (writes `fast.txt`, then
`sleep 40`, then `slow.txt`) and B (writes `react-fast.txt` after A's first report, `react-slow.txt` after A finishes).

- [`bg-agents-headless.json`](bg-agents-headless.json) — the session result: it ended (`stop_reason: end_turn`) while
  "Agent A's report is only interim. Its `sleep 40` is still running in the background".
- [`bg-agents-headless.files`](bg-agents-headless.files) — the files that existed afterwards: `fast.txt`, `react-fast.txt`.
  `slow.txt` and `react-slow.txt` were never written: the background agent died with the process.

Consequence (implemented): `scripts/run-headless.sh` sets `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` and `DELIVER_HEADLESS=1`;
`agent-guard.sh` refuses background agents in headless sessions; `SKILL.md` invariant 6 has Michael put every due action into
one message so stages still advance together. Interactive sessions and Munder Difflin keep background agents/workers.

## The login screen on the floor was the first-run screen, not missing credentials

The first floor runs showed "Select login method" in Michael's terminal, and the first message typed into the composer
went into that screen ([`md-login-screen.png`](md-login-screen.png): "OAuth error: Invalid code"). Two hypotheses were tested:

1. *Munder Difflin strips `CLAUDE_*` variables, so Claude Code is not authenticated.* A credential wrapper was added — the
   screen stayed. Then `claude -p "reply pong"` and the interactive TUI were run with **no** `CLAUDE_*` variables at all
   (`env -i HOME=<fresh> PATH=… HTTPS_PROXY=…`): both answered (`pong`, prompt ready). Rejected.
2. *A fresh HOME has never completed Claude Code's first run.* The test HOME's `~/.claude.json` existed (created by
   non-interactive `claude plugin …` calls during init) but had no `hasCompletedOnboarding`. With the flag set, Michael's
   terminal booted straight into Claude Code and the job ran. Confirmed.

Consequence: docs/07 § 5 and docs/06 describe the first-run screen; the floor test sets the flag on its fresh HOME.
