#!/usr/bin/env node
// `node --test <dir>` (with or without the trailing slash) fails on Node 22+: the arguments are file globs, and a directory
// is then loaded as a module (MODULE_NOT_FOUND). Seen live three times (runs 29, 33, 45): a card blocked and Michael spent
// minutes re-planning. Name the files or a glob instead.
export function nodeTestDirArgs(cmd) {
  const bad = [];
  for (const m of String(cmd ?? "").matchAll(/\bnode\s+(?:--[\w-]+(?:=\S+)?\s+)*--test(?![\w-])((?:\s+(?!&&|\|\||;|\|)[^\s;&|]+)*)/g)) {
    for (const raw of m[1].trim().split(/\s+/).filter(Boolean)) {
      const a = raw.replace(/^['"]|['"]$/g, "");
      if (a.startsWith("-")) continue;
      if (/[*?{]/.test(a) || /\.(c|m)?[jt]sx?$/.test(a)) continue;
      bad.push(a);
    }
  }
  return bad;
}

// CLI (dl gate): node node-test-args.mjs "<command>" → prints the hint and exits 1 when the command has a directory argument
import { fileURLToPath } from "node:url";
if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const bad = nodeTestDirArgs(process.argv[2]);
  if (bad.length) { console.log(`'node --test ${bad.join(" ")}' — a directory fails on Node 22+ (MODULE_NOT_FOUND); name the files or a glob: node --test '${bad[0].replace(/\/$/, "")}/**/*.test.mjs'`); process.exit(1); }
}
