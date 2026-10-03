// Drives the real Munder Difflin app (Electron) like a user: open the hive, brief Michael, watch the floor.
//   node md-drive.cjs <md dir> <home> <shots dir> <repo> "<message to Michael>" [timeout minutes]
// Prints progress lines; exits 0 when the repo's job reaches done / awaiting_pr_merge, 1 on timeout or stall.
const { _electron } = require('playwright');
const fs = require('fs'), path = require('path');
const [,, mdDir, home, shots, repo, message, mins = '60'] = process.argv;
const t0 = Date.now(), log = (m) => console.log(`[${Math.round((Date.now() - t0) / 1000)}s] ${m}`);
const job = () => { try { const id = fs.readFileSync(path.join(repo, '.work/ACTIVE'), 'utf8').trim(); return JSON.parse(fs.readFileSync(path.join(repo, '.work', id, 'job.json'), 'utf8')); } catch { return null; } };
const lastJob = () => { try { const d = fs.readdirSync(path.join(repo, '.work')).filter((x) => x.startsWith('JOB-')).sort().pop(); return d && JSON.parse(fs.readFileSync(path.join(repo, '.work', d, 'job.json'), 'utf8')); } catch { return null; } };
const events = () => { try { const d = fs.readdirSync(path.join(repo, '.work')).filter((x) => x.startsWith('JOB-')).sort().pop(); return fs.readFileSync(path.join(repo, '.work', d, 'events.log'), 'utf8').split('\n').filter(Boolean); } catch { return []; } };
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
  let shot = 1, lastLen = 0, lastChange = Date.now(), lastPhase = '';
  while (Date.now() - t0 < Number(mins) * 60000) {
    await win.waitForTimeout(30000);
    const j = job() ?? lastJob(), ev = events();
    if (ev.length !== lastLen) { for (const e of ev.slice(lastLen)) log(`event ${e.split('\t').slice(1).join(' ').slice(0, 150)}`); lastLen = ev.length; lastChange = Date.now(); }
    if (j && j.phase !== lastPhase) { log(`phase ${j.phase}`); lastPhase = j.phase; }
    if (shot <= 120 && (Date.now() - t0) / 60000 >= shot) await win.screenshot({ path: `${shots}/${String(shot++).padStart(2, '0')}-floor.png` });
    if (j && ['done', 'awaiting_pr_merge', 'aborted'].includes(j.phase)) { log(`finished: ${j.phase}`); await win.screenshot({ path: `${shots}/99-final.png` }); await app.close(); process.exit(j.phase === 'aborted' ? 1 : 0); }
    if (Date.now() - lastChange > 20 * 60000) { log('stalled: no event for 20 minutes'); await win.screenshot({ path: `${shots}/99-stalled.png` }); await app.close(); process.exit(1); }
  }
  log('timeout'); await win.screenshot({ path: `${shots}/99-timeout.png` }); await app.close(); process.exit(1);
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
