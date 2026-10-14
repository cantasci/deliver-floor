#!/usr/bin/env node
// bmad.mjs — shaping with the BMad Method (settings.upstream.engine: "bmad"), the only file that knows BMad.
//
// BMad is fed, not steered. Code builds every prompt it gets: the whole request, the repo, the standards, the project's
// architecture and our delivery checklist (information, not instructions). BMad chooses its own path (bmad-help), writes its
// artifacts headless and verifies them itself (update with the decisions taken, then bmad-review). Nothing it decides binds
// on its own: every decision, assumption, question, conflict and review finding it reports goes into the shaping ledger,
// and Michael closes each WITH the human, on what BMad said — his proposal quotes a BMad artifact, never the request.
// Seen in the spike: bmad-spec returned "complete" with ten decisions of its own, three of them against what the business
// had decided (a 22-step scale, "unavailable" instead of a RangeError, an indicator selector). Its status is not trusted:
// the ledger is read from its .memlog.md tags and its JSON, by code.
//
// Files (in the job dir): bmad/inputs/ (what BMad is given) · bmad/out/ (BMad's output folder) · bmad/runs/<n>-<step>.*
// (prompt, raw result, stderr) · shaping.json (plan, runs, ledger, reviews, batches).
//
//   node bmad.mjs needs <job dir>                              upstream.engine "auto": does the request need shaping? (JSON; exit 0 = yes)
//   node bmad.mjs init <job dir> <version>                     shaping.json + the input package
//   node bmad.mjs installed <job dir> <version>                record the install (dl shape install ran npx)
//   node bmad.mjs status <job dir> [rounds] [reask]            the next step (JSON): install | help | decide | update | create | review | done
//   node bmad.mjs start <job dir> [rounds] [reask]             prepare the next BMad run: prompt file + snapshot (JSON)
//   node bmad.mjs finish <job dir> <rc> <seconds>              read the run's result, record it, extract the ledger (JSON)
//   node bmad.mjs abandon <job dir>                            forget a run that never finished
//   node bmad.mjs ledger <job dir> [open]                      the ledger (text)
//   node bmad.mjs propose <job dir> <id> "<text>" <file> "<quote>"     Michael's proposal, standing on a BMad artifact
//   node bmad.mjs decide <job dir> <id> "<text>" <file> "<quote>" "<rationale>"   Michael alone — only what needs no human
//   node bmad.mjs answer <job dir> <id|proposals> <who> "<answer>"     the human's decision (dl clarify)
//   node bmad.mjs gap <job dir> "<readiness id>" "<what is missing>"   the readiness review found BMad's output silent on it
//   node bmad.mjs questions <job dir>                          QUESTIONS.md for the human
//   node bmad.mjs manifest <job dir>                           sha256 of everything shaping produced (the freeze)
//   node bmad.mjs ids <job dir>                                the capability / requirement ids the plan must trace (JSON)
//   node bmad.mjs artifacts <job dir>                          the current artifacts, for the BA (text)
//   node bmad.mjs standards <job dir>                          the architecture's AD-n rules → standards/bmad-architecture.md
//   node bmad.mjs report <job dir>                             the PR section (markdown)
import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, statSync, copyFileSync } from "node:fs";
import { join, relative, dirname } from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath, pathToFileURL } from "node:url";
import { collect } from "./knowledge.mjs";

