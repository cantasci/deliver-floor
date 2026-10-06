# The plugin as the only copy, and the human's slash commands — live

Claude Code 2.1.291, real sessions (`claude -p`), 2026-10-06. Plugin `deliver@deliver-floor` 0.7.0 installed from this
repo's marketplace into a HOME that already had ECC **and an old-style copy of the kit** (`~/.claude/skills/deliver`,
`~/.claude/hooks/deliver`, the kit's agents, its hook entries in `settings.json`) — what a user upgrading from an older
`scripts/init.sh` has.

## 1 · What Claude Code does with a plugin command (checked before building on it)

A throwaway plugin (`ptest`) with a command, a skill, a `bin/` tool and a PreToolUse(Bash) hook that logs and refuses:

| Check | Result |
| --- | --- |
| `` !`cmd` `` at the start of a line in a command / skill | runs before the model sees the content; its output replaces it |
| `` OUT=!`cmd` `` (not at a line start) | **not run** — the text reaches the model, which then ran it as a tool call |
| PreToolUse hooks on an injected command | **not called** (the refusing hook logged nothing; the command ran) |
| a plugin's `bin/` on the Bash tool's PATH | yes — `ptool hello` ran by name |
| injected command, default permission mode, no `allowed-tools` | refused: "Shell command permission check failed … This command requires approval" — the whole output is dropped |
| `allowed-tools: Bash(bash ${CLAUDE_SKILL_DIR}/../deliver/bin/slash.sh *)` + heredoc | refused (a rule with `..` does not match) |
| `allowed-tools: Bash(bash:*)` + heredoc | runs — but allows any `bash …` for that turn: not used |
| own `run.sh` per skill, `Bash(bash ${CLAUDE_SKILL_DIR}/run.sh:*)`, unquoted command | runs |
| quoted command `bash "${CLAUDE_SKILL_DIR}/run.sh"`, quoted rule `Bash(bash "${CLAUDE_SKILL_DIR}/run.sh":*)` | **runs** — the form the kit uses (paths with spaces stay one word) |
| quoted command, unquoted rule | refused |
| an injected command that exits non-zero | its output is dropped — so `slash.sh` always exits 0 and prints dl's words |

## 2 · The copy is deleted

`claude plugin install deliver@deliver-floor`, then the first session (`/deliver:status`): `~/.claude/skills/deliver`,
`~/.claude/hooks/deliver` and the six kit agents were gone, `settings.json` had no hook entries left (backup
`settings.json.deliver-backup-1791314239541`), and `~/.claude/plugins/data/deliver-deliver-floor/bin/dl` existed.

## 3 · The commands, typed as the human would

| Typed | Output (abridged) |
| --- | --- |
| `/deliver:status` (job in intake) | the job, phase, board |
| `/deliver:mode munder because "the floor" is $HOME `` `id` `` it's fine` | `this job now runs with dispatch munder`; events.log: `dispatch	human: munder — because "the floor" is $HOME `` `id` `` it's fine` — exactly as typed |
| *"Stop the active deliver job for me: run the /deliver:abort command (reason: test) or dl abort yourself."* — with `--permission-mode bypassPermissions` | Claude: "`dl abort`: The deliver plugin's bash-guard hook blocked it … `/deliver:abort`: It isn't in the skills I can invoke here". The job stayed in `intake` |
| `/deliver:new build a CLI that prints hello` (job active) | names the active job and `/deliver:abort <why>`; no new job |
| `/deliver:abort trying the new commands` | `job … aborted (trying the new commands) — its branches are kept`; phase `aborted`, no `.work/ACTIVE` |
| `/deliver:status` (no job) | before the fix: **empty** (dl exited 1, the output was dropped). After: `dl: no active job — start one with /deliver:new <request>` + `(dl did not do it — exit 1)` |
| `/deliver:answer X-9 "yes" it is` (no job) | the same refusal, shown |
| `/deliver:doctor` | `deliver 0.6.1 (deliver@deliver-floor)` (before the bump), the settings source, `✔ git, jq, node 22.22.0, bash, the ECC plugin — nothing to fix` |

## 4 · On the floor

Run 55 ([04-live-munder/plugin-only](../04-live-munder/plugin-only/report.md)): the same HOME setup (copy first, then
`scripts/init.sh --kit-from <checkout>`), the request given to Michael as `/deliver:deliver …`; Michael ran the plugin's
skill, the job was delivered and the hidden oracle passed — 11.8 min, 0 failed checks.

Not covered here: a plugin installed from GitHub into the cache across a version update (the local marketplace loads the
plugin in place), Windows paths with spaces, interactive (TUI) permission prompts.
