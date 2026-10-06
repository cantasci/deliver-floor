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
//                      as the plugin: a copy of the kit in ~/.claude is deleted (copied-kit.mjs), and <plugin data>/bin/dl
//                      runs this version's dl — the one path that stays the same across updates (Michael's brief names it)
import { existsSync, mkdirSync, readFileSync, writeFileSync, copyFileSync, readdirSync, chmodSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { join, dirname } from "node:path";
import { homedir, platform } from "node:os";
import { fileURLToPath } from "node:url";
import { findBash } from "./bash-path.mjs";
import { removeCopiedKit } from "./copied-kit.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const kit = process.env.CLAUDE_PLUGIN_ROOT ?? join(here, "..", "..");
const cfgDir = process.env.CLAUDE_CONFIG_DIR ?? join(homedir(), ".claude");
const dataDir = process.env.CLAUDE_PLUGIN_DATA ?? join(cfgDir, "deliver-data");
const report = process.argv.includes("--report");   // /deliver:doctor: read-only, every check printed for the human
let input = {};
if (!report) try { input = JSON.parse(readFileSync(0, "utf8") || "{}"); } catch { /* no input */ }
const project = process.env.CLAUDE_PROJECT_DIR ?? input.cwd ?? process.cwd();
const win = platform() === "win32";

const done = [], warn = [];
const readJson = (p, d) => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return d; } };
const writeJson = (p, v) => { mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, JSON.stringify(v, null, 2) + "\n"); };
const has = (cmd, args = ["--version"]) => { try { execFileSync(cmd, args, { stdio: "ignore", timeout: 5000 }); return true; } catch { return false; } };

// ── once per plugin version ─────────────────────────────────────────────────────────────────────────────────────────
const version = readJson(join(kit, ".claude-plugin", "plugin.json"), {}).version ?? "dev";
const marker = join(dataDir, `setup-${version}.done`);
if (!report && !existsSync(marker)) {
  // an update: tell the user once what version they are on now and where the changes are listed
  const prev = (existsSync(dataDir) ? readdirSync(dataDir) : []).map((f) => f.match(/^setup-(.+)\.done$/)?.[1]).filter(Boolean)
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true })).pop();
  if (prev) done.push(`updated to ${version} (was ${prev}) — what changed: https://github.com/cantasci/deliver-floor/blob/main/CHANGELOG.md`);
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
if (!report && projCfg && projCfg.commit?.ai_attribution !== true) {
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
if (win && !findBash()) warn.push("Git Bash not found — install Git for Windows (dl and the guards run in bash), or set CLAUDE_CODE_GIT_BASH_PATH");
const installed = readJson(join(cfgDir, "plugins", "installed_plugins.json"), {}).plugins ?? {};
const copied = existsSync(join(cfgDir, "skills", "deliver"));
if (!Object.keys(installed).some((k) => k.startsWith("ecc@")) && !existsSync(join(cfgDir, "agents", "architect.md")))
  warn.push("the ECC plugin is not installed — /plugin marketplace add https://github.com/affaan-m/ECC, then /plugin install ecc@ecc (the deliver plugin installs it for you once that marketplace is added)");
const asPlugin = Boolean(process.env.CLAUDE_PLUGIN_ROOT);
if (asPlugin && Object.keys(installed).some((k) => k.startsWith("deliver@"))) {
  const removed = removeCopiedKit(cfgDir, kit);
  if (removed.length) done.push(`the plugin is the only copy of the kit now — removed the copy in ${cfgDir}: ${removed.join("; ")}. Restart Claude Code once (the copy's /deliver and hooks are still loaded in this session)`);
} else if (copied && Object.keys(installed).some((k) => k.startsWith("deliver@")))
  warn.push("the kit is installed twice (plugin AND copied into ~/.claude) — the next session of the plugin removes the copy");
if (asPlugin) {   // the stable dl: Michael's brief and other CLIs on the floor call it; it always runs the version loaded last
  const launcher = join(dataDir, "bin", "dl");
  const body = `#!/usr/bin/env bash\n# Written by the deliver plugin at every session start: runs the plugin version that session loaded.\nexec bash "${join(kit, "skills", "deliver", "bin", "dl").replace(/\\/g, "/")}" "$@"\n`;
  if ((existsSync(launcher) ? readFileSync(launcher, "utf8") : "") !== body) {
    mkdirSync(dirname(launcher), { recursive: true }); writeFileSync(launcher, body); try { chmodSync(launcher, 0o755); } catch { /* Windows */ }
  }
}
const projCopy = join(project, ".claude", "skills", "deliver");
if (asPlugin && existsSync(join(projCopy, "bin", "dl")))
  warn.push(`this repo carries its own copy of the kit (${projCopy}, committed): /deliver here runs that copy, not the plugin. Remove it with scripts/install.sh --project ${project} --uninstall and commit, or keep it on purpose`);
const mode = projCfg?.dispatch ?? readJson(join(kit, "skills", "deliver", "config.json"), {}).dispatch ?? "munder";
if (projCfg && mode === "munder") {
  const ud = win ? join(process.env.APPDATA ?? "", "Munder Difflin") : platform() === "darwin" ? join(homedir(), "Library", "Application Support", "munder-difflin") : join(process.env.XDG_CONFIG_HOME ?? join(homedir(), ".config"), "munder-difflin");
  const alt = win ? join(process.env.APPDATA ?? "", "munder-difflin") : platform() === "darwin" ? join(homedir(), "Library", "Application Support", "Munder Difflin") : ud;
  if (!existsSync(join(ud, "config.json")) && !existsSync(join(alt, "config.json")))
    warn.push(`this repo runs on the Munder Difflin floor (the default) but the app is not set up — install it with scripts/init.sh --munder from https://github.com/cantasci/deliver-floor (the cantasci/munder-difflin fork; the released app's seats never start), or choose subagents by hand: "dispatch": "subagent" in .deliver.json`);
}

if (report) {
  const installedAs = Object.keys(installed).filter((k) => k.startsWith("deliver@")).join(", ") || "not installed as a plugin";
  console.log(`deliver ${version} (${installedAs}) — ${kit}`);
  for (const w of warn) console.log(`⚠ ${w}`);
  if (!warn.length) console.log(`✔ git, jq, node ${process.versions.node}, bash, the ECC plugin${projCfg && mode === "munder" ? ", Munder Difflin" : ""} — nothing to fix`);
  process.exit(0);
}
if (done.length || warn.length) {
  const lines = [...done.map((d) => `deliver: ${d}`), ...warn.map((w) => `deliver: ⚠ ${w}`)];
  process.stdout.write(JSON.stringify({
    systemMessage: lines.join("\n"),
    hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: warn.length ? `The deliver plugin reports setup problems the user must fix before /deliver works:\n${warn.map((w) => `- ${w}`).join("\n")}` : "" },
  }) + "\n");
}
process.exit(0);
