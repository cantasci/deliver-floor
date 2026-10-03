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
async function answer(win) {
  const id = fs.readFileSync(path.join(repo, '.work/ACTIVE'), 'utf8').trim();
  const r = JSON.parse(fs.readFileSync(path.join(repo, '.work', id, 'readiness.json'), 'utf8'));
  const answers = JSON.parse(fs.readFileSync(answersFile, 'utf8'));
  let n = 0;
  for (const it of (r.items ?? r).filter((x) => x.status === 'open' && x.owner !== 'pm')) {
    const a = answers.find((x) => new RegExp(x.match, 'i').test(it.question));
    if (!a) { if (!unanswered.has(it.id)) log(`no prepared answer for ${it.id} — a real person must answer: ${it.question}`); unanswered.add(it.id); continue; }
    execFileSync(dlBin, ['-C', repo, 'clarify', it.id, a.answer], { env: { ...process.env, DELIVER_APPROVER: 'e2e-human' } });
    log(`human answered ${it.id}: ${it.question.slice(0, 90)}`); n++;
  }
  if (n) {
    await win.fill('textarea[placeholder*="Michael"]', 'I answered your questions (recorded with dl clarify, see readiness.json). Continue the /deliver job.');
    await win.keyboard.press('Enter'); log('told Michael the questions are answered');
  }
}
(async () => {
  fs.mkdirSync(shots, { recursive: true });
  const app = await _electron.launch({ executablePath: `${mdDir}/node_modules/electron/dist/electron`, args: ['.', '--no-sandbox', '--disable-gpu'],
    cwd: mdDir, env: { ...process.env, HOME: home, ELECTRON_DISABLE_SANDBOX: '1' }, timeout: 90000 });
  const win = await app.firstWindow();
  await win.waitForTimeout(6000);
  const open = win.locator('button', { hasText: /^open$/i }).first();
  if (await open.count()) { await open.click(); log('opened the hive'); }
  await win.waitForSelector('textarea[placeholder="Message Michael"]', { timeout: 120000 });
  await win.waitForTimeout(20000); // let Michael's Claude session finish booting
  await win.screenshot({ path: `${shots}/00-floor.png` });
  await win.fill('textarea[placeholder="Message Michael"]', message);
  await win.keyboard.press('Enter');
  log(`briefed Michael: ${message}`);
  let shot = 1, lastLen = 0, lastChange = Date.now(), lastPhase = '', lastAsk = 0;
  let burst = 0, nb = 0;
  // Proof of who does the work: when Michael sends a seat a work order (md-send), select that person on the floor and
  // screenshot their own terminal while they work; once more when they report done (md-done). Round-robin over busy seats.
  const busy = new Map(); let rr = 0, ns = 0;
  const select = async (name) => {
    try {
      if (name === 'Michael') { await win.getByText('BOSS', { exact: true }).first().click({ timeout: 3000 }); return true; }
      const note = win.locator(`[aria-label="Note for ${name}"]`).first();
      if (!(await note.count())) return false;
      await note.locator('xpath=ancestor::*[@draggable="true"][1]').click({ position: { x: 12, y: 12 }, timeout: 3000 });
      return true;
    } catch (e) { log(`select ${name} failed: ${String(e.message ?? e).split('\n')[0].slice(0, 120)}`); return false; }
  };
  const seatShot = async (seat, b, tag) => {
    const name = b.name ?? (b.name = floorName(b.worker));
    if (!name || !(await select(name))) return;
    await win.waitForTimeout(900);
    const file = `p${String(++ns).padStart(3, '0')}-${seat.replace('#', '')}-${b.task}-${tag}.png`;
    await win.screenshot({ path: `${shots}/${file}` }); log(`shot ${file} (${name} at work)`);
    await select('Michael');
  };
  const tab = async (name) => { const b = win.locator('button', { hasText: new RegExp(`^\\s*${name}\\s*$`, 'i') }).first(); if (await b.count()) await b.click().catch(() => {}); };
  while (Date.now() - t0 < Number(mins) * 60000) {
    await win.waitForTimeout(5000);
    // While floor workers run: the Command Center's workers tab, a screenshot every 5 s (they can finish within a minute).
    if (burst > 0) {
      if (burst === 8) await tab('workers');
      await win.screenshot({ path: `${shots}/w${String(++nb).padStart(3, '0')}-workers.png` });
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
    if (shot <= 120 && (Date.now() - t0) / 60000 >= shot) await win.screenshot({ path: `${shots}/${String(shot++).padStart(2, '0')}-floor.png` });
    if (j && ['done', 'awaiting_pr_merge', 'aborted'].includes(j.phase)) { log(`finished: ${j.phase}`); await win.screenshot({ path: `${shots}/99-final.png` }); await closeApp(app); process.exit(j.phase === 'aborted' ? 1 : 0); }
    if (Date.now() - lastChange > 20 * 60000) { log('stalled: no event for 20 minutes'); await win.screenshot({ path: `${shots}/99-stalled.png` }); await closeApp(app); process.exit(1); }
  }
  log('timeout'); await win.screenshot({ path: `${shots}/99-timeout.png` }); await closeApp(app); process.exit(1);
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
