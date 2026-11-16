#!/usr/bin/env node
// usage.mjs — what a job's agents spent, per role and per card, and the job's budget (settings.budget).
// Tokens come from Claude Code itself: each subagent's transcript (the SubagentStop hook), the orchestrator's own session
// (the Agent and Stop hooks), the code driver's result per role session. Dollars are an estimate from the price table
// (settings.prices, $ per million tokens) — except under the code driver, where Claude Code reports them (total_cost_usd).
//   node usage.mjs event <agent transcript> <job dir> <agent> <agent id>  → the payload of one "usage" event (SubagentStop)
//   node usage.mjs michael <session transcript> <job dir>                 → <job dir>/michael-usage.json: his share since the job
//                                                                           began, per session (a headless job is many sessions)
//   node usage.mjs spend <job dir> [--json]                               → per role, per card, Michael, the total, the budget
//   node usage.mjs budget <job dir>                                       → one line; exit 0 within (or no budget), 1 ≥ 75 %, 2 ≥ 90 %,
//                                                                           3 used up
//   node usage.mjs report <job dir>                                       → the PR body's cost section (markdown)
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, basename } from "node:path";
import { pathToFileURL } from "node:url";

const read = (p, d) => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return d; } };
const job = (dir) => read(join(dir, "job.json"), {});

// the assistant messages of a transcript, once each: Claude Code writes one line per content block, each with the
// message's full usage (measured: a message with thinking + text + a tool call is several lines with the same id)
export function messages(transcript, { since = 0, mainOnly = false } = {}) {
  let text = ""; try { text = readFileSync(transcript, "utf8"); } catch { return { first: "", msgs: [] }; }
  const byId = new Map(); let first = "";
  for (const line of text.split("\n")) {
    if (!line) continue;
    if (!first && line.includes('"type":"user"')) {
      try {
        const c = JSON.parse(line).message?.content;
        first = typeof c === "string" ? c : Array.isArray(c) ? c.filter((b) => b.type === "text").map((b) => b.text).join("\n") : "";
      } catch { /* not JSON */ }
    }
    if (!line.includes('"usage"')) continue;
    let l; try { l = JSON.parse(line); } catch { continue; }
    if (l.type !== "assistant" || !l.message?.usage) continue;
    if (mainOnly && l.isSidechain) continue;
    if (since && Date.parse(l.timestamp ?? "") < since) continue;
    byId.set(l.message.id ?? `n${byId.size}`, { model: l.message.model, u: l.message.usage });
  }
  return { first, msgs: [...byId.values()] };
}

// $ per million tokens for a model: the exact id, else the longest key it starts with ("claude-opus-5-5[1m]")
export function priceOf(model, prices = {}) {
  if (!model) return null;
  if (prices[model]) return prices[model];
  const k = Object.keys(prices).filter((p) => model.startsWith(p)).sort((a, b) => b.length - a.length)[0];
  return k ? prices[k] : null;
}

// tokens and the estimate over a set of messages; an unpriced model counts its tokens, not dollars, and is named
export function tally(msgs, prices) {
  const t = { in: 0, out: 0, cw: 0, cr: 0, usd: 0, unpriced: new Set(), models: new Map() };
  for (const { model, u } of msgs) {
    if (!model || model === "<synthetic>") continue;
    const cw = u.cache_creation_input_tokens ?? 0, cw1h = u.cache_creation?.ephemeral_1h_input_tokens ?? 0;
    t.in += u.input_tokens ?? 0; t.out += u.output_tokens ?? 0; t.cw += cw; t.cr += u.cache_read_input_tokens ?? 0;
    t.models.set(model, (t.models.get(model) ?? 0) + (u.output_tokens ?? 0));
    const p = priceOf(model, prices);
    if (!p) { t.unpriced.add(model); continue; }
    // fast mode: Anthropic's published fast prices are twice the standard ones (Opus 5.5, Fable 5.2)
    const fast = u.speed === "fast" ? 2 : 1;
    t.usd += fast * ((u.input_tokens ?? 0) * p.in + (u.output_tokens ?? 0) * p.out + (cw - cw1h) * p.cw5m
      + cw1h * p.cw1h + (u.cache_read_input_tokens ?? 0) * p.cr) / 1e6;
  }
  t.model = [...t.models].sort((a, b) => b[1] - a[1])[0]?.[0] ?? "-";
  return t;
}

