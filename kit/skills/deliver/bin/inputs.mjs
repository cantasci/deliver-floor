#!/usr/bin/env node
// What only a person can provide before the work runs — credentials, API keys, accounts, a .env file (readiness DEL-inputs).
// The readiness review lists them in readiness.json → "inputs"; the human puts each one where it says, dl checks it, and a
// card that needs one (card.inputs) is not assigned while it is missing.
//   "inputs": [{"id":"IN-1", "what":"Mambu sandbox API key", "file":"/Users/me/.config/watchlist/.env.local",
//               "link":".env.local", "keys":["MAMBU_API_KEY","MAMBU_BASE_URL"],
//               "check":"curl -s -o /dev/null -w '%{http_code}' -H \"apikey: $MAMBU_API_KEY\" \"$MAMBU_BASE_URL/api/users/me\"",
//               "for":"the customer service's live mapping (its integration tests)",
//               "evidence":"services/customer/mambu.py reads MAMBU_API_KEY"}]
// evidence — why the work needs it: the request's words or the file that reads it. Asked for only then — never by default
// file  — where the human puts it: an absolute path, outside the repo or git-ignored in it (never committed)
// link  — where the code reads it, repo-relative: dl links it into every card, QA and integration worktree (git-ignored there)
// keys  — the variables the file must give a value (KEY=value lines); their values are never printed
// check — one read-only call that proves it works (it gets the file's variables and DELIVER_INPUT=<file>); an HTTP status as
//         its last output line counts: 2xx/3xx pass. Only the status is reported, never the output.
// Seen live: a card needed .env.local and nobody asked for it at the start; the human put it in docs/dev/ (not ignored), the
// .gitignore entry existed only on the job branch, and the key was first used on the last day — 401, four cards deferred.
//   node inputs.mjs check <job dir> [IN-n …]   → JSON [{id, what, ok, detail}]
//   node inputs.mjs list <job dir>             → JSON [{…input}]
import { readFileSync, existsSync, statSync } from "node:fs";
import { join, isAbsolute, relative, resolve } from "node:path";
import { homedir } from "node:os";
import { execFileSync, spawnSync } from "node:child_process";
import { pathToFileURL } from "node:url";

const KEY = /^[A-Za-z_][A-Za-z0-9_]*$/;
const home = (p) => String(p ?? "").replace(/^~(?=\/|$)/, homedir());

export function inputsOf(jobDir) {
  try {
    const r = JSON.parse(readFileSync(join(jobDir, "readiness.json"), "utf8"));
    return Array.isArray(r) ? [] : Array.isArray(r.inputs) ? r.inputs : [];
  } catch { return []; }
}

// the shape readiness.mjs checks before the freeze; items = the readiness items (DEL-inputs says whether there are any)
export function shapeErrors(raw, items) {
  const errors = [], inputs = raw ?? [];
  if (!Array.isArray(inputs)) return ["inputs must be an array"];
  const seen = new Set();
  for (const i of inputs) {
    const id = i?.id ?? "(no id)";
    if (!/^IN-\d+$/.test(id)) errors.push(`${id}: an input's id looks like IN-1`);
    if (seen.has(id)) errors.push(`${id}: duplicate id`);
    seen.add(id);
    if (!String(i?.what ?? "").trim()) errors.push(`${id}: 'what' says what the human provides (e.g. "Mambu sandbox API key")`);
    // asked for only when the work needs it (the user's rule: an .env file is not required by default)
    if (!String(i?.evidence ?? "").trim()) errors.push(`${id}: 'evidence' says why the work needs it — the request's words, or the file that reads it (e.g. "src/mambu/client.py reads MAMBU_API_KEY"); no evidence, no input`);
    if (!isAbsolute(home(i?.file))) errors.push(`${id}: 'file' is the absolute path where the human puts it (outside the repo, or git-ignored in it)`);
    if (i?.link !== undefined && (typeof i.link !== "string" || !i.link.trim() || isAbsolute(i.link) || i.link.split("/").includes("..")))
      errors.push(`${id}: 'link' is the repo-relative path the code reads it from (e.g. ".env.local")`);
    if (i?.keys !== undefined && (!Array.isArray(i.keys) || i.keys.some((k) => !KEY.test(String(k)))))
      errors.push(`${id}: 'keys' lists variable names (["API_KEY"]) — never their values`);
    if (i?.check !== undefined && (typeof i.check !== "string" || !i.check.trim())) errors.push(`${id}: 'check' is one read-only command`);
  }
  const di = (items ?? []).find((x) => x.id === "DEL-inputs");
  if (di?.status === "decided" && !inputs.length) errors.push("DEL-inputs is decided — list each input in readiness.json → inputs (id, what, file, link, keys, check)");
  if (di?.status === "n_a" && inputs.length) errors.push(`DEL-inputs is n/a, but inputs lists ${inputs.map((i) => i.id).join(", ")}`);
  return errors;
}

