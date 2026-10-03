#!/usr/bin/env node
// tracker-cli.mjs — the command line of tracker.mjs (dl calls it on every transition).
//   node tracker-cli.mjs open   <job dir>                          create the job (epic) + all cards in the tool
//   node tracker-cli.mjs sync   <job dir> [card] [--event "<text>"] move card(s) to the column their state implies
//   node tracker-cli.mjs note   <job dir> <card> <author> "<text>"  comment on a card as a role
//   node tracker-cli.mjs branch <job dir> <card>                   attach the card's branch to the task
//   node tracker-cli.mjs kanban <job dir> [--html <file>]          print the board as kanban columns (+ HTML view)
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { createTracker, kanbanText, kanbanHtml } from "./tracker.mjs";

// ---- CLI -----------------------------------------------------------------------------------------------------------------
{
  const [cmd, jobDir, ...rest] = process.argv.slice(2);
  const flag = (n) => { const i = rest.indexOf(n); return i >= 0 ? rest.splice(i, 2)[1] : undefined; };
  try {
    if (!cmd || !jobDir) throw new Error("usage: tracker.mjs open|sync|note|kanban <job dir> …");
    if (cmd === "kanban") {
      const job = JSON.parse(readFileSync(join(jobDir, "job.json"), "utf8")), board = JSON.parse(readFileSync(join(jobDir, "board.json"), "utf8"));
      console.log(kanbanText(job, board));
      const html = flag("--html"); if (html) { writeFileSync(html, kanbanHtml(job, board)); console.log(`html: ${html}`); }
    } else {
      const t = await createTracker(jobDir);
      if (cmd === "open") { await t.open(); console.log(t.where()); }
      else if (cmd === "sync") { const ev = flag("--event"); await t.sync(rest[0], ev); }
      else if (cmd === "note") { const [card, author, ...text] = rest; await t.note(card, author, text.join(" ")); }
      else if (cmd === "branch") await t.branch(rest[0]);
      else throw new Error(`unknown command: ${cmd}`);
    }
  } catch (e) { console.error(`tracker: ${e.message}`); process.exit(1); }
}
