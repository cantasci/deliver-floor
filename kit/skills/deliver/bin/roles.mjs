#!/usr/bin/env node
// roles.mjs — reads roles.yaml and turns the job's selected roles into project-specific role cards.
//   node roles.mjs catalog                 → the catalog as JSON
//   node roles.mjs check <job.json>        → every selected role/agent exists in the catalog (exit 1 if not)
//   node roles.mjs render <job dir>        → .work/<job>/roles/<role>.md + ROLES.md
// A role card = rules.all + rules.<kind> + the role's own rules + facts about this project and job.
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { section as knowledgeSection } from "./knowledge.mjs";

const SKILL_DIR = join(dirname(fileURLToPath(import.meta.url)), "..");
// The name to invoke an agent by: under a plugin install the kit's own agents are namespaced (dl sets DELIVER_AGENT_NS).
export const agentCall = (a) => {
  const ns = process.env.DELIVER_AGENT_NS ?? "";
  return ns && !a.includes(":") && existsSync(join(SKILL_DIR, "..", "..", "agents", `${a}.md`)) ? `${ns}:${a}` : a;
};

// --- a small YAML subset: maps by indentation, "- scalar" lists, quoted/bare scalars, # comments ------------------
export function parseYaml(text, label = "yaml") {
  const lines = [];
  text.split("\n").forEach((raw, n) => {
    const noComment = stripComment(raw);
    if (!noComment.trim()) return;
    const indent = noComment.match(/^ */)[0].length;
    if (/\t/.test(noComment.slice(0, indent + 1))) throw new Error(`${label}:${n + 1}: tabs are not allowed`);
    lines.push({ indent, text: noComment.trim(), n: n + 1 });
  });
  let i = 0;
  const KEY = /^("[^"]*"|[^:"]+?):(?:\s+(.*))?$/;
  const mapEntries = (obj, indent) => { // consume "key: value" lines at exactly this indent
    while (i < lines.length && lines[i].indent === indent && !lines[i].text.startsWith("- ")) {
      const { text: t, n } = lines[i];
      const m = t.match(KEY);
      if (!m) throw new Error(`${label}:${n}: cannot parse '${t}'`);
      const key = scalar(m[1]); i++;
      if (m[2] !== undefined && m[2] !== "") obj[key] = scalar(m[2]);
      else obj[key] = i < lines.length && lines[i].indent > indent ? block(lines[i].indent) : null;
    }
    return obj;
  };
  const block = (indent) => {
    if (i >= lines.length) return null;
    if (lines[i].text.startsWith("- ")) {
      const arr = [];
      while (i < lines.length && lines[i].indent === indent && lines[i].text.startsWith("- ")) {
        const rest = lines[i].text.slice(2), m = rest.match(KEY);
        if (m && !rest.startsWith('"')) { // a list item that is a map: "- key: value" + keys indented by 2
          lines[i] = { ...lines[i], indent: indent + 2, text: rest };
          arr.push(mapEntries({}, indent + 2));
        } else { arr.push(scalar(rest)); i++; }
      }
      return arr;
    }
    const obj = mapEntries({}, indent);
    if (i < lines.length && lines[i].indent > indent) throw new Error(`${label}:${lines[i].n}: unexpected indentation`);
    return obj;
  };
  const out = block(0) ?? {};
  if (i < lines.length) throw new Error(`${label}:${lines[i].n}: unexpected indentation`);
  return out;
}
function stripComment(line) {
  let q = false;
  for (let k = 0; k < line.length; k++) {
    if (line[k] === '"' && line[k - 1] !== "\\") q = !q;
    if (line[k] === "#" && !q && (k === 0 || /\s/.test(line[k - 1]))) return line.slice(0, k).replace(/\s+$/, "");
  }
  return line.replace(/\s+$/, "");
}
function scalar(s) {
  s = s.trim();
  if (s.startsWith("[") && s.endsWith("]")) { // flow list: ["a", b, "c, d"]
    const out = []; let cur = "", q = false;
    for (const ch of s.slice(1, -1)) {
      if (ch === '"') q = !q;
      if (ch === "," && !q) { if (cur.trim()) out.push(scalar(cur)); cur = ""; } else cur += ch;
    }
    if (cur.trim()) out.push(scalar(cur));
    return out;
  }
  if (s.startsWith('"')) return JSON.parse(s);
  if (s === "true") return true;
  if (s === "false") return false;
  if (s === "null" || s === "~") return null;
  if (/^-?\d+(\.\d+)?$/.test(s)) return Number(s);
  return s;
}

export const loadCatalog = (file = join(SKILL_DIR, "roles.yaml")) => parseYaml(readFileSync(file, "utf8"), "roles.yaml");

