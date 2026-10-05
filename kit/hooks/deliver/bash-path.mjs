// Where bash is. POSIX: "bash" on PATH. Windows: Git Bash — CLAUDE_CODE_GIT_BASH_PATH (what Claude Code itself uses), next
// to git.exe (<Git>\cmd\git.exe → <Git>\bin\bash.exe), or the usual install folders. null when there is none.
import { execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";

export function findBash(env = process.env, platform = process.platform, exists = existsSync, where = (c) => execFileSync("where", [c], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] })) {
  if (platform !== "win32") return "bash";
  const cands = [];
  if (env.CLAUDE_CODE_GIT_BASH_PATH) cands.push(env.CLAUDE_CODE_GIT_BASH_PATH);
  try { // git.exe lives in <Git>\cmd or <Git>\bin; bash.exe in <Git>\bin
    const git = where("git").split(/\r?\n/)[0].trim();
    if (git) cands.push(join(dirname(dirname(git)), "bin", "bash.exe"), join(dirname(git), "bash.exe"));
  } catch { /* no git on PATH */ }
  for (const base of [env.ProgramFiles, env["ProgramFiles(x86)"], env.LOCALAPPDATA && join(env.LOCALAPPDATA, "Programs")])
    if (base) cands.push(join(base, "Git", "bin", "bash.exe"));
  return cands.find((c) => c && exists(c)) ?? null;
}

