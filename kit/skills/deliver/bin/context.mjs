#!/usr/bin/env node
// context.mjs — the existing architecture of a repo with code, as a project standard: .deliver/knowledge/architecture.md.
//
// A repo that already has code has an architecture: its components, their stacks, paths and suites. The readiness review
// would otherwise ask the human for it on every job (ARC-style, ARC-components are the product owner's). Written once from
// the repo's files (draft), confirmed by the team (the human answers the ARC items "as in the draft" once, and the file is
// committed with that job's PR), it is a standard from then on: the BA settles those items from it with its words quoted
// (source "standard: architecture.md"). A new component is still the human's to decide — the file states only what exists.
// Facts only, each with the file it was read from: the code is the detail, and an agent reads it itself.
//
//   node context.mjs draft <repo>               the draft, read from the repo's files (markdown on stdout)
//   node context.mjs check <repo> [file]        the file (default .deliver/knowledge/architecture.md) against the repo:
//                                               exit 0 ok · 1 errors (a path gone, unfilled) · 2 no file; WARN for drift
//   node context.mjs components <repo> [file]   the file's components (JSON)
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join, resolve, basename, isAbsolute } from "node:path";
import { pathToFileURL } from "node:url";
import { stack as suiteOf, commitConvention, fixedPorts, detect } from "./detect.mjs";

export const KINDS = ["service", "bff", "app", "web", "mobile", "library", "worker", "db", "infra", "docs"];
export const DOC = (repo) => join(repo, ".deliver", "knowledge", "architecture.md");
const MANIFESTS = ["package.json", "pyproject.toml", "setup.py", "requirements.txt", "go.mod", "Cargo.toml", "pom.xml", "build.gradle",
  "build.gradle.kts", "composer.json", "Gemfile", "mix.exs", "Package.swift", "pubspec.yaml", "deno.json"];
const SKIP = new Set(["node_modules", "vendor", "dist", "build", "out", "target", "coverage", ".venv", "venv", "__pycache__", ".git", ".work", ".deliver", ".gradle", ".idea", ".next", "Pods"]);
const read = (p) => { try { return readFileSync(p, "utf8"); } catch { return ""; } };
const json = (p) => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return null; } };
const isDir = (p) => { try { return statSync(p).isDirectory(); } catch { return false; } };

/** a project root's manifest, stack and kind — read from its files */
export function project(root, rel) {
  const dir = rel === "." ? root : join(root, rel);
  const manifest = MANIFESTS.find((m) => existsSync(join(dir, m)));
  if (!manifest) return null;
  const st = new Set(), add = (...x) => x.forEach((y) => st.add(y));
  const where = rel === "." ? "" : `${rel}/`;
  if (manifest === "package.json" || existsSync(join(dir, "package.json"))) {
    const pkg = json(join(dir, "package.json")) ?? {};
    const deps = { ...pkg.dependencies, ...pkg.devDependencies, ...pkg.peerDependencies };
    add(existsSync(join(dir, "tsconfig.json")) || deps.typescript ? "typescript" : "javascript");
    for (const [d, s] of [["next", "react"], ["react-native", "react-native"], ["react", "react"], ["vue", "vue"], ["nuxt", "vue"], ["@angular/core", "angular"],
      ["@nestjs/core", "nestjs"], ["express", "node"], ["fastify", "node"], ["koa", "node"]]) if (deps[d]) add(s);
  }
  const py = read(join(dir, "pyproject.toml")) + read(join(dir, "requirements.txt")) + read(join(dir, "setup.py"));
  if (/^(pyproject\.toml|setup\.py|requirements\.txt)$/.test(manifest)) { add("python"); for (const f of ["django", "fastapi", "flask"]) if (new RegExp(`\\b${f}\\b`, "i").test(py)) add(f); }
  const gradle = read(join(dir, "build.gradle")) + read(join(dir, "build.gradle.kts"));
  if (manifest === "go.mod") add("go");
  if (manifest === "Cargo.toml") add("rust");
  if (manifest === "pom.xml") { add("java"); if (/spring-boot/.test(read(join(dir, "pom.xml")))) add("spring-boot"); }
  if (/^build\.gradle/.test(manifest)) { add(/kotlin/.test(gradle) || manifest.endsWith(".kts") ? "kotlin" : "java"); if (/com\.android/.test(gradle)) add("android"); if (/spring-boot|org\.springframework\.boot/.test(gradle)) add("spring-boot"); }
  if (manifest === "composer.json") add("php");
  if (manifest === "Gemfile") add("ruby");
  if (manifest === "mix.exs") add("elixir");
  if (manifest === "Package.swift") add("swift");
  if (manifest === "pubspec.yaml") add("flutter");
  if (manifest === "deno.json") add("typescript", "deno");
  const s = [...st];
  const kind = s.some((x) => ["android", "flutter", "react-native", "swift"].includes(x)) ? "mobile"
    : s.some((x) => ["react", "vue", "angular"].includes(x)) ? "web"
    : s.some((x) => ["nestjs", "node", "django", "fastapi", "flask", "spring-boot"].includes(x)) ? "service" : "library";
  const suite = suiteOf(dir, where);
  const verify = suite?.verify ? (rel === "." ? suite.verify : `cd ${/^[\w./-]+$/.test(rel) ? rel : `'${rel}'`} && ${suite.verify}`) : "";
  return { rel, manifest: `${where}${manifest}`, stack: s, kind, verify, evidence: suite?.ev?.join("; ") ?? "" };
}

