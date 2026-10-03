#!/usr/bin/env node
// board.json validator — runs on the Leads' cards before execution starts (and on every guarded phase change).
// Error → exit 1 (execution must not start). Warning → exit 0, but Michael should fix it.
// If job.json / plan.md sit next to board.json, cards are also checked against the job's roles and the plan's ACs.
import { readFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { globToRegExp } from "./scope.mjs";

const file = process.argv[2];
if (!file) { console.error("usage: validate.mjs <board.json>"); process.exit(2); }

const STATES = new Set(["ready", "running", "review", "merged", "blocked", "archived"]);
const errors = [], warnings = [];
let board;
try { board = JSON.parse(readFileSync(file, "utf8")); }
catch (e) { console.error(`ERROR could not read board.json: ${e.message}`); process.exit(1); }

const dir = dirname(file);
const job = existsSync(join(dir, "job.json")) ? JSON.parse(readFileSync(join(dir, "job.json"), "utf8")) : null;
const plan = existsSync(join(dir, "plan.md")) ? readFileSync(join(dir, "plan.md"), "utf8") : "";
const roleAgents = new Set((job?.roles ?? []).map((r) => r.agent));
const planACs = new Set([...plan.matchAll(/\bAC-(\d+)\b/g)].map((m) => `AC-${m[1]}`));

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
  if (!Array.isArray(c.notes)) errors.push(`${id}: 'notes' must be an array ([] is fine)`);
  if (Array.isArray(c.scope)) {
    for (const p of c.scope) {
      if (typeof p !== "string" || !p.trim()) { errors.push(`${id}: empty scope entry`); continue; }
      if (/^(\*\*?|\*\*\/\*)$/.test(p) || p.startsWith("/") || p.split("/").includes(".."))
        errors.push(`${id}: scope '${p}' is too broad or escapes the repo ('**', '*', '/…', '..' are not allowed)`);
      if (p.startsWith(".work/") || p.startsWith(".git/")) errors.push(`${id}: scope '${p}' points into .work/ or .git/`);
      try { globToRegExp(p); } catch { errors.push(`${id}: scope '${p}' is not a valid glob`); }
    }
  }
  if (job && roleAgents.size && c.agent && !roleAgents.has(c.agent))
    errors.push(`${id}: agent '${c.agent}' is not one of the job's selected roles (${[...roleAgents].join(", ")})`);
  if (planACs.size && Array.isArray(c.acceptance)) {
    const refs = c.acceptance.flatMap((a) => [...String(a).matchAll(/\bAC-(\d+)\b/g)].map((m) => `AC-${m[1]}`));
    for (const r of refs) if (!planACs.has(r)) errors.push(`${id}: references ${r}, which is not in plan.md`);
    if (refs.length === 0) warnings.push(`${id}: acceptance does not reference any AC-n from plan.md`);
  }
  if (typeof c.verify === "string" && /^\s*(true|:|echo\b|exit 0)/.test(c.verify))
    errors.push(`${id}: verify '${c.verify}' proves nothing — it must run the card's tests`);
}

