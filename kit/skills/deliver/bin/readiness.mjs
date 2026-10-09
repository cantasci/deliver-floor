#!/usr/bin/env node
// readiness.mjs — the requirements readiness review: no card is cut while a decision is missing.
//
// readiness.json (written from the Business Analyst's READINESS answer) is
//   { "items": [ { "id": "ARC-style", "status": "decided" | "n_a" | "open", "answer": "…", "source": "…",
//                  "question": "…", "options": ["…"], "impact": "…" } … ],
//     "architecture": { "style": "microservices", "components": [
//        { "id": "orders-svc", "kind": "service", "stack": ["java","spring-boot"], "path": "services/orders/",
//          "owner": "backend", "reviewer": "reviewer-java", "verify": "cd services/orders && ./gradlew test", "notes": "…" } … ] } }
// architecture is the frozen technical frame: every card belongs to one component; its stack decides the dev's
// skills and the reviewer. `verify` (optional) runs the component's own whole suite from the repo root: a QA pass runs it
// instead of verify_full. Once the job is planned, readiness.json is frozen (dl checks its hash on every step).
//   decided → answer + source (a section of the request, a repo file, "standard: <file>" — a company or project standard
//             from knowledge, e.g. the brand's visual identity — or "human: <name> <date>"); a decision taken from the
//             request, a repo file or a standard also carries `quote`: the words that state it, verbatim ("a … b" for fragments)
//   n_a     → answer says why it does not apply + source
//   open    → a question (+ options, impact) and its owner:
//             "business" — the answer changes scope, observable behaviour, a contract or a business rule → the human answers
//             "pm"       — an implementation detail with none of those effects → Michael (the PM) decides, with a rationale
// Every catalog item that applies to the job must be present; the BA may add items with ids starting "X-".
//
//   node readiness.mjs applicable <job dir>              the catalog items that apply (JSON) — given to the BA
//   node readiness.mjs check <job dir>                   validate; writes readiness.md and QUESTIONS.md
//                                                        exit 0 ready · 1 invalid · 3 open questions remain
//   node readiness.mjs clarify <job dir> <id> <by> "<answer>"   record the human's answer
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { parseYaml, loadCatalog } from "./roles.mjs";
import { collect } from "./knowledge.mjs";

const SKILL_DIR = join(dirname(fileURLToPath(import.meta.url)), "..");
export const catalog = () => parseYaml(readFileSync(join(SKILL_DIR, "readiness.yaml"), "utf8"), "readiness.yaml").items ?? [];

export function areasOf(job) {
  const roles = new Set((job.roles ?? []).map((r) => r.role));
  const a = new Set(["always", ...(job.areas ?? [])]);
  const has = (...xs) => xs.some((x) => roles.has(x));
  if (has("backend", "backend-lead", "tech-lead")) a.add("backend").add("data").add("integration");
  if (has("frontend", "frontend-lead")) a.add("frontend").add("ui");
  if (has("mobile", "mobile-lead", "qa-mobile")) a.add("mobile").add("ui");
  return a;
}
export const applicable = (job) => catalog().filter((i) => areasOf(job).has(i.area));

