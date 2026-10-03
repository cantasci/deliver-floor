#!/usr/bin/env node
// knowledge.mjs — company standards, project standards and lessons learned, fed to the roles.
//
// Sources, most general first (a later file with the same name overrides an earlier one):
//   1. $DELIVER_KNOWLEDGE or ~/.deliver/knowledge/*.md         company standards (can be a cloned standards repo)
//   2. <repo>/.deliver/knowledge/*.md                          project standards (committed with the code)
//   3. ~/.deliver/knowledge/lessons/<repo name>.md             memory: lessons learned by earlier jobs (dl learn)
//   4. <repo>/graphify-out/GRAPH_REPORT.md                     code knowledge graph (graphify), if present
// A standards file may start with front matter:
//   ---
//   title: API error handling
//   applies_to: [dev, review, backend]      kinds (pm lead dev review qa) and/or role names; default: all
//   stack: [typescript, javascript]         default: any stack
//   ---
// Its "## Must" section (bullets) is copied into every matching role card; the rest is referenced by path.
//
//   node knowledge.mjs list <repo> [kind] [role] [stack,…]   applicable documents (JSON)
//   node knowledge.mjs learn <repo> <job id> <role|all> "<lesson>"
//   node knowledge.mjs sync-md <repo>                        ingest everything into Munder Difflin's Knowledge Graph
import { readFileSync, readdirSync, existsSync, mkdirSync, appendFileSync, statSync } from "node:fs";
import { join, basename, dirname, resolve } from "node:path";
import { homedir } from "node:os";
import { createRequire } from "node:module";
import { pathToFileURL } from "node:url";

export const orgDir = () => process.env.DELIVER_KNOWLEDGE || join(process.env.DELIVER_HOME || join(homedir(), ".deliver"), "knowledge");
export const lessonsFile = (repo) => join(orgDir(), "lessons", `${basename(resolve(repo))}.md`);

