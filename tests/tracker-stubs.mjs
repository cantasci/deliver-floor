#!/usr/bin/env node
// Local stand-ins for the parts of the Asana, Linear and GitHub APIs that kit/skills/deliver/bin/trackers/*.mjs use — for
// tests without accounts. Each enforces what its vendor documents for these calls (auth header form, required fields, the
// columns that exist) and writes one common shape to <state.json> after every change, so the tests read all three alike:
//   { container: {id, title}, items: {<id>: {title, parent, column, comments: [], blocked_by: [], body}}, calls: [] }
//   node tracker-stubs.mjs asana|linear|github <state.json> [port]      prints "listening <port>"
//   STUB_COLUMNS_FILE (re-read on every request): the columns the board has, comma-separated (drop one to test errors)
import { createServer } from "node:http";
import { writeFileSync, readFileSync, existsSync } from "node:fs";

const [kind, stateFile, port = "0"] = process.argv.slice(2);
const columns = () => (process.env.STUB_COLUMNS_FILE && existsSync(process.env.STUB_COLUMNS_FILE)
  ? readFileSync(process.env.STUB_COLUMNS_FILE, "utf8").trim() : "To Do,In Progress,QA,Code Review,Done,Blocked,Won't Do").split(",");
const st = { container: null, items: {}, calls: [] };
let n = 0;
const save = () => writeFileSync(stateFile, JSON.stringify(st, null, 2));
const send = (res, code, body) => { res.writeHead(code, { "Content-Type": "application/json" }); res.end(JSON.stringify(body)); };
const item = (id, title, parent) => (st.items[id] = { title, parent: parent ?? null, column: null, comments: [], blocked_by: [], body: "" });

// ---- Asana: REST, {data: …} envelopes, Bearer personal access token ---------------------------------------------------
const PROJECT = "1200", sectionGid = (i) => `s${i}`;
function asana(req, path, body, res) {
  if (!/^Bearer .+/.test(req.headers.authorization ?? "")) return send(res, 401, { errors: [{ message: "Not Authorized" }] });
  const d = body?.data ?? {}, A = (code, data) => send(res, code, { data });
  let m;
  if (req.method === "GET" && path === "/users/me") return A(200, { gid: "1", name: "Bot", email: "bot@example.com" });
  if (req.method === "GET" && path === `/projects/${PROJECT}`) return A(200, { gid: PROJECT, name: "Watchlist" });
  if (req.method === "GET" && /^\/projects\/[^/]+$/.test(path)) return send(res, 404, { errors: [{ message: "project: Not a recognized ID" }] });
  if (req.method === "GET" && path === `/projects/${PROJECT}/sections`) return A(200, columns().map((name, i) => ({ gid: sectionGid(i), name })));
  if (req.method === "POST" && path === "/tasks") {
    if (!d.name) return send(res, 400, { errors: [{ message: "name: Missing input" }] });
    if (!(d.projects?.length || d.workspace || d.parent)) return send(res, 400, { errors: [{ message: "workspace: Missing input" }] });
    if (d.parent && d.parent !== st.container?.id) return send(res, 404, { errors: [{ message: "parent: Not a recognized ID" }] });
    const gid = String(9000 + ++n);
    if (d.parent) item(gid, d.name, d.parent); else st.container = { id: gid, title: d.name };
    if (st.items[gid]) st.items[gid].body = d.notes ?? "";
    save(); return A(201, { gid, name: d.name, permalink_url: `https://app.asana.com/0/${PROJECT}/${gid}` });
  }
  if (req.method === "POST" && (m = path.match(/^\/tasks\/(\d+)\/addDependencies$/))) {
    if (!Array.isArray(d.dependencies)) return send(res, 400, { errors: [{ message: "dependencies: Missing input" }] });
    st.items[m[1]].blocked_by.push(...d.dependencies); save(); return A(200, {});
  }
  if (req.method === "POST" && (m = path.match(/^\/sections\/s(\d+)\/addTask$/))) {
    const col = columns()[Number(m[1])];
    if (!col || !st.items[d.task]) return send(res, 404, { errors: [{ message: "Not a recognized ID" }] });
    st.items[d.task].column = col; save(); return A(200, {});
  }
  if (req.method === "POST" && (m = path.match(/^\/tasks\/(\d+)\/stories$/))) {
    if (!d.text) return send(res, 400, { errors: [{ message: "text: Missing input" }] });
    st.items[m[1]].comments.push(d.text); save(); return A(201, { gid: String(++n), text: d.text });
  }
  if (req.method === "PUT" && (m = path.match(/^\/tasks\/(\d+)$/))) { if (d.notes) st.items[m[1]].body = d.notes; save(); return A(200, { gid: m[1] }); }
  return send(res, 404, { errors: [{ message: `no route ${req.method} ${path}` }] });
}

