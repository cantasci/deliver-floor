#!/usr/bin/env node
// Runs one of the kit's bash hooks on every platform:  node run.mjs <hook name>   (stop-guard, bash-guard, …)
// Claude Code runs a hook command in the platform shell — on Windows that is cmd/PowerShell, which cannot start a .sh file.
// This launcher finds bash (Git Bash on Windows: CLAUDE_CODE_GIT_BASH_PATH, next to git.exe, or the usual install paths),
// hands it the hook's stdin and returns its stdout, stderr and exit code unchanged. No bash at all: the hook allows the
// action (exit 0) and says so on stderr — a guard that cannot run must not block the user's session.
import { spawnSync } from "node:child_process";
import { findBash } from "./bash-path.mjs";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const name = (process.argv[2] ?? "").replace(/[^a-z-]/g, "");
const script = join(here, `${name}.sh`);
if (!name || !existsSync(script)) { process.stderr.write(`deliver hook: unknown hook '${process.argv[2] ?? ""}'\n`); process.exit(0); }

const bash = findBash();
if (!bash) {
  process.stderr.write(`deliver hook ${name}: bash not found — install Git for Windows (it brings Git Bash) or set CLAUDE_CODE_GIT_BASH_PATH; the guard did not run\n`);
  process.exit(0);
}
let input = "";
try { input = readFileSync(0, "utf8"); } catch { /* no stdin */ }
const r = spawnSync(bash, [script], { input, encoding: "utf8", env: process.env, maxBuffer: 16 * 1024 * 1024 });
if (r.error) { process.stderr.write(`deliver hook ${name}: ${r.error.message}\n`); process.exit(0); }
process.stdout.write(r.stdout ?? ""); process.stderr.write(r.stderr ?? "");
process.exit(r.status ?? 0);