export function parseEnv(text) {
  const env = {};
  for (const line of String(text).split(/\r?\n/)) {
    const m = line.match(/^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (!m) continue;
    let v = m[2].trim();
    if (/^(['"]).*\1$/.test(v)) v = v.slice(1, -1);
    else v = v.replace(/\s+#.*$/, "");
    env[m[1]] = v;
  }
  return env;
}

const git = (repo, args) => {
  try { execFileSync("git", ["-C", repo, ...args], { stdio: "ignore" }); return true; } catch { return false; }
};
const inside = (repo, p) => { const r = relative(resolve(repo), resolve(p)); return r && !r.startsWith("..") && !isAbsolute(r) ? r : null; };

// checkInput(input, repo) → {id, what, ok, detail}: the file is there, never committed, gives its keys, and its check passes
export function checkInput(input, repo, { timeout = 60 } = {}) {
  const out = { id: input.id, what: input.what, ok: false, detail: "" };
  const file = home(input.file), notes = [];
  let st;
  try { st = statSync(file); } catch { out.detail = `missing: nothing at ${file}`; return out; }
  if (!st.isFile() || st.size === 0) { out.detail = `${file} is ${st.isFile() ? "empty" : "not a file"}`; return out; }
  const rel = inside(repo, file);
  if (rel) {
    if (git(repo, ["ls-files", "--error-unmatch", "--", rel])) { out.detail = `${rel} is tracked by git — it must never be committed: move it outside the repo`; return out; }
    if (!git(repo, ["check-ignore", "-q", "--", rel])) { out.detail = `${rel} is in the repo and not git-ignored on its checked-out branch — a commit would take it: put it outside the repo, or have the human add it to .gitignore on the base branch first`; return out; }
  }
  if (input.link && !git(repo, ["check-ignore", "-q", "--no-index", "--", input.link])) {
    out.detail = `${input.link} (where the code reads it) is not git-ignored on the repo's checked-out branch — the link dl puts into every worktree would be committed: the human adds it to .gitignore on the base branch first`;
    return out;
  }
  if ((st.mode & 0o077) !== 0) notes.push("readable by other users: chmod 600");
  let env = {};
  if (input.keys?.length || input.check) env = parseEnv(readFileSync(file, "utf8"));
  const empty = (input.keys ?? []).filter((k) => !String(env[k] ?? "").trim());
  if (empty.length) { out.detail = `no value for ${empty.join(", ")} in ${file}`; return out; }
  if (input.check) {
    const r = spawnSync("bash", ["-c", input.check], { cwd: repo, env: { ...process.env, ...env, DELIVER_INPUT: file },
      encoding: "utf8", timeout: timeout * 1000, stdio: ["ignore", "pipe", "ignore"] });
    const last = String(r.stdout ?? "").trim().split("\n").pop()?.trim() ?? "";
    const http = /^\d{3}$/.test(last) ? Number(last) : null;
    if (r.error?.code === "ETIMEDOUT" || r.signal) { out.detail = `the check did not answer in ${timeout} s`; return out; }
    if (r.status !== 0) { out.detail = `the check failed (exit ${r.status}${http ? `, HTTP ${http}` : ""})`; return out; }
    if (http && http >= 400) { out.detail = `the check answered HTTP ${http}${http === 401 || http === 403 ? " — the credential is refused" : ""}`; return out; }
    notes.unshift(http ? `check: HTTP ${http}` : "check passed");
  }
  out.ok = true;
  out.detail = [`${file}${input.keys?.length ? ` gives ${input.keys.join(", ")}` : ""}`, ...notes].join(" · ");
  return out;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [cmd, jobDir, ...ids] = process.argv.slice(2);
  try {
    if (!jobDir || !existsSync(join(jobDir, "job.json"))) throw new Error("usage: inputs.mjs check|list <job dir> [IN-n …]");
    const job = JSON.parse(readFileSync(join(jobDir, "job.json"), "utf8"));
    const all = inputsOf(jobDir), pick = ids.length ? all.filter((i) => ids.includes(i.id)) : all;
    const unknown = ids.filter((id) => !all.some((i) => i.id === id));
    if (unknown.length) throw new Error(`no such input: ${unknown.join(", ")} (readiness.json → inputs: ${all.map((i) => i.id).join(", ") || "none"})`);
    if (cmd === "list") process.stdout.write(JSON.stringify(pick) + "\n");
    else if (cmd === "check") process.stdout.write(JSON.stringify(pick.map((i) => checkInput(i, job.repo ?? "."))) + "\n");
    else throw new Error("usage: inputs.mjs check|list <job dir> [IN-n …]");
  } catch (e) { console.error(`inputs: ${e.message}`); process.exit(1); }
}
