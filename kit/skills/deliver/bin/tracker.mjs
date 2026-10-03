#!/usr/bin/env node
// tracker.mjs — where the cards are shown and moved: a small interface, a factory, and one class per tool.
//
// board.json stays the source of truth for the flow (dl's guards read it). A tracker MIRRORS it: it creates the
// job and its cards in a tool people already watch, moves each card through the workflow columns as the roles
// finish their steps, and posts each role's result (QA verdict, review verdict, gate result) as a comment.
//
//   settings.tracker = { "kind": "local" | "jira", "columns": {…}, "jira": {…} }        (config.json / .deliver.json)
//
// Adding a tool = one class with the four methods below + registerTracker("<kind>", Class). Nothing else changes.
//
//   node tracker.mjs open   <job dir>                          create the job (epic) + all cards in the tool
//   node tracker.mjs sync   <job dir> [card] [--event "<text>"] move card(s) to the column their state implies
//   node tracker.mjs note   <job dir> <card> <author> "<text>"  comment on a card as a role
//   node tracker.mjs kanban <job dir> [--html <file>]          print the board as kanban columns (+ HTML view)
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

// ---- the workflow ------------------------------------------------------------------------------------------------
// Default kanban columns. A stage is derived from the card's state and its recorded gate/QA/review results.
export const DEFAULT_COLUMNS = {
  todo: "To Do", in_progress: "In Progress", qa: "QA", review: "Code Review", done: "Done", blocked: "Blocked", wontdo: "Won't Do",
};
export const STAGE_ORDER = ["todo", "in_progress", "qa", "review", "done", "blocked", "wontdo"];

export function stageOf(c) {
  switch (c.state) {
    case "ready": return "todo";
    case "running": return "in_progress";
    case "merged": return "done";
    case "blocked": return "blocked";
    case "archived": return "wontdo";
    case "review": {
      const gate = c.gate?.result === "PASS", qa = c.qa?.verdict === "pass";
      if (!gate || c.gate?.head !== c.qa?.gate_head && c.qa?.verdict) return gate ? "qa" : "in_progress";
      if (!qa) return "qa";
      if (c.review?.verdict === "approve" && c.review?.head === c.qa?.head) return "review"; // approved, waiting for merge
      return "review";
    }
    default: return "todo";
  }
}
const columnsOf = (job) => ({ ...DEFAULT_COLUMNS, ...(job.settings?.tracker?.columns ?? {}) });

// ---- the interface -------------------------------------------------------------------------------------------------
export class Tracker {
  constructor(jobDir) {
    this.jobDir = jobDir;
    this.job = JSON.parse(readFileSync(join(jobDir, "job.json"), "utf8"));
    this.board = JSON.parse(readFileSync(join(jobDir, "board.json"), "utf8"));
    this.columns = columnsOf(this.job);
  }
  /** create the job container and every card that has no external id yet */
  async open() {}
  /** bring one card (or all) to the column its state implies */
  async sync(_card, _event) {}
  /** comment on a card on behalf of a role */
  async note(_card, _author, _text) {}
  /** a short line describing where people see the board */
  where() { return ""; }
  card(id) { const c = this.board.cards.find((x) => x.id === id); if (!c) throw new Error(`no such card: ${id}`); return c; }
  saveBoard() { writeFileSync(join(this.jobDir, "board.json"), JSON.stringify(this.board, null, 2) + "\n"); }
  saveJob() { writeFileSync(join(this.jobDir, "job.json"), JSON.stringify(this.job, null, 2) + "\n"); }
}

// ---- local: board.json + a kanban view (terminal + HTML) -----------------------------------------------------------
export class LocalTracker extends Tracker {
  async open() { this.render(); }
  async sync() { this.render(); }
  async note(card, author, text) {
    const c = this.card(card);
    c.comments = [...(c.comments ?? []), { at: new Date().toISOString(), author, text }];
    this.saveBoard(); this.render();
  }
  where() { return `kanban: ${join(this.jobDir, "kanban.html")} · dl kanban`; }
  render() { writeFileSync(join(this.jobDir, "kanban.html"), kanbanHtml(this.job, this.board, this.columns)); }
}