// --- checks ---------------------------------------------------------------------------------------------------------
export function checkJobRoles(job, cat) {
  const errors = [];
  const known = new Set(Object.keys(cat.roles ?? {}));
  const reviewers = new Set(Object.values(cat.stack_reviewers ?? {}));
  for (const r of job.roles ?? []) {
    if (r.role === "reviewer" || r.role?.startsWith("reviewer")) {
      if (!reviewers.has(r.agent)) errors.push(`reviewer agent '${r.agent}' is not in stack_reviewers`);
      continue;
    }
    if (!known.has(r.role)) { errors.push(`role '${r.role}' is not in roles.yaml`); continue; }
    if (cat.roles[r.role].agent !== r.agent) errors.push(`role '${r.role}' must use agent '${cat.roles[r.role].agent}', not '${r.agent}'`);
  }
  for (const [name, r] of Object.entries(cat.roles ?? {}))
    if (r.always && !(job.roles ?? []).some((s) => s.role === name)) errors.push(`role '${name}' is always selected`);
  const devs = (job.roles ?? []).filter((r) => cat.roles[r.role]?.kind === "dev");
  if (!devs.length) errors.push("no dev role selected — nobody could build the cards");
  // The stack reviewer follows the language. In a repo without code the language is decided at readiness (ARC-stack — the
  // request or the human, never a default), so until then the job may have no reviewer yet; from planning on it must.
  const stackOpen = !(job.stack ?? []).length && ["intake", "readiness", "awaiting_clarification"].includes(job.phase);
  if (!stackOpen && !(job.roles ?? []).some((r) => r.role?.startsWith("reviewer"))) errors.push("no stack reviewer selected (role 'reviewer')");
  const PROVIDERS = ["claude", "codex", "gemini", "grok", "kimi", "qwen", "opencode", "crush", "pi", "copilot", "cursor", "antigravity"];
  for (const r of job.roles ?? []) if (r.provider && !PROVIDERS.includes(r.provider)) errors.push(`role '${r.role}': provider '${r.provider}' is not one of ${PROVIDERS.join(", ")}`);
  const sa = (job.roles ?? []).filter((r) => (r.provider ?? "claude") !== "claude" && (job.settings?.dispatch ?? "munder") !== "munder");
  for (const r of sa) errors.push(`role '${r.role}' runs on ${r.provider}: non-Claude roles run as Munder Difflin floor workers — set dispatch "munder"`);
  return errors;
}

// --- rendering ------------------------------------------------------------------------------------------------------
const KIND_TITLE = { ba: "Business analyst", lead: "Lead", dev: "Developer", review: "Reviewer", qa: "QA" };

function projectFacts(job) {
  const root = job.repo;
  const facts = [
    `Repository: ${root} (base branch ${job.base_branch}; job branch ${job.branch})`,
    `Stack: ${(job.stack ?? []).join(", ") || "not detected"}`,
    `Full verification of the job: \`${job.settings?.verify_full ?? "-"}\``,
  ];
  facts.push(job.settings?.commit?.ai_attribution === true ? "Commits: AI attribution lines are allowed." :
    "Commits: no AI attribution — no 'Co-Authored-By: Claude …', no 'Generated with Claude Code', no Anthropic e-mail (the gate rejects them).");
  facts.push(job.settings?.commit?.convention === "conventional"
    ? `Commits: this repo uses Conventional Commits (${job.settings.commit.convention_source ?? "its commit rules"}) — every message is \`<type>(<optional scope>): <summary>\`, lower-case summary, the card id at the end: \`feat: add notch change (T-01)\`, \`fix: …\`, \`test: integration tests for AC-1..AC-4 (T-01)\`. The gate rejects any other form.`
    : "Commits: `<CARD-ID>: <what changed>` (QA: `<CARD-ID> QA: <what>`).");
  if (job.settings?.commit?.role_in_message === true) facts.push("Commits: end every commit message with a trailer line `Role: <your seat, e.g. backend#1>` (the gate checks it).");
  if (job.settings?.worktree_setup) facts.push(`Each worktree is prepared with: \`${job.settings.worktree_setup}\``);
  for (const f of ["CLAUDE.md", "AGENTS.md", "CONTRIBUTING.md"])
    if (root && existsSync(join(root, f))) facts.push(`Project conventions: read \`${f}\` at the repository root before you start.`);
  return facts;
}

