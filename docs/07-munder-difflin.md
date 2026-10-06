# 07 — Munder Difflin: Michael on the office floor

[Munder Difflin](https://github.com/cantasci/munder-difflin) (the fork `scripts/init.sh --munder` installs; upstream is [munderdiffl.in](https://munderdiffl.in), whose spawn-queue seats never start) is a desktop app (Electron) where agents sit at desks on an office floor: a god agent
(**Michael**) runs the floor, workers appear at desks while they work, and the hive (a folder) holds their memory, mailboxes,
board and log. `/deliver` runs on it with one rule more: **you talk only to Michael, and Michael uses no subagents.** Every
role the requirements call for — BA, Leads, every dev seat, QA, reviewers, specialists — is a person Michael seats at a desk
for the whole job, on the CLI and model its role names. Michael gives each of them their work orders, with the ECC or kit
instructions and skills for the task.

```text
 you ── message / Slack / webhook ──► MICHAEL (god agent, cwd = hive)  ──► /deliver <request>
                                         │  dl -C <repo> …  (same flow, same guards — and no Agent tool on the floor)
                                         │  dl md-hire                       → one spawn request per seat
                                         │  dl md-send backend T-02 order.md → a work order in the seat's inbox
                                         ▼
          ┌──────────── people at their desks, for the whole job (one per role seat) ────────────┐
          │ ba         readiness · plan · specs · closing        (kit business-analyst)           │
          │ backend-lead  cards                                  (ecc:architect)                  │
          │ backend 1 / backend 2  cards T-01, T-02 … in their worktrees  (kit backend-dev, TDD)  │
          │ qa         integration/e2e tests per card            (kit qa-tester)                  │
          │ reviewer   review per card                           (ecc:typescript-reviewer …)      │
          └── inform "done <task> <seat>" → Michael's inbox → dl md-done → gate → QA → review ─────┘
   ASK ME cards ◄── the readiness questions, only at the start (hive/tasks.json → humanQA)
   Knowledge Graph ◄── dl knowledge sync-md (company standards + lessons)
   MemPalace ◄── Michael's memory.md (dl learn writes lessons there too)
```

## Choosing the mode

The floor is the default.

`/deliver` runs on the Munder Difflin floor unless you choose otherwise **by hand**. Michael never switches the mode.

| Mode | When | How |
| --- | --- | --- |
| **Munder Difflin floor** (default, `"dispatch": "munder"`) | every role is a person at a seat, you talk only to Michael | `scripts/init.sh --munder --hive <dir> --repo <repo>`, start the app, give `/deliver:deliver <request>` to **Michael in the app** |
| **Claude Code subagents** (`"dispatch": "subagent"`) | no app: one `claude` session, roles run as subagents; also every unattended run (`scripts/run-headless.sh`) | new jobs: `"dispatch": "subagent"` in the repo's `.deliver.json` — `scripts/init.sh --subagent --repo <repo>` writes it, `scripts/sandbox.sh --subagent <dir>` makes a sandbox with it. A running job: `dl dispatch subagent "<why>"` from your own terminal |

Back to the floor: remove the key (or set `"munder"`), or `/deliver:mode munder <why>` for a running job. `/deliver:mode` is the
human's command: bash-guard refuses it to every agent, Michael included, and it is refused in unattended sessions.

**`/deliver:deliver` outside the app opens the floor.** Type `/deliver:deliver <request>` in a plain Claude Code session in a floor repo, and the
session does not run the job itself: `dl floor-open` aims Munder Difflin at the repo's floor (`munder.hive_root` in
`.deliver.json`, else the app's current floor), starts the app when it is not running (`munder.app_command`, else the
installed app, else the source checkout `scripts/init.sh --munder` made), teaches Michael `/deliver` there, and puts your
request in his inbox — the app wakes him. When the app had to be started, it opens on its floor picker with the repo's floor
selected: **click Open once** (the app has no setting to skip the picker); Michael starts and reads the job. You follow the job on the floor (or `/deliver:status` / `/deliver:board` from the terminal).
An app already open on another floor is never switched: you are told to open the repo's floor in it.

**The job itself never runs from a separate terminal.** The app's Michael reads the hive inbox; a second Michael
in another terminal reads the same inbox, and the two race for every seat's report (seen on a user's machine). `dl` refuses
every flow command of a floor job unless it comes from the app's Michael (`AGENT_ID=god`, which the app sets in his
terminal): `this job runs on the Munder Difflin floor … give /deliver to Michael in the app`. From any terminal you can still
read (`/deliver:status`, `/deliver:board`, `/deliver:seats`), answer (`/deliver:answer`), stop the job (`/deliver:abort`) and switch the mode (`/deliver:mode`).

## 1. Install and configure — one command

```bash
scripts/init.sh --munder --hive ~/md-hive --repo /path/to/repo
```