const SKILL_DIR = join(dirname(fileURLToPath(import.meta.url)), "..");
const read = (p) => { try { return readFileSync(p, "utf8"); } catch { return ""; } };
const readJson = (p, d) => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return d; } };
const writeJson = (p, v) => writeFileSync(p, JSON.stringify(v, null, 2) + "\n");
const now = () => new Date().toISOString().replace(/\.\d+Z$/, "Z");
const sha = (t) => createHash("sha256").update(t).digest("hex");
const norm = (t) => String(t).toLowerCase().replace(/[‘’]/g, "'").replace(/[“”]/g, '"').replace(/[`*_]/g, "").replace(/\s+/g, " ").trim();

export const dirs = (jobDir) => ({ bmad: join(jobDir, "bmad"), inputs: join(jobDir, "bmad", "inputs"), out: join(jobDir, "bmad", "out"), runs: join(jobDir, "bmad", "runs") });
const shapingFile = (jobDir) => join(jobDir, "shaping.json");
export const loadShaping = (jobDir) => readJson(shapingFile(jobDir), null);
const save = (jobDir, s) => writeJson(shapingFile(jobDir), s);
const job = (jobDir) => readJson(join(jobDir, "job.json"), {});
const repoOf = (jobDir) => job(jobDir).repo ?? dirname(dirname(jobDir));
const rel = (jobDir, p) => relative(repoOf(jobDir), p);

/** every file under dir (recursive) → { path: sha256 } */
function snapshot(dir) {
  const out = {};
  const walk = (d) => {
    if (!existsSync(d)) return;
    for (const f of readdirSync(d)) {
      const p = join(d, f);
      if (statSync(p).isDirectory()) walk(p); else out[p] = sha(readFileSync(p));
    }
  };
  walk(dir);
  return out;
}

// ── auto: shape only what is not a specification yet ───────────────────────────────────────────────────────────────────
// Measured live: on a request that named its requirements, acceptance criteria and contract, shaping gave the same product
// for 30 % more (runs 62/64); on a one-paragraph idea it caught decisions the readiness review alone missed (runs 65/66).
// A request that states at least two of the three is a specification; anything less is shaped. Code decides, by these signals.
export function needsShaping(jobDir) {
  const t = String(job(jobDir).request ?? "");
  const signals = {
    requirements: /\b(REQ|FR|NFR|US|UC)-\d+/.test(t) || /^\s*\|[^\n]*\b(req(uirement)?s?\b|req id)[^\n]*\|/im.test(t),
    acceptance: /\bgiven\b[^\n]*\bwhen\b|acceptance criteria|\bAC-\d+/i.test(t),
    contract: /^#+\s*(contract|api|interface)\b/im.test(t) || /`[A-Za-z_][\w.]*\([^`)]*\)`/.test(t),
  };
  const name = { requirements: "requirement ids", acceptance: "acceptance criteria", contract: "a contract" };
  const list = (ks, and) => ks.map((k) => name[k]).join(ks.length > 2 ? ", " : ` ${and} `).replace(/, ([^,]+)$/, `, ${and} $1`);
  const have = Object.keys(signals).filter((k) => signals[k]), miss = Object.keys(signals).filter((k) => !signals[k]);
  const shape = have.length < 2;
  return { shape, signals, reason: shape
    ? `${have.length ? `the request states ${list(have, "and")} but no ${list(miss, "or")}` : "the request states no requirement ids, acceptance criteria or contract"} — BMad shapes it first`
    : `the request states ${list(have, "and")}${miss.length ? ` (no ${list(miss, "or")})` : ""} — a specification already, not shaped` };
}

// ── the input package ───────────────────────────────────────────────────────────────────────────────────────────────────
export function init(jobDir, version) {
  const d = dirs(jobDir);
  for (const x of [d.inputs, d.out, d.runs]) mkdirSync(x, { recursive: true });
  const j = job(jobDir);
  writeFileSync(join(d.inputs, "request.md"), `# ${j.title ?? "Request"}\n\n${j.request ?? ""}\n`);
  copyFileSync(join(SKILL_DIR, "readiness.yaml"), join(d.inputs, "delivery-checklist.yaml"));
  if (!loadShaping(jobDir)) save(jobDir, { engine: "bmad", version, installed: null, plan: null, runs: [], ledger: [], reviews: [], batches: [] });
  return loadShaping(jobDir);
}

function inputPackage(jobDir) {
  const repo = repoOf(jobDir), d = dirs(jobDir), j = job(jobDir);
  const arch = join(repo, ".deliver", "knowledge", "architecture.md");
  const standards = collect(repo).docs.filter((x) => x.name !== "architecture.md").map((x) => x.path.startsWith(repo) ? relative(repo, x.path) : x.path);
  const code = (j.stack ?? []).length > 0;
  return [
    `- The request, all of it: ${rel(jobDir, join(d.inputs, "request.md"))}` + (/^Requirements:\s*\S+/m.test(j.request ?? "") ? " (it names its requirements file; read that too)" : ""),
    `- The repo: ${repo}${code ? ` — it has code (${(j.stack ?? []).join(", ")})` : " — no code yet"}`,
    existsSync(arch) ? `- The project's architecture, confirmed by the team (a standard): ${relative(repo, arch)}` : null,
    standards.length ? `- Company and project standards (they bind where they state something): ${standards.join(", ")}` : null,
    `- For your information — what our delivery team needs to know before it can cut tasks (a checklist, not instructions; items that do not apply to this request do not apply): ${rel(jobDir, join(d.inputs, "delivery-checklist.yaml"))}`,
  ].filter(Boolean).join("\n");
}

const HEADLESS = "headless: true — there is no interactive user: do not ask, do not greet, do not offer to run anything. Record what needs a human decision in open_questions[] and what you inferred in assumptions[].";
// what our own team does after shaping — bmad-help may name them, they are not run here
const OURS = /^bmad-(create-epics-and-stories|sprint-planning|build|build-auto|code-review|review|qa-generate-e2e-tests|retrospective|correct-course|walkthrough|help|party-mode|customize|advanced-elicitation)$/;

// ── the next step ───────────────────────────────────────────────────────────────────────────────────────────────────────
const usable = (r) => r.status && r.status !== "invalid" && r.status !== "blocked";
const created = (s) => [...new Set(s.runs.filter((r) => r.step === "create" && usable(r)).map((r) => r.skill))];
const humanOpen = (s) => s.ledger.filter((i) => i.status === "open" && i.needs_human);
const pmOpen = (s) => s.ledger.filter((i) => i.status === "open" && !i.needs_human);
const unsent = (s) => s.ledger.filter((i) => i.status === "decided" && i.batch == null);

// How often the decisions go back to the same artifacts before BMad has made something new or reviewed: seen live on an idea
// (run 66), each update raised a question about the decisions just applied, the same one four times, and shaping never ended.
// Past the limit, what is decided binds through the ledger (source "shape: B-n") and is listed in the PR as such.
const chainLength = (s) => {
  const anchor = Math.max(0, ...s.runs.filter((r) => (r.step === "create" || r.step === "review") && usable(r)).map((r) => r.n));
  return s.batches.filter((b) => (s.runs.find((r) => r.step === "update" && r.batch === b.n)?.n ?? Infinity) > anchor).length;
};
export const ledgerOnly = (s) => unsent(s).filter((i) => i.kind !== "gap");

export function status(jobDir, rounds = 2, reask = 2) {
  const s = loadShaping(jobDir);
  if (!s) return { next: "init" };
  if (s.running) return { next: "running", run: s.running };
  if (!s.installed) return { next: "install" };
  const failed = (step, skill) => s.runs.filter((r) => r.step === step && (r.skill ?? null) === (skill ?? null) && (r.status === "invalid" || r.status === "blocked")).length;
  if (!s.plan) return { next: "help", attempts: failed("help") };
  const open = s.ledger.filter((i) => i.status === "open");
  if (open.length) return { next: "decide", human: humanOpen(s).map((i) => i.id), unproposed: humanOpen(s).filter((i) => !i.proposal).map((i) => i.id), pm: pmOpen(s).map((i) => i.id) };
  // the decisions go back to BMad before anything new is made: one update per artifact it has made, in its order
  const batch = s.batches.find((b) => !b.done);
  if (batch) {
    const todo = batch.skills.find((k) => !s.runs.some((r) => r.step === "update" && r.skill === k && r.batch === batch.n && usable(r)));
    if (todo) return { next: "update", skill: todo, batch: batch.n, attempts: s.runs.filter((r) => r.step === "update" && r.skill === todo && r.batch === batch.n && !usable(r)).length };
  }
  if (unsent(s).length && created(s).length && (chainLength(s) < reask || unsent(s).some((i) => i.kind === "gap")))
    return { next: "update", skill: created(s)[0], batch: (s.batches.at(-1)?.n ?? 0) + 1, newBatch: true, attempts: 0 };
  const todo = s.plan.sequence.map((x) => x.skill).find((k) => !created(s).includes(k));
  if (todo) return { next: "create", skill: todo, attempts: failed("create", todo) };
  const lastChange = Math.max(0, ...s.runs.filter((r) => (r.step === "create" || r.step === "update") && usable(r)).map((r) => r.n));
  const lastReview = Math.max(0, ...s.runs.filter((r) => r.step === "review" && usable(r)).map((r) => r.n));
  if (rounds > 0 && s.reviews.length < rounds && lastChange > lastReview) return { next: "review", round: s.reviews.length + 1, attempts: failed("review") };
  return { next: "done", reviews: s.reviews.map((r) => r.verdict), artifacts: created(s) };
}

// ── prompts (code writes them; Michael never does) ──────────────────────────────────────────────────────────────────────
const latestFiles = (s, skill) => [...new Set(s.runs.filter((r) => r.skill === skill && (r.step === "create" || r.step === "update") && usable(r)).flatMap((r) => r.files))]
  .filter((f) => !/\.memlog\.md$/.test(f));
const decisionLine = (i) => `- ${i.id} (${i.kind}${i.skill ? `, ${i.skill}` : ""}) — BMad said: "${i.text}"\n  decided ${/^human/.test(i.decision.by) ? "by the business" : "by the PM"}: ${i.decision.text}`;

function promptFor(jobDir, st) {
  const s = loadShaping(jobDir), d = dirs(jobDir), j = job(jobDir);
  const out = rel(jobDir, d.out), slug = String(j.id ?? "job").replace(/^JOB-\d+-\d+-/, "").slice(0, 40);
  const decided = s.ledger.filter((i) => i.status === "decided");
  if (st.next === "help") return `Use the bmad-help skill. ${HEADLESS}

${inputPackage(jobDir)}
Nothing of BMad has run for this request yet.

Question: to get from this request to an implementation-ready specification (requirements and architecture that a delivery team can cut into tasks), which BMad skills must run, in which order, and which are optional or unnecessary for this request? Our own team cuts the tasks and implements, so stop before epics/stories, sprint planning and build; a review of the artifacts follows your sequence, do not list it.

End with JSON only:
{"sequence":[{"skill":"bmad-…","intent":"create","why":"…","inputs":["…"]}],"skipped":[{"skill":"…","why":"…"}]}`;
  if (st.next === "create") {
    const step = s.plan.sequence.find((x) => x.skill === st.skill);
    const before = created(s).map((k) => `- ${k}: ${latestFiles(s, k).join(", ")}`).join("\n");
    return `Use the ${st.skill} skill. ${HEADLESS}

intent: create
slug: ${slug}
Write your artifacts under ${out}/ (your output folder).
Inputs:
${inputPackage(jobDir)}
${before ? `Artifacts BMad already made for this request (settled — build on them):\n${before}\n` : ""}${decided.length ? `Decisions already taken on what BMad said (binding):\n${decided.map(decisionLine).join("\n")}\n` : ""}
This step was chosen by bmad-help, which said: ${JSON.stringify(step)}

End with the JSON your headless contract defines (status, the artifact paths, assumptions[], open_questions[]).`;
  }
  if (st.next === "update") {
    const items = st.newBatch ? unsent(s) : s.ledger.filter((i) => i.batch === st.batch);
    return `Use the ${st.skill} skill. ${HEADLESS}

intent: update
Artifacts to update: ${latestFiles(s, st.skill).join(", ")}
Change signal — decisions taken on what BMad said (by the business with the PM). Apply those that concern these artifacts as stated, log each to the memlog, and list every conflict with a prior decision in conflicts_with_prior_decisions[]. A decision that concerns only another artifact leaves this one as it is.
${items.map(decisionLine).join("\n")}

End with the JSON your headless contract defines for update (status, the artifact paths, conflicts_with_prior_decisions[], open_questions[]).`;
  }
  if (st.next === "review") return `skill:bmad-review — review these artifacts before our delivery team cuts tasks from them. ${HEADLESS}
Report findings in your canonical shape and end with a JSON summary:
{"findings":[{"lens":"…","severity":"critical|high|medium|low","artifact":"…","finding":"…","needs_human":true|false}],"verdict":"ready|ready-with-concerns|not-ready"}
needs_human: true when settling it changes what is built (scope, behaviour, a contract, a risk accepted); false for wording, consistency and test detail.

Artifacts:
${created(s).flatMap((k) => latestFiles(s, k)).map((f) => `- ${f}`).join("\n")}
Sources they were built from:
${inputPackage(jobDir)}
${decided.length ? `Decisions taken so far (by the business with the PM) — check the artifacts against them too:\n${decided.map(decisionLine).join("\n")}\n` : ""}`;
  throw new Error(`no BMad run for step ${st.next}`);
}

const memlogs = (dir) => Object.fromEntries(Object.keys(snapshot(dir)).filter((p) => p.endsWith(".memlog.md")).map((p) => [p, read(p)]));

export function start(jobDir, rounds = 2, reask = 2) {
  const s = loadShaping(jobDir), st = status(jobDir, rounds, reask), d = dirs(jobDir);
  if (!["help", "create", "update", "review"].includes(st.next)) throw new Error(`nothing for BMad to run now (next: ${st.next})`);
  if ((st.attempts ?? 0) >= 3) throw new Error(`BMad's ${st.next}${st.skill ? ` ${st.skill}` : ""} gave no usable result 3 times — tell the human (the runs: ${rel(jobDir, d.runs)})`);
  const n = s.runs.length + 1, name = `${String(n).padStart(2, "0")}-${st.next}${st.skill ? `-${st.skill.replace(/^bmad-/, "")}` : ""}`;
  const prompt = promptFor(jobDir, st);
  if (st.next === "update" && st.newBatch) {   // the decisions sent now are one batch; every artifact BMad made gets them
    const items = unsent(s);
    for (const i of items) i.batch = st.batch;
    s.batches.push({ n: st.batch, items: items.map((i) => i.id), skills: created(s), done: false });
  }
  writeFileSync(join(d.runs, `${name}.prompt.md`), prompt);
  writeJson(join(d.runs, `${name}.before.json`), { files: snapshot(d.out), memlogs: memlogs(d.out) });
  s.running = { n, name, step: st.next, skill: st.skill ?? null, batch: st.batch ?? null, round: st.round ?? null, at: now() };
  save(jobDir, s);
  return { n, name, step: st.next, skill: st.skill ?? null, prompt: join(d.runs, `${name}.prompt.md`), log: join(d.runs, `${name}.json`) };
}

// ── reading what BMad returned ──────────────────────────────────────────────────────────────────────────────────────────
/** the last JSON object in a session's result text: a ```json block, else bare JSON, else the last parseable {…} */
export function lastJson(text) {
  const t = String(text ?? "");
  for (const b of [...t.matchAll(/```json\s*\n([\s\S]*?)```/g)].map((m) => m[1]).reverse()) { try { return JSON.parse(b); } catch { /* next */ } }
  try { return JSON.parse(t.trim()); } catch { /* not bare JSON */ }
  for (let i = t.lastIndexOf("{"); i >= 0; i = i > 0 ? t.lastIndexOf("{", i - 1) : -1) {
    try { return JSON.parse(t.slice(i)); } catch { /* further back */ }
  }
  return null;
}
const MEMTAG = /^\s*-\s*\((decision|assumption|question)\)\s*(.+)$/;
// A question BMad asks about something already decided: the ids it names (it often cites them), or the same words.
const words = (t) => new Set(norm(t).split(/[^a-z0-9']+/).filter((w) => w.length > 3));
function repeatOf(s, text) {
  const decided = s.ledger.filter((i) => i.status === "decided" && i.kind !== "gap");
  const named = [...String(text).matchAll(/\bB-(\d+)\b/g)].map((m) => `B-${m[1]}`).filter((id) => decided.some((i) => i.id === id));
  const w = words(text);
  const alike = decided.filter((i) => (i.kind === "question" || i.kind === "finding") && w.size >= 4 && (() => {
    const v = words(i.text); let both = 0; for (const x of w) if (v.has(x)) both++;
    return both / Math.min(w.size, v.size) >= 0.6;
  })()).map((i) => i.id);
  return [...new Set([...named, ...alike])];
}
const asText = (x) => (typeof x === "string" ? x : x?.text ?? x?.question ?? x?.assumption ?? x?.finding ?? x?.description ?? JSON.stringify(x));

export function finish(jobDir, rc, seconds) {
  const s = loadShaping(jobDir), d = dirs(jobDir);
  if (!s?.running) throw new Error("no BMad run is in progress");
  const r = s.running, logPath = join(d.runs, `${r.name}.json`), raw = readJson(logPath, null);
  const json = lastJson(raw?.result ?? read(logPath));
  const before = readJson(join(d.runs, `${r.name}.before.json`), { files: {}, memlogs: {} }), after = snapshot(d.out);
  const files = Object.keys(after).filter((p) => before.files[p] !== after[p]).map((p) => rel(jobDir, p)).sort();
  const run = { n: r.n, name: r.name, step: r.step, skill: r.skill, batch: r.batch, at: r.at, rc: Number(rc), seconds: Number(seconds),
    cost: raw?.total_cost_usd ?? null, files, status: null };
  delete s.running;
  const add = (kind, text, extra = {}) => {
    const t = String(text ?? "").trim();
    if (!t || s.ledger.some((i) => i.kind === kind && norm(i.text) === norm(t))) return;
    if (kind === "question" || kind === "finding") { const rep = repeatOf(s, t); if (rep.length) extra = { ...extra, repeat_of: rep }; }
    s.ledger.push({ id: `B-${s.ledger.length + 1}`, kind, skill: r.skill ?? null, run: r.n, text: t, needs_human: kind !== "conflict",
      status: kind === "conflict" ? "noted" : "open", ...extra });
  };
  const bad = (why) => { run.status = "invalid"; run.error = why; };
  // Seen live: Claude Code does not hand its own sign-in (CLAUDE_CODE_OAUTH_TOKEN) to the commands it runs — the BMad session
  // said "Not logged in" in two seconds. Say what it is, not "no JSON".
  const said = String(raw?.result ?? "");
  if (raw?.is_error && /not logged in|\/login|invalid api key|authentication/i.test(said))
    bad(`the BMad session is not signed in to Claude ("${said.slice(0, 80)}") — a /login of this machine's Claude Code is enough; signed in with a token in the environment (CI, headless), point DELIVER_CLAUDE_TOKEN_FILE at a file holding it: Claude Code does not pass its own token to the commands it runs`);
  else if (raw?.is_error && said) bad(`the BMad session ended with an error: ${said.slice(0, 160)}`);
  else if (!json) bad(Number(rc) ? `the session failed (rc ${rc}) — see ${rel(jobDir, logPath)}.err` : "no JSON at the end of BMad's answer");
  else if (run.status === "invalid") { /* judged above */ }
  else if (r.step === "help") {
    const seq = (json.sequence ?? []).filter((x) => /^bmad-[a-z-]+$/.test(x?.skill ?? ""));
    const mine = seq.filter((x) => !OURS.test(x.skill));
    if (!mine.length) bad(seq.length ? "bmad-help named only skills our own team runs" : "bmad-help named no skill to run");
    else { run.status = "complete"; s.plan = { run: r.n, sequence: mine, skipped: json.skipped ?? [], ours: seq.filter((x) => OURS.test(x.skill)).map((x) => x.skill) }; }
  } else if (r.step === "review") {
    if (!Array.isArray(json.findings) || !json.verdict) bad("bmad-review returned no findings[] and verdict");
    else {
      run.status = "complete";
      s.reviews.push({ run: r.n, round: r.round, verdict: json.verdict, findings: json.findings.length,
        by_severity: json.findings.reduce((a, f) => ({ ...a, [f.severity ?? "?"]: (a[f.severity ?? "?"] ?? 0) + 1 }), {}) });
      for (const f of json.findings) add("finding", asText(f), { severity: f.severity ?? null, lens: f.lens ?? null, artifact: f.artifact ?? null, needs_human: f.needs_human !== false });
    }
  } else {
    run.status = ["complete", "partial", "blocked"].includes(json.status) ? json.status : "complete";
    if (run.status === "blocked") add("blocked", `${r.skill} could not run: ${json.reason ?? json.error_code ?? "no reason given"}`);
    else if (!files.length) bad("BMad wrote nothing in its output folder");
    if (run.status !== "invalid") {
      for (const q of json.open_questions ?? []) add("question", asText(q));
      for (const c of json.conflicts_with_prior_decisions ?? []) add("conflict", asText(c));
    }
    if (r.step === "create" && run.status !== "invalid" && run.status !== "blocked") {
      for (const a of json.assumptions ?? []) add("assumption", asText(a));
      // its own decisions, from the memlog lines this run wrote (an update's memlog lines are our decisions, applied)
      const tagged = { decision: [], assumption: [], question: [] };
      for (const p of Object.keys(after).filter((x) => x.endsWith(".memlog.md"))) {
        const was = new Set(String(before.memlogs[p] ?? "").split("\n"));
        for (const line of read(p).split("\n")) { const m = line.match(MEMTAG); if (m && !was.has(line)) tagged[m[1]].push(m[2]); }
      }
      for (const t of tagged.decision) add("decision", t);
      if (!(json.assumptions ?? []).length) for (const t of tagged.assumption) add("assumption", t);
      if (!(json.open_questions ?? []).length) for (const t of tagged.question) add("question", t);
    }
  }
  if (r.step === "update" && usable(run)) {
    const b = s.batches.find((x) => x.n === r.batch);
    if (b && b.skills.every((k) => k === r.skill || s.runs.some((x) => x.step === "update" && x.skill === k && x.batch === b.n && usable(x)))) b.done = true;
  }
  run.json = json;
  s.runs.push(run);
  save(jobDir, s);
  return { run: r.name, status: run.status, error: run.error ?? null, files, cost: run.cost, seconds: run.seconds,
    path: r.step === "help" && s.plan ? s.plan.sequence.map((x) => x.skill) : undefined,
    verdict: r.step === "review" ? s.reviews.at(-1)?.verdict : undefined,
    new_items: s.ledger.filter((i) => i.run === r.n).map((i) => `${i.id} ${i.kind}${i.status === "noted" ? " (noted)" : i.needs_human ? "" : " (PM)"}: ${i.text.slice(0, 160)}`) };
}

// ── the ledger: Michael proposes, the human decides; Michael alone only what needs no human ─────────────────────────────
function artifactQuote(jobDir, file, quote) {
  const d = dirs(jobDir), repo = repoOf(jobDir);
  if (!String(quote ?? "").trim()) return "quote the words of the BMad artifact your proposal stands on";
  const p = [join(repo, String(file)), join(d.out, String(file))].find((x) => x.startsWith(d.out) && existsSync(x) && statSync(x).isFile());
  if (!p) return `${file} is not a BMad artifact of this job (under ${rel(jobDir, d.out)}): a proposal stands on what BMad said, not on the request`;
  const hay = norm(read(p));
  const miss = String(quote).split(/\s*(?:…|\.\.\.)\s*/).map(norm).filter(Boolean).filter((f) => !hay.includes(f));
  return miss.length ? `quote not found in ${file}: "${miss[0].slice(0, 80)}"` : null;
}
const item = (s, id) => {
  const i = s.ledger.find((x) => x.id === id);
  if (!i) throw new Error(`${id} is not in the shaping ledger (dl shape ledger)`);
  if (i.status !== "open") throw new Error(`${id} is ${i.status}`);
  return i;
};

export function propose(jobDir, id, text, file, quote) {
  const s = loadShaping(jobDir), i = item(s, id);
  if (!String(text ?? "").trim()) throw new Error("say what you propose");
  const e = artifactQuote(jobDir, file, quote); if (e) throw new Error(e);
  i.proposal = { text, file, quote, at: now() };
  save(jobDir, s);
  return `${id}: proposed — "${text}"`;
}
export function decide(jobDir, id, text, file, quote, rationale) {
  const s = loadShaping(jobDir), i = item(s, id);
  if (i.needs_human) throw new Error(`${id} (${i.kind}) changes what is built: it is decided with the human — dl shape propose ${id} …, then the human answers (dl clarify ${id} "<answer>")`);
  if (!String(rationale ?? "").trim()) throw new Error("a PM decision needs its rationale");
  const e = artifactQuote(jobDir, file, quote); if (e) throw new Error(e);
  Object.assign(i, { status: "decided", decision: { text, by: "pm", file, quote, rationale, at: now() } });
  save(jobDir, s);
  return `${id}: decided by the PM — "${text}"`;
}
export function answer(jobDir, id, who, text) {
  const s = loadShaping(jobDir);
  if (!String(text ?? "").trim()) throw new Error("the answer is empty");
  const targets = id === "proposals" ? s.ledger.filter((i) => i.status === "open" && i.needs_human && i.proposal) : [item(s, id)];
  if (!targets.length) throw new Error("no open item has a proposal to accept");
  for (const i of targets)
    Object.assign(i, { status: "decided", decision: { text: id === "proposals" ? `${i.proposal.text} (accepted: "${text}")` : text, by: `human: ${who} ${now().slice(0, 10)}`, at: now() } });
  save(jobDir, s);
  return targets.map((i) => `${i.id}: decided by the human`).join("\n");
}
export function gap(jobDir, rid, text) {
  const s = loadShaping(jobDir);
  if (!rid || !String(text ?? "").trim()) throw new Error('usage: dl shape gap <readiness id> "<what BMad\'s artifacts do not state>"');
  // not a decision but a request to BMad, sent with the next update: what it states or asks comes back to the ledger
  s.ledger.push({ id: `B-${s.ledger.length + 1}`, kind: "gap", skill: null, run: null, text: `${rid}: ${text}`, needs_human: false, status: "decided",
    decision: { text: `The readiness review found the artifacts silent on ${rid} (${text}). State it where the sources state it; otherwise list it in open_questions[]`, by: "pm", at: now() } });
  save(jobDir, s);
  return `${s.ledger.at(-1).id}: goes to BMad with the next update`;
}

export function ledgerText(jobDir, onlyOpen) {
  const s = loadShaping(jobDir);
  return s.ledger.filter((i) => !onlyOpen || i.status === "open").map((i) =>
    `${i.id} [${i.status}${i.status === "open" ? (i.needs_human ? " · with the human" : " · PM") : ""}] ${i.kind}${i.skill ? ` (${i.skill})` : ""}${i.severity ? ` ${i.severity}` : ""}: ${i.text}` +
    (i.proposal ? `\n    proposal: ${i.proposal.text}  [${i.proposal.file}: "${i.proposal.quote.slice(0, 80)}"]` : "") +
    (i.decision ? `\n    decided (${i.decision.by}): ${i.decision.text}` : "")).join("\n");
}

export function questions(jobDir) {
  const s = loadShaping(jobDir), j = job(jobDir);
  const lines = [`# Decisions before the work can start — ${j.id ?? ""}`, "",
    "BMad shaped this request. Below is what it decided, assumed, asked or found; nothing it wrote binds until you decide.",
    "Michael's proposal stands on BMad's own words (quoted). Answer each in a terminal — `dl clarify <id> \"<your decision>\"` —",
    "or accept all of Michael's proposals at once: `dl clarify proposals \"<your words>\"`.", ""];
  for (const i of humanOpen(s)) {
    lines.push(`## ${i.id} — ${i.kind}${i.skill ? ` (${i.skill})` : ""}${i.severity ? `, ${i.severity}` : ""}`, "", i.text, "");
    for (const id of i.repeat_of ?? []) {
      const was = s.ledger.find((x) => x.id === id);
      if (was?.decision) lines.push(`- **Asked before as ${id}** — decided: "${was.decision.text}". BMad says it still does not settle this: rule on exactly what it asks.`);
    }
    if (i.repeat_of?.length) lines.push("");
    if (i.proposal) lines.push(`- **Michael proposes:** ${i.proposal.text}`, `  _BMad's words:_ "${i.proposal.quote}" (${i.proposal.file})`, "");
  }
  return lines.join("\n");
}

// ── after shaping: the freeze, the plan's traceability, the architecture's rules, the PR ────────────────────────────────
export function manifest(jobDir) {
  const d = dirs(jobDir), snap = { ...snapshot(d.out), ...snapshot(d.inputs) };
  const lines = Object.keys(snap).sort().map((p) => `${relative(jobDir, p)} ${snap[p]}`);
  lines.push(`shaping.json ${sha(read(shapingFile(jobDir)))}`);
  return sha(lines.join("\n"));
}
const currentArtifacts = (jobDir) => {
  const s = loadShaping(jobDir);
  return s ? created(s).flatMap((k) => latestFiles(s, k).map((f) => ({ skill: k, file: f }))) : [];
};
/** CAP-n of a spec's "## Capabilities", FR-n headings of a PRD: what the plan's acceptance criteria must trace */
export function ids(jobDir) {
  const repo = repoOf(jobDir), out = new Set();
  for (const { file } of currentArtifacts(jobDir)) {
    const t = read(join(repo, file));
    const caps = t.match(/^##\s+Capabilities\b[\s\S]*?(?=^##\s|(?![\s\S]))/m)?.[0] ?? "";
    for (const m of caps.matchAll(/\bCAP-\d+\b/g)) out.add(m[0]);
    for (const m of t.matchAll(/^#{2,5}\s+(FR-\d+)\b/gm)) out.add(m[1]);
  }
  return [...out].sort((a, b) => a.localeCompare(b, "en", { numeric: true }));
}
/** the spine's "### AD-n — title" rules as a job standard: every lead, dev and reviewer gets them, the reviewer answers each */
export function standards(jobDir) {
  const repo = repoOf(jobDir), rules = [];
  for (const { file } of currentArtifacts(jobDir).filter((x) => /ARCHITECTURE-SPINE\.md$/i.test(x.file))) {
    for (const m of read(join(repo, file)).matchAll(/^###\s+(AD-\d+)\s*[—–:-]+\s*(.+?)\s*$([\s\S]*?)(?=^###?\s|(?![\s\S]))/gm)) {
      const rule = m[3].match(/\*\*Rule:\*\*\s*(.+)/)?.[1]?.trim();
      rules.push(`- [${m[1]}] ${m[2].replace(/\s*\[[A-Z]+\]\s*$/, "")}${rule ? `: ${rule}` : ""}`);
    }
  }
  if (!rules.length) return null;
  const dir = join(jobDir, "standards"); mkdirSync(dir, { recursive: true });
  const p = join(dir, "bmad-architecture.md");
  writeFileSync(p, `---\ntitle: The architecture shaped for this job (BMad, decided with the business)\napplies_to: [lead, dev, review]\n---\n\n# Architecture decisions\n\nEvery rule binds this job's code; the reviewer answers each by its id.\n\n## Must\n\n${rules.join("\n")}\n`);
  return p;
}
export function artifactsText(jobDir) {
  if (!loadShaping(jobDir)) return "none";
  return currentArtifacts(jobDir).map((x) => `- ${x.file} (${x.skill})`).join("\n") +
    `\n- the shaping ledger: ${rel(jobDir, shapingFile(jobDir))} — every decision taken on what BMad said (source "shape: B-n")`;
}

export function report(jobDir) {
  const s = loadShaping(jobDir);
  if (!s) return "";
  const cost = s.runs.reduce((a, r) => a + (r.cost ?? 0), 0), secs = s.runs.reduce((a, r) => a + (r.seconds ?? 0), 0);
  const esc = (t) => String(t ?? "").replace(/\|/g, "\\|").replace(/\n/g, " ");
  const out = [`## Shaped with the BMad Method ${s.version}`, "",
    `BMad chose its own path, wrote the specification headless, applied the decisions taken on what it said and reviewed its own work: ${s.runs.length} runs, ${Math.round(secs / 60)} min, $${cost.toFixed(2)}. Nothing it decided was binding until the decisions below.`, "",
    `**Path:** ${(s.plan?.sequence ?? []).map((x) => x.skill).join(" → ") || "-"}${(s.plan?.skipped ?? []).length ? ` · skipped: ${s.plan.skipped.map((x) => x.skill).join(", ")}` : ""}`, "",
    `**Artifacts:** ${currentArtifacts(jobDir).map((x) => `\`${x.file}\``).join(", ") || "-"}`, ""];
  if (s.reviews.length) out.push(`**Its reviews:** ${s.reviews.map((r) => `round ${r.round ?? "?"} — ${r.verdict}, ${r.findings} finding(s)`).join(" · ")}`, "");
  const decided = s.ledger.filter((i) => i.status === "decided");
  if (decided.length) {
    out.push("| Id | From | BMad said | Decision | By |", "| --- | --- | --- | --- | --- |");
    for (const i of decided) out.push(`| ${i.id} | ${i.kind}${i.skill ? ` · ${i.skill}` : ""} | ${esc(i.text).slice(0, 220)} | ${esc(i.decision.text).slice(0, 220)} | ${/^human/.test(i.decision.by) ? "the human" : "Michael"} |`);
    out.push("");
  }
  const noted = s.ledger.filter((i) => i.kind === "conflict");
  if (noted.length) out.push("**What BMad changed against its own earlier decisions:**", "", ...noted.map((i) => `- ${i.text}`), "");
  const after = ledgerOnly(s);
  if (after.length) out.push(`**Decided after BMad's last update** (binding through the ledger, not written into its artifacts — the update chain reached its limit): ${after.map((i) => i.id).join(", ")}`, "");
  return out.join("\n");
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [cmd, jobDir, ...a] = process.argv.slice(2);
  const print = (v) => console.log(typeof v === "string" ? v : JSON.stringify(v, null, 2));
  try {
    if (!jobDir || !existsSync(join(jobDir, "job.json"))) throw new Error("usage: bmad.mjs <command> <job dir> …");
    if (cmd === "needs") { const r = needsShaping(jobDir); print(r); process.exit(r.shape ? 0 : 3); }
    else if (cmd === "init") print(init(jobDir, a[0]));
    else if (cmd === "installed") { const s = loadShaping(jobDir); s.installed = { version: a[0], at: now() }; save(jobDir, s); print("installed"); }
    else if (cmd === "status") print(status(jobDir, Number(a[0] ?? 2), Number(a[1] ?? 2)));
    else if (cmd === "start") print(start(jobDir, Number(a[0] ?? 2), Number(a[1] ?? 2)));
    else if (cmd === "finish") print(finish(jobDir, a[0], a[1]));
    else if (cmd === "abandon") { const s = loadShaping(jobDir); delete s.running; save(jobDir, s); print("abandoned"); }
    else if (cmd === "ledger") print(ledgerText(jobDir, a[0] === "open") || "(the ledger is empty)");
    else if (cmd === "propose") print(propose(jobDir, a[0], a[1], a[2], a[3]));
    else if (cmd === "decide") print(decide(jobDir, a[0], a[1], a[2], a[3], a[4]));
    else if (cmd === "answer") print(answer(jobDir, a[0], a[1], a[2]));
    else if (cmd === "gap") print(gap(jobDir, a[0], a[1]));
    else if (cmd === "questions") print(questions(jobDir));
    else if (cmd === "manifest") print(manifest(jobDir));
    else if (cmd === "ids") print(ids(jobDir));
    else if (cmd === "artifacts") print(artifactsText(jobDir));
    else if (cmd === "standards") print(standards(jobDir) ?? "no AD-n rules");
    else if (cmd === "report") print(report(jobDir));
    else throw new Error(`unknown command: ${cmd}`);
  } catch (e) { console.error(`bmad: ${e.message}`); process.exit(1); }
}
