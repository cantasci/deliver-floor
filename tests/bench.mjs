#!/usr/bin/env node
// The bench's numbers: what a run cost, read from Claude Code's own session results, and the table of all runs.
//   node tests/bench.mjs cost <file or dir>...   → {"usd":…, "sessions":…, "models":{model: usd}, "errors":[text]} — every `claude -p` result
//        in the given files (stream-json .jsonl or json .json) or in the .jsonl/.json files directly inside the given dirs
//   node tests/bench.mjs oracle <oracle.log>      → {"result":"pass|fail|error","pass":n,"fail":n}
//   node tests/bench.mjs table <bench dir>        → markdown: one row per scenario, one column group per arm
//   node tests/bench.mjs spent <bench dir>        → the dollars every finished run of the bench cost, summed
// The same source for every arm: Claude Code's `total_cost_usd` per session (subagents included), not the kit's estimate —
// the plain arm has no kit to estimate it. The kit's own figure is kept beside it (usd_kit) as a check on the kit.
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join } from "node:path";

const results = (file) => {
  let text; try { text = readFileSync(file, "utf8"); } catch { return []; }
  const out = [];
  const take = (o) => { if (o && o.type === "result" && typeof o.total_cost_usd === "number") out.push(o); };
  if (file.endsWith(".jsonl")) for (const line of text.split("\n")) { if (line.trim()) try { take(JSON.parse(line)); } catch {} }
  else try { const o = JSON.parse(text); take(o.type ? o : { ...o, type: "result" }); } catch {}
  return out;
};
const files = (p) => {
  if (!existsSync(p)) return [];
  if (!statSync(p).isDirectory()) return [p];
  return readdirSync(p).filter((f) => /\.jsonl?$/.test(f)).map((f) => join(p, f)).filter((f) => statSync(f).isFile());
};
function cost(paths) {
  const rs = paths.flatMap(files).flatMap(results);
  const models = {};
  for (const r of rs) for (const [m, u] of Object.entries(r.modelUsage ?? {})) models[m] = +((models[m] ?? 0) + (u.costUSD ?? 0)).toFixed(4);
  // a session a limit or an API error ended: its text, so the bench can tell "stopped from outside" from "failed"
  const errors = rs.filter((r) => r.is_error).map((r) => String(r.result ?? r.subtype ?? "error").slice(0, 300));
  return { usd: +rs.reduce((s, r) => s + r.total_cost_usd, 0).toFixed(4), sessions: rs.length, models, errors };
}
function oracle(log) {
  let t = ""; try { t = readFileSync(log, "utf8"); } catch { return { result: "error", pass: 0, fail: 0 }; }
  const n = (k) => +(t.match(new RegExp(`^ℹ ${k} (\\d+)`, "m"))?.[1] ?? 0);
  const pass = n("pass"), fail = n("fail");
  return { result: pass > 0 && fail === 0 ? "pass" : pass + fail > 0 ? "fail" : "error", pass, fail };
}
const ARMS = ["full", "quick", "plain"];
const runs = (dir) => ARMS.flatMap((arm) => {
  const d = join(dir, arm); if (!existsSync(d)) return [];
  return readdirSync(d).map((sc) => join(d, sc, "result.json")).filter(existsSync).map((f) => JSON.parse(readFileSync(f, "utf8")));
});
function table(dir) {
  const rs = runs(dir);
  if (!rs.length) return "no finished runs in " + dir;
  const scs = [...new Set(rs.map((r) => r.scenario))];
  const cell = (r) => {
    if (!r) return "— | — | —";
    const o = r.oracle.result === "pass" ? `✅ ${r.oracle.pass}/${r.oracle.pass}` : r.oracle.result === "fail" ? `❌ ${r.oracle.pass}/${r.oracle.pass + r.oracle.fail}` : "❌ no code";
    return `${o} | ${Math.round(r.seconds / 60)} min | $${r.usd.toFixed(2)}`;
  };
  const head = ARMS.map((a) => `${a}: oracle | time | cost`).join(" | ");
  const lines = [`| scenario | ${head} |`, `| --- |${ARMS.map(() => " --- | --- | --- |").join("")}`];
  for (const sc of scs) lines.push(`| ${sc} | ${ARMS.map((a) => cell(rs.find((r) => r.scenario === sc && r.arm === a))).join(" | ")} |`);
  const tot = (a) => {
    const xs = rs.filter((r) => r.arm === a);
    return xs.length ? `${xs.filter((r) => r.oracle.result === "pass").length}/${xs.length} pass · ${Math.round(xs.reduce((s, r) => s + r.seconds, 0) / 60)} min · $${xs.reduce((s, r) => s + r.usd, 0).toFixed(2)}` : "—";
  };
  lines.push("", ...ARMS.map((a) => `- **${a}**: ${tot(a)}`));
  const notes = rs.filter((r) => r.note).map((r) => `- ${r.scenario} · ${r.arm}: ${r.note}`);
  if (notes.length) lines.push("", ...notes);
  lines.push("", `Kit ${[...new Set(rs.map((r) => r.kit))].join(", ")}. Cost: Claude Code's own \`total_cost_usd\` per session, summed (subagents included). Time: wall clock of the run, setup excluded.`);
  return lines.join("\n");
}
const [cmd, ...a] = process.argv.slice(2);
if (cmd === "cost") console.log(JSON.stringify(cost(a)));
else if (cmd === "oracle") console.log(JSON.stringify(oracle(a[0])));
else if (cmd === "table") console.log(table(a[0]));
else if (cmd === "spent") console.log(runs(a[0]).reduce((s, r) => s + r.usd, 0).toFixed(2));
else { console.error("usage: bench.mjs cost <path>... | oracle <log> | table <dir> | spent <dir>"); process.exit(2); }
