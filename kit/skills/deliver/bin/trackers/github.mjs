// GitHub Projects — the job is an issue in the repo, every card a sub-issue of it, added to an existing project (v2); the
// project's single-select Status field has the columns as its options. Built from GitHub's official descriptions:
// REST (github.com/github/rest-api-description, api.github.com) and the GraphQL schema (github.com/octokit/graphql-schema):
//   GET  /user · GET /repos/{owner}/{repo}                                     who the token is, the repo (check)
//   POST /repos/{o}/{r}/issues {title, body, labels}                         the job issue, then each card
//   POST /repos/{o}/{r}/issues/{n}/sub_issues {sub_issue_id}                 the card under the job (the REST issue id)
//   POST /repos/{o}/{r}/issues/{n}/dependencies/blocked_by {issue_id}        depends_on
//   POST /repos/{o}/{r}/issues/{n}/comments {body} · PATCH /repos/{o}/{r}/issues/{n} {body}
//   POST /graphql: user|organization(login) { projectV2(number) { id url fields { … on ProjectV2SingleSelectField } } }
//                  addProjectV2ItemById(input: {projectId, contentId: issue node_id}) · updateProjectV2ItemFieldValue(
//                  input: {projectId, itemId, fieldId, value: {singleSelectOptionId}})
// Credentials: GITHUB_TOKEN (or GH_TOKEN) with access to the repo's issues and the project. Settings: tracker.github =
// {repo: "owner/name", project: <number>, project_owner: <login, default the repo's owner>, status_field: "Status", labels: []}.
import { Tracker, registerTracker, stageOf } from "../tracker.mjs";

