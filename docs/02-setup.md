# 02 — Setup, and taking a normal project into the flow

About 15 minutes. `scripts/init.sh` does steps 1–3 for you; the rest is per repository.

## 1. One command: `scripts/init.sh`

```bash
git clone https://github.com/cantasci/deliver-floor && cd deliver-floor
scripts/init.sh --repo /path/to/your/repo                        # ECC + the kit (~/.claude) + .deliver.json + doctor
scripts/init.sh --repo /path/to/repo --munder --hive ~/md-hive   # … and Munder Difflin from source (see 07)
```

| Flag | Effect |
| --- | --- |
| *(none)* | checks tools · installs the ECC plugin (`ecc@ecc`) if missing · installs the kit at user level · runs doctor |
| `--repo <path>` | also writes a starter `.deliver.json` for that repo (if it has none): `verify_full` guessed from the stack, `merge_mode` `human` (or `local` without an `origin`) |
| `--project <repo>` | installs the kit into `<repo>/.claude` instead of `~/.claude` (commit it to share it with the team) |
| `--munder --hive <dir>` | clones, installs, builds and configures Munder Difflin, registers the repo, teaches Michael `/deliver` |
| `--munder-dir <dir>` | where the Munder Difflin checkout lives (default `~/.local/share/munder-difflin`) |
| `--skip-onboarding` | marks Munder Difflin's first-run wizard as done (CI / headless) |
| `--no-ecc` | leave the ECC plugin alone |

It is idempotent: every step checks first. `bash -x scripts/init.sh …` shows every command.

### What it installs

`scripts/install.sh` (called by init; usable on its own: `--user`, `--project <repo>`, `--dry-run`, `--uninstall`,
`--keep-attribution`, `--plugin` — see the plugin section below):

- `kit/agents/*.md` → `<target>/agents/` (business-analyst, qa-tester, backend-dev, frontend-dev, mobile-dev, database-dev)
- `kit/skills/deliver/` → `<target>/skills/deliver/` (SKILL.md, roles.yaml, readiness.yaml, config.json, templates, `bin/dl` …)
- `kit/hooks/deliver/` → `<target>/hooks/deliver/`
- merges `kit/settings.hooks.json` into `<target>/settings.json`: the five hooks, `env.GATEGUARD_EXEMPT_GLOBS` (so ECC's
  GateGuard lets Michael write `.work/` files), and `attribution: {commit: "", pr: ""}` so no Co-Authored-By / "Generated with"
  lines are added to commits and PRs. Backup first (in `<target>/.deliver-backups/`), no duplicates, foreign hooks kept.

ECC notes:

- **One install path.** With the plugin installed, don't also run ECC's `./install.sh --profile full`.
- **Don't copy ECC's hooks into `settings.json`** — the plugin loads them.
- ECC has hundreds of skills; they load on demand. The role cards name the few each role should load.

### Or: install the kit as a Claude Code plugin — no script to run

The repo is a plugin marketplace (`.claude-plugin/marketplace.json` → `kit/`, plugin `deliver`). Inside Claude Code:

```text
/plugin marketplace add https://github.com/affaan-m/ECC
/plugin marketplace add https://github.com/cantasci/deliver-floor
/plugin install deliver@deliver-floor
```

That is all. The plugin depends on ECC (`"dependencies": ["ecc@ecc"]`), so installing `deliver` installs ECC too, once ECC's
marketplace is added (`… (+ 1 dependency: ecc)`). Claude Code has no install hook, so **the first session does the setup** —
the plugin's SessionStart hook (`kit/hooks/deliver/setup.mjs`), once per plugin version:

- `~/.claude/settings.json` gets the env a plugin cannot set (`GATEGUARD_EXEMPT_GLOBS`: ECC's GateGuard lets Michael write
  `.work/` files), with a backup; restart Claude Code once so it applies;
- in a repo with `.deliver.json`, `.claude/settings.local.json` gets an empty commit/PR attribution — that repo only;
- every session: git, jq, Node 18+, bash (Git Bash on Windows), ECC and — for a floor repo — Munder Difflin are checked;
  what is missing is named with the command that fixes it. Nothing is printed when all is well.