| Step | What happens |
| --- | --- |
| source | `git clone https://github.com/cantasci/munder-difflin` into `~/.local/share/munder-difflin` (`--munder-dir` to change). That is the fork, not upstream (`chaitanyagiri/munder-difflin`): only the fork gives a spawn-queue worker — every `/deliver` seat — a first prompt, cards it on the floor and records why one failed to start; upstream, seats never start. `--munder-repo <url\|path>` / `--munder-ref <branch\|tag>` pick another source. An existing checkout is pointed at that repo and moved to that ref (detached; a checkout with local edits other than `package-lock.json` is left as it is) |
| dependencies | `npm install` — again whenever the source's committed `package-lock.json` changes |
| native modules | `node-pty` rebuilt against the local Node headers (N-API, Electron loads it), `better-sqlite3` from the official Electron prebuild — works where Electron's header download is blocked |
| build | `npm run build` — whenever the checked-out commit is not the one `out/.built-from` names (new source is never run from a stale build) |
| configure | `~/.config/munder-difflin/config.json` (macOS: `~/Library/Application Support/munder-difflin/`): `harnessHome` = the hive, repo in `registeredRepos`, `orchestratorMaySpawn: true` (Michael may seat people), `workerIdleTimeoutMinutes` ≥ 480 (a seat waits between tasks — QA
for the devs — and must not be sent home after the default 20 idle minutes), `maxConcurrentWorkers` ≥ 12 (a job's seats all at
once instead of queueing behind the default 4), Knowledge Graph on; `--skip-onboarding` marks the first-run wizard done |
| repo | `.deliver.json` gets `"dispatch": "munder"` (the default anyway — written so the repo says it) |
| brief | `scripts/md-brief.sh` writes the `/deliver` section into the hive's `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (any CLI that runs Michael reads its file) |

Start it: `cd ~/.local/share/munder-difflin && npm run preview` (Linux as root / in containers:
`ELECTRON_DISABLE_SANDBOX=1 npm run preview -- --noSandbox`). Open the hive, and message Michael:

```text
/deliver /path/to/requirements.md
```

## 2. How the flow maps onto the floor

| Flow | On the floor |
| --- | --- |
| Michael (PM) | the god agent at the boss desk; his terminal is the Command Center. No subagents: the agent-guard hook refuses the Agent tool while a floor job is active |
| the team | `dl md-hire` right after the roles are chosen: one person per seat of every selected role (`count` seats each, default 1), through the spawn queue — no click in the app. Each one sits down, says `seated <seat>`, and stays for the whole job |
| any role's work | a work order: `dl md-send <role\|seat> <task> <prompt> --agent <ECC or kit agent>`. Task = a card id (dev, QA, review) or a plan step (`readiness`, `plan`, `cards-<lead>`, `spec-T-xx`, `closing`). The order carries the role card, the agent's instructions and the prompt. Every task but code answers in one file the order names, `.work/<job>/out/<task>-<role>.md\|json` (an earlier answer to the same task is moved to `out/.prev/`) |
| a dev seat on a card | `dl wt add T-02` (assigns the card to a seat, e.g. `backend#2`) → `dl md-send backend T-02 <prompt>` goes to that seat |
| done | the person's inform `done <task> <seat>` arrives in Michael's inbox; he reads it with `dl md-inbox` (each message once, archived exactly; a report archived but never recorded is flagged `UNRECORDED`) → `dl md-done <seat> "<summary>"` → the card's next step. md-done accepts the report only when the answer file is there, not empty and (`.json`) valid; otherwise the seat is told and keeps the task (run 53: a seat reported done for a write a hook had refused). He waits with `dl md-wait` (back within a second of a message). bash-guard refuses moving inbox files (a glob move once filed a report unread), polling the inbox with his own loop, and `find /` for anyone |
| who did what | `events.log`: `md-hire`, `md-send <task> <seat> (<agent>) → <worker>`, `md-done <task> <seat>: <summary>`; on the card: `md_workers` (role, seat, worker) |
| empty desk | a seat released or reaped shows as `not seated` in `dl md-seats`; `dl md-hire` seats a replacement with the same face |
| seat health | `live` only after the person's `seated` message — the app's registry alone proves nothing (a worker that died at startup stays in it). See § 2a |
| end of job | `dl md-release`: every seat gets the release order and goes home |
| human questions | only at the start: the readiness questions on ASK ME cards (`hive/tasks.json → humanQA`) — or the composer; answers recorded with `dl clarify` (by Michael) or `/deliver:answer` (you). After that Michael decides (`dl pm-decide`), and the PR lists it |
| role → face | `roles.yaml → floor` (character + accent) for a role's first seat; further seats get a cast member nobody on the job has |