function frontMatter(text) {
  const m = text.match(/^---\n([\s\S]*?)\n---\n?/);
  if (!m) return { meta: {}, body: text };
  const meta = {};
  for (const line of m[1].split("\n")) {
    const kv = line.match(/^(\w+):\s*(.*)$/);
    if (!kv) continue;
    let v = kv[2].trim();
    if (v.startsWith("[") && v.endsWith("]")) v = v.slice(1, -1).split(",").map((x) => x.trim().replace(/^["']|["']$/g, "")).filter(Boolean);
    else v = v.replace(/^["']|["']$/g, "");
    meta[kv[1]] = v;
  }
  return { meta, body: text.slice(m[0].length) };
}

const mustOf = (body) => {
  const m = body.match(/^##\s+Must\b.*\n([\s\S]*?)(?=^##\s|(?![\s\S]))/m);
  return m ? m[1].split("\n").filter((l) => /^\s*[-*]\s+/.test(l)).map((l) => l.replace(/^\s*[-*]\s+/, "").trim()) : [];
};

function readDir(dir, origin) {
  if (!existsSync(dir) || !statSync(dir).isDirectory()) return [];
  return readdirSync(dir).filter((f) => f.endsWith(".md") && !f.startsWith("_")).sort().map((f) => {
    const path = join(dir, f);
    const { meta, body } = frontMatter(readFileSync(path, "utf8"));
    const title = meta.title || (body.match(/^#\s+(.+)$/m)?.[1] ?? f.replace(/\.md$/, ""));
    const arr = (v) => (v == null || v === "" ? [] : Array.isArray(v) ? v : [v]);
    return { name: f, path, origin, title, applies_to: arr(meta.applies_to), stack: arr(meta.stack), must: mustOf(body) };
  });
}

export function collect(repo) {
  const byName = new Map();
  for (const d of [...readDir(orgDir(), "company"), ...readDir(join(repo, ".deliver", "knowledge"), "project")]) byName.set(d.name, d);
  const docs = [...byName.values()];
  const lf = lessonsFile(repo);
  const lessons = existsSync(lf)
    ? readFileSync(lf, "utf8").split("\n").map((l) => l.match(/^- \[(.+?)\] \((.+?)\) (.+)$/)).filter(Boolean).map((m) => ({ at: m[1], role: m[2], text: m[3] }))
    : [];
  const graph = existsSync(join(repo, "graphify-out", "GRAPH_REPORT.md")) ? join(repo, "graphify-out", "GRAPH_REPORT.md") : null;
  return { docs, lessons, lessonsFile: lf, graph };
}

export function applicable(repo, { kind, role, stack = [] } = {}) {
  const k = collect(repo);
  const matchRole = (a) => a.length === 0 || a.includes("all") || a.includes(kind) || a.includes(role);
  const matchStack = (s) => s.length === 0 || s.some((x) => stack.includes(x));
  return {
    docs: k.docs.filter((d) => matchRole(d.applies_to) && matchStack(d.stack)),
    lessons: k.lessons.filter((l) => l.role === "all" || l.role === role || l.role === kind).slice(-15),
    lessonsFile: k.lessonsFile,
    graph: k.graph,
  };
}

/** Markdown section for a role card. */
export function section(repo, ctx) {
  const a = applicable(repo, ctx);
  const out = ["## Company standards and memory", ""];
  if (!a.docs.length && !a.lessons.length && !a.graph) {
    out.push("No standards are registered for this role yet (see docs/08-knowledge.md to add them).", "");
    return out.join("\n");
  }
  for (const d of a.docs) {
    out.push(`### ${d.title} (${d.origin}: \`${d.path}\`)`);
    if (d.must.length) out.push("", ...d.must.map((m) => `- MUST: ${m}`));
    out.push("", `Read the whole document before work that touches this topic.`, "");
  }
  if (a.lessons.length) {
    out.push("### Lessons from earlier jobs (memory)", "", ...a.lessons.map((l) => `- ${l.text} _(${l.at})_`), "");
  }
  if (a.graph) out.push("### Code knowledge graph", "", `A graphify report of this codebase exists: \`${a.graph}\` (graph.json beside it). Use it to find modules, callers and dependencies before grepping.`, "");
  if (process.env.KG_CLI && process.env.KG_ROOT)
    out.push("### Munder Difflin knowledge graph", "", `These standards are also in the floor's Knowledge Graph: \`node "$KG_CLI" search "<topic>"\`.`, "");
  return out.join("\n");
}

export function learn(repo, job, role, text) {
  const lf = lessonsFile(repo);
  mkdirSync(dirname(lf), { recursive: true });
  if (!existsSync(lf)) appendFileSync(lf, `# Lessons — ${basename(resolve(repo))}\n\nLearned by /deliver jobs. Promote a lesson to a standard by moving it into a knowledge file's "## Must" section.\n\n`);
  const line = `- [${new Date().toISOString().slice(0, 10)} ${job}] (${role}) ${text.replace(/\s+/g, " ").trim()}\n`;
  appendFileSync(lf, line);
  return lf;
}

/** Ingest standards + lessons into Munder Difflin's Knowledge Graph (needs KG_CLI + KG_ROOT, set on the floor). */
export function syncMunder(repo) {
  const cli = process.env.KG_CLI, root = process.env.KG_ROOT;
  if (!cli || !root) throw new Error("KG_CLI / KG_ROOT are not set — run this from an agent terminal in Munder Difflin with the Knowledge Graph enabled (Settings → Knowledge Graph)");
  const core = createRequire(import.meta.url)(join(dirname(cli), "kg-core.cjs"));
  const k = collect(repo);
  const items = [...k.docs.map((d) => ({ path: d.path, title: d.title, tags: ["deliver", "standards", d.origin, ...d.applies_to, ...d.stack] })),
    ...(existsSync(k.lessonsFile) ? [{ path: k.lessonsFile, title: `Lessons — ${basename(resolve(repo))}`, tags: ["deliver", "lessons"] }] : [])];
  let replaced = 0;
  for (const it of items) {
    const source = `deliver:${it.path}`;
    for (const m of core.list(root)) if (m.source === source && core.removeDoc(root, m.id)) replaced++;
    core.ingest(root, { srcPath: it.path, title: it.title, tags: it.tags, source });
  }
  return { ingested: items.length, replaced };
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [cmd, repo = ".", ...rest] = process.argv.slice(2);
  if (cmd === "list") {
    const [kind, role, stack] = rest;
    console.log(JSON.stringify(applicable(repo, { kind, role, stack: (stack ?? "").split(",").filter(Boolean) }), null, 2));
  } else if (cmd === "learn") {
    const [job, role, text] = rest;
    if (!job || !role || !text) { console.error('usage: knowledge.mjs learn <repo> <job> <role|all> "<lesson>"'); process.exit(2); }
    console.log(`learned → ${learn(repo, job, role, text)}`);
  } else if (cmd === "sync-md") {
    try { const r = syncMunder(repo); console.log(`Munder Difflin knowledge graph: ${r.ingested} document(s) ingested (${r.replaced} older version(s) replaced)`); }
    catch (e) { console.error(`knowledge: ${e.message}`); process.exit(1); }
  } else { console.error("usage: knowledge.mjs list|learn|sync-md <repo> …"); process.exit(2); }
}
