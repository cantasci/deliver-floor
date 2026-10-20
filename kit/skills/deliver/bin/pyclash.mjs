#!/usr/bin/env node
// Two Python test modules with one name, both in folders without __init__.py: pytest's default import mode ("prepend") puts
// each folder on sys.path and imports the module by its name — the second one fails collection ("import file mismatch", or
// an ImportError from the helper it found first). Live job: unit/ and integration/ of one service each had
// export_v03_support.py (a dev's helper and QA's) — the whole suite failed collection once both cards were merged.
//   git ls-tree … | node pyclash.mjs <worktree> <added file> …   → "<added>\t<the other>" per clash
// stdin: every file of the trees to compare with (the card's commit and the job branch). A folder whose pytest settings
// (pytest.ini, pyproject.toml, setup.cfg, tox.ini) use --import-mode=importlib imports by path: no clash there.
import { readFileSync } from "node:fs";
import { join, dirname, basename } from "node:path";

const [wt, ...added] = process.argv.slice(2);
const all = new Set(readFileSync(0, "utf8").split("\n").filter(Boolean));
const SKIP = new Set(["__init__.py", "conftest.py", "setup.py", "__main__.py"]);
const isTest = (f) => /(^|\/)(tests?|testing)(\/|$)|(^|\/)test_[^/]*$|_tests?\.py$/.test(f);
const pkg = (f) => dirname(f) !== "." && all.has(join(dirname(f), "__init__.py"));
const configs = [...all].filter((f) => /(^|\/)(pytest\.ini|pyproject\.toml|setup\.cfg|tox\.ini)$/.test(f));
const importlib = configs.filter((c) => { try { return /import[-_]mode\s*=?\s*["']?importlib/.test(readFileSync(join(wt, c), "utf8")); } catch { return false; } })
  .map((c) => (dirname(c) === "." ? "" : dirname(c) + "/"));
const byPath = (f) => importlib.some((d) => f.startsWith(d));

for (const f of added) {
  const b = basename(f);
  if (!f.endsWith(".py") || SKIP.has(b) || !isTest(f) || pkg(f) || byPath(f)) continue;
  for (const o of all) if (o !== f && basename(o) === b && isTest(o) && !pkg(o) && !byPath(o)) console.log(`${f}\t${o}`);
}