// ---- Linear: GraphQL, the personal API key as the Authorization header itself (no "Bearer") ---------------------------
function linear(req, path, body, res) {
  const auth = req.headers.authorization ?? "";
  if (path !== "/graphql") return send(res, 404, { errors: [{ message: "not found" }] });
  if (!auth || auth.startsWith("Bearer ")) return send(res, 400, { errors: [{ message: "Authentication required, not authenticated" }] });
  const q = body?.query ?? "", v = body?.variables ?? {}, D = (data) => send(res, 200, { data }), E = (msg) => send(res, 200, { errors: [{ message: msg }] });
  const states = columns().map((name, i) => ({ id: `st${i}`, name }));
  if (/\bviewer\b/.test(q)) return D({ viewer: { name: "Bot", email: "bot@example.com" } });
  if (/\bteams\(/.test(q)) return D({ teams: { nodes: v.key === "WL" ? [{ id: "team1", key: "WL", name: "Watchlist", states: { nodes: states } }] : [] } });
  if (/\bissueCreate\(/.test(q)) {
    const i = v.input ?? {};
    if (!i.teamId) return E("Argument Validation Error: teamId must be a UUID");
    if (i.parentId && i.parentId !== st.container?.id) return E("Argument Validation Error: parentId must be a UUID of an existing issue");
    const id = `iss${++n}`, identifier = `WL-${n}`;
    if (i.parentId) { item(id, i.title, i.parentId); st.items[id].body = i.description ?? ""; if (i.stateId) st.items[id].column = states.find((s) => s.id === i.stateId)?.name ?? null; }
    else st.container = { id, title: i.title };
    st.items[id] && (st.items[id].key = identifier);
    save(); return D({ issueCreate: { success: true, issue: { id, identifier, url: `https://linear.app/acme/issue/${identifier}` } } });
  }
  if (/\bissueRelationCreate\(/.test(q)) {
    const i = v.input ?? {};
    if (!i.issueId || !i.relatedIssueId || i.type !== "blocks") return E("Argument Validation Error");
    st.items[i.relatedIssueId].blocked_by.push(i.issueId); save(); return D({ issueRelationCreate: { success: true } });
  }
  if (/\bissueUpdate\(/.test(q)) {
    const it = st.items[v.id]; if (!it) return E("Entity not found");
    if (v.input?.stateId) { const s = states.find((x) => x.id === v.input.stateId); if (!s) return E("stateId not found"); it.column = s.name; }
    if (v.input?.description) it.body = v.input.description;
    save(); return D({ issueUpdate: { success: true } });
  }
  if (/\bcommentCreate\(/.test(q)) { st.items[v.input.issueId].comments.push(v.input.body); save(); return D({ commentCreate: { success: true } }); }
  if (/\battachmentLinkURL\(/.test(q)) { (st.items[v.issueId].links ??= []).push(v.url); save(); return D({ attachmentLinkURL: { success: true } }); }
  return E(`unknown operation: ${q.slice(0, 80)}`);
}

// ---- GitHub: REST (+ sub-issues, dependencies) and GraphQL for Projects (v2), Bearer token -------------------------------
const gh = { issues: {}, byNode: {}, items: {} };
function github(req, path, body, res) {
  if (!/^Bearer .+/.test(req.headers.authorization ?? "")) return send(res, 401, { message: "Requires authentication" });
  let m; const b = body ?? {};
  const opts = () => columns().map((name, i) => ({ id: `opt${i}`, name }));
  if (path === "/graphql") {
    const q = b.query ?? "", v = b.variables ?? {}, D = (data) => send(res, 200, { data }), E = (msg) => send(res, 200, { data: null, errors: [{ message: msg }] });
    if (/\borganization\(login/.test(q)) return v.o === "acme" ? D({ organization: { projectV2: v.n === 7 ? { id: "PVT_1", url: "https://github.com/orgs/acme/projects/7", title: "Delivery",
      fields: { nodes: [{ id: "F_title", name: "Title" }, { id: "F_status", name: "Status", options: opts() }] } } : null } }) : E(`Could not resolve to an Organization with the login of '${v.o}'.`);
    if (/\buser\(login/.test(q)) return E(`Could not resolve to a User with the login of '${v.o}'.`);
    if (/\baddProjectV2ItemById\(/.test(q)) {
      const iss = gh.byNode[v.c]; if (v.p !== "PVT_1" || !iss) return E("Could not resolve to a node");
      const itemId = `PVTI_${iss.number}`; gh.items[itemId] = iss.number; return D({ addProjectV2ItemById: { item: { id: itemId } } });
    }
    if (/\bupdateProjectV2ItemFieldValue\(/.test(q)) {
      const num = gh.items[v.i], o = opts().find((x) => x.id === v.o);
      if (v.f !== "F_status" || !num || !o) return E("The single select option Id does not belong to the field");
      st.items[num].column = o.name; save(); return D({ updateProjectV2ItemFieldValue: { projectV2Item: { id: v.i } } });
    }
    return E("unknown operation");
  }
  if (req.method === "GET" && path === "/user") return send(res, 200, { login: "deliver-bot" });
  if (req.method === "GET" && path === "/repos/acme/demo") return send(res, 200, { full_name: "acme/demo", has_issues: true });
  if (req.method === "GET" && path.startsWith("/repos/")) return send(res, 404, { message: "Not Found" });
  if (req.method === "POST" && path === "/repos/acme/demo/issues") {
    if (!b.title) return send(res, 422, { message: "Validation Failed: title" });
    const number = ++n, id = 50000 + number, node_id = `I_${number}`;
    gh.issues[number] = { id, node_id }; gh.byNode[node_id] = { number };
    if (st.container) { item(number, b.title, null); st.items[number].body = b.body ?? ""; } else st.container = { id: number, title: b.title };
    save(); return send(res, 201, { number, id, node_id, html_url: `https://github.com/acme/demo/issues/${number}` });
  }
  if (req.method === "POST" && (m = path.match(/^\/repos\/acme\/demo\/issues\/(\d+)\/sub_issues$/))) {
    const num = Object.keys(gh.issues).find((k) => gh.issues[k].id === b.sub_issue_id);
    if (!num || Number(m[1]) !== st.container?.id) return send(res, 422, { message: "Validation Failed" });
    st.items[num].parent = Number(m[1]); save(); return send(res, 201, {});
  }
  if (req.method === "POST" && (m = path.match(/^\/repos\/acme\/demo\/issues\/(\d+)\/dependencies\/blocked_by$/))) {
    const dep = Object.keys(gh.issues).find((k) => gh.issues[k].id === b.issue_id);
    if (!dep) return send(res, 422, { message: "Validation Failed" });
    st.items[m[1]].blocked_by.push(Number(dep)); save(); return send(res, 201, {});
  }
  if (req.method === "POST" && (m = path.match(/^\/repos\/acme\/demo\/issues\/(\d+)\/comments$/))) {
    if (!b.body) return send(res, 422, { message: "Validation Failed: body" });
    st.items[m[1]].comments.push(b.body); save(); return send(res, 201, {});
  }
  if (req.method === "PATCH" && (m = path.match(/^\/repos\/acme\/demo\/issues\/(\d+)$/))) { if (b.body) st.items[m[1]].body = b.body; save(); return send(res, 200, {}); }
  return send(res, 404, { message: `no route ${req.method} ${path}` });
}

const routes = { asana, linear, github };
if (!routes[kind]) { console.error("usage: tracker-stubs.mjs asana|linear|github <state.json> [port]"); process.exit(2); }
const srv = createServer(async (req, res) => {
  let raw = ""; for await (const ch of req) raw += ch;
  const path = req.url.split("?")[0].replace(/^\/api\/1\.0/, "");
  st.calls.push({ method: req.method, url: req.url }); save();
  try { routes[kind](req, path, raw ? JSON.parse(raw) : null, res); } catch (e) { send(res, 500, { message: String(e.stack ?? e) }); }
});
srv.listen(Number(port), "127.0.0.1", () => { save(); console.log(`listening ${srv.address().port}`); });
