#!/usr/bin/env node
// scope.mjs — glob matching shared by `dl gate` and validate.mjs.
//   node scope.mjs '<scope JSON array>'  < changed-file list   → prints the files outside the scope
// Glob syntax: `**` any number of path segments, `*` anything inside one segment,
// `?` one character, `{a,b}` alternatives. Patterns are repo-relative.
import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

export function globToRegExp(glob) {
  let re = "";
  for (let i = 0; i < glob.length; i++) {
    const c = glob[i];
    if (c === "*") {
      if (glob[i + 1] === "*") {
        i++;
        if (glob[i + 1] === "/") { i++; re += "(?:.*/)?"; } else re += ".*";
      } else re += "[^/]*";
    } else if (c === "?") re += "[^/]";
    else if (c === "{") {
      const end = glob.indexOf("}", i);
      if (end === -1) { re += "\\{"; continue; }
      re += "(?:" + glob.slice(i + 1, end).split(",").map((p) => globToRegExp(p).source.slice(1, -1)).join("|") + ")";
      i = end;
    } else re += /[.+^$()|[\]\\]/.test(c) ? "\\" + c : c;
  }
  return new RegExp("^" + re + "$");
}

export const inScope = (file, scope) => scope.some((g) => globToRegExp(g).test(file));

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const scope = JSON.parse(process.argv[2] ?? "[]");
  const files = readFileSync(0, "utf8").split("\n").filter(Boolean);
  for (const f of files) if (!inScope(f, scope)) console.log(f);
}
