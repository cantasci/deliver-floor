// Drives the real Munder Difflin app (Electron) like a user: open the hive, brief Michael, watch the floor.
//   node md-drive.cjs <md dir> <home> <shots dir> <repo> "<message to Michael>" [timeout minutes] [answers.json] [dl]
// Prints progress lines; exits 0 when the repo's job reaches done / awaiting_pr_merge, 1 on timeout or stall.
// When Michael stops with questions (awaiting_clarification), the "human" answers each one from answers.json
// (matched by topic, recorded with dl clarify — as a person would through ASK ME) and tells Michael in the composer.
// A question no prepared answer matches is left open: the run then stalls, as it would without a person.
const { _electron } = require('playwright');
const fs = require('fs'), path = require('path');
const [,, mdDir, home, shots, repo, message, mins = '60', answersFile, dlBin] = process.argv;
const { execFileSync } = require('child_process');
// Munder Difflin may keep its window while agent terminals live: closing is bounded, the verdict is already decided.
const closeApp = (app) => Promise.race([app.close().catch(() => {}), new Promise((r) => setTimeout(r, 15000))]);
const t0 = Date.now(), log = (m) => console.log(`[${Math.round((Date.now() - t0) / 1000)}s] ${m}`);
const job = () => { try { const id = fs.readFileSync(path.join(repo, '.work/ACTIVE'), 'utf8').trim(); return JSON.parse(fs.readFileSync(path.join(repo, '.work', id, 'job.json'), 'utf8')); } catch { return null; } };
const lastJob = () => { try { const d = fs.readdirSync(path.join(repo, '.work')).filter((x) => x.startsWith('JOB-')).sort().pop(); return d && JSON.parse(fs.readFileSync(path.join(repo, '.work', d, 'job.json'), 'utf8')); } catch { return null; } };
// The hive (for the floor's agent names): <harnessHome>/hive, harnessHome from Munder Difflin's config.
const hiveRoot = () => { try { return path.join(JSON.parse(fs.readFileSync(path.join(home, '.config/munder-difflin/config.json'), 'utf8')).harnessHome, 'hive'); } catch { return null; } };
const floorName = (worker) => { try { return JSON.parse(fs.readFileSync(path.join(hiveRoot(), 'registry.json'), 'utf8')).agents[worker]?.name ?? null; } catch { return null; } };
const events = () => { try { const d = fs.readdirSync(path.join(repo, '.work')).filter((x) => x.startsWith('JOB-')).sort().pop(); return fs.readFileSync(path.join(repo, '.work', d, 'events.log'), 'utf8').split('\n').filter(Boolean); } catch { return []; } };
const unanswered = new Set();
let focusMichael = null; // set once the window is up: selects Michael so the composer is his
async function answer(win) {
  const id = fs.readFileSync(path.join(repo, '.work/ACTIVE'), 'utf8').trim();
  const r = JSON.parse(fs.readFileSync(path.join(repo, '.work', id, 'readiness.json'), 'utf8'));
  let n = 0;
  for (const it of (r.items ?? r).filter((x) => x.status === 'open' && x.owner !== 'pm')) {
    // the answer that fits best (tests/pick-answer.mjs) — a first match once answered the wrong question
    let a = null;
    try { a = { answer: execFileSync('node', [path.join(__dirname, 'pick-answer.mjs'), answersFile, it.question, it.id], { encoding: 'utf8' }) }; } catch { a = null; }
    if (!a) { if (!unanswered.has(it.id)) log(`no prepared answer for ${it.id} — a real person must answer: ${it.question}`); unanswered.add(it.id); continue; }
    execFileSync(dlBin, ['-C', repo, 'clarify', it.id, a.answer], { env: { ...process.env, DELIVER_APPROVER: 'e2e-human' } });
    log(`human answered ${it.id}: ${it.question.slice(0, 90)}`); n++;
  }
  if (n) {
    if (focusMichael) await focusMichael();
    await win.fill('textarea[placeholder*="Michael"]', 'I answered your questions (recorded with dl clarify, see readiness.json). Continue the /deliver job.');
    await win.keyboard.press('Enter'); log('told Michael the questions are answered');
  }
}
(async () => {
  fs.mkdirSync(shots, { recursive: true });
  const app = await _electron.launch({ executablePath: `${mdDir}/node_modules/electron/dist/electron`, args: ['.', '--no-sandbox', '--disable-gpu',
      // a headless display counts as background to Chromium: keep animation frames and timers running for the driver
      '--disable-renderer-backgrounding', '--disable-background-timer-throttling', '--disable-backgrounding-occluded-windows'],
    cwd: mdDir, env: { ...process.env, HOME: home, ELECTRON_DISABLE_SANDBOX: '1' }, timeout: 90000 });
  const win = await app.firstWindow();
  await win.waitForTimeout(6000);
  const open = win.locator('button', { hasText: /^open$/i }).first();
  if (await open.count()) { await open.click(); log('opened the hive'); }
  await win.waitForSelector('textarea[placeholder="Message Michael"]', { timeout: 120000 });
  await win.waitForTimeout(20000); // let Michael's Claude session finish booting
  // A busy floor (many terminals starting at once) can stall a screenshot: skip that one, never end the run on it.
  const snap = async (p) => { try { await win.screenshot({ path: p, timeout: 30000 }); } catch (e) { log(`screenshot skipped: ${String(e.message ?? e).split('\n')[0].slice(0, 120)}`); } };
  await snap(`${shots}/00-floor.png`);
  await win.fill('textarea[placeholder="Message Michael"]', message);
  await win.keyboard.press('Enter');
  log(`briefed Michael: ${message}`);
  let shot = 1, lastLen = 0, lastChange = Date.now(), lastPhase = '', lastAsk = 0;
  let burst = 0, nb = 0;
  // Proof of who does the work: when Michael sends a seat a work order (md-send), select that person on the floor and
  // screenshot their own terminal while they work; once more when they report done (md-done). Round-robin over busy seats.
  const busy = new Map(); let rr = 0, ns = 0;
  // Select a person on the agent strip. Each name is a span titled "<name> — double-click to rename" (the text itself is
  // upper-cased). A normal click first; cards that are still sliding in never count as stable, so then the DOM click
  // event, which React handles exactly like a click on the card. A double click would rename the person instead.
  const why = (e) => String(e?.message ?? e).split('\n').filter((l) => l.trim()).slice(0, 6).join(' | ').slice(0, 400);
  // nth: several people can share a name — a re-seated seat leaves the failed worker's card on the floor (the app keeps it)
  // The card that names a person: older Munder Difflin builds title it "<name> — double-click to rename"; current ones
  // (v0.4.x) show the name only as upper-cased text, no title (seen live: no card found, no screenshot).
  const cards = async (name) => {
    const byTitle = win.locator(`[title="${name} — double-click to rename"]`);
    return (await byTitle.count()) ? byTitle : win.getByText(name.toUpperCase(), { exact: true });
  };
  const select = async (name, nth = 0) => {
    const el = (await cards(name)).nth(nth);
    if (!(await el.count())) {
      if (name !== 'Michael') { log(`select ${name}: no card on the agent strip`); return false; }
      try { await win.getByText('BOSS', { exact: true }).first().click({ timeout: 3000 }); return true; } catch (e) { log(`select Michael failed: ${why(e)}`); return false; }
    }
    try { await el.click({ timeout: 1500 }); return true; } catch (e) {
      try { await el.dispatchEvent('click'); log(`select ${name}: click timed out (${why(e)}) — sent the DOM click`); return true; }
      catch (e2) { log(`select ${name} failed: ${why(e2)}`); return false; }
    }
  };
  focusMichael = () => select('Michael');
  const seatShot = async (seat, b, tag) => {
    const name = b.name ?? (b.name = floorName(b.worker));
    if (!name) return;
    // Proof only when the Command Center really shows this person: its terminal header names the worker ("pty worker-…"),
    // polled on a timer, not on animation frames (which a background window may not get). Same-named cards: try each,
    // newest first (a re-seated seat's failed worker keeps its card).
    const n = await (await cards(name)).count();
    let shown = false;
    for (let k = Math.max(n, 1) - 1; k >= 0 && !shown; k--) {
      if (!(await select(name, k))) continue;
      shown = await win.waitForFunction((w) => document.body.innerText.includes(w), b.worker, { polling: 250, timeout: 5000 }).then(() => true, () => false);
    }
    if (!shown) { log(`select ${name}: the Command Center does not show ${b.worker} (${n} card(s) named ${name}) — no screenshot`); await select('Michael'); return; }
    await win.waitForTimeout(600);
    const file = `p${String(++ns).padStart(3, '0')}-${seat.replace('#', '')}-${b.task}-${tag}.png`;
    await snap(`${shots}/${file}`); log(`shot ${file} (${name}'s own terminal, ${b.worker})`);
    await select('Michael');
  };
  const tab = async (name) => { const b = win.locator('button', { hasText: new RegExp(`^\\s*${name}\\s*$`, 'i') }).first(); if (await b.count()) await b.click().catch(() => {}); };
  while (Date.now() - t0 < Number(mins) * 60000) {
    await win.waitForTimeout(5000);
    // While floor workers run: the Command Center's workers tab, a screenshot every 5 s (they can finish within a minute).
    if (burst > 0) {
      if (burst === 8) await tab('workers');
      await snap(`${shots}/w${String(++nb).padStart(3, '0')}-workers.png`);
      if (--burst === 0) await tab('terminal');
    }
    const j = job() ?? lastJob(), ev = events();
    if (ev.length !== lastLen) {
      for (const e of ev.slice(lastLen)) {
        log(`event ${e.split('\t').slice(1).join(' ').slice(0, 150)}`);
        const [, kind, text = ''] = e.split('\t');
        if (kind === 'md-dispatch' && burst === 0) burst = 8;
        let m;
        if (kind === 'md-send' && (m = text.match(/^(\S+) (\S+) \((\S+)\) → (\S+)/))) busy.set(m[2], { task: m[1], agent: m[3], worker: m[4], n: 0 });
        if (kind === 'md-done' && (m = text.match(/^(\S+) (\S+):/)) && busy.has(m[2])) { await seatShot(m[2], busy.get(m[2]), 'done'); busy.delete(m[2]); }
      }
      lastLen = ev.length; lastChange = Date.now();
    }
    // one busy person per tick, each up to 8 shots while working
    const working = [...busy.entries()].filter(([, b]) => b.n < 8);
    if (working.length) { const [seat, b] = working[rr++ % working.length]; b.n++; await seatShot(seat, b, `w${b.n}`); }
    if (j && j.phase !== lastPhase) { log(`phase ${j.phase}`); lastPhase = j.phase; lastAsk = 0; }
    // Waiting for the human: try again every 30 s — the person may answer later (a new entry in answers.json).
    if (j?.phase === 'awaiting_clarification' && answersFile && dlBin && Date.now() - lastAsk > 30000) {
      lastAsk = Date.now();
      try { await answer(win); } catch (e) { log(`answering failed: ${String(e.message ?? e).slice(0, 200)}`); }
    }
    if (shot <= 120 && (Date.now() - t0) / 60000 >= shot) await snap(`${shots}/${String(shot++).padStart(2, '0')}-floor.png`);
    if (j && ['done', 'awaiting_pr_merge', 'aborted'].includes(j.phase)) {
      log(`finished: ${j.phase}`); await snap(`${shots}/98-finished.png`);
      // Seats on the floor: wait for Michael's release and each seat's answer to it (act "done" in the hive log), then for the
      // floor to take them off — but no longer than a minute once all have answered: the app may keep their cards (F15),
      // and waiting on that cost 4 idle minutes per run.
      const seats = Object.values(j.munder?.seats ?? {}).map((x) => x.worker);
      const gone = () => { try { const r = JSON.parse(fs.readFileSync(path.join(hiveRoot(), 'registry.json'), 'utf8')); return seats.every((w) => !r.agents[w] || r.agents[w].archived || r.agents[w].status === 'gone'); } catch { return true; } };
      const answered = () => { try { const done = new Set(fs.readFileSync(path.join(hiveRoot(), 'log.jsonl'), 'utf8').split('\n').filter(Boolean).map((l) => { try { return JSON.parse(l); } catch { return {}; } }).filter((m) => m.kind === 'message' && m.to === 'god' && m.act === 'done').map((m) => m.from)); return seats.every((w) => done.has(w)); } catch { return false; } };
      let since = 0;
      for (let k = 0; seats.length && k < 48 && !gone(); k++) { if (answered() && ++since > 12) break; await win.waitForTimeout(5000); }
      log(seats.length ? (gone() ? `all ${seats.length} seats released` : answered() ? `all ${seats.length} seats answered the release; the floor still shows them (F15)` : 'seats still on the floor after 4 minutes') : 'no seats');
      for (const e of events().slice(lastLen)) log(`event ${e.split('\t').slice(1).join(' ').slice(0, 150)}`);
      await snap(`${shots}/99-final.png`); await closeApp(app); process.exit(j.phase === 'aborted' ? 1 : 0);
    }
    if (Date.now() - lastChange > 20 * 60000) { log('stalled: no event for 20 minutes'); await snap(`${shots}/99-stalled.png`); await closeApp(app); process.exit(1); }
  }
  log('timeout'); await snap(`${shots}/99-timeout.png`); await closeApp(app); process.exit(1);
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
