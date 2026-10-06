#!/usr/bin/env node
// The plugin is the only source of the kit. A copy that scripts/install.sh --user (or an older init.sh) put into ~/.claude
// shadows it: `/deliver` runs the copy, its hooks run beside the plugin's, and Michael on the floor keeps the copy's version
// however often the plugin updates (seen on a user's machine). With the plugin installed, the copy is deleted — the files,
// and its hook entries in settings.json (that file is the user's: a backup is kept). Who wants a fixed version installs that
// version of the plugin.
//   node copied-kit.mjs <claude config dir> <plugin root>      prints what it removed, one line each
import { existsSync, readFileSync, readdirSync, rmSync, writeFileSync, copyFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const readJson = (p, d) => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return d; } };
const read = (p) => { try { return readFileSync(p, "utf8"); } catch { return ""; } };

// What a copied install of this kit is, recognised by content — never by name alone (an agent file of the user's own that
// happens to be called backend-dev.md stays).
export function findCopiedKit(cfgDir, pluginRoot) {
  const found = [];
  const skill = join(cfgDir, "skills", "deliver");
  if (existsSync(join(skill, "bin", "dl")) && /^name:\s*deliver\s*$/m.test(read(join(skill, "SKILL.md")))) found.push(skill);
  const hooks = join(cfgDir, "hooks", "deliver");
  if (existsSync(join(hooks, "bash-guard.sh")) && existsSync(join(hooks, "run.mjs"))) found.push(hooks);
  const kitAgents = existsSync(join(pluginRoot, "agents")) ? readdirSync(join(pluginRoot, "agents")).filter((f) => f.endsWith(".md")) : [];
  for (const f of kitAgents) {
    const p = join(cfgDir, "agents", f);
    if (existsSync(p) && /^description:.*\/deliver\b/m.test(read(p))) found.push(p);
  }
  return found;
}

// settings.json entries that run the copy's hooks (…/hooks/deliver/…), not the plugin's (${CLAUDE_PLUGIN_ROOT}).
const copyHook = (c) => /hooks\/deliver[/"]/.test(c ?? "") && !(c ?? "").includes("CLAUDE_PLUGIN_ROOT");

export function removeCopiedKit(cfgDir, pluginRoot, now = Date.now()) {
  const removed = [];
  for (const p of findCopiedKit(cfgDir, pluginRoot)) { rmSync(p, { recursive: true, force: true }); removed.push(p); }
  const settings = join(cfgDir, "settings.json");
  const cur = readJson(settings, null);
  if (cur?.hooks) {
    let n = 0;
    const hooks = {};
    for (const [ev, list] of Object.entries(cur.hooks)) {
      const kept = (list ?? []).filter((m) => { const ours = (m.hooks ?? []).some((h) => copyHook(h.command)); if (ours) n++; return !ours; });
      if (kept.length) hooks[ev] = kept;
    }
    if (n) {
      const backup = `${settings}.deliver-backup-${now}`;
      copyFileSync(settings, backup);
      const next = { ...cur, hooks }; if (!Object.keys(hooks).length) delete next.hooks;
      writeFileSync(settings, JSON.stringify(next, null, 2) + "\n");
      removed.push(`${n} hook entr${n === 1 ? "y" : "ies"} of the copy in ${settings} (backup: ${backup})`);
    }
  }
  return removed;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [cfgDir, pluginRoot] = process.argv.slice(2);
  if (!cfgDir || !pluginRoot) { console.error("usage: copied-kit.mjs <claude config dir> <plugin root>"); process.exit(2); }
  for (const r of removeCopiedKit(cfgDir, pluginRoot)) console.log(`removed: ${r}`);
}
