# 07 — Munder Difflin: Michael on the office floor

[Munder Difflin](https://munderdiffl.in) is a desktop app (Electron) where agents sit at desks on an office floor: a god agent
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
   ASK ME cards ◄── open business questions / blocked cards (hive/tasks.json → humanQA)
   Knowledge Graph ◄── dl knowledge sync-md (company standards + lessons)
   MemPalace ◄── Michael's memory.md (dl learn writes lessons there too)
```

## 1. Install and configure — one command

```bash
scripts/init.sh --munder --hive ~/md-hive --repo /path/to/repo
```

| Step | What happens |
| --- | --- |
| source | `git clone https://github.com/chaitanyagiri/munder-difflin` into `~/.local/share/munder-difflin` (`--munder-dir` to change), or fast-forward it |
| dependencies | `npm install` |
| native modules | `node-pty` rebuilt against the local Node headers (N-API, Electron loads it), `better-sqlite3` from the official Electron prebuild — works where Electron's header download is blocked |
| build | `npm run build` |
| configure | `~/.config/munder-difflin/config.json` (macOS: `~/Library/Application Support/munder-difflin/`): `harnessHome` = the hive, repo in `registeredRepos`, `orchestratorMaySpawn: true` (Michael may seat people), `workerIdleTimeoutMinutes` ≥ 480 (a seat waits between tasks — QA
for the devs — and must not be sent home after the default 20 idle minutes), `maxConcurrentWorkers` ≥ 12 (a job's seats all at
once instead of queueing behind the default 4), Knowledge Graph on; `--skip-onboarding` marks the first-run wizard done |
| repo | `.deliver.json` gets `"dispatch": "munder"` |
| brief | `scripts/md-brief.sh` writes the `/deliver` section into the hive's `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (any CLI that runs Michael reads its file) |

Start it: `cd ~/.local/share/munder-difflin && npm run preview` (Linux as root / in containers:
`ELECTRON_DISABLE_SANDBOX=1 npm run preview -- --no-sandbox`). Open the hive, and message Michael:

```text
/deliver /path/to/requirements.md
```

## 2. How the flow maps onto the floor

| Flow | On the floor |
| --- | --- |
| Michael (PM) | the god agent at the boss desk; his terminal is the Command Center. No subagents: the agent-guard hook refuses the Agent tool while a floor job is active |
| the team | `dl md-hire` right after the roles are chosen: one person per seat of every selected role (`count` seats each, default 1), through the spawn queue — no click in the app. Each one sits down, says `seated <seat>`, and stays for the whole job |
| any role's work | a work order: `dl md-send <role\|seat> <task> <prompt> --agent <ECC or kit agent>`. Task = a card id (dev, QA, review) or a plan step (`readiness`, `plan`, `cards-<lead>`, `spec-T-xx`, `closing`). The order carries the role card, the agent's instructions and the prompt; analysis goes to `.work/<job>/out/` |
| a dev seat on a card | `dl wt add T-02` (assigns the card to a seat, e.g. `backend#2`) → `dl md-send backend T-02 <prompt>` goes to that seat |
| done | the person's inform `done <task> <seat>` arrives in Michael's inbox → `dl md-done <seat> "<summary>"` → the card's next step |
| who did what | `events.log`: `md-hire`, `md-send <task> <seat> (<agent>) → <worker>`, `md-done <task> <seat>: <summary>`; on the card: `md_workers` (role, seat, worker) |
| empty desk | a seat released or reaped shows as `not seated` in `dl md-seats`; `dl md-hire` seats a replacement with the same face |
| end of job | `dl md-release`: every seat gets the release order and goes home |
| human questions | ASK ME cards (`hive/tasks.json → humanQA`) — or the composer; answers recorded with `dl clarify` |
| role → face | `roles.yaml → floor` (character + accent) for a role's first seat; further seats get a cast member nobody on the job has |

A seat is a plain `claude` (or the role's provider) in the repo with `isolate: false`: its instructions come with every order,
so one person can follow `ecc:architect` for one task and a kit agent for the next. `dl md-dispatch` (an ephemeral worker per
card, released when it reports `done`) is still there for floors that want it, but the playbook uses seats.

## 3. Models and CLIs

- Michael: Munder Difflin's `godProvider` / `godModel` (Settings). Any provider works; the hive brief covers Claude
  (`CLAUDE.md`), Codex/OpenCode/Crush/Copilot/Cursor (`AGENTS.md`) and Gemini/Antigravity (`GEMINI.md`).
- Roles: `provider` + `model` per role in `job.roles` ([04](04-roles.md#models-and-clis-per-role)). Workers inherit Munder
  Difflin's `defaultModel` when the role names none.

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
- `dl kanban` / `.work/<job>/kanban.html`: the cards by column, seats busy/idle.
- Munder Difflin's own Tasks board shows hive tasks; for a delivery job `board.json` is the source of truth — don't move
  delivery cards on the hive board.
