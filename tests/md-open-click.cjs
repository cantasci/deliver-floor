// The person at the screen after `dl floor-open` started Munder Difflin: the app opens on its floor picker with the repo's
// floor selected, and the person clicks Open — the one click the app requires (it has no setting to skip the picker).
// Used as munder.app_command in the live floor-open test; then it keeps the app open and photographs the floor.
//   node md-open-click.cjs <md dir> <home> <shots dir> <repo>     (stops when the repo's job is done, or after 90 min)
const { _electron } = require('playwright');
const fs = require('fs'), path = require('path');
const [,, mdDir, home, shots, repo] = process.argv;
const t0 = Date.now(), log = (m) => console.log(`[${Math.round((Date.now() - t0) / 1000)}s] ${m}`);
const phase = () => { try { const d = fs.readdirSync(path.join(repo, '.work')).filter((x) => x.startsWith('JOB-')).sort().pop(); return JSON.parse(fs.readFileSync(path.join(repo, '.work', d, 'job.json'), 'utf8')).phase; } catch { return null; } };
(async () => {
  fs.mkdirSync(shots, { recursive: true });
  const app = await _electron.launch({ executablePath: `${mdDir}/node_modules/electron/dist/electron`, args: ['.', '--no-sandbox', '--disable-gpu',
      '--disable-renderer-backgrounding', '--disable-background-timer-throttling', '--disable-backgrounding-occluded-windows'],
    cwd: mdDir, env: { ...process.env, HOME: home, ELECTRON_DISABLE_SANDBOX: '1' }, timeout: 90000 });
  const win = await app.firstWindow();
  const snap = async (n) => { try { await win.screenshot({ path: `${shots}/${n}.png`, timeout: 30000 }); } catch (e) { log(`screenshot skipped: ${String(e.message).split('\n')[0]}`); } };
  await win.waitForTimeout(6000); await snap('00-picker');
  const open = win.locator('button', { hasText: /^open$/i }).first();
  if (await open.count()) { await open.click(); log('the person clicked Open on the floor picker'); } else log('no floor picker shown');
  await win.waitForSelector('textarea[placeholder="Message Michael"]', { timeout: 120000 }); log('Michael is on the floor');
  await win.waitForTimeout(20000); await snap('01-floor');
  let n = 2;
  while (Date.now() - t0 < 90 * 60000) {
    await win.waitForTimeout(60000);
    const p = phase(); if (n % 2 === 0) await snap(String(n).padStart(2, '0') + `-${p ?? 'no-job'}`); n++;
    if (p === 'done' || p === 'aborted') { log(`job ${p}`); await win.waitForTimeout(90000); await snap('99-final'); break; }
  }
  await Promise.race([app.close().catch(() => {}), new Promise((r) => setTimeout(r, 15000))]); process.exit(0);
})().catch((e) => { log(`failed: ${e.message}`); process.exit(1); });