export const KINDS = ["service", "bff", "app", "web", "mobile", "library", "worker", "db", "infra", "docs"];
export function readReadiness(jobDir) {
  const raw = JSON.parse(readFileSync(join(jobDir, "readiness.json"), "utf8"));
  return Array.isArray(raw) ? { items: raw, architecture: null } : { items: raw.items ?? [], architecture: raw.architecture ?? null };
}
export function checkArchitecture(job, arch) {
  const errors = [];
  if (!arch) return ["architecture is missing — the BA's READINESS answer lists every component (ARC-components)"];
  const comps = arch.components;
  if (!arch.style) errors.push("architecture.style is missing (monolith | modular-monolith | microservices | library | …)");
  if (!Array.isArray(comps) || !comps.length) return [...errors, "architecture.components must list at least one component"];
  const cat = loadCatalog(), roles = new Map((job.roles ?? []).map((r) => [r.role, r]));
  const ids = new Set();
  for (const c of comps) {
    const id = c.id ?? "(no id)";
    if (!/^[a-z0-9][a-z0-9-]*$/.test(id)) errors.push(`component '${id}': id must be lower-case kebab-case`);
    if (ids.has(id)) errors.push(`component '${id}': duplicate id`); ids.add(id);
    if (!KINDS.includes(c.kind)) errors.push(`component '${id}': kind must be one of ${KINDS.join(", ")}`);
    if (!Array.isArray(c.stack) || !c.stack.length) errors.push(`component '${id}': stack must list its languages/frameworks (e.g. ["java","spring-boot"])`);
    const ps = Array.isArray(c.path) ? c.path : [c.path];
    if (!ps.length || ps.some((x) => typeof x !== "string" || !x || x.startsWith("/") || x.split("/").includes("..")))
      errors.push(`component '${id}': path must be a repo-relative directory or file, or a list of them, e.g. ["src/orders/", "test/orders/"] ("." for the root); a card's scope must lie inside these`);
    const owner = roles.get(c.owner);
    if (!owner) errors.push(`component '${id}': owner '${c.owner}' is not a role on this job`);
    else if (cat.roles?.[c.owner]?.kind !== "dev") errors.push(`component '${id}': owner '${c.owner}' must be a dev role`);
    const want = (c.stack ?? []).map((st) => cat.stack_reviewers?.[st]).filter(Boolean);
    const rev = roles.get(c.reviewer);
    if (!c.reviewer || !rev || !String(c.reviewer).startsWith("reviewer")) errors.push(`component '${id}': reviewer must name a reviewer role on this job (e.g. "reviewer-${(c.stack ?? ["x"])[0]}")`);
    else if (want.length && !want.includes(rev.agent)) errors.push(`component '${id}': reviewer ${c.reviewer} (${rev.agent}) does not match its stack — use one of ${[...new Set(want)].join(", ")}`);
    if (c.verify !== undefined && (typeof c.verify !== "string" || !c.verify.trim() || /^\s*(true|:|echo\b|exit 0)/.test(c.verify)))
      errors.push(`component '${id}': verify must be the command that runs this component's whole test suite from the repo root (e.g. "cd services/orders && ./gradlew test"), or be left out`);
  }
  return errors;
}

// A decision is only as good as its source: one taken from the request (or a repo file) must quote the words that state
// it. An interpretation of a term the request uses but does not define is not a decision — it is an open business item.
// (Seen live: "Input is trimmed" was decided as String.prototype.trim(), citing a clause that never defined trimming.)
const norm = (t) => String(t).toLowerCase().replace(/[\u2018\u2019]/g, "'").replace(/[\u201c\u201d]/g, '"').replace(/\s+/g, " ").trim();
// A company or project standard (shared standards/, .deliver/knowledge/ — brand, architecture …) settles an item only where it
// states it in so many words: source "standard: <file>" + the quote, found verbatim in that document.
const standardDoc = (src, job) => {
  const m = String(src).match(/^\s*standard:\s*([\w.-]+)/i);
  if (!m) return null;
  const d = collect(job.repo ?? ".").docs.find((x) => x.name === m[1] || x.name === `${m[1]}.md`);
  return d ? { name: d.name, text: norm(readFileSync(d.path, "utf8")) } : { name: m[1], text: null };
};
function standardError(i, job) {
  const d = standardDoc(i.source, job);
  if (!d) return undefined;   // not a standard: the other rules apply
  if (d.text === null) return `standard '${d.name}' is not one of this job's standards (shared standards/, ~/.deliver/knowledge, .deliver/knowledge/)`;
  const fr = String(i.quote ?? "").split(/\s*(?:…|\.\.\.)\s*/).map(norm).filter(Boolean);
  if (!fr.length) return `decided from standard '${d.name}' needs \`quote\`: its words that state this decision, verbatim`;
  const miss = fr.filter((f) => !d.text.includes(f));
  return miss.length ? `quote not found in standard '${d.name}': "${miss[0].slice(0, 80)}" — a standard settles only what it states; else the item is open` : null;
}
function quoteError(i, job) {
  const src = String(i.source);
  if (/^\s*(human|pm):/i.test(src)) return null;                 // answered by the business / decided by Michael (dl clarify / dl decide)
  const se = standardError(i, job); if (se !== undefined) return se;
  if (!i.quote || !String(i.quote).trim()) return 'decided from a source needs `quote`: the words of the request (or repo file) that state this decision, verbatim. If the source only uses the term without stating the decision, the item is open (owner "business")';
  let hay = norm(job.request ?? "");
  for (const m of src.matchAll(/[\w./-]+\.(md|json|ya?ml|txt|mjs|js|ts|java|go|py|kt|swift)\b/g)) {
    try { hay += " " + norm(readFileSync(join(job.repo ?? ".", m[0]), "utf8")); } catch { /* not a repo file (e.g. the request's own name) */ }
  }
  const miss = String(i.quote).split(/\s*(?:…|\.\.\.)\s*/).map(norm).filter(Boolean).filter((f) => !hay.includes(f));
  return miss.length ? `quote not found in the request${/\.\w+\b/.test(src) ? " or the named file" : ""}: "${miss[0].slice(0, 80)}" — quote the exact words, or make the item open` : null;
}

