const { chromium } = require('/home/hatch/workspace/goals/showcasemy-resume-to-portfolio-product/files/launch-post/node_modules/playwright-core');

const URL = 'http://127.0.0.1:8931/index.html';
const OUT = '/home/hatch/workspace/kinetic-whip/verify/';
const EXE = '/home/hatch/.cache/ms-playwright/chromium-1181/chrome-linux/chrome';
const PROXY = { server: 'http://127.0.0.1:8888', bypass: '127.0.0.1,localhost' };

(async () => {
  const browser = await chromium.launch({ executablePath: EXE, args: ['--no-sandbox', '--disable-gpu'] });
  const errors = [];
  const mctx = await browser.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true, proxy: PROXY, ignoreHTTPSErrors: true });
  const mpage = await mctx.newPage();
  mpage.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  mpage.on('pageerror', (e) => errors.push(e.message));
  await mpage.goto(URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
  for (let i = 0; i < 60; i++) {
    await mpage.waitForTimeout(1000);
    const st = await mpage.evaluate(() => window.__KW || null);
    if (st && st.state === 'menu') break;
  }
  await mpage.touchscreen.tap(195, 462);
  await mpage.waitForTimeout(1500);
  const cdp = await mctx.newCDPSession(mpage);
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 195, y: 420, id: 1 }] });
  let maxSpin = 0;
  for (let i = 1; i <= 40; i++) {
    const a = (i / 40) * Math.PI * 2 * 2;
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: 195 + Math.cos(a) * 70, y: 420 + Math.sin(a) * 70, id: 1 }] });
    await mpage.waitForTimeout(100);
    const st = await mpage.evaluate(() => window.__KW || null);
    if (st && st.spin > maxSpin) maxSpin = st.spin;
    if (i === 20) await mpage.screenshot({ path: OUT + 'v1-play2-mobile.png' });
  }
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  const st = await mpage.evaluate(() => window.__KW || null);
  console.log('state:', JSON.stringify(st), 'maxSpin:', maxSpin.toFixed(0));
  console.log('errors:', JSON.stringify(errors));
  await browser.close();
  console.log('DONE');
})().catch((e) => { console.error('FAIL', e.message); process.exit(1); });
