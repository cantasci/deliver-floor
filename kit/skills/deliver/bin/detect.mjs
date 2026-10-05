#!/usr/bin/env node
// What a repo itself says about how it is tested and set up — read from its files, never assumed. Used when .deliver.json
// is written (dl config --init, the first /deliver, scripts/init.sh). Every value carries the file it came from; what the
// repo does not say stays empty (verify_full "" in a repo without code: it is set once the stack is decided).
//   node detect.mjs <repo>   → {"verify_full", "worktree_setup", "worktree_exclude", "merge_mode", "hive_root", "evidence"}
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join, resolve } from "node:path";
import { execFileSync } from "node:child_process";
import { homedir, platform } from "node:os";

const read = (p) => { try { return readFileSync(p, "utf8"); } catch { return ""; } };
const json = (p) => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return null; } };
const has = (dir, ...names) => names.some((n) => existsSync(join(dir, n)));

// npm writes this placeholder into every new package.json: it is not a test suite
const NPM_PLACEHOLDER = /no test specified/;

function node(dir, ev, where) {
  const pkg = json(join(dir, "package.json"));
  if (!pkg) return null;
  const s = pkg.scripts ?? {};
  const pm = has(dir, "pnpm-lock.yaml") ? "pnpm" : has(dir, "yarn.lock") ? "yarn" : has(dir, "bun.lockb", "bun.lock") ? "bun" : "npm";
  const lock = { pnpm: "pnpm-lock.yaml", yarn: "yarn.lock", bun: "bun.lock(b)", npm: has(dir, "package-lock.json") ? "package-lock.json" : "" }[pm];
  const run = (name) => (pm === "npm" ? (name === "test" ? "npm test" : `npm run ${name}`) : pm === "bun" ? `bun run ${name}` : `${pm} ${name}`);
  const testOk = s.test && !NPM_PLACEHOLDER.test(s.test);
  const names = testOk ? [...["typecheck", "lint"].filter((n) => s[n]), "test"] : [];
  const steps = names.map(run);
  // nothing to install → no setup (an install would only leave a new lockfile in every card's worktree)
  const deps = Object.keys({ ...pkg.dependencies, ...pkg.devDependencies, ...pkg.optionalDependencies }).length > 0;
  const setup = !deps ? "" : pm === "npm" ? (has(dir, "package-lock.json") ? "npm ci" : "npm install --no-package-lock")
    : pm === "pnpm" ? "pnpm install --frozen-lockfile" : pm === "yarn" ? "yarn install --frozen-lockfile" : "bun install";
  ev.push(testOk
    ? `${where}package.json scripts ${names.join(", ")}${lock ? `; ${lock} → ${pm}` : ""}`
    : `${where}package.json has no test script${s.test ? " (only npm's placeholder)" : ""} — verify_full left empty`);
  return { verify: testOk ? steps.join(" && ") : "", setup, exclude: ["node_modules"] };
}

function python(dir, ev, where) {
  if (!has(dir, "pyproject.toml", "requirements.txt", "setup.py", "setup.cfg")) return null;
  const pyproject = read(join(dir, "pyproject.toml"));
  const reqs = ["requirements.txt", "requirements-dev.txt", "dev-requirements.txt"].map((f) => read(join(dir, f))).join("\n");
  const pytest = /\bpytest\b/.test(pyproject + reqs) || has(dir, "pytest.ini", "conftest.py") || /\[tool:pytest\]/.test(read(join(dir, "setup.cfg")));
  const tests = has(dir, "tests", "test");
  const prefix = has(dir, "uv.lock") ? "uv run " : has(dir, "poetry.lock") ? "poetry run " : "";
  const verify = pytest ? `${prefix}pytest -q` : tests ? `${prefix}python -m unittest discover` : "";
  const setup = has(dir, "uv.lock") ? "uv sync" : has(dir, "poetry.lock") ? "poetry install" : "";
  ev.push(verify ? `${where}${pytest ? "pytest named in the project files" : "a tests/ folder without pytest → unittest"}${prefix ? ` (${prefix.trim()})` : ""}`
    : `${where}Python project without tests — verify_full left empty`);
  return { verify, setup, exclude: [".venv"] };
}