// An item that shapes the product (`ask: human` in readiness.yaml) is settled by the request's own words or by the human —
// never by a repo file, a convention or an inference. (Seen live: a seed repo's "pure functions, no I/O" in CLAUDE.md was
// taken as the whole product's architecture — no UI, no database, no API, no fetchers — and none of it was asked.)
const askHuman = () => new Set(catalog().filter((c) => c.ask === "human").map((c) => c.id));
const ASK_HUMAN = 'shapes the product (scope · architecture · UI · data · integrations · deployment): it is settled only by the request\'s own words (quote them), by a company or project standard that states it (source "standard: <file>", quoted), or by the human\'s answer, which Michael asks for and records (dl clarify). Any other repo file, a convention or silence is not enough — make it open, owner "business", for Michael to ask, and offer the repo\'s conventions as one of the options';
function humanError(i, job) {
  const src = String(i.source ?? "");
  if (/^\s*human:/i.test(src)) return null;
  if (/^\s*pm:/i.test(src)) return `decided by the PM, but it ${ASK_HUMAN}`;
  if (standardDoc(src, job)) return standardError(i, job);   // the company's or project's own standard, quoted (brand DNA …)
  const fr = String(i.quote ?? "").split(/\s*(?:…|\.\.\.)\s*/).map(norm).filter(Boolean);
  const req = norm(job.request ?? "");
  if (fr.length && fr.every((f) => req.includes(f))) return null;
  return `${i.status} ${fr.length ? "from words that are not in the request" : "without quoting the request"} — it ${ASK_HUMAN}`;
}