A seat is a plain `claude` (or the role's provider) in the repo with `isolate: false`: its instructions come with every order,
so one person can follow `ecc:architect` for one task and a kit agent for the next. `dl md-dispatch` (an ephemeral worker per
card, released when it reports `done`) is still there for floors that want it, but the playbook uses seats.

## 2a. Seats that fail — seen, explained, re-seated

`dl md-seats` gives every seat a state, and for each one that is not live, the reason:

| State | Meaning |
| --- | --- |
| `pending` | the spawn request waits in `spawn-requests/` — the app has not picked it up (when the job has more seats than the floor's worker cap, `fleet.json` `workerCap`, md-seats says so: raise `maxConcurrentWorkers` or lower a role's count) |
| `starting` | the worker is on the floor, but has not sent `seated` yet |
| `live` | it sent `seated`, and its last Claude reply is not an error |
| `gone` | released, archived or reaped — `not seated`, `dl md-hire` seats a replacement |
| `failed` | one of: the app rejected the request (`spawn-requests/.failed/`) · the floor recorded why it could not start the worker (registry `lastError`, e.g. "no usage left for its model") · its process died (the app's `log.jsonl` `agent-exit`, with the last line of its crash log — e.g. `Invalid API key`) · its last Claude reply is an API error (e.g. `Credit balance is too low`) · no `seated` within `munder.seat_timeout_minutes` (default 5), also for a request the app never picks up |

The app itself only writes an abnormal exit to `log.jsonl` and `crashes/`; it does not change the worker's registry entry.
`dl` reads those files, so a crash is no longer silent.

**Re-seating** — Michael's decision, not a question for you:

```bash
dl md-reseat backend#1 "died at startup: invalid API key"
dl md-reseat qa#1 "credit balance too low on the default model" --model sonnet
```

The queued request is withdrawn, a live or starting worker is sent home, the seat's open task is cleared (Michael sends it
again once the new person is seated), and a new person is hired for that seat only — on `--model` when given. Every re-seat
is logged and listed in the PR under "Decisions Michael took himself". `dl md-hire` never re-hires a failed seat by itself
(the same model would fail the same way); `dl md-send` refuses a seat that is not live and names the reason.

The app keeps a failed worker's card on the floor (it has no way to be told to remove it); it does no work and goes when
you close it or restart the app. The seat's new person sits at a new card with the same face.

**The model is always explicit.** A seat starts on the re-seat's `--model` if it was given one, else on its role's `model`,
else on `munder.model` (kit default `sonnet`) — never on the app's default model, which may be one the account has no credit
for.

## 3. Models and CLIs

- Michael: Munder Difflin's `godProvider` / `godModel` (Settings). Any provider works; the hive brief covers Claude
  (`CLAUDE.md`), Codex/OpenCode/Crush/Copilot/Cursor (`AGENTS.md`) and Gemini/Antigravity (`GEMINI.md`).
- Roles: `provider` + `model` per role in `job.roles` ([04](04-roles.md#models-and-clis-per-role)). A Claude seat without a
  role model gets `munder.model` (kit default `sonnet`) — never the app's `defaultModel` (§ 2a).

## 4. Knowledge Graph and MemPalace

- `dl knowledge sync-md` (from a floor terminal, where `KG_CLI`/`KG_ROOT` are set) ingests the company and project standards
  and the lessons file into the floor's Knowledge Graph; re-running replaces the earlier copies. Every role card then tells the
  role it can `node "$KG_CLI" search "<topic>"`.
- MemPalace mines each agent's `hive/agents/<id>/memory.md`; `dl learn` on the floor also appends the lesson to Michael's
  `memory.md`, so lessons are searchable across the floor. Details: [08-knowledge](08-knowledge.md).

## 5. Authentication and first run

Michael and the workers are ordinary `claude` processes started by Munder Difflin in your HOME, so they use your login.
Two things to know:

- **First run.** A HOME where Claude Code was never started interactively shows its first-run screens (theme, login method)
  in Michael's terminal, and anything typed there — e.g. your first message — goes into those screens. Start `claude` once in
  a normal terminal (or set `"hasCompletedOnboarding": true` in `~/.claude.json` on a provisioned machine) before opening the
  floor. Munder Difflin itself accepts the folder-trust and bypass-permissions prompts.
- **Credentials in variables.** Munder Difflin removes `CLAUDE_*` variables from the terminals it opens (it keeps
  `CLAUDE_CONFIG_DIR`, `CLAUDE_CODE_OAUTH_TOKEN`, `CLAUDE_CODE_USE_BEDROCK/VERTEX`; `ANTHROPIC_*` pass through). A login
  (`/login`), `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` work as they are. If your setup authenticates through another
  `CLAUDE_*` variable, point Munder Difflin's `defaultCommand` (Michael) and `.deliver.json` `"munder": {"claude_command": …}`
  (workers) at a two-line wrapper named `claude` that exports it and runs `exec /path/to/claude "$@"`.

## 6. Watching

- The floor: who is at which desk, Michael's terminal, the workers' terminals.
- `/deliver:board` / `.work/<job>/kanban.html`: the cards by column, seats busy/idle.
- Munder Difflin's own Tasks board shows hive tasks; for a delivery job `board.json` is the source of truth — don't move
  delivery cards on the hive board.
