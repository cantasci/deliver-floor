// Asana — the job is a task in an existing project, every card a subtask of it in the same project; the project's sections
// are the columns. Built from Asana's official OpenAPI description (github.com/Asana/openapi, defs/asana_oas.yaml):
//   GET  /users/me                          who the token belongs to (check)
//   GET  /projects/{gid}, /projects/{gid}/sections
//   POST /tasks {data:{name, notes, projects, parent}}      the job task, then each card under it
//   POST /tasks/{gid}/addDependencies {data:{dependencies}}  depends_on (a task may have 30 dependencies + dependents)
//   POST /sections/{gid}/addTask {data:{task}}               the card moves to its column (and leaves the others)
//   POST /tasks/{gid}/stories {data:{text}}                  a role's comment
//   PUT  /tasks/{gid} {data:{notes}}                         the description, with the branch
// Credentials: ASANA_TOKEN (a personal access token, sent as Bearer). Settings: tracker.asana.project = the project gid.
import { Tracker, registerTracker, stageOf } from "../tracker.mjs";

export class AsanaTracker extends Tracker {
  constructor(jobDir) {
    super(jobDir);
    const cfg = this.job.settings?.tracker?.asana ?? {};
    this.base = (process.env.ASANA_BASE_URL ?? "https://app.asana.com/api/1.0").replace(/\/$/, "");
    this.project = String(cfg.project ?? "");
    if (!this.project) throw new Error("settings.tracker.asana.project is not set (the project's gid, from its URL)");
    if (!process.env.ASANA_TOKEN) throw new Error("Asana credentials missing: ASANA_TOKEN (a personal access token)");
    this.auth = `Bearer ${process.env.ASANA_TOKEN}`;
  }
  async req(method, path, data) {
    const r = await fetch(`${this.base}${path}`, {
      method, headers: { Authorization: this.auth, Accept: "application/json", "Content-Type": "application/json" },
      body: data ? JSON.stringify({ data }) : undefined,
    });
    const text = await r.text();
    if (!r.ok) {
      let msg = text.slice(0, 300); try { msg = JSON.parse(text).errors.map((e) => e.message).join("; "); } catch { /* raw */ }
      throw new Error(`Asana ${method} ${path} → ${r.status}: ${msg}`);
    }
    return text ? JSON.parse(text).data : {};
  }
  async sections() {
    if (!this._sections) this._sections = await this.req("GET", `/projects/${this.project}/sections`);
    return this._sections;
  }
  async open() {
    if (!this.job.tracker?.epic) {
      const t = await this.req("POST", "/tasks", { name: this.job.title, projects: [this.project],
        notes: `/deliver job ${this.job.id}\n\n${this.job.request.slice(0, 3000)}` });
      this.job.tracker = { kind: "asana", epic: t.gid, url: t.permalink_url }; this.saveJob();
    }
    for (const c of this.board.cards) if (!c.tracker?.id) {
      const t = await this.req("POST", "/tasks", { name: `${c.id}: ${c.title}`.slice(0, 250), notes: this.description(c),
        projects: [this.project], parent: this.job.tracker.epic });
      c.tracker = { id: t.gid, url: t.permalink_url, column: null }; this.saveBoard();
      const deps = (c.depends_on ?? []).map((d) => this.board.cards.find((x) => x.id === d)?.tracker?.id).filter(Boolean);
      if (deps.length) await this.req("POST", `/tasks/${t.gid}/addDependencies`, { dependencies: deps }).catch(() => {});
    }
    await this.sync();
  }
  async sync(card, event) {
    const cards = card ? [this.card(card)] : this.board.cards;
    for (const c of cards) {
      if (!c.tracker?.id) await this.open();
      const target = this.columns[stageOf(c)];
      if (c.tracker.column === target) continue;
      const s = (await this.sections()).find((x) => x.name.toLowerCase() === String(target).toLowerCase());
      if (!s) throw new Error(`${c.id}: the project has no section '${target}' (has: ${(await this.sections()).map((x) => x.name).join(", ")}) — add it, or map it in settings.tracker.columns`);
      await this.req("POST", `/sections/${s.gid}/addTask`, { task: c.tracker.id });
      c.tracker.column = target; this.saveBoard();
      if (event) await this.note(c.id, "michael", event);
    }
  }
  async note(card, author, text) {
    const c = this.card(card);
    if (!c.tracker?.id) await this.open();
    await this.req("POST", `/tasks/${c.tracker.id}/stories`, { text: `[${author}] ${text}` });
  }
  description(c) {
    return [c.context, "Acceptance criteria:\n" + (c.acceptance ?? []).map((a) => `- ${a}`).join("\n"),
      `Component: ${c.component ?? "-"}  ·  Scope: ${(c.scope ?? []).join(", ")}  ·  QA tests: ${(c.qa_scope ?? []).join(", ")}`,
      `Verify: ${c.verify}  ·  QA verify: ${c.qa_verify ?? "-"}`,
      ...(c.branch ? [`Development: branch ${c.branch}${c.branch_url ? ` — ${c.branch_url}` : ""}`] : [])].join("\n\n");
  }
  async branch(card) {
    const c = this.card(card);
    if (!c.branch) return;
    if (!c.tracker?.id) await this.open();
    await this.req("PUT", `/tasks/${c.tracker.id}`, { notes: this.description(c) });
    await this.note(card, "michael", `branch ${c.branch}${c.branch_url ? ` (${c.branch_url})` : ""}`);
  }
  where() { return this.job.tracker?.url ? `asana: ${this.job.tracker.url}` : `asana: project ${this.project}`; }
  async check() {
    const out = [], ok = (m) => out.push({ ok: true, msg: m }), bad = (m) => out.push({ ok: false, msg: m });
    try { const me = await this.req("GET", "/users/me"); ok(`signed in to Asana as ${me.email ?? me.name ?? me.gid} (ASANA_TOKEN)`); }
    catch (e) { bad(`cannot sign in to Asana: ${e.message}`); return out; }
    try { const p = await this.req("GET", `/projects/${this.project}`); ok(`project ${this.project}: ${p.name ?? ""}`.trim()); }
    catch (e) { bad(`project ${this.project} is not visible to this user: ${e.message}`); return out; }
    try {
      const names = new Set((await this.sections()).map((s) => s.name.toLowerCase()));
      const missing = Object.entries(this.columns).filter(([, n]) => !names.has(String(n).toLowerCase()));
      if (missing.length) bad(`the project has no section for: ${missing.map(([k, n]) => `${k} → '${n}'`).join(", ")} — add them in Asana, or map each to one it has in tracker.columns`);
      else ok(`the project has a section for every column (${Object.values(this.columns).join(", ")})`);
    } catch (e) { bad(`cannot read the project's sections: ${e.message}`); }
    return out;
  }
}
registerTracker("asana", AsanaTracker);