export function check(jobDir) {
  const job = JSON.parse(readFileSync(join(jobDir, "job.json"), "utf8"));
  const file = join(jobDir, "readiness.json");
  const errors = [];
  if (!existsSync(file)) return { errors: ["readiness.json is missing — the Business Analyst's READINESS review writes it"], open: [], items: [] };
  let items, architecture;
  try { ({ items, architecture } = readReadiness(jobDir)); } catch (e) { return { errors: [`readiness.json: ${e.message}`], open: [], items: [] }; }
  if (!Array.isArray(items)) return { errors: ["readiness.json: items must be an array"], open: [], items: [] };
  const byId = new Map(items.map((i) => [i.id, i]));
  for (const c of applicable(job)) if (!byId.has(c.id)) errors.push(`${c.id} (${c.q}) is not answered`);
  const known = new Set(catalog().map((c) => c.id)), human = askHuman();
  for (const i of items) {
    if (human.has(i.id) && (i.status === "decided" || i.status === "n_a")) { const e = humanError(i, job); if (e) errors.push(`${i.id}: ${e}`); }
    if (human.has(i.id) && i.status === "open" && i.owner === "pm") errors.push(`${i.id}: open for the PM, but it ${ASK_HUMAN}`);
    if (!i.id) { errors.push("an item has no id"); continue; }
    if (!known.has(i.id) && !String(i.id).startsWith("X-")) errors.push(`${i.id}: unknown id (extra items start with "X-")`);
    if (!["decided", "n_a", "open"].includes(i.status)) errors.push(`${i.id}: status must be decided | n_a | open`);
    if (i.status === "decided" && (!i.answer || !i.source)) errors.push(`${i.id}: decided needs an answer and its source`);
    if (i.status === "decided" && i.source) { const e = quoteError(i, job); if (e) errors.push(`${i.id}: ${e}`); }
    if (i.status === "n_a" && (!i.answer || !i.source)) errors.push(`${i.id}: n_a needs the reason (answer) and its source`);
    if (i.status === "open" && !i.question) errors.push(`${i.id}: open needs a question`);
    if (i.status === "open" && !["business", "pm"].includes(i.owner)) errors.push(`${i.id}: open needs owner "business" (scope/behaviour/contract/business rule) or "pm" (implementation detail)`);
  }
  // The language is never a default (seen: a POC whose requirements name Python libraries was started in Node). It comes from
  // the repo's code, the request (quoted), or — in a repo without code — the team chooses the best fit for the requirements:
  // a PM decision whose rationale quotes the request words that point to it (e.g. "yfinance") and names what was weighed.
  const st = byId.get("ARC-stack");
  if (st?.status === "decided" && /^pm:/.test(String(st.source ?? ""))) {
    const why = String(st.source).replace(/^pm:\s*\S+\s*\S*\s*—?\s*/, "");
    const cited = [...why.matchAll(/["“`']([^"”`']{3,})["”`']/g)].map((m) => norm(m[1])).filter((q) => norm(job.request ?? "").includes(q));
    if (!cited.length) errors.push("ARC-stack decided by the PM must say why this language fits the requirements, quoting the request words that point to it (e.g. \"yfinance\") — not a habit or a default");
    if (!/\b(over|instead of|rather than|vs\.?|versus|alternative|considered)\b/i.test(why)) errors.push("ARC-stack decided by the PM must name the alternatives it weighed (\"… over Node.js because …\")");
  }
  errors.push(...checkArchitecture(job, architecture).map((e) => `architecture: ${e}`));
  // A decided item that needs a specialist brings that ECC role onto the job (e.g. an a11y target → ecc:a11y-architect).
  const onJob = new Set((job.roles ?? []).map((r) => r.role)), cat = catalog();
  const warnings = [];
  for (const i of items) {
    const c = cat.find((x) => x.id === i.id);
    if (i.status !== "decided" || !c) continue;
    if (c.requires_role && !onJob.has(c.requires_role)) errors.push(`${i.id} is decided ("${String(i.answer).slice(0, 60)}") → role '${c.requires_role}' must be on the job (dl jobset, see roles.yaml)`);
    if (c.suggests_role && !onJob.has(c.suggests_role)) warnings.push(`${i.id} is decided → consider role '${c.suggests_role}' (its 'when' rule in roles.yaml decides)`);
  }
  const open = items.filter((i) => i.status === "open");
  const openBusiness = open.filter((i) => i.owner !== "pm"), openPm = open.filter((i) => i.owner === "pm");
  const q = (c) => catalog().find((x) => x.id === c.id)?.q ?? c.question ?? "";
  const md = [`# Readiness — ${job.id}`, "", `${items.length} item(s): ${items.filter((i) => i.status === "decided").length} decided · ` +
    `${items.filter((i) => i.status === "n_a").length} not applicable · ${open.length} open`, "",
    "Sources: a requirement / file = from the request or the repo · `human:` = answered by the business · `pm:` = an implementation detail decided by Michael (the PM)", "",
    "| Item | Status | Decision / reason | Source |", "| --- | --- | --- | --- |",
    ...items.map((i) => `| **${i.id}** ${q(i)} | ${i.status} | ${(i.status === "open" ? "❓ " + i.question : i.answer ?? "").replace(/\n/g, " ")} | ${(i.source ?? "").replace(/\n/g, " ")} |`), "",
    "## Architecture (frozen once the job is planned)", "", `Style: ${architecture?.style ?? "—"}`, "",
    "| Component | Kind | Stack | Path | Owner (dev role) | Reviewer | Suite at a QA pass |", "| --- | --- | --- | --- | --- | --- | --- |",
    ...(architecture?.components ?? []).map((c) => `| ${c.id} | ${c.kind} | ${(c.stack ?? []).join(", ")} | ${[].concat(c.path).map((x) => `\`${x}\``).join(", ")} | ${c.owner} | ${c.reviewer} | ${c.verify ? `\`${c.verify}\`` : "the whole suite (verify_full)"} |`), ""].join("\n");
  writeFileSync(join(jobDir, "readiness.md"), md);
  const qs = openBusiness.length ? [`# Questions before the work can start — ${job.id}`, "",
    "Answer each one in a terminal (or tell Michael):  dl clarify <id> \"<answer>\"", "",
    ...openBusiness.flatMap((i) => [`## ${i.id}`, "", i.question, ...(i.options?.length ? ["", ...i.options.map((o) => `- ${o}`)] : []),
      ...(i.impact ? ["", `_Why it matters:_ ${i.impact}`] : []), ""])].join("\n") : "";
  writeFileSync(join(jobDir, "QUESTIONS.md"), qs);
  return { errors, warnings, open, openBusiness, openPm, items };
}

export function decide(jobDir, id, decision, rationale) { // the PM closes an implementation-detail item
  const file = join(jobDir, "readiness.json");
  const raw = JSON.parse(readFileSync(file, "utf8"));
  const items = Array.isArray(raw) ? raw : raw.items;
  const i = items.find((x) => x.id === id);
  if (!i) throw new Error(`no readiness item ${id}`);
  if (i.status !== "open") throw new Error(`${id} is not open`);
  if (i.owner !== "pm" || askHuman().has(id)) throw new Error(`${id} belongs to the business — only the human answers it (dl clarify)`);
  i.history = [...(i.history ?? []), { status: i.status, question: i.question, at: new Date().toISOString() }];
  Object.assign(i, { status: "decided", answer: decision, source: `pm: michael ${new Date().toISOString().slice(0, 10)} — ${rationale}` });
  writeFileSync(file, JSON.stringify(raw, null, 2) + "\n");
  return i;
}

// Before the freeze, an answer that does not answer its question goes back to the human: the item is open again with
// the same question (and why the answer did not settle it); the rejected answer stays in its history.
export function reopen(jobDir, id, why) {
  const file = join(jobDir, "readiness.json");
  const raw = JSON.parse(readFileSync(file, "utf8"));
  const items = Array.isArray(raw) ? raw : raw.items;
  const i = items.find((x) => x.id === id);
  if (!i) throw new Error(`no readiness item ${id}`);
  if (i.status !== "decided") throw new Error(`${id} is ${i.status} — only a decided item can be reopened`);
  const asked = [...(i.history ?? [])].reverse().find((h) => h.question)?.question ?? i.question ?? `What is the answer for ${id}?`;
  i.history = [...(i.history ?? []), { status: i.status, answer: i.answer, source: i.source, rejected: why, at: new Date().toISOString() }];
  Object.assign(i, { status: "open", owner: "business", question: `${asked} (Asked again: the recorded answer did not answer it — ${why})` });
  delete i.answer; delete i.source; delete i.quote;
  writeFileSync(file, JSON.stringify(raw, null, 2) + "\n");
  return i;
}

export function clarify(jobDir, id, by, answer) {
  const file = join(jobDir, "readiness.json");
  const raw = JSON.parse(readFileSync(file, "utf8"));
  const items = Array.isArray(raw) ? raw : raw.items;
  const i = items.find((x) => x.id === id);
  if (!i) throw new Error(`no readiness item ${id}`);
  i.history = [...(i.history ?? []), { status: i.status, answer: i.answer, question: i.question, at: new Date().toISOString() }];
  Object.assign(i, { status: "decided", answer, source: `human: ${by} ${new Date().toISOString().slice(0, 10)}` });
  writeFileSync(file, JSON.stringify(raw, null, 2) + "\n");
  return i;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [cmd, jobDir, ...rest] = process.argv.slice(2);
  try {
    if (cmd === "applicable") {
      const job = JSON.parse(readFileSync(join(jobDir, "job.json"), "utf8"));
      console.log(JSON.stringify(applicable(job).map(({ id, area, q }) => ({ id, area, q })), null, 2));
    } else if (cmd === "check") {
      const r = check(jobDir);
      for (const e of r.errors) console.log(`ERROR ${e}`);
      for (const w of r.warnings ?? []) console.log(`WARN  ${w}`);
      for (const o of r.openPm) console.log(`PM    ${o.id}: ${o.question}`);
      for (const o of r.openBusiness) console.log(`OPEN  ${o.id}: ${o.question}`);
      if (r.errors.length) process.exit(1);
      console.log(`readiness: ${r.items.length} item(s), ${r.openBusiness.length} open for the human, ${r.openPm.length} for the PM → ${join(jobDir, "readiness.md")}`);
      process.exit(r.openBusiness.length ? 3 : r.openPm.length ? 4 : 0);
    } else if (cmd === "decide") {
      const [id, decision, ...why] = rest;
      if (!id || !decision || !why.length) throw new Error('usage: readiness.mjs decide <job dir> <id> "<decision>" "<rationale>"');
      const i = decide(jobDir, id, decision, why.join(" "));
      console.log(`${i.id}: decided by the PM — ${i.answer}`);
    } else if (cmd === "clarify") {
      const [id, by, ...answer] = rest;
      if (!id || !by || !answer.length) throw new Error('usage: readiness.mjs clarify <job dir> <id> <by> "<answer>"');
      const i = clarify(jobDir, id, by, answer.join(" "));
      console.log(`${i.id}: decided — ${i.answer}`);
    } else if (cmd === "reopen") {
      const [id, ...why] = rest;
      if (!id || !why.length) throw new Error('usage: readiness.mjs reopen <job dir> <id> "<why the answer did not answer it>"');
      const i = reopen(jobDir, id, why.join(" "));
      console.log(`${i.id}: open again for the human`);
    } else throw new Error("usage: readiness.mjs applicable|check|clarify|decide|reopen <job dir> …");
  } catch (e) { console.error(`readiness: ${e.message}`); process.exit(1); }
}
