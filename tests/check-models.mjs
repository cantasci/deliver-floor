#!/usr/bin/env node
// Which model each role actually ran on — read from Claude Code's own session transcripts, not from what anyone claims.
//   node tests/check-models.mjs subagents <projects dir>            Michael's sessions + every subagent, by agent type
//   node tests/check-models.mjs floor <registry.json> <projects dir> Michael (god) + every floor seat, by seat name
// Prints JSON: { michael: {model: n}, roles: { <agent type | seat name>: {model: n} } } — n = assistant messages.
import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { join, basename } from "node:path";

const [mode, a, b] = process.argv.slice(2);
const walk = (d) => (existsSync(d) ? readdirSync(d).flatMap((n) => { const p = join(d, n); return statSync(p).isDirectory() ? walk(p) : [p]; }) : []);
const models = (file) => {
  const out = {};
  for (const line of readFileSync(file, "utf8").split("\n")) {
    if (!line.trim()) continue;
    let e; try { e = JSON.parse(line); } catch { continue; }
    if (e.type !== "assistant" || !e.message?.model || e.message.model === "<synthetic>") continue;
    out[e.message.model] = (out[e.message.model] ?? 0) + 1;
  }
  return out;
};
const add = (into, key, m) => { into[key] ??= {}; for (const [k, v] of Object.entries(m)) into[key][k] = (into[key][k] ?? 0) + v; };

const res = { michael: {}, roles: {} };
if (mode === "subagents") {
  for (const f of walk(a).filter((p) => p.endsWith(".jsonl"))) {
    if (f.includes("/subagents/")) {
      const meta = f.replace(/\.jsonl$/, ".meta.json");
      const type = existsSync(meta) ? JSON.parse(readFileSync(meta, "utf8")).agentType : "unknown";
      add(res.roles, type, models(f));
    } else add(res, "michael", models(f));
  }
} else if (mode === "floor") {
  const reg = JSON.parse(readFileSync(a, "utf8"));
  const files = walk(b).filter((p) => p.endsWith(".jsonl") && !p.includes("/subagents/"));
  for (const ag of Object.values(reg.agents ?? {})) {
    const f = files.find((p) => basename(p) === `${ag.sessionId}.jsonl`);
    if (!f) continue;
    if (ag.isGod) add(res, "michael", models(f)); else add(res.roles, ag.name, models(f));
  }
} else { console.error("usage: check-models.mjs subagents <projects dir> | floor <registry.json> <projects dir>"); process.exit(2); }
console.log(JSON.stringify(res, null, 1));