/** every directory (to depth 3) with a manifest of its own — the projects a repo is made of */
export function projects(root) {
  const out = [];
  const walk = (rel, depth) => {
    const dir = rel === "." ? root : join(root, rel);
    let names = []; try { names = readdirSync(dir).sort(); } catch { return; }
    for (const n of names) {
      if (n.startsWith(".") || SKIP.has(n)) continue;
      const r = rel === "." ? n : `${rel}/${n}`;
      if (!isDir(join(root, r))) continue;
      const p = project(root, r);
      if (p) out.push(p);
      if (depth > 1) walk(r, depth - 1);
    }
  };
  walk(".", 3);
  return out;
}

const kebab = (s) => String(s).toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "app";

export function draft(repo) {
  const root = resolve(repo), subs = projects(root), top = project(root, ".");
  // a root manifest that only holds the workspace (package.json "workspaces", a Gradle settings file …) is not a component
  // of its own when the projects under it are; a root with its own source next to them is
  const rootSrc = ["src", "lib", "app"].some((d) => isDir(join(root, d)));
  const comps = subs.length ? [...(top && rootSrc ? [top] : []), ...subs] : top ? [top] : [];
  const ids = new Map();
  for (const c of comps) {
    let id = kebab(c.rel === "." ? basename(root) : basename(c.rel));
    if (ids.has(id)) id = kebab(c.rel);
    ids.set(id, c); c.id = id;
  }
  const d = detect(root), cc = commitConvention(root), ports = fixedPorts(root);
  const style = comps.length <= 1 ? "{{monolith | library — one component; which one, the team says}}"
    : `{{monorepo of ${comps.length} components: monolith | modular-monolith | microservices — the team says which}}`;
  const row = (c) => `| ${c.id} | ${c.kind} | ${c.stack.join(", ") || "?"} | \`${c.rel === "." ? "." : `${c.rel}/`}\` | ${c.verify ? `\`${c.verify}\`` : "—"} | ${c.manifest} |`;
  return [
    "---", "title: Project architecture", "applies_to: [all]", "---", "", `# Project architecture — ${basename(root)}`, "",
    `<!-- Drafted by dl context draft from the repository's files on ${new Date().toISOString().slice(0, 10)}. The team confirms it once (the`,
    "     readiness review's ARC items) and it is committed with that job's PR; from then on it is a project standard the BA quotes",
    "     (source \"standard: architecture.md\"). Fill in every {{…}} and correct what is wrong. Facts only: the code is the detail. -->", "",
    "## Style", "", style, "",
    "## Components", "",
    "| Component | Kind | Stack | Path | Suite | Found in |", "| --- | --- | --- | --- | --- | --- |",
    ...(comps.length ? comps.map(row) : ["| {{id}} | {{kind}} | {{stack}} | `{{path}}` | — | no manifest found |"]), "",
    `Kinds: ${KINDS.join(", ")}. A component's path holds its code and its tests; a database, a queue or an external system`,
    "the team owns is a component too (kind db / infra), even without a folder here.", "",
    "## Commands", "",
    `- Whole suite: ${d.verify_full ? `\`${d.verify_full}\`` : "none found"} (${d.evidence.verify_full})`,
    `- Install in a fresh worktree: ${d.worktree_setup ? `\`${d.worktree_setup}\`` : "nothing to install"}`, "",
    "## Conventions", "",
    `- Commits: ${cc.convention} (${cc.source})`,
    ...(ports.length ? [`- The test setup binds fixed ports: ${ports.map((p) => `${p.file} ${p.ports.join(", ")}`).join("; ")}`] : []),
    ...["CLAUDE.md", "AGENTS.md", "CONTRIBUTING.md"].filter((f) => existsSync(join(root, f))).map((f) => `- Project rules: \`${f}\``), "",
  ].join("\n");
}

