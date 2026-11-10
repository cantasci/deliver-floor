#!/usr/bin/env node
// The code driver for the executing phase: the steps of `dl next` that need no judgment are run here, not by Michael.
//   node run.mjs <repo root>        (dl run)
// Why: in live jobs Michael — a model with the whole playbook in its context — read `dl next`, ran the command it named and
// filed the answer, step after step: 60 % of a large job's tokens, and 39–61 % of a small job's time with no agent working.
// What it does, per card, as `dl next` lists it:
//   DISPATCH / REDISPATCH   dl wt add → the card's dev agent (its own `claude -p --agent` session) → dl gate
//   QA-WRITE                dl wt qa → the QA agent writes the tests from the spec while the dev builds
//   QA-JOIN, QA             dl qa-join; dl qa pass with the tests QA named per AC; refused → the QA agent again (QA-RUN)
//   REVIEW                  every pending reviewer in parallel → dl review (a blind finding marked blocking goes to Michael)
//   INTEGRATE, STACK, CHECK the dl command of the line
// Cards move independently: a slow dev never holds another card's review or merge.
// What it leaves to Michael (exit 10, with .work/<job>/out/run/HANDOVER.md): FIX, BLOCK, DECIDE, a stuck dev, a blind
// reviewer's blocking finding (triaged against the spec), a verdict dl refuses, and any line it does not know.
// Exit: 0 executing is finished (PHASE dl phase integrating) or the job is not executing · 10 Michael's turn · 3 a usage
// limit (nothing recorded, no attempt used) · 1 an error.
// Test hook: DELIVER_CLAUDE names the program run in place of `claude` (tests/fake-claude.mjs).
import { spawn } from "node:child_process";
import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync, copyFileSync, rmSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const BIN = dirname(fileURLToPath(import.meta.url));
const DL = join(BIN, "dl");
const ROOT = resolve(process.argv[2] ?? ".");
const CLAUDE = process.env.DELIVER_CLAUDE || "claude";
const MODE = process.env.PERMISSION_MODE || "auto";
const MAX_STEPS = Number(process.env.DELIVER_RUN_MAX_STEPS || 400);

const active = join(ROOT, ".work", "ACTIVE");
if (!existsSync(active)) { console.log("run: no active job"); process.exit(0); }
const JOB = readFileSync(active, "utf8").trim();
const JD = join(ROOT, ".work", JOB);
const OUT = join(JD, "out", "run");
mkdirSync(OUT, { recursive: true });
const HANDOVER = join(OUT, "HANDOVER.md");

const job = () => JSON.parse(readFileSync(join(JD, "job.json"), "utf8"));
const board = () => JSON.parse(readFileSync(join(JD, "board.json"), "utf8"));
const card = (id) => board().cards.find((c) => c.id === id);
const now = () => new Date().toISOString().replace(/\.\d+Z$/, "Z");
const event = (kind, text) => appendFileSync(join(JD, "events.log"), `${now()}\t${kind}\t${String(text).replace(/\s+/g, " ").slice(0, 400)}\n`);
const say = (s) => console.log(`run: ${s}`);
const lastLine = (s) => s.split("\n").pop() ?? "";

// dl changes the board, the job and the worktrees: one dl at a time (its own locks would refuse a second one as "busy")
let lane = Promise.resolve();
const dl = (...args) => {
  const p = lane.then(() => new Promise((done) => {
    const c = spawn(DL, ["-C", ROOT, ...args], { env: process.env });
    let out = "";
    c.stdout.on("data", (d) => (out += d)); c.stderr.on("data", (d) => (out += d));
    c.on("close", (code) => done({ code: code ?? 1, out: out.trim() }));
  }));
  lane = p.catch(() => {});
  return p;
};

class Limit extends Error {}
const sessions = existsSync(join(OUT, "sessions.json")) ? JSON.parse(readFileSync(join(OUT, "sessions.json"), "utf8")) : {};
let runs = 0, cost = 0;