// which card and role a subagent worked for, from the prompt the playbook gives it (ROLE CARD: …/roles/<role>.md;
// the card's worktree …/wt/T-xx, or the card JSON)
export function attribute(prompt) {
  const role = prompt.match(/\/roles\/([a-z0-9-]+)\.md/)?.[1] ?? "-";
  const card = prompt.match(/\/wt\/(T-\d+)/)?.[1] ?? prompt.match(/"id"\s*:\s*"(T-\d+)"/)?.[1] ?? "-";
  return { role, card };
}

export const fmt = (t) => `model=${t.model} in=${t.in} out=${t.out} cw=${t.cw} cr=${t.cr} usd=${t.usd.toFixed(4)}${t.unpriced.size ? ` unpriced=${[...t.unpriced].join(",")}` : ""}`;

// the usage events of the job: one per agent run. A subagent resumed (SendMessage) stops again with its whole transcript —
// the last event of an agent id counts, not the sum
export function events(dir) {
  let lines = []; try { lines = readFileSync(join(dir, "events.log"), "utf8").split("\n"); } catch { /* no log */ }
  const runs = new Map();
  for (const l of lines) {
    const [ts, kind, msg = ""] = l.split("\t"); if (kind !== "usage") continue;
    const [agent, id] = msg.split(" ");
    const kv = Object.fromEntries([...msg.matchAll(/(\w+)=(\S+)/g)].map((m) => [m[1], m[2]]));
    runs.set(id && id !== "-" ? id : `n${runs.size}`, { ts, agent, id, card: kv.card ?? "-", role: kv.role ?? "-", model: kv.model ?? "-",
      in: +kv.in || 0, out: +kv.out || 0, cw: +kv.cw || 0, cr: +kv.cr || 0, usd: +kv.usd || 0, unpriced: kv.unpriced ?? "", src: kv.src ?? "est" });
  }
  return [...runs.values()];
}

// the budget in force: the human's raise (job.budget) over settings.budget; null = no limit
export function budgetOf(j) {
  const b = { ...(j.settings?.budget ?? {}), ...(j.budget ?? {}) };
  const n = (v) => (typeof v === "number" && v > 0 ? v : null);
  return { usd: n(b.usd), minutes: n(b.minutes) };
}

export function spend(dir) {
  const j = job(dir), runs = events(dir), ms = Object.values(read(join(dir, "michael-usage.json"), {}));
  const mi = ms.length ? ms.reduce((a, m) => ({ in: a.in + m.in, out: a.out + m.out, cw: a.cw + m.cw, cr: a.cr + m.cr, usd: a.usd + m.usd,
    unpriced: [...a.unpriced, ...(m.unpriced ?? [])], runs: a.runs + 1 }), { in: 0, out: 0, cw: 0, cr: 0, usd: 0, unpriced: [], runs: 0 }) : null;
  const sum = (xs) => xs.reduce((a, r) => ({ in: a.in + r.in, out: a.out + r.out, cw: a.cw + r.cw, cr: a.cr + r.cr, usd: a.usd + r.usd, runs: a.runs + 1 }),
    { in: 0, out: 0, cw: 0, cr: 0, usd: 0, runs: 0 });
  const group = (key) => [...runs.reduce((m, r) => m.set(r[key], [...(m.get(r[key]) ?? []), r]), new Map())]
    .map(([k, xs]) => ({ [key]: k, ...sum(xs) })).sort((a, b) => b.usd - a.usd);
  const agents = sum(runs), michael = mi && mi.in + mi.out + mi.cw + mi.cr > 0 ? { in: mi.in, out: mi.out, cw: mi.cw, cr: mi.cr, usd: mi.usd, runs: mi.runs } : null;
  const total = { usd: agents.usd + (michael?.usd ?? 0), out: agents.out + (michael?.out ?? 0) };
  const created = Date.parse(j.created ?? j.created_at ?? "");
  const minutes = Number.isNaN(created) ? 0 : (Date.now() - created) / 60000;
  const b = budgetOf(j);
  const share = Math.max(b.usd ? total.usd / b.usd : 0, b.minutes ? minutes / b.minutes : 0);
  const unpriced = [...new Set([...runs.flatMap((r) => (r.unpriced ? r.unpriced.split(",") : [])), ...(mi?.unpriced ?? [])])];
  return { roles: group("role"), cards: group("card"), agents, michael, total, minutes: Math.round(minutes), budget: b,
    share: Math.round(share * 100), state: !b.usd && !b.minutes ? "none" : share >= 1 ? "reached" : share >= 0.9 ? "90" : share >= 0.75 ? "75" : "ok",
    exact: runs.length > 0 && runs.every((r) => r.src === "cc") && !michael, unpriced, prices_as_of: j.settings?.prices_as_of ?? null };
}

