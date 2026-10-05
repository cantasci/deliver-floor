#!/usr/bin/env node
// A local stand-in for the part of the Jira Cloud REST API v3 that tracker.mjs uses — for tests without a Jira site.
// It enforces what Jira enforces for these calls (auth header, required fields, transitions only to statuses of the
// workflow) and writes its whole state to a JSON file after every change, so tests can assert on it.
//   node jira-stub.mjs <state.json> [port]        prints "listening <port>"
//   env STUB_STATUSES="To Do,In Progress,QA,Code Review,Done,Blocked,Won't Do"   the workflow (drop one to test errors)
import { createServer } from "node:http";
import { writeFileSync, readFileSync, existsSync } from "node:fs";

const stateFile = process.argv[2];
// the workflow's statuses; STUB_STATUSES_FILE (re-read on every request) lets a test change the workflow mid-run
const statusesNow = () => (process.env.STUB_STATUSES_FILE && existsSync(process.env.STUB_STATUSES_FILE)
  ? readFileSync(process.env.STUB_STATUSES_FILE, "utf8").trim() : process.env.STUB_STATUSES ?? "To Do,In Progress,QA,Code Review,Done,Blocked,Won't Do").split(",");
let statuses = statusesNow();
const st = { issues: {}, links: [], calls: [] };
let n = 0;
const save = () => writeFileSync(stateFile, JSON.stringify(st, null, 2));
const send = (res, code, body) => { res.writeHead(code, { "Content-Type": "application/json" }); res.end(body === undefined ? "" : JSON.stringify(body)); };

createServer(async (req, res) => {
  let raw = ""; for await (const ch of req) raw += ch;
  const body = raw ? JSON.parse(raw) : null;
  statuses = statusesNow();
  st.calls.push({ method: req.method, url: req.url }); save();
  if (!/^(Basic|Bearer) .+/.test(req.headers.authorization ?? "")) return send(res, 401, { errorMessages: ["unauthorized"] });
  const m = req.url.match(/^\/rest\/api\/3(\/.*)$/);
  if (!m) return send(res, 404, { errorMessages: ["not found"] });
  const path = m[1];
  let x;
  if (req.method === "POST" && path === "/issue") {
    const f = body?.fields ?? {};
    if (!f.project?.key || !f.issuetype?.name || !f.summary) return send(res, 400, { errors: { fields: "project, issuetype and summary are required" } });
    if (f.parent && !st.issues[f.parent.key]) return send(res, 400, { errors: { parent: "parent issue does not exist" } });
    const key = `${f.project.key}-${++n}`;
    st.issues[key] = { key, fields: f, status: statuses[0], comments: [], remotelinks: [] }; save();
    return send(res, 201, { id: String(n), key, self: `/rest/api/3/issue/${key}` });
  }
  if ((x = path.match(/^\/issue\/([A-Z0-9]+-\d+)(\?.*)?$/)) && req.method === "GET") {
    const i = st.issues[x[1]]; if (!i) return send(res, 404, {});
    return send(res, 200, { key: i.key, fields: { ...i.fields, status: { name: i.status } } });
  }
  if ((x = path.match(/^\/issue\/([A-Z0-9]+-\d+)$/)) && req.method === "PUT") {
    const i = st.issues[x[1]]; if (!i) return send(res, 404, {});
    Object.assign(i.fields, body?.fields ?? {}); save(); return send(res, 204);
  }
  if ((x = path.match(/^\/issue\/([A-Z0-9]+-\d+)\/transitions$/))) {
    const i = st.issues[x[1]]; if (!i) return send(res, 404, {});
    if (req.method === "GET") return send(res, 200, { transitions: statuses.filter((s) => s !== i.status).map((s) => ({ id: String(statuses.indexOf(s) + 11), name: `to ${s}`, to: { name: s } })) });
    const target = statuses[Number(body?.transition?.id) - 11];
    if (!target || target === i.status) return send(res, 400, { errorMessages: ["invalid transition"] });
    i.status = target; save(); return send(res, 204);
  }
  if ((x = path.match(/^\/issue\/([A-Z0-9]+-\d+)\/comment$/)) && req.method === "POST") {
    const i = st.issues[x[1]]; if (!i) return send(res, 404, {});
    const text = JSON.stringify(body?.body ?? ""); i.comments.push(text); save(); return send(res, 201, { id: String(i.comments.length) });
  }
  if ((x = path.match(/^\/issue\/([A-Z0-9]+-\d+)\/remotelink$/)) && req.method === "POST") {
    const i = st.issues[x[1]]; if (!i) return send(res, 404, {});
    if (!body?.object?.url) return send(res, 400, { errors: { url: "required" } });
    i.remotelinks.push(body); save(); return send(res, 201, { id: i.remotelinks.length });
  }
  if (path === "/issueLink" && req.method === "POST") { st.links.push(body); save(); return send(res, 201); }
  return send(res, 404, { errorMessages: [`no stub for ${req.method} ${path}`] });
}).listen(Number(process.argv[3] ?? 0), "127.0.0.1", function () { console.log(`listening ${this.address().port}`); });