// agent(<key>, <agent>, <role>, <prompt>, {cwd, resume}) → the agent's answer. Its own session: DELIVER_AGENT_ID marks it as a role
// agent for the guards (never Michael). resume: continue the session this key ran before (QA-RUN after QA-WRITE, a dev's
// second attempt) — it has the spec and its own work in its history, nothing is read again.
function agent(key, name, role, prompt, { cwd = ROOT, resume = false } = {}) {
  const ns = process.env.DELIVER_AGENT_NS && !name.includes(":") && existsSync(join(BIN, "..", "..", "..", "agents", `${name}.md`)) ? `${process.env.DELIVER_AGENT_NS}:${name}` : name;
  const model = job().roles?.find((r) => r.role === role)?.model;
  const args = ["-p", prompt, "--agent", ns, "--permission-mode", MODE, "--output-format", "json"];
  if (model) args.push("--model", model);
  if (resume && sessions[key]) args.push("--resume", sessions[key]);
  const n = ++runs, id = `run-${key}-${n}`.replace(/[^A-Za-z0-9_.-]/g, "-");
  writeFileSync(join(OUT, `${id}.prompt.md`), prompt);
  event("dispatch", name);
  return new Promise((done, fail) => {
    const c = spawn(CLAUDE, args, { cwd, env: { ...process.env, DELIVER_AGENT_ID: id, DELIVER_HEADLESS: "1", CLAUDE_CODE_DISABLE_BACKGROUND_TASKS: "1" } });
    let out = "", err = "";
    c.stdout.on("data", (d) => (out += d)); c.stderr.on("data", (d) => (err += d));
    c.on("error", (e) => fail(new Error(`${CLAUDE}: ${e.message}`)));
    c.on("close", () => {
      let r = {}; try { r = JSON.parse(out.trim().split("\n").pop()); } catch { r = { result: out.trim() || err.trim(), is_error: true }; }
      const text = String(r.result ?? "");
      writeFileSync(join(OUT, `${id}.md`), text + "\n");
      if (/hit your .*limit|out of (usage )?credits|usage limit reached/i.test(text) || /rate_limit|overloaded/i.test(String(r.subtype ?? "")))
        return fail(new Limit(text.slice(0, 200)));
      if (r.session_id) { sessions[key] = r.session_id; writeFileSync(join(OUT, "sessions.json"), JSON.stringify(sessions, null, 2) + "\n"); }
      cost += Number(r.total_cost_usd ?? 0);
      event("agent", `${name} ${id}: ${text}`);
      done(text);
    });
  });
}

// the last JSON value in an answer (fenced or bare)
function json(text) {
  const fenced = [...text.matchAll(/```(?:json)?\s*\n([\s\S]*?)```/g)].map((m) => m[1]).reverse();
  for (const t of [...fenced, text.slice(text.indexOf("{"), text.lastIndexOf("}") + 1), text.slice(text.indexOf("["), text.lastIndexOf("]") + 1)])
    try { if (t.trim()) return JSON.parse(t); } catch { /* next */ }
  return null;
}

const notes = [];         // what Michael takes over, with where the evidence is
const mine = new Set();   // cards the driver has given to Michael
const give = (id, what) => { if (id) mine.add(id); notes.push(`- ${id ? `**${id}** — ` : ""}${what}`); say(`→ Michael: ${id ?? ""} ${what}`); };

