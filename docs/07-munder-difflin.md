# 07 — Munder Difflin: Michael on the office floor

[Munder Difflin](https://munderdiffl.in) is a desktop app (Electron) where agents sit at desks on an office floor: a god agent
(**Michael**) runs the floor, workers appear at desks while they work, and the hive (a folder) holds their memory, mailboxes,
board and log. `/deliver` runs on it unchanged — Michael is the PM, and every role of the job can be a worker at a desk on
the CLI and model its role names.

```text
 you ── message / Slack / webhook ──► MICHAEL (god agent, cwd = hive)  ──► /deliver <request>
                                         │  dl -C <repo> …  (same flow, same guards)
                                         │  dl md-dispatch T-02 prompt.md   → hive/spawn-requests/<id>.json
                                         ▼
                   ┌─────────── floor workers (one desk per card × role) ────────────┐
                   │ backend#1: claude --agent backend-dev  (cwd = card worktree)    │
                   │ backend#2: codex --model gpt-5-codex   (role card + agent body) │
                   │ qa:        claude --agent qa-tester                             │
                   └── act:"done" → Michael's inbox → gate → QA → review → merge ────┘
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
| configure | `~/.config/munder-difflin/config.json` (macOS: `~/Library/Application Support/munder-difflin/`): `harnessHome` = the hive, repo in `registeredRepos`, `orchestratorMaySpawn: true` (Michael may start workers), Knowledge Graph on; `--skip-onboarding` marks the first-run wizard done |
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
| Michael (PM) | the god agent at the boss desk; his terminal is the Command Center |
| BA, Leads | subagents of Michael (Claude) — or floor workers via `dl md-dispatch` when Michael is not Claude |
| a dev seat on a card | a floor worker: `dl wt add T-02` (assignment) → prompt file → `dl md-dispatch T-02 <prompt> [role]` |
| QA, reviewers | `dl md-dispatch T-02 <prompt> qa` / `reviewer` — a worker in the same worktree, read-only by its rules |
| worker done | the worker's `act:"done"` arrives in Michael's inbox; he runs the card's next step |
| card record | `md_workers` on the card: which worker (role, provider) did what |
| human questions | ASK ME cards (`hive/tasks.json → humanQA`) — or the composer; answers recorded with `dl clarify` |
| role → desk | `roles.yaml → floor` (character + accent); `dl roles` writes `hire@1` manifests to `.work/<job>/munder/hires/` and offers them in `hive/research/hires/` to seat a role permanently |

`dl md-dispatch` writes the spawn request: `objective` = the role card + (for non-Claude CLIs) the agent definition's
instructions + the prompt; `cwd` = the card worktree; `command` = `<settings.munder.claude_command> --agent <agent>` for
Claude roles or `provider` for the others; `model` = the role's model (or `settings.munder.model`); `isolate: false` (the
worktree is already isolated by `dl`); `tokenCap`, `character`, `accent`.

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

## 5. Authentication

Munder Difflin removes `CLAUDE_*` variables from the terminals it opens (it keeps `CLAUDE_CONFIG_DIR`,
`CLAUDE_CODE_OAUTH_TOKEN`, `CLAUDE_CODE_USE_BEDROCK/VERTEX`). On a workstation this does not matter: log in once with
`claude` (`/login`) and every terminal on the floor is logged in. Where Claude Code authenticates through other `CLAUDE_*`
variables (CI, cloud containers), use a two-line wrapper and point both Michael and the workers at it:

```bash
#!/usr/bin/env bash
export CLAUDE_SESSION_INGRESS_TOKEN_FILE=/path/to/token   # whatever variables your environment authenticates with
exec /usr/local/bin/claude "$@"
```

Name it `claude` (Munder Difflin infers the provider from the binary name), then: Munder Difflin config
`"defaultCommand": "/opt/md/bin/claude"` (Michael) and `.deliver.json` `"munder": {"claude_command": "/opt/md/bin/claude"}`
(workers). `ANTHROPIC_API_KEY` passes through unchanged and needs no wrapper. The live test does exactly this
(`tests/e2e-munder.sh`).

## 6. Watching

- The floor: who is at which desk, Michael's terminal, the workers' terminals.
- `dl kanban` / `.work/<job>/kanban.html`: the cards by column, seats busy/idle.
- Munder Difflin's own Tasks board shows hive tasks; for a delivery job `board.json` is the source of truth — don't move
  delivery cards on the hive board.
