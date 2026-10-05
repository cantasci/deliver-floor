#!/usr/bin/env node
// macOS ships bash 3.2. Two things it cannot do, both seen on a user's Mac (dl died at three places):
//   1. a `case` statement inside $( … ) — 3.2's parser takes the pattern's ")" for the end of the substitution;
//   2. "${a[@]}" of an EMPTY array under `set -u` — 3.2 (up to 4.3) calls it unbound. Use ${a[@]+"${a[@]}"}.
// Plus bash-4-only features. Prints each finding as file:line and exits 1 when there is one.
//   node tests/lint-bash32.mjs <bash file>…
import { readFileSync } from "node:fs";

const findings = [];
const lineOf = (s, i) => s.slice(0, i).split("\n").length;
const BASH4 = [
  [/\bdeclare -A\b|\blocal -A\b/, "associative arrays (bash 4)"],
  [/\bmapfile\b|\breadarray\b/, "mapfile/readarray (bash 4)"],
  [/\$\{[A-Za-z_]+(,,|\^\^)\}/, "case conversion ${x,,} (bash 4)"],
  [/\[\[ -v /, "[[ -v ]] (bash 4.2)"],
  [/&>>|\|&/, "&>> or |& (bash 4)"],
  [/;;&|;&\s*$/, "case fall-through ;& ;;& (bash 4)"],
  [/\b(local|declare) -n\b/, "namerefs (bash 4.3)"],
  [/\bdeclare -g\b/, "declare -g (bash 4.2)"],
  [/\bcoproc\b|\bwait -n\b|\bEPOCHSECONDS\b|\bBASHPID\b/, "bash 4/5 builtin"],
];

// true when the line has "{x, y}" inside double quotes, inside a $( ), inside double quotes (quote state tracked per level)
function braceInNestedQuotes(l) {
  const st = [{ dq: false }]; // one frame per $( ) level
  for (let i = 0; i < l.length; i++) {
    const c = l[i], top = st[st.length - 1];
    if (c === "\\") { i++; continue; }
    if (!top.dq && c === "'") { const k = l.indexOf("'", i + 1); if (k < 0) return false; i = k; continue; }
    if (c === "$" && l[i + 1] === "(" && l[i + 2] !== "(") { st.push({ dq: false, outerDq: top.dq }); i++; continue; }
    if (c === ")" && !top.dq && st.length > 1) { st.pop(); continue; }
    if (c === '"') { top.dq = !top.dq; continue; }
    if (c === "{" && top.dq && st.length > 1 && st.some((f, k) => k > 0 && f.outerDq)) {
      const k = l.indexOf("}", i); if (k > 0 && /, /.test(l.slice(i, k)) && !l.slice(i, k).includes('"')) return true;
    }
  }
  return false;
}

for (const f of process.argv.slice(2)) {
  const s = readFileSync(f, "utf8");
  // 1. case inside a command substitution: walk every $( and look for "case … in" before its closing paren depth 0,
  //    counting parens the way bash 3.2 does (quotes respected, nothing else).
  for (let i = s.indexOf("$("); i >= 0; i = s.indexOf("$(", i + 2)) {
    if (s[i + 2] === "(") continue;
    let depth = 1, j = i + 2, body = "";
    while (j < s.length && depth > 0) {
      const c = s[j];
      if (c === "\\") { body += s.slice(j, j + 2); j += 2; continue; }
      if (c === "'" || c === '"') { const k = s.indexOf(c, j + 1); body += " "; j = k < 0 ? s.length : k + 1; continue; }
      if (c === "(") depth++; else if (c === ")") depth--;
      body += c; j++;
    }
    if (/(^|[\s;(])case\b[^;\n]*\bin\b/.test(body)) findings.push(`${f}:${lineOf(s, i)}: case statement inside $( ) — bash 3.2 cannot parse it`);
  }
  // 2. arrays that can be empty, expanded bare under set -u
  { // set -u may come from the script that sources this file, so every file is checked
    const arrays = new Set([...s.matchAll(/\b(?:local\s+)?([A-Za-z_][A-Za-z0-9_]*)=\(\)/g)].map((m) => m[1]));
    for (const name of arrays) {
      const re = new RegExp(`(?<!\\+)"\\$\\{${name}\\[@\\]\\}"`, "g");
      for (const m of s.matchAll(re)) {
        const ln = s.slice(s.lastIndexOf("\n", m.index) + 1, m.index);
        if (ln.includes("#")) continue;   // in a comment
        const before = s.slice(Math.max(0, m.index - name.length - 8), m.index);
        if (!before.includes(`${name}[@]+`)) findings.push(`${f}:${lineOf(s, m.index)}: "\${${name}[@]}" can be an empty array under set -u — use \${${name}[@]+"\${${name}[@]}"}`);
      }
    }
  }
  // 3. two more traps found on a real Mac (fix/floor-robustness, d6d6455): "$name→" — bash 3.2 reads a non-ASCII byte right
  //    after a name as part of it (use ${name}); and "…$(… "…{a, b}…" …)…" — a brace list in a double-quoted string inside
  //    a $( ) that is itself inside double quotes is mangled.
  s.split("\n").forEach((l, n) => {
    if (/^\s*#/.test(l)) return;
    if (/\$[A-Za-z_][A-Za-z0-9_]*[^\x00-\x7F]/.test(l)) findings.push(`${f}:${n + 1}: "$name" followed by a non-ASCII character — bash 3.2 reads it as one name; use \${name}`);
    if (braceInNestedQuotes(l)) findings.push(`${f}:${n + 1}: "{a, b}" in a double-quoted string inside a quoted $( ) — bash 3.2 mangles it`);
  });
  // 4. bash-4-only features (comments skipped)
  s.split("\n").forEach((l, n) => {
    if (/^\s*#/.test(l)) return;
    const code = l.replace(/'[^']*'|"(?:[^"\\]|\\.)*"/g, "''");   // patterns inside quoted strings are data
    for (const [re, what] of BASH4) if (re.test(code)) findings.push(`${f}:${n + 1}: ${what}`);
  });
}
for (const x of findings) console.log(x);
process.exit(findings.length ? 1 : 0);
