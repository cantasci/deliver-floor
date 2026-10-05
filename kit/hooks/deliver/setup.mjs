#!/usr/bin/env node
// SessionStart — the plugin's "postinstall". Claude Code has no install hook, so the first session after an install or an
// update does the setup once (marker per plugin version), and every session checks what /deliver needs. Fast, offline,
// cross-platform (node only). It prints nothing when all is well.
//
//   once per version   ~/.claude/settings.json gets the env a plugin cannot set (GATEGUARD_EXEMPT_GLOBS — ECC's GateGuard
//                      lets Michael write .work/ files); a backup is kept. Applies from the next session.
//   per repo           a repo with .deliver.json: .claude/settings.local.json gets an empty commit/PR attribution
//                      (commit.ai_attribution false is checked by the gate) — this repo only, never global
//   every session      git, jq, node ≥ 18, bash (Git Bash on Windows), the ECC plugin, and — for the floor, the default
//                      mode — Munder Difflin; anything missing is named with the command that fixes it
import { existsSync, mkdirSync, readFileSync, writeFileSync, copyFileSync, readdirSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { join, dirname } from "node:path";
import { homedir, platform } from "node:os";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const kit = process.env.CLAUDE_PLUGIN_ROOT ?? join(here, "..", "..");
const cfgDir = process.env.CLAUDE_CONFIG_DIR ?? join(homedir(), ".claude");
const dataDir = process.env.CLAUDE_PLUGIN_DATA ?? join(cfgDir, "deliver-data");
let input = {};
try { input = JSON.parse(readFileSync(0, "utf8") || "{}"); } catch { /* no input */ }
const project = process.env.CLAUDE_PROJECT_DIR ?? input.cwd ?? process.cwd();
const win = platform() === "win32";

const done = [], warn = [];
const readJson = (p, d) => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return d; } };
const writeJson = (p, v) => { mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, JSON.stringify(v, null, 2) + "\n"); };
const has = (cmd, args = ["--version"]) => { try { execFileSync(cmd, args, { stdio: "ignore", timeout: 5000 }); return true; } catch { return false; } };

// ── once per plugin version ─────────────────────────────────────────────────────────────────────────────────────────
const version = readJson(join(kit, ".claude-plugin", "plugin.json"), {}).version ?? "dev";
const marker = join(dataDir, `setup-${version}.done`);
if (!existsSync(marker)) {
  const snippet = readJson(join(kit, "settings.hooks.json"), {});
  const settingsPath = join(cfgDir, "settings.json");
  const cur = readJson(settingsPath, {});
  const env = { ...(cur.env ?? {}) };
  let changed = false;
  for (const [k, v] of Object.entries(snippet.env ?? {})) {
    if (env[k] === undefined || /\.work\//.test(String(env[k]))) { if (env[k] !== v) { env[k] = v; changed = true; } }
  }
  if (changed) {
    if (existsSync(settingsPath)) copyFileSync(settingsPath, `${settingsPath}.deliver-backup-${Date.now()}`);
    writeJson(settingsPath, { ...cur, env });
    done.push(`first-run setup: ${settingsPath} now carries ${Object.keys(snippet.env ?? {}).join(", ")} (backup kept) — restart Claude Code once so it applies`);
  }
  mkdirSync(dataDir, { recursive: true }); writeFileSync(marker, new Date().toISOString() + "\n");
}

// ── per repo ─────────────────────────────────────────────────────────────────────────────────────────────────────────
const deliverJson = join(project, ".deliver.json");
const projCfg = existsSync(deliverJson) ? readJson(deliverJson, {}) : null;
if (projCfg && projCfg.commit?.ai_attribution !== true) {
  const local = join(project, ".claude", "settings.local.json");
  const cur = readJson(local, {});
  if (cur.attribution === undefined && cur.includeCoAuthoredBy === undefined) {
    writeJson(local, { ...cur, attribution: { commit: "", pr: "" } });
    done.push(`${local}: no AI attribution in this repo's commits and PRs (commit.ai_attribution is false)`);
  }
}

// ── every session ───────────────────────────────────────────────────────────────────────────────────────────────────
if (!has("git")) warn.push("git is missing — install git");
if (!has("jq")) warn.push(`jq is missing — ${win ? "winget install jqlang.jq" : platform() === "darwin" ? "brew install jq" : "apt install jq"}`);
if (Number(process.versions.node.split(".")[0]) < 18) warn.push(`node ${process.versions.node} — /deliver needs Node 18+`);
if (win) {
  const gb = process.env.CLAUDE_CODE_GIT_BASH_PATH;
  if (!(gb && existsSync(gb)) && !has("bash")) {
    const guess = [process.env.ProgramFiles, process.env.LOCALAPPDATA && join(process.env.LOCALAPPDATA, "Programs")].filter(Boolean).map((b) => join(b, "Git", "bin", "bash.exe")).find(existsSync);
    if (!guess) warn.push("Git Bash not found — install Git for Windows (dl and the guards run in bash), or set CLAUDE_CODE_GIT_BASH_PATH");
  }
}
const installed = readJson(join(cfgDir, "plugins", "installed_plugins.json"), {}).plugins ?? {};
const copied = existsSync(join(cfgDir, "skills", "deliver"));
if (!Object.keys(installed).some((k) => k.startsWith("ecc@")) && !existsSync(join(cfgDir, "agents", "architect.md")))
  warn.push("the ECC plugin is not installed — /plugin marketplace add https://github.com/affaan-m/ECC, then /plugin install ecc@ecc (the deliver plugin installs it for you once that marketplace is added)");
if (copied && Object.keys(installed).some((k) => k.startsWith("deliver@")))
  warn.push("the kit is installed twice (plugin AND copied into ~/.claude) — run scripts/install.sh --user --uninstall");
const mode = projCfg?.dispatch ?? readJson(join(kit, "skills", "deliver", "config.json"), {}).dispatch ?? "munder";
if (projCfg && mode === "munder") {
  const ud = win ? join(process.env.APPDATA ?? "", "Munder Difflin") : platform() === "darwin" ? join(homedir(), "Library", "Application Support", "munder-difflin") : join(process.env.XDG_CONFIG_HOME ?? join(homedir(), ".config"), "munder-difflin");
  const alt = win ? join(process.env.APPDATA ?? "", "munder-difflin") : platform() === "darwin" ? join(homedir(), "Library", "Application Support", "Munder Difflin") : ud;
  if (!existsSync(join(ud, "config.json")) && !existsSync(join(alt, "config.json")))
    warn.push(`this repo runs on the Munder Difflin floor (the default) but the app is not set up — install it (https://munderdiffl.in, or scripts/init.sh --munder), or choose subagents by hand: "dispatch": "subagent" in .deliver.json`);
}

if (done.length || warn.length) {
  const lines = [...done.map((d) => `deliver: ${d}`), ...warn.map((w) => `deliver: ⚠ ${w}`)];
  process.stdout.write(JSON.stringify({
    systemMessage: lines.join("\n"),
    hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: warn.length ? `The deliver plugin reports setup problems the user must fix before /deliver works:\n${warn.map((w) => `- ${w}`).join("\n")}` : "" },
  }) + "\n");
}
process.exit(0);
