#!/usr/bin/env node
// When a Claude usage limit resets, read from Claude Code's own message — so an unattended run (scripts/run-headless.sh)
// waits until then and goes on by itself (live job: 36.6 of 65.7 hours were limit waits, many of them hours past the reset
// because nobody saw it).
//   node limit-reset.mjs [now, epoch seconds] < text
//     exit 0 → prints the reset as epoch seconds · 2 → out of credits: no reset, the human's call · 1 → no limit in the text
// Seen: "You've hit your session limit · resets 2:30pm (Europe/Berlin)"; a weekly limit names its day ("resets Oct 12, 3pm").
import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

const MONTHS = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];

export function resetAt(text, now = Date.now()) {
  const m = text.match(/hit your [\w -]*limit[^\n]*?resets\s+(?:([a-z]{3})[a-z]*\.?\s+(\d{1,2}),?\s+(?:at\s+)?)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\s*(?:\(([^)]+)\))?/i);
  if (!m) return /out of (usage )?credits/i.test(text) ? { credits: true } : null;
  const [, mon, day, hh, mm, ap, zone] = m;
  const h = (Number(hh) % 12) + (ap.toLowerCase() === "pm" ? 12 : 0), min = Number(mm ?? 0);
  let tz = zone || Intl.DateTimeFormat().resolvedOptions().timeZone;
  try { new Intl.DateTimeFormat("en-US", { timeZone: tz }); } catch { tz = Intl.DateTimeFormat().resolvedOptions().timeZone; }
  const fmt = new Intl.DateTimeFormat("en-US", { timeZone: tz, hourCycle: "h23", year: "numeric", month: "numeric", day: "numeric",
    hour: "numeric", minute: "numeric", second: "numeric" });
  const parts = (t) => Object.fromEntries(fmt.formatToParts(new Date(t)).filter((p) => p.type !== "literal").map((p) => [p.type, Number(p.value)]));
  const offset = (t) => { const p = parts(t); return Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second) - Math.floor(t / 1000) * 1000; };
  // a wall-clock time in tz → epoch ms: start from it read as UTC, correct by tz's offset (twice, for a DST change between)
  const wall = (y, mo, d) => { const g = Date.UTC(y, mo, d, h, min); const e0 = g - offset(g); return g - offset(e0); };
  const today = parts(now);
  let at;
  if (mon) {
    const mo = MONTHS.indexOf(mon.toLowerCase()); if (mo < 0) return null;
    at = wall(today.year, mo, Number(day));
    if (at <= now) at = wall(today.year + 1, mo, Number(day));   // a day already past: next year's
  } else {
    at = wall(today.year, today.month - 1, today.day);
    if (at <= now) at = wall(today.year, today.month - 1, today.day + 1);   // the time already passed today: tomorrow
  }
  return { at: Math.floor(at / 1000) };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const r = resetAt(readFileSync(0, "utf8"), process.argv[2] ? Number(process.argv[2]) * 1000 : Date.now());
  if (!r) process.exit(1);
  if (r.credits) process.exit(2);
  console.log(r.at);
}
