#!/usr/bin/env node
// agents.mjs — which subagent worked on which card, read from Claude Code's own subagent transcripts, so a role agent that
// stopped (a usage limit, an API error, a restart) is CONTINUED with its whole history (SendMessage to its id) instead of
// replaced by a new agent that has to read everything again. Claude Code keeps every subagent's transcript at
// <config dir>/projects/<project>/<session id>/subagents/agent-<agent id>.jsonl (+ agent-<id>.meta.json: agentType,
// description); its first line carries agentId, sessionId and the prompt the agent was given. A prompt names the job's
// folder (.work/<JOB>/…) and the card (T-xx), so jobs started before this file existed are found the same way.
//   node agents.mjs <job dir> [card] [--all]      JSON, newest first: the newest agent of each role on each card
//                                                  (--all: every agent of the job, plan steps included)
import { readdirSync, readFileSync, statSync, existsSync, openSync, readSync, closeSync } from "node:fs";
import { join, basename } from "node:path";
import { homedir } from "node:os";

const firstLine = (f) => { // the first line only — transcripts grow large
  const fd = openSync(f, "r"), buf = Buffer.alloc(65536); const n = readSync(fd, buf, 0, buf.length, 0); closeSync(fd);
  const s = buf.subarray(0, n).toString("utf8"); const i = s.indexOf("\n"); return i < 0 ? s : s.slice(0, i);
};
const text = (c) => typeof c === "string" ? c : Array.isArray(c) ? c.map((x) => x.text ?? "").join("\n") : "";

export function findAgents(jobDir, { card, all = false, configDir = process.env.CLAUDE_CONFIG_DIR ?? join(homedir(), ".claude") } = {}) {
  const job = basename(jobDir), root = join(configDir, "projects"), out = [];
  if (!existsSync(root)) return out;
  for (const proj of readdirSync(root)) {
    let sessions; try { sessions = readdirSync(join(root, proj)); } catch { continue; }
    for (const sess of sessions) {
      const dir = join(root, proj, sess, "subagents");
      if (!existsSync(dir)) continue;
      for (const f of readdirSync(dir).filter((x) => /^agent-.+\.jsonl$/.test(x))) {
        const path = join(dir, f);
        let first; try { first = JSON.parse(firstLine(path)); } catch { continue; }
        const prompt = text(first.message?.content);
        if (!prompt.includes(`.work/${job}/`) && !prompt.includes(`.work\\${job}\\`)) continue;
        const c = (prompt.match(/[/\\]wt[/\\](T-\d+)\b/) ?? prompt.match(/\b(T-\d+)\b/))?.[1] ?? null;
        if (card && c !== card) continue;
        let meta = {}; try { meta = JSON.parse(readFileSync(path.replace(/\.jsonl$/, ".meta.json"), "utf8")); } catch { /* older Claude Code */ }
        // how it ended: the last assistant message, and whether Claude Code recorded an API error (a usage limit, credit)
        const lines = readFileSync(path, "utf8").trim().split("\n");
        let last = "", apiError = null, at = null, ended = false;
        for (let i = lines.length - 1; i >= 0 && !(at && ended); i--) {
          let j; try { j = JSON.parse(lines[i]); } catch { continue; }
          if (!at && j.timestamp) at = j.timestamp;
          if (!ended && j.type === "assistant") { ended = true; last = text(j.message?.content); if (j.isApiErrorMessage) apiError = last; }
        }
        at ??= first.timestamp ?? null;
        out.push({ card: c, agentId: first.agentId ?? f.slice(6, -6), sessionId: first.sessionId ?? sess, agentType: meta.agentType ?? null,
          description: meta.description ?? null, last_at: at ?? new Date(statSync(path).mtimeMs).toISOString(),
          last: last.replace(/\s+/g, " ").slice(0, 200), apiError: apiError ? apiError.replace(/\s+/g, " ").slice(0, 200) : null });
      }
    }
  }
  out.sort((a, b) => String(b.last_at).localeCompare(String(a.last_at)));
  if (all) return out;
  const seen = new Set();   // the newest agent of each role on each card — the one to continue
  return out.filter((a) => { const k = `${a.card}\t${a.agentType}`; return a.card && !seen.has(k) && seen.add(k); });
}

if (import.meta.url === `file://${process.argv[1]}` || process.argv[1]?.endsWith("agents.mjs")) {
  const args = process.argv.slice(2), all = args.includes("--all"), [jobDir, card] = args.filter((a) => a !== "--all");
  if (!jobDir) { console.error("usage: agents.mjs <job dir> [card] [--all]"); process.exit(2); }
  console.log(JSON.stringify(findAgents(jobDir, { card, all })));
}
