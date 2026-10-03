#!/usr/bin/env node
// readiness.mjs — the requirements readiness review: no card is cut while a decision is missing.
//
// readiness.json (written from the Business Analyst's READINESS answer) is
//   { "items": [ { "id": "ARC-style", "status": "decided" | "n_a" | "open", "answer": "…", "source": "…",
//                  "question": "…", "options": ["…"], "impact": "…" } … ],
//     "architecture": { "style": "microservices", "components": [
//        { "id": "orders-svc", "kind": "service", "stack": ["java","spring-boot"], "path": "services/orders/",
//          "owner": "backend", "reviewer": "reviewer-java", "notes": "…" } … ] } }
// architecture is the frozen technical frame: every card belongs to one component; its stack decides the dev's
// skills and the reviewer. Once the job is planned, readiness.json is frozen (dl checks its hash on every step).
//   decided → answer + source (a quote/section of the request, a repo file, or "human: <name> <date>")
//   n_a     → answer says why it does not apply + source
//   open    → question for the human (+ options, impact)
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

export const KINDS = ["service", "bff", "app", "web", "mobile", "library", "worker", "db", "infra"];
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
    if (typeof c.path !== "string" || !c.path || c.path.startsWith("/") || c.path.split("/").includes("..")) errors.push(`component '${id}': path must be a repo-relative directory ("." for the root)`);
    const owner = roles.get(c.owner);
    if (!owner) errors.push(`component '${id}': owner '${c.owner}' is not a role on this job`);
    else if (cat.roles?.[c.owner]?.kind !== "dev") errors.push(`component '${id}': owner '${c.owner}' must be a dev role`);
    const want = (c.stack ?? []).map((st) => cat.stack_reviewers?.[st]).filter(Boolean);
    const rev = roles.get(c.reviewer);
    if (!c.reviewer || !rev || !String(c.reviewer).startsWith("reviewer")) errors.push(`component '${id}': reviewer must name a reviewer role on this job (e.g. "reviewer-${(c.stack ?? ["x"])[0]}")`);
    else if (want.length && !want.includes(rev.agent)) errors.push(`component '${id}': reviewer ${c.reviewer} (${rev.agent}) does not match its stack — use one of ${[...new Set(want)].join(", ")}`);
  }
  return errors;
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
  const known = new Set(catalog().map((c) => c.id));
  for (const i of items) {
    if (!i.id) { errors.push("an item has no id"); continue; }
    if (!known.has(i.id) && !String(i.id).startsWith("X-")) errors.push(`${i.id}: unknown id (extra items start with "X-")`);
    if (!["decided", "n_a", "open"].includes(i.status)) errors.push(`${i.id}: status must be decided | n_a | open`);
    if (i.status === "decided" && (!i.answer || !i.source)) errors.push(`${i.id}: decided needs an answer and its source`);
    if (i.status === "n_a" && (!i.answer || !i.source)) errors.push(`${i.id}: n_a needs the reason (answer) and its source`);
    if (i.status === "open" && !i.question) errors.push(`${i.id}: open needs a question for the human`);
  }
  errors.push(...checkArchitecture(job, architecture).map((e) => `architecture: ${e}`));
  const open = items.filter((i) => i.status === "open");
  const q = (c) => catalog().find((x) => x.id === c.id)?.q ?? c.question ?? "";
  const md = [`# Readiness — ${job.id}`, "", `${items.length} item(s): ${items.filter((i) => i.status === "decided").length} decided · ` +
    `${items.filter((i) => i.status === "n_a").length} not applicable · ${open.length} open`, "",
    "| Item | Status | Decision / reason | Source |", "| --- | --- | --- | --- |",
    ...items.map((i) => `| **${i.id}** ${q(i)} | ${i.status} | ${(i.status === "open" ? "❓ " + i.question : i.answer ?? "").replace(/\n/g, " ")} | ${(i.source ?? "").replace(/\n/g, " ")} |`), "",
    "## Architecture (frozen once the job is planned)", "", `Style: ${architecture?.style ?? "—"}`, "",
    "| Component | Kind | Stack | Path | Owner (dev role) | Reviewer |", "| --- | --- | --- | --- | --- | --- |",
    ...(architecture?.components ?? []).map((c) => `| ${c.id} | ${c.kind} | ${(c.stack ?? []).join(", ")} | \`${c.path}\` | ${c.owner} | ${c.reviewer} |`), ""].join("\n");
  writeFileSync(join(jobDir, "readiness.md"), md);
  const qs = open.length ? [`# Questions before the work can start — ${job.id}`, "",
    "Answer each one in a terminal (or tell Michael):  dl clarify <id> \"<answer>\"", "",
    ...open.flatMap((i) => [`## ${i.id}`, "", i.question, ...(i.options?.length ? ["", ...i.options.map((o) => `- ${o}`)] : []),
      ...(i.impact ? ["", `_Why it matters:_ ${i.impact}`] : []), ""])].join("\n") : "";
  writeFileSync(join(jobDir, "QUESTIONS.md"), qs);
  return { errors, open, items };
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
      for (const o of r.open) console.log(`OPEN  ${o.id}: ${o.question}`);
      if (r.errors.length) process.exit(1);
      console.log(`readiness: ${r.items.length} item(s), ${r.open.length} open → ${join(jobDir, "readiness.md")}`);
      process.exit(r.open.length ? 3 : 0);
    } else if (cmd === "clarify") {
      const [id, by, ...answer] = rest;
      if (!id || !by || !answer.length) throw new Error('usage: readiness.mjs clarify <job dir> <id> <by> "<answer>"');
      const i = clarify(jobDir, id, by, answer.join(" "));
      console.log(`${i.id}: decided — ${i.answer}`);
    } else throw new Error("usage: readiness.mjs applicable|check|clarify <job dir> …");
  } catch (e) { console.error(`readiness: ${e.message}`); process.exit(1); }
}