const money = (v) => `$${v.toFixed(2)}`;
export function budgetLine(s) {
  const parts = [];
  if (s.budget.usd) parts.push(`${money(s.total.usd)} of ${money(s.budget.usd)}`);
  if (s.budget.minutes) parts.push(`${s.minutes} of ${s.budget.minutes} min`);
  return parts.length ? `${parts.join(" · ")} (${s.share} %)` : `${money(s.total.usd)} · ${s.minutes} min (no budget)`;
}

function report(dir) {
  const s = spend(dir);
  if (!s.agents.runs && !s.michael) return "";
  const k = (n) => (n >= 1e6 ? `${(n / 1e6).toFixed(1)}M` : n >= 1e3 ? `${Math.round(n / 1e3)}k` : String(n));
  const row = (name, r) => `| ${name} | ${r.runs ?? "-"} | ${k(r.in + r.cw + r.cr)} | ${k(r.out)} | ${money(r.usd)} |`;
  const out = ["", "<!-- deliver:cost -->", "## Cost", "",
    `${s.exact ? "Reported by Claude Code (the code driver)." : `Estimated from the token counts in Claude Code's transcripts and the price table (settings.prices${s.prices_as_of ? `, as of ${s.prices_as_of}` : ""}).`} Input counts cache reads and writes.`,
    "", `Total **${money(s.total.usd)}** · ${s.minutes} min${s.budget.usd || s.budget.minutes ? ` · budget ${budgetLine(s)}` : ""}`, "",
    "| Role | Runs | Input tokens | Output tokens | $ |", "| --- | --- | --- | --- | --- |",
    ...s.roles.map((r) => row(r.role, r)), ...(s.michael ? [row("orchestrator (Michael)", s.michael)] : []), "",
    "| Card | Runs | Input tokens | Output tokens | $ |", "| --- | --- | --- | --- | --- |",
    ...s.cards.map((r) => row(r.card === "-" ? "(no card: readiness, planning, closing)" : r.card, r))];
  if (s.unpriced.length) out.push("", `No price for ${s.unpriced.join(", ")}: their tokens are counted, not their dollars (settings.prices).`);
  return out.join("\n");
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [cmd, a, b, c, d] = process.argv.slice(2);
  if (cmd === "event" && a && b) {
    const { first, msgs } = messages(a); const t = tally(msgs, job(b).settings?.prices); const { role, card } = attribute(first);
    console.log(`${c || "agent"} ${d || "-"} card=${card} role=${role} ${fmt(t)}`);
  } else if (cmd === "michael" && a && b) {
    const j = job(b); const since = Date.parse(j.created ?? j.created_at ?? "") || 0;
    const t = tally(messages(a, { since, mainOnly: true }).msgs, j.settings?.prices);
    const all = read(join(b, "michael-usage.json"), {});
    all[basename(a)] = { model: t.model, in: t.in, out: t.out, cw: t.cw, cr: t.cr, usd: +t.usd.toFixed(4), unpriced: [...t.unpriced], at: new Date().toISOString() };
    writeFileSync(join(b, "michael-usage.json"), JSON.stringify(all, null, 2) + "\n");
  } else if (cmd === "spend" && a && existsSync(a)) {
    const s = spend(a);
    if (b === "--json") console.log(JSON.stringify(s, null, 2));
    else {
      console.log(`cost: ${budgetLine(s)}${s.exact ? "" : " — estimated"}`);
      for (const r of s.roles) console.log(`  ${r.role.padEnd(24)} ${String(r.runs).padStart(3)} run(s)  ${money(r.usd).padStart(9)}`);
      if (s.michael) console.log(`  ${"orchestrator (Michael)".padEnd(24)} ${String(s.michael.runs).padStart(3)} session(s) ${money(s.michael.usd).padStart(6)}`);
      if (s.unpriced.length) console.log(`  no price for ${s.unpriced.join(", ")} (settings.prices): tokens counted, not dollars`);
    }
  } else if (cmd === "budget" && a && existsSync(a)) {
    const s = spend(a); console.log(budgetLine(s));
    process.exit({ reached: 3, 90: 2, 75: 1 }[s.state] ?? 0);
  } else if (cmd === "report" && a && existsSync(a)) {
    const r = report(a); if (r) console.log(r);
  } else { console.error("usage: usage.mjs event <transcript> <job dir> <agent> <id> | michael <transcript> <job dir> | spend|budget|report <job dir>"); process.exit(2); }
}