/** the Components table of an architecture document */
export function parse(text) {
  const sec = String(text).match(/^##\s+Components\b.*\n([\s\S]*?)(?=^##\s|(?![\s\S]))/m)?.[1] ?? "";
  const style = (String(text).match(/^##\s+Style\b.*\n([\s\S]*?)(?=^##\s|(?![\s\S]))/m)?.[1] ?? "").trim();
  const rows = sec.split("\n").filter((l) => /^\|/.test(l) && !/^\|\s*-/.test(l) && !/^\|\s*Component\s*\|/i.test(l));
  return {
    style,
    components: rows.map((l) => {
      const [id, kind, st, path, suite] = l.split("|").slice(1).map((x) => x.trim());
      return { id, kind, stack: (st ?? "").split(",").map((x) => x.trim()).filter(Boolean),
        path: [...(path ?? "").matchAll(/`([^`]+)`/g)].map((m) => m[1]), verify: (suite ?? "").match(/`([^`]+)`/)?.[1] ?? "" };
    }),
  };
}

export function check(repo, file = DOC(repo)) {
  const root = resolve(repo), f = isAbsolute(file) ? file : join(root, file);
  if (!existsSync(f)) return { missing: true, errors: [`${f} does not exist`], warnings: [], components: [] };
  const text = readFileSync(f, "utf8"), errors = [], warnings = [];
  const unfilled = [...new Set(text.replace(/<!--[\s\S]*?-->/g, "").match(/\{\{[^}]*\}\}/g) ?? [])];
  if (unfilled.length) errors.push(`not filled in: ${unfilled.slice(0, 3).join(" · ")} — the team states it (or the line goes)`);
  const { style, components } = parse(text);
  if (!style) errors.push("## Style is empty — monolith, modular-monolith, microservices, library …");
  if (!components.length) errors.push("## Components lists no component");
  const ids = new Set();
  for (const c of components) {
    if (!/^[a-z0-9][a-z0-9-]*$/.test(c.id ?? "")) errors.push(`component '${c.id}': id must be lower-case kebab-case`);
    if (ids.has(c.id)) errors.push(`component '${c.id}': listed twice`); ids.add(c.id);
    if (!KINDS.includes(c.kind)) errors.push(`component '${c.id}': kind '${c.kind}' — one of ${KINDS.join(", ")}`);
    if (!c.stack.length) errors.push(`component '${c.id}': no stack`);
    if (!c.path.length && !["db", "infra"].includes(c.kind)) errors.push(`component '${c.id}': no path (\`dir/\`, or \`.\` for the whole repo)`);
    for (const p of c.path) if (p !== "." && !existsSync(join(root, p))) errors.push(`component '${c.id}': path ${p} is not in the repo any more — the file is out of date`);
  }
  // drift: a project with a manifest of its own that no component covers
  const covered = (rel) => components.some((c) => c.path.some((p) => p === "." || p === "./" || `${rel}/`.startsWith(p.replace(/\/?$/, "/"))));
  for (const p of projects(root)) if (!covered(p.rel)) warnings.push(`${p.rel}/ has its own ${basename(p.manifest)} and is in no component — a new part of the repo, or a component the file misses`);
  return { missing: false, errors, warnings, components, style };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [cmd, repo = ".", file] = process.argv.slice(2);
  if (cmd === "draft") process.stdout.write(draft(repo));
  else if (cmd === "check") {
    const r = check(repo, file);
    for (const e of r.errors) console.log(`ERROR ${e}`);
    for (const w of r.warnings) console.log(`WARN  ${w}`);
    if (!r.missing && !r.errors.length) console.log(`architecture: ${r.components.length} component(s) — ${r.components.map((c) => `${c.id} (${c.path.join(", ")})`).join(", ")}`);
    process.exit(r.missing ? 2 : r.errors.length ? 1 : 0);
  } else if (cmd === "components") { const r = check(repo, file); console.log(JSON.stringify(r.components)); process.exit(r.missing ? 2 : 0); }
  else { console.error("usage: context.mjs draft|check|components <repo> [file]"); process.exit(2); }
}
