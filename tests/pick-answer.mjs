#!/usr/bin/env node
// The prepared "human" picks the answer that fits a question best — never just the first whose keywords appear.
//   node pick-answer.mjs <answers.json> "<question>" [readiness item id]
//     → prints the answer; exit 2 when none fits, two fit equally, or only one keyword fits
// An answer may name the readiness item ids it answers (`ids`, the catalog's stable ids such as NFR-compliance); an id
// match wins. Otherwise each answer's `match` is a regex of alternatives (a|b|c), scored by how many alternatives the
// question contains, and it takes at least two: a single shared word answered a compliance question with the
// thresholds answer in a live run — Michael recorded it. No answer is better than a wrong one: a person decides.
// Seen live: a question about the sign of notches quoted the downgrade example "BBB+ -> BB+", so a first-match picked the
// answer about the miscounted example — Michael rightly refused it. A tie is a question no prepared answer settles.
import { readFileSync } from "node:fs";
const [file, question, id] = process.argv.slice(2);
const answers = JSON.parse(readFileSync(file, "utf8"));
// top-level alternatives only: "a|b(c|d)|e" → a, b(c|d), e
const alts = (m) => {
  const out = []; let depth = 0, cur = "";
  for (let i = 0; i < m.length; i++) {
    const ch = m[i];
    if (ch === "\\") { cur += ch + (m[++i] ?? ""); continue; }
    if (ch === "(" || ch === "[") depth++;
    if (ch === ")" || ch === "]") depth--;
    if (ch === "|" && depth === 0) { out.push(cur); cur = ""; continue; }
    cur += ch;
  }
  return [...out, cur].filter(Boolean);
};
const byId = id ? answers.filter((a) => (a.ids ?? []).includes(id)) : [];
if (byId.length === 1) { process.stdout.write(byId[0].answer); process.exit(0); }
const scored = answers
  .filter((a) => a.match)   // an answer without `match` answers only its own item ids
  .map((a) => ({ a, score: alts(a.match).filter((x) => new RegExp(x, "i").test(question)).length }))
  .filter((x) => x.score >= 2)
  .sort((x, y) => y.score - x.score);
if (!scored.length) { console.error("no prepared answer fits (an id match or at least two keywords are needed)"); process.exit(2); }
if (scored[1] && scored[1].score === scored[0].score) {
  console.error(`ambiguous: "${scored[0].a.topic}" and "${scored[1].a.topic}" fit equally`); process.exit(2);
}
process.stdout.write(scored[0].a.answer);
