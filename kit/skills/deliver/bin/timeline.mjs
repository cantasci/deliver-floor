#!/usr/bin/env node
// timeline.mjs — where a job's time went, from its event log only (nothing is estimated).
//   node timeline.mjs <job dir> [--json]
// · phases: how long each phase lasted
// · seats / agents: how long each one worked (floor: md-send → md-done; subagents: dispatch → its SubagentStop) and
//   what share of the job that is — a seat busy 10 % of the time is waiting on someone else 90 %
// · cards: assigned → gate passed → QA recorded → review recorded → merged
// · tests: how long dl's own test runs took per card (gate, QA, the whole suite — from board.json): the gate and QA runs
//   hold Michael up while they run; the whole suite runs in the background since 0.10
// · nobody working: stretches where no seat or agent had work (Michael alone — reading, recording, deciding — or idle)
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const jobDir = process.argv[2];
if (!jobDir || !existsSync(join(jobDir, "events.log"))) { console.error("usage: timeline.mjs <job dir> [--json]"); process.exit(2); }
const ev = readFileSync(join(jobDir, "events.log"), "utf8").split("\n").filter(Boolean).map((l) => {
  const [ts, kind, ...rest] = l.split("\t"); return { t: Date.parse(ts), ts, kind, msg: rest.join("\t") };
}).filter((e) => !Number.isNaN(e.t));
if (!ev.length) { console.error("the event log is empty"); process.exit(1); }
const start = ev[0].t, end = ev[ev.length - 1].t, total = Math.max(1, end - start);
const min = (ms) => (ms / 60000).toFixed(1);

// phases
const phases = [];
for (const e of ev) if (e.kind === "phase") {
  if (phases.length) phases[phases.length - 1].end = e.t;
  phases.push({ phase: e.msg.split(" ")[0], start: e.t, end });
}
if (phases.length && ev[0].t < phases[0].start) phases.unshift({ phase: "intake", start: ev[0].t, end: phases[0].start });

// work intervals: who worked when
const work = []; const open = new Map(); const queue = new Map();
for (const e of ev) {
  if (e.kind === "md-send") { const m = e.msg.match(/^(\S+) (\S+#\d+)/); if (m) open.set(m[2], { who: m[2], task: m[1], start: e.t }); }
  else if (e.kind === "md-done") { const m = e.msg.match(/^(\S+) (\S+#\d+):/); const o = m && open.get(m[2]); if (o) { work.push({ ...o, end: e.t }); open.delete(m[2]); } }
  else if (e.kind === "dispatch") { const k = e.msg.trim(); (queue.get(k) ?? queue.set(k, []).get(k)).push(e.t); }
  else if (e.kind === "agent") { const k = e.msg.split(" ")[0]; const q = queue.get(k); if (q?.length) work.push({ who: k, task: "", start: q.shift(), end: e.t }); }
}
for (const o of open.values()) work.push({ ...o, end, unfinished: true });
const busy = new Map();
for (const w of work) busy.set(w.who, (busy.get(w.who) ?? 0) + (w.end - w.start));

// nobody working: the gaps in the union of the work intervals
const iv = work.map((w) => [w.start, w.end]).sort((a, b) => a[0] - b[0]); const gaps = []; let cur = start;
for (const [s, e] of iv) { if (s > cur) gaps.push([cur, s]); cur = Math.max(cur, e); }
if (end > cur) gaps.push([cur, end]);
const idle = gaps.reduce((a, [s, e]) => a + (e - s), 0);

// cards
const cards = new Map(); const c = (id) => cards.get(id) ?? cards.set(id, { id }).get(id);
for (const e of ev) {
  const id = e.msg.match(/^(T-\d+)/)?.[1]; if (!id) continue;
  if (e.kind === "assign" && !c(id).assigned) c(id).assigned = e.t;
  if (e.kind === "gate" && /PASS/.test(e.msg)) c(id).gate = e.t;
  if (e.kind === "qa") c(id).qa = e.t;
  if (e.kind === "review") c(id).review = e.t;
  if (e.kind === "integrate" && /merged/.test(e.msg)) c(id).merged = e.t;
}
const span = (a, b) => (a && b ? min(b - a) : "-");
let board = { cards: [] }; try { board = JSON.parse(readFileSync(join(jobDir, "board.json"), "utf8")); } catch { /* no board yet */ }
const secs = (v) => (typeof v === "number" ? v : null);
const tests = (board.cards ?? []).filter((k) => k.gate?.seconds != null || k.qa?.seconds != null || k.suite?.seconds != null)
  .map((k) => ({ id: k.id, gate_s: secs(k.gate?.seconds), qa_s: secs(k.qa?.seconds), suite_s: secs(k.suite?.seconds), suite: k.suite?.result ?? k.suite?.state ?? null }));

const out = {
  total_min: +min(total), nobody_working_min: +min(idle),
  phases: phases.map((p) => ({ phase: p.phase, min: +min(p.end - p.start) })),
  seats: [...busy].map(([who, ms]) => ({ who, busy_min: +min(ms), share: Math.round((100 * ms) / total) })).sort((a, b) => b.busy_min - a.busy_min),
  tests,
  michael_waited_on_tests_min: +min(1000 * tests.reduce((a, t) => a + (t.gate_s ?? 0) + (t.qa_s ?? 0), 0)),
  cards: [...cards.values()].map((x) => ({ id: x.id, dev: span(x.assigned, x.gate), gate_to_qa: span(x.gate, x.qa), qa_to_review: span(x.qa, x.review), review_to_merge: span(x.review, x.merged), total: span(x.assigned, x.merged) })),
};
if (process.argv.includes("--json")) { console.log(JSON.stringify(out, null, 2)); process.exit(0); }
console.log(`job ${min(total)} min · nobody working ${min(idle)} min (${Math.round((100 * idle) / total)} %) — Michael alone, or waiting`);
console.log("\nphase            min");
for (const p of out.phases) console.log(`${p.phase.padEnd(16)} ${String(p.min).padStart(5)}`);
console.log("\nseat / agent                       busy min  share");
for (const s of out.seats) console.log(`${s.who.padEnd(34)} ${String(s.busy_min).padStart(8)}  ${String(s.share).padStart(4)} %`);
if (out.cards.length) {
  console.log("\ncard   dev → gate   gate → QA   QA → review   review → merge   assigned → merged (min)");
  for (const k of out.cards) console.log(`${k.id.padEnd(6)} ${String(k.dev).padStart(10)}   ${String(k.gate_to_qa).padStart(9)}   ${String(k.qa_to_review).padStart(11)}   ${String(k.review_to_merge).padStart(14)}   ${String(k.total).padStart(17)}`);
}
if (out.tests.length) {
  console.log(`\ntests (s)   gate     QA   whole suite (background)   — Michael waited on the gate and QA runs: ${out.michael_waited_on_tests_min} min`);
  for (const t of out.tests) console.log(`${t.id.padEnd(8)} ${String(t.gate_s ?? "-").padStart(6)} ${String(t.qa_s ?? "-").padStart(6)}   ${String(t.suite_s ?? "-").padStart(6)} ${t.suite ?? ""}`);
}