// The components this role builds (dev), reviews (reviewer) or tests (qa), with the stack skills to load.
function componentsSection(sel, r, job, cat) {
  let arch = null;
  try { const raw = JSON.parse(readFileSync(join(job.repo, ".work", job.id, "readiness.json"), "utf8")); arch = raw.architecture ?? null; } catch { return ""; }
  if (!arch?.components?.length) return "";
  const mine = arch.components.filter((c) => r.kind === "qa" || r.kind === "ba" || r.kind === "lead" || c.owner === sel.role || c.reviewer === sel.role);
  if (!mine.length) return "";
  const skills = (c) => [...new Set((c.stack ?? []).flatMap((s) => cat.stack_skills?.[s] ?? []))];
  return ["## Components (frozen architecture: " + (arch.style ?? "?") + ")", "",
    ...mine.map((c) => `- **${c.id}** (${c.kind}) — stack ${(c.stack ?? []).join(", ")} — path ${[].concat(c.path).map((x) => `\`${x}\``).join(", ")} — dev: ${c.owner}, review: ${c.reviewer}` +
      (skills(c).length ? `\n  skills to load for it: ${skills(c).map((x) => "`" + x + "`").join(", ")}` : "")),
    "", "The architecture is frozen: build inside it. If it cannot work, say so in your answer — do not change it.", ""].join("\n");
}

function roleEntry(sel, cat) {
  if (sel.role?.startsWith("reviewer")) return { kind: "review", agent: sel.agent, does: "Lead review of each card's change for the job's stack.", floor: { character: "toby", accent: "slate" } };
  return cat.roles[sel.role];
}

export function renderRole(sel, job, cat) {
  const r = roleEntry(sel, cat);
  const rules = [...(cat.rules?.all ?? []), ...(cat.rules?.[r.kind] ?? []), ...(r.rules ?? [])];
  const md = [
    `# Role: ${sel.role} — ${KIND_TITLE[r.kind] ?? r.kind}${r.focus ? ` (${r.focus})` : ""}`,
    "",
    `Job: **${job.id}** — ${job.title}`,
    `Agent: \`${agentCall(sel.agent)}\` · runs on: ${sel.provider ?? "claude"}${sel.model ? ` (${sel.model})` : ""} · writes files: ${r.writes ? "yes (only where the rules allow)" : "no"}`,
    `Why this role is on the job: ${sel.why ?? r.when ?? "-"}`,
    "",
    "## Mission",
    "",
    r.does ?? (r.kind === "dev" ? `Implement the cards assigned to the '${sel.role}' role, one card per session, inside the card worktree.` : "-"),
    "",
    "## Rules",
    "",
    ...rules.map((x, k) => `${k + 1}. ${x}`),
    "",
    "## This project",
    "",
    ...projectFacts(job).map((x) => `- ${x}`),
    "",
    componentsSection(sel, r, job, cat),
    job.repo ? knowledgeSection(job.repo, { kind: r.kind, role: sel.role, stack: job.stack ?? [], jobDir: job.dir }) : "",
  ].join("\n");
  return { md, rules, entry: r };
}


export function render(jobDir) {
  const job = { ...JSON.parse(readFileSync(join(jobDir, "job.json"), "utf8")), dir: jobDir };
  const cat = loadCatalog();
  const errors = checkJobRoles(job, cat);
  if (errors.length) { for (const e of errors) console.error(`ERROR ${e}`); process.exit(1); }
  mkdirSync(join(jobDir, "roles"), { recursive: true });
  const munder = job.settings?.dispatch === "munder";
  const rows = [];
  for (const sel of job.roles) {
    if (sel.agent === "artemis") { rows.push(`| ${sel.role} | artemis (Michael) | qa | ${sel.why ?? ""} | — |`); continue; }
    const out = renderRole(sel, job, cat);
    const file = join(jobDir, "roles", `${sel.role}.md`);
    writeFileSync(file, out.md);
    rows.push(`| ${sel.role} | \`${agentCall(sel.agent)}\` | ${out.entry.kind} | ${sel.why ?? ""} | roles/${sel.role}.md |`);
  }
  writeFileSync(join(jobDir, "ROLES.md"), [
    `# Roles for ${job.id}`, "", "| Role | Agent | Kind | Why | Rules |", "| --- | --- | --- | --- | --- |", ...rows, "",
    process.env.DELIVER_AGENT_NS ? `The kit runs as the \`${process.env.DELIVER_AGENT_NS}\` plugin: call its agents by the names above (subagent_type, claude --agent). job.json and board.json keep the plain names.\n` : "",
    munder ? "On the Munder Difflin floor each role seat is a person Michael hires for the whole job: dl md-hire, dl md-seats." : "",
  ].join("\n"));
  console.log(`roles: ${job.roles.length} role card(s) → ${join(jobDir, "roles")}`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [cmd, arg] = process.argv.slice(2);
  if (cmd === "catalog") console.log(JSON.stringify(loadCatalog(), null, 2));
  else if (cmd === "check") {
    const errs = checkJobRoles(JSON.parse(readFileSync(arg, "utf8")), loadCatalog());
    for (const e of errs) console.log(`ERROR ${e}`);
    process.exit(errs.length ? 1 : 0);
  } else if (cmd === "render") render(arg);
  else { console.error("usage: roles.mjs catalog | check <job.json> | render <job dir>"); process.exit(2); }
}
