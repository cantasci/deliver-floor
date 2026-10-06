#!/usr/bin/env node
// knowledge.mjs — company standards, project standards and lessons learned, fed to the roles.
//
// The source of truth is git: each project keeps its own standards and lessons, and an optional shared knowledge repo
// (settings.knowledge.repo — cloned by dl new) holds what is common to several projects. Lessons and new standards reach
// either one only through a PR a human merges. Sources, most general first (a later file with the same name wins):
//   1. <shared clone>/standards/*.md                           shared standards (settings.knowledge.repo)
//   2. $DELIVER_KNOWLEDGE or ~/.deliver/knowledge/*.md         local company standards (older setup; still read)
//   3. <repo>/.deliver/knowledge/*.md                          project standards (committed with the code)
//   4. lessons: <repo>/.deliver/knowledge/lessons.md (accepted, merged with an earlier job's PR), <shared>/lessons.md,
//      the current job's proposed lessons (.work/<job>/lessons.json), and the older ~/.deliver/knowledge/lessons/<repo>.md
//   5. <repo>/graphify-out/GRAPH_REPORT.md                     code knowledge graph (graphify), if present
// A standards file may start with front matter:
//   ---
//   title: API error handling
//   applies_to: [dev, review, backend]      kinds (ba lead dev review qa) and/or role names; default: all
//   stack: [typescript, javascript]         default: any stack
//   ---
// Its "## Must" section (bullets) is copied into every matching role card; the rest is referenced by path.
//
//   node knowledge.mjs list <repo> [kind] [role] [stack,…]   applicable documents (JSON)
//   node knowledge.mjs learn <repo> <job dir> <json: {role, text, topic, evidence[], scope}>   propose a lesson (this job)
//   node knowledge.mjs promote <repo> <job dir> <json: {topic, rule, applies_to[], scope}>     propose a standard (this job)
//   node knowledge.mjs publish <repo> <job dir> <dir to write into> <project|shared>          write what this job proposed
//   node knowledge.mjs sync-md <repo>                        ingest everything into Munder Difflin's Knowledge Graph
import { readFileSync, readdirSync, existsSync, mkdirSync, appendFileSync, statSync, writeFileSync } from "node:fs";
import { join, basename, dirname, resolve } from "node:path";
import { homedir } from "node:os";
import { createRequire } from "node:module";
import { pathToFileURL } from "node:url";

export const orgDir = () => process.env.DELIVER_KNOWLEDGE || join(process.env.DELIVER_HOME || join(homedir(), ".deliver"), "knowledge");
export const lessonsFile = (repo) => join(orgDir(), "lessons", `${basename(resolve(repo))}.md`); // older, per machine
export const projectLessons = (repo) => join(repo, ".deliver", "knowledge", "lessons.md");
export const sharedDir = () => process.env.DELIVER_SHARED_KNOWLEDGE || "";
const readJson = (p, d) => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return d; } };

