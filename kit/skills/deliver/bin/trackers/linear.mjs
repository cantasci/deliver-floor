// Linear — the job is an issue in an existing team, every card a sub-issue of it; the team's workflow states are the columns.
// Built from Linear's official GraphQL schema and SDK (github.com/linear/linear: packages/sdk/src/schema.graphql, client.ts):
//   POST https://api.linear.app/graphql, Authorization: <personal API key> (no "Bearer" — the SDK sends the key as is)
//   viewer · teams(filter: {key: {eq}}) { states } · issueCreate(input: {teamId, title, description, parentId, stateId})
//   issueRelationCreate(input: {issueId, relatedIssueId, type: blocks})  — the source issue blocks the related one
//   issueUpdate(id, input: {stateId | description}) · commentCreate(input: {issueId, body}) · attachmentLinkURL(issueId, url, title)
// Credentials: LINEAR_API_KEY. Settings: tracker.linear.team = the team's key (e.g. ENG).
// The card's tracker key is the issue identifier (ENG-12): dl puts it in the card's branch name, as it does for Jira.
import { Tracker, registerTracker, stageOf } from "../tracker.mjs";

export class LinearTracker extends Tracker {
  constructor(jobDir) {
    super(jobDir);
    const cfg = this.job.settings?.tracker?.linear ?? {};
    this.url = process.env.LINEAR_API_URL ?? "https://api.linear.app/graphql";
    this.teamKey = cfg.team ?? "";
    if (!this.teamKey) throw new Error("settings.tracker.linear.team is not set (the team's key, e.g. ENG)");
    if (!process.env.LINEAR_API_KEY) throw new Error("Linear credentials missing: LINEAR_API_KEY (a personal API key)");
  }
  async gql(query, variables = {}) {
    const r = await fetch(this.url, { method: "POST", headers: { Authorization: process.env.LINEAR_API_KEY, "Content-Type": "application/json" },
      body: JSON.stringify({ query, variables }) });
    const text = await r.text();
    let j; try { j = JSON.parse(text); } catch { throw new Error(`Linear → ${r.status}: ${text.slice(0, 300)}`); }
    if (!r.ok || j.errors?.length) throw new Error(`Linear → ${r.status}: ${(j.errors ?? []).map((e) => e.message).join("; ") || text.slice(0, 300)}`);
    return j.data;
  }
  async team() {
    if (!this._team) {
      const d = await this.gql(`query($key: String!) { teams(filter: {key: {eq: $key}}) { nodes { id key name states { nodes { id name } } } } }`, { key: this.teamKey });
      this._team = d.teams.nodes[0];
      if (!this._team) throw new Error(`no Linear team with key ${this.teamKey} visible to this API key`);
    }
    return this._team;
  }
  async state(name) {
    const t = await this.team(), s = t.states.nodes.find((x) => x.name.toLowerCase() === String(name).toLowerCase());
    if (!s) throw new Error(`the team ${t.key} has no workflow state '${name}' (has: ${t.states.nodes.map((x) => x.name).join(", ")}) — add it, or map it in settings.tracker.columns`);
    return s;
  }
  async create(input) {
    const d = await this.gql(`mutation($input: IssueCreateInput!) { issueCreate(input: $input) { success issue { id identifier url } } }`, { input });
    return d.issueCreate.issue;
  }
  async open() {
    const team = await this.team();
    if (!this.job.tracker?.epic) {
      const i = await this.create({ teamId: team.id, title: this.job.title, description: `/deliver job ${this.job.id}\n\n${this.job.request.slice(0, 3000)}` });
      this.job.tracker = { kind: "linear", epic: i.id, epic_key: i.identifier, url: i.url }; this.saveJob();
    }
    for (const c of this.board.cards) if (!c.tracker?.id) {
      const i = await this.create({ teamId: team.id, title: `${c.id}: ${c.title}`.slice(0, 250), description: this.description(c),
        parentId: this.job.tracker.epic, stateId: (await this.state(this.columns[stageOf(c)])).id });
      c.tracker = { kind: "linear", id: i.id, key: i.identifier, url: i.url, column: this.columns[stageOf(c)] }; this.saveBoard();
      for (const d of c.depends_on ?? []) {
        const dep = this.board.cards.find((x) => x.id === d)?.tracker?.id;
        if (dep) await this.gql(`mutation($input: IssueRelationCreateInput!) { issueRelationCreate(input: $input) { success } }`,
          { input: { issueId: dep, relatedIssueId: i.id, type: "blocks" } }).catch(() => {});
      }
    }
    await this.sync();
  }
  async update(id, input) { await this.gql(`mutation($id: String!, $input: IssueUpdateInput!) { issueUpdate(id: $id, input: $input) { success } }`, { id, input }); }
  async sync(card, event) {
    const cards = card ? [this.card(card)] : this.board.cards;
    for (const c of cards) {
      if (!c.tracker?.id) await this.open();
      const target = this.columns[stageOf(c)];
      if (c.tracker.column === target) continue;
      await this.update(c.tracker.id, { stateId: (await this.state(target)).id });
      c.tracker.column = target; this.saveBoard();
      if (event) await this.note(c.id, "michael", event);
    }
  }
  async note(card, author, text) {
    const c = this.card(card);
    if (!c.tracker?.id) await this.open();
    await this.gql(`mutation($input: CommentCreateInput!) { commentCreate(input: $input) { success } }`, { input: { issueId: c.tracker.id, body: `**[${author}]** ${text}` } });
  }
  description(c) {
    return [c.context, "**Acceptance criteria**\n" + (c.acceptance ?? []).map((a) => `- ${a}`).join("\n"),
      `Component: ${c.component ?? "-"}  ·  Scope: ${(c.scope ?? []).join(", ")}  ·  QA tests: ${(c.qa_scope ?? []).join(", ")}`,
      `Verify: \`${c.verify}\`  ·  QA verify: \`${c.qa_verify ?? "-"}\``,
      ...(c.branch ? [`Development: branch \`${c.branch}\`${c.branch_url ? ` — ${c.branch_url}` : ""}`] : [])].join("\n\n");
  }
  async branch(card) {
    const c = this.card(card);
    if (!c.branch) return;
    if (!c.tracker?.id) await this.open();
    await this.update(c.tracker.id, { description: this.description(c) });
    if (c.branch_url && c.tracker.branch_linked !== c.branch_url) {
      await this.gql(`mutation($issueId: String!, $url: String!, $title: String) { attachmentLinkURL(issueId: $issueId, url: $url, title: $title) { success } }`,
        { issueId: c.tracker.id, url: c.branch_url, title: `branch ${c.branch}` });
      c.tracker.branch_linked = c.branch_url; this.saveBoard();
    }
    await this.note(card, "michael", `branch \`${c.branch}\`${c.branch_url ? ` (${c.branch_url})` : ""}`);
  }
  where() { return this.job.tracker?.url ? `linear: ${this.job.tracker.url}` : `linear: team ${this.teamKey}`; }
  async check() {
    const out = [], ok = (m) => out.push({ ok: true, msg: m }), bad = (m) => out.push({ ok: false, msg: m });
    try { const d = await this.gql(`query { viewer { name email } }`); ok(`signed in to Linear as ${d.viewer.email ?? d.viewer.name} (LINEAR_API_KEY)`); }
    catch (e) { bad(`cannot sign in to Linear: ${e.message}`); return out; }
    let t; try { t = await this.team(); ok(`team ${t.key}: ${t.name}`); } catch (e) { bad(e.message); return out; }
    const names = new Set(t.states.nodes.map((s) => s.name.toLowerCase()));
    const missing = Object.entries(this.columns).filter(([, n]) => !names.has(String(n).toLowerCase()));
    if (missing.length) bad(`the team ${t.key} has no workflow state for: ${missing.map(([k, n]) => `${k} → '${n}'`).join(", ")} — add them in Linear, or map each to one it has in tracker.columns`);
    else ok(`the team ${t.key} has a workflow state for every column (${Object.values(this.columns).join(", ")})`);
    return out;
  }
}
registerTracker("linear", LinearTracker);