const simple = [
  ["go.mod", () => "go test ./...", "go.mod"],
  ["Cargo.toml", () => "cargo test", "Cargo.toml"],
  ["pom.xml", (d) => (has(d, "mvnw") ? "./mvnw -q test" : "mvn -q test"), "pom.xml"],
  ["build.gradle", (d) => (has(d, "gradlew") ? "./gradlew test" : "gradle test"), "build.gradle"],
  ["build.gradle.kts", (d) => (has(d, "gradlew") ? "./gradlew test" : "gradle test"), "build.gradle.kts"],
  ["mix.exs", () => "mix test", "mix.exs"],
  ["Gemfile", (d) => (has(d, "spec") ? "bundle exec rspec" : has(d, "Rakefile") ? "bundle exec rake test" : ""), "Gemfile"],
  ["composer.json", (d) => (json(join(d, "composer.json"))?.scripts?.test ? "composer test" : has(d, "phpunit.xml", "phpunit.xml.dist") ? "vendor/bin/phpunit" : ""), "composer.json"],
  ["Package.swift", () => "swift test", "Package.swift"],
  ["pubspec.yaml", () => "flutter test", "pubspec.yaml"],
];

function stack(dir, where = "") {
  const ev = [];
  const r = node(dir, ev, where) ?? python(dir, ev, where);
  if (r) return { ...r, ev };
  for (const [file, cmd, label] of simple) {
    if (!existsSync(join(dir, file))) continue;
    const v = cmd(dir);
    ev.push(v ? `${where}${label} → ${v}` : `${where}${label} without a test setup — verify_full left empty`);
    return { verify: v, setup: "", exclude: [], ev };
  }
  if (has(dir, "deno.json", "deno.jsonc")) { ev.push(`${where}deno.json → deno test`); return { verify: "deno test", setup: "", exclude: [], ev }; }
  return null;
}

export function detect(repo) {
  const root = resolve(repo);
  const evidence = {};
  let verify = "", setup = "", exclude = [];

  // 1. the repo's own entry point wins: a Makefile with a test target
  const mk = ["Makefile", "makefile", "GNUmakefile"].find((f) => existsSync(join(root, f)));
  const hasMakeTest = mk && /^test\s*:/m.test(read(join(root, mk)));
  // 2. the stack at the root, else each top-level folder with its own project (a monorepo: frontend/, backend/ …)
  let found = stack(root);
  if (!found) {
    const parts = [];
    let dirs = [];
    try { dirs = readdirSync(root).filter((d) => !d.startsWith(".") && !["node_modules", "vendor", "dist", "build"].includes(d) && statSync(join(root, d)).isDirectory()).sort(); } catch { /* unreadable */ }
    for (const d of dirs) { const s = stack(join(root, d), `${d}/`); if (s) parts.push({ d, ...s }); }
    if (parts.length) {
      const q = (d) => (/^[\w./-]+$/.test(d) ? d : `'${d}'`);
      found = {
        verify: parts.filter((p) => p.verify).map((p) => `(cd ${q(p.d)} && ${p.verify})`).join(" && "),
        setup: parts.filter((p) => p.setup).map((p) => `(cd ${q(p.d)} && ${p.setup})`).join(" && "),
        exclude: parts.flatMap((p) => p.exclude.map((e) => `${p.d}/${e}`)),
        ev: parts.flatMap((p) => p.ev),
      };
    }
  }
  if (hasMakeTest) { verify = "make test"; evidence.verify_full = `${mk} has a test target`; }
  else if (found?.verify) { verify = found.verify; evidence.verify_full = found.ev.join("; "); }
  else evidence.verify_full = found ? found.ev.join("; ") : "no code in the repo yet — set once the stack is decided";
  if (found) { setup = found.setup; exclude = found.exclude; if (setup) evidence.worktree_setup = "the install command for the package manager/lockfile found"; }

  // merge mode: a PR needs a remote
  let remote = false;
  try { execFileSync("git", ["-C", root, "remote", "get-url", "origin"], { stdio: "ignore" }); remote = true; } catch { /* none */ }
  evidence.merge_mode = remote ? "origin remote → a PR you merge" : "no origin remote → merged locally";

  // the floor this repo is registered on (scripts/init.sh --munder --repo …, or the app's own repo list)
  let hive = "";
  const win = platform() === "win32", mac = platform() === "darwin";
  const base = win ? (process.env.APPDATA ?? join(homedir(), "AppData", "Roaming")) : mac ? join(homedir(), "Library", "Application Support") : (process.env.XDG_CONFIG_HOME ?? join(homedir(), ".config"));
  for (const name of ["munder-difflin", "Munder Difflin"]) {
    const c = json(join(base, name, "config.json"));
    if (c?.harnessHome && (c.registeredRepos ?? []).some((r) => resolve(r) === root)) { hive = c.harnessHome; evidence.hive_root = `Munder Difflin (${name}/config.json) lists this repo`; break; }
  }

  return { verify_full: verify, worktree_setup: setup, worktree_exclude: exclude, merge_mode: remote ? "human" : "local", hive_root: hive, evidence };
}

if (import.meta.url === `file://${process.argv[1]}` || process.argv[1]?.endsWith("detect.mjs")) {
  process.stdout.write(JSON.stringify(detect(process.argv[2] ?? "."), null, 2) + "\n");
}
