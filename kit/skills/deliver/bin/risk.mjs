#!/usr/bin/env node
// risk.mjs — risk-based test design, the blind review's triage and the non-functional gate (settings.test_design.risk).
//
// Every acceptance criterion of plan.md carries a priority on its line — "- AC-3 [P1] (REQ-02): Given …":
//   P0  a failure loses money or data, breaks security, privacy or compliance, or stops the core flow; no workaround
//   P1  the core feature is wrong, but a workaround exists or few users are hit
//   P2  secondary behaviour, the edges of normal use
//   P3  cosmetic or rare
// The priority decides how deeply it is tested (each card spec's "## Test design") and whether the card gets a blind review
// (settings.review.blind: "risk" → cards with a P0 or P1 criterion). Every decided NFR-* readiness item is a non-functional
// requirement: the plan says how it is checked, and the closing report gives it PASS / CONCERNS / FAIL with its evidence —
// anything but PASS ships only with Michael's waiver (dl waive), listed in the PR.
//
//   node risk.mjs plan <job dir>                              the plan's ACs with their priority (JSON); errors → exit 1
//   node risk.mjs card <job dir> <card id>                    the card's ACs + priorities and its top priority (JSON)
//   node risk.mjs qa <job dir> <card id> "<summary>"          a QA pass names a result for every AC of the card
//   node risk.mjs triage <job dir> <card id> <verdict> '<json>'   the blind review's findings, each judged against the spec
//   node risk.mjs nfr <job dir>                               the decided non-functional requirements (JSON)
//   node risk.mjs report <job dir>                            report.md accounts for every one of them; exit 1 with the gaps
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const read = (p) => { try { return readFileSync(p, "utf8"); } catch { return ""; } };
const readJson = (p, d) => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return d; } };
export const PRIORITIES = ["P0", "P1", "P2", "P3"];
const norm = (t) => String(t).toLowerCase().replace(/[‘’]/g, "'").replace(/[“”]/g, '"').replace(/[`*_]/g, "").replace(/\s+/g, " ").trim();

/** the plan's acceptance criteria: [{ ac: "AC-1", priority: "P0" | null, line }] — one per "- AC-n" line, first wins */
export function planACs(planText) {
  const out = new Map();
  for (const line of String(planText).split("\n")) {
    const m = line.match(/^\s*[-*]\s+\**(AC-\d+)\b/);
    if (!m || out.has(m[1])) continue;
    const p = line.match(/\[(P[0-3])\]/);
    out.set(m[1], { ac: m[1], priority: p ? p[1] : null, line: line.trim() });
  }
  return [...out.values()];
}
export const refsOf = (card) => [...new Set((card.acceptance ?? []).flatMap((a) => [...String(a).matchAll(/\bAC-(\d+)\b/g)].map((m) => `AC-${m[1]}`)))];
const rank = (p) => (p ? PRIORITIES.indexOf(p) : 9);
export function cardRisk(card, acs) {
  const byAc = new Map(acs.map((a) => [a.ac, a]));
  const list = refsOf(card).map((ac) => ({ ac, priority: byAc.get(ac)?.priority ?? null }));
  const top = list.reduce((t, a) => (rank(a.priority) < rank(t) ? a.priority : t), null);
  return { acs: list, top };
}
/** does this card need a blind review? mode: "risk" (a P0/P1 criterion) | "all" | "off" */
export const needsBlind = (mode, top) => mode === "all" || (mode === "risk" && (top === "P0" || top === "P1"));

/** a spec's "## Test design" section (until the next ## heading) */
export const testDesign = (spec) => String(spec).match(/^##\s+Test design\b.*\n([\s\S]*?)(?=^##\s|(?![\s\S]))/m)?.[1] ?? null;

const load = (jobDir) => {
  const job = readJson(join(jobDir, "job.json"), {});
  return { job, acs: planACs(read(join(jobDir, "plan.md"))), board: readJson(join(jobDir, "board.json"), { cards: [] }) };
};
const findCard = (board, id) => {
  const c = (board.cards ?? []).find((x) => x.id === id);
  if (!c) throw new Error(`no such card: ${id}`);
  return c;
};

/** a QA pass names a result for every AC the card claims ("AC-2 pass: …", "AC-4 unit: <the dev's test>") */
export function qaErrors(card, acs, summary) {
  const named = new Set([...String(summary).matchAll(/\bAC-(\d+)\b/g)].map((m) => `AC-${m[1]}`));
  return cardRisk(card, acs).acs.filter((a) => !named.has(a.ac))
    .map((a) => `${a.ac}${a.priority ? ` [${a.priority}]` : ""} has no result in the QA verdict — every acceptance criterion of ${card.id} gets one, with the test that shows it (a P3 one may name the dev's unit test)`);
}

// The blind reviewer judged the change from the diff alone. Michael checks every finding against the spec: "intended" — the
// spec states this behaviour, its words quoted (found verbatim in specs/<card>.md or plan.md) — or "defect", which goes back
// to the dev. Approve only with no defect; "changes" only with one.
export function triage(jobDir, cardId, verdict, json) {
  const errors = [];
  let items;
  try { items = JSON.parse(json || "null"); } catch (e) { return { errors: [`--triage is not JSON: ${e.message}`] }; }
  if (!Array.isArray(items)) return { errors: ['--triage must be a list: [{"finding":"…","decision":"defect|intended","quote":"<the spec\'s words, for intended>"}] — [] when the blind reviewer found nothing'] };
  const spec = norm(read(join(jobDir, "specs", `${cardId}.md`)) + "\n" + read(join(jobDir, "plan.md")));
  const out = [];
  items.forEach((it, k) => {
    const n = `finding ${k + 1}`;
    if (!it || typeof it !== "object") { errors.push(`${n}: must be an object`); return; }
    const finding = String(it.finding ?? "").trim();
    if (!finding) errors.push(`${n}: 'finding' is empty — copy what the blind reviewer reported`);
    if (!["defect", "intended"].includes(it.decision)) { errors.push(`${n}: 'decision' must be defect or intended`); return; }
    if (it.decision === "intended") {
      const fr = String(it.quote ?? "").split(/\s*(?:…|\.\.\.)\s*/).map(norm).filter(Boolean);
      if (!fr.length) errors.push(`${n} (${finding.slice(0, 50)}): intended needs \`quote\` — the words of the card's spec (or the plan) that ask for this behaviour; without them it is a defect`);
      else { const miss = fr.find((f) => !spec.includes(f)); if (miss) errors.push(`${n}: quote not found in specs/${cardId}.md or plan.md: "${miss.slice(0, 80)}" — only the spec settles what is intended`); }
    }
    out.push({ finding, decision: it.decision, ...(it.decision === "intended" ? { quote: String(it.quote).trim() } : {}) });
  });
  const defects = out.filter((x) => x.decision === "defect").length;
  if (verdict === "approve" && defects) errors.push(`${defects} finding(s) triaged as defect — the blind review asks for changes (dl review ${cardId} changes …)`);
  if (verdict === "changes" && !defects) errors.push("'changes' without a finding triaged as defect — every finding is intended by the spec, so the blind review approves");
  return { errors, triage: out };
}

/** the decided non-functional requirements: readiness items NFR-* and X-NFR-* that are decided (not n_a) */
export function nfrItems(jobDir) {
  const raw = readJson(join(jobDir, "readiness.json"), { items: [] });
  return (Array.isArray(raw) ? raw : raw.items ?? []).filter((i) => /^(X-)?NFR-/.test(i.id ?? "") && i.status === "decided")
    .map((i) => ({ id: i.id, answer: i.answer ?? "" }));
}

/** report.md's "## Non-functional requirements" table: | NFR-x | PASS / CONCERNS / FAIL | evidence | */
export function reportNfr(jobDir) {
  const job = readJson(join(jobDir, "job.json"), {});
  const sec = read(join(jobDir, "report.md")).match(/^##\s+Non-functional requirements\b.*\n([\s\S]*?)(?=^##\s|<!--\s*deliver:|(?![\s\S]))/m)?.[1] ?? "";
  const waived = new Set((job.waivers ?? []).map((w) => w.id));
  const errors = [], rows = [];
  for (const it of nfrItems(jobDir)) {
    const row = sec.split("\n").find((l) => new RegExp(`^\\|\\s*\\**${it.id.replace(/[-]/g, "\\-")}\\**\\s*\\|`).test(l));
    if (!row) { errors.push(`${it.id} (decided: "${it.answer.slice(0, 60)}") has no row in report.md's Non-functional requirements table`); continue; }
    const [, , st = "", ev = ""] = row.split("|").map((x) => x.trim());
    const status = (st.match(/\b(PASS|CONCERNS|FAIL)\b/) ?? [])[1];
    if (!status || /PASS\s*\/\s*CONCERNS/.test(st)) { errors.push(`${it.id} has no status (PASS, CONCERNS or FAIL)`); continue; }
    if (!ev || /^evidence\b|measurement, test name/i.test(ev)) errors.push(`${it.id} has no evidence (a test, a measurement, a review, a log)`);
    if (status !== "PASS" && !waived.has(it.id)) errors.push(`${it.id} is ${status} — fix it (a fix card), or ship it knowingly: dl waive ${it.id} "<why it may ship as it is>" (listed in the PR)`);
    rows.push({ id: it.id, status });
  }
  return { errors, rows };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [cmd, jobDir, ...rest] = process.argv.slice(2);
  try {
    if (!jobDir || !existsSync(join(jobDir, "job.json"))) throw new Error("usage: risk.mjs plan|card|qa|triage|nfr|report <job dir> …");
    if (cmd === "plan") {
      const { acs } = load(jobDir);
      const miss = acs.filter((a) => !a.priority);
      console.log(JSON.stringify(acs));
      if (!acs.length || miss.length) {
        console.error(acs.length ? `plan.md: ${miss.map((a) => a.ac).join(", ")} without a priority — each AC line carries [P0] … [P3]` : "plan.md has no acceptance criteria");
        process.exit(1);
      }
    } else if (cmd === "card") {
      const { acs, board } = load(jobDir);
      console.log(JSON.stringify(cardRisk(findCard(board, rest[0]), acs)));
    } else if (cmd === "qa") {
      const { acs, board } = load(jobDir);
      const errs = qaErrors(findCard(board, rest[0]), acs, rest[1] ?? "");
      if (errs.length) { for (const e of errs) console.error(e); process.exit(1); }
    } else if (cmd === "triage") {
      const [card, verdict, json] = rest;
      const r = triage(jobDir, card, verdict, json);
      if (r.errors.length) { for (const e of r.errors) console.error(e); process.exit(1); }
      console.log(JSON.stringify(r.triage));
    } else if (cmd === "nfr") console.log(JSON.stringify(nfrItems(jobDir)));
    else if (cmd === "report") {
      const r = reportNfr(jobDir);
      if (r.errors.length) { for (const e of r.errors) console.error(e); process.exit(1); }
      console.log(JSON.stringify(r.rows));
    } else throw new Error("usage: risk.mjs plan|card|qa|triage|nfr|report <job dir> …");
  } catch (e) { console.error(`risk: ${e.message}`); process.exit(1); }
}