const roleCard = (role) => join(JD, "roles", `${role}.md`);
function planContext(c) {
  const plan = existsSync(join(JD, "plan.md")) ? readFileSync(join(JD, "plan.md"), "utf8") : "";
  const goal = (plan.match(/^## Goal\s*\n([\s\S]*?)(?=^## )/m)?.[1] ?? "").trim();
  const ids = new Set((c.acceptance ?? []).flatMap((a) => [...String(a).matchAll(/\bAC-\d+\b/g)].map((m) => m[0])));
  const acs = plan.split("\n").filter((l) => [...ids].some((i) => new RegExp(`\\b${i}\\b`).test(l))).slice(0, 40);
  return `${goal}\n${acs.join("\n")}`.trim();
}
function component(c) {
  const r = existsSync(join(JD, "readiness.json")) ? JSON.parse(readFileSync(join(JD, "readiness.json"), "utf8")) : {};
  const k = r.architecture?.components?.find((x) => x.id === c.component);
  return k ? `${k.id} — stack ${(k.stack ?? []).join(", ")}, path ${[].concat(k.path).join(", ")}` : (c.component ?? "-");
}
// the light path (dl track light; dl's dev_tests): the developer writes the card's code and all of its tests; no QA agent
const small = () => { const j = job(); return j.track === "light" && j.settings?.light?.qa !== true; };

function devPrompt(c, wt, feedback) {
  const hand = join(JD, "handoffs", `${c.id}.md`);
  mkdirSync(dirname(hand), { recursive: true });
  if (!existsSync(hand)) copyFileSync(join(BIN, "..", "templates", "handoff.md"), hand);
  const tests = small()
    ? `TESTS: you write ALL of this card's tests — unit tests and, in qa_scope ${JSON.stringify(c.qa_scope ?? [])}, one integration test per acceptance criterion at least, named after it ("AC-2: …"). \`${c.qa_verify ?? ""}\` must pass. End your summary with one line: AC-MAP: AC-1: <test name>; AC-2: <test name>; … (every AC of the card).`
    : `QA TESTS: qa_scope ${JSON.stringify(c.qa_scope ?? [])} belongs to the QA role — never edit it; after a QA round its tests must pass unchanged (\`${c.qa_verify ?? ""}\`).`;
  return `CARD:
${JSON.stringify(c, null, 1)}
SPEC (what to build, the acceptance criteria and test data — follow it): ${join(JD, "specs", `${c.id}.md`)}
COMPONENT: ${component(c)}
ROLE CARD (your rules — read first): ${roleCard(c.role)}
WORKTREE: ${wt}   (branch ${c.branch}; base is the job branch ${job().branch})
Work ONLY inside this directory. All paths are relative to it.
PLAN CONTEXT: ${planContext(c)}
HANDOFF FILE: ${hand} — fill it in.
${tests}
PREVIOUS FEEDBACK: ${feedback || "none"}
Work test-first (unit tests). When done: run the verify command in the worktree, commit, fill the handoff, and return your summary.`;
}
const qaWritePrompt = (c, qwt) => `MODE: QA-WRITE — write card ${c.id}'s integration/e2e tests from the spec, NOW, while the developer builds it. No product code.
ROLE CARD (your rules — read first): ${roleCard("qa")}
CARD: ${JSON.stringify(c, null, 1)}
SPEC (one test per acceptance criterion at least, with its test data and edge cases): ${join(JD, "specs", `${c.id}.md`)}
WORKTREE: ${qwt}   QA_SCOPE (write only here): ${JSON.stringify(c.qa_scope)}   QA_VERIFY: ${c.qa_verify}
The product code is not there yet: test the contract the spec and the card's context name (exports, endpoints, messages),
make the tests load and fail for the right reason, commit them in this repo's commit format, leave the worktree clean.
Return: the tests written per AC, and as your LAST line: AC-MAP: AC-1: <test name>; AC-2: <test name>; … (every AC of the card; one the test design leaves to the dev: "AC-4 unit: <test>").`;
const qaRunPrompt = (c, why, fresh) => `MODE: QA-RUN — card ${c.id}: ${fresh ? "write (if there are none yet) and run" : "your tests are on the card branch; run"} the integration/e2e tests for its acceptance criteria on the dev's commit. No product code.
ROLE CARD (your rules — read first): ${roleCard("qa")}
CARD: ${JSON.stringify(c, null, 1)}
SPEC: ${join(JD, "specs", `${c.id}.md`)}
WORKTREE: ${c.worktree}   QA_SCOPE (write only here): ${JSON.stringify(c.qa_scope)}   QA_VERIFY: ${c.qa_verify}
DEV'S COMMIT (what the gate passed — test this): ${c.gate?.head ?? "HEAD"}
WHAT dl SAID when the pass was recorded: ${why}
Decide per failure whether the code or your test is wrong. Change a test only where it contradicts the spec; never to make the
code pass. Commit your changes in this repo's commit format, leave the worktree clean.
OUTPUT — only JSON: {"verdict":"pass|fail","summary":"AC-1 pass: <test>; AC-2 fail: <what>; … (every AC of the card)","commits":["<full hash of each commit you made, oldest first>"]}`;
const reviewPrompt = (c, role, std) => `Role: ${role} — Lead reviewer. Review only; do not modify files.
ROLE CARD (your rules — read first): ${roleCard(role)}
CARD: ${JSON.stringify(c, null, 1)}
CHANGE: run \`git -C ${c.worktree} diff ${job().branch}...HEAD\` (and \`--stat\`).
QA RESULT: ${c.qa?.summary ?? "-"}
STANDARDS (company + project Must rules you answer to, one by one): ${std || "none"}
Check: acceptance criteria met${small() ? " — the developer wrote the tests of this card too: every acceptance criterion has a test that would fail without the change, or it is a blocking item" : ""}, correctness bugs, security, test quality, scope, and every STANDARDS rule.
OUTPUT — only JSON: {"verdict":"approve|changes","blocking":[{"file":"…","line":0,"issue":"…","fix":"…"}],"nits":["…"],
  "standards":{"<rule id>":"ok | violated: <where and what> | n_a: <why it does not apply to this change>"}}
Use "changes" only when there is at least one blocking item. A violated standard is a blocking item.`;
const blindPrompt = (c) => `Role: blind reviewer. Review only; do not modify files.
ROLE CARD (your rules — read first): ${roleCard("blind")}
CHANGE: run \`git -C ${c.worktree} diff ${job().branch}...HEAD\` (and \`--stat\`); read any file of ${c.worktree} you need.
You are not told what the change is for — on purpose: judge what the code does.
OUTPUT — only JSON: {"findings":[{"file":"…","line":0,"issue":"…","shows":"<an input or a sequence that shows it>","severity":"blocking|nit"}]}`;

const acmapFile = (id) => join(OUT, `${id}.acmap`);
function keepAcMap(id, text) {
  const m = [...text.matchAll(/^\s*AC-MAP:\s*(.+)$/gm)].pop();
  if (m) writeFileSync(acmapFile(id), m[1].trim() + "\n");
}

// --- the steps ------------------------------------------------------------------------------------------------------------
async function develop(id, feedback) {
  const w = await dl("wt", "add", id);
  if (w.code !== 0) { if (w.code !== 4) give(id, `dl wt add refused: ${lastLine(w.out)}`); return; }   // 4: no attempts left → dl next says BLOCK
  const wt = lastLine(w.out).trim(), c = card(id);
  // QA starts at the same moment (settings.qa_early): it writes the card's tests from the spec while the dev builds
  if (!feedback && !small() && (c.qa_scope ?? []).length && job().settings?.qa_early !== false && !busy.has(`${id}:qa`)) start(`${id}:qa`, () => qaWrite(id));
  say(`${id} → ${c.agent}${feedback ? " (again)" : ""}`);
  const text = await agent(`${id}-dev`, c.agent, c.role, devPrompt(c, wt, feedback), { cwd: wt, resume: Boolean(feedback) });
  if (small()) keepAcMap(id, text);
  if (/^\s*status:\s*stuck/im.test(text)) return give(id, `the developer is stuck — ${join(OUT, `run-${id}-dev-*.md`)}; decide it (phases/executing.md, Blocked)`);
  const g = await dl("gate", id);
  say(`${id} gate: ${lastLine(g.out)}`);
}
async function qaWrite(id) {
  const w = await dl("wt", "qa", id);
  if (w.code !== 0) return;   // QA's tests are on the card already, or the card moved on
  const c = card(id), qwt = lastLine(w.out).trim();
  say(`${id} → qa-tester (QA-WRITE)`);
  keepAcMap(id, await agent(`${id}-qa`, "qa-tester", "qa", qaWritePrompt(c, qwt), { cwd: qwt }));
}
async function qa(id, joined) {
  const c = card(id); let why = "no AC-MAP from QA-WRITE: name every AC with its test";
  if (joined && existsSync(acmapFile(id))) {
    const r = await dl("qa", id, "pass", readFileSync(acmapFile(id), "utf8").trim());
    say(`${id} qa: ${lastLine(r.out)}`);
    if (r.code === 0) return;
    why = r.out.split("\n").filter((l) => /REFUSED|fail|FAIL|not ok/.test(l)).slice(-12).join(" | ").slice(0, 1500) || r.out.slice(-600);
  }
  if (small()) {   // the developer wrote these tests: they fail on its own commit → back to the developer
    const r = await dl("qa", id, "fail", `the card's tests do not pass on its commit: ${why}`.slice(0, 900));
    if (r.code !== 0) give(id, `dl qa fail refused: ${lastLine(r.out)}`);
    return;
  }
  say(`${id} → qa-tester (QA-RUN)`);
  const v = json(await agent(`${id}-qa`, "qa-tester", "qa", qaRunPrompt(c, why, !joined), { cwd: c.worktree, resume: true }));
  if (!v || !/^(pass|fail)$/.test(v.verdict ?? "") || !v.summary) return give(id, `QA returned no verdict — ${join(OUT, `run-${id}-qa-*.md`)}`);
  for (const sha of v.commits ?? []) await dl("qa-commit", id, String(sha));
  const r = await dl("qa", id, v.verdict, String(v.summary).slice(0, 1800));
  say(`${id} qa ${v.verdict}: ${lastLine(r.out)}`);
  if (r.code !== 0) give(id, `dl refused QA's ${v.verdict}: ${r.out.split("\n").filter((l) => l.includes("REFUSED")).pop() ?? lastLine(r.out)}`);
}
async function review(id, roles) {
  const c = card(id), j = job();
  await Promise.all(roles.map(async (role) => {
    const sel = j.roles?.find((r) => r.role === role);
    if (!sel) return give(id, `reviewer '${role}' is not a role on the job`);
    if (role === "blind") {
      const v = json(await agent(`${id}-blind`, sel.agent, role, blindPrompt(c), { cwd: c.worktree }));
      if (!v) return give(id, `the blind reviewer returned no JSON — ${join(OUT, `run-${id}-blind-*.md`)}`);
      const blocking = (v.findings ?? []).filter((f) => f.severity === "blocking");
      if (blocking.length) {
        writeFileSync(join(OUT, `${id}-blind.json`), JSON.stringify(v, null, 2) + "\n");
        return give(id, `the blind reviewer has ${blocking.length} blocking finding(s): triage each against the spec and record it (dl review ${id} … --by blind --triage) — ${join(OUT, `${id}-blind.json`)}; do not run the blind review again`);
      }
      const r = await dl("review", id, "approve", `no blocking findings (${(v.findings ?? []).length} nit(s))`, "--by", "blind", "--triage", "[]");
      if (r.code !== 0) give(id, `dl refused the blind approval: ${lastLine(r.out)}`);
      return;
    }
    const std = (await dl("knowledge", "must", role)).out;
    const v = json(await agent(`${id}-${role}`, sel.agent, role, reviewPrompt(c, role, std), { cwd: c.worktree }));
    if (!v || !/^(approve|changes)$/.test(v.verdict ?? "")) return give(id, `reviewer ${role} returned no verdict — ${join(OUT, `run-${id}-${role}-*.md`)}`);
    const summary = v.verdict === "approve" ? `no blocking items${v.nits?.length ? `; ${v.nits.length} nit(s)` : ""}`
      : (v.blocking ?? []).map((b) => `${b.file ?? ""}${b.line ? `:${b.line}` : ""} ${b.issue ?? ""}${b.fix ? ` — fix: ${b.fix}` : ""}`).join(" | ").slice(0, 1800) || "changes";
    const r = await dl("review", id, v.verdict, summary, "--by", role, "--standards", JSON.stringify(v.standards ?? {}));
    say(`${id} review ${role}: ${v.verdict}`);
    if (r.code !== 0) give(id, `dl refused ${role}'s ${v.verdict}: ${r.out.split("\n").filter((l) => l.includes("REFUSED")).pop() ?? lastLine(r.out)}`);
  }));
}
async function integrate(id) {
  const r = await dl("integrate", id);
  say(`${id}: ${r.out.split("\n").find((l) => /^(MERGED|CONFLICT|BROKEN|STALLED)/.test(l)) ?? lastLine(r.out)}`);
  if (r.code === 3) return develop(id, `Conflict with the job branch: run \`git merge ${job().branch}\` in your worktree, resolve, run verify, commit.`);
  if (r.code !== 0) give(id, `dl integrate: ${lastLine(r.out)} (exit 5: the repo's commit rules refuse the merge message — phases/executing.md, Phase 4.4)`);
}
function feedbackOf(line) {
  const log = line.match(/feedback: (\S+\.log)/)?.[1];
  if (log && existsSync(log)) return `${line}\n${readFileSync(log, "utf8").split("\n").filter((l) => /^(FAIL|not ok|\s+→)/.test(l)).slice(0, 40).join("\n")}`;
  return line;
}

// --- the loop -------------------------------------------------------------------------------------------------------------
const busy = new Map();   // key → promise
let limit = null;
const start = (key, fn) => {
  const p = fn().catch((e) => { if (e instanceof Limit) limit = e; else give(key.split(":")[0].match(/T-\d+/)?.[0] ?? null, `the driver failed on a step (${key}): ${e.message}`); }).finally(() => busy.delete(key));
  busy.set(key, p);
};
function finish(code, why) {
  if (notes.length) writeFileSync(HANDOVER, `# For Michael — what the code driver could not decide (${now()})\n\nThe driver runs the cards (dispatch, gate, QA, review, merge). Handle only these, then end your turn (\`dl checkpoint\`):\n\n${notes.join("\n")}\n`);
  else rmSync(HANDOVER, { force: true });
  event("driver", `${why} — ${runs} agent run(s), $${cost.toFixed(2)}`);
  say(`${why} (${runs} agent run(s), $${cost.toFixed(2)})`);
  process.exit(code);
}

rmSync(HANDOVER, { force: true });
let steps = 0, last = "", same = 0;
try {
  for (;;) {
    if (limit) { if (busy.size) await Promise.all(busy.values()); throw limit; }
    if (job().phase !== "executing") finish(0, `phase ${job().phase}: not the driver's`);
    // the PLAYBOOK line is for a model (which file to read) — not a step of the board
    const nx = (await dl("next")).out.split("\n").filter((l) => !l.startsWith("PLAYBOOK ")).join("\n");
    const lines = nx.split("\n").filter(Boolean);
    let phase = false; const forMichael = [];
    for (const line of lines) {
      const [op, ...rest] = line.trim().split(/\s+/);
      const id = rest.find((t) => /^T-\d+$/.test(t));
      const free = (k = id) => k && !busy.has(k) && !mine.has(k);
      if (op === "DISPATCH") { for (const c of rest.filter((t) => /^T-\d+$/.test(t))) if (free(c)) start(c, () => develop(c, "")); }
      else if (op === "REDISPATCH") { if (free()) start(id, () => develop(id, feedbackOf(line))); }
      else if (op === "QA-WRITE") { if (!small() && !busy.has(`${id}:qa`)) start(`${id}:qa`, () => qaWrite(id)); }
      else if (op === "GATE") { if (free()) start(id, async () => { const g = await dl("gate", id); say(`${id} gate: ${lastLine(g.out)}`); }); }
      else if (op === "QA-JOIN") { if (free()) start(id, async () => { const r = await dl("qa-join", id); if (r.code !== 0) give(id, `dl qa-join: ${lastLine(r.out)}`); }); }
      else if (op === "QA") { if (free()) start(id, () => qa(id, /dl qa T-\d+ pass/.test(line) || small())); }
      else if (op === "REVIEW") { if (free()) start(id, () => review(id, (line.match(/reviewers: ([^→)]+)/)?.[1] ?? "reviewer").split(",").map((s) => s.trim()).filter(Boolean))); }
      else if (op === "INTEGRATE") { if (free()) start(id, () => integrate(id)); }
      else if (op === "STACK" || op === "CHECK") {
        const cmd = line.match(/dl ((?:stack-test|merge-check) T-\d+)/)?.[1];
        if (cmd && !busy.has(cmd)) start(cmd, async () => { const r = await dl(...cmd.split(" ")); say(`${cmd}: ${lastLine(r.out)}`); });
      }
      else if (op === "PHASE") phase = /dl phase integrating/.test(line);
      else if (["WAIT", "IDLE", "CHECKPOINT", "DRIVER"].includes(op)) { /* nothing to do */ }
      else forMichael.push(line);   // FIX, FIX-CUT, FIX-SPEC, FIX-ADD, BLOCK, DECIDE, ASK, INPUT, UNRECORDED, anything new
    }
    if (busy.size === 0) {
      if (forMichael.length || mine.size) { for (const l of forMichael) give(null, l); finish(10, "Michael's turn"); }
      if (phase) {   // every card is merged: the phase change is dl's check, not a judgment
        const r = await dl("phase", "integrating");
        if (r.code !== 0) { give(null, `dl phase integrating: ${lastLine(r.out)}`); finish(10, "Michael's turn"); }
        finish(0, "executing is finished: phase integrating");
      }
      if (!lines.length) finish(0, "nothing to do");
      if (nx === last) { if (++same >= 2) { give(null, `dl next does not move:\n${nx}`); finish(10, "Michael's turn (no progress)"); } } else same = 0;
      last = nx;
    }
    if (++steps > MAX_STEPS) { give(null, `the driver stopped after ${MAX_STEPS} steps`); finish(10, "Michael's turn (step limit)"); }
    if (busy.size) await Promise.race(busy.values());
  }
} catch (e) {
  if (e instanceof Limit) { event("driver", `usage limit: ${e.message}`); console.log(`run: usage limit — ${e.message}`); process.exit(3); }
  console.error(`run: ${e.stack ?? e}`); process.exit(1);
}
