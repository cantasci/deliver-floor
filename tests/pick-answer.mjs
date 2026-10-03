#!/usr/bin/env node
// The prepared "human" picks the answer that fits a question best — never just the first whose keywords appear.
//   node pick-answer.mjs <answers.json> "<question>"   → prints the answer; exit 2 when none fits or two fit equally
// Each answer's `match` is a regex of alternatives (a|b|c); its score is how many alternatives the question contains.
// Seen live: a question about the sign of notches quoted the downgrade example "BBB+ -> BB+", so a first-match picked the
// answer about the miscounted example — Michael rightly refused it. A tie is a question no prepared answer settles.
import { readFileSync } from "node:fs";
const [file, question] = process.argv.slice(2);
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
const scored = answers
  .map((a) => ({ a, score: alts(a.match).filter((x) => new RegExp(x, "i").test(question)).length }))
  .filter((x) => x.score > 0)
  .sort((x, y) => y.score - x.score);
if (!scored.length) { console.error("no prepared answer fits"); process.exit(2); }
if (scored[1] && scored[1].score === scored[0].score) {
  console.error(`ambiguous: "${scored[0].a.topic}" and "${scored[1].a.topic}" fit equally`); process.exit(2);
}
process.stdout.write(scored[0].a.answer);