// ---- jira: Jira Cloud / Data Center REST API ----------------------------------------------------------------------
// settings.tracker.jira = { "project": "WL", "issue_type": "Task", "epic_type": "Epic", "labels": ["deliver"] }
// env: JIRA_BASE_URL, JIRA_EMAIL + JIRA_API_TOKEN (Cloud, basic auth) or JIRA_PAT (Data Center, bearer)
// The workflow must have statuses named like settings.tracker.columns (defaults: To Do, In Progress, QA, Code Review,
// Done, Blocked, Won't Do); a missing transition is reported, never invented.
export class JiraTracker extends Tracker {
  constructor(jobDir) {
    super(jobDir);
    const cfg = this.job.settings?.tracker?.jira ?? {};
    this.base = (process.env.JIRA_BASE_URL ?? cfg.base_url ?? "").replace(/\/$/, "");
    this.project = cfg.project; this.issueType = cfg.issue_type ?? "Task"; this.epicType = cfg.epic_type ?? "Epic";
    this.labels = cfg.labels ?? ["deliver"];
    this.api = cfg.api_version ?? "3";
    if (!this.base) throw new Error("JIRA_BASE_URL is not set");
    if (!this.project) throw new Error("settings.tracker.jira.project is not set");
    if (process.env.JIRA_PAT) this.auth = `Bearer ${process.env.JIRA_PAT}`;
    else if (process.env.JIRA_EMAIL && process.env.JIRA_API_TOKEN)
      this.auth = "Basic " + Buffer.from(`${process.env.JIRA_EMAIL}:${process.env.JIRA_API_TOKEN}`).toString("base64");
    else throw new Error("Jira credentials missing: JIRA_EMAIL + JIRA_API_TOKEN, or JIRA_PAT");
  }
  async req(method, path, body) {
    const r = await fetch(`${this.base}/rest/api/${this.api}${path}`, {
      method, headers: { Authorization: this.auth, Accept: "application/json", "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await r.text();
    if (!r.ok) throw new Error(`Jira ${method} ${path} → ${r.status}: ${text.slice(0, 300)}`);
    return text ? JSON.parse(text) : {};
  }
  doc(text) { // Atlassian Document Format (API v3) or plain text (v2)
    if (this.api === "2") return text;
    return { type: "doc", version: 1, content: String(text).split("\n\n").map((p) => ({ type: "paragraph", content: p ? [{ type: "text", text: p }] : [] })) };
  }
  async open() {
    if (!this.job.tracker?.epic) {
      const e = await this.req("POST", "/issue", { fields: {
        project: { key: this.project }, issuetype: { name: this.epicType }, summary: this.job.title, labels: [...this.labels, this.job.id],
        description: this.doc(`/deliver job ${this.job.id}\n\n${this.job.request.slice(0, 3000)}`) } });
      this.job.tracker = { kind: "jira", epic: e.key, url: `${this.base}/browse/${e.key}` }; this.saveJob();
    }
    for (const c of this.board.cards) if (!c.tracker?.key) {
      const fields = { project: { key: this.project }, issuetype: { name: this.issueType }, summary: `${c.id}: ${c.title}`.slice(0, 250),
        labels: [...this.labels, this.job.id, `role-${c.role}`],
        description: this.doc([c.context, "Acceptance criteria:\n" + (c.acceptance ?? []).map((a) => `- ${a}`).join("\n"),
          `Scope: ${(c.scope ?? []).join(", ")}  ·  QA tests: ${(c.qa_scope ?? []).join(", ")}`, `Verify: ${c.verify}`].join("\n\n")) };
      fields.parent = { key: this.job.tracker.epic };
      const i = await this.req("POST", "/issue", { fields });
      c.tracker = { key: i.key, url: `${this.base}/browse/${i.key}`, column: null };
      this.saveBoard();
      if ((c.depends_on ?? []).length) for (const d of c.depends_on) {
        const dk = this.board.cards.find((x) => x.id === d)?.tracker?.key;
        if (dk) await this.req("POST", "/issueLink", { type: { name: "Blocks" }, inwardIssue: { key: i.key }, outwardIssue: { key: dk } }).catch(() => {});
      }
    }
    await this.sync();
  }
  async sync(card, event) {
    const cards = card ? [this.card(card)] : this.board.cards;
    for (const c of cards) {
      if (!c.tracker?.key) await this.open();
      const target = this.columns[stageOf(c)];
      if (c.tracker.column === target) continue;
      const { transitions = [] } = await this.req("GET", `/issue/${c.tracker.key}/transitions`);
      const t = transitions.find((x) => (x.to?.name ?? x.name).toLowerCase() === target.toLowerCase());
      if (!t) throw new Error(`${c.tracker.key}: no transition to '${target}' (available: ${transitions.map((x) => x.to?.name ?? x.name).join(", ")}) — map it in settings.tracker.columns`);
      await this.req("POST", `/issue/${c.tracker.key}/transitions`, { transition: { id: t.id } });
      c.tracker.column = target; this.saveBoard();
      if (event) await this.note(c.id, "michael", event);
    }
  }
  async note(card, author, text) {
    const c = this.card(card);
    if (!c.tracker?.key) await this.open();
    await this.req("POST", `/issue/${c.tracker.key}/comment`, { body: this.doc(`[${author}] ${text}`) });
  }
  where() { return this.job.tracker?.url ? `jira: ${this.job.tracker.url}` : `jira: ${this.base} (project ${this.project})`; }
}

// ---- factory ---------------------------------------------------------------------------------------------------------
const REGISTRY = new Map([["local", LocalTracker], ["jira", JiraTracker]]);
export const registerTracker = (kind, cls) => REGISTRY.set(kind, cls);
export const trackerKinds = () => [...REGISTRY.keys()];
export function createTracker(jobDir) {
  const job = JSON.parse(readFileSync(join(jobDir, "job.json"), "utf8"));
  const kind = job.settings?.tracker?.kind ?? "local";
  const Cls = REGISTRY.get(kind);
  if (!Cls) throw new Error(`unknown tracker '${kind}' (known: ${trackerKinds().join(", ")})`);
  return new Cls(jobDir);
}

// ---- kanban views ------------------------------------------------------------------------------------------------------
export function kanbanText(job, board, columns = columnsOf(job)) {
  const by = Object.fromEntries(STAGE_ORDER.map((s) => [s, []]));
  for (const c of board.cards) by[stageOf(c)].push(c);
  const shown = STAGE_ORDER.filter((s) => by[s].length || ["todo", "in_progress", "qa", "review", "done"].includes(s));
  const w = 26, pad = (s) => (s.length > w - 1 ? s.slice(0, w - 2) + "…" : s).padEnd(w);
  const head = shown.map((s) => pad(`${columns[s]} (${by[s].length})`)).join("│ ");
  const rows = Math.max(...shown.map((s) => by[s].length), 0);
  const out = [`${job.id} — ${job.title}`, head, shown.map(() => "─".repeat(w)).join("┼─")];
  for (let i = 0; i < rows; i++) {
    out.push(shown.map((s) => pad(by[s][i] ? `${by[s][i].id} ${by[s][i].seat ?? by[s][i].role}·a${by[s][i].attempts}` : "")).join("│ "));
    out.push(shown.map((s) => pad(by[s][i] ? `  ${by[s][i].title}` : "")).join("│ "));
  }
  return out.join("\n");
}

const esc = (s) => String(s ?? "").replace(/[&<>"]/g, (m) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[m]);
export function kanbanHtml(job, board, columns = columnsOf(job)) {
  const by = Object.fromEntries(STAGE_ORDER.map((s) => [s, []]));
  for (const c of board.cards) by[stageOf(c)].push(c);
  const shown = STAGE_ORDER.filter((s) => by[s].length || ["todo", "in_progress", "qa", "review", "done"].includes(s));
  const card = (c) => `<article><h3>${esc(c.id)} · ${esc(c.title)}</h3>
    <p class="meta">${esc(c.component ?? "")}${c.component ? " · " : ""}${esc(c.seat ?? c.role)} → ${esc(c.agent)} · attempt ${c.attempts}${c.tracker?.key ? ` · <a href="${esc(c.tracker.url)}">${esc(c.tracker.key)}</a>` : ""}</p>
    ${c.branch ? `<p class="meta">branch <code>${esc(c.branch)}</code></p>` : ""}
    <p class="checks">gate ${c.gate ? esc(c.gate.result) : "–"} · QA ${c.qa ? esc(c.qa.verdict) : "–"} · review ${c.review ? esc(c.review.verdict) : "–"}</p>
    ${(c.comments ?? []).slice(-2).map((n) => `<p class="note"><b>${esc(n.author)}</b> ${esc(n.text)}</p>`).join("")}</article>`;
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="refresh" content="10"><title>${esc(job.id)} kanban</title><style>
:root{--bg:#f6f7f9;--col:#eceef2;--card:#fff;--ink:#1d2330;--mute:#5d6678;--line:#d8dce4}
@media (prefers-color-scheme:dark){:root{--bg:#14171d;--col:#1c2028;--card:#252a34;--ink:#e7eaf0;--mute:#9aa3b5;--line:#323846}}
body{margin:0;padding:16px;background:var(--bg);color:var(--ink);font:14px/1.4 system-ui,sans-serif}
h1{font-size:16px;margin:0 0 4px}.sub{color:var(--mute);margin:0 0 16px}
.board{display:flex;gap:12px;overflow-x:auto;align-items:flex-start}
section{flex:0 0 240px;background:var(--col);border-radius:8px;padding:8px}
section h2{font-size:13px;margin:4px 4px 8px;color:var(--mute)}
article{background:var(--card);border:1px solid var(--line);border-radius:6px;padding:8px;margin-bottom:8px}
article h3{font-size:13px;margin:0 0 4px}.meta,.checks,.note{margin:2px 0;color:var(--mute);font-size:12px}
a{color:inherit}</style></head><body>
<h1>${esc(job.title)}</h1><p class="sub">${esc(job.id)} · phase ${esc(job.phase)} · refreshes every 10 s</p>
<div class="board">${shown.map((s) => `<section><h2>${esc(columns[s])} (${by[s].length})</h2>${by[s].map(card).join("")}</section>`).join("")}</div>
</body></html>\n`;
}

// ---- CLI -----------------------------------------------------------------------------------------------------------------
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [cmd, jobDir, ...rest] = process.argv.slice(2);
  const flag = (n) => { const i = rest.indexOf(n); return i >= 0 ? rest.splice(i, 2)[1] : undefined; };
  try {
    if (!cmd || !jobDir) throw new Error("usage: tracker.mjs open|sync|note|kanban <job dir> …");
    if (cmd === "kanban") {
      const job = JSON.parse(readFileSync(join(jobDir, "job.json"), "utf8")), board = JSON.parse(readFileSync(join(jobDir, "board.json"), "utf8"));
      console.log(kanbanText(job, board));
      const html = flag("--html"); if (html) { writeFileSync(html, kanbanHtml(job, board)); console.log(`html: ${html}`); }
    } else {
      const t = createTracker(jobDir);
      if (cmd === "open") { await t.open(); console.log(t.where()); }
      else if (cmd === "sync") { const ev = flag("--event"); await t.sync(rest[0], ev); }
      else if (cmd === "note") { const [card, author, ...text] = rest; await t.note(card, author, text.join(" ")); }
      else throw new Error(`unknown command: ${cmd}`);
    }
  } catch (e) { console.error(`tracker: ${e.message}`); process.exit(1); }
}
