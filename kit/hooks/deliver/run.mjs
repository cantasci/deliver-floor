#!/usr/bin/env node
// Runs one of the kit's bash hooks on every platform:  node run.mjs <hook name>   (stop-guard, bash-guard, …)
// Claude Code runs a hook command in the platform shell — on Windows that is cmd/PowerShell, which cannot start a .sh file.
// This launcher finds bash (Git Bash on Windows: CLAUDE_CODE_GIT_BASH_PATH, next to git.exe, or the usual install paths),
// hands it the hook's stdin and returns its stdout, stderr and exit code unchanged. No bash at all: the hook allows the
// action (exit 0) and says so on stderr — a guard that cannot run must not block the user's session.
import { spawnSync, execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const name = (process.argv[2] ?? "").replace(/[^a-z-]/g, "");
const script = join(here, `${name}.sh`);
if (!name || !existsSync(script)) { process.stderr.write(`deliver hook: unknown hook '${process.argv[2] ?? ""}'\n`); process.exit(0); }

export function findBash(env = process.env, platform = process.platform) {
  if (platform !== "win32") return "bash";
  const cands = [];
  if (env.CLAUDE_CODE_GIT_BASH_PATH) cands.push(env.CLAUDE_CODE_GIT_BASH_PATH);
  try { // git.exe lives in <Git>\cmd or <Git>\bin; bash.exe in <Git>\bin
    const git = execFileSync("where", ["git"], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).split(/\r?\n/)[0].trim();
    if (git) cands.push(join(dirname(dirname(git)), "bin", "bash.exe"), join(dirname(git), "bash.exe"));
  } catch { /* no git on PATH */ }
  for (const base of [env.ProgramFiles, env["ProgramFiles(x86)"], env.LOCALAPPDATA && join(env.LOCALAPPDATA, "Programs")])
    if (base) cands.push(join(base, "Git", "bin", "bash.exe"));
  return cands.find((c) => c && existsSync(c)) ?? null;
}

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
