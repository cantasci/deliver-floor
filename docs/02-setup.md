# 02 — Setup

About 15 minutes. Do the steps in order.

## 1. Install ECC (the role library)

Inside Claude Code:

```text
/plugin marketplace add https://github.com/affaan-m/ECC     # skip if already added
/plugin install ecc@ecc
```

Restart Claude Code, then check that the agents are visible: `/agents` should list `ecc:planner`, `ecc:architect`, `ecc:typescript-reviewer`, …

ECC rules to keep in mind:

- **Pick one install path.** If you used `/plugin install`, do **not** also run ECC's `./install.sh --profile full`. Doing both installs the same things twice.
- **Don't copy ECC's hooks into `settings.json`.** The plugin already loads them. Copying them makes them run twice.
- **Rules are not part of the plugin.** If you want ECC's rules, copy whole directories by hand: `rules/common` plus the one language you use, into `~/.claude/rules/`. Rules are loaded into every session, so keep this small.
- **ECC has 286 skills.** They only load when relevant, but their descriptions still use context. If sessions feel crowded, use ECC's selective install instead of the full plugin (e.g. `./install.sh --target claude --skills tdd-workflow,security-review`; see ECC's README).

## 2. Install this kit

```bash
cd __new_plan
scripts/install.sh --user --dry-run           # look first
scripts/install.sh --user                     # every project on this machine
# or
scripts/install.sh --project /path/to/repo    # one repo; commit .claude/ to share with the team
```

What it does:

- Copies `kit/agents/*.md` into `<target>/agents/`.
- Copies `kit/skills/deliver/` into `<target>/skills/deliver/`.
- Copies `kit/hooks/deliver/` into `<target>/hooks/deliver/`.
- Adds the three hooks to `<target>/settings.json`. It backs the file up first and never adds a duplicate.
- Running it again is safe: unchanged files are skipped and changed ones are backed up.

## 3. Put `dl` on your PATH (for you, not for Michael)

```bash
echo 'alias dl="$HOME/.claude/skills/deliver/bin/dl"' >> ~/.zshrc && source ~/.zshrc
dl help
```

With `--project`, point the alias at `<repo>/.claude/skills/deliver/bin/dl` instead.

## 4. Configure each repo (`.deliver.json`)

Create `.deliver.json` at the root of every repo you'll run jobs in. It overrides the kit defaults (see [03-settings](03-settings.md)):

```json
{
  "verify_full": "npm run typecheck && npm test",
  "worktree_setup": "ln -s \"$ROOT/node_modules\" node_modules",
  "merge_strategy": "pr"
}
```

`worktree_setup` matters. A fresh worktree has no `node_modules`, Gradle cache or `.env`, so without it every `verify` fails. Pick a setup command that matches the repo:

| Repo | `worktree_setup` |
| --- | --- |
| npm, deps rarely change | `ln -s "$ROOT/node_modules" node_modules` |
| npm, cards add deps | `npm ci --prefer-offline` |
| pnpm | `pnpm install --frozen-lockfile --prefer-offline` |
| needs `.env` | `cp "$ROOT/.env" .env && …` |
| Gradle | `""` (the Gradle cache is global) |
| Python | `ln -s "$ROOT/.venv" .venv` |

## 5. Fewer permission prompts (recommended)

Dev agents run tests and git all the time. Add an allowlist to the repo's `.claude/settings.json`, adjusted to your commands:

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm test *)",
      "Bash(npm run *)",
      "Bash(npx *)",
      "Bash(*/.claude/skills/deliver/bin/dl *)",
      "Bash(node */.claude/skills/deliver/bin/validate.mjs *)"
    ]
  }
}
```

`bash-guard` still blocks pushes to main, force pushes and deleting `.work/`, whatever the allowlist says.

## 6. Check

```bash
scripts/doctor.sh /path/to/repo
```

Everything should be ✔. Warnings about optional tools are fine.

## 7. First run: a small job

Pick something tiny to learn the flow, e.g.:

```text
/deliver Add a /health endpoint that returns {"status":"ok"} with a test
```

Watch for these:

1. **Gate 1** shows you the roles, the plan and the board. Read the cards: are the `scope` and `verify` of each one right? That is where most later trouble starts.
2. During execution, `dl status` (from another terminal) shows the board, and `tail -f .work/*/events.log` shows the timeline.
3. **Gate 2** shows the diff stat. Approve, and you get a PR from `job/<id>`.

## 8. (Optional) Munder Difflin

If you want Michael on the office floor, see [05-run-modes](05-run-modes.md#2-michael-in-munder-difflin). The kit doesn't change; only where the session runs does.