// The QA role writes the card's integration/e2e tests in qa_scope and runs them with qa_verify; the dev never touches them.
const hasQa = job && (job.roles ?? []).some((r) => r.role === "qa");
for (const c of cards) {
  const id = c.id ?? "(no id)";
  if (c.qa_scope !== undefined || hasQa) {
    if (!Array.isArray(c.qa_scope) || c.qa_scope.length === 0) errors.push(`${id}: 'qa_scope' must be a non-empty array (where QA writes the integration/e2e tests)`);
    else for (const p of c.qa_scope) {
      if (typeof p !== "string" || /^(\*\*?|\*\*\/\*)$/.test(p) || p.startsWith("/") || p.split("/").includes("..")) errors.push(`${id}: qa_scope '${p}' is too broad or escapes the repo`);
      else if ((c.scope ?? []).some((d) => d === p || globToRegExp(d).test(p.split(/[*?{]/)[0] + "x.test.js") && globToRegExp(p).test(p.split(/[*?{]/)[0] + "x.test.js")))
        errors.push(`${id}: qa_scope '${p}' overlaps the dev scope — QA tests and dev code/unit tests must live apart`);
    }
    if (typeof c.qa_verify !== "string" || !c.qa_verify.trim()) errors.push(`${id}: 'qa_verify' is empty (the command that runs the QA tests)`);
    else if (/^\s*(true|:|echo\b|exit 0)/.test(c.qa_verify)) errors.push(`${id}: qa_verify '${c.qa_verify}' proves nothing`);
  }
}

// Every card belongs to one component of the frozen architecture: its scope lives in the component's path and its
// role is the component's owner (QA-only cards: role "qa").
let arch = null;
try { const r = JSON.parse(readFileSync(join(dir, "readiness.json"), "utf8")); arch = Array.isArray(r) ? null : r.architecture ?? null; } catch { /* no readiness yet */ }
if (arch?.components?.length) {
  const comps = new Map(arch.components.map((c) => [c.id, c]));
  for (const c of cards) {
    if (c.state === "archived") continue;
    const id = c.id ?? "(no id)", comp = comps.get(c.component);
    if (!comp) { errors.push(`${id}: 'component' must name an architecture component (${[...comps.keys()].join(", ")})`); continue; }
    if (c.role !== comp.owner && c.role !== "qa") errors.push(`${id}: component ${comp.id} is owned by role '${comp.owner}', not '${c.role}'`);
    const base = comp.path === "." || comp.path === "./" ? "" : comp.path.replace(/\/?$/, "/");
    for (const g of [...(c.scope ?? []), ...(c.qa_scope ?? [])])
      if (base && !String(g).startsWith(base)) errors.push(`${id}: '${g}' is outside component ${comp.id} (${base})`);
  }
}

// The Business Analyst writes a spec per card (specs/T-xx.md); devs build and QA tests against it.
if (job && (job.roles ?? []).some((r) => r.role === "ba"))
  for (const c of cards) {
    if (c.state === "archived" || c.state === "merged") continue;
    const sp = join(dir, "specs", `${c.id}.md`);
    if (!existsSync(sp)) { errors.push(`${c.id}: no BA spec (specs/${c.id}.md) — the Business Analyst writes one per card`); continue; }
    const t = readFileSync(sp, "utf8");
    if (!/acceptance criteria/i.test(t) || !/given/i.test(t) || !/then/i.test(t))
      errors.push(`${c.id}: specs/${c.id}.md has no Given/When/Then acceptance criteria`);
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

// Every AC of the plan should be covered by at least one live card.
if (planACs.size) {
  const covered = new Set(cards.filter((c) => c.state !== "archived")
    .flatMap((c) => (c.acceptance ?? []).flatMap((a) => [...String(a).matchAll(/\bAC-(\d+)\b/g)].map((m) => `AC-${m[1]}`))));
  for (const ac of planACs) if (!covered.has(ac)) warnings.push(`${ac} from plan.md is not covered by any card`);
}

// Cards that can run in parallel (no dependency path between them) must not share scope → warning
const reach = (from, to, seen = new Set()) => {
  if (from === to) return true;
  if (seen.has(from) || !byId.has(from)) return false;
  seen.add(from);
  return (byId.get(from).depends_on ?? []).some((d) => reach(d, to, seen));
};
const prefix = (g) => g.split(/[*?[{]/)[0];
const overlaps = (a, b) => {
  const pa = prefix(a), pb = prefix(b);
  if (pa === a && pb === b) return a === b;                 // two plain paths
  if (pa === a) return globToRegExp(b).test(a);             // path vs glob
  if (pb === b) return globToRegExp(a).test(b);
  return pa.startsWith(pb) || pb.startsWith(pa);            // two globs: shared directory prefix
};
const live = [...byId.values()].filter((c) => c.state !== "archived" && c.state !== "merged");
for (let i = 0; i < live.length; i++)
  for (let j = i + 1; j < live.length; j++) {
    const a = live[i], b = live[j];
    if (reach(a.id, b.id) || reach(b.id, a.id)) continue;
    const all = (c) => [...(c.scope ?? []), ...(c.qa_scope ?? [])];
    const hit = all(a).flatMap((x) => all(b).filter((y) => overlaps(x, y)).map((y) => `${x} ~ ${y}`));
    if (hit.length) warnings.push(`${a.id} and ${b.id} can run in parallel but their scopes overlap (${hit[0]}) → add depends_on or split the scope`);
  }

for (const w of warnings) console.log(`WARN  ${w}`);
for (const e of errors) console.log(`ERROR ${e}`);
if (errors.length) { console.log(`\n${errors.length} error(s) — board is not ready for execution.`); process.exit(1); }
console.log(`board valid: ${cards.length} card(s)${warnings.length ? `, ${warnings.length} warning(s)` : ""}.`);
