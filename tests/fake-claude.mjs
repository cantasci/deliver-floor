#!/usr/bin/env node
// A stand-in for `claude -p … --agent <name>` in tests of the code driver (kit/skills/deliver/bin/run.mjs, DELIVER_CLAUDE).
// What an agent "does" is a shell script: $FAKE_CLAUDE_DIR/<agent, ':' and '/' as '_'>.sh, run in the agent's directory with
// PROMPT (the prompt), RESUME (1 when --resume was passed) and DELIVER_AGENT_ID. Its stdout is the agent's answer.
// Every call is appended to $FAKE_CLAUDE_DIR/calls.log: <agent>\t<resume>\t<first line of the prompt>.
import { spawnSync } from "node:child_process";
import { appendFileSync, existsSync } from "node:fs";
import { join } from "node:path";
const a = process.argv.slice(2), arg = (f) => (a.includes(f) ? a[a.indexOf(f) + 1] : "");
const prompt = arg("-p"), agent = arg("--agent"), dir = process.env.FAKE_CLAUDE_DIR;
const script = join(dir, `${agent.replace(/[:/]/g, "_")}.sh`);
appendFileSync(join(dir, "calls.log"), `${agent}\t${a.includes("--resume") ? 1 : 0}\t${prompt.split("\n")[0].slice(0, 80)}\n`);
let result = `no script for agent ${agent}`, is_error = true;
if (existsSync(script)) {
  const r = spawnSync("bash", [script], { env: { ...process.env, PROMPT: prompt, RESUME: a.includes("--resume") ? "1" : "" }, encoding: "utf8" });
  result = (r.stdout ?? "").trim() || (r.stderr ?? "").trim(); is_error = r.status !== 0;
}
console.log(JSON.stringify({ type: "result", subtype: is_error ? "error" : "success", is_error, result, session_id: `sess-${agent}-${process.env.DELIVER_AGENT_ID ?? ""}`, total_cost_usd: 0.01 }));
