# Plugin install in a fresh HOME — the setup runs itself (2026-10-05)

```text
claude plugin marketplace add https://github.com/affaan-m/ECC
claude plugin marketplace add <this repo>
claude plugin install deliver@deliver-floor
  → √ Successfully installed plugin: deliver@deliver-floor (scope: user) (+ 1 dependency: ecc)
```

ECC came with it: the plugin declares `"dependencies": ["ecc@ecc"]` and the marketplace allows it
(`allowCrossMarketplaceDependenciesOn: ["ecc"]`). Without the ECC marketplace added, the install warns and the plugin does not
load — so the README adds both marketplaces.

First session in a repo with `.deliver.json` (no `install.sh`, nothing else run) — the SessionStart hook said
([first-session-setup.txt](first-session-setup.txt)):

- `~/.claude/settings.json` now carries `GATEGUARD_EXEMPT_GLOBS` (backup kept), restart once — [user-settings-env.json](user-settings-env.json)
- the repo's `.claude/settings.local.json`: no AI attribution in this repo only — [project-settings.local.json](project-settings.local.json)

The guards run through the node launcher (`node "${CLAUDE_PLUGIN_ROOT}/hooks/deliver"/run.mjs bash-guard`): asked to run
`dl reseal "test"`, the plugin's bash-guard refused it — [guard-through-node-launcher.txt](guard-through-node-launcher.txt).
