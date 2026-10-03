#!/usr/bin/env node
// board.json validator — runs on the Leads' cards before execution starts.
// Error → exit 1 (execution must not start). Warning → exit 0, but Michael should fix it.
import { readFileSync } from "node:fs";

const file = process.argv[2];
if (!file) { console.error("usage: validate.mjs <board.json>"); process.exit(2); }

const STATES = new Set(["ready", "running", "review", "merged", "blocked", "archived"]);
const errors = [], warnings = [];
let board;
try { board = JSON.parse(readFileSync(file, "utf8")); }
catch (e) { console.error(`ERROR could not read board.json: ${e.message}`); process.exit(1); }

const cards = Array.isArray(board.cards) ? board.cards : (errors.push("missing cards array"), []);
if (cards.length === 0) errors.push("board has no cards");

const byId = new Map();
for (const c of cards) {
  const id = c.id ?? "(no id)";
  if (!/^T-\d{2,}$/.test(id)) errors.push(`${id}: id must look like 'T-01'`);
  if (byId.has(id)) errors.push(`${id}: duplicate id`);
  byId.set(id, c);
  for (const k of ["title", "role", "agent", "verify", "context"])
    if (typeof c[k] !== "string" || !c[k].trim()) errors.push(`${id}: '${k}' is empty`);
  for (const k of ["scope", "acceptance"])
    if (!Array.isArray(c[k]) || c[k].length === 0) errors.push(`${id}: '${k}' must be a non-empty array`);
  if (!Array.isArray(c.depends_on)) errors.push(`${id}: 'depends_on' must be an array ([] is fine)`);
  if (!STATES.has(c.state)) errors.push(`${id}: invalid state '${c.state}'`);
  if (typeof c.attempts !== "number") errors.push(`${id}: 'attempts' must be a number`);
  if (Array.isArray(c.scope) && c.scope.some((p) => p === "**" || p === "*" || p.startsWith("/")))
    errors.push(`${id}: scope is too broad or absolute ('**', '*', '/…' are not allowed)`);
}

for (const c of cards)
  for (const d of c.depends_on ?? []) {
    if (d === c.id) errors.push(`${c.id}: depends on itself`);
    else if (!byId.has(d)) errors.push(`${c.id}: depends on a missing card → ${d}`);
  }

// Cycle check (DFS)
const color = new Map();
const visit = (id, path) => {
  if (color.get(id) === 1) { errors.push(`cycle: ${[...path, id].join(" → ")}`); return; }
  if (color.get(id) === 2 || !byId.has(id)) return;
  color.set(id, 1);
  for (const d of byId.get(id).depends_on ?? []) visit(d, [...path, id]);
  color.set(id, 2);
};
for (const id of byId.keys()) visit(id, []);

// Cards that can run in parallel (no dependency path between them) must not share scope → warning
const reach = (from, to, seen = new Set()) => {
  if (from === to) return true;
  if (seen.has(from) || !byId.has(from)) return false;
  seen.add(from);
  return (byId.get(from).depends_on ?? []).some((d) => reach(d, to, seen));
};
const prefix = (g) => g.split(/[*?[{]/)[0];
const overlaps = (a, b) => { const pa = prefix(a), pb = prefix(b); return pa.startsWith(pb) || pb.startsWith(pa); };
const ids = [...byId.keys()];
for (let i = 0; i < ids.length; i++)
  for (let j = i + 1; j < ids.length; j++) {
    const a = byId.get(ids[i]), b = byId.get(ids[j]);
    if (reach(a.id, b.id) || reach(b.id, a.id)) continue;
    const hit = (a.scope ?? []).flatMap((x) => (b.scope ?? []).filter((y) => overlaps(x, y)).map((y) => `${x} ~ ${y}`));
    if (hit.length) warnings.push(`${a.id} and ${b.id} can run in parallel but their scopes overlap (${hit[0]}) → add depends_on or split the scope`);
  }

for (const w of warnings) console.log(`WARN  ${w}`);
for (const e of errors) console.log(`ERROR ${e}`);
if (errors.length) { console.log(`\n${errors.length} error(s) — board is not ready for execution.`); process.exit(1); }
console.log(`board valid: ${cards.length} card(s)${warnings.length ? `, ${warnings.length} warning(s)` : ""}.`);