- every session: a copy of the kit in `~/.claude` (`skills/deliver`, `hooks/deliver`, the kit's agents, their hook entries
  in `settings.json`) is deleted — the plugin is the only copy; `settings.json` is backed up, your own agents and hooks stay.
  And `~/.claude/plugins/data/deliver-deliver-floor/bin/dl` is rewritten to run the version this session loaded: the one
  `dl` path that survives updates (Michael's brief names it for CLIs that cannot run `/deliver:deliver`).

`scripts/install.sh --user --plugin` still exists for a machine set up from a terminal; it is no longer required.

What changes with the plugin:

- The kit's agents are namespaced: `deliver:backend-dev`, `deliver:qa-tester`, … `dl` detects the plugin and writes those
  names into ROLES.md, the role cards and the seats' orders. `job.json` and `board.json` keep the plain names. Developing
  with `claude --plugin-dir kit`? Set `DELIVER_AGENT_NS=deliver`.
- The job starts with `/deliver:deliver <request>` (or `/deliver:new`); everything else you do is a slash command too —
  [README § Your commands](../README.md#your-commands). You never run `dl` in a terminal.
- `dl` is on Claude Code's PATH while the plugin is enabled (the plugin's `bin/`): Michael and Claude call it by name.
- **One copy.** The plugin deletes a copied kit in `~/.claude` (above). `scripts/install.sh --project <repo>` still copies
  the kit into one repo (committed, a pinned version) — then that repo runs its copy, and the session says so.

`kit/hooks/hooks.json` is generated from `kit/settings.hooks.json` (the one source of truth); after changing the hooks:

```bash
jq '{hooks: ((.hooks | (.. | objects | select(has("command")) | .command) |= sub("__HOOKS_DIR__"; "\"${CLAUDE_PLUGIN_ROOT}/hooks/deliver\"")))}' \
  kit/settings.hooks.json > kit/hooks/hooks.json
```

`tests/run.sh` fails while the two disagree.

### Windows

The plugin runs on Windows with what Claude Code on Windows already needs, plus jq:

| Need | Why | Install |
| --- | --- | --- |
| Git for Windows (Git Bash) | `dl` and the guards are bash; Claude Code's Bash tool uses Git Bash too | `winget install Git.Git` |
| jq | `dl` reads and writes its JSON state with it | `winget install jqlang.jq` |
| Node 18+ | helpers and the hook launcher | `winget install OpenJS.NodeJS.LTS` |
| Munder Difflin (floor mode) | the default run mode | `scripts/init.sh --munder` in Git Bash (builds the [cantasci/munder-difflin](https://github.com/cantasci/munder-difflin) fork; the released installer's seats never start) |

How the kit copes:

- Hooks are started as `node "…/hooks/deliver"/run.mjs <guard>`: Claude Code runs hook commands in the Windows shell, which
  cannot start a `.sh` file; the launcher finds Git Bash (`CLAUDE_CODE_GIT_BASH_PATH`, next to `git.exe`, or the usual
  install folders) and runs the guard in it.
- Paths: Claude Code hands hooks `C:\Users\…`; `dl` sees `/c/Users/…` in Git Bash. The guards normalise both forms before
  comparing.
- Line endings: `.gitattributes` keeps LF in every checkout, so `core.autocrlf` cannot break the scripts.
- `/deliver` in a floor repo opens the installed app (`%LOCALAPPDATA%\Programs\Munder Difflin`), its config is read from
  `%APPDATA%\Munder Difflin`.
- `worktree_setup` commands are yours: on Windows avoid `ln -s` (it needs Developer Mode) — copy instead.

`scripts/init.sh --munder` builds Munder Difflin from source (native modules); on Windows install the released app instead.
The Windows path is checked by `tests/run.sh` (launcher, path normalisation, line endings) but has not been run on a real
Windows machine yet.

### Claude authentication

Michael and the Claude roles are ordinary Claude Code sessions and sign in the way your `claude` does: a `/login` (your
subscription; `claude setup-token` → `CLAUDE_CODE_OAUTH_TOKEN` for an unattended machine), `ANTHROPIC_API_KEY`, Bedrock
(`CLAUDE_CODE_USE_BEDROCK=1`), Vertex (`CLAUDE_CODE_USE_VERTEX=1`) or a gateway (`ANTHROPIC_BASE_URL` +
`ANTHROPIC_AUTH_TOKEN`). Put the variables in `~/.claude/settings.json` → `env` or the shell that starts `claude` / Munder
Difflin — never in `.deliver.json`. `scripts/doctor.sh` says which one it found. Roles on other vendors' CLIs sign in with
that CLI's own login or key ([README § Connect it](../README.md#connect-it)).

## 2. `dl` on your PATH (for you; Michael uses the absolute path)

```bash
echo 'alias dl="$HOME/.claude/skills/deliver/bin/dl"' >> ~/.zshrc && source ~/.zshrc
dl help
```

## 3. Check

```bash
scripts/doctor.sh /path/to/repo
```

Everything should be ✔. Warnings about optional tools (gh, Munder Difflin, tracker) are fine.

## 4. Taking a normal project into the flow

Do this once per repository. It is the difference between a flow that works and one that fails every gate.

### 4.1 `.deliver.json` — how this repo is verified and delivered

You do not write it from scratch: the first `/deliver` (or `dl config --init`) writes it from what the repo says — the test
command from your `Makefile`/`package.json`/`pyproject.toml`/…, the install command from your lockfile, the merge mode from
the remote — and prints where each value came from ([03 § What is read from the repo](03-settings.md#what-is-read-from-the-repo)).
Check those values and make them what your CI runs; a repo that adds a lint or `.env` step, for example, ends up with:

```json
{
  "verify_full": "npm run typecheck && npm run lint && npm test",
  "worktree_setup": "npm ci --prefer-offline",
  "merge_mode": "human",
  "max_parallel": 3,
  "tracker": { "kind": "local" }
}
```

- **`verify_full`** — the whole suite, run on the job branch after every card merged. Make it what your CI runs.
- **`worktree_setup`** — a fresh worktree has no dependencies or `.env`; without this, every `verify` fails:

| Repo | `worktree_setup` |
| --- | --- |
| npm, deps rarely change | `ln -s "$ROOT/node_modules" node_modules` |
| npm/pnpm, cards add deps | `npm ci --prefer-offline` · `pnpm install --frozen-lockfile --prefer-offline` |
| needs `.env` | `cp "$ROOT/.env" .env && …` |
| Gradle / Maven (Spring Boot) | `""` (caches are global) — or `./gradlew --offline dependencies -q` |
| Go | `""` (module cache is global) |
| Python | `ln -s "$ROOT/.venv" .venv` |

  Symlinked paths are listed in `worktree_exclude` (default: `node_modules`, `.venv`, `.env`) so they never show up as
  uncommitted files.
- **`merge_mode`** — `human` (PR, you merge), `semi` (PR + auto-merge on your approval), `auto` (merge on green CI),
  `local` (no remote: merge into the base branch). See [03](03-settings.md#merge-modes).
- Everything else: [03-settings](03-settings.md).

### 4.2 Company and project standards — what every role must follow

```text
~/.deliver/knowledge/*.md            company standards (or DELIVER_KNOWLEDGE=<a cloned standards repo>)
<repo>/.deliver/knowledge/*.md       this project's standards (commit them)
```

Each file has a `## Must` list that is copied into every matching role card (`applies_to: [dev, review, backend]`,
`stack: [java]`). Details and examples: [08-knowledge](08-knowledge.md). `dl knowledge list` shows what each role gets.

### 4.3 Multi-component repos (microservices, BFF + core, mobile + backend)

You don't configure the architecture up front: the readiness review asks for it and freezes it. What helps is a requirements
document that says it — e.g. "4 Spring Boot services + 1 Go service, PostgreSQL owned by the DBA team, React web, Kotlin
Android". The BA records each component with its path, stack and owner; Michael adds the right dev and reviewer roles
(`reviewer-java`, `reviewer-go`, `database`) and the cards stay inside their component's path. See
[04-roles](04-roles.md#mixed-stacks-one-role-card-per-component-stack).

### 4.4 Requirements

A sentence works for small jobs. For real work, write a requirements `.md`: goal, users/roles, requirement ids (`REQ-…`) with
examples, out of scope, non-functional targets (accessibility, performance, security), and clarifications you already know.
[`examples/watchlist-poc/JOB.md`](../examples/watchlist-poc/JOB.md) is a small, complete one. Anything missing becomes a
question at readiness — Michael does not guess.

### 4.5 Permissions

Auto mode (`Shift+Tab` → auto) is the easiest. Without it, allow the repo's commands in `.claude/settings.json`:

```json
{ "permissions": { "allow": ["Bash(git *)", "Bash(npm *)", "Bash(npx *)", "Bash(node *)", "Bash(*/.claude/skills/deliver/bin/dl *)"] } }
```

The guards still block pushes to main, force pushes, and writes outside a card's worktree, whatever the allowlist says.

### 4.6 Tracker (optional)

The local kanban is on by default (`/deliver:board`, `.work/<job>/kanban.html`). For Jira, Asana, Linear or GitHub Projects, set
the credentials in the environment and the tool in `.deliver.json`, e.g. `"tracker": {"kind": "jira", "jira": {"project": "WL"}}`
or `{"kind": "linear", "linear": {"team": "ENG"}}`; `/deliver:doctor` checks it before any job, and `/deliver:tracker` moves
a running job to another one — [10-trackers](10-trackers.md).

## 5. First run

Try it on the sandbox first — nothing of yours is touched:

**On the Munder Difflin floor — the default mode.** Install the app, make a sandbox, give the job to Michael in the app:

```bash
scripts/sandbox.sh /tmp/wl watchlist-poc
scripts/init.sh --munder --hive ~/md-hive --repo /tmp/wl
```

```text
/deliver /path/to/deliver-floor/examples/watchlist-poc/JOB.md          (typed to Michael in the app)
```

**With Claude Code subagents — chosen by hand.** No app; one `claude` session, roles run as its subagents:

```bash
scripts/sandbox.sh --subagent /tmp/wl watchlist-poc && cd /tmp/wl && claude
```

```text
/deliver /path/to/deliver-floor/examples/watchlist-poc/JOB.md
```

Never start `/deliver` for a floor job from a separate terminal: `dl` refuses it, because a second Michael would read the
same inbox. Switching modes and recovering seats: [07 § Choosing the mode](07-munder-difflin.md#choosing-the-mode).

Then on your repo, something small: `/deliver Add a /health endpoint that returns {"status":"ok"}`.

Watch:

1. **Readiness** — the BA's answers (`.work/<job>/readiness.md`). If something business-related is open, Michael asks you,
   once, all questions together.
2. **The board** — `/deliver:status` / `/deliver:board`, `/deliver:timeline` for where the time went.
3. **The PR** — `report.md` is its body: every acceptance criterion with its evidence.