export class GitHubTracker extends Tracker {
  constructor(jobDir) {
    super(jobDir);
    const cfg = this.job.settings?.tracker?.github ?? {};
    this.api = (process.env.GITHUB_API_URL ?? "https://api.github.com").replace(/\/$/, "");
    [this.owner, this.name] = String(cfg.repo ?? "").split("/");
    if (!this.owner || !this.name) throw new Error("settings.tracker.github.repo is not set (owner/name)");
    this.number = Number(cfg.project);
    if (!this.number) throw new Error("settings.tracker.github.project is not set (the project's number, from its URL)");
    this.projectOwner = cfg.project_owner ?? this.owner;
    this.statusField = cfg.status_field ?? "Status";
    this.labels = cfg.labels ?? [];
    this.token = process.env.GITHUB_TOKEN ?? process.env.GH_TOKEN;
    if (!this.token) throw new Error("GitHub credentials missing: GITHUB_TOKEN (or GH_TOKEN)");
  }
  async rest(method, path, body) {
    const r = await fetch(`${this.api}${path}`, { method, headers: { Authorization: `Bearer ${this.token}`, Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28", "Content-Type": "application/json" }, body: body ? JSON.stringify(body) : undefined });
    const text = await r.text();
    if (!r.ok) { let m = text.slice(0, 300); try { m = JSON.parse(text).message; } catch { /* raw */ } throw new Error(`GitHub ${method} ${path} → ${r.status}: ${m}`); }
    return text ? JSON.parse(text) : {};
  }
  async gql(query, variables = {}) {
    const r = await fetch(`${this.api}/graphql`, { method: "POST", headers: { Authorization: `Bearer ${this.token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ query, variables }) });
    const text = await r.text();
    let j; try { j = JSON.parse(text); } catch { throw new Error(`GitHub GraphQL → ${r.status}: ${text.slice(0, 300)}`); }
    if (!r.ok || j.errors?.length) throw new Error(`GitHub GraphQL → ${r.status}: ${(j.errors ?? []).map((e) => e.message).join("; ") || text.slice(0, 300)}`);
    return j.data;
  }
  async project() {
    if (!this._project) {
      const fields = `projectV2(number: $n) { id url title fields(first: 50) { nodes { ... on ProjectV2SingleSelectField { id name options { id name } } } } }`;
      let p = null;
      for (const who of ["organization", "user"]) {
        try { p = (await this.gql(`query($o: String!, $n: Int!) { ${who}(login: $o) { ${fields} } }`, { o: this.projectOwner, n: this.number }))[who]?.projectV2; }
        catch { /* the login is the other kind */ }
        if (p) break;
      }
      if (!p) throw new Error(`no project #${this.number} of ${this.projectOwner} visible to this token`);
      p.status = p.fields.nodes.find((f) => f?.name === this.statusField && f.options);
      this._project = p;
    }
    return this._project;
  }
  async open() {
    const repo = `/repos/${this.owner}/${this.name}`;
    if (!this.job.tracker?.epic) {
      const i = await this.rest("POST", `${repo}/issues`, { title: this.job.title, body: `/deliver job ${this.job.id}\n\n${this.job.request.slice(0, 3000)}`, labels: this.labels });
      this.job.tracker = { kind: "github", epic: i.number, url: i.html_url }; this.saveJob();
    }
    const p = await this.project();
    for (const c of this.board.cards) if (!c.tracker?.number) {
      const i = await this.rest("POST", `${repo}/issues`, { title: `${c.id}: ${c.title}`.slice(0, 250), body: this.description(c), labels: this.labels });
      c.tracker = { kind: "github", number: i.number, id: i.id, url: i.html_url, column: null }; this.saveBoard();
      await this.rest("POST", `${repo}/issues/${this.job.tracker.epic}/sub_issues`, { sub_issue_id: i.id }).catch(() => {});
      const d = await this.gql(`mutation($p: ID!, $c: ID!) { addProjectV2ItemById(input: {projectId: $p, contentId: $c}) { item { id } } }`, { p: p.id, c: i.node_id });
      c.tracker.item = d.addProjectV2ItemById.item.id; this.saveBoard();
      for (const dep of c.depends_on ?? []) {
        const did = this.board.cards.find((x) => x.id === dep)?.tracker?.id;
        if (did) await this.rest("POST", `${repo}/issues/${i.number}/dependencies/blocked_by`, { issue_id: did }).catch(() => {});
      }
    }
    await this.sync();
  }
  async sync(card, event) {
    const cards = card ? [this.card(card)] : this.board.cards;
    for (const c of cards) {
      if (!c.tracker?.item) await this.open();
      const target = this.columns[stageOf(c)];
      if (c.tracker.column === target) continue;
      const p = await this.project();
      if (!p.status) throw new Error(`project #${this.number} has no single-select field '${this.statusField}' — set tracker.github.status_field`);
      const o = p.status.options.find((x) => x.name.toLowerCase() === String(target).toLowerCase());
      if (!o) throw new Error(`${c.id}: the '${this.statusField}' field has no option '${target}' (has: ${p.status.options.map((x) => x.name).join(", ")}) — add it, or map it in settings.tracker.columns`);
      await this.gql(`mutation($p: ID!, $i: ID!, $f: ID!, $o: String!) { updateProjectV2ItemFieldValue(input: {projectId: $p, itemId: $i, fieldId: $f, value: {singleSelectOptionId: $o}}) { projectV2Item { id } } }`,
        { p: p.id, i: c.tracker.item, f: p.status.id, o: o.id });
      c.tracker.column = target; this.saveBoard();
      if (event) await this.note(c.id, "michael", event);
    }
  }
  async note(card, author, text) {
    const c = this.card(card);
    if (!c.tracker?.number) await this.open();
    await this.rest("POST", `/repos/${this.owner}/${this.name}/issues/${c.tracker.number}/comments`, { body: `**[${author}]** ${text}` });
  }
  description(c) {
    return [c.context, "**Acceptance criteria**\n" + (c.acceptance ?? []).map((a) => `- [ ] ${a}`).join("\n"),
      `Component: ${c.component ?? "-"}  ·  Scope: ${(c.scope ?? []).map((s) => `\`${s}\``).join(", ")}  ·  QA tests: ${(c.qa_scope ?? []).map((s) => `\`${s}\``).join(", ")}`,
      `Verify: \`${c.verify}\`  ·  QA verify: \`${c.qa_verify ?? "-"}\``,
      ...(c.branch ? [`Development: branch \`${c.branch}\`${c.branch_url ? ` — ${c.branch_url}` : ""}`] : [])].join("\n\n");
  }
  async branch(card) {
    const c = this.card(card);
    if (!c.branch) return;
    if (!c.tracker?.number) await this.open();
    await this.rest("PATCH", `/repos/${this.owner}/${this.name}/issues/${c.tracker.number}`, { body: this.description(c) });
    await this.note(card, "michael", `branch \`${c.branch}\`${c.branch_url ? ` (${c.branch_url})` : ""}`);
  }
  where() { return this.job.tracker?.url ? `github: ${this.job.tracker.url} (project #${this.number})` : `github: ${this.owner}/${this.name}, project #${this.number}`; }
  async check() {
    const out = [], ok = (m) => out.push({ ok: true, msg: m }), bad = (m) => out.push({ ok: false, msg: m });
    try { const me = await this.rest("GET", "/user"); ok(`signed in to GitHub as ${me.login} (${process.env.GITHUB_TOKEN ? "GITHUB_TOKEN" : "GH_TOKEN"})`); }
    catch (e) { bad(`cannot sign in to GitHub: ${e.message}`); return out; }
    try { const r = await this.rest("GET", `/repos/${this.owner}/${this.name}`); (r.has_issues === false ? bad : ok)(`repo ${r.full_name}${r.has_issues === false ? ": issues are turned off" : ""}`); }
    catch (e) { bad(`repo ${this.owner}/${this.name} is not visible to this token: ${e.message}`); return out; }
    let p; try { p = await this.project(); ok(`project #${this.number}: ${p.title}`); } catch (e) { bad(e.message); return out; }
    if (!p.status) { bad(`project #${this.number} has no single-select field '${this.statusField}' — set tracker.github.status_field`); return out; }
    const names = new Set(p.status.options.map((o) => o.name.toLowerCase()));
    const missing = Object.entries(this.columns).filter(([, n]) => !names.has(String(n).toLowerCase()));
    if (missing.length) bad(`the '${this.statusField}' field has no option for: ${missing.map(([k, n]) => `${k} → '${n}'`).join(", ")} — add them in the project, or map each to one it has in tracker.columns`);
    else ok(`the '${this.statusField}' field has an option for every column (${Object.values(this.columns).join(", ")})`);
    return out;
  }
}
registerTracker("github", GitHubTracker);