// A lesson in lessons.md — structured, so it can be counted by topic and traced to what happened:
//   ## <date> · <job> · <role> · topic: <topic>
//   <the lesson, one paragraph>
//   - evidence: <what happened> (one line each)
//   - project: <name>                                     (in the shared lessons file)
export function parseLessons(text, origin) {
  const out = [];
  for (const m of text.matchAll(/^## (\S+) · (\S+) · (\S+) · topic: (\S+)\n([\s\S]*?)(?=^## |(?![\s\S]))/gm)) {
    const lines = m[5].trim().split("\n");
    out.push({ at: m[1], job: m[2], role: m[3], topic: m[4], origin,
      text: lines.filter((l) => !/^- \w+:/.test(l)).join(" ").trim(),
      evidence: lines.filter((l) => l.startsWith("- evidence: ")).map((l) => l.slice(12)),
      project: lines.find((l) => l.startsWith("- project: "))?.slice(11) ?? "" });
  }
  // the older one-line form: - [date job] (role) text
  for (const m of text.matchAll(/^- \[(.+?)\] \((.+?)\) (.+)$/gm)) out.push({ at: m[1], job: "", role: m[2], topic: "", text: m[3], evidence: [], origin });
  return out;
}
export function formatLesson(l, project) {
  return [`## ${l.at} · ${l.job} · ${l.role} · topic: ${l.topic}`, l.text, ...l.evidence.map((e) => `- evidence: ${e.replace(/\s+/g, " ")}`),
    ...(project ? [`- project: ${project}`] : []), ""].join("\n");
}
const fileLessons = (p, origin) => (existsSync(p) ? parseLessons(readFileSync(p, "utf8"), origin) : []);
export function allLessons(repo, jobDir) {
  return [...fileLessons(lessonsFile(repo), "local (older)"), ...(sharedDir() ? fileLessons(join(sharedDir(), "lessons.md"), "shared") : []),
    ...fileLessons(projectLessons(repo), "project"),
    ...(jobDir ? readJson(join(jobDir, "lessons.json"), []).map((l) => ({ ...l, origin: `proposed by this job (${l.scope})` })) : [])];
}
/** distinct jobs that recorded a lesson on this topic (accepted, shared, and this job's proposals) */
export const topicJobs = (repo, jobDir, topic) => [...new Set(allLessons(repo, jobDir).filter((l) => l.topic === topic).map((l) => l.job || l.at))];
const hasStandard = (repo, topic) => collect(repo).docs.some((d) => d.name === `${topic}.md` || (d.topics ?? []).includes(topic));

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
  return readdirSync(dir).filter((f) => f.endsWith(".md") && !f.startsWith("_") && f !== "lessons.md" && f !== "README.md").sort().map((f) => {
    const path = join(dir, f);
    const { meta, body } = frontMatter(readFileSync(path, "utf8"));
    const title = meta.title || (body.match(/^#\s+(.+)$/m)?.[1] ?? f.replace(/\.md$/, ""));
    const arr = (v) => (v == null || v === "" ? [] : Array.isArray(v) ? v : [v]);
    return { name: f, path, origin, title, applies_to: arr(meta.applies_to), stack: arr(meta.stack), topics: arr(meta.topics), must: mustOf(body) };
  });
}

export function collect(repo, jobDir) {
  const byName = new Map();
  for (const d of [...(sharedDir() ? readDir(join(sharedDir(), "standards"), "shared") : []), ...readDir(orgDir(), "company"),
    ...readDir(join(repo, ".deliver", "knowledge"), "project")]) byName.set(d.name, d);
  const docs = [...byName.values()];
  const graph = existsSync(join(repo, "graphify-out", "GRAPH_REPORT.md")) ? join(repo, "graphify-out", "GRAPH_REPORT.md") : null;
  return { docs, lessons: allLessons(repo, jobDir), lessonsFile: projectLessons(repo), graph };
}

export function applicable(repo, { kind, role, stack = [], jobDir } = {}) {
  const k = collect(repo, jobDir);
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
    out.push("### Lessons from earlier jobs (memory)", "", ...a.lessons.map((l) => `- ${l.text} _(${l.at}${l.topic ? `, ${l.topic}` : ""}; ${l.origin})_`), "");
  }
  if (a.graph) out.push("### Code knowledge graph", "", `A graphify report of this codebase exists: \`${a.graph}\` (graph.json beside it). Use it to find modules, callers and dependencies before grepping.`, "");
  if (process.env.KG_CLI && process.env.KG_ROOT)
    out.push("### Munder Difflin knowledge graph", "", `These standards are also in the floor's Knowledge Graph: \`node "$KG_CLI" search "<topic>"\`.`, "");
  return out.join("\n");
}

// A lesson is proposed by the job that learned it, with what happened (evidence) and a topic; it reaches the project (and,
// for scope "shared", the shared repo) only with that job's PR. Scope "kit": a defect in the flow itself — reported for the
// deliver kit in the PR, never stored as a rule for the project.
export function learn(repo, jobDir, l) {
  const job = readJson(join(jobDir, "job.json"), {});
  const lesson = { at: new Date().toISOString().slice(0, 10), job: job.id ?? basename(jobDir), role: l.role, topic: l.topic,
    text: String(l.text).replace(/\s+/g, " ").trim(), evidence: l.evidence ?? [], scope: l.scope ?? "project", stack: job.stack ?? [] };
  const f = join(jobDir, "lessons.json"); const all = readJson(f, []); all.push(lesson); writeFileSync(f, JSON.stringify(all, null, 2) + "\n");
  // On the Munder Difflin floor the lesson also goes into Michael's own memory (mined into the floor's MemPalace).
  const god = process.env.HIVE_ROOT && join(process.env.HIVE_ROOT, "agents", "god");
  if (god && existsSync(god)) appendFileSync(join(god, "memory.md"), `- /deliver lesson for ${basename(resolve(repo))} (${lesson.role}, ${lesson.topic}): ${lesson.text}\n`);
  const jobs = lesson.scope === "kit" ? [] : topicJobs(repo, jobDir, lesson.topic);
  return { lesson, jobs: jobs.length, promote: jobs.length >= 3 && !hasStandard(repo, lesson.topic) };
}

export function promote(repo, jobDir, p) {
  const f = join(jobDir, "promotions.json"); const all = readJson(f, []);
  all.push({ topic: p.topic, rule: p.rule, applies_to: p.applies_to ?? [], scope: p.scope ?? "project", at: new Date().toISOString().slice(0, 10) });
  writeFileSync(f, JSON.stringify(all, null, 2) + "\n");
  return { topic: p.topic, jobs: topicJobs(repo, jobDir, p.topic).length };
}

/** Write this job's proposals of one scope into a checkout (the job's integration worktree, or the shared clone). */
export function publish(repo, jobDir, into, scope) {
  const job = readJson(join(jobDir, "job.json"), {}), project = basename(resolve(repo)), written = [];
  const lessons = readJson(join(jobDir, "lessons.json"), []).filter((l) => l.scope === scope);
  const proms = readJson(join(jobDir, "promotions.json"), []).filter((p) => p.scope === scope);
  const dir = scope === "shared" ? into : join(into, ".deliver", "knowledge");
  if (lessons.length) {
    const lf = join(dir, "lessons.md"); mkdirSync(dirname(lf), { recursive: true });
    if (!existsSync(lf)) writeFileSync(lf, `# Lessons${scope === "shared" ? "" : ` — ${project}`}\n\nRecorded by /deliver jobs with what happened; accepted by merging the job's PR. A topic seen in three jobs becomes a standard (a "## Must" rule).\n\n`);
    appendFileSync(lf, lessons.map((l) => formatLesson(l, scope === "shared" ? project : "")).join("\n") + "\n"); written.push(lf);
  }
  for (const p of proms) {
    const sf = join(scope === "shared" ? join(into, "standards") : dir, `${p.topic}.md`); mkdirSync(dirname(sf), { recursive: true });
    const ev = allLessons(repo, jobDir).filter((l) => l.topic === p.topic).map((l) => `- ${l.at} ${l.job || ""} (${l.role}): ${l.text}`);
    writeFileSync(sf, `---\ntitle: ${p.topic}\napplies_to: [${p.applies_to.join(", ")}]\nstack: [${(job.stack ?? []).join(", ")}]\ntopics: [${p.topic}]\n---\n# ${p.topic}\n\n## Must\n- ${p.rule}\n\n## Background\nPromoted by ${job.id} from the lessons on this topic:\n\n${ev.join("\n")}\n`);
    written.push(sf);
  }
  return written;
}

/** Ingest standards + lessons into Munder Difflin's Knowledge Graph (needs KG_CLI + KG_ROOT, set on the floor). */
export function syncMunder(repo) {
  const cli = process.env.KG_CLI, root = process.env.KG_ROOT;
  if (!cli || !root) throw new Error("KG_CLI / KG_ROOT are not set — run this from an agent terminal in Munder Difflin with the Knowledge Graph enabled (Settings → Knowledge Graph)");
  const core = createRequire(import.meta.url)(join(dirname(cli), "kg-core.cjs"));
  const k = collect(repo);
  const items = [...k.docs.map((d) => ({ path: d.path, title: d.title, tags: ["deliver", "standards", d.origin, ...d.applies_to, ...d.stack] })),
    ...[[projectLessons(repo), `Lessons — ${basename(resolve(repo))}`, "project"], [sharedDir() && join(sharedDir(), "lessons.md"), "Lessons — shared", "shared"],
      [lessonsFile(repo), `Lessons — ${basename(resolve(repo))} (older, this machine)`, "local"]]
      .filter(([f]) => f && existsSync(f)).map(([path, title, o]) => ({ path, title, tags: ["deliver", "lessons", o] }))];
  let replaced = 0;
  for (const it of items) {
    const source = `deliver:${it.path}`;
    for (const m of core.list(root)) if (m.source === source && core.removeDoc(root, m.id)) replaced++;
    core.ingest(root, { srcPath: it.path, title: it.title, tags: it.tags, source });
  }
  return { ingested: items.length, replaced };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [cmd, repo = ".", ...rest] = process.argv.slice(2);
  if (cmd === "list") {
    const [kind, role, stack] = rest;
    console.log(JSON.stringify(applicable(repo, { kind, role, stack: (stack ?? "").split(",").filter(Boolean) }), null, 2));
  } else if (cmd === "learn") {
    const [jobDir, json] = rest; const r = learn(repo, jobDir, JSON.parse(json));
    console.log(JSON.stringify({ topic: r.lesson.topic, scope: r.lesson.scope, jobs: r.jobs, promote: r.promote }));
  } else if (cmd === "promote") {
    const [jobDir, json] = rest; console.log(JSON.stringify(promote(repo, jobDir, JSON.parse(json))));
  } else if (cmd === "publish") {
    const [jobDir, into, scope] = rest; for (const f of publish(repo, jobDir, into, scope)) console.log(f);
  } else if (cmd === "topics") {
    const [jobDir] = rest; const by = {};
    for (const l of allLessons(repo, jobDir)) if (l.topic) (by[l.topic] ??= new Set()).add(l.job || l.at);
    console.log(JSON.stringify(Object.fromEntries(Object.entries(by).map(([t, j]) => [t, { jobs: j.size, standard: hasStandard(repo, t) }]))));
  } else if (cmd === "sync-md") {
    try { const r = syncMunder(repo); console.log(`Munder Difflin knowledge graph: ${r.ingested} document(s) ingested (${r.replaced} older version(s) replaced)`); }
    catch (e) { console.error(`knowledge: ${e.message}`); process.exit(1); }
  } else { console.error("usage: knowledge.mjs list|learn|sync-md <repo> …"); process.exit(2); }
}
