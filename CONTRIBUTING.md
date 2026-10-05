# Contributing to deliver-floor

Thank you for helping. Three things keep this project trustworthy:

1. **Work that is not verified is not done.** Run `tests/run.sh` (deterministic, no model needed) before every PR — it must
   pass. A change to the flow, the guards or the floor also needs a live run (`tests/e2e-live.sh`, `tests/e2e-interactive.sh`
   or `tests/e2e-munder.sh`); archive it with `tests/archive-run.sh` under `docs/verification/` and add a row to
   `docs/verification/HISTORY.md` — failures included.
2. **Code decides state.** New behaviour belongs in `dl` (and a check in `tests/run.sh`), not only in the playbook text.
3. **Write for the reader.** Docs in `docs/` follow the code; `docs/OPEN.md` lists what is not done or not verified.

Practicalities:

- Scripts are bash 3.2-compatible (macOS): `node tests/lint-bash32.mjs <file>` checks the usual traps.
- Keep LF line endings (`.gitattributes` enforces it).
- `kit/hooks/hooks.json` is generated from `kit/settings.hooks.json` — see `docs/02-setup.md`.
- No AI attribution in commits of delivered work; the gate checks it.

By contributing you agree that your contributions are licensed under the Apache License 2.0 (see `LICENSE`).

## Releasing

Claude Code installs a new version of the plugin only when `version` in `kit/.claude-plugin/plugin.json` changes. A
change under `kit/` therefore raises it (semver: a fix → patch, a feature → minor) and adds a `## <version>` entry at the top
of `CHANGELOG.md` saying what users get. `tests/run.sh` fails when `kit/` differs from `origin/main` without both.
